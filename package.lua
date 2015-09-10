-- Package management Premake module
-- Copyright (c) 2015 João Matos and the Premake project
-- Contains package routines.

	local p = premake
	p.package = p.api.container("newpackage", p.global, { "config" })

	local packaging = p.modules.prepack
	packaging.package = {}

	local package = packaging.package

	function p.package.new(name)
		local pkg = p.container.new(p.package, name)
		return pkg
	end

	function p.package.bake(self)
	end	

	p.api.rootContainer().newpackages = {}
