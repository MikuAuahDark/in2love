---@class Inochi2D.FmtPackage1
local FmtPackage1 = {}

local isLoadingINP_ = false
local textureSlotsTable = {}

---Gets whether the current loading state is set to INP loading
function FmtPackage1.inIsINPMode()
	return isLoadingINP_
end

---Not part of Inochi2D
---@param inpMode boolean
function FmtPackage1.inSetINPMode(inpMode)
	isLoadingINP_ = not not inpMode
end

---Not part of Inochi2D
function FmtPackage1.inSetTextureSlots(slotstable)
	textureSlotsTable = slotstable
end

---@param id integer
---@return love.Texture|false
function FmtPackage1.inGetTextureFromId(id)
	local tex = textureSlotsTable[id + 1]
	if tex then
		return tex
	else
		return false
	end
end

return FmtPackage1
