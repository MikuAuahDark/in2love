local path = (...):sub(1, -string.len(".core.nodes.driver.simplephysics") - 1)

---@type Inochi2D.Pendulum_Class
local Pendulum = require(path..".core.nodes.driver.pendulum")
---@type Inochi2D.Pendulum_Class
local SpringPendulum = require(path..".core.nodes.driver.spring_pendulum")
---@type Inochi2D.Driver
local Driver = require(path..".core.nodes.driver.driver")
---@type Inochi2D.NodesFactory
local NodesFactory = require(path..".core.nodes.factory")
---@type Inochi2D.NodesPackage
local NodesPackage = require(path..".core.nodes.package")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class (exact) Inochi2D.SimplePhysics: Inochi2D.Driver
---@field private paramRef integer
---@field private param_ Inochi2D.Parameter?
---@field public modelType_ Inochi2D.PhysicsModel
---@field public mapMode Inochi2D.ParamMapMode
---@field public gravity number Gravity scale (1.0 = puppet gravity)
---@field public length number Pendulum/spring rest length (pixels)
---@field public frequency number Resonant frequency (Hz)
---@field public angleDamping number Angular damping ratio
---@field public lengthDamping number Length damping ratio
---@field public outputScale In2LOVE.vec2
---@field public anchor In2LOVE.vec2
---@field public output In2LOVE.vec2
---@field public system Inochi2D.PhysicsSystem?
local SimplePhysics = Driver:extend()

---Constructs a new SimplePhysics node
function SimplePhysics:new(data1, data2)
	local uuid, parent
	if type(data1) == "number" then
		---@cast data1 integer
		---@cast data2 Inochi2D.Node?
		uuid = data1
		parent = data2
	else
		---@cast data1 Inochi2D.Node?
		uuid = NodesPackage.inCreateUUID()
		parent = data1
	end

	Driver.new(self, uuid, parent)

	self.paramRef = 4294967295
	self.param_ = nil
	self.modelType_ = "Pendulum"
	self.mapMode = "AngleLength"
	self.gravity = 1
	self.length = 100
	self.frequency = 1
	self.angleDamping = 0.5
	self.lengthDamping = 0.5
	self.outputScale = {1, 1}
	self.anchor = {0, 0}
	self.output = {0, 0}
	self.system = nil

	self:reset()
end

function SimplePhysics:typeId()
	return "SimplePhysics"
end

function SimplePhysics:serialize()
	local result = Driver.serialize(self)
	result.param = self.paramRef
	result.model_type = self.modelType_
	result.map_mode = self.mapMode
	result.gravity = self.gravity
	result.length = self.length
	result.frequency = self.frequency
	result.angle_damping = self.angleDamping
	result.length_damping = self.lengthDamping
	result.output_scale = self.outputScale
	return result
end

function SimplePhysics:deserialize(data)
	Driver.deserialize(self, data)

	if data.param then
		self.paramRef = assert(tonumber(data.param))
	end

	if data.model_type then
		assert(data.model_type == "Pendulum" or data.model_type == "SpringPendulum")
		self.modelType_ = data.model_type
	end

	if data.map_mode then
		assert(data.map_mode == "AngleLength" or data.map_mode == "XY")
		self.mapMode = data.map_mode
	end

	if data.gravity then
		self.gravity = assert(tonumber(data.gravity))
	end

	if data.length then
		self.length = assert(tonumber(data.length))
	end

	if data.frequency then
		self.frequency = assert(tonumber(data.frequency))
	end

	if data.angle_damping then
		self.angleDamping = assert(tonumber(data.angle_damping))
	end

	if data.length_damping then
		self.lengthDamping = assert(tonumber(data.length_damping))
	end

	if data.output_scale then
		self.outputScale[1] = assert(data.output_scale[1])
		self.outputScale[2] = assert(data.output_scale[2])
	end
end

---@return Inochi2D.Parameter[]
function SimplePhysics:getAffectedParameters()
	return {self:param()}
