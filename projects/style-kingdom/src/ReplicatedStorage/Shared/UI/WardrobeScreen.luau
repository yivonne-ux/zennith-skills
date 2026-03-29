--!strict
-- Style Kingdom — WardrobeScreen
-- Equip items to outfit slots, save/load outfits, preview character

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemCatalog = require(script.Parent.Parent.ItemCatalog)
local UILib = require(script.Parent.UILib)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local functions = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Functions")

local WardrobeScreen = {}

local screenGui: ScreenGui
local slotsPanel: Frame
local itemGrid: ScrollingFrame
local outfitBar: ScrollingFrame

local playerData: any = nil
local currentOutfit: { [string]: string? } = {
	top = nil,
	bottom = nil,
	dress = nil,
	shoes = nil,
	accessory1 = nil,
	accessory2 = nil,
	hair = nil,
	headwear = nil,
	bag = nil,
	name = "My Outfit",
}
local selectedSlot: string = "top"

local SLOT_CONFIG = {
	{ id = "top", label = "Top", icon = "👕", order = 1 },
	{ id = "bottom", label = "Bottom", icon = "👖", order = 2 },
	{ id = "dress", label = "Dress", icon = "👗", order = 3 },
	{ id = "shoes", label = "Shoes", icon = "👟", order = 4 },
	{ id = "accessory1", label = "Acc. 1", icon = "💍", order = 5 },
	{ id = "accessory2", label = "Acc. 2", icon = "📿", order = 6 },
	{ id = "hair", label = "Hair", icon = "💇", order = 7 },
	{ id = "headwear", label = "Hat", icon = "🎩", order = 8 },
	{ id = "bag", label = "Bag", icon = "👜", order = 9 },
}

-- Map slot id to accepted item categories
local SLOT_CATEGORIES: { [string]: { string } } = {
	top = { "Top" },
	bottom = { "Bottom" },
	dress = { "Dress" },
	shoes = { "Shoes" },
	accessory1 = { "Accessory" },
	accessory2 = { "Accessory" },
	hair = { "Hair" },
	headwear = { "Headwear" },
	bag = { "Bag" },
}

