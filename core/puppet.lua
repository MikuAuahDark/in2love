local path = (...):sub(1, -string.len(".core.puppet") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.AnimationPlayer_Class
local AnimationPlayer = require(path..".core.animation")
---@type Inochi2D.AutomationModule
local AutomationModule = require(path..".core.automation")
---@type Inochi2D.Composite_Class
local Composite = require(path..".core.nodes.composite.composite")
---@type Inochi2D.Driver
local Driver = require(path..".core.nodes.driver.driver")
---@type Inochi2D.Node_Class
local Node = require(path..".core.nodes.node_class")
---@type Inochi2D.Part_Class
local Part = require(path..".core.nodes.part.part")
---@type Inochi2D.ParamModule
local ParamModule = require(path..".core.param")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class (exact) Inochi2D.Puppet: Inochi2D.Object
---@field private puppetRootNode Inochi2D.Node An internal puppet root node
---@field private rootParts Inochi2D.Node[] A list of parts that are not masked by other parts for z sorting
---@field private drivers Inochi2D.Driver[] A list of drivers that need to run to update the puppet
---@field private drivenParameters table<Inochi2D.Parameter,Inochi2D.Driver> A list of parameters that are driven by drivers
---@field private animations table<string,Inochi2D.Animation> A dictionary of named animations
---@field public meta Inochi2D.PuppetMeta Meta information about this puppet
---@field public physics Inochi2D.PuppetPhysics Global physics settings for this puppet
---@field public root Inochi2D.Node The root node of the puppet
---@field public parameters Inochi2D.Parameter[] Parameters
---@field public automation Inochi2D.Automation[] Parameters
---@field public textureSlots (love.Texture|false)[] INP Texture slots for this puppet
---@field public extData table<string,string> Extended vendor data
---@field public renderParameters boolean Whether parameters should be rendered
---@field public enableDrivers boolean Whether drivers should run
---@field public player Inochi2D.AnimationPlayer
local Puppet = Object:extend()

-- Magic value meaning that the model has no thumbnail
---@diagnostic disable-next-line: inject-field
Puppet.NO_THUMBNAIL = 4294967295;

---@alias Inochi2D.PuppetAllowedUsers
---Only the author(s) are allowed to use the puppet
---| "onlyAuthor"
---Only licensee(s) are allowed to use the puppet
---| "onlyLicensee"
---Everyone may use the model
---| "everyone"

---@alias Inochi2D.PuppetAllowedRedistribution
---Redistribution is prohibited
---| "prohibited"
---Redistribution is allowed, but only under the same license as the original.
---| "viralLicense"
---Redistribution is allowed, and the puppet may be redistributed under a different license than the original.
---
---This goes in conjunction with modification rights.
---| "copyleftLicense"

---@alias Inochi2D.PuppetAllowedModification
---Modification is prohibited
---| "prohibited"
---Modification is only allowed for personal use
---| "allowPersonal"
---Modification is allowed with redistribution, see `allowedRedistribution` for redistribution terms.
---| "allowRedistribute"

---@class Inochi2D.PuppetUsageRights: Inochi2D.Object, Inochi2D.ISerializable
---@field public allowedUsers Inochi2D.PuppetAllowedUsers Who is allowed to use the puppet?
---@field public allowViolence boolean Whether violence content is allowed
---@field public allowSexual boolean Whether sexual content is allowed
---@field public allowCommercial boolean Whether commerical use is allowed
---@field public allowRedistribution Inochi2D.PuppetAllowedRedistribution Whether a model may be redistributed
---@field public allowModification Inochi2D.PuppetAllowedModification Whether a model may be modified
---@field public requireAttribution boolean Whether the author(s) must be attributed for use.
local UsageRights = Object:extend()

---@private
function UsageRights:new()
	self.allowedUsers = "onlyAuthor"
	self.allowViolence = false
	self.allowSexual = false
	self.allowCommercial = false
	self.allowRedistribution = "prohibited"
	self.allowModification = "prohibited"
	self.requireAttribution = false
end

function UsageRights:serialize()
	return {
		allowedUsers = self.allowedUsers,
		allowViolence = self.allowViolence,
		allowSexual = self.allowSexual,
		allowCommercial = self.allowCommercial,
		allowRedistribution = self.allowRedistribution,
		allowModification = self.allowModification,
		requireAttribution = self.requireAttribution
	}
end

function UsageRights:deserialize(t)
	if t.allowedUsers ~= nil then
		self.allowedUsers = t.allowedUsers
	end

	if t.allowViolence ~= nil then
		self.allowViolence = not not t.allowViolence
	end

	if t.allowSexual ~= nil then
		self.allowSexual = not not t.allowSexual
	end

	if t.allowCommercial ~= nil then
		self.allowCommercial = not not t.allowCommercial
	end

	if t.allowRedistribution ~= nil then
		self.allowRedistribution = assert(t.allowRedistribution)
	end

	if t.allowModification ~= nil then
		self.allowModification = t.allowModification
	end

	if t.requireAttribution ~= nil then
		self.requireAttribution = not not t.requireAttribution
	end
end

---@cast UsageRights +fun():Inochi2D.PuppetUsageRights
---@diagnostic disable-next-line: inject-field
Puppet.UsageRights = UsageRights

---Puppet meta information
---@class Inochi2D.PuppetMeta: Inochi2D.Object, Inochi2D.ISerializable
---@field public name string Name of the puppet
---@field public version_ string Version of the Inochi2D spec that was used for creating this model
---@field public rigger string? Rigger(s) of the puppet
---@field public artist string? Artist(s) of the puppet
---@field public rights Inochi2D.PuppetUsageRights? Usage Rights of the puppet
---@field public copyright string? Copyright string
---@field public licenseURL string? URL of license
---@field public contact string? Contact information of the first author
---@field public reference string? Link to the origin of this puppet
---@field public thumbnailId integer Texture ID of this puppet's thumbnail
---@field public preservePixels boolean Whether the puppet should preserve pixel borders. This feature is mainly useful for puppets which use pixel art.
local Meta = Object:extend()

---@private
function Meta:new()
	self.name = ""
	self.version_ = "1.0-alpha"
	self.rigger = nil
	self.artist = nil
	self.rights = nil
	self.copyright = nil
	self.licenseURL = nil
	self.contact = nil
	self.reference = nil
	self.thumbnailId = Puppet.NO_THUMBNAIL
	self.preservePixels = false
end

function Meta:serialize()
	return {
		name = self.name,
		version = self.version_,
		rigger = self.rigger,
		artist = self.artist,
		rights = self.rights and self.rights:serialize(),
		copyright = self.copyright,
		licenseURL = self.licenseURL,
		contact = self.contact,
		reference = self.reference,
		-- Handle Lua 1-based index
		thumbnailId = self.thumbnailId ~= Puppet.NO_THUMBNAIL and self.thumbnailId - 1 or Puppet.NO_THUMBNAIL,
		preservePixels = self.preservePixels
	}
end

function Meta:deserialize(t)
	self.name = t.name or self.name
	self.version_ = t.version or self.version_
	self.rigger = t.rigger
	self.artist = t.artist

	if t.rights then
		self.rights = UsageRights()
		self.rights:deserialize(t.rights)
	end

	self.copyright = t.copyright
	self.licenseURL = t.licenseURL
	self.contact = t.contact
	self.reference = t.reference

	if t.thumbnailId and t.thumbnailId ~= Puppet.NO_THUMBNAIL then
		self.thumbnailId = t.thumbnailId
	end

	if t.preservePixels ~= nil then
		self.preservePixels = not not t.preservePixels
	end

	return self
end

---@cast Meta +fun():Inochi2D.PuppetMeta
---@diagnostic disable-next-line: inject-field
Puppet.Meta = Meta

---Puppet physics settings
---@class Inochi2D.PuppetPhysics: Inochi2D.Object, Inochi2D.ISerializable
---@field public pixelsPerMeter number
---@field public gravity number
local Physics = Object:extend()

---@private
function Physics:new()
	self.pixelsPerMeter = 1000
	self.gravity = 9.8
end

function Physics:serialize()
	return {
		pixelsPerMeter = self.pixelsPerMeter,
		gravity = self.gravity
	}
end

function Physics:deserialize(t)
	if t.pixelsPerMeter ~= nil then
		self.pixelsPerMeter = assert(tonumber(t.pixelsPerMeter))
	end

	if t.gravity ~= nil then
		self.gravity = assert(tonumber(t.gravity))
	end

	return self
end

---@cast Physics +fun():Inochi2D.PuppetPhysics
---@diagnostic disable-next-line: inject-field
Puppet.Physics = Physics

---@param root Inochi2D.Node?
---@private
function Puppet:new(root)
	self.puppetRootNode = Node(self)
	self.rootParts = {}
	self.drivers = {}
	self.drivenParameters = {}
	self.animations = {}
	self.meta = Meta()
	self.physics = Physics()
	self.root = root or Node(self.puppetRootNode)
	self.root.name = "Root"
	self.parameters = {}
	self.automation = {}
	self.textureSlots = {}
	self.extData = {}
	self.renderParameters = true
	self.enableDrivers = true
	self.player = AnimationPlayer(self)

	if root then
		self:scanParts(self.root, true)
		self:selfSort()
	end
end

---@param node Inochi2D.Node?
---@param driversOnly boolean?
---@private
function Puppet:scanPartsRecurse(node, driversOnly)
	-- Don't need to scan null nodes
	if not node then
		return
	end

	-- Collect Drivers
	if node:is(Driver) then
		---@cast node Inochi2D.Driver
		self.drivers[#self.drivers + 1] = node
		for _, param in ipairs(node:getAffectedParameters()) do
			self.drivenParameters[param] = node
		end
	elseif not driversOnly then
		-- Collect drawable nodes only if we aren't inside a Composite node

		if node:is(Composite) then
			-- Composite nodes handle and keep their own root node list, as such we should just draw them directly
			---@cast node Inochi2D.Composite
			node:scanParts()
			self.rootParts[#self.rootParts + 1] = node
			-- For this subtree, only look for Drivers
			driversOnly = true
		elseif node:is(Part) then
			--- Collect Part nodes
			self.rootParts[#self.rootParts + 1] = node
		end
		-- Non-part nodes just need to be recursed through, they don't draw anything.
	end

	for _, child in ipairs(node:children()) do
		self:scanPartsRecurse(child, driversOnly)
	end
end

---@param node Inochi2D.Node
---@param reparent boolean?
---@private
function Puppet:scanParts(node, reparent)
	-- We want rootParts to be cleared so that we
	-- don't draw the same part multiple times
	-- and if the node tree changed we want to reflect those changes
	-- not the old node tree.
	Util.clearTable(self.rootParts)

	-- Same for drivers
	Util.clearTable(self.drivers)
	Util.clearTable(self.drivenParameters)

	self:scanPartsRecurse(node)

	if reparent then
		if self.puppetRootNode then
			self.puppetRootNode:clearChildren()
			node:parent(self.puppetRootNode)
		end
	end
end

---@param a Inochi2D.Node
---@param b Inochi2D.Node
local function puppetSelfSortComparator(a, b)
	return a:zSort() > b:zSort()
end

---@private
function Puppet:selfSort()
	return Util.sort(self.rootParts, puppetSelfSortComparator, true)
end

---@param n Inochi2D.Node
---@param name string
---@private
function Puppet:findNodeByName(n, name)
	-- Name matches!
	if n.name == name then
		return n
	end

	-- Recurse through children
	for _, child in ipairs(n:children()) do
		local c = self:findNodeByName(child, name)
		if c then
			return c
		end
	end

	-- Not found
	return nil
end

---@param n Inochi2D.Node
---@param uuid integer
function Puppet:findNodeByUUID(n, uuid)
	-- Name matches!
	if n:uuid() == uuid then
		return n
	end

	-- Recurse through children
	for _, child in ipairs(n:children()) do
		local c = self:findNodeByUUID(child, uuid)
		if c then
			return c
		end
	end

	-- Not found
	return nil
end

---@param n Inochi2D.Node
---@param data integer|string
function Puppet:findNode(n, data)
	if type(data) == "string" then
		return self:findNodeByName(n, data)
	else
		return self:findNodeByUUID(n, data)
	end
end

---Updates the nodes
---@param delta number?
function Puppet:update(delta)
	-- Rest additive offsets
	for _, parameter in ipairs(self.parameters) do
		parameter:preUpdate()
	end

	-- Update Automators
	for _, auto in ipairs(self.automation) do
		auto:update()
	end

	self.root:beginUpdate()

	-- Step the animations
	self.player:step(delta)

	if self.renderParameters then
		-- Update parameters
		for _, parameter in ipairs(self.parameters) do
			if (not self.enableDrivers) or (not self.drivenParameters[parameter]) then
				parameter:update()
			end
		end
	end

	-- Ensure the transform tree is updated
	self.root:transformChanged()

	if self.renderParameters and self.enableDrivers then
		-- Update parameter/node driver nodes (e.g. physics)
		for _, driver in ipairs(self.drivers) do
			driver:updateDriver(delta)
		end
	end

	-- Update nodes
	self.root:update()
end

---Reset drivers/physics nodes
function Puppet:resetDrivers()
	for _, driver in ipairs(self.drivers) do
		driver:reset()
	end
end

---Returns the index of a parameter by name
---
---**NOTE**: This returns 1-based index!
---@param name string
function Puppet:findParameterIndex(name)
	for i, parameter in ipairs(self.parameters) do
		if parameter.name == name then
			return i
		end
	end

	return -1
end

---Returns a parameter by UUID
---@param uuid integer
function Puppet:findParameter(uuid)
	for _, parameter in ipairs(self.parameters) do
		if parameter.uuid == uuid then
			return parameter
		end
	end

	return nil
end

---Gets if a node is bound to ANY parameter.
---@param n Inochi2D.Node
function Puppet:getIsNodeBound(n)
	for i, parameter in ipairs(self.parameters) do
		if parameter:hasAnyBinding(n) then
			return true
		end
	end

	return false
end

---Draws the puppet
---
---**TODO**: Remove or implement?
function Puppet:draw()
	self:selfSort()

	for _, rootPart in ipairs(self.rootParts) do
		if rootPart:renderEnabled() then
			rootPart:drawOne()
		end
	end
end

---Removes a parameter from this puppet
function Puppet:removeParameter(param)
	local index = Util.index(self.parameters, param)
	if index then
		table.remove(self.parameters, index)
	end
end

---Gets this puppet's root transform
function Puppet:transform()
	return self.puppetRootNode.transform
end

---Rescans the puppet's nodes
---
---Run this every time you change the layout of the puppet's node tree
function Puppet:rescanNodes()
	return self:scanParts(self.root)
end

---Updates the texture state for all texture slots.
function Puppet:updateTextureState()
	for _, texture in ipairs(self.textureSlots) do
		if texture then
			local filt = self.meta.preservePixels and "nearest" or "linear"
			texture:setFilter(filt, filt)
		end
	end
end

---Finds Node by its name or unique id
---@generic T: Inochi2D.Node
---@param name_or_uuid string|integer
---@param type T|fun(...:any):T
---@return T|nil
---@overload fun(self:Inochi2D.Puppet,name_or_uuid:string|integer):(Inochi2D.Node|nil)
function Puppet:find(name_or_uuid, type)
	local result = self:findNode(self.root, name_or_uuid)

	if result and Object.is(result, type or Node) then
		return result
	end

	return nil
end

---Returns all the parts in the puppet
---@return Inochi2D.Part[]
function Puppet:getAllParts()
	return self:findNodesType(self.root, Part)
end

---@generic T: Inochi2D.Node
---@param n Inochi2D.Node
---@param type T|fun(...:any):T
---@return T[]
function Puppet:findNodesType(n, type)
	local nodes = {}

	if n:is(type) then
		nodes[#nodes + 1] = n
	end

	-- Recurse through children
	for _, child in ipairs(n:children()) do
		for c in self:findNodesType(child, type) do
			nodes[#nodes + 1] = c
		end
	end

	return nodes
end

---Adds a texture to a new slot if it doesn't already exist within this puppet
---@param texture love.Texture
function Puppet:addTextureToSlot(texture)
	-- NOTE: This deviate from the original code

	-- Add texture if we can't find it.
	local i = Util.index(self.textureSlots, texture)
	if not i then
		self.textureSlots[#self.textureSlots + 1] = texture
		i = #self.textureSlots
	end

	return i - 1
end

---Populate texture slots with all visible textures in the model
function Puppet:populateTextureSlots()
	Util.clearTable(self.textureSlots)
	for _, part in ipairs(self:getAllParts()) do
		for _, texture in ipairs(part.textures) do
			if texture then
				self:addTextureToSlot(texture)
			end
		end
	end
end

---Sets thumbnail of this puppet
---@param texture love.Texture
function Puppet:setThumbnail(texture)
	if self.meta.thumbnailId == Puppet.NO_THUMBNAIL then
		self.meta.thumbnailId = self:addTextureToSlot(texture)
	else
		self.textureSlots[self.meta.thumbnailId + 1] = texture
	end
end

---Gets the texture slot index for a texture
---
---returns -1 if none was found
---@param texture love.Texture
function Puppet:getTextureSlotIndexFor(texture)
	return (Util.index(self.textureSlots, texture) or 0) - 1
end


---Clears this puppet's thumbnail
---
---By default it does not delete the texture assigned, pass in true to delete texture
---@param deleteTexture boolean?
function Puppet:clearThumbnail(deleteTexture)
	if self.meta.thumbnailId ~= Puppet.NO_THUMBNAIL then
		if deleteTexture then
			self.textureSlots[self.meta.thumbnailId + 1] = false
		end

		self.meta.thumbnailId = Puppet.NO_THUMBNAIL
	end
end

-- TODO: __tostring
function Puppet:__tostring()
	return string.format("Puppet<%p>", self)
end

---Serializes a puppet
function Puppet:serialize()
	-- TODO: Re-evaluate serialization
	return {
		meta = self.meta:serialize(),
		physics = self.physics:serialize(),
		nodes = self.root:serialize(),
		param = Util.serializeArray(self.parameters),
		automation = Util.serializeArray(self.automation),
		animations = Util.serializeDictionary(self.animations)
	}
end

function Puppet:deserialize(t)
	self.meta:deserialize(assert(t.meta))

	if t.physics then
		self.physics:deserialize(t.physics)
	end

	self.root:deserialize(t.nodes)

	-- Allow parameter loading to be overridden (for Inochi Creator)
	if t.param then
		for _, key in ipairs(assert(t.param)) do
			self.parameters[#self.parameters+1] = ParamModule.inParameterCreate(key)
		end
	end

	-- Deserialize automation
	if t.automation then
		for _, key in ipairs(t.automation) do
			local type = tostring(assert(key.type))

			if AutomationModule.inHasAutomationType(type) then
				local auto = AutomationModule.inInstantiateAutomation(type, self)
				auto:deserialize(key)
				self.automation[#self.automation+1] = auto
			end
		end
	end

	if t.animation then
		-- TODO
	end

	self:finalizeDeserialization(t)
end

---Finalizer
function Puppet:finalizeDeserialization(t)
	self.root:setPuppet(self)
	self.root.name = "Root"
	self.puppetRootNode = Node(self)
	self.root:finalize()

	for _, parameter in ipairs(self.parameters) do
		parameter:finalize(self)
	end

	for _, automation in ipairs(self.automation) do
		automation:finalize(self)
	end

	for _, animation in pairs(self.animations) do
		animation:finalize(self)
	end

	self:scanParts(self.root, true)
	self:selfSort()
end

---Gets the internal root parts array 
---
---Do note that some root parts may be Composites instead.
function Puppet:getRootParts()
	return self.rootParts
end

---Gets a list of drivers
function Puppet:getDrivers()
	return self.drivers
end

---Gets a mapping from parameters to their drivers
function Puppet:getParameterDrivers()
	return self.drivenParameters
end

---Gets the animation dictionary
function Puppet:getAnimations()
	return self.animations
end

---@alias Inochi2D.Puppet_Class
---| Inochi2D.Puppet
---| fun(root:Inochi2D.Node?):Inochi2D.Puppet
---@cast Puppet +Inochi2D.Puppet_Class
return Puppet
