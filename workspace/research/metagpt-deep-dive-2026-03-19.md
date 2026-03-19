# MetaGPT Deep Dive: Architecture, Lessons, and Zennith OS Comparison

**Date:** 2026-03-19
**Researcher:** Zenki (Claude Opus 4.6)
**Purpose:** Understand MetaGPT architecture deeply. Extract patterns for Zennith OS evolution.

---

## 1. WHAT IS METAGPT

MetaGPT is a **multi-agent framework** (65.5k GitHub stars, MIT license) that assigns different roles to LLMs to form a collaborative software company. Its core philosophy: **Code = SOP(Team)** -- it materializes Standard Operating Procedures and applies them to LLM-based teams.

- **Paper:** "MetaGPT: Meta Programming for A Multi-Agent Collaborative Framework" (ICLR 2024)
- **Latest version:** v0.8.2 (March 2025)
- **Commercial product:** MGX (MetaGPT X) -- launched Feb 2025, #1 Product of the Week on ProductHunt
- **Language:** Python 97.5%, requires Python 3.9-3.12
- **Key research:** AFlow (ICLR 2025, oral, top 1.8%) -- automated workflow generation via Monte Carlo Tree Search

---

## 2. ARCHITECTURE DEEP DIVE

### 2.1 The Four Core Abstractions

MetaGPT is built on four clean abstractions that everything else composes from:

```
Role  -->  Action  -->  Message  -->  Environment
(who)     (what)       (how)         (where)
```

#### ROLE (Agent)
The base agent unit. Every role has:
- **Identity:** `name`, `profile`, `goal`, `constraints`, `desc`
- **Capabilities:** `actions` (list of Action classes it can perform)
- **State machine:** `states` list with `state` index tracking current position
- **Memory:** Three-tier -- `memory` (persistent), `working_memory` (task-specific), `msg_buffer` (async inbox)
- **Subscriptions:** `watch` set -- which Action types this role reacts to
- **React modes:** `REACT` (LLM chooses next action), `BY_ORDER` (sequential), `PLAN_AND_ACT` (plan then execute)
- **Lifecycle:** `_observe()` -> `_think()` -> `_act()` -> `_react()` -- the core loop

```python
# MetaGPT role lifecycle (simplified)
async def run(self, with_message=None):
    # 1. Observe: process messages from buffer
    news_count = await self._observe()
    if news_count == 0:
        return None

    # 2. React: think-act loop
    response = await self._react()

    # 3. Publish result to environment
    self.publish_message(response)
    return response
```

#### ACTION (Task)
The unit of work. Each action:
- Wraps an LLM call with structured input/output
- Can use `ActionNode` for structured execution (temperature, format control)
- Connected to roles via composition (roles own actions)
- Has `i_context` for accepting different context types (CodingContext, TestingContext, etc.)
- The `cause_by` field on messages tracks which action produced them (critical for routing)

**43 built-in actions including:**
- `write_prd.py` -- Product requirements
- `design_api.py` -- API design
- `write_code.py` -- Code generation
- `write_test.py` -- Test generation
- `write_code_review.py` -- Code review
- `debug_error.py` -- Error debugging
- `fix_bug.py` -- Bug fixing
- `research.py` -- Research tasks

#### MESSAGE (Communication)
The inter-agent communication unit:
- `id` -- UUID
- `content` -- natural language text
- `role` -- sender type ("user", "system", "assistant")
- `cause_by` -- which Action class produced this message
- `sent_from` -- originating component
- `send_to` -- set of recipient identifiers (default: broadcast)
- `instruct_content` -- optional structured data (BaseModel)

**MessageQueue:** Async deque with `push()`, `pop()`, `pop_all()`, persistence via JSON.

#### ENVIRONMENT (World)
The shared space where roles live:
- `roles` dict -- registry of all active roles
- `member_addrs` -- maps roles to their address sets (routing table)
- `history` -- Memory object logging all messages
- `publish_message()` -- broadcasts to roles matching `send_to` addresses
- `run()` -- executes one round: collects non-idle roles, runs them concurrently via `asyncio.gather()`
- `is_idle` -- returns True only when ALL roles report idle

### 2.2 The Subscription Model (How Agents Listen)

This is MetaGPT's most elegant pattern. Instead of explicit routing:

