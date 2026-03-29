--!strict
-- Style Kingdom — WorldBuilder
-- Generates the 3D game world: boutique, runway, spawn area, decorations
-- All built with Parts (no external models needed)

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- ============================================================
-- COLORS
-- ============================================================
local C = {
	Pink = Color3.fromHex("#FF85A2"),
	PinkLight = Color3.fromHex("#FFD4E0"),
	PinkDark = Color3.fromHex("#E0627E"),
	Gold = Color3.fromHex("#FFD700"),
	Purple = Color3.fromHex("#6B3FA0"),
	White = Color3.fromHex("#FFFFFF"),
	Cream = Color3.fromHex("#FFF5EE"),
	Wood = Color3.fromHex("#8B6914"),
	WoodLight = Color3.fromHex("#D4A847"),
	WoodDark = Color3.fromHex("#5C3A0A"),
	Glass = Color3.fromHex("#C8E6FF"),
	Grass = Color3.fromHex("#7EC850"),
	GrassDark = Color3.fromHex("#5DA33A"),
	Sky = Color3.fromHex("#87CEEB"),
	Concrete = Color3.fromHex("#C0C0C0"),
	Red = Color3.fromHex("#FF4444"),
	Neon = Color3.fromHex("#FF69B4"),
}

-- ============================================================
-- HELPERS
-- ============================================================
local function makePart(props: {
	name: string?,
	size: Vector3,
	position: Vector3,
	color: Color3?,
	material: Enum.Material?,
	transparency: number?,
	anchored: boolean?,
	canCollide: boolean?,
	parent: Instance?,
}): Part
	local part = Instance.new("Part")
	part.Name = props.name or "Part"
	part.Size = props.size
	part.Position = props.position
	part.Color = props.color or C.White
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Transparency = props.transparency or 0
	part.Anchored = if props.anchored ~= nil then props.anchored else true
	part.CanCollide = if props.canCollide ~= nil then props.canCollide else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent or Workspace
	return part
end

local function makeText(parent: BasePart, text: string, color: Color3?)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, 2, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or C.White
	label.TextScaled = true
	label.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
	label.Parent = gui
end

local function makeFolder(name: string, parent: Instance?): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent or Workspace
	return folder
end

-- ============================================================
-- GROUND + SKY
-- ============================================================
local function buildGround()
	-- Remove default baseplate
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	-- Main ground — pink tiled plaza
	makePart({
		name = "Ground",
		size = Vector3.new(300, 1, 300),
		position = Vector3.new(0, -0.5, 0),
		color = C.PinkLight,
		material = Enum.Material.Marble,
	})

	-- Grass border
	for _, pos in
		{
			Vector3.new(-120, -0.4, 0),
			Vector3.new(120, -0.4, 0),
			Vector3.new(0, -0.4, -120),
			Vector3.new(0, -0.4, 120),
		}
	do
		makePart({
			name = "Grass",
			size = Vector3.new(60, 0.5, 300),
			position = pos,
			color = C.Grass,
			material = Enum.Material.Grass,
		})
	end

	-- Atmosphere
	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.3
	atmo.Offset = 0.25
	atmo.Color = Color3.fromHex("#FFE8F0")
	atmo.Decay = Color3.fromHex("#FFB8D0")
	atmo.Glare = 0
	atmo.Haze = 1
	atmo.Parent = Lighting

	-- Bloom for dreamy look
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 0.9
	bloom.Parent = Lighting

	-- Color correction for warm feel
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.05
	cc.Contrast = 0.1
	cc.Saturation = 0.2
	cc.TintColor = Color3.fromHex("#FFF0F5")
	cc.Parent = Lighting
end

