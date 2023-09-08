local path = (...):sub(1, -string.len(".fmt") - 1)

---@param dest table
---@param modname string
local function merge(dest, modname)
	for k, v in pairs(require(modname)) do
		dest[k] = v
	end
end

---@alias Inochi2D.FmtModule Inochi2D.Binfmt|Inochi2D.FmtPackage1|Inochi2D.FmtPackage2

local FmtModule = {}

merge(FmtModule, path..".fmt.binfmt")
merge(FmtModule, path..".fmt.package1")
merge(FmtModule, path..".fmt.package2")

---@cast FmtModule Inochi2D.FmtModule
return FmtModule
