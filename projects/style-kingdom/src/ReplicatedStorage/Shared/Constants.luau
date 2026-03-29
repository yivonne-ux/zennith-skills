--!strict
-- Style Kingdom — Game Constants
-- All tunable values in one place for easy balancing

local Constants = {}

-- ============================================================
-- BOUTIQUE TIERS
-- ============================================================
Constants.BOUTIQUE_TIERS = {
	[1] = { name = "Market Stall", mannequins = 1, customerCap = 1, cost = 0, earningRate = 10 },
	[2] = { name = "Small Shop", mannequins = 2, customerCap = 2, cost = 500, earningRate = 25 },
	[3] = { name = "Corner Boutique", mannequins = 3, customerCap = 3, cost = 2000, earningRate = 50 },
	[4] = { name = "Fashion Store", mannequins = 5, customerCap = 4, cost = 8000, earningRate = 100 },
	[5] = { name = "Flagship Store", mannequins = 7, customerCap = 5, cost = 25000, earningRate = 200 },
	[6] = { name = "Fashion House", mannequins = 10, customerCap = 6, cost = 75000, earningRate = 400 },
	[7] = { name = "Fashion Empire", mannequins = 15, customerCap = 8, cost = 200000, earningRate = 800 },
}

Constants.MAX_BOUTIQUE_TIER = 7

-- ============================================================
-- PROGRESSION
-- ============================================================
Constants.MAX_LEVEL = 100
Constants.MAX_PRESTIGE = 5

-- XP required per level: base * level^1.5
Constants.XP_BASE = 10 -- Tuned: L10=1day, L25=5days, L50=3wks, L100=3mo
Constants.XP_EXPONENT = 1.15 -- Tuned so Level 100 is ~3 months of daily play

-- Prestige multipliers (earnings multiplier per prestige count)
Constants.PRESTIGE_MULTIPLIERS = {
	[0] = 1.0,
	[1] = 1.5,
	[2] = 2.0,
	[3] = 2.5,
	[4] = 3.0,
	[5] = 5.0,
}

-- XP rewards
Constants.XP_CUSTOMER_SERVED = 25 -- Boosted from 15 to make customer service the primary XP source
Constants.XP_CONTEST_ENTERED = 25
Constants.XP_CONTEST_WIN = 100
Constants.XP_CONTEST_TOP3 = 50
Constants.XP_DAILY_CHALLENGE_EASY = 30
Constants.XP_DAILY_CHALLENGE_MEDIUM = 60
Constants.XP_DAILY_CHALLENGE_HARD = 100

-- ============================================================
-- ECONOMY
-- ============================================================

-- Customer payments (base, multiplied by tier and prestige)
Constants.CUSTOMER_BASE_PAY = {
	[1] = 10, -- 1 star
	[2] = 20, -- 2 stars
	[3] = 35, -- 3 stars
	[4] = 55, -- 4 stars
	[5] = 80, -- 5 stars
}
Constants.CUSTOMER_TIP_5STAR = 25 -- Bonus for 5 stars

-- Contest rewards
Constants.CONTEST_REWARDS_SC = {
	[1] = 200, -- 1st place
	[2] = 120, -- 2nd place
	[3] = 75, -- 3rd place
}
Constants.CONTEST_REWARDS_GG = {
	[1] = 10, -- 1st place
	[2] = 5, -- 2nd place
	[3] = 2, -- 3rd place
}
Constants.CONTEST_PARTICIPATION_SC = 15

-- Offline earnings
Constants.OFFLINE_MAX_HOURS = 8
Constants.OFFLINE_RATE_MULTIPLIER = 0.5 -- 50% of active rate

-- Fusion: combine 3 items of same tier to get 1 of next tier
Constants.FUSION_INPUT_COUNT = 3

-- ============================================================
-- CONTEST TIMING (seconds)
-- ============================================================
Constants.CONTEST_CYCLE_SECONDS = 900 -- 15 minutes between contests
Constants.CONTEST_DRESSING_SECONDS = 90 -- 90 seconds to dress
Constants.CONTEST_RUNWAY_SECONDS_PER_PLAYER = 15
Constants.CONTEST_VOTING_SECONDS = 60 -- 60 seconds to vote
Constants.CONTEST_RESULTS_SECONDS = 15 -- 15 seconds to show results
Constants.CONTEST_VOTES_PER_PLAYER = 3 -- Each player gets 3 votes

-- Vote weight scaling by level (level 1 = 1.0x, level 100 = 2.0x)
Constants.VOTE_WEIGHT_MIN = 1.0
Constants.VOTE_WEIGHT_MAX = 2.0

