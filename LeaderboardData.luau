local DSS = game:GetService("DataStoreService")
local RecentDS = DSS:GetDataStore("RecentPurchases")
local TopDS = DSS:GetOrderedDataStore("TopSpenders")

local MAX_RECENT = 25
local purchaseCooldown = {}

local LeaderboardData = {}

function LeaderboardData.RecordPurchase(userId, playerName, itemName, price)
	if purchaseCooldown[userId] and time() - purchaseCooldown[userId] < 2 then
		warn("Player is on purchase cooldown")
		return
	end
	purchaseCooldown[userId] = time()

	local success, recent = pcall(function()
		return RecentDS:GetAsync("RecentList") or {}
	end)
	if not success then recent = {} end
	table.insert(recent, 1, {userId = userId, name = playerName, item = itemName, price = price, timestamp = os.time()})
	if #recent > MAX_RECENT then
		table.remove(recent, #recent)
	end
	pcall(function() RecentDS:SetAsync("RecentList", recent) end)

	local currentTotal = (TopDS:GetAsync(userId) or 0) + price
	pcall(function() TopDS:SetAsync(userId, currentTotal) end)
end

function LeaderboardData.GetRecentPurchases()
	local success, recent = pcall(function()
		return RecentDS:GetAsync("RecentList")
	end)
	return success and recent or {}
end

function LeaderboardData.GetTopSpenders(limit)
	local success, data = pcall(function()
		return TopDS:GetSortedAsync(false, limit)
	end)
	if success then
		local topSpenders = data:GetCurrentPage()
		local result = {}
		for _, entry in ipairs(topSpenders) do
			local userId = tonumber(entry.key)
			local amount = entry.value
			table.insert(result, {userId = userId, amount = amount})
		end
		return result
	else
		return {}
	end
end

function LeaderboardData.ClearAll()
	pcall(function() RecentDS:RemoveAsync("RecentList") end)
	pcall(function()
		local data = TopDS:GetSortedAsync(false, 100):GetCurrentPage()
		for _,entry in pairs(data) do
			TopDS:RemoveAsync(entry.key)
		end
	end)
end

return LeaderboardData
