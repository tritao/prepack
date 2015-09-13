---
-- blizzard/package.lua
-- Battle.net package management extension
-- Copyright (c) 2014-2015 Blizzard Entertainment
---
package = package or {}

package.auto_includes = {}
package.auto_links = {}
package.auto_libdirs = {}
package.auto_bindirs = {}
package.auto_binpath = {}
package.auto_includepath = {}
package.auto_bincopy = {}

package.auto_includes_inc = 1
package.use_cache = {}

cwd = os.getcwd()

-- a registry of packages that we've seen
package.packages = {}

-- the current package, premake is all about global context, don't fight it
package.current = nil

package.action = _ACTION
package.os = os.get()


--
function _match_link(filename, match)
	if type(match) == 'function' then
		return match(filename)
	end
	return string.match(filename, match:lower())
end


-- help filter to link only those libs that are mentioned.
function package.create_filter(t)
	return function(l)
		local matches = {}
		local nonmatches = {}
		local all_index = nil

		for k, link in ipairs(l) do
			local filename = path.getname(link):lower()

			for index, match in ipairs(t) do
				if match == '*' then
					all_index = index
				elseif _match_link(filename, match) then
					if matches[index] then
						table.insert(matches[index], link)
					else
						matches[index] = {link}
					end
					break
				else
					table.insert(nonmatches, link)
				end
			end
		end

		if all_index then
			matches[all_index] = nonmatches
		end

		local linres = {}

		for key, val in ipairs(matches) do
			if t[key] == '*' then
				table.insertflat(linres, val)
			elseif #val > 0 then
				table.insert(linres, val[1])
			end
		end

		return linres;
	end
end

-- declare the base auto package.
function package.declare_auto(name, version)
	local available_variants = cache.get_variants(name, version)
	if next(available_variants) == nil then
		error('Package "' .. name .. ' - ' .. version .. '" has no variants. It might not exist.')
	end

	local package_auto_id = name .. '-' .. version .. '-X' .. package.auto_includes_inc --cant use a slash to stop includedirs and links prefixing the cwd
	package.auto_includes_inc = package.auto_includes_inc + 1
	verbosef("Package Auto Id: %s", package_auto_id)

	-- needed for lambda.
	local lname = name
	local lversion = version

	-- create a new package
	local pkg = {
		name				= lname,
		version				= lversion,
		variant				= 'auto',
		id					= package_auto_id,
		variants			= available_variants,
		auto_includes		= _use(lname, lversion, 'include'),
		auto_links			= _use(lname, lversion, 'link'),
		auto_libdirs		= _use(lname, lversion, 'libdirs'),
		auto_bindirs		= _use(lname, lversion, 'bindirs'),
		auto_bincopy		= _use(lname, lversion, 'copy_bin'),
		auto_binpath		= _use(lname, lversion, 'binpath'),
		auto_includepath	= _use(lname, lversion, 'includepath'),

		-- initializer.
		func = function()
			if cache.has_variant(lname, lversion, 'noarch') then
				package.declare(lname .. '/' .. lversion, 'noarch'):initialize()
			end

			if cache.has_variant(lname, lversion, 'universal') then
				package.declare(lname .. '/' .. lversion, 'universal'):initialize()
			end
		end
	}
	setmetatable(pkg, { __index = package })

	-- Add to new index in array so _use() closure will have new locals
	package.auto_includes[package_auto_id]		= pkg.auto_includes
	package.auto_links[package_auto_id]			= pkg.auto_links
	package.auto_libdirs[package_auto_id]		= pkg.auto_libdirs
	package.auto_bindirs[package_auto_id]		= pkg.auto_bindirs
	package.auto_bincopy[package_auto_id]		= pkg.auto_bincopy
	package.auto_binpath[package_auto_id]		= pkg.auto_binpath
	package.auto_includepath[package_auto_id]	= pkg.auto_includepath

	return pkg
end

