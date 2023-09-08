---@class Inochi2D.Binfmt
local Binfmt = {}

---Entrypoint magic bytes that define this is an Inochi2D puppet
---
---Trans Rights!
Binfmt.MAGIC_BYTES = "TRNSRTS\0"
Binfmt.TEX_SECTION = "TEX_SECT"
Binfmt.EXT_SECTION = "EXT_SECT"

---Verifies that a buffer has the Inochi2D magic bytes present.
---@param file In2LOVE.IReadable
function Binfmt.inVerifyMagicBytes(file)
	return Binfmt.inVerifySection(file, Binfmt.MAGIC_BYTES)
end

---Verifies a section
---@param file In2LOVE.IReadable
---@param section string
function Binfmt.inVerifySection(file, section)
	local buffer = file:read(#section) or ""
	return #buffer >= #section and buffer:sub(1, #section) == section
end


---Big endian
---@param file In2LOVE.IReadable
function Binfmt.readUint32(file)
	local b = file:read(4) or ""

	return b:byte(1, 1) * 16777216 + b:byte(2, 2) * 65536 + b:byte(3, 3) * 256 + b:byte(4, 4)
end

return Binfmt
