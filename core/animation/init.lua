local path = (...):sub(1, -string.len(".core.animation") - 1)

local love = require("love")

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---A reference to a currently playing animation
---@class Inochi2D.PlayingAnimation: Inochi2D.Object
---@field public name string
---@field public animation Inochi2D.Animation
---@field public time number
---@field public looping boolean
---@field public running boolean
---@field public paused boolean
local PlayingAnimation = Object:extend()

function PlayingAnimation:new()
	self.name = ""
	self.animation = nil
	self.time = 0
	self.looping = false
	self.running = false
	self.paused = false
end

function PlayingAnimation:advance(delta)
	if not self.paused then
		self.time = self.time + delta

		-- Animations needs to be both looping AND running before they'll loop
		-- Eg. if an animation ends then it should play the lead out if possible.
		if self.looping and self.running then
			local loopStart = math.max(self.animation.leadIn, 0) * self.animation.timestep
			local loopEnd = (self.animation.leadOut <= 0 and self.animation.length or self.animation.leadOut) * self.animation.timestep
			self.time = loopStart + math.fmod(self.time - loopStart, loopEnd - loopStart)
		end
	end
end

---@class Inochi2D.AnimationPlayer: Inochi2D.Object
---@field private parent Inochi2D.Puppet
---@field private crossfadeStart number
---@field private prevAnimation Inochi2D.PlayingAnimation?
---@field private currAnimation Inochi2D.PlayingAnimation?
---@field private additiveAnimations Inochi2D.PlayingAnimation[] All the additive animations
---@field public crossfadeFrames number How many frames of crossfade
local AnimationPlayer = Object:extend()

---@cast PlayingAnimation +fun():Inochi2D.PlayingAnimation
AnimationPlayer.PlayingAnimation = PlayingAnimation

---Constructs a new AnimationPlayer
---@param puppet Inochi2D.Puppet
function AnimationPlayer:new(puppet)
	self.parent = puppet
	self.crossfadeStart = 0
	self.prevAnimation = nil
	self.currAnimation = nil
	self.additiveAnimations = {}
	self.crossfadeFrames = 300
end

