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

## Content Performance Review (added to Nightly + Weekly)

### Nightly Addition (22:30 MYT)

After step 4 (Extract patterns), also:

5b. **Scan seed bank for new performance data**
   - Read `~/.openclaw/workspace/data/seeds.jsonl`
   - Filter seeds updated in last 24h (by ts) with non-null performance data
   - Summarize: N seeds with new metrics, top performer, worst performer
   - Append to nightly review learning-log entry

### Weekly Addition (Sunday 22:30 MYT)

After step 3 (Week in Review), also:

4b. **Content Performance Report**
   Include in the "Week in Review" townhall post:

   ```
   ## Content Performance Report

   ### Top 5 Seeds by ROAS
   [Query: bash seed-store.sh top --metric roas --top 5]

   ### Top 5 Seeds by Engagement
   [Query: bash seed-store.sh top --metric engagement --top 5]

   ### Worst 5 Seeds (learn from these)
   [Query: bash seed-store.sh query --status tested --sort performance --top 5 (reverse)]

   ### Tuning Recommendations Applied This Week
   [Read: ~/.openclaw/workspace/data/tuning-log.jsonl, filter last 7 days]

   ### A/B Test Results
   [Read: ~/.openclaw/workspace/data/ab-tests.jsonl, filter completed in last 7 days]

   ### Seed Bank Stats
   - Total seeds: N
   - Seeds with performance data: N
   - Winners: N
   - New seeds this week: N
   ```

### Integration Commands

```bash
# Seed bank CLI
SEED_STORE="$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh"

# Top performers
bash "$SEED_STORE" top --metric roas --top 5
bash "$SEED_STORE" top --metric ctr --top 5

# Seed bank stats
bash "$SEED_STORE" count
bash "$SEED_STORE" count --status winner
bash "$SEED_STORE" count --status tested

# Winning patterns
cat ~/.openclaw/workspace/data/winning-patterns.jsonl | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        p = json.loads(line.strip())
        if p.get('status') in ('detected','confirmed','promoted'):
            print(f\"  {p['description']} (evidence: {p['evidence_count']})\")
    except: pass
"

# A/B test results
cat ~/.openclaw/workspace/data/ab-tests.jsonl | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        t = json.loads(line.strip())
        if t.get('status','').startswith('winner'):
            r = t.get('results', {})
            print(f\"  {t['test_type']}: {t['status']} (improvement: {r.get('improvement','n/a')})\")
    except: pass
"
```

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

## NIGHTLY CRYSTALLIZATION PROTOCOL

Every night (cron at 2am), read rooms/feedback.jsonl and:

1. **Extract Patterns**
   - Find insights that appeared 3+ times
   - Find errors that were solved the same way
   - Find wins that can be replicated

2. **Crystallize into Skills**
   - If pattern works 3+ times → encode into a skill
   - Create or update ~/.openclaw/skills/<pattern-name>/SKILL.md

3. **Update Agent SOUL.md**
   - Add learned behaviors to relevant agent's SOUL.md
   - Example: If Apollo learns a winning hook format, add to his SOUL.md

4. **Update MEMORY.md**
   - Add cross-agent insights to MEMORY.md
   - These become common knowledge

5. **Report to Townhall**
   - Write summary to rooms/townhall.jsonl
   - "Compound Learning Report: X patterns crystallized, Y insights shared"

## CROSS-POLLINATION

Agents should read rooms/feedback.jsonl at session start to learn from others.
