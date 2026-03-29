--!strict
-- Style Kingdom — EconomyManager
-- Handles all currency transactions with server-side validation
-- NO currency changes happen on the client — all go through here

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local Utils = require(ReplicatedStorage.Shared.Utils)

-- DataManager is loaded as a module from ServerScriptService
local DataManager -- Forward declaration, resolved after init

local EconomyManager = {}

-- ============================================================
-- CURRENCY OPERATIONS
-- ============================================================

function EconomyManager.addStyleCoins(player: Player, amount: number): boolean
	if amount <= 0 then
		return false
	end
	return DataManager.modifyData(player, function(data)
		data.styleCoins += amount
		data.totalEarnings += amount
	end)
end

function EconomyManager.addGlamGems(player: Player, amount: number): boolean
	if amount <= 0 then
		return false
	end
	return DataManager.modifyData(player, function(data)
		data.glamGems += amount
	end)
end

function EconomyManager.spendStyleCoins(player: Player, amount: number): boolean
	if amount <= 0 then
		return false
	end
	local data = DataManager.getData(player)
	if not data then
		return false
	end
	if data.styleCoins < amount then
		return false
	end

	data.styleCoins -= amount
	return true
end

function EconomyManager.spendGlamGems(player: Player, amount: number): boolean
	if amount <= 0 then
		return false
	end
	local data = DataManager.getData(player)
	if not data then
		return false
	end
	if data.glamGems < amount then
		return false
	end

	data.glamGems -= amount
	return true
end

-- ============================================================
-- PURCHASE ITEM
-- ============================================================

function EconomyManager.purchaseItem(player: Player, itemId: string, useGems: boolean): (boolean, string)
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	-- Check if item exists
	local item = ItemCatalog.ById[itemId]
	if not item then
		return false, "Item not found"
	end

	-- Check if already owned
	if data.ownedItems[itemId] then
		return false, "Already owned"
	end

	-- Check if event-only and not currently available
	if item.eventOnly then
		return false, "This item is only available during events"
	end

	-- Determine price and currency
	if useGems then
		if not item.premiumPrice then
			return false, "Not available for GlamGems"
		end
		if not EconomyManager.spendGlamGems(player, item.premiumPrice) then
			return false, "Not enough GlamGems"
		end
	else
		if not EconomyManager.spendStyleCoins(player, item.price) then
			return false, "Not enough StyleCoins"
		end
	end

	-- Grant item
	data.ownedItems[itemId] = true

	-- Notify client
	local purchaseEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("ItemPurchased")
	if purchaseEvent then
		purchaseEvent:FireClient(player, itemId, data.styleCoins, data.glamGems)
	end

	return true, "Success"
end

-- ============================================================
-- CUSTOMER PAYMENT
-- ============================================================

function EconomyManager.payForCustomerService(player: Player, stars: number): (boolean, number)
	local data = DataManager.getData(player)
	if not data then
		return false, 0
	end

	local hasVIP = data.ownedGamePasses["VIP"] == true
	local payment = Utils.calculatePayment(stars, data.boutique.tier, data.prestigeCount)

	-- VIP doubles customer earnings
	if hasVIP then
		payment *= 2
	end

	data.styleCoins += payment
	data.totalEarnings += payment
	data.customersServed += 1

	return true, payment
end

-- ============================================================
-- BOUTIQUE EXPANSION
-- ============================================================

function EconomyManager.expandBoutique(player: Player): (boolean, string)
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	local currentTier = data.boutique.tier
	if currentTier >= Constants.MAX_BOUTIQUE_TIER then
		return false, "Already at max tier"
	end

	local nextTier = currentTier + 1
	local cost = Constants.BOUTIQUE_TIERS[nextTier].cost

	if not EconomyManager.spendStyleCoins(player, cost) then
		return false, "Not enough StyleCoins"
	end

	-- Upgrade boutique
	data.boutique.tier = nextTier
	data.boutique.customerCapacity = Constants.BOUTIQUE_TIERS[nextTier].customerCap
	-- Mannequin count updated by BoutiqueManager (handles model changes)

	-- Notify client
	local expandEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("BoutiqueExpanded")
	if expandEvent then
		expandEvent:FireClient(player, nextTier, data.styleCoins)
	end

	return true, "Expanded to " .. Constants.BOUTIQUE_TIERS[nextTier].name
end

-- ============================================================
-- ITEM FUSION
-- ============================================================

