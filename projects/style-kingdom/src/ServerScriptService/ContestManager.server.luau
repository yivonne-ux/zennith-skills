--!strict
-- Style Kingdom — ContestManager
-- Runway contest lifecycle: IDLE → THEME_ANNOUNCED → DRESSING → RUNWAY → VOTING → RESULTS → IDLE
-- Runs on a 15-minute cycle

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local ThemeCatalog = require(ReplicatedStorage.Shared.ThemeCatalog)
local Utils = require(ReplicatedStorage.Shared.Utils)

local DataManager -- resolved after init
local EconomyManager -- resolved after init

local ContestManager = {}

-- ============================================================
-- STATE
-- ============================================================
local currentState: string = "IDLE"
local currentTheme: any = nil
local recentThemes: { string } = {} -- last 5 themes to avoid repeats
local MAX_RECENT = 5

-- Contest entries: { [Player]: { outfit, score } }
local entries: { [Player]: { outfit: any, score: number } } = {}

-- Votes: { [Player(voter)]: { Player(target) } }
local votes: { [Player]: { Player } } = {}

-- Runway walk order
local walkOrder: { Player } = {}

-- ============================================================
-- STATE MACHINE
-- ============================================================

local function setState(newState: string)
	currentState = newState
	local stateEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("ContestStateChanged")
	if stateEvent then
		stateEvent:FireAllClients(newState)
	end
end

-- Forward declarations for phase functions
local startDressingPhase: () -> ()
local startRunwayPhase: () -> ()
local startVotingPhase: () -> ()
local calculateResults: () -> ()

-- ============================================================
-- PHASE: THEME ANNOUNCED
-- ============================================================
local function startThemePhase()
	setState("THEME_ANNOUNCED")

	-- Pick a random theme (avoiding recent ones)
	currentTheme = ThemeCatalog.getRandomTheme(recentThemes)
	table.insert(recentThemes, currentTheme.id)
	if #recentThemes > MAX_RECENT then
		table.remove(recentThemes, 1)
	end

	-- Clear previous contest data
	entries = {}
	votes = {}
	walkOrder = {}

	-- Notify all players
	local themeEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("ContestThemeAnnounced")
	if themeEvent then
		themeEvent:FireAllClients(currentTheme.id, currentTheme.name, currentTheme.description)
	end

	print(`[Contest] Theme announced: {currentTheme.name}`)

	-- Transition to dressing after a brief delay
	task.wait(3)
	startDressingPhase()
end

-- ============================================================
-- PHASE: DRESSING
-- ============================================================
startDressingPhase = function()
	setState("DRESSING")
	print(`[Contest] Dressing phase started ({Constants.CONTEST_DRESSING_SECONDS}s)`)

	-- Wait for dressing time
	task.wait(Constants.CONTEST_DRESSING_SECONDS)

	-- Check if anyone entered
	local entryCount = 0
	for _ in entries do
		entryCount += 1
	end

	if entryCount < 2 then
		-- Not enough entries — skip to idle
		print("[Contest] Not enough entries, skipping contest")
		local notifyEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("NotifyPlayer")
		if notifyEvent then
			for _, player in Players:GetPlayers() do
				notifyEvent:FireClient(player, "Contest cancelled — not enough participants!")
			end
		end
		setState("IDLE")
		return
	end

	startRunwayPhase()
end

