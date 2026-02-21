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
        agent: athena
        description: "Weekly tuning cycle — Sunday 20:00 MYT"
      - schedule: "0 10 * * *"
        command: "bash ~/.openclaw/skills/content-tuner/scripts/ab-framework.sh evaluate"
        agent: athena
        description: "Daily A/B test evaluation — 10:00 MYT"
---

# Content Tuner — Phase 4 of the Content Factory

## Purpose

Automated strategy improvement -- the system that makes everything else get smarter over time. The Content Tuner closes the feedback loop in the Content Factory by reading real performance data, identifying what works, and evolving the playbooks that Apollo, Iris, and the rest of the team use to create content.

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

**Cron:** Sunday 20:00 MYT via Athena

### ab-framework.sh — A/B Testing Framework

```
bash ~/.openclaw/skills/content-tuner/scripts/ab-framework.sh <command> [options]
```

Commands:
- `create` -- Create a new A/B test (control vs variant)
- `evaluate` -- Evaluate tests that are ready (past their evaluate_after time)
- `list` -- List active or recent tests
- `summary` -- Summarize all completed tests

**Cron:** Daily 10:00 MYT -- `evaluate` command via Athena

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
- **creative** -- promotion notifications for Apollo to incorporate
- **feedback** -- underperformer flags, A/B control wins

## CHANGELOG

### v1.0.0 (2026-02-13)
- Initial creation: Content Tuner as Phase 4 of the Content Factory
- tune.sh: weekly tuning cycle with pattern promotion and underperformer flagging
- ab-framework.sh: A/B testing framework with create, evaluate, list, summary commands
- Safety: 3+ data points AND >20% improvement threshold for promotions
- Full audit logging to tuning-log.jsonl
