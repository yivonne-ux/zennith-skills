---
name: skill-inspector
version: "1.0.0"
description: Periodic auditor for the GAIA CORP-OS skill ecosystem. Inventories all skills, detects duplicates and overlapping functionality, runs health checks, and suggests optimizations.
metadata:
  openclaw:
    scope: infrastructure
    guardrails:
      - Never delete or modify other skills' files
      - Read-only analysis — report and suggest only
      - Post critical issues to exec room, routine to feedback room
      - Full reports saved to skill-inspection.jsonl
---

# Skill Inspector — Ecosystem Auditor

## Purpose

Periodically audits all OpenClaw and Claude Code skills to keep the skill ecosystem clean, efficient, and free of duplication. Produces actionable reports with merge suggestions, health warnings, and optimization recommendations.

## Commands

| Command | Description |
|---------|-------------|
| `inspect` | Full 5-phase inspection (inventory, similarity, health, optimization, report) |
| `inventory` | List all skills with stats (SKILL.md presence, script count, size, last modified) |
| `check <name>` | Deep-check a single skill |
| `similar` | Run similarity detection only |
| `health` | Run health checks only |
| `report` | Show last saved inspection report |

## Usage

```bash
bash ~/.openclaw/skills/skill-inspector/scripts/inspect.sh inspect
bash ~/.openclaw/skills/skill-inspector/scripts/inspect.sh inventory
bash ~/.openclaw/skills/skill-inspector/scripts/inspect.sh check auto-heal
bash ~/.openclaw/skills/skill-inspector/scripts/inspect.sh similar
bash ~/.openclaw/skills/skill-inspector/scripts/inspect.sh health
bash ~/.openclaw/skills/skill-inspector/scripts/inspect.sh report
```

## Schedule

Weekly inspection: Sunday 3am MYT (cron).

## Output

- Console: human-readable report
- JSONL: `~/.openclaw/workspace/data/skill-inspection.jsonl`
- Rooms: summary to feedback, critical issues to exec

## Phases

1. **Inventory** — Scan all skill dirs, catalog metadata and stats
2. **Similarity Detection** — Keyword overlap in descriptions, script name collisions, cross-skill references
3. **Health Check** — Executable permissions, bash syntax, SKILL.md presence, error handling patterns
4. **Optimization Suggestions** — Merge candidates, large scripts, unused skills, deprecated patterns
5. **Report** — Combine all phases, post to rooms, save JSONL record
