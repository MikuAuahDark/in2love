local path = (...):sub(1, -string.len(".core.param.parameter_binding_impl") - 1)

---@type Inochi2D.ParameterBinding
local ParameterBinding = require(path..".core.param.parameter_binding")
---@type Inochi2D.BindTarget_Class
local BindTarget = require(path..".core.param.bind_target")
---@type Inochi2D.UtilModule
local Util = require(path..".util")

---@class (exact) Inochi2D.ParameterBindingImpl: Inochi2D.ParameterBinding
---@field private nodeRef integer Node reference (for deserialization)
---@field private interpolateMode_ Inochi2D.InterpolateMode
---@field public parameter Inochi2D.Parameter Parent Parameter owning this binding
---@field public target Inochi2D.BindTarget Reference to what parameter we're binding to
---@field public values any[][] The value at each 2D keypoint
---@field public isSet_ boolean[][] Whether the value at each 2D keypoint is user-set
local ParameterBindingImpl = ParameterBinding:extend()

---For derived class, please call this!
---@param parameter Inochi2D.Parameter
---@param targetNode Inochi2D.Node?
---@param paramName string?
function ParameterBindingImpl:new(parameter, targetNode, paramName)
	self.nodeRef = 4294967295
	self.interpolateMode_ = "Linear"
	self.parameter = parameter
	self.target = BindTarget()
	self.values = {}
	self.isSet_ = {}

	if targetNode and paramName then
		self.target.node = targetNode
		self.target.paramName = paramName

		self:clear()
	end
end

---Gets target of binding
function ParameterBindingImpl:getTarget()
	return self.target
end

---Gets name of binding
function ParameterBindingImpl:getName()
	return self.target.paramName
end

---Gets the node of the binding
function ParameterBindingImpl:getNode()
	return self.target.node
end

---Gets the uuid of the node of the binding
function ParameterBindingImpl:getNodeUUID()
	return self.nodeRef
end

---Returns isSet_
function ParameterBindingImpl:getIsSet()
	return self.isSet_
end

function ParameterBindingImpl:serialize()
	return  {
		node = self.target.node and self.target.node.uuid or 4294967295,
		param_name = self.target.paramName,
		values = Util.serializeArray(self.values),
		isSet = Util.serializeArray(self.isSet_),
		interpolate_mode = self.interpolateMode_
	}
end

