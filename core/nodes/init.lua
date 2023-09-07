local path = (...):sub(1, -string.len(".core.nodes") - 1)

---@type Inochi2D.NodesPackage
local NodesPackage = require(path..".core.nodes.package")
---@type Inochi2D.Node_Class
local Node = require(path..".core.nodes.node")

---@alias Inochi2D.BlendingMode
---Normal blending mode
---| "Normal"
---Multiply blending mode
---| "Multiply"
---Color Dodge
---| "ColorDodge"
---Linear Dodge
---| "LinearDodge"
---Screen
---| "Screen"
---Clip to Lower
---Special blending mode that clips the drawable
---to a lower rendered area.
---| "ClipToLower"
---Slice from Lower
---Special blending mode that slices the drawable
---via a lower rendered area.
---Basically inverse ClipToLower
---| "SliceFromLower"

---@class Inochi2D.NodesModule
local NodesModule = {}

NodesModule.Node = Node
NodesModule.inClearUUIDs = NodesPackage.inClearUUIDs
NodesModule.inCreateUUID = NodesPackage.inCreateUUID
NodesModule.inUnloadUUID = NodesPackage.inUnloadUUID

return NodesModule