-- ============================================================
-- BOUTIQUE BUILDING
-- ============================================================
local function buildBoutique()
	local folder = makeFolder("Boutique")
	local origin = Vector3.new(0, 0, -20)

	-- Floor
	makePart({
		name = "Floor",
		size = Vector3.new(30, 0.5, 24),
		position = origin + Vector3.new(0, 0.25, 0),
		color = C.WoodLight,
		material = Enum.Material.Wood,
		parent = folder,
	})

	-- Back wall
	makePart({
		name = "BackWall",
		size = Vector3.new(30, 14, 1),
		position = origin + Vector3.new(0, 7.5, -12),
		color = C.Cream,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})

	-- Left wall
	makePart({
		name = "LeftWall",
		size = Vector3.new(1, 14, 24),
		position = origin + Vector3.new(-15, 7.5, 0),
		color = C.Cream,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})

	-- Right wall
	makePart({
		name = "RightWall",
		size = Vector3.new(1, 14, 24),
		position = origin + Vector3.new(15, 7.5, 0),
		color = C.Cream,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})

	-- Ceiling
	makePart({
		name = "Ceiling",
		size = Vector3.new(30, 0.5, 24),
		position = origin + Vector3.new(0, 14.5, 0),
		color = C.White,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})

	-- Front glass windows (two panels with door gap)
	makePart({
		name = "FrontWindowLeft",
		size = Vector3.new(11, 10, 0.5),
		position = origin + Vector3.new(-7, 5.5, 12),
		color = C.Glass,
		material = Enum.Material.Glass,
		transparency = 0.6,
		parent = folder,
	})
	makePart({
		name = "FrontWindowRight",
		size = Vector3.new(11, 10, 0.5),
		position = origin + Vector3.new(7, 5.5, 12),
		color = C.Glass,
		material = Enum.Material.Glass,
		transparency = 0.6,
		parent = folder,
	})

	-- Front top panel (above door)
	makePart({
		name = "FrontTop",
		size = Vector3.new(30, 4, 1),
		position = origin + Vector3.new(0, 12.5, 12),
		color = C.Pink,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})

	-- Sign
	local sign = makePart({
		name = "Sign",
		size = Vector3.new(16, 3, 0.5),
		position = origin + Vector3.new(0, 16, 12),
		color = C.PinkDark,
		material = Enum.Material.Neon,
		parent = folder,
	})
	makeText(sign, "✨ STYLE KINGDOM ✨", C.Gold)

	-- Counter/checkout desk
	makePart({
		name = "Counter",
		size = Vector3.new(8, 3, 2),
		position = origin + Vector3.new(-5, 2, 6),
		color = C.WoodDark,
		material = Enum.Material.Wood,
		parent = folder,
	})

	-- Register on counter
	makePart({
		name = "Register",
		size = Vector3.new(1.5, 1, 1),
		position = origin + Vector3.new(-5, 4, 6),
		color = C.Gold,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})

	-- Display shelves (back wall)
	for i = 0, 3 do
		makePart({
			name = `Shelf_{i}`,
			size = Vector3.new(6, 0.3, 1.5),
			position = origin + Vector3.new(-8 + i * 5.5, 4, -11),
			color = C.WoodLight,
			material = Enum.Material.Wood,
			parent = folder,
		})
		makePart({
			name = `ShelfUpper_{i}`,
			size = Vector3.new(6, 0.3, 1.5),
			position = origin + Vector3.new(-8 + i * 5.5, 8, -11),
			color = C.WoodLight,
			material = Enum.Material.Wood,
			parent = folder,
		})
	end

	-- Mannequin platforms (display stands)
	for i = 0, 2 do
		makePart({
			name = `MannequinStand_{i}`,
			size = Vector3.new(3, 1, 3),
			position = origin + Vector3.new(-8 + i * 8, 1, -6),
			color = C.Pink,
			material = Enum.Material.SmoothPlastic,
			parent = folder,
		})

		-- Mannequin body (simple cylinder + sphere)
		makePart({
			name = `MannequinBody_{i}`,
			size = Vector3.new(1.5, 4, 1),
			position = origin + Vector3.new(-8 + i * 8, 4, -6),
			color = C.Cream,
			material = Enum.Material.SmoothPlastic,
			parent = folder,
		})

		-- Mannequin head
		local head = Instance.new("Part")
		head.Name = `MannequinHead_{i}`
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(1.5, 1.5, 1.5)
		head.Position = origin + Vector3.new(-8 + i * 8, 6.5, -6)
		head.Color = C.Cream
		head.Material = Enum.Material.SmoothPlastic
		head.Anchored = true
		head.TopSurface = Enum.SurfaceType.Smooth
		head.BottomSurface = Enum.SurfaceType.Smooth
		head.Parent = folder
	end

	-- Chandelier (center ceiling)
	local chandelier = makePart({
		name = "Chandelier",
		size = Vector3.new(4, 1, 4),
		position = origin + Vector3.new(0, 13, 0),
		color = C.Gold,
		material = Enum.Material.Neon,
		transparency = 0.3,
		parent = folder,
	})

	-- Spotlight
	local spotlight = Instance.new("SpotLight")
	spotlight.Brightness = 3
	spotlight.Range = 30
	spotlight.Angle = 90
	spotlight.Color = Color3.new(1, 0.95, 0.9)
	spotlight.Face = Enum.NormalId.Bottom
	spotlight.Parent = chandelier

	-- Pink carpet (entrance)
	makePart({
		name = "EntranceCarpet",
		size = Vector3.new(6, 0.1, 8),
		position = origin + Vector3.new(0, 0.55, 16),
		color = C.Pink,
		material = Enum.Material.Fabric,
		parent = folder,
	})
