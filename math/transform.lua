local love = require("love")

local path = (...):sub(1, -string.len(".math.transform") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---@alias In2LOVE.vec4 {[1]:number,[2]:number,[3]:number,[4]:number}
---@alias In2LOVE.vec3 {[1]:number,[2]:number,[3]:number}
---@alias In2LOVE.vec2 {[1]:number,[2]:number}

---A transform
---@class Inochi2D.Transform: Inochi2D.Object
---@operator mul(Inochi2D.Transform):Inochi2D.Transform
---@field private trs love.Transform
---@field public translation In2LOVE.vec3 The translation of the transform
---@field public rotation In2LOVE.vec3 The rotation of the transform
---@field public scale In2LOVE.vec2 The scale of the transform
---@field public pixelSnap boolean Whether the transform should snap to pixels
local Transform = Object:extend()

---@param a In2LOVE.vec3
---@param b In2LOVE.vec3
---@return In2LOVE.vec3
local function t3add(a, b)
	return {
		a[1] + b[1],
		a[2] + b[2],
		a[3] + b[3]
	}
end

---@param mat4 love.Transform
---@param x number
---@param y number
---@param z number
---@param w number
local function mat4mulvec4(mat4, x, y, z, w)
	-- LOVE lacking 3D transform functions makes this hilarious
	local a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p = mat4:getMatrix()
	return
		a * x + b * y + c * z + d * w,
		e * x + f * y + g * z + h * w,
		i * x + j * y + k * z + l * w,
		m * x + n * y + o * z + p * w
end

---@param x number
---@param y number
---@param z number
local function mat4translate(x, y, z)
	-- LOVE lacking 3D transform functions makes this hilarious
	return love.math.newTransform():setMatrix(
		1, 0, 0, x,
		0, 1, 0, y,
		0, 0, 1, z,
		0, 0, 0, 1
	)
end

---@param x number
---@param y number
---@param z number
local function mat4quatrot(x, y, z)
	local cr = math.cos(x * 0.5);
    local sr = math.sin(x * 0.5);
    local cp = math.cos(y * 0.5);
    local sp = math.sin(y * 0.5);
    local cy = math.cos(z * 0.5);
    local sy = math.sin(z * 0.5);
    local q3 = cr * cp * cy + sr * sp * sy;
    local q0 = sr * cp * cy - cr * sp * sy;
    local q1 = cr * sp * cy + sr * cp * sy;
    local q2 = cr * cp * sy - sr * sp * cy;

	-- First row of the rotation matrix
	local r00 = 2 * (q0 * q0 + q1 * q1) - 1
	local r01 = 2 * (q1 * q2 - q0 * q3)
	local r02 = 2 * (q1 * q3 + q0 * q2)
	-- Second row of the rotation matrix
	local r10 = 2 * (q1 * q2 + q0 * q3)
	local r11 = 2 * (q0 * q0 + q2 * q2) - 1
	local r12 = 2 * (q2 * q3 - q0 * q1)
	-- Third row of the rotation matrix
	local r20 = 2 * (q1 * q3 - q0 * q2)
	local r21 = 2 * (q2 * q3 + q0 * q1)
	local r22 = 2 * (q0 * q0 + q3 * q3) - 1

	-- LOVE lacking 3D transform functions makes this hilarious
	return love.math.newTransform():setMatrix(
		r00, r01, r02, 0,
		r10, r11, r12, 0,
		r20, r21, r22, 0,
		0,   0,   0,   1
	)
end

---@param x number
---@param y number
---@param z number
local function mat4scale(x, y, z)
	y = y or x
	z = z or math.sqrt(x * y) -- ???

	-- LOVE lacking 3D transform functions makes this hilarious
	return love.math.newTransform():setMatrix(
		x, 0, 0, 0,
		0, y, 0, 0,
		0, 0, z, 0,
		0, 0, 0, 1
	)
end

---@param translation In2LOVE.vec3?
---@param rotation In2LOVE.vec3?
---@param scale In2LOVE.vec2?
---@private
function Transform:new(translation, rotation, scale)
	self.translation = {0, 0, 0}
	self.rotation = {0, 0, 0}
	self.scale = {1, 1}
	self.pixelSnap = false
	self.trs = love.math.newTransform()

	if translation then
		self.translation[1] = translation[1]
		self.translation[2] = translation[2]
		self.translation[3] = translation[3]
	end

	if rotation then
		self.rotation[1] = rotation[1]
		self.rotation[2] = rotation[2]
		self.rotation[3] = rotation[3]
	end

	if scale then
		self.scale[1] = scale[1]
		self.scale[2] = scale[2]
	end
end

---@cast Transform +fun(translation:In2LOVE.vec3?,rotation:In2LOVE.vec3?,scale:In2LOVE.vec2?):Inochi2D.Transform

---@param other Inochi2D.Transform
function Transform:calcOffset(other)
	local tnew = Transform(
		t3add(self.translation, other.translation),
		t3add(self.rotation, other.rotation)
		{self.scale[1] * other.scale[1], self.scale[2] * other.scale[2]}
	)
	tnew:update()
	return tnew
end

---@param other Inochi2D.Transform
function Transform:__mul(other)
	-- TODO: Re-evaluate multiplication order in LOVE
	local strs = self.trs:clone():apply(other.trs)
	local tnew = Transform(
		-- TRANSLATION
		{mat4mulvec4(strs, 1, 1, 1, 1)},
		-- ROTATION
		t3add(self.rotation, other.rotation),
		-- SCALE
		{self.scale[1] * other.scale[1], self.scale[2] * other.scale[2]}
	)
	tnew.rts = strs

	return tnew
end

---Gets the matrix for this transform
---@param copy boolean?
function Transform:matrix(copy)
	if copy then
		return self.trs:clone()
	else
		return self.trs
	end
end

function Transform:update()
	self.trs:reset()
	self.trs:apply(mat4translate(self.translation[1], self.translation[2], self.translation[3]))
	self.trs:apply(mat4quatrot(self.rotation[1], self.rotation[2], self.rotation[3]))
	self.trs:apply(mat4scale(self.scale[1], self.scale[2], 1))
end

function Transform:clear()
	self.translation[1], self.translation[2], self.translation[3] = 0, 0, 0
	self.rotation[1], self.rotation[2], self.rotation[3] = 0, 0, 0
	self.scale[1], self.scale[2] = 1, 1
end

function Transform:serialize()
	return {
		trans = self.translation,
		rot = self.rotation,
		scale = self.scale
	}
end

function Transform:deserialize(t)
	self.translation = t.trans
	self.rotation = t.rot
	self.scale = t.scale
end

function Transform:clone()
	local tnew = Transform(self.translation, self.rotation, self.scale)
	tnew:update()
	return tnew
end

---@class Inochi2D.Transform2D: Inochi2D.Object
---@field private trs love.Transform
---@field public translation In2LOVE.vec2
---@field public rotation number
---@field public scale In2LOVE.vec2
local Transform2D = Object:extend()

---@param translate In2LOVE.vec2?
---@param rotation number?
---@param scale In2LOVE.vec2?
---@private
function Transform2D:new(translate, rotation, scale)
	self.translation = {0, 0}
	self.rotation = rotation or 0
	self.scale = {0, 0}

	if translate then
		self.translation[1] = translate[1]
		self.translation[2] = translate[2]
	end

	if scale then
		self.scale[1] = scale[1]
		self.scale[2] = scale[2]
	end

	self.trs = love.math.newTransform()
end

function Transform2D:matrix()
	return self.trs
end

function Transform2D:update()
	self.trs:reset()
		:translate(self.translation[1], self.translation[2])
		:rotate(self.rotation)
		:scale(self.scale[1], self.scale[2])
end

---@cast Transform2D +fun(translate:In2LOVE.vec2?,rotation:number?,scale:In2LOVE.vec2?):Inochi2D.Transform2D
Transform.D2 = Transform2D

---@alias Inochi2D.TransformModule
---| Inochi2D.Transform
---| +fun(translation:In2LOVE.vec3?,rotation:In2LOVE.vec3?,scale:In2LOVE.vec2?):Inochi2D.Transform
return Transform
