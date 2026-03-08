# Biz Discovery — Automated Business Opportunity Engine

_Artemis scouts. Athena validates. Dreami creates. Hermes launches. GAIA scales._

## Purpose

Automatically discover, validate, and blueprint profitable business opportunities. Based on Ali Akbar's Spy-Clone-Scale and Seena Rez's Dopamine Formula — but fully automated through GAIA's 9-agent pipeline.

## The Pipeline

```
DISCOVER → VALIDATE → BLUEPRINT → BUILD → LAUNCH
(Artemis)  (Athena)   (Dreami)   (Taoz)  (Hermes)
                      (Hermes)   (Iris)
```

## Commands

### Daily Discovery Scan (Artemis)
```bash
bash ~/.openclaw/skills/biz-discovery/scripts/biz-scout.sh scan
```
Scans: TikTok Creative Center trends, Shopee MY bestsellers, Meta Ad Library (long-running ads), Google Trends MY.
Outputs opportunity cards to `workspace/data/biz-opportunities/`.

### Validate Opportunity (Athena)
```bash
bash ~/.openclaw/skills/biz-discovery/scripts/biz-scout.sh validate <opportunity-id>
```
Checks: active ad count (50+?), ad longevity (30+ days?), single-product focus?, 5x markup possible?, supplier available?, not saturated in MY?

### Score & Rank (Athena)
```bash
bash ~/.openclaw/skills/biz-discovery/scripts/biz-scout.sh rank
```
Ranks all validated opportunities by composite score (demand × margin × competition_gap × trend_momentum).

### Blueprint (Dreami + Hermes)
```bash
bash ~/.openclaw/skills/biz-discovery/scripts/biz-scout.sh blueprint <opportunity-id>
```
Generates: product page copy, 10 hook variants (3-Second Rule), pricing strategy, funnel structure, ad creative briefs.

### Alert to Jenn (Zenni)
```bash
bash ~/.openclaw/skills/biz-discovery/scripts/biz-scout.sh alert
```
Sends top 3 scored opportunities to Jenn via WhatsApp with one-line summary + score.

## Scoring Formula (Ali Akbar + Seena Rez)

```
Score = (Active_Ads × 0.25) + (Ad_Longevity × 0.20) + (Margin_Potential × 0.20)
      + (Trend_Momentum × 0.15) + (MY_Gap × 0.10) + (Content_Angle × 0.10)
```

| Factor | Source | Weight |
|--------|--------|--------|
| Active Ads (50+ = validated) | Meta Ad Library, TikTok Creative Center | 25% |
| Ad Longevity (30+ days = profitable) | Meta Ad Library (date tracking) | 20% |
| Margin Potential (5x+ markup) | Supplier cost vs retail price | 20% |
| Trend Momentum (rising/falling) | Google Trends, TikTok hashtag velocity | 15% |
| MY Gap (trending globally, not in MY) | Shopee MY search volume vs US/UK | 10% |
| Content Angle (UGC/organic potential) | TikTok organic content availability | 10% |

## 3 Business Models Detected

| Model | Margin | Agent Lead | Auto-Level |
|-------|--------|------------|------------|
| Digital Products (templates, ebooks, courses) | ~100% | Dreami + Iris | Full auto — AI creates the product |
| Physical Dropship (spy-validated products) | 25-40% | Hermes + Artemis | Semi-auto — needs supplier vetting |
| AI Services (GAIA as managed service) | 90%+ | Taoz + Zenni | Manual — needs client relationship |

## Agent Responsibilities

| Agent | Discovery Role |
|-------|---------------|
| **Artemis** | Daily scans: trends, products, competitor ads, market gaps. Uses: web-read, scrapling, pinchtab, content-scraper |
| **Athena** | Validate & score: ad count, longevity, margin calc, trend analysis. Reads vault.db patterns |
| **Dreami** | Blueprint: ad copy (Harmonic Trio hooks), scripts (Dopamine Cycles), product descriptions |
| **Hermes** | Pricing, funnel design, supplier sourcing, launch execution, revenue tracking |
| **Iris** | Ad creatives, product visuals, video ads (Kling/Sora) |
| **Taoz** | Build store/funnel infra, automate fulfillment pipeline |
| **Zenni** | Alert Jenn, orchestrate multi-agent blueprint execution |
| **Myrmidons** | Bulk ops: product imports, price monitoring, content distribution |
| **Argus** | QA: store health, ad performance, fulfillment quality |

## Seena Rez Rules (Embedded in Dreami)

1. **3-Second Rule**: Every hook must win in 3 seconds
2. **Harmonic Trio**: Curiosity + Relevance + Urgency in every hook
3. **Dopamine Cycles**: 0-1s hook, 2-4s tension, 5-8s payoff
4. **Hyperauthenticity**: AI = engine, NOT the face. Content must feel genuine
5. **Series Format**: Every brand gets at least 1 episodic content series
6. **Organic First**: Prove with organic TikTok → scale with Spark Ads

## Data Sources

| Source | Tool | Cost |
|--------|------|------|
| TikTok Creative Center | tiktok-trends skill (Playwright) | Free |
| Meta Ad Library | meta-ads-library skill (Playwright) | Free |
| Shopee MY | product-scout skill (Playwright) | Free |
| Google Trends | Google Trends API | Free |
| Competitor stores | scrapling-fetch / pinchtab-browse | Free |
| TikTok Shop sales | Apify (when installed) | $49/mo |

## Compound Learning

Every discovery cycle writes to vault.db:
- `source_type: 'biz-opportunity'` — raw opportunities
- `source_type: 'biz-validation'` — validation results
- `source_type: 'biz-pattern'` — what worked/didn't (post-launch)

Athena reads historical patterns to improve scoring over time.

## Cron Schedule (Recommended)

```
# Daily discovery scan at 9am MYT
0 9 * * * bash ~/.openclaw/skills/biz-discovery/scripts/biz-scout.sh scan >> ~/.openclaw/logs/biz-discovery.log 2>&1

# Alert top opportunities at 10am MYT
0 10 * * * bash ~/.openclaw/skills/biz-discovery/scripts/biz-scout.sh alert >> ~/.openclaw/logs/biz-discovery.log 2>&1
```
