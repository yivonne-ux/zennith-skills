# Zennith OS — Project State
> Last updated: 2026-03-18 by Zenki (MacBook Claude Code Opus 4.6)
> This file is the shared brain. Every Claude Code instance reads this.
> Update after every significant build/deploy/decision.

---

## Active Projects

### 1. Jade Oracle (@Jade4134bot) — LIVE
**Status**: Running on VPS (jade-os.fly.dev)
**What**: AI psychic consultant on Telegram, powered by real QMDJ (奇门遁甲) divination
**Model**: deepseek/deepseek-chat-v3-0324 via OpenRouter (claude-sonnet-4-6 fallback)

**Architecture**:
- `jade-bot-v3.js` — Telegram bot + Shopify webhook handler (50KB)
- `jade-interpretation-engine.js` — Oracle card system (25 cards mapped to QMDJ symbols)
- `qmdj-engine.js` — QMDJ calculator (阴盘, 长卿 school, numeric formula)
- `qmdj-knowledge.json` — 363KB knowledge base (81 stem combos, bilingual)

**Key decisions**:
- Default to 时盘 (moment reading) for ALL questions — no birth data needed
- Birth data (命盘) only collected when user explicitly asks for /reading or /bazi
- Once collected, birth data saved to disk (`users/{chatId}.json`) — never asked again
- Gender saved for love readings — never re-asked
- After 3rd shipan reading, Jade casually offers birth chart option (once per user)
- MAX 1 question before reading (just topic, or gender for love). No menus.
- Tone: personal psychic friend, lowercase, casual, no Chinese characters in output

**Validated**: QMDJ engine 5/5 against yrydai.com app
| Test | Engine | App | Match |
|------|--------|-----|-------|
| 2026-03-17 16:22 时盘 | 阳遁1局 | 阳遁1局 | ✅ |
| 2026-03-18 15:43 时盘 | 阳遁2局 | 阳遁2局 | ✅ |
| 1991-12-08 命盘 | 阴遁4局 | 阴遁4局 | ✅ |
| 1998-10-30 命盘 | 阴遁3局 | 阴遁3局 | ✅ |
| 2026-03-18 18:13 时盘 | 阳遁3局 | 阳遁3局 | ✅ all 8 palaces |

**NOT yet built**:
- Shopify store (product pages, checkout)
- PDF reading reports (code exists, not connected to bot)
- Email delivery (code exists, no API keys)
- Web login / user auth
- Western astrology + tarot integration in bot (engines exist, not wired)
- Ad campaigns / TikTok / IG content pipeline

**VPS files** (jade-os.fly.dev:/home/node/.openclaw/data/):
- `jade-telegram-bot.js` — the running bot (= jade-bot-v3.js)
- `jade-interpretation-engine.js` — deployed
- `qmdj-engine.js` — deployed
- `reading-engine/data/` — knowledge bases deployed
- `workspace-jade/SOUL.md` — personality file
- `users/` — persistent user data (per-user JSON files)

**CRITICAL**: Bot token was revoked and regenerated. New token ONLY on VPS env vars. NEVER put in local files or git.

---

### 2. Zennith OS (Multi-Agent System) — RUNNING
**Status**: 4 agents on local iMac via OpenClaw gateway
**Agents**: Zenni (gpt-5.4), Taoz (Claude Code), Dreami (gemini-3.1-pro), Scout (gemini-3-flash)
**Skills**: 62 active, all in this repo
**Routing**: classify.sh (keyword-based, zero LLM cost, 67/67 tests pass)

---

### 3. DTC Product Research & Sourcing — READY FOR SAMPLES
**Status**: Research complete. Ready for supplier contact + sample ordering.
**Source**: Zenki (MacBook Claude Code Opus 4.6) — synced 2026-03-18
**Files**: `workspace/knowledge/product-research/` (9 CSVs + 18 reports)
**Full sync doc**: `workspace/knowledge/ZENKI-SYNC.md`

**Key data**:
- 70 products scored (Ali Akbar 12-checkbox method)
- 14 products fully developed with forensic analysis + superior blueprints
- 49 suppliers vetted on Alibaba International
- 56 suppliers found on 1688.com (domestic China — 30-70% cheaper)
- 25 products formatted for 1688 batch sourcing upload (xlsx template)
- Supplier contact messages drafted for all 14 products

**Priority launch order**:
1. Tier 1: Vertigo supplement, Skin Flooding Kit, Oral Probiotic Lozenge
2. Tier 2: Beef Organ, Astaxanthin Complex, Anti-Snoring Mouthpiece
3. Tier 3: Scent Necklace, GHK-Cu Serum, Pheromone Perfume, Tuning Fork

