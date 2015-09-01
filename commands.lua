-- Package management Premake module
-- Copyright (c) 2015 João Matos and the Premake project
-- Contains package manager commands routines.

    local p = premake
    local pkg = p.modules.prepack

    function pkg.list()
        for pk in pkgdb.foreach() do
            print(pk.name)
            print(pk.url)
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

    function pkg.update()
        print("Updating packages index...")
        local index, err = http.get(pkg.indexurl, function ()
            print("progress")
        end)

        if index == nil then
            print("Error retrieving package index: " .. err)
            return
        end

        print("Sucessfully retrieved package index.")
        print(index)
    end

    function pkg.help()
        print("Package management commands:")
        for k,v in pairs(pkg.commands) do
            print("\t" .. k .. ": " .. v.description)
        end
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
    }