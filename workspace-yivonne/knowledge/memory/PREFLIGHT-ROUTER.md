---
name: PREFLIGHT ROUTER — Mandatory knowledge loading per task type
description: READ THIS AT SESSION START. Maps every task type to required memory files that MUST be read before action. No exceptions. No judgment. Just load.
type: feedback
---

# PREFLIGHT ROUTER

**WHEN TO USE:** At the START of every session AND before every task below.
**HOW:** Read the required files listed. Don't summarize from memory — actually READ them fresh. Rules change, data updates.

---

## TASK: ADS ANALYSIS / REPORTING

**Before pulling any ads data or making any recommendation:**

```
MUST READ:
1. feedback_PREFLIGHT_ALL_ACTIONS.md          — action checklist (budget/kill/scale rules)
2. feedback_meta_ads_hard_rules_march22.md    — 10 hard rules (20% budget, 48hr wait, dual-channel)
3. feedback_meta_budget_algorithm_rules.md    — budget math, time-of-day, token management
4. project_pinxin_campaign_state_march22.md   — campaign IDs, current state, decisions log
5. project_mirra_meta_ads_compounding_ledger.md — Mirra campaign state

MUST PULL (live data):
- Meta API: campaign spend, ad-level performance
- Google Sheet: WA sales with ad ID matching
- Shopify: web orders (Pinxin)
```

## TASK: BUDGET CHANGE / SCALE / KILL

**Before recommending ANY change:**

```
MUST READ:
1. feedback_PREFLIGHT_ALL_ACTIONS.md          — the full checklist
2. feedback_meta_ads_hard_rules_march22.md    — Rule 1: stop changes, Rule 2: bid progression
3. feedback_meta_budget_algorithm_rules.md    — 20% max, 48hr wait

MUST VERIFY:
- Last budget change date (check cron logs + midnight scripts)
- Current budget (API, not memory — it may have been changed)
- 3-day ROAS (Pinxin >2.3x, Mirra >3.0x)
- Is this the ONLY change? (one at a time)
- Schedule for midnight (never during active hours)
```

## TASK: CREATIVE PRODUCTION

**Before writing any production script or brief:**

```
MUST READ:
1. feedback_pinxin_w3_compound_learnings.md   — all yes/no from W3
2. feedback_pinxin_mood_photography_reference.md — mood ref as Image 1
3. feedback_pinxin_production_workflow_916.md  — 4:5 → 9:16 two-pass
4. feedback_pinxin_pricing_actual.md          — real RM pricing
5. feedback_NEVER_AI_packaging.md             — real pkg-*.png only
6. feedback_food_audit_pixel_match.md         — signature markers per dish
7. feedback_design_audit_checklist.md         — 6-layer visual audit
8. feedback_pinxin_color_direction.md         — natural, not warm/reddish
9. feedback_creative_research_engine.md       — reference fatigue check

MUST VERIFY:
- Reference fatigue (grep previous scripts for ref usage count)
- Food variety (max 1-2 cutouts per ad)
- All asset files exist (run validation before production)
- Pricing matches pinxinvegan.com (check live, not memory)
```

## TASK: SOCIAL POST PRODUCTION (not ads)

**Social posts ≠ ads. Different pipeline.**

```
MUST READ:
1. feedback_pinxin_social_post_learnings.md  — social vs ads differences, W1 yes/no
2. feedback_pinxin_w3_compound_learnings.md  — all yes/no from W3 (still applies)
3. feedback_pinxin_mood_photography_reference.md — mood ref as Image 1
4. feedback_food_audit_pixel_match.md        — signature markers per dish
5. feedback_design_audit_checklist.md        — 6-layer visual audit

KEY DIFFERENCES FROM ADS:
- Output: 4:5 (1080×1350) — NOT 9:16
- Pipeline: Single NANO pass → logo → grain — NO two-pass extension
- Logo Y: y=30 (top-right) — NOT y=300
- Illustration posts: Use locked refs from _LOCKED/ as Image 1
- EVERY prompt: "ZERO EGGS. 100% vegan. No eggs, dairy, animal products."
- Food cutout as Image 2 even for illustration posts
```

## TASK: MIRRA ANALYSIS (Specific)

**Mirra has unique attribution problems:**

```
MUST READ:
1. feedback_mirra_attribution_gap.md          — 89% orders unattributed
2. feedback_report_bugs_march25.md            — missing campaign bug
3. feedback_mirra_creative_formula.md         — transformation + message UI

MUST DO:
- ALWAYS pull Google Sheet AND match ad IDs (autoads_sheet_attribution.py logic)
- NEVER trust conversation metrics alone for "winning" ads
- Report BLENDED ROAS (not per-ad unless >50% attribution rate)
- Check ALL active campaigns (query act_830110298602617/campaigns?status=ACTIVE)
```

## TASK: NEW SESSION START

**Every new conversation, first thing:**

```
MUST READ:
1. This file (PREFLIGHT-ROUTER.md)
2. MEMORY.md (index — scan for relevant sections)
3. project_zennith_ads_automation.md          — what's running, schedule, status
4. The LATEST autoads.log + analyzer.log      — what happened since last session
5. The LATEST attribution log                  — WA sales matching

MUST CHECK:
- crontab -l (are all jobs still scheduled?)
- Meta token expiry (60-day token)
- Any new campaigns created that aren't monitored?
```

## TASK: UPLOADING TO META

**Before any ad upload:**

```
MUST READ:
1. feedback_human_approval_before_upload.md   — human reviews ALL artwork first
2. feedback_pinxin_pricing_actual.md          — pricing in ad copy matches website
3. feedback_meta_ads_hard_rules_march22.md    — Rule 8: creative production rules

MUST VERIFY:
- All 3 text fields filled (primary + headline + description)
- CTA = ORDER_NOW (website) or appropriate WA CTA
- Link = correct landing page
- Image passes 6-layer design audit
- Human has explicitly approved
```

## TASK: RESEARCH / INTELLIGENCE

```
MUST READ:
1. creative-intelligence-meta-ads-engine.md   — existing knowledge base
2. _shared/intelligence/META-ADS-INTELLIGENCE-2026-Q1.md — current intelligence

MUST DO:
- Check date of existing intelligence (stale if >7 days)
- Cross-reference new findings against existing knowledge
- Update intelligence doc if new findings
```

---

## THE DISCIPLINE RULE

**I MUST read the required files BEFORE typing any recommendation.**

Not "I know what's in there from context." Actually open and read them. Data changes. Rules get updated. Memory decays.

If I catch myself recommending without having read the required files → STOP → read them → then continue.

**The human should NEVER need to correct a rule I already have in my files. That's a system failure, not a knowledge gap.**
