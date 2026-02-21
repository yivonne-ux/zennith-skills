# Self-Heal

**Tier 2 error recovery — monitors feedback room and auto-recovers from common failure patterns**

## What It Does

Part of the 3-tier self-healing system. Monitors the feedback room for structured errors and attempts automated recovery before escalating to humans.

## 3-Tier Healing Architecture

1. **Tier 1**: Agent retries locally (built into dispatch)
2. **Tier 2**: Self-heal skill (this) — automated recovery patterns
3. **Tier 3**: Escalate to human via exec room

## Features

- **Error pattern matching**: Recognizes common failure types
- **Circuit breaker**: 3 failures in 30 min → stops dispatching to problematic agent
- **Structured error parsing**: Reads `type:error`, `severity`, `error_class`, `needs`
- **Auto-recovery strategies**: API key refresh, session reset, config reload, service restart
- **Escalation**: Posts to exec room when auto-recovery fails

## Error Classes

- `api_error` → retry with backoff, check credentials
- `context_overflow` → session reset
- `rate_limit` → exponential backoff
- `config_error` → validate and reload config
- `timeout` → restart service or increase timeout
- `unknown` → log and escalate

## Usage

```bash
# Run manually
~/.openclaw/skills/self-heal/scripts/error-recovery.sh

# Check logs
tail -f ~/.openclaw/logs/error-recovery-cron.log

# See circuit breaker status
grep "circuit.*open" ~/.openclaw/logs/error-recovery-cron.log
```

## Cron Schedule

Runs every 10 minutes: `*/10 * * * *`

## Integration

Called by: Cron
Monitors: `~/.openclaw/workspace/rooms/feedback.jsonl`
Posts to: `~/.openclaw/workspace/rooms/exec.jsonl` (escalations)
Works with: `auto-failover` (watchdog) and `agent-vitality` (self-improvement)
