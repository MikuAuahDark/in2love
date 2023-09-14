local path = (...):sub(1, -string.len(".render") - 1)
---@cast path string

local love = require("love")

---@type In2LOVE.CanvasManager_Class
local CanvasManager = require(path..".canvasmanager")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

local DEFAULT_CLEAR = {0, 0, 0, 0}
local BLACK_TEXTURE = love.graphics.newCanvas(1, 1)

---@class In2LOVE.Render
local Render = {
	mesh = love.graphics.newMesh(1, "triangles", "stream"),
	---@type In2LOVE.MeshData[]
	data = {},
	---@type table<any, integer[]>
	indices = {},
	size = 0,

	---@type love.Canvas|nil
	previousCanvas = nil,
	modelAlbedoCanvas = CanvasManager(),
	modelEmissiveCanvas = CanvasManager(),
	modelBumpmapCanvas = CanvasManager(),
	stencilCanvas = CanvasManager("stencil8"),
	resultCanvas1 = CanvasManager(),
	resultCanvas2 = CanvasManager(),

	compositeAlbedoCanvas = CanvasManager(),
	compositeEmissiveCanvas = CanvasManager(),
	compositeBumpmapCanvas = CanvasManager(),
	compositeBounds = {0, 0, 0, 0},
	compositeQuad = love.graphics.newQuad(0, 0, 0, 0, 128, 128),

	---@type love.Shader
	shaderMask = nil,
	---@type love.Shader
	shaderComposite = nil,
	---@type love.Shader
	shaderBasic = nil,
	---@type love.Shader|nil
	currentShader = nil,
	---@type "basic"|"composite"|"mask"
	currentShaderMode = "basic",
	isCompositing = false,
}

---@param size integer
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

---@param shader string
function Render.setMaskShaderCode(shader)
	Render.shaderMask = love.graphics.newShader(shader)
end

---@param shader string
function Render.setCompositeShaderCode(shader)
	Render.shaderComposite = love.graphics.newShader(shader)
end

---@param shader string
function Render.setBasicShaderCode(shader)
	Render.shaderBasic = love.graphics.newShader(shader)
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

	if Render.currentShader and Render.currentShader ~= Render.shaderMask then
		if emissive then
			Render.currentShader:send("emissive", emissive)
		else
			Render.currentShader:send("emissive", BLACK_TEXTURE)
		end

		if bumpmap then
			Render.currentShader:send("bumpmap", bumpmap)
		else
			Render.currentShader:send("bumpmap", BLACK_TEXTURE)
		end
	end

	love.graphics.draw(Render.mesh, transform)
end

---@param blend Inochi2D.BlendingMode?
function Render.in2SetBlendMode(blend)
	if not blend then
		-- Disable blending
		love.graphics.setBlendMode("replace", "premultiplied")
	elseif blend == "Normal" then
		love.graphics.setBlendMode("alpha", "alphamultiply")
	elseif blend == "Multiply" then
		love.graphics.setBlendMode("multiply", "premultiplied")
		Render.in2SetAdvancedBlending("add", "add", "dstcolor", "dstcolor", "oneminussrcalpha", "oneminussrcalpha")
	elseif blend == "ColorDodge" then
		love.graphics.setBlendMode("lighten", "alphamultiply")
		Render.in2SetAdvancedBlending("add", "add", "dstcolor", "dstcolor", "one", "one")
	elseif blend == "LinearDodge" then
		love.graphics.setBlendMode("add", "alphamultiply")
		Render.in2SetAdvancedBlending("add", "add", "one", "one", "one", "one")
	elseif blend == "Screen" then
		love.graphics.setBlendMode("screen", "alphamultiply")
	elseif blend == "ClipToLower" then
		love.graphics.setBlendMode("replace", "alphamultiply")
		Render.in2SetAdvancedBlending("add", "add", "dstalpha", "dstalpha", "oneminussrcalpha", "oneminussrcalpha")
	elseif blend == "SliceFromLower" then
		love.graphics.setBlendMode("multiply", "premultiplied")
		Render.in2SetAdvancedBlending("subtract", "subtract", "oneminusdstalpha", "oneminusdstalpha", "oneminussrcalpha", "oneminussrcalpha")
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
	if not Render.isCompositing then
		Render.compositeBounds[1], Render.compositeBounds[2], Render.compositeBounds[3], Render.compositeBounds[4] = 0, 0, 0, 0
		love.graphics.setCanvas({
			Render.compositeAlbedoCanvas:get(),
			Render.compositeEmissiveCanvas:get(),
			Render.compositeBumpmapCanvas:get(),
			depthstencil = Render.stencilCanvas:get()
		})
		love.graphics.clear(DEFAULT_CLEAR, DEFAULT_CLEAR, DEFAULT_CLEAR)
		Render.isCompositing = true
	end
