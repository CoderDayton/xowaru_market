local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local AFKSystem           = ReplicatedStorage:WaitForChild("AFKSystem")
local AFKPointConfig      = require(AFKSystem.AFKPointConfig)
local ProductCardTemplate = AFKSystem.ProductCardTemplate
local Players             = game:GetService("Players")
local PlayerGui           = Players.LocalPlayer:WaitForChild("PlayerGui")

local ShopUI              = PlayerGui:WaitForChild("ShopUI")

local ShopUIPopulator = {}

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

function ShopUIPopulator.PopulateShopUI()
    local success, result = pcall(function()
        local panel = ShopUI.CanvasGroup.MainPanel
        local content = panel.ContentArea.Gamepasses.Content

        if not content then
            error("Content container not found")
        end

        clearChildren(content)

        local itemCount = 0

        -- Gamepasses section
        for itemName, itemData in pairs(AFKPointConfig.Gamepasses) do
            local shopItem = createShopItem(itemName, itemData)
            addItemToShopUI(shopItem, content)
            itemCount += 1
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

        return itemCount > 0
    end)

    if success then
        print("Shop UI populated with items.")
        return true, result
    else
        warn("Failed to populate Shop UI:", result)
        return false, result
    end
end

return ShopUIPopulator