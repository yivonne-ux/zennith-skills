--!strict
-- Style Kingdom — ContestScreen
-- Full contest UI: theme announce → dress → runway → vote → results

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ThemeCatalog = require(script.Parent.Parent.ThemeCatalog)
local UILib = require(script.Parent.UILib)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local functions = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Functions")

local ContestScreen = {}

local screenGui: ScreenGui
local phaseContainer: Frame
local themePanel: Frame
local dressingPanel: Frame
local runwayPanel: Frame
local votingPanel: Frame
local resultsPanel: Frame
local idlePanel: Frame

-- State tracked for future use (contest phase transitions, theme matching)
local _currentState: string = "IDLE"
local _currentThemeId: string = ""
local _currentThemeName: string = ""
local _currentThemeDesc: string = ""
local _contestantIds: { number } = {}
local _playerData: any = nil
local votesRemaining: number = 3

function ContestScreen.init()
	screenGui = UILib.screenGui("ContestScreen")
	screenGui.DisplayOrder = 20
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local container = UILib.frame({
		name = "Container",
		size = UDim2.new(1, 0, 1, -188),
		position = UDim2.fromOffset(0, 90),
		color = UILib.Colors.BgLight,
		parent = screenGui,
	})

	-- Header
	UILib.textLabel({
		name = "Title",
		text = "🏆 Fashion Contest",
		size = UDim2.new(1, 0, 0, 40),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		color = UILib.Colors.BgCard,
		transparency = 0,
		parent = container,
	})

	phaseContainer = UILib.frame({
		name = "PhaseContainer",
		size = UDim2.new(1, 0, 1, -40),
		position = UDim2.fromOffset(0, 40),
		transparency = 1,
		parent = container,
	})

	-- Create all phase panels
	ContestScreen._buildIdlePanel()
	ContestScreen._buildThemePanel()
	ContestScreen._buildDressingPanel()
	ContestScreen._buildRunwayPanel()
	ContestScreen._buildVotingPanel()
	ContestScreen._buildResultsPanel()

	-- Show idle by default
	ContestScreen._showPhase("IDLE")
end

-- ============================================================
-- PHASE PANELS
-- ============================================================

function ContestScreen._buildIdlePanel()
	idlePanel = UILib.frame({
		name = "Idle",
		size = UDim2.fromScale(1, 1),
		transparency = 1,
		parent = phaseContainer,
	})

	local center = UILib.frame({
		name = "Center",
		size = UDim2.new(0.85, 0, 0, 260),
		position = UDim2.new(0.5, 0, 0.35, 0),
		anchor = Vector2.new(0.5, 0.5),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadiusLarge,
		parent = idlePanel,
	})

	UILib.textLabel({
		text = "🏆",
		size = UDim2.new(1, 0, 0, 60),
		position = UDim2.fromOffset(0, 20),
		textSize = 48,
		xAlign = Enum.TextXAlignment.Center,
		parent = center,
	})

	UILib.textLabel({
		name = "WaitTitle",
		text = "Next Contest Starting Soon...",
		size = UDim2.new(1, -24, 0, 30),
		position = UDim2.fromOffset(12, 85),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		parent = center,
	})

	UILib.textLabel({
		name = "WaitDesc",
		text = "Contests run every 15 minutes.\nGet your best outfits ready!",
		size = UDim2.new(1, -24, 0, 50),
		position = UDim2.fromOffset(12, 120),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextSecondary,
		xAlign = Enum.TextXAlignment.Center,
		wrapped = true,
		parent = center,
	})

	-- Tips
	UILib.textLabel({
		name = "Tip",
		text = "💡 Tip: Match your outfit tags to the contest theme for higher scores!",
		size = UDim2.new(1, -24, 0, 40),
		position = UDim2.fromOffset(12, 185),
		font = UILib.Fonts.Caption,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.Accent,
		xAlign = Enum.TextXAlignment.Center,
		wrapped = true,
		parent = center,
	})
end

