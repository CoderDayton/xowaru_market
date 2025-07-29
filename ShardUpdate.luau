local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RemoteSignal = require(ReplicatedStorage.RemoteSignal)

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ShardGui")
local frame = gui:WaitForChild("ShardFrame")
local label = frame:WaitForChild("ShardLabel")

local ShardUpdateSignal = RemoteSignal.new("ShardUpdate")

ShardUpdateSignal:Connect(function(newShardCount)
	label.Text = ("%s"):format(tostring(newShardCount or 0))
end)

frame.AddButton.MouseButton1Click:Connect(function()
    -- TODO: Open shard shop ui
    print("Opening shard shop...")
end)

label.Text = "0" -- Initial UI state