--!strict
-- Style Kingdom — BoutiqueScreen
-- Boutique overview: upgrade tiers, manage mannequins, view customers, stats

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(script.Parent.Parent.Constants)
local UILib = require(script.Parent.UILib)
local Utils = require(script.Parent.Parent.Utils)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local functions = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Functions")

local BoutiqueScreen = {}

local screenGui: ScreenGui
local statsPanel: Frame
local upgradePanel: Frame
local customerPanel: ScrollingFrame
local playerData: any = nil
local activeCustomers: { any } = {}

function BoutiqueScreen.init()
	screenGui = UILib.screenGui("BoutiqueScreen")
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
		text = "🏪 My Boutique",
		size = UDim2.new(1, 0, 0, 40),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		color = UILib.Colors.BgCard,
		transparency = 0,
		parent = container,
	})

	-- ============================================================
	-- STATS OVERVIEW
	-- ============================================================
	statsPanel = UILib.frame({
		name = "Stats",
		size = UDim2.new(1, -16, 0, 100),
		position = UDim2.new(0, 8, 0, 48),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadius,
		parent = container,
	})

	local statsPad = Instance.new("UIPadding")
	statsPad.PaddingLeft = UDim.new(0, 12)
	statsPad.PaddingRight = UDim.new(0, 12)
	statsPad.PaddingTop = UDim.new(0, 8)
	statsPad.Parent = statsPanel

	-- Boutique name + tier
	UILib.textLabel({
		name = "BoutiqueName",
		text = "Market Stall (Tier 1)",
		size = UDim2.new(1, 0, 0, 24),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.Primary,
		xAlign = Enum.TextXAlignment.Left,
		parent = statsPanel,
	})

	-- Stats row
	local statsRow = UILib.frame({
		name = "StatsRow",
		size = UDim2.new(1, 0, 0, 56),
		position = UDim2.fromOffset(0, 28),
		transparency = 1,
		parent = statsPanel,
	})

	UILib.listLayout({
		fillDirection = Enum.FillDirection.Horizontal,
		padding = 12,
		parent = statsRow,
	})

	local statItems = {
		{ label = "Customers", value = "0", icon = "👥" },
		{ label = "Mannequins", value = "1", icon = "🎭" },
		{ label = "Earnings/hr", value = "10", icon = "💰" },
		{ label = "Served", value = "0", icon = "⭐" },
	}

	for i, stat in statItems do
		local statCard = UILib.frame({
			name = `Stat_{stat.label}`,
			size = UDim2.fromOffset(75, 52),
			color = UILib.Colors.BgLight,
			cornerRadius = 8,
			parent = statsRow,
		})
		statCard.LayoutOrder = i

		UILib.textLabel({
			text = `{stat.icon} {stat.value}`,
			size = UDim2.new(1, 0, 0, 24),
			position = UDim2.fromOffset(0, 4),
			font = UILib.Fonts.Heading,
			textSize = UILib.Sizes.TextBody,
			textColor = UILib.Colors.TextPrimary,
			xAlign = Enum.TextXAlignment.Center,
			parent = statCard,
		})

		UILib.textLabel({
			name = "Label",
			text = stat.label,
			size = UDim2.new(1, 0, 0, 16),
			position = UDim2.fromOffset(0, 30),
			font = UILib.Fonts.Caption,
			textSize = UILib.Sizes.TextSmall,
			textColor = UILib.Colors.TextMuted,
			xAlign = Enum.TextXAlignment.Center,
			parent = statCard,
		})
	end

	-- ============================================================
	-- UPGRADE PANEL
	-- ============================================================
	upgradePanel = UILib.frame({
		name = "Upgrade",
		size = UDim2.new(1, -16, 0, 130),
		position = UDim2.new(0, 8, 0, 158),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadius,
		parent = container,
	})

	local upgradePad = Instance.new("UIPadding")
	upgradePad.PaddingLeft = UDim.new(0, 12)
	upgradePad.PaddingRight = UDim.new(0, 12)
	upgradePad.PaddingTop = UDim.new(0, 8)
	upgradePad.Parent = upgradePanel

	UILib.textLabel({
		name = "UpgradeTitle",
		text = "📈 Next Upgrade",
		size = UDim2.new(1, 0, 0, 22),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextPrimary,
		parent = upgradePanel,
	})

	UILib.textLabel({
		name = "NextTierName",
		text = "Small Shop (Tier 2)",
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 26),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.Accent,
		parent = upgradePanel,
	})

	UILib.textLabel({
		name = "NextTierBenefits",
		text = "+1 Customer Slot • +1 Mannequin • 25 SC/hr",
		size = UDim2.new(1, 0, 0, 18),
		position = UDim2.fromOffset(0, 48),
		font = UILib.Fonts.Caption,
		textSize = UILib.Sizes.TextSmall,
		textColor = UILib.Colors.TextSecondary,
		parent = upgradePanel,
	})

	-- Upgrade button
	UILib.textButton({
		name = "UpgradeBtn",
		text = "💰 Upgrade — 500 SC",
		size = UDim2.new(1, 0, 0, 44),
		position = UDim2.fromOffset(0, 72),
		bgColor = UILib.Colors.Secondary,
		textColor = UILib.Colors.BgDark,
		textSize = UILib.Sizes.TextBody,
		parent = upgradePanel,
		onClick = function()
			BoutiqueScreen.upgrade()
		end,
	})

	-- ============================================================
	-- ACTIVE CUSTOMERS PANEL
	-- ============================================================
	UILib.textLabel({
		name = "CustomersTitle",
		text = "👥 Waiting Customers",
		size = UDim2.new(1, -16, 0, 24),
		position = UDim2.new(0, 16, 0, 296),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextBody,
		textColor = UILib.Colors.TextPrimary,
		parent = container,
	})

	customerPanel = UILib.scrollFrame({
		name = "CustomerList",
		size = UDim2.new(1, -16, 1, -328),
		position = UDim2.new(0, 8, 0, 322),
		padding = 8,
		parent = container,
	})

	UILib.listLayout({
		padding = 8,
		parent = customerPanel,
	})
