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
			BoundTo = {"x3 Shards"},
			RobuxPrice = 99,
			PointPrice = 250000,
			Features = {
				ShardMultiplier = 2,
			},
			Icon = "rbxassetid://x2shardsiconid",
		},
		["x3 Shards"] = {
			GamepassId = 2345678901,
			Description = "Earn triple shards permanently. Cannot stack with x2 Shards",
			StackType = "Multiply",
			BoundTo = {"x2 Shards"},
			RobuxPrice = 199,
			PointPrice = 500000,
			Features = {
				ShardMultiplier = 3,
			},
			Icon = "rbxassetid://x3shardsiconid",
		},
		["VIP"] = {
			GamepassId = 3456789012,
			Description = "Exclusive VIP perks including 50% more shards, 50% faster auto-clicking, 10% UGC discount and more.",
			RobuxPrice = 425,
			Icon = "rbxassetid://102392861658517",
			Features = {
				ChatTag = "🌟VIP🌟",
				NameColor = Color3.fromRGB(255, 205, 90),
				DiscountPercent = 10, -- 10% off UGC items
				MinigameBonus = 2, -- 2x minigame rewards
				AutoClickerMultiplier = 1.3, -- 30% faster auto-clicking
				ShardMultiplier = 2, -- 100% more shards
			},
		},
		["Fast Collector"] = {
			GamepassId = 4567890123,
			Description = "Shards awarded 30% faster.",
			StackType = "Multiply",
			RobuxPrice = 149,
			PointPrice = 30000,
			Features = {
				IntervalMultiplier = 0.7,
			},
			Icon = "rbxassetid://fastcollectoriconid",
		},
		["Auto Clicker"] = {
			GamepassId = 5678901234,
			Description = "Automatically clicks for you, earning shards without manual clicking.",
			RobuxPrice = 199,
			PointPrice = 50000,
			Features = {
				ClickRate = 5,
			},
			Icon = "rbxassetid://autoclickericonid",
		}
	},

	-- Only show boosts here that are NOT shop unlocks and DO show up in the Boosts UI:
	Boosts = {
		["Friend Invite"] = {
			Description = "For each friend in-game, get +10% shards (max 50%).",
			StackType = "Multiply",
			Icon = "rbxassetid://friendbonusiconid",
			Features = {
				ShardMultiplier = 1.1, -- 10% more shards per friend
			}
		},
		["Premium"] = {
			Description = "Get +20% shards while Premium is active.",
			StackType = "Multiply",
			Icon = "rbxassetid://9795349605",
			Features = {
				ShardMultiplier = 1.2, -- 20% more shards while Premium
			}
		},
	},

	Consumables = {
		["x2 Shards 1hr"] = {
			Duration = 3600,
			ProductId = 1111111111,
			Description = "x2 shards for 1 hour.",
			RobuxPrice = 20,
			PointPrice = 5000,
			Features = {
				ShardMultiplier = 2,
			},
			Icon = "rbxassetid://consumable_x2_1hr",
		},
		["x3 Shards 30min"] = {
			Duration = 1800,
			ProductId = 1111111112,
			Description = "x3 shards for 30 minutes.",
			RobuxPrice = 15,
			PointPrice = 4000,
			Features = {
				ShardMultiplier = 3,
			},
			Icon = "rbxassetid://consumable_x3_30min",
		},
		["x10 Shards 5min"] = {
			Duration = 300,
			ProductId = 1111111113,
			Description = "x10 shards for 5 minutes.",
			RobuxPrice = 10,
			PointPrice = 1500,
			Features = {
				ShardMultiplier = 10,
			},
			Icon = "rbxassetid://consumable_x10_5min",
		},
		["Minigame x2 1hr"] = {
			Duration = 3600,
			ProductId = 1111111115,
			Description = "Double rewards from minigames for 1 hour.",
			RobuxPrice = 18,
			PointPrice = 2500,
			Features = {
				MinigameMultiplier = 2,
			},
			Icon = "rbxassetid://consumable_minigame_x2_1hr",
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
