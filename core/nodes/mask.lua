local path = (...):sub(1, -string.len(".core.nodes.mask") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.NodesFactory
local NodesFactory = require(path..".core.nodes.factory")
---@type Inochi2D.NodesPackage
local NodesPackage = require(path..".core.nodes.package")
---@type Inochi2D.Drawable
local Drawable = require(path..".core.nodes.drawable")
---@type Inochi2D.MeshData_Class
local MeshData = require(path..".core.meshdata")

---@class Inochi2D.Mask: Inochi2D.Drawable
local Mask = Drawable:extend()

function Mask:new(data1, data2, data3)
	local data, uuid, parent

	if Object.is(data1, MeshData) then
		if type(data2) == "number" then
			-- (data, uuid, parent) overload
			---@cast data1 Inochi2D.MeshData
			---@cast data2 integer
			---@cast data3 Inochi2D.Node?
			data = data1
			uuid = data2
			parent = data3
		else
			-- (data, parent) overload
			---@cast data1 Inochi2D.MeshData
			---@cast data2 Inochi2D.Node?
			data = data1
			uuid = NodesPackage.inCreateUUID()
			parent = data3
		end
	else
		-- (parent) overload
		---@cast data1 Inochi2D.Node?
		parent = data1
	end

	Drawable.new(self, data, uuid, parent)
end

---RENDERING
function Mask:drawSelf()
	-- TODO
end

function Mask:renderMask(dodge)
	-- TODO
end

function Mask:typeId()
	return "Mask"
end

function Mask:drawOneDirect(forMasking)
	self:drawSelf()
end

function Mask:draw()
	if self.enabled then
		for _, child in ipairs(self:children()) do
			child:draw()
		end
	end
end

NodesFactory.inRegisterNodeType(Mask)
---@alias Inochi2D.Mask_Class Inochi2D.Mask
---| fun(parent?:Inochi2D.Node):Inochi2D.Mask
---| fun(data:Inochi2D.MeshData,parent?:Inochi2D.Node):Inochi2D.Mask
---| fun(data:Inochi2D.MeshData,uuid:integer,parent?:Inochi2D.Node):Inochi2D.Mask
---@cast Mask +Inochi2D.Mask_Class
return Mask
