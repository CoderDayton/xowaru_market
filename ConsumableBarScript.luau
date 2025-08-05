local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))
local ConsumableUpdateSignal = RemoteSignal.new("ConsumableUpdate")

local MainHUD = script.Parent
local consumableBar = MainHUD:WaitForChild("ConsumableBar")

local consumableSlots = {}

local function formatTime(secs)
    if secs <= 0 then return "0s" end
    local mins = math.floor(secs / 60)
    local s = math.floor(secs % 60)
    if mins > 0 then
        return string.format("%d:%02d", mins, s)
    else
        return string.format("%ds", s)
    end
end

-- Add or update a boost slot
local function AddOrUpdateConsumableSlot(consumableName, pIcon, endsAt)
    local slot = consumableSlots[consumableName]

    if not slot then
        slot = Instance.new("Frame")
        slot.Name = consumableName
        slot.Size = UDim2.fromOffset(60, 64)
        slot.BackgroundTransparency = 1
        slot.BackgroundColor3 = Color3.fromRGB(44, 47, 70)
        slot.ZIndex = 20
        slot.Parent = consumableBar

        local UIScale = Instance.new("UIScale")
        UIScale.Name = "UIScale"
        UIScale.Scale = 1.2
        UIScale.Parent = slot

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Image = pIcon
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.fromOffset(38, 38)
        icon.Position = UDim2.fromOffset(11, 6)
        icon.ZIndex = 22
        icon.Parent = slot

        local timer = Instance.new("TextLabel")
        timer.Name = "Timer"
        timer.Text = "..."
        timer.Font = Enum.Font.FredokaOne
        timer.TextColor3 = Color3.fromRGB(235, 240, 255)
        timer.BackgroundTransparency = 1
        timer.TextSize = 20
        timer.AnchorPoint = Vector2.new(0.5, 0)
        timer.Position = UDim2.new(0.5, 0, 1, -24)
        timer.Size = UDim2.new(1, -6, 0, 20)
        timer.TextStrokeColor3 = Color3.new(0,0,0)
        timer.TextStrokeTransparency = 0.42
        timer.ZIndex = 28
        timer.Parent = slot

        local timerShadow = Instance.new("TextLabel")
        timerShadow.Text = timer.Text
        timerShadow.Font = timer.Font
        timerShadow.TextSize = timer.TextSize
        timerShadow.TextColor3 = Color3.fromRGB(22,22,32)
        timerShadow.BackgroundTransparency = 1
        timerShadow.AnchorPoint = timer.AnchorPoint
        timerShadow.Position = timer.Position + UDim2.fromOffset(1,2)
        timerShadow.Size = timer.Size
        timerShadow.ZIndex = timer.ZIndex - 1
        timerShadow.TextStrokeTransparency = 1
        timerShadow.Parent = slot
        timer:GetPropertyChangedSignal("Text"):Connect(function()
            timerShadow.Text = timer.Text
        end)

        consumableSlots[consumableName] = slot
    end

    slot:SetAttribute("EndsAt", endsAt)
    slot:SetAttribute("Icon", pIcon)
end

-- Timer loop: update all timers and remove expired slots
task.spawn(function()
    while true do
        for consumableName, slot in pairs(consumableSlots) do
            local endsAt = slot:GetAttribute("EndsAt")
            if endsAt then
                local now = os.time()
                local timeLeft = math.max(0, endsAt - now)
                local timer = slot:FindFirstChild("Timer")
                if timer then
                    timer.Text = formatTime(timeLeft)
                end
                if timeLeft <= 0 then
                    slot:Destroy()
                    consumableSlots[consumableName] = nil
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Handler for full update from server
ConsumableUpdateSignal:Connect(function(consumableList)
    -- Remove any slots not in list
    local keep = {}
    for _, consumable in ipairs(consumableList) do
        keep[consumable.Name] = true
    end
    for consumableName, slot in pairs(consumableSlots) do
        if not keep[consumableName] then
            slot:Destroy()
            consumableSlots[consumableName] = nil
        end
    end

    for _, consumable in ipairs(consumableList) do
        AddOrUpdateConsumableSlot(consumable.Name, consumable.Icon, consumable.EndsAt)
    end
end)
