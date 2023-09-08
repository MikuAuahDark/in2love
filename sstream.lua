local path = (...):sub(1, -string.len(".sstream") - 1)

---@type Inochi2D.Object
local Object = require(path..".lib.classic")

---@alias In2LOVE.IReadable {read:fun(self:any,nbytes:integer):(string?)}

---@class (exact) In2LOVE.StringStream: Inochi2D.Object
---@field private pos integer
---@field private buffer string
local StringStream = Object:extend()

function StringStream:new(buf)
	self.pos = 0
	self.buffer = buf
end

---@param bytes integer
function StringStream:read(bytes)
	local maxread = #self.buffer - math.min(bytes + self.pos, #self.buffer)

	if maxread > 0 then
		local result = self.buffer:sub(self.pos + 1, self.pos + maxread)
		self.pos = self.pos + maxread
		return result
	end

	return nil
end

---@param whence seekwhence?
---@param offset integer?
---@return integer
function StringStream:seek(whence, offset)
	offset = offset or 0
	whence = whence or "cur"

	if whence == "set" then
		assert(offset > 0 and offset <= #self.buffer, "Invalid seek offset")
		self.pos = offset
	elseif whence == "cur" then
		local after = self.pos + offset

		assert(after > 0 and after <= #self.buffer, "Invalid seek offset")
		self.pos = after
	elseif whence == "end" then
		local after = #self.buffer + offset

		assert(after > 0 and after <= #self.buffer, "Invalid seek offset")
		self.pos = after
	else
		error("Invalid seek mode")
	end

	return self.pos
end

---@alias In2LOVE.StringStream_Class In2LOVE.StringStream
---| fun(buf:string):In2LOVE.StringStream
---@cast StringStream +In2LOVE.StringStream_Class
return StringStream