end

-- ============================================================
-- DATA UPDATES
-- ============================================================

function BoutiqueScreen.updateStats()
	if not playerData then
		return
	end

	local tier = playerData.boutique.tier
	local tierData = Constants.BOUTIQUE_TIERS[tier]
	if not tierData then
		return
	end

	-- Update boutique name
	local nameLabel = statsPanel:FindFirstChild("BoutiqueName") :: TextLabel?
	if nameLabel then
		nameLabel.Text = `{tierData.name} (Tier {tier})`
	end

	-- Update stats
	local statsRow = statsPanel:FindFirstChild("StatsRow") :: Frame?
	if statsRow then
		local custStat = statsRow:FindFirstChild("Stat_Customers")
		if custStat then
			local val = custStat:FindFirstChildWhichIsA("TextLabel") :: TextLabel?
			if val then
				val.Text = `👥 {#activeCustomers}/{tierData.customerCap}`
			end
		end

		local mannStat = statsRow:FindFirstChild("Stat_Mannequins")
		if mannStat then
			local val = mannStat:FindFirstChildWhichIsA("TextLabel") :: TextLabel?
			if val then
				val.Text = `🎭 {tierData.mannequins}`
			end
		end

		local earnStat = statsRow:FindFirstChild("Stat_Earnings/hr")
		if earnStat then
			local val = earnStat:FindFirstChildWhichIsA("TextLabel") :: TextLabel?
			if val then
				val.Text = `💰 {tierData.earningRate}`
			end
		end

		local servStat = statsRow:FindFirstChild("Stat_Served")
		if servStat then
			local val = servStat:FindFirstChildWhichIsA("TextLabel") :: TextLabel?
			if val then
				val.Text = `⭐ {playerData.customersServed or 0}`
			end
		end
	end

	-- Update upgrade panel
	local nextTier = tier + 1
	if nextTier <= Constants.MAX_BOUTIQUE_TIER then
		local nextData = Constants.BOUTIQUE_TIERS[nextTier]
		upgradePanel.Visible = true

		local nextName = upgradePanel:FindFirstChild("NextTierName") :: TextLabel?
		if nextName then
			nextName.Text = `{nextData.name} (Tier {nextTier})`
		end

		local nextBenefits = upgradePanel:FindFirstChild("NextTierBenefits") :: TextLabel?
		if nextBenefits then
			nextBenefits.Text =
				`+{nextData.customerCap - tierData.customerCap} Customers • {nextData.mannequins} Mannequins • {nextData.earningRate} SC/hr`
		end

		local upgradeBtn = upgradePanel:FindFirstChild("UpgradeBtn") :: TextButton?
		if upgradeBtn then
			upgradeBtn.Text = `💰 Upgrade — {Utils.formatNumber(nextData.cost)} SC`
			local canAfford = playerData.styleCoins >= nextData.cost
			upgradeBtn.BackgroundColor3 = if canAfford then UILib.Colors.Secondary else UILib.Colors.TextMuted
		end
	else
		upgradePanel.Visible = false
	end
