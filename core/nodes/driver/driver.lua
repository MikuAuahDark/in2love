local path = (...):sub(1, -string.len(".core.nodes.driver.driver") - 1)

---@type Inochi2D.Node_Class
local Node = require(path..".core.nodes.node_class")

---@alias Inochi2D.PhysicsModel
---Rigid pendulum
---| "Pendulum"
---Springy pendulum
---| "SpringPendulum"

---@alias Inochi2D.ParamMapMode
---| "AngleLength"
---| "XY"

---@class (exact) Inochi2D.Driver: Inochi2D.Node
local Driver = Node:extend()

---Constructs a new Driver node
---@param uuid integer
---@param parent Inochi2D.Node?
function Driver:new(uuid, parent)
	Node.new(self, uuid, parent)
end

---@return Inochi2D.Parameter[]
function Driver:getAffectedParameters()
	return {}
end

---@param param Inochi2D.Parameter
function Driver:affectsParameter(param)
	for _, p in ipairs(self:getAffectedParameters()) do
		if p.uuid == param.uuid then
			return true
		end
	end

	return false
end

---@param dt number?
function Driver:updateDriver(dt)
	error("need to override updateDriver")
end

function Driver:reset()
	error("need to override reset")
end

return Driver
