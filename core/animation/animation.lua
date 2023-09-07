local path = (...):sub(1, -string.len(".core.animation.animation") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---@class (exact) Inochi2D.Animation: Inochi2D.Object
---@field public timestep number The timestep of each frame
---@field public additive boolean Whether the animation is additive. Additive animations will not replace main animations, but add their data on top of the running main animation.
---@field public animationWeight number The weight of the animation. This is only relevant for additive animations
---@field public lanes Inochi2D.AnimationLane[] All of the animation lanes in this animation
---@field public length integer Length in frames
---@field public leadIn integer Time where the lead-in ends
---@field public leadOut integer Time where the lead-out starts
local Animation = Object:extend()

function Animation:new()
	self.timestep = 0.0166
	self.additive = false
	self.animationWeight = 0
	self.lanes = {}
	self.length = 0
	self.leadIn = -1
	self.leadOut = -1
end

---Finalizes the animation
---@param puppet Inochi2D.Puppet
function Animation:finalize(puppet)
	for _, lane in ipairs(self.lanes) do
		lane:finalize(puppet)
	end
end

---@alias Inochi2D.Animation_Class Inochi2D.Animation
---| fun():Inochi2D.Animation
---@cast Animation +Inochi2D.Animation_Class
return Animation
