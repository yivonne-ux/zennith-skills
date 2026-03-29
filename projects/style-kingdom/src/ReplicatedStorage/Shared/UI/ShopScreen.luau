--!strict
-- Style Kingdom — ShopScreen
-- Browse and purchase items, filterable by category/style/rarity

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemCatalog = require(script.Parent.Parent.ItemCatalog)
local UILib = require(script.Parent.UILib)
local Utils = require(script.Parent.Parent.Utils)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local functions = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Functions")

local ShopScreen = {}

local screenGui: ScreenGui
local contentScroll: ScrollingFrame
local filterBar: Frame
local detailPanel: Frame

local currentFilter: string = "All"
local currentStyleFilter: string = "All"
local playerData: any = nil

function ShopScreen.init()
	screenGui = UILib.screenGui("ShopScreen")
	screenGui.DisplayOrder = 20
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Main container (below HUD top bar, above nav bar)
	local container = UILib.frame({
		name = "Container",
		size = UDim2.new(1, 0, 1, -188), -- 90 top + 98 bottom (nav + safe area)
		position = UDim2.fromOffset(0, 90),
		color = UILib.Colors.BgLight,
		parent = screenGui,
	})

	-- ============================================================
	-- HEADER
	-- ============================================================
	local header = UILib.frame({
		name = "Header",
		size = UDim2.new(1, 0, 0, 44),
		color = UILib.Colors.BgCard,
		parent = container,
	})

	UILib.textLabel({
		name = "Title",
		text = "🛒 Fashion Shop",
		size = UDim2.fromScale(1, 1),
		font = UILib.Fonts.Title,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		parent = header,
	})

	-- ============================================================
	-- FILTER BAR: Category tabs
	-- ============================================================
	filterBar = UILib.frame({
		name = "FilterBar",
		size = UDim2.new(1, 0, 0, 100),
		position = UDim2.fromOffset(0, 44),
		color = UILib.Colors.BgCard,
		parent = container,
	})

	-- Category filter row
	local catScroll = UILib.scrollFrame({
		name = "CategoryScroll",
		size = UDim2.new(1, 0, 0, 48),
		position = UDim2.fromOffset(0, 2),
		direction = Enum.ScrollingDirection.X,
		canvasSize = UDim2.fromOffset(0, 0),
		parent = filterBar,
	})
	catScroll.AutomaticCanvasSize = Enum.AutomaticSize.X

	UILib.listLayout({
		fillDirection = Enum.FillDirection.Horizontal,
		padding = 6,
		parent = catScroll,
	})

	local categories = { "All", "Top", "Bottom", "Dress", "Shoes", "Accessory", "Headwear", "Bag" }
	for i, cat in categories do
		local btn = UILib.textButton({
			name = cat,
			text = cat,
			size = UDim2.fromOffset(76, 44),
			bgColor = if cat == "All" then UILib.Colors.Primary else UILib.Colors.BgLight,
			textColor = if cat == "All" then UILib.Colors.TextLight else UILib.Colors.TextSecondary,
			textSize = UILib.Sizes.TextCaption,
			cornerRadius = 15,
			parent = catScroll,
			onClick = function()
				ShopScreen.setFilter(cat, currentStyleFilter)
			end,
		})
		btn.LayoutOrder = i
	end

	-- Style filter row
	local styleScroll = UILib.scrollFrame({
		name = "StyleScroll",
		size = UDim2.new(1, 0, 0, 44),
		position = UDim2.fromOffset(0, 52),
		direction = Enum.ScrollingDirection.X,
		canvasSize = UDim2.fromOffset(0, 0),
		parent = filterBar,
	})
	styleScroll.AutomaticCanvasSize = Enum.AutomaticSize.X

	UILib.listLayout({
		fillDirection = Enum.FillDirection.Horizontal,
		padding = 6,
		parent = styleScroll,
	})

	local styleIcons = { All = "🌏", KFashion = "🇰🇷", JFashion = "🇯🇵", SEA = "🌺", Formal = "✨" }
	local styles = { "All", "KFashion", "JFashion", "SEA", "Formal" }
	for i, style in styles do
		local icon = styleIcons[style] or "✨"
		local displayName = if style == "KFashion"
			then "K-Fashion"
			elseif style == "JFashion" then "J-Fashion"
			else style
		local btn = UILib.textButton({
			name = style,
			text = `{icon} {displayName}`,
			size = UDim2.fromOffset(104, 40),
			bgColor = if style == "All" then UILib.Colors.Accent else UILib.Colors.BgLight,
			textColor = if style == "All" then UILib.Colors.TextLight else UILib.Colors.TextSecondary,
			textSize = UILib.Sizes.TextSmall,
			cornerRadius = 13,
			parent = styleScroll,
			onClick = function()
				ShopScreen.setFilter(currentFilter, style)
			end,
		})
		btn.LayoutOrder = i
	end

	-- ============================================================
	-- ITEM GRID (scrollable)
	-- ============================================================
	contentScroll = UILib.scrollFrame({
		name = "ItemGrid",
		size = UDim2.new(1, 0, 1, -144),
		position = UDim2.fromOffset(0, 144),
		padding = 8,
		parent = container,
	})

	UILib.gridLayout({
		cellSize = UDim2.fromOffset(110, 140),
		padding = UDim2.fromOffset(8, 8),
		parent = contentScroll,
	})

	-- ============================================================
	-- DETAIL PANEL (modal overlay)
	-- ============================================================
	detailPanel = UILib.frame({
		name = "DetailPanel",
		size = UDim2.fromScale(1, 1),
		color = UILib.Colors.BgOverlay,
		transparency = 0.4,
		zIndex = 50,
		parent = screenGui,
	})
	detailPanel.Visible = false

	local detailCard = UILib.frame({
		name = "DetailCard",
		size = UDim2.new(0.85, 0, 0, 380),
		position = UDim2.fromScale(0.5, 0.45),
		anchor = Vector2.new(0.5, 0.5),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadiusLarge,
		zIndex = 51,
		parent = detailPanel,
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
		parent = detailCard,
		onClick = function()
			detailPanel.Visible = false
		end,
	})
