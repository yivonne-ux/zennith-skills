---
name: skill-health
description: Monitor and maintain 90+ skills — staleness detection, dependency health, security scanning, agent assignment checks.
agents:
  - taoz
  - scout
---

# Skill Health — Staleness Detection & Maintenance

3-layer health check for the entire skill library. Detects stale skills, broken dependencies, hardcoded credentials, and missing agent assignments.

## When to Use

- Weekly maintenance scan (cron every Sunday)
- After major skill refactoring
- Before shipping any code changes
- When skills start behaving unexpectedly

## Procedure

### Quick Scan

```bash
bash ~/.openclaw/skills/skill-health/scripts/staleness-check.sh
```

### Single Skill Check

```bash
bash ~/.openclaw/skills/skill-health/scripts/staleness-check.sh --skill nanobanana
```

### Custom Stale Threshold

```bash
bash ~/.openclaw/skills/skill-health/scripts/staleness-check.sh --days 14
```

## What It Checks

| Layer | What | Flags |
|-------|------|-------|
| Staleness | SKILL.md last modified date | >30 days = stale |
| Dependencies | Referenced scripts/files exist | Missing file = broken |
| Security | Hardcoded API keys in code | OpenAI, AWS, GitHub, Slack, Google, Meta patterns |
| Agents | agents: field in YAML frontmatter | Missing = unroutable |

## Key Constraints

- Run from Taoz (builder) context, not production
- Security scan excludes .env and secrets/ directories (those are expected)
- Staleness threshold is configurable (default 30 days)
- Does NOT auto-fix by default (use --fix flag)
