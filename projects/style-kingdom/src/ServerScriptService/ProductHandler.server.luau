--!strict
-- Style Kingdom — ProductHandler
-- Processes all GamePass and Developer Product purchases via Roblox marketplace

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)

-- Forward declarations (resolved after init)
local DataManager
local EconomyManager

-- ============================================================
-- GAME PASS PROCESSING
-- ============================================================

local function processGamePassPurchase(player: Player, gamePassId: number)
	-- Find which pass was purchased
	local passName: string? = nil
	for name, passInfo in Constants.GAME_PASSES do
		if passInfo.id == gamePassId then
			passName = name
			break
		end
	end

	if not passName then
		warn(`[ProductHandler] Unknown GamePass ID: {gamePassId}`)
		return
	end

	-- Mark as owned in player data
	DataManager.modifyData(player, function(data)
		data.ownedGamePasses[passName] = true
	end)

	-- Apply immediate effects
	if passName == "VIP" then
		-- VIP daily gems are handled by DailyRewards
		print(`[ProductHandler] {player.Name} purchased VIP Fashion Pass`)
	elseif passName == "DOUBLE_INCOME" then
		print(`[ProductHandler] {player.Name} purchased Double Income`)
	elseif passName == "AUTO_SERVE" then
		print(`[ProductHandler] {player.Name} purchased Auto-Serve`)
	elseif passName == "EXTRA_MANNEQUINS" then
		-- Mannequin slots handled by BoutiqueManager
		print(`[ProductHandler] {player.Name} purchased Extra Mannequins`)
	elseif passName == "OUTFIT_SLOTS" then
		print(`[ProductHandler] {player.Name} purchased Outfit Slots Plus`)
	elseif passName == "VIP_MONTHLY" then
		-- Same benefits as permanent VIP, handled identically
		print(`[ProductHandler] {player.Name} purchased VIP Monthly`)
	elseif passName == "LUCKY_STYLIST" then
		-- Whale pass: 5x tips, exclusive drops, priority NPCs
		print(`[ProductHandler] {player.Name} purchased Lucky Stylist (whale tier)`)
	end

	-- Notify client
	local notifyEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("NotifyPlayer")
	if notifyEvent then
		notifyEvent:FireClient(player, "Purchase successful! " .. Constants.GAME_PASSES[passName].name)
	end
end

-- ============================================================
-- DEVELOPER PRODUCT PROCESSING
-- ============================================================

