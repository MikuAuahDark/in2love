local path = (...):sub(1, -string.len(".core.nodes.driver") - 1)

---@class Inochi2D.DriverModule
local DriverModule = {
	---@type Inochi2D.Driver
	Driver = require(path..".core.nodes.driver.driver"),
	---@type Inochi2D.SimplePhysics_Class
	SimplePhysics = require(path..".core.nodes.driver.simplephysics"),
	---@type Inochi2D.Pendulum_Class
	Pendulum = require(path..".core.nodes.driver.pendulum"),
	---@type Inochi2D.SpringPendulum_Class
	SpringPendulum = require(path..".core.nodes.driver.pendulum"),
}

return DriverModule
