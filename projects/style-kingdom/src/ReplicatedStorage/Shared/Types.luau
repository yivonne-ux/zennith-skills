--!strict
-- Style Kingdom — Core Type Definitions
-- All data structures used across server and client

export type ItemCategory = "Top" | "Bottom" | "Dress" | "Shoes" | "Accessory" | "Hair" | "Headwear" | "Bag"

export type ItemStyle = "KFashion" | "JFashion" | "SEA" | "Formal" | "Fusion"

export type ItemRarity = number -- 1=Common, 2=Uncommon, 3=Rare, 4=Epic, 5=Legendary

export type Item = {
	id: string, -- "kfash_hoodie_001"
	name: string, -- "Seoul Oversized Hoodie"
	category: ItemCategory,
	style: ItemStyle,
	rarity: ItemRarity,
	tags: { string }, -- {"street", "oversized", "casual", "korean"}
	assetId: string, -- Roblox asset ID for clothing/accessory
	flavorText: string, -- Cultural context description
	price: number, -- Cost in StyleCoins
	premiumPrice: number?, -- Cost in GlamGems (nil = not buyable with GG)
	tier: number, -- Fusion tier (1-5)
	eventOnly: boolean?, -- Only available during seasonal events
}

export type Outfit = {
	top: string?, -- Item ID
	bottom: string?,
	dress: string?, -- Mutually exclusive with top+bottom
	shoes: string?,
	accessory1: string?,
	accessory2: string?,
	hair: string?,
	headwear: string?,
	bag: string?,
	name: string, -- Player-named outfit
}

export type BoutiqueData = {
	tier: number, -- 1-7
	mannequins: { Outfit }, -- Outfits on display
	decorations: { string }, -- Decoration item IDs placed
	customerCapacity: number, -- Max simultaneous NPCs
	earnings: number, -- Offline earnings accumulator
	lastOnlineTime: number, -- os.time() of last session
}

export type DailyChallenge = {
	id: string, -- "serve_5_kfashion"
	description: string, -- "Serve 5 customers who want K-fashion"
	target: number, -- 5
	progress: number, -- current progress
	difficulty: "Easy" | "Medium" | "Hard",
	rewardSC: number, -- StyleCoins reward
	rewardXP: number, -- XP reward
	completed: boolean,
}

export type PlayerProfile = {
	-- Economy
	styleCoins: number,
	glamGems: number,

	-- Progression
	level: number,
	xp: number,
	prestigeCount: number,

	-- Wardrobe
	ownedItems: { [string]: boolean }, -- Set of item IDs
	savedOutfits: { Outfit }, -- Up to 10 (expandable via GamePass)
	equippedOutfit: Outfit,

	-- Boutique
	boutique: BoutiqueData,

	-- Stats
	customersServed: number,
	contestsWon: number,
	contestsEntered: number,
	totalEarnings: number,
	bestContestScore: number,

	-- Daily
	loginStreak: number,
	lastLoginDate: string, -- "2026-03-25"
	dailyChallenges: { DailyChallenge },
	dailyChallengeDate: string,

	-- Purchases
	ownedGamePasses: { [string]: boolean },

	-- Settings
	musicVolume: number,
	sfxVolume: number,
}

export type ThemeScoring = {
	desiredTags: { [string]: number }, -- tag -> weight (positive)
	bonusTags: { [string]: number }, -- extra points
	penaltyTags: { [string]: number }, -- negative weights
}

export type ContestTheme = {
	id: string, -- "seoul_street"
	name: string, -- "Seoul Street Style"
	description: string, -- "Channel your inner K-fashion icon"
	scoring: ThemeScoring,
	icon: string?, -- Asset ID for theme icon
}

export type NPCPreference = {
	name: string, -- "Ji-Yeon"
	preferredStyle: ItemStyle,
	desiredTags: { [string]: number },
	budget: number, -- How much they pay (base)
	patience: number, -- Seconds before leaving
	tipMultiplier: number, -- Bonus for 5-star service
}

export type ContestState = "IDLE" | "THEME_ANNOUNCED" | "DRESSING" | "RUNWAY" | "VOTING" | "RESULTS"

export type ContestEntry = {
	player: Player,
	outfit: Outfit,
	score: number,
	votes: number,
}

return nil
