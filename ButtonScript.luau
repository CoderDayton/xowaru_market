local TweenService = game:GetService("TweenService")
local MainHUD = script.Parent

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CLICK_SOUND_ID = "rbxassetid://96992108673305"

-- Utility: Animate scale with UIScale on a button
local function setupButtonAnimation(btn)
	local scale = btn:FindFirstChildWhichIsA("UIScale") or Instance.new("UIScale")
    scale.Parent = btn
	scale.Scale = 1
	local hoverTween, pressTween

	btn.MouseEnter:Connect(function()
		if hoverTween then hoverTween:Cancel() end
		hoverTween = TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.05})
		hoverTween:Play()
	end)

	btn.MouseLeave:Connect(function()
		if hoverTween then hoverTween:Cancel() end
		hoverTween = TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
		hoverTween:Play()
	end)

	btn.MouseButton1Down:Connect(function()
		if pressTween then pressTween:Cancel() end
		pressTween = TweenService:Create(scale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.93})
		pressTween:Play()
	end)

	btn.MouseButton1Up:Connect(function()
		if pressTween then pressTween:Cancel() end
		-- On release, return to hover (1.05) if still hovering, else 1
		local mouse = game:GetService("Players").LocalPlayer:GetMouse()
		local abs = btn.AbsolutePosition
		local sz = btn.AbsoluteSize
		local inside = mouse.X >= abs.X and mouse.X <= abs.X+sz.X and mouse.Y >= abs.Y and mouse.Y <= abs.Y+sz.Y
		local target = inside and 1.05 or 1
		pressTween = TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = target})
		pressTween:Play()
	end)
end

local function addClickSound(button)
    local clickSound = button:FindFirstChild("ClickSound") or Instance.new("Sound")
    clickSound.Name = "ClickSound"
    clickSound.SoundId = CLICK_SOUND_ID
    clickSound.Volume = 0.1
    clickSound.PlaybackSpeed = 1.5
    clickSound.Parent = button
    button.MouseButton1Click:Connect(function()
        if clickSound.IsPlaying then
            clickSound:Stop()
        else
            clickSound:Play()
        end
    end)
end

-- Automatically wire up all TextButton/ImageButton descendants
for _, btn in ipairs(MainHUD:GetDescendants()) do
	if btn:IsA("TextButton") or btn:IsA("ImageButton") then
		setupButtonAnimation(btn)
		addClickSound(btn)
	end
end