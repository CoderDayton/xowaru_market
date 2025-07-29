local AFKPointUtils = {}

function AFKPointUtils.GetGamepassMultiplier(player)
	-- TODO: Check player gamepasses
	return 1
end

function AFKPointUtils.GetConsumableMultiplier(player)
	-- TODO: Check for timed consumables/boosts
	return 1
end

function AFKPointUtils.GetFriendBonus(player)
	-- TODO: Calculate based on in-game friends
	return 1
end

function AFKPointUtils.IsVIP(player)
	-- TODO: Detect VIP status/gamepass
	return false
end

function AFKPointUtils.GetMinigameConsumableMultiplier(player)
	return 1 -- TODO
end

return AFKPointUtils