end

-- ============================================================
-- FILTERING
-- ============================================================

function ShopScreen.setFilter(category: string, style: string)
	currentFilter = category
	currentStyleFilter = style

	-- Update filter button highlights
	local catScroll = filterBar:FindFirstChild("CategoryScroll")
	if catScroll then
		for _, btn in catScroll:GetChildren() do
			if btn:IsA("TextButton") then
				local isActive = btn.Name == category
				btn.BackgroundColor3 = if isActive then UILib.Colors.Primary else UILib.Colors.BgLight
				btn.TextColor3 = if isActive then UILib.Colors.TextLight else UILib.Colors.TextSecondary
			end
		end
	end

	local styleScroll = filterBar:FindFirstChild("StyleScroll")
	if styleScroll then
		for _, btn in styleScroll:GetChildren() do
			if btn:IsA("TextButton") then
				local isActive = btn.Name == style
				btn.BackgroundColor3 = if isActive then UILib.Colors.Accent else UILib.Colors.BgLight
				btn.TextColor3 = if isActive then UILib.Colors.TextLight else UILib.Colors.TextSecondary
			end
		end
	end

	ShopScreen.refreshItems()
end

-- ============================================================
-- ITEM DISPLAY
-- ============================================================

function ShopScreen.refreshItems()
	-- Clear existing items
	for _, child in contentScroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Filter items
	local items = ItemCatalog.Items
	local ownedItems = if playerData then playerData.ownedItems else {}

	local order = 0
	for _, item in items do
		-- Category filter
		if currentFilter ~= "All" and item.category ~= currentFilter then
			continue
		end
		-- Style filter
		if currentStyleFilter ~= "All" and item.style ~= currentStyleFilter then
			continue
		end
		-- Skip event-only items not currently active
		if item.eventOnly then
			continue
		end

		order += 1
		local owned = ownedItems[item.id] == true

		local card = UILib.itemCard({
			item = item,
			owned = owned,
			onClick = function()
				ShopScreen.showDetail(item, owned)
			end,
			parent = contentScroll,
		})
		card.LayoutOrder = order
	end
end

-- ============================================================
-- ITEM DETAIL MODAL
-- ============================================================

