---
-- blizzard/context.lua
-- Battle.net package management extension
-- Copyright (c) 2014-2015 Blizzard Entertainment
---
bnet = bnet or {}


bnet.build_custom_variant = nil
bnet.build_dir = ""
bnet.obj_dir = ""
bnet.lib_dir = ""
bnet.bin_dir = ""
bnet.projects_dir = ""


function bnet.new()
	return {
		variant = _build_variant
	}
end

premake.override(premake.context, "new", function (base, cfgset, environ)
	local ctx = base(cfgset, environ)
	ctx.bnet = bnet.new()
	return ctx
end)

