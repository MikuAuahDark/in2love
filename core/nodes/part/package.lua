local path = (...):sub(1, -string.len(".core.nodes.part.package") - 1)

local love = require("love")

---@type Inochi2D.Part_Class
local Part = require(path..".core.nodes.part.part")
---@type Inochi2D.MeshData_Class
local MeshData = require(path..".core.meshdata")

---@class Inochi2D.PartPackage
local PartPackage = {}

function PartPackage.inInitPart()
	-- TODO
end

---Creates a simple part that is sized after the texture given
---part is created based on file path given.
---Supported file types are: png, tga and jpeg
---
---This is unoptimal for normal use and should only be used
---for real-time use when you want to add/remove parts on the fly
---@param texture string|love.Texture
---@param parent Inochi2D.Node?
---@param name string?
function PartPackage.inCreateSimplePart(texture, parent, name)
	if type(texture) == "string" then
		texture = love.graphics.newImage(texture)
	end
	name = name or "New Part"

	local w, h = texture:getDimensions()

	local data = MeshData()
	data.vertices[#data.vertices+1] = {-w / 2, -h / 2}
	data.vertices[#data.vertices+1] = {-w / 2, h / 2}
	data.vertices[#data.vertices+1] = {w / 2, -h / 2}
	data.vertices[#data.vertices+1] = {w / 2, h / 2}
	data.uvs[#data.uvs+1] = {0, 0}
	data.uvs[#data.uvs+1] = {0, 1}
	data.uvs[#data.uvs+1] = {1, 0}
	data.uvs[#data.uvs+1] = {1, 1}
	data.indices[#data.indices+1] = 0
	data.indices[#data.indices+1] = 1
	data.indices[#data.indices+1] = 2
	data.indices[#data.indices+1] = 2
	data.indices[#data.indices+1] = 1
	data.indices[#data.indices+1] = 3

	local p = Part(data, {texture}, parent)
	p.name = name

	return p
end

---Draws a texture at the transform of the specified part
---@param texture love.Texture Draws a texture at the transform of the specified part
---@param part Inochi2D.Part
function PartPackage.inDrawTextureAtPart(texture, part)
	-- TODO
end

---Draws a texture at the transform of the specified part
---@param texture love.Texture
---@param position Inochi2D.vec2
---@param opacity number?
---@param color Inochi2D.vec3?
---@param screenColor Inochi2D.vec3?
function PartPackage.inDrawTextureAtPosition(texture, position, opacity, color, screenColor)
	opacity = opacity or 1
	color = color or {1, 1, 1}
	screenColor = screenColor or {0, 0, 0}

	-- TODO
end

---STUB!
function PartPackage.inDrawTextureAtRect()
	-- TODO
end

return PartPackage
