--!strict
-- Style Kingdom — Notifications
-- Toast notifications, popups (daily reward, lucky box, level up, prestige)

local Players = game:GetService("Players")

local Constants = require(script.Parent.Parent.Constants)
local UILib = require(script.Parent.UILib)
local Utils = require(script.Parent.Parent.Utils)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Notifications = {}

local screenGui: ScreenGui
local toastContainer: Frame
local activeToasts: { Frame } = {}
local MAX_TOASTS = 5

function Notifications.init()
	screenGui = UILib.screenGui("Notifications")
	screenGui.DisplayOrder = 200 -- Above everything
	screenGui.Parent = playerGui

	-- Toast container (top-right, stacks downward)
	toastContainer = UILib.frame({
		name = "ToastContainer",
		size = UDim2.new(0.7, 0, 0, 300),
		position = UDim2.new(1, -8, 0, 96),
		anchor = Vector2.new(1, 0),
		transparency = 1,
		parent = screenGui,
	})

	UILib.listLayout({
		padding = 6,
		vAlign = Enum.VerticalAlignment.Top,
		parent = toastContainer,
	})
end

-- ============================================================
-- TOAST NOTIFICATIONS
-- ============================================================

function Notifications.toast(message: string, icon: string?, duration: number?, color: Color3?)
	-- Remove oldest if at max
	if #activeToasts >= MAX_TOASTS then
		local oldest = table.remove(activeToasts, 1)
		if oldest then
			oldest:Destroy()
		end
	end

	local toast = UILib.frame({
		name = "Toast",
		size = UDim2.new(1, 0, 0, 40),
		color = color or UILib.Colors.BgDark,
		cornerRadius = UILib.Sizes.CornerRadiusSmall,
		parent = toastContainer,
	})
	toast.BackgroundTransparency = 0.15

	local displayIcon = icon or "ℹ️"
	UILib.textLabel({
		text = `{displayIcon} {message}`,
		size = UDim2.new(1, -16, 1, 0),
		position = UDim2.fromOffset(8, 0),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.TextLight,
		wrapped = true,
		parent = toast,
	})

	table.insert(activeToasts, toast)

	-- Slide in from right
	local targetPos = toast.Position
	toast.Position = targetPos + UDim2.fromOffset(200, 0)
	UILib.tween(toast, { Position = targetPos })

	-- Auto-dismiss
	task.delay(duration or 3, function()
		if toast.Parent then
			UILib.tween(toast, { Position = toast.Position + UDim2.fromOffset(200, 0) })
			task.delay(0.3, function()
				local idx = table.find(activeToasts, toast)
				if idx then
					table.remove(activeToasts, idx)
				end
				toast:Destroy()
			end)
		end
	end)
end

function Notifications.success(message: string)
	Notifications.toast(message, "✅", 3, UILib.Colors.Success)
end

function Notifications.warning(message: string)
	Notifications.toast(message, "⚠️", 4, UILib.Colors.Warning)
end

function Notifications.error(message: string)
	Notifications.toast(message, "❌", 5, UILib.Colors.Error)
end

function Notifications.info(message: string)
	Notifications.toast(message, "ℹ️", 3, UILib.Colors.Info)
end

-- ============================================================
-- FULL-SCREEN POPUPS
-- ============================================================

local function createPopup(title: string, content: Frame, onClose: (() -> ())?): Frame
	local overlay = UILib.overlay({
		name = "PopupOverlay",
		onClose = onClose,
		parent = screenGui,
	})

	local card = UILib.frame({
		name = "PopupCard",
		size = UDim2.new(0.85, 0, 0, 360),
		position = UDim2.fromScale(0.5, 0.45),
		anchor = Vector2.new(0.5, 0.5),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadiusLarge,
		zIndex = 51,
		parent = overlay,
	})

	-- Close button
	UILib.textButton({
		name = "Close",
		text = "✕",
		size = UDim2.fromOffset(36, 36),
		position = UDim2.new(1, -8, 0, 8),
		anchor = Vector2.new(1, 0),
		bgColor = UILib.Colors.Error,
		textColor = UILib.Colors.TextLight,
		textSize = 18,
		cornerRadius = 18,
		zIndex = 52,
		parent = card,
		onClick = function()
			overlay:Destroy()
			if onClose then
				onClose()
			end
		end,
	})

	-- Title
	UILib.textLabel({
		name = "Title",
		text = title,
		size = UDim2.new(1, -60, 0, 36),
		position = UDim2.fromOffset(12, 12),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		zIndex = 51,
		parent = card,
	})

	content.Position = UDim2.fromOffset(0, 52)
	content.Size = UDim2.new(1, 0, 1, -52)
	content.ZIndex = 51
	content.Parent = card

	return overlay
