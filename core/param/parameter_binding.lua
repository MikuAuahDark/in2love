local path = (...):sub(1, -string.len(".core.param.parameter_binding") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---@class Inochi2D.ParameterBinding: Inochi2D.Object
local ParameterBinding = Object:extend()

---Finalize loading of parameter
---@param puppet Inochi2D.Puppet
function ParameterBinding:finalize(puppet)
	error("need to override finalize")
end

---Apply a binding to the model at the given parameter value
---@param leftKeypoint Inochi2D.vec2
---@param offset Inochi2D.vec2
function ParameterBinding:apply(leftKeypoint, offset)
	error("need to override apply")
end

---Clear all keypoint data
function ParameterBinding:clear()
	error("need to override clear")
end

---Sets value at specified keypoint to the current value
---@param point Inochi2D.vec2
function ParameterBinding:setCurrent(point)
	error("need to override setCurrent")
end

---Unsets value at specified keypoint
---@param point Inochi2D.vec2
function ParameterBinding:unset(point)
	error("need to override unset")
end

---Resets value at specified keypoint to default
---@param point Inochi2D.vec2
function ParameterBinding:reset(point)
	error("need to override reset")
end

---Returns whether the specified keypoint is set
---@param index Inochi2D.vec2
---@return boolean
function ParameterBinding:isSet(index)
	error("need to override isSet")
end


---Scales the value, optionally with axis awareness
---@param index Inochi2D.vec2
---@param axis integer
---@param scale number
function ParameterBinding:scaleValueAt(index, axis, scale)
	error("need to override scaleValueAt")
end

---Extrapolates the value across an axis
---@param index Inochi2D.vec2
---@param axis integer
function ParameterBinding:extrapolateValueAt(index, axis)
	error("need to override extrapolateValueAt")
end

---Copies the value to a point on another compatible binding
---@param src Inochi2D.vec2
---@param other Inochi2D.ParameterBinding
---@param dest Inochi2D.vec2
function ParameterBinding:copyKeypointToBinding(src, other, dest)
	error("need to override copyKeypointToBinding")
end

---Swaps the value to a point on another compatible binding
---@param src Inochi2D.vec2
---@param other Inochi2D.ParameterBinding
---@param dest Inochi2D.vec2
function ParameterBinding:swapKeypointWithBinding(src, other, dest)
	error("need to override swapKeypointWithBinding")
end

---Flip the keypoints on an axis
---@param axis integer
function ParameterBinding:reverseAxis(axis)
	error("need to override reverseAxis")
end

---Update keypoint interpolation
function ParameterBinding:reInterpolate()
	error("need to override reInterpolate")
end

---Returns isSet_
---@return boolean[][]
function ParameterBinding:getIsSet()
	error("need to override getIsSet")
end

---Gets how many breakpoints this binding is set to
---@return integer
function ParameterBinding:getSetCount()
	error("need to override getSetCount")
end

---Move keypoints to a new axis point
---@param axis integer
---@param oldindex integer
---@param index integer
function ParameterBinding:moveKeypoints(axis, oldindex, index)
	error("need to override ")
end

---Add keypoints along a new axis point
---@param axis integer
---@param index integer
function ParameterBinding:insertKeypoints(axis, index)
	error("need to override insertKeypoints")
end

---Remove keypoints along an axis point
---@param axis integer
---@param index integer
function ParameterBinding:deleteKeypoints(axis, index)
	error("need to override deleteKeypoints")
end

---Gets target of binding
---@return Inochi2D.BindTarget
function ParameterBinding:getTarget()
	error("need to override getTarget")
end

---Gets name of binding
---@return string
function ParameterBinding:getName()
	error("need to override getName")
end

---Gets the node of the binding
---@return Inochi2D.Node?
function ParameterBinding:getNode()
	error("need to override getNode")
end

---Gets the uuid of the node of the binding
---@return integer
function ParameterBinding:getNodeUUID()
	error("need to override getNodeUUID")
end

---Checks whether a binding is compatible with another node
---@param other Inochi2D.Node
---@return boolean
function ParameterBinding:isCompatibleWithNode(other)
	error("need to override isCompatibleWithNode")
end

---Gets and sets the interpolation mode
---@param mode Inochi2D.InterpolateMode
---@return Inochi2D.InterpolateMode
---@overload fun(self:Inochi2D.ParameterBinding):Inochi2D.InterpolateMode
---@overload fun(self:Inochi2D.ParameterBinding,mode:Inochi2D.InterpolateMode)
function ParameterBinding:interpolateMode(mode)
	error("need to override interpolateMode")
end

---Serialize
---@return table<string, any>
function ParameterBinding:serializeSelf()
	error("need to override serializeSelf")
end

---Deserialize
---@param data table<string, any>
function ParameterBinding:deserialize(data)
	error("need to override deserialize")
end

return ParameterBinding
