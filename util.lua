local path = (...):sub(1, -string.len(".util") - 1)

local sort = require(path..".lib.sort")

---@class Inochi2D.UtilModule
local Util = {}

local hasClear, clear = pcall(require, "table.clear")
if hasClear then
	Util.clearTable = clear
else
	---@param tab table
	function Util.clearTable(tab)
		for k in pairs(tab) do
			tab[k] = nil
		end
	end
end

---@generic T
---@param t T[]
---@param less? fun(a: T, b: T):boolean
---@param stable? boolean
function Util.sort(t, less, stable)
	if stable then
		return sort.stable_sort(t, less)
	else
		return sort.unstable_sort(t, less)
	end
end

---@generic T
---@param t T[]
---@param v T
function Util.index(t, v)
	for i, a in ipairs(t) do
		if a == v then
			return i
		end
	end

	return nil
end

---@generic T
---@param tab T[]
function Util.serializeArray(tab)
	local result = {}
	for _, v in ipairs(tab) do
		result[#result + 1] = v:serialize()
	end

	return result
end

---@generic T
---@param tab table<string,T>
function Util.serializeDictionary(tab)
	local result = {}
	for k, v in ipairs(tab) do
		result[k] = v:serialize()
	end

	return result
end

---@param a number
---@param b number
---@param t number
function Util.lerp(a, b, t)
	return a * (1 - t) + b * t
end

---Hermite lerpolation (cubic hermite spline).
---From inmath.
---@param x number
---@param tx number
---@param y number
---@param ty number
---@param t number
function Util.hermite(x, tx, y, ty, t)
	local h1 = 2 * t ^ 3 - 3 * t ^ 2 + 1
	local h2 = -2* t ^ 3 + 3 * t ^ 2
	local h3 = t ^ 3 - 2 * t ^ 2 + t
	local h4 = t ^ 3 - t ^ 2
	return h1 * x + h3 * tx + h2 * y + h4 * ty
end

---Cubic interpolation.
---From inmath.
---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param t number
function Util.cubic(p0, p1, p2, p3, t)
	local a = -0.5 * p0 + 1.5 * p1 - 1.5 * p2 + 0.5 * p3
	local b = p0 - 2.5 * p1 + 2 * p2 - 0.5 * p3
	local c = -0.5 * p0 + 0.5 * p2
	return a * (t ^ 3) + b * (t ^ 2) + c * t + p1
end

---@param value number
---@param min number
---@param max number
function Util.clamp(value, min, max)
	return math.min(math.max(value, min), max)
end

return Util
