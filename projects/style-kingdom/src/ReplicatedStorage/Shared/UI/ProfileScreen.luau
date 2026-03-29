--!strict
-- Style Kingdom — ProfileScreen
-- Player stats, prestige progress, daily challenges, settings

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(script.Parent.Parent.Constants)
local UILib = require(script.Parent.UILib)
local Utils = require(script.Parent.Parent.Utils)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local functions = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Functions")

local ProfileScreen = {}

local screenGui: ScreenGui
local statsContainer: Frame
local challengeContainer: ScrollingFrame
local prestigePanel: Frame
local playerData: any = nil

function ProfileScreen.init()
	screenGui = UILib.screenGui("ProfileScreen")
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

	-- Scrollable content
	local scroll = UILib.scrollFrame({
		name = "Content",
		size = UDim2.fromScale(1, 1),
		padding = 8,
		parent = container,
	})

	UILib.listLayout({ padding = 10, parent = scroll })

	-- ============================================================
	-- PLAYER HEADER
	-- ============================================================
	local header = UILib.frame({
		name = "Header",
		size = UDim2.new(1, -16, 0, 100),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadius,
		parent = scroll,
	})
	header.LayoutOrder = 1

	-- Avatar placeholder
	local avatarBg = UILib.frame({
		name = "AvatarBg",
		size = UDim2.fromOffset(64, 64),
		position = UDim2.fromOffset(16, 18),
		color = UILib.Colors.Primary,
		cornerRadius = 32,
		parent = header,
	})

	UILib.textLabel({
		text = "👤",
		size = UDim2.fromScale(1, 1),
		textSize = 32,
		xAlign = Enum.TextXAlignment.Center,
		parent = avatarBg,
	})

	-- Player name
	UILib.textLabel({
		name = "PlayerName",
		text = player.DisplayName,
		size = UDim2.new(1, -100, 0, 24),
		position = UDim2.fromOffset(90, 18),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.TextPrimary,
		parent = header,
	})

	-- Level + XP bar
	UILib.textLabel({
		name = "LevelText",
		text = "Level 1 • 0 XP",
		size = UDim2.new(1, -100, 0, 18),
		position = UDim2.fromOffset(90, 44),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.Accent,
		parent = header,
	})

	UILib.progressBar({
		name = "XPBar",
		size = UDim2.new(1, -108, 0, 14),
		position = UDim2.fromOffset(90, 66),
		progress = 0,
		barColor = UILib.Colors.Accent,
		text = "0/100 XP",
		parent = header,
	})

	-- ============================================================
	-- STATS GRID
	-- ============================================================
	statsContainer = UILib.frame({
		name = "Stats",
		size = UDim2.new(1, -16, 0, 180),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadius,
		parent = scroll,
	})
	statsContainer.LayoutOrder = 2

	local statsPad = Instance.new("UIPadding")
	statsPad.PaddingLeft = UDim.new(0, 10)
	statsPad.PaddingRight = UDim.new(0, 10)
	statsPad.PaddingTop = UDim.new(0, 8)
	statsPad.Parent = statsContainer

	UILib.textLabel({
		name = "StatsTitle",
		text = "📊 Lifetime Stats",
		size = UDim2.new(1, 0, 0, 24),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextPrimary,
		parent = statsContainer,
	})

	-- 2x3 stat grid
	local statGrid = UILib.frame({
		name = "StatGrid",
		size = UDim2.new(1, 0, 0, 140),
		position = UDim2.fromOffset(0, 28),
		transparency = 1,
		parent = statsContainer,
	})

	UILib.gridLayout({
		cellSize = UDim2.new(0.48, 0, 0, 40),
		padding = UDim2.fromOffset(8, 8),
		parent = statGrid,
	})

	local statDefs = {
		{ key = "customersServed", label = "Customers Served", icon = "👥", order = 1 },
		{ key = "contestsWon", label = "Contests Won", icon = "🏆", order = 2 },
		{ key = "contestsEntered", label = "Contests Entered", icon = "🎭", order = 3 },
		{ key = "totalEarnings", label = "Total Earnings", icon = "💰", order = 4 },
		{ key = "bestContestScore", label = "Best Score", icon = "⭐", order = 5 },
		{ key = "loginStreak", label = "Login Streak", icon = "🔥", order = 6 },
	}

	for _, stat in statDefs do
		local cell = UILib.frame({
			name = `Stat_{stat.key}`,
			size = UDim2.fromOffset(100, 40),
			color = UILib.Colors.BgLight,
			cornerRadius = 8,
			parent = statGrid,
		})
		cell.LayoutOrder = stat.order

		UILib.textLabel({
			name = "Value",
			text = `{stat.icon} 0`,
			size = UDim2.new(1, -8, 0, 20),
			position = UDim2.fromOffset(4, 4),
			font = UILib.Fonts.Heading,
			textSize = UILib.Sizes.TextBody,
			textColor = UILib.Colors.TextPrimary,
			parent = cell,
		})

		UILib.textLabel({
			name = "Label",
			text = stat.label,
			size = UDim2.new(1, -8, 0, 14),
			position = UDim2.fromOffset(4, 24),
			font = UILib.Fonts.Caption,
			textSize = UILib.Sizes.TextSmall,
			textColor = UILib.Colors.TextMuted,
			parent = cell,
		})
	end

	-- ============================================================
	-- DAILY CHALLENGES
	-- ============================================================
	local challengeHeader = UILib.frame({
		name = "ChallengeHeader",
		size = UDim2.new(1, -16, 0, 30),
		transparency = 1,
		parent = scroll,
	})
	challengeHeader.LayoutOrder = 3

	UILib.textLabel({
		text = "📋 Daily Challenges",
		size = UDim2.fromScale(1, 1),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextPrimary,
		parent = challengeHeader,
	})

	challengeContainer = UILib.scrollFrame({
		name = "Challenges",
		size = UDim2.new(1, -16, 0, 200),
		parent = scroll,
	})
	challengeContainer.LayoutOrder = 4
	challengeContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y

	UILib.listLayout({ padding = 8, parent = challengeContainer })

	-- ============================================================
	-- PRESTIGE PANEL
	-- ============================================================
	prestigePanel = UILib.frame({
		name = "Prestige",
		size = UDim2.new(1, -16, 0, 130),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadius,
		parent = scroll,
	})
	prestigePanel.LayoutOrder = 5

	local ppPad = Instance.new("UIPadding")
	ppPad.PaddingLeft = UDim.new(0, 12)
	ppPad.PaddingRight = UDim.new(0, 12)
	ppPad.PaddingTop = UDim.new(0, 8)
	ppPad.Parent = prestigePanel

	UILib.textLabel({
		name = "PrestigeTitle",
		text = "🌟 Prestige",
		size = UDim2.new(1, 0, 0, 24),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.Secondary,
		parent = prestigePanel,
	})

	UILib.textLabel({
		name = "PrestigeInfo",
		text = "Reach Level 100 + Fashion Empire to prestige!",
		size = UDim2.new(1, 0, 0, 36),
		position = UDim2.fromOffset(0, 28),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.TextSecondary,
		wrapped = true,
		parent = prestigePanel,
	})

	UILib.textLabel({
		name = "PrestigeMultiplier",
		text = "Current multiplier: 1.0x",
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 66),
		font = UILib.Fonts.Mono,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.Accent,
		parent = prestigePanel,
	})

	UILib.textButton({
		name = "PrestigeBtn",
		text = "🌟 Prestige Now",
		size = UDim2.new(1, 0, 0, 36),
		position = UDim2.fromOffset(0, 88),
		bgColor = UILib.Colors.TextMuted,
		textSize = UILib.Sizes.TextCaption,
		parent = prestigePanel,
		onClick = function()
			ProfileScreen.prestige()
		end,
	})

	-- ============================================================
	-- SETTINGS
	-- ============================================================
	local settingsPanel = UILib.frame({
		name = "Settings",
		size = UDim2.new(1, -16, 0, 80),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadius,
		parent = scroll,
	})
	settingsPanel.LayoutOrder = 6

	local setPad = Instance.new("UIPadding")
	setPad.PaddingLeft = UDim.new(0, 12)
	setPad.PaddingRight = UDim.new(0, 12)
	setPad.PaddingTop = UDim.new(0, 8)
	setPad.Parent = settingsPanel

	UILib.textLabel({
		text = "⚙️ Settings",
		size = UDim2.new(1, 0, 0, 24),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextPrimary,
		parent = settingsPanel,
	})

	UILib.textLabel({
		name = "SettingsInfo",
		text = "Music & SFX volume controls coming soon!",
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 30),
		font = UILib.Fonts.Caption,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.TextMuted,
		parent = settingsPanel,
	})
