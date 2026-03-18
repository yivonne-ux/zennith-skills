# Zennith OS — Pub-Sub Message Protocol (v1)

> Inter-agent communication via typed, subscription-based message routing.
> Inspired by MetaGPT's subscription model. Built for OpenClaw's JSONL rooms.
> Last updated: 2026-03-19

---

## 1. Overview

Zennith OS has two routing systems that coexist:

| System | Handles | How | Cost |
|--------|---------|-----|------|
| **classify.sh** | HUMAN -> AGENT | Regex keyword matching (700+ lines) | Zero LLM |
| **pubsub-dispatch.sh** | AGENT -> AGENT | Typed subscriptions (PUBSUB.json) | Zero LLM |

**classify.sh** routes the first message from users (WhatsApp/Telegram) to the right agent.
**pubsub-dispatch.sh** handles all subsequent inter-agent communication — agents publishing results that trigger work in other agents, forming chains and pipelines.

Together they enable autonomous multi-step execution: a user sends one message, classify.sh picks the first agent, and the pub-sub system chains the rest.

---

## 2. Message Format (JSONL)

Every inter-agent message is a single JSON line appended to a room file.

### Required Fields

```json
{
  "id": "a1b2c3d4e5f6",
  "from": "taoz",
  "type": "code-artifact",
  "content": "Built new skill: video-gen. 3 scripts, 1 SKILL.md. Tests pass.",
  "timestamp": "2026-03-19T14:30:00Z",
  "routed": false,
  "delivered_to": []
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | 12-char UUID fragment. Unique per message. |
| `from` | string | Agent name who produced this message (zenni, taoz, dreami, scout). |
| `type` | string | Message type from PUBSUB.json's `message_types` list. This is the routing key. |
| `content` | string | Free-form text content. Can be plain text or JSON string for structured data. |
| `timestamp` | string | ISO 8601 UTC timestamp. |
| `routed` | boolean | Set to `true` after pubsub-dispatch.sh processes it. Prevents double-routing. |
| `delivered_to` | array | List of agent names this message was delivered to. Audit trail. |

### Optional Fields (Pipeline Context)

```json
{
  "pipeline": "campaign-launch",
  "pipeline_run": "f7e8d9c0",
  "round": 3,
  "target_agent": "dreami"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `pipeline` | string | Pipeline name if this message is part of a pipeline run. |
| `pipeline_run` | string | 8-char UUID for this specific pipeline execution. |
| `round` | integer | Which round of the pipeline produced this message. |
| `target_agent` | string | Set by the dispatcher when routing to a specific agent. |

---

## 3. Agent Subscriptions

Each agent declares two lists in PUBSUB.json:

- **`produces`** — Message types this agent can output
- **`watches`** — Message types this agent reacts to

### Current Subscription Table

```
ZENNI (main) — Orchestrator
  Watches:  escalation, completion-report, error, approval-request, pipeline-summary
  Produces: routing-decision, user-response, status-update, objective-assignment, approval

TAOZ — CTO/Builder
  Watches:  code-request, build-request, bug-report, infrastructure-task,
            deploy-request, skill-request, technical-question
  Produces: code-artifact, build-result, deploy-status, technical-analysis,
            skill-created, infrastructure-report

DREAMI — Creative Director
  Watches:  creative-request, content-request, brand-task, campaign-brief,
            copy-request, video-request, image-request
  Produces: creative-brief, ad-copy, image-prompt, video-script, brand-content,
            campaign-plan, copy-variants

SCOUT — Researcher/QA
  Watches:  research-request, scrape-request, analysis-request, qa-request,
            trend-request, fact-check-request
  Produces: research-report, competitor-analysis, market-data, scrape-result,
            qa-result, trend-report
```

### How Routing Works

1. Agent A finishes work and publishes a typed message (e.g., `type: "code-artifact"`)
2. pubsub-dispatch.sh reads the `type` field
3. Checks PUBSUB.json: which agents have `"code-artifact"` in their `watches` list?
4. Routes the message to each watching agent's room file
5. The watching agent picks it up on next heartbeat or poll

**The sender never needs to know who's listening.** Agents are decoupled.

---

## 4. Room Files

Messages are stored in JSONL room files at `~/.openclaw/workspace/rooms/`.

### Predefined Rooms

| Room | File | Purpose | Primary Writers |
|------|------|---------|----------------|
| exec | exec.jsonl | Leadership decisions, approvals | Zenni, pipeline summaries |
| build | build.jsonl | Technical tasks, code, deploys | Taoz |
| creative | creative.jsonl | Content, copy, visuals | Dreami |
| analytics | analytics.jsonl | Research, data, trends | Scout |
| execution | execution.jsonl | Active task checkpoints | Any active agent |
| feedback | feedback.jsonl | QA results, health alerts | Scout (QA mode) |
| social | social.jsonl | Social media posts | Dreami |
| townhall | townhall.jsonl | Cross-team, dead letters | Any agent |

### Pipeline Rooms

Pipelines get their own room: `pipeline-{name}-{run_id}.jsonl`
Example: `pipeline-campaign-launch-f7e8d9c0.jsonl`

### Agent-to-Room Mapping

pubsub-dispatch.sh maps `(agent, message_type)` to the correct room:

- Messages for **zenni** -> `exec.jsonl`
- Messages for **taoz** -> `build.jsonl`
- Messages for **dreami** -> `creative.jsonl`
- Messages for **scout** -> `analytics.jsonl` (research) or `feedback.jsonl` (QA)
- Unroutable messages -> `townhall.jsonl` (dead letter room)

---

## 5. Pipelines

Pipelines are predefined multi-step flows that chain agents together.

### How Pipelines Work

1. A message type triggers a pipeline (e.g., `content-request` triggers `content-factory`)
2. pipeline-run.sh creates a pipeline-specific room
3. Seeds it with the trigger message
4. For each step in the flow:
   a. Dispatches to the responsible agent
   b. Waits for the agent to produce the expected output type
   c. Feeds the output as context to the next step
5. Continues until all steps complete or max_rounds exhausted
6. Writes a `completion-report` to the exec room

### Defined Pipelines

#### content-factory
```
Trigger: content-request
Flow: scout:research-report -> dreami:creative-brief -> dreami:ad-copy -> dreami:image-prompt
Max rounds: 5
```
Full content production: research market/trends, create brief, write copy, generate image prompts.

#### campaign-launch
```
Trigger: campaign-brief
Flow: scout:research-report -> dreami:creative-brief -> dreami:ad-copy
      -> dreami:image-prompt -> taoz:build-result
Max rounds: 10
```
Full campaign lifecycle including landing page/integration build.

#### bug-fix
```
Trigger: bug-report
Flow: taoz:technical-analysis -> taoz:code-artifact -> taoz:build-result -> scout:qa-result
Max rounds: 5
```
Investigate, fix, verify cycle.

#### brand-audit
```
Trigger: brand-task
Flow: scout:research-report -> scout:competitor-analysis -> dreami:creative-brief
Max rounds: 5
```
Brand health assessment with competitive context.

#### skill-build
```
Trigger: skill-request
Flow: taoz:technical-analysis -> taoz:code-artifact -> taoz:build-result -> scout:qa-result
Max rounds: 5
```
Design, build, test new OpenClaw skills.

### Round-Based Execution

Each pipeline has a `max_rounds` limit. A "round" is one dispatch-and-wait cycle:

```
Round 1: Dispatch to scout, wait for research-report
Round 2: Dispatch to dreami with research context, wait for creative-brief
Round 3: Dispatch to dreami with brief, wait for ad-copy
...
```

The pipeline stops when:
- All flow steps are complete (SUCCESS)
- max_rounds exhausted (PARTIAL — report what completed)
- Agent timeout on a step (continues to next round)

### Pipeline Output

Every pipeline produces a `completion-report` in the exec room:

```json
{
  "from": "zenni",
  "type": "completion-report",
  "content": {
    "pipeline": "content-factory",
    "run_id": "f7e8d9c0",
    "status": "complete",
    "steps_completed": 4,
    "steps_total": 4,
    "rounds_used": 4,
    "max_rounds": 5,
    "room": "pipeline-content-factory-f7e8d9c0"
  }
}
```

---

## 6. CLI Reference

### pubsub-dispatch.sh

```bash
# Publish a typed message and auto-route to watchers
pubsub-dispatch.sh publish <from_agent> <type> "<content>" [--room R] [--pipeline P] [--round N]

# Process unrouted messages in a room file
pubsub-dispatch.sh route <room_file.jsonl>

# Process all pending in a named room
pubsub-dispatch.sh drain <room_name>

# Show subscription table
pubsub-dispatch.sh status

# Check who watches a type
pubsub-dispatch.sh check <message_type>

# List all valid message types
pubsub-dispatch.sh types
```

### pipeline-run.sh

```bash
# Run a pipeline
pipeline-run.sh <pipeline_name> "<initial_input>" [--dry-run] [--verbose]

# List available pipelines
pipeline-run.sh list

# Show pipeline details
pipeline-run.sh describe <pipeline_name>
```

---

## 7. How Agents Use the Pub-Sub System

### Publishing Results

After completing work, an agent publishes its output:

```bash
bash ~/.openclaw/bin/pubsub-dispatch.sh publish taoz code-artifact \
  "Built video-gen skill. 3 scripts, tests pass. Path: ~/.openclaw/skills/video-gen/"
```

The dispatcher automatically routes this to any agent watching `code-artifact`.

### Requesting Work From Another Agent

Instead of knowing which agent handles what, publish a typed request:

```bash
bash ~/.openclaw/bin/pubsub-dispatch.sh publish zenni code-request \
  "Build a new skill for batch image resizing. Input: directory of PNGs. Output: resized WebP."
```

Taoz watches `code-request` and will receive this automatically.

### Inside Pipeline Context

When an agent runs inside a pipeline, it should publish to the pipeline room:

```bash
bash ~/.openclaw/bin/pubsub-dispatch.sh publish scout research-report \
  "Found 5 competitor brands in MY bento market: ..." \
  --room pipeline-content-factory-f7e8d9c0 \
  --pipeline content-factory \
  --round 1
```

---

## 8. Migration Guide: classify.sh to Hybrid Routing

### Current State (classify.sh only)
```
User message -> classify.sh -> picks ONE agent -> dispatch.sh -> agent responds
```

### Target State (classify.sh + pubsub)
```
User message -> classify.sh -> picks FIRST agent -> dispatch.sh -> agent works
                                                                      |
                                                                      v
                                                              agent publishes result
                                                                      |
                                                                      v
                                                              pubsub-dispatch.sh routes
                                                              to watching agents
                                                                      |
                                                                      v
                                                              chain continues...
```

### Migration Steps

**Phase 1: Coexistence (Current)**
- classify.sh continues handling all HUMAN -> AGENT routing
- pubsub-dispatch.sh handles AGENT -> AGENT routing
- No changes to classify.sh needed
- Agents learn to publish typed outputs after completing work

**Phase 2: Agent Adoption**
- Update agent SOUL.md files to include pub-sub publishing instructions
- Add `pubsub-dispatch.sh publish` calls to skill scripts that produce outputs
- Monitor `pubsub.log` for routing patterns

**Phase 3: Pipeline Integration**
- Identify recurring multi-agent workflows (content creation, campaigns, bug fixes)
- Define them as pipelines in PUBSUB.json
- classify.sh can trigger pipelines directly for known multi-step requests:
  ```bash
  # In classify.sh, when detecting a campaign request:
  bash ~/.openclaw/bin/pipeline-run.sh campaign-launch "$TASK" &
  echo "PIPELINE:campaign-launch"
  ```

**Phase 4: Autonomous Loops**
- Agents publish completion reports that trigger further work
- Pipelines chain automatically without human intervention
- Zenni monitors completion-reports and escalations only
- classify.sh becomes the entry point; pub-sub handles the chain

### What Does NOT Change
- classify.sh remains the HUMAN -> AGENT router (zero LLM cost, deterministic)
- Room file format stays JSONL (just gains structured `type` field)
- dispatch.sh still handles the actual OpenClaw agent spawning
- Agent models and heartbeats remain as configured in openclaw.json

---

## 9. Adding New Agents

To add a new agent to the pub-sub system:

1. Add agent entry to `PUBSUB.json` under `agents`:
   ```json
   "new_agent": {
     "id": "new_agent",
     "role": "Description",
     "produces": ["output-type-1", "output-type-2"],
     "watches": ["input-type-1", "input-type-2"],
     "priority": 5
   }
   ```

2. Add any new message types to the `message_types` array

3. Optionally define pipelines that include the new agent

4. Update the agent's SOUL.md with pub-sub publishing instructions

5. No changes needed to pubsub-dispatch.sh or pipeline-run.sh — they read from PUBSUB.json dynamically.

---

## 10. Adding New Message Types

1. Add the type string to `message_types` in PUBSUB.json
2. Add to relevant agents' `produces` and/or `watches` lists
3. The dispatcher validates types — unknown types are rejected with an error

---

## 11. Observability

### Log File
All routing decisions logged to: `~/.openclaw/workspace/rooms/logs/pubsub.log`

Format:
```
2026-03-19T14:30:00Z [INFO] Published [code-artifact] from=taoz to room=build
2026-03-19T14:30:00Z [INFO] Routed [code-artifact] from=taoz -> zenni (room=exec)
2026-03-19T14:30:01Z [WARN] No agents watch type 'custom-event' — sending to dead letter room
```

### Pipeline Rooms
Each pipeline run creates its own room file with full message history:
`~/.openclaw/workspace/rooms/pipeline-{name}-{run_id}.jsonl`

### Status Command
```bash
pubsub-dispatch.sh status    # Full subscription table
pubsub-dispatch.sh check bug-report   # Who handles bugs?
```

---

## 12. Design Principles

1. **Zero LLM cost** — All routing is deterministic JSON lookup. No AI needed for dispatch.
2. **Decoupled agents** — Agents publish typed outputs. They never need to know who listens.
3. **Append-only rooms** — JSONL files are append-only. No message deletion. Full audit trail.
4. **Idempotent routing** — `routed: true` flag prevents double-processing.
5. **Graceful degradation** — Unknown types go to dead letter room. Timeouts are logged, not fatal.
6. **macOS compatible** — Bash 3.2, no associative arrays, no GNU-only flags.
7. **Config-driven** — PUBSUB.json is the single source of truth. Scripts read it dynamically.
