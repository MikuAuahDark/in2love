local path = (...):sub(1, -string.len(".core.nodes.node") - 1)

---@type Inochi2D.NodesFactory
local NodesFactory = require(path..".core.nodes.factory")
---@type Inochi2D.NodesPackage
local NodesPackage = require(path..".core.nodes.package")
---@type Inochi2D.TransformModule
local Transform = require(path..".math.transform")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class (exact) Inochi2D.Node: Inochi2D.Object, Inochi2D.ISerializable
---@field private puppet_ Inochi2D.Puppet
---@field private parent_ Inochi2D.Node?
---@field private children_ Inochi2D.Node[]
---@field private uuid_ integer Returns the unique identifier for this node
---@field private zsort_ number
---@field private lockToRoot_ boolean
---@field private nodePath_ string
---@field protected offsetTransform Inochi2D.Transform The offset to the transform to apply
---@field protected offsetSort number The offset to apply to sorting
---@field public enabled boolean Whether the node is enabled 
---@field public name string Visual name of the node
---@field public localTransform Inochi2D.Transform The local transform of the node
---@field public globalTransform Inochi2D.Transform The cached world space transform of the node
---@field public recalculateTransform boolean
local Node = require(path..".core.nodes.node_class")

-- Needs to be loaded BEFORE puppet!
function Node:__tostring()
	return self.name
end

---@type Inochi2D.Puppet_Class
local Puppet = require(path..".core.puppet")

---@param data1 Inochi2D.Node|Inochi2D.Puppet|integer|nil
---@param data2 Inochi2D.Node|nil
function Node:new(data1, data2)
	self.children_ = {}
	self.zsort_ = 0
	self.lockToRoot_ = false
	self.nodePath_ = ""
	self.offsetTransform = Transform()
	self.offsetSort = 0
	self.enabled = true
	self.name = "Unnamed Node"
	self.localTransform = Transform()
	self.globalTransform = Transform()
	self.recalculateTransform = true

	if type(data1) == "number" then
		-- (uuid, parent?) overload
		if data2 then
			self:parent(data2)
		end

		self.uuid_ = data1
	else
		---@cast data1 -integer
		if data1 then
			if data1:is(Puppet) then
				---@cast data1 Inochi2D.Puppet
				-- (puppet) overload
				self.puppet_ = data1
			elseif data1:is(Node) then
				---@cast data1 Inochi2D.Node
				-- (parent) overload
				self:parent(data1)
			end
		end

		self.uuid_ = NodesPackage.inCreateUUID()
	end
	-- () overload, parent_ is nil by default.
end

---Send mask reset request one node up
function Node:resetMask()
	if self.parent_ then
		self.parent_:resetMask()
	end
end

