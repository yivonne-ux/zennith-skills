---
name: auto-heal
version: "1.0.0"
description: Self-healing system. When OpenClaw errors can't be fixed by watchdog, auto-assigns to Claude Code Opus 4.6 for diagnosis and repair.
metadata:
  openclaw:
    scope: infrastructure
    guardrails:
      - Never delete user data or conversation history
      - Always backup before modifying config files
      - Max budget per heal attempt: $2.00
      - Max 3 heal attempts per hour (prevent runaway spending)
---

# Auto-Heal — Self-Healing Error Recovery

## Purpose

When the watchdog detects errors it can't fix with simple restarts/resets, auto-heal escalates to Claude Code Opus 4.6 for intelligent diagnosis and repair. No human approval needed.

## How It Works

1. `healer.sh` runs every 5 minutes (after watchdog)
2. Scans recent logs for unresolved errors
3. Classifies error type and severity
4. For simple errors: applies known fix from playbook
5. For complex errors: invokes `claude-code-runner.sh build` with error context
6. Claude Code reads the error, diagnoses root cause, and applies fix
7. Posts result to feedback room
8. Logs learning for future pattern matching

## Error Classification

| Error Pattern | Category | Auto-Fix |
|--------------|----------|----------|
| `token limit exceeded` | session-overflow | Reset session (watchdog handles) |
| `rate_limit\|HTTP 429` | rate-limit | Wait + switch model |
| `session file locked` | lock-stuck | Remove stale lock, restart gateway |
| `HTTP 500\|502\|503` | provider-down | Switch to fallback model |
| `cron.*failed` | cron-broken | Diagnose via Claude Code |
| `TypeError\|ReferenceError` | code-bug | Diagnose via Claude Code |
| `ECONNREFUSED\|ETIMEDOUT` | network | Retry, then escalate |
| `permission denied` | permissions | Fix permissions via Claude Code |

## Guardrails

- Max $2.00 per heal attempt (passed to claude-code-runner.sh)
- Max 3 attempts per hour (tracked in state file)
- Always backs up files before modifying
- Posts all actions to feedback room for audit trail
- Never modifies SOUL.md or USER.md
