local path = (...):sub(1, -string.len(".core.param.value_parameter_binding") - 1)

---@type Inochi2D.ParameterBindingImpl_Class
local ParameterBindingImpl = require(path..".core.param.parameter_binding_impl")

---@class Inochi2D.ValueParameterBinding: Inochi2D.ParameterBindingImpl
---@field public values number[][] The value at each 2D keypoint
local ValueParameterBinding = ParameterBindingImpl:extend()

---@param parameter Inochi2D.Parameter
---@param targetNode Inochi2D.Node?
---@param paramName string?
function ValueParameterBinding:new(parameter, targetNode, paramName)
	ParameterBindingImpl.new(self, parameter, targetNode, paramName)
end

---@param value number
function ValueParameterBinding:applyToTarget(value)
	self.target.node:setValue(self.target.paramName, value)
end

---@param i number
function ValueParameterBinding:clearValue(i)
	return self.target.node:getDefaultValue(self.target.paramName)
end

---@param index Inochi2D.vec2
---@param axis integer
---@param scale number
function ValueParameterBinding:scaleValueAt(index, axis, scale)
	-- Nodes know how to do axis-aware scaling
	self:setValue(index, self.target.node:scaleValue(self.target.paramName, self:getValue(index), axis, scale))
end

---@param other Inochi2D.Node
function ValueParameterBinding:isCompatibleWithNode(other)
	return other:hasParam(self.target.paramName)
end

function ValueParameterBinding:newObject()
	return 0.0
end

function ValueParameterBinding:getType()
	return ValueParameterBinding
end

---@alias Inochi2D.ValueParameterBinding_Class Inochi2D.ValueParameterBinding
---| fun(parameter:Inochi2D.Parameter):Inochi2D.ValueParameterBinding
---| fun(parameter:Inochi2D.Parameter,node:Inochi2D.Node,paramName:string):Inochi2D.ValueParameterBinding
---@cast ValueParameterBinding +Inochi2D.ValueParameterBinding_Class
return ValueParameterBinding
