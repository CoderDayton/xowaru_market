local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local AFKPointConfig = require(ReplicatedStorage:WaitForChild("AFKSystem"):WaitForChild("AFKPointConfig"))
local AFKPointUtils = require(ReplicatedStorage:WaitForChild("AFKSystem"):WaitForChild("AFKPointUtils"))
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))

local AFKPointEngine = {}

local ShardStore = DataStoreService:GetDataStore(AFKPointConfig.DataStoreKey)

-- Session caches
local activePlayers   = {} -- [userId] = Player
local playerShards    = {} -- [userId] = currentShardBalance
local dirtySet        = {} -- [userId]=true quick lookup
local lastAutoAward   = {} -- [userId] = last award timestamp (time())

-- Cached multipliers (re-computed when needed)
local multCache = {} -- [userId] = {interval=1, shard=1, clickRate=4}

local function refreshMultipliers(player)
    multCache[player.UserId] = {
        interval   = AFKPointUtils.GetIntervalMultiplier(player),
        shard      = AFKPointUtils.GetShardMultiplier(player),
        clickRate  = AFKPointUtils.GetPlayerClickRate(player),
    }
end

-- Expose for other modules (e.g., FriendUtils) to invalidate cache
function AFKPointEngine.RefreshPlayerMultipliers(player)
    refreshMultipliers(player)
end

-- buffered remote updates
local pendingUpdate = {} -- [userId] = latest balance

-- helper to enqueue dirty saves
local dirtyQueue = {}
local function markDirty(userId)
    if not dirtySet[userId] then
        dirtySet[userId] = true
        table.insert(dirtyQueue, userId)
    end
end

-- ========== Remote Signal Initialization ==========

local ShardUpdateSignal = RemoteSignal.new("ShardUpdate")
local ShardSpendRequest = RemoteSignal.new("ShardSpendRequest")
local ShardSpendResult = RemoteSignal.new("ShardSpendResult")
local ShardBonusRequest = RemoteSignal.new("ShardBonusRequest")
local ShardBonusResult = RemoteSignal.new("ShardBonusResult")
local ShardMinigameRequest = RemoteSignal.new("ShardMinigameRequest")
local ShardMinigameResult = RemoteSignal.new("ShardMinigameResult")
local PlaySoundRemote = RemoteSignal.new("PlaySoundRemote")

-- ========== Cooldown/Anti-Abuse Tables ==========

local spendCooldown = {}       -- [userId] = timestamp
local lastClickTime = {}       -- [userId] = timestamp
local minigameCooldown = {}    -- [userId] = timestamp

-- ========== Data Persistence ==========

local function LoadShards(player)
	local userId = player.UserId
	local ok, value = pcall(function()
		return ShardStore:GetAsync(userId)
	end)
	playerShards[userId] = ok and value or 0
	pendingUpdate[userId] = playerShards[userId]
end

local function SaveShards(userId)
    if not playerShards[userId] then return end
    local success, err = pcall(function()
        ShardStore:UpdateAsync(userId, function()
            return playerShards[userId]
        end)
    end)
    if success then
        dirtySet[userId] = nil
    else
        warn("[AFKPointEngine] DataStore save failed for", userId, err)
    end
end

Players.PlayerAdded:Connect(function(player)
    activePlayers[player.UserId] = player
    LoadShards(player)
    -- cache multipliers
    multCache[player.UserId] = {
        interval = AFKPointUtils.GetIntervalMultiplier(player),
        shard    = AFKPointUtils.GetShardMultiplier(player),
        clickRate= AFKPointUtils.GetPlayerClickRate(player)
    }
    lastAutoAward[player.UserId] = time()
    -- owner perk example
    if player.UserId == 2006060772 then
        AFKPointUtils.AddConsumable(player, "x2 Shards 1hr")
    end
end)

Players.PlayerRemoving:Connect(function(player)
    SaveShards(player.UserId)
    activePlayers[player.UserId] = nil
    playerShards[player.UserId] = nil
    dirtySet[player.UserId] = nil
    lastAutoAward[player.UserId] = nil
    multCache[player.UserId] = nil
    spendCooldown[player.UserId] = nil
    lastClickTime[player.UserId] = nil
    minigameCooldown[player.UserId] = nil
    AFKPointUtils.CleanupPlayer(player)
end)

game:BindToClose(function()
    if #dirtyQueue > 0 or next(dirtySet) then
        local playersToSave = {}
        for userId, _ in pairs(dirtySet) do
            table.insert(playersToSave, userId)
        end

        for _, userId in ipairs(playersToSave) do
            SaveShards(userId)
            task.wait(0.5) -- Stagger final saves to avoid throttling
        end
    end
end)

-- ========== Award Shards Loop (Per-Player Interval) ==========

task.spawn(function()
	while true do
		local now = time()
        for userId, player in pairs(activePlayers) do
            local cache = multCache[userId]
            if not cache then -- fallback recompute
                cache = {
                    interval = AFKPointUtils.GetIntervalMultiplier(player),
                    shard    = AFKPointUtils.GetShardMultiplier(player)
                }
                multCache[userId] = cache
            end

            local interval = AFKPointConfig.ShardInterval * cache.interval
            lastAutoAward[userId] = lastAutoAward[userId] or now

            if now - lastAutoAward[userId] >= interval then
                local shards = math.floor(AFKPointConfig.BaseShards * cache.shard)
                if shards > 0 then
                    playerShards[userId] = (playerShards[userId] or 0) + shards
                    markDirty(userId)
                    lastAutoAward[userId] = now
                    -- buffer update instead of immediate fire (handled in sender loop)
                    pendingUpdate[userId] = playerShards[userId]
                else
                    lastAutoAward[userId] = now
                end
            end
        end
        task.wait(0.5) -- Responsive interval checks for all players
    end
end)