end

-- ============================================================
-- DATA REFRESH
-- ============================================================

function ProfileScreen.refresh()
	if not playerData then
		return
	end

	-- Update header
	local header = screenGui:FindFirstChild("Container")
	if not header then
		return
	end

	local content = header:FindFirstChild("Content") :: ScrollingFrame?
	if not content then
		return
	end

	local headerCard = content:FindFirstChild("Header") :: Frame?
	if headerCard then
		local levelText = headerCard:FindFirstChild("LevelText") :: TextLabel?
		if levelText then
			levelText.Text = `Level {playerData.level} • {Utils.formatNumber(playerData.xp)} XP`
		end

		local xpBar = headerCard:FindFirstChild("XPBar") :: Frame?
		if xpBar then
			local xpNeeded = Utils.xpForLevel(playerData.level)
			local progress = if xpNeeded > 0 then math.clamp(playerData.xp / xpNeeded, 0, 1) else 0
			local fill = xpBar:FindFirstChild("Fill") :: Frame?
			if fill then
				fill.Size = UDim2.fromScale(progress, 1)
			end
			local text = xpBar:FindFirstChild("Text") :: TextLabel?
			if text then
				text.Text = `{Utils.formatNumber(playerData.xp)}/{Utils.formatNumber(xpNeeded)} XP`
			end
		end
	end

	-- Update stats
	local statGrid = statsContainer:FindFirstChild("StatGrid") :: Frame?
	if statGrid then
		local statMap = {
			customersServed = playerData.customersServed or 0,
			contestsWon = playerData.contestsWon or 0,
			contestsEntered = playerData.contestsEntered or 0,
			totalEarnings = playerData.totalEarnings or 0,
			bestContestScore = playerData.bestContestScore or 0,
			loginStreak = playerData.loginStreak or 0,
		}
		local statIcons = {
			customersServed = "👥",
			contestsWon = "🏆",
			contestsEntered = "🎭",
			totalEarnings = "💰",
			bestContestScore = "⭐",
			loginStreak = "🔥",
		}

		for key, value in statMap do
			local cell = statGrid:FindFirstChild(`Stat_{key}`)
			if cell then
				local valLabel = cell:FindFirstChild("Value") :: TextLabel?
				if valLabel then
					local icon = statIcons[key] or "📊"
					valLabel.Text = `{icon} {Utils.formatNumber(value)}`
				end
			end
		end
	end

	-- Update daily challenges
	ProfileScreen.refreshChallenges()

	-- Update prestige
	local prestigeCount = playerData.prestigeCount or 0
	local multi = Constants.PRESTIGE_MULTIPLIERS[prestigeCount] or 1.0

	local multiLabel = prestigePanel:FindFirstChild("PrestigeMultiplier") :: TextLabel?
	if multiLabel then
		multiLabel.Text = `Current multiplier: {multi}x (Prestige {prestigeCount}/{Constants.MAX_PRESTIGE})`
	end

	local canPrestige = playerData.level >= Constants.MAX_LEVEL
		and (playerData.boutique.tier or 1) >= Constants.MAX_BOUTIQUE_TIER
		and prestigeCount < Constants.MAX_PRESTIGE

	local pBtn = prestigePanel:FindFirstChild("PrestigeBtn") :: TextButton?
	if pBtn then
		pBtn.BackgroundColor3 = if canPrestige then UILib.Colors.Secondary else UILib.Colors.TextMuted
		pBtn.Text = if canPrestige
			then "🌟 Prestige Now!"
			elseif prestigeCount >= Constants.MAX_PRESTIGE then "✅ Max Prestige!"
			else `🌟 Need Lv.{Constants.MAX_LEVEL} + Tier {Constants.MAX_BOUTIQUE_TIER}`
	end
