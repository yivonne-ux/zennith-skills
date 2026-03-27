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
agents:
  - dreami
  - main
---

# Content Tuner — Phase 4 of the Content Factory

## Purpose

Automated strategy improvement -- the system that makes everything else get smarter over time. Closes the feedback loop by reading real performance data, identifying what works, and evolving the playbooks that Dreami and the team use.

Without the tuner, the content-intel playbook is static. With the tuner, the playbook evolves based on what actually performs for GAIA's audience.

## How It Works

1. **Read winning patterns** from `winning-patterns.jsonl` (produced by ad-performance analysis and seed bank queries)
2. **Compare against content-intel defaults** -- hook templates, copywriting formulas, channel specs
3. **Promote patterns that consistently outperform** -- 3+ data points AND >20% improvement get added to content-intel
4. **Flag underperformers** -- defaults that never appear in winning patterns get flagged for Jenn's review (never auto-removed)
5. **A/B test new ideas** -- ab-framework.sh manages structured A/B tests between defaults and winning patterns

## Safety Rules

- **Promotion threshold:** 3+ data points AND >20% average improvement. No exceptions.
- **No auto-removal:** Underperforming defaults are flagged, never removed. Jenn decides.
- **Logging:** Every tuning decision logged to `tuning-log.jsonl` with full evidence.
- **A/B minimum:** Variants need >10% improvement to beat control.
- **Audit trail:** All actions post summaries to exec and feedback rooms.

## Scripts

### tune.sh — Weekly Tuning Cycle
```
bash ~/.openclaw/skills/content-tuner/scripts/tune.sh
```
Runs the full cycle: read patterns -> extract defaults -> compare -> promote/flag -> log -> post summary.
**Cron:** Sunday 20:00 MYT via Zenni (main)

### ab-framework.sh — A/B Testing Framework
```
bash ~/.openclaw/skills/content-tuner/scripts/ab-framework.sh <command> [options]
```
Commands: `create` | `evaluate` | `list` | `summary`
**Cron:** Daily 10:00 MYT -- `evaluate` command via Zenni (main)

## Data Files

| File | Purpose |
|------|---------|
| `~/.openclaw/workspace/data/winning-patterns.jsonl` | Input: winning patterns from ad performance |
| `~/.openclaw/workspace/data/tuning-log.jsonl` | Output: audit log of all tuning decisions |
| `~/.openclaw/workspace/data/ab-tests.jsonl` | A/B test records |
| `~/.openclaw/skills/content-intel/SKILL.md` | Target: playbook updated with promoted patterns |

## Integration Points

### Reads From
- `winning-patterns.jsonl` -- patterns from ad performance and seed bank queries
- `content-intel/SKILL.md` -- current default templates, formulas, specs
- `seeds.jsonl` -- via seed-store.sh for A/B test performance data

### Writes To
- `content-intel/SKILL.md` -- appends "Recommended by Performance Data" section
- `tuning-log.jsonl`, `ab-tests.jsonl`, `winning-patterns.jsonl` (status updates)

### Posts To Rooms
- **exec** -- weekly tuning summary, A/B test results
- **creative** -- promotion notifications for Dreami
- **feedback** -- underperformer flags, A/B control wins

> Load `references/winning-patterns.md` for all confirmed winning pattern JSON specs (tutorial format, CN localization, heritage Malaysian, brand DNA compliance, retargeting rotation), underperformer flags, and Zenni DNA writing workflow.

## CHANGELOG

### v1.1.0 (2026-03-10)
- LOOP Integration: MIRRA/Jade Oracle winning patterns, 5 auto-qualified patterns, 3 underperformer flags, DNA writing workflow

### v1.0.0 (2026-02-13)
- Initial creation: tune.sh, ab-framework.sh, safety thresholds, audit logging
