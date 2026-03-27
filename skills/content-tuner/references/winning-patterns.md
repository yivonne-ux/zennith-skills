# LOOP Integration — MIRRA/Jade Oracle Winning Patterns

**Source:** Learning Extraction (March 10, 2026) — MIRRA & Jade Oracle Campaign Analysis
**Purpose:** Close the creative feedback loop (Zenni -> DNA -> Dreami) with real performance data

## Winning Patterns to Promote (Auto-Qualified)

### Pattern 1: Tutorial Content Format (Confidence: HIGH)
```json
{
  "pattern_id": "tutorial-format-dominance",
  "source": "MIRRA Instagram Reels (17/20 top posts)",
  "confidence": 85,
  "data_points": 20,
  "improvement": 85,
  "criteria": {
    "format": "Tutorial-style (step-by-step)",
    "structure": "Hook -> Problem -> Solution -> Result",
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

### Pattern 2: Localization (CN vs EN) (Confidence: HIGH)
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

### Pattern 3: Heritage Malaysian + Plant-Based (Confidence: HIGH)
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

### Pattern 4: Brand DNA Compliance (Confidence: MEDIUM)
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

### Pattern 5: Retargeting 7-Day Rotation (Confidence: MEDIUM)
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

## Underperformers to Flag (For Jenn's Review)

### Flag 1: Generic Health Claims
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

### Flag 2: Over-Translated CN Copy
```json
{
  "pattern_id": "over-translated-cn",
  "source": "MIRRA CN Campaign Analysis",
  "status": "UNDERPERFORMER",
  "issue": "Unnatural phrasing from direct translation",
  "recommendation": "Use original Malaysian phrasing with local context"
}
```

### Flag 3: Missing Tags
```json
{
  "pattern_id": "missing-tags",
  "source": "MIRRA Content Audit",
  "status": "UNDERPERFORMER",
  "issue": "Generic creative without channel/context tags",
  "recommendation": "Always tag with channel + diet + culture (e.g., 'tiktok', 'vegan', 'malaysian')"
}
```

## Updated Workflow: Zenni DNA Writing

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
