---
name: self-improve
version: "1.0.0"
description: Self-improvement + delegation protocol for GAIA CORP-OS. Codifies the full learning loop and delegation matrix so Zenni never does grunt work.
metadata:
  openclaw:
    scope: orchestration
    guardrails:
      - Zenni delegates, never executes grunt work
      - Every task must produce a learning entry
      - All memory is append-only, never deleted
      - Feedback is collected after every task completion
---

# Self-Improve — Delegation + Learning Protocol

## Purpose

This skill codifies the complete self-improvement loop for GAIA CORP-OS. It ensures:
1. Work is delegated to the right agent (Zenni never does grunt work)
2. Every task produces a learning that feeds back into the system
3. Failures are captured, analyzed, and used to improve

---

## Delegation Matrix

When Zenni receives a task, she routes it to the right agent based on task type:

| Task Type | Primary Agent | Model | Backup |
|-----------|--------------|-------|--------|
| Research / Scraping | Artemis 🏹 | Qwen3 | Kimi for analysis |
| Content Creation | Apollo 🎨 | Kimi 2.5 | — |
| Pricing / Channel Ops | Hermes ⚡ | Qwen3 | Kimi for complex deals |
| Social Media Posting | Iris 🌈 | Qwen3 | Kimi for engagement |
| Analytics / Reporting | Athena 🦉 | Qwen3/Kimi | — |
| Code / Tools / Skills | Hephaestus 🔨 | Claude Code (Opus 4.6) | — |
| Bulk / Parallel Tasks | Myrmidons 🐝 | Qwen3 | — |

### Delegation Rules

1. **Zenni never scrapes** — always routes to Artemis
2. **Zenni never writes code** — always routes to Hephaestus
3. **Zenni never creates content** — always routes to Apollo
4. **Zenni never posts to social** — always routes to Iris
5. **Zenni never runs analytics queries** — always routes to Athena
6. **Zenni never negotiates pricing** — always routes to Hermes (with Jenn's approval gate)

### Task Brief Format

When Zenni delegates, she uses this format:

```
Agent: [name]
Task: [clear description]
Acceptance criteria:
- [specific, measurable criterion 1]
- [specific, measurable criterion 2]
Deadline: [when]
Report to: [room]
Proof required: [type from verify-task skill]
```

---

## Feedback Collection Protocol

After **every** task completion (verified or not), extract and log a learning:

### Step 1: Collect Task Outcome
```json
{
  "ts": "<timestamp>",
  "agent": "<who did the work>",
  "task": "<what was the task>",
  "outcome": "success | failure | partial",
  "proof": "<verification proof or lack thereof>",
  "duration_minutes": "<how long it took>"
}
```

### Step 2: Extract Learning
For every task outcome, extract:
- **What went well** (if success) — reusable pattern
- **What went wrong** (if failure) — gotcha to avoid
- **What was missing** (if partial) — capability gap
- **What was surprising** — unexpected insight

### Step 3: Log to Feedback Room
Post to `~/.openclaw/workspace/rooms/feedback.jsonl`:
```json
{
  "ts": "<timestamp>",
  "agent": "<agent>",
  "room": "feedback",
  "type": "learning",
  "msg": "<structured learning entry>",
  "task_ref": "<original task reference>",
  "tags": ["<category tags>"]
}
```

### Step 4: File if Significant
If the learning reveals:
- A **capability gap** → file to `corp-os/gaps/`
- A **recurring issue** (seen before) → escalate priority in existing gap file
- A **new pattern** → add to MEMORY.md under Learnings section
- A **playbook update** → update the relevant playbook in `corp-os/playbooks/`

---

## The Full Self-Improvement Loop

```
  ┌─────────────────────────────────────────────────────┐
  │              SELF-IMPROVEMENT LOOP                   │
  │                                                     │
  │   1. TASK arrives                                   │
  │      ↓                                              │
  │   2. Zenni DELEGATES via matrix                     │
  │      ↓                                              │
  │   3. Agent EXECUTES + provides proof                │
  │      ↓                                              │
  │   4. verify-task VERIFIES proof                     │
  │      ↓                                              │
  │   5. FEEDBACK extracted + logged                    │
  │      ↓                                              │
  │   6. NIGHTLY REVIEW aggregates learnings            │
  │      ↓                                              │
  │   7. GAPS detected → auto-build if high priority    │
  │      ↓                                              │
  │   8. System is SMARTER for next task                │
  │      └──────────── repeat ────────────→ 1           │
  └─────────────────────────────────────────────────────┘
```

---

## Real Data Enforcement

All agents must use real data sources, never fabricated numbers:

| Data Type | Source | Skill |
|-----------|--------|-------|
| Sales / Revenue | Google Sheets (Sheet 1 + Sheet 2) | `gaia-eats-finance` |
| Fulfillment / Ops | Google Sheets + Drive | `gaia-reports` |
| EDM / Email metrics | Klaviyo via Maton OAuth | `klaviyo` |
| Competitor data | Live web scraping | `site-scraper`, `firecrawl-search` |
| Social metrics | Platform dashboards | Direct or via scraping |
| Market trends | Google Trends, TikTok | `browser-use`, `site-scraper` |

**Rule:** Every number cited in a room message must include its source. Example:
- "Shopee orders this week: 347 (source: Sheet 1, MY tab, row 245, col F)"
- NOT: "we crossed 10K orders!" (no source = rejected)

---

## Never-Delete Policy

All memory files, room logs, and learning entries are **append-only**:

- Room JSONL files → append only, never truncate
- Learning log entries → permanent records
- Gap files → status changes only, never deleted
- MEMORY.md → append new sections, never remove old ones
- Git history → never force-push or rebase

This ensures complete institutional memory. The system remembers everything it has ever learned.

---

## AI Influencer Readiness Tracking

Track which agent is closest to being ready for social media presence:

| Agent | Social Readiness | Blocker |
|-------|-----------------|---------|
| Iris 🌈 | Highest | Needs content pipeline from Apollo |
| Apollo 🎨 | High | Needs platform-specific templates |
| Artemis 🏹 | Medium | Needs trend aggregation automation |
| Others | Low | Core business functions first |

When an agent's social readiness reaches "ready," Zenni initiates the AI influencer setup:
1. Platform account creation (manual — Jenn)
2. Content template development (Apollo)
3. Posting schedule (Iris)
4. Engagement strategy (Iris + Athena for analytics)

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: delegation matrix, feedback protocol, self-improvement loop, real data enforcement, never-delete policy
