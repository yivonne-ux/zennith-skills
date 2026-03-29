--!strict
-- Style Kingdom — UILib
-- Reusable UI component factory with consistent styling
-- Mobile-first: large touch targets, readable fonts, thumb-friendly layout

local TweenService = game:GetService("TweenService")

local UILib = {}

-- ============================================================
-- DESIGN TOKENS
-- ============================================================
UILib.Colors = {
	-- Brand
	Primary = Color3.fromHex("#FF85A2"), -- Rose pink
	PrimaryDark = Color3.fromHex("#E0627E"),
	Secondary = Color3.fromHex("#FFD700"), -- Gold
	SecondaryDark = Color3.fromHex("#DAA520"),
	Accent = Color3.fromHex("#6B3FA0"), -- Deep purple

	-- Backgrounds
	BgLight = Color3.fromHex("#FFF0F3"), -- Soft pink (visible contrast vs white cards)
	BgDark = Color3.fromHex("#2D1B3D"), -- Deep plum
	BgCard = Color3.fromHex("#FFFFFF"),
	BgOverlay = Color3.fromHex("#000000"), -- Use with transparency

	-- Text
	TextPrimary = Color3.fromHex("#2D1B3D"),
	TextSecondary = Color3.fromHex("#6B5A7A"),
	TextLight = Color3.fromHex("#FFFFFF"),
	TextMuted = Color3.fromHex("#7A6B8A"), -- Darkened for WCAG AA contrast

	-- Feedback
	Success = Color3.fromHex("#2EAA6F"), -- Darkened for white text contrast (4.5:1+)
	Warning = Color3.fromHex("#FFB347"),
	Error = Color3.fromHex("#FF6B6B"),
	Info = Color3.fromHex("#87CEEB"),

	-- Rarity colors
	Common = Color3.fromHex("#B0B0B0"),
	Uncommon = Color3.fromHex("#7FDFBB"),
	Rare = Color3.fromHex("#5B9BFF"),
	Epic = Color3.fromHex("#C77DFF"),
	Legendary = Color3.fromHex("#FFD700"),

	-- Currency
	StyleCoin = Color3.fromHex("#FFD700"),
	GlamGem = Color3.fromHex("#E040FB"),
}

UILib.Fonts = {
	Title = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold),
	Heading = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	Body = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	Caption = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
	Mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium),
}

UILib.Sizes = {
	TextTitle = 28,
	TextHeading = 22,
	TextBody = 16,
	TextCaption = 13,
	TextSmall = 12, -- Minimum readable size on mobile
	CornerRadius = 12,
	CornerRadiusSmall = 8,
	CornerRadiusLarge = 16,
	Padding = 12,
	PaddingSmall = 8,
	PaddingLarge = 16,
	ButtonHeight = 48, -- Mobile-friendly touch target
	IconSize = 32,
	NavBarHeight = 64,
	NavBarSafeArea = 34, -- iPhone home indicator safe area
}

UILib.RarityColors = {
	[1] = UILib.Colors.Common,
	[2] = UILib.Colors.Uncommon,
	[3] = UILib.Colors.Rare,
	[4] = UILib.Colors.Epic,
	[5] = UILib.Colors.Legendary,
}

UILib.RarityNames = {
	[1] = "Common",
	[2] = "Uncommon",
	[3] = "Rare",
	[4] = "Epic",
	[5] = "Legendary",
}

-- ============================================================
-- ANIMATION HELPERS
-- ============================================================
local quickTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local smoothTween = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local bounceTween = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

function UILib.tween(instance: Instance, props: { [string]: any }, info: TweenInfo?)
	local tw = TweenService:Create(instance, info or smoothTween, props)
	tw:Play()
	return tw
end

function UILib.fadeIn(gui: GuiObject, duration: number?)
	gui.BackgroundTransparency = 1
	if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
		(gui :: TextLabel).TextTransparency = 1
	end
	gui.Visible = true
	local info = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	UILib.tween(gui, { BackgroundTransparency = 0 }, info)
	if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
		UILib.tween(gui :: TextLabel, { TextTransparency = 0 }, info)
	end
end

function UILib.fadeOut(gui: GuiObject, duration: number?)
	local info = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	UILib.tween(gui, { BackgroundTransparency = 1 }, info)
	if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
		UILib.tween(gui :: TextLabel, { TextTransparency = 1 }, info)
	end
	task.delay(duration or 0.2, function()
		gui.Visible = false
	end)
