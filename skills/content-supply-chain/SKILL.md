# Content Supply Chain — Self-Improving Creative Loop

**Owner:** Zenni (orchestration), all agents participate
**Cost:** $0 base (Gemini CLI + keyword routing), API cost only for dispatched agent tasks

## The Loop

```
RESEARCH → STRATEGY → BRIEF → CREATE → PRODUCE → DISTRIBUTE → ANALYZE → LEARN → LOOP
   ↑                                                                              |
   └──────────────────────── compound learnings feed back ─────────────────────────┘
```

Each cycle compounds: learnings from cycle N feed into cycle N+1 automatically.

## Agent Responsibilities per Stage

| Stage | Owner | Skills Used | Engine |
|-------|-------|-------------|--------|
| RESEARCH | Artemis | content-seed-bank, web-search-pro, meta-ads-library | OpenClaw |
| STRATEGY | Athena + Hermes | campaign-planner, creative-taxonomy, funnel-playbook | OpenClaw |
| BRIEF | Hermes + Dreami | campaign-planner, ideation-engine, content-ideation-workflow | OpenClaw |
| CREATE | Dreami | gemini-runner.sh (creative), content-seed-bank | Gemini CLI |
| PRODUCE | Iris | ad-composer, creative-factory, video-gen | OpenClaw + NanoBanana |
| DISTRIBUTE | Iris + Hermes | social-publish, meta-ads-manager | OpenClaw |
| ANALYZE | Athena + Hermes | ad-performance, growth-engine, content-tuner | OpenClaw |
| LEARN | System | knowledge-compound, resolve-learnings, digest.sh | Local ($0) |

## Content Matrix

Each cycle can target combinations of:
- **Channels:** IG, FB, TikTok, Shopee, EDM, WhatsApp
- **Personas:** Per brand direction (e.g., Office Girls, Gym Bros, Health Moms)
- **Languages:** EN, CN, BM
- **Formats:** M1-M5 (MOFU) + B1-B4 (BOFU) = 9 template types
- **Brands:** 7 active F&B/wellness brands
- **Timing:** Weekly cycles, daily micro-cycles for winning content
- **Offers:** Promotions, bundles, seasonal campaigns

## Usage

```bash
# Full cycle for a brand
bash ~/.openclaw/skills/content-supply-chain/scripts/content-supply-chain.sh cycle --brand mirra

# Dry run (see what would happen)
bash ~/.openclaw/skills/content-supply-chain/scripts/content-supply-chain.sh cycle --brand mirra --dry-run

# Target specific direction
bash ~/.openclaw/skills/content-supply-chain/scripts/content-supply-chain.sh cycle --brand mirra --direction en-1

# Single stage
bash ~/.openclaw/skills/content-supply-chain/scripts/content-supply-chain.sh run-stage create --brand mirra

# Check status
bash ~/.openclaw/skills/content-supply-chain/scripts/content-supply-chain.sh status --brand mirra

# View content matrix
bash ~/.openclaw/skills/content-supply-chain/scripts/content-supply-chain.sh matrix --brand mirra

# Cycle history
bash ~/.openclaw/skills/content-supply-chain/scripts/content-supply-chain.sh history --brand mirra
```

## Compound Learning Architecture

Three layers, all feeding back into the loop:
1. **Global** — Cross-brand patterns (what works everywhere)
2. **Category** — Per-category insights (F&B, wellness, etc.)
3. **Brand** — Brand-specific learnings (mirra bento vs pinxin vegan)

Resolved via `resolve-learnings.py --brand <brand>` at STRATEGY stage.

## Cron Integration

```bash
# Weekly full cycle (Monday 9am MYT)
0 9 * * 1 bash ~/.openclaw/skills/content-supply-chain/scripts/content-supply-chain.sh cycle --brand mirra
# Daily micro-cycle: analyze + learn only
0 22 * * * bash ~/.openclaw/skills/content-supply-chain/scripts/content-supply-chain.sh run-stage analyze --brand mirra && bash ~/.openclaw/skills/content-supply-chain/scripts/content-supply-chain.sh run-stage learn --brand mirra
```
