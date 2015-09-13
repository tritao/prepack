-- Package management Premake module
-- Copyright (c) 2015 João Matos and the Premake project

local api = premake.api

local scope = "workspace"

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