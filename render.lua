local path = (...):sub(1, -string.len(".render") - 1)

local love = require("love")

---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class In2LOVE.Render
local Render = {
	mesh = love.graphics.newMesh(1, "triangles", "stream"),
	---@type In2LOVE.MeshData[]
	data = {},
	---@type table<any, integer[]>
	indices = {},
	size = 0,
}

---@private
function Render.resizeMesh(size)
	if size > Render.size then
		Render.mesh = love.graphics.newMesh(size, "triangles", "stream")

		Util.clearTable(Render.data)
		for i = 1, size do
			Render.data[i] = {0, 0, 0, 0, 1, 1, 1, 1}
		end

		Render.size = size
	end
end

---@param mesh Inochi2D.MeshData
---@param deforms In2LOVE.vec2[]
---@param transform love.Transform
---@param albedo? love.Texture|false
---@param emissive? love.Texture|false
---@param bumpmap? love.Texture|false
function Render.in2DrawVertices(mesh, deforms, transform, albedo, emissive, bumpmap)
	assert(#mesh.vertices == #deforms)

	Render.resizeMesh(#mesh.vertices)

	for i, v in ipairs(mesh.vertices) do
		local m = Render.data[i]
		local d = deforms[i]
		local uv = mesh.uvs[i]
		-- m[1] = v[1] - mesh.origin[1] + d[1]
		-- m[2] = v[2] - mesh.origin[2] + d[2]
		m[1], m[2] = v[1] - mesh.origin[1] + d[1], v[2] - mesh.origin[2] + d[2]
		m[3] = uv[1]
		m[4] = uv[2]
	end

	if not Render.indices[mesh.indices] then
		local ind = {}

		for i, v in ipairs(mesh.indices) do
			ind[i] = v + 1
		end

		Render.indices[mesh.indices] = ind
	end

	Render.mesh:setVertices(Render.data, 1, #mesh.vertices)
	Render.mesh:setVertexMap(Render.indices[mesh.indices])
	Render.mesh:setDrawRange(1, #mesh.indices)
	if albedo then
		Render.mesh:setTexture(albedo)
	else
		Render.mesh:setTexture()
	end

	love.graphics.draw(Render.mesh, transform)
end

local tempStencilCallback
local tempThisArg
local function stencil()
	tempStencilCallback(tempThisArg)
end

---TODO: Support LOVE 12 stencil API
---@generic T
---@param dodge boolean|nil
---@param cb fun(self:T)
---@param thisArg T
function Render.in2DrawMask(dodge, cb, thisArg)
	-- Masks uses stencil buffer
	tempStencilCallback = cb
	tempThisArg = thisArg
	love.graphics.stencil(stencil, "replace", dodge and 0 or 1, true)
end

function Render.in2BeginMask(hasMask)
	love.graphics.clear(false, hasMask and 0 or 1)
end

---Starts masking content
function Render.in2BeginMaskContent()
	love.graphics.setStencilTest("equal", 1)
end

function Render.in2EndMask()
	love.graphics.setStencilTest()
end

Render.resizeMesh(1024)

return Render
