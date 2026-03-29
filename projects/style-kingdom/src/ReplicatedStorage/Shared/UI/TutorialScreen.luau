--!strict
-- Style Kingdom — TutorialScreen
-- First-time user experience (FTUE): guides new players through core mechanics

local Players = game:GetService("Players")

local UILib = require(script.Parent.UILib)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TutorialScreen = {}

local screenGui: ScreenGui
local currentStep: number = 0
local totalSteps: number = 0
local onCompleteCallback: (() -> ())? = nil

-- Tutorial steps: each has a title, description, icon, and optional highlight target
local TUTORIAL_STEPS = {
	{
		title = "Welcome to Style Kingdom!",
		desc = "Build your fashion empire, serve customers, and compete in runway contests!",
		icon = "👗",
		action = "Tap anywhere to continue",
	},
	{
		title = "Your Boutique",
		desc = "This is your fashion boutique. NPC customers will arrive looking for outfits. The better you style them, the more you earn!",
		icon = "🏪",
		action = "Tap the Boutique tab below",
		highlightTab = "boutique",
	},
	{
		title = "The Wardrobe",
		desc = "Equip items to your outfit here. Each item has tags like 'street', 'korean', 'formal'. Match tags to what customers want for higher stars!",
		icon = "👕",
		action = "Tap the Wardrobe tab",
		highlightTab = "wardrobe",
	},
	{
		title = "The Shop",
		desc = "Buy new fashion items with StyleCoins (💰). Filter by style — K-Fashion, J-Fashion, SEA, or Formal. Collect them all!",
		icon = "🛒",
		action = "Tap the Shop tab",
		highlightTab = "shop",
	},
	{
		title = "Fashion Contests",
		desc = "Every 15 minutes, a themed runway contest starts! Dress to match the theme, walk the runway, and vote for the best outfit. Top 3 win prizes!",
		icon = "🏆",
		action = "Tap the Contest tab",
		highlightTab = "contest",
	},
	{
		title = "Daily Challenges",
		desc = "Complete 3 daily challenges for bonus SC and GG. Finish all 3 for an extra 200 SC + 5 GG! Check your Profile tab.",
		icon = "📋",
		action = "Tap the Profile tab",
		highlightTab = "profile",
	},
	{
		title = "You're Ready!",
		desc = "Start by equipping an outfit in the Wardrobe, then serve your first customer in the Boutique. Good luck, stylist!",
		icon = "✨",
		action = "Tap to start playing!",
	},
}

function TutorialScreen.init()
	totalSteps = #TUTORIAL_STEPS

	screenGui = UILib.screenGui("Tutorial")
	screenGui.DisplayOrder = 500 -- Above everything
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Dark overlay
	UILib.frame({
		name = "Overlay",
		size = UDim2.fromScale(1, 1),
		color = UILib.Colors.BgOverlay,
		transparency = 0.5,
		zIndex = 100,
		parent = screenGui,
	})

	-- Tutorial card
	local card = UILib.frame({
		name = "Card",
		size = UDim2.new(0.88, 0, 0, 300),
		position = UDim2.new(0.5, 0, 0.4, 0),
		anchor = Vector2.new(0.5, 0.5),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadiusLarge,
		zIndex = 101,
		parent = screenGui,
	})

	-- Icon
	UILib.textLabel({
		name = "Icon",
		text = "👗",
		size = UDim2.new(1, 0, 0, 60),
		position = UDim2.fromOffset(0, 16),
		textSize = 48,
		xAlign = Enum.TextXAlignment.Center,
		zIndex = 101,
		parent = card,
	})

	-- Title
	UILib.textLabel({
		name = "Title",
		text = "Welcome!",
		size = UDim2.new(1, -24, 0, 32),
		position = UDim2.fromOffset(12, 80),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		zIndex = 101,
		parent = card,
	})

	-- Description
	UILib.textLabel({
		name = "Desc",
		text = "",
		size = UDim2.new(1, -32, 0, 80),
		position = UDim2.fromOffset(16, 118),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextSecondary,
		xAlign = Enum.TextXAlignment.Center,
		wrapped = true,
		zIndex = 101,
		parent = card,
	})

	-- Step counter
	UILib.textLabel({
		name = "Steps",
		text = "1 / 7",
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 210),
		font = UILib.Fonts.Caption,
		textSize = UILib.Sizes.TextSmall,
		textColor = UILib.Colors.TextMuted,
		xAlign = Enum.TextXAlignment.Center,
		zIndex = 101,
		parent = card,
	})

	-- Action button
	UILib.textButton({
		name = "ActionBtn",
		text = "Tap to continue →",
		size = UDim2.new(1, -32, 0, 48),
		position = UDim2.new(0.5, 0, 1, -16),
		anchor = Vector2.new(0.5, 1),
		bgColor = UILib.Colors.Primary,
		textSize = UILib.Sizes.TextBody,
		zIndex = 102,
		parent = card,
		onClick = function()
			TutorialScreen.nextStep()
		end,
	})

	-- Skip button
	UILib.textButton({
		name = "SkipBtn",
		text = "Skip Tutorial",
		size = UDim2.fromOffset(120, 36),
		position = UDim2.new(0.5, 0, 1, -60),
		anchor = Vector2.new(0.5, 1),
		bgColor = UILib.Colors.BgDark,
		textColor = UILib.Colors.TextMuted,
		textSize = UILib.Sizes.TextSmall,
		cornerRadius = 18,
		zIndex = 102,
		parent = screenGui,
		onClick = function()
			TutorialScreen.complete()
		end,
	})
end

function TutorialScreen.start(onComplete: (() -> ())?)
	onCompleteCallback = onComplete
	currentStep = 0
	screenGui.Enabled = true
	TutorialScreen.nextStep()
end

function TutorialScreen.nextStep()
	currentStep += 1

	if currentStep > totalSteps then
		TutorialScreen.complete()
		return
	end

	local step = TUTORIAL_STEPS[currentStep]
	local card = screenGui:FindFirstChild("Card") :: Frame?
	if not card then
		return
	end

	local icon = card:FindFirstChild("Icon") :: TextLabel?
	if icon then
		icon.Text = step.icon
	end

	local title = card:FindFirstChild("Title") :: TextLabel?
	if title then
		title.Text = step.title
	end

	local desc = card:FindFirstChild("Desc") :: TextLabel?
	if desc then
		desc.Text = step.desc
	end

	local steps = card:FindFirstChild("Steps") :: TextLabel?
	if steps then
		steps.Text = `{currentStep} / {totalSteps}`
	end

	local actionBtn = card:FindFirstChild("ActionBtn") :: TextButton?
	if actionBtn then
		actionBtn.Text = step.action .. " →"
	end
end

function TutorialScreen.complete()
	screenGui.Enabled = false
	if onCompleteCallback then
		onCompleteCallback()
	end
end

function TutorialScreen.isActive(): boolean
	return screenGui.Enabled
end

return TutorialScreen
