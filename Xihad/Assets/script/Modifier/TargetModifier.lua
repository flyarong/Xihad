local base = require 'Modifier.Modifier'
local TargetModifier = setmetatable({
	speed = nil,
	target= nil,
	_variable = nil,
}, base)
TargetModifier.__index = TargetModifier

function TargetModifier.new(speed, target, variable)
	assert(variable)
	local o = setmetatable(base.new(), TargetModifier)
	
	o:setSpeed(speed)
	o:setTarget(target)
	o._variable = variable
	
	return o
end

function TargetModifier:setSpeed(speed)
	self.speed = math.abs(speed)
end

function TargetModifier:setTarget(target)
	self.target = target
end

function TargetModifier:setLength(delta, length)
	error('No implementation by default')
end

function TargetModifier:between(current, expect, target)
	error('No implementation by default')
end

function TargetModifier:onUpdate(time)
	if not self.target then return end
	
	local delta = self.target - self._variable:get()
	delta = self:setLength(delta, self.speed * time)
	
	local current= self._variable:get()
	local expect = current + delta
	if not self:between(current, expect, self.target) then
		expect = self.target
	end
	
	self._variable:set(expect)
end

return TargetModifier