local path = (...):sub(1, -string.len(".core.nodes.part.apart") - 1)

---@type Inochi2D.Part_Class
local Part = require(path..".lib.classic")
---@type Inochi2D.NodesFactory
local NodesFactory = require(path..".core.nodes.factory")

---Parts which contain spritesheet animation
---@class (exact) Inochi2D.AnimatedPart: Inochi2D.Part
---@field public splits In2LOVE.vec2 The amount of splits in the texture
local AnimatedPart = Part:extend()

function AnimatedPart:new(...)
	self.splits = {0, 0}
	return Part.new(self, ...)
end

function AnimatedPart:typeId()
	return "AnimatedPart"
end

NodesFactory.inRegisterNodeType(AnimatedPart)
---@alias Inochi2D.AnimatedPart_Class Inochi2D.AnimatedPart
---| fun(...:any):Inochi2D.AnimatedPart
---@cast AnimatedPart +Inochi2D.AnimatedPart_Class
return AnimatedPart
