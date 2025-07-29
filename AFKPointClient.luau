local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSignal = require(ReplicatedStorage.RemoteSignal)

-- Request/response channels
local ShardSpendRequest = RemoteSignal.new("ShardSpendRequest")
local ShardSpendResult = RemoteSignal.new("ShardSpendResult")
local ShardBonusRequest = RemoteSignal.new("ShardBonusRequest")
local ShardBonusResult = RemoteSignal.new("ShardBonusResult")
local ShardMinigameRequest = RemoteSignal.new("ShardMinigameRequest")
local ShardMinigameResult = RemoteSignal.new("ShardMinigameResult")
local ShardUpdateSignal = RemoteSignal.new("ShardUpdate") -- Live sync

-- Local shard balance (for UI updates)
local CurrentShardBalance = 0

-- ====== Request Functions ======

function RequestSpend(amount)
    ShardSpendRequest:Fire(amount)
end

function ClaimBonus(action)
    ShardBonusRequest:Fire(action)
end

function ClaimMinigameReward()
    ShardMinigameRequest:Fire()
end

-- ====== Response Handlers ======

ShardSpendResult:Connect(function(success, newBalance, err)
    if success then
        print("[SPEND] Success! New shards:", newBalance)
    else
        warn("[SPEND] Failed:", err or "Unknown error")
    end
end)

ShardBonusResult:Connect(function(success, newBalance, message)
    if success then
        print("[BONUS] Claimed! New shards:", newBalance)
    else
        warn("[BONUS] Failed:", message or "Unknown error")
    end
end)

ShardMinigameResult:Connect(function(success, newBalance)
    if success then
        print("[MINIGAME] Reward received! New shards:", newBalance)
    else
        warn("[MINIGAME] Failed to award minigame reward.")
    end
end)

-- ====== Live Balance Sync ======
ShardUpdateSignal:Connect(function(newBalance)
    CurrentShardBalance = newBalance or CurrentShardBalance
    print("[SYNC] Shard balance updated:", CurrentShardBalance)
    -- Update your UI here!
end)

return {
    CurrentShardBalance = function() return CurrentShardBalance end,
}