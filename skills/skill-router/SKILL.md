---
name: skill-router
description: Intra-agent skill selector. Given a task description, returns the best skill(s) to use. Zero-cost keyword matching with LLM fallback. Used by all agents after classify.sh routes to them.
agents: [main, dreami, taoz, iris]
version: 1.1.0
---

# Skill Router — Intra-Agent Skill Selector

classify.sh routes tasks to agents. Skill Router routes tasks to skills within an agent.

## Problem

Agents have 25+ creative skills and no deterministic way to pick the right one. classify.sh handles
inter-agent routing (which agent?), but once a task lands on an agent, it still needs to decide which
skill(s) to invoke. Without this, agents guess — wasting tokens or picking suboptimal tools.

## How It Works

```
classify.sh                    skill-router.sh
User msg --> Which agent? --> Agent --> Which skill(s)? --> Skill(s)
             (keyword match)            (keyword match)
             zero LLM cost             zero LLM cost
```

1. Parse task description
2. Match against keyword patterns (zero cost, like classify.sh)
3. If high confidence (>0.8): return skill directly
4. If ambiguous: return top 2-3 candidates with confidence scores
5. Optional: `--llm` flag uses claude CLI for disambiguation ($0 on Claude Max)

## Workflow SOP

```
INPUT: Task description (string) + agent name (optional)
STEP 1: Parse task description for keywords
STEP 2: Match against 30+ routing rules (ordered by specificity)
STEP 3: Score candidates by confidence (0-1)
STEP 4: If top match > 0.8 -> return skill directly
STEP 5: If ambiguous (top 2 within 0.15) -> use --llm flag for Claude disambiguation
STEP 6: Return skill name + confidence + reasoning
OUTPUT: Skill name(s) with confidence scores
```

## Brand DNA Awareness

skill-router reads brand DNA.json (`~/.openclaw/brands/{brand}/DNA.json`) to understand which skills
are most relevant per brand category:

- **F&B/wellness brands** (pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein)
  prioritize product-studio, grabfood-enhance, content-repurpose, campaign-translate,
  **page-cro**, **pricing-strategy**, **churn-prevention**.
- **Digital/tech brands** (jade-oracle, gaia-os, gaia-learn) prioritize content-supply-chain,
  ad-composer, campaign-planner, **ai-seo**, **offer-builder**.
- **Print/recipe brands** (gaia-print, gaia-recipes) prioritize brand-studio, creative-studio.
- **Supplement brands** (gaia-supplements, iris) prioritize product-studio, ad-composer,
  **offer-builder**, **pricing-strategy**.
- **All brands:** **humanizer** (before publishing), **wrap-up** (end of session).
- **System/meta:** **context-optimization** (token issues), **skill-creator** (new skills).

## Usage

```bash
# Basic — returns best match
skill-router.sh "generate mirra product photos for shopee"

# All candidates with scores
skill-router.sh --all "create a video ad for mirra bento"

# Filter by agent
skill-router.sh --agent dreami "translate campaign copy to bahasa"

# JSON output for programmatic use
skill-router.sh --json "audit brand images"

# LLM disambiguation when keywords tie
skill-router.sh --llm "create jade character content for instagram"
```

## Flags

| Flag | Description |
|------|-------------|
| `--task "..."` | Explicit task flag (alternative to positional arg) |
| `--agent NAME` | Filter to skills available to that agent |
| `--llm` | Use Claude CLI for disambiguation ($0 on Claude Max) |
| `--json` | Machine-readable JSON output |
| `--all` | Show all candidates with scores, not just top match |

> Load `references/brand-routing-examples.md` for all 14 brand routing examples, F&B deep routing rules, and Malaysian market routing specifics.

## Quality Checklist

| Criterion | Threshold | Fallback |
|-----------|-----------|----------|
| Routing accuracy | Top-1 correct >= 90% | Log misroutes to routing-log.jsonl |
| Confidence threshold | Minimum 0.6 | Below 0.6 -> "ambiguous" + top 3 |
| High-confidence cutoff | >= 0.8 -> auto-route | 0.6-0.8 -> suggest but flag |
| Disambiguation | Top-2 within 0.15 | Trigger `--llm` fallback |
| Brand DNA loaded | Brand mentioned in task | Load DNA.json; fail gracefully if missing |
| Multi-skill tasks | Task spans 2+ skills | Return ordered list with pipeline suggestion |

## Integration

**Feeds FROM:** classify.sh (agent routing).
**Feeds INTO:** All creative skills — skill-router is the dispatch layer.

**Programmatic use:**
```bash
SKILL=$(skill-router.sh --json "$TASK" | jq -r '.skill')
bash ~/.openclaw/skills/$SKILL/scripts/*.sh "$@"
```

## Data

- `data/skill-index.json` — structured index of all skills with capabilities
- Keyword rules embedded in the script (like classify.sh) for zero-cost matching
- `~/.openclaw/workspace/data/skill-router/routing-log.jsonl` — append-only routing log
