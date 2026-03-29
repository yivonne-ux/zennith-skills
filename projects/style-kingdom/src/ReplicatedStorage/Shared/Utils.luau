--!strict
-- Style Kingdom — Shared Utility Functions

local Constants = require(script.Parent.Constants)

local Utils = {}

-- Calculate XP required to reach a given level
function Utils.xpForLevel(level: number): number
	return math.floor(Constants.XP_BASE * (level ^ Constants.XP_EXPONENT))
end

-- Calculate total XP required from level 1 to a target level
function Utils.totalXpToLevel(level: number): number
	local total = 0
	for i = 1, level - 1 do
		total += Utils.xpForLevel(i)
	end
	return total
end

-- Get the star rating from an outfit score (for customer satisfaction)
function Utils.getStarRating(score: number): number
	local stars = 1
	for s = 5, 1, -1 do
		if score >= Constants.CUSTOMER_STAR_THRESHOLDS[s] then
			stars = s
			break
		end
	end
	return stars
end

-- Calculate customer payment based on stars, tier, and prestige
function Utils.calculatePayment(stars: number, boutiqueTier: number, prestigeCount: number): number
	local basePay = Constants.CUSTOMER_BASE_PAY[stars] or 10
	local tierMultiplier = 1 + (boutiqueTier - 1) * 0.2 -- +20% per tier
	local prestigeMultiplier = Constants.PRESTIGE_MULTIPLIERS[prestigeCount] or 1.0
	local tip = if stars == 5 then Constants.CUSTOMER_TIP_5STAR else 0

	return math.floor((basePay + tip) * tierMultiplier * prestigeMultiplier)
end

-- Calculate offline earnings
function Utils.calculateOfflineEarnings(
	hoursOffline: number,
	boutiqueTier: number,
	prestigeCount: number,
	hasDoubleIncome: boolean
): number
	local cappedHours = math.min(hoursOffline, Constants.OFFLINE_MAX_HOURS)
	local tierData = Constants.BOUTIQUE_TIERS[boutiqueTier]
	if not tierData then
		return 0
	end

	local baseRate = tierData.earningRate
	local prestigeMultiplier = Constants.PRESTIGE_MULTIPLIERS[prestigeCount] or 1.0
	local doubleMultiplier = if hasDoubleIncome then 2 else 1

	return math.floor(
		cappedHours * baseRate * Constants.OFFLINE_RATE_MULTIPLIER * prestigeMultiplier * doubleMultiplier
	)
end

-- Calculate vote weight based on player level
function Utils.getVoteWeight(level: number): number
	local t = math.clamp((level - 1) / (Constants.MAX_LEVEL - 1), 0, 1)
	return Constants.VOTE_WEIGHT_MIN + t * (Constants.VOTE_WEIGHT_MAX - Constants.VOTE_WEIGHT_MIN)
end

-- Get today's date as string (YYYY-MM-DD)
function Utils.getTodayString(): string
	local now = os.date("!*t")
	return string.format("%04d-%02d-%02d", now.year, now.month, now.day)
end

-- Format currency with commas (e.g., 1234567 -> "1,234,567")
function Utils.formatNumber(n: number): string
	local formatted = tostring(math.floor(n))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

-- Deep copy a table
function Utils.deepCopy(original: any): any
	if type(original) ~= "table" then
		return original
	end
	local copy = {}
	for key, value in original do
		copy[Utils.deepCopy(key)] = Utils.deepCopy(value)
	end
	return copy
end

-- Shuffle an array in-place (Fisher-Yates)
function Utils.shuffle(arr: { any })
	for i = #arr, 2, -1 do
		local j = math.random(i)
		arr[i], arr[j] = arr[j], arr[i]
	end
end

-- Pick a random item from a weighted table { {item, weight}, ... }
function Utils.weightedRandom(items: { { any } }): any
	local totalWeight = 0
	for _, entry in items do
		totalWeight += entry[2]
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in items do
		cumulative += entry[2]
		if roll <= cumulative then
			return entry[1]
		end
	end

	return items[#items][1]
end

return Utils