end

function UILib.popIn(gui: GuiObject)
	gui.Size = UDim2.fromScale(0, 0)
	gui.Visible = true
	UILib.tween(gui, { Size = gui:GetAttribute("TargetSize") or UDim2.fromScale(1, 1) }, bounceTween)
end

-- ============================================================
-- COMPONENT FACTORIES
-- ============================================================

function UILib.screenGui(name: string): ScreenGui
	local sg = Instance.new("ScreenGui")
	sg.Name = name
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 10
	return sg
end

function UILib.frame(props: {
	name: string?,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	color: Color3?,
	transparency: number?,
	parent: Instance?,
	cornerRadius: number?,
	zIndex: number?,
}): Frame
	local f = Instance.new("Frame")
	f.Name = props.name or "Frame"
	f.Size = props.size or UDim2.fromScale(1, 1)
	f.Position = props.position or UDim2.fromScale(0, 0)
	f.AnchorPoint = props.anchor or Vector2.new(0, 0)
	f.BackgroundColor3 = props.color or UILib.Colors.BgCard
	f.BackgroundTransparency = props.transparency or 0
	f.BorderSizePixel = 0
	f.ZIndex = props.zIndex or 1

	if props.cornerRadius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, props.cornerRadius)
		corner.Parent = f
	end

	if props.parent then
		f.Parent = props.parent
	end
	return f
end

function UILib.textLabel(props: {
	name: string?,
	text: string?,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	font: Font?,
	textSize: number?,
	color: Color3?,
	textColor: Color3?,
	xAlign: Enum.TextXAlignment?,
	yAlign: Enum.TextYAlignment?,
	parent: Instance?,
	transparency: number?,
	richText: boolean?,
	wrapped: boolean?,
	zIndex: number?,
}): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = props.name or "Label"
	t.Text = props.text or ""
	t.Size = props.size or UDim2.fromScale(1, 0)
	t.AutomaticSize = if props.size then Enum.AutomaticSize.None else Enum.AutomaticSize.Y
	t.Position = props.position or UDim2.fromScale(0, 0)
	t.AnchorPoint = props.anchor or Vector2.new(0, 0)
	t.FontFace = props.font or UILib.Fonts.Body
	t.TextSize = props.textSize or UILib.Sizes.TextBody
	t.BackgroundColor3 = props.color or Color3.new(1, 1, 1)
	t.BackgroundTransparency = props.transparency or 1
	t.TextColor3 = props.textColor or UILib.Colors.TextPrimary
	t.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
	t.TextYAlignment = props.yAlign or Enum.TextYAlignment.Center
	t.BorderSizePixel = 0
	t.RichText = props.richText or false
	t.TextWrapped = props.wrapped or false
	t.ZIndex = props.zIndex or 1

	if props.parent then
		t.Parent = props.parent
	end
	return t
end

function UILib.textButton(props: {
	name: string?,
	text: string?,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	font: Font?,
	textSize: number?,
	bgColor: Color3?,
	textColor: Color3?,
	cornerRadius: number?,
	parent: Instance?,
	onClick: (() -> ())?,
	zIndex: number?,
}): TextButton
	local b = Instance.new("TextButton")
	b.Name = props.name or "Button"
	b.Text = props.text or "Button"
	b.Size = props.size or UDim2.new(1, 0, 0, UILib.Sizes.ButtonHeight)
	b.Position = props.position or UDim2.fromScale(0, 0)
	b.AnchorPoint = props.anchor or Vector2.new(0, 0)
	b.FontFace = props.font or UILib.Fonts.Heading
	b.TextSize = props.textSize or UILib.Sizes.TextBody
	b.BackgroundColor3 = props.bgColor or UILib.Colors.Primary
	b.TextColor3 = props.textColor or UILib.Colors.TextLight
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.ZIndex = props.zIndex or 1

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, props.cornerRadius or UILib.Sizes.CornerRadius)
	corner.Parent = b

	-- Hover/press feedback
	b.MouseButton1Down:Connect(function()
		UILib.tween(b, { Size = b.Size - UDim2.fromOffset(4, 4) }, quickTween)
	end)
	b.MouseButton1Up:Connect(function()
		UILib.tween(b, { Size = props.size or UDim2.new(1, 0, 0, UILib.Sizes.ButtonHeight) }, quickTween)
	end)
	b.MouseLeave:Connect(function()
		UILib.tween(b, { Size = props.size or UDim2.new(1, 0, 0, UILib.Sizes.ButtonHeight) }, quickTween)
	end)

	if props.onClick then
		b.MouseButton1Click:Connect(props.onClick)
	end

	if props.parent then
		b.Parent = props.parent
	end
	return b
