local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RemoteSignal = require(ReplicatedStorage.RemoteSignal)
local MainHUD = game.Players.LocalPlayer.PlayerGui:WaitForChild("MainHUD")
local AFKPointConfig = require(ReplicatedStorage:WaitForChild("AFKSystem"):WaitForChild("AFKPointConfig"))

-- Request/response channels
local ShardSpendRequest = RemoteSignal.new("ShardSpendRequest")
local ShardSpendResult = RemoteSignal.new("ShardSpendResult")
local ShardBonusRequest = RemoteSignal.new("ShardBonusRequest")
local ShardBonusResult = RemoteSignal.new("ShardBonusResult")
local ShardMinigameRequest = RemoteSignal.new("ShardMinigameRequest")
local ShardMinigameResult = RemoteSignal.new("ShardMinigameResult")
local ShardUpdateSignal = RemoteSignal.new("ShardUpdate") -- Live sync

-- ========== Local Variables ==========
local currentShardBalance = 0
local lastShardBalance = 0

local minClickInterval = 1 / AFKPointConfig.MaxClicksPerSecond or 0.2 -- Default to 5 clicks per second
local lastClickTime = 0

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

ShardBonusResult:Connect(function(success, newBalance, message, gained)
	if success then
        if gained and gained > 0 then
            showClickPopup(gained)
        end
	end
end)

ShardMinigameResult:Connect(function(success, newBalance)
	if success then
		print("[MINIGAME] Reward received! New shards:", newBalance)
	else
		warn("[MINIGAME] Failed to award minigame reward.")
	end
end)

-- ====== Other Handlers ======

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not gameProcessed then
        if canClick() then
            ClaimBonus("Click")
            playClickSound()
        end
    end
end)

MainHUD.MainClickButton.MouseButton1Click:Connect(function()
    if canClick() then
        ClaimBonus("Click")
        playClickSound()
    end
end)

-- ====== UI Update Function ======

function FormatShardCount(n)
    if n < 1000000 then
        return string.format("%s", tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
    end
    local units = {"", "K", "M", "B", "T", "Q"}
    local k = 1000
    local magnitude = math.floor(math.log(n, k))
    local value = n / (k ^ magnitude)
    local suffix = units[magnitude] or ("e" .. tostring(magnitude*3))
    local formatted = string.format("%.2f", value):gsub("%.?0+$", "") -- removes .00 or .0
    return formatted .. suffix
end

function updateShards(newShardCount)
    local MainHUD = game.Players.LocalPlayer.PlayerGui:WaitForChild("MainHUD")
    local left = MainHUD:WaitForChild("Left")
    local shards = left:WaitForChild("Shards")
    local label = shards:WaitForChild("ShardAmount")
    if not label then return end
    newShardCount = tonumber(newShardCount) or 0

    local UIScale = shards:FindFirstChildWhichIsA("UIScale") or Instance.new("UIScale")
    UIScale.Parent = shards
    UIScale.Scale = 1

    local value = Instance.new("NumberValue")
    value.Value = lastShardBalance

    local tween = TweenService:Create(value, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = newShardCount})
    value.Changed:Connect(function()
        label.Text = FormatShardCount(math.floor(value.Value))
    end)
    tween.Completed:Connect(function()
        label.Text = FormatShardCount(newShardCount)
        TweenService:Create(UIScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {Scale = 1.17}):Play()
        task.wait(0.13)
        TweenService:Create(UIScale, TweenInfo.new(0.19, Enum.EasingStyle.Quad), {Scale = 1}):Play()
        value:Destroy()
    end)
    tween:Play()
    lastShardBalance = newShardCount
end

function showClickPopup(amount)
    local TweenService = game:GetService("TweenService")
    local MainHUD = game.Players.LocalPlayer.PlayerGui:WaitForChild("MainHUD")
    local popup = Instance.new("Frame")
    popup.BackgroundTransparency = 1
    popup.Size = UDim2.fromOffset(150, 44)

    local minPadX, minPadY = 140, 100
    local maxPadX, maxPadY = 140, 200
    local x = math.random(minPadX, MainHUD.AbsoluteSize.X - maxPadX)
    local y = math.random(minPadY, MainHUD.AbsoluteSize.Y - maxPadY)
    popup.Position = UDim2.fromOffset(x, y)
    popup.Parent = MainHUD

    local shardIcon = Instance.new("ImageLabel")
    shardIcon.BackgroundTransparency = 1
    shardIcon.Size = UDim2.fromOffset(40, 40)
    shardIcon.ScaleType = Enum.ScaleType.Fit
    shardIcon.Position = UDim2.fromOffset(0, 4)
    shardIcon.Image = "rbxassetid://138071024126324"
    shardIcon.Parent = popup

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Position = UDim2.fromOffset(20, 0)
    text.Size = UDim2.fromOffset(108, 44)
    text.Text = "+"..FormatShardCount(amount)
    text.Font = Enum.Font.FredokaOne
    text.TextSize = 42
    text.TextColor3 = Color3.new(1,1,1)
    text.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    text.TextStrokeTransparency = 0.2
    text.Parent = popup

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Parent = text
    UIStroke.Color = Color3.fromRGB(0, 0, 0)
    UIStroke.Thickness = 5
    UIStroke.Transparency = 0.2

    TweenService:Create(popup, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {Position = popup.Position - UDim2.fromOffset(0, 40), BackgroundTransparency = 1}):Play()
    TweenService:Create(text, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
    TweenService:Create(shardIcon, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {ImageTransparency = 1}):Play()
    TweenService:Create(UIStroke, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
    task.wait(1.2)
    popup:Destroy()
end

function playClickSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://1673280232"
    sound.Volume = 0.03
    sound.Parent = MainHUD
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

function canClick()
    local now = tick()
    if now - lastClickTime >= minClickInterval then
        lastClickTime = now
        return true
    end
    return false
end

-- ====== Live Balance Sync ======
ShardUpdateSignal:Connect(function(newBalance)
	currentShardBalance = newBalance or currentShardBalance
    updateShards(currentShardBalance)
end)

return {
	currentShardBalance = function() return currentShardBalance end,
}
