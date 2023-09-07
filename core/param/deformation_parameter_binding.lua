local path = (...):sub(1, -string.len(".core.param.deformation_parameter_binding") - 1)

---@type Inochi2D.ParameterBindingImpl_Class
local ParameterBindingImpl = require(path..".core.param.parameter_binding_impl")
---@type Inochi2D.Deformation_Class
local Deformation = require(path..".core.deformation")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class Inochi2D.DeformationParameterBinding: Inochi2D.ParameterBindingImpl
---@field public values Inochi2D.Deformation[][] The value at each 2D keypoint
local DeformationParameterBinding = ParameterBindingImpl:extend()

---@param parameter Inochi2D.Parameter
---@param targetNode Inochi2D.Node?
---@param paramName string?
function DeformationParameterBinding:new(parameter, targetNode, paramName)
	ParameterBindingImpl.new(self, parameter, targetNode, paramName)
end

---@param point In2LOVE.vec2
---@param offsets In2LOVE.vec2[]
function DeformationParameterBinding:update(point, offsets)
	self.isSet_[point[1] + 1][point[2] + 1] = true
	self.values[point[1] + 1][point[2] + 1].vertexOffsets = Util.copyArray(offsets)
	self:reInterpolate()
end

function DeformationParameterBinding:deserialize(t)
	ParameterBindingImpl.deserialize(self, t)

	for _, u in ipairs(self.values) do
		for i, v in ipairs(u) do
			local d = Deformation()
			u[i] = d:deserialize(v)
		end
	end
end

---@param value Inochi2D.Deformation
function DeformationParameterBinding:applyToTarget(value)
	assert(self.target.paramName == "deform")

	if self.target.node:is(Drawable) then
		---@type Inochi2D.Drawable
		local d = self.target.node

		d.deformStack:push(value)
	end
end

---@param i Inochi2D.Deformation
function DeformationParameterBinding:clearValue(i)
	local len = #i.vertexOffsets
	local result = {}

	if self.target.node:is(Drawable) then
		---@type Inochi2D.Drawable
		local d = self.target.node
		len = #d.vertices
	end

	for j = 1, len do
		result[j] = {0, 0}
	end

	return result
end

---@param index In2LOVE.vec2
---@param axis integer
---@param scale number
function DeformationParameterBinding:scaleValueAt(index, axis, scale)
	local vecScale = {scale, scale}

	if axis == 0 then
		vecScale[2] = 1
	elseif axis == 1 then
		vecScale[1] = 1
	elseif axis ~= -1 then
		error("Bad axis")
	end

	-- Default to just scalar scale
	self:setValue(index, self:getValue(index) * vecScale)
end

---@param other Inochi2D.Node
function DeformationParameterBinding:isCompatibleWithNode(other)
	if self.target.node:is(Drawable) and other:is(Drawable) then
		---@type Inochi2D.Drawable
		local d = self.target.node
		---@cast other Inochi2D.Drawable

		return #d.vertices == #o.vertices
	end
end

function DeformationParameterBinding:newObject()
	return Deformation()
end

function DeformationParameterBinding:getType()
	return DeformationParameterBinding
end

---@alias Inochi2D.DeformationParameterBinding_Class Inochi2D.DeformationParameterBinding
---| fun(parameter:Inochi2D.Parameter):Inochi2D.DeformationParameterBinding
---| fun(parameter:Inochi2D.Parameter,node:Inochi2D.Node,paramName:string):Inochi2D.DeformationParameterBinding
---@cast DeformationParameterBinding +Inochi2D.DeformationParameterBinding_Class
return DeformationParameterBinding
