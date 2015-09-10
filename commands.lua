-- Package management Premake module
-- Copyright (c) 2015 João Matos and the Premake project
-- Contains package manager commands routines.

    local colors = include("ansicolors.lua")

    local p = premake
    local pkg = p.modules.prepack
    local pkgdb = pkg.database

    function pkg.list()
        for pk in pkgdb.foreach() do
            print(pk.name .. " " .. pk.version .. " [" .. pk.license .. "]")
        end
    end

    function pkg.search(package)
        print("Searching for packages ")
    end

    function pkg.install()
        print("Installing package ")
    end    

    function pkg.index()
        print("Buiding packages index")
    end

    function pkg.bundle()
        print("Bundling package")
    end

    function pkg.update()
        print("Updating packages index...")

        if os.isfile(pkg.repositoryindex) then
            os.copyfile(pkg.repositoryindex, pkg.cacheindex)
        else
            local index, err = http.get(pkg.repositoryindex, function ()
                print("progress")
            end)

            if index == nil then
                print("Error retrieving package index: " .. err)
                return
            end            
        end

        print("Sucessfully retrieved package index.")
    end

    function pkg.help(args)
        if args == nil or #args == 1 then
            print("Usage: prepack <command> [arguments]\n")
            print("Available commands:")
            for k,v in pairs(pkg.commands) do
                print("\t" .. colors("%{red}" .. k) .. "\t" .. v.description)
            end
            return
        end

        -- If we have arguments, then look up the help for the requested command.
        local command = args[2]
        local action = pkg.commands[string.lower(command)]
        if action == nil then
            print("Unknown command '" .. command .. "'.")
            return
        end
    end

    function pkg.debug()
        print("Debug information:")

        local git, res = os.outputof("git --version 2>nul")
        local hg, res = os.outputof("hg --version --quiet 2>nul")
        local svn, res = os.outputof("svn --version")

        print("git: " .. git or "not found")
        print("hg: " .. hg or "not found")
        print("svn: " .. svn or "not found")

        print("\nPackage cache: " .. pkg.cache)
    end    

    pkg.commands = {
        list = {
            description = "Lists the packages in the index",
            exec = pkg.list
        },

        search = {
            description = "Searches for a package in the index",
            exec = pkg.search
        },

        install = {
            description = "Installs packages in the system",
            exec = pkg.install
        },

        bundle = {
            description = "Bundles a local package to an archive",
            exec = pkg.bundle
        },

        update = {
            description = "Updates the package index",
            exec = pkg.update
        },

        index = {
            description = "Builds an index of the local packages",
            exec = pkg.index
        },

        help = {
            description = "Shows an help listing of commands",
            exec = pkg.help
        },

        debug = {
            description = "Dumps debug information",
            exec = pkg.debug
        },        
    }