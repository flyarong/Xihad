local Leveler = {
	exp 	= 0,
	level 	= 1,
	grader 	= nil,
}
Leveler.__index = Leveler

function Leveler.new( level, grader, object )
	assert(grader ~= nil)
	local obj = setmetatable({
			level  = level,
			grader = grader,
		}, Leveler)
	return obj
end

function Leveler:getLevel()
	return self.level
end

function Leveler:getNextLevelExp()
	return self.grader:getNextLevelExp(self.level)
end

---
-- @return level-up information
function Leveler:_obtainExp(exp)
	local object = self:getHostObject()
	
	while exp > 0 do
		local maxGain = self:getNextLevelExp()
		local used = math.min(maxGain, exp)
		if used >= maxGain then
			self.exp = self.exp + used
			
			coroutine.yield(used, self.grader:promote(object, self.level+1))
			self.level = self.level + 1
		else
			coroutine.yield(used)
		end
		
		exp = exp - used
	end
end

function Leveler:obtainExp(exp)
	return coroutine.wrap(function()
			return self:_obtainExp(exp)
		end)
end

return Leveler