local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))
local UIController = require(ReplicatedStorage:WaitForChild("UIController"))
local ShopUIPopulator = require(ReplicatedStorage:WaitForChild("AFKSystem").ShopUIPopulator)
local SoundHandler = require(ReplicatedStorage:WaitForChild("SoundHandler"))

local ShopUI = script.Parent
local MainPanel = ShopUI:WaitForChild("MainPanel")

local SetupButtonsLocal = RemoteSignal.new("SetupButtonsLocal")

local shopBindings = {
    {
        button = "MainPanel.CloseButton",
        handler = function()
            ShopUI.Enabled = false
        end
    }
}

-- Create shop controller with configuration
local shopController = UIController.new(ShopUI, shopBindings, {
    defaultSound = "ButtonSound",
    gamepadEnabled = true,
    onEnable = function() return end,
    onDisable = function() return end
})

-- Function to register product buttons dynamically
local function registerProductButtons()
    local contentArea = MainPanel:FindFirstChild("ContentArea")
    if not contentArea then return end

    local gamepasses = contentArea:FindFirstChild("Gamepasses")
    local content = gamepasses:FindFirstChild("Content")
    shopController:registerProductButtons(content, function(card, button)
        print("[ShopUI] Purchasing " .. card.Title.Text)
        SoundHandler.PlaySound("ButtonSound")
    end)

    local shards = contentArea:FindFirstChild("Shards")
    content = shards:FindFirstChild("Content")
    shopController:registerProductButtons(content, function(card, button)
        print("[ShopUI] Purchasing " .. card.Title.Text)
        SoundHandler.PlaySound("ButtonSound")
    end)

    local consumables = contentArea:FindFirstChild("Consumables")
    content = consumables:FindFirstChild("Content")
    shopController:registerProductButtons(content, function(card, button)
        print("[ShopUI] Purchasing " .. card.Title.Text)
        SoundHandler.PlaySound("ButtonSound")
    end)

    print("[ShopUIController] Registered " .. #shopController.buttonsList - 1 .. " product buttons")
end

-- Initialize the controller
local function init()
    -- Clear existing button registry and populate shop UI
    local success = ShopUIPopulator.PopulateShopUI()
    if not success then
        warn("[ShopUIController] Failed to populate shop UI.")
        return
    end

    SetupButtonsLocal:FireLocal(ShopUI)

    shopController:initialize()

    registerProductButtons()

    print("[ShopUIController] Initialized with " .. #shopController.buttonsList .. " buttons.")
end

-- Initialize when script loads
init()

-- Re-initialize when shop UI is shown
ShopUI:GetPropertyChangedSignal("Enabled"):Connect(function()
    if ShopUI.Enabled then
        init()
    end
end)

return shopController