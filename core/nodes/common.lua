local path = (...):sub(1, -string.len(".core.nodes.common") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---@class Inochi2D.NodesCommon
local NodesCommon = {}

---@alias Inochi2D.BlendingMode
---Normal blending mode
---| "Normal"
---Multiply blending mode
---| "Multiply"
---Color Dodge
---| "ColorDodge"
---Linear Dodge
---| "LinearDodge"
---Screen
---| "Screen"
---Clip to Lower
---Special blending mode that clips the drawable
---to a lower rendered area.
---| "ClipToLower"
---Slice from Lower
---Special blending mode that slices the drawable
---via a lower rendered area.
---Basically inverse ClipToLower
---| "SliceFromLower"

---@alias Inochi2D.MaskingMode
---The part should be masked by the drawables specified
---| "Mask"
---The path should be dodge masked by the drawables specified
---| "DodgeMask"

---@param blendingMode Inochi2D.BlendingMode
function NodesCommon.inSetBlendMode(blendingMode)
	-- TODO
end

---@class Inochi2D.MaskBinding: Inochi2D.Object
---@field public maskSrcUUID integer
---@field public mode Inochi2D.MaskingMode
---@field public maskSrc Inochi2D.Drawable?
local MaskBinding = Object:extend()

---@param maskSrcUUID integer?
---@param mode Inochi2D.MaskingMode?
---@param maskSrc Inochi2D.Drawable?
function MaskBinding:new(maskSrcUUID, mode, maskSrc)
	self.maskSrcUUID = maskSrcUUID or 4294967295
	self.mode = mode or "Mask"
	self.maskSrc = maskSrc
end

function MaskBinding:serialize()
	return {
		source = self.maskSrcUUID,
		mode = self.mode
	}
end

function MaskBinding:deserialize(t)
	self.maskSrcUUID = assert(tonumber(t.source))
	self.mode = assert(t.mode)
end

---@cast MaskBinding +fun(maskSrcUUID:integer?,mode:Inochi2D.MaskingMode?,maskSrc:Inochi2D.Drawable?):Inochi2D.MaskBinding
NodesCommon.MaskBinding = MaskBinding

return NodesCommon
