local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))
local SoundHandler = require(ReplicatedStorage:WaitForChild("SoundHandler"))
local AFKSystem = ReplicatedStorage:WaitForChild("AFKSystem")
local ShopUIPopulator = require(AFKSystem.ShopUIPopulator)

local ShopUI = script.Parent
local MainPanel = ShopUI:WaitForChild("CanvasGroup"):WaitForChild("MainPanel")
local CloseButton = MainPanel:WaitForChild("CloseButton")

local SetupButtonsLocal = RemoteSignal.new("SetupButtonsLocal")

-- ===== Button Management System =====
local buttonRegistry = {}
local buttonsList = {}  -- Ordered list for navigation
local selectedIndex = 1  -- Current selected button index
local isInitialized = false

-- Tween info for scaling animations
local scaleTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Function to scale a button (selected/deselected)
local function setButtonScale(button, isSelected)
    local uiScale = button:FindFirstChild("UIScale") or Instance.new("UIScale")
    uiScale.Parent = button
    local targetScale = isSelected and 1.1 or 1
    TweenService:Create(uiScale, scaleTweenInfo, {Scale = targetScale}):Play()
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

-- Handle input when shop UI is enabled
local inputConnection = nil
local function setupInputHandling()
    if inputConnection then return end

    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not ShopUI.Enabled or gameProcessed then return end

        -- Escape key to close
        if input.KeyCode == Enum.KeyCode.Escape then
            ShopUI.Enabled = false
            SoundHandler.PlaySound("ButtonSound")
            return
        end

        -- Gamepad navigation
        if input.UserInputType == Enum.UserInputType.Gamepad1 then
            if #buttonsList == 0 then return end

            if input.KeyCode == Enum.KeyCode.DPadDown then
                moveSelection(1)
            elseif input.KeyCode == Enum.KeyCode.DPadUp then
                moveSelection(-1)
            elseif input.KeyCode == Enum.KeyCode.ButtonA then
                local selectedButton = buttonsList[selectedIndex]
                if selectedButton then
                    SoundHandler.PlaySound("ButtonSound")
                    buttonRegistry[selectedButton]()
                end
            elseif input.KeyCode == Enum.KeyCode.ButtonB then
                ShopUI.Enabled = false
                SoundHandler.PlaySound("ButtonSound")
            end
        end
    end)
end

-- Clean up connection when UI is disabled
ShopUI:GetPropertyChangedSignal("Enabled"):Connect(function()
    if ShopUI.Enabled then
        setupInputHandling()
        if #buttonsList > 0 and selectedIndex <= #buttonsList then
            selectButton(selectedIndex)
        end
    else
        if inputConnection then
            inputConnection:Disconnect()
            inputConnection = nil
        end
    end
end)

local function registerButton(button, handlerFunc)
    if not button or not handlerFunc or type(handlerFunc) ~= "function" then
        warn("[ShopUI] Invalid button registration:", button, handlerFunc)
        return
    end
    
    if not button:IsA("GuiObject") then
        warn("[ShopUI] Button is not a valid GuiObject:", button)
        return
    end
    
    table.insert(buttonsList, button)
    buttonRegistry[button] = handlerFunc
    
    -- Connect mouse click (PC/desktop)
    button.MouseButton1Click:Connect(function()
        SoundHandler.PlaySound("ButtonSound")
        handlerFunc()  -- Call handler
    end)
    
    -- Add mobile touch handling
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            setButtonScale(button, true)
        end
    end)
    
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local tolerance = 5  -- Pixels
            local touchPos = input.Position
            local buttonPos = button.AbsolutePosition
            local buttonSize = button.AbsoluteSize
            if touchPos.X >= buttonPos.X - tolerance and touchPos.X <= buttonPos.X + buttonSize.X + tolerance and
                touchPos.Y >= buttonPos.Y - tolerance and touchPos.Y <= buttonPos.Y + buttonSize.Y + tolerance then
                SoundHandler.PlaySound("ButtonSound")
                handlerFunc()  -- Call handler
                setButtonScale(button, false)
            end
        end
    end)
    
    -- Initial scale (deselected)
    setButtonScale(button, false)
end

-- Register product buttons (will be populated dynamically)
local function registerProductButtons()
    local contentArea = MainPanel:FindFirstChild("ContentArea")
    if not contentArea then return end

    local gamepasses = contentArea:FindFirstChild("Gamepasses")
    if not gamepasses then return end

    local content = gamepasses:FindFirstChild("Content")
    if not content then return end

    -- Register each product card button directly using the button instance
    for _, card in ipairs(content:GetChildren()) do
        if card:IsA("Frame") and card:FindFirstChild("PurchaseButton") then
            local purchaseButton = card:FindFirstChild("PurchaseButton")

            -- Register button directly using the instance instead of path
            if purchaseButton then
                table.insert(buttonsList, purchaseButton)
                buttonRegistry[purchaseButton] = function()
                    print("[ShopUI] Purchasing " .. card.Title.Text)
                    -- Add purchase logic here
                end

                -- Connect mouse click (PC/desktop)
                purchaseButton.MouseButton1Click:Connect(function()
                    SoundHandler.PlaySound("ButtonSound")
                    buttonRegistry[purchaseButton]()  -- Call handler
                end)

                -- Add mobile touch handling
                purchaseButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        setButtonScale(purchaseButton, true)
                    end
                end)

                purchaseButton.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        local tolerance = 5  -- Pixels
                        local touchPos = input.Position
                        local buttonPos = purchaseButton.AbsolutePosition
                        local buttonSize = purchaseButton.AbsoluteSize
                        if touchPos.X >= buttonPos.X - tolerance and touchPos.X <= buttonPos.X + buttonSize.X + tolerance and
                            touchPos.Y >= buttonPos.Y - tolerance and touchPos.Y <= buttonPos.Y + buttonSize.Y + tolerance then
                            SoundHandler.PlaySound("ButtonSound")
                            buttonRegistry[purchaseButton]()  -- Call handler
                            setButtonScale(purchaseButton, false)
                        end
                    end
                end)

                -- Initial scale (deselected)
                setButtonScale(purchaseButton, false)
            end
        end
    end
end

-- Initialize shop UI
local function init()
    -- Clear existing button registry
    buttonRegistry = {}
    buttonsList = {}
    selectedIndex = 1

    -- Populate shop UI with items
    local success = ShopUIPopulator.PopulateShopUI()
    if not success then
        warn("[ShopUIController] Failed to populate shop UI.")
        return
    end

    SetupButtonsLocal:FireLocal(ShopUI)

    registerButton(CloseButton, function()
        ShopUI.Enabled = false
    end)

    -- Register buttons
    registerProductButtons()

    -- Setup input handling
    if ShopUI.Enabled then
        setupInputHandling()
    end

    isInitialized = true
    print("[ShopUIController] Initialized with " .. #buttonsList .. " buttons.")
end

-- Initialize when script loads
init()

-- Re-initialize when shop UI is shown
ShopUI:GetPropertyChangedSignal("Enabled"):Connect(function()
    if ShopUI.Enabled and not isInitialized then
        init()
    end
end)