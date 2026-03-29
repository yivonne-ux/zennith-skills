--!strict
-- Style Kingdom — Item Catalog
-- Master database of all clothing/accessory items
-- Both server (scoring) and client (UI) depend on this

local ItemCatalog = {}

-- Helper to create items consistently
local function item(data: {
	id: string,
	name: string,
	category: string,
	style: string,
	rarity: number,
	tags: { string },
	flavorText: string,
	price: number,
	premiumPrice: number?,
	tier: number,
	eventOnly: boolean?,
})
	return {
		id = data.id,
		name = data.name,
		category = data.category,
		style = data.style,
		rarity = data.rarity,
		tags = data.tags,
		assetId = "", -- Placeholder: replace with Roblox asset IDs after upload
		flavorText = data.flavorText,
		price = data.price,
		premiumPrice = data.premiumPrice,
		tier = data.tier,
		eventOnly = data.eventOnly or false,
	}
end

-- ============================================================
-- K-FASHION (15 items)
-- ============================================================
ItemCatalog.Items = {

	-- K-Fashion
	item({
		id = "kf_oversized_hoodie",
		name = "Seoul Oversized Hoodie",
		category = "Top",
		style = "KFashion",
		rarity = 1,
		tags = { "street", "korean", "casual", "oversized", "hoodie" },
		flavorText = "The oversized silhouette is a staple of Korean street fashion, popularized by K-pop idols.",
		price = 80,
		tier = 1,
	}),

	item({
		id = "kf_oversized_hoodie_blk",
		name = "Midnight Seoul Hoodie",
		category = "Top",
		style = "KFashion",
		rarity = 2,
		tags = { "street", "korean", "casual", "oversized", "hoodie", "dark" },
		flavorText = "All-black everything — the Hongdae night look.",
		price = 150,
		tier = 1,
	}),

	item({
		id = "kf_oversized_hoodie_pastel",
		name = "Pastel Dream Hoodie",
		category = "Top",
		style = "KFashion",
		rarity = 2,
		tags = { "street", "korean", "casual", "oversized", "hoodie", "pastel", "cute" },
		flavorText = "Soft pastel tones inspired by Seoul's cafe culture.",
		price = 150,
		tier = 1,
	}),

	item({
		id = "kf_wide_leg_pants",
		name = "Gangnam Wide-Leg Pants",
		category = "Bottom",
		style = "KFashion",
		rarity = 1,
		tags = { "street", "korean", "casual", "wide", "modern" },
		flavorText = "Wide-leg silhouettes dominate Seoul's fashion districts.",
		price = 100,
		tier = 1,
	}),

	item({
		id = "kf_crop_top",
		name = "Myeongdong Crop Top",
		category = "Top",
		style = "KFashion",
		rarity = 1,
		tags = { "street", "korean", "casual", "crop", "trendy" },
		flavorText = "Named after Seoul's busiest shopping district.",
		price = 60,
		tier = 1,
	}),

	item({
		id = "kf_bucket_hat",
		name = "K-Street Bucket Hat",
		category = "Headwear",
		style = "KFashion",
		rarity = 1,
		tags = { "street", "korean", "casual", "hat", "accessory" },
		flavorText = "No Korean street look is complete without the iconic bucket hat.",
		price = 50,
		tier = 1,
	}),

	item({
		id = "kf_layered_jacket",
		name = "Itaewon Layered Jacket",
		category = "Top",
		style = "KFashion",
		rarity = 3,
		tags = { "street", "korean", "layered", "jacket", "cool" },
		flavorText = "Layering is an art form in Korean fashion — this jacket nails it.",
		price = 350,
		tier = 2,
	}),

	item({
		id = "kf_school_uniform",
		name = "Korean School Uniform",
		category = "Dress",
		style = "KFashion",
		rarity = 2,
		tags = { "korean", "uniform", "school", "classic", "preppy" },
		flavorText = "The classic Korean school uniform — instantly recognizable from K-dramas.",
		price = 200,
		tier = 1,
	}),

	item({
		id = "kf_kpop_stage",
		name = "K-Pop Stage Outfit",
		category = "Dress",
		style = "KFashion",
		rarity = 4,
		tags = { "korean", "kpop", "stage", "performance", "flashy", "glitter" },
		flavorText = "Inspired by the dazzling costumes of K-pop music videos.",
		price = 1200,
		premiumPrice = 50,
		tier = 3,
	}),

	item({
		id = "kf_sneakers_white",
		name = "Seoul White Sneakers",
		category = "Shoes",
		style = "KFashion",
		rarity = 1,
		tags = { "street", "korean", "casual", "sneakers", "clean" },
		flavorText = "Clean white sneakers — the foundation of every K-fashion outfit.",
		price = 70,
		tier = 1,
	}),

	item({
		id = "kf_sneakers_chunky",
		name = "Chunky Platform Sneakers",
		category = "Shoes",
		style = "KFashion",
		rarity = 2,
		tags = { "street", "korean", "sneakers", "platform", "trendy" },
		flavorText = "Chunky soles add height and attitude to any look.",
		price = 180,
		tier = 1,
	}),

	item({
		id = "kf_sneakers_hype",
		name = "Hype Beast Kicks",
		category = "Shoes",
		style = "KFashion",
		rarity = 3,
		tags = { "street", "korean", "sneakers", "hype", "rare", "limited" },
		flavorText = "The kind of sneakers people camp overnight to buy.",
		price = 500,
		tier = 2,
	}),

	item({
		id = "kf_crossbody_bag",
		name = "Hongdae Crossbody Bag",
		category = "Bag",
		style = "KFashion",
		rarity = 1,
		tags = { "street", "korean", "casual", "bag", "accessory" },
		flavorText = "A small crossbody bag — practical and stylish for Hongdae nights.",
		price = 60,
		tier = 1,
	}),

	item({
		id = "kf_beanie",
		name = "Seoul Beanie",
		category = "Headwear",
		style = "KFashion",
		rarity = 1,
		tags = { "street", "korean", "casual", "beanie", "cozy" },
		flavorText = "Perfect for those chilly Seoul winters.",
		price = 40,
		tier = 1,
	}),

	item({
		id = "kf_hanbok_modern",
		name = "Modern Hanbok Jeogori",
		category = "Top",
		style = "KFashion",
		rarity = 4,
		tags = { "korean", "traditional", "hanbok", "modern", "fusion", "elegant" },
		flavorText = "A modern take on the jeogori — Korea's traditional upper garment, reimagined for today.",
		price = 1500,
		premiumPrice = 60,
		tier = 3,
	}),

	-- ============================================================
	-- J-FASHION (10 items)
	-- ============================================================

	item({
		id = "jf_harajuku_skirt",
		name = "Harajuku Layered Skirt",
		category = "Bottom",
		style = "JFashion",
		rarity = 2,
		tags = { "japanese", "harajuku", "layered", "colorful", "bold" },
		flavorText = "Harajuku's Takeshita Street is the birthplace of Japan's most daring fashion.",
		price = 180,
		tier = 1,
	}),

	item({
		id = "jf_sailor_fuku",
		name = "Sailor Fuku Uniform",
		category = "Dress",
		style = "JFashion",
		rarity = 2,
		tags = { "japanese", "uniform", "school", "sailor", "classic" },
		flavorText = "The iconic Japanese sailor-style school uniform, recognized worldwide.",
		price = 200,
		tier = 1,
	}),

	item({
		id = "jf_kimono_modern",
		name = "Neo-Kimono Dress",
		category = "Dress",
		style = "JFashion",
		rarity = 4,
		tags = { "japanese", "kimono", "traditional", "modern", "fusion", "elegant" },
		flavorText = "Ancient kimono silhouettes reimagined with contemporary fabrics and cuts.",
		price = 1400,
		premiumPrice = 55,
		tier = 3,
	}),

	item({
		id = "jf_platform_shoes",
		name = "Shibuya Platform Shoes",
		category = "Shoes",
		style = "JFashion",
		rarity = 2,
		tags = { "japanese", "platform", "bold", "harajuku", "shoes" },
		flavorText = "Sky-high platforms are a Harajuku signature.",
		price = 200,
		tier = 1,
	}),

	item({
		id = "jf_leg_warmers",
		name = "Colorful Leg Warmers",
		category = "Accessory",
		style = "JFashion",
		rarity = 1,
		tags = { "japanese", "colorful", "cute", "retro", "accessory" },
		flavorText = "A staple of Japanese street fashion since the Y2K era.",
		price = 40,
		tier = 1,
	}),

	item({
		id = "jf_bow_headband",
		name = "Oversized Bow Headband",
		category = "Headwear",
		style = "JFashion",
		rarity = 1,
		tags = { "japanese", "cute", "kawaii", "bow", "headband" },
		flavorText = "Kawaii culture at its finest — bigger is better!",
		price = 35,
		tier = 1,
	}),

	item({
		id = "jf_graphic_tee",
		name = "Akihabara Graphic Tee",
		category = "Top",
		style = "JFashion",
		rarity = 1,
		tags = { "japanese", "casual", "graphic", "anime", "street" },
		flavorText = "Bold graphic tees inspired by anime and manga culture.",
		price = 70,
		tier = 1,
	}),

	item({
		id = "jf_plaid_skirt",
		name = "Tokyo Plaid Mini Skirt",
		category = "Bottom",
		style = "JFashion",
		rarity = 1,
		tags = { "japanese", "plaid", "school", "preppy", "mini" },
		flavorText = "Plaid patterns are a Tokyo fashion essential.",
		price = 80,
		tier = 1,
	}),

	item({
		id = "jf_long_socks",
		name = "Over-the-Knee Socks",
		category = "Accessory",
		style = "JFashion",
		rarity = 1,
		tags = { "japanese", "socks", "cute", "school", "accessory" },
		flavorText = "The finishing touch for any Japanese school-inspired look.",
		price = 30,
		tier = 1,
	}),

	item({
		id = "jf_decora_set",
		name = "Decora Accessory Set",
		category = "Accessory",
		style = "JFashion",
		rarity = 3,
		tags = { "japanese", "harajuku", "decora", "colorful", "bold", "maximal" },
		flavorText = "Decora fashion means more is more — pile on the clips, badges, and charms!",
		price = 400,
		tier = 2,
	}),

	-- ============================================================
	-- SEA FASHION (15 items)
	-- ============================================================

	item({
		id = "sea_batik_sarong_mega",
		name = "Mega Mendung Batik Sarong",
		category = "Bottom",
		style = "SEA",
		rarity = 3,
		tags = { "malaysian", "indonesian", "batik", "traditional", "pattern", "elegant" },
		flavorText = "Mega Mendung (great clouds) is one of Indonesia's most iconic batik patterns from Cirebon.",
		price = 350,
		tier = 2,
	}),

	item({
		id = "sea_batik_sarong_parang",
		name = "Parang Batik Sarong",
		category = "Bottom",
		style = "SEA",
		rarity = 3,
		tags = { "malaysian", "indonesian", "batik", "traditional", "pattern", "royal" },
		flavorText = "Parang (knife) pattern was once reserved for Javanese royalty.",
		price = 400,
		tier = 2,
	}),

	item({
		id = "sea_batik_sarong_kawung",
		name = "Kawung Batik Sarong",
		category = "Bottom",
		style = "SEA",
		rarity = 3,
		tags = { "malaysian", "indonesian", "batik", "traditional", "geometric", "classic" },
		flavorText = "Kawung's repeating circles represent the sugar palm fruit — one of the oldest batik motifs.",
		price = 350,
		tier = 2,
	}),

	item({
		id = "sea_kebaya_emerald",
		name = "Emerald Lace Kebaya",
		category = "Top",
		style = "SEA",
		rarity = 3,
		tags = { "malaysian", "indonesian", "kebaya", "traditional", "lace", "elegant", "formal" },
		flavorText = "The kebaya is a fitted lace blouse worn across Malaysia, Indonesia, and Singapore.",
		price = 450,
		tier = 2,
	}),

	item({
		id = "sea_kebaya_burgundy",
		name = "Burgundy Lace Kebaya",
		category = "Top",
		style = "SEA",
		rarity = 3,
		tags = { "malaysian", "indonesian", "kebaya", "traditional", "lace", "elegant", "rich" },
		flavorText = "Deep burgundy kebaya — a timeless choice for festive occasions.",
		price = 450,
		tier = 2,
	}),

	item({
		id = "sea_baju_kurung_blue",
		name = "Royal Blue Baju Kurung",
		category = "Dress",
		style = "SEA",
		rarity = 2,
		tags = { "malaysian", "traditional", "baju_kurung", "formal", "modest", "elegant" },
		flavorText = "Baju kurung is Malaysia's national dress — flowing, modest, and beautiful.",
		price = 250,
		tier = 1,
	}),

	item({
		id = "sea_baju_kurung_gold",
		name = "Gold Songket Baju Kurung",
		category = "Dress",
		style = "SEA",
		rarity = 4,
		tags = { "malaysian", "traditional", "baju_kurung", "songket", "gold", "luxurious", "formal" },
		flavorText = "Songket is hand-woven with gold or silver threads — a fabric fit for royalty.",
		price = 1800,
		premiumPrice = 70,
		tier = 3,
	}),

	item({
		id = "sea_batik_shirt",
		name = "Modern Batik Shirt",
		category = "Top",
		style = "SEA",
		rarity = 1,
		tags = { "malaysian", "indonesian", "batik", "casual", "unisex", "modern" },
		flavorText = "The everyday batik shirt — worn to offices, events, and casual outings across SEA.",
		price = 100,
		tier = 1,
	}),

	item({
		id = "sea_songket_skirt",
		name = "Songket Pencil Skirt",
		category = "Bottom",
		style = "SEA",
		rarity = 3,
		tags = { "malaysian", "songket", "traditional", "formal", "elegant", "woven" },
		flavorText = "Songket's intricate gold threading makes every piece a work of art.",
		price = 500,
		tier = 2,
	}),

	item({
		id = "sea_cheongsam_red",
		name = "Crimson Cheongsam",
		category = "Dress",
		style = "SEA",
		rarity = 3,
		tags = { "chinese", "cheongsam", "traditional", "formal", "elegant", "festive" },
		flavorText = "The cheongsam (qipao) in auspicious red — a Lunar New Year staple.",
		price = 500,
		tier = 2,
	}),

	item({
		id = "sea_cheongsam_modern",
		name = "Modern Mini Cheongsam",
		category = "Dress",
		style = "SEA",
		rarity = 3,
		tags = { "chinese", "cheongsam", "modern", "fusion", "trendy", "elegant" },
		flavorText = "A modern mini-length cheongsam blending tradition with contemporary style.",
		price = 550,
		tier = 2,
	}),

	item({
		id = "sea_rattan_bag",
		name = "Handwoven Rattan Bag",
		category = "Bag",
		style = "SEA",
		rarity = 2,
		tags = { "malaysian", "indonesian", "rattan", "natural", "artisan", "bag" },
		flavorText = "Handwoven rattan bags from Borneo — each one is unique.",
		price = 120,
		tier = 1,
	}),

	item({
		id = "sea_tudung_satin",
		name = "Satin Tudung Bawal",
		category = "Headwear",
		style = "SEA",
		rarity = 2,
		tags = { "malaysian", "tudung", "hijab", "modest", "satin", "elegant" },
		flavorText = "The tudung bawal is a square-shaped hijab popular in Malaysia.",
		price = 80,
		tier = 1,
	}),

	item({
		id = "sea_tudung_instant",
		name = "Instant Shawl Hijab",
		category = "Headwear",
		style = "SEA",
		rarity = 1,
		tags = { "malaysian", "tudung", "hijab", "modest", "instant", "modern" },
		flavorText = "The instant shawl — easy to wear and effortlessly chic.",
		price = 60,
		tier = 1,
	}),

	item({
		id = "sea_sandals_traditional",
		name = "Selipar Jepun Sandals",
		category = "Shoes",
		style = "SEA",
		rarity = 1,
		tags = { "malaysian", "sandals", "casual", "traditional", "simple" },
		flavorText = "The classic Malaysian rubber sandals — everyone owns at least one pair.",
		price = 25,
		tier = 1,
	}),

	-- ============================================================
	-- FORMAL / UNIVERSAL (10 items)
	-- ============================================================

	item({
		id = "fm_hanbok_full",
		name = "Full Hanbok Set",
		category = "Dress",
		style = "Formal",
		rarity = 4,
		tags = { "korean", "traditional", "hanbok", "formal", "elegant", "festive" },
		flavorText = "The full hanbok — Korea's traditional dress worn for Seollal and Chuseok celebrations.",
		price = 1600,
		premiumPrice = 65,
		tier = 3,
	}),

	item({
		id = "fm_qipao_full",
		name = "Full-Length Qipao",
		category = "Dress",
		style = "Formal",
		rarity = 4,
		tags = { "chinese", "traditional", "qipao", "formal", "elegant", "classic" },
		flavorText = "The floor-length qipao — timeless Chinese elegance at its finest.",
		price = 1600,
		premiumPrice = 65,
		tier = 3,
	}),

	item({
		id = "fm_sari_drape",
		name = "Silk Sari Drape",
		category = "Dress",
		style = "Formal",
		rarity = 4,
		tags = { "indian", "traditional", "sari", "formal", "elegant", "luxurious" },
		flavorText = "Six meters of pure silk, draped to perfection — the Indian sari is wearable art.",
		price = 1800,
		premiumPrice = 70,
		tier = 3,
	}),

	item({
		id = "fm_blazer",
		name = "Tailored Power Blazer",
		category = "Top",
		style = "Formal",
		rarity = 2,
		tags = { "formal", "blazer", "professional", "modern", "sharp" },
		flavorText = "A sharp blazer makes any outfit boardroom-ready.",
		price = 250,
		tier = 1,
	}),

	item({
		id = "fm_heels_black",
		name = "Classic Black Heels",
		category = "Shoes",
		style = "Formal",
		rarity = 2,
		tags = { "formal", "heels", "classic", "elegant", "black" },
		flavorText = "The little black heel — goes with everything.",
		price = 150,
		tier = 1,
	}),

	item({
		id = "fm_heels_gold",
		name = "Gold Strappy Heels",
		category = "Shoes",
		style = "Formal",
		rarity = 3,
		tags = { "formal", "heels", "gold", "luxurious", "elegant", "festive" },
		flavorText = "Gold heels that catch the light at every step.",
		price = 400,
		tier = 2,
	}),

	item({
		id = "fm_clutch",
		name = "Jeweled Clutch Purse",
		category = "Bag",
		style = "Formal",
		rarity = 2,
		tags = { "formal", "clutch", "elegant", "accessory", "evening" },
		flavorText = "A sparkling clutch for galas and red carpets.",
		price = 180,
		tier = 1,
	}),

	item({
		id = "fm_pearl_necklace",
		name = "Pearl Strand Necklace",
		category = "Accessory",
		style = "Formal",
		rarity = 2,
		tags = { "formal", "pearl", "elegant", "classic", "accessory", "jewelry" },
		flavorText = "Pearls never go out of style.",
		price = 160,
		tier = 1,
	}),

	item({
		id = "fm_updo",
		name = "Elegant Updo Hairstyle",
		category = "Hair",
		style = "Formal",
		rarity = 2,
		tags = { "formal", "updo", "elegant", "classic", "hair" },
		flavorText = "A swept-up hairstyle for the most formal occasions.",
		price = 120,
		tier = 1,
	}),

	item({
		id = "fm_evening_gown",
		name = "Starlight Evening Gown",
		category = "Dress",
		style = "Formal",
		rarity = 5,
		tags = { "formal", "gown", "elegant", "luxurious", "glitter", "evening", "red_carpet" },
		flavorText = "A show-stopping gown that sparkles like the night sky.",
		price = 5000,
		premiumPrice = 200,
		tier = 4,
	}),

	item({
		id = "fm_formal_pants",
		name = "Tailored Formal Trousers",
		category = "Bottom",
		style = "Formal",
		rarity = 1,
		tags = { "formal", "pants", "professional", "classic", "sharp" },
		flavorText = "Clean lines and a perfect fit.",
		price = 120,
		tier = 1,
	}),
}

