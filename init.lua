local path = (...)

local love = require("love")
assert(love.graphics, "love.graphics is required")

---@type Inochi2D.FmtModule
local FmtModule = require(path..".fmt")

---@class Inochi2D
local Inochi2D = {
	inLoadPuppet = FmtModule.inLoadPuppet
}

return Inochi2D
