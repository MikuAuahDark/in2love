local path = (...):sub(1, -string.len(".core.nodes") - 1)

---@type Inochi2D.NodesPackage
local NodesPackage = require(path..".core.nodes.package")
---@type Inochi2D.Node_Class
local Node = require(path..".core.nodes.node")

---@class Inochi2D.NodesModule
local NodesModule = {}

NodesModule.Node = Node
NodesModule.inClearUUIDs = NodesPackage.inClearUUIDs
NodesModule.inCreateUUID = NodesPackage.inCreateUUID
NodesModule.inUnloadUUID = NodesPackage.inUnloadUUID

return NodesModule
