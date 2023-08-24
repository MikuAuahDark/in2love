local path = (...):sub(1, -string.len(".core.deformation_stack") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---@class Inochi2D.DeformationStack: Inochi2D.Object
---@field private parent Inochi2D.Drawable
local DeformationStack = Object:extend()

---@param parent Inochi2D.Drawable
function DeformationStack:new(parent)
	self.parent = parent
end

---Push deformation on to stack
---@param deformation Inochi2D.Deformation
function DeformationStack:push(deformation)
	assert(#self.parent.deformation == #deformation.vertexOffsets)

	for i, v in ipairs(self.parent.deformation) do
		local u = deformation.vertexOffsets[i]
		v[1], v[2] = v[1] + u[1], v[2] + u[2]
	end

	self.parent:notifyDeformPushed(deformation)
end

function DeformationStack:preUpdate()
	for _, v in ipairs(self.parent.deformation) do
		v[1], v[2] = 0, 0
	end
end

function DeformationStack:update()
	self.parent:refreshDeform()
end

---@alias Inochi2D.DeformationStack_Class Inochi2D.DeformationStack
---| fun(parent:Inochi2D.Drawable):Inochi2D.DeformationStack
---@cast DeformationStack +Inochi2D.DeformationStack_Class
return DeformationStack
