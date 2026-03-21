---
name: fast-iterate
version: "1.0.0"
description: >
  Pre-ship quality multiplier. Generates N variants, scores each against criteria
  via LLM-as-judge, identifies what makes the winner best, rewrites the prompt
  with learnings, and repeats for K rounds. Ships only the final winner.
  Pure LLM — no real-world data needed. Runs BEFORE anything goes live.
evolves: true
metadata:
  openclaw:
    scope: optimization
    inspiration: "Karpathy's autoresearch inner loop — formalized as standalone tool"
    guardrails:
      - Always produces at least 2 variants per round for meaningful comparison
      - Prompt evolution is logged — full history preserved for review
      - Never ships without at least 1 round of evaluation
      - Scoring is strict — LLM-as-judge with binary criteria, no self-congratulation
    agents:
      - main
      - dreami
      - apollo
      - hermes
      - artemis
      - calliope
    pubsub:
      emits:
        - topic: "fast-iterate.complete"
          payload: "{ task, winner, final_score, rounds, prompt_evolution }"
      listens:
        - topic: "pipeline.content.pre-ship"
          action: "Run fast-iterate on content before publishing"
        - topic: "creative.draft.ready"
          action: "Quality-multiply the draft through iteration rounds"
---

# Fast-Iterate — Pre-Ship Quality Multiplier

## Core Insight

This is the inner loop from Karpathy's autoresearch — pure LLM, no real-world data.
It runs BEFORE shipping anything. The pattern:

```
Round 1: Generate N variants → Score each → Pick winner
         Analyze: "What made the winner best?"

Round 2: Rewrite prompt with Round 1 learnings → Generate N more → Score → Pick winner
         Analyze: "What patterns are compounding?"

Round 3: Even more refined prompt → Generate N more → Score → Pick winner
         Output: Final winner + full scoring log + prompt evolution history
```

Each round produces better variants because the prompt itself improves.
This is meta-learning: the system learns how to ask for what it wants.

## Why This Exists

Every piece of content shipped by Zennith OS should go through fast-iterate first.
A 30-second fast-iterate pass with 3 rounds turns a B+ draft into an A.

Without fast-iterate:
- Agent generates 1 variant
- Human reviews, says "make it better"
- Agent generates another
- 3 rounds of back-and-forth
- 15 minutes wasted

With fast-iterate:
- Agent generates 3 variants, auto-picks best, auto-learns why
- 3 rounds of self-improvement in 60 seconds
- Human gets the winner directly
- Zero back-and-forth

## How It Works

### The Multi-Round Tournament

```
Round 1 (Exploration)
├── Variant A ──→ Score: 0.67 (8/12 criteria)
├── Variant B ──→ Score: 0.83 (10/12 criteria)  ← WINNER
└── Variant C ──→ Score: 0.58 (7/12 criteria)

Analysis: "B won because it used a question hook and specific numbers.
           C lost because it was too generic. A lacked urgency."

Prompt Rewrite: Original + "Use question hooks. Include specific numbers.
                 Avoid generic claims. Add urgency."

Round 2 (Refinement)
├── Variant D ──→ Score: 0.83 (10/12 criteria)
├── Variant E ──→ Score: 0.92 (11/12 criteria)  ← WINNER
└── Variant F ──→ Score: 0.75 (9/12 criteria)

Analysis: "E nailed the Malaysian cultural reference that D missed.
           All variants now have strong hooks — the prompt rewrite worked."

Prompt Rewrite: Original + Round 1 learnings + "Include Malaysian cultural
                 context. Maintain question hook pattern."

Round 3 (Polish)
├── Variant G ──→ Score: 0.92 (11/12 criteria)
├── Variant H ──→ Score: 1.00 (12/12 criteria)  ← WINNER
└── Variant I ──→ Score: 0.92 (11/12 criteria)

SHIP: Variant H (perfect score)
```

### Prompt Evolution

The key innovation: the prompt itself gets better each round.

```
Round 1 prompt: "Write an ad headline for Jade Oracle"

Round 2 prompt: "Write an ad headline for Jade Oracle.
                 Use a question hook (proven to score higher).
                 Include a specific number or timeframe.
                 Avoid generic spiritual language."

Round 3 prompt: "Write an ad headline for Jade Oracle.
                 Use a question hook with a specific number.
                 Reference BaZi or Chinese metaphysics specifically.
                 Include urgency tied to lunar calendar.
                 Keep under 10 words."
```

The final prompt is itself a valuable artifact — it encodes what works.

## Usage

