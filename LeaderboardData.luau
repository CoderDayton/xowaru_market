--[[
    LeaderboardData module for managing recent purchases and top spenders.
    - Records purchases with cooldowns.
    - Manages recent purchases per user.
    - Retrieves top spenders with a limit.
    - Clears all data (for admin use).
]]--

local DSS = game:GetService("DataStoreService")

local RecentDS = DSS:GetDataStore("RecentPurchases")
local TopDS = DSS:GetOrderedDataStore("TopSpenders")
local RecentIndexDS = DSS:GetOrderedDataStore("RecentPurchaseIndex")


-- ========== Configuration ==========
local MAX_RECENT = 25
local CLEANUP_INTERVAL_SECONDS = 12 * 60 * 60 -- 12 hours
local CLEANUP_RETENTION_DAYS = 30

-- ========== Local Variables ==========
local cleanupActive = false
local purchaseCooldown = {}


local LeaderboardData = {}

function LeaderboardData.RecordPurchase(userId, playerName, itemName, price)
	if purchaseCooldown[userId] and time() - purchaseCooldown[userId] < 2 then
		warn("Player is on purchase cooldown")
		return
	end
	purchaseCooldown[userId] = time()

	-- Handle per-player recent purchases
	local purchaseKey = "RecentList_" .. userId
	local success, recent = pcall(function()
		return RecentDS:GetAsync(purchaseKey) or {}
	end)
	if not success then recent = {} end

	local timestamp = os.time()
	table.insert(recent, 1, {userId = userId, name = playerName, item = itemName, price = price, timestamp = timestamp})
	if #recent > MAX_RECENT then
		table.remove(recent, #recent)
	end

	pcall(function()
		RecentDS:SetAsync(purchaseKey, recent)
	end)

	local indexKey   = ("%d_%d"):format(timestamp, userId)   --  max ≈ 22 chars
	pcall(function()
		RecentIndexDS:SetAsync(indexKey, timestamp)    end)

	local currentTotal = (TopDS:GetAsync(userId) or 0) + price
	pcall(function() 
		TopDS:SetAsync(userId, currentTotal)
	end)
end

function LeaderboardData.GetRecentPurchases(userId)
	local purchaseKey = "RecentList_" .. userId
	local success, recent = pcall(function()
		return RecentDS:GetAsync(purchaseKey)
	end)
	return success and recent or {}
end

function LeaderboardData.GetAllRecentPurchases()
	local ok, pages = pcall(function()
		return RecentIndexDS:GetSortedAsync(false, MAX_RECENT)
	end)
	if not ok then return {} end

	local feed = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local ts, uid = entry.key:match("^(%d+)_(%d+)$")
		if ts and uid then
			local perKey = "RecentList_" .. uid
			local succ, list = pcall(function()
				return RecentDS:GetAsync(perKey) or {}
			end)
			if succ then
				for _, p in ipairs(list) do
					if p.timestamp == tonumber(ts) then
						table.insert(feed, p)
						break
					end
				end
			end
		end
	end
	return feed
end

function LeaderboardData.GetTopSpenders(limit)
	local success, data = pcall(function()
		return TopDS:GetSortedAsync(false, limit or MAX_RECENT)
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

function LeaderboardData.CleanupOldIndexEntries(daysOld : number)
	if cleanupActive then
		warn("[Cleanup] Cleanup already in progress")
		return
	end

	cleanupActive = true

	-- CONFIG ----------------------------------------------------------------
	local INDEX_NAME  = "RecentPurchaseIndex"   -- Your OrderedDataStore name
	local PAGE_SIZE   = 100                  -- max records pulled per page
	--------------------------------------------------------------------------

	local DataStoreService = game:GetService("DataStoreService")
	local indexStore       = DataStoreService:GetOrderedDataStore(INDEX_NAME)
	local cutoff = os.time() - (daysOld * 24 * 60 * 60)

	local ok, page = pcall(function()
		return indexStore:GetSortedAsync(false, PAGE_SIZE)
	end)

	if not ok or not page then
		warn("[Cleanup] Failed to read index:", page)
		cleanupActive = false
		return
	end

	repeat
		for _, entry in ipairs(page:GetCurrentPage()) do
			local ts = tonumber(entry.key:match("^(%d+)"))
			if not ts or ts >= cutoff then
				-- Reached a recent entry → nothing older beyond this point
				cleanupActive = false
				return
			end

			-- Old entry → delete
			local delOk, delErr = pcall(function()
                indexStore:RemoveAsync(entry.key)
            end)
            if not delOk then
                warn("[Cleanup] Failed to remove:", entry.key, delErr)
            end
		end

        -- Check if we reached the end of the page
        if page == nil or #page:GetCurrentPage() == 0 then
            cleanupActive = false
            return
        end

		-- Advance to next page of (older) keys
		local advanceOk, nextPage = pcall(function()
			return page:AdvanceToNextPageAsync()
		end)

		if not advanceOk or not nextPage then
			warn("[Cleanup] Failed to advance to next page:", nextPage)
			cleanupActive = false
			return
		end

		page = nextPage
	until page == nil

    print("[Cleanup] Completed cleanup of old index entries older than", daysOld, "days")
	cleanupActive = false
end

function LeaderboardData.IsCleanupActive()
	return cleanupActive
end

-- Automatically clean up old index entries every 12 hours
task.spawn(function()
	while true do
		LeaderboardData.CleanupOldIndexEntries(CLEANUP_RETENTION_DAYS)
		task.wait(CLEANUP_INTERVAL_SECONDS)
	end
end)

return LeaderboardData