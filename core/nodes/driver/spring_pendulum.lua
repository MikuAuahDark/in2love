local path = (...):sub(1, -string.len(".core.nodes.driver.spring_pendulum") - 1)

local love = require("love")

---@type Inochi2D.PhysicsSystem
local PhysicsSystem = require(path..".phys.system")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class (exact) Inochi2D.SpringPendulum: Inochi2D.PhysicsSystem
---@field package driver Inochi2D.SimplePhysics
---@field private bob In2LOVE.vec2
---@field private dBob In2LOVE.vec2
local SpringPendulum = PhysicsSystem:extend()

---@param driver Inochi2D.SimplePhysics
function SpringPendulum:new(driver)
	PhysicsSystem.new(self)

	self.driver = driver
	self.bob = {driver.anchor[1], driver.anchor[2] + driver.length}
	self.dBob = {0, 0}

	self:addVariable(self.bob)
	self:addVariable(self.dBob)
end

---@param t number
function SpringPendulum:eval(t)
	self:setD(self.bob, self.dBob)

	-- These are normalized vs. mass
	local springKsqrt = self.driver.frequency * 2 * math.pi
	local springK = springKsqrt * springKsqrt

	local g = self.driver:getGravity()
	local restLength = self.driver.length - g / springK

	local offPos = {
		self.bob[1] - self.driver.anchor[1],
		self.bob[2] - self.driver.anchor[2]
	}
	local offPosNorm = Util.vecNormalize(offPos)

	local lengthRatio = g / self.driver.length
	local critDampAngle = 2 * math.sqrt(lengthRatio)
	local critDampLength = 2 * springKsqrt

	local dist = Util.vec2Distance(driver.anchor, self.bob)
	local ddBob = {
		0 - offPosNorm[1] * (dist - restLength) * springK,
		g - offPosNorm[2] * (dist - restLength) * springK,
	}

	local dBobRotX = self.dBob[1] * offPosNorm[2] + self.dBob[2] * offPosNorm[1]
	local dBobRotY = self.dBob[2] * offPosNorm[2] - self.dBob[1] * offPosNorm[1]
	local ddBobRotX = dBobRotX * self.driver.angleDamping * critDampAngle
	local ddBobRotY = dBobRotY * self.driver.lengthDamping * critDampLength
	ddBob[1] = ddBob[1] + ddBobRotX * offPosNorm[2] - dBobRotY * offPosNorm[1]
	ddBob[2] = ddBob[2] + ddBobRotY * offPosNorm[2] + dBobRotX * offPosNorm[1]

	self:setD(self.dBob, ddBob)
end

---@param h number
function SpringPendulum:tick(h)
	PhysicsSystem.tick(self, h)
	self.driver.output[1], self.driver.output[2] = self.bob[1], self.bob[2]
end

---@param trans love.Transform?
function SpringPendulum:drawDebug(trans)
	love.graphics.push("all")
	if trans then
		love.graphics.applyTransform(trans)
	end
	love.graphics.setLineWidth(3)
	love.graphics.setColor(1, 0, 1, 1)
	love.graphics.line(
		self.driver.anchor[1], self.driver.anchor[2],
		self.bob[1], self.bob[2]
	)
	love.graphics.pop()
end

function SpringPendulum:updateAnchor()
	self.bob[1] = self.driver.anchor[1]
	self.bob[2] = self.driver.anchor[2] + self.driver.length
end

---@alias Inochi2D.SpringPendulum_Class Inochi2D.SpringPendulum
---| fun(driver:Inochi2D.SimplePhysics):Inochi2D.SpringPendulum
---@cast SpringPendulum +Inochi2D.SpringPendulum_Class
return SpringPendulum
