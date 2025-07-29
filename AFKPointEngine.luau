print("AFKPointEngine loaded")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local AFKPointConfig = require(ReplicatedStorage.AFKSystem.AFKPointConfig)
local AFKPointUtils = require(ReplicatedStorage.AFKSystem.AFKPointUtils)
local RemoteSignal = require(ReplicatedStorage.RemoteSignal)

local AFKPointEngine = {}

local ShardStore = DataStoreService:GetDataStore(AFKPointConfig.DataStoreKey)

-- Session cache of shards for each player
local playerShards = {} -- [userId] = currentShardBalance
local dirtyPlayers = {} -- [userId] = true (needs saving)
local lastAutoAward = {} -- [userId] = last award timestamp

-- ========== Remote Signal Initialization ==========

local ShardUpdateSignal = RemoteSignal.new("ShardUpdate")

local ShardSpendRequest = RemoteSignal.new("ShardSpendRequest")
local ShardSpendResult = RemoteSignal.new("ShardSpendResult")
local ShardBonusRequest = RemoteSignal.new("ShardBonusRequest")
local ShardBonusResult = RemoteSignal.new("ShardBonusResult")
local ShardMinigameRequest = RemoteSignal.new("ShardMinigameRequest")
local ShardMinigameResult = RemoteSignal.new("ShardMinigameResult")

-- ========== Cooldown/Anti-Abuse Tables ==========

local spendCooldown = {}       -- [userId] = timestamp
local bonusClickTimestamps = {}-- [userId] = array of click times
local minigameCooldown = {}    -- [userId] = timestamp

-- ========== Data Persistence ==========

local function LoadShards(player)
	local userId = player.userId
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
end)

Players.PlayerRemoving:Connect(function(player)
	SaveShards(player)
	playerShards[player.UserId] = nil
	dirtyPlayers[player.UserId] = nil
	lastAutoAward[player.UserId] = nil
end)

game:BindToClose(function()
	-- Save all dirty players on shutdown
	for userId, _ in pairs(dirtyPlayers) do
		SaveShards(userId)
	end
end)

-- ========== Multiplier Calculation ==========

local function GetTotalMultiplier(player)
	local mult = 1
	mult = mult * AFKPointUtils.GetMultiplier(player)
    mult = mult * AFKPointUtils.GetConsumableMultiplier(player)

	local friendBonus = AFKPointUtils.GetFriendBonus(player)
	mult = mult * friendBonus

	return mult
end

local function GetMinigameMultiplier(player)
	local minigameMult = 1
	if AFKPointUtils.IsVIP(player) then
		minigameMult = minigameMult * (AFKPointConfig.Gamepasses["VIP"].Features.MinigameMultiplier or 1)
	end
	minigameMult = minigameMult * AFKPointUtils.GetMinigameMultiplier(player)
	return minigameMult
end

-- ========== Award Shards Loop ==========

task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local userId = player.UserId

			-- Only award once per interval per player (prevents double awards from errors)
			if not lastAutoAward[userId] or (os.time() - (lastAutoAward[userId] or 0) >= AFKPointConfig.ShardInterval) then
				local base = AFKPointConfig.BaseShards
				local mult = GetTotalMultiplier(player)
				local award = math.floor(base * mult)

				if award > 0 then
					playerShards[userId] = (playerShards[userId] or 0) + award
					dirtyPlayers[userId] = true
					lastAutoAward[userId] = os.time()
					ShardUpdateSignal:FireTo(player, playerShards[userId])
				end
			end
		end
		task.wait(AFKPointConfig.ShardInterval)
	end
end)

-- ========== Bonus Award Actions ==========

function AFKPointEngine.AwardBonus(player, action)
	-- Only allow defined BonusActions
	local configVal = AFKPointConfig.BonusActions[action]
	if not configVal then return end
	local mult = GetTotalMultiplier(player)
	local amount = math.floor(configVal * mult)
	if amount > 0 then
		playerShards[player.UserId] = (playerShards[player.UserId] or 0) + amount
		dirtyPlayers[player.UserId] = true
		ShardUpdateSignal:FireTo(player, playerShards[player.UserId])
	end
end

function AFKPointEngine.AwardMinigame(player)
	local mult = GetMinigameMultiplier(player)
	local base = AFKPointConfig.BonusActions.MinigameWin or 10
	local award = math.floor(base * mult)
	if award > 0 then
		playerShards[player.UserId] = (playerShards[player.UserId] or 0) + award
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
		task.wait(30) -- Save every 30 seconds
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
			ShardBonusResult:FireTo(player, false, AFKPointEngine.GetShards(player), "Too many clicks! Slow down.")
			return
		end
		table.insert(bonusClickTimestamps[userId], now)
	end

	AFKPointEngine.AwardBonus(player, action)
	ShardBonusResult:FireTo(player, true, AFKPointEngine.GetShards(player))
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