local path = (...):sub(1, -string.len(".core.deformation") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class Inochi2D.Deformation: Inochi2D.Object, Inochi2D.ISerializable
---@field public vertexOffsets Inochi2D.vec2[]
local Deformation = Object:extend()

---@param value Inochi2D.Deformation?
function Deformation:new(value)
	self.vertexOffsets = value and Util.copyArray(value.vertexOffsets) or {}
end

---@param points Inochi2D.vec2[]
function Deformation:update(points)
	self.vertexOffsets = Util.copyArray(points)
end

---@alias Inochi2D.Deformation_Class Inochi2D.Deformation
---| fun():Inochi2D.Deformation
---| fun(other:Inochi2D.Deformation):Inochi2D.Deformation
---@cast Deformation +Inochi2D.Deformation_Class

function Deformation:__unm()
	local result = Deformation()

	for _, v in ipairs(self.vertexOffsets) do
		result.vertexOffsets[#result.vertexOffsets + 1] = {-v[1], -v[2]}
	end

	return result
end

---@param lhs Inochi2D.Deformation|Inochi2D.vec2|number
---@param rhs Inochi2D.Deformation|Inochi2D.vec2|number
---@return Inochi2D.Deformation, Inochi2D.Deformation|Inochi2D.vec2|number, boolean
local function resolveOrderOfOperation(lhs, rhs)
	---@diagnostic disable-next-line: param-type-mismatch
	if Object.is(lhs, Deformation) then
		---@cast lhs Inochi2D.Deformation
		return lhs, rhs, false
	else
		---@diagnostic disable-next-line: param-type-mismatch
		if Object.is(rhs, Deformation) then
			---@cast rhs Inochi2D.Deformation
			return rhs, lhs, true
		else
			error("invalid type, expected Deformation, vec2, or number")
		end
	end
end

---@param lhs Inochi2D.Deformation|Inochi2D.vec2|number
---@param rhs Inochi2D.Deformation|Inochi2D.vec2|number
function Deformation.__mul(lhs, rhs)
	lhs, rhs = resolveOrderOfOperation(lhs, rhs)
	local result = Deformation()

	---@diagnostic disable-next-line: param-type-mismatch
	if Object.is(rhs, Deformation) then
		---@cast rhs Inochi2D.Deformation
		assert(#lhs.vertexOffsets >= #rhs.vertexOffsets)

		for i = 1, #lhs.vertexOffsets do
			local l = lhs.vertexOffsets[i]
			local r = rhs.vertexOffsets[i]
			result.vertexOffsets[i] = {l[1] * r[1], l[2] * r[2]}
		end
	elseif Util.isVec2(rhs) then
		---@cast rhs Inochi2D.vec2
		for i, l in ipairs(lhs.vertexOffsets) do
			result.vertexOffsets[i] = {l[1] * rhs[1], l[2] * rhs[2]}
		end
	elseif type(rhs) == "number" then
		for i, l in ipairs(lhs.vertexOffsets) do
			result.vertexOffsets[i] = {l[1] * rhs, l[2] * rhs}
		end
	else
		error("invalid type, expected Deformation, vec2, or number")
	end

	return result
end

---@param lhs Inochi2D.Deformation|Inochi2D.vec2|number
---@param rhs Inochi2D.Deformation|Inochi2D.vec2|number
function Deformation.__add(lhs, rhs)
	lhs, rhs = resolveOrderOfOperation(lhs, rhs)
	local result = Deformation()

	---@diagnostic disable-next-line: param-type-mismatch
	if Object.is(rhs, Deformation) then
		---@cast rhs Inochi2D.Deformation
		assert(#lhs.vertexOffsets >= #rhs.vertexOffsets)

		for i = 1, #lhs.vertexOffsets do
			local l = lhs.vertexOffsets[i]
			local r = rhs.vertexOffsets[i]
			result.vertexOffsets[i] = {l[1] + r[1], l[2] + r[2]}
		end
	elseif Util.isVec2(rhs) then
		---@cast rhs Inochi2D.vec2
		for i, l in ipairs(lhs.vertexOffsets) do
			result.vertexOffsets[i] = {l[1] + rhs[1], l[2] + rhs[2]}
		end
	elseif type(rhs) == "number" then
		for i, l in ipairs(lhs.vertexOffsets) do
			result.vertexOffsets[i] = {l[1] + rhs, l[2] + rhs}
		end
	else
		error("invalid type, expected Deformation, vec2, or number")
	end

	return result
end

---@param lhs Inochi2D.Deformation|Inochi2D.vec2|number
---@param rhs Inochi2D.Deformation|Inochi2D.vec2|number
function Deformation.__sub(lhs, rhs)
	local isFlip
	lhs, rhs, isFlip = resolveOrderOfOperation(lhs, rhs)
	local result = Deformation()

	-- Note: a - b != b - a. It's a - b == -b + a.
	---@diagnostic disable-next-line: param-type-mismatch
	if Object.is(rhs, Deformation) then
		---@cast rhs Inochi2D.Deformation
		assert(#lhs.vertexOffsets >= #rhs.vertexOffsets)

		if isFlip then
			for i = 1, #lhs.vertexOffsets do
				local l = lhs.vertexOffsets[i]
				local r = rhs.vertexOffsets[i]
				result.vertexOffsets[i] = {r[1] - l[1], r[2] - l[2]}
			end
		else
			for i = 1, #lhs.vertexOffsets do
				local l = lhs.vertexOffsets[i]
				local r = rhs.vertexOffsets[i]
				result.vertexOffsets[i] = {l[1] - r[1], l[2] - r[2]}
			end
		end
	elseif Util.isVec2(rhs) then
		---@cast rhs Inochi2D.vec2
		if isFlip then
			for i, l in ipairs(lhs.vertexOffsets) do
				result.vertexOffsets[i] = {rhs[1] - l[1], rhs[2] - l[2]}
			end
		else
			for i, l in ipairs(lhs.vertexOffsets) do
				result.vertexOffsets[i] = {l[1] - rhs[1], l[2] - rhs[2]}
			end
		end
	elseif type(rhs) == "number" then
		if isFlip then
			for i, l in ipairs(lhs.vertexOffsets) do
				result.vertexOffsets[i] = {rhs - l[1], rhs - l[2]}
			end
		else
			for i, l in ipairs(lhs.vertexOffsets) do
				result.vertexOffsets[i] = {l[1] - rhs, l[2] - rhs}
			end
		end
	else
		error("invalid type, expected Deformation, vec2, or number")
	end

	return result
end

function Deformation:serialize()
	local result = {}

	for i, v in ipairs(self.vertexOffsets) do
		result[i] = {v[1], v[2]}
	end

	return result
end

function Deformation:deserialize(t)
	for i, v in ipairs(t) do
		self.vertexOffsets[i] = {v[1], v[2]}
	end
end

return Deformation
