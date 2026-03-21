---
name: auto-research
version: "1.0.0"
description: >
  Self-improving loop engine inspired by Karpathy's autoresearch pattern.
  Generates variants, evaluates against criteria, keeps improvements, discards
  regressions, and compounds learnings over time. Applicable to ad creatives,
  email subjects, product descriptions, content hooks, pricing copy, and any
  domain where a measurable metric can judge quality.
evolves: true
metadata:
  openclaw:
    scope: optimization
    inspiration: "https://github.com/karpathy/autoresearch"
    guardrails:
      - Variants are ONLY kept when they beat the current best score
      - All experiments are logged to learnings.json for audit trail
      - Real-world feedback sources are optional — LLM-as-judge is default
      - Never overwrites the original template — always preserves it as baseline
    agents:
      - main
      - dreami
      - apollo
      - hermes
      - artemis
    pubsub:
      emits:
        - topic: "auto-research.variant.improved"
          payload: "{ variant_id, score, delta, objective }"
        - topic: "auto-research.run.complete"
          payload: "{ run_id, iterations, best_score, improvements }"
      listens:
        - topic: "pipeline.content.needs-optimization"
          action: "Start auto-research loop with provided config"
---

# Auto-Research — Self-Improving Loop Engine

> *"You're not touching any of the Python files like you normally would as a researcher.
> Instead, you are programming the program.md Markdown files that provide context to the
> AI agents and set up your autonomous research org."* — Andrej Karpathy

## Core Insight

Karpathy's autoresearch pattern for ML training, adapted for marketing, content, and
business optimization:

```
LOOP:
  1. Generate variant (using LLM + learnings from prior rounds)
  2. Evaluate against criteria (LLM-as-judge or real-world metric)
  3. Score (sum of criteria passes / total criteria)
  4. If score > current best → KEEP, log improvement
  5. If score <= current best → DISCARD, log what didn't work
  6. Append learnings to learnings.json
  7. REPEAT until max_iterations
```

The human edits the strategy (config YAML = the "program.md" equivalent).
The AI agent edits the content (the "train.py" equivalent).
The eval metric determines success. No opinions — just scores.

## How It Works

### The Loop

```
┌─────────────────────────────────────────────┐
│           auto-loop.sh <config.yaml>        │
├─────────────────────────────────────────────┤
│                                             │
│  Load current best (or template)            │
│         │                                   │
│         ▼                                   │
│  ┌─── Generate variant (LLM) ◄──────────┐  │
│  │                                       │  │
│  │    Evaluate against criteria (LLM)    │  │
│  │         │                             │  │
│  │         ▼                             │  │
│  │    Score: yes_count / total_criteria   │  │
│  │         │                             │  │
│  │    ┌────┴────┐                        │  │
│  │    │ Better? │                        │  │
│  │    └────┬────┘                        │  │
│  │     Y/  \N                            │  │
│  │    /     \                            │  │
│  │  KEEP   DISCARD                       │  │
│  │   │       │                           │  │
│  │   └───┬───┘                           │  │
│  │       │                               │  │
│  │  Log learnings ───────────────────────┘  │
│  │                                          │
│  └── Until max_iterations reached           │
│                                             │
│  Output: best variant + learnings.json      │
└─────────────────────────────────────────────┘
```

### The Separation of Concerns

| Role | Who | Edits What |
|------|-----|-----------|
| **Strategy** | Human (Jenn Woei) | Config YAML — objective, criteria, thresholds |
| **Execution** | AI Agent | Content variants — copy, headlines, descriptions |
| **Judgment** | Eval function | Score — deterministic, no opinions |

This mirrors Karpathy's split: human edits `program.md`, AI edits `train.py`,
`val_bpb` determines success.

## Use Cases for Zennith OS

### 1. Ad Creative Optimization
- **Objective**: CTR or ROAS
- **Generate**: Ad headline + body copy variants
- **Evaluate**: Score against hook power, clarity, urgency, brand voice, CTA strength
- **Feedback**: Meta Ads API performance data (when available)
- **Config**: `configs/ad-creative.yaml`

### 2. Email Subject Lines
- **Objective**: Open rate
- **Generate**: Subject line variants
- **Evaluate**: Score against curiosity, urgency, personalization, length, spam-safety
- **Config**: `configs/email-subject.yaml`

### 3. Product Descriptions
- **Objective**: Conversion rate
- **Generate**: Product description variants
- **Evaluate**: Score against benefit clarity, SEO keywords, emotional trigger, social proof, scannability
- **Config**: `configs/product-description.yaml`

