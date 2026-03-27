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
agents:
  - taoz
  - scout
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
  4. If score > current best -> KEEP, log improvement
  5. If score <= current best -> DISCARD, log what didn't work
  6. Append learnings to learnings.json
  7. REPEAT until max_iterations
```

The human edits the strategy (config YAML). The AI agent edits the content. The eval metric determines success.

## How It Works

### The Loop

```
  Load current best (or template)
         |
         v
  Generate variant (LLM) <----------+
  |                                  |
  Evaluate against criteria (LLM)   |
         |                          |
         v                          |
    Score: yes_count / total        |
         |                          |
    Better? ---Y--> KEEP            |
         |                          |
         +---N--> DISCARD           |
         |                          |
    Log learnings ------------------+
         |
  Until max_iterations reached
```

### The Separation of Concerns

| Role | Who | Edits What |
|------|-----|-----------|
| **Strategy** | Human (Jenn Woei) | Config YAML — objective, criteria, thresholds |
| **Execution** | AI Agent | Content variants — copy, headlines, descriptions |
| **Judgment** | Eval function | Score — deterministic, no opinions |

## Usage

```bash
# Run a loop with a config file
bash ~/.openclaw/skills/auto-research/scripts/auto-loop.sh \
  ~/.openclaw/skills/auto-research/configs/ad-creative.yaml

# Run with custom iteration count
MAX_ITERATIONS=20 bash ~/.openclaw/skills/auto-research/scripts/auto-loop.sh \
  ~/.openclaw/skills/auto-research/configs/email-subject.yaml
```

> Load `references/use-cases-and-config.md` for all 6 use cases (ad creative, email, product descriptions, thumbnails, pricing, QMDJ), full config YAML format with examples, output structure, pub-sub events, and agent usage.

## Compounding Learnings

The `learnings.json` file accumulates across runs. Each run reads prior learnings
to inform new variant generation. Over time, patterns emerge:
- "Short headlines (< 8 words) consistently score higher on hook_power"
- "Questions outperform statements for curiosity"
- "Malaysian cultural references boost brand_voice scores"

The 50th run generates better variants than the 1st because it has 49 experiments of learnings.

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
