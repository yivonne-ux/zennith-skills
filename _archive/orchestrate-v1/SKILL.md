---
name: orchestrate
version: "1.0.0"
description: Multi-agent orchestration protocol for GAIA CORP-OS. Teaches Zenni how to delegate tasks to real Pantheon agents via OpenClaw CLI.
metadata:
  openclaw:
    scope: orchestration
    guardrails:
      - Zenni delegates, never executes grunt work
      - Every delegation must include acceptance criteria
      - All results posted to rooms
      - Taoz uses claude-code-runner.sh, not openclaw agent
---

# Orchestrate — Multi-Agent Delegation Protocol

## Purpose

This skill teaches Zenni (the orchestrator) how to delegate tasks to real Pantheon agents. Zenni's job is to **think, route, verify** — never to do the grunt work herself.

---

## The Pantheon — Agent Roster

| Agent | ID | Archetype | Model | Domain |
|-------|-----|-----------|-------|--------|
| Zenni | `main` | The Oracle | claude-sonnet-4.6 | Orchestration, governance, Jenn interface |
| Athena | `athena` | The Strategist | glm-5 | Analytics, reporting, insights |
| Hermes | `hermes` | The Merchant | glm-5 | Pricing, promotions, channel ops |
| Apollo | `apollo` | The Muse | qwen3-235b-a22b | Creative, brand, content |
| Artemis | `artemis` | The Scout | kimi-k2.5 | Research, scraping, competitive intel |
| Iris | `iris` | The Voice | qwen3-vl-235b | Social media, community, engagement |
| Taoz | `taoz` | The Forge | qwen3-coder-next | Code, tools, skill building |
| Myrmidons | `myrmidons` | The Swarm | minimax-m2.5 | Bulk tasks, WhatsApp processing |
| Dreami | `dreami` | Creative Director | kimi-k2.5 | Campaign strategy, creative direction |
| Artee | `artee` | Art Director | kimi-k2.5 | Visual QA, brand consistency |

---

## Delegation Matrix

When a task arrives, Zenni routes it based on type:

| Task Type | Route To | Proof Type |
|-----------|----------|------------|
| Research / Scraping / Scouting | Artemis | structured_data |
| Content creation / Copy / EDM | Apollo | content_draft |
| Pricing / Bundles / Channel ops | Hermes | margin_math |
| Analytics / Reporting / Forecasting | Athena | data_table |
| Social posting / Community / Engagement | Iris | post_schedule |
| Code / Tools / Skills / Infrastructure | Taoz | build_log |
| Bulk parallel tasks | Multiple agents | varies |

### Delegation Rules

1. **Zenni never scrapes** — always route to Artemis
2. **Zenni never writes code** — always route to Taoz
3. **Zenni never creates content** — always route to Apollo
4. **Zenni never posts to social** — always route to Iris
5. **Zenni never runs analytics queries** — always route to Athena
6. **Zenni never negotiates pricing** — always route to Hermes (with Jenn approval gate for >RM 500 impact)

---

## How to Delegate

### Step 1: Write the Task Brief

```
Agent: [agent_name]
Task: [clear description of what to do]
Context: [relevant background — what prompted this, any data needed]
Acceptance criteria:
- [specific, measurable criterion 1]
- [specific, measurable criterion 2]
Deadline: [when — ASAP, EOD, specific time]
Room: [which room to post results to — townhall, exec, build, social, feedback]
Proof required: [type — structured_data, content_draft, margin_math, data_table, post_schedule, build_log]
```

### Step 2: Invoke the Agent

Use the delegation script:

```bash
bash ~/.openclaw/skills/orchestrate/scripts/delegate.sh \
  "<agent_id>" \
  "<task_brief>" \
  "<room>" \
  "<proof_type>" \
  "<thinking_level>"
```

Parameters:
- `agent_id` — one of: artemis, apollo, hermes, athena, iris
- `task_brief` — the full task description (quoted)
- `room` — target room: townhall, exec, build, social, feedback
- `proof_type` — expected proof type for verification
- `thinking_level` — optional: low, medium, high (default: medium)

### Step 3: Process Results

When the agent returns:
1. **Verify** the result meets acceptance criteria
2. **Log** the task outcome to the feedback room
3. **Escalate** to Jenn if the result is S1/S2 severity
4. **Post** a summary to the target room if the agent did not already

---

## Special Case: Taoz (Code Tasks)

Taoz uses Claude Code, NOT `openclaw agent`. Invoke via:

```bash
bash ~/.openclaw/skills/claude-code/scripts/claude-code-runner.sh \
  "<review|build>" \
  "<prompt>" \
  "<cwd>" \
  "<budget>"
```

- `review` mode: read-only analysis, $0.50 budget
- `build` mode: full tool access, $1.00 budget

---

## Parallel Delegation

Zenni can delegate to multiple agents simultaneously:
- Maximum 4 concurrent delegations
- Use `&` in bash to run delegate.sh calls in parallel
- Wait for all with `wait`
- Collect results and synthesize

Example:
```bash
bash delegate.sh artemis "Scout Shopee vegan snacks" build structured_data &
bash delegate.sh apollo "Draft Valentine's EDM copy" build content_draft &
wait
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Agent timeout (>300s) | Log timeout, retry once, then escalate to Zenni |
| Empty response | Log gap, try different agent or model |
| Agent error | Log error details to feedback room, retry with higher thinking level |
| Task too complex | Break into subtasks, delegate sequentially |

---

## Post-Delegation Feedback

After every delegation, extract a learning:

```json
{
  "ts": "<timestamp>",
  "agent": "<who did the work>",
  "task": "<what was delegated>",
  "outcome": "success | failure | partial",
  "duration_seconds": "<how long>",
  "learning": "<what we learned>"
}
```

Post to feedback room for nightly review aggregation.

---

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: delegation matrix, task brief format, delegate.sh integration, parallel delegation, error handling
