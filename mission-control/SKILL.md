---
name: mission-control
version: "1.0.0"
description: Central nervous system for GAIA CORP-OS. Agents communicate via dispatch, check missions, and self-heal with A/B/C retry strategies.
metadata:
  openclaw:
    scope: orchestration
    guardrails:
      - Never delete mission history
      - Max 3 retry strategies per error (A/B/C then escalate)
      - All inter-agent messages logged to rooms
      - Budget cap: $5/day for auto-spawned agent work
---

# Mission Control — Inter-Agent Communication & Self-Healing

## Purpose

Makes agents communicate, coordinate on missions, and self-heal errors by trying multiple strategies until one works.

## Architecture

```
MISSIONS.md (shared state — all agents read this)
     ↓
dispatch.sh (agent-to-agent messaging)
     ↓
mission-check.sh (runs every 10 min — checks mission progress, spawns agents)
     ↓
rooms/*.jsonl (communication log — agents post results here)
     ↓
feedback.jsonl (learning log — what worked, what didn't)
```

## Inter-Agent Communication

Agents communicate via rooms + dispatch:

1. **Post to room** — agent writes result to `rooms/<name>.jsonl`
2. **Dispatch** — agent asks another agent to do something via `dispatch.sh`
3. **Read room** — agent reads recent entries from a room to get context
4. **Mission board** — all agents check `MISSIONS.md` for current priorities

### Dispatch Format

```bash
bash dispatch.sh <from_agent> <to_agent> <action> <message> [room]
```

Actions: `request`, `report`, `escalate`, `handoff`, `ping`

## Self-Healing with A/B/C Strategies

When an error occurs:

1. **Check mission board** — which mission is affected?
2. **Review history** — what was tried before? (read feedback room)
3. **Try Strategy A** — the obvious fix (restart, retry, reset)
4. **If A fails → Try Strategy B** — alternative approach (different model, different agent, different method)
5. **If B fails → Try Strategy C** — creative solution (break task down, search for solution, invoke Claude Code)
6. **If C fails → Escalate** — post to exec room for Jenn

### Strategy Templates

| Error Type | Strategy A | Strategy B | Strategy C |
|-----------|-----------|-----------|-----------|
| Model timeout | Retry with longer timeout | Switch to fallback model | Break into smaller subtasks |
| Empty response | Reset session + retry | Try different agent | Simplify prompt + retry |
| API error | Wait 60s + retry | Switch provider | Search for alternative API |
| Task failure | Retry with more context | Assign to different agent | Invoke Claude Code to diagnose |
| Data missing | Check cached data | Try alternative source | Ask Jenn for data |
| Stale mission | Retry primary agent | Try alternative agent | Claude Code creative fix |

## Scripts

### dispatch.sh — Inter-Agent Messaging

```bash
bash ~/.openclaw/skills/mission-control/scripts/dispatch.sh <from> <to> <action> <message> [room]
```

- `request` / `handoff` — auto-invokes the target agent via `openclaw agent`
- `report` / `ping` — just posts to the room (no invocation)
- `escalate` — posts to target room AND feedback room
- All messages logged to `~/.openclaw/logs/dispatch.log`

### mission-check.sh — Periodic Mission Scanner

Runs every 10 min via system crontab. Does:

1. **Parse MISSIONS.md** — extract active/in-progress missions
2. **Check room activity** — count recent entries per mission room
3. **Detect stale missions** — based on priority thresholds:
   - P0 (critical): stale after 1 hour
   - P1 (high): stale after 4 hours
   - P2 (medium): stale after 12 hours
   - P3 (low): stale after 24 hours
4. **Scan rooms for errors** — detect failures, timeouts, escalations
5. **A/B/C retry** — auto-try strategies with state tracking
6. **Circuit breaker** — after 3 consecutive failures, stop invoking an agent for 10 min

State tracked in `~/.openclaw/logs/mission-state.json`:
- Per-mission: which strategies tried, results, resolved flag
- Per-agent: circuit breaker status, consecutive failure count

## Cron Schedule

```
*/10 * * * * bash mission-check.sh  # Every 10 min
```

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: MISSIONS.md, dispatch.sh, mission-check.sh
- A/B/C retry strategies with state tracking
- Circuit breaker pattern for agent failures
- Auto-escalation to exec room after C exhaustion
