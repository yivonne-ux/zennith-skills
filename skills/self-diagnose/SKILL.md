---
name: self-diagnose
agents:
  - taoz
  - main
---

# Self-Diagnose Skill

## Description
System health diagnostics for GAIA OS. Checks session counts, gateway RAM, A2A bridge status, and cron errors.

## Usage
```bash
bash ~/.openclaw/skills/self-diagnose/scripts/diagnose.sh
```

## Checks Performed
1. **Session Count** — RED FLAG if > 80
2. **Gateway RAM** — RED FLAG if > 1GB
3. **Gateway Status** — RED FLAG if not running
4. **A2A Bridge** — YELLOW if gaia-secondary offline
5. **Cron Errors** — YELLOW if > 3 errors in last 24h

## Output
- Human-readable diagnostics with emoji status indicators
- Summary with actionable next steps
- Logged to `~/.openclaw/workspace-main/memory/YYYY-MM-DD.md`

## Cron Integration
Run via OpenClaw cron every 8 hours:
```json
{
  "schedule": "0 */8 * * *",
  "action": "Run system diagnostics",
  "script": "bash ~/.openclaw/skills/self-diagnose/scripts/diagnose.sh"
}
```

## Red Flag Thresholds
| Check | Threshold | Action |
|-------|-----------|--------|
| Sessions | > 80 | Kill zombie sessions |
| Gateway RAM | > 1GB | Restart gateway |
| Gateway Status | Not running | `openclaw gateway start` |
| Cron Errors | > 3 consecutive | Investigate root cause |

## Related Skills
- `healthcheck` — Host security hardening
- `taoz-auditor` — Code audit and regression testing
