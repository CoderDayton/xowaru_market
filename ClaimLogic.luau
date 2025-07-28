local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClaimUtils = require(ReplicatedStorage:WaitForChild("ClaimUtils"))
local UIUtils = require(ReplicatedStorage:WaitForChild("UIUtils"))
local MarketplaceService = game:GetService("MarketplaceService")

local debug = false -- Set to false in production

for pName, pConfig in pairs(ClaimUtils.GetPodiums()) do
    local podium = ClaimUtils.GetPodiumObject(pName)
    if not podium then
        warn("Podium not found in Workspace: " .. tostring(pName))
        continue
    end

    local claimPrompt = podium:FindFirstChild("ClaimTrigger") and podium.ClaimTrigger:FindFirstChildOfClass("ProximityPrompt")
    local billboardLabel = podium:FindFirstChild("TextHolder") and podium.TextHolder:FindFirstChild("BillboardGui") and podium.TextHolder.BillboardGui:FindFirstChildOfClass("TextLabel")
    local assetId = tonumber(pConfig.UGCAssetId)
    if not assetId then
        warn("No valid UGCAssetId for podium: " .. pName)
        continue
    end

    local assetInfo = MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
    local isLimited = assetInfo and assetInfo.IsLimitedUnique

    local gamepassId = nil
    if isLimited then
        gamepassId = tonumber(pConfig.GamepassId)
        if not gamepassId then
            warn("No GamepassId found for limited item at podium: " .. podium.Name)
            continue
        end
    end

    -- Helper: Get live UGC stock
    local function getLiveStock()
        local success, info = pcall(function()
            return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
        end)
        if success and info and info.Remaining then
            return info.Remaining
        else
            return 0
        end
    end

    -- Billboard always shows live stock (with ClaimUtils polish)
    local function updateBillboard()
        if not billboardLabel or billboardLabel.Text == "" then return end
        local stock = isLimited and getLiveStock() or nil

        -- ClaimUtils.UpdateBillboard(
        --     billboardLabel,
        --     stock,
        --     podium
        -- )

        local info = MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
        UIUtils.SetupOrUpdateBillboard(podium, pConfig, info)

        if claimPrompt and isLimited then
            claimPrompt.Enabled = (stock > 0)
        end
    end

    updateBillboard()

    if isLimited then
        task.spawn(function()
            while true do
                updateBillboard()
                task.wait(10)
            end
        end)
    end

    if claimPrompt then
        claimPrompt.Triggered:Connect(function(player)
            updateBillboard()

            local liveStock = getLiveStock()
            -- 1. Sold out? (first check)
            if isLimited and liveStock <= 0 then
                UIUtils.ShowFeedback(player, pConfig.SoldOutMessage, {Type = "Error"})
                return
            end

            -- 2. Already owns UGC?
            local ownsUGC = false
            if ClaimUtils.CreatorUserId == player.UserId and debug then
                ownsUGC = false -- Creator can bypass ownership check in debug mode
            else
                ownsUGC = ClaimUtils.PlayerOwnsUGC(player, assetId)
            end
            if ownsUGC then
                UIUtils.ShowFeedback(player, pConfig.AlreadyClaimedMessage, {Type = "Error"})
                return
            end

            -- 3. Gamepass check (for limited)
            if isLimited then
                local ownsGamepass = false
                if ClaimUtils.CreatorUserId == player.UserId and debug then
                    ownsGamepass = false -- Creator can bypass gamepass check in debug mode
                else
                    ownsGamepass = ClaimUtils.PlayerOwnsGamepass(player, gamepassId)
                end

                if not ownsGamepass then
                    MarketplaceService:PromptGamePassPurchase(player, gamepassId)
                    -- Listen for GamePass purchase
                    local conn
                    conn = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(playerId, purchasedGamepassId, wasPurchased)
                        if playerId == player.UserId and purchasedGamepassId == gamepassId then
                            if wasPurchased then
                                -- Double-check live stock
                                local currentStock = getLiveStock()
                                if currentStock <= 0 then
                                    UIUtils.ShowFeedback(player, "The item just sold out! Tragic.", {Type = "Error"})
                                    updateBillboard()
                                    conn:Disconnect()
                                    return
                                end
                                -- Fire purchase event for leaderboard
                                local price = MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass).PriceInRobux or 0
                                ReplicatedStorage.PurchaseMade:FireServer(player, pConfig.DisplayName, price)
                                -- Prompt UGC purchase
                                MarketplaceService:PromptPurchase(player, assetId)
                                ClaimUtils.PlayClaimEffectAtPodium(podium)
                                UIUtils.ShowFeedback(player, pConfig.ClaimMessage)
                            else
                                UIUtils.ShowFeedback(player, "You need the gamepass to claim this item!", {Type = "Error"})
                            end
                            conn:Disconnect()
                        end
                    end)
                    return
                end
            end

            -- 4. Prompt UGC purchase (normal or after gamepass check)
            MarketplaceService:PromptPurchase(player, assetId)
        end)
    end
end