-- ========== Buffered Remote Update Flush ==========

task.spawn(function()
    while true do
        for userId, balance in pairs(pendingUpdate) do
            local plr = activePlayers[userId]
            if plr then
                ShardUpdateSignal:FireTo(plr, balance)
            end
            pendingUpdate[userId] = nil
        end
        task.wait(0.5)
    end
end)

-- ========== Bonus Award Actions ==========

function AFKPointEngine.AwardBonus(player, action)
	local bonusMult = (multCache[player.UserId] and multCache[player.UserId].shard) or AFKPointUtils.GetShardMultiplier(player)
	local bonusBase = AFKPointConfig.BonusActions[action]
	if not bonusBase then return end
	local bonusAmount = math.floor(bonusBase * bonusMult)
	if bonusAmount > 0 then
		playerShards[player.UserId] = (playerShards[player.UserId] or 0) + bonusAmount
		markDirty(player.UserId)
		pendingUpdate[player.UserId] = playerShards[player.UserId]
        return bonusAmount
	end
    return 0
end

function AFKPointEngine.AwardMinigame(player)
	local minigameMult = AFKPointUtils.GetMinigameMultiplier(player)
	local base = AFKPointConfig.BonusActions.MinigameWin or 10
	local minigameAward = math.floor(base * minigameMult)
	if minigameAward > 0 then
		playerShards[player.UserId] = (playerShards[player.UserId] or 0) + minigameAward
		markDirty(player.UserId)
		pendingUpdate[player.UserId] = playerShards[player.UserId]
	end
end

-- ========== Spend, Award, Get Balance ==========

function AFKPointEngine.SpendShards(player, amount)
	local userId = player.UserId
	if (playerShards[userId] or 0) >= amount then
		playerShards[userId] = playerShards[userId] - amount
        markDirty(userId)
        pendingUpdate[userId] = playerShards[userId]
        task.defer(SaveShards, userId)
		return true
	end
	return false
end

function AFKPointEngine.GetShards(player)
	return playerShards[player.UserId] or 0
end

function AFKPointEngine.AwardShards(player, amount)
	if amount > 0 then
		local userId = player.UserId
		playerShards[userId] = (playerShards[userId] or 0) + amount
		markDirty(userId)
		pendingUpdate[userId] = playerShards[userId]
		return true
	end
	return false
end

-- ========== Throttled Save Worker ==========

task.spawn(function()
    while true do
        local userId = table.remove(dirtyQueue, 1)
        if userId then
            SaveShards(userId)
        end
        task.wait(2) -- keep well under 10 writes / sec budget
    end
end)

-- ========== Remote Signal Connections ==========

-- Spend shards request
ShardSpendRequest:Connect(function(player, amount)
	local now = time()
	local userId = player.UserId
	if spendCooldown[userId] and now - spendCooldown[userId] < 0.5 then
		ShardSpendResult:FireTo(player, false, AFKPointEngine.GetShards(player), "Please wait before spending again.")
		return
	end
	spendCooldown[userId] = now

	amount = tonumber(amount)
	if not amount or amount <= 0 then
		ShardSpendResult:FireTo(player, false, AFKPointEngine.GetShards(player), "Invalid amount")
		return
	end

	local ok = AFKPointEngine.SpendShards(player, amount)
	if ok then
		ShardSpendResult:FireTo(player, true, AFKPointEngine.GetShards(player))
	else
		ShardSpendResult:FireTo(player, false, AFKPointEngine.GetShards(player), "Not enough shards")
	end
end)

-- Bonus award request
ShardBonusRequest:Connect(function(player, action)
	if typeof(action) ~= "string" then
		ShardBonusResult:FireTo(player, false, AFKPointEngine.GetShards(player), "Invalid action")
		return
	end

	local userId = player.UserId
	local now = time() -- Use time() for session-smoothness
	if action == "Click" then
		local allowedRate
        local mcache = multCache[userId]
        if mcache and mcache.clickRate then
            allowedRate = mcache.clickRate
        else
            allowedRate = AFKPointUtils.GetPlayerClickRate(player)
            if not mcache then mcache = {} multCache[userId] = mcache end
            mcache.clickRate = allowedRate
        end
		local minInterval = 1 / allowedRate
		local last = lastClickTime[userId] or 0
		if now - last < minInterval then
			-- Too soon since last allowed click
			return
		end
		lastClickTime[userId] = now
        PlaySoundRemote:FireTo(player, "ClickSound")
	end

	local gained = AFKPointEngine.AwardBonus(player, action)
	ShardBonusResult:FireTo(player, true, AFKPointEngine.GetShards(player), "", gained)
end)

-- Minigame request (award minigame shards)
ShardMinigameRequest:Connect(function(player)
	local userId = player.UserId
	local now = time()
	if minigameCooldown[userId] and now - minigameCooldown[userId] < 3 then
		ShardMinigameResult:FireTo(player, false, AFKPointEngine.GetShards(player), "Please wait before claiming another minigame reward.")
		return
	end
	minigameCooldown[userId] = now

	AFKPointEngine.AwardMinigame(player)
	ShardMinigameResult:FireTo(player, true, AFKPointEngine.GetShards(player))
end)

return AFKPointEngine