---Derived class must deserialize self.values themselves later
---@param t table<string, any>
function ParameterBindingImpl:deserialize(t)
	self.nodeRef = assert(t.node)
	self.target.paramName = assert(t.param_name)
	self.values = assert(t.values)
	self.isSet_ = assert(t.isSet)
	self.interpolateMode_ = t.interpolate_mode or "Linear"

	local xCount = self.parameter:axisPointCount(0)
	local yCount = self.parameter:axisPointCount(1)

	assert(#self.values == xCount, "Mismatched X value count")
	assert(#self.isSet_, "Mismatched X isSet_ count")

	for i = 1, xCount do
		assert(#self.values[i] == yCount, "Mismatched Y value count")
		assert(#self.isSet_[i] == yCount, "Mismatched Y isSet_ count")
	end
end

---Finalize loading of parameter
---@param puppet Inochi2D.Puppet
function ParameterBindingImpl:finalize(puppet)
	self.target.node = puppet:find(self.nodeRef)
end

---Clear all keypoint data
function ParameterBindingImpl:clear()
	local xCount = self.parameter:axisPointCount(0)
	local yCount = self.parameter:axisPointCount(1)

	-- Length is enforced

	for x = 1, xCount do
		for y = 1, yCount do
			self.values[x][y] = self:clearValue(self.values[x][y])
		end
	end
end

---Clear the value of derived type here.
---It's defined weirdly due to Lua lacking "ref" syntax.
---@generic T
---@param i T
---@return T
function ParameterBindingImpl:clearValue(i)
---@diagnostic disable-next-line: missing-return
end

---Gets the value at the specified point
---@param point In2LOVE.vec2
---@return any
function ParameterBindingImpl:getValue(point)
	return self.values[point[1] + 1][point[2] + 1]
end

---Sets value at specified keypoint
---@param point In2LOVE.vec2
---@param value any
function ParameterBindingImpl:setValue(point, value)
	self.values[point[1] + 1][point[2] + 1] = value;
	self.isSet_[point[1] + 1][point[2] + 1] = true;

	self:reInterpolate();
end

---Sets value at specified keypoint to the current value
---@param point In2LOVE.vec2
function ParameterBindingImpl:setCurrent(point)
	self.isSet_[point[1] + 1][point[2] + 1] = true;
	self:reInterpolate();
end

---Unsets value at specified keypoint
---@param point In2LOVE.vec2
function ParameterBindingImpl:unset(point)
	self.values[point[1] + 1][point[2] + 1] = self:clearValue(self.values[point[1] + 1][point[2] + 1])
	self.isSet_[point[1] + 1][point[2] + 1] = false

	self:reInterpolate()
end

---Resets value at specified keypoint to default
---@param point In2LOVE.vec2
function ParameterBindingImpl:reset(point)
	self.values[point[1] + 1][point[2] + 1] = self:clearValue(self.values[point[1] + 1][point[2] + 1])
	self.isSet_[point[1] + 1][point[2] + 1] = true

	self:reInterpolate()
end

---Returns whether the specified keypoint is set
---@param index In2LOVE.vec2
function ParameterBindingImpl:isSet(index)
	return self.isSet_[index[1] + 1][index[2] + 1]
end

---Flip the keypoints on an axis
---@param axis integer
function ParameterBindingImpl:reverseAxis(axis)
	if axis == 0 then
		Util.reverseArray(self.values)
		Util.reverseArray(self.isSet_)
	else
		for _, v in ipairs(self.values) do
			Util.reverseArray(v)
		end

		for _, v in ipairs(self.isSet_) do
			Util.reverseArray(v)
		end
	end
end

---Re-calculate interpolation
function ParameterBindingImpl:reInterpolate()
	local xCount = self.parameter:axisPointCount(0)
	local yCount = self.parameter:axisPointCount(1)

	-- Currently valid points
	---@type boolean[][]
	local valid = {}
	local validCount = 0
	local totalCount = xCount * yCount

	-- Initialize validity map to user-set points
	for x = 1, xCount do
		valid[x] = Util.copyArray(self.isSet_[x])

		for y = 1, yCount do
			if self.isSet_[x][y] then
				validCount = validCount + 1
			end
		end
	end

	-- If there are zero valid points, just clear ourselves
	if validCount == 0 then
		self:clear()
		return
	end

	-- Whether any given point was just set
	---@type boolean[][]
	local newlySet = {}
	for i = 1, xCount do
		newlySet[i] = {}
	end

	-- List of indices to commit
	---@type In2LOVE.vec2[]
	local commitPoints = {}

	-- Used by extendAndIntersect for x/y factor
	---@type number[][]
	local interpDistance = {}
	for x = 1, xCount do
		local t = {}

		for y = 1, yCount do
			t[y] = 0
		end

		interpDistance[x] = t
	end

	-- Current interpolation axis
	local yMajor = false

	-- Helpers to handle interpolation across both axes more easily
	-- TODO: Optimize routine. Function creation is expensive.
	local function majorCnt()
		if yMajor then
			return yCount
		else
			return xCount
		end
	end

	local function minorCnt()
		if yMajor then
			return xCount
		else
			return yCount
		end
	end

	---@param maj integer
	---@param min integer
	local function isValid(maj, min)
		if yMajor then
			return valid[min + 1][maj + 1]
		else
			return valid[maj + 1][min + 1]
		end
	end

	---@param maj integer
	---@param min integer
	local function isNewlySet(maj, min)
		if yMajor then
			return newlySet[min + 1][maj + 1]
		else
			return newlySet[maj + 1][min + 1]
		end
	end

	---@param maj integer
	---@param min integer
	local function get(maj, min)
		if yMajor then
			return self.values[min + 1][maj + 1]
		else
			return self.values[maj + 1][min + 1]
		end
	end

	---@param maj integer
	---@param min integer
	local function getDistance(maj, min)
		if yMajor then
			return interpDistance[min + 1][maj + 1]
		else
			return interpDistance[maj + 1][min + 1]
		end
	end

	---@param maj integer
	---@param min integer
	---@param val any
	---@param distance number
	local function reset(maj, min, val, distance)
		if yMajor then
			maj, min = min, maj
		end

		--print(string.format("set (%d, %d) -> %s", maj, min, val))
		assert(not valid[maj + 1][min + 1])
		self.values[maj + 1][min + 1] = val
		interpDistance[maj + 1][min + 1] = distance
		newlySet[maj + 1][min + 1] = true
	end

	---@param maj integer
	---@param min integer
	---@param val any
	---@param distance number?
	local function set(maj, min, val, distance)
		reset(maj, min, val, distance or 0)
		if yMajor then
			commitPoints[#commitPoints + 1] = {min, maj}
		else
			commitPoints[#commitPoints + 1] = {maj, min}
		end
	end

	---@param idx integer
	local function axisPoint(idx)
		if yMajor then
			return self.parameter.axisPoints[1][idx + 1]
		else
			return self.parameter.axisPoints[2][idx + 1]
		end
	end

	---@param maj integer
	---@param left integer
	---@param mid integer
	---@param right integer
	local function interp(maj, left, mid, right)
		local leftOff = axisPoint(left)
		local midOff = axisPoint(mid)
		local rightOff = axisPoint(right)
		local off = (midOff - leftOff) / (rightOff - leftOff)

		-- print(string.format("interp %d %d %d %d -> %f %f %f %f", maj, left, mid, right, leftOff, midOff, rightOff, off))
		return Util.lerp(get(maj, left), get(maj, right), off)
	end

	---@param secondPass boolean
	local function interpolate1D2D(secondPass)
		yMajor = secondPass
		local detectedIntersections = false

		for i = 0, majorCnt() - 1 do
			local l = 0
			local cnt = minorCnt()

			-- Find first element set
			while l < cnt and (not isValid(i, l)) do
				l = l + 1
			end

			if l < cnt then
				while true do
					-- Advance until before a missing element
					while l < cnt - 1 and isValid(i, l + 1) do
						l = l + 1
					end

					local r = l + 1

					-- Reached right side, done
					if l < (cnt - 1) then
						-- Find next set element
						while r < cnt and (not isValid(i, r)) do
							r = r + 1
						end

						-- If we ran off the edge, we're done
						if r >= cnt then
							break
						end

						-- Interpolate between the pair of valid elements
						for m = l + 1, r - 1 do
							local val = interp(i, l, m, r)

							-- If we're running the second stage of intersecting 1D interpolation
							if secondPass and isNewlySet(i, m) then
								-- Found an intersection, do not commit the previous points
								if not detectedIntersections then
									-- print(string.format("Intersection at %d, %d", i, m))
									Util.clearTable(commitPoints)
								end

								-- Average out the point at the intersection
								set(i, m, (val + get(i, m)) / 2)
								-- From now on we're only computing intersection points
								detectedIntersections = true
							end

							-- If we've found no intersections so far, continue with normal
							-- 1D interpolation.
							if not detectedIntersections then
								set(i, m, val)
							end
						end
					end

					-- Look for the next pair
					l = r
				end
			end
		end
	end

	---@param baseX integer
	---@param baseY integer
	---@param offX integer
	---@param offY integer
	local function extrapolateCorner2(baseX, baseY, offX, offY)
		local base = self.values[baseX][baseY ]
		local dX = self.values[baseX + offX][baseY] - base
		local dY = self.values[baseX][baseY + offY] - base
		self.values[baseX + offX][baseY + offY] = base + dX + dY
		commitPoints[#commitPoints + 1] = {baseX + offX, baseY + offY}
	end

	local function extrapolateCorners()
		if yCount <= 1 or xCount <= 1 then
			return
		end

		for x = 1, xCount do
			for y = 1, yCount do
				if valid[x][y] and valid[x + 1][y] and valid[x][y + 1] and (not valid[x + 1][y + 1]) then
					extrapolateCorner2(x, y, 1, 1)
				elseif valid[x][y] and valid[x + 1][y] and (not valid[x][y + 1]) and valid[x + 1][y + 1] then
					extrapolateCorner2(x + 1, y, -1, 1)
				elseif valid[x][y] and (not valid[x + 1][y]) and valid[x][y + 1] and valid[x + 1][y + 1] then
					extrapolateCorner2(x, y + 1, 1, -1)
				elseif (not valid[x][y]) and valid[x + 1][y] and valid[x][y + 1] and valid[x + 1][y + 1] then
					extrapolateCorner2(x + 1, y + 1, -1, -1)
				end
			end
		end
	end

	---@param secondPass boolean
	local function extendAndIntersect(secondPass)
		yMajor = secondPass
		local detectedIntersections = false

		-- uh
		---@param maj integer
		---@param min integer
		---@param val any
		---@param origin number
		local function setOrAverage(maj, min, val, origin)
			local minDist = math.abs(axisPoint(min) - origin)
			-- Same logic as in interpolate1D2D
			if secondPass and isNewlySet(maj, min) then
				-- Found an intersection, do not commit the previous points
				if not detectedIntersections then
					Util.clearTable(commitPoints)
				end

				local majDist = getDistance(maj, min)
				local frac = minDist / (minDist + majDist * majDist / minDist)
				-- Interpolate the point at the intersection
				set(maj, min, Util.lerp(val, get(maj, min), frac))
				-- From now on we're only computing intersection points
				detectedIntersections = true
			end

			-- If we've found no intersections so far, continue with normal
			-- 1D interpolation.
			if not detectedIntersections then
				set(maj, min, val, minDist)
			end
		end

		for i = 0, majorCnt() - 1 do
			local j = 0
			local cnt = minorCnt()

			-- Find first element set
			while j < cnt and (not isValid(i, j)) do
				j = j + 1
			end

			if j < cnt then
				-- Replicate leftwards
				local val = get(i, j)
				local origin = axisPoint(j)

				for k = 0, j - 1 do
					setOrAverage(i, k, val, origin)
				end

				-- Find last element set
				j = cnt - 1
				while not isValid(i, j) do
					j = j - 1
				end

				-- Replicate rightwards
				val = get(i, j)
				origin = axisPoint(j)
				for k = j + 1, cnt - 1 do
					setOrAverage(i, k, val, origin)
				end
			end
		end
	end

	-- Routine
	while true do
		for _, i in ipairs(commitPoints) do
			assert(not valid[i[1] + 1][i[2] + 1], "trying to double-set a point")
			valid[i[1] + 1][i[2] + 1] = true
			validCount = validCount + 1
		end

		Util.clearTable(commitPoints)

		-- Are we done?
		if validCount == totalCount then
			break
		end

		-- Reset the newlySet array
		for x = 1, xCount do
			Util.clearTable(newlySet[x])

			for y = 1, yCount do
				newlySet[x][y] = false
			end
		end

		-- Try 1D interpolation in the X-Major direction
		interpolate1D2D(false)
		-- Try 1D interpolation in the Y-Major direction, with intersection detection
		-- If this finds an intersection with the above, it will fall back to
		-- computing *only* the intersecting points as the average of the interpolated values.
		-- If that happens, the next loop will re-try normal 1D interpolation.
		interpolate1D2D(true)

		-- Did we get work done? If so, commit and loop
		if #commitPoints == 0 then
			-- Now try corner extrapolation
			extrapolateCorners()
		end

		-- Did we get work done? If so, commit and loop
		if #commitPoints == 0 then
			-- Running out of options. Expand out points in both axes outwards, but if
			-- two expansions intersect then compute the average and commit only intersections.
			-- This works like interpolate1D2D, in two passes, one per axis, changing behavior
			-- once an intersection is detected.
			extendAndIntersect(false)
			extendAndIntersect(true)
		end

		-- Should never happen
		if #commitPoints == 0 then
			break
		end
	end

	-- The above algorithm should be guaranteed to succeed in all cases.
	assert(validCount == totalCount, "Interpolation failed to complete")
end

---@param leftKeypoint In2LOVE.vec2
---@param offset In2LOVE.vec2
function ParameterBindingImpl:interpolate(leftKeypoint, offset)
	if self.interpolateMode_ == "Nearest" then
		return self:interpolateNearest(leftKeypoint, offset)
	elseif self.interpolateMode_ == "Linear" then
		return self:interpolateLinear(leftKeypoint, offset)
	elseif self.interpolateMode_ == "Cubic" then
		return self:interpolateCubic(leftKeypoint, offset)
	else
		error("unknown interpolation")
	end
end

---@param leftKeypoint In2LOVE.vec2
---@param offset In2LOVE.vec2
function ParameterBindingImpl:interpolateNearest(leftKeypoint, offset)
	local px = leftKeypoint[1] + math.floor(offset[1] + 0.5)
	local py = self.parameter.isVec2 and (leftKeypoint[2] + math.floor(offset[2] + 0.5)) or 0
	return self.values[px + 1][py + 1]
end

---@param leftKeypoint In2LOVE.vec2
---@param offset In2LOVE.vec2
function ParameterBindingImpl:interpolateLinear(leftKeypoint, offset)
	local p0, p1

	if self.parameter.isVec2 then
		local p00 = self.values[leftKeypoint[1] + 1][leftKeypoint[2] + 1]
		local p01 = self.values[leftKeypoint[1] + 1][leftKeypoint[2] + 2]
		local p10 = self.values[leftKeypoint[1] + 2][leftKeypoint[2] + 1]
		local p11 = self.values[leftKeypoint[1] + 2][leftKeypoint[2] + 2]
		p0 = Util.lerp(p00, p01, offset[2])
		p1 = Util.lerp(p10, p11, offset[2])
	else
		p0 = self.values[leftKeypoint[1] + 1][1]
		p1 = self.values[leftKeypoint[1] + 2][1]
	end

	return Util.lerp(p0, p1, offset[1])
end

---@param leftKeypoint In2LOVE.vec2
---@param offset In2LOVE.vec2
function ParameterBindingImpl:interpolateCubic(leftKeypoint, offset)
	local xkp = leftKeypoint[1]
	local xlen = #self.values - 1

	if self.parameter.isVec2 then
		local pOut = {}

		local ykp = leftKeypoint[2]
		local ylen = #self.values[1] - 1

		for y = 0, 3 do
			local yp = Util.clamp(ykp + y - 1, 0, ylen) + 1
			local p00 = self.values[math.max(xkp - 1, 0) + 1][yp]
			local p01 = self.values[xkp + 1][yp]
			local p02 = self.values[xkp + 2][yp]
			local p03 = self.values[math.min(xkp + 2, xlen) + 1][yp]
			pOut[y + 1] = Util.cubic(p00, p01, p02, p03, offset[1])
		end

		return Util.cubic(pOut[1], pOut[2], pOut[3], pOut[4], offset[2])
	else
		local p0 = self.values[math.max(xkp - 1, 0) + 1][1]
		local p1 = self.values[xkp + 1][1]
		local p2 = self.values[xkp + 2][1]
		local p3 = self.values[math.min(xkp + 2, xlen) + 1][1]
		return Util.cubic(p0, p1, p2, p3, offset[1])
	end
end

---@param leftKeypoint In2LOVE.vec2
---@param offset In2LOVE.vec2
function ParameterBindingImpl:apply(leftKeypoint, offset)
	self:applyToTarget(self:interpolate(leftKeypoint, offset))
end

---@param axis integer
---@param index integer
function ParameterBindingImpl:insertKeypoints(axis, index)
	assert(axis == 0 or axis == 1)

	if axis == 0 then
		local yCount = self.parameter:axisPointCount(1)

		local t = {}
		local s = {}
		for i = 1, yCount do
			t[i] = self:newObject()
			s[i] = false
		end

		table.insert(self.values, index + 1, t)
		table.insert(self.isSet_, index + 1, s)
	elseif axis == 1 then
		for _, i in ipairs(self.values) do
			table.insert(i, index + 1, self:newObject())
		end

		for _, i in ipairs(self.isSet_) do
			table.insert(i, index + 1, false)
		end
	end

	self:reInterpolate()
end

-- Due to Lua lacking constructor for primitive types, derived class must implement this.
function ParameterBindingImpl:newObject()
	error("need to override newObject")
	return nil
end

function ParameterBindingImpl:moveKeypoints(axis, oldindex, newindex)
	assert(axis == 0 or axis == 1)

	if axis == 0 then
		self.values[oldindex + 1], self.values[newindex + 1] = self.values[newindex + 1], self.values[oldindex + 1]
		self.isSet_[oldindex + 1], self.isSet_[newindex + 1] = self.isSet_[newindex + 1], self.isSet_[oldindex + 1]
	elseif axis == 1 then
		for _, i in ipairs(self.values) do
			i[oldindex + 1], i[newindex + 1] = i[newindex + 1], i[oldindex + 1]
		end

		for _, i in ipairs(self.isSet_) do
			i[oldindex + 1], i[newindex + 1] = i[newindex + 1], i[oldindex + 1]
		end
	end

	self:reInterpolate()
end

---@param axis integer
---@param index integer
function ParameterBindingImpl:deleteKeypoints(axis, index)
	assert(axis == 0 or axis == 1)

	if axis == 0 then
		table.remove(self.values, index + 1)
		table.remove(self.isSet_, index + 1)
	elseif axis == 1 then
		for _, i in ipairs(self.values) do
			table.remove(i, index + 1)
		end

		for _, i in ipairs(self.isSet_) do
			table.remove(i, index + 1)
		end
	end

	self:reInterpolate()
end

---@param index In2LOVE.vec2
---@param axis integer
---@param scale number
function ParameterBindingImpl:scaleValueAt(index, axis, scale)
	-- Default to just scalar scale
	self:setValue(index, self:getValue(index) * scale)
end

---@param index In2LOVE.vec2
---@param axis integer
function ParameterBindingImpl:extrapolateValueAt(index, axis)
	local offset = self.parameter:getKeypointOffset(index)
	local ok = false

	if axis <= 0 then -- axis == 0 or -1
		offset[1] = 1 - offset[1]
		ok = true
	end

	if math.abs(axis) == 1 then -- axis == 1 or -1
		offset[2] = 1 - offset[2]
		ok = true
	end

	assert(ok, "bad axis")

	local srcIndex = {0, 0} ---@type In2LOVE.vec2
	local subOffset = {0, 0} ---@type In2LOVE.vec2
	self.parameter:findOffset(offset, srcIndex, subOffset)

	local srcVal = self:interpolate(srcIndex, subOffset)

	self:setValue(index, srcVal)
	self:scaleValueAt(index, axis, -1)
end

---For derived class, please override this!
function ParameterBindingImpl:getType()
	error("need to override getType")
	return ParameterBindingImpl
end

---@param src In2LOVE.vec2
---@param other Inochi2D.ParameterBinding
---@param dest In2LOVE.vec2
function ParameterBindingImpl:copyKeypointToBinding(src, other, dest)
	if not self:isSet(src) then
		other:unset(dest)
	elseif other:is(self:getType()) then
		---@cast other Inochi2D.ParameterBindingImpl
		other:setValue(dest, self:getValue(src))
	else
		error("ParameterBinding class mismatch")
	end
end

---@param src In2LOVE.vec2
---@param other Inochi2D.ParameterBinding
---@param dest In2LOVE.vec2
function ParameterBindingImpl:swapKeypointWithBinding(src, other, dest)
	if other:is(self:getType()) then
		---@cast other Inochi2D.ParameterBindingImpl
		local tv = self.values
		local ts = self.isSet_
		local ov = other.values
		local os = other.isSet_

		-- Swap directly, to avoid clobbering by update
		ov[dest[1] + 1][dest[2] + 1], tv[src[1] + 1][src[2] + 1] = tv[src[1] + 1][src[2] + 1], ov[dest[1] + 1][dest[2] + 1]
		os[dest[1] + 1][dest[2] + 1], ts[src[1] + 1][src[2] + 1] = ts[src[1] + 1][src[2] + 1], os[dest[1] + 1][dest[2] + 1]

		self:reInterpolate()
		other:reInterpolate()
	else
		error("ParameterBinding class mismatch")
	end
end

---Gets and sets the interpolation mode
---@param mode Inochi2D.InterpolateMode
---@return Inochi2D.InterpolateMode
---@overload fun(self:Inochi2D.ParameterBindingImpl):Inochi2D.InterpolateMode
---@overload fun(self:Inochi2D.ParameterBindingImpl,mode:Inochi2D.InterpolateMode)
function ParameterBindingImpl:interpolateMode(mode)
	if mode then
		self.interpolateMode_ = mode
	else
		return self.interpolateMode_
	end
end

---Apply parameter to target node
function ParameterBindingImpl:applyToTarget(value)
	error("need to override applyToTarget")
end

---@alias Inochi2D.ParameterBindingImpl_Class Inochi2D.ParameterBindingImpl
---| fun(parameter:Inochi2D.Parameter):Inochi2D.ParameterBindingImpl
---| fun(parameter:Inochi2D.Parameter,node:Inochi2D.Node,paramName:string):Inochi2D.ParameterBindingImpl
---@cast ParameterBindingImpl +Inochi2D.ParameterBindingImpl_Class
return ParameterBindingImpl
