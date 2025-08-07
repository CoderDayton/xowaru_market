local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RemoteSignal = require(ReplicatedStorage.RemoteSignal)
local MainHUD = game.Players.LocalPlayer.PlayerGui:WaitForChild("MainHUD")
local SoundHandler = require(ReplicatedStorage:WaitForChild("SoundHandler"))
local UIUtils = require(ReplicatedStorage:WaitForChild("UIUtils"))

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

-- Palette (edit to match your UI theme) -----------------------------
local BASE_COLOR      = Color3.fromRGB(255, 255, 255)
local PULSE_COLOR     = Color3.fromRGB(185, 245, 255)
local PULSE_SCALE_MAX = 1.08

-- Cached tweeninfo objects for reuse -------------------------------
local TI_NUMBER = TweenInfo.new(0.35, Enum.EasingStyle.Quad , Enum.EasingDirection.Out)
local TI_SCALE  = TweenInfo.new(0.18, Enum.EasingStyle.Sine , Enum.EasingDirection.Out)
local TI_COLOR  = TweenInfo.new(0.18, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

----------------------------------------------------------------------
-- updateShards
----------------------------------------------------------------------
function updateShards(newShardCount: number)
    local left    = MainHUD:WaitForChild("Left")
    local shards  = left   :WaitForChild("Shards")
    local label   = shards :WaitForChild("ShardAmount")
    if not label then return end

    newShardCount = tonumber(newShardCount) or 0

    ------------------------------------------------------------------
    -- 1. Clear prior tweens if still running
    ------------------------------------------------------------------
    for _, tag in {"CountTween","ScaleTween","ColorTween"} do
        local obj = label:FindFirstChild(tag)
        if obj then obj:Destroy() end
    end

    ------------------------------------------------------------------
    -- 2. Smooth number roll-up
    ------------------------------------------------------------------
    local nv   = Instance.new("NumberValue")
    nv.Name    = "CountTween"
    nv.Value   = lastShardBalance or 0
    nv.Parent  = label

    local twNumber = TweenService:Create(nv, TI_NUMBER, {Value = newShardCount})
    nv.Changed:Connect(function()
        label.Text = UIUtils.FormatShardCount(nv.Value)
    end)
    twNumber.Completed:Connect(function() nv:Destroy() end)
    twNumber:Play()

    ------------------------------------------------------------------
    -- 3. Subtle pulse (scale + tint) – both start, then auto-return
    ------------------------------------------------------------------
    -- UIScale (create once then reuse)
    local uiScale = label:FindFirstChildOfClass("UIScale")
                  or Instance.new("UIScale")
    uiScale.Parent = label

    -- scale out / back
    local scaleUp   = TweenService:Create(uiScale, TI_SCALE , {Scale = PULSE_SCALE_MAX})
    local scaleDown = TweenService:Create(uiScale, TI_SCALE , {Scale = 1})

    -- color shift / back
    local colorUp   = TweenService:Create(label , TI_COLOR , {TextColor3 = PULSE_COLOR})
    local colorDown = TweenService:Create(label , TI_COLOR , {TextColor3 = BASE_COLOR})

    scaleUp.Completed:Connect(function() scaleDown:Play() end)
    colorUp.Completed:Connect(function() colorDown:Play() end)

    -- tag for cleanup (optional, keeps hierarchy tidy)
    for _, t in {scaleUp, colorUp} do
        local marker = Instance.new("BoolValue")
        marker.Name  = t == scaleUp and "ScaleTween" or "ColorTween"
        marker.Parent = label
        t.Completed:Connect(function() marker:Destroy() end)
    end

    scaleUp:Play()
    colorUp:Play()

    ------------------------------------------------------------------
    -- 4. Persist balance for next call
    ------------------------------------------------------------------
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
    text.Text = "+"..UIUtils.FormatShardCount(amount)
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
