local path = (...):sub(1, -string.len(".core.nodes.drawable") - 1)

local love = require("love")

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.Node_Class
local Node = require(path..".core.nodes.node_class")
---@type Inochi2D.NodesFactory
local NodesFactory = require(path..".core.nodes.factory")
---@type Inochi2D.NodesPackage
local NodesPackage = require(path..".core.nodes.package")
---@type Inochi2D.DeformationStack_Class
local DeformationStack = require(path..".core.nodes.defstack")
---@type Inochi2D.MeshData_Class
local MeshData = require(path..".core.meshdata")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class (exact) Inochi2D.Drawable: Inochi2D.Node
---@field protected data Inochi2D.MeshData The mesh data of this part (DO NOT MODIFY!)
---@field public deformation In2LOVE.vec2[] Deformation offset to apply
---@field public bounds In2LOVE.vec4 The bounds of this drawable
---@field public deformStack Inochi2D.DeformationStack Deformation stack
---@field public doGenerateBounds boolean
local Drawable = Node:extend()

Drawable.doGenerateBounds = false

function Drawable:new(data1, data2, data3)
	local data

	if Object.is(data1, MeshData) then
		local uuid, parent
		---@cast data1 Inochi2D.MeshData
		data = data1

		if type(data2) == "number" then
			-- (data, uuid, parent) overload
			---@cast data2 integer
			---@cast data3 Inochi2D.Node?
			uuid = data2
			parent = data3
		else
			---@cast data2 Inochi2D.Node?
			uuid = NodesPackage.inCreateUUID()
			parent = data2
		end

		Node.new(self, uuid, parent)
	else
		-- (parent) overload
		Node.new(self, data1)
		data = MeshData()
	end

	self.data = data
	self.deformation = {}
	self.bounds = {0, 0, 0, 0}
	self.deformStack = DeformationStack(self)
end

---@private
function Drawable:updateIndices()
end

---@private
function Drawable:updateVertices()
	-- Zero-fill the deformation delta
	Util.clearTable(self.deformation)

	for _ = 1, #self:vertices() do
		self.deformation[#self.deformation+1] = {0, 0}
	end

	self:updateDeform()
end

---@private
function Drawable:updateDeform()
	-- Important check since the user can change this every frame
	assert(#self.deformation == #self:vertices(), "Data length mismatch, if you want to change the mesh you need to change its data with Part.rebuffer.")

	self:updateBounds()
end

function Drawable:bindIndex()
end

---@param dodge boolean?
---@protected
function Drawable:renderMask(dodge)
	error("need to override renderMask")
end

function Drawable:serialize()
	local result = Node.serialize(self)
	result.mesh = self.data:serialize()

	return result
end

function Drawable:deserialize(data)
	Node.deserialize(self, data)
	self.data:deserialize(data.mesh)

	-- Update indices and vertices
	self:updateIndices()
	self:updateVertices()
end

---@param deform Inochi2D.Deformation
---@protected
function Drawable:onDeformPushed(deform)
end

---@package
function Drawable:notifyDeformPushed(deform)
	self:onDeformPushed(deform)
end

function Drawable:vertices()
	return self.data.vertices
end

---Refreshes the drawable, updating its vertices
function Drawable:refresh()
	self:updateVertices()
end

---Refreshes the drawable, updating its deformation deltas
function Drawable:refreshDeform()
	self:updateDeform()
end

function Drawable:beginUpdate()
	self.deformStack:preUpdate()
	Node.beginUpdate(self)
end

---Updates the drawable
function Drawable:update()
	Node.update(self)
	self.deformStack:update()
	self:updateDeform()
end

---Draws the drawable without any processing
---@param forMasking boolean
function Drawable:drawOneDirect(forMasking)
end

function Drawable:typeId()
	return "Drawable"
end

---Updates the drawable's bounds
function Drawable:updateBounds()
	if Drawable.doGenerateBounds then
		-- Calculate bounds
		local wtransform = self:transform()
		local matrix = wtransform:matrix()
		self.bounds[1] = wtransform.translation[1]
		self.bounds[2] = wtransform.translation[2]
		self.bounds[3] = wtransform.translation[1]
		self.bounds[4] = wtransform.translation[2]

		for i, vertex in ipairs(self:vertices()) do
			local vx, vy = matrix:transformPoint(
				vertex[1] + self.deformation[i][1],
				vertex[2] + self.deformation[i][2]
			)

			self.bounds[1] = math.min(self.bounds[1], vx)
			self.bounds[2] = math.min(self.bounds[2], vy)
			self.bounds[3] = math.max(self.bounds[3], vx)
			self.bounds[4] = math.max(self.bounds[4], vy)
		end
	end
end

function Drawable:drawBounds()
	if Drawable.doGenerateBounds and #self:vertices() > 0 then
		love.graphics.line(
			self.bounds[1], self.bounds[2],
			self.bounds[3], self.bounds[2],
			self.bounds[3], self.bounds[4],
			self.bounds[1], self.bounds[4],
			self.bounds[1], self.bounds[2]
		)
	end
end

function Drawable:drawMeshLines()
	-- TODO
end

function Drawable:drawMeshPoints()
	-- TODO
end

---Returns the mesh data for this Part.
function Drawable:getMesh()
	return self.data
end

---Changes this mesh's data
function Drawable:rebuffer(data)
	self.data = data
	self:updateIndices()
	self:updateVertices()
end

function Drawable:reset()
	-- TODO
end

NodesFactory.inRegisterNodeType(Drawable)
return Drawable
