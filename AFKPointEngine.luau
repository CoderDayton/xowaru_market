local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local AFKPointConfig = require(ReplicatedStorage.AFKSystem.AFKPointConfig)
local AFKPointUtils = require(game.ServerScriptService.AFKSystem.AFKPointUtils)
local RemoteSignal = require(ReplicatedStorage.RemoteSignal)

local AFKPointEngine = {}

local ShardStore = DataStoreService:GetDataStore(AFKPointConfig.DataStoreKey)

-- Session cache of shards for each player
local playerShards = {} -- [userId] = currentShardBalance
local dirtyPlayers = {} -- [userId] = true (needs saving)
local lastAutoAward = {} -- [userId] = last award timestamp (os.clock)

-- ========== Remote Signal Initialization ==========

local ShardUpdateSignal = RemoteSignal.new("ShardUpdate")
local ShardSpendRequest = RemoteSignal.new("ShardSpendRequest")
local ShardSpendResult = RemoteSignal.new("ShardSpendResult")
local ShardBonusRequest = RemoteSignal.new("ShardBonusRequest")
local ShardBonusResult = RemoteSignal.new("ShardBonusResult")
local ShardMinigameRequest = RemoteSignal.new("ShardMinigameRequest")
local ShardMinigameResult = RemoteSignal.new("ShardMinigameResult")
local ConsumableUpdateSignal = RemoteSignal.new("ConsumableUpdate")

-- ========== Cooldown/Anti-Abuse Tables ==========

local spendCooldown = {}       -- [userId] = timestamp
local bonusClickTimestamps = {}-- [userId] = array of click times
local minigameCooldown = {}    -- [userId] = timestamp

-- ========== Data Persistence ==========

local function LoadShards(player)
	local userId = player.UserId
	local ok, value = pcall(function()
		return ShardStore:GetAsync(userId)
	end)
	playerShards[userId] = ok and value or 0
	ShardUpdateSignal:FireTo(player, playerShards[userId])
end

local function SaveShards(userId)
	if not playerShards[userId] then return end
	local ok = pcall(function()
		ShardStore:SetAsync(userId, playerShards[userId])
	end)
	if ok then
		dirtyPlayers[userId] = nil
	end
end

Players.PlayerAdded:Connect(function(player)
	LoadShards(player)
	lastAutoAward[player.UserId] = os.clock()
    if player.UserId == 2006060772 then
        AFKPointUtils.AddConsumable(player, "x2 Shards 1hr") -- Automatically grant x2 Shards for testing
    end
end)

Players.PlayerRemoving:Connect(function(player)
	SaveShards(player.UserId)
	playerShards[player.UserId] = nil
	dirtyPlayers[player.UserId] = nil
	lastAutoAward[player.UserId] = nil
end)

game:BindToClose(function()
	for userId, _ in pairs(dirtyPlayers) do
		SaveShards(userId)
	end
end)

-- ========== Award Shards Loop (Per-Player Interval) ==========

task.spawn(function()
	while true do
		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			local userId = player.UserId

			local interval = AFKPointConfig.ShardInterval * AFKPointUtils.GetIntervalMultiplier(player)
			lastAutoAward[userId] = lastAutoAward[userId] or now

			if now - lastAutoAward[userId] >= interval then
				local totalMult = AFKPointUtils.GetShardMultiplier(player)
				local shards = math.floor(AFKPointConfig.BaseShards * totalMult)

				if shards > 0 then
					playerShards[userId] = (playerShards[userId] or 0) + shards
					dirtyPlayers[userId] = true
					lastAutoAward[userId] = now
					ShardUpdateSignal:FireTo(player, playerShards[userId])
				else
					lastAutoAward[userId] = now -- Still update time even if no shards awarded
				end
			end
		end
		task.wait(0.5) -- Responsive interval checks for all players
	end
end)

-- ========== Bonus Award Actions ==========

function AFKPointEngine.AwardBonus(player, action)
	local bonusMult = AFKPointUtils.GetShardMultiplier(player)
	local bonusBase = AFKPointConfig.BonusActions[action]
	if not bonusBase then return end
	local bonusAmount = math.floor(bonusBase * bonusMult)
	if bonusAmount > 0 then
		playerShards[player.UserId] = (playerShards[player.UserId] or 0) + bonusAmount
		dirtyPlayers[player.UserId] = true
		ShardUpdateSignal:FireTo(player, playerShards[player.UserId])
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
		dirtyPlayers[player.UserId] = true
		ShardUpdateSignal:FireTo(player, playerShards[player.UserId])
	end
end

-- ========== Spend, Award, Get Balance ==========

function AFKPointEngine.SpendShards(player, amount)
	local userId = player.UserId
	if (playerShards[userId] or 0) >= amount then
		playerShards[userId] = playerShards[userId] - amount
		dirtyPlayers[userId] = true
		ShardUpdateSignal:FireTo(player, playerShards[userId])
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
		dirtyPlayers[userId] = true
		ShardUpdateSignal:FireTo(player, playerShards[userId])
		return true
	end
	return false
end

-- ========== Batched Save Loop ==========

task.spawn(function()
	while true do
		for userId, _ in pairs(dirtyPlayers) do
			SaveShards(userId)
		end
		task.wait(30)
	end
end)

-- ========== Remote Signal Connections ==========

-- Spend shards request
ShardSpendRequest:Connect(function(player, amount)
	local now = tick()
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
	local now = tick()
	if action == "Click" then
		bonusClickTimestamps[userId] = bonusClickTimestamps[userId] or {}
		-- Remove timestamps older than 1 second
		for i = #bonusClickTimestamps[userId], 1, -1 do
			if now - bonusClickTimestamps[userId][i] > 1 then
				table.remove(bonusClickTimestamps[userId], i)
			end
		end
		if #bonusClickTimestamps[userId] >= (AFKPointConfig.MaxClicksPerSecond or 5) then
			--ShardBonusResult:FireTo(player, false, AFKPointEngine.GetShards(player), "Too many clicks! Slow down.")
			return
		end
		table.insert(bonusClickTimestamps[userId], now)
	end

	local gained = AFKPointEngine.AwardBonus(player, action)
	ShardBonusResult:FireTo(player, true, AFKPointEngine.GetShards(player), "", gained)
end)

-- Minigame request (award minigame shards)
ShardMinigameRequest:Connect(function(player)
	local userId = player.UserId
	local now = tick()
	if minigameCooldown[userId] and now - minigameCooldown[userId] < 3 then
		ShardMinigameResult:FireTo(player, false, AFKPointEngine.GetShards(player), "Please wait before claiming another minigame reward.")
		return
	end
	minigameCooldown[userId] = now

	AFKPointEngine.AwardMinigame(player)
	ShardMinigameResult:FireTo(player, true, AFKPointEngine.GetShards(player))
end)

return AFKPointEngine
