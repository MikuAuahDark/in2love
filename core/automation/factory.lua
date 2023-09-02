---@class Inochi2D.AutomationFactory
local AutomationFactory = {}

---@type table<string, Inochi2D.Automation>
local registered = {}

---@param name string
---@param t Inochi2D.Automation
function AutomationFactory.inRegisterAutomationType(name, t)
	registered[name] = t
end

---Instantiates automation
---@param name string
---@param parent Inochi2D.Puppet
---@return Inochi2D.Automation
---@overload fun(name:"physics",parent:Inochi2D.Puppet):Inochi2D.PhysicsAutomation
---@overload fun(name:"sine",parent:Inochi2D.Puppet):Inochi2D.SineAutomation
function AutomationFactory.inInstantiateAutomation(name, parent)
	return registered[name](parent)
end

---Gets whether a node type is present in the factories
---@param name string
function AutomationFactory.inHasAutomationType(name)
	return not not registered[name]
end

return AutomationFactory
