--!strict
-- Style Kingdom — Contest Theme Catalog
-- Defines all runway contest themes and their tag-based scoring rules

local ThemeCatalog = {}

ThemeCatalog.Themes = {

	-- ============================================================
	-- K-FASHION THEMES
	-- ============================================================
	{
		id = "seoul_street",
		name = "Seoul Street Style",
		description = "Channel your inner Hongdae fashion icon",
		scoring = {
			desiredTags = { street = 3, korean = 2, casual = 1, oversized = 1 },
			bonusTags = { hoodie = 1, sneakers = 1, hat = 1 },
			penaltyTags = { formal = -2, traditional = -1 },
		},
	},

	{
		id = "kpop_stage",
		name = "K-Pop Stage Ready",
		description = "Dress like you're performing at MAMA Awards",
		scoring = {
			desiredTags = { kpop = 3, stage = 3, flashy = 2, performance = 2 },
			bonusTags = { glitter = 2, bold = 1, korean = 1 },
			penaltyTags = { casual = -2, simple = -1 },
		},
	},

	{
		id = "kdrama_chic",
		name = "K-Drama Main Character",
		description = "Look like you stepped out of a Korean drama",
		scoring = {
			desiredTags = { korean = 2, elegant = 2, modern = 2, classic = 1 },
			bonusTags = { preppy = 1, sharp = 1, clean = 1 },
			penaltyTags = { bold = -1, maximal = -2 },
		},
	},

	-- ============================================================
	-- J-FASHION THEMES
	-- ============================================================
	{
		id = "harajuku_bold",
		name = "Harajuku Street",
		description = "Go bold, go colorful, go Harajuku!",
		scoring = {
			desiredTags = { harajuku = 3, japanese = 2, colorful = 2, bold = 2 },
			bonusTags = { layered = 1, kawaii = 1, maximal = 2 },
			penaltyTags = { minimal = -2, formal = -1 },
		},
	},

	{
		id = "kawaii_cute",
		name = "Kawaii Overload",
		description = "Maximum cuteness — bows, pastels, and all things adorable",
		scoring = {
			desiredTags = { cute = 3, kawaii = 3, japanese = 1, pastel = 2 },
			bonusTags = { bow = 1, pink = 1, accessory = 1 },
			penaltyTags = { dark = -2, cool = -1 },
		},
	},

	{
		id = "tokyo_night",
		name = "Tokyo Night Out",
		description = "Shibuya after dark — sleek, edgy, electric",
		scoring = {
			desiredTags = { japanese = 2, dark = 2, cool = 2, modern = 2 },
			bonusTags = { platform = 1, street = 1, bold = 1 },
			penaltyTags = { traditional = -2, cute = -1 },
		},
	},

	-- ============================================================
	-- SEA FASHION THEMES
	-- ============================================================
	{
		id = "batik_beauty",
		name = "Batik Beauty",
		description = "Celebrate the art of batik — traditional or modern",
		scoring = {
			desiredTags = { batik = 4, traditional = 2, pattern = 2 },
			bonusTags = { malaysian = 1, indonesian = 1, elegant = 1 },
			penaltyTags = { street = -1, casual = -1 },
		},
	},

	{
		id = "raya_glamour",
		name = "Hari Raya Glamour",
		description = "Dress for the most festive Raya celebration",
		scoring = {
			desiredTags = { malaysian = 3, traditional = 2, formal = 2, elegant = 2, festive = 2 },
			bonusTags = { baju_kurung = 2, kebaya = 2, songket = 2, gold = 1 },
			penaltyTags = { casual = -2, street = -2 },
		},
	},

	{
		id = "tropical_chic",
		name = "Tropical Elegance",
		description = "Effortless SEA style — breezy, colorful, natural",
		scoring = {
			desiredTags = { malaysian = 2, indonesian = 2, natural = 2, artisan = 1 },
			bonusTags = { rattan = 1, batik = 1, casual = 1, modern = 1 },
			penaltyTags = { formal = -1, dark = -1 },
		},
	},

	{
		id = "lunar_new_year",
		name = "Lunar New Year",
		description = "Red, gold, and prosperity — dress for good fortune",
		scoring = {
			desiredTags = { chinese = 3, festive = 3, traditional = 2, elegant = 2 },
			bonusTags = { cheongsam = 2, qipao = 2, gold = 2, luxurious = 1 },
			penaltyTags = { casual = -2, dark = -1 },
		},
	},

	-- ============================================================
	-- CROSS-CULTURAL THEMES
	-- ============================================================
	{
		id = "asian_fusion",
		name = "East Meets West",
		description = "Blend Asian tradition with modern Western style",
		scoring = {
			desiredTags = { fusion = 3, modern = 2, traditional = 1, elegant = 1 },
			bonusTags = { korean = 1, japanese = 1, malaysian = 1, trendy = 1 },
			penaltyTags = {},
		},
	},

	{
		id = "red_carpet",
		name = "Asian Red Carpet",
		description = "A-list Asian celebrity glamour",
		scoring = {
			desiredTags = { formal = 3, elegant = 3, luxurious = 2, red_carpet = 2 },
			bonusTags = { gown = 2, glitter = 1, jewelry = 1, heels = 1 },
			penaltyTags = { casual = -3, street = -2 },
		},
	},

	{
		id = "school_style",
		name = "Asian School Fashion",
		description = "Rock the iconic Asian school uniform look",
		scoring = {
			desiredTags = { school = 3, uniform = 2, classic = 1, preppy = 1 },
			bonusTags = { korean = 1, japanese = 1, socks = 1 },
			penaltyTags = { formal = -1, flashy = -2 },
		},
	},

	{
		id = "modest_elegance",
		name = "Modest & Chic",
		description = "Prove that modest fashion is the most elegant",
		scoring = {
			desiredTags = { modest = 3, elegant = 2, hijab = 2, traditional = 1 },
			bonusTags = { kebaya = 2, baju_kurung = 2, tudung = 2, satin = 1 },
			penaltyTags = { crop = -2, mini = -2 },
		},
	},

	{
		id = "all_black",
		name = "All Black Everything",
		description = "Monochrome mood — all black, maximum attitude",
		scoring = {
			desiredTags = { dark = 3, black = 3, cool = 2, modern = 1 },
			bonusTags = { street = 1, sharp = 1, minimal = 1 },
			penaltyTags = { colorful = -3, pastel = -2 },
		},
	},

	{
		id = "cozy_vibes",
		name = "Cozy & Comfy",
		description = "Maximum comfort without sacrificing style",
		scoring = {
			desiredTags = { cozy = 3, casual = 2, oversized = 2, comfortable = 1 },
			bonusTags = { hoodie = 1, beanie = 1, soft = 1 },
			penaltyTags = { formal = -2, heels = -1 },
		},
	},

	{
		id = "pattern_clash",
		name = "Pattern Clash",
		description = "Mix batik, plaid, stripes — the bolder the better",
		scoring = {
			desiredTags = { pattern = 3, bold = 2, batik = 2, plaid = 2 },
			bonusTags = { layered = 1, maximal = 1, colorful = 1 },
			penaltyTags = { minimal = -2, simple = -1 },
		},
	},

	{
		id = "vintage_asia",
		name = "Vintage Asian",
		description = "Channel the golden eras of Asian fashion",
		scoring = {
			desiredTags = { traditional = 3, classic = 2, elegant = 2, retro = 1 },
			bonusTags = { hanbok = 2, kimono = 2, cheongsam = 2, sari = 2 },
			penaltyTags = { modern = -1, street = -1 },
		},
	},
}

