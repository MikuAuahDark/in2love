local path = (...):sub(1, -string.len(".core.automation.Automation") - 1)

local love = require("love")

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.AutomationBinding_Class
local AutomationBinding = require(path..".core.automation.binding")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class Inochi2D.Automation: Inochi2D.Object, Inochi2D.ISerializable
---@field private parent Inochi2D.Puppet
---@field protected bindings Inochi2D.AutomationBinding[]
---@field public name string Human readable name of automation
---@field public enabled boolean Whether the automation is enabled
---@field public typeId string Type ID of the automation
local Automation = Object:extend()

---Instantiates a new Automation
---@param puppet Inochi2D.Puppet
function Automation:new(puppet)
	self.parent = puppet
	self.bindings = {}
	self.name = ""
	self.enabled = true
	self.typeId = ""
end

---Helper function to remap range from 0.0-1.0 to min-max
---@param value number
---@param range In2LOVE.vec2
function Automation:remapRange(value, range)
	return range[1] + value * (range[2] - range[1])
end

---Called on update to update a single binding.
---
---Unlike the original Inochi2D where you get delta time through deltaTime(), it's passed as parameter instead.
---Use binding.range to get the range to apply the automation within.
---@param dt number Delta time
function Automation:onUpdate(dt)
end

---Adds a binding
function Automation:bind(binding)
	self.bindings[#self.bindings+1] = binding
end

---Finalizes the loading of the automation
---@param parent Inochi2D.Puppet
function Automation:finalize(parent)
	self.parent = parent

	for _, binding in ipairs(self.bindings) do
		binding:finalize(parent)
	end
end

---Updates and applies the automation to all the parameters that this automation is bound to
---@param dt number?
function Automation:update(dt)
	if self.enabled then
		local delta = dt or love.timer.getDelta()
		self:onUpdate(delta)
	end
end

function Automation:serialize()
	return {
		type = self.typeId,
		name = self.name,
		bindings = Util.serializeArray(self.bindings)
	}
end

function Automation:deserialize(t)
	self.name = assert(t.name)

	for _, b in ipairs(t.bindings) do
		local binding = AutomationBinding()
		binding:deserialize(b)
		self.bindings[#self.bindings+1] = binding
	end
end

---@alias Inochi2D.Automation_Class Inochi2D.Automation
---| fun(parent:Inochi2D.Puppet):Inochi2D.Automation
---@cast Automation +Inochi2D.Automation_Class
return Automation
