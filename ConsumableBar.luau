local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))
local ConsumableUpdateSignal = RemoteSignal.new("ConsumableUpdate")

local MainHUD = script.Parent
local consumableBar = MainHUD:FindFirstChild("ConsumableBar")

local boostSlots = {}

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

-- Add or update a boost slot (idempotent)
local function AddOrUpdateBoostSlot(boostName, iconId, endsAt)
    local slot = boostSlots[boostName]
    if not slot then
        slot = Instance.new("Frame")
        slot.Name = boostName
        slot.Size = UDim2.fromOffset(58, 62)
        slot.BackgroundTransparency = 0.15
        slot.BackgroundColor3 = Color3.fromRGB(68, 72, 90)
        local slotCorner = Instance.new("UICorner")
        slotCorner.Parent = slot
        slotCorner.CornerRadius = UDim.new(0, 14)
        slot.Parent = consumableBar

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Image = "rbxassetid://" .. tostring(iconId)
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.fromOffset(36, 36)
        icon.Position = UDim2.fromOffset(11, 5)
        icon.Parent = slot

        local timer = Instance.new("TextLabel")
        timer.Name = "Timer"
        timer.Text = "..."
        timer.Font = Enum.Font.FredokaOne
        timer.TextColor3 = Color3.fromRGB(230, 230, 255)
        timer.BackgroundTransparency = 1
        timer.TextSize = 18
        timer.Position = UDim2.fromOffset(0, 44)
        timer.Size = UDim2.new(1, 0, 0, 18)
        timer.Parent = slot

        boostSlots[boostName] = slot
    end

    slot:SetAttribute("EndsAt", endsAt)
    slot:SetAttribute("IconId", iconId)
end

-- Timer loop: update all timers and remove expired slots
task.spawn(function()
    while true do
        for boostName, slot in pairs(boostSlots) do
            local endsAt = slot:GetAttribute("EndsAt")
            local iconId = slot:GetAttribute("IconId")
            if endsAt then
                local now = os.time()
                local timeLeft = math.max(0, endsAt - now)
                local timer = slot:FindFirstChild("Timer")
                if timer then
                    timer.Text = formatTime(timeLeft)
                end
                if timeLeft <= 0 then
                    slot:Destroy()
                    boostSlots[boostName] = nil
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Handler for full update from server
ConsumableUpdateSignal:Connect(function(boostList)
    -- Remove any slots not in list
    local keep = {}
    for _, boost in ipairs(boostList) do
        keep[boost.Name] = true
    end
    for boostName, slot in pairs(boostSlots) do
        if not keep[boostName] then
            slot:Destroy()
            boostSlots[boostName] = nil
        end
    end
    -- Add/update all boosts in the list
    for _, boost in ipairs(boostList) do
        AddOrUpdateBoostSlot(boost.Name, boost.Icon, boost.EndsAt)
    end
end)
