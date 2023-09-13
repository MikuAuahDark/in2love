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

---@param blend Inochi2D.BlendingMode
function Render.in2SetBlendMode(blend)
	if blend == "Normal" then
		love.graphics.setBlendMode("alpha", "alphamultiply")
	elseif blend == "Multiply" then
		love.graphics.setBlendMode("multiply", "premultiplied")
		Render.in2SetAdvancedBlending("add", "add", "dstcolor", "oneminussrcalpha", "dstcolor", "oneminussrcalpha")
	elseif blend == "ColorDodge" then
		love.graphics.setBlendMode("lighten", "alphamultiply")
		Render.in2SetAdvancedBlending("add", "add", "dstcolor", "one", "dstcolor", "one")
	elseif blend == "LinearDodge" then
		love.graphics.setBlendMode("add", "alphamultiply")
		Render.in2SetAdvancedBlending("add", "add", "one", "one", "one", "one")
	elseif blend == "Screen" then
		love.graphics.setBlendMode("screen", "alphamultiply")
	elseif blend == "ClipToLower" then
		love.graphics.setBlendMode("replace", "alphamultiply")
		Render.in2SetAdvancedBlending("add", "add", "dstalpha", "oneminussrcalpha", "dstalpha", "oneminussrcalpha")
	elseif blend == "SliceFromLower" then
		love.graphics.setBlendMode("multiply", "premultiplied")
		Render.in2SetAdvancedBlending("subtract", "subtract", "oneminusdstalpha", "oneminussrcalpha", "oneminusdstalpha", "oneminussrcalpha")
	else
		error("unknown blend mode "..blend)
	end
end

if love.graphics.setBlendState then
	Render.in2SetAdvancedBlending = love.graphics.setBlendState
else
	local hasffi, ffi = pcall(require, "ffi")

	if hasffi then
		local SDL = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C
		ffi.cdef[[
			void* GL_GetProcAddress(const char *proc) asm("SDL_GL_GetProcAddress");
		]]
		local glBlendEquationSeparate = ffi.cast("void(__stdcall*)(uint32_t,uint32_t)", SDL.GL_GetProcAddress("glBlendEquationSeparate"))
		local glBlendFuncSeparate = ffi.cast("void(__stdcall*)(uint32_t,uint32_t,uint32_t,uint32_t)", SDL.GL_GetProcAddress("glBlendFuncSeparate"))

		---@alias In2LOVE.BlendFunc
		---| "add"
		---| "subtract"
		local blendFunc = setmetatable({
			["add"] = 0x8006,
			["subtract"] = 0x800A
		}, {__index = function(_, k)
			error("unknown blend function "..k)
		end})

		---@alias In2LOVE.BlendFactor
		---| "one"
		---| "oneminussrcalpha"
		---| "dstcolor"
		---| "dstalpha"
		---| "oneminusdstalpha"
		local blendMode = setmetatable({
			["one"] = 1,
			["oneminussrcalpha"] = 0x0303,
			["dstcolor"] = 0x0306,
			["dstalpha"] = 0x0304,
			["oneminusdstalpha"] = 0x0305
		}, {__index = function(_, k)
			error("unknown blend factor "..k)
		end})

		---@param operationRGB In2LOVE.BlendFunc
		---@param operationA In2LOVE.BlendFunc
		---@param srcFactorRGB In2LOVE.BlendFactor
		---@param srcFactorA In2LOVE.BlendFactor
		---@param dstFactorRGB In2LOVE.BlendFactor
		---@param dstFactorA In2LOVE.BlendFactor
		function Render.in2SetAdvancedBlending(operationRGB, operationA, srcFactorRGB, srcFactorA, dstFactorRGB, dstFactorA)
			glBlendEquationSeparate(blendFunc[operationRGB], blendFunc[operationA])
			glBlendFuncSeparate(blendMode[srcFactorRGB], blendMode[dstFactorRGB], blendMode[srcFactorA], blendMode[dstFactorA])
		end
	else
		---@param operationRGB In2LOVE.BlendFunc
		---@param operationA In2LOVE.BlendFunc
		---@param srcFactorRGB In2LOVE.BlendFactor
		---@param srcFactorA In2LOVE.BlendFactor
		---@param dstFactorRGB In2LOVE.BlendFactor
		---@param dstFactorA In2LOVE.BlendFactor
		function Render.in2SetAdvancedBlending(operationRGB, operationA, srcFactorRGB, srcFactorA, dstFactorRGB, dstFactorA)
			-- Nope, sorry.
		end
	end
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

function Render.in2BeginComposite()
	-- TODO
end

function Render.in2EndComposite()
	-- TODO
end

Render.resizeMesh(1024)

return Render
