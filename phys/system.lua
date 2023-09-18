local path = (...):sub(1, -string.len(".phys.system") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---In2LOVE notes: In Lua, all numbers are passed by (and only by) value.
---This means it needs to be encapsulated as vec2.
---@class (exact) Inochi2D.PhysicsSystem: Inochi2D.Object
---@field private variableMap table<In2LOVE.vec2, integer>
---@field private refs In2LOVE.vec2[]
---@field private derivative number[]
---@field private t number
local PhysicsSystem = Object:extend()

function PhysicsSystem:new()
	self.variableMap = {}
	self.refs = {}
	self.derivative = {}
	self.t = 0
end

---Add a vec2 variable to the simulation
---@param var In2LOVE.vec2
function PhysicsSystem:addVariable(var)
	self.refs[#self.refs+1] = var
	local index = #self.refs
	self.variableMap[var] = index

	return index
end

---Set the derivative of a vec2 variable (solver input)
---@param var In2LOVE.vec2|integer
---@param value In2LOVE.vec2
function PhysicsSystem:setD(var, value)
	if type(var) ~= "number" then
		var = assert(self.variableMap[var])
	end

	local idx = (var - 1) * 2
	self.derivative[idx + 1] = value[1]
	self.derivative[idx + 2] = value[2]
end

function PhysicsSystem:getState()
	---@type number[]
	local vals = {}

	for _, ptr in ipairs(self.refs) do
		vals[#vals+1] = ptr[1]
		vals[#vals+2] = ptr[2]
	end

	return vals
end

function PhysicsSystem:setState(vals)
	for i, ptr in ipairs(self.refs) do
		local idx = (i - 1) * 2
		ptr[1] = vals[idx + 1]
		ptr[2] = vals[idx + 2]
	end
end

---Evaluate the simulation at a given time
---@param t number
function PhysicsSystem:eval(t)
	error("need to override eval")
end

---Run a simulation tick (Runge-Kutta method)
---@param h number
function PhysicsSystem:tick(h)
	local cur = self:getState()
	local tmp = {}

	for i = 1, #cur do
		tmp[i] = 0
		self.derivative[i] = 0
	end
	self.derivative[#cur + 1] = nil

	self:eval(self.t)
	local k1 = Util.copyArray(self.derivative)
	local k2 = self:_doKStep(h, cur, k1, 2)
	local k3 = self:_doKStep(h, cur, k2, 2)
	local k4 = self:_doKStep(h, cur, k3, 1)

	for i = 1, #cur do
		local r = cur[i] + h * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) / 6

		if r ~= r or math.abs(r) == math.huge then
			-- Simulation failed, revert
			for j = 1, #cur do
				local ref = self.refs[math.floor((j - 1) / 2) + 1]
				ref[j % 2 + 1] = cur[j]
			end

			break
		end

		local ref = self.refs[math.floor((i - 1) / 2) + 1]
		ref[i % 2 + 1] = r
	end

	self.t = self.t + h
end

---@param h number
---@param cur number[]
---@param kold number[]
---@param div number
---@private
function PhysicsSystem:_doKStep(h, cur, kold, div)
	for i = 1, #cur do
		local ref = self.refs[math.floor((i - 1) / 2) + 1]
		ref[i % 2 + 1] = cur[i] + h * kold[i] / 2
	end
	self:eval(self.t + h / div)
	return Util.copyArray(self.derivative)
end

---Updates the anchor for the physics system
function PhysicsSystem:updateAnchor()
	error("need to override updateAnchor")
end

---@param trans love.Transform?
function PhysicsSystem:drawDebug(trans)
	error("need to override drawDebug")
end

return PhysicsSystem