-- ============================================================
-- NPC CUSTOMERS
-- ============================================================
Constants.NPC_SPAWN_INTERVALS = {
	[1] = 20, -- Tier 1: 1 NPC every 20 seconds
	[2] = 17,
	[3] = 14,
	[4] = 12,
	[5] = 10,
	[6] = 9,
	[7] = 8, -- Tier 7: 1 NPC every 8 seconds
}
Constants.NPC_PATIENCE_BASE = 45 -- seconds before leaving
Constants.NPC_BROWSE_TIME = 4 -- seconds NPC browses before requesting

-- ============================================================
-- DAILY REWARDS
-- ============================================================
-- Boosted to compete with DTI/Fashion Famous daily rewards
Constants.LOGIN_STREAK_REWARDS = {
	[1] = { sc = 100, gg = 1, item = nil },
	[2] = { sc = 150, gg = 1, item = nil },
	[3] = { sc = 200, gg = 2, item = nil },
	[4] = { sc = 300, gg = 2, item = nil },
	[5] = { sc = 400, gg = 5, item = nil },
	[6] = { sc = 500, gg = 5, item = nil },
	[7] = { sc = 1000, gg = 15, item = "random_rare" }, -- Day 7 = premium + rare item
}
Constants.MAX_LOGIN_STREAK = 7

-- Streak escalation: multiplier applied to rewards after first week
-- Week 2 (day 8-14) = 1.5x, Week 3+ (day 15+) = 2x
Constants.STREAK_WEEK_MULTIPLIERS = {
	[1] = 1.0, -- Days 1-7
	[2] = 1.5, -- Days 8-14
	[3] = 2.0, -- Days 15-21
	[4] = 2.0, -- Days 22+
}

-- ============================================================
-- MILESTONE UNLOCKS (level → reward description)
-- ============================================================
Constants.MILESTONE_REWARDS = {
	[10] = { sc = 500, gg = 5, label = "Fusion Unlocked!" },
	[25] = { sc = 1000, gg = 10, label = "Premium Customers Unlocked!" },
	[50] = { sc = 2500, gg = 25, label = "VIP Shop Preview!" },
	[75] = { sc = 5000, gg = 50, label = "Exclusive Theme Unlocked!" },
	[100] = { sc = 10000, gg = 100, label = "Prestige Available!" },
}

-- ============================================================
-- WARDROBE
-- ============================================================
Constants.DEFAULT_OUTFIT_SLOTS = 10
Constants.EXTRA_OUTFIT_SLOTS_GAMEPASS = 20

-- ============================================================
-- GAME PASSES (Optimized pricing based on top creator data)
-- Pricing tiers: Starter(49-99), Core(149-449), Premium(799), Whale(1299)
-- Uses charm pricing (ending in 9) aligned with Robux package denominations
-- ============================================================
Constants.GAME_PASSES = {
	-- Starter tier: break "first purchase" barrier (49R = ~$0.60)
	OUTFIT_SLOTS = { id = 0, price = 49, name = "Outfit Slots Plus" },

	-- Core tier: meaningful gameplay advantage
	EXTRA_MANNEQUINS = { id = 0, price = 99, name = "Extra Mannequins" },
	AUTO_SERVE = { id = 0, price = 149, name = "Auto-Serve" },

	-- Premium tier: main revenue driver (DTI dual-pricing model)
	DOUBLE_INCOME = { id = 0, price = 449, name = "Double Income" }, -- Blox Fruits charges 450 for 2x Money
	VIP = { id = 0, price = 799, name = "VIP Fashion Pass (Permanent)" }, -- DTI charges 800 for permanent VIP
	VIP_MONTHLY = { id = 0, price = 299, name = "VIP Fashion Pass (Monthly)" }, -- DTI charges 300/mo, captures recurring revenue

	-- Whale tier: anchor pricing (makes 449/799 look reasonable)
	LUCKY_STYLIST = { id = 0, price = 1299, name = "Lucky Stylist" }, -- 5x customer tips + exclusive rare drops + priority NPC spawns
}

-- VIP Pass benefits (referenced by other systems):
-- 2x customer earnings, VIP nameplate, +10 outfit slots, daily 5 GG bonus,
-- VIP lounge access, exclusive items 20% cheaper in VIP shop

