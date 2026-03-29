--!strict
-- Style Kingdom — HUD
-- Always-visible overlay: currency, level, XP bar, contest timer, nav bar

local Players = game:GetService("Players")

local UILib = require(script.Parent.UILib)
local Utils = require(script.Parent.Parent.Utils)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUD = {}

local screenGui: ScreenGui
local currencySC: Frame
local currencyGG: Frame
local levelLabel: TextLabel
local xpBar: Frame
local contestTimer: TextLabel
local navBar: Frame

-- Track which screen is active
local activeScreen: string = "boutique"
local screenChangeCallbacks: { (string) -> () } = {}

function HUD.onScreenChange(callback: (string) -> ())
	table.insert(screenChangeCallbacks, callback)
end

local function notifyScreenChange(screenId: string)
	activeScreen = screenId
	for _, cb in screenChangeCallbacks do
		task.spawn(cb, screenId)
	end
end

function HUD.init()
	screenGui = UILib.screenGui("HUD")
	screenGui.DisplayOrder = 100 -- Always on top
	screenGui.Parent = playerGui

	-- ============================================================
	-- TOP BAR: Currency + Level
	-- ============================================================
	local topBar = UILib.frame({
		name = "TopBar",
		size = UDim2.new(1, 0, 0, 90),
		color = UILib.Colors.BgDark,
		transparency = 0.2,
		parent = screenGui,
	})

	-- Safe area padding (notch/island)
	local topPad = Instance.new("UIPadding")
	topPad.PaddingTop = UDim.new(0, 44) -- iPhone notch safe area
	topPad.PaddingLeft = UDim.new(0, 12)
	topPad.PaddingRight = UDim.new(0, 12)
	topPad.Parent = topBar

	-- StyleCoins display
	currencySC = UILib.currencyDisplay({
		name = "StyleCoins",
		amount = 0,
		currencyType = "SC",
		size = UDim2.fromOffset(130, 32),
		position = UDim2.fromOffset(0, 2),
		parent = topBar,
	})

	-- GlamGems display
	currencyGG = UILib.currencyDisplay({
		name = "GlamGems",
		amount = 0,
		currencyType = "GG",
		size = UDim2.fromOffset(110, 32),
		position = UDim2.fromOffset(140, 2),
		parent = topBar,
	})

	-- Level badge
	local levelBadge = UILib.frame({
		name = "LevelBadge",
		size = UDim2.fromOffset(90, 32),
		position = UDim2.new(1, 0, 0, 2),
		anchor = Vector2.new(1, 0),
		color = UILib.Colors.Accent,
		cornerRadius = 16,
		parent = topBar,
	})

	levelLabel = UILib.textLabel({
		name = "Level",
		text = "Lv. 1",
		size = UDim2.fromScale(1, 1),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.TextLight,
		xAlign = Enum.TextXAlignment.Center,
		parent = levelBadge,
	})

	-- XP Progress bar (below level badge)
	xpBar = UILib.progressBar({
		name = "XPBar",
		size = UDim2.new(1, -24, 0, 6),
		position = UDim2.new(0, 12, 0, 38),
		progress = 0,
		barColor = UILib.Colors.Accent,
		parent = topBar,
	})

	-- ============================================================
	-- CONTEST TIMER (shown when contest is active)
	-- ============================================================
	local timerContainer = UILib.frame({
		name = "ContestTimer",
		size = UDim2.new(0.6, 0, 0, 36),
		position = UDim2.new(0.5, 0, 0, 94),
		anchor = Vector2.new(0.5, 0),
		color = UILib.Colors.Secondary,
		cornerRadius = 18,
		parent = screenGui,
	})
	timerContainer.Visible = false

	contestTimer = UILib.textLabel({
		name = "TimerText",
		text = "🏆 Contest: Seoul Street Style — 1:30",
		size = UDim2.fromScale(1, 1),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.BgDark,
		xAlign = Enum.TextXAlignment.Center,
		parent = timerContainer,
	})

	-- ============================================================
	-- BOTTOM NAV BAR
	-- ============================================================
	navBar = UILib.tabBar({
		tabs = {
			{ id = "boutique", label = "Boutique", icon = "🏪" },
			{ id = "wardrobe", label = "Wardrobe", icon = "👗" },
			{ id = "shop", label = "Shop", icon = "🛒" },
			{ id = "contest", label = "Contest", icon = "🏆" },
			{ id = "profile", label = "Profile", icon = "👤" },
		},
		onSelect = function(id: string)
			HUD.setActiveTab(id)
			notifyScreenChange(id)
		end,
		parent = screenGui,
	})

	-- Set initial active tab
	HUD.setActiveTab("boutique")
end

-- ============================================================
-- UPDATE METHODS
-- ============================================================

function HUD.updateCurrency(sc: number, gg: number)
	local scAmount = currencySC:FindFirstChild("Amount") :: TextLabel?
	if scAmount then
		scAmount.Text = Utils.formatNumber(sc)
	end
	local ggAmount = currencyGG:FindFirstChild("Amount") :: TextLabel?
	if ggAmount then
		ggAmount.Text = Utils.formatNumber(gg)
	end
end

function HUD.updateLevel(level: number, xp: number)
	levelLabel.Text = `Lv. {level}`

	local xpNeeded = Utils.xpForLevel(level)
	local progress = if xpNeeded > 0 then math.clamp(xp / xpNeeded, 0, 1) else 0

	-- Update XP bar if it exists
	if xpBar then
		local fill = xpBar:FindFirstChild("Fill") :: Frame?
		if fill then
			UILib.tween(fill, { Size = UDim2.fromScale(progress, 1) })
		end
		local text = xpBar:FindFirstChild("Text") :: TextLabel?
		if text then
			text.Text = `{Utils.formatNumber(xp)}/{Utils.formatNumber(xpNeeded)} XP`
		end
	end
end

function HUD.showContestTimer(themeName: string, timeLeft: number)
	local timerContainer = screenGui:FindFirstChild("ContestTimer") :: Frame?
	if timerContainer then
		timerContainer.Visible = true
		local mins = math.floor(timeLeft / 60)
		local secs = timeLeft % 60
		contestTimer.Text = `🏆 {themeName} — {mins}:{string.format("%02d", secs)}`
	end
end

function HUD.hideContestTimer()
	local timerContainer = screenGui:FindFirstChild("ContestTimer") :: Frame?
	if timerContainer then
		timerContainer.Visible = false
	end
end

function HUD.setActiveTab(tabId: string)
	activeScreen = tabId
	-- Update tab highlight
	for _, child in navBar:GetChildren() do
		if child:IsA("TextButton") then
			local label = child:FindFirstChild("Label") :: TextLabel?
			local icon = child:FindFirstChild("Icon") :: TextLabel?
			local isActive = child.Name == tabId
			if label then
				label.TextColor3 = if isActive then UILib.Colors.Primary else UILib.Colors.TextMuted
			end
			if icon then
				icon.TextColor3 = if isActive then UILib.Colors.Primary else UILib.Colors.TextLight
			end
		end
	end
end

function HUD.getActiveScreen(): string
	return activeScreen
end

function HUD.getScreenGui(): ScreenGui
	return screenGui
end

return HUD
