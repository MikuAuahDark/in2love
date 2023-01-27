---@class Inochi2D.fmt
local Format = {}

---Loads a puppet from a file
---@param path string
function Format.inLoadPuppet(path)
end

---Loads a puppet from memory
---@param data string
function Format.inLoadPuppetFromMemory(data)
end

---Loads a JSON based puppet
---@param data string
function Format.inLoadJSONPuppet(data)
end

---Loads a INP based puppet
---@param buffer string
function Format.inLoadINPPuppet(buffer)
end

---Writes Inochi2D puppet to file
---@param p Inochi2D.Puppet
function Format.inWriteINPPuppet(p)
end

---Writes a puppet to file
---@param p Inochi2D.Puppet
function Format.inWriteJSONPuppet(p)
end

Format.IN_TEX_PNG = 0 -- PNG encoded Inochi2D texture
Format.IN_TEX_TGA = 1 -- TGA encoded Inochi2D texture
Format.IN_TEX_BC7 = 2 -- BC7 encoded Inochi2D texture

return Format
