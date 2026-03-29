--!strict
-- Style Kingdom — DataManager
-- Handles all player data persistence using ProfileStore
-- This is the ONLY script that directly touches DataStore

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local Utils = require(ReplicatedStorage.Shared.Utils)

-- ProfileStore module (installed from github.com/MadStudioRoblox/ProfileStore)
local ProfileStore = require(ServerScriptService:WaitForChild("ProfileStore"))

-- ============================================================
-- DEFAULT PLAYER DATA
-- ============================================================
local DEFAULT_DATA = {
	-- Economy
	styleCoins = 500, -- Starting currency
	glamGems = 5, -- Small starting premium currency

	-- Progression
	level = 1,
	xp = 0,
	prestigeCount = 0,

	-- Wardrobe (starter items given for free)
	ownedItems = {}, -- Populated with starter items below
	savedOutfits = {},
	equippedOutfit = {
		top = nil,
		bottom = nil,
		dress = nil,
		shoes = nil,
		accessory1 = nil,
		accessory2 = nil,
		hair = nil,
		headwear = nil,
		bag = nil,
		name = "Default",
	},

	-- Boutique
	boutique = {
		tier = 1,
		mannequins = {},
		decorations = {},
		customerCapacity = 1,
		earnings = 0,
		lastOnlineTime = 0,
	},

	-- Stats
	customersServed = 0,
	contestsWon = 0,
	contestsEntered = 0,
	totalEarnings = 0,
	bestContestScore = 0,

	-- Daily
	loginStreak = 0,
	lastLoginDate = "",
	dailyChallenges = {},
	dailyChallengeDate = "",

	-- Purchases
	ownedGamePasses = {},

	-- Settings
	musicVolume = 0.5,
	sfxVolume = 0.8,
}

-- Add starter items to default data
local starterItems = ItemCatalog.getStarterItems()
for _, itemId in starterItems do
	DEFAULT_DATA.ownedItems[itemId] = true
end

-- ============================================================
-- PROFILE STORE SETUP
-- ============================================================
local PlayerProfileStore = ProfileStore.New("PlayerData_v1", DEFAULT_DATA)

local DataManager = {}

-- Active profiles indexed by Player
local Profiles: { [Player]: any } = {}

-- ============================================================
-- PROFILE LOADING
-- ============================================================
function DataManager.onPlayerAdded(player: Player)
	local profile = PlayerProfileStore:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- Failed to load — kick player
		player:Kick("Failed to load your data. Please rejoin.")
		return
	end

	-- Session lock: if another server has the profile, it will be released
	profile:AddUserId(player.UserId)
	profile:Reconcile() -- Fill in missing keys from DEFAULT_DATA

	-- Handle session end (player left or server shutting down)
	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		if player.Parent == Players then
			player:Kick("Your data session ended. Please rejoin.")
		end
	end)

	-- Check if player is still in game
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	-- Store the profile
	Profiles[player] = profile

	-- Calculate offline earnings
	local data = profile.Data
	if data.boutique.lastOnlineTime > 0 then
		local hoursOffline = (os.time() - data.boutique.lastOnlineTime) / 3600
		if hoursOffline > 0.05 then -- At least 3 minutes
			local hasDoubleIncome = data.ownedGamePasses["DOUBLE_INCOME"] == true
			local earnings =
				Utils.calculateOfflineEarnings(hoursOffline, data.boutique.tier, data.prestigeCount, hasDoubleIncome)
			if earnings > 0 then
				data.styleCoins += earnings
				data.boutique.earnings += earnings
				data.totalEarnings += earnings
				-- Fire event to client to show offline earnings popup
				local offlineEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("OfflineEarnings")
				if offlineEvent then
					offlineEvent:FireClient(player, earnings, hoursOffline)
				end
			end
		end
	end

	-- Update last online time
	data.boutique.lastOnlineTime = os.time()

	-- Handle daily login streak
	local today = Utils.getTodayString()
	if data.lastLoginDate ~= today then
		-- Check if streak continues or resets
		-- Simple check: if last login was yesterday, continue streak
		local yesterday = os.date("!*t", os.time() - 86400)
		local yesterdayStr = string.format("%04d-%02d-%02d", yesterday.year, yesterday.month, yesterday.day)

		if data.lastLoginDate == yesterdayStr then
			data.loginStreak = math.min(data.loginStreak + 1, Constants.MAX_LOGIN_STREAK)
		else
			data.loginStreak = 1 -- Reset streak
		end

		data.lastLoginDate = today

		-- Fire daily reward event
		local rewardDay = data.loginStreak
		local reward = Constants.LOGIN_STREAK_REWARDS[rewardDay]
		if reward then
			data.styleCoins += reward.sc
			data.glamGems += reward.gg
			local dailyEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("DailyReward")
			if dailyEvent then
				dailyEvent:FireClient(player, rewardDay, reward)
			end
		end
	end

	-- Notify other systems that player data is ready
	local dataReady = ReplicatedStorage.Remotes.Events:FindFirstChild("PlayerDataReady")
	if dataReady then
		dataReady:FireClient(player)
	end
end

function DataManager.onPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile then
		-- Update last online time before saving
		profile.Data.boutique.lastOnlineTime = os.time()
		profile:EndSession()
	end
end

-- ============================================================
-- DATA ACCESS (other server scripts call these)
-- ============================================================

function DataManager.getProfile(player: Player): any?
	return Profiles[player]
end

function DataManager.getData(player: Player): any?
	local profile = Profiles[player]
	if profile then
		return profile.Data
	end
	return nil
end

-- Safe data modification with validation
function DataManager.modifyData(player: Player, callback: (data: any) -> ()): boolean
	local profile = Profiles[player]
	if not profile then
		return false
	end
	callback(profile.Data)
	return true
end

-- Check if player owns an item
function DataManager.ownsItem(player: Player, itemId: string): boolean
	local data = DataManager.getData(player)
	if not data then
		return false
	end
	return data.ownedItems[itemId] == true
end

-- Check if player owns a game pass
function DataManager.hasGamePass(player: Player, passName: string): boolean
	local data = DataManager.getData(player)
	if not data then
		return false
	end
	return data.ownedGamePasses[passName] == true
end

-- Add XP and handle level ups
function DataManager.addXP(player: Player, amount: number)
	local data = DataManager.getData(player)
	if not data then
		return
	end
	if data.level >= Constants.MAX_LEVEL then
		return
	end

	data.xp += amount

	-- Check for level up(s)
	local leveled = false
	while data.level < Constants.MAX_LEVEL do
		local required = Utils.xpForLevel(data.level)
		if data.xp >= required then
			data.xp -= required
			data.level += 1
			leveled = true
		else
			break
		end
	end

	if leveled then
		local levelUpEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("LevelUp")
		if levelUpEvent then
			levelUpEvent:FireClient(player, data.level)
		end
	end
end

-- ============================================================
-- CONNECTIONS
-- ============================================================
Players.PlayerAdded:Connect(DataManager.onPlayerAdded)
Players.PlayerRemoving:Connect(DataManager.onPlayerRemoving)

-- Handle server shutdown
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		DataManager.onPlayerRemoving(player)
	end
end)

-- Handle players already in game (studio testing)
for _, player in Players:GetPlayers() do
	task.spawn(DataManager.onPlayerAdded, player)
end

return DataManager