-- declare a package given a name
-- will attempt to locate the package in the cache and then look inside the package for further instructions
function package.declare(name, variant)
	if not variant then
		local n,v = string.match(name, "(.+)[\\|/](.+)")
		return package.declare_auto(n, v)
	end

	-- if we already have this package, return it
	-- this allows packages to be safely declared multiple times
	if package.packages[name] and package.packages[name][variant] then
		return package.packages[name][variant]
	end

	local previous_package = package.current

	-- create a new package
	package.current = { name = name, location = nil, variant = variant, func = nil, includes = {}, links = {}, libdirs = {}, bindirs = {}, filter = nil }
	setmetatable(package.current, { __index = package })

	verbosef('PACKAGE %s VARIANT %s', package.current.name, package.current.variant)

	-- check to see if this is an explicit reference to a directory
	package.current.location = cache.download(name, variant)
	local directory = package.current.location

	-- does it contain an include directory?
	local directory_include = path.join(directory, 'include')
	if os.isdir(directory_include) then
		verbosef(' INC ' .. directory_include)
		table.insert(package.current.includes, directory_include)
	end

	-- does it contain an bin directory?
	local directory_bin = path.join(directory, 'bin')
	if os.isdir(directory_bin) then
		verbosef(' BIN ' .. directory_bin)
		if os.get() == "linux" or os.get() == 'macosx' then
			_make_executable(directory_bin)
		end
		table.insert(package.current.bindirs, directory_bin)
	end

	-- does it contain an runtime directory?
	local directory_runtime = path.join(directory, 'runtime')
	if os.isdir(directory_runtime) then
		verbosef(' BIN ' .. directory_runtime)
		if os.get() == "linux" or os.get() == 'macosx' then
			_make_executable(directory_runtime)
		end
		table.insert(package.current.bindirs, directory_runtime)
	end

	-- does it contain a library directory?
	local directory_lib = path.join(directory, 'lib')
	if os.isdir(directory_lib) then
		verbosef(' LIB ' .. directory_lib)
		table.insert(package.current.libdirs, directory_lib)
		package.current.links = _get_lib_files(directory_lib)
	end

	-- on mac does it contain a framework directory?
	if os.get() == 'macosx' then
		local directory_fw = path.join(directory, 'framework')
		if os.isdir(directory_fw) then
			verbosef(' FRAMEWORK ' .. directory_fw)
			table.insert(package.current.libdirs, directory_fw)
			package.current.links = _get_fw_folders(directory_fw)
		end
	end

	-- does it contain a package premake directive?
	local path_premake = path.join(directory, 'premake5-package.lua')
	if os.isfile(path_premake) then
		package.current.func = dofile(path_premake)
	end

	-- save in the package registry
	package.packages[name] = package.packages[name] or {}
	package.packages[name][variant] = package.current

	local p = package.current
	package.current = previous_package
	return p
end


-- initializer.
function package:initialize(operation)
	local previous_package = package.current
	package.current = self

	if self.func then
		-- Remember the current _SCRIPT and working directory so I can restore them after this new chunk has been run.
		local cwd = os.getcwd()
		local script = _SCRIPT
		local scriptDir = _SCRIPT_DIR

		if self.location then
			-- Set the new _SCRIPT and working directory
			_SCRIPT     = path.join(self.location, 'premake5-package.lua')
			_SCRIPT_DIR = self.location
			os.chdir(self.location)
		end

		-- execute the callback
		self.func('project')

		-- Finally, restore the previous _SCRIPT variable and working directory
		_SCRIPT = script
		_SCRIPT_DIR = scriptDir
		os.chdir(cwd)
	end

	package.current = previous_package
end


-- a package declaration for a variant sub package
-- must be used when there's a current package
function package.variant(variant)
	return package.declare(path.join(package.current.name, variant))
end


-- returns the 'build' directory given a package name
function package.directory(name)
	return path.join(solution().location, 'package', name)
end


-- helper function that determins if an operation is for linking
function package.islink(operation)
	return not operation or operation == 'link'
end


-- helper function that determins if an operation is for including
function package.isinclude(operation)
	return not operation or operation == 'include'
end


-- helper function that determins if an operation is for copying bin files
function package.isbincopy(operation)
	return operation and operation == 'copy_bin'
end


-- helper function that determines if command line operation matches parameter
function package.isaction(action)
	return action == package.action
