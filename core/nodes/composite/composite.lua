local path = (...):sub(1, -string.len(".core.nodes.composite.composite") - 1)

---@type Inochi2D.CorePackage
local CorePackage = require(path..".core.package")
---@type Inochi2D.Node_Class
local Node = require(path..".core.nodes.node_class")
---@type Inochi2D.NodesFactory
local NodesFactory = require(path..".core.nodes.factory")
---@type Inochi2D.NodesPackage
local NodesPackage = require(path..".core.nodes.package")
---@type Inochi2D.Part_Class
local Part = require(path..".core.nodes.part.part")
---@type In2LOVE.Render
local Render = require(path..".render")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class (exact) Inochi2D.Composite: Inochi2D.Node
---@field protected subParts Inochi2D.Part[]
---@field protected offsetOpacity number
---@field protected offsetTint In2LOVE.vec3
---@field protected offsetScreenTint In2LOVE.vec3
---@field public blendingMode Inochi2D.BlendingMode The blending mode
---@field public opacity number The opacity of the composite
---@field public threshold number The threshold for rendering masks
---@field public tint In2LOVE.vec3 Multiplicative tint color
---@field public screenTint In2LOVE.vec3 Screen tint color
local Composite = Node:extend()

function Composite:new(data1, data2)
	self.subParts = {}
	self.offsetOpacity = 1
	self.offsetTint = {0, 0, 0}
	self.offsetScreenTint = {0, 0, 0}
	self.blendingMode = "Normal"
	self.opacity = 1
	self.threshold = 0.5
	self.tint = {1, 1, 1}
	self.screenTint = {0, 0, 0}

	if type(data1) == "number" then
		-- (uuid, parent) overload
		Node.new(self, data1, data2)
	else
		-- (parent) overload
		Node.new(self, NodesPackage.inCreateUUID(), data1)
	end
end

---@private
function Composite:drawSelf()
	if #self.subParts > 0 then
		Render.in2BeginComposite()

		for _, child in ipairs(self.subParts) do
			child:drawOne()
		end

		Render.in2EndComposite()

		Render.in2ActivateCompositeShader(
			{
				self.tint[1] * self.offsetTint[1],
				self.tint[2] * self.offsetTint[2],
				self.tint[3] * self.offsetTint[3],
			}, {
				self.screenTint[1] * self.offsetScreenTint[1],
				self.screenTint[2] * self.offsetScreenTint[2],
				self.screenTint[3] * self.offsetScreenTint[3],
			},
			self.offsetOpacity * self.opacity
		)
		Render.in2SetBlendMode(self.blendingMode)
		Render.in2MergeComposite()
	end
end

---@param a Inochi2D.Part
---@param b Inochi2D.Part
local function sortHigh(a, b)
	return a:zSort() > b:zSort()
end

---@private
function Composite:selfSort()
	return Util.sort(self.subParts, sortHigh)
end

---@param node Inochi2D.Node?
function Composite:scanPartsRecurse(node)
	-- Don't need to scan null nodes
	if node then
		-- Do the main check
		if node:is(Part) then
			---@cast node Inochi2D.Part
			self.subParts[#self.subParts+1] = node
		end

		-- Non-part nodes just need to be recursed through,
		-- they don't draw anything.
		for _, child in ipairs(node:children()) do
			self:scanPartsRecurse(child)
		end
	end
end

function Composite:renderMask()
	-- TODO
end

function Composite:serialize()
	local result = Node.serialize(self)

	result.blend_mode = self.blendingMode
	result.tint = self.tint
	result.screenTint = self.screenTint
	result.mask_threshold = self.threshold
	result.opacity = self.opacity

	return result
end

function Composite:deserialize(data)
	-- Older models may not have these tags
	self.opacity = tonumber(data.opacity) or self.opacity
	self.threshold = tonumber(data) or self.threshold
	self.blendingMode = data.blend_mode or self.blendingMode

	if data.tint then
		self.tint[1], self.tint[2], self.tint[3] = data.tint[1], data.tint[2], data.tint[3]
	end

	if data.screenTint then
		self.screenTint[1] = data.screenTint[1]
		self.screenTint[2] = data.screenTint[2]
		self.screenTint[3] = data.screenTint[3]
	end

	return Node.deserialize(self, data)
end

function Composite:typeId()
	return "Composite"
end

local DEFAULT_PARAM_VALUE = {
	["opacity"] = 1,
	["tint.r"] = 1,
	["tint.g"] = 1,
	["tint.b"] = 1,
	["screenTint.r"] = 0,
	["screenTint.g"] = 0,
	["screenTint.b"] = 0,
}

---@param key string
function Composite:hasParam(key)
	return Node.hasParam(self, key) or (not not DEFAULT_PARAM_VALUE[key])
end

---@param key string
function Composite:getDefaultValue(key)
	-- Skip our list if our parent already handled it
	local def = Node.getDefaultValue(self, key)
	if def == def then -- NaN check
		return def
	end

	return DEFAULT_PARAM_VALUE[key] or (0/0)
end

---@param key string
---@param value number
function Composite:setValue(key, value)
	-- Skip our list of our parent already handled it
	if not Node.setValue(self, key, value) then
		if key == "opacity" then
			self.offsetOpacity = self.offsetOpacity * value
		elseif key == "tint.r" then
			self.offsetTint[1] = self.offsetTint[1] + value
		elseif key == "tint.g" then
			self.offsetTint[2] = self.offsetTint[2] + value
		elseif key == "tint.b" then
			self.offsetTint[3] = self.offsetTint[3] + value
		elseif key == "screenTint.r" then
			self.offsetScreenTint[1] = self.offsetScreenTint[1] + value
		elseif key == "screenTint.g" then
			self.offsetScreenTint[2] = self.offsetScreenTint[2] + value
		elseif key == "screenTint.b" then
			self.offsetScreenTint[3] = self.offsetScreenTint[3] + value
		else
			return false
		end
	end

	return true
end

---@param key string
function Composite:getValue(key)
	if key == "opacity" then
		return self.offsetOpacity
	elseif key == "tint.r" then
		return self.offsetTint[1]
	elseif key == "tint.g" then
		return self.offsetTint[2]
	elseif key == "tint.b" then
		return self.offsetTint[3]
	elseif key == "screenTint.r" then
		return self.offsetScreenTint[1]
	elseif key == "screenTint.g" then
		return self.offsetScreenTint[2]
	elseif key == "screenTint.b" then
		return self.offsetScreenTint[3]
	else
		return Node.getValue(self, key)
	end
end

function Composite:beginUpdate()
	self.offsetOpacity = 1
	self.offsetTint[1], self.offsetTint[2], self.offsetTint[3] = 1, 1, 1
	self.offsetScreenTint[1], self.offsetScreenTint[2], self.offsetScreenTint[3] = 0, 0, 0

	return Node.beginUpdate(self)
end

function Composite:drawOne()
	Node.drawOne(self)

	self:selfSort()
	self:drawSelf()
end

function Composite:draw()
	if self.enabled then
		return self:drawOne()
	end
end

---Scans for parts to render
function Composite:scanParts()
	Util.clearTable(self.subParts)
	local child = self:children()

	if #child > 0 then
		self:scanPartsRecurse(child[1]:parent())
	end
end


NodesFactory.inRegisterNodeType(Composite)
---@alias Inochi2D.Composite_Class Inochi2D.Composite
---| fun(parent?:Inochi2D.Node):Inochi2D.Composite
---| fun(uuid:integer,parent?:Inochi2D.Node):Inochi2D.Composite
---@cast Composite +Inochi2D.Composite_Class
return Composite
