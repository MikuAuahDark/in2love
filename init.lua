local path = (...)

local love = require("love")
assert(love.graphics, "love.graphics is required")

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
require(path..".core.nodes")

---@type Inochi2D.FmtModule
local FmtModule = require(path..".fmt")
require(path..".core.nodes")

---@class Inochi2D
local Inochi2D = {
	inLoadPuppet = FmtModule.inLoadPuppet,
	isObject = Object.is
}

return Inochi2D
