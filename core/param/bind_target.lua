local path = (...):sub(1, -string.len(".core.param.bind_target") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---A target to bind to
---@class Inochi2D.BindTarget: Inochi2D.Object
---@field public node Inochi2D.Node? The node to bind to
---@field public paramName string The parameter to bind
local BindTarget = Object:extend()

function BindTarget:new()
	self.node = nil
	self.paramName = ""
end

---@alias Inochi2D.BindTarget_Class Inochi2D.BindTarget
---| fun():Inochi2D.BindTarget
---@cast BindTarget +Inochi2D.BindTarget_Class
return BindTarget