### 4. Content Thumbnails & Hooks
- **Objective**: Click-through or watch-time
- **Generate**: Hook/thumbnail copy variants
- **Evaluate**: Score against pattern interrupt, curiosity gap, specificity, emotion, promise
- **Feedback**: YouTube/TikTok analytics (when available)

### 5. Pricing Copy
- **Objective**: Revenue per visitor
- **Generate**: Pricing page copy variants
- **Evaluate**: Score against value framing, anchor pricing, urgency, objection handling, clarity

### 6. QMDJ Reading Quality
- **Objective**: User satisfaction
- **Generate**: Reading format/structure variants
- **Evaluate**: Score against accuracy, actionability, personalization, cultural sensitivity, clarity
- **Feedback**: User satisfaction ratings (when available)

## Usage

```bash
# Run a loop with a config file
bash ~/.openclaw/skills/auto-research/scripts/auto-loop.sh \
  ~/.openclaw/skills/auto-research/configs/ad-creative.yaml

# Run with custom iteration count
MAX_ITERATIONS=20 bash ~/.openclaw/skills/auto-research/scripts/auto-loop.sh \
  ~/.openclaw/skills/auto-research/configs/email-subject.yaml
```

## Config Format

```yaml
# Required
objective: "CTR"
task: "Write a Facebook ad headline for MIRRA plant-based bento"
template: |
  Healthy eating made easy. MIRRA plant-based bento — order now.

# Evaluation criteria (binary yes/no, like Karpathy's checkboxes)
criteria:
  - id: hook_power
    description: "Opens with a pattern interrupt or curiosity gap"
  - id: clarity
    description: "Main benefit is obvious within 3 seconds"
  - id: emotion
    description: "Triggers a specific emotion (curiosity, desire, fear of missing out)"
  - id: urgency
    description: "Creates time pressure or scarcity"
  - id: brand_voice
    description: "Matches MIRRA brand voice — warm, Malaysian, health-conscious"
  - id: cta_strength
    description: "Call to action is clear and compelling"

# Optional
max_iterations: 10
keep_threshold: null  # null = must beat current best
model: "claude-sonnet-4-6"
brand: "mirra"
output_dir: "~/.openclaw/workspace/data/auto-research/mirra-ad"

# Real-world feedback (optional — adds to LLM eval)
feedback_sources:
  - type: meta_api
    campaign_id: "123456"
    metric: "ctr"
  - type: shopify_api
    metric: "conversion_rate"
```

## Output Structure

```
output_dir/
  best.txt              — Current best variant (plain text)
  best_score.json       — Current best score breakdown
  learnings.json        — All experiments: scores, deltas, what worked/didn't
  variants/
    001.txt             — Variant 1
    001_score.json      — Variant 1 score
    002.txt             — Variant 2
    ...
  run_summary.json      — Final summary: iterations, improvements, best score
```

## Integration with Zennith OS

### Pub-Sub Events
- **Emits** `auto-research.variant.improved` when a better variant is found
- **Emits** `auto-research.run.complete` when the loop finishes
- **Listens** for `pipeline.content.needs-optimization` to auto-start loops

### Content Factory Integration
- Output feeds into content-tuner's winning patterns pipeline
- Best variants can be promoted to brand DNA via content-tuner

### Agent Usage
- **Dreami**: Ad creative and content hook optimization
- **Apollo**: Email subject lines and product description optimization
- **Hermes**: Pricing copy and ad performance optimization
- **Artemis**: Research-backed content quality optimization

## Compounding Learnings

The `learnings.json` file accumulates across runs. Each run reads prior learnings
to inform new variant generation. This is how the system gets smarter over time —
the same principle as Karpathy's `results.tsv` tracking experiment history.

Over time, patterns emerge:
- "Short headlines (< 8 words) consistently score higher on hook_power"
- "Questions outperform statements for curiosity"
- "Malaysian cultural references boost brand_voice scores"

These patterns compound. The 50th run generates better variants than the 1st run
because it has 49 experiments of learnings to draw from.

## Scripts

### auto-loop.sh
Main loop runner. See `scripts/auto-loop.sh` for implementation.

## CHANGELOG

### v1.0.0 (2026-03-22)
- Initial creation: Self-improving loop engine adapted from Karpathy's autoresearch
- auto-loop.sh: Main loop with generate/eval/keep-or-discard/learn cycle
- Example configs: ad-creative, email-subject, product-description
- LLM-as-judge evaluation with binary criteria scoring
- Learnings accumulation across runs for compounding improvement
- Pub-sub integration for Zennith OS pipeline flows
