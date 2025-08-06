local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))
local SoundHandler = require(ReplicatedStorage:WaitForChild("SoundHandler"))

local MainHUD = script.Parent

local SetupButtonsLocal = RemoteSignal.new("SetupButtonsLocal")

-- Modular button registry: { button = { handler = func, ... } }
local buttonRegistry = {}
local buttonsList = {}  -- Ordered list for navigation
local selectedIndex = 1  -- Current selected button index

-- Tween info for scaling animations
local scaleTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Function to scale a button (selected/deselected)
local function setButtonScale(button, isSelected)
	local uiScale = button:FindFirstChild("UIScale") or Instance.new("UIScale")
	uiScale.Parent = button
	local targetScale = isSelected and 1.1 or 1
	TweenService:Create(uiScale, scaleTweenInfo, {Scale = targetScale}):Play()
end

-- Register a button with its handler function
local function registerButton(buttonPath, handlerFunc)
	if not buttonPath or not handlerFunc or type(handlerFunc) ~= "function" then
		warn("Invalid button registration:", buttonPath, handlerFunc)
		return
	end

	local button = nil
	if string.find(buttonPath, "%.") then
		local pathParts = string.split(buttonPath, ".")
		local mainPath = pathParts[1]
		local subPath = table.concat(pathParts, ".", 2)

		if not MainHUD:FindFirstChild(mainPath) then
			warn("MainHUD does not contain:", mainPath)
			return
		end

		if not MainHUD:WaitForChild(mainPath):FindFirstChild(subPath) then
			warn("Button not found in MainHUD:", subPath)
			return
		end

		button = MainHUD:WaitForChild(mainPath):WaitForChild(subPath)
	else
		button = MainHUD:WaitForChild(buttonPath)
	end

	if not button or not button:IsA("GuiObject") then
		warn("Button not found or invalid type:", buttonPath)
		return
	end

	table.insert(buttonsList, button)
	buttonRegistry[button] = handlerFunc

	-- Connect mouse click (PC/desktop)
	button.MouseButton1Click:Connect(function()
		SoundHandler.PlaySound("ButtonSound")
		handlerFunc()  -- Call handler
	end)

	-- Add mobile touch handling (reliable for taps/swipes)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			-- Optional press visual (scale down)
			setButtonScale(button, true)  -- Reuse your scale function for press effect
		end
	end)

	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			-- Check bounds with small tolerance for mobile inaccuracy (no Target needed)
			local tolerance = 5  -- Pixels; adjust if needed
			local touchPos = input.Position
			local buttonPos = button.AbsolutePosition
			local buttonSize = button.AbsoluteSize
			if touchPos.X >= buttonPos.X - tolerance and touchPos.X <= buttonPos.X + buttonSize.X + tolerance and
				touchPos.Y >= buttonPos.Y - tolerance and touchPos.Y <= buttonPos.Y + buttonSize.Y + tolerance then
				SoundHandler.PlaySound("ButtonSound")
				handlerFunc()  -- Call handler
				setButtonScale(button, false)  -- Reset scale
			end
		end
	end)

	-- Initial scale (deselected)
	setButtonScale(button, false)
end

-- Select a button by index (update scales)
local function selectButton(index)
	if index < 1 or index > #buttonsList then return end
	if selectedIndex then
		setButtonScale(buttonsList[selectedIndex], false)
	end
	selectedIndex = index
	setButtonScale(buttonsList[selectedIndex], true)
end

-- Move selection (for gamepad/keyboard navigation)
local function moveSelection(direction)
	local newIndex = (selectedIndex + direction - 1) % #buttonsList + 1
	selectButton(newIndex)
end

-- Handle gamepad input for navigation and activation
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or #buttonsList == 0 then return end
	if input.UserInputType == Enum.UserInputType.Gamepad1 then
		if input.KeyCode == Enum.KeyCode.DPadDown then
			moveSelection(1)
		elseif input.KeyCode == Enum.KeyCode.DPadUp then
			moveSelection(-1)
		elseif input.KeyCode == Enum.KeyCode.ButtonA then
			local selectedButton = buttonsList[selectedIndex]
			if selectedButton then
				SoundHandler.PlaySound("ButtonSound")
				buttonRegistry[selectedButton]()  -- Call handler
			end
		end
	end
end)

-- Bind global actions for additional gamepad buttons (e.g., quick toggles without navigation)
ContextActionService:BindAction("ToggleShop", function(actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		local shopButton = buttonsList[1]  -- Assuming first is ShopButton; adjust index
		if shopButton then
			SoundHandler.PlaySound("ButtonSound")
			buttonRegistry[shopButton]()
		end
	end
end, false, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)

ContextActionService:BindAction("ToggleAutoClicker", function(actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		local autoButton = buttonsList[2]  -- Assuming second is AutoClickerButton; adjust index
		if autoButton then
			SoundHandler.PlaySound("ButtonSound")
			buttonRegistry[autoButton]()
		end
	end
end, false, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.DPadDown)

registerButton("Left.ShopButton", function()
	local ShopUI = MainHUD.Parent:WaitForChild("ShopUI")
	ShopUI.Enabled = true
end)

registerButton("Left.DailysButton", function()
	-- TODO: Implement DailysButton functionality
	print("Clicked DailysButton")
end)

registerButton("Left.InventoryButton", function()
	-- TODO: Implement InventoryButton functionality
	print("Clicked InventoryButton")
end)

registerButton("Left.RebirthButton", function()
	-- TODO: Implement RebirthButton functionality
	print("Clicked RebirthButton")
end)

registerButton("Left.CodesButton", function()
	-- TODO: Implement CodesButton functionality
	print("Clicked CodesButton")
end)

registerButton("Left.VIPButton", function()
	-- TODO: Implement VIPButton functionality
	print("Clicked VIPButton")
end)

local AutoClickerToggle = RemoteSignal.new("AutoClickerToggle")
registerButton("Right.AutoClickerButton", function()
	AutoClickerToggle:FireLocal()
end)

registerButton("Right.HideUIButton", function()
	-- TODO: Implement HideUIButton functionality
	print("Clicked HideUIButton")
end)

registerButton("MainClickButton", function() return end)

-- Initial selection
if #buttonsList > 0 then
	SetupButtonsLocal:FireLocal(MainHUD)
else
	warn("No buttons registered in MainHUDController!")
end