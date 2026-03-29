--!strict
-- Style Kingdom — ClientController
-- Main client orchestrator: initializes UI, routes server events to screens

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local ItemCatalog = require(Shared.ItemCatalog)

-- UI Modules
local UI = Shared:WaitForChild("UI")
local BoutiqueScreen = require(UI.BoutiqueScreen)
local ContestScreen = require(UI.ContestScreen)
local HUD = require(UI:WaitForChild("HUD"))
local Notifications = require(UI.Notifications)
local ProfileScreen = require(UI.ProfileScreen)
local ShopScreen = require(UI.ShopScreen)
local SoundManager = require(Shared.SoundManager)
local TutorialScreen = require(UI.TutorialScreen)
local WardrobeScreen = require(UI.WardrobeScreen)

local events = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Events")
local functions = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Functions")

-- ============================================================
-- LOCAL STATE
-- ============================================================
local playerData: any = nil

-- ============================================================
-- SCREEN MANAGEMENT
-- ============================================================
local screens = {
	boutique = BoutiqueScreen,
	wardrobe = WardrobeScreen,
	shop = ShopScreen,
	contest = ContestScreen,
	profile = ProfileScreen,
}

local function switchScreen(screenId: string)
	for id, screen in screens do
		if id == screenId then
			screen.show()
		else
			screen.hide()
		end
	end
end

-- ============================================================
-- INITIALIZE ALL UI
-- ============================================================
SoundManager.init()
-- Create UIError BindableEvent for cross-module error reporting
local uiError = Instance.new("BindableEvent")
uiError.Name = "UIError"
uiError.Parent = ReplicatedStorage

HUD.init()
ShopScreen.init()
WardrobeScreen.init()
ContestScreen.init()
BoutiqueScreen.init()
ProfileScreen.init()
TutorialScreen.init()
Notifications.init()

-- Wire UI error reporting → toasts
uiError.Event:Connect(function(msg: string)
	Notifications.error(msg)
end)

-- Wire screen switching from HUD nav bar
HUD.onScreenChange(function(screenId: string)
	if screens[screenId] then
		switchScreen(screenId)
	end
end)

-- Start on boutique screen
switchScreen("boutique")

-- ============================================================
-- DATA LOADING
-- ============================================================
local function loadPlayerData()
	local getDataFunc = functions:FindFirstChild("GetPlayerData") :: RemoteFunction
	if getDataFunc then
		playerData = getDataFunc:InvokeServer()
		if playerData then
			-- Push data to all screens
			HUD.updateCurrency(playerData.styleCoins, playerData.glamGems)
			HUD.updateLevel(playerData.level, playerData.xp)
			ShopScreen.updatePlayerData(playerData)
			WardrobeScreen.updatePlayerData(playerData)
			ContestScreen.updatePlayerData(playerData)
			BoutiqueScreen.updatePlayerData(playerData)
			ProfileScreen.updatePlayerData(playerData)
		end
	end
end

-- Wait for data ready signal, then load
events:WaitForChild("PlayerDataReady").OnClientEvent:Connect(function()
	loadPlayerData()

	-- Show tutorial for brand new players (level 1, no customers served)
	if playerData and playerData.level == 1 and (playerData.customersServed or 0) == 0 then
		TutorialScreen.start(function()
			-- After tutorial, switch to wardrobe to equip first outfit
			switchScreen("wardrobe")
			HUD.setActiveTab("wardrobe")
		end)
	end
end)

-- ============================================================
-- ECONOMY EVENTS
-- ============================================================

events:WaitForChild("CurrencyUpdated").OnClientEvent:Connect(function(sc: number, gg: number)
	if playerData then
		playerData.styleCoins = sc
		playerData.glamGems = gg
	end
	HUD.updateCurrency(sc, gg)
end)

events:WaitForChild("ItemPurchased").OnClientEvent:Connect(function(itemId: string, sc: number, gg: number)
	if playerData then
		playerData.ownedItems[itemId] = true
		playerData.styleCoins = sc
		playerData.glamGems = gg
	end
	HUD.updateCurrency(sc, gg)
	ShopScreen.updatePlayerData(playerData)
	WardrobeScreen.updatePlayerData(playerData)

	local item = ItemCatalog.ById[itemId]
	if item then
		Notifications.success(`Purchased: {item.name}!`)
		SoundManager.playPurchase()
	end
end)

-- ============================================================
-- PROGRESSION EVENTS
-- ============================================================