end

function UILib.imageLabel(props: {
	name: string?,
	image: string?,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	color: Color3?,
	transparency: number?,
	scaleType: Enum.ScaleType?,
	parent: Instance?,
	cornerRadius: number?,
}): ImageLabel
	local img = Instance.new("ImageLabel")
	img.Name = props.name or "Image"
	img.Image = props.image or ""
	img.Size = props.size or UDim2.fromOffset(UILib.Sizes.IconSize, UILib.Sizes.IconSize)
	img.Position = props.position or UDim2.fromScale(0, 0)
	img.AnchorPoint = props.anchor or Vector2.new(0, 0)
	img.ImageColor3 = props.color or Color3.new(1, 1, 1)
	img.BackgroundTransparency = props.transparency or 1
	img.ScaleType = props.scaleType or Enum.ScaleType.Fit
	img.BorderSizePixel = 0

	if props.cornerRadius then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, props.cornerRadius)
		c.Parent = img
	end

	if props.parent then
		img.Parent = props.parent
	end
	return img
end

function UILib.scrollFrame(props: {
	name: string?,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	direction: Enum.ScrollingDirection?,
	canvasSize: UDim2?,
	parent: Instance?,
	padding: number?,
}): ScrollingFrame
	local sf = Instance.new("ScrollingFrame")
	sf.Name = props.name or "Scroll"
	sf.Size = props.size or UDim2.fromScale(1, 1)
	sf.Position = props.position or UDim2.fromScale(0, 0)
	sf.AnchorPoint = props.anchor or Vector2.new(0, 0)
	sf.ScrollingDirection = props.direction or Enum.ScrollingDirection.Y
	sf.CanvasSize = props.canvasSize or UDim2.fromScale(0, 0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 4
	sf.ScrollBarImageColor3 = UILib.Colors.Primary
	sf.ElasticBehavior = Enum.ElasticBehavior.Always

	if props.padding then
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, props.padding)
		pad.PaddingRight = UDim.new(0, props.padding)
		pad.PaddingTop = UDim.new(0, props.padding)
		pad.PaddingBottom = UDim.new(0, props.padding)
		pad.Parent = sf
	end

	if props.parent then
		sf.Parent = props.parent
	end
	return sf
end

-- Grid layout for item cards
function UILib.gridLayout(props: {
	cellSize: UDim2?,
	padding: UDim2?,
	fillDirection: Enum.FillDirection?,
	sortOrder: Enum.SortOrder?,
	parent: Instance?,
}): UIGridLayout
	local gl = Instance.new("UIGridLayout")
	gl.CellSize = props.cellSize or UDim2.fromOffset(100, 120)
	gl.CellPadding = props.padding or UDim2.fromOffset(8, 8)
	gl.FillDirection = props.fillDirection or Enum.FillDirection.Horizontal
	gl.SortOrder = props.sortOrder or Enum.SortOrder.LayoutOrder
	gl.FillDirectionMaxCells = 0 -- Auto
	gl.HorizontalAlignment = Enum.HorizontalAlignment.Center

	if props.parent then
		gl.Parent = props.parent
	end
	return gl
end

-- List layout
function UILib.listLayout(props: {
	padding: number?,
	fillDirection: Enum.FillDirection?,
	hAlign: Enum.HorizontalAlignment?,
	vAlign: Enum.VerticalAlignment?,
	sortOrder: Enum.SortOrder?,
	parent: Instance?,
}): UIListLayout
	local ll = Instance.new("UIListLayout")
	ll.Padding = UDim.new(0, props.padding or UILib.Sizes.PaddingSmall)
	ll.FillDirection = props.fillDirection or Enum.FillDirection.Vertical
	ll.HorizontalAlignment = props.hAlign or Enum.HorizontalAlignment.Center
	ll.VerticalAlignment = props.vAlign or Enum.VerticalAlignment.Top
	ll.SortOrder = props.sortOrder or Enum.SortOrder.LayoutOrder

	if props.parent then
		ll.Parent = props.parent
	end
	return ll
end