end


-- helper function that determines if os matches parameter
function package.isos(os)
	return os == package.os
end


function _generate_variants(name, cfg)
	local options = cache.variants[name]
	local check   = { }

	-- Check if there is a build_custom_variant method, and use that.
	if type(bnet.build_custom_variant) == 'function' then
		table.insertflat(check, bnet.build_custom_variant(cfg, options))
	end

	-- Check the default variants.
	table.insert(check, _build_variant(cfg))						-- Check for [os]-[arch]-[compiler]-[config]
	table.insert(check, _build_variant(cfg, false, false, true))	-- Check for [os]-[arch]-[compiler]
	table.insert(check, _build_variant(cfg, false, true, false))	-- Check for [os]-[arch]-[config]
	table.insert(check, _build_variant(cfg, false, true, true))		-- Check for [os]-[arch]
	table.insert(check, _build_variant(cfg, true, true, true))		-- Check for [os]
	table.insert(check, 'noarch')
	table.insert(check, 'universal')

	local res = {}
	for _, v in ipairs(check) do
		if options[v] == 1 then
			table.insert(res, v)
		end
	end

	return res;
end


function _get_so_searchstring(val)
	if os.get() == 'windows' then
		return path.join(val, "*.dll")
	elseif os.get() == 'linux' then
		return path.join(val, "*.so*")
	else
		return path.join(val, "*.dylib")
	end
end


function _use(name, version, operation)
	return function(ctx)

		local closed_name = name
		local closed_version = version
		local closed_operation = operation

		return _do_use(closed_name, closed_version, closed_operation, ctx)
	end
end


function _do_use(name, version, operation, ctx)
	local name = name .. '/' .. version

	if package.use_cache[ctx] and package.use_cache[ctx][name] and package.use_cache[ctx][name][operation] then
		return package.use_cache[ctx][name][operation]
	end

	local res = {}
	local variants = _generate_variants(name, ctx)
	for _,v in pairs(variants) do
		local p = package.declare(name, v)

		if operation == 'binpath' and #p.bindirs > 0 then
			return p.bindirs[1]

		elseif operation == 'includepath' and #p.includes > 0 then
			return p.includes[1]

		elseif operation == 'bindirs' then
			table.insertflat(res, table.filterempty(p.bindirs))

		elseif operation == 'libdirs' then
			table.insertflat(res, table.filterempty(p.libdirs))

		elseif p.isinclude(operation) then
			table.insertflat(res, table.filterempty(p.includes))

		elseif p.islink(operation) then
			table.insertflat(res, table.filterempty(p.links))

		elseif p.isbincopy(operation) then
			for _, libdir in pairs(p.bindirs) do
				for _, file in ipairs(os.matchfiles(_get_so_searchstring(libdir))) do
					table.insert(res, path.getabsolute(file))
				end
			end

			if os.get() == 'linux' or os.get() == 'macosx' then
				for _, libdir in pairs(p.libdirs) do
					for _, file in ipairs(os.matchfiles(_get_so_searchstring(libdir))) do
						table.insert(res, path.getabsolute(file))
					end
				end
			end
		end
	end

	-- cache the result.
	package.use_cache[ctx] = package.use_cache[ctx] or {}
	package.use_cache[ctx][name] = package.use_cache[ctx][name] or {}
	package.use_cache[ctx][name][operation] = res

	-- return result.
	return res
end


function _get_lib_files(dir)
	local files = {}
	if os.get() == 'windows' then
		files = os.matchfiles(path.join(dir, '*.lib'))
	elseif os.get() == 'linux' then
		files = table.join(os.matchfiles(path.join(dir, 'lib*.a')), os.matchfiles(path.join(dir, 'lib*.so*')))
	else
		files = table.join(os.matchfiles(path.join(dir, 'lib*.a')), os.matchfiles(path.join(dir, 'lib*.dylib*')))
	end
	return files;
end


function _get_fw_folders(dir)
	if os.get() == 'macosx' then
		local pattern = path.join(dir, '*.framework')
		return os.matchdirs(pattern)
	else
		return {}
	end
end