function WardrobeScreen.init()
	screenGui = UILib.screenGui("WardrobeScreen")
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

	-- ============================================================
	-- HEADER
	-- ============================================================
	UILib.textLabel({
		name = "Title",
		text = "👗 Wardrobe",
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
	-- OUTFIT SLOT SELECTOR (horizontal scroll of 9 equipment slots)
	-- ============================================================
	slotsPanel = UILib.frame({
		name = "SlotsPanel",
		size = UDim2.new(1, 0, 0, 80),
		position = UDim2.fromOffset(0, 40),
		color = UILib.Colors.BgCard,
		parent = container,
	})

	local slotsScroll = UILib.scrollFrame({
		name = "SlotsScroll",
		size = UDim2.new(1, -8, 1, -8),
		position = UDim2.fromOffset(4, 4),
		direction = Enum.ScrollingDirection.X,
		parent = slotsPanel,
	})
	slotsScroll.AutomaticCanvasSize = Enum.AutomaticSize.X

	UILib.listLayout({
		fillDirection = Enum.FillDirection.Horizontal,
		padding = 6,
		parent = slotsScroll,
	})

	for _, slotCfg in SLOT_CONFIG do
		local slotBtn = Instance.new("TextButton")
		slotBtn.Name = slotCfg.id
		slotBtn.Size = UDim2.fromOffset(64, 68)
		slotBtn.BackgroundColor3 = if slotCfg.id == selectedSlot then UILib.Colors.Primary else UILib.Colors.BgLight
		slotBtn.BorderSizePixel = 0
		slotBtn.Text = ""
		slotBtn.LayoutOrder = slotCfg.order
		slotBtn.AutoButtonColor = false
		slotBtn.Parent = slotsScroll

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = slotBtn

		-- Slot icon
		UILib.textLabel({
			name = "Icon",
			text = slotCfg.icon,
			size = UDim2.new(1, 0, 0, 36),
			position = UDim2.fromOffset(0, 4),
			textSize = 24,
			xAlign = Enum.TextXAlignment.Center,
			parent = slotBtn,
		})

		-- Slot label
		UILib.textLabel({
			name = "Label",
			text = slotCfg.label,
			size = UDim2.new(1, 0, 0, 16),
			position = UDim2.fromOffset(0, 42),
			font = UILib.Fonts.Caption,
			textSize = UILib.Sizes.TextSmall,
			textColor = if slotCfg.id == selectedSlot then UILib.Colors.TextLight else UILib.Colors.TextSecondary,
			xAlign = Enum.TextXAlignment.Center,
			parent = slotBtn,
		})

		-- Equipped item indicator
		UILib.textLabel({
			name = "Equipped",
			text = "",
			size = UDim2.new(1, 0, 0, 12),
			position = UDim2.fromOffset(0, 56),
			font = UILib.Fonts.Caption,
			textSize = 8,
			textColor = UILib.Colors.Secondary,
			xAlign = Enum.TextXAlignment.Center,
			parent = slotBtn,
		})

		slotBtn.MouseButton1Click:Connect(function()
			WardrobeScreen.selectSlot(slotCfg.id)
		end)
	end

	-- ============================================================
	-- ITEM GRID: owned items that fit selected slot
	-- ============================================================
	itemGrid = UILib.scrollFrame({
		name = "ItemGrid",
		size = UDim2.new(1, 0, 1, -178), -- header + slots + outfit bar
		position = UDim2.fromOffset(0, 120),
		padding = 8,
		parent = container,
	})

	UILib.gridLayout({
		cellSize = UDim2.fromOffset(100, 130),
		padding = UDim2.fromOffset(8, 8),
		parent = itemGrid,
	})

	-- ============================================================
	-- OUTFIT ACTION BAR (bottom)
	-- ============================================================
	outfitBar = UILib.frame({
		name = "OutfitBar",
		size = UDim2.new(1, 0, 0, 56),
		position = UDim2.new(0, 0, 1, 0),
		anchor = Vector2.new(0, 1),
		color = UILib.Colors.BgCard,
		parent = container,
	})

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 8)
	pad.Parent = outfitBar

	UILib.listLayout({
		fillDirection = Enum.FillDirection.Horizontal,
		padding = 8,
		hAlign = Enum.HorizontalAlignment.Center,
		parent = outfitBar,
	})

	-- Equip button
	UILib.textButton({
		name = "EquipBtn",
		text = "✓ Apply Outfit",
		size = UDim2.fromOffset(130, 40),
		bgColor = UILib.Colors.Primary,
		textSize = UILib.Sizes.TextCaption,
		parent = outfitBar,
		onClick = function()
			WardrobeScreen.applyOutfit()
		end,
	})

	-- Save button
	UILib.textButton({
		name = "SaveBtn",
		text = "💾 Save",
		size = UDim2.fromOffset(80, 40),
		bgColor = UILib.Colors.Accent,
		textSize = UILib.Sizes.TextCaption,
		parent = outfitBar,
		onClick = function()
			WardrobeScreen.saveOutfit()
		end,
	})

	-- Clear button
	UILib.textButton({
		name = "ClearBtn",
		text = "🗑 Clear",
		size = UDim2.fromOffset(80, 40),
		bgColor = UILib.Colors.Error,
		textSize = UILib.Sizes.TextCaption,
		parent = outfitBar,
		onClick = function()
			WardrobeScreen.clearOutfit()
		end,
	})
end

-- ============================================================
-- SLOT SELECTION
-- ============================================================

function WardrobeScreen.selectSlot(slotId: string)
	selectedSlot = slotId

	-- Update slot button visuals
	local slotsScroll = slotsPanel:FindFirstChild("SlotsScroll")
	if slotsScroll then
		for _, btn in slotsScroll:GetChildren() do
			if btn:IsA("TextButton") then
				local isActive = btn.Name == slotId
				btn.BackgroundColor3 = if isActive then UILib.Colors.Primary else UILib.Colors.BgLight
				local label = btn:FindFirstChild("Label") :: TextLabel?
				if label then
					label.TextColor3 = if isActive then UILib.Colors.TextLight else UILib.Colors.TextSecondary
				end
			end
		end
	end

	WardrobeScreen.refreshItems()
end

-- ============================================================
-- ITEM DISPLAY
-- ============================================================

function WardrobeScreen.refreshItems()
	-- Clear grid
	for _, child in itemGrid:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if not playerData then
		return
	end

	local acceptedCategories = SLOT_CATEGORIES[selectedSlot] or {}
	local ownedItems = playerData.ownedItems or {}
	local equippedItemId = currentOutfit[selectedSlot]

	-- "Unequip" card first
	local unequipCard = UILib.frame({
		name = "_unequip",
		size = UDim2.fromOffset(100, 130),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadiusSmall,
		parent = itemGrid,
	})
	unequipCard.LayoutOrder = 0

	local stroke = Instance.new("UIStroke")
	stroke.Color = if equippedItemId == nil then UILib.Colors.Error else UILib.Colors.TextMuted
	stroke.Thickness = if equippedItemId == nil then 2 else 1
	stroke.Transparency = 0.3
	stroke.Parent = unequipCard

	UILib.textLabel({
		text = "🚫",
		size = UDim2.new(1, 0, 0, 70),
		textSize = 32,
		xAlign = Enum.TextXAlignment.Center,
		parent = unequipCard,
	})
	UILib.textLabel({
		text = "Unequip",
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 75),
		font = UILib.Fonts.Caption,
		textSize = UILib.Sizes.TextCaption,
		textColor = UILib.Colors.TextSecondary,
		xAlign = Enum.TextXAlignment.Center,
		parent = unequipCard,
	})

	local unequipBtn = Instance.new("TextButton")
	unequipBtn.Size = UDim2.fromScale(1, 1)
	unequipBtn.BackgroundTransparency = 1
	unequipBtn.Text = ""
	unequipBtn.ZIndex = 10
	unequipBtn.Parent = unequipCard
	unequipBtn.MouseButton1Click:Connect(function()
		currentOutfit[selectedSlot] = nil
		WardrobeScreen.refreshItems()
		WardrobeScreen.updateSlotIndicators()
	end)

	-- Show owned items that fit this slot
	local order = 1
	for itemId, isOwned in ownedItems do
		if not isOwned then
			continue
		end

		local item = ItemCatalog.ById[itemId]
		if not item then
			continue
		end

		-- Check if this item fits the selected slot
		local fits = false
		for _, cat in acceptedCategories do
			if item.category == cat then
				fits = true
				break
			end
		end
		if not fits then
			continue
		end

		order += 1
		local isEquipped = equippedItemId == itemId

		local card = UILib.itemCard({
			item = item,
			owned = true,
			equipped = isEquipped,
			onClick = function()
				currentOutfit[selectedSlot] = itemId
				WardrobeScreen.refreshItems()
				WardrobeScreen.updateSlotIndicators()
			end,
			parent = itemGrid,
		})
		card.LayoutOrder = order
	end