```python
# Each role declares what action outputs it cares about
class Engineer(Role):
    def __init__(self):
        self._watch([WriteDesign])  # Engineer watches for design docs

class Architect(Role):
    def __init__(self):
        self._watch([WritePRD])  # Architect watches for PRDs
```

When a ProductManager produces a PRD (via `WritePRD` action), the message's `cause_by` field is set to `WritePRD`. The Architect's `_observe()` method checks incoming messages against its `watch` set. Match found -> message enters the Architect's memory -> triggers `_think()` -> `_act()`.

**This is publish-subscribe, not explicit routing.**

### 2.3 The Team & Execution Loop

```python
class Team:
    async def run(self, n_round=3, idea=""):
        if idea:
            self.env.publish_message(Message(content=idea))  # Seed the system

        while n_round > 0:
            if self.env.is_idle:
                break  # All agents done
            n_round -= 1
            self._check_balance()  # Budget guard
            await self.env.run()  # One round: all agents run concurrently

        return self.env.history
```

**Key insight:** The system runs in rounds. Each round, ALL non-idle agents run concurrently. Messages produced in round N are consumed in round N+1. This creates a natural pipeline without explicit orchestration.

### 2.4 The Software Company Pipeline (SOP in Practice)

```
Requirement (user input)
    |
    v
ProductManager --> WritePRD --> PRD document
    |                              |
    v                              v
Architect <-- watches WritePRD --> WriteDesign --> System design + API specs
    |                                                    |
    v                                                    v
ProjectManager <-- watches WriteDesign --> ProjectManagement --> Task breakdown
    |                                                               |
    v                                                               v
Engineer <-- watches ProjectManagement --> WriteCode --> Implementation
    |                                                        |
    v                                                        v
QAEngineer <-- watches WriteCode --> WriteTest --> Tests + results
```

Each role watches the output of the previous role. No central router needed. The SOP emerges from the subscription graph.

### 2.5 Memory Architecture

**Three levels within each Role:**
1. **`msg_buffer`** (MessageQueue) -- Async inbox. Messages arrive here via `put_message()`. Processed during `_observe()`.
2. **`memory`** (Memory) -- Persistent storage. Messages indexed by action type. Supports `get_by_role()`, `get_by_action()`, `try_remember(keyword)`, `find_news()`.
3. **`working_memory`** -- Task-specific temporary storage. Cleared between major tasks.

**Environment-level:**
- `history` (Memory) -- All messages ever published. Audit trail.

**No embedding-based retrieval.** Memory search is keyword/action-index based. Simple but fast.

### 2.6 AFlow -- Automated Workflow Generation

AFlow (ICLR 2025, oral presentation, top 1.8%) is MetaGPT's breakthrough in automated workflow design:

**Core idea:** Instead of humans designing agent workflows, use Monte Carlo Tree Search (MCTS) to automatically discover effective workflows.

**Components:**
- **Node** -- Single LLM invocation with controllable temperature, format, prompt
- **Operator** -- Predefined node combinations (Generate, Format, Review, Revise, Ensemble, Test, Programmer)
- **Workflow** -- Connected graph of nodes representing an execution plan
- **Optimizer** -- MCTS variant that iteratively selects, expands, evaluates, and refines workflows
- **Evaluator** -- Assesses workflow performance, provides improvement signals

**Usage:**
```bash
python -m examples.aflow.optimize --dataset MATH --max_rounds 20
```

Supports: HumanEval, MBPP, GSM8K, MATH, HotpotQA, DROP benchmarks.

**Key insight:** AFlow proves that agent workflows can be discovered, not just designed. This is the future of multi-agent orchestration.

---

## 3. MGX (MetaGPT X) -- The Commercial Product

- **URL:** mgx.dev
- **Launch:** Feb 19, 2025
- **Positioning:** "The world's first AI agent development team"
- **Purpose:** Natural language programming -- describe what you want, a team of AI agents builds it
- **Achievement:** #1 Product of Day (Mar 4, 2025), #1 Product of Week (Mar 10, 2025) on ProductHunt
- **Architecture:** Uses `MGXEnv` (extended environment) instead of base `Environment`
- **Team:** TeamLeader, ProductManager, Architect, Engineer2, DataAnalyst

MGX proves the commercial viability of the multi-agent SOP approach. It took a research framework and turned it into a product that non-technical users can access.

