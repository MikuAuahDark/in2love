local love = require("love")

local path = (...):sub(1, -string.len(".math.transform") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---@alias In2LOVE.vec4 {[1]:number,[2]:number,[3]:number,[4]:number}
---@alias In2LOVE.vec3 {[1]:number,[2]:number,[3]:number}
---@alias In2LOVE.vec2 {[1]:number,[2]:number}

---A transform
---@class (exact) Inochi2D.Transform: Inochi2D.Object
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
---@return number,number,number,number
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
_G.mat4translate = mat4translate

---@param roll number
---@param pitch number
---@param yaw number
local function mat4quatrot(roll, pitch, yaw)
	-- Copied from inmath.
	local cr = math.cos(roll / 2)
	local cp = math.cos(pitch / 2)
	local cy = math.cos(yaw / 2)
	local sr = math.sin(roll / 2)
	local sp = math.sin(pitch / 2)
	local sy = math.sin(yaw / 2)

	local w = cr * cp * cy + sr * sp * sy
	local x = sr * cp * cy - cr * sp * sy
	local y = cr * sp * cy + sr * cp * sy
	local z = cr * cp * sy - sr * sp * cy

	local xx = x ^ 2
	local xy = x * y
	local xz = x * z
	local xw = x * w
	local yy = y ^ 2
	local yz = y * z
	local yw = y * w
	local zz = z ^ 2
	local zw = z * w

	local r00 = 1 - 2 * (yy + zz)
	local r01 = 2 * (xy - zw)
	local r02 = 2 * (xz + yw)

	local r10 = 2 * (xy + zw)
	local r11 = 1 - 2 * (xx + zz)
	local r12 = 2 * (yz - xw)

	local r20 = 2 * (xz - yw)
	local r21 = 2 * (yz + xw)
	local r22 = 1 - 2 * (xx + yy)

	-- LOVE lacking 3D transform functions makes this hilarious
	return love.math.newTransform():setMatrix(
		-- FIXME: LOVE doesn't like when Z index goes beyond [-1, 1], so force Z rotation to 0
		r00, r01, 0,   0,
		r10, r11, 0,   0,
		0,   0,   1,   0,
		0,   0,   0,   1
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

	self:update()
end

---@cast Transform +fun(translation:In2LOVE.vec3?,rotation:In2LOVE.vec3?,scale:In2LOVE.vec2?):Inochi2D.Transform

---@param other Inochi2D.Transform
function Transform:calcOffset(other)
	local tnew = Transform(
		t3add(self.translation, other.translation),
		t3add(self.rotation, other.rotation),
		{self.scale[1] * other.scale[1], self.scale[2] * other.scale[2]}
	)
	return tnew
end

---Returns the result of 2 transforms multiplied together
---@param other Inochi2D.Transform
function Transform:__mul(other)
	local strs = other.trs * self.trs
	local tnew = Transform(
		-- TRANSLATION
		{mat4mulvec4(strs, 1, 1, 1, 1)},
		-- ROTATION
		t3add(self.rotation, other.rotation),
		-- SCALE
		{self.scale[1] * other.scale[1], self.scale[2] * other.scale[2]}
	)
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
		:apply(mat4translate(self.translation[1], self.translation[2], self.translation[3]))
		:apply(mat4quatrot(self.rotation[1], self.rotation[2], self.rotation[3]))
		:scale(self.scale[1], self.scale[2])
end

function Transform:clear()
	self.translation[1], self.translation[2], self.translation[3] = 0, 0, 0
	self.rotation[1], self.rotation[2], self.rotation[3] = 0, 0, 0
	self.scale[1], self.scale[2] = 1, 1
	self.trs:reset()
end

function Transform:serialize()
	local trans = {self.translation[1], self.translation[2], self.translation[3] - 1}
	return {
		trans = trans,
		rot = self.rotation,
		scale = self.scale
	}
end

function Transform:deserialize(t)
	self.translation = t.trans
	self.rotation = t.rot
	self.scale = t.scale
	self:update()
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
---@diagnostic disable-next-line: inject-field
Transform.D2 = Transform2D

---@alias Inochi2D.TransformModule
---| Inochi2D.Transform
---| +fun(translation:In2LOVE.vec3?,rotation:In2LOVE.vec3?,scale:In2LOVE.vec2?):Inochi2D.Transform
return Transform
