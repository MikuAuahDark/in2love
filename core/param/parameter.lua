local path = (...):sub(1, -string.len(".core.param.parameter") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.DeformationParameterBinding_Class
local DeformationParameterBinding = require(path..".core.param.deformation_parameter_binding")
---@type Inochi2D.ValueParameterBinding_Class
local ValueParameterBinding = require(path..".core.param.value_parameter_binding")
---@type Inochi2D.NodesPackage
local NodesPackage = require(path..".core.nodes.package")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---A parameter
---@class Inochi2D.Parameter: Inochi2D.Object, Inochi2D.ISerializable
---@field public uuid integer Unique ID of parameter
---@field public name string Name of the parameter
---@field public indexableName string Optimized indexable name generated at runtime. DO NOT SERIALIZE THIS.
---@field public active boolean Whether this parameter updates the model
---@field public offset Inochi2D.vec2 Automator calculated offset to apply
---@field public value Inochi2D.vec2 The current parameter value
---@field public defaults Inochi2D.vec2 The default value
---@field public isVec2 boolean Whether the parameter is 2D
---@field public min Inochi2D.vec2 The parameter's minimum bounds
---@field public max Inochi2D.vec2 The parameter's maximum bounds
---@field public axisPoints number[][] Position of the keypoints along each axis
---@field public bindings Inochi2D.ParameterBinding[] Binding to targets
local Parameter = Object:extend()

---Create new parameter
---@param name string?
---@param isVec2 boolean?
function Parameter:new(name, isVec2)
	self.uuid = 4294967295
	self.name = name or ""
	self.indexableName = ""
	self.active = true
	self.offset = {0, 0}
	self.value = {0, 0}
	self.defaults = {0, 0}
	self.isVec2 = not not self.isVec2
	self.min = {0, 0}
	self.max = {1, 1}
	self.axisPoints = {{0, 1}, {0, 1}}
	self.bindings = {}

	if not isVec2 then
		self.axisPoints[2] = {0}
	end

	if name then
		self:makeIndexable()
	end

	-- HACK: Clear UUID on destructor
	self.uuidCleaner = newproxy(true)
	getmetatable(self.uuidCleaner).__gc = function()
		NodesPackage.inUnloadUUID(self.uuid)
	end
end

---Gets the value normalized to the internal range (0.0->1.0)
---
---Sets the value normalized up from the internal range (0.0->1.0)
---to the user defined range.
---@param value Inochi2D.vec2
---@overload fun(self:Inochi2D.Parameter):Inochi2D.vec2
---@overload fun(self:Inochi2D.Parameter,value:Inochi2D.vec2)
function Parameter:normalizedValue(value)
	if value then
		self.value[1] = value[1] * (self.max[1] - self.min[1]) + self.min[1]
		self.value[2] = value[2] * (self.max[2] - self.min[2]) + self.min[2]
	else
		return self:mapValue(self.value)
	end
end

---@alias Inochi2D.Parameter_Class Inochi2D.Parameter
---| fun():Inochi2D.Parameter
---| fun(name:string,isVec2:boolean):Inochi2D.Parameter
---@cast Parameter +Inochi2D.Parameter_Class

---Clone this parameter
function Parameter:clone()
	local newParam = Parameter(self.name.." (Copy)", self.isVec2)

	newParam.min = {self.min[1], self.min[2]}
	newParam.max = {self.max[1], self.max[2]}
	newParam.axisPoints = {}
	for i, v in ipairs(self.axisPoints) do
		local t = {}

		for i2, v2 in ipairs(v) do
			t[i2] = v2
		end

		newParam.axisPoints[i] = t
	end

	for _, binding in ipairs(self.bindings) do
		local newBinding = newParam:createBinding(binding:getNode(), binding:getName(), false)
		newBinding:interpolateMode(binding:interpolateMode())

		for x = 0, self:axisPointCount(0) - 1 do
			for y = 0, self:axisPointCount(1) - 1 do
				local t = {x, y}
				binding:copyKeypointToBinding(t, newBinding, t)
			end
		end

		newParam:addBinding(newBinding)
	end

	return newParam
end

---Serializes a parameter
function Parameter:serialize()
	local bindings = {}
	local result = {
		uuid = self.uuid,
		name = self.name,
		is_vec2 = self.isVec2,
		min = self.min,
		max = self.max,
		defaults = self.defaults,
		axis_points = self.axisPoints,
		bindings = bindings,
	}

	for _, binding in ipairs(self.bindings) do
		bindings[#bindings + 1] = binding:serializeSelf()
	end

	return result
end

---Deserializes a parameter
function Parameter:deserialize(t)
	self.uuid = assert(t.uuid)
	self.name = assert(t.name)
	self.isVec2 = not not t.is_vec2

	if t.min then
		self.min = {t.min[1], t.min[2]}
	end

	if t.max then
		self.max = {t.max[1], t.max[2]}
	end

	if t.axis_points then
		local ap = {}

		for i, v in ipairs(t.axis_points) do
			local t2 = {}

			for i2, v2 in ipairs(v) do
				t2[i2] = v2
			end

			ap[i] = t2
		end

		self.axisPoints = ap
	end

	if t.defaults then
		self.defaults = {t.defaults[1], t.defaults[2]}
	end

	if t.bindings and #t.bindings > 0 then
		for _, child in ipairs(t.bindings) do
			-- Skip empty children
			if child.param_name then
				local paramName = child.param_name
				local binding

				if paramName == "deform" then
					binding = DeformationParameterBinding(self)
					binding:deserialize(child)
				else
					binding = ValueParameterBinding(self)
					binding:deserialize(child)
				end

				self.bindings[#self.bindings+1] = binding
			end
		end
	end
end

---Finalize loading of parameter
---@param puppet Inochi2D.Puppet
function Parameter:finalize(puppet)
	self:makeIndexable()
	self.value[1], self.value[2] = self.defaults[1], self.defaults[2]

	---@type Inochi2D.ParameterBinding[]
	local validBindingList = {}

	for _, binding in ipairs(self.bindings) do
		if puppet:find(binding:getNodeUUID()) then
			binding:finalize(puppet)
			validBindingList[#validBindingList+1] = binding
		end
	end

	self.bindings = validBindingList
end

---@param offset Inochi2D.vec2
---@param outIndex Inochi2D.vec2
---@param outOffset Inochi2D.vec2
function Parameter:findOffset(offset, outIndex, outOffset)
	-- TODO: optimize routine
	---@param axis integer
	---@param val number
	---@param index integer
	---@param off number
	local function interpAxis(axis, val, index, off)
		local pos = self.axisPoints[axis + 1]

		for i = 1, #pos do
			if pos[i + 1] > val or i == (#pos - 1) then
				index = i - 1
				off = (val - pos[i]) / (pos[i + 1] - pos[i])
				break
			end
		end

		return index, off
	end

	outIndex[1], outOffset[1] = interpAxis(0, offset[1], outIndex[1], outOffset[1])
	if self.isVec2 then
		outIndex[2], outOffset[2] = interpAxis(1, offset[2], outIndex[2], outOffset[2])
	end
end

function Parameter:preUpdate()
	self.offset[1], self.offset[2] = 0, 0
end

function Parameter:update()
	if self.active then
		local index = {0, 0}
		local offset_ = {0, 0}

		self:findOffset(self:mapValue({self.value[1] + self.offset[1], self.value[2] + self.offset[2]}), index, offset_)

		for _, binding in ipairs(self.bindings) do
			binding:apply(index, offset_)
		end
	end
end

---Get number of points for an axis
---@param axis integer?
function Parameter:axisPointCount(axis)
	return #self.axisPoints[(axis or 0) + 1]
end

-- TODO: Parameter:moveAxisPoint
-- TODO: Parameter:insertAxisPoint
-- TODO: Parameter:deleteAxisPoint
-- TODO: Parameter:reverseAxis

--[[
---Add a new axis point at the given offset
---@param axis integer
---@param off number
function Parameter:insertAxisPoint(axis, off)
	assert(off > 0 and off < 1, "offset out of bounds")
	assert(self.isVec2 and axis <= 1 or axis == 0, "bad axis")

	-- Find the index at which to insert

end
]]

---Get the offset (0..1) of a specified keypoint index
---@param index Inochi2D.vec2
function Parameter:getKeypointOffset(index)
	return {self.axisPoints[1][index[1] + 1], self.axisPoints[2][index[2] + 1]}
end

---Get the value at a specified keypoint index
---@param index Inochi2D.vec2
function Parameter:getKeypointValue(index)
	return self:unmapValue(self:getKeypointOffset(index))
end

---Maps an input value to an offset (0.0->1.0)
---@param value Inochi2D.vec2
function Parameter:mapValue(value)
	local rangeX = self.max[1] - self.min[1]
	local rangeY = self.max[2] - self.min[2]
	local tmpX = value[1] - self.min[1]
	local tmpY = value[2] - self.min[2]
	local offX, offY = tmpX / rangeX, tmpY / rangeY

	return {
		Util.clamp(offX, 0, 1),
		Util.clamp(offY, 0, 1)
	}
end

function Parameter:unmapValue(offset)
	local rangeX = self.max[1] - self.min[1]
	local rangeY = self.max[2] - self.min[2]

	return {
		rangeX * offset[1] + self.min[1],
		rangeY + offset[2] + self.min[2]
	}
end

---Maps an input value to an offset (0.0->1.0) for an axis
---@param axis integer
---@param value number
function Parameter:mapAxis(axis, value)
	local input = {self.min[1], self.min[2]}
	input[axis + 1] = value

	return self:mapValue(input)[axis + 1]
end

---Maps an internal value (0.0->1.0) to the input range for an axis
---@param axis integer
---@param offset number
function Parameter:unmapAxis(axis, offset)
	local input = {self.min[1], self.min[2]}
	input[axis + 1] = offset

	return self:unmapValue(input)[axis + 1]
end

---Gets the axis point closest to a given offset
---@param axis integer
---@param offset number
function Parameter:getClosestAxisPointIndex(axis, offset)
	local closestPoint = 0
	local closestDist = math.huge

	for i, pointVal in ipairs(self.axisPoints[axis + 1]) do
		local dist = math.abs(pointVal - offset)

		if dist < closestDist then
			closestDist = dist
			closestPoint = i - 1
		end
	end

	return closestPoint
end

---Find the keypoint closest to the (current) value
---@param value Inochi2D.vec2?
function Parameter:findClosestKeypoint(value)
	value = value or self.value

	local mapped = self:mapValue(value)
	local x = self:getClosestAxisPointIndex(0, mapped[1])
	local y = self:getClosestAxisPointIndex(1, mapped[1])
	return {x, y}
end

---Find the keypoint closest to the (current) value
---@param value Inochi2D.vec2
function Parameter:getClosestKeypointValue(value)
	return self:getKeypointValue(self:findClosestKeypoint(value))
end

---Find a binding by node ref and name
---@param n Inochi2D.Node
---@param bindingName string
function Parameter:getBinding(n, bindingName)
	for _, binding in ipairs(self.bindings) do
		if binding:getNode() == n and binding:getName() == bindingName then
			return binding
		end
	end

	return nil
end

---Check if a binding exists for a given node and name
---@param n Inochi2D.Node
---@param bindingName string
function Parameter:hasBinding(n, bindingName)
	return not not self:getBinding(n, bindingName)
end

---Check if any bindings exists for a given node
---@param n Inochi2D.Node
function Parameter:hasAnyBinding(n)
	for _, binding in ipairs(self.bindings) do
		if binding:getNode() == n then
			return true
		end
	end

	return false
end

---Create a new binding (without adding it) for a given node and name
---@param n Inochi2D.Node
---@param bindingName string
---@param setZero boolean?
function Parameter:createBinding(n, bindingName, setZero)
	if setZero == nil then
		setZero = true
	end

	local b
	if bindingName == "deform" then
		b = DeformationParameterBinding(self, n, bindingName)
	else
		b = ValueParameterBinding(self, n, bindingName)
	end

	if setZero then
		local zeroIndex = self:findClosestKeypoint({0, 0})
		local zero = self:getKeypointValue(zeroIndex)

		if math.abs(zero[1]) < 0.001 and math.abs(zero[1]) < 0.001 then
			b:reset(zeroIndex)
		end
	end

	return b
end

---Find a binding if it exists, or create and add a new one, and return it
---@param n Inochi2D.Node
---@param bindingName string
---@param setZero boolean?
function Parameter:getOrAddBinding(n, bindingName, setZero)
	local binding = self:getBinding(n, bindingName)

	if not binding then
		binding = self:createBinding(n, bindingName, setZero)
		self:addBinding(binding)
	end

	return binding
end

---Add a new binding (must not exist)
---@param binding Inochi2D.ParameterBinding
function Parameter:addBinding(binding)
	assert(not self:hasBinding(binding:getNode(), binding:getName()))
	self.bindings[#self.bindings+1] = binding
end

---Remove an existing binding by ref
---@param binding Inochi2D.ParameterBinding
function Parameter:removeBinding(binding)
	local i = Util.index(self.bindings, binding)
	if i then
		table.remove(self.bindings, i)
	end
end

function Parameter:makeIndexable()
	self.indexableName = self.name:lower()
end

return Parameter
