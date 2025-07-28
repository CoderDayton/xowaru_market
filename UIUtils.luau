local TweenService = game:GetService("TweenService")

local UIUtils = {}

function UIUtils.TweenTextTransparency(label, targetTransparency, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(label, tweenInfo, {TextTransparency = targetTransparency})
	tween:Play()
	tween.Completed:Wait()
end

local TweenService = game:GetService("TweenService")

function UIUtils.ShowFeedback(player, message, opts)
    opts = opts or {}
    task.spawn(function()
        local gui = player:FindFirstChild("PlayerGui"):FindFirstChild("FeedbackGui")
        if not gui then return end

        local frame = gui:FindFirstChild("FeedbackFrame")
        local label = frame and frame:FindFirstChild("FeedbackLabel") or nil
        if not frame or not label then return end

        -- Custom color support: green for success, red for error, yellow for warn
        local color = opts.Color or Color3.fromRGB(200,255,200)
        if opts.Type == "Error" then color = Color3.fromRGB(255,80,80) end
        if opts.Type == "Warn" then color = Color3.fromRGB(255,210,60) end

        frame.Visible = true

        label.Text = message
        label.TextColor3 = color
        label.TextTransparency = 1
        frame.BackgroundTransparency = 0.35

        -- Slight bounce in (scale up then down)
        frame.Size = UDim2.fromScale(0.3, 0.11)
        local bounceUp = TweenService:Create(frame, TweenInfo.new(0.13, Enum.EasingStyle.Back), {Size = UDim2.fromScale(0.34, 0.13)})
        local bounceDown = TweenService:Create(frame, TweenInfo.new(0.10, Enum.EasingStyle.Back), {Size = UDim2.fromScale(0.3, 0.11)})
        bounceUp:Play()
        bounceUp.Completed:Wait()
        bounceDown:Play()

        -- Fade in text
        local tweenInfo = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fadeIn = TweenService:Create(label, tweenInfo, {TextTransparency = 0})
        fadeIn:Play()
        fadeIn.Completed:Wait()

        task.wait(opts.Duration or 3)

        -- Fade out text and frame
        local fadeOut = TweenService:Create(label, tweenInfo, {TextTransparency = 1})
        fadeOut:Play()
        local frameFade = TweenService:Create(frame, TweenInfo.new(0.25), {BackgroundTransparency = 1})
        frameFade:Play()
        frameFade.Completed:Wait()
        frame.Visible = false
    end)
end

function UIUtils.SetupOrUpdateBillboard(podium, config, info)
    local textHolder = podium:FindFirstChild("TextHolder")
    if not textHolder then return end

    local gui = textHolder:FindFirstChild("BillboardGui")
    if not gui then
        gui = Instance.new("BillboardGui")
        gui.Name = "BillboardGui"
        gui.Size = UDim2.new(0, 340, 0, 120)
        gui.AlwaysOnTop = true
        gui.LightInfluence = 0
        gui.StudsOffset = Vector3.new(0, 3.5, 0)
        gui.Parent = textHolder
    end

    local modifierLabel = gui:FindFirstChild("ModifierLabel")
    if not modifierLabel then
        modifierLabel = Instance.new("TextLabel")
        modifierLabel.Name = "ModifierLabel"
        modifierLabel.Size = UDim2.new(1, 0, 0.42, 0)
        modifierLabel.Position = UDim2.new(0, 0, -0.41, 0)
        modifierLabel.BackgroundTransparency = 1
        modifierLabel.TextColor3 = config.ModifierColor or Color3.fromRGB(255,200,40)
        modifierLabel.TextStrokeTransparency = 0.18
        modifierLabel.TextStrokeColor3 = Color3.fromRGB(30, 30, 40)
        modifierLabel.TextScaled = true
        modifierLabel.RichText = true
        modifierLabel.Font = Enum.Font.LuckiestGuy
        modifierLabel.Text = ""
        modifierLabel.ZIndex = 2
        modifierLabel.Parent = gui
    end

    local mainLabel = gui:FindFirstChild("MainBillboardLabel")
    if not mainLabel then
        mainLabel = Instance.new("TextLabel")
        mainLabel.Name = "MainBillboardLabel"
        mainLabel.Size = UDim2.new(1, 0, 1, 0)
        mainLabel.Position = UDim2.new(0, 0, 0, 0)
        mainLabel.BackgroundTransparency = 1
        mainLabel.TextColor3 = config.MainColor or Color3.fromRGB(255,255,90)
        mainLabel.TextStrokeTransparency = 0.28
        mainLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        mainLabel.TextScaled = true
        mainLabel.RichText = true
        mainLabel.Font = Enum.Font.FredokaOne
        mainLabel.ZIndex = 1
        mainLabel.Parent = gui
    end

    if config.ModifierText and config.ModifierText ~= "" then
        modifierLabel.Text = string.format(
            '<b><font color="rgb(%d,%d,%d)">%s</font></b>',
            (config.ModifierColor and config.ModifierColor.R * 255 or 255),
            (config.ModifierColor and config.ModifierColor.G * 255 or 200),
            (config.ModifierColor and config.ModifierColor.B * 255 or 40),
            config.ModifierText
        )
        modifierLabel.Visible = true
    else
        modifierLabel.Visible = false
    end

    -- Stock and name use the same main color and bold
    if info and info.IsLimitedUnique then
        mainLabel.Text = string.format(
            '<b>%s</b>\n<b>%d Left</b>',
            config.DisplayName,
            info.Remaining or 0
        )
    else
        mainLabel.Text = string.format('<b>%s</b>', config.DisplayName)
    end
    mainLabel.TextColor3 = config.MainColor or Color3.fromRGB(255,255,90)
end



return UIUtils
