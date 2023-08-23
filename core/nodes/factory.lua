---@class Inochi2D.NodesFactory
local NodesFactory = {}

---@type table<string, Inochi2D.Node>
local registered = {}

---@param name string
---@param type Inochi2D.Node
function NodesFactory.inRegisterNodeType(name, type)
	registered[name] = type
end

---@param name string
function NodesFactory.inHasNodeType(name)
	return not not registered[name]
end

---@param name string
---@param parent Inochi2D.Node?
---@return Inochi2D.Node
function NodesFactory.inInstantiateNode(name, parent)
	return registered[name](parent)
end

return NodesFactory