**Top margin products from 1688**:
- Scent necklace: ¥2.60 source → $35-45 sell (99% margin, 466K sold on 1688)
- Tuning fork set: ¥39 source → $55 sell (90% margin, 177K sold)
- Ear seeds: ¥0.77 source → $39.99 sell (99.7% margin, 52K sold)

**Next steps**: Send supplier contact messages (Tier 1 first) → order samples → test → brand → launch

---

### 4. Ling Xi (灵犀) — STRATEGY COMPLETE
**Status**: Master strategy written, not yet built
**What**: AI-powered BaZi + QMDJ + 数字能量学 platform for Asian markets
**Sister brand**: Jade Oracle (English) ↔ Ling Xi (Chinese)
**Strategy file**: `workspace/knowledge/LING-XI-MASTER-STRATEGY-2026.md`

---

### 5. Brand Machine — IN PROGRESS
**Brands**: 14 (pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein, jade-oracle, gaia-os, gaia-print, gaia-learn, gaia-recipes, gaia-supplements, iris)
**Core F&B**: pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein
**MIRRA** = bento-style health food (NOT skincare)

---

## Team

| Person | Role | Claude Code | Focus |
|--------|------|-------------|-------|
| Jenn | CEO | This machine (iMac) | Strategy, Jade Oracle, system architecture |
| Tricia | Designer | MacBook | Video workflows, image refine, brand visuals, ad creative |
| Yivonne | Ops | MacBook | Ad upload, content scheduling, multi-brand ops |

---

## Key Technical Decisions

1. **QMDJ lineage**: 阴盘 (Yin Plate), 长卿 school, NOT 翁向宏
2. **局数 formula**: `(年支序+时支序+农历月+农历日) % 9` (if 0→9)
3. **Oracle cards**: 25 proprietary cards (9 Archetype from 九星, 8 Pathway from 八门, 8 Guardian from 八神)
4. **Copy business model**: Identify winning online businesses → clone with AI → scale via agents
5. **First clone target**: Psychic Samira ($500K+/mo) → The Jade Oracle
6. **All $0 models**: gpt-5.4 (OAuth), gemini-cli (OAuth), Claude Code (Max subscription)
7. **openclaw.json has API keys** — excluded from git, stays local per machine

---

## Critical Lessons (Don't Repeat)

1. **Hallucination cascade** (2026-03-10): Taoz built LOCAL files, marked "success". Zenni read success → wrote "Store live" → fake analysis across 97 files. NOTHING WAS REAL. **Rule**: Local files ≠ live. Verify at source.
2. **Zenni dispatch hallucination**: Says "Dispatched to X" but never calls the tool. **Fix**: dispatch.sh auto-executes.
3. **NanoBanana brand bleed**: GAIA OS watermarks, tarot imagery bleeding into food brand images. **Fix**: Use --raw or --use-case character.
4. **HeyGen rejected**: For Jade videos. Don't use again.
5. **Google blocks Playwright**: Must use real Chrome or bypass OAuth.

---

## Repo Structure

```
zennith-skills/                    ← THIS REPO
├── skills/                        ← 62 skills (the intelligence)
├── brands/                        ← 14 brand DNA configs
├── workspace-*/SOUL.md            ← agent identities
├── workspace/scripts/             ← shared utilities
├── workspace/rooms/               ← agent communication
├── bin/                           ← CLI tools
├── CLAUDE.md                      ← auto-generated system docs
├── PROJECT-STATE.md               ← THIS FILE (shared brain)
└── .gitignore
```

**Not in repo** (local per machine):
- `openclaw.json` — API keys
- `workspace/data/images/` — generated images (8GB+)
- `workspace/data/videos/` — generated videos
- User sessions, memory, credentials

---

## How to Contribute

```bash
# Clone
git clone https://github.com/jennwoei316/zennith-skills.git ~/.openclaw-sync
# Or if ~/.openclaw/ already exists:
cd ~/.openclaw && git init && git remote add origin https://github.com/jennwoei316/zennith-skills.git
git fetch origin && git merge origin/main --allow-unrelated-histories

# Daily
git pull                          # get everyone's changes
# ... build stuff ...
git add -A && git commit -m "what you did" && git push

# Symlink skills to Claude Code
ln -sf ~/.openclaw/skills/* ~/.claude/skills/
```

**After significant work**: Update this PROJECT-STATE.md and push.
