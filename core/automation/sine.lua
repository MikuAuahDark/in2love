local path = (...):sub(1, -string.len(".core.automation.sine") - 1)

local love = require("love")

---@type Inochi2D.Object
local Object = require(path..".lib.classic")
---@type Inochi2D.Automation_Class
local Automation = require(path..".core.automation.automation")
---@type Inochi2D.AutomationFactory
local Factory = require(path..".core.automation.factory")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@alias Inochi2D.SineType
---| "Sin"
---| "Cos"
---| "Tan"
---@type table<Inochi2D.SineType, number>|table<number, Inochi2D.SineType>
local SineType = {
	Sin = 0,
	Cos = 1,
	Tan = 2,
	[0] = "Sin",
	[1] = "Cos",
	[2] = "Tan"
}

---@class Inochi2D.SineAutomation: Inochi2D.Automation
---@field public speed number Speed of the wave
---@field public phase number The phase of the wave
---@field public sineType Inochi2D.SineType The type of wave
local SineAutomation = Automation:extend()

function SineAutomation:new(parent)
	Automation.new(self, parent)

	self.typeId = "sine"
	self.speed = 1
	self.phase = 0
	self.sineType = "Sin"
	self.theTime = love.timer.getTime()
end

---@param dt number
function SineAutomation:onUpdate(dt)
	self.theTime = self.theTime + dt

	for _, binding in ipairs(self.bindings) do
		-- "math" hackery
		local wave = self:remapRange((math[self.sineType:lower()]((self.theTime * self.speed) + self.phase) + 1) / 2, binding.range)
		binding:addAxisOffset(wave)
	end
end

function SineAutomation:serialize()
	local result = Automation.serialize(self)
	result.speed = self.speed
	result.sine_type = SineType[self.sineType]
end

function SineAutomation:deserialize(t)
	Automation.deserialize(self, t)
	self.speed = assert(t.speed)
	---@diagnostic disable-next-line: assign-type-mismatch
	self.sineType = assert(SineType[t.sine_type])
end

Factory.inRegisterAutomationType("sine", SineAutomation)
---@alias Inochi2D.SineAutomation_Class Inochi2D.SineAutomation
---| fun(parent:Inochi2D.Puppet):Inochi2D.SineAutomation
---@cast SineAutomation +Inochi2D.SineAutomation_Class
return SineAutomation
