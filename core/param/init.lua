---@class Inochi2D.ParamModule
local ParamModule = {}

---@type (fun(data:table):Inochi2D.Parameter)?
local createFunc = nil

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
