---
name: content-tuner
version: "1.0.0"
description: Self-tuning engine for the Content Factory. Reads winning patterns, compares against content-intel defaults, promotes patterns that consistently outperform, and flags underperformers. The system that makes everything else get smarter over time.
metadata:
  openclaw:
    scope: optimization
    guardrails:
      - Only promotes patterns with 3+ data points AND >20% improvement
      - Never auto-removes defaults from content-intel — flags for Jenn's review
      - All tuning decisions are logged to tuning-log.jsonl for audit trail
      - A/B tests require >10% improvement for variant to beat control
    cron:
      - schedule: "0 20 * * 0"
        command: "bash ~/.openclaw/skills/content-tuner/scripts/tune.sh"
        agent: main
        description: "Weekly tuning cycle — Sunday 20:00 MYT"
      - schedule: "0 10 * * *"
        command: "bash ~/.openclaw/skills/content-tuner/scripts/ab-framework.sh evaluate"
        agent: main
        description: "Daily A/B test evaluation — 10:00 MYT"
---

# Content Tuner — Phase 4 of the Content Factory

## Purpose

Automated strategy improvement -- the system that makes everything else get smarter over time. The Content Tuner closes the feedback loop in the Content Factory by reading real performance data, identifying what works, and evolving the playbooks that Dreami and the rest of the team use to create content.

Without the tuner, the content-intel playbook is static -- based on best practices and assumptions. With the tuner, the playbook evolves based on what actually performs for GAIA's audience.

## How It Works

1. **Read winning patterns** from `winning-patterns.jsonl` (produced by ad-performance analysis and seed bank queries)
2. **Compare against content-intel defaults** -- the hook templates, copywriting formulas, and channel specs in the content-intel SKILL.md
3. **Promote patterns that consistently outperform** -- patterns with 3+ data points AND >20% improvement get added to a "Recommended by Performance Data" section in content-intel
4. **Flag underperformers** -- defaults that never appear in winning patterns get flagged in the feedback room for Jenn's review (never auto-removed)
5. **A/B test new ideas** -- the ab-framework.sh script manages structured A/B tests between default templates and winning patterns

## Safety Rules

- **Promotion threshold:** 3+ data points AND >20% average improvement. No exceptions.
- **No auto-removal:** Underperforming defaults are flagged, never removed. Jenn decides.
- **Logging:** Every tuning decision (promotion, confirmation, flag, no-action) is logged to `tuning-log.jsonl` with full evidence.
- **A/B minimum:** Variants need >10% improvement to beat control. Otherwise control wins by default.
- **Audit trail:** All actions post summaries to exec and feedback rooms.

## Scripts

### tune.sh — Weekly Tuning Cycle

```
bash ~/.openclaw/skills/content-tuner/scripts/tune.sh
```

Runs the full tuning cycle:
1. Reads winning patterns from the past 7 days (or status "detected"/"confirmed")
2. Extracts current defaults from content-intel SKILL.md (hooks, formulas, channel specs)
3. Compares patterns vs defaults using python3 analysis
4. Promotes confirmed patterns (adds to content-intel recommended section)
5. Flags underperformers (posts to feedback room)
6. Logs all decisions to tuning-log.jsonl
7. Posts summary to exec room (and creative room if promotions occurred)

**Cron:** Sunday 20:00 MYT via Zenni (main)

### ab-framework.sh — A/B Testing Framework

```
bash ~/.openclaw/skills/content-tuner/scripts/ab-framework.sh <command> [options]
```

Commands:
- `create` -- Create a new A/B test (control vs variant)
- `evaluate` -- Evaluate tests that are ready (past their evaluate_after time)
- `list` -- List active or recent tests
- `summary` -- Summarize all completed tests

**Cron:** Daily 10:00 MYT -- `evaluate` command via Zenni (main)

## Data Files

| File | Purpose |
|------|---------|
| `~/.openclaw/workspace/data/winning-patterns.jsonl` | Input: winning patterns detected by ad performance analysis |
| `~/.openclaw/workspace/data/tuning-log.jsonl` | Output: audit log of all tuning decisions |
| `~/.openclaw/workspace/data/ab-tests.jsonl` | A/B test records |
| `~/.openclaw/skills/content-intel/SKILL.md` | Target: playbook that gets updated with promoted patterns |