-- ============================================================
-- COMPOSITE COMPONENTS
-- ============================================================

-- Currency display (icon + amount)
function UILib.currencyDisplay(props: {
	name: string?,
	amount: number,
	currencyType: "SC" | "GG",
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	parent: Instance?,
}): Frame
	local isSC = props.currencyType == "SC"
	local color = if isSC then UILib.Colors.StyleCoin else UILib.Colors.GlamGem
	local icon = if isSC then "💰" else "💎"

	local container = UILib.frame({
		name = props.name or "Currency",
		size = props.size or UDim2.fromOffset(120, 36),
		position = props.position,
		anchor = props.anchor,
		color = UILib.Colors.BgDark,
		cornerRadius = 18,
		parent = props.parent,
	})
	container.BackgroundTransparency = 0.3

	UILib.textLabel({
		name = "Icon",
		text = icon,
		size = UDim2.fromOffset(28, 36),
		position = UDim2.fromOffset(6, 0),
		textSize = 18,
		xAlign = Enum.TextXAlignment.Center,
		parent = container,
	})

	UILib.textLabel({
		name = "Amount",
		text = tostring(props.amount),
		size = UDim2.new(1, -38, 1, 0),
		position = UDim2.fromOffset(34, 0),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextBody,
		textColor = color,
		xAlign = Enum.TextXAlignment.Right,
		parent = container,
	})

	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = container

	return container
end

