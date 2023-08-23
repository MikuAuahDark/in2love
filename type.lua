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

---@class Inochi2D.ISerializable
local ISerializable = {}

---@return table<string, any>
function ISerializable:serialize()
end

---@param t table<string, any>
function ISerializable:deserialize(t)
end
