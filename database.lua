-- Package management Premake module
-- Copyright (c) 2015 João Matos and the Premake project
-- Contains package database routines.

	local p = premake
	local pkg = p.modules.prepack

	pkg.database = {}
	local pkgdb = pkg.database

	pkg.cwd = 'C:\\Development\\premake-core\\' or os.getcwd()
	pkg.cache = ''
	pkgdb.dev = "C:\\Users\\triton\\Dropbox\\Public\\packages\\"
	pkgdb.packages = {}

	function pkgdb.init()
		-- Create local package cache if it does not yet exist
		local cache = path.join(pkg.cwd, ".prepack")
		if not os.isdir(cache) then
			os.mkdir(cache)
		end
		pkg.cache = cache
		pkg.cacheindex = path.join(pkg.cache, ".index.lua")

		-- Search for Lua package files.
		local searchPaths = { pkgdb.cache }
		for _,searchPath in ipairs(searchPaths) do
			local matches = os.matchfiles(path.join(searchPath, "**.lua"))
			for _,file in pairs(matches) do
				print("Loading package '" .. file .. "'")
				dofile (file)
			end
		end
	end

	function pkgdb.loadindex()
		if not os.isfile(pkg.cacheindex) then 
			print("Package index was not found, run update command.")
			return false
		end

		-- TODO: Add better error handling for invalid cache indexes.
		local index = dofile(path.translate(pkg.cacheindex))
		print(table.tostring(index, true))

		
	end

	function pkgdb.foreach()
		for pkg in pairs(pkgdb.packages) do
			callback(pkg)
		end

		local root = p.api.rootContainer()
		return p.container.eachChild(root, p.package)		
	end

	function pkgdb.add()

	end

	function pkgdb.remove()

	end

