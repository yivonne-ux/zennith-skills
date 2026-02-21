---
name: brand-intel
version: "1.0.0"
description: "Deep brand research and competitive intelligence. Scrapes, analyzes, and builds Brand DNA Cards for every GAIA brand. Social listening, sentiment analysis, competitor tracking, and market positioning."
---

# Brand Intelligence — Deep Research Engine

## Purpose
Know YOUR brands better than anyone. Scrape everything, analyze patterns, build Brand DNA Cards, track sentiment, find gaps.

## GAIA Brand Portfolio

| Brand | Category | Status | Platforms |
|---|---|---|---|
| **Gaia Eats** | D2C supplements, meals | Active | Shopify, IG, FB, TikTok |
| **Pinxin Vegan Cuisine** | Poon Choi, Matsu, Sour Soup | Active | Shopify, IG, FB |
| **Wholey Wonder** | Wellness products | Active | Shopee, Lazada |
| **Wholey Wonder Damai** | Wellness variant | Active | Shopee, Lazada |
| **Rasaya Wellness 绿生原** | TCM wellness | Active | Shopee, own site |
| **Mirra Eats** | Meal delivery | Active | Own platform |
| **Mirra Meals** | Meal subscription | Active | Own platform |

## Brand DNA Card (Template)

For each brand, generate:

```yaml
brand_name: "Gaia Eats"
tagline: ""
category: "D2C plant-based food & supplements"
positioning:
  who: "Health-conscious Malaysians 25-45"
  what: "Premium plant-based food products"
  why: "Taste without compromise, health without sacrifice"
  how: "Traditional recipes reimagined with modern nutrition science"

voice:
  tone: ["warm", "authentic", "Malaysian"]
  language: ["English", "Malay", "some Chinese"]
  personality: "Like a friend who cooks amazing food and happens to be health-conscious"
  dos: ["use local language naturally", "celebrate Malaysian food culture"]
  donts: ["preachy about veganism", "clinical/medical claims", "condescending"]

visual_identity:
  primary_colors: ["#sage-green", "#gold", "#cream"]
  secondary_colors: ["#earth-brown", "#leaf-green"]
  photography_style: "warm, natural lighting, overhead flat-lays, close-up textures"
  video_style: "authentic, LoFi, kitchen setting, hands visible"
  typography: "clean sans-serif headers, warm serif body"

audience:
  primary:
    age: "28-40"
    gender: "60F/40M"
    interests: ["health", "cooking", "sustainability", "family meals"]
    pain_points: ["tasteless healthy food", "time-poor", "expensive organic"]
  secondary:
    age: "22-28"
    interests: ["fitness", "plant-based lifestyle", "social media foodie"]

competitive_landscape:
  direct_competitors: []
  indirect_competitors: []
  competitive_advantage: ""
  market_gaps: []

content_performance:
  best_performing_posts: []
  best_hooks: []
  best_formats: []
  worst_performing: []
  engagement_rate: null

social_presence:
  instagram: { handle: "", followers: null, engagement_rate: null }
  tiktok: { handle: "", followers: null }
  facebook: { page: "", followers: null }
  shopee: { store: "", rating: null, reviews: null }

swot:
  strengths: []
  weaknesses: []
  opportunities: []
  threats: []

seasonal_calendar:
  peak_months: []
  campaign_history: []

last_updated: null
```

## Research Pipeline

### Step 1: Scrape Everything
```bash
# For each brand, run:
bash scrape-queue.sh add --platform meta-ads --target "[brand name]" --type brand_scan
bash scrape-queue.sh add --platform instagram --target "[handle]" --type profile_deep
bash scrape-queue.sh add --platform shopee --target "[store URL]" --type store_scan
bash scrape-queue.sh add --platform site --target "[website URL]" --type full_crawl
bash scrape-queue.sh add --platform google --target "[brand name] review" --type sentiment
```

### Step 2: Social Listening
Monitor mentions, hashtags, and sentiment:
- Brand name mentions (all platforms)
- Product name mentions
- Competitor mentions
- Category keywords (vegan malaysia, plant-based, healthy food KL)
- Sentiment scoring: positive / neutral / negative + trend

### Step 3: Competitor Analysis
For each brand's direct competitors:
- Meta Ads Library scrape (what ads are they running?)
- Social profile analysis (engagement rate, posting frequency, content mix)
- Product/pricing comparison
- Review analysis (what do customers love/hate?)

### Step 4: Generate Brand DNA Card
Compile all data into Brand DNA Card (template above).
Store in `~/.openclaw/workspace/data/brands/[brand-name].yaml`

### Step 5: Gap Analysis
Cross-reference all brands:
- Where are we strong vs weak?
- What competitors do that we don't?
- What content types are we NOT making that work for competitors?
- What audience segments are we missing?

## Social Listening Signals

### Track These Keywords
```
Brand mentions: "gaia eats", "pinxin", "wholey wonder", "rasaya", "绿生原", "mirra eats"
Product mentions: "vegan rendang", "poon choi", "vegan matsu"
Category: "vegan malaysia", "plant-based malaysia", "healthy food KL", "素食"
Competitor: [populated after first competitor scan]
Sentiment triggers: "love", "hate", "amazing", "terrible", "recommend", "avoid"
```

### Alert Thresholds
- Negative sentiment spike (>3 negative mentions in 24h) → Alert Jenn
- Competitor viral content (>10K engagement) → Alert Artemis
- Brand mention by influencer (>10K followers) → Alert Iris
- Product complaint pattern (same issue 3+ times) → Alert operations

## Output

All brand intel stored in:
```
~/.openclaw/workspace/data/brands/
  ├── gaia-eats.yaml
  ├── pinxin-vegan.yaml
  ├── wholey-wonder.yaml
  ├── wholey-wonder-damai.yaml
  ├── rasaya-wellness.yaml
  ├── mirra-eats.yaml
  └── mirra-meals.yaml
```

Updated weekly by Artemis (brand scan cron).

## CHANGELOG
### v1.0.0 (2026-02-20)
- Initial creation: Brand DNA Card template, research pipeline, social listening, competitor analysis
