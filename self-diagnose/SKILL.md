---
name: self-diagnose
version: "1.0.0"
description: Comprehensive self-diagnosis system for GAIA CORP-OS. Gathers issues, analyzes root causes, auto-fixes problems, verifies repairs, and learns from incidents.
metadata:
  openclaw:
    scope: infrastructure
    guardrails:
      - Never delete session files without backup
      - Never auto-add cron entries (warn only)
      - Always log fixes to feedback room before applying
      - Escalate to exec room only when truly stuck
      - Never modify openclaw.json
---

# Self-Diagnose -- Full-Stack System Health Intelligence

## Purpose

This skill provides deep, autonomous health monitoring and self-healing for the entire GAIA CORP-OS platform. It goes beyond the existing watchdog (model health) and error-recovery (reactive fixes) by running a 5-phase diagnostic pipeline:

1. **GATHER** -- Collect all symptoms from every data source
2. **ANALYZE** -- Categorize, rank severity, detect patterns
3. **FIX** -- Auto-remediate what is safe to fix
4. **VERIFY** -- Confirm fixes worked, try alternatives if not
5. **LEARN** -- Store diagnosis in RAG memory for future reference

## Architecture

```
diagnose.sh (main entry point)
  |-- PHASE 1: GATHER (symptoms from rooms, logs, agents, cron, daemons, disk)
  |-- PHASE 2: ANALYZE (categorize, rank, detect recurrence)
  |-- PHASE 3: FIX (auto-remediate safe issues)
  |-- PHASE 4: VERIFY (re-check fixes, try alternatives, escalate)
  +-- PHASE 5: LEARN (store in RAG memory, update patterns, log to JSONL)

agent-health.sh (per-agent deep check)
  |-- Session file size + bloat detection
  |-- Last activity timestamp
  |-- Error count in feedback room
  |-- Token usage estimate
  +-- Model reachability ping
```

## Commands

| Command | Description | Phases |
|---------|-------------|--------|
| `diagnose` | Full 5-phase diagnosis | 1-5 |
| `check` | Quick health snapshot (no fixes) | 1 only |
| `history` | Show last 10 diagnosis results | read log |
| `fix <type>` | Force-fix a specific issue type | 3-4 |

### Issue Types

| Type | Severity | Auto-fixable | Fix Action |
|------|----------|-------------|------------|
| `session_bloat` | warning | Yes | Backup + reset session |
| `agent_unresponsive` | warning | Yes | Restart agent session |
| `gateway_error` | critical | Yes | Restart gateway |
| `daemon_down` | critical | Yes | Restart room-watcher |
| `cron_missing` | warning | No | Warn only (too risky) |
| `disk_full` | critical | No | Escalate |
| `model_unreachable` | warning | No | Escalate |
| `room_errors` | info | No | Log pattern |
| `log_errors` | warning | Depends | Varies by error class |

## Cron Registration

```json
[
  {
    "id": "self-diagnose-check",
    "name": "Self-Diagnose Quick Check",
    "schedule": "*/15 * * * *",
    "timezone": "Asia/Kuala_Lumpur",
    "command": "bash ~/.openclaw/skills/self-diagnose/scripts/diagnose.sh check",
    "description": "Every 15 min: quick health snapshot, no fixes.",
    "enabled": true
  },
  {
    "id": "self-diagnose-full",
    "name": "Self-Diagnose Full Diagnosis",
    "schedule": "0 */2 * * *",
    "timezone": "Asia/Kuala_Lumpur",
    "command": "bash ~/.openclaw/skills/self-diagnose/scripts/diagnose.sh diagnose",
    "description": "Every 2 hours: full 5-phase diagnosis with auto-fix.",
    "enabled": true
  }
]
```

## Diagnosis Log Format (JSONL)

```json
{"ts":1707900000000,"type":"diagnosis","cmd":"diagnose","issues_found":3,"issues_fixed":2,"issues_escalated":1,"details":"session_bloat:dreami(fixed),gateway_timeout(fixed),cron_missing:improve(escalated)","duration_s":12}
```

## Relationship to Other Skills

| Skill | Relationship |
|-------|-------------|
| `auto-failover` (watchdog) | Watchdog handles gateway + session resets on tight loop. Self-diagnose does deeper analysis. |
| `self-heal` (error-recovery) | Error-recovery reacts to feedback room errors. Self-diagnose proactively scans ALL sources. |
| `rag-memory` | Diagnosis results stored as learnings for future pattern matching. |
| `room-watcher` | Self-diagnose checks if room-watcher daemon is running. |
| `session-lifecycle-manager` | Self-diagnose checks session sizes that lifecycle manager should maintain. |

## CHANGELOG

### v1.0.0 (2026-02-14)
- Initial: 5-phase diagnosis pipeline (gather, analyze, fix, verify, learn)
- Per-agent health checker (agent-health.sh)
- Auto-fix: session bloat, unresponsive agents, gateway errors, daemon restarts
- Cron: quick check every 15 min, full diagnosis every 2 hours
- RAG memory integration for learning from incidents