function ContestScreen._buildThemePanel()
	themePanel = UILib.frame({
		name = "ThemeAnnounce",
		size = UDim2.fromScale(1, 1),
		transparency = 1,
		parent = phaseContainer,
	})
	themePanel.Visible = false

	local card = UILib.frame({
		name = "Card",
		size = UDim2.new(0.9, 0, 0, 300),
		position = UDim2.new(0.5, 0, 0.35, 0),
		anchor = Vector2.new(0.5, 0.5),
		color = UILib.Colors.Secondary,
		cornerRadius = UILib.Sizes.CornerRadiusLarge,
		parent = themePanel,
	})

	UILib.textLabel({
		name = "Announce",
		text = "✨ THEME REVEALED ✨",
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.fromOffset(0, 20),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.BgDark,
		xAlign = Enum.TextXAlignment.Center,
		parent = card,
	})

	UILib.textLabel({
		name = "ThemeName",
		text = "Seoul Street Style",
		size = UDim2.new(1, -24, 0, 40),
		position = UDim2.fromOffset(12, 60),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextTitle,
		textColor = UILib.Colors.BgDark,
		xAlign = Enum.TextXAlignment.Center,
		parent = card,
	})

	UILib.textLabel({
		name = "ThemeDesc",
		text = "Channel your inner K-fashion icon with street style looks",
		size = UDim2.new(1, -32, 0, 60),
		position = UDim2.fromOffset(16, 110),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		wrapped = true,
		parent = card,
	})

	UILib.textLabel({
		name = "TagHints",
		text = "Look for: street, korean, casual",
		size = UDim2.new(1, -24, 0, 24),
		position = UDim2.fromOffset(12, 180),
		font = UILib.Fonts.Mono,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.TextSecondary,
		xAlign = Enum.TextXAlignment.Center,
		parent = card,
	})

	UILib.textButton({
		name = "GoBtn",
		text = "👗 Open Wardrobe & Dress Up!",
		size = UDim2.new(1, -48, 0, 48),
		position = UDim2.new(0.5, 0, 1, -16),
		anchor = Vector2.new(0.5, 1),
		bgColor = UILib.Colors.Primary,
		parent = card,
	})
end

function ContestScreen._buildDressingPanel()
	dressingPanel = UILib.frame({
		name = "Dressing",
		size = UDim2.fromScale(1, 1),
		transparency = 1,
		parent = phaseContainer,
	})
	dressingPanel.Visible = false

	-- Timer
	UILib.textLabel({
		name = "Timer",
		text = "⏱ 1:30 remaining",
		size = UDim2.new(1, 0, 0, 36),
		position = UDim2.fromOffset(0, 8),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.Error,
		xAlign = Enum.TextXAlignment.Center,
		parent = dressingPanel,
	})

	-- Theme reminder
	UILib.textLabel({
		name = "ThemeReminder",
		text = "Theme: Seoul Street Style",
		size = UDim2.new(1, 0, 0, 24),
		position = UDim2.fromOffset(0, 44),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.Accent,
		xAlign = Enum.TextXAlignment.Center,
		parent = dressingPanel,
	})

	-- Submit entry button
	UILib.textButton({
		name = "SubmitEntry",
		text = "🏆 Submit Contest Entry",
		size = UDim2.new(0.8, 0, 0, 52),
		position = UDim2.new(0.5, 0, 1, -20),
		anchor = Vector2.new(0.5, 1),
		bgColor = UILib.Colors.Secondary,
		textColor = UILib.Colors.BgDark,
		textSize = UILib.Sizes.TextBody,
		parent = dressingPanel,
		onClick = function()
			ContestScreen.submitEntry()
		end,
	})

	-- Instructions
	UILib.textLabel({
		name = "Instructions",
		text = "Go to Wardrobe → equip your best outfit → come back and submit!",
		size = UDim2.new(0.9, 0, 0, 40),
		position = UDim2.new(0.5, 0, 0.5, 0),
		anchor = Vector2.new(0.5, 0.5),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextSecondary,
		xAlign = Enum.TextXAlignment.Center,
		wrapped = true,
		parent = dressingPanel,
	})
end