---Sets or pushes an animation either as a main or additive animation.
---This does not respect the animation mode set for the animation.
---Animations are added in a paused state, use play to play them.
---@param animation string
---@param asMain boolean
function AnimationPlayer:set(animation, asMain)
	local anims = self.parent:getAnimations()

	if anims[animation] then
		if asMain then
			self.currAnimation = PlayingAnimation()
			self.currAnimation.name = animation
			self.currAnimation.animation = anims[animation]
			self.currAnimation.time = 0
			self.currAnimation.paused = true
			self.currAnimation.running = true
		else
			-- If the current additive animations contain the animation then
			-- don't do anything.
			for _, additive in ipairs(self.additiveAnimations) do
				if additive.name == animation then
					return
				end
			end

			local anim = PlayingAnimation()
			anim.name = animation
			anim.animation = anims[animation]
			anim.time = 0
			anim.paused = true
			anim.running = true
			self.additiveAnimations[#self.additiveAnimations + 1] = anim
		end
	end
end

---Play an animation
---@param animation string
---@param looping boolean?
---@param blend boolean?
function AnimationPlayer:play(animation, looping, blend)
	local anims = self.parent:getAnimations()

	if anims[animation] then
		-- Attempt to restart main animations
		if self.currAnimation and self.currAnimation.name == animation then
			if self.prevAnimation then
				self.prevAnimation.paused = false
			end

			self.currAnimation.paused = false
			self.currAnimation.running = true
			self.currAnimation.looping = not not looping
			return
		end

		-- Attempt to restart additive animations
		for _, additive in ipairs(self.additiveAnimations) do
			if additive.name == animation then
				if additive.paused then
					additive.paused = false
				else
					additive.time = 0
				end

				return
			end
		end

		if anims[animation].additive then
			-- Add new animation to list
			-- As above will escape out early it's safe to not return here.
			local anim = PlayingAnimation()
			anim.name = animation
			anim.animation = anims[animation]
			anim.time = 0
			anim.looping = not not looping
			self.additiveAnimations[#self.additiveAnimations + 1] = anim
		else
			-- Handle setting up crossfade if it is enabled.
			if blend then
				self.prevAnimation = self.currAnimation
				self.prevAnimation.running = false

				-- NOTE: We set this even if we might not use it
				self.crossfadeStart = love.timer.getTime()
			else
				self.prevAnimation = nil
			end

			-- Add our new animation as the current animation
			self.currAnimation = PlayingAnimation()
			self.currAnimation.name = animation
			self.currAnimation.animation = anims[animation]
			self.currAnimation.time = 0
			self.currAnimation.looping = not not looping
		end
	end
end

---Pause a currently playing animation
---@param animation string
function AnimationPlayer:pause(animation)
	local anims = self.parent:getAnimations()

	if anims[animation] then
		if anims[animation].additive then
			-- Restart the animation if we already have it around.
			for _, additive in ipairs(self.additiveAnimations) do
				if additive.name == animation then
					additive.paused = true
					return
				end
			end
		end
	else
		if self.prevAnimation then
			self.prevAnimation.paused = true
		end

		if self.currAnimation then
			self.currAnimation.paused = true
		end
	end
end

---Stops the current main animation
---@param animation string
---@param immediately boolean?
function AnimationPlayer:stop(animation, immediately)
	if self.currAnimation and self.currAnimation.name == animation then
		if immediately then
			-- Immediately destroy the animations, 
			-- ending them instantaneously.
			self.currAnimation = nil
			self.prevAnimation = nil
		else
			-- Tell the animation nicely to end otherwise.
			self.currAnimation.running = false
		end
	else
		-- There can be multiple additive animations,
		-- so we need to iterate over them all (even if they're already not running)
		-- Loop backwards to handle arbitrary popping.
		for i = #self.additiveAnimations, 1, -1 do
			local anim = self.additiveAnimations[i]

			if anim.name == animation then
				if immediately then
					-- Immediately destroy the animation, 
					-- ending them instantaneously.
					table.remove(self.additiveAnimations, i)
				else
					-- Tell the animation nicely to end otherwise.
					anim.running = false
				end
			end
		end
	end
end

---Seek the specified animation to the specified frame
---@param animation string
---@param frame number
function AnimationPlayer:seek(animation, frame)
	local anims = self.parent:getAnimations()

	if anims[animation] then
		if anims[animation].additive then
			-- Seek additive animation
			for _, additive in ipairs(self.additiveAnimations) do
				if additive.name == animation then
					additive.time = frame * additive.animation.timestep
					self:stepOther(0)
					return
				end
			end
		else
			-- Seek main animation
			if self.currAnimation then
				self.currAnimation.time = frame * self.currAnimation.animation.timestep
				self:stepMain(0)
			end
		end
	end
end

---Gets the currently playing frame and subframe for the specified animation.
---@param animation string
function AnimationPlayer:tell(animation)
	local anims = self.parent:getAnimations()

	if anims[animation] then
		if anims[animation].additive then
			-- Seek additive animation
			for _, additive in ipairs(self.additiveAnimations) do
				if additive.name == animation then
					return additive.time / additive.animation.timestep
				end
			end
		else
			-- Seek main animation
			if self.currAnimation then
				return self.currAnimation.time / self.currAnimation.animation.timestep
			end
		end
	end

	-- Fallback: If there's no animation with that name then it's just stuck at frame 0
	return 0
end

---Stop all animations
---@param immediately boolean?
function AnimationPlayer:stopAll(immediately)
	if immediately then
		-- Immediately destroy the animations, 
		-- ending them instantaneously.
		self.currAnimation = nil
		self.prevAnimation = nil
		self.additiveAnimations = {}
	else
		-- Set all the animation states to not running.
		-- They'll self-destruct once they've reached the end.
		if self.currAnimation then
			self.currAnimation.running = false
		end

		if self.prevAnimation then
			self.prevAnimation.running = false
		end

		for _, anim in ipairs(self.additiveAnimations) do
			anim.running = false
		end
	end
end

---Step through the main animation
---@param delta number
function AnimationPlayer:stepMain(delta)
	if self.currAnimation then
		-- Advance time for the animations
		if self.prevAnimation then
			self.prevAnimation:advance(delta)
		end

		-- Frame is stored as a float so that we can have half-frames for higher refresh rate monitors.
		local currFrame = self.currAnimation.time / self.currAnimation.animation.timestep

		-- Iterate and step all the lanes in the current animation
		for _, lane in ipairs(self.currAnimation.animation.lanes) do
			local value = lane:get(currFrame)
			lane.paramRef.targetParam.value[lane.paramRef.targetAxis + 1] = lane.paramRef.targetParam:unmapAxis(lane.paramRef.targetAxis, value)
		end

		-- Crossfade T
		-- TODO: Adjust ct based on in/out of animation?
		local ct
		if self.crossfadeFrames <= 0 then
			ct = 1
		else
			ct = ((love.timer.getTime() - self.crossfadeStart) / self.currAnimation.animation.timestep) / self.crossfadeFrames;
		end

		-- If current animation is stopping
		if not self.currAnimation.running then
			if ct >= 1 then
				-- We're done fading, yeet!
				self.prevAnimation = nil
				self.currAnimation = nil
			else
				-- Fading logic
				for _, lane in ipairs(self.currAnimation.animation.lanes) do
					local value = Util.lerp(lane:get(currFrame), lane.paramRef.targetParam.defaults[lane.paramRef.targetAxis + 1], ct)
					lane.paramRef.targetParam.value[lane.paramRef.targetAxis + 1] = lane.paramRef.targetParam:unmapAxis(lane.paramRef.targetAxis, value);
				end
			end
		elseif self.prevAnimation then
			local prevCurrFrame = self.prevAnimation.time / self.prevAnimation.animation.timestep

			if self.prevAnimation.animation.leadOut < self.prevAnimation.animation.length then
				ct = (prevCurrFrame - self.prevAnimation.animation.leadOut) / self.prevAnimation.animation.length
			end

			if ct >= 1 then
				self.prevAnimation = nil
			else
				-- Crossfade logic
				for _, lane in ipairs(self.currAnimation.animation.lanes) do
					local value = Util.lerp(lane:get(prevCurrFrame), lane.paramRef.targetParam.value[lane.paramRef.targetAxis + 1], ct)
					lane.paramRef.targetParam.value[lane.paramRef.targetAxis + 1] = lane.paramRef.targetParam:unmapAxis(lane.paramRef.targetAxis, value);
				end
			end
		end
	end
end

---Step through the additive animations
---@param delta number
function AnimationPlayer:stepOther(delta)
	for _, anim in ipairs(self.additiveAnimations) do
		anim:advance(delta)
	end
end

---Run an animation step
---
---Paused animations will automatically be skipped to save processing resources
---@param delta number?
function AnimationPlayer:step(delta)
	delta = delta or love.timer.getDelta()

	if self.currAnimation and self.currAnimation.paused == false then
		self:stepMain(delta)
	end

	self:stepOther(delta)
end

function AnimationPlayer:getAnimTime()
	return self.currAnimation and self.currAnimation.time or 0
end

---@alias Inochi2D.AnimationPlayer_Class Inochi2D.AnimationPlayer
---| fun(puppet:Inochi2D.Puppet):Inochi2D.AnimationPlayer
---@cast AnimationPlayer +Inochi2D.AnimationPlayer_Class
return AnimationPlayer
