local path = (...):sub(1, -string.len(".core.nodes.part.part") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.NodesCommon
local NodesCommon = require(path..".core.nodes.common")
---@type Inochi2D.NodesFactory
local NodesFactory = require(path..".core.nodes.factory")
---@type Inochi2D.NodesPackage
local NodesPackage = require(path..".core.nodes.package")
---@type Inochi2D.Drawable
local Drawable = require(path..".core.nodes.drawable")
---@type Inochi2D.MeshData_Class
local MeshData = require(path..".core.meshdata")
---@type Inochi2D.FmtPackage1
local FmtPackage1 = require(path..".fmt.package1")
---@type In2LOVE.Render
local Render = require(path..".render")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@alias Inochi2D.TextureUsage
---| "Albedo"
---| "Emissive"
---| "Bumpmap"

---Dynamic Mesh Part
---@class (exact) Inochi2D.Part: Inochi2D.Drawable
---@field public textures (love.Texture|false)[] List of textures this part can use
---@field public textureIds integer[] List of texture IDs
---@field public masks Inochi2D.MaskBinding[] List of masks to apply
---@field public blendingMode Inochi2D.BlendingMode Blending mode
---@field public maskAlphaThreshold number Alpha Threshold for the masking system, the higher the more opaque pixels will be discarded in the masking process
---@field public opacity number Opacity of the mesh
---@field public emissionStrength number Strength of emission
---@field public tint In2LOVE.vec3 Multiplicative tint color
---@field public screenTint In2LOVE.vec3 Screen tint color
---@field public offsetMaskThreshold number
---@field public offsetOpacity number
---@field public offsetEmissionStrength number
---@field public offsetTint In2LOVE.vec3
---@field public offsetScreenTint In2LOVE.vec3
local Part = Drawable:extend()

local NO_TEXTURE = 4294967295

function Part:new(data1, data2, data3, data4)
	local data, textures, uuid, parent

	if Object.is(data1, MeshData) and type(data2) == "table" then
		if type(data3) == "number" then
			-- (data, textures, uuid, parent) overload
			---@cast data1 Inochi2D.MeshData
			---@cast data2 (love.Texture|false)[]
			---@cast data3 integer
			---@cast data4 Inochi2D.Node?
			data = data1
			textures = data2
			uuid = data3
			parent = data4
		else
			-- (data, textures, parent) overload
			---@cast data1 Inochi2D.MeshData
			---@cast data2 (love.Texture|false)[]
			---@cast data3 integer
			---@cast data4 Inochi2D.Node?
			data = data1
			textures = data2
			uuid = NodesPackage.inCreateUUID()
			parent = data3
		end

		Drawable.new(self, data, uuid, parent)
	else
		-- (parent) overload
		Drawable.new(self, data1)
		textures = {}
	end

	self.textures = {}
	self.textureIds = {}
	self.masks = {}
	self.blendingMode = "Normal"
	self.maskAlphaThreshold = 0.5
	self.opacity = 1
	self.emissionStrength = 1
	self.tint = {1, 1, 1}
	self.screenTint = {0, 0, 0}
	self.offsetMaskThreshold = 0
	self.offsetOpacity = 1
	self.offsetEmissionStrength = 1
	self.offsetTint = {0, 0, 0}
	self.offsetScreenTint = {0, 0, 0}

	for i = 1, math.min(#textures, 3) do
		self.textures[#self.textures+1] = textures[i]
	end
end

---@private
function Part:updateUVs()
end

---RENDERING
---@param isMask boolean?
---@private
function Part:drawSelf(isMask)
	if #self.textures > 0 then
		Render.in2DrawVertices(self.data, self.deformation, self:transform():matrix(), self.textures[1], self.textures[2], self.textures[3])
	end
end

---@param dodge boolean?
function Part:renderMask(dodge)
	Render.in2BeginMask(dodge)
	Render.in2DrawMask(Part.drawSelfMasked, self)
	Render.in2EndMask()
end

---Not part of original Inochi2D
---@private
function Part:drawSelfMasked()
	return self:drawSelf(true)
end

function Part:typeId()
	return "Part"
end

function Part:serialize()
	local result = Drawable.serialize(self)

	if FmtPackage1.inIsINPMode() then
		local tex = {}

		for _, texture in ipairs(self.textures) do
			local index = -1

			if texture then
				index = self:puppet():getTextureSlotIndexFor(texture)
			end

			tex[#tex+1] = index >= 0 and index or NO_TEXTURE
		end

		result.texture = tex
	end

	result.blend_mode = self.blendingMode
	result.tint = self.tint
	result.screenTint = self.screenTint
	result.emissionStrength = self.emissionStrength

	if #self.masks > 0 then
		result.masks = Util.serializeArray(self.masks)
	end

	result.mask_threshold = self.maskAlphaThreshold
	result.opacity = self.opacity

	return result
end

function Part:deserialize(data)
	Drawable.deserialize(self, data)

	if FmtPackage1.inIsINPMode() then
		for _, textureId in ipairs(data.textures) do
			if textureId ~= NO_TEXTURE then
				self.textureIds[#self.textureIds+1] = textureId
				self.textures[#self.textures+1] = FmtPackage1.inGetTextureFromId(textureId)
			end
		end
	else
		error("Loading from texture path is deprecated")
	end

	self.opacity = assert(tonumber(data.opacity))
	self.maskAlphaThreshold = assert(tonumber(data.mask_threshold))

	-- Older models may not have tint
	if data.tint then
		self.tint[1], self.tint[2], self.tint[3] = data.tint[1], data.tint[2], data.tint[3]
	end

	-- Older models may not have screen tint
	if data.screenTint then
		self.screenTint[1] = data.screenTint[1]
		self.screenTint[2] = data.screenTint[2]
		self.screenTint[3] = data.screenTint[3]
	end

	-- Older models may not have emission
	if data.emissionStrength then
		-- Why writing to tint?
		self.tint[1] = data.emissionStrength[1]
		self.tint[2] = data.emissionStrength[2]
		self.tint[3] = data.emissionStrength[3]
	end

	if data.masked_by then
		local mode = assert(data.mask_mode)

		-- Go every masked part
		for _, imask in ipairs(data.masked_by) do
			local uuid = assert(tonumber(imask))
			self.masks[#self.masks+1] = NodesCommon.MaskBinding(uuid, mode)
		end
	end

	if data.masks then
		for _, mask in ipairs(data.masks) do
			local binding = NodesCommon.MaskBinding()
			binding:deserialize(mask)
			self.masks[#self.masks+1] = binding
		end
	end

	-- Update indices and vertices
	self:updateUVs()
end

---TODO: Cache this
function Part:maskCount()
	local c = 0

	for _, m in ipairs(self.masks) do
		if m.mode == "Mask" then
			c = c + 1
		end
	end

	return c
end

function Part:dodgeCount()
	local c = 0

	for _, m in ipairs(self.masks) do
		if m.mode == "DodgeMask" then
			c = c + 1
		end
	end

	return c
end

---Gets the active texture
function Part:activeTexture()
	return self.textures[1]
end

local DEFAULT_PARAM_VALUE = {
	["alphaThreshold"] = 0,
	["opacity"] = 1,
	["tint.r"] = 1,
	["tint.g"] = 1,
	["tint.b"] = 1,
	["screenTint.r"] = 0,
	["screenTint.g"] = 0,
	["screenTint.b"] = 0,
	["emissionStrength"] = 1
}

---@param key string
function Part:hasParam(key)
	return Drawable.hasParam(self, key) or (not not DEFAULT_PARAM_VALUE[key])
end

---@param key string
function Part:getDefaultValue(key)
	-- Skip our list if our parent already handled it
	local def = Drawable.getDefaultValue(self, key)
	if def == def then -- NaN check
		return def
	end

	return DEFAULT_PARAM_VALUE[key] or (0/0)
end

---@param key string
---@param value number
function Part:setValue(key, value)
	-- Skip our list of our parent already handled it
	if not Drawable.setValue(self, key, value) then
		if key == "alphaThreshold" then
			self.offsetMaskThreshold = self.offsetMaskThreshold * value
		elseif key == "opacity" then
			self.offsetOpacity = self.offsetOpacity * value
		elseif key == "tint.r" then
			self.offsetTint[1] = self.offsetTint[1] * value
		elseif key == "tint.g" then
			self.offsetTint[2] = self.offsetTint[2] * value
		elseif key == "tint.b" then
			self.offsetTint[3] = self.offsetTint[3] * value
		elseif key == "screenTint.r" then
			self.offsetScreenTint[1] = self.offsetScreenTint[1] * value
		elseif key == "screenTint.g" then
			self.offsetScreenTint[2] = self.offsetScreenTint[2] * value
		elseif key == "screenTint.b" then
			self.offsetScreenTint[3] = self.offsetScreenTint[3] * value
		elseif key == "emissionStrength" then
			self.offsetEmissionStrength = self.offsetEmissionStrength + value
		else
			return false
		end
	end

	return true
end

---@param key string
function Part:getValue(key)
	if key == "alphaThreshold" then
		return self.offsetMaskThreshold
	elseif key == "opacity" then
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
	elseif key == "emissionStrength" then
		return self.offsetEmissionStrength
	else
		return Drawable.getValue(self, key)
	end
end

---@param drawable Inochi2D.Drawable
function Part:isMaskedBy(drawable)
	return self:getMaskIdx(drawable) >= 0
end

---@param drawable integer|(Inochi2D.Drawable?)
function Part:getMaskIdx(drawable)
	local id = nil

	if type(drawable) == "number" then
		id = drawable
	elseif drawable then
		---@cast drawable Inochi2D.Drawable
		id = drawable:uuid()
	end

	if id then
		for i, mask in ipairs(self.masks) do
			if mask.maskSrc and mask.maskSrc:uuid() == id then
				return i - 1
			end
		end
	end

	return -1
end

function Part:beginUpdate()
	self.offsetMaskThreshold = 0
	self.offsetOpacity = 1
	self.offsetTint[1], self.offsetTint[2], self.offsetTint[3] = 1, 1, 1
	self.offsetScreenTint[1], self.offsetScreenTint[2], self.offsetScreenTint[3] = 0, 0, 0
	self.offsetEmissionStrength = 0
	return Drawable.beginUpdate(self)
end

---@param data Inochi2D.MeshData
function Part:rebuffer(data)
	Drawable.rebuffer(self, data)
	self:updateUVs()
end

function Part:draw()
	if self.enabled then
		self:drawOne()

		for _, child in ipairs(self:children()) do
			child:draw()
		end
	end
end

function Part:drawOne()
	if self.enabled and self.data:isReady() then
		if #self.masks > 0 then
			Render.in2ClearMask()

			for _, mask in ipairs(self.masks) do
				if mask.maskSrc then
					mask.maskSrc:renderMask(mask.mode == "DodgeMask")
				end
			end

			Render.in2BeginMask()
			self:drawSelf()
			Render.in2EndMask()

			return
		end

		self:drawSelf()
	end

	return Drawable.drawOne(self)
end

---@param forMasking boolean
function Part:drawOneDirect(forMasking)
	return self:drawSelf(forMasking)
end

function Part:finalize()
	Drawable.finalize(self)

	local validMasks = {}

	for _, mask in ipairs(self.masks) do
		local nMask = self:puppet():find(mask.maskSrcUUID, Drawable)

		if nMask then
			---@cast nMask Inochi2D.Drawable
			mask.maskSrc = nMask
			validMasks[#validMasks+1] = mask
		end
	end

	self.masks = validMasks
end

NodesFactory.inRegisterNodeType(Part)
---@alias Inochi2D.Part_Class Inochi2D.Part
---| fun(parent?:Inochi2D.Node):Inochi2D.Part
---| fun(data:Inochi2D.MeshData,textures:(love.Texture|false)[],parent:Inochi2D.Node?):Inochi2D.Part
---| fun(data:Inochi2D.MeshData,textures:(love.Texture|false)[],uuid:integer,parent:Inochi2D.Node?):Inochi2D.Part
---@cast Part +Inochi2D.Part_Class
return Part