end

function WardrobeScreen.updateSlotIndicators()
	local slotsScroll = slotsPanel:FindFirstChild("SlotsScroll")
	if not slotsScroll then
		return
	end

	for _, btn in slotsScroll:GetChildren() do
		if btn:IsA("TextButton") then
			local equippedLabel = btn:FindFirstChild("Equipped") :: TextLabel?
			if equippedLabel then
				local itemId = currentOutfit[btn.Name]
				if itemId then
					local item = ItemCatalog.ById[itemId]
					equippedLabel.Text = if item then item.name else ""
				else
					equippedLabel.Text = ""
				end
			end
		end
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
-- OUTFIT ACTIONS
-- ============================================================

function WardrobeScreen.applyOutfit()
	local equipFunc = functions:FindFirstChild("EquipOutfit") :: RemoteFunction?
	if equipFunc then
		local outfitToSend = {
			top = currentOutfit.top or "",
			bottom = currentOutfit.bottom or "",
			dress = currentOutfit.dress or "",
			shoes = currentOutfit.shoes or "",
			accessory1 = currentOutfit.accessory1 or "",
			accessory2 = currentOutfit.accessory2 or "",
			hair = currentOutfit.hair or "",
			headwear = currentOutfit.headwear or "",
			bag = currentOutfit.bag or "",
			name = currentOutfit.name or "My Outfit",
		}
		local success, msg = equipFunc:InvokeServer(outfitToSend)
		if not success then
			reportError(msg or "Equip failed")
		end
	end
end

function WardrobeScreen.saveOutfit()
	local saveFunc = functions:FindFirstChild("SaveOutfit") :: RemoteFunction?
	if saveFunc then
		local outfitToSave = {
			top = currentOutfit.top or "",
			bottom = currentOutfit.bottom or "",
			dress = currentOutfit.dress or "",
			shoes = currentOutfit.shoes or "",
			accessory1 = currentOutfit.accessory1 or "",
			accessory2 = currentOutfit.accessory2 or "",
			hair = currentOutfit.hair or "",
			headwear = currentOutfit.headwear or "",
			bag = currentOutfit.bag or "",
			name = currentOutfit.name or "My Outfit",
		}
		-- Save to next available slot
		local slot = 1
		if playerData and playerData.savedOutfits then
			slot = #playerData.savedOutfits + 1
		end
		local success, msg = saveFunc:InvokeServer(outfitToSave, slot)
		if not success then
			reportError(msg or "Save failed")
		end
	end
end

function WardrobeScreen.clearOutfit()
	for key, _ in currentOutfit do
		if key ~= "name" then
			currentOutfit[key] = nil
		end
	end
	WardrobeScreen.refreshItems()
	WardrobeScreen.updateSlotIndicators()
end

-- ============================================================
-- SCREEN VISIBILITY
-- ============================================================

function WardrobeScreen.show()
	screenGui.Enabled = true
	-- Load current equipped outfit from player data
	if playerData and playerData.equippedOutfit then
		for key, val in playerData.equippedOutfit do
			currentOutfit[key] = if val ~= "" then val else nil
		end
	end
	WardrobeScreen.refreshItems()
	WardrobeScreen.updateSlotIndicators()
end

function WardrobeScreen.hide()
	screenGui.Enabled = false
end

function WardrobeScreen.updatePlayerData(data: any)
	playerData = data
end

return WardrobeScreen