end

function ProfileScreen.refreshChallenges()
	-- Clear existing
	for _, child in challengeContainer:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local challenges = if playerData then playerData.dailyChallenges else nil
	if not challenges or #challenges == 0 then
		UILib.textLabel({
			name = "NoChallenges",
			text = "No challenges today. Check back tomorrow!",
			size = UDim2.new(1, 0, 0, 40),
			font = UILib.Fonts.Body,
			textSize = UILib.Sizes.TextCaption,
			textColor = UILib.Colors.TextMuted,
			xAlign = Enum.TextXAlignment.Center,
			wrapped = true,
			parent = challengeContainer,
		})
		return
	end

	local diffColors = {
		Easy = UILib.Colors.Success,
		Medium = UILib.Colors.Warning,
		Hard = UILib.Colors.Error,
	}

	for i, challenge in challenges do
		local card = UILib.frame({
			name = `Challenge_{i}`,
			size = UDim2.new(1, 0, 0, 72),
			color = UILib.Colors.BgCard,
			cornerRadius = UILib.Sizes.CornerRadiusSmall,
			parent = challengeContainer,
		})
		card.LayoutOrder = i

		if challenge.completed then
			card.BackgroundTransparency = 0.4
		end

		-- Difficulty badge
		local diffColor = diffColors[challenge.difficulty] or UILib.Colors.Info
		local badge = UILib.frame({
			name = "Badge",
			size = UDim2.fromOffset(52, 18),
			position = UDim2.fromOffset(8, 6),
			color = diffColor,
			cornerRadius = 9,
			parent = card,
		})

		UILib.textLabel({
			text = challenge.difficulty,
			size = UDim2.fromScale(1, 1),
			font = UILib.Fonts.Caption,
			textSize = UILib.Sizes.TextSmall,
			textColor = UILib.Colors.TextLight,
			xAlign = Enum.TextXAlignment.Center,
			parent = badge,
		})

		-- Description
		UILib.textLabel({
			text = challenge.description,
			size = UDim2.new(1, -16, 0, 20),
			position = UDim2.fromOffset(8, 28),
			font = UILib.Fonts.Body,
			textSize = UILib.Sizes.TextCaption,
			textColor = if challenge.completed then UILib.Colors.Success else UILib.Colors.TextPrimary,
			parent = card,
		})

		-- Progress bar
		local progress = math.clamp(challenge.progress / challenge.target, 0, 1)
		UILib.progressBar({
			size = UDim2.new(1, -80, 0, 12),
			position = UDim2.fromOffset(8, 52),
			progress = progress,
			barColor = if challenge.completed then UILib.Colors.Success else UILib.Colors.Primary,
			text = `{challenge.progress}/{challenge.target}`,
			parent = card,
		})

		-- Reward
		UILib.textLabel({
			text = if challenge.completed then "✅" else `💰{challenge.rewardSC}`,
			size = UDim2.fromOffset(56, 20),
			position = UDim2.new(1, -8, 0, 48),
			anchor = Vector2.new(1, 0),
			font = UILib.Fonts.Heading,
			textSize = UILib.Sizes.TextSmall,
			textColor = UILib.Colors.StyleCoin,
			xAlign = Enum.TextXAlignment.Right,
			parent = card,
		})
	end
end

-- ============================================================
-- SERVER ACTIONS
-- ============================================================

function ProfileScreen.prestige()
	local prestigeFunc = functions:FindFirstChild("Prestige") :: RemoteFunction?
	if prestigeFunc then
		local success, msg = prestigeFunc:InvokeServer()
		if not success then
			local errorEvent = ReplicatedStorage:FindFirstChild("UIError") :: BindableEvent?
			if errorEvent then
				errorEvent:Fire(msg or "Prestige failed")
			end
		end
	end
end

-- ============================================================
-- SCREEN VISIBILITY
-- ============================================================

function ProfileScreen.show()
	screenGui.Enabled = true
	ProfileScreen.refresh()
end

function ProfileScreen.hide()
	screenGui.Enabled = false
end

function ProfileScreen.updatePlayerData(data: any)
	playerData = data
	if screenGui.Enabled then
		ProfileScreen.refresh()
	end
end

return ProfileScreen