-- Build lookup by ID
ThemeCatalog.ById = {}
for _, theme in ThemeCatalog.Themes do
	ThemeCatalog.ById[theme.id] = theme
end

-- Get a random theme, optionally excluding recent ones
function ThemeCatalog.getRandomTheme(excludeIds: { string }?): any
	local available = {}
	local excludeSet = {}

	if excludeIds then
		for _, id in excludeIds do
			excludeSet[id] = true
		end
	end

	for _, theme in ThemeCatalog.Themes do
		if not excludeSet[theme.id] then
			table.insert(available, theme)
		end
	end

	if #available == 0 then
		-- If all excluded, pick from full list
		return ThemeCatalog.Themes[math.random(#ThemeCatalog.Themes)]
	end

	return available[math.random(#available)]
end

-- Score an outfit against a theme
function ThemeCatalog.scoreOutfit(themeId: string, itemTags: { { string } }): number
	local theme = ThemeCatalog.ById[themeId]
	if not theme then
		return 0
	end

	local score = 0
	local scoring = theme.scoring

	-- Collect all tags from all items into a frequency map
	local tagCounts: { [string]: number } = {}
	for _, tags in itemTags do
		for _, tag in tags do
			tagCounts[tag] = (tagCounts[tag] or 0) + 1
		end
	end

	-- Score desired tags
	for tag, weight in scoring.desiredTags do
		if tagCounts[tag] then
			score += weight * math.min(tagCounts[tag], 3) -- Cap at 3 to prevent stacking
		end
	end

	-- Score bonus tags
	if scoring.bonusTags then
		for tag, weight in scoring.bonusTags do
			if tagCounts[tag] then
				score += weight
			end
		end
	end

	-- Apply penalty tags
	if scoring.penaltyTags then
		for tag, weight in scoring.penaltyTags do
			if tagCounts[tag] then
				score += weight -- weight is already negative
			end
		end
	end

	return math.max(score, 0) -- Floor at 0
end

return ThemeCatalog