---

## 4. METAGPT vs ZENNITH OS -- STRUCTURAL COMPARISON

### 4.1 Agent System

| Dimension | MetaGPT | Zennith OS (OpenClaw) |
|-----------|---------|----------------------|
| **Agent definition** | Python class inheriting `Role` | JSON config in `openclaw.json` + SOUL.md identity |
| **Agent count** | 14 built-in roles | 10 agents (Zenni, Taoz, Dreami, Scout, Artemis, Hermes, Athena, Iris, Argus, Jade) |
| **Identity model** | `name`, `profile`, `goal`, `constraints` | SOUL.md (rich personality, voice, philosophy) |
| **Capabilities** | `Action` classes (Python code) | Skills (shell scripts + SKILL.md) |
| **Model binding** | Single LLM per team (configurable) | Per-agent model assignment (heterogeneous) |
| **Autonomy level** | Fully autonomous within round budget | Heartbeat-driven + human-triggered |

**Zennith advantage:** Rich identity system (SOUL.md) gives agents personality, not just function. Heterogeneous model assignment (right model for right job) is more cost-efficient than one-model-fits-all.

**MetaGPT advantage:** Programmatic role definition is more composable. New roles can be created in code without config changes.

### 4.2 Orchestration / Routing

| Dimension | MetaGPT | Zennith OS |
|-----------|---------|------------|
| **Routing method** | Pub-sub via `_watch()` subscriptions | Deterministic keyword matching via `classify.sh` |
| **Central router** | None (emergent from subscription graph) | Zenni + classify.sh (explicit) |
| **LLM cost for routing** | Zero (subscription matching) | Zero (grep-based keyword matching) |
| **Flexibility** | Adding new role = define watches | Adding new pattern = edit classify.sh regex |
| **Pipeline** | Implicit (subscription chains) | Explicit (tier system: RELAY/LOOKUP/SCRIPT/CODE/DISPATCH) |

**MetaGPT advantage:** Pub-sub is more elegant and scalable. No central router bottleneck. Adding a new role automatically integrates into the pipeline based on what it watches. No regex maintenance.

**Zennith advantage:** The 5-tier system (RELAY/LOOKUP/SCRIPT/CODE/DISPATCH) is pragmatic and handles real-world complexity (not everything is an LLM call). The SCRIPT and CODE tiers are brilliant -- most agent frameworks force everything through LLM, wasting money.

### 4.3 Communication

