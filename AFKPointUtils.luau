local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AFKPointConfig = require(ReplicatedStorage.AFKSystem.AFKPointConfig)
local MarketplaceService = game:GetService("MarketplaceService")
local FriendService = game:GetService("FriendService")

local AFKPointUtils = {}

function AFKPointUtils.GetGamepassMultiplier(player)
    local gamepassMultiplier = 1
	for _, gamepass in pairs(AFKPointConfig.Gamepasses) do
        local success, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepass.GamePassId)
        end)
        if success and owns and gamepass.Features and gamepass.Features.ShardMultiplier then
            gamepassMultiplier = gamepassMultiplier * (gamepass.ShardMultiplier or 1)
        end
    end
	return gamepassMultiplier
end

function AFKPointUtils.GetConsumableMultiplier(player)
    local consumableMultiplier = 1
    -- for name, con in pairs(AFKPointConfig.Consumables) do
    --     if PlayerHasActiveConsumable(player, name) and con.Features and con.Features.ShardMultiplier then
    --         consumableMultiplier = consumableMultiplier * con.Features.ShardMultiplier
    --     end
    -- end
    return consumableMultiplier
end

function AFKPointUtils.GetFriendBonus(player)
    local friendBonus = 1
    local ok, friends = pcall(function() return FriendService:GetFriendsAsync(player.UserId) end)
    if ok and #friends > 0 then
        local bonus = AFKPointConfig.Boosts["Friend Invite"].Features.ShardMultiplier or 0.1 -- 10% per friend
        friendBonus = 1 + (#friends * bonus)
    end

	local cap = AFKPointConfig.FriendBonusCap or 1
	if friendBonus > cap then
		friendBonus = cap
	end
	return friendBonus
end

function AFKPointUtils.IsVIP(player)
	-- TODO: Detect VIP status/gamepass
	return false
end

function AFKPointUtils.GetMinigameMultiplier(player)
	local mult = 1

    -- Gamepasses
    for _, gamepass in pairs(AFKPointConfig.Gamepasses) do
        local success, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepass.GamePassId)
        end)
        if success and owns and gamepass.Features and gamepass.Features.MinigameMultiplier then
            mult = mult * (gamepass.MinigameMultiplier or 1)
        end
    end

    -- for name, con in pairs(AFKPointConfig.Consumables) do
    --     if PlayerHasActiveConsumable(player, name) and con.Features and con.Features.MinigameMultiplier then
    --         mult = mult * con.Features.MinigameMultiplier
    --     end
    -- end

    return mult
end

return AFKPointUtils