end

-- ============================================================
-- DAILY REWARD POPUP
-- ============================================================

function Notifications.showDailyReward(day: number, reward: any)
	local content = UILib.frame({
		name = "DailyContent",
		transparency = 1,
	})

	-- Calendar strip (7 days)
	local strip = UILib.frame({
		name = "Strip",
		size = UDim2.new(1, -16, 0, 80),
		position = UDim2.fromOffset(8, 8),
		transparency = 1,
		parent = content,
	})

	UILib.listLayout({
		fillDirection = Enum.FillDirection.Horizontal,
		padding = 4,
		hAlign = Enum.HorizontalAlignment.Center,
		parent = strip,
	})

	for i = 1, 7 do
		local dayReward = Constants.LOGIN_STREAK_REWARDS[i]
		local isToday = i == day
		local isPast = i < day

		local dayCard = UILib.frame({
			name = `Day{i}`,
			size = UDim2.fromOffset(42, 72),
			color = if isToday
				then UILib.Colors.Primary
				elseif isPast then UILib.Colors.Success
				else UILib.Colors.BgLight,
			cornerRadius = 8,
			parent = strip,
		})
		dayCard.LayoutOrder = i

		UILib.textLabel({
			text = `D{i}`,
			size = UDim2.new(1, 0, 0, 18),
			position = UDim2.fromOffset(0, 4),
			font = UILib.Fonts.Caption,
			textSize = UILib.Sizes.TextSmall,
			textColor = if isToday or isPast then UILib.Colors.TextLight else UILib.Colors.TextMuted,
			xAlign = Enum.TextXAlignment.Center,
			parent = dayCard,
		})

		UILib.textLabel({
			text = if isPast then "✓" elseif i == 7 then "🎁" else "💰",
			size = UDim2.new(1, 0, 0, 22),
			position = UDim2.fromOffset(0, 24),
			textSize = 16,
			xAlign = Enum.TextXAlignment.Center,
			parent = dayCard,
		})

		UILib.textLabel({
			text = `{dayReward.sc}`,
			size = UDim2.new(1, 0, 0, 16),
			position = UDim2.fromOffset(0, 48),
			font = UILib.Fonts.Caption,
			textSize = 9,
			textColor = if isToday or isPast then UILib.Colors.TextLight else UILib.Colors.TextMuted,
			xAlign = Enum.TextXAlignment.Center,
			parent = dayCard,
		})
	end

	-- Today's reward
	UILib.textLabel({
		text = `🎉 Day {day} Reward!`,
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.fromOffset(0, 100),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.Primary,
		xAlign = Enum.TextXAlignment.Center,
		parent = content,
	})

	local rewardLines = {}
	if reward.sc > 0 then
		table.insert(rewardLines, `💰 +{Utils.formatNumber(reward.sc)} StyleCoins`)
	end
	if reward.gg > 0 then
		table.insert(rewardLines, `💎 +{reward.gg} GlamGems`)
	end
	if reward.item then
		table.insert(rewardLines, `🎁 Bonus: Random Rare Item!`)
	end

	UILib.textLabel({
		text = table.concat(rewardLines, "\n"),
		size = UDim2.new(0.8, 0, 0, 60),
		position = UDim2.new(0.1, 0, 0, 140),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		wrapped = true,
		parent = content,
	})

	-- Claim button
	local popup: Frame? = nil
	UILib.textButton({
		name = "ClaimBtn",
		text = "🎉 Claim Reward!",
		size = UDim2.new(0.7, 0, 0, 48),
		position = UDim2.new(0.15, 0, 1, -20),
		anchor = Vector2.new(0, 1),
		bgColor = UILib.Colors.Secondary,
		textColor = UILib.Colors.BgDark,
		parent = content,
		onClick = function()
			if popup then
				popup:Destroy()
			end
			Notifications.success(`Day {day} reward claimed!`)
		end,
	})

	popup = createPopup("📅 Daily Login Reward", content)