end

-- ============================================================
-- RUNWAY STAGE
-- ============================================================
local function buildRunway()
	local folder = makeFolder("Runway")
	local origin = Vector3.new(50, 0, 0)

	-- Main runway platform
	makePart({
		name = "RunwayPlatform",
		size = Vector3.new(8, 1, 50),
		position = origin + Vector3.new(0, 0.5, 0),
		color = C.White,
		material = Enum.Material.Marble,
		parent = folder,
	})

	-- Runway carpet (center strip)
	makePart({
		name = "RunwayCarpet",
		size = Vector3.new(4, 0.1, 48),
		position = origin + Vector3.new(0, 1.1, 0),
		color = C.PinkDark,
		material = Enum.Material.Fabric,
		parent = folder,
	})

	-- Stage at end
	makePart({
		name = "Stage",
		size = Vector3.new(16, 2, 10),
		position = origin + Vector3.new(0, 1, -28),
		color = C.Purple,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})

	-- Backdrop
	makePart({
		name = "Backdrop",
		size = Vector3.new(16, 12, 1),
		position = origin + Vector3.new(0, 8, -33),
		color = C.PinkDark,
		material = Enum.Material.Neon,
		transparency = 0.2,
		parent = folder,
	})

	local backdropSign = makePart({
		name = "BackdropSign",
		size = Vector3.new(12, 3, 0.1),
		position = origin + Vector3.new(0, 12, -32.4),
		color = C.Gold,
		material = Enum.Material.Neon,
		parent = folder,
	})
	makeText(backdropSign, "🏆 FASHION CONTEST 🏆", C.White)

	-- Audience seating (both sides)
	for side = -1, 1, 2 do
		for row = 0, 3 do
			for seat = 0, 4 do
				makePart({
					name = "Seat",
					size = Vector3.new(2.5, 2, 2.5),
					position = origin + Vector3.new(side * (7 + row * 3), 1 + row * 0.5, -10 + seat * 6),
					color = if row % 2 == 0 then C.Pink else C.PinkLight,
					material = Enum.Material.SmoothPlastic,
					parent = folder,
				})
			end
		end
	end

	-- Runway lights (neon strips along edges)
	for z = -22, 22, 4 do
		for side = -1, 1, 2 do
			makePart({
				name = "RunwayLight",
				size = Vector3.new(0.3, 0.3, 3),
				position = origin + Vector3.new(side * 4.5, 1.2, z),
				color = C.Neon,
				material = Enum.Material.Neon,
				parent = folder,
			})
		end
	end

	-- Spotlights on stage
	for _, offset in { Vector3.new(-5, 0, 0), Vector3.new(0, 0, 0), Vector3.new(5, 0, 0) } do
		local lightPart = makePart({
			name = "StageLight",
			size = Vector3.new(1, 1, 1),
			position = origin + Vector3.new(0, 14, -28) + offset,
			color = C.Gold,
			material = Enum.Material.Neon,
			transparency = 0.5,
			parent = folder,
		})
		local spot = Instance.new("SpotLight")
		spot.Brightness = 5
		spot.Range = 25
		spot.Angle = 45
		spot.Color = Color3.new(1, 0.9, 0.8)
		spot.Face = Enum.NormalId.Bottom
		spot.Parent = lightPart
	end
end

