local path = (...):sub(1, -string.len(".core.animation.keyframe") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---@class Inochi2D.Keyframe: Inochi2D.Object, Inochi2D.ISerializable
---@field public frame integer The frame at which this frame occurs
---@field public value number The value of the parameter at the given frame
---@field public tension number Interpolation tension for cubic/inout
local Keyframe = Object:extend()

function Keyframe:new()
	self.frame = 0
	self.value = 0
	self.tension = 0.5
end

-- TODO: How to serialize keyframes?
function Keyframe:serialize()
	return {
		frame = self.frame,
		value = self.value,
		tension = self.tension
	}
end

-- TODO: How to serialize keyframes?
function Keyframe:deserialize(t)
end

---@alias Inochi2D.Keyframe_Class Inochi2D.Keyframe
---| fun():Inochi2D.Keyframe
---@cast Keyframe +Inochi2D.Keyframe_Class
return Keyframe
