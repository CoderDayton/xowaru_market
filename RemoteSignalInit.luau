-- Central server-side remote event registration

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))

-- List all remote signal names used in the project
local SIGNAL_NAMES = {
	"ShardUpdate",
	"ShardSpendRequest",
	"ShardSpendResult",
	"ShardBonusRequest",
	"ShardBonusResult",
	"ShardMinigameRequest",
	"ShardMinigameResult",
	"ConsumableUpdate",
}

for _, name in ipairs(SIGNAL_NAMES) do
	RemoteSignal.new(name)
end

print("[RemoteSignalInit] All RemoteSignals initialized on server.")
