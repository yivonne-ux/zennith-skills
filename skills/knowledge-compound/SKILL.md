---
name: knowledge-compound
description: Self-learning loop — intake external knowledge, digest into patterns, compound into agent capabilities
version: 1.0.0
agents:
  - taoz
  - main
---

# Knowledge Compound Loop

Turn every research, workflow study, competitor scan, user correction, and session learning into compounding agent intelligence.

## The Loop

```
INTAKE → DIGEST → STORE → MATCH → PROMOTE → AGENTS LEARN
  ↑                                              |
  └──── new research, feedback, sessions ────────┘
```

## Entry Points

### 1. digest.sh — Intake + Digest any knowledge source
```bash
bash ~/.openclaw/skills/knowledge-compound/scripts/digest.sh \
  --source "robonuggets/R34" \
  --type "workflow" \
  --file "/path/to/analysis.md" \
  --agent "dreami"

bash ~/.openclaw/skills/knowledge-compound/scripts/digest.sh \
  --source "user-correction" \
  --type "brand-fix" \
  --fact "MIRRA is a bento meal delivery brand, NOT skincare. Colors: salmon pink #F7AB9F, black #252525, cream #FFF9EB" \
  --agent "dreami"

bash ~/.openclaw/skills/knowledge-compound/scripts/digest.sh \
  --source "competitor/grab-food" \
  --type "competitor-intel" \
  --file "/path/to/analysis.json" \
  --agent "dreami,scout"
```

### 2. pattern.sh — Query or update pattern registry
```bash
bash ~/.openclaw/skills/knowledge-compound/scripts/pattern.sh list
bash ~/.openclaw/skills/knowledge-compound/scripts/pattern.sh count "image-first-then-animate"
bash ~/.openclaw/skills/knowledge-compound/scripts/pattern.sh promote  # auto-promote patterns with count >= 3
```

### 3. nightly-compound.sh — Runs at 22:35 MYT
- Reads day's room activity + session completions
- Extracts new patterns, increments counts
- Promotes validated patterns → skill proposals
- Posts digest to townhall room

## Knowledge Sources (what gets digested)

| Source Type | Example | Agent |
|---|---|---|
| workflow | n8n JSON, RoboNuggets template | Zenni (main) |
| competitor-intel | Ad scrape, pricing data | Scout → Dreami |
| user-correction | "MIRRA is not skincare" | All affected agents |
| session-learning | Agent session completion | Agent that completed |
| tool-discovery | "Seedance 2.0 on fal.ai" | Dreami |
| brand-update | DNA.json change, new product | Dreami |
| performance-data | Ad ROAS, engagement metrics | Dreami, Zenni (main) |
| tutorial | YouTube video digest | Relevant agent |

## Pattern Lifecycle

```
observed (1x) → validated (3x) → skill-proposed (3x+) → implemented → compounding
```

## Storage

- **Facts**: `gaia.db` → `knowledge` table (FTS5 searchable)
- **Patterns**: `gaia.db` → `patterns` table (count-tracked)
- **Agent learnings**: SOUL.md `## Compound Learnings` section (promoted from patterns)

## Agent Assignment

- **Zenni (main)**: Primary knowledge processor — digests, analyzes, extracts patterns
- **Scout**: Research intake — competitor intel, market data
- **Dreami**: Creative patterns — prompting techniques, content formats
- **All agents**: Query knowledge base on boot via `boot-knowledge.py`
