---
name: auto-failover
version: "1.0.0"
description: Auto-recovery watchdog for GAIA CORP-OS. Monitors model health, resets bloated sessions, triggers failover when primary model dies.
metadata:
  openclaw:
    scope: infrastructure
    guardrails:
      - Never delete session history files (backup only)
      - Always log failover events to feedback room
      - Auto-restart gateway only if confirmed dead
---

# Auto-Failover — Model Recovery + Session Watchdog

## Purpose

This skill runs as a background watchdog that:
1. Detects when the primary model is down or hitting token limits
2. Auto-resets bloated sessions before they overflow
3. Switches to fallback model when primary fails
4. Auto-restarts the gateway if it crashes
5. Logs all recovery events to the feedback room

## Architecture

```
watchdog.sh (every 5 min via cron)
  ├── Check gateway alive → restart if dead
  ├── Check session token counts → reset if > 80% of context window
  ├── Check recent errors in logs → trigger failover if model errors
  └── Log health status
```

## Model Priority Chain (Zenni / main agent)

| Priority | Model | Provider | Context | Use When |
|----------|-------|----------|---------|----------|
| P1 (Primary) | claude-opus-4-6 | Anthropic | 200K | Default orchestrator |
| P2 (Fallback) | claude-sonnet-4-6 | Anthropic | 200K | When P1 is down |
| P3 (Emergency) | z-ai/glm-4.7 | OpenRouter | 202K | When P1+P2 both down |

## Session Health Thresholds

| Threshold | Action |
|-----------|--------|
| > 80% context window | Warn in logs |
| > 90% context window | Auto-reset session (backup first) |
| Token limit error in logs | Immediate session reset + retry |
| API 429 (rate limit) | Wait 60s, then retry |
| API 500/502/503 | Switch to fallback model |
| Gateway process dead | Auto-restart |

## Cron Registration

```json
{
  "id": "auto-failover-watchdog",
  "name": "Auto-Failover Watchdog",
  "schedule": "*/5 * * * *",
  "timezone": "Asia/Kuala_Lumpur",
  "command": "bash ~/.openclaw/skills/auto-failover/scripts/watchdog.sh",
  "description": "Every 5 min: check model health, reset bloated sessions, restart gateway if dead.",
  "enabled": true
}
```

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial: watchdog script, session auto-reset, gateway auto-restart, model failover
