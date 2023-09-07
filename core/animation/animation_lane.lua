local path = (...):sub(1, -string.len(".core.animation.animation_lane") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.AnimationParameterRef_Class
local AnimationParamRef = require(path..".core.animation.animation_parameter_ref")
---@type Inochi2D.Keyframe_Class
local Keyframe = require(path..".core.animation.keyframe")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class (exact) Inochi2D.AnimationLane: Inochi2D.Object, Inochi2D.ISerializable
---@field private refuuid integer
---@field public paramRef Inochi2D.AnimationParameterRef Reference to parameter if any
---@field public frames Inochi2D.Keyframe[] List of frames in the lane
---@field public interpolation Inochi2D.InterpolateMode The interpolation between each frame in the lane
local AnimationLane = Object:extend()

function AnimationLane:new()
	self.refuuid = 4294967295
	self.paramRef = nil
	self.frames = {}
	self.interpolation = "Nearest"
end

function AnimationLane:serialize()
	local result = {
		interpolation = self.interpolation,
		keyframes = {}
	}

	if self.paramRef then
		result.uuid = self.paramRef.targetParam.uuid
		result.target = self.paramRef.targetAxis
	end

	-- TODO: How to serialize keyframes?
	for _, frame in ipairs(self.frames) do
		result.keyframes[#result.keyframes + 1] = frame:serialize()
	end
end

function AnimationLane:deserialize(t)
	self.interpolation = t.interpolation
	self.refuuid = t.uuid or 4294967295
	self.paramRef = AnimationParamRef()
	self.paramRef.targetAxis = t.target
	self.frames = {}

	for _, frame in ipairs(t.keyframes) do
		local k = Keyframe()
		k:deserialize(frame)
		self.frames[#self.frames + 1] = k
	end
end

---@param frame number
---@param snapSubframes boolean?
function AnimationLane:get(frame, snapSubframes)
	if #self.frames > 0 then
		-- If subframe snapping is turned on then we'll only run at the framerate
		-- of the animation, without any smooth interpolation on faster app rates.
		if snapSubframes then
			frame = math.floor(frame)
		end

		-- Fallback if there's only 1 frame
		if #self.frames == 1 then
			return self.frames[1].value
		end

		for i, f in ipairs(self.frames) do
			if f.frame > frame then
				-- Fallback to not try to index frame -1
				if i == 1 then
					return f.value
				end

				-- Interpolation "time" 0->1
				local tonext = f.frame - frame
				local ilen = f.frame - self.frames[i - 1].frame
				local t = 1 - tonext / ilen

				-- Interpolation tension 0->1
				local tension = f.tension

				if self.interpolation == "Nearest" then
					-- Nearest - Snap to the closest frame
					return t > 0.5 and f.value or self.frames[i - 1].value
				elseif self.interpolation == "Stepped" then
					-- Stepped - Snap to the current active keyframe
					return f.value
				elseif self.interpolation == "Linear" then
					-- Linear - Linearly interpolate between frame A and B
					return Util.lerp(self.frames[i - 1].value, f.value, t)
				elseif self.interpolation == "Cubic" then
					-- Cubic - Smoothly in a curve between frame A and B
					local prev = self.frames[math.max(i - 1, 1)].value
					local next1 = self.frames[math.min(i + 1, #self.frames)].value
					local next2 = self.frames[math.min(i + 2, #self.frames)].value

					-- TODO: Switch formulae, catmullrom interpolation
					return Util.cubic(prev, f.value, next1, next2, t)
				elseif self.interpolation == "Bezier" then
					-- TODO: Switch formulae, Beziér curve
					return Util.lerp(self.frames[i - 1].value, f.value, Util.clamp(Util.hermite(0, 2 * tension, 1, 2 * tension, t), 0, 1))
				else
					error("unknown interpolation "..tostring(self.interpolation))
				end
			end
		end

		return self.frames[#self.frames].value
	end

	-- Fallback, no values.
	-- Ideally we won't even call this function
	-- if there's nothing to do.
	return 0
end

---@param puppet Inochi2D.Puppet
function AnimationLane:finalize(puppet)
	if self.paramRef then
		self.paramRef.targetParam = puppet:findParameter(self.refuuid)
	end
end

---@param a Inochi2D.Keyframe
---@param b Inochi2D.Keyframe
local function frameSorter(a, b)
	return a.frame < b.frame
end

function AnimationLane:updateFrames()
	Util.sort(self.frames, frameSorter, true)
end

---@alias Inochi2D.AnimationLane_Class Inochi2D.AnimationLane
---| fun():Inochi2D.AnimationLane
---@cast AnimationLane +Inochi2D.AnimationLane_Class
return AnimationLane