| Dimension | MetaGPT | Zennith OS |
|-----------|---------|------------|
| **Message format** | Python `Message` class with UUID, content, cause_by, send_to | JSONL in rooms/*.jsonl |
| **Delivery** | In-memory `publish_message()` via Environment | File-based (JSONL append) + `sessions_spawn` + `sessions_send` |
| **Persistence** | Serializable but primarily in-memory | JSONL files (durable by default) |
| **Cross-machine** | Not supported natively | Gateway + WhatsApp/Telegram channels |
| **Cost** | Free (in-process) | `sessions_send` costs tokens; rooms are free |

**MetaGPT advantage:** In-process message passing is fast, simple, typed.

**Zennith advantage:** File-based rooms are durable, debuggable, cross-machine. Real-world messaging channels (WhatsApp, Telegram) connect AI to humans naturally.

### 4.4 Memory

| Dimension | MetaGPT | Zennith OS |
|-----------|---------|------------|
| **Storage** | In-memory list + action-type index | Daily markdown files + vector embeddings |
| **Search** | Keyword + action-type lookup | `memory_search` (vectorized, semantic) |
| **Persistence** | Session-scoped (serializable) | Permanent (daily files, auto-vectorized every ~2h) |
| **Cross-agent** | Shared Environment history | Shared rooms, KNOWLEDGE-SYNC.md bridge |
| **Learning** | No explicit learning loop | OBSERVE -> LEARN -> IMPROVE -> CRYSTALLIZE -> COMPOUND |

**MetaGPT advantage:** Action-type indexing is clever for structured workflows. Fast lookup by action type.

**Zennith advantage:** Persistent memory with compounding loop is far more sophisticated. The "living organism" philosophy means agents actually get better over time, which MetaGPT does not do.

### 4.5 Execution Model

| Dimension | MetaGPT | Zennith OS |
|-----------|---------|------------|
| **Loop type** | Round-based (n_round iterations) | Heartbeat-driven + event-triggered |
| **Concurrency** | `asyncio.gather()` all non-idle roles per round | maxConcurrent: 6, subagent spawning |
| **Budget control** | `invest()` + `_check_balance()` | Token cost tracking per provider |
| **Idle detection** | `is_idle` property on all roles | Session timeout + pruning |
| **Pipeline** | Automatic (round N output -> round N+1 input) | Manual dispatch or heartbeat triggers |

**MetaGPT advantage:** The round-based execution model is clean and predictable. All agents run, produce output, next round all agents process those outputs. Natural pipeline without orchestration code.

**Zennith advantage:** Event-triggered + heartbeat is more suitable for always-on production systems. MetaGPT's round model is for batch jobs (generate a codebase), not continuous operations (run a business 24/7).

### 4.6 SOP vs Classify.sh

| Dimension | MetaGPT SOP | Zennith classify.sh |
|-----------|-------------|---------------------|
| **Philosophy** | "Encode human work processes into agent pipelines" | "Route user requests to the right agent" |
| **Scope** | Full workflow (requirement -> design -> code -> test) | Single routing decision |
| **Pipeline stages** | Implicit via subscription chains | Explicit via tier system |
| **Modification** | Create new Role + Action classes | Edit regex patterns in bash |
| **Error handling** | ExecutableFeedback (run code, check errors, retry) | Rigour gate (lint/test before shipping) |

**Critical insight:** These solve different problems. MetaGPT SOPs define *how work flows through a pipeline*. classify.sh defines *who handles a request*. Zennith needs BOTH -- routing (classify.sh) AND pipeline definitions (SOPs for each domain).

---

## 5. WHAT ZENNITH OS SHOULD ADOPT

### 5.1 ADOPT: Subscription-Based Routing (Pub-Sub)

**Current state:** classify.sh is a 700+ line bash script with regex patterns. Every new capability requires editing the regex. Fragile, hard to test, impossible for agents to modify themselves.

**MetaGPT pattern:** Each role declares `_watch([ActionType1, ActionType2])`. When a message is produced by that action type, the watching role automatically picks it up.

**Proposed for Zennith:**
```json
// In each agent's config or SOUL.md
{
  "watches": ["creative-brief", "ad-copy", "brand-content"],
  "produces": ["visual-content", "ad-image", "social-post"]
}
```

When Dreami produces a `creative-brief`, any agent watching `creative-brief` (e.g., Iris for visuals, Hermes for ad placement) automatically gets triggered. No classify.sh edit needed.

**Migration path:** Keep classify.sh for human-initiated requests (the entry point). Add pub-sub for agent-to-agent communication (the pipeline).

### 5.2 ADOPT: Round-Based Execution for Pipelines

**Current state:** Multi-step workflows require explicit orchestration. Zennith spawns agents one by one, waits for results, spawns the next.

**MetaGPT pattern:** Define the pipeline as a subscription graph. Run rounds until idle. The pipeline executes itself.

**Proposed for Zennith:**
```
Campaign Pipeline:
  Round 1: Athena (strategy) produces competitive-analysis
  Round 2: Dreami (watching competitive-analysis) produces creative-brief
  Round 3: Iris (watching creative-brief) produces ad-visuals
           Apollo (watching creative-brief) produces ad-copy
  Round 4: Hermes (watching ad-visuals + ad-copy) produces campaign-package
  Round 5: All idle -> pipeline complete
```

This could be implemented as a "pipeline runner" skill that reads a pipeline definition (JSON/YAML) and executes rounds until all agents report idle.

### 5.3 ADOPT: Action-Type Message Indexing

**Current state:** Messages in rooms are plain JSONL. No structured indexing by type.

**MetaGPT pattern:** Every message has `cause_by` (what action produced it). Memory is indexed by action type for fast lookup.

**Proposed for Zennith:** Add a `type` field to room messages:
```jsonl
{"from":"dreami","type":"creative-brief","content":"...","ts":"2026-03-19T10:00:00"}
{"from":"iris","type":"ad-visual","content":"...","ts":"2026-03-19T10:05:00"}
```

Agents can then quickly find all messages of a specific type without parsing content.

### 5.4 ADOPT: Structured Role Definition

**Current state:** Agent capabilities are defined across multiple files (SOUL.md, classify.sh patterns, skill symlinks). No single source of truth for "what can this agent do."

**MetaGPT pattern:** Role class defines `actions` list -- clear, programmatic, queryable.

**Proposed for Zennith:** Add a `capabilities` section to each agent's config:
```json
{
  "id": "dreami",
  "capabilities": {
    "actions": ["write-copy", "create-brief", "script-video", "brand-voice-check"],
    "watches": ["competitive-analysis", "brand-update", "campaign-request"],
    "produces": ["creative-brief", "ad-copy", "video-script", "social-post"]
  }
}
```

This becomes the single source of truth. classify.sh can read from it. Pub-sub can use it. Agents can query each other's capabilities.

### 5.5 CONSIDER: AFlow-Style Workflow Discovery

**Current state:** Workflows are manually designed by Jenn + Taoz.

**MetaGPT AFlow:** Uses MCTS to automatically discover effective workflows by trying variations and measuring results.

**Proposed for Zennith (future):** After accumulating enough campaign data (which campaigns performed best), use a discovery process to find optimal agent pipelines. E.g., "Does adding Athena's strategy step before Dreami's creative improve ROAS?" Test it. Measure it. Compound the learning.

This aligns perfectly with the GAIA Vision's compounding loop: OBSERVE -> LEARN -> IMPROVE -> CRYSTALLIZE -> COMPOUND.

### 5.6 DO NOT ADOPT: Single-Process Architecture

MetaGPT runs all agents in one Python process. This works for batch jobs (generate a codebase) but breaks for:
- Always-on operation (Zennith runs 24/7)
- Cross-machine deployment (iMac + MacBook)
- Heterogeneous models (each agent uses different LLM)
- Real-world channels (WhatsApp, Telegram)
- Cost isolation (track spend per agent)

OpenClaw's distributed architecture (gateway + separate agent processes + channels) is correct for a production AI OS. Keep it.

### 5.7 DO NOT ADOPT: Software Company Metaphor

MetaGPT is locked into the software company metaphor (PM -> Architect -> Engineer -> QA). Zennith OS operates a **brand portfolio** across marketing, manufacturing, manpower, and money pillars. The metaphor should remain the **living organism / amoeba model** -- cells that grow, learn, and compound.

---

## 6. INSTALLATION FEASIBILITY

### Can We Install MetaGPT Locally?

**Yes, trivially:**
```bash
pip install --upgrade metagpt
# Requires Python 3.9-3.12, Node.js, pnpm
```

**Config at:** `~/.metagpt/config2.yaml`

**Would it complement or compete with OpenClaw?**

**Complement, not compete.** They solve different problems:

| | MetaGPT | OpenClaw/Zennith |
|--|---------|-----------------|
| **Best for** | Batch projects (build a codebase, write a report) | Continuous operations (run a business 24/7) |
| **Trigger** | One-shot command | Always-on heartbeats + human messages |
| **Output** | Artifact (repo, document) | Ongoing operations (campaigns, content, ops) |
| **Channels** | CLI / programmatic | WhatsApp, Telegram, web |

**Potential integration:** Use MetaGPT as a "project mode" within Zennith. When Taoz needs to build a complex codebase, spawn a MetaGPT pipeline instead of doing it all in one Claude Code session. The SOP pipeline (PRD -> Design -> Code -> Test) could improve code quality for large projects.

---

## 7. KEY LESSONS FROM METAGPT

### Lesson 1: Subscriptions > Central Router
MetaGPT's pub-sub model eliminates the single point of failure / maintenance burden of a central router. Each agent declares what it cares about. The system self-organizes.

### Lesson 2: SOPs Are Just Subscription Chains
You don't need a separate "SOP engine." If Agent A watches for Action X and produces Action Y, and Agent B watches for Action Y, you have an SOP. The pipeline is emergent.

### Lesson 3: Rounds Create Natural Pipelines
Running all agents concurrently in rounds, where round N+1 processes round N's output, creates pipelines without orchestration code. This is cleaner than explicit dispatch.

### Lesson 4: Action Types Enable Smart Routing
Tagging every message with its action type (`cause_by`) enables agents to filter for exactly the messages they need. No content parsing, no regex matching.

### Lesson 5: Budget Guards Are Essential
MetaGPT's `invest()` + `_check_balance()` pattern prevents runaway costs. Zennith should formalize this -- per-pipeline budgets, not just per-provider tracking.

### Lesson 6: Three React Modes Cover All Cases
- **REACT** (LLM chooses): For complex, ambiguous tasks
- **BY_ORDER** (sequential): For known pipelines
- **PLAN_AND_ACT** (plan then execute): For multi-step tasks requiring upfront planning

Zennith agents currently don't have explicit react modes. Adding this would give each agent a configurable strategy for how it handles incoming work.

### Lesson 7: Idle Detection Prevents Infinite Loops
MetaGPT's `is_idle` check prevents the system from running forever. When all agents have nothing to do, the pipeline terminates. Critical for autonomous loops.

### Lesson 8: AFlow Proves Workflows Can Be Discovered
The most profound lesson: optimal workflows don't have to be designed by humans. Given enough data and a search algorithm, the system can find them. This is the ultimate expression of the compounding loop.

---

## 8. RECOMMENDED ROADMAP FOR ZENNITH OS

### Phase 1: Structured Agent Capabilities (Week)
Add `capabilities.watches` and `capabilities.produces` to each agent in `openclaw.json`. This is the foundation for pub-sub. Zero disruption to existing system.

### Phase 2: Message Type Tagging (Week)
Add `type` field to room JSONL messages. Update agents to tag their outputs. This enables action-type indexing.

### Phase 3: Pipeline Runner Skill (2 Weeks)
Build a `pipeline-runner` skill that:
1. Reads a pipeline definition (YAML)
2. Runs rounds until all participating agents are idle
3. Collects outputs into a structured result
4. Tracks budget per pipeline

Use case: Campaign Pipeline, Content Supply Chain, Product Launch Pipeline.

### Phase 4: Pub-Sub Layer (2 Weeks)
Implement subscription matching in the gateway. When an agent produces a message with `type: X`, automatically deliver it to all agents whose `capabilities.watches` includes `X`. This replaces manual dispatch for agent-to-agent workflows while keeping classify.sh for human-to-agent routing.

### Phase 5: React Modes (1 Week)
Add `reactMode` to agent config: `"reactive"` (LLM chooses), `"sequential"` (follow SOP), `"plan-first"` (plan then execute). Each agent gets the mode that suits its role.

### Phase 6: Workflow Discovery (Future)
Once enough pipeline execution data exists, build an AFlow-inspired optimizer that discovers better agent pipelines by testing variations and measuring outcomes.

---

## 9. SUMMARY TABLE

| What | MetaGPT Does | Zennith OS Does | Gap? | Action |
|------|-------------|-----------------|------|--------|
| Agent definition | Python classes | JSON + SOUL.md | Different, both valid | Add `capabilities` to config |
| Routing | Pub-sub subscriptions | Regex classify.sh | YES -- pub-sub is better for agent-to-agent | Implement pub-sub layer |
| Communication | In-process messages | JSONL rooms + gateway | Different scale, both valid | Add type tags to messages |
| Memory | In-memory + action index | Files + vector embeddings | Zennith is stronger | Keep current approach |
| Execution | Round-based batch | Heartbeat + event-driven | Different use cases | Add pipeline runner for batch workflows |
| Learning | None | Compounding loop | Zennith is MUCH stronger | Keep and deepen |
| Budget control | invest() + balance check | Per-provider tracking | MetaGPT is stronger | Add per-pipeline budgets |
| Workflow discovery | AFlow (MCTS) | Manual design | YES -- big opportunity | Future phase |
| Identity/soul | Minimal (name, goal) | Rich (SOUL.md, personality) | Zennith is stronger | Keep current approach |
| Production readiness | Research framework | Production system | Zennith is stronger | Keep current architecture |

---

**Bottom line:** MetaGPT's pub-sub routing and round-based execution are elegant patterns that Zennith OS should adopt for agent-to-agent workflows. But Zennith's living organism philosophy, persistent memory, compounding loop, heterogeneous models, and production architecture are significantly more advanced for running a real business. The two systems complement each other -- MetaGPT for structured project pipelines, Zennith for continuous business operations.

The single most impactful adoption: **pub-sub subscriptions for agent-to-agent communication**, keeping classify.sh for human-to-agent routing. This eliminates the regex maintenance burden and enables self-organizing pipelines.
