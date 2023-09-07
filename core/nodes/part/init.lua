local path = (...):sub(1, -string.len(".core.nodes.part") - 1)

---@type Inochi2D.PartPackage
local PartPackage = require(path..".core.nodes.part.package")

---@class Inochi2D.PartModule
local PartModule = {
	---@type Inochi2D.AnimatedPart_Class
	AnimatedPart = require(path..".core.nodes.part.apart"),
	---@type Inochi2D.Part_Class
	Part = require(path..".core.nodes.part.part"),

	inInitPart = PartPackage.inInitPart,
	inCreateSimplePart = PartPackage.inCreateSimplePart,
	inDrawTextureAtPart = PartPackage.inDrawTextureAtPart,
	inDrawTextureAtPosition = PartPackage.inDrawTextureAtPosition,
	inDrawTextureAtRect = PartPackage.inDrawTextureAtRect
}

return PartModule
