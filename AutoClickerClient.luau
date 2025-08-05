local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local AFKPointConfig = require(ReplicatedStorage:WaitForChild("AFKSystem"):WaitForChild("AFKPointConfig"))
local AFKPointUtils = require(ReplicatedStorage:WaitForChild("AFKSystem"):WaitForChild("AFKPointUtils"))
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))

-- ====== Remote Signals ======
local AutoClickerToggle = RemoteSignal.new("AutoClickerToggle")
local ShardBonusSignal = RemoteSignal.new("ShardBonusRequest")

-- UI references
local autoClickerButton = script.Parent:WaitForChild("AutoClickerButton")
local autoClickerRect = autoClickerButton:WaitForChild("Rect")

local autoEnabled = false
local clickTimer = 0

-- Get VIP multiplier if owned
local function getAutoClickRate()
	local rate = AFKPointConfig.Gamepasses["Auto Clicker"].Features.ClickRate or 0
	if AFKPointUtils.CheckGamepass(LocalPlayer, "VIP") then
		rate = rate * (AFKPointConfig.Gamepasses["VIP"].Features.AutoClickerMultiplier or 1)
	end
	return math.floor(rate)
end

-- UI update
local function updateUI()
	local UIGradient = autoClickerRect:FindFirstChild("UIGradient")
	if AFKPointUtils.CheckGamepass(LocalPlayer, "Auto Clicker") then
		autoClickerButton.Text = autoEnabled and "Auto Clicker: ON" or "Auto Clicker: OFF"
		local sequences = {
			Disabled = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("#7b112b")),
				ColorSequenceKeypoint.new(0.5, Color3.fromHex("#f31818")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("#7b112b"))
			}),
			Enabled = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("#127017")),
				ColorSequenceKeypoint.new(0.5, Color3.fromHex("#20c929")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("#127017"))
			})
		}
		UIGradient.Color = autoEnabled and sequences.Enabled or sequences.Disabled
	end
end

AutoClickerToggle:LocalConnect(function()
	if not AFKPointUtils.CheckGamepass(LocalPlayer, "Auto Clicker") then
		-- Prompt for purchase if not owned
		MarketplaceService:PromptGamePassPurchase(LocalPlayer, AFKPointConfig.Gamepasses["Auto Clicker"].GamepassId)
		return
	end
	-- Toggle auto mode
	autoEnabled = not autoEnabled
	updateUI()
end)

-- Run auto-clicking
RunService.RenderStepped:Connect(function(dt)
	if not autoEnabled or not AFKPointUtils.CheckGamepass(LocalPlayer,"Auto Clicker") then return end
	local rate = getAutoClickRate()
	if rate <= 0 then return end

	clickTimer = clickTimer + dt
	local minInterval = 1 / rate
	while clickTimer >= minInterval do
		clickTimer = clickTimer - minInterval
		ShardBonusSignal:Fire("Click")
	end
end)

-- OPTIONAL: Listen for PromptGamePassPurchaseFinished to auto-enable after buying
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if player == LocalPlayer and gamePassId == AFKPointConfig.Gamepasses["Auto Clicker"].GamepassId and purchased then
		autoEnabled = true
		updateUI()
	end
end)
