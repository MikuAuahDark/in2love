local path = (...):sub(1, -string.len(".core.animation.animation_parameter_ref") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---@class Inochi2D.AnimationParameterRef: Inochi2D.Object
---@field public targetParam Inochi2D.Parameter? A parameter to target
---@field public targetAxis integer Target axis of the parameter
local AnimationParameterRef = Object:extend()

function AnimationParameterRef:new()
	self.targetParam = nil
	self.targetAxis = 0
end

---@alias Inochi2D.AnimationParameterRef_Class Inochi2D.AnimationParameterRef
---| fun():Inochi2D.AnimationParameterRef
---@cast AnimationParameterRef +Inochi2D.AnimationParameterRef_Class
return AnimationParameterRef
