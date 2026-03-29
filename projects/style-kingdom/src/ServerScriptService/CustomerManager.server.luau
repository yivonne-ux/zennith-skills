--!strict
-- Style Kingdom — CustomerManager
-- NPC customer spawning, preferences, and satisfaction scoring
-- NPCs use TweenService waypoints (NOT PathfindingService) for mobile performance

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Constants = require(ReplicatedStorage.Shared.Constants)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local Utils = require(ReplicatedStorage.Shared.Utils)

local DataManager -- resolved after init
local EconomyManager -- resolved after init

local CustomerManager = {}

-- ============================================================
-- NPC TEMPLATES (name, preferred style, tags, budget, patience)
-- ============================================================
local NPC_TEMPLATES = {
	-- K-Fashion customers
	{
		name = "Ji-Yeon",
		preferredStyle = "KFashion",
		desiredTags = { korean = 2, street = 2, casual = 1 },
		budget = 1.0,
		patience = 45,
		tipMultiplier = 1.2,
	},
	{
		name = "Min-Jun",
		preferredStyle = "KFashion",
		desiredTags = { korean = 2, modern = 1, cool = 1 },
		budget = 1.0,
		patience = 40,
		tipMultiplier = 1.0,
	},
	{
		name = "Soo-Ah",
		preferredStyle = "KFashion",
		desiredTags = { korean = 2, kpop = 2, flashy = 1 },
		budget = 1.5,
		patience = 35,
		tipMultiplier = 1.5,
	},
	{
		name = "Hyun-Woo",
		preferredStyle = "KFashion",
		desiredTags = { korean = 2, oversized = 1, street = 1 },
		budget = 0.8,
		patience = 50,
		tipMultiplier = 1.0,
	},

	-- J-Fashion customers
	{
		name = "Sakura",
		preferredStyle = "JFashion",
		desiredTags = { japanese = 2, kawaii = 2, cute = 1 },
		budget = 1.0,
		patience = 45,
		tipMultiplier = 1.2,
	},
	{
		name = "Yuki",
		preferredStyle = "JFashion",
		desiredTags = { japanese = 2, harajuku = 2, bold = 1 },
		budget = 1.2,
		patience = 40,
		tipMultiplier = 1.3,
	},
	{
		name = "Takeshi",
		preferredStyle = "JFashion",
		desiredTags = { japanese = 2, street = 1, anime = 1 },
		budget = 0.9,
		patience = 50,
		tipMultiplier = 1.0,
	},
	{
		name = "Aoi",
		preferredStyle = "JFashion",
		desiredTags = { japanese = 2, traditional = 1, elegant = 1 },
		budget = 1.5,
		patience = 35,
		tipMultiplier = 1.5,
	},

	-- SEA Fashion customers
	{
		name = "Aisyah",
		preferredStyle = "SEA",
		desiredTags = { malaysian = 2, batik = 2, traditional = 1 },
		budget = 1.0,
		patience = 45,
		tipMultiplier = 1.2,
	},
	{
		name = "Dewi",
		preferredStyle = "SEA",
		desiredTags = { indonesian = 2, kebaya = 2, elegant = 1 },
		budget = 1.2,
		patience = 40,
		tipMultiplier = 1.3,
	},
	{
		name = "Rizal",
		preferredStyle = "SEA",
		desiredTags = { malaysian = 1, batik = 1, casual = 1, modern = 1 },
		budget = 0.8,
		patience = 50,
		tipMultiplier = 1.0,
	},
	{
		name = "Mei Lin",
		preferredStyle = "SEA",
		desiredTags = { chinese = 2, cheongsam = 1, elegant = 1 },
		budget = 1.3,
		patience = 40,
		tipMultiplier = 1.4,
	},
	{
		name = "Priya",
		preferredStyle = "SEA",
		desiredTags = { indian = 1, traditional = 2, formal = 1, luxurious = 1 },
		budget = 1.5,
		patience = 35,
		tipMultiplier = 1.5,
	},
	{
		name = "Nurul",
		preferredStyle = "SEA",
		desiredTags = { malaysian = 2, modest = 2, hijab = 1 },
		budget = 1.0,
		patience = 45,
		tipMultiplier = 1.2,
	},

	-- Formal / High-end customers
	{
		name = "Victoria",
		preferredStyle = "Formal",
		desiredTags = { formal = 3, elegant = 2, luxurious = 1 },
		budget = 2.0,
		patience = 30,
		tipMultiplier = 2.0,
	},
	{
		name = "Alexander",
		preferredStyle = "Formal",
		desiredTags = { formal = 2, sharp = 1, classic = 1 },
		budget = 1.5,
		patience = 35,
		tipMultiplier = 1.5,
	},

	-- Fusion / Eclectic customers
	{
		name = "Luna",
		preferredStyle = "Fusion",
		desiredTags = { fusion = 2, modern = 1, trendy = 1 },
		budget = 1.2,
		patience = 40,
		tipMultiplier = 1.3,
	},
	{
		name = "Kai",
		preferredStyle = "Fusion",
		desiredTags = { fusion = 1, street = 1, bold = 1, colorful = 1 },
		budget = 1.0,
		patience = 45,
		tipMultiplier = 1.0,
	},
}

