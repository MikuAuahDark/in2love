---@type table<integer, boolean>
local takenUUIDs = {}
local InInvalidUUID = 4294967295;

---@class Inochi2D.NodesPackage
local NodesPackage = {}

---Creates a new UUID for a node
function NodesPackage.inCreateUUID()
	while true do
		local id = math.random(0, InInvalidUUID - 1)

		-- Make sure the ID is actually unique in the current context
		if not takenUUIDs[id] then
			return id
		end
	end
end

---Unloads a single UUID from the internal listing, freeing it up for reuse
---@param id integer
function NodesPackage.inUnloadUUID(id)
	takenUUIDs[id] = nil
end

---Clears all UUIDs from the internal listing
function NodesPackage.inClearUUIDs()
    takenUUIDs = {}
end

return NodesPackage
