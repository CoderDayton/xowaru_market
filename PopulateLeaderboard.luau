local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LeaderboardUtils = require(ReplicatedStorage:WaitForChild("LeaderboardUtils"))
local LeaderboardData = require(script.Parent:WaitForChild("LeaderboardData"))

local recentFrame = Workspace.LeaderboardBoard.LeaderboardGui.MainPanel.RecentScrollingFrame
local topFrame = Workspace.LeaderboardBoard.LeaderboardGui.MainPanel.TopScrollingFrame

local PopulateLeaderboard = {}

local function clear(frame)
	for _,child in pairs(frame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function animateEntry(entry)
	entry.BackgroundTransparency = 1
	entry.Position += UDim2.fromOffset(0,15)
	TweenService:Create(entry, TweenInfo.new(0.6), {
		BackgroundTransparency = 0.15,
		Position = entry.Position - UDim2.fromOffset(0,15)
	}):Play()
end

function PopulateLeaderboard.Populate()
	clear(recentFrame)
	clear(topFrame)

	local recent = LeaderboardData.GetRecentPurchases()
	local top = LeaderboardData.GetTopSpenders(50)

	for _,data in ipairs(recent) do
        if typeof(data) ~= "table" or not data.userId or not data.name or not data.item or typeof(data.item) ~= "string" or not data.price then
            warn("Invalid recent purchase data:", data)
            continue
        end
		local entry = LeaderboardUtils.CreateRecentEntry(recentFrame, data.userId, data.name, data.item, data.price)
		entry.RobuxRow.RobuxAmount.Text = tostring(data.price)
		animateEntry(entry)
	end

	for rank,data in ipairs(top) do
        if typeof(data) ~= "table" or not data.userId or not data.amount then
            warn("Invalid top spender data:", data)
            continue
        end
		if data.amount <= 0 then continue end
		local name = game.Players:GetNameFromUserIdAsync(data.userId)
		local entry = LeaderboardUtils.CreateTopSpenderEntry(topFrame, data.userId, name, data.amount, rank)
		animateEntry(entry)
	end
end

PopulateLeaderboard.Populate()

return PopulateLeaderboard
