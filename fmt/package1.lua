---@class Inochi2D.FmtPackage1
local FmtPackage1 = {}

local isLoadingINP_ = false

---Gets whether the current loading state is set to INP loading
function FmtPackage1.inIsINPMode()
	return isLoadingINP_
end

---Not part of Inochi2D
---@param inpMode boolean
function FmtPackage1.inSetINPMode(inpMode)
	isLoadingINP_ = not not inpMode
end

return FmtPackage1