function EconomyManager.fuseItems(player: Player, itemIds: { string }): (boolean, string, string?)
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded", nil
	end

	-- Validate: need exactly 3 items
	if #itemIds ~= Constants.FUSION_INPUT_COUNT then
		return false, "Need exactly 3 items to fuse", nil
	end

	-- Validate: all items exist and are owned
	local fusionTier: number? = nil
	for _, itemId in itemIds do
		local item = ItemCatalog.ById[itemId]
		if not item then
			return false, "Item not found: " .. itemId, nil
		end
		if not data.ownedItems[itemId] then
			return false, "You don't own: " .. itemId, nil
		end

		-- All items must be the same tier
		if fusionTier == nil then
			fusionTier = item.tier
		elseif item.tier ~= fusionTier then
			return false, "All items must be the same tier", nil
		end
	end

	if not fusionTier or fusionTier >= 5 then
		return false, "Cannot fuse tier 5 items", nil
	end

	-- Find a random item of the next tier
	local nextTier = fusionTier + 1
	local candidates = {}
	for _, item in ItemCatalog.Items do
		if item.tier == nextTier and not item.eventOnly then
			table.insert(candidates, item)
		end
	end

	if #candidates == 0 then
		return false, "No items available at next tier", nil
	end

	-- Remove input items
	for _, itemId in itemIds do
		data.ownedItems[itemId] = nil
	end

	-- Grant random result
	local result = candidates[math.random(#candidates)]
	data.ownedItems[result.id] = true

	return true, "Success", result.id
end

-- ============================================================
-- PRESTIGE / REBIRTH
-- ============================================================

function EconomyManager.prestige(player: Player): (boolean, string)
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	-- Requirements: Level 100 and max boutique tier
	if data.level < Constants.MAX_LEVEL then
		return false, "Must be level " .. Constants.MAX_LEVEL
	end
	if data.boutique.tier < Constants.MAX_BOUTIQUE_TIER then
		return false, "Must have a Fashion Empire boutique"
	end
	if data.prestigeCount >= Constants.MAX_PRESTIGE then
		return false, "Already at max prestige"
	end

	-- Reset progression but keep items
	data.prestigeCount += 1
	data.level = 1
	data.xp = 0
	data.styleCoins = 1000 -- Reset with enough to reach Tier 2
	data.boutique.tier = 1
	data.boutique.customerCapacity = 1
	data.boutique.mannequins = {}
	data.boutique.decorations = {}
	-- Items, glamGems, stats, and game passes are KEPT

	local prestigeEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("Prestige")
	if prestigeEvent then
		prestigeEvent:FireClient(player, data.prestigeCount)
	end

	return true, "Prestige " .. data.prestigeCount .. " achieved!"
end

-- ============================================================
-- REMOTE FUNCTION HANDLERS
-- ============================================================

-- ============================================================
-- RATE LIMITING
-- ============================================================
local rateLimits: { [Player]: { [string]: number } } = {}

local function checkRateLimit(player: Player, action: string, cooldown: number): boolean
	if not rateLimits[player] then
		rateLimits[player] = {}
	end
	local now = os.clock()
	local last = rateLimits[player][action] or 0
	if now - last < cooldown then
		return false
	end
	rateLimits[player][action] = now
	return true
end

-- Clean up on leave
game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
	rateLimits[player] = nil
end)

local function init()
	-- Resolve DataManager reference
	DataManager = require(script.Parent:WaitForChild("DataManager"))

	-- Set up RemoteFunctions with rate limiting + input validation
	local functions = ReplicatedStorage.Remotes.Functions

	local purchaseFunc = functions:FindFirstChild("PurchaseItem")
	if purchaseFunc then
		(purchaseFunc :: RemoteFunction).OnServerInvoke = function(player: Player, itemId: any, useGems: any)
			if type(itemId) ~= "string" then
				return false, "Invalid item"
			end
			if type(useGems) ~= "boolean" and type(useGems) ~= "string" then
				useGems = false
			end
			if not checkRateLimit(player, "purchase", 0.5) then
				return false, "Too fast"
			end
			return EconomyManager.purchaseItem(player, itemId, useGems == true or useGems == "GG")
		end
	end

	local expandFunc = functions:FindFirstChild("ExpandBoutique")
	if expandFunc then
		(expandFunc :: RemoteFunction).OnServerInvoke = function(player: Player)
			if not checkRateLimit(player, "expand", 2) then
				return false, "Too fast"
			end
			return EconomyManager.expandBoutique(player)
		end
	end

	local fuseFunc = functions:FindFirstChild("FuseItems")
	if fuseFunc then
		(fuseFunc :: RemoteFunction).OnServerInvoke = function(player: Player, itemIds: any)
			if type(itemIds) ~= "table" then
				return false, "Invalid items", nil
			end
			for _, v in itemIds do
				if type(v) ~= "string" then
					return false, "Invalid item ID", nil
				end
			end
			if not checkRateLimit(player, "fuse", 1) then
				return false, "Too fast", nil
			end
			return EconomyManager.fuseItems(player, itemIds)
		end
	end

	local prestigeFunc = functions:FindFirstChild("Prestige")
	if prestigeFunc then
		(prestigeFunc :: RemoteFunction).OnServerInvoke = function(player: Player)
			if not checkRateLimit(player, "prestige", 5) then
				return false, "Too fast"
			end
			return EconomyManager.prestige(player)
		end
	end
end

init()

return EconomyManager