function ContestScreen._buildRunwayPanel()
	runwayPanel = UILib.frame({
		name = "Runway",
		size = UDim2.fromScale(1, 1),
		transparency = 1,
		parent = phaseContainer,
	})
	runwayPanel.Visible = false

	UILib.textLabel({
		name = "RunwayTitle",
		text = "👠 RUNWAY SHOW",
		size = UDim2.new(1, 0, 0, 40),
		position = UDim2.fromOffset(0, 10),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextTitle,
		textColor = UILib.Colors.Secondary,
		xAlign = Enum.TextXAlignment.Center,
		parent = runwayPanel,
	})

	UILib.textLabel({
		name = "WalkerName",
		text = "Walking: PlayerName",
		size = UDim2.new(1, 0, 0, 28),
		position = UDim2.fromOffset(0, 55),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		parent = runwayPanel,
	})

	UILib.textLabel({
		name = "WalkerProgress",
		text = "1 / 5",
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 85),
		font = UILib.Fonts.Caption,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.TextMuted,
		xAlign = Enum.TextXAlignment.Center,
		parent = runwayPanel,
	})
end

function ContestScreen._buildVotingPanel()
	votingPanel = UILib.frame({
		name = "Voting",
		size = UDim2.fromScale(1, 1),
		transparency = 1,
		parent = phaseContainer,
	})
	votingPanel.Visible = false

	UILib.textLabel({
		name = "VoteTitle",
		text = "🗳 VOTE NOW",
		size = UDim2.new(1, 0, 0, 36),
		position = UDim2.fromOffset(0, 8),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.Primary,
		xAlign = Enum.TextXAlignment.Center,
		parent = votingPanel,
	})

	UILib.textLabel({
		name = "VotesLeft",
		text = "Votes remaining: 3",
		size = UDim2.new(1, 0, 0, 24),
		position = UDim2.fromOffset(0, 44),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.Accent,
		xAlign = Enum.TextXAlignment.Center,
		parent = votingPanel,
	})

	-- Contestant grid (scrollable)
	local voteScroll = UILib.scrollFrame({
		name = "ContestantGrid",
		size = UDim2.new(1, 0, 1, -80),
		position = UDim2.fromOffset(0, 72),
		padding = 8,
		parent = votingPanel,
	})

	UILib.gridLayout({
		cellSize = UDim2.fromOffset(140, 100),
		padding = UDim2.fromOffset(10, 10),
		parent = voteScroll,
	})
end

function ContestScreen._buildResultsPanel()
	resultsPanel = UILib.frame({
		name = "Results",
		size = UDim2.fromScale(1, 1),
		transparency = 1,
		parent = phaseContainer,
	})
	resultsPanel.Visible = false

	UILib.textLabel({
		name = "ResultsTitle",
		text = "🎉 CONTEST RESULTS",
		size = UDim2.new(1, 0, 0, 40),
		position = UDim2.fromOffset(0, 10),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextTitle,
		textColor = UILib.Colors.Secondary,
		xAlign = Enum.TextXAlignment.Center,
		parent = resultsPanel,
	})

	-- Results list (populated dynamically)
	UILib.scrollFrame({
		name = "ResultsList",
		size = UDim2.new(0.9, 0, 1, -60),
		position = UDim2.new(0.05, 0, 0, 55),
		parent = resultsPanel,
	})
end

-- ============================================================
-- PHASE TRANSITIONS
-- ============================================================

function ContestScreen._showPhase(phase: string)
	idlePanel.Visible = phase == "IDLE"
	themePanel.Visible = phase == "THEME_ANNOUNCED"
	dressingPanel.Visible = phase == "DRESSING"
	runwayPanel.Visible = phase == "RUNWAY"
	votingPanel.Visible = phase == "VOTING"
	resultsPanel.Visible = phase == "RESULTS"
end

function ContestScreen.setState(state: string)
	_currentState = state
	ContestScreen._showPhase(state)
end

