---
-- blizzard/packageman.lua
-- Battle.net package management extension
-- Copyright (c) 2014-2015 Blizzard Entertainment
---
	packageman = {}

	local package_cache = {}
	local package_alias = {}
	local import_filter = {}

--
-- Api keywords
--
	premake.api.register {
		name = "includedependencies",
		scope = "config",
		kind = "tableorstring"
	}

	premake.api.register {
		name = "linkdependencies",
		scope = "config",
		kind = "tableorstring"
	}

	premake.api.register {
		name = "bindirdependencies",
		scope = "config",
		kind = "tableorstring"
	}

	premake.api.register {
		name = "copybindependencies",
		scope = "config",
		kind = "tableorstring",
	}

	premake.api.register {
		name = "copybintarget",
		scope = "config",
		kind = "path",
		tokens = true,
		pathVars = true,
	}

---
-- Setup package aliases.
---
	function packagealias(table)
		for name, alias in pairs(table) do
			package_alias[name] = alias
		end
	end

---
-- Import a set of packages.
---
	function import(table)
		if not table then
			return nil
		end

		-- Store current scope.
		local scope = premake.api.scope.current

		-- import packages.
		local init_table = {}
		for name, version in pairs(table) do
			name = packageman.realname(name)
			if not package_cache[name] then
				local prj = package.declare_auto(name, version)
				package_cache[name] = prj
				init_table[name] = prj;
			end
		end

		-- initialize.
		for _, p in pairs(init_table) do
			p:initialize()
		end

		-- restore current scope.
		premake.api.scope.current = scope
	end

---
-- Import lib filter for a set of packages.
---
	function importlibfilter(table)
		if not table then
			return nil
		end

		-- import packages.
		for name, filter in pairs(table) do
			if not import_filter[name] then
				import_filter[name] = filter
			end
		end
	end

---
--- Gets the default import filter
---
	local default_import_filter = function(name)
		if import_filter[name] then
			return import_filter[name]
		end

		return nil
	end


---
-- Get the real name of a package.
---
	function packageman.realname(package)
		local name = package_alias[package]
		if not name then
			return package
		end

		premake.warnOnce("ALIAS", "'%s' aliased to '%s'.", package, name)
		return name
	end

---
--- resolve packages, internal method.
---
	function packageman.resolvepackages(ctx)

		local function sortedpairs(t)
			-- first transform the table into pure key/value pairs, and collect all keys.
			local n    = {}
			local keys = {}
			for k, v in pairs(t) do
				if tonumber(k) ~= nil then
					if not n[v] then
						n[v] = v
						table.insert(keys, v)
					end
				else
					if not n[k] then
						n[k] = v
						table.insert(keys, k)
					end
				end
			end

			-- sort the keys.
			table.sort(keys)

			-- return the iterator function
			local i = 0
			return function()
				i = i + 1
				if keys[i] then
					return keys[i], t[keys[i]]
				end
			end
		end


		local resolveIncludes = function(p, name, ctx)
			if not p.includes and p.variant == 'auto' then
				return p.auto_includes(ctx)
			end

			return p.includes
		end

		local resolveBindirs = function(p, name, ctx)
			if not p.bindirs and p.variant == 'auto' then
				return p.auto_bindirs(ctx)
			end

			return p.bindirs
		end

		local resolveLinks = function(p, name, ctx, tbl)
			local links = p.links
			local libdirs = p.libdirs

			if not links and p.variant == 'auto' then
				links = p.auto_links(ctx)
				if tbl then
					local filter = package.create_filter(tbl)
					links = filter(links)
				end
			end

			if not libdirs and p.variant == 'auto' then
				libdirs = p.auto_libdirs(ctx)
			end

			return links, libdirs
		end

		if ctx.packages_resolved then
			return
		end

		-- resolve package includes.
		if ctx.includedependencies then
			for name,_ in sortedpairs(ctx.includedependencies) do
				local p = package.get(name)
				local paths = resolveIncludes(p, name, ctx)
				local includedirs = ctx.includedirs
				for _, path in ipairs(paths) do
					table.insertkeyed(includedirs, path)
				end
			end
		end

		-- resolve package binpath.
		if ctx.bindirdependencies then
			for name,_ in sortedpairs(ctx.bindirdependencies) do
				local p = package.get(name)
				local paths = resolveBindirs(p, name, ctx)
				local bindirs = ctx.bindirs
				for _, path in ipairs(paths) do
					table.insertkeyed(bindirs, path)
				end
			end
		end

		-- resolve package includes.
		if ctx.copybindependencies then

			local info = premake.config.gettargetinfo(ctx)
			local targetDir = ctx.copybintarget or info.directory

			for name, value in sortedpairs(ctx.copybindependencies) do
				local handle_path = function(sourcePath, destPath)
					local command = '{COPY} "' ..
						path.translate(premake.project.getrelative(ctx.project, sourcePath)) .. '" "' ..
						path.translate(premake.project.getrelative(ctx.project, destPath)) .. '"'

					table.insert(ctx.postbuildcommands, command)
				end

				local p = package.get(name)
				local paths = resolveBindirs(p, name, ctx)
				if type(paths) == 'table' then
					for _, path in pairs(paths) do
						handle_path(path, targetDir)
					end
				else
					handle_path(paths, targetDir)
				end
			end
		end

		-- resolve package links.
		if ctx.linkdependencies then
			for name, value in sortedpairs(ctx.linkdependencies) do
				local tbl = nil
				if type(value) == 'table' then
					tbl = value
				else
					tbl = default_import_filter(name)
				end

				local p = package.get(name)
				local links, libdirs = resolveLinks(p, name, ctx, tbl)
				local ctxlinks = ctx.links
				for _, link in ipairs(links) do
					table.insertkeyed(ctxlinks, link)
				end
				table.insertflat(ctx.libdirs, libdirs)
			end
		end

		ctx.packages_resolved = true
	end


---
--- inject package resolver into premake.action.call
---
	premake.override(premake.action, "call", function(base, name)
		print('Resolving Packages...')
		for sln in premake.global.eachSolution() do
			for prj in premake.solution.eachproject(sln) do
				if not prj.external then
					cfg = prj
					packageman.resolvepackages(prj)
					for cfg in premake.project.eachconfig(prj) do
						packageman.resolvepackages(cfg)
					end
				end
			end
		end

		base(name)
	end)


---
-- shortcut for if you need both include & link dependencies
---
	function usedependencies(table)
		includedependencies(table)
		linkdependencies(table)
	end


---
-- get a previously imported package by name.
---
	function package.get(name)
		local p = package_cache[packageman.realname(name)]
		if not p then
			error("Package was not imported; use 'import { '" .. name .. "' }'.")
		end
		return p
	end


---
-- override 'project' so that when a package defines a new project we initialize it with some default values.
---
	premake.override(premake.project, "new", function(base, name)
		local prj = base(name)

		if package.current then
			prj.package = package.current.name

			-- set some default package values.
			prj.blocks[1].targetdir = bnet.lib_dir
			prj.blocks[1].objdir    = path.join(bnet.obj_dir, name)
			prj.blocks[1].location  = path.join(bnet.projects_dir, 'packages')
		end

		return prj
	end)
