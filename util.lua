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

function Util.isArray(t)
	if type(t) ~= "table" then
		return false
	end

	for k in pairs(t) do
		if type(k) ~= "number" then
			return false
		end
	end

	return true
end

---@generic T
---@param tab T[]
function Util.serializeArray(tab)
	local result = {}

	for _, v in ipairs(tab) do
		if type(v) == "table" then
			if type(v.serialize) == "function" then
				---@cast v Inochi2D.ISerializable
				result[#result + 1] = v:serialize()
			elseif Util.isArray(v) then
				result[#result+1] = Util.serializeArray(v)
			else
				result[#result+1] = v
			end
		else
			result[#result+1] = v
		end
	end

	return result
end

---@generic T
---@param tab table<string,T>
function Util.serializeDictionary(tab)
	local result = {}

	for k, v in pairs(tab) do
		if type(v) == "table" then
			if type(v.serialize) == "function" then
				---@cast v Inochi2D.ISerializable
				result[k] = v:serialize()
			elseif Util.isArray(v) then
				result[k] = Util.serializeArray(v)
			else
				result[k] = v
			end
		else
			result[k] = v
		end
	end

	return result
end

---@generic T
---@param tab T[]
function Util.reverseArray(tab)
	local len = #tab
	for i = 1, math.floor(len / 2) do
		tab[i], tab[len - i + 1] = tab[len - i + 1], tab[i]
	end
end

---@generic T
---@param tab T[]
---@param duplicator function?
---@return T[]
function Util.copyArray(tab, duplicator)
	local result = {}

	if duplicator then
		for k, v in ipairs(tab) do
			if type(v) == "table" then
				result[k] = duplicator(v, duplicator)
			end
		end
	else
		for k, v in ipairs(tab) do
			result[k] = v
		end
	end

	return result
end

---@generic T
---@param a T
---@param b T
---@param t number
---@return T
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

function Util.isVec2(value)
	if type(value) == "table" then
		return type(value[1]) == "number" and type(value[2]) == "number"
	end

	return false
end

---@param a In2LOVE.vec2
---@param b In2LOVE.vec2
function Util.vec2Distance(a, b)
	return math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2)
end

---https://www.tutorialspoint.com/cplusplus-program-to-compute-cross-product-of-two-vectors
---@param a In2LOVE.vec3
---@param b In2LOVE.vec3
function Util.vec3Cross(a, b)
	return {
		a[2] * b[3] - a[3] * b[2],
		a[3] * b[1] - a[1] * b[3],
		a[1] * b[2] - a[2] * b[1]
	}
end

---@param vec In2LOVE.vec2
---@return In2LOVE.vec2
---@overload fun(vec:In2LOVE.vec3):In2LOVE.vec3
---@overload fun(vec:In2LOVE.vec4):In2LOVE.vec4
function Util.vecNormalize(vec)
	local length2 = vec[1] * vec[1] + vec[2] * vec[2]

	if vec[3] then
		length2 = length2 + vec[3] * vec[3]
	end

	if vec[4] then
		length2 = length2 + vec[4] * vec[4]
	end

	local length = math.sqrt(length2)
	if length == 0 then
		return vec
	elseif vec[4] then
		return {vec[1] / length, vec[2] / length, vec[3] / length, vec[4] / length}
	elseif vec[3] then
		return {vec[1] / length, vec[2] / length, vec[3] / length}
	else
		return {vec[1] / length, vec[2] / length}
	end
end

return Util
