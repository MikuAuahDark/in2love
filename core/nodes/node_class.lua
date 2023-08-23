-- Workaround Puppet-Node cyclic dependency.
local path = (...):sub(1, -string.len(".core.nodes.node_class") - 1)

local Object = require(path..".lib.classic")
return Object:extend()
