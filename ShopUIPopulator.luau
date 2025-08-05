local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AFKPointConfig = require(ReplicatedStorage:WaitForChild("AFKSystem"):WaitForChild("AFKPointConfig"))
local ProductCardTemplate = ReplicatedStorage:WaitForChild("AFKSystem"):WaitForChild("ProductCardTemplate")
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local function clearChildren(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

local function createShopItem(itemName, itemData)
    local shopItem = {
        Title = itemName,
        Description = itemData.Description or "No description available",
        Price = itemData.RobuxPrice or 0,
        Icon = itemData.Icon or "rbxassetid://15843018474", -- Default icon if not provided
        Color = itemData.Color or ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(146, 146, 146)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(53, 53, 53)),
        }),
    }
    return shopItem
end

local function addItemToShopUI(shopItem, parent)
    local productCard = ProductCardTemplate:Clone()
    productCard.Title.Text = shopItem.Title
    productCard.Description.Text = shopItem.Description
    productCard.PurchaseButton.Price.Text = tostring(shopItem.Price)
    productCard.Icon.Image = shopItem.Icon
    productCard.UIGradient.Color = shopItem.Color
    productCard.Parent = parent
end

local function populateShopUI()
    local content = PlayerGui:WaitForChild("ShopUI").CanvasGroup.MainPanel.ContentArea.Gamepasses.Content
    clearChildren(content)

    -- Gamepasses section
    for itemName, itemData in pairs(AFKPointConfig.Gamepasses) do
        local shopItem = createShopItem(itemName, itemData)
        addItemToShopUI(shopItem, content)
    end

    -- for _, purchase in ipairs(AFKPointConfig.ShardPurchases) do
    --     local shopItem = createShopItem("Buy " .. purchase.Amount .. " Shards", {
    --         Description = "Purchase " .. purchase.Amount .. " shards",
    --         RobuxPrice = purchase.Price,
    --     })
    --     addItemToShopUI(shopItem, content)
    -- end

    -- for itemName, itemData in pairs(AFKPointConfig.Consumables) do
    --     local shopItem = createShopItem(itemName, itemData)
    --     addItemToShopUI(shopItem, content)
    -- end
end

local function init()
    populateShopUI()
end

init()
