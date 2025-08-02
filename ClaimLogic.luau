local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClaimUtils = require(ReplicatedStorage:WaitForChild("ClaimUtils"))
local UIUtils = require(ReplicatedStorage:WaitForChild("UIUtils"))
local MarketplaceService = game:GetService("MarketplaceService")

local debug = false -- Set to false in production

-- Cache table for GetProductInfo
local productCache = {}
local CACHE_TTL = 10 -- seconds

-- Fetch with caching
local function getCachedProductInfo(assetId)
	local cached = productCache[assetId]
	if cached and (tick() - cached.timestamp < CACHE_TTL) then
		return cached.info
	end

	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
	end)

	if success and info then
		productCache[assetId] = {
			info = info,
			timestamp = tick()
		}
		return info
	else
		warn("Failed to get product info for assetId: " .. tostring(assetId))
		return nil
	end
end

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

	local initialInfo = getCachedProductInfo(assetId)
	if not initialInfo then continue end

	local isLimited = initialInfo.IsLimitedUnique
	local gamepassId = isLimited and tonumber(pConfig.GamepassId) or nil

	if isLimited and not gamepassId then
		warn("No GamepassId found for limited item at podium: " .. podium.Name)
		continue
	end

	-- Helper: Get live UGC stock
	local function getLiveStock()
		local info = getCachedProductInfo(assetId)
		return (info and info.Remaining) or 0
	end

	local function updateBillboard()
		if not billboardLabel or billboardLabel.Text == "" then return end

		local info = getCachedProductInfo(assetId)
		if not info then return end

		UIUtils.SetupOrUpdateBillboard(podium, pConfig, info)

		if claimPrompt and isLimited then
			local stock = info.Remaining or 0
			claimPrompt.Enabled = (stock > 0)
		end
	end

	updateBillboard()

	if isLimited then
		task.spawn(function()
			while true do
				updateBillboard()
				task.wait(CACHE_TTL)
			end
		end)
	end

	if claimPrompt then
		claimPrompt.Triggered:Connect(function(player)
			updateBillboard()

			local liveStock = getLiveStock()
			if isLimited and liveStock <= 0 then
				UIUtils.ShowFeedback(player, pConfig.SoldOutMessage, {Type = "Error"})
				return
			end

			local ownsUGC = false
			if ClaimUtils.CreatorUserId == player.UserId and debug then
				ownsUGC = false
			else
				ownsUGC = ClaimUtils.PlayerOwnsUGC(player, assetId)
			end
			if ownsUGC then
				UIUtils.ShowFeedback(player, pConfig.AlreadyClaimedMessage, {Type = "Error"})
				return
			end

			if isLimited then
				local ownsGamepass = false
				if ClaimUtils.CreatorUserId == player.UserId and debug then
					ownsGamepass = false
				else
					ownsGamepass = ClaimUtils.PlayerOwnsGamepass(player, gamepassId)
				end

				if not ownsGamepass then
					MarketplaceService:PromptGamePassPurchase(player, gamepassId)

					local conn
					conn = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(playerId, purchasedGamepassId, wasPurchased)
						if playerId == player.UserId and purchasedGamepassId == gamepassId then
							if wasPurchased then
								local currentStock = getLiveStock()
								if currentStock <= 0 then
									UIUtils.ShowFeedback(player, "The item just sold out! Tragic.", {Type = "Error"})
									updateBillboard()
									conn:Disconnect()
									return
								end

								local priceInfo = MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
								local price = priceInfo and priceInfo.PriceInRobux or 0
								ReplicatedStorage.PurchaseMade:FireServer(player, pConfig.DisplayName, price)
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

			MarketplaceService:PromptPurchase(player, assetId)
		end)
	end
end