events:WaitForChild("LevelUp").OnClientEvent:Connect(function(newLevel: number)
	if playerData then
		playerData.level = newLevel
	end
	HUD.updateLevel(newLevel, 0)
	Notifications.showLevelUp(newLevel)
	SoundManager.playLevelUp()
end)

events:WaitForChild("Prestige").OnClientEvent:Connect(function(prestigeCount: number)
	Notifications.showPrestige(prestigeCount)
	loadPlayerData() -- Full refresh
end)

-- ============================================================
-- BOUTIQUE EVENTS
-- ============================================================

events:WaitForChild("BoutiqueExpanded").OnClientEvent:Connect(function(newTier: number, sc: number)
	if playerData then
		playerData.boutique.tier = newTier
		playerData.styleCoins = sc
	end
	HUD.updateCurrency(sc, playerData and playerData.glamGems or 0)
	BoutiqueScreen.updatePlayerData(playerData)

	local tierName = Constants.BOUTIQUE_TIERS[newTier].name
	Notifications.success(`Boutique expanded to {tierName}!`)
end)

-- ============================================================
-- CUSTOMER EVENTS
-- ============================================================

events:WaitForChild("CustomerSpawned").OnClientEvent:Connect(function(npcInfo: any)
	BoutiqueScreen.addCustomer(npcInfo)
	Notifications.info(`{npcInfo.name} arrived! Wants {npcInfo.preferredStyle} style`)
end)

events:WaitForChild("CustomerServed").OnClientEvent:Connect(function(_npcIndex: number, stars: number, payment: number)
	if playerData then
		playerData.customersServed = (playerData.customersServed or 0) + 1
	end
	Notifications.showCustomerServed(stars, payment)
	SoundManager.playStarRating(stars)
end)

events:WaitForChild("CustomerLeft").OnClientEvent:Connect(function(npcIndex: number, happy: boolean)
	BoutiqueScreen.removeCustomer(npcIndex)
	if not happy then
		Notifications.warning("Customer left unhappy!")
	end
end)

-- ============================================================
-- CONTEST EVENTS
-- ============================================================

events:WaitForChild("ContestStateChanged").OnClientEvent:Connect(function(newState: string)
	ContestScreen.setState(newState)

	if newState == "IDLE" then
		HUD.hideContestTimer()
		SoundManager.playBGM("BGM_BOUTIQUE")
	end
end)

events
	:WaitForChild("ContestThemeAnnounced").OnClientEvent
	:Connect(function(themeId: string, themeName: string, themeDesc: string)
		ContestScreen.setTheme(themeId, themeName, themeDesc)
		HUD.showContestTimer(themeName, Constants.CONTEST_DRESSING_SECONDS)
		Notifications.toast(`🏆 Contest: {themeName}!`, "✨", 5)
		SoundManager.playContestAnnounce()
		SoundManager.playBGM("BGM_CONTEST")
	end)

events:WaitForChild("ContestEntrySubmitted").OnClientEvent:Connect(function(themeScore: number)
	Notifications.success(`Entry submitted! Theme score: {string.format("%.1f", themeScore)}`)
end)

events
	:WaitForChild("ContestRunwayStart").OnClientEvent
	:Connect(function(walkerUserId: number, index: number, total: number)
		local walker = Players:GetPlayerByUserId(walkerUserId)
		local walkerName = if walker then walker.DisplayName else "Unknown"
		ContestScreen.setRunwayWalker(walkerName, index, total)
	end)

events:WaitForChild("ContestVotingStart").OnClientEvent:Connect(function(contestantIds: { number })
	ContestScreen.setupVoting(contestantIds)
end)

events:WaitForChild("ContestResults").OnClientEvent:Connect(function(results: { any })
	ContestScreen.showResults(results)
end)

-- ============================================================
-- DAILY / MISC EVENTS
-- ============================================================

events:WaitForChild("OfflineEarnings").OnClientEvent:Connect(function(earnings: number, hours: number)
	Notifications.showOfflineEarnings(earnings, hours)
end)

events:WaitForChild("DailyReward").OnClientEvent:Connect(function(day: number, reward: any)
	Notifications.showDailyReward(day, reward)
end)

events:WaitForChild("NotifyPlayer").OnClientEvent:Connect(function(message: string)
	Notifications.info(message)
end)

events:WaitForChild("ShowPopup").OnClientEvent:Connect(function(popupType: string, data: any)
	if popupType == "lucky_box" then
		Notifications.showLuckyBox(data)
	end
end)

-- ============================================================
-- DONE
-- ============================================================
-- Start background music
SoundManager.playBGM("BGM_BOUTIQUE")

print("[Style Kingdom] ClientController initialized — all UI screens loaded")