## Integration Points

### Reads From
- `winning-patterns.jsonl` -- patterns detected by ad performance analysis and seed bank queries
- `content-intel/SKILL.md` -- current default templates, formulas, and specs
- `seeds.jsonl` -- via seed-store.sh for A/B test performance data

### Writes To
- `content-intel/SKILL.md` -- appends "Recommended by Performance Data" section
- `tuning-log.jsonl` -- all tuning decisions with evidence
- `ab-tests.jsonl` -- A/B test lifecycle records
- `winning-patterns.jsonl` -- updates pattern status to "promoted"

### Posts To Rooms
- **exec** -- weekly tuning summary, A/B test results
- **creative** -- promotion notifications for Dreami to incorporate
- **feedback** -- underperformer flags, A/B control wins

## LOOP Integration — MIRRA/Jade Oracle Winning Patterns

**Source:** Learning Extraction (March 10, 2026) — MIRRA & Jade Oracle Campaign Analysis
**Purpose:** Close the creative feedback loop (Zenni → DNA → Dreami) with real performance data

### Winning Patterns to Promote (Auto-Qualified)

#### Pattern 1: Tutorial Content Format (Confidence: HIGH)
```json
{
  "pattern_id": "tutorial-format-dominance",
  "source": "MIRRA Instagram Reels (17/20 top posts)",
  "confidence": 85,
  "data_points": 20,
  "improvement": 85,
  "criteria": {
    "format": "Tutorial-style (step-by-step)",
    "structure": "Hook → Problem → Solution → Result",
    "must_include": ["High-protein claim", "Meal prep emphasis", "Time anchor (30 mins)"],
    "example": "Ready in under 30 minutes. 35g+ protein. Perfect for meal prepping."
  },
  "performance": {
    "engagement_rate": 85,
    "ctr_baseline": 1.8,
    "ctr_achieved": 2.8,
    "improvement_pct": 56
  },
  "promotion_status": "CONFIRMED"
}
```

#### Pattern 2: Localization (CN vs EN) (Confidence: HIGH)
```json
{
  "pattern_id": "cn-localization-efficiency",
  "source": "MIRRA Campaign Comparison (Mar 6-7)",
  "confidence": 90,
  "data_points": 5,
  "improvement": 32,
  "criteria": {
    "cn_campaigns_cost_per_connection": 5.90,
    "en_campaigns_cost_per_connection": 7.72,
    "budget_shift": "30% from EN to CN",
    "example_hooks": {
      "ot_queen": "KPI拿满分，别让身材变负分！",
      "lazy_foodie": "懒人套餐 — 立即订购"
    }
  },
  "performance": {
    "ctr_cn": 3.65,
    "ctr_en": 1.8,
    "cost_efficiency_improvement": 32
  },
  "promotion_status": "CONFIRMED"
}
```

#### Pattern 3: Heritage Malaysian + Plant-Based (Confidence: HIGH)
```json
{
  "pattern_id": "heritage-malaysian-vegan-resonance",
  "source": "MIRRA Rendang Campaign",
  "confidence": 95,
  "data_points": 3,
  "improvement": 78,
  "criteria": {
    "hook_format": "Did you know X can be Y?",
    "heritage_dishes": ["Rendang", "Nasi Lemak"],
    "tags": ["trending", "vegan", "malaysian"],
    "ctr": 3.2,
    "roas": 4.1
  },
  "performance": {
    "rendang": {"ctr": 3.2, "roas": 4.1},
    "nasi_lemak": {"ctr": 1.8, "roas": 2.3}
  },
  "promotion_status": "CONFIRMED"
}
```

#### Pattern 4: Brand DNA Compliance (Confidence: MEDIUM)
```json
{
  "pattern_id": "brand-dna-compliance",
  "source": "MIRRA Creative Audit",
  "confidence": 75,
  "data_points": 10,
  "improvement": 22,
  "criteria": {
    "colors": ["#F7AB9F", "#FFF9EB", "#FFFFFF"],
    "nutrition_concept": "#sukusukuseparuh",
    "auto_reject_score": 8.5
  },
  "performance": {
    "ctr_with_dna": 2.2,
    "ctr_without_dna": 1.8,
    "improvement_pct": 22
  },
  "promotion_status": "CONFIRMED"
}
```

