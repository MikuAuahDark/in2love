local path = (...):sub(1, -string.len(".fmt.package2") - 1)

local love = require("love")

---@type Inochi2D.Puppet_Class
local Puppet = require(path..".core.puppet")
---@type Inochi2D.FmtPackage1
local FmtPackage1 = require(path..".fmt.package1")
---@type Inochi2D.Binfmt
local Binfmt = require(path..".fmt.binfmt")
---@module "in2love.lib.JSON" -- the best we can do
local JSON = require(path..".lib.JSON")
---@type In2LOVE.StringStream_Class
local StringStream = require(path..".sstream")

---@class Inochi2D.FmtPackage2
local FmtPackage2 = {}

local luafile = getmetatable(io.stdout)

local function isNonText(s)
	for i = 1, #s do
		if s:byte(i, i) < 32 then
			return true
		end
	end

	return false
end

---Loads a puppet from a file
---@param file string|love.Data|In2LOVE.IReadable
function FmtPackage2.inLoadPuppet(file)
	local f
	local close = false
	if type(file) == "string" then
		if #file < 1024 and isNonText(file) == false then
			f = assert(love.filesystem.newFile(file, "r"))
			close = true
		else
			f = StringStream(file)
		end
	elseif type(file) == "userdata" then
		if getmetatable(file) == luafile then
			---@cast file file*
			f = file
		---@diagnostic disable-next-line: undefined-field
		elseif file.typeOf then
			---@cast file love.Object
			if file:typeOf("Data") then
				---@cast file love.Data
				f = StringStream(file:getString())
			elseif file:typeOf("File") then
				---@cast file love.File
				f = file
			else
				error("unsupported love type")
			end
		end
	elseif type(file) == "table" and file.read then
		---@cast file In2LOVE.IReadable
		f = file
	else
		error("expected string, love.Data, or IReadable")
	end
	---@cast f In2LOVE.IReadable

	return FmtPackage2.inLoadINPPuppet(f)
end

---Loads a INP based puppet
---@param file In2LOVE.IReadable
function FmtPackage2.inLoadINPPuppet(file)
	assert(Binfmt.inVerifyMagicBytes(file), "Invalid data format for INP puppet/Inochi Creator INX")

	FmtPackage1.inSetINPMode(true)

	-- Find the puppet data
	local puppetDataLength = Binfmt.readUint32(file)
	local puppetData = file:read(puppetDataLength) or ""
	assert(#puppetData == puppetDataLength, "Unexpected end of file when reading puppet data")

	-- Load textures in to memory
	assert(Binfmt.inVerifySection(file, Binfmt.TEX_SECTION), "Expected Texture Blob section, got nothing!")
	local slots = {} ---@type (love.Texture|false)[]
	local slotCount = Binfmt.readUint32(file)
	FmtPackage1.inSetTextureSlots(slots)

	for _ = 1, slotCount do
		local textureLength = Binfmt.readUint32(file)
		local textureType = (file:read(1) or ""):byte(1, 1)

		if textureLength > 0 then
			local extension = ""
			if textureType == FmtPackage2.IN_TEX_PNG then
				extension = ".png"
			elseif textureType == FmtPackage2.IN_TEX_TGA then
				extension = ".tga"
			elseif textureType == FmtPackage2.IN_TEX_BC7 then
				-- TODO
				extension = ".ktx"
			end

			local fileData = love.filesystem.newFileData(file:read(textureLength) or "", extension)
			slots[#slots+1] = love.graphics.newImage(fileData)
			fileData:release()
		end
	end

	local puppet = Puppet()
	puppet:deserialize(JSON:decode(puppetData))
	puppet.textureSlots = slots
	puppet:updateTextureState()

	if Binfmt.inVerifySection(file, Binfmt.EXT_SECTION) then
		-- TODO extData
	end

	FmtPackage1.inSetTextureSlots({})

	-- We're done!
	return puppet
end

FmtPackage2.IN_TEX_PNG = 0 -- PNG encoded Inochi2D texture
FmtPackage2.IN_TEX_TGA = 1 -- TGA encoded Inochi2D texture
FmtPackage2.IN_TEX_BC7 = 2 -- BC7 encoded Inochi2D texture

return FmtPackage2
