---
name: Master Session Learnings — March 24-25, 2026
description: COMPREHENSIVE. All skills unlocked, yes/no decisions, systems built, design learnings. Biggest session ever — ads automation + creative production + intelligence.
type: feedback
---

## SESSION OVERVIEW
Date: March 24-25, 2026
Scope: Pinxin + Mirra ads automation, creative production, intelligence system
Duration: ~10 hours

## NEW SKILLS UNLOCKED

### 1. Automated Ads Monitoring System (Zennith)
- `autoads_analyzer.py` — kill/scale/creative recs, 2x daily
- `autoads_forensic.py` — weekly deep audit + creative brief
- `autoads_sheet_attribution.py` — WA sales → ad ID matching, daily
- Claude remote agent — daily Meta intelligence sweep
- Offline conversions — Mirra + Pinxin CAPI nightly uploads

### 2. Reference-Based Mood Photography
- Prompt-only color direction FAILS for NANO — must use mood image as Image 1
- 4 mood references define Pinxin's color DNA (burgundy/chiaroscuro/green-gold/sage)
- Location: `_shared/references/mood-photography/` + `pinxin/04_references/format-specific/mood-photography/`

### 3. Two-Pass 4:5→9:16 Production Workflow
- Generate at 4:5 (OUTPUT_SPEC_45) → blur-extend → NANO EXTEND_916_PROMPT → logo → grain
- UNIVERSAL rule for ALL brands. Never generate at 9:16 directly.

### 4. 6-Layer Design Audit
- Tonal separation, layout composition, distortion, seam detection, color grading, food pixel-match
- Must run ALL 6 layers on every output. "Looks fine" is not an audit.

### 5. Food Signature Marker Verification
- Each Pinxin dish has unique markers (petai beans, purple eggplant, okra, black fungus, etc)
- NANO remixes food into generic dishes with 3+ inputs → max 1-2 food cutouts per ad
- Include markers in prompt: "MUST show GREEN PETAI BEANS"

### 6. WA Sales Attribution Engine
- Google Sheet ad ID extraction → ad name matching → per-ad ROAS
- Mirra: only 11% of orders have ad IDs (89% unattributed)
- Sales Boom Boom = top proven formula (6 orders, RM2,535)
- Conversation volume ≠ purchase volume (S19 = 156 convos, 1 sale)

### 7. Meta Ads Intelligence 2026
- Andromeda = creative-first (entity IDs, not audience targeting)
- Malaysia CPM $3.42 (83% cheaper than US)
- Only 5% of ads become winners → need volume
- API v21→v22 updated. v25 has breaking attribution changes.

## YES DECISIONS (Do More)

1. ✅ **Single hero dish per ad** — NANO preserves food faithfully with 1 input
2. ✅ **Explicit signature markers in prompts** — forces NANO to keep distinctive features
3. ✅ **Proven winners as structural references** — BOFU-18/02/10 as Image 1
4. ✅ **Identity gimmick formats** — bank statement, calculator, notification, boarding pass, receipt
5. ✅ **Mood reference as Image 1** — color anchor, not prompt text
6. ✅ **Two-pass 4:5→9:16** — content in Meta safe zone
7. ✅ **Real packaging photos** — pkg-*.png from local-cache, never AI
8. ✅ **Combo pricing only** — 买8送8, RM12++/盒, never per-dish RM
9. ✅ **Reference fatigue check** before every batch
10. ✅ **3-day ROAS scale trigger** — Pinxin >2.3x, Mirra >3.0x
11. ✅ **Bold 3D typography** — RM12++ 一盒 = strongest scroll-stopper
12. ✅ **Lo-fi retarget ads** — "你忘了结账!" = direct, effective
13. ✅ **Daily sheet attribution** — only source of truth for WA ad performance
14. ✅ **Sales Boom Boom creative formula** — proven top seller for Mirra
15. ✅ **CAPI nightly uploads** — compounds Meta's purchase optimization

## NO DECISIONS (Never Repeat)

1. ❌ **NEVER generate at 9:16 directly** — content outside Meta safe zones
2. ❌ **NEVER give NANO 3+ food cutouts** — remixes into generic dishes
3. ❌ **NEVER let NANO generate packaging** — use real pkg-*.png
4. ❌ **NEVER let NANO generate logos** — PIL composite only
5. ❌ **NEVER write fictional per-dish prices** — real: RM21.90/dish, combo: RM12++
6. ❌ **NEVER use prompt-only color direction** — NANO ignores text, copies Image 1
7. ❌ **NEVER audit food as "looks like food"** — must pixel-match signature markers
8. ❌ **NEVER use the word "logo" in prompts** — NANO renders it literally
9. ❌ **NEVER trust conversation metrics for Mirra** — 89% orders unattributed
10. ❌ **NEVER scale Mirra on per-ad ROAS** — data too sparse, use blended only
11. ❌ **NEVER assume Meta's "50 purchases" rule** — Malaysian small budgets use 3-day ROAS trigger instead
12. ❌ **NEVER use sage/Lee Ho Ma mood ref** — contains egg, Pinxin is vegan
13. ❌ **NEVER re-use fatigued references** — check fatigue before every batch
14. ❌ **NEVER pass "borderline" in audit** — if you hesitate, it fails

## SYSTEMS BUILT (Persistent)

| System | Location | Schedule |
|--------|----------|----------|
| autoads_report.py | _shared/creative-intelligence/autoads/ | 5x daily cron |
| autoads_analyzer.py | same | 2x daily cron (10AM, 10PM) |
| autoads_forensic.py | same | Sunday midnight cron |
| autoads_sheet_attribution.py | same | Daily 8AM cron |
| offline_conversions.py | apex-meta/scripts/ | 11:37 PM cron |
| offline_conversions_pinxin.py | same | 11:40 PM cron |
| Intelligence Sweep | Claude remote agent | Midnight daily |
| META-ADS-INTELLIGENCE-2026-Q1.md | _shared/intelligence/ | Manual update |
| Mood references | _shared/references/mood-photography/ | Permanent |
| pinxin_batch_w3.py | pinxin/05_scripts/ | On-demand |
| TRICIA-VIDEO-BRIEF.md | pinxin/ | Ready for Tricia |

## BUDGET STATE (After midnight tonight)

| Brand | Campaign | Before | After |
|-------|----------|--------|-------|
| Pinxin | Website-LC | RM300 | RM360 |
| Pinxin | CTWA-SALES | RM400 | RM480 |
| Pinxin | Retarget | RM50 | RM60 |
| Mirra | Sales EN | RM300 | RM360 |
| Mirra | Scale EN-WA | RM300 | RM360 |
| Mirra | RT CN | RM100 | RM100 (hold) |
| Mirra | RT EN | RM100 | RM100 (hold) |
| **TOTAL** | | **RM1,550** | **RM1,820/day** |