function ContestScreen.setTheme(themeId: string, themeName: string, themeDesc: string)
	_currentThemeId = themeId
	_currentThemeName = themeName
	_currentThemeDesc = themeDesc

	-- Update theme panel
	local card = themePanel:FindFirstChild("Card")
	if card then
		local nameLabel = card:FindFirstChild("ThemeName") :: TextLabel?
		if nameLabel then
			nameLabel.Text = themeName
		end
		local descLabel = card:FindFirstChild("ThemeDesc") :: TextLabel?
		if descLabel then
			descLabel.Text = themeDesc
		end

		-- Show desired tags as hints
		local theme = ThemeCatalog.ById[themeId]
		if theme then
			local hints = {}
			for tag, _ in theme.scoring.desiredTags do
				table.insert(hints, tag)
			end
			local tagLabel = card:FindFirstChild("TagHints") :: TextLabel?
			if tagLabel then
				tagLabel.Text = "Look for: " .. table.concat(hints, ", ")
			end
		end
	end

	-- Update dressing panel
	local reminder = dressingPanel:FindFirstChild("ThemeReminder") :: TextLabel?
	if reminder then
		reminder.Text = `Theme: {themeName}`
	end
end

function ContestScreen.updateDressingTimer(timeLeft: number)
	local timer = dressingPanel:FindFirstChild("Timer") :: TextLabel?
	if timer then
		local mins = math.floor(timeLeft / 60)
		local secs = timeLeft % 60
		timer.Text = `⏱ {mins}:{string.format("%02d", secs)} remaining`
		timer.TextColor3 = if timeLeft <= 15 then UILib.Colors.Error else UILib.Colors.TextPrimary
	end
end

function ContestScreen.setRunwayWalker(walkerName: string, index: number, total: number)
	local nameLabel = runwayPanel:FindFirstChild("WalkerName") :: TextLabel?
	if nameLabel then
		nameLabel.Text = `Walking: {walkerName}`
	end
	local progress = runwayPanel:FindFirstChild("WalkerProgress") :: TextLabel?
	if progress then
		progress.Text = `{index} / {total}`
	end
end

function ContestScreen.setupVoting(ids: { number })
	_contestantIds = ids
	votesRemaining = 3

	local votesLabel = votingPanel:FindFirstChild("VotesLeft") :: TextLabel?
	if votesLabel then
		votesLabel.Text = `Votes remaining: {votesRemaining}`
	end

	-- Populate contestant cards
	local grid = votingPanel:FindFirstChild("ContestantGrid") :: ScrollingFrame?
	if grid then
		-- Clear old cards
		for _, child in grid:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for i, userId in ids do
			-- Don't allow voting for self
			if userId == player.UserId then
				continue
			end

			local contestant = Players:GetPlayerByUserId(userId)
			local name = if contestant then contestant.DisplayName else `Player {userId}`

			local card = UILib.frame({
				name = `Vote_{userId}`,
				size = UDim2.fromOffset(140, 100),
				color = UILib.Colors.BgCard,
				cornerRadius = UILib.Sizes.CornerRadius,
				parent = grid,
			})
			card.LayoutOrder = i

			UILib.textLabel({
				text = name,
				size = UDim2.new(1, -8, 0, 24),
				position = UDim2.fromOffset(4, 8),
				font = UILib.Fonts.Heading,
				textSize = UILib.Sizes.TextCaption,
				textColor = UILib.Colors.TextPrimary,
				xAlign = Enum.TextXAlignment.Center,
				parent = card,
			})

			UILib.textButton({
				name = "VoteBtn",
				text = "⭐ Vote",
				size = UDim2.new(1, -16, 0, 36),
				position = UDim2.new(0.5, 0, 1, -12),
				anchor = Vector2.new(0.5, 1),
				bgColor = UILib.Colors.Primary,
				textSize = UILib.Sizes.TextCaption,
				parent = card,
				onClick = function()
					ContestScreen.castVote(userId)
				end,
			})
		end
	end
end

