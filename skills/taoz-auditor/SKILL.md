---
name: taoz-auditor
agents:
  - taoz
---

# Taoz Auditor — Self-Improving Routing Intelligence

## What This Is

A self-healing routing system where Taoz (glm-5) audits every dispatch, catches failures, orchestrates retries, extracts patterns, and improves classify.sh over time.

## The Loop

```
Happy path: User → Zenni → classify.sh → Agent → Job done ✓
                                                     ↓
                                              Taoz audits async

Failure path: Agent fails → Taoz orchestrates → Tries alternatives
              → Finds right path → Extracts pattern → Tests in sandbox
              → Promotes to classify.sh → classify.sh gets smarter
```

## Commands

| Command | What it does |
|---------|-------------|
| `gaia-auditor audit` | Review recent dispatches for failures |
| `gaia-auditor orchestrate <label>` | Retry a failed dispatch with alternatives |
| `gaia-auditor learn` | Extract routing patterns from orchestrations |
| `gaia-auditor test` | Run sandbox routing regression |
| `gaia-auditor promote` | Generate new classify.sh rules |
| `gaia-auditor status` | Show audit statistics |
| `gaia-auditor complete <label> <success|fail>` | Log dispatch outcome |
| `gaia-auditor full-cycle` | Run complete audit→orchestrate→learn→test→promote |

## Owner

Taoz (CTO/Builder) — runs via cron or heartbeat.

## Cron Schedule

- `gaia-auditor audit` — every 2 hours
- `gaia-auditor full-cycle` — nightly at 10pm MYT (before nightly.sh)

## Data Files

| File | Purpose |
|------|---------|
| `logs/dispatch-log.jsonl` | All dispatches (written by classify.sh) |
| `logs/audit-log.jsonl` | Audit results and orchestration attempts |
| `logs/audit-learnings.jsonl` | Extracted routing learnings |
| `logs/routing-patterns.jsonl` | Pending/promoted routing rules |

## Claude Code Integration

When Taoz identifies patterns that need new classify.sh rules:
1. Taoz extracts the pattern and suggested grep
2. Fires Claude Code CLI to write the actual rule
3. Claude Code updates classify.sh
4. Taoz runs `gaia-auditor test` to validate
5. If PASS → rule is live
