local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RemoteSignal = require(ReplicatedStorage.RemoteSignal)
local MainHUD = game.Players.LocalPlayer.PlayerGui:WaitForChild("MainHUD")
local SoundHandler = require(ReplicatedStorage:WaitForChild("SoundHandler"))

-- Request/response channels
local ShardSpendRequest = RemoteSignal.new("ShardSpendRequest")
local ShardSpendResult = RemoteSignal.new("ShardSpendResult")
local ShardBonusRequest = RemoteSignal.new("ShardBonusRequest")
local ShardBonusResult = RemoteSignal.new("ShardBonusResult")
local ShardMinigameRequest = RemoteSignal.new("ShardMinigameRequest")
local ShardMinigameResult = RemoteSignal.new("ShardMinigameResult")
local ShardUpdateSignal = RemoteSignal.new("ShardUpdate") -- Live sync
local PlaySoundRemote = RemoteSignal.new("PlaySoundRemote")

-- ========== Local Variables ==========
local currentShardBalance = 0
local lastShardBalance = 0

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
	if success and gained and gained > 0 then
        showClickPopup(gained)
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
        ClaimBonus("Click")
    end
end)

MainHUD.MainClickButton.MouseButton1Click:Connect(function()
    ClaimBonus("Click")
end)

PlaySoundRemote:Connect(function(name, overrideVolume, overridePlaybackSpeed)
	SoundHandler.PlaySound(name, overrideVolume, overridePlaybackSpeed)
end)

-- ====== UI Update Function ======

function FormatShardCount(n)
    n = tonumber(n) or 0
    if n < 1000000 then
        -- Use string pattern to insert commas every three digits
        local s = tostring(math.floor(n))
        local len = #s
        local formatted = ""
        for i = 1, len do
            formatted = formatted .. s:sub(i,i)
            if (len - i) % 3 == 0 and i < len then
                formatted = formatted .. ","
            end
        end
        return formatted
    end
    local units = {"", "K", "M", "B", "T", "Q"}
    local k = 1000
    local magnitude = math.floor(math.log(n, k))
    local value = n / (k ^ magnitude)
    local suffix = units[magnitude] or ("e" .. tostring(magnitude*3))
    local formatted = string.format("%.2f", value)
    return formatted .. suffix
end

function updateShards(newShardCount)
    local left = MainHUD:WaitForChild("Left")
    local shards = left:WaitForChild("Shards")
    local label = shards:WaitForChild("ShardAmount")
    if not label then return end
    newShardCount = tonumber(newShardCount) or 0

    -- Always use a single UIScale instance
    local UIScale = shards:FindFirstChild("UIScale") or Instance.new("UIScale")
    UIScale.Name = "UIScale"
    UIScale.Parent = shards

    -- Robust: Stop any previous scale tweens and instantly reset scale to 1
    UIScale.Scale = 1
    if UIScale:FindFirstChild("PulseTween") then
        UIScale.PulseTween:Destroy()
    end

    -- Only one number tween at a time
    if label:FindFirstChild("CountTween") then
        label.CountTween:Destroy()
    end

    local value = Instance.new("NumberValue")
    value.Name = "CountTween"
    value.Value = lastShardBalance
    value.Parent = label

    local tween = TweenService:Create(value, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Value = newShardCount})

    value.Changed:Connect(function()
        label.Text = FormatShardCount(math.floor(value.Value))
    end)

    tween.Completed:Connect(function()
        label.Text = FormatShardCount(newShardCount)
        value:Destroy()
        tween:Destroy()
    end)

    -- Gentle pulse, **never larger than 1.07**
    local pulseTween = TweenService:Create(UIScale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.07})
    pulseTween.Name = "PulseTween"
    pulseTween.Parent = UIScale
    pulseTween:Play()

    pulseTween.Completed:Connect(function()
        TweenService:Create(UIScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end)

    tween:Play()
    lastShardBalance = newShardCount
end

function showClickPopup(amount)
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

-- ====== Live Balance Sync ======
ShardUpdateSignal:Connect(function(newBalance)
	currentShardBalance = newBalance or currentShardBalance
    updateShards(currentShardBalance)
end)

return {
	currentShardBalance = function() return currentShardBalance end,
}