function ContestScreen.showResults(results: { any })
	local list = resultsPanel:FindFirstChild("ResultsList") :: ScrollingFrame?
	if not list then
		return
	end

	-- Clear old results
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	UILib.listLayout({ padding = 8, parent = list })

	local medals = { "🥇", "🥈", "🥉" }

	for i, result in results do
		local medal = medals[i] or `#{i}`
		local isMe = result.userId == player.UserId

		local row = UILib.frame({
			name = `Result_{i}`,
			size = UDim2.new(1, 0, 0, 52),
			color = if isMe then UILib.Colors.Primary else UILib.Colors.BgCard,
			cornerRadius = UILib.Sizes.CornerRadiusSmall,
			parent = list,
		})
		row.LayoutOrder = i

		if isMe then
			row.BackgroundTransparency = 0.3
		end

		UILib.textLabel({
			text = `{medal} {result.name}`,
			size = UDim2.new(0.6, 0, 1, 0),
			position = UDim2.fromOffset(12, 0),
			font = UILib.Fonts.Heading,
			textSize = UILib.Sizes.TextBody,
			textColor = if isMe then UILib.Colors.TextLight else UILib.Colors.TextPrimary,
			parent = row,
		})

		UILib.textLabel({
			text = `Score: {string.format("%.1f", result.totalScore)}`,
			size = UDim2.new(0.35, 0, 1, 0),
			position = UDim2.new(0.6, 0, 0, 0),
			font = UILib.Fonts.Mono,
			textSize = UILib.Sizes.TextCaption,
			textColor = UILib.Colors.Secondary,
			xAlign = Enum.TextXAlignment.Right,
			parent = row,
		})
	end
end

-- Error reporting via BindableEvent
local function reportError(msg: string)
	local errorEvent = ReplicatedStorage:FindFirstChild("UIError") :: BindableEvent?
	if errorEvent then
		errorEvent:Fire(msg)
	end
end

-- ============================================================
-- SERVER ACTIONS
-- ============================================================

function ContestScreen.submitEntry()
	local submitFunc = functions:FindFirstChild("SubmitContestEntry") :: RemoteFunction?
	if not submitFunc then
		return
	end

	-- Get current equipped outfit from server
	local getDataFunc = functions:FindFirstChild("GetPlayerData") :: RemoteFunction?
	local data = if getDataFunc then getDataFunc:InvokeServer() else nil
	local outfit = if data then data.equippedOutfit else nil

	if not outfit then
		warn("[Contest] No outfit equipped")
		return
	end

	local success, msg = submitFunc:InvokeServer(outfit)
	if success then
		local btn = dressingPanel:FindFirstChild("SubmitEntry") :: TextButton?
		if btn then
			btn.Text = "✅ Entry Submitted!"
			btn.BackgroundColor3 = UILib.Colors.Success
			btn.Active = false
		end
	else
		reportError(msg or "Submit failed")
	end
end

function ContestScreen.castVote(userId: number)
	if votesRemaining <= 0 then
		return
	end

	local voteFunc = functions:FindFirstChild("CastVote") :: RemoteFunction?
	if voteFunc then
		local success, msg = voteFunc:InvokeServer(userId)
		if success then
			votesRemaining -= 1
			local votesLabel = votingPanel:FindFirstChild("VotesLeft") :: TextLabel?
			if votesLabel then
				votesLabel.Text = `Votes remaining: {votesRemaining}`
			end

			-- Disable voted button
			local grid = votingPanel:FindFirstChild("ContestantGrid") :: ScrollingFrame?
			if grid then
				local card = grid:FindFirstChild(`Vote_{userId}`)
				if card then
					local btn = card:FindFirstChild("VoteBtn") :: TextButton?
					if btn then
						btn.Text = "✅ Voted"
						btn.BackgroundColor3 = UILib.Colors.Success
					end
				end
			end
		else
			reportError(msg or "Vote failed")
		end
	end
end

-- ============================================================
-- SCREEN VISIBILITY
-- ============================================================

function ContestScreen.show()
	screenGui.Enabled = true
end

function ContestScreen.hide()
	screenGui.Enabled = false
end

function ContestScreen.updatePlayerData(data: any)
	_playerData = data
end

return ContestScreen