-- Item card for shop/wardrobe
function UILib.itemCard(
	props: {
		item: any, -- Item from catalog
		owned: boolean?,
		equipped: boolean?,
		onClick: (() -> ())?,
		parent: Instance?,
	}
): Frame
	local item = props.item
	local rarityColor = UILib.RarityColors[item.rarity] or UILib.Colors.Common

	local card = UILib.frame({
		name = item.id,
		size = UDim2.fromOffset(110, 140),
		color = UILib.Colors.BgCard,
		cornerRadius = UILib.Sizes.CornerRadiusSmall,
		parent = props.parent,
	})

	-- Rarity border glow
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarityColor
	stroke.Thickness = if item.rarity >= 4 then 2 else 1
	stroke.Transparency = if item.rarity >= 3 then 0 else 0.5
	stroke.Parent = card

	-- Item icon area with gradient background
	local iconArea = UILib.frame({
		name = "IconArea",
		size = UDim2.new(1, 0, 0, 80),
		color = rarityColor,
		transparency = 0.7,
		parent = card,
	})

	-- Gradient overlay for depth
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, rarityColor),
	})
	gradient.Rotation = 135
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(0.6, 0.7),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	gradient.Parent = iconArea

	-- 3D ViewportFrame with mannequin part
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "ItemPreview"
	viewport.Size = UDim2.new(1, -8, 1, -8)
	viewport.Position = UDim2.fromOffset(4, 4)
	viewport.BackgroundTransparency = 1
	viewport.Parent = iconArea

	-- Create a simple 3D clothing shape based on category
	local categoryShapes = {
		Top = { size = Vector3.new(2, 2.5, 0.8), color = rarityColor },
		Bottom = { size = Vector3.new(1.8, 3, 0.6), color = rarityColor },
		Dress = { size = Vector3.new(2, 4, 0.8), color = rarityColor },
		Shoes = { size = Vector3.new(1.5, 0.8, 2.5), color = rarityColor },
		Accessory = { size = Vector3.new(1, 1, 1), color = rarityColor },
		Hair = { size = Vector3.new(1.5, 1.5, 1.5), color = rarityColor },
		Headwear = { size = Vector3.new(2, 1.2, 2), color = rarityColor },
		Bag = { size = Vector3.new(1.2, 1.5, 0.6), color = rarityColor },
	}

	local shapeInfo = categoryShapes[item.category] or { size = Vector3.new(1.5, 1.5, 1.5), color = rarityColor }

	-- Main item shape
	local itemModel = Instance.new("Part")
	itemModel.Size = shapeInfo.size
	itemModel.Position = Vector3.new(0, 0, 0)
	itemModel.Color = item.rarity >= 4 and rarityColor
		or Color3.new(rarityColor.R * 0.7 + 0.3, rarityColor.G * 0.7 + 0.3, rarityColor.B * 0.7 + 0.3)
	itemModel.Material = if item.rarity >= 4 then Enum.Material.Neon else Enum.Material.SmoothPlastic
	itemModel.Anchored = true
	itemModel.Parent = viewport

	-- Add decorative accent part
	local accent = Instance.new("Part")
	accent.Size = shapeInfo.size * 0.4
	accent.Position = Vector3.new(0, shapeInfo.size.Y * 0.3, shapeInfo.size.Z * 0.3)
	accent.Color = UILib.Colors.Secondary
	accent.Material = Enum.Material.SmoothPlastic
	accent.Anchored = true
	accent.Parent = viewport

	-- Camera for viewport
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.5, 4), Vector3.new(0, 0, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- Category emoji overlay (small, in corner)
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
		name = "CategoryIcon",
		text = categoryIcons[item.category] or "✨",
		size = UDim2.fromOffset(20, 20),
		position = UDim2.fromOffset(4, 4),
		textSize = 14,
		xAlign = Enum.TextXAlignment.Center,
		parent = iconArea,
	})

	-- Rarity badge
	UILib.textLabel({
		name = "Rarity",
		text = UILib.RarityNames[item.rarity] or "?",
		size = UDim2.fromOffset(60, 16),
		position = UDim2.new(1, -4, 0, 4),
		anchor = Vector2.new(1, 0),
		font = UILib.Fonts.Caption,
		textSize = UILib.Sizes.TextSmall,
		textColor = UILib.Colors.TextLight,
		color = rarityColor,
		transparency = 0,
		xAlign = Enum.TextXAlignment.Center,
		parent = iconArea,
	})
	local rarBadge = iconArea:FindFirstChild("Rarity")
	if rarBadge then
		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 4)
		rc.Parent = rarBadge
	end

	-- Item name
	UILib.textLabel({
		name = "ItemName",
		text = item.name,
		size = UDim2.new(1, -8, 0, 32),
		position = UDim2.fromOffset(4, 82),
		font = UILib.Fonts.Caption,
		textSize = UILib.Sizes.TextSmall,
		textColor = UILib.Colors.TextPrimary,
		xAlign = Enum.TextXAlignment.Center,
		wrapped = true,
		parent = card,
	})

	-- Price row
	local priceText = if props.owned then "✓ Owned" else `💰 {item.price}`
	local priceColor = if props.owned then UILib.Colors.Success else UILib.Colors.StyleCoin
	UILib.textLabel({
		name = "Price",
		text = priceText,
		size = UDim2.new(1, -8, 0, 20),
		position = UDim2.new(0, 4, 1, -22),
		font = UILib.Fonts.Heading,
		textSize = UILib.Sizes.TextCaption,
		textColor = priceColor,
		xAlign = Enum.TextXAlignment.Center,
		parent = card,
	})

	-- Equipped indicator
	if props.equipped then
		local eqBadge = UILib.frame({
			name = "Equipped",
			size = UDim2.fromOffset(20, 20),
			position = UDim2.fromOffset(4, 4),
			color = UILib.Colors.Success,
			cornerRadius = 10,
			parent = card,
		})
		UILib.textLabel({
			text = "✓",
			size = UDim2.fromScale(1, 1),
			textSize = 12,
			textColor = UILib.Colors.TextLight,
			xAlign = Enum.TextXAlignment.Center,
			parent = eqBadge,
		})
	end

	-- Click handler
	if props.onClick then
		local btn = Instance.new("TextButton")
		btn.Name = "ClickZone"
		btn.Size = UDim2.fromScale(1, 1)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 10
		btn.Parent = card
		btn.MouseButton1Click:Connect(props.onClick)
	end

	return card
end

-- Progress bar (XP, etc.)
function UILib.progressBar(
	props: {
		name: string?,
		size: UDim2?,
		position: UDim2?,
		anchor: Vector2?,
		progress: number, -- 0 to 1
		barColor: Color3?,
		bgColor: Color3?,
		text: string?,
		parent: Instance?,
	}
): Frame
	local container = UILib.frame({
		name = props.name or "ProgressBar",
		size = props.size or UDim2.new(1, 0, 0, 20),
		position = props.position,
		anchor = props.anchor,
		color = props.bgColor or Color3.fromHex("#E0D0E8"),
		cornerRadius = 10,
		parent = props.parent,
	})

	UILib.frame({
		name = "Fill",
		size = UDim2.fromScale(math.clamp(props.progress, 0, 1), 1),
		color = props.barColor or UILib.Colors.Primary,
		cornerRadius = 10,
		parent = container,
	})

	if props.text then
		UILib.textLabel({
			name = "Text",
			text = props.text,
			size = UDim2.fromScale(1, 1),
			font = UILib.Fonts.Caption,
			textSize = UILib.Sizes.TextSmall,
			textColor = UILib.Colors.TextLight,
			xAlign = Enum.TextXAlignment.Center,
			zIndex = 2,
			parent = container,
		})
	end

	return container