function Node:serialize()
	local result = {
		uuid = self.uuid_,
		name = self.name,
		type = self:typeId(),
		enabled = self.enabled,
		zsort = self.zsort_,
		transform = self.localTransform:serialize(),
		lockToRoot = self.lockToRoot_,
	}

	if #self.children_ > 0 then
		local children = {}

		for _, child in ipairs(self.children_) do
			if not child:is(Node.Tmp) then
				children[#children + 1] = child:serialize()
			end
		end

		result.children = children
	end

	return result
end

---Needed for deserialization
---@param puppet Inochi2D.Puppet
---@package
function Node:setPuppet(puppet)
	self.puppet_ = puppet
end

---Whether the node is enabled for rendering.
---Disabled nodes will not be drawn.
---This happens recursively
function Node:renderEnabled()
	if self.parent_ then
		return self.parent_:renderEnabled() and self.enabled
	end

	return self.enabled
end

---Returns the unique identifier for this node
function Node:uuid()
	return self.uuid_
end

---This node's type ID
---@param self any
function Node:typeId()
	return "Node"
end

---Gets the relative Z sorting
function Node:relZSort()
	return self.zsort_
end

---Gets the basis zSort offset.
function Node:zSortBase()
	return self.parent_ and self.parent_:zSort() or 0
end

---Gets the Z sorting without parameter offsets
function Node:zSortNoOffset()
	return self:zSortBase() + self:relZSort()
end

---Gets or sets the (relative) Z sorting
---@param value number
---@overload fun(self:Inochi2D.Node):number
---@overload fun(self:Inochi2D.Node,value:number)
function Node:zSort(value)
	if value then
		self.zsort_ = value
	else
		return self:zSortNoOffset() + self.offsetSort
	end
end

---Lock translation to root
---@param value boolean
---@overload fun(self:Inochi2D.Node):boolean
function Node:lockToRoot(value)
	-- Automatically handle converting lock space and proper world space.
	if value and (not self.lockToRoot_) then
		self.localTransform.translation = self:transformNoLock().translation
	elseif (not value) and self.lockToRoot_ then
		-- Uh, no 3D vector library
		local t1, t2 = self.localTransform.translation, self.parent_:transformNoLock().translation
		self.localTransform.translation[1] = t1[1] - t2[1]
		self.localTransform.translation[2] = t1[2] - t2[2]
		self.localTransform.translation[3] = t1[3] - t2[3]
	end

	self.lockToRoot_ = value
end

---The transform in world space
---@param ignoreParam boolean?
function Node:transform(ignoreParam)
	if self.recalculateTransform then
		self.localTransform:update()
		self.offsetTransform:update()

		if ignoreParam then
			if self.lockToRoot_ then
				self.globalTransform = self.localTransform * self:puppet().root.localTransform
			elseif self.parent_ then
				self.globalTransform = self.localTransform * self.parent_:transform()
			else
				self.globalTransform = self.localTransform:clone()
			end
		else
			if self.lockToRoot_ then
				self.globalTransform = self.localTransform:calcOffset(self.offsetTransform) * self:puppet().root.localTransform
			elseif self.parent_ then
				self.globalTransform = self.localTransform:calcOffset(self.offsetTransform) * self.parent_:transform()
			else
				self.globalTransform = self.localTransform:calcOffset(self.offsetTransform)
			end
		end

		self.recalculateTransform = false
	end

	return self.globalTransform
end

---The transform in world space without locking
function Node:transformNoLock()
	self.localTransform:update()

	if self.parent_ then
		return self.localTransform * self.parent_:transform()
	end

	return self.localTransform
end

---Calculates the relative position between 2 nodes and applies the offset.
---You should call this before reparenting nodes.
---@param to Inochi2D.Node
function Node:setRelativeToNode(to)
	self:setRelativeToMatrix(to:transformNoLock():matrix())
	self:zSort(self:zSortNoOffset() - to:zSortNoOffset())
end

---Calculates the relative position between this node and a matrix and applies the offset.
---This does not handle zSorting. Pass a Node for that.
---@param to love.Transform
function Node:setRelativeToMatrix(to)
	self.localTransform.translation = Node.getRelativePosition(to, self:transformNoLock():matrix())
	self.localTransform:update()
end

---Gets a relative position for 2 matrices
---@param m1 love.Transform
---@param m2 love.Transform
---@return {[1]:number,[2]:number,[3]:number}
---@diagnostic disable-next-line: inject-field
function Node.getRelativePosition(m1, m2)
	---@type love.Transform
	local cm = m1:inverse() * m2
	local x, y, z = select(13, cm:getMatrix())
	return {x, y, z}
end

---Gets a relative position for 2 matrices.
---Inverse order of getRelativePosition
---@param m1 love.Transform
---@param m2 love.Transform
---@return {[1]:number,[2]:number,[3]:number}
---@diagnostic disable-next-line: inject-field
function Node.getRelativePositionInv(m1, m2)
	---@type love.Transform
	local cm = m2 * m1:inverse()
	local x, y, z = select(13, cm:getMatrix())
	return {x, y, z}
end

---Gets the path to the node.
function Node:getNodePath()
	if #self.nodePath_ > 0 then
		return self.nodePath_
	end

	local pathSegments = {}
	local parent = self

	while parent do
		table.insert(pathSegments, 1, parent.name)
		parent = parent.parent_
	end

	return "/"..table.concat(pathSegments, "/")
end

---Gets the depth of this node
function Node:depth()
	local depth = 0
	local parent = self

	while parent do
		depth = depth + 1
		parent = parent.parent_
	end

	return depth
end

---Gets a list of this node's children
function Node:children()
	return self.children_
end

local OFFSET_START = -math.huge
local OFFSET_END = math.huge

---Gets or sets the parent of this node
---@param node Inochi2D.Node
---@overload fun(self:Inochi2D.Node):Inochi2D.Node?
---@overload fun(self:Inochi2D.Node,node:Inochi2D.Node)
function Node:parent(node)
	if node then
		self:insertInto(node, OFFSET_END)
	else
		return self.parent_
	end
end

---The puppet this node is attached to
---@return Inochi2D.Puppet
function Node:puppet()
	if self.parent_ then
		return self.parent_:puppet()
	end

	return self.puppet_
end

---Removes all children from this node
function Node:clearChildren()
	for i = #self.children_, 1, -1 do
		self.children_[i].parent_ = nil
		self.children_[i] = nil
	end
end

---@param child Inochi2D.Node
function Node:addChild(child)
	child:parent(self)
end

function Node:getIndexInParent()
	return self:getIndexInNode(self.parent_)
end

---@param n Inochi2D.Node
function Node:getIndexInNode(n)
	return (Util.index(n.children_, self) or 0) - 1
end

---@param node Inochi2D.Node?
---@param offset number
function Node:insertInto(node, offset)
	self.nodePath_ = nil

	-- Remove ourselves from our current parent if we are
	-- the child of one already.
	if self.parent_ then
		-- Try to find ourselves in our parent
		-- note idx will be -1 if we can't be found
		local idx = self:getIndexInParent()
		assert(idx >= 0, "Invalid parent-child relationship!")

		-- Remove ourselves
		table.remove(self.parent_.children_, idx + 1)
	end

	-- If we want to become parentless we need to handle that
	if not node then
		self.parent_ = nil
		return
	end

	-- Update our relationship with our new parent
	self.parent_ = node

	-- Update position
	if offset == OFFSET_START then
		table.insert(node.children_, 1, self)
	elseif offset == OFFSET_END then
		node.children_[#node.children_ + 1] = self
	else
		table.insert(node.children_, offset, self)
	end

	local p = self:puppet()
	if p then
		p:rescanNodes()
	end
end

local DEFAULT_PARAM_VALUE = {
	["zSort"] = 0,
	["transform.t.x"] = 0,
	["transform.t.y"] = 0,
	["transform.t.z"] = 0,
	["transform.r.x"] = 0,
	["transform.r.y"] = 0,
	["transform.r.z"] = 0,
	["transform.s.x"] = 1,
	["transform.s.y"] = 1,
}

---Return whether this node supports a parameter
---@param key string
function Node:hasParam(key)
	return not not DEFAULT_PARAM_VALUE[key]
end

---Gets the default offset value
---@param key string
---@return number
function Node:getDefaultValue(key)
	return DEFAULT_PARAM_VALUE[key] or (0/0)
end

---Sets offset value
---@param key string
---@param value number
function Node:setValue(key, value)
	if key == "zSort" then
		self.offsetSort = self.offsetSort + value
	elseif key == "transform.t.x" then
		self.offsetTransform.translation[1] = self.offsetTransform.translation[1] + value
	elseif key == "transform.t.y" then
		self.offsetTransform.translation[2] = self.offsetTransform.translation[2] + value
	elseif key == "transform.t.z" then
		self.offsetTransform.translation[3] = self.offsetTransform.translation[3] + value
	elseif key == "transform.r.x" then
		self.offsetTransform.rotation[1] = self.offsetTransform.rotation[1] + value
	elseif key == "transform.r.y" then
		self.offsetTransform.rotation[2] = self.offsetTransform.rotation[2] + value
	elseif key == "transform.r.z" then
		self.offsetTransform.rotation[3] = self.offsetTransform.rotation[3] + value
	elseif key == "transform.s.x" then
		self.offsetTransform.scale[1] = self.offsetTransform.scale[1] * value
	elseif key == "transform.s.y" then
		self.offsetTransform.scale[2] = self.offsetTransform.scale[2] * value
	else
		return false
	end

	self:transformChanged()
	return true
end

---Scale an offset value, given an axis and a scale
---
---If axis is -1, apply magnitude and sign to signed properties.
---If axis is 0 or 1, apply magnitude only unless the property is
---signed and aligned with that axis.
---
---Note that scale adjustments are not considered aligned,
---since we consider preserving aspect ratio to be the user
---intent by default.
---@param key string
---@param value number
---@param axis integer
---@param scale number
function Node:scaleValue(key, value, axis, scale)
	if axis == -1 then
		return value * scale
	end

	local newVal

	if
		-- Z-rotation is XY-mirroring
		key == "transform.r.z" or
		-- Y-rotation is X-mirroring
		((key == "transform.r.y" or key == "transform.t.x") and axis == 0) or
		-- X-rotation is Y-mirroring
		((key == "transform.r.x" or key == "transform.t.y") and axis == 1)
	then
		newVal = scale * value
	else
		newVal = math.abs(scale) * value
	end

	return newVal
end

---@param key string
function Node:getValue(key)
	if key == "zSort" then
		return self.offsetSort
	elseif key == "transform.t.x" then
		return self.offsetTransform.translation[1]
	elseif key == "transform.t.y" then
		return self.offsetTransform.translation[2]
	elseif key == "transform.t.z" then
		return self.offsetTransform.translation[3]
	elseif key == "transform.r.x" then
		return self.offsetTransform.rotation[1]
	elseif key == "transform.r.y" then
		return self.offsetTransform.rotation[2]
	elseif key == "transform.r.z" then
		return self.offsetTransform.rotation[3]
	elseif key == "transform.s.x" then
		return self.offsetTransform.scale[1]
	elseif key == "transform.s.y" then
		return self.offsetTransform.scale[2]
	else
		return 0
	end
end

---Draws this node and it's subnodes
function Node:draw()
	if self:renderEnabled() then
		for _, child in ipairs(self:children()) do
			child:draw()
		end
	end
end

---Draws this node.
function Node:drawOne()
end

---Finalizes this node and any children
function Node:finalize()
	for _, child in ipairs(self:children()) do
		child:finalize()
	end
end

function Node:beginUpdate()
	self.offsetSort = 0
	self.offsetTransform:clear()

	-- Iterate through children
	for _, child in ipairs(self:children()) do
		child:beginUpdate()
	end
end

---Updates the node
function Node:update()
	if self.enabled then
		for _, child in ipairs(self:children()) do
			child:update()
		end
	end
end

---Marks this node's transform (and its descendents') as dirty
function Node:transformChanged()
	self.recalculateTransform = true

	for _, child in ipairs(self:children()) do
		child:transformChanged()
	end
end

---@param data table<string, any>
function Node:deserialize(data)
	self.uuid_ = assert(data.uuid)
	self.name = assert(data.name)
	self.enabled = assert(data.enabled)
	self.zsort_ = assert(data.zsort)
	self.localTransform:deserialize(assert(data.transform))

	if data.lockToRoot ~= nil then
		self.lockToRoot_ = not not data.lockToRoot
	end

	-- Pre-populate our children with the correct types
	if data.children then
		for _, child in ipairs(data.children) do
			-- Fetch type from json
			---@type string
			local nodeType = assert(child.type)

			if NodesFactory.inHasNodeType(nodeType) then
				local n = NodesFactory.inInstantiateNode(nodeType, self)
				n:deserialize(child)
			end
		end
	end
end

---@class Inochi2D.NodeTmp: Inochi2D.Node
local Tmp = Node:extend()

function Tmp.typeId()
	return "Tmp"
end

NodesFactory.inRegisterNodeType(Node)
NodesFactory.inRegisterNodeType(Tmp)

---@cast Tmp +fun(parent?:Inochi2D.Node):Inochi2D.NodeTmp
---@cast Tmp +fun(puppet:Inochi2D.Puppet):Inochi2D.NodeTmp
---@cast Tmp +fun(uuid:integer,parent?:Inochi2D.Node):Inochi2D.NodeTmp
---@diagnostic disable-next-line: inject-field
Node.Tmp = Tmp

---@alias Inochi2D.Node_Class Inochi2D.Node
---| fun(parent?:Inochi2D.Node):Inochi2D.Node
---| fun(puppet:Inochi2D.Puppet):Inochi2D.Node
---| fun(uuid:integer,parent?:Inochi2D.Node):Inochi2D.Node
---@cast Node +Inochi2D.Node_Class
return Node
