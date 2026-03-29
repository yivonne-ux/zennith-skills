--!strict
-- Style Kingdom — GameManager
-- Master orchestrator: initializes all systems, creates remotes, manages game state

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================
-- STEP 1: Create folder structure in ReplicatedStorage
-- ============================================================
local function ensureFolder(parent: Instance, name: string): Folder
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder :: Folder
end

-- Create Shared folder structure
local shared = ensureFolder(ReplicatedStorage, "Shared")
local remotes = ensureFolder(ReplicatedStorage, "Remotes")
local events = ensureFolder(remotes, "Events")
local functions = ensureFolder(remotes, "Functions")
ensureFolder(ReplicatedStorage, "Assets")

-- ============================================================
-- STEP 2: Create all RemoteEvents
-- ============================================================
local remoteEvents = {
	-- Player data
	"PlayerDataReady",
	"OfflineEarnings",
	"DailyReward",
	"LevelUp",
	"Prestige",

	-- Economy
	"ItemPurchased",
	"CurrencyUpdated",

	-- Boutique
	"BoutiqueExpanded",

	-- Customers
	"CustomerSpawned",
	"CustomerServed",
	"CustomerLeft",

	-- Contest
	"ContestStateChanged",
	"ContestThemeAnnounced",
	"ContestRunwayStart",
	"ContestVotingStart",
	"ContestResults",
	"ContestEntrySubmitted",

	-- UI
	"NotifyPlayer",
	"ShowPopup",
}

for _, name in remoteEvents do
	if not events:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = events
	end
end

-- ============================================================
-- STEP 3: Create all RemoteFunctions
-- ============================================================
local remoteFunctions = {
	-- Data
	"GetPlayerData",

	-- Economy
	"PurchaseItem",
	"ExpandBoutique",
	"FuseItems",
	"Prestige",

	-- Wardrobe
	"EquipOutfit",
	"SaveOutfit",
	"DeleteOutfit",

	-- Contest
	"SubmitContestEntry",
	"CastVote",

	-- Customer
	"ServeCustomer",
}

for _, name in remoteFunctions do
	if not functions:FindFirstChild(name) then
		local func = Instance.new("RemoteFunction")
		func.Name = name
		func.Parent = functions
	end
end

-- ============================================================
-- STEP 4: Set up GetPlayerData handler
-- ============================================================
local function onGetPlayerData(player: Player)
	-- Wait for DataManager to be available
	local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
	local data = DataManager.getData(player)
	if data then
		return {
			styleCoins = data.styleCoins,
			glamGems = data.glamGems,
			level = data.level,
			xp = data.xp,
			prestigeCount = data.prestigeCount,
			ownedItems = data.ownedItems,
			savedOutfits = data.savedOutfits,
			equippedOutfit = data.equippedOutfit,
			boutique = {
				tier = data.boutique.tier,
				customerCapacity = data.boutique.customerCapacity,
			},
			customersServed = data.customersServed,
			contestsWon = data.contestsWon,
			loginStreak = data.loginStreak,
			ownedGamePasses = data.ownedGamePasses,
		}
	end
	return nil
end

local getDataFunc = functions:FindFirstChild("GetPlayerData")
if getDataFunc then
	(getDataFunc :: RemoteFunction).OnServerInvoke = onGetPlayerData
end

-- ============================================================
-- STEP 5: Set up EquipOutfit handler
-- ============================================================
local function onEquipOutfit(player: Player, outfit: any)
	local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
	local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	-- Validate all items in outfit are owned
	local slots = { "top", "bottom", "dress", "shoes", "accessory1", "accessory2", "hair", "headwear", "bag" }
	for _, slot in slots do
		local itemId = outfit[slot]
		if itemId and itemId ~= "" then
			if not data.ownedItems[itemId] then
				return false, "You don't own: " .. itemId
			end
			-- Verify item exists in catalog
			if not ItemCatalog.ById[itemId] then
				return false, "Invalid item: " .. itemId
			end
		end
	end

	-- Validate mutual exclusivity: dress vs top+bottom
	if outfit.dress and outfit.dress ~= "" then
		if (outfit.top and outfit.top ~= "") or (outfit.bottom and outfit.bottom ~= "") then
			return false, "Cannot wear a dress with separate top/bottom"
		end
	end

	-- Apply outfit
	data.equippedOutfit = outfit

	-- Apply to character's appearance
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			-- Apply via HumanoidDescription
			local desc = humanoid:GetAppliedDescription()
			-- Clear existing clothing
			desc.Shirt = 0
			desc.Pants = 0
			desc.GraphicTShirt = 0

			-- Apply each item's asset
			for _, slot in slots do
				local itemId = outfit[slot]
				if itemId and itemId ~= "" then
					local item = ItemCatalog.ById[itemId]
					if item and item.assetId ~= "" then
						-- Map category to HumanoidDescription property
						if item.category == "Top" or item.category == "Dress" then
							desc.Shirt = tonumber(item.assetId) or 0
						elseif item.category == "Bottom" then
							desc.Pants = tonumber(item.assetId) or 0
						end
						-- Accessories handled via SetAccessories for 3D items
					end
				end
			end

			humanoid:ApplyDescription(desc)
		end
	end

	return true, "Outfit equipped"
end

local equipFunc = functions:FindFirstChild("EquipOutfit")
if equipFunc then
	(equipFunc :: RemoteFunction).OnServerInvoke = onEquipOutfit
end

-- ============================================================
-- STEP 6: Set up SaveOutfit handler
-- ============================================================
local function onSaveOutfit(player: Player, outfit: any, slotIndex: number)
	local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
	local Constants = require(ReplicatedStorage.Shared.Constants)
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	local maxSlots = Constants.DEFAULT_OUTFIT_SLOTS
	if data.ownedGamePasses["OUTFIT_SLOTS"] then
		maxSlots += Constants.EXTRA_OUTFIT_SLOTS_GAMEPASS
	end

	if slotIndex < 1 or slotIndex > maxSlots then
		return false, "Invalid slot"
	end

	-- Ensure savedOutfits array is big enough
	while #data.savedOutfits < slotIndex do
		table.insert(data.savedOutfits, {
			top = nil,
			bottom = nil,
			dress = nil,
			shoes = nil,
			accessory1 = nil,
			accessory2 = nil,
			hair = nil,
			headwear = nil,
			bag = nil,
			name = "Empty",
		})
	end

	data.savedOutfits[slotIndex] = outfit
	return true, "Outfit saved"
end

local saveFunc = functions:FindFirstChild("SaveOutfit")
if saveFunc then
	(saveFunc :: RemoteFunction).OnServerInvoke = onSaveOutfit
end

-- ============================================================
-- STEP 7: Game state
-- ============================================================
print("[Style Kingdom] GameManager initialized")
print("[Style Kingdom] Created", #remoteEvents, "RemoteEvents")
print("[Style Kingdom] Created", #remoteFunctions, "RemoteFunctions")

return nil