local function processDevProductPurchase(receiptInfo: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId

	-- Find which product was purchased
	local productName: string? = nil
	for name, productInfo in Constants.DEV_PRODUCTS do
		if productInfo.id == productId then
			productName = name
			break
		end
	end

	if not productName then
		warn(`[ProductHandler] Unknown DevProduct ID: {productId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = DataManager.getData(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Process by product type
	if productName == "GG_100" or productName == "GG_500" or productName == "GG_1200" or productName == "GG_3000" then
		local gemAmount = Constants.DEV_PRODUCTS[productName].glamGems
		EconomyManager.addGlamGems(player, gemAmount)
		print(`[ProductHandler] {player.Name} purchased {gemAmount} GlamGems`)
	elseif
		productName == "SC_500"
		or productName == "SC_2000"
		or productName == "SC_6000"
		or productName == "SC_15000"
	then
		local scAmount = Constants.DEV_PRODUCTS[productName].styleCoins

		-- Daily SC purchase cap (anti-inflation)
		local today = os.date("!*t")
		local dayKey = string.format("%04d-%02d-%02d", today.year, today.month, today.day)
		if not data._scPurchaseToday then
			data._scPurchaseToday = { day = dayKey, amount = 0 }
		end
		if data._scPurchaseToday.day ~= dayKey then
			data._scPurchaseToday = { day = dayKey, amount = 0 }
		end
		if data._scPurchaseToday.amount + scAmount > Constants.SC_PURCHASE_DAILY_CAP then
			local remaining = Constants.SC_PURCHASE_DAILY_CAP - data._scPurchaseToday.amount
			if remaining <= 0 then
				local notifyEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("NotifyPlayer")
				if notifyEvent then
					notifyEvent:FireClient(player, "Daily SC purchase limit reached! Try again tomorrow.")
				end
				-- Still grant the purchase (Robux already spent) but cap the amount
				scAmount = 0
			else
				scAmount = remaining
			end
		end
		data._scPurchaseToday.amount += scAmount

		if scAmount > 0 then
			EconomyManager.addStyleCoins(player, scAmount)
		end
		print(`[ProductHandler] {player.Name} purchased {scAmount} StyleCoins`)
	elseif productName == "LUCKY_BOX" then
		-- Pity counter tracking
		if not data._luckyBoxPity then
			data._luckyBoxPity = 0
		end
		data._luckyBoxPity += 1

		-- Roll for random item based on rarity odds
		local roll = math.random()
		local targetRarity = 1
		local cumulative = 0

		-- Pity system: guaranteed Epic+ after N boxes, Legendary after M
		local forcedRarity: number? = nil
		if data._luckyBoxPity >= Constants.LUCKY_BOX_PITY_LEGENDARY then
			forcedRarity = 5
			data._luckyBoxPity = 0
		elseif data._luckyBoxPity >= Constants.LUCKY_BOX_PITY_EPIC then
			forcedRarity = 4
		end

		-- Lucky Stylist bonus: +10% to rarity 3+
		local hasLuckyStylist = data.ownedGamePasses and data.ownedGamePasses["LUCKY_STYLIST"]
		if hasLuckyStylist then
			-- Shift odds toward higher rarities
			roll = math.max(0, roll - Constants.LUCKY_STYLIST_RARE_DROP_BONUS)
		end

		for rarity = 1, 5 do
			cumulative += Constants.LUCKY_BOX_ODDS[rarity]
			if roll <= cumulative then
				targetRarity = rarity
				break
			end
		end

		-- Apply pity system override
		if forcedRarity and forcedRarity > targetRarity then
			targetRarity = forcedRarity
		end
		-- Reset pity on Epic+ pull
		if targetRarity >= 4 then
			data._luckyBoxPity = 0
		end

		-- Find items of that rarity that the player doesn't own
		local candidates = {}
		for _, item in ItemCatalog.Items do
			if item.rarity == targetRarity and not item.eventOnly and not data.ownedItems[item.id] then
				table.insert(candidates, item)
			end
		end

		-- If player owns all items of that rarity, try next rarity up
		if #candidates == 0 then
			for r = targetRarity + 1, 5 do
				for _, item in ItemCatalog.Items do
					if item.rarity == r and not item.eventOnly and not data.ownedItems[item.id] then
						table.insert(candidates, item)
					end
				end
				if #candidates > 0 then
					break
				end
			end
		end

		-- If player owns everything, give StyleCoins instead
		if #candidates == 0 then
			local refund = 200 * targetRarity
			EconomyManager.addStyleCoins(player, refund)
			local notifyEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("NotifyPlayer")
			if notifyEvent then
				notifyEvent:FireClient(player, `You own all items! Received {refund} StyleCoins instead.`)
			end
		else
			local result = candidates[math.random(#candidates)]
			data.ownedItems[result.id] = true

			local notifyEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("ShowPopup")
			if notifyEvent then
				notifyEvent:FireClient(player, "lucky_box", {
					itemId = result.id,
					itemName = result.name,
					rarity = result.rarity,
				})
			end
		end

		print(`[ProductHandler] {player.Name} opened Lucky Fashion Box`)
	elseif productName == "INSTANT_EXPAND" then
		-- Expand boutique without currency cost
		if data.boutique.tier < Constants.MAX_BOUTIQUE_TIER then
			data.boutique.tier += 1
			data.boutique.customerCapacity = Constants.BOUTIQUE_TIERS[data.boutique.tier].customerCap

			local expandEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("BoutiqueExpanded")
			if expandEvent then
				expandEvent:FireClient(player, data.boutique.tier, data.styleCoins)
			end
		else
			-- Already max tier, refund as GlamGems
			EconomyManager.addGlamGems(player, 50)
			local notifyEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("NotifyPlayer")
			if notifyEvent then
				notifyEvent:FireClient(player, "Already at max tier! Received 50 GlamGems instead.")
			end
		end

		print(`[ProductHandler] {player.Name} used Instant Expansion`)
	end

	-- Notify client of currency update
	local currencyEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("CurrencyUpdated")
	if currencyEvent then
		currencyEvent:FireClient(player, data.styleCoins, data.glamGems)
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

local function init()
	DataManager = require(ServerScriptService:WaitForChild("DataManager"))
	EconomyManager = require(ServerScriptService:WaitForChild("EconomyManager"))

	-- Handle GamePass purchases
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if wasPurchased then
			processGamePassPurchase(player, gamePassId)
		end
	end)

	-- Handle Developer Product purchases
	MarketplaceService.ProcessReceipt = processDevProductPurchase

	-- Check existing GamePasses on player join (in case they bought passes previously)
	Players.PlayerAdded:Connect(function(player)
		task.wait(3) -- Wait for data to load

		for passName, passInfo in Constants.GAME_PASSES do
			if passInfo.id > 0 then
				local success, ownsPass = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passInfo.id)
				end)

				if success and ownsPass then
					DataManager.modifyData(player, function(data)
						data.ownedGamePasses[passName] = true
					end)
				end
			end
		end
	end)

	print("[Style Kingdom] ProductHandler initialized")
end

init()

return nil
