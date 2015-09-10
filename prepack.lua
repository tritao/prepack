-- Package management Premake module
-- Copyright (c) 2015 João Matos and the Premake project

    local p = premake
    p.modules.prepack = {}

    include("database.lua")
    include("package.lua")
    include ("commands.lua")

    local pkg = p.modules.prepack
    local pkgdb = pkg.database

    --pkg.repository = "https://dl.dropboxusercontent.com/u/194502/packages/"
    pkg.repository = pkgdb.dev
    pkg.repositoryindex = pkg.repository .. ".index.lua"

    newaction {
        trigger = "prepack",
        description = "Prepack package manager",
        execute = function()
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
        end,
        onSolution = function(sln)
            return true
        end,
        quiet = true
    }

    local api = p.api

    local scope = "newpackage"

    api.register {
        name = "url",
        scope = scope,
        kind = "string",
    }

    api.register {
        name = "description",
        scope = scope,
        kind = "string",
    }    

    api.register {
        name = "license",
        scope = scope,
        kind = "string",
    }

    api.register {
        name = "tags",
        scope = scope,
        kind = "list:string",
    }

    api.register {
        name = "version",
        scope = scope,
        kind = "string",
    }

    -- Source code management APIs

    api.register {
        name = "hg",
        scope = scope,
        kind = "string",
    }

    api.register {
        name = "git",
        scope = scope,
        kind = "string",
    }

    api.register {
        name = "svn",
        scope = scope,
        kind = "string",
    }

    api.register {
        name = "branch",
        scope = scope,
        kind = "string",
    }    

    api.register {
        name = "revision",
        scope = scope,
        kind = "string",
    }

    return pkg