-- ============================================================
-- PHASE: RUNWAY
-- ============================================================
startRunwayPhase = function()
	setState("RUNWAY")

	-- Build walk order (randomized)
	walkOrder = {}
	for player in entries do
		if player.Parent == Players then -- Still in game
			table.insert(walkOrder, player)
		end
	end
	Utils.shuffle(walkOrder)

	print(`[Contest] Runway phase — {#walkOrder} contestants`)

	-- Each player walks in sequence
	local runwayEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("ContestRunwayStart")

	for i, player in walkOrder do
		if runwayEvent then
			-- Tell all clients who is walking now
			runwayEvent:FireAllClients(player.UserId, i, #walkOrder)
		end
		task.wait(Constants.CONTEST_RUNWAY_SECONDS_PER_PLAYER)
	end

	startVotingPhase()
end

-- ============================================================
-- PHASE: VOTING
-- ============================================================
startVotingPhase = function()
	setState("VOTING")

	local votingEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("ContestVotingStart")
	if votingEvent then
		-- Send list of contestants for voting UI
		local contestantIds = {}
		for _, player in walkOrder do
			table.insert(contestantIds, player.UserId)
		end
		votingEvent:FireAllClients(contestantIds)
	end

	print(`[Contest] Voting phase ({Constants.CONTEST_VOTING_SECONDS}s)`)
	task.wait(Constants.CONTEST_VOTING_SECONDS)

	calculateResults()
end

-- ============================================================
-- CALCULATE RESULTS
-- ============================================================
calculateResults = function()
	setState("RESULTS")

	-- Tally votes with level-weighted scoring
	local voteTotals: { [Player]: number } = {}

	for voter, targets in votes do
		local voterData = DataManager.getData(voter)
		local voterLevel = if voterData then voterData.level else 1
		local voteWeight = Utils.getVoteWeight(voterLevel)

		for _, target in targets do
			voteTotals[target] = (voteTotals[target] or 0) + voteWeight
		end
	end

	-- Also factor in outfit-theme score (30% theme score + 70% votes)
	local results: { { player: Player, totalScore: number, voteScore: number, themeScore: number } } = {}

	for player, entry in entries do
		local voteScore = voteTotals[player] or 0
		local themeScore = entry.score

		-- Normalize scores: theme score max ~30, votes max depends on player count
		-- Use simple weighted sum
		local totalScore = (themeScore * 0.3) + (voteScore * 0.7)

		table.insert(results, {
			player = player,
			totalScore = totalScore,
			voteScore = voteScore,
			themeScore = themeScore,
		})
	end

	-- Sort by total score (descending)
	table.sort(results, function(a, b)
		return a.totalScore > b.totalScore
	end)

	-- Distribute rewards
	for rank, result in results do
		local player = result.player
		if player.Parent ~= Players then
			continue
		end -- Player left

		local data = DataManager.getData(player)
		if not data then
			continue
		end

		-- Track contest entry
		data.contestsEntered += 1

		-- Wire daily challenge tracking
		local DailyChallengeMgr = require(ServerScriptService:WaitForChild("DailyChallengeManager"))
		DailyChallengeMgr.trackProgress(player, "contests_entered", 1)

		if rank <= 3 then
			-- Top 3 get SC + GG + XP
			local scReward = Constants.CONTEST_REWARDS_SC[rank] or 0
			local ggReward = Constants.CONTEST_REWARDS_GG[rank] or 0
			local xpReward = if rank == 1 then Constants.XP_CONTEST_WIN else Constants.XP_CONTEST_TOP3

			EconomyManager.addStyleCoins(player, scReward)
			EconomyManager.addGlamGems(player, ggReward)
			DataManager.addXP(player, xpReward)

			if rank == 1 then
				data.contestsWon += 1
				DailyChallengeMgr.trackProgress(player, "contests_won", 1)
			end

			-- Update best score
			if result.totalScore > data.bestContestScore then
				data.bestContestScore = result.totalScore
			end
		else
			-- Participation reward
			EconomyManager.addStyleCoins(player, Constants.CONTEST_PARTICIPATION_SC)
			DataManager.addXP(player, Constants.XP_CONTEST_ENTERED)
		end
	end

	-- Send results to all clients
	local resultsEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("ContestResults")
	if resultsEvent then
		local resultsData = {}
		for rank, result in results do
			if rank > 10 then
				break
			end -- Only send top 10
			table.insert(resultsData, {
				userId = result.player.UserId,
				name = result.player.Name,
				rank = rank,
				totalScore = math.floor(result.totalScore * 10) / 10, -- 1 decimal
				voteScore = math.floor(result.voteScore * 10) / 10,
				themeScore = result.themeScore,
			})
		end
		resultsEvent:FireAllClients(resultsData)
	end

	print(`[Contest] Results: 1st={if results[1] then results[1].player.Name else "none"}`)

	-- Show results for a few seconds, then back to idle
	task.wait(Constants.CONTEST_RESULTS_SECONDS)
	setState("IDLE")
end

-- ============================================================
-- ENTRY SUBMISSION (called by client during DRESSING phase)
-- ============================================================
function ContestManager.submitEntry(player: Player, outfit: any): (boolean, string)
	if currentState ~= "DRESSING" then
		return false, "Contest is not in dressing phase"
	end

	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	-- Validate outfit items are owned
	local itemTags: { { string } } = {}
	local slots = { "top", "bottom", "dress", "shoes", "accessory1", "accessory2", "hair", "headwear", "bag" }

	for _, slot in slots do
		local itemId = outfit[slot]
		if itemId and itemId ~= "" then
			if not data.ownedItems[itemId] then
				return false, `You don't own: {itemId}`
			end
			local item = ItemCatalog.ById[itemId]
			if item then
				table.insert(itemTags, item.tags)
			end
		end
	end

	-- Must have at least 1 item equipped
	if #itemTags == 0 then
		return false, "Must wear at least one item"
	end

	-- Score against current theme
	local themeScore = ThemeCatalog.scoreOutfit(currentTheme.id, itemTags)

	entries[player] = {
		outfit = outfit,
		score = themeScore,
	}

	-- Notify client of submission
	local entryEvent = ReplicatedStorage.Remotes.Events:FindFirstChild("ContestEntrySubmitted")
	if entryEvent then
		entryEvent:FireClient(player, themeScore)
	end

	return true, `Entry submitted! Theme score: {themeScore}`
end

-- ============================================================
-- VOTE CASTING (called by client during VOTING phase)
-- ============================================================
function ContestManager.castVote(player: Player, targetUserId: number): (boolean, string)
	if currentState ~= "VOTING" then
		return false, "Voting is not open"
	end

	-- Find target player
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then
		return false, "Player not found"
	end

	-- Can't vote for yourself
	if target == player then
		return false, "Cannot vote for yourself"
	end

	-- Must be a contestant
	if not entries[target] then
		return false, "Player is not a contestant"
	end

	-- Check vote limit
	if not votes[player] then
		votes[player] = {}
	end

	if #votes[player] >= Constants.CONTEST_VOTES_PER_PLAYER then
		return false, "No votes remaining"
	end

	-- Check for duplicate vote
	for _, existingTarget in votes[player] do
		if existingTarget == target then
			return false, "Already voted for this player"
		end
	end

	table.insert(votes[player], target)

	return true, `Vote cast! {Constants.CONTEST_VOTES_PER_PLAYER - #votes[player]} votes remaining`
end

-- ============================================================
-- REMOTE FUNCTION HANDLERS
-- ============================================================
local function init()
	DataManager = require(ServerScriptService:WaitForChild("DataManager"))
	EconomyManager = require(ServerScriptService:WaitForChild("EconomyManager"))

	local functions = ReplicatedStorage.Remotes.Functions

	local submitFunc = functions:FindFirstChild("SubmitContestEntry")
	if submitFunc then
		(submitFunc :: RemoteFunction).OnServerInvoke = function(player: Player, outfit: any)
			return ContestManager.submitEntry(player, outfit)
		end
	end

	local voteFunc = functions:FindFirstChild("CastVote")
	if voteFunc then
		(voteFunc :: RemoteFunction).OnServerInvoke = function(player: Player, targetUserId: number)
			return ContestManager.castVote(player, targetUserId)
		end
	end

	print("[Style Kingdom] ContestManager initialized")

	-- Start the contest cycle loop (with overlap guard)
	task.spawn(function()
		while true do
			task.wait(Constants.CONTEST_CYCLE_SECONDS)

			-- Don't start new contest if previous one is still running
			if currentState ~= "IDLE" then
				print("[Contest] Skipping cycle — previous contest still active")
				continue
			end

			-- Need at least 3 players for a meaningful contest
			if #Players:GetPlayers() >= 3 then
				startThemePhase()
			else
				print("[Contest] Not enough players for contest, waiting...")
			end
		end
	end)
end

init()

return ContestManager
