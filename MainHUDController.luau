local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))

local BUTTON_SOUND_ID = "rbxassetid://14382276423"
local BUTTON_SOUND_VOLUME = 0.06
local BUTTON_SOUND_SPEED = 1.1

-- Preload the button sound at the start of the script
local buttonSound = Instance.new("Sound")
buttonSound.SoundId = BUTTON_SOUND_ID
buttonSound.Volume = BUTTON_SOUND_VOLUME
buttonSound.PlaybackSpeed = BUTTON_SOUND_SPEED
buttonSound.Parent = SoundService

local MainHUD = script.Parent

local SetupButtonsLocal = RemoteSignal.new("SetupButtonsLocal")

-- Modular button registry: { button = { handler = func, ... } }
local buttonRegistry = {}
local buttonsList = {}  -- Ordered list for navigation
local selectedIndex = 1  -- Current selected button index

-- Tween info for scaling animations
local scaleTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function PlayButtonSound()
    local sound = buttonSound:Clone()
    sound.Parent = script
    sound:Play()
    game:GetService("Debris"):AddItem(sound, sound.TimeLength)
end

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

    -- Connect mouse/touch click
    button.MouseButton1Click:Connect(function()
        PlayButtonSound()
        handlerFunc()  -- Call handler
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
                PlayButtonSound()
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
            PlayButtonSound()
            buttonRegistry[shopButton]()
        end
    end
end, false, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.UserInputType.Touch)

ContextActionService:BindAction("ToggleAutoClicker", function(actionName, inputState)
    if inputState == Enum.UserInputState.Begin then
        local autoButton = buttonsList[2]  -- Assuming second is AutoClickerButton; adjust index
        if autoButton then
            PlayButtonSound()
            buttonRegistry[autoButton]()
        end
    end
end, false, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.DPadDown, Enum.UserInputType.Touch)

registerButton("Left.ShopButton", function()
    local ShopUI = MainHUD.Parent:WaitForChild("ShopUI")
    ShopUI.Enabled = not ShopUI.Enabled
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