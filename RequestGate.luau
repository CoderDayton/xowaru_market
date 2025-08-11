--!strict
-- Minimal guard: short cooldown between attempts + idempotence window after success.

local RequestGate = {}
RequestGate.__index = RequestGate

export type Gate = {
	lastAttempt: number,
	lastSuccess: number,
	cooldown: number,
	idempotence: number,
}

function RequestGate.new(cooldownSec: number, idempotenceSec: number): Gate
	return setmetatable({
		lastAttempt = 0,
		lastSuccess = -1e9, -- far past
		cooldown = cooldownSec,
		idempotence = idempotenceSec,
	}, RequestGate)
end

function RequestGate:canAttempt(): boolean
	local t = os.clock() -- high-resolution; good for sub-second cooldowns
	if t - self.lastAttempt < self.cooldown then
		return false
	end
	self.lastAttempt = t
	return true
end

function RequestGate:recordSuccess()
	self.lastSuccess = os.clock()
end

function RequestGate:isRecentlySuccessful(): boolean
	return (os.clock() - self.lastSuccess) <= self.idempotence
end

return RequestGate
