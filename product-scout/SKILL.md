---
name: product-scout
version: "1.0.0"
description: Scan Shopee/Lazada for product opportunities across 衣食住行 (clothing, food, housing, transport). Calculates market gap scores and generates opportunity reports.
metadata:
  openclaw:
    scope: research
    guardrails:
      - Public marketplace data only
      - Monthly sales are estimates (cite methodology)
      - Respect rate limits (2s between page loads)
      - All findings go through Zenni for strategic routing
---

# Product Scout — 衣食住行 Opportunity Scanner

## Purpose

Scan Southeast Asian marketplaces (Shopee, Lazada) for product opportunities across all four GAIA pillars. Every new brand starts with data — what sells, what's missing, and where the gaps are.

## The Four Pillars

| Pillar | Category | Example Keywords | Current Brand |
|--------|----------|-----------------|---------------|
| 食 (Food) | Food & Beverage | vegan, plant-based, organic, superfoods, healthy snacks | GAIA Eats (LIVE) |
| 衣 (Fashion) | Apparel & Accessories | streetwear, sustainable fashion, graphic tees, POD | Delulu Club (PLANNED) |
| 住 (Housing) | Home & Living | home decor, wellness, aromatherapy, sustainable living | TBD |
| 行 (Transport) | Travel & Mobility | travel accessories, commute essentials, portable gadgets | TBD |

## Usage

```bash
# Scan food category on Shopee MY
python3 ~/.openclaw/skills/product-scout/scripts/scout_products.py \
  --platform shopee --country MY --category food --keyword "vegan snack"

# Scan fashion opportunities
python3 ~/.openclaw/skills/product-scout/scripts/scout_products.py \
  --platform shopee --country MY --category fashion --keyword "graphic tee"

# Multi-keyword scan
python3 ~/.openclaw/skills/product-scout/scripts/scout_products.py \
  --platform shopee --country MY --category food \
  --keyword "vegan,plant-based,organic snack,superfood"

# Full 衣食住行 scan
python3 ~/.openclaw/skills/product-scout/scripts/scout_products.py \
  --platform shopee --country MY --category all
```

## Output Format

```json
{
  "platform": "shopee",
  "country": "MY",
  "category": "food",
  "keyword": "vegan snack",
  "scraped_at": "2026-02-12T16:00:00Z",
  "products": [
    {
      "name": "Organic Granola Bar 6-Pack",
      "price_myr": 19.90,
      "reviews": 1240,
      "rating": 4.8,
      "monthly_sales_est": 520,
      "seller": "Nature's Best MY",
      "seller_rating": 4.9,
      "url": "https://shopee.com.my/..."
    }
  ],
  "opportunity_analysis": {
    "avg_price": 22.50,
    "price_range": "8.90 - 49.90",
    "top_seller_reviews": 8112,
    "market_gap_score": 7.2,
    "gaps_found": [
      "No Malaysian-made vegan protein bar in top 20",
      "Premium segment (>RM30) has only 3 products but high review counts"
    ],
    "recommendation": "White space exists for a Malaysian premium vegan snack brand at RM25-35 price point"
  }
}
```

## Market Gap Score (1-10)

Calculated from:
- **Low competition** (fewer sellers with >100 reviews) → higher score
- **High demand** (total reviews in category / number of products) → higher score
- **Price gap** (underserved price segments) → higher score
- **Quality gap** (avg rating < 4.5 with demand) → higher score
- **Origin gap** (no local/Malaysian brand in top 20) → higher score

Score 7+ = strong opportunity. Score 5-7 = worth evaluating. Below 5 = competitive.

## Agent Assignment

- **Artemis 🏹** — runs the scans, produces structured data
- **Hermes ⚡** — analyzes pricing and margin potential
- **Athena 🦉** — evaluates market size and growth trends
- **Zenni 👑** — routes high-scoring opportunities to exec room

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: Shopee/Lazada scanner for 衣食住行 with gap analysis
