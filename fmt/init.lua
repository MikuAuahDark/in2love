---@class Inochi2D.fmt
local fmt = {}

---Loads a puppet from a file
---@param path string
function fmt.inLoadPuppet(path)
end

---Loads a puppet from memory
---@param data string
function fmt.inLoadPuppetFromMemory(data)
end

---Loads a JSON based puppet
---@param data string
function fmt.inLoadJSONPuppet(data)
end

---Loads a INP based puppet
---@param buffer string
function fmt.inLoadINPPuppet(buffer)
end

---Writes Inochi2D puppet to file
---@param p Inochi2D.Puppet
function fmt.inWriteINPPuppet(p)
end

---Writes a puppet to file
---@param p Inochi2D.Puppet
function fmt.inWriteJSONPuppet(p)
end

fmt.IN_TEX_PNG = 0 -- PNG encoded Inochi2D texture
fmt.IN_TEX_TGA = 1 -- TGA encoded Inochi2D texture
fmt.IN_TEX_BC7 = 2 -- BC7 encoded Inochi2D texture

return fmt