#### Pattern 5: Retargeting 7-Day Rotation (Confidence: MEDIUM)
```json
{
  "pattern_id": "retargeting-rotation",
  "source": "Learning Data: 'Retargeting CTR drops 50% after 7 days'",
  "confidence": 70,
  "data_points": 4,
  "improvement": 50,
  "criteria": {
    "rotation_cycle": "7 days",
    "angles": ["Reminder", "Urgency", "Offer"],
    "budget_allocation": "20% of original budget for testing",
    "test_duration": "48h"
  },
  "performance": {
    "ctr_fresh": 2.5,
    "ctr_stale": 1.25,
    "improvement_pct": 50
  },
  "promotion_status": "CONFIRMED"
}
```

### Underperformers to Flag (For Jenn's Review)

#### Flag 1: Generic Health Claims
```json
{
  "pattern_id": "generic-health-claims",
  "source": "MIRRA Campaign Analysis",
  "status": "UNDERPERFORMER",
  "example": "Low calorie meal",
  "ctr": 1.2,
  "roas": 1.5,
  "recommendation": "Replace with: 'Did you know nasi lemak can be 450 kcal?'"
}
```

#### Flag 2: Over-Translated CN Copy
```json
{
  "pattern_id": "over-translated-cn",
  "source": "MIRRA CN Campaign Analysis",
  "status": "UNDERPERFORMER",
  "issue": "Unnatural phrasing from direct translation",
  "recommendation": "Use original Malaysian phrasing with local context"
}
```

#### Flag 3: Missing Tags
```json
{
  "pattern_id": "missing-tags",
  "source": "MIRRA Content Audit",
  "status": "UNDERPERFORMER",
  "issue": "Generic creative without channel/context tags",
  "recommendation": "Always tag with channel + diet + culture (e.g., 'tiktok', 'vegan', 'malaysian')"
}
```

### Updated Workflow: Zenni DNA Writing

**Step 1:** Zenni extracts winning patterns from Meta insights (weekly)
```bash
# Zenni reads last 7 days of Meta performance data
# Filters for: >20% improvement AND 3+ data points
# Output: winning-patterns.jsonl
```

**Step 2:** Zenni writes to brand DNA
```bash
# Write to: ~/.openclaw/brands/MIRRA/creative_learnings.json
{
  "last_updated": "2026-03-10",
  "winning_patterns": ["tutorial-format-dominance", "cn-localization-efficiency", ...],
  "underperformers": ["generic-health-claims", ...]
}
```

**Step 3:** Dreami reads DNA before generation
```bash
# All creative generation prompts include:
"Read ~/.openclaw/brands/MIRRA/creative_learnings.json before generating.
Incorporate confirmed winning patterns. Avoid flagged underperformers."
```

**Step 4:** Content-tuner promotes/flags weekly
```bash
# tune.sh runs weekly (Sunday 20:00 MYT)
# Promotes patterns meeting threshold
# Flags underperformers to feedback room
# Logs all decisions to tuning-log.jsonl
```

## CHANGELOG

### v1.1.0 (2026-03-10)
- **LOOP Integration:** Added MIRRA/Jade Oracle winning patterns from learning data
- **Pattern Promotion:** Auto-qualified 5 winning patterns (tutorial, localization, heritage, brand DNA, retargeting)
- **Underperformer Flags:** Added 3 underperformers for Jenn's review (generic claims, over-translation, missing tags)
- **DNA Writing Workflow:** Updated Zenni workflow to write to creative_learnings.json
- **Dreami Integration:** Added DNA reading step to all creative generation prompts

### v1.0.0 (2026-02-13)
- Initial creation: Content Tuner as Phase 4 of the Content Factory
- tune.sh: weekly tuning cycle with pattern promotion and underperformer flagging
- ab-framework.sh: A/B testing framework with create, evaluate, list, summary commands
- Safety: 3+ data points AND >20% improvement threshold for promotions
- Full audit logging to tuning-log.jsonl