end

-- Tab bar for screen navigation
function UILib.tabBar(props: {
	tabs: { { id: string, label: string, icon: string } },
	onSelect: ((id: string) -> ())?,
	parent: Instance?,
}): Frame
	local totalHeight = UILib.Sizes.NavBarHeight + UILib.Sizes.NavBarSafeArea
	local bar = UILib.frame({
		name = "TabBar",
		size = UDim2.new(1, 0, 0, totalHeight),
		position = UDim2.fromScale(0, 1),
		anchor = Vector2.new(0, 1),
		color = UILib.Colors.BgDark,
		parent = props.parent,
	})
	bar.BackgroundTransparency = 0.1

	-- Bottom safe area padding for home indicator
	local bottomPad = Instance.new("UIPadding")
	bottomPad.PaddingBottom = UDim.new(0, UILib.Sizes.NavBarSafeArea)
	bottomPad.Parent = bar

	UILib.listLayout({
		fillDirection = Enum.FillDirection.Horizontal,
		hAlign = Enum.HorizontalAlignment.Center,
		padding = 0,
		parent = bar,
	})

	local tabWidth = 1 / #props.tabs

	for i, tabData in props.tabs do
		local tab = Instance.new("TextButton")
		tab.Name = tabData.id
		tab.Size = UDim2.new(tabWidth, 0, 1, 0)
		tab.BackgroundTransparency = 1
		tab.Text = ""
		tab.LayoutOrder = i
		tab.Parent = bar

		UILib.textLabel({
			name = "Icon",
			text = tabData.icon,
			size = UDim2.new(1, 0, 0, 28),
			position = UDim2.fromOffset(0, 8),
			textSize = 22,
			xAlign = Enum.TextXAlignment.Center,
			parent = tab,
		})

		UILib.textLabel({
			name = "Label",
			text = tabData.label,
			size = UDim2.new(1, 0, 0, 16),
			position = UDim2.fromOffset(0, 38),
			font = UILib.Fonts.Caption,
			textSize = UILib.Sizes.TextSmall,
			textColor = UILib.Colors.TextMuted,
			xAlign = Enum.TextXAlignment.Center,
			parent = tab,
		})

		if props.onSelect then
			tab.MouseButton1Click:Connect(function()
				props.onSelect(tabData.id)
			end)
		end
	end

	return bar
end

-- Star rating display
function UILib.starRating(props: {
	stars: number,
	maxStars: number?,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	parent: Instance?,
}): Frame
	local max = props.maxStars or 5
	local container = UILib.frame({
		name = "Stars",
		size = props.size or UDim2.fromOffset(max * 24, 24),
		position = props.position,
		anchor = props.anchor,
		transparency = 1,
		parent = props.parent,
	})

	UILib.listLayout({
		fillDirection = Enum.FillDirection.Horizontal,
		padding = 2,
		parent = container,
	})

	for i = 1, max do
		UILib.textLabel({
			name = `Star{i}`,
			text = if i <= props.stars then "⭐" else "☆",
			size = UDim2.fromOffset(22, 22),
			textSize = 18,
			xAlign = Enum.TextXAlignment.Center,
			parent = container,
		})
	end

	return container
end

-- Overlay backdrop for modals
function UILib.overlay(props: {
	name: string?,
	onClose: (() -> ())?,
	parent: Instance?,
}): Frame
	local bg = UILib.frame({
		name = props.name or "Overlay",
		size = UDim2.fromScale(1, 1),
		color = UILib.Colors.BgOverlay,
		transparency = 0.4,
		zIndex = 50,
		parent = props.parent,
	})

	if props.onClose then
		local closeBtn = Instance.new("TextButton")
		closeBtn.Size = UDim2.fromScale(1, 1)
		closeBtn.BackgroundTransparency = 1
		closeBtn.Text = ""
		closeBtn.ZIndex = 50
		closeBtn.Parent = bg
		closeBtn.MouseButton1Click:Connect(props.onClose)
	end

	return bg
end

return UILib
