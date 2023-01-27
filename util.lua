local path = (...):sub(1, -string.len(".util") - 1)

local sort = require(path..".lib.sort")

---@class Inochi2D.Util
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

return Util
