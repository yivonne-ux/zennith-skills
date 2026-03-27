---
name: corp-os-compound
version: "1.0.0"
description: Enhanced nightly + weekly review for GAIA CORP-OS. Scans rooms, feedback, learning-log — extracts patterns, detects gaps, updates memory. The compounding engine.
metadata:
  openclaw:
    scope: review-and-learn
    guardrails:
      - Never delete existing memory — append only
      - Learning entries are permanent records
      - Gap files trigger skill-building only when priority is "high"
      - Max 1 auto-build per night
agents:
  - taoz
  - main
---

# CORP-OS Compound — Self-Improvement Loop

## Purpose

This skill runs the GAIA self-improvement loop. It reviews what happened, extracts learnings, detects capability gaps, and ensures the system gets smarter every day.

**Core principle:** Every failure is a learning. Every learning compounds. Nothing is wasted.

---

## Nightly Review (22:30 MYT)

**Trigger:** Cron job, daily at 22:30 Asia/Kuala_Lumpur

### Steps

1. **Scan room messages (last 24h)**
   - Read all JSONL files in `~/.openclaw/workspace/rooms/`
   - Filter to messages with `ts` within last 24 hours
   - Categorize: tasks completed, tasks failed, decisions made, signals detected, escalations

2. **Scan feedback room for unresolved failures**
   - Read `~/.openclaw/workspace/rooms/feedback.jsonl`
   - Filter entries with `type: "failure"` or `type: "gap"` that have no corresponding `type: "resolved"` entry

3. **Scan today's learning-log entries**
   - Read files in `~/.openclaw/workspace/corp-os/learning-log/` matching today's date

4. **Extract patterns and gotchas**
   - **Recurring issues** -- same error/failure appearing multiple times
   - **Gotchas** -- things that tripped up agents
   - **Wins** -- what worked well that should be repeated
   - **Capability gaps** -- tasks that couldn't be completed because a skill/tool doesn't exist

5. **Update memory files**
   - Append to `~/.openclaw/workspace/MEMORY.md` under `## Learnings` section
   - Create `~/.openclaw/workspace/corp-os/learning-log/lrng-YYYY-MM-DD-nightly.md` with:
     Summary, Patterns Detected, Gotchas, Wins, Capability Gaps, Actions Taken

6. **File capability gaps**
   - Create `~/.openclaw/workspace/corp-os/gaps/gap-YYYY-MM-DD-<short-title>.md`
   - Fields: Detected, Priority (low/medium/high), Status (detected/building/built/integrated), Description, Evidence, Proposed Solution, Impact
   - High-priority gaps trigger auto-builder

7. **Check for uncommitted skill changes**
   - Auto-commit with: `"chore(nightly): auto-commit uncommitted skill changes from YYYY-MM-DD"`

---

## Weekly Review (Sunday 22:30 MYT)

**Trigger:** Cron job, Sundays at 22:30 Asia/Kuala_Lumpur

### Steps

1. **Read all learning-log entries from past 7 days**

2. **Identify recurring failures** -- issues appearing >2 times -> flag as systemic, escalate to exec room

3. **Produce "Week in Review" to townhall**
   - Post structured summary to `townhall.jsonl` with tasks, top win, top issue, gaps filled/remaining

4. **Recommend threshold/playbook updates**
   - Signal threshold breached >3 times -> recommend adjustment
   - Playbook invoked >2 times -> recommend automation

5. **Skill performance review**
   - Which skills were used / NOT used this week
   - Skills unchanged for >30 days get "review needed" flag

---

## Memory Files (Append-Only Policy)

All memory artifacts follow the **never-delete policy:**
- `MEMORY.md` -- only append new sections, never remove
- `learning-log/` entries -- permanent, never deleted
- `gaps/` files -- status changes only, never deleted
- Room JSONL files -- append-only, never truncated
- Git commits -- never force-pushed or rebased

> Load `references/review-procedures.md` for content performance review (seed bank integration, weekly performance report, integration commands), skill auto-builder procedure and guardrails, nightly crystallization protocol, and cross-pollination rules.

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: nightly review, weekly review, skill auto-builder, append-only memory policy
