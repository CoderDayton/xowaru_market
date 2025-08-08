local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))
local UIController = require(ReplicatedStorage:WaitForChild("UIController"))
local ShopUIPopulator = require(ReplicatedStorage:WaitForChild("AFKSystem").ShopUIPopulator)
local SoundHandler = require(ReplicatedStorage:WaitForChild("SoundHandler"))
local SoftShadow = require(ReplicatedStorage:WaitForChild("Utils").SoftShadow)
local StyleGuide = require(ReplicatedStorage:WaitForChild("Shared").StyleGuide)

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
    onEnable = function()
        local mainPanel = ShopUI:FindFirstChild("MainPanel")
        local contentArea = mainPanel:FindFirstChild("ContentArea")
        if mainPanel then
            SoftShadow.apply(mainPanel, {
                SizeScale = 2,
                Opacity = 0.5,
                Color = Color3.fromRGB(0, 0, 0),
                Position = "Outside",
            })
        end

        if contentArea then
            SoftShadow.apply(contentArea, {
                SizeScale = 1.5,
                Opacity = 0.5,
                Color = StyleGuide.Colors.Glow5,
                Position = "Inside"
            })
        end
    end,
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