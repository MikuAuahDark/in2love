local path = (...):sub(1, -string.len(".core.automation.binding") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.Parameter_Class
local Parameter = require(path..".core.param.parameter")

---@class Inochi2D.AutomationBinding: Inochi2D.Object
---@field public paramId string Used for serialization. Name of parameter
---@field public param Inochi2D.Parameter Parameter to bind to
---@field public axis integer Axis to bind to (0 = X; 1 = Y)
---@field public range Inochi2D.vec2 Min/max range of binding
local AutomationBinding = Object:extend()
local NAN = 0/0

function AutomationBinding:new()
	self.paramId = ""
	self.param = Parameter()
	self.axis = 0
	self.range = {0, 0}
end

---Gets the value at the specified axis
function AutomationBinding:getAxisValue()
	return self.param.value[self.axis + 1] or NAN
end

---Sets axis value (WITHOUT REMAPPING)
function AutomationBinding:setAxisValue(value)
	assert(self.axis == 0 or self.axis == 1)
	self.param.value[self.axis + 1] = value
end

---Sets axis value (WITHOUT REMAPPING)
function AutomationBinding:addAxisOffset(value)
	assert(self.axis == 0 or self.axis == 1)
	self.param.value[self.axis + 1] = self.param.value[self.axis + 1] + value
end

---Serializes a parameter
function AutomationBinding:serialize()
	return {
		param = self.param.name,
		axis = self.axis,
		range = self.range
	}
end

---Deserializes a parameter
function AutomationBinding:deserialize(t)
	self.paramId = assert(t.param)
	self.axis = assert(t.axis)

	-- Was supposed to look at t.axis in the original code. Typo?
	local p = assert(t.range)
	self.range[1], self.range[2] = p[1], p[2]
end

---@param puppet Inochi2D.Puppet
function AutomationBinding:finalize(puppet)
	for _, parameter in ipairs(puppet.parameters) do
		if parameter.name == self.paramId then
			self.param = parameter
			return
		end
	end
end

---@alias Inochi2D.AutomationBinding_Class Inochi2D.AutomationBinding
---| fun():Inochi2D.AutomationBinding
---@cast AutomationBinding +Inochi2D.AutomationBinding_Class
return AutomationBinding
