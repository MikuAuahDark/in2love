---@class Inochi2D.Binfmt
local Binfmt = {}

---Entrypoint magic bytes that define this is an Inochi2D puppet
---
---Trans Rights!
Binfmt.MAGIC_BYTES = "TRNSRTS\0"
Binfmt.TEX_SECTION = "TEX_SECT"
Binfmt.EXT_SECTION = "EXT_SECT"

---Verifies that a buffer has the Inochi2D magic bytes present.
---@param buffer string
function Binfmt.inVerifyMagicBytes(buffer)
	return Binfmt.inVerifySection(buffer, Binfmt.MAGIC_BYTES)
end

---Verifies a section
---@param buffer string
---@param section string
function Binfmt.inVerifySection(buffer, section)
	return #buffer >= #section and buffer:sub(1, #section) == section
end

function Binfmt.inInterpretDataFromBuffer()
end

return Binfmt
