local path = (...):sub(1, -string.len(".core.nodes.composite") - 1)

---@type Inochi2D.Composite_Class
local Composite = require(path..".core.nodes.composite.composite")
---@type Inochi2D.CompositePackage
local CompositePackage = require(path..".core.nodes.composite.package")

---@class Inochi2D.CompositeModule
local CompositeModule = {
	CompositePackage.inInitComposite,
	Composite = Composite
}

return CompositeModule