function ShopScreen.showDetail(item: any, owned: boolean)
	-- Clear previous detail content
	local detailCard = detailPanel:FindFirstChild("DetailCard") :: Frame
	for _, child in detailCard:GetChildren() do
		if child.Name ~= "Close" and not child:IsA("UICorner") then
			child:Destroy()
		end
	end

	local rarityColor = UILib.RarityColors[item.rarity] or UILib.Colors.Common

	-- Item icon area
	local iconArea = UILib.frame({
		name = "IconArea",
		size = UDim2.new(1, 0, 0, 120),
		color = rarityColor,
		transparency = 0.8,
		parent = detailCard,
	})

	local categoryIcons = {
		Top = "👕",
		Bottom = "👖",
		Dress = "👗",
		Shoes = "👟",
		Accessory = "💍",
		Hair = "💇",
		Headwear = "🎩",
		Bag = "👜",
	}

	UILib.textLabel({
		text = categoryIcons[item.category] or "✨",
		size = UDim2.fromScale(1, 1),
		textSize = 56,
		xAlign = Enum.TextXAlignment.Center,
		parent = iconArea,
	})

	-- Rarity ribbon
	local rarityBadge = UILib.frame({
		name = "RarityBadge",
		size = UDim2.fromOffset(100, 24),
		position = UDim2.new(0.5, 0, 0, 124),
		anchor = Vector2.new(0.5, 0),
		color = rarityColor,
		cornerRadius = 12,
		zIndex = 52,
		parent = detailCard,
	})
	UILib.textLabel({
		text = `{UILib.RarityNames[item.rarity] or "?"} — Tier {item.tier}`,
		size = UDim2.fromScale(1, 1),
		font = UILib.Fonts.Caption,
		textSize = UILib.Sizes.TextSmall,
		textColor = UILib.Colors.TextLight,
		xAlign = Enum.TextXAlignment.Center,
		zIndex = 52,
		parent = rarityBadge,
	})

	-- Item name
	UILib.textLabel({
		name = "ItemName",
		text = item.name,
		size = UDim2.new(1, -24, 0, 28),
		position = UDim2.fromOffset(12, 155),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextHeading,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		parent = detailCard,
	})

	-- Flavor text
	UILib.textLabel({
		name = "FlavorText",
		text = item.flavorText,
		size = UDim2.new(1, -24, 0, 40),
		position = UDim2.fromOffset(12, 185),
		font = UILib.Fonts.Caption,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.TextSecondary,
		xAlign = Enum.TextXAlignment.Center,
		wrapped = true,
		parent = detailCard,
	})

	-- Tags
	local tagText = "Tags: " .. table.concat(item.tags, ", ")
	UILib.textLabel({
		name = "Tags",
		text = tagText,
		size = UDim2.new(1, -24, 0, 20),
		position = UDim2.fromOffset(12, 230),
		font = UILib.Fonts.Mono,
		textSize = UILib.Sizes.TextSmall,
		textColor = UILib.Colors.TextMuted,
		xAlign = Enum.TextXAlignment.Center,
		wrapped = true,
		parent = detailCard,
	})

	-- Style badge
	local styleNames = {
		KFashion = "🇰🇷 K-Fashion",
		JFashion = "🇯🇵 J-Fashion",
		SEA = "🌺 Southeast Asian",
		Formal = "✨ Formal",
	}
	UILib.textLabel({
		name = "Style",
		text = styleNames[item.style] or item.style,
		size = UDim2.new(1, -24, 0, 20),
		position = UDim2.fromOffset(12, 255),
		font = UILib.Fonts.Body,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.Accent,
		xAlign = Enum.TextXAlignment.Center,
		parent = detailCard,
	})

	-- Price / Purchase section
	local priceY = 290

	if owned then
		UILib.textLabel({
			name = "OwnedLabel",
			text = "✓ You own this item",
			size = UDim2.new(1, -24, 0, 30),
			position = UDim2.fromOffset(12, priceY),
			font = UILib.Fonts.Heading,
			textSize = UILib.Sizes.TextBody,
			textColor = UILib.Colors.Success,
			xAlign = Enum.TextXAlignment.Center,
			parent = detailCard,
		})

		UILib.textButton({
			name = "EquipBtn",
			text = "👗 Equip Now",
			size = UDim2.new(1, -48, 0, 44),
			position = UDim2.new(0, 24, 1, -16),
			anchor = Vector2.new(0, 1),
			bgColor = UILib.Colors.Accent,
			textSize = UILib.Sizes.TextBody,
			zIndex = 52,
			parent = detailCard,
			onClick = function()
				-- TODO: Switch to wardrobe with this item selected
				detailPanel.Visible = false
			end,
		})
	else
		-- SC price button
		UILib.textButton({
			name = "BuySC",
			text = `💰 Buy for {Utils.formatNumber(item.price)} SC`,
			size = UDim2.new(1, -48, 0, 44),
			position = UDim2.fromOffset(24, priceY),
			bgColor = UILib.Colors.Primary,
			textSize = UILib.Sizes.TextBody,
			zIndex = 52,
			parent = detailCard,
			onClick = function()
				ShopScreen.purchaseItem(item.id, "SC")
			end,
		})

		-- GG price button (if available)
		if item.premiumPrice then
			UILib.textButton({
				name = "BuyGG",
				text = `💎 Buy for {item.premiumPrice} GG`,
				size = UDim2.new(1, -48, 0, 38),
				position = UDim2.fromOffset(24, priceY + 50),
				bgColor = UILib.Colors.GlamGem,
				textSize = UILib.Sizes.TextCaption,
				zIndex = 52,
				parent = detailCard,
				onClick = function()
					ShopScreen.purchaseItem(item.id, "GG")
				end,
			})
		end
	end

	detailPanel.Visible = true
end

-- ============================================================
-- SERVER ACTIONS
-- ============================================================

function ShopScreen.purchaseItem(itemId: string, currency: string)
	local purchaseFunc = functions:FindFirstChild("PurchaseItem") :: RemoteFunction?
	if purchaseFunc then
		local success, msg = purchaseFunc:InvokeServer(itemId, currency)
		if success then
			-- Data will be updated via CurrencyUpdated + ItemPurchased events
			detailPanel.Visible = false
			ShopScreen.refreshItems()
		else
			warn(`[Shop] Purchase failed: {msg}`)
		end
	end
end

-- ============================================================
-- SCREEN VISIBILITY
-- ============================================================

function ShopScreen.show()
	screenGui.Enabled = true
	ShopScreen.refreshItems()
end

function ShopScreen.hide()
	screenGui.Enabled = false
	detailPanel.Visible = false
end

function ShopScreen.updatePlayerData(data: any)
	playerData = data
	if screenGui.Enabled then
		ShopScreen.refreshItems()
	end
end

return ShopScreen
