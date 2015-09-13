---
-- blizzard/cache.lua
-- Battle.net package management extension
-- Copyright (c) 2014-2015 Blizzard Entertainment
---
cache = {}

cache.package_hostname = 'package.battle.net'
cache.variants = {}
cache.folders  = { "." }
cache.location_override = nil

local JSON = assert(loadfile "json.lua")()


function cache.use_env_var_location()
	local path = os.getenv('PACKAGE_CACHE_PATH')

	if path and os.isdir(path) then
		cache.location_override = nil
		return true
	end

	return false
end


function cache.get_folder()
	if cache.location_override then
		return cache.location_override
	end

	local folder = os.getenv('PACKAGE_CACHE_PATH')
	if folder then
		return folder
	else
		if os.get() == 'linux' or os.get() == 'macosx' then
			return '/tmp/package_cache'
		end
		return 'c:/package_cache'
	end
end

local url_encodings = {}

url_encodings[' '] = '%%20'
url_encodings['!'] = '%%21'
url_encodings['"'] = '%%22'
url_encodings['#'] = '%%23'
url_encodings['$'] = '%%24'
url_encodings['&'] = '%%26'
url_encodings['\''] = '%%27'
url_encodings['('] = '%%28'
url_encodings[')'] = '%%29'
url_encodings['*'] = '%%2A'
url_encodings['+'] = '%%2B'
url_encodings['-'] = '%%2D'
url_encodings['.'] = '%%2E'
url_encodings['/'] = '%%2F'
url_encodings[':'] = '%%3A'
url_encodings[';'] = '%%3B'
url_encodings['<'] = '%%3C'
url_encodings['='] = '%%3D'
url_encodings['>'] = '%%3E'
url_encodings['?'] = '%%3F'
url_encodings['@'] = '%%40'
url_encodings['['] = '%%5B'
url_encodings['\\'] = '%%5C'
url_encodings[']'] = '%%5D'
url_encodings['^'] = '%%5E'
url_encodings['_'] = '%%5F'
url_encodings['`'] = '%%60'


function escape_url_param(param)
	param = param:gsub('%%', '%%25')

	for k,v in pairs(url_encodings) do
		param = param:gsub('%' .. k, v)
	end

	return param
end


function _package_location(folder, package, version)
	local location = path.join(folder, package, version)
	location = path.normalize(location)

	if os.get() == "linux" or os.get() == "macosx" then
		location = location:gsub("%s+", "_")
		location = location:gsub("%(", "_")
		location = location:gsub("%)", "_")
	end

	return location
end


function cache.has_variant(package, version, variant)
	return cache.variants[package .. '/' .. version][variant] == 1
end


function cache.get_variants(package, version)
	cache.variants[package .. '/' .. version] = {}

	-- test if we have the package locally.
	for i, folder in ipairs(cache.folders) do
		local location = _package_location(folder, package, version)
		if os.isdir(location) then
			for i, dir in pairs(os.matchdirs(location .. '/*')) do
				local n, variant = string.match(dir, "(.+)[\\|/](.+)")
				cache.variants[package .. '/' .. version][variant] = 1
			end
		end
	end

	-- Query the server for variant information.
	local file = "archives?name=" .. escape_url_param(package) .. "&version=" .. escape_url_param(version)

	local content, err = http.get(cache.package_hostname .. '/' .. file)
	if not content then
		premake.error(err)
	end

	-- load content as json object.
	local variant_tbl = JSON:decode(content)

	for i, variant in pairs(variant_tbl) do
		verbosef("Adding variant: " .. variant)
		cache.variants[package .. '/' .. version][path.getbasename(variant)] = 1
	end

	-- Currently only use this return in tests, package.lua references cache.variants directly
	return cache.variants[package .. '/' .. version]
end


function cache.download(package, variant)
	-- first see if we can find the package locally.
	for i, folder in pairs(cache.folders) do
		local location = _package_location(folder, package, variant)
		if os.isdir(location) then
			verbosef("LOCAL: %s", location)
			return location
		end
	end

	-- then try the package cache.
	local location = _package_location(cache.get_folder(), package, variant)
	if os.isdir(location) then
		verbosef("CACHED: %s", location)
		return location
	end

	-- calculate standard file_url.
	local destination = location .. ".zip"
	local file        = path.join(package, variant .. '.zip')
	local file_url    = cache.package_hostname .. '/' .. file:gsub(' ', '%%20')

	-- get link information from server.
	local name, version = string.match(package, "(.+)[\\|/](.+)")
	local file = "link?name=" .. escape_url_param(name) .. "&version=" .. escape_url_param(version) .. "&variant=" .. escape_url_param(variant)
	local content, err = http.get(cache.package_hostname .. '/' .. file)
	if content then
		local info_tbl = JSON:decode(content)
		if info_tbl.url then
			file_url = info_tbl.url
		end
	end

	-- get solutionname and username.
	local solution_name = "unknown"
	if premake.api and premake.api.scope and premake.api.scope.solution then
		solution_name = premake.api.scope.solution.name
	end

	local user = "UNKNOWN"
	if os.get() == "windows" then
		user = os.getenv("USERNAME") or user
	else
		user = os.getenv("LOGNAME") or user
	end

	-- Download file.
	print(' DOWNLOAD: ' .. file_url)
	os.mkdir(path.getdirectory(destination))
	local return_str, return_code = http.download(file_url, destination, nil, {"From: " .. user, "Referer: " .. solution_name})
	if return_code ~= 0 then
		premake.error('Download of file %s returned: %s\nCURLE_ERROR_CODE(%d)', file_url, return_str, return_code)
	end

	-- Unzip it
	verbosef(' UNZIP   : %s', destination)
	zip.extract(destination, location)
	os.remove(destination)

	return location
end