end

-- ============================================================
-- CUSTOMER MANAGEMENT
-- ============================================================

function BoutiqueScreen.addCustomer(npcInfo: any)
	table.insert(activeCustomers, npcInfo)
	BoutiqueScreen.refreshCustomerList()
end

function BoutiqueScreen.removeCustomer(npcIndex: number)
	if npcIndex >= 1 and npcIndex <= #activeCustomers then
		table.remove(activeCustomers, npcIndex)
	end
	BoutiqueScreen.refreshCustomerList()
end

function BoutiqueScreen.refreshCustomerList()
	-- Clear existing
	for _, child in customerPanel:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if #activeCustomers == 0 then
		UILib.textLabel({
			name = "Empty",
			text = "No customers waiting...\nKeep your boutique stocked and they'll come!",
			size = UDim2.new(1, 0, 0, 60),
			font = UILib.Fonts.Body,
			textSize = UILib.Sizes.TextCaption,
			textColor = UILib.Colors.TextMuted,
			xAlign = Enum.TextXAlignment.Center,
			wrapped = true,
			parent = customerPanel,
		})
		return
	end

	for i, npc in activeCustomers do
		local card = UILib.frame({
			name = `Customer_{i}`,
			size = UDim2.new(1, 0, 0, 70),
			color = UILib.Colors.BgCard,
			cornerRadius = UILib.Sizes.CornerRadiusSmall,
			parent = customerPanel,
		})
		card.LayoutOrder = i

		-- NPC name + preference
		UILib.textLabel({
			text = `{npc.name}`,
			size = UDim2.new(0.5, 0, 0, 22),
			position = UDim2.fromOffset(10, 8),
			font = UILib.Fonts.Heading,
			textSize = UILib.Sizes.TextCaption,
			textColor = UILib.Colors.TextPrimary,
			parent = card,
		})

		local styleIcons = { KFashion = "🇰🇷", JFashion = "🇯🇵", SEA = "🌺", Formal = "✨" }
		UILib.textLabel({
			text = `Wants: {styleIcons[npc.preferredStyle] or ""} {npc.preferredStyle}`,
			size = UDim2.new(0.6, 0, 0, 18),
			position = UDim2.fromOffset(10, 30),
			font = UILib.Fonts.Caption,
			textSize = UILib.Sizes.TextSmall,
			textColor = UILib.Colors.TextSecondary,
			parent = card,
		})

		-- Serve button
		UILib.textButton({
			name = "ServeBtn",
			text = "👗 Serve",
			size = UDim2.fromOffset(80, 36),
			position = UDim2.new(1, -10, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			bgColor = UILib.Colors.Primary,
			textSize = UILib.Sizes.TextCaption,
			parent = card,
			onClick = function()
				BoutiqueScreen.serveCustomer(i)
			end,
		})
	end

	BoutiqueScreen.updateStats()
end

-- ============================================================
-- SERVER ACTIONS
-- ============================================================

-- Error reporting via BindableEvent (Notifications listens)
local function reportError(msg: string)
	local errorEvent = ReplicatedStorage:FindFirstChild("UIError") :: BindableEvent?
	if errorEvent then
		errorEvent:Fire(msg)
	end
end

function BoutiqueScreen.upgrade()
	local expandFunc = functions:FindFirstChild("ExpandBoutique") :: RemoteFunction?
	if expandFunc then
		local success, msg = expandFunc:InvokeServer()
		if not success then
			reportError(msg or "Upgrade failed")
		end
	end
end

function BoutiqueScreen.serveCustomer(npcIndex: number)
	local serveFunc = functions:FindFirstChild("ServeCustomer") :: RemoteFunction?
	if serveFunc then
		local success, msg = serveFunc:InvokeServer(npcIndex)
		if not success then
			reportError(msg or "Serve failed")
		end
		-- Data updated via CustomerServed event
	end
end

-- ============================================================
-- SCREEN VISIBILITY
-- ============================================================

function BoutiqueScreen.show()
	screenGui.Enabled = true
	BoutiqueScreen.updateStats()
	BoutiqueScreen.refreshCustomerList()
end

function BoutiqueScreen.hide()
	screenGui.Enabled = false
end

function BoutiqueScreen.updatePlayerData(data: any)
	playerData = data
	if screenGui.Enabled then
		BoutiqueScreen.updateStats()
	end
end

return BoutiqueScreen
