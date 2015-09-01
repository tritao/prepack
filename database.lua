-- Package management Premake module
-- Copyright (c) 2015 João Matos and the Premake project
-- Contains package database routines.

	local p = premake
	local pkg = p.modules.prepack

	pkg.database = {}
	local pkgdb = pkg.database

	pkgdb.cache = "C:\\Users\\triton\\Dropbox\\Public\\packages"
	pkgdb.packages = {}

	function pkgdb.init()
		local searchPaths = { pkgdb.cache }

		-- Search for Lua package files.
		for _,searchPath in ipairs(searchPaths) do
			local matches = os.matchfiles(path.join(searchPath, "**.lua"))
			for _,file in pairs(matches) do
				--print("Package found '" .. file .. "'")
				dofile (file)
			end
		end
	end

	function pkgdb.foreach()
		--[[ for pkg in pairs(pkgdb.packages) do
			callback(pkg)
		end ]]

		local root = p.api.rootContainer()
		return p.container.eachChild(root, p.package)		
	end

	function pkgdb.add()

	end

	function pkgdb.remove()

	end

