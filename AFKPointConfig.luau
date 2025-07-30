local AFKPointConfig = {
	ShardInterval = 1,      -- seconds between shard awards
	BaseShards = 1,         -- base shards per interval
	MaxClicksPerSecond = 5, -- Prevents autoclicking exploits (set to whatever feels fair)
    FriendBonusCap = 1.5, -- Max 50% from friends

	BonusActions = {
		Click = 2,
		MinigameWin = 10,
	},

	Gamepasses = {
		["x2 Shards"] = {
			GamepassId = 1234567890,
			Description = "Earn x2 Shards permanently. Cannot stack with x3 Shards",
			StackType = "Multiply",
			BoundTo = {"3x Shards"}, -- Cannot purchase if player owns x3 Shards
			RobuxPrice = 99,
			PointPrice = 25000,
            Features = {
                ShardMultiplier = 2, -- 2x shards from AFKing and clicking
            }
		},
		["x3 Shards"] = {
			GamepassId = 2345678901,
			Description = "Earn triple shards permanently. Cannot stack with x2 Shards",
			StackType = "Multiply",
			BoundTo = {"x2 Shards"}, -- Cannot purchase if player owns x2 Shards
			RobuxPrice = 199,
			PointPrice = 50000,
            Features = {
                ShardMultiplier = 3, -- 3x shards from AFKing and clicking
            }
		},
		["VIP"] = {
			GamepassId = 3456789012,
			Description = "Exclusive VIP perks including 50% more shards, 50% faster auto-clicking, 10% UGC discount and more.",
			RobuxPrice = 425,
			PointPrice = 200000,
            Features = {
                ChatTag = "🌟VIP🌟",
                NameColor = Color3.fromRGB(255, 205, 90),
                DiscountPercent = 10, -- 10% discount on all UGC purchases
                MinigameBonus = 1.5, -- 50% more shards from minigames
                AutoClickerMultiplier = 1.5, -- 50% faster auto-clicker
                ShardMultiplier = 1.5, -- 50% more shards from AFKing and clicking
            }
		},
		["Fast Collector"] = {
			GamepassId = 4567890123,
			Description = "Shards awarded 30% faster.",
			StackType = "Multiply",
			RobuxPrice = 149,
			PointPrice = 30000,
            Features = {
                IntervalMultiplier = 0.7, -- 30% faster shard collection
            }
		},
        ["Auto Clicker"] = {
            GamepassId = 5678901234,
            Description = "Automatically clicks for you, earning shards without manual clicking.",
            RobuxPrice = 199,
            PointPrice = 50000,
            Features = {
                ClickRate = 5,   -- Clicks per second
            }
        }
	},

	Boosts = {
		["Friend Invite"] = {
			Description = "For each friend in-game, get +10% shards (max 50%).",
			StackType = "Multiply",
			RobuxPrice = nil,
			PointPrice = nil,
            Features = {
                ShardMultiplier = 1.1, -- 10% more shards per friend
            }
		},
	},

	Consumables = {
		["x2 Shards 1hr"] = {
			Duration = 3600, -- 1 hour
			ProductId = 1111111111,
			Description = "x2 shards for 1 hour.",
			RobuxPrice = 20,
			PointPrice = 5000,
            Features = {
                ShardMultiplier = 2, -- 2x shards for the duration
            }
		},
		["x3 Shards 30min"] = {
			Duration = 1800, -- 30 minutes
			ProductId = 1111111112,
			Description = "x3 shards for 30 minutes.",
			RobuxPrice = 15,
			PointPrice = 4000,
            Features = {
                ShardMultiplier = 3, -- 3x shards for the duration
            }
		},
		["x10 Shards 5min"] = {
			Duration = 300, -- 5 minutes
			ProductId = 1111111113,
			Description = "x10 shards for 5 minutes.",
			RobuxPrice = 10,
			PointPrice = 1500,
            Features = {
                ShardMultiplier = 10, -- 10x shards for the duration
            }
		},
		["Minigame x2 1hr"] = {
			Duration = 3600,
			ProductId = 1111111115,
			Description = "Double rewards from minigames for 1 hour.",
			RobuxPrice = 18,
			PointPrice = 2500,
            Features = {
                MinigameMultiplier = 2, -- Double minigame rewards for the duration
            }
		},
	},

	ShardPurchases = {
		{Amount = 1000, Price = 5},
		{Amount = 10000, Price = 10},
		{Amount = 50000, Price = 75},
		{Amount = 250000, Price = 250},
		{Amount = 500000, Price = 325},
	},

	DailyStreakRewards = {
		[1] = {Type = "Shards", Amount = 500, Description = "Day 1: 500 Shards"},
		[2] = {Type = "Shards", Amount = 1000, Description = "Day 2: 1000 Shards"},
		[3] = {Type = "Consumable", Consumable = "x2 Shards 1hr", Description = "Day 3: x2 Shards Booster"},
		[4] = {Type = "Shards", Amount = 2000, Description = "Day 4: 2000 Shards"},
		[5] = {Type = "Badge", BadgeId = 123456789, Description = "Day 5: Special Badge"},
		[6] = {Type = "Consumable", Consumable = "x10 Shards 5min", Description = "Day 6: x10 Shards Booster"},
		[7] = {Type = "Shards", Amount = 5000, Description = "Day 7: 5000 Shards!"},
	},

	Titles = {
		-- Unlocked by total shards earned, claims, or milestones
		{Name = "Rookie Collector", Requirement = {Type = "TotalShards", Amount = 10000}},
		{Name = "UGC Enthusiast", Requirement = {Type = "Claims", Amount = 5}},
		{Name = "Shard Tycoon", Requirement = {Type = "TotalShards", Amount = 100000}},
		{Name = "Legendary", Requirement = {Type = "Claims", Amount = 25}},
	},

	DataStoreKey = "AFKShards",
	UpgradeKey = "AFKShardUpgrades",
	ConsumableKey = "AFKShardConsumables",
	DailyStreakKey = "AFKDailyStreak",
}

return AFKPointConfig
