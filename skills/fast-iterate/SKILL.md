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
Round 1: Generate N variants -> Score each -> Pick winner
         Analyze: "What made the winner best?"

Round 2: Rewrite prompt with Round 1 learnings -> Generate N more -> Score -> Pick winner

Round 3: Even more refined prompt -> Generate N more -> Score -> Pick winner
         Output: Final winner + full scoring log + prompt evolution history
```

Each round produces better variants because the prompt itself improves.
This is meta-learning: the system learns how to ask for what it wants.

## Why This Exists

Every piece of content shipped by Zennith OS should go through fast-iterate first.
A 30-second pass with 3 rounds turns a B+ draft into an A.

Without fast-iterate: 3 rounds of back-and-forth, 15 minutes wasted.
With fast-iterate: 3 rounds of self-improvement in 60 seconds.

## Usage

```bash
# Basic usage
bash ~/.openclaw/skills/fast-iterate/scripts/fast-iterate.sh \
  --task "Write an ad headline for Jade Oracle BaZi readings" \
  --criteria "hook_power,clarity,emotion,urgency,brand_voice"

# Full options
fast-iterate.sh --task "Write a product description for MIRRA Rendang Bento" \
  --criteria "hook_power,clarity,emotion,urgency,brand_voice,social_proof,local_relevance" \
  --variants 5 --rounds 4 --model "claude-sonnet-4-6" --brand "mirra" \
  --output-dir "~/.openclaw/workspace/data/fast-iterate/mirra-rendang"

# Pipe-friendly (output only the final winner)
fast-iterate.sh --task "Write a TikTok hook for Wholey Wonder collagen" \
  --criteria "hook_power,curiosity,specificity,emotion" --quiet
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

> Load `references/examples-and-criteria.md` for multi-round tournament examples, prompt evolution walkthrough, criteria shorthand expansion table, output structure, agent integration examples, and pub-sub events.

## CHANGELOG

### v1.0.0 (2026-03-22)
- Initial creation: Pre-ship quality multiplier with multi-round tournament
- fast-iterate.sh: Generate N variants x K rounds with prompt evolution
- Criteria shorthand expansion for common evaluation dimensions
- Full scoring log and prompt evolution history
- Quiet mode for pipe-friendly output
- Pub-sub integration for Zennith OS content pipeline
