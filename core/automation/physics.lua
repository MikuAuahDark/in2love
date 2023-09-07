local path = (...):sub(1, -string.len(".core.automation.physics") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.Automation_Class
local Automation = require(path..".core.automation.automation")
---@type Inochi2D.AutomationFactory
local Factory = require(path..".core.automation.factory")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class Inochi2D.VerletNode: Inochi2D.Object, Inochi2D.ISerializable
---@field public distance number
---@field public position In2LOVE.vec2
---@field public oldPosition In2LOVE.vec2
local VerletNode = Object:extend()

---@param pos In2LOVE.vec2?
function VerletNode:new(pos)
	local x, y = 0, 0
	if pos then
		x, y = pos[1], pos[2]
	end

	self.distance = 1
	self.position = {x, y}
	self.oldPosition = {x, y}
end

function VerletNode:serialize()
	return {
		distance = self.distance,
		position = self.position,
		old_position = self.oldPosition
	}
end

function VerletNode:deserialize(t)
	self.distance = assert(t.distance)

	local p = assert(t.position)
	self.position[1], self.position[2] = p[1], p[2]

	p = assert(t.old_position)
	self.oldPosition[1], self.oldPosition[2] = p[1], p[2]
end

---@cast VerletNode +fun(pos:In2LOVE.vec2?):Inochi2D.VerletNode

---@class Inochi2D.PhysicsAutomation: Inochi2D.Automation
---@field public nodes Inochi2D.VerletNode[] A node in the internal verlet simulation
---@field public damping number Amount of damping to apply to movement
---@field public bounciness number How bouncy movement should be. 1 = default bounciness
---@field public gravity number Gravity to apply to each link
local PhysicsAutomation = Automation:extend()

function PhysicsAutomation:new(parent)
	Automation.new(self, parent)

	self.typeId = "physics"
	self.nodes = {}
	self.damping = 0.05
	self.bounciness = 1
	self.gravity = 20
end

---@param dt number
---@param i integer
---@param binding Inochi2D.AutomationBinding
function PhysicsAutomation:simulate(dt, i, binding)
	local node = self.nodes[i]

	local tmpX, tmpY = node.position[1], node.position[2]
	-- node.position = (node.position - node.oldPosition) + vec2(0, gravity) * (deltaTime * deltaTime) * bounciness;
	node.position[1] = tmpX - node.oldPosition[1]
	node.position[2] = (tmpY - node.oldPosition[2]) + self.gravity * dt * dt * self.bounciness
	node.oldPosition[1], node.oldPosition[2] = tmpX, tmpY
end

function PhysicsAutomation:constrain()
	for i = 1, #self.nodes - 1 do
		local node1 = self.nodes[i]
		local node2 = self.nodes[i + 1]

		-- idx 0 = first node in param, this always is the reference node.
		-- We base our "hinge" of the value of this reference value
		if i == 1 then
			node1.position[1], node1.position[2] = self.bindings[i]:getAxisValue(), 0
		end

		-- Then we calculate the distance of the difference between
		-- node 1 and 2, 
		local diffX = node1.position[1] - node2.position[1]
		local diffY = node1.position[2] - node2.position[2]
		local dist = Util.vec2Distance(node1.position, node2.position)
		local diff = 0

		-- We need the distance to be larger than 0 so that
		-- we don't get division by zero problems.
		if dist > 0 then
			-- Node2 decides how far away it wants to be from Node1
			diff = (node2.distance - dist) / dist
		end

		-- Apply out fancy new link
		local tx = diffX * 0.5 * diff
		local ty = diffY * 0.5 * diff
		node1.position[1] = node1.position[1] + tx
		node1.position[2] = node1.position[2] + ty
		node2.position[1] = node2.position[1] - tx
		node2.position[2] = node2.position[2] - ty

		-- Clamp so that we don't start flopping above the hinge above us
		node2.position[2] = Util.clamp(node2.position[2], node1.position[2], math.huge)
	end
end

function PhysicsAutomation:onUpdate(dt)
	if #self.bindings > 1 then
		-- simulate each link in our chain
		for i, binding in ipairs(self.bindings) do
			self:simulate(dt, i, binding)
		end

		-- Constrain values
		for _ = 1, 4 + #self.bindings * 2 do
			self:constrain()
		end

		-- Clamp and apply everything to be within range
		for i, node in ipairs(self.nodes) do
			local b = self.bindings[i]
			node.position[1] = Util.clamp(node.position[1], b.range[1], b.range[2])
			b:addAxisOffset(node.position[1])
		end
	end
end

function PhysicsAutomation:serialize()
	local result = Automation.serialize(self)
	result.nodes = Util.serializeArray(self.nodes)
	result.damping = self.damping
	result.bounciness = self.bounciness
	result.gravity = self.gravity
	return result
end

function PhysicsAutomation:deserialize(t)
	Automation.deserialize(self, t)

	for _, node in ipairs(t.nodes) do
		local n = VerletNode()
		n:deserialize(node)
		self.nodes[#self.nodes+1] = n
	end

	self.damping = assert(t.damping)
	self.bounciness = assert(t.bounciness)
	self.gravity = assert(t.gravity)
end

---Adds a binding
---@param binding Inochi2D.AutomationBinding
function PhysicsAutomation:bind(binding)
	Automation.bind(self, binding)
	self.nodes[#self.nodes+1] = VerletNode({0, 1})
end

Factory.inRegisterAutomationType("physics", PhysicsAutomation)
---@alias Inochi2D.PhysicsAutomation_Class Inochi2D.PhysicsAutomation
---| fun(parent:Inochi2D.Puppet):Inochi2D.PhysicsAutomation
---@cast PhysicsAutomation +Inochi2D.PhysicsAutomation_Class
return PhysicsAutomation
