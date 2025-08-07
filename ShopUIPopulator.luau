local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local AFKSystem           = ReplicatedStorage:WaitForChild("AFKSystem")
local AFKPointConfig      = require(AFKSystem.AFKPointConfig)
local ProductCardTemplate = AFKSystem.ProductCardTemplate
local Players             = game:GetService("Players")
local PlayerGui           = Players.LocalPlayer:WaitForChild("PlayerGui")
local UIUtils             = require(ReplicatedStorage:WaitForChild("UIUtils"))
local MultiFrameScrollManager = require(ReplicatedStorage:WaitForChild("MultiFrameScrollManager"))

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
        local panel = ShopUI.MainPanel
        local contentArea = panel:FindFirstChild("ContentArea")
        if not contentArea then
            error("ContentArea container not found")
        end

        local itemCount = 0

        -- Gamepasses section
        local gamepassesSection = contentArea:FindFirstChild("Gamepasses")
        if gamepassesSection then
            local content = gamepassesSection:FindFirstChild("Content")
            if content then
                clearChildren(content)

                -- Populate Gamepasses
                for itemName, itemData in pairs(AFKPointConfig.Gamepasses) do
                    local shopItem = createShopItem(itemName, itemData)
                    addItemToShopUI(shopItem, content)
                    itemCount += 1
                end
            end
        end

        -- Shard purchases section
        local shardsSection = contentArea:FindFirstChild("Shards")
        if shardsSection and AFKPointConfig.ShardPurchases then
            local content = shardsSection:FindFirstChild("Content")
            if content then
                clearChildren(content)

                for _, purchase in ipairs(AFKPointConfig.ShardPurchases) do
                    local formattedAmount = ""
                    if UIUtils and UIUtils.FormatShardCount then
                        formattedAmount = UIUtils.FormatShardCount(purchase.Amount)
                    else
                        formattedAmount = tostring(purchase.Amount)
                    end

                    local shopItem = createShopItem(formattedAmount .. " Shards", {
                        Description = "Purchase " .. formattedAmount .. " shards",
                        RobuxPrice = purchase.Price,
                    })
                    addItemToShopUI(shopItem, content)
                    itemCount += 1
                end
            end
        end

        -- Consumables section
        local consumablesSection = contentArea:FindFirstChild("Consumables")
        if consumablesSection and AFKPointConfig.Consumables then
            local content = consumablesSection:FindFirstChild("Content")
            if content then
                clearChildren(content)

                for itemName, itemData in pairs(AFKPointConfig.Consumables) do
                    local shopItem = createShopItem(itemName, itemData)
                    addItemToShopUI(shopItem, content)
                    itemCount += 1
                end
            end
        end

        -- Setup automatic scrolling for the main contentArea ScrollingFrame
        -- This will automatically calculate CanvasSize based on all the child frames with layouts
        MultiFrameScrollManager.setupScrollingFrame(contentArea)

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