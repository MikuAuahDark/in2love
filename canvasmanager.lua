local path = (...):sub(1, -string.len(".canvasmanager") - 1)
---@cast path string

local love = require("love")

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---@class (exact) In2LOVE.CanvasManager: Inochi2D.Object
---@field private format love.PixelFormat
---@field private canvas love.Canvas
---@field private width integer
---@field private height integer
local CanvasManager = Object:extend()

---@param format? love.PixelFormat
function CanvasManager:new(format)
	self.format = format or "normal"
	self:update(128, 128)
end

---@param width integer
---@param height integer
function CanvasManager:update(width, height)
	if self.width ~= width and self.height ~= height then
		if self.canvas then
			self.canvas:release()
		end

		self.canvas = love.graphics.newCanvas(width, height, {format = self.format})
		self.width, self.height = width, height
	end
end

function CanvasManager:get()
	return self.canvas
end

---@alias In2LOVE.CanvasManager_Class In2LOVE.CanvasManager
---| fun(format?:love.PixelFormat):In2LOVE.CanvasManager
---@cast CanvasManager +In2LOVE.CanvasManager_Class
return CanvasManager
