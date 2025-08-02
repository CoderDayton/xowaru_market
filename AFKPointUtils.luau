local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AFKPointConfig = require(ReplicatedStorage.AFKSystem.AFKPointConfig)
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local AFKPointUtils = {}

-- ========= Cache =========

local gamepassCache = {} -- [userId][gamepassId] = true
local activeBoosts = {} -- [userId][boostName] = { expiration, value, minigameMultiplier }

local function CheckGamepass(player, gamepassId)
    local userId = player.UserId
    gamepassCache[userId] = gamepassCache[userId] or {}
    if gamepassCache[userId][gamepassId] ~= nil then
        return gamepassCache[userId][gamepassId]
    end

    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
    end)
    gamepassCache[userId][gamepassId] = success and hasGamepass
    return hasGamepass
end

-- Activate (or extend) a consumable boost for a player
function AFKPointUtils.AddConsumable(player, boostName)
    local info = AFKPointConfig.Consumables[boostName]
    if not info then
        warn("Unknown consumable boost: " .. tostring(boostName))
        return false
    end

    local userId = player.UserId
    activeBoosts[userId] = activeBoosts[userId] or {}
    local now = os.time()
    local duration = info.Duration or 0
    local expireTime = now + duration

    local fields = {
        ShardMultiplier = info.Features and info.Features.ShardMultiplier or nil,
        MinigameMultiplier = info.Features and info.Features.MinigameMultiplier or nil,
    }

    local existing = activeBoosts[userId][boostName]
    if existing and existing.expiration and now < existing.expiration then
        -- Extend expiration only, but always update all fields!
        existing.expiration = existing.expiration + duration
        for k, v in pairs(fields) do
            existing[k] = v
        end
    else
        activeBoosts[userId][boostName] = {
            expiration = expireTime,
            ShardMultiplier = fields.ShardMultiplier,
            MinigameMultiplier = fields.MinigameMultiplier,
        }
    end
    return activeBoosts[userId][boostName]
end

function AFKPointUtils.HasConsumable(player, boostName)
    local userId = player.UserId
    return activeBoosts[userId] and activeBoosts[userId][boostName] ~= nil
end

function AFKPointUtils.RemoveConsumable(player, boostName)
    local userId = player.UserId
    if activeBoosts[userId] and activeBoosts[userId][boostName] then
        activeBoosts[userId][boostName] = nil
        return true
    end
    return false
end

function AFKPointUtils.GetGamepassMultiplier(player)
    local mult = 1
    for _, info in pairs(AFKPointConfig.Gamepasses) do
        if info.Features and info.Features.ShardMultiplier then
            if CheckGamepass(player, info.GamepassId) then
                mult = mult * info.Features.ShardMultiplier
            end
        end
    end
    return mult
end

function AFKPointUtils.GetConsumableMultiplier(player)
    local mult = 1
    local userId = player.UserId
    if activeBoosts[userId] then
        local now = os.time()
        for boostName, data in pairs(activeBoosts[userId]) do
            if data.expiration and now >= data.expiration then
                activeBoosts[userId][boostName] = nil
            elseif data.ShardMultiplier and (not data.expiration or data.expiration > now) then
                mult = mult * data.ShardMultiplier
            end
        end
    end
    return mult
end

function AFKPointUtils.GetFriendBonus(player)
    local bonus = 1
    local friendsInGame = 0
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local ok, areFriends = pcall(function()
                return player:IsFriendsWith(other.UserId)
            end)
            if ok and areFriends then
                friendsInGame += 1
            end
        end
    end
    if friendsInGame > 0 then
        bonus = 1 + 0.1 * friendsInGame
    end
    return bonus
end

-- Total multiplier for passive/click shards: gamepasses * boosts * capped friend bonus
function AFKPointUtils.GetShardMultiplier(player)
    local mult = 1
    mult = mult * AFKPointUtils.GetGamepassMultiplier(player)
    mult = mult * AFKPointUtils.GetConsumableMultiplier(player)
    if AFKPointUtils.HasPremium(player) then
        local boost = AFKPointConfig.Boosts["Premium"]
        local premiumMult = boost and boost.Features and boost.Features.ShardMultiplier or 1
        mult = mult * premiumMult
    end

    local friendMult = AFKPointUtils.GetFriendBonus(player)
    local cap = AFKPointConfig.FriendBonusCap or 1.5
    if friendMult > cap then
        friendMult = cap
    end

    mult = mult * friendMult

    return mult
end


-- Multiplier for minigame rewards: VIP + all active minigame boosts (uses Features.MinigameMultiplier)
function AFKPointUtils.GetMinigameMultiplier(player)
    local mult = 1

    -- VIP bonus
    local vipPass = AFKPointConfig.Gamepasses["VIP"]
    if vipPass and CheckGamepass(player, vipPass.GamepassId) then
        if vipPass.Features and vipPass.Features.MinigameBonus then
            mult = mult * vipPass.Features.MinigameBonus
        end
    end

    -- Active minigame consumables
    local userId = player.UserId
    if activeBoosts[userId] then
        local now = os.time()
        for boostName, data in pairs(activeBoosts[userId]) do
            if now >= data.expiration then
                activeBoosts[userId][boostName] = nil
            elseif data.MinigameMultiplier then
                mult = mult * data.MinigameMultiplier
            end
        end
    end

    return mult
end

-- Multiplier for how much faster a player receives AFK ticks (lower = faster)
function AFKPointUtils.GetIntervalMultiplier(player)
    local mult = 1
    for _, info in pairs(AFKPointConfig.Gamepasses) do
        if info.Features and info.Features.IntervalMultiplier then
            if CheckGamepass(player, info.GamepassId) then
                mult = mult * info.Features.IntervalMultiplier
            end
        end
    end
    return mult
end

-- Returns true if player is VIP (owns the VIP gamepass)
function AFKPointUtils.IsVIP(player)
    local vipPass = AFKPointConfig.Gamepasses["VIP"]
    if not vipPass then return false end
    return CheckGamepass(player, vipPass.GamepassId)
end

-- Returns true if player has Premium
function AFKPointUtils.HasPremium(player)
    return player.MembershipType == Enum.MembershipType.Premium
end

-- Returns VIP chat tag if VIP, otherwise nil
function AFKPointUtils.GetChatTag(player)
    local vipPass = AFKPointConfig.Gamepasses["VIP"]
    if not vipPass then return nil end
    if CheckGamepass(player, vipPass.GamepassId) then
        return vipPass.Features and vipPass.Features.ChatTag or nil
    end
    return nil
end

-- Returns VIP shop discount percent (int), or 0 if not VIP
function AFKPointUtils.GetDiscount(player)
    local vipPass = AFKPointConfig.Gamepasses["VIP"]
    if not vipPass then return 0 end
    if CheckGamepass(player, vipPass.GamepassId) then
        return vipPass.Features and vipPass.Features.DiscountPercent or 0
    end
    return 0
end

Players.PlayerRemoving:Connect(function(player)
    gamepassCache[player.UserId] = nil -- Clear cache on player leave
end)

return AFKPointUtils