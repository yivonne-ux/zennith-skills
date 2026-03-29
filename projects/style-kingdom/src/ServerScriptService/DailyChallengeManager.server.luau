--!strict
-- Style Kingdom — DailyChallengeManager
-- Generates daily challenges per player, tracks progress, awards rewards

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Utils = require(ReplicatedStorage.Shared.Utils)

local DataManager -- Resolved after init

local DailyChallengeManager = {}

-- ============================================================
-- CHALLENGE TEMPLATES
-- ============================================================
-- Each template defines a challenge type that can be generated with random targets

type ChallengeTemplate = {
	id: string,
	description: string,
	difficulty: "Easy" | "Medium" | "Hard",
	minTarget: number,
	maxTarget: number,
	rewardSC: number,
	rewardXP: number,
	trackingKey: string, -- Which event increments this
}

local EASY_CHALLENGES: { ChallengeTemplate } = {
	{
		id = "serve_customers",
		description = "Serve {target} customers",
		difficulty = "Easy",
		minTarget = 3,
		maxTarget = 5,
		rewardSC = 100,
		rewardXP = Constants.XP_DAILY_CHALLENGE_EASY,
		trackingKey = "customer_served",
	},
	{
		id = "earn_coins",
		description = "Earn {target} StyleCoins",
		difficulty = "Easy",
		minTarget = 100,
		maxTarget = 300,
		rewardSC = 75,
		rewardXP = Constants.XP_DAILY_CHALLENGE_EASY,
		trackingKey = "coins_earned",
	},
	{
		id = "equip_outfits",
		description = "Equip {target} different outfits",
		difficulty = "Easy",
		minTarget = 2,
		maxTarget = 3,
		rewardSC = 80,
		rewardXP = Constants.XP_DAILY_CHALLENGE_EASY,
		trackingKey = "outfits_equipped",
	},
}

local MEDIUM_CHALLENGES: { ChallengeTemplate } = {
	{
		id = "serve_kfashion",
		description = "Serve {target} customers who want K-Fashion",
		difficulty = "Medium",
		minTarget = 3,
		maxTarget = 5,
		rewardSC = 200,
		rewardXP = Constants.XP_DAILY_CHALLENGE_MEDIUM,
		trackingKey = "kfashion_served",
	},
	{
		id = "serve_5star",
		description = "Get {target} five-star ratings",
		difficulty = "Medium",
		minTarget = 2,
		maxTarget = 4,
		rewardSC = 250,
		rewardXP = Constants.XP_DAILY_CHALLENGE_MEDIUM,
		trackingKey = "five_star_served",
	},
	{
		id = "enter_contest",
		description = "Enter {target} fashion contests",
		difficulty = "Medium",
		minTarget = 1,
		maxTarget = 2,
		rewardSC = 175,
		rewardXP = Constants.XP_DAILY_CHALLENGE_MEDIUM,
		trackingKey = "contests_entered",
	},
}

local HARD_CHALLENGES: { ChallengeTemplate } = {
	{
		id = "win_contest",
		description = "Win a fashion contest",
		difficulty = "Hard",
		minTarget = 1,
		maxTarget = 1,
		rewardSC = 500,
		rewardXP = Constants.XP_DAILY_CHALLENGE_HARD,
		trackingKey = "contests_won",
	},
	{
		id = "serve_many",
		description = "Serve {target} customers in one session",
		difficulty = "Hard",
		minTarget = 10,
		maxTarget = 15,
		rewardSC = 400,
		rewardXP = Constants.XP_DAILY_CHALLENGE_HARD,
		trackingKey = "customer_served",
	},
	{
		id = "fuse_items",
		description = "Fuse {target} items",
		difficulty = "Hard",
		minTarget = 1,
		maxTarget = 2,
		rewardSC = 350,
		rewardXP = Constants.XP_DAILY_CHALLENGE_HARD,
		trackingKey = "items_fused",
	},
}

-- ============================================================
-- CHALLENGE GENERATION
-- ============================================================

local function generateChallenge(template: ChallengeTemplate): any
	local target = math.random(template.minTarget, template.maxTarget)
	local description = string.gsub(template.description, "{target}", tostring(target))

	return {
		id = template.id,
		description = description,
		target = target,
		progress = 0,
		difficulty = template.difficulty,
		rewardSC = template.rewardSC,
		rewardXP = template.rewardXP,
		completed = false,
	}