```bash
# Basic usage
bash ~/.openclaw/skills/fast-iterate/scripts/fast-iterate.sh \
  --task "Write an ad headline for Jade Oracle BaZi readings" \
  --criteria "hook_power,clarity,emotion,urgency,brand_voice"

# Full options
bash ~/.openclaw/skills/fast-iterate/scripts/fast-iterate.sh \
  --task "Write a product description for MIRRA Rendang Bento" \
  --criteria "hook_power,clarity,emotion,urgency,brand_voice,social_proof,local_relevance" \
  --variants 5 \
  --rounds 4 \
  --model "claude-sonnet-4-6" \
  --brand "mirra" \
  --output-dir "~/.openclaw/workspace/data/fast-iterate/mirra-rendang"

# Pipe-friendly (output only the final winner)
bash ~/.openclaw/skills/fast-iterate/scripts/fast-iterate.sh \
  --task "Write a TikTok hook for Wholey Wonder collagen" \
  --criteria "hook_power,curiosity,specificity,emotion" \
  --quiet
```

### Parameters

| Flag | Default | Description |
|------|---------|-------------|
| `--task` | (required) | What to generate |
| `--criteria` | (required) | Comma-separated criteria IDs |
| `--variants` | 3 | Variants per round |
| `--rounds` | 3 | Number of iteration rounds |
| `--model` | claude-sonnet-4-6 | LLM model for generation and evaluation |
| `--brand` | (none) | Brand name — loads DNA.json for brand voice context |
| `--output-dir` | auto-generated | Where to save results |
| `--quiet` | false | Output only the final winner (for piping) |
| `--criteria-file` | (none) | Path to JSON file with detailed criteria descriptions |

### Criteria Shorthand

When using `--criteria` with short IDs, the script expands them to full descriptions:

| ID | Expands To |
|----|-----------|
| `hook_power` | "Opens with a pattern interrupt or curiosity gap that stops the scroll" |
| `clarity` | "Main message is obvious within 3 seconds of reading" |
| `emotion` | "Triggers a specific emotion — not neutral or flat" |
| `urgency` | "Creates time pressure or reason to act now" |
| `brand_voice` | "Matches the brand's established voice and tone" |
| `social_proof` | "Includes or implies social proof — reviews, numbers, community" |
| `local_relevance` | "Contains culturally relevant reference for target market" |
| `specificity` | "Uses specific numbers, names, or details — not vague" |
| `curiosity` | "Creates an information gap that compels further reading" |
| `cta_strength` | "Call to action is clear, specific, and compelling" |
| `scannability` | "Easy to scan on mobile — short paragraphs, bullets, hierarchy" |
| `seo` | "Naturally includes relevant search keywords" |

For custom criteria, use `--criteria-file` with a JSON array of `{id, description}` objects.

## Output Structure

```
output_dir/
  winner.txt                 — Final winning variant (plain text)
  scoring_log.json           — Full scoring history across all rounds
  prompt_evolution.json      — How the prompt changed each round
  rounds/
    round_01/
      variants.json          — All variants with scores
      winner.txt             — Round winner
      analysis.txt           — What made the winner best
      prompt_used.txt        — The prompt used this round
    round_02/
      ...
    round_03/
      ...
```

## Integration with Zennith OS

### As a Standalone Tool
Any agent can call fast-iterate before shipping content:
```bash
# Dreami optimizing ad copy
fast-iterate.sh --task "Instagram caption for MIRRA new menu" \
  --criteria "hook_power,emotion,brand_voice,cta_strength" --brand mirra

# Apollo polishing email copy
fast-iterate.sh --task "Newsletter intro paragraph for Jade Oracle" \
  --criteria "curiosity,emotion,brand_voice,personalization" --brand jade-oracle

# Hermes refining pricing copy
fast-iterate.sh --task "Pricing page headline for Serein subscription" \
  --criteria "clarity,value_framing,urgency,trust" --brand serein
```

### As Part of Content Pipeline
fast-iterate can be called by the content-supply-chain skill as a pre-ship gate:
1. Content generated by Dreami/Apollo
2. fast-iterate runs 3 rounds of quality multiplication
3. Only the winner proceeds to brand-voice-check
4. Then to human review

### Relationship to auto-research
- **fast-iterate** = inner loop, pure LLM, pre-ship quality gate (seconds/minutes)
- **auto-research** = outer loop, real-world feedback, ongoing optimization (hours/days)
- fast-iterate produces good initial content
- auto-research makes it better over time with real performance data

### Pub-Sub Events
- **Emits** `fast-iterate.complete` with winner, score, and prompt evolution
- **Listens** for `pipeline.content.pre-ship` to auto-trigger quality multiplication
- **Listens** for `creative.draft.ready` to iterate on drafts

## CHANGELOG

### v1.0.0 (2026-03-22)
- Initial creation: Pre-ship quality multiplier with multi-round tournament
- fast-iterate.sh: Generate N variants x K rounds with prompt evolution
- Criteria shorthand expansion for common evaluation dimensions
- Full scoring log and prompt evolution history
- Quiet mode for pipe-friendly output
- Pub-sub integration for Zennith OS content pipeline