end

---@param h number
function SimplePhysics:updateDriver(h)
	assert(self.system)

	self:updateInputs()

	-- Minimum physics timestep: 0.01s
	while h > 0.01 do
		self.system:tick(0.01)
		h = h - 0.01
	end

	self.system:tick(h)
	self:updateOutputs()
end

function SimplePhysics:updateAnchors()
	assert(self.system)
	self.system:updateAnchor()
end

function SimplePhysics:updateInputs()
	self.anchor[1], self.anchor[2] = self:transform():matrix():transformPoint(0, 0)
end

function SimplePhysics:updateOutputs()
	if self.param_ then
		-- Okay, so this is confusing. We want to translate the angle back to local space,
		-- but not the coordinates.

		-- Transform the physics output back into local space.
		-- The origin here is the anchor. This gives us the local angle.		
		local localPos4X, localPos4Y = self:transform():matrix():inverseTransformPoint(self.output[1], self.output[2])
		local localAngle = Util.vecNormalize({localPos4X, localPos4Y})

		-- Figure out the relative length. We can work this out directly in global space.
		local relLength = Util.vec2Distance(self.output, self.anchor) / self.length

		local paramValX, paramValY
		if self.mapMode == "XY" then
			local localPostNormX = localAngle[1] * relLength
			local localPostNormY = localAngle[2] * relLength
			paramValX = localPostNormX
			paramValY = 1 - localPostNormY -- Y goes up for params
		elseif self.mapMode == "AngleLength" then
			local a = math.atan2(-localAngle[1], localAngle[2]) / math.pi
			paramValX, paramValY = a, relLength
		else
			error("invalid map mode")
		end

		self.param_.value[1] = paramValX * self.outputScale[1]
		self.param_.value[2] = paramValY * self.outputScale[2]
		self.param_:update()
	end
end

function SimplePhysics:reset()
	self:updateInputs()

	if self.modelType_ == "Pendulum" then
		self.system = Pendulum(self)
	elseif self.modelType_ == "SpringPendulum" then
		self.system = SpringPendulum(self)
	else
		error("invalid model type")
	end
end

function SimplePhysics:finalize()
	self.param_ = self:puppet():findParameter(self.paramRef)
	Driver.finalize(self)
	self:reset()
end

function SimplePhysics:drawDebug()
	self.system:drawDebug()
end

---@return nil
---@overload fun(self:Inochi2D.SimplePhysics):Inochi2D.Parameter?
---@overload fun(self:Inochi2D.SimplePhysics,p:Inochi2D.Parameter?)
function SimplePhysics:param(...)
	if select("#", ...) == 1 then
		-- setter
		self.param_ = ...

		if self.param_ then
			self.paramRef = self.param_.uuid
		else
			self.paramRef = 4294967295
		end
	else
		-- getter
		return self.param_
	end
end

function SimplePhysics:getScale()
	return self:puppet().physics.pixelsPerMeter
end

function SimplePhysics:getGravity()
	return self.gravity * self:puppet().physics.gravity * self:getScale()
end

---@overload fun(self:Inochi2D.SimplePhysics):Inochi2D.PhysicsModel
---@overload fun(self:Inochi2D.SimplePhysics,t:Inochi2D.PhysicsModel)
function SimplePhysics:modelType(...)
	local t = ...
	---@cast t Inochi2D.PhysicsModel?

	if t then
		self.modelType_ = t
		self:reset()
	else
		return self.modelType_
	end
end

NodesFactory.inRegisterNodeType(SimplePhysics)
---@alias Inochi2D.SimplePhysics_Class Inochi2D.SimplePhysics
---| fun(parent:Inochi2D.Node?):Inochi2D.SimplePhysics
---| fun(uuid:integer,parent:Inochi2D.Node?):Inochi2D.SimplePhysics
---@cast SimplePhysics +Inochi2D.SimplePhysics_Class
return SimplePhysics
