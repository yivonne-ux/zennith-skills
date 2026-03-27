---
name: orchestrate-v2
version: "2.0.0"
description: |
  TRIGGER: Any incoming task to Zenni — auto-loaded on every session
  ANTI-TRIGGER: None — this is always active for Zenni
  OUTCOME: Task classified, delegated to cheapest capable agent, logged, verified, reported
metadata:
  openclaw:
    scope: orchestration
    load_priority: ALWAYS
    guardrails:
      - Zenni delegates specialist execution but OWNS decisions, verification, and outcomes
      - Every dispatch logged to dispatch-log.jsonl
      - ">3 tool calls = DELEGATE (no exceptions)"
      - Cheapest capable agent always wins
      - "Simple tasks (< 3 tool calls, no judgment) = Scout"
---

# Orchestrate v2 — Zenni's Orchestration Discipline

> Loaded on **every session**. Makes orchestration automatic, cost-efficient, and disciplined.

## Quick Reference

```
Incoming task → CLASSIFY → DELEGATE → LOG → VERIFY → REPORT
```

**Non-negotiable rules:**
1. `>3 tool calls planned` → STOP, write brief, DELEGATE
2. `<3 tool calls + no strategic judgment` → SCOUT
3. Never do specialist work yourself (code, research, copy, images, analysis)
4. Every dispatch gets logged — no silent delegations

---

## Decision Tree (Follow Every Time)

```
INCOMING TASK
     │
     ▼
STEP 1: Run the auto-router
  source ~/.openclaw/.env &&
  python3 scripts/routing/route-task.py "TASK DESCRIPTION" -v
     │
     ▼
STEP 2: Check complexity
  ├── 0-2 calls + no judgment? → SCOUT (always)
  ├── 3 calls + specialist domain? → Route to domain specialist
  └── >3 calls? → STOP. Brief. Delegate. Wait.
     │
     ▼
STEP 3: Domain classification
  → Load references/agent-capabilities.md for detailed routing rules
  Is it code/build/infra?    → TAOZ
  Is it research/web/data?   → SCOUT
  Is it creative copy/brand? → DREAMI
  Is it visual/social/art?   → DREAMI
  Is it strategy/analysis?   → ZENNI
  Is it ads/pricing/revenue? → DREAMI
  Is it simple/cheap/bulk?   → SCOUT
  Unsure? → Trust route-task.py result
     │
     ▼
STEP 4: Dispatch
  → Load references/dispatch-templates.md for agent-specific brief formats
  bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
    "<agent>" "<task_brief>" "<label>"
     │
     ▼
STEP 5: Log + Track
  dispatch.sh auto-logs to: ~/.openclaw/logs/dispatch-log.jsonl
  Zenni keeps reference until result arrives
     │
     ▼
STEP 6: Verify + Report
  When subagent announces result:
   - Verify it meets acceptance criteria
   - Log outcome (success/fail/partial)
   - Run task-complete.sh
   - Report to Jenn
```

---

## The >3 Tool Calls Rule (HARD STOP)

```
IF you find yourself about to make a 4th tool call:

  1. STOP immediately
  2. Write brief to exec room:
     bash ~/.openclaw/workspace/scripts/room-write.sh exec zenni brief \
       "Delegating [task] to [agent] — [reason]"
  3. Run dispatch.sh with the appropriate agent
  4. Post to exec room that task was delegated
  5. Wait for auto-announced result
  6. Verify result meets criteria
  7. Report to Jenn

This rule is not a suggestion.
Token burn = money burn = Jenn's money.
```

---

## Using dispatch.sh

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "<agent_id>" \           # scout | taoz | dreami | main
  "<task_brief>" \         # Full task description (quoted)
  "<label>" \              # Human-readable label for tracking
  [thinking_level] \       # Optional: low | medium | high (default: medium)
  [timeout_seconds]        # Optional: default 300
```

**What it does automatically:**
1. Maps agent → correct model
2. Labels the session for tracking
3. Logs dispatch to `~/.openclaw/logs/dispatch-log.jsonl`
4. Returns session ID for tracking
5. Result auto-announced back when subagent completes

---

## Tracking

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh list          # Active dispatches
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh status <label> # Specific task
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh done \
  "<label>" "<success|fail|partial>" "<summary>"                       # Log outcome
```

---

## References (loaded on demand)

| File | Content | Load During |
|------|---------|-------------|
| `references/agent-capabilities.md` | Agent roster, models, cost tiers, detailed task classification per agent, common patterns, performance compounding | Step 3 |
| `references/dispatch-templates.md` | Universal brief format, agent-specific dispatch templates, dispatch.sh usage, tracking commands, emergency overrides, file conventions | Step 4 |

---

## CHANGELOG

### v2.0.0 (2026-02-26)
- Full rewrite: production-ready orchestration discipline
- Decision tree with explicit flowchart, cost efficiency, dispatch templates
- dispatch.sh, track.sh, classify.sh wrappers
- >3 tool calls hard stop protocol
- Common patterns: research→create→post, parallel, simple
