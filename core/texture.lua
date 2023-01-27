---@class Inochi2D.Texture
local Texture = {}

---@param data love.ImageData
function Texture.inTexPremultiply(data)
	return data:mapPixel(function(x, y, r, g, b, a)
		return r * a, g * a, b * a, a
	end)
end

---@param data love.ImageData
function Texture.inTexUnPremultiply(data)
	return data:mapPixel(function(x, y, r, g, b, a)
		if a > 0 then
			return r / a, g / a, b / a, a
		else
			return r, g, b, a
		end
	end)
end

return Texture
