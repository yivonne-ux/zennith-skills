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
   - List unresolved issues

3. **Scan today's learning-log entries**
   - Read files in `~/.openclaw/workspace/corp-os/learning-log/` matching today's date
   - Summarize learnings already captured

4. **Extract patterns and gotchas**
   - From today's room activity, identify:
     - **Recurring issues** — same error/failure appearing multiple times
     - **Gotchas** — things that tripped up agents (wrong API, missing data, unclear specs)
     - **Wins** — what worked well that should be repeated
     - **Capability gaps** — tasks that couldn't be completed because a skill/tool doesn't exist

5. **Update memory files**
   - Append to `~/.openclaw/workspace/MEMORY.md` under `## Learnings` section (if new patterns found)
   - Create `~/.openclaw/workspace/corp-os/learning-log/lrng-YYYY-MM-DD-nightly.md` with:
     ```
     # Nightly Review — YYYY-MM-DD

     ## Summary
     - Tasks completed: N
     - Tasks failed: N
     - Decisions made: N
     - Unresolved issues: N

     ## Patterns Detected
     - [pattern descriptions]

     ## Gotchas
     - [gotcha descriptions]

     ## Wins
     - [what worked well]

     ## Capability Gaps
     - [gaps found]

     ## Actions Taken
     - [what was updated/filed]
     ```

6. **File capability gaps**
   - If gaps found, create `~/.openclaw/workspace/corp-os/gaps/gap-YYYY-MM-DD-<short-title>.md`:
     ```
     # Gap: [Title]

     **Detected:** YYYY-MM-DD
     **Priority:** low | medium | high
     **Status:** detected | building | built | integrated

     ## Description
     [What capability is missing]

     ## Evidence
     [What task/failure revealed this gap]

     ## Proposed Solution
     [What skill/tool would fill this gap]

     ## Impact
     [What becomes possible once this gap is filled]
     ```
   - High-priority gaps trigger the auto-builder (see skill-auto-builder section below)

7. **Check for uncommitted skill changes**
   - If `~/.openclaw/skills/` is a git repo, check for modified but uncommitted files
   - If found, auto-commit with descriptive message:
     `"chore(nightly): auto-commit uncommitted skill changes from YYYY-MM-DD"`

---

## Weekly Review (Sunday 22:30 MYT)

**Trigger:** Cron job, Sundays at 22:30 Asia/Kuala_Lumpur

### Steps

1. **Read all learning-log entries from past 7 days**
   - Aggregate all `lrng-*` files from the week

2. **Identify recurring failures**
   - Any issue appearing > 2 times across the week → flag as systemic
   - Systemic issues get escalated to exec room as a decision brief

3. **Produce "Week in Review" to townhall**
   - Post a structured summary to `townhall.jsonl`:
     ```json
     {
       "ts": <now>,
       "agent": "zenni",
       "room": "townhall",
       "msg": "Week in Review (Feb 3-9)\n\nTasks: 23 completed, 4 failed\nTop win: ...\nTop issue: ...\nGaps filled: 2\nGaps remaining: 1\n\nFull review: corp-os/learning-log/lrng-2026-02-09-weekly.md",
       "type": "action"
     }
     ```

4. **Recommend threshold/playbook updates**
   - If a signal threshold was breached > 3 times this week → recommend adjusting the threshold
   - If a playbook was invoked > 2 times → recommend automation or threshold tightening
   - Post recommendations to exec room for Jenn's review

5. **Skill performance review**
   - Check which skills were used this week (from room logs mentioning skill names)
   - Check which skills were NOT used → flag for potential deprecation review
   - Check skill versions → any skill unchanged for > 30 days gets a "review needed" flag

---

## Skill Auto-Builder

When a nightly review finds a **high-priority** gap in `corp-os/gaps/`:

1. Compose a build brief from the gap file
2. Dispatch to `claude-code.build` (budget: $1.00)
3. Verify: skill file exists + skill reload succeeds
4. Post to build room with 4-part execution contract:
   - **Result:** What was built
   - **Proof:** Test output
   - **What Changed:** Files created/modified
   - **Learning:** What we learned during the build
5. Update gap status to `built`
6. Git commit the new skill with semantic version

**Guardrails:**
- Max 1 auto-build per night
- Only high-priority gaps qualify
- Jenn is notified in townhall with a summary of what was auto-built
- If build fails → gap status stays `detected`, failure logged to feedback room

---

## Memory Files (Append-Only Policy)

All memory artifacts follow the **never-delete policy:**
- `MEMORY.md` — only append new sections, never remove existing ones
- `learning-log/` entries — permanent, never deleted
- `gaps/` files — status changes only, never deleted
- Room JSONL files — append-only, never truncated
- Git commits — never force-pushed or rebased

This ensures the system has a complete history of everything that happened and everything it learned.

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: nightly review, weekly review, skill auto-builder, append-only memory policy
