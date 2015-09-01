-- Package management Premake module
-- Copyright (c) 2015 João Matos and the Premake project

    local p = premake
    p.modules.prepack = {}

    include("database.lua")
    include("package.lua")

    local pkg = p.modules.prepack
    local pkgdb = pkg.database

    pkg.indexurl = "https://dl.dropboxusercontent.com/u/194502/packages/index.json"

    include ("commands.lua")

    newaction {
        trigger = "package",
        description = "Builds the package index",
        execute = function()
            local command = _ARGS[1]
            if command == nil then
                pkg.help()
                return
            end

            local action = pkg.commands[string.lower(command)]
            if action == nil then
                print("Unknown package command '" .. command .. "'\n")
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
        end,
        onSolution = function(sln)
            return true
        end,
        quiet = true
    }

    local api = p.api

    api.register {
        name = "url",
        scope = "newpackage",
        kind = "string",
    }

    pkgdb.init()

    return pkg