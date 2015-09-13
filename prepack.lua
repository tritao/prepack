-- Package management Premake module
-- Copyright (c) 2015 João Matos and the Premake project

    local p = premake
    p.modules.prepack = {}

    include("database.lua")
    include("commands.lua")
    include("api.lua")

    local pkg = p.modules.prepack
    local pkgdb = pkg.database

    --pkg.repository = "https://dl.dropboxusercontent.com/u/194502/packages/"
    pkg.repository = pkgdb.dev
    pkg.repositoryindex = pkg.repository .. ".index.lua"

    local function main()
        local command = _ARGS[1]
        if command == nil then
            pkg.help()
            return
        end

        local action = pkg.commands[string.lower(command)]
        if action == nil then
            print("Unknown command '" .. command .. "'.\n")
            pkg.help()
            return
        end

        local exec = action.exec
        if exec == nil then
            print("Execute function for command '" .. command .. "'' was not found.")
            return
        end

        local args = _ARGS
        exec(args)
    end

    newaction {
        trigger = "prepack",
        description = "Prepack package manager",
        execute = main,
        onSolution = function(sln) return true end,
        quiet = true
    }

    return pkg