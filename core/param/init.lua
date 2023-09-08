local path = (...):sub(1, -string.len(".core.param") - 1)

---@type Inochi2D.Parameter_Class
local Parameter = require(path..".core.param.parameter")

---@class Inochi2D.ParamModule
local ParamModule = {}

---@type (fun(data:table):Inochi2D.Parameter)
local createFunc = function(data)
	local param = Parameter()
	param:deserialize(data)
	return param
end

---@param data table
function ParamModule.inParameterCreate(data)
	assert(createFunc)
	return createFunc(data)
end

---@param factory fun(data:table):Inochi2D.Parameter
function ParamModule.inParameterSetFactory(factory)
	createFunc = factory
end

return ParamModule
