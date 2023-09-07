local path = (...):sub(1, -string.len(".core.nodes.drawable") - 1)

local love = require("love")

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---Mesh data
---@class Inochi2D.MeshData: Inochi2D.Object
---@field public vertices In2LOVE.vec2[] Vertices in the mesh
---@field public uvs In2LOVE.vec2[] Base uvs
---@field public indices integer[] Indices in the mesh
---@field public origin In2LOVE.vec2 Origin of the mesh
---@field public loveMesh In2LOVE.MeshData
---@field public loveMeshDirty boolean
local MeshData = Object:extend()

function MeshData:new()
	self.vertices = {}
	self.uvs = {}
	self.indices = {}
	self.origin = {0, 0}

	-- Deviates or not part of original Inochi2D
	self.loveMesh = {}
	self.loveMeshDirty = false
end

---Adds a new vertex
---@param xy In2LOVE.vec2
---@param uv In2LOVE.vec2
function MeshData:add(xy, uv)
	self.vertices[#self.vertices+1] = {xy[1], xy[2]}
	self.uvs[#self.uvs+1] = {uv[1], uv[2]}
	self.loveMeshDirty = true
end

---Clear connections/indices
function MeshData:clearConnections()
	Util.clearTable(self.indices)
end

---Connects 2 vertices together
---@param first integer
---@param second integer
function MeshData:connect(first, second)
	self.indices[#self.indices+1] = first
	self.indices[#self.indices+1] = second
end

---Find the index of a vertex
---
---Note: 1-based index!
---@param vert In2LOVE.vec2
function MeshData:find(vert)
	for i, v in ipairs(self.vertices) do
		if v[1] == vert[1] and v[2] == vert[2] then
			return i
		end
	end

	return nil
end

---Whether the mesh data is ready to be used
function MeshData:isReady()
	return #self.indices > 0 and #self.indices % 3 == 0
end

---Whether the mesh data is ready to be triangulated
function MeshData:canTriangulate()
	return #self.indices > 0 and #self.indices % 3 == 0
end

---Fixes the winding order of a mesh.
function MeshData:fixWinding()
	if self:isReady() then
		for j = 0, math.floor(#self.indices / 3) - 1 do
			local i = j * 3
			local vertA = self.vertices[self.indices[i + 1] + 1]
			local vertB = self.vertices[self.indices[i + 2] + 1]
			local vertC = self.vertices[self.indices[i + 3] + 1]
			-- TODO: Optimize this table creation
			local cr = Util.vec3Cross(
				{vertB[1] - vertA[1], vertB[2] - vertA[2], 0},
				{vertC[1] - vertA[1], vertC[2] - vertA[2], 0}
			)

			if cr[3] < 0 then
				-- Swap winding
				self.indices[i + 2], self.indices[i + 3] = self.indices[i + 3], self.indices[i + 2]
			end
		end
	end
end

---Gets connections at a certain point
---@param point integer|In2LOVE.vec2
function MeshData:connectionsAtPoint(point)
	if type(point) == "number" then
		local found = 0

		for _, index in ipairs(self.indices) do
			if index == point then
				found = found + 1
			end
		end

		return found
	else
		---@cast point In2LOVE.vec2
		local p = self:find(point)
		return p and self:connectionsAtPoint(p) or 0
	end
end

---@alias Inochi2D.MeshData_Class Inochi2D.MeshData
---| fun():Inochi2D.MeshData
---@cast MeshData +Inochi2D.MeshData_Class

function MeshData:copy()
	local new = MeshData()

	-- Copy verts
	for _, v in ipairs(self.vertices) do
		new.vertices[#new.vertices+1] = {v[1], v[2]}
	end

	-- Copy UVs
	for _, v in ipairs(self.uvs) do
		new.uvs[#new.uvs+1] = {v[1], v[2]}
	end

	-- Copy indices
	for _, v in ipairs(self.indices) do
		new.indices[#new.indices+1] = v
	end

	new.origin[1], new.origin[2] = self.origin[1], self.origin[2]

	return new
end

function MeshData:serialize()
	local verts = {}
	local uvs = {}

	for _, v in ipairs(self.vertices) do
		verts[#verts+1] = v[1]
		verts[#verts+1] = v[2]
	end

	for _, v in ipairs(self.uvs) do
		uvs[#uvs+1] = v[1]
		uvs[#uvs+1] = v[2]
	end

	return {
		verts = verts,
		uvs = uvs,
		indices = self.indices,
		origin = self.origin
	}
end

function MeshData:deserialize(t)
	if t.verts then
		assert(#t.verts % 2 == 0)

		for i = 1, #t.verts, 2 do
			self.vertices[#self.vertices+1] = {t.verts[i], t.verts[i + 1]}
		end
	end

	if t.uvs then
		assert(#t.uvs % 2 == 0)

		for i = 1, #t.uvs, 2 do
			self.uvs[#self.uvs+1] = {t.uvs[i], t.uvs[i + 1]}
		end
	end

	if t.indices then
		for _, v in ipairs(t.indices) do
			self.indices[#self.indices+1] = v
		end
	end

	if t.origin then
		self.origin[1], self.origin[2] = t.origin[1], t.origin[2]
	end
end

---@param x number|number[]
---@param y number?
local function fmtIdx(x, y)
	if type(x) == "table" then
		return x[1].."x"..x[2]
	else
		return x.."x"..y
	end
end

---Generates a quad based mesh which is cut `cuts` amount of times
---
---Example:
---```lua
---MeshData.createQuadMesh(vec2i(texture.width, texture.height), vec4(0, 0, 1, 1), vec2i(32, 16))
---```
---@param size In2LOVE.vec2 size of the mesh
---@param uvBounds In2LOVE.vec4 x, y UV coordinates + width/height in UV coordinate space
---@param cuts In2LOVE.vec2 how many time to cut the mesh on the X and Y axis
---@param origin In2LOVE.vec2
function MeshData.createQuadMesh(size, uvBounds, cuts, origin)
	cuts = cuts or {6, 6}
	origin = origin or {0, 0}

	-- Splits may not be below 2.
	local cx, cy = math.max(cuts[1], 2), math.max(cuts[2], 2)

	local data = MeshData()
	local m = {}
	local sw = math.floor(size[1] / cx)
	local sh = math.floor(size[2] / cy)
	local uvx = uvBounds[3] / cx
	local uvy = uvBounds[4] / cy

	-- Generate vertices and UVs
	for y = 0, cy do
		for x = 0, cx do
			data.vertices[#data.vertices+1] = {
				x * sw - origin[1],
				y * sh - origin[2]
			}
			data.uvs[#data.uvs+1] = {
				uvBounds[1] + x * uvx,
				uvBounds[2] + y * uvy
			}
			m[fmtIdx(x, y)] = #data.vertices - 1
		end
	end

	-- Generate indices
	local center = {math.floor(cx / 2), math.floor(cy / 2)}

	for y = 0, cy - 1 do
		for x = 0, cx - 1 do
			-- Indices
			local i0 = {x, y}
			local i1 = {x, y + 1}
			local i2 = {x + 1, y}
			local i3 = {x + 1, y + 1}

			-- We want the verticies to generate in an X pattern so that we won't have too many distortion problems
			if (x < center[1] and y < center[2]) or (x >= center[1] and y >= center[2]) then
				data.indices[#data.indices+1] = m[fmtIdx(i0)]
				data.indices[#data.indices+1] = m[fmtIdx(i2)]
				data.indices[#data.indices+1] = m[fmtIdx(i3)]
				data.indices[#data.indices+1] = m[fmtIdx(i0)]
				data.indices[#data.indices+1] = m[fmtIdx(i3)]
				data.indices[#data.indices+1] = m[fmtIdx(i1)]
			else
				data.indices[#data.indices+1] = m[fmtIdx(i0)]
				data.indices[#data.indices+1] = m[fmtIdx(i1)]
				data.indices[#data.indices+1] = m[fmtIdx(i2)]
				data.indices[#data.indices+1] = m[fmtIdx(i1)]
				data.indices[#data.indices+1] = m[fmtIdx(i2)]
				data.indices[#data.indices+1] = m[fmtIdx(i3)]
			end
		end
	end

	return data
end

return MeshData