-- Active NPCs per player: { [Player]: { npcModel: Model, template: table, state: string, timer: number } }
local activeNPCs: { [Player]: { any } } = {}

-- ============================================================
-- NPC SPAWNING
-- ============================================================

local function spawnNPC(player: Player)
	local data = DataManager.getData(player)
	if not data then
		return
	end

	-- Check capacity
	local currentNPCs = activeNPCs[player] or {}
	if #currentNPCs >= data.boutique.customerCapacity then
		return
	end

	-- Pick a random template, weighted toward the player's boutique tier
	-- Higher tiers get more varied and high-budget customers
	local tier = data.boutique.tier
	local template = NPC_TEMPLATES[math.random(#NPC_TEMPLATES)]

	-- Higher tier = higher chance of premium customers
	if tier >= 4 and math.random() < 0.3 then
		-- Try to pick a high-budget customer
		local premiumTemplates = {}
		for _, t in NPC_TEMPLATES do
			if t.budget >= 1.5 then
				table.insert(premiumTemplates, t)
			end
		end
		if #premiumTemplates > 0 then
			template = premiumTemplates[math.random(#premiumTemplates)]
		end
	end

	-- Create NPC data (not the 3D model — that's handled by the boutique workspace)
	local npcData = {
		template = template,
		state = "ENTERING",
		spawnTime = os.time(),
		patienceRemaining = template.patience + (tier * 3), -- Higher tier = more patience
	}

	if not activeNPCs[player] then
		activeNPCs[player] = {}
	end
	table.insert(activeNPCs[player], npcData)

	-- Notify client to show NPC
	local spawnEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("CustomerSpawned")
	if spawnEvent then
		spawnEvent:FireClient(player, {
			name = template.name,
			preferredStyle = template.preferredStyle,
			desiredTags = template.desiredTags,
			patience = npcData.patienceRemaining,
			index = #activeNPCs[player], -- NPC index for reference
		})
	end

	-- Start patience countdown
	task.spawn(function()
		task.wait(Constants.NPC_BROWSE_TIME) -- Browse time

		-- Check if NPC was served during browse
		local npcs = activeNPCs[player]
		if not npcs then
			return
		end

		local npc = npcs[#npcs] -- Latest NPC
		if not npc or npc ~= npcData then
			return
		end

		npc.state = "WAITING_FOR_SERVICE"

		-- Wait for patience to expire
		task.wait(npc.patienceRemaining)

		-- If still waiting, NPC leaves unhappy
		if npc.state == "WAITING_FOR_SERVICE" then
			npc.state = "LEAVING"

			local leftEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("CustomerLeft")
			if leftEvent then
				leftEvent:FireClient(player, #npcs, false) -- false = unhappy
			end

			-- Remove NPC from active list
			local idx = table.find(npcs, npcData)
			if idx then
				table.remove(npcs, idx)
			end
		end
	end)
end

-- ============================================================
-- SERVE CUSTOMER (called via RemoteFunction)
-- ============================================================
function CustomerManager.serveCustomer(player: Player, npcIndex: number, outfit: any): (boolean, string, number)
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded", 0
	end

	local npcs = activeNPCs[player]
	if not npcs or not npcs[npcIndex] then
		return false, "No customer at that position", 0
	end

	local npc = npcs[npcIndex]
	if npc.state ~= "WAITING_FOR_SERVICE" then
		return false, "Customer is not ready to be served", 0
	end

	-- Score the outfit against NPC's preferences
	local itemTags: { { string } } = {}
	local slots = { "top", "bottom", "dress", "shoes", "accessory1", "accessory2", "hair", "headwear", "bag" }

	for _, slot in slots do
		local itemId = outfit[slot]
		if itemId and itemId ~= "" then
			if not data.ownedItems[itemId] then
				return false, "You don't own: " .. itemId, 0
			end
			local item = ItemCatalog.ById[itemId]
			if item then
				table.insert(itemTags, item.tags)
			end
		end
	end

	-- Calculate score using NPC's desired tags (same system as contest themes)
	local score = 0
	local tagCounts: { [string]: number } = {}

	for _, tags in itemTags do
		for _, tag in tags do
			tagCounts[tag] = (tagCounts[tag] or 0) + 1
		end
	end

	for tag, weight in npc.template.desiredTags do
		if tagCounts[tag] then
			score += weight * math.min(tagCounts[tag], 3)
		end
	end

	-- Convert score to star rating
	local stars = Utils.getStarRating(score)

	-- Process payment
	local success, payment = EconomyManager.payForCustomerService(player, stars)
	if not success then
		return false, "Payment failed", 0
	end

	-- Apply NPC-specific multipliers (budget + tip for 5-star)
	local budgetMultiplier = npc.template.budget or 1.0
	local tipMultiplier = if stars == 5 then (npc.template.tipMultiplier or 1.0) else 1.0

	-- Lucky Stylist GamePass: 5x tips
	local hasLuckyStylist = data.ownedGamePasses and data.ownedGamePasses["LUCKY_STYLIST"]
	if hasLuckyStylist and stars >= 4 then
		tipMultiplier *= Constants.LUCKY_STYLIST_TIP_MULTIPLIER
	end

	local adjustedPayment = math.floor(payment * budgetMultiplier * tipMultiplier)
	if adjustedPayment > payment then
		local bonus = adjustedPayment - payment
		EconomyManager.addStyleCoins(player, bonus)
		payment = adjustedPayment
	end

	-- Add XP
	DataManager.addXP(player, Constants.XP_CUSTOMER_SERVED)

	-- Track daily challenges
	local DailyChallengeMgr = require(ServerScriptService:WaitForChild("DailyChallengeManager"))
	DailyChallengeMgr.trackProgress(player, "customer_served", 1)
	if stars >= 5 then
		DailyChallengeMgr.trackProgress(player, "five_star_served", 1)
	end
	if npc.template.preferredStyle == "KFashion" then
		DailyChallengeMgr.trackProgress(player, "kfashion_served", 1)
	end
	DailyChallengeMgr.trackProgress(player, "coins_earned", payment)

	-- Mark NPC as served
	npc.state = "SATISFIED"

	-- Notify client
	local servedEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("CustomerServed")
	if servedEvent then
		servedEvent:FireClient(player, npcIndex, stars, payment)
	end

	-- Remove NPC after delay (for animation)
	task.spawn(function()
		task.wait(3)
		local currentNpcs = activeNPCs[player]
		if currentNpcs then
			local idx = table.find(currentNpcs, npc)
			if idx then
				table.remove(currentNpcs, idx)
			end
		end
	end)

	return true, `{stars} stars! Earned {payment} SC`, stars
end

-- ============================================================
-- AUTO-SERVE (for players with Auto-Serve GamePass)
-- ============================================================
local function autoServeCheck(player: Player)
	local data = DataManager.getData(player)
	if not data then
		return
	end
	if not data.ownedGamePasses["AUTO_SERVE"] then
		return
	end

	local npcs = activeNPCs[player]
	if not npcs then
		return
	end

	for i, npc in npcs do
		if npc.state == "WAITING_FOR_SERVICE" then
			-- Auto-serve at 3-star quality (base payment, no outfit scoring)
			local stars = 3
			local success, payment = EconomyManager.payForCustomerService(player, stars)
			if success then
				DataManager.addXP(player, Constants.XP_CUSTOMER_SERVED)
				npc.state = "SATISFIED"

				local servedEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("CustomerServed")
				if servedEvent then
					servedEvent:FireClient(player, i, stars, payment)
				end

				-- Remove after delay
				task.spawn(function()
					task.wait(3)
					local currentNpcs = activeNPCs[player]
					if currentNpcs then
						local idx = table.find(currentNpcs, npc)
						if idx then
							table.remove(currentNpcs, idx)
						end
					end
				end)
			end
		end
	end
end

-- ============================================================
-- SPAWN LOOP
-- ============================================================
local function init()
	DataManager = require(ServerScriptService:WaitForChild("DataManager"))
	EconomyManager = require(ServerScriptService:WaitForChild("EconomyManager"))

	-- Set up ServeCustomer RemoteFunction
	local serveFunc = ReplicatedStorage.Remotes.Functions:FindFirstChild("ServeCustomer")
	if serveFunc then
		(serveFunc :: RemoteFunction).OnServerInvoke = function(player: Player, npcIndex: number, outfit: any)
			return CustomerManager.serveCustomer(player, npcIndex, outfit)
		end
	end

	-- Clean up NPCs when player leaves
	Players.PlayerRemoving:Connect(function(player)
		activeNPCs[player] = nil
	end)

	-- Main spawn loop
	task.spawn(function()
		while true do
			task.wait(1) -- Check every second

			for _, player in Players:GetPlayers() do
				local data = DataManager.getData(player)
				if not data then
					continue
				end

				local tier = data.boutique.tier
				local interval = Constants.NPC_SPAWN_INTERVALS[tier] or 20

				-- Check if it's time to spawn a new NPC
				local npcs = activeNPCs[player]
				local npcCount = if npcs then #npcs else 0

				if npcCount < data.boutique.customerCapacity then
					-- Simple spawn timing: use a counter in the NPC list
					if not activeNPCs[player] then
						activeNPCs[player] = {}
					end

					-- Spawn if enough time has passed since last spawn
					local lastSpawn = 0
					if npcs and #npcs > 0 then
						lastSpawn = npcs[#npcs].spawnTime or 0
					end

					if os.time() - lastSpawn >= interval then
						spawnNPC(player)
					end
				end

				-- Auto-serve check
				autoServeCheck(player)
			end
		end
	end)

	print("[Style Kingdom] CustomerManager initialized")
end

init()

return CustomerManager