end

-- ============================================================
-- LEVEL UP POPUP
-- ============================================================

function Notifications.showLevelUp(newLevel: number)
	Notifications.toast(`🎉 LEVEL UP! You're now Level {newLevel}!`, "🌟", 5, UILib.Colors.Accent)
end

-- ============================================================
-- PRESTIGE POPUP
-- ============================================================

function Notifications.showPrestige(count: number)
	local content = UILib.frame({
		name = "PrestigeContent",
		transparency = 1,
	})

	UILib.textLabel({
		text = "✨",
		size = UDim2.new(1, 0, 0, 60),
		position = UDim2.fromOffset(0, 10),
		textSize = 48,
		xAlign = Enum.TextXAlignment.Center,
		parent = content,
	})

	local multi = Constants.PRESTIGE_MULTIPLIERS[count] or 1
	UILib.textLabel({
		text = `Prestige {count}`,
		size = UDim2.new(1, 0, 0, 36),
		position = UDim2.fromOffset(0, 75),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextTitle,
		textColor = UILib.Colors.Secondary,
		xAlign = Enum.TextXAlignment.Center,
		parent = content,
	})

	UILib.textLabel({
		text = `Earnings multiplier: {multi}x\nYour items and GlamGems are kept!\nLevel and boutique have been reset.`,
		size = UDim2.new(0.85, 0, 0, 80),
		position = UDim2.new(0.075, 0, 0, 120),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextSecondary,
		xAlign = Enum.TextXAlignment.Center,
		wrapped = true,
		parent = content,
	})

	createPopup("🌟 PRESTIGE!", content)
end

-- ============================================================
-- LUCKY BOX POPUP
-- ============================================================

function Notifications.showLuckyBox(data: any)
	local rarityColor = UILib.RarityColors[data.rarity] or UILib.Colors.Common
	local rarityName = UILib.RarityNames[data.rarity] or "?"

	local content = UILib.frame({
		name = "LuckyContent",
		transparency = 1,
	})

	UILib.textLabel({
		text = "🎰",
		size = UDim2.new(1, 0, 0, 60),
		position = UDim2.fromOffset(0, 10),
		textSize = 48,
		xAlign = Enum.TextXAlignment.Center,
		parent = content,
	})

	UILib.textLabel({
		text = data.itemName or "Mystery Item",
		size = UDim2.new(0.85, 0, 0, 36),
		position = UDim2.new(0.075, 0, 0, 80),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextHeading,
		textColor = rarityColor,
		xAlign = Enum.TextXAlignment.Center,
		parent = content,
	})

	UILib.textLabel({
		text = `{rarityName} Item`,
		size = UDim2.new(1, 0, 0, 24),
		position = UDim2.fromOffset(0, 120),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextBody,
		textColor = rarityColor,
		xAlign = Enum.TextXAlignment.Center,
		parent = content,
	})

	createPopup("🎰 Lucky Box!", content)
end

-- ============================================================
-- OFFLINE EARNINGS POPUP
-- ============================================================

function Notifications.showOfflineEarnings(earnings: number, hours: number)
	Notifications.toast(
		`Welcome back! +{Utils.formatNumber(earnings)} SC earned offline ({string.format("%.1f", hours)}h)`,
		"🌙",
		5,
		UILib.Colors.Accent
	)
end

-- ============================================================
-- CUSTOMER SERVED FEEDBACK
-- ============================================================

function Notifications.showCustomerServed(stars: number, payment: number)
	local starText = string.rep("⭐", stars)
	local color = if stars >= 4
		then UILib.Colors.Success
		elseif stars >= 2 then UILib.Colors.Warning
		else UILib.Colors.Error
	Notifications.toast(`{starText} +{Utils.formatNumber(payment)} SC`, nil, 3, color)
end

return Notifications