-- Build lookup table by ID for O(1) access
ItemCatalog.ById = {}
for _, itemData in ItemCatalog.Items do
	ItemCatalog.ById[itemData.id] = itemData
end

-- Get all items of a specific style
function ItemCatalog.getByStyle(style: string): { any }
	local results = {}
	for _, itemData in ItemCatalog.Items do
		if itemData.style == style then
			table.insert(results, itemData)
		end
	end
	return results
end

-- Get all items of a specific category
function ItemCatalog.getByCategory(category: string): { any }
	local results = {}
	for _, itemData in ItemCatalog.Items do
		if itemData.category == category then
			table.insert(results, itemData)
		end
	end
	return results
end

-- Get all items of a specific rarity
function ItemCatalog.getByRarity(rarity: number): { any }
	local results = {}
	for _, itemData in ItemCatalog.Items do
		if itemData.rarity == rarity then
			table.insert(results, itemData)
		end
	end
	return results
end

-- Get all non-event items (available in regular shop)
function ItemCatalog.getShopItems(): { any }
	local results = {}
	for _, itemData in ItemCatalog.Items do
		if not itemData.eventOnly then
			table.insert(results, itemData)
		end
	end
	return results
end

-- Get starter items (given to new players for free)
function ItemCatalog.getStarterItems(): { string }
	return {
		"kf_oversized_hoodie",
		"kf_wide_leg_pants",
		"kf_crop_top",
		"kf_sneakers_white",
		"jf_graphic_tee",
		"jf_plaid_skirt",
		"sea_batik_shirt",
		"sea_sandals_traditional",
		"fm_formal_pants",
		"fm_blazer",
	}
end

return ItemCatalog
