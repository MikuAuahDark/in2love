local path = (...):sub(1, -string.len(".core.automation") - 1)

---@type Inochi2D.AutomationFactory
local AutomationFactory = require(path..".core.automation.factory")
---@type Inochi2D.Automation_Class
local Automation = require(path..".core.automation.automation")
---@type Inochi2D.PhysicsAutomation_Class
local PhysicsAutomation = require(path..".core.automation.physics")
---@type Inochi2D.SineAutomation_Class
local SineAutomation = require(path..".core.automation.sine")

---@class Inochi2D.AutomationModule
local AutomationModule = {
	inInstantiateAutomation = AutomationFactory.inInstantiateAutomation,
	inHasAutomationType = AutomationFactory.inHasAutomationType,
	Automation = Automation,
	PhysicsAutomation = PhysicsAutomation,
	SineAutomation = SineAutomation
}

return AutomationModule
