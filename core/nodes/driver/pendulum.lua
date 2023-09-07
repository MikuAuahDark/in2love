local path = (...):sub(1, -string.len(".core.nodes.driver.pendulum") - 1)

local love = require("love")

---@type Inochi2D.PhysicsSystem
local PhysicsSystem = require(path..".phys.system")

---@class (exact) Inochi2D.Pendulum: Inochi2D.PhysicsSystem
---@field package driver Inochi2D.SimplePhysics
---@field private bob In2LOVE.vec2
---@field private angle In2LOVE.vec2
---@field private dAngle In2LOVE.vec2
local Pendulum = PhysicsSystem:extend()

---@param driver Inochi2D.SimplePhysics
function Pendulum:new(driver)
	PhysicsSystem.new(self)

	self.driver = driver
	self.bob = {0, 0}
	self.angle = {0, 0}
	self.dAngle = {0, 0}

	self:addVariable(self.angle)
	self:addVariable(self.dAngle)
end

---@param t number
function Pendulum:eval(t)
	self:setD(self.angle, {self.dAngle[1], 0})
	local lengthRatio = self.driver:getGravity() / self.driver.length
	local critDamp = 2 * math.sqrt(lengthRatio)
	local dd = -lengthRatio * math.sin(self.angle[1])
	dd = dd - self.dAngle[1] * self.driver.angleDamping * critDamp
	self:setD(self.dAngle, {dd, 0})
end

---@param h number
function Pendulum:tick(h)
	-- Compute the angle against the updated anchor position
	local dBobX = self.bob[1] - self.driver.anchor[1]
	local dBobY = self.bob[2] - self.driver.anchor[2]
	self.angle[1] = math.atan2(-dBobX, dBobY)

	-- Run the pendulum simulation in terms of angle
	PhysicsSystem.tick(self, h)

	-- Update the bob position at the new angle
	dBobX = -math.sin(self.angle[1])
	dBobY = math.cos(self.angle[1])

	self.bob[1] = self.driver.anchor[1] + dBobX * self.driver.length
	self.bob[2] = self.driver.anchor[2] + dBobX * self.driver.length
	self.driver.output[1], self.driver.output[2] = self.bob[1], self.bob[2]
end

---@param trans love.Transform?
function Pendulum:drawDebug(trans)
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

function Pendulum:updateAnchor()
	self.bob[1] = self.driver.anchor[1]
	self.bob[2] = self.driver.anchor[2] + self.driver.length
end

---@alias Inochi2D.Pendulum_Class Inochi2D.Pendulum
---| fun(driver:Inochi2D.SimplePhysics):Inochi2D.Pendulum
---@cast Pendulum +Inochi2D.Pendulum_Class
return Pendulum