-- ============================================================
-- DEVELOPER PRODUCTS (Repeatable purchases — whale revenue ceiling)
-- Tiered GlamGems with increasing bonus % to incentivize larger purchases
-- Plus StyleCoins packs for soft currency whales
-- ============================================================
Constants.DEV_PRODUCTS = {
	-- GlamGems (premium currency)
	GG_100 = { id = 0, price = 99, glamGems = 100 }, -- Base rate
	GG_500 = { id = 0, price = 399, glamGems = 500 }, -- +25% bonus
	GG_1200 = { id = 0, price = 799, glamGems = 1200 }, -- +50% bonus
	GG_3000 = { id = 0, price = 1699, glamGems = 3000 }, -- +76% bonus (whale tier)

	-- StyleCoins (soft currency, for players who want to skip grinding)
	SC_500 = { id = 0, price = 49, styleCoins = 500 }, -- Cup-of-coffee first purchase
	SC_2000 = { id = 0, price = 149, styleCoins = 2000 }, -- +33% bonus
	SC_6000 = { id = 0, price = 399, styleCoins = 6000 }, -- +50% bonus
	SC_15000 = { id = 0, price = 799, styleCoins = 15000 }, -- +87% bonus

	-- Consumables
	LUCKY_BOX = { id = 0, price = 49 }, -- Random item gacha
	INSTANT_EXPAND = { id = 0, price = 149 }, -- Skip boutique upgrade cost
}

-- Lucky Box probabilities (displayed to players in shop UI)
Constants.LUCKY_BOX_ODDS = {
	[1] = 0.50, -- 50% Common
	[2] = 0.25, -- 25% Uncommon
	[3] = 0.15, -- 15% Rare
	[4] = 0.08, -- 8% Epic
	[5] = 0.02, -- 2% Legendary
}
-- Pity system: guaranteed Epic+ after 10 boxes, Legendary after 25
Constants.LUCKY_BOX_PITY_EPIC = 10
Constants.LUCKY_BOX_PITY_LEGENDARY = 25

-- ============================================================
-- COLLECTION ACHIEVEMENTS (F2P progression path)
-- ============================================================
Constants.COLLECTION_ACHIEVEMENTS = {
	{ id = "all_kfashion", label = "K-Fashion Complete", style = "KFashion", rewardSC = 2000, rewardGG = 20 },
	{ id = "all_jfashion", label = "J-Fashion Complete", style = "JFashion", rewardSC = 1500, rewardGG = 15 },
	{ id = "all_sea", label = "SEA Collection Complete", style = "SEA", rewardSC = 2000, rewardGG = 20 },
	{ id = "all_formal", label = "Formal Mastery", style = "Formal", rewardSC = 2500, rewardGG = 25 },
	{ id = "rarity_3_all", label = "Rare Collector", minRarity = 3, rewardSC = 3000, rewardGG = 30 },
	{ id = "rarity_4_all", label = "Epic Collector", minRarity = 4, rewardSC = 5000, rewardGG = 50 },
	{ id = "first_10", label = "Fashionista", count = 10, rewardSC = 500, rewardGG = 5 },
	{ id = "first_25", label = "Style Icon", count = 25, rewardSC = 1500, rewardGG = 15 },
	{ id = "first_50", label = "Fashion Legend", count = 50, rewardSC = 5000, rewardGG = 50 },
}

-- ============================================================
-- MANNEQUIN BONUS
-- ============================================================
-- Per mannequin wearing an outfit that matches the customer's preferred style: +10% payment
Constants.MANNEQUIN_STYLE_BONUS = 0.10

-- ============================================================
-- LUCKY STYLIST GAMEPASS BENEFITS
-- ============================================================
Constants.LUCKY_STYLIST_TIP_MULTIPLIER = 5.0 -- 5x customer tips
Constants.LUCKY_STYLIST_PRIORITY_SPAWN_CHANCE = 0.3 -- 30% chance of premium NPC
Constants.LUCKY_STYLIST_RARE_DROP_BONUS = 0.10 -- +10% to rarity 3+ in Lucky Box

-- ============================================================
-- SC PURCHASE DAILY CAP (anti-inflation for pay-to-skip)
-- ============================================================
Constants.SC_PURCHASE_DAILY_CAP = 10000 -- Max 10K SC purchasable per day

-- Weekly XP bonus for completing all 7 daily challenge sets
Constants.WEEKLY_CHALLENGE_BONUS_XP = 1000

-- ============================================================
-- SCORING
-- ============================================================
-- Star rating thresholds for customer satisfaction
Constants.CUSTOMER_STAR_THRESHOLDS = {
	[1] = 0, -- 0+ score = 1 star
	[2] = 3, -- 3+ score = 2 stars
	[3] = 6, -- 6+ score = 3 stars
	[4] = 10, -- 10+ score = 4 stars
	[5] = 15, -- 15+ score = 5 stars
}

-- ============================================================
-- SERVER
-- ============================================================
Constants.MAX_PLAYERS_PER_SERVER = 20
Constants.DATA_SAVE_INTERVAL = 300 -- 5 minutes

return Constants
