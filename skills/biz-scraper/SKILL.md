---
name: biz-scraper
description: GAIA E-Commerce Flywheel — Ali Akbar "Spy -> Clone -> Scale" method with AI agents. Scrapes competitors, clones winning funnels, generates content at scale, launches, measures, compounds.
---

# Biz Scraper — GAIA E-Commerce Flywheel

The "Spy -> Clone -> Scale" engine for GAIA CORP-OS. Turns competitor intelligence into ready-to-launch campaigns using the full agent roster.

Based on vault.db knowledge:
- Ali Akbar spy-clone-scale method
- Multi-business expansion: digital dropshipping (100% margin), physical dropshipping (25-40%), AI content ops (90%+)
- Happy Mammoth funnel analysis (upsells, subscriptions, email collection, urgency, AOV $259)
- Seena Rez Dopamine Cycles + Harmonic Trio + 3-Second Rule

## Script

```
~/.openclaw/skills/biz-scraper/scripts/biz-scraper.sh
```

## Commands

### spy — Scrape & score a product/competitor URL
```bash
biz-scraper.sh spy --url <product_url> [--brand <brand>]
```
Scrapes via Jina Reader API, extracts product name, price, funnel indicators, scores opportunity, saves to vault.db.

### spy-niche — Research a niche keyword
```bash
biz-scraper.sh spy-niche --keyword <niche> [--brand <brand>]
```

### clone — Generate campaign brief from opportunity
```bash
biz-scraper.sh clone --id <vault_id> [--brand <brand>]
```

### status — Check flywheel pipeline
```bash
biz-scraper.sh status [--brand <brand>]
```

## Flywheel Architecture

Six stages, each owned by specific agents. Output of each stage feeds the next.

```
  +----------+     +----------+     +----------+
  |  1. SPY  |---->| 2. CLONE |---->|3.GENERATE|
  | Artemis  |     |Dreami+   |     | Iris+    |
  |          |     |Hermes    |     | Dreami   |
  +----------+     +----------+     +----------+
       ^                                  |
       |                                  v
  +----------+     +----------+     +----------+
  |6.COMPOUND|<----|5.MEASURE |<----|4. LAUNCH |
  |  Taoz    |     | Athena   |     | Hermes   |
  +----------+     +----------+     +----------+
```

> Load `references/flywheel-stages.md` for detailed process, inputs, outputs, JSON schemas, and agent-specific tasks for all 6 stages.

### Stage Summary

| Stage | Agent(s) | Purpose | Output |
|-------|----------|---------|--------|
| 1. SPY | Artemis | Scrape + score opportunities | `biz-opportunity` in vault.db |
| 2. CLONE | Dreami + Hermes | Campaign brief from intel | `campaign-brief` in vault.db |
| 3. GENERATE | Iris + Dreami | Produce all creative assets | Content library (images/videos/copy) |
| 4. LAUNCH | Hermes | Deploy to sales channels | Live campaign IDs |
| 5. MEASURE | Athena | Analyze performance, find winners | `campaign-analysis` in vault.db |
| 6. COMPOUND | Taoz | Feed learnings back into system | Patterns in vault.db + updated templates |

## Routing

| Stage | Tier | Agent(s) | Trigger |
|-------|------|----------|---------|
| SPY | DISPATCH | Artemis | `biz-scraper.sh spy --url ...` |
| CLONE | DISPATCH | Dreami, Hermes | `biz-scraper.sh clone --id ...` |
| GENERATE | DISPATCH/SCRIPT | Iris, Dreami | Campaign brief ready |
| LAUNCH | DISPATCH | Hermes | Content library ready |
| MEASURE | DISPATCH | Athena | Campaign live >48h |
| COMPOUND | CODE | Taoz | Analysis complete |

## Dependencies

- Jina Reader API (free tier, no key needed for basic scraping)
- vault.db (`~/.openclaw/workspace/vault/vault.db`)
- NanoBanana (`nanobanana-gen.sh`) for image generation
- video-gen pipeline for video ads
- marketing-formulas skill for ad copy frameworks
- growth-engine skill for pricing models
- Brand DNA files at `~/.openclaw/brands/{brand}/DNA.json`
