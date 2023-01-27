---@diagnostic disable: missing-return
---@class Inochi2D.Object
local Object = {}

---@generic T: Inochi2D.Object
---@param obj T
---@return T
function Object.extend(obj)
end

---@param other any
---@return boolean
function Object:is(other)
end