-- ============================================================
-- SPAWN AREA
-- ============================================================
local function buildSpawnArea()
	local folder = makeFolder("SpawnArea")

	-- Spawn platform
	makePart({
		name = "SpawnPlatform",
		size = Vector3.new(20, 1, 20),
		position = Vector3.new(0, 0.5, 40),
		color = C.Pink,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})

	-- Welcome arch
	makePart({
		name = "ArchLeft",
		size = Vector3.new(2, 12, 2),
		position = Vector3.new(-8, 6.5, 32),
		color = C.Gold,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})
	makePart({
		name = "ArchRight",
		size = Vector3.new(2, 12, 2),
		position = Vector3.new(8, 6.5, 32),
		color = C.Gold,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})
	local archTop = makePart({
		name = "ArchTop",
		size = Vector3.new(18, 2, 2),
		position = Vector3.new(0, 13, 32),
		color = C.Gold,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})
	makeText(archTop, "👗 STYLE KINGDOM 👗", C.White)

	-- Decorative flower pots
	for _, pos in
		{
			Vector3.new(-6, 1.5, 36),
			Vector3.new(6, 1.5, 36),
			Vector3.new(-6, 1.5, 44),
			Vector3.new(6, 1.5, 44),
		}
	do
		local pot = Instance.new("Part")
		pot.Name = "FlowerPot"
		pot.Shape = Enum.PartType.Cylinder
		pot.Size = Vector3.new(2, 2, 2)
		pot.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
		pot.Color = C.PinkDark
		pot.Material = Enum.Material.SmoothPlastic
		pot.Anchored = true
		pot.Parent = folder

		-- Flowers (green ball on top)
		local flower = Instance.new("Part")
		flower.Name = "Flowers"
		flower.Shape = Enum.PartType.Ball
		flower.Size = Vector3.new(2.5, 2.5, 2.5)
		flower.Position = pos + Vector3.new(0, 1.5, 0)
		flower.Color = C.Grass
		flower.Material = Enum.Material.Grass
		flower.Anchored = true
		flower.Parent = folder
	end

	-- Set spawn location
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "SpawnLocation"
	spawnLocation.Size = Vector3.new(12, 1, 12)
	spawnLocation.Position = Vector3.new(0, 1.1, 40)
	spawnLocation.Color = C.PinkLight
	spawnLocation.Material = Enum.Material.SmoothPlastic
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = true
	spawnLocation.TopSurface = Enum.SurfaceType.Smooth
	spawnLocation.Transparency = 0.5
	spawnLocation.Parent = folder
end

-- ============================================================
-- DECORATIONS & PATHWAYS
-- ============================================================
local function buildPathways()
	local folder = makeFolder("Pathways")

	-- Path from spawn to boutique
	makePart({
		name = "PathToBoutique",
		size = Vector3.new(6, 0.2, 30),
		position = Vector3.new(0, 0.1, 15),
		color = C.Concrete,
		material = Enum.Material.Concrete,
		parent = folder,
	})

	-- Path from boutique to runway
	makePart({
		name = "PathToRunway",
		size = Vector3.new(40, 0.2, 6),
		position = Vector3.new(25, 0.1, -5),
		color = C.Concrete,
		material = Enum.Material.Concrete,
		parent = folder,
	})

	-- Direction signs
	local signToBoutique = makePart({
		name = "SignToBoutique",
		size = Vector3.new(4, 3, 0.5),
		position = Vector3.new(-4, 3, 25),
		color = C.Pink,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})
	makeText(signToBoutique, "🏪 Boutique →", C.White)

	local signToRunway = makePart({
		name = "SignToRunway",
		size = Vector3.new(4, 3, 0.5),
		position = Vector3.new(20, 3, -8),
		color = C.Purple,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})
	makeText(signToRunway, "🏆 Runway →", C.White)

	-- Decorative lamp posts
	for _, pos in
		{
			Vector3.new(-6, 0, 8),
			Vector3.new(6, 0, 8),
			Vector3.new(-6, 0, 22),
			Vector3.new(6, 0, 22),
			Vector3.new(30, 0, -2),
			Vector3.new(40, 0, -2),
		}
	do
		-- Pole
		makePart({
			name = "LampPole",
			size = Vector3.new(0.5, 8, 0.5),
			position = pos + Vector3.new(0, 4, 0),
			color = C.WoodDark,
			material = Enum.Material.Metal,
			parent = folder,
		})
		-- Light
		local lamp = makePart({
			name = "Lamp",
			size = Vector3.new(2, 1, 2),
			position = pos + Vector3.new(0, 8.5, 0),
			color = C.Gold,
			material = Enum.Material.Neon,
			transparency = 0.3,
			parent = folder,
		})
		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 2
		pointLight.Range = 20
		pointLight.Color = Color3.new(1, 0.95, 0.85)
		pointLight.Parent = lamp
	end
end

-- ============================================================
-- BUILD EVERYTHING
-- ============================================================
print("[Style Kingdom] Building 3D world...")
buildGround()
buildBoutique()
buildRunway()
buildSpawnArea()
buildPathways()
print("[Style Kingdom] 3D world built!")
