---
name: audience-simulator
description: |
  TRIGGER: "test this copy", "audience reaction", "simulate audience", "pre-test ad", "score this content", "will this work for [brand]"
  ANTI-TRIGGER: actual A/B testing with real users, market research from external sources, content creation (this scores, not creates)
  OUTCOME: Persona reaction report with per-persona scores, aggregate verdict (PASS/REFINE/FAIL), and actionable improvement suggestions
agents: [dreami, taoz]
version: 1.1.0
---

# Audience Simulator — Pre-Test Content with Persona-Based LLM Agents

> Simulate how your target audience would react to content BEFORE publishing or spending ad budget.

Uses LLM-as-judge with brand-specific persona profiles to score content. 5-10 well-defined personas per brand, drawn from DNA.json audience definitions. All personas calibrated for the Malaysian market.

```
CONTENT → Load brand personas → Each persona "reacts" → Aggregate scores → Pass/Fail/Refine
```

---

## Simulation Workflow

```
INPUT: Content (ad copy, caption, image description) + brand name + [optional: specific personas]

STEP 1: Load brand DNA → extract audience personas
        Source: ~/.openclaw/brands/{brand}/DNA.json
        Fallback: Load references/persona-library.md for full persona profiles

STEP 2: For each persona (5-10 per brand):
  a. Generate persona context (demographics, values, pain points, deal-breakers)
  b. Present the content to the persona
  c. Simulate reaction:
     - Would they stop scrolling?
     - Would they read beyond the first line?
     - Would they engage (like, comment, save, share)?
     - Would they click through?
     - Would they buy / take action?
  d. Score: 1-10 for each dimension
     → Load references/scoring-and-reports.md for scoring rubrics
  e. Generate persona-voice feedback:
     "As Sarah, I would... because..."

STEP 3: Aggregate scores across all personas
        - Per-persona breakdown
        - Per-dimension breakdown (Attention, Relevance, Emotion, Action)
        - Overall average

STEP 4: Identify segments:
        - LOVE IT (score >= 8): core audience for this content
        - NEUTRAL (score 5-7): won't repel but won't convert
        - TURNED OFF (score < 5): content actively alienates this segment

STEP 5: Generate improvement suggestions
        - Specific, actionable rewrites (not generic advice)
        - Tied to specific persona feedback
        - Prioritized by impact (fixing deal-breaker > optimizing nice-to-have)

STEP 6: Pass/Fail decision
        - avg >= 7.0 = PASS (ship it)
        - avg 5.0-6.9 = REFINE (fixable, see suggestions)
        - avg < 5.0 = FAIL (fundamental mismatch, rethink approach)

OUTPUT: Persona reaction report + aggregate score + improvement suggestions
        Saved to: ~/.openclaw/workspace/data/audience-sim/{brand}/
```

---

## CLI Usage

```bash
# Test ad copy against all brand personas
bash scripts/audience-simulator.sh test \
  --brand mirra \
  --content "Your weight management meals, delivered fresh daily. Order now."

# Test with specific personas only
bash scripts/audience-simulator.sh test \
  --brand jade-oracle \
  --content "Your tarot reader can't do math" \
  --personas "emma,mei-lin"

# Test image concept (pre-flight before generating)
bash scripts/audience-simulator.sh test \
  --brand pinxin-vegan \
  --content "Bold overhead shot of vegan nasi lemak, steam rising, dark green background" \
  --type image-concept

# Batch test multiple content variants from a file
bash scripts/audience-simulator.sh batch \
  --brand mirra --input variants.txt

# A/B pre-test: compare two options head-to-head
bash scripts/audience-simulator.sh compare \
  --brand mirra \
  --a "Try our calorie-controlled bento" \
  --b "Weight management has never tasted this good"

# Full campaign pre-test from a brief
bash scripts/audience-simulator.sh campaign \
  --brand jade-oracle --brief campaign-brief.md
```

---

## Quality Gate

When used as a gate (e.g., in content-supply-chain):

| Score | Verdict | Action |
|-------|---------|--------|
| >= 7.0 | **PASS** | Content approved for publishing/ad spend |
| 5.0-6.9 | **REFINE** | Apply suggestions, re-test before publishing |
| < 5.0 | **FAIL** | Fundamental mismatch — go back to brief/strategy |

**No content should go to paid ad spend without scoring >= 7.0 across brand personas.**

---

## References (loaded on demand)

| File | Content | Load During |
|------|---------|-------------|
| `references/persona-library.md` | Full persona profiles for all 14 brands (demographics, values, triggers, deal-breakers) | Step 1 |
| `references/scoring-and-reports.md` | Scoring rubrics (4 dimensions), report formats (MD + JSON), CLI flags, brand examples, integration points, Malaysian market calibration | Steps 2-6 |