end

function DailyChallengeManager.generateDailyChallenges(): { any }
	-- Pick 1 easy, 1 medium, 1 hard
	local easy = EASY_CHALLENGES[math.random(#EASY_CHALLENGES)]
	local medium = MEDIUM_CHALLENGES[math.random(#MEDIUM_CHALLENGES)]
	local hard = HARD_CHALLENGES[math.random(#HARD_CHALLENGES)]

	return {
		generateChallenge(easy),
		generateChallenge(medium),
		generateChallenge(hard),
	}
end

-- ============================================================
-- PROGRESS TRACKING
-- ============================================================

-- Map tracking keys to challenge template IDs for lookup
local function findMatchingChallenges(data: any, trackingKey: string): { any }
	local matches = {}
	if not data.dailyChallenges then
		return matches
	end

	-- Build a map of challenge IDs to their tracking keys
	local challengeKeyMap: { [string]: string } = {}
	for _, pool in { EASY_CHALLENGES, MEDIUM_CHALLENGES, HARD_CHALLENGES } do
		for _, template in pool do
			challengeKeyMap[template.id] = template.trackingKey
		end
	end

	for _, challenge in data.dailyChallenges do
		if not challenge.completed and challengeKeyMap[challenge.id] == trackingKey then
			table.insert(matches, challenge)
		end
	end

	return matches
end

function DailyChallengeManager.trackProgress(player: Player, trackingKey: string, amount: number?)
	local data = DataManager.getData(player)
	if not data then
		return
	end

	local increment = amount or 1
	local challenges = findMatchingChallenges(data, trackingKey)

	for _, challenge in challenges do
		challenge.progress += increment

		if challenge.progress >= challenge.target and not challenge.completed then
			challenge.completed = true

			-- Award rewards via proper economy system
			local EconomyMgr = require(ServerScriptService:WaitForChild("EconomyManager"))
			EconomyMgr.addStyleCoins(player, challenge.rewardSC)
			DataManager.addXP(player, challenge.rewardXP)

			-- GG bonus for hard challenges
			if challenge.difficulty == "Hard" then
				EconomyMgr.addGlamGems(player, 3)
			elseif challenge.difficulty == "Medium" then
				EconomyMgr.addGlamGems(player, 1)
			end

			-- Notify client
			local currEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("CurrencyUpdated")
			if currEvent then
				currEvent:FireClient(player, data.styleCoins, data.glamGems)
			end

			local notifyEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("NotifyPlayer")
			if notifyEvent then
				local ggText = if challenge.difficulty == "Hard"
					then " +3 GG"
					elseif challenge.difficulty == "Medium" then " +1 GG"
					else ""
				notifyEvent:FireClient(
					player,
					`Challenge complete: {challenge.description}! +{challenge.rewardSC} SC{ggText}`
				)
			end

			-- Check "Complete All 3" bonus
			local allDone = true
			for _, c in data.dailyChallenges do
				if not c.completed then
					allDone = false
					break
				end
			end
			if allDone then
				EconomyMgr.addStyleCoins(player, 200)
				EconomyMgr.addGlamGems(player, 5)
				if notifyEvent then
					notifyEvent:FireClient(player, "🎉 All challenges complete! Bonus: +200 SC +5 GG")
				end
				if currEvent then
					currEvent:FireClient(player, data.styleCoins, data.glamGems)
				end
			end
		end
	end
end

-- ============================================================
-- PLAYER SETUP
-- ============================================================

function DailyChallengeManager.checkAndRefreshChallenges(player: Player)
	local data = DataManager.getData(player)
	if not data then
		return
	end

	local today = Utils.getTodayString()

	-- If challenges are from a different day, generate new ones
	if data.dailyChallengeDate ~= today then
		data.dailyChallenges = DailyChallengeManager.generateDailyChallenges()
		data.dailyChallengeDate = today
	end
end

-- ============================================================
-- INIT
-- ============================================================

local function init()
	DataManager = require(ServerScriptService:WaitForChild("DataManager"))

	-- Check challenges when players join
	Players.PlayerAdded:Connect(function(player: Player)
		-- Wait for data to load
		task.wait(3)
		DailyChallengeManager.checkAndRefreshChallenges(player)
	end)

	-- Check existing players
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			task.wait(3)
			DailyChallengeManager.checkAndRefreshChallenges(player)
		end)
	end
end

init()

return DailyChallengeManager