end

function Render.in2EndComposite()
	if Render.isCompositing then
		Render.compositeQuad:setViewport(
			Render.compositeBounds[1],
			Render.compositeBounds[2],
			Render.compositeBounds[3] - Render.compositeBounds[1],
			Render.compositeBounds[4] - Render.compositeBounds[2],
			Render.compositeAlbedoCanvas:get():getDimensions()
		)
		love.graphics.setCanvas({
			Render.modelAlbedoCanvas:get(),
			Render.modelEmissiveCanvas:get(),
			Render.modelBumpmapCanvas:get(),
			depthstencil = Render.stencilCanvas:get()
		})
		Render.isCompositing = false
	end
end

function Render.in2MergeComposite()
	if Render.currentShader then
		Render.currentShader:send("emissive", Render.compositeEmissiveCanvas:get())
		Render.currentShader:send("bumpmap", Render.compositeBumpmapCanvas:get())
	end

	love.graphics.push()
	love.graphics.origin()
	love.graphics.draw(Render.compositeAlbedoCanvas:get())
	love.graphics.flushBatch()
	love.graphics.pop()
end

---@param multColor In2LOVE.vec3
---@param screenColor In2LOVE.vec3
---@param opacity number
function Render.in2ActivateCompositeShader(multColor, screenColor, opacity)
	love.graphics.setShader(Render.shaderBasic)
	Render.currentShader = Render.shaderBasic
	Render.currentShaderMode = "basic"

	Render.shaderBasic:sendColor("screenColor", screenColor)
	love.graphics.setColor(multColor[1], multColor[2], multColor[3], opacity)
end

---@param multColor In2LOVE.vec3
---@param screenColor In2LOVE.vec3
---@param opacity number
---@param emissionStrength number?
function Render.in2ActivateBasicShader(multColor, screenColor, opacity, emissionStrength)
	love.graphics.setShader(Render.shaderBasic)
	Render.currentShader = Render.shaderBasic
	Render.currentShaderMode = "basic"

	Render.shaderBasic:sendColor("screenColor", screenColor)
	Render.shaderBasic:send("emissionStrength", emissionStrength or 1)
	love.graphics.setColor(multColor[1], multColor[2], multColor[3], opacity)
end

---@param threshold number
---@param opacity number?
function Render.in2ActivateMaskShader(threshold, opacity)
	love.graphics.setShader(Render.shaderMask)
	Render.currentShader = Render.shaderMask
	Render.currentShaderMode = "mask"

	Render.shaderMask:send("threshold", threshold)
	love.graphics.setColor(1, 1, 1, opacity)
end

function Render.in2BeginModelRender()
	local w, h = love.graphics.getDimensions()
	Render.stencilCanvas:update(w, h)
	Render.modelAlbedoCanvas:update(w, h)
	Render.modelBumpmapCanvas:update(w, h)
	Render.modelEmissiveCanvas:update(w, h)
	Render.compositeAlbedoCanvas:update(w, h)
	Render.compositeEmissiveCanvas:update(w, h)
	Render.compositeBumpmapCanvas:update(w, h)
	Render.resultCanvas1:update(w, h)
	Render.resultCanvas2:update(w, h)

	Render.previousCanvas = love.graphics.getCanvas()
	love.graphics.push("all")
	love.graphics.push("all")
	love.graphics.setCanvas({
		Render.modelAlbedoCanvas:get(),
		Render.modelEmissiveCanvas:get(),
		Render.modelBumpmapCanvas:get(),
		depthstencil = Render.stencilCanvas:get()
	})
	love.graphics.clear(DEFAULT_CLEAR, DEFAULT_CLEAR, DEFAULT_CLEAR)
end

function Render.in2EndModelRender()
	love.graphics.pop()
	love.graphics.setCanvas(Render.previousCanvas)
	love.graphics.origin()
	love.graphics.draw(Render.modelAlbedoCanvas:get())
	love.graphics.pop()
end

local relpath = path:gsub("%.", "/")
Render.resizeMesh(1024)
Render.setBasicShaderCode(relpath.."/shaders/basic.glsl")
Render.setCompositeShaderCode(relpath.."/shaders/composite.glsl")
Render.setMaskShaderCode(relpath.."/shaders/mask.glsl")

return Render
