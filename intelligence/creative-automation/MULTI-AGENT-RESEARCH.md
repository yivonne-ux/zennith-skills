# Multi-Agent Architecture & Claude Code: Deep Research Synthesis

**Date:** 2026-03-10
**Scope:** Claude Code patterns, multi-agent orchestration, production failure modes, state management, creative pipeline architecture

---

## 1. Anthropic's Own Multi-Agent Architecture (The Authoritative Blueprint)

Anthropic published their internal multi-agent research system design in June 2025. This is the single most important reference because it reveals the architecture behind Claude's Research feature -- a system that outperformed single-agent Claude Opus 4 by **90.2%** on internal evaluations.

### Architecture: Orchestrator-Worker with Memory Persistence

The system uses a **LeadResearcher** agent that enters an iterative research loop. The LeadResearcher begins by thinking through the approach and **saving its plan to Memory** -- because if the context window exceeds 200,000 tokens, it will be truncated and the plan must survive. It then spawns specialized **Subagents** (typically 3 at a time, running in parallel) with specific research tasks. Each Subagent independently performs web searches, evaluates results using interleaved thinking, and returns findings to the LeadResearcher.

**Critical performance insight**: Token usage by itself explains **80% of the variance** in task performance, with tool call count and model choice as the remaining factors. Multi-agent systems use approximately **15x more tokens** than chat interactions, and **4x more** than single-agent interactions. This means multi-agent is only economically viable when task value justifies the token cost.

**Design lesson for creative pipelines**: Prompt design emerged as the **single most important** lever for guiding agent behavior. Small changes in phrasing made the difference between efficient research and wasted effort. Tool design was equally critical.

Sources:
- [Anthropic: How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
- [ByteByteGo analysis](https://blog.bytebytego.com/p/how-anthropic-built-a-multi-agent)
- [Simon Willison's commentary](https://simonwillison.net/2025/Jun/14/multi-agent-research-system/)

---

## 2. Anthropic's Six Composable Patterns (The Foundation)

Before going multi-agent, Anthropic's canonical "Building Effective Agents" guide establishes six composable patterns, with the key directive: **start with the simplest solution and only increase complexity when needed**.

| Pattern | When to use | Trade-off |
|---|---|---|
| **Augmented LLM** | Single model + retrieval/tools/memory | Baseline, minimal overhead |
| **Prompt Chaining** | Fixed subtask decomposition | Latency for accuracy |
| **Routing** | Input classification to specialized handlers | Separation of concerns |
| **Parallelization** | Independent subtasks or voting | Throughput for token cost |
| **Orchestrator-Workers** | Dynamic task decomposition | Flexibility for complexity |
| **Evaluator-Optimizer** | Quality refinement via feedback loops | Iteration cost for quality |

The critical recommendation: **frameworks can help you get started quickly, but don't hesitate to reduce abstraction layers and build with basic components as you move to production.** Tool documentation should be crafted as carefully as prompts -- tools are prominent in Claude's context window and affect context efficiency.

Sources:
- [Anthropic: Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)
- [AIM Multiple: 6 Composable Patterns](https://aimultiple.com/building-ai-agents)
- [Anthropic: Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

---

## 3. Claude Code Agent Teams & Swarm Orchestration (Current State)

Claude Code now supports **Agent Teams** -- coordinated swarms where one session acts as team lead, spawning teammates that work independently in their own context windows.

### TeammateTool Architecture

The core orchestration layer provides **13 distinct operations**. A swarm consists of:
- **Leader**: Creates team, spawns workers, coordinates work
- **Teammates**: Full independent Claude Code instances, each with its own large context window
- **Task List**: Shared work queue with **dependency tracking**
- **Inboxes**: JSON files for inter-agent messaging

Teammates can **self-claim work** as they finish tasks. This is a pull model, not push -- reducing coordination overhead.

### Best Use Cases
- **Research and review**: Multiple teammates investigate different aspects simultaneously
- **New modules/features**: Each teammate owns a separate piece
- **Debugging with competing hypotheses**: Parallel theory testing
- **Cross-layer coordination**: Frontend, backend, tests each owned by different teammate

### When NOT to Use Teams
Agent teams add coordination overhead and use significantly more tokens. For **sequential tasks, same-file edits, or work with many dependencies**, a single session or subagents are more effective.

### Subagents (SDK)
For programmatic control, the Claude Agent SDK (Python + TypeScript) supports spawning subagents with:
- Custom system prompts per subagent
- Restricted tool access via `allowedTools`
- Independent permissions
- Concurrent execution (e.g., style-checker + security-scanner + test-coverage running simultaneously)

Sources:
- [Claude Code Docs: Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Anthropic Docs: Subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- [Addy Osmani: Claude Code Swarms](https://addyosmani.com/blog/claude-code-agent-teams/)
- [Claude Code Swarm Orchestration Skill (Gist)](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
- [Paddo.dev: Claude Code's Hidden Multi-Agent System](https://paddo.dev/blog/claude-code-hidden-swarm/)

---

## 4. CLAUDE.md Patterns That Actually Work

Research across 2,500+ repositories and multiple practitioner guides reveals clear patterns for effective CLAUDE.md files.

### What Works

1. **Keep it lean**: Frontier LLMs can follow approximately **150-200 instructions** with reasonable consistency. If your CLAUDE.md is too long, important rules get lost. If Claude already does something correctly without the instruction, **delete it**.

2. **High-priority placement matters**: CLAUDE.md and `.claude/rules/` files receive **high priority** in Claude's context weighting. Use CLAUDE.md for universally applicable instructions. Use rules files with path targeting for area-specific patterns (e.g., API patterns for API files only).

3. **Project context in one line**: "This is a Next.js e-commerce app with Stripe integration" orients Claude more than you'd expect.

4. **Compaction instructions**: Customize what survives context compaction with explicit instructions like "When compacting, always preserve the full list of modified files and any test commands."

5. **Reference specific files and constraints**: Precision reduces corrections. Point to example patterns, mention constraints explicitly.

### What Fails

- **Code style guidelines**: Never send an LLM to do a linter's job. Style rules degrade instruction-following and eat context.
- **Overly long files**: Rules buried deep get ignored.
- **Redundant instructions**: If Claude does it correctly by default, the instruction adds noise.

### Multi-File Rules Architecture
For larger projects, the `.claude/rules/` directory allows splitting instructions into focused rule files that are automatically loaded with the same priority as CLAUDE.md but scoped to relevant paths.

Sources:
- [HumanLayer: Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Builder.io: How to Write a Good CLAUDE.md](https://www.builder.io/blog/claude-md-guide)
- [Claude Code Rules Directory](https://claudefa.st/blog/guide/mechanics/rules-directory)
- [Claude Code Best Practices (Official)](https://code.claude.com/docs/en/best-practices)
- [GitHub Blog: How to Write a Great agents.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)

---

## 5. Production Failure Modes (The Hard Truths)

Research shows **41-86.7% of multi-agent LLM systems fail in production**, with most breakdowns occurring within hours of deployment. Nearly **79% of problems originate from specification and coordination issues**, not technical implementation.

### Top Failure Categories

| Category | Frequency | Description |
|---|---|---|
| **Coordination Failures** | 36.94% | Communication breakdowns, state sync issues, conflicting objectives |
| **Verification Gaps** | 21.30% | Inadequate testing, missing validation, poor monitoring |
| **Context Loss at Handoffs** | High | Critical details vanish when one model's reply exceeds another's context window |
| **Silent Handoff Failures** | Common | One agent assumes another completed a task when the handoff failed silently |
| **Schema Drift** | Common | Field names change, data types don't match, formatting shifts between agents |

### Context Loss: The Central Problem

When critical information disappears during handoffs (due to context limits, compression, or misaligned prompts), **downstream agents begin reasoning from incomplete snapshots**. This is the single most destructive failure mode for creative pipelines where aesthetic decisions, brand rules, and rejection history must survive every handoff.

### GitHub's Three Engineering Fixes

GitHub published a definitive guide in February 2026 identifying three patterns that prevent multi-agent failures:

1. **Typed Schemas Over Natural Language**: Enforce strict schemas at every agent boundary. Field names, data types, and formatting must be validated.

2. **Action Schemas Over Vague Intent**: Define the exact set of allowed actions and their structure. LLMs don't follow implied intent -- only explicit instructions.

3. **MCP for Enforcement**: Model Context Protocol defines explicit input/output schemas for every tool, validating calls before execution. Agents can't invent fields, omit required inputs, or drift across interfaces.

The core insight: **treat agents like distributed systems, not chat interfaces**.

Sources:
- [GitHub Blog: Multi-agent workflows often fail](https://github.blog/ai-and-ml/generative-ai/multi-agent-workflows-often-fail-heres-how-to-engineer-ones-that-dont/)
- [Augment Code: Why Multi-Agent Systems Fail](https://www.augmentcode.com/guides/why-multi-agent-llm-systems-fail-and-how-to-fix-them)
- [Galileo: Why Multi-Agent LLM Systems Fail](https://galileo.ai/blog/multi-agent-llm-systems-fail)
- [TechAhead: 7 Failure Modes](https://www.techaheadcorp.com/blog/ways-multi-agent-ai-fails-in-production/)
- [XTrace: AI Agent Context Handoff](https://xtrace.ai/blog/ai-agent-context-handoff)
- [Getmaxim: Multi-Agent System Reliability](https://www.getmaxim.ai/articles/multi-agent-system-reliability-failure-patterns-root-causes-and-production-validation-strategies/)

---

## 6. State Management Between Agents

### Memory Architecture Types

Production multi-agent systems require multiple memory layers:

| Memory Type | Scope | Implementation |
|---|---|---|
| **Working Memory** | Current task scratchpad | Context window, in-memory state |
| **Short-term Memory** | Single session | Thread-level checkpoints (Redis, in-memory savers) |
| **Long-term Memory** | Cross-session persistence | Vector stores, databases, file-based stores |
| **Shared Memory** | Cross-agent coordination | Shared workspace (files, databases, message queues) |
| **Semantic Memory** | Knowledge repository | Facts, concepts, relationships (RAG systems) |
| **Procedural Memory** | Workflow skills | Stored multi-step processes (executable templates) |

### Anthropic's Approach in Practice
The LeadResearcher in Anthropic's system explicitly **saves its plan to Memory** before spawning subagents, because context truncation at 200K tokens would otherwise destroy the research plan. This is a file-based persistence pattern -- the simplest that works.

### Agent Cognitive Compressor
Advanced systems maintain bounded internal state with **explicit separation between what an agent can recall and what it commits to shared memory**. This prevents context pollution while maintaining coordination.

### Practical Implementations
- **Mem0**: Production-ready long-term memory with extraction, consolidation, and retrieval
- **Redis**: Handles both immediate context and cross-session storage in one platform
- **Letta/Zep/LangMem**: Specialized frameworks for memory engineering
- **File-based (CLAUDE.md/JSON)**: Claude Code's native approach via inboxes and task files

Sources:
- [O'Reilly: Why Multi-Agent Systems Need Memory Engineering](https://www.oreilly.com/radar/why-multi-agent-systems-need-memory-engineering/)
- [MongoDB: Agent Memory Guide](https://www.mongodb.com/resources/basics/artificial-intelligence/agent-memory)
- [Redis: AI Agent Memory Architecture](https://redis.io/blog/ai-agent-memory-stateful-systems/)
- [Letta: Agent Memory](https://www.letta.com/blog/agent-memory)
- [Mem0 Paper (arXiv)](https://arxiv.org/pdf/2504.19413)

---

## 7. Google's Eight Multi-Agent Design Patterns

Google published eight foundational patterns built on three execution primitives: **sequential**, **loop**, and **parallel**.

1. **Sequential Pipeline**: Assembly line, deterministic, easy to debug
2. **Coordinator/Router**: One agent receives requests, dispatches to specialists, synthesizes results
3. **Parallel Fan-Out**: Multiple agents work simultaneously on independent tasks
4. **Supervisor-Based**: Central agent plans, delegates, decides when done (can become bottleneck)
5. **Blackboard Architecture**: Specialists contribute partial solutions to shared workspace (no manager bottleneck)
6. **Hierarchical**: Multi-level delegation for complex organizations
7. **Competitive/Voting**: Multiple agents solve same problem, best answer selected
8. **Human-in-the-Loop**: Autonomous for routine, escalate edge cases with monitoring dashboards

**Key insight for creative pipelines**: The **Blackboard Architecture** is particularly relevant -- specialists (layout agent, color agent, typography agent, brand-compliance agent) contribute to a shared design state without routing everything through a manager. This maps naturally to creative production where different aspects of a design can be evaluated independently.

Sources:
- [InfoQ: Google's Eight Essential Multi-Agent Design Patterns](https://www.infoq.com/news/2026/01/multi-agent-design-patterns/)
- [Google Developers Blog: Multi-Agent Patterns in ADK](https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/)
- [Google Cloud: Choose a Design Pattern](https://docs.cloud.google.com/architecture/choose-design-pattern-agentic-ai-system)

---

## 8. Framework Landscape (CrewAI vs AutoGen vs LangGraph vs Claude SDK)

| Framework | Best For | Adoption | Key Strength |
|---|---|---|---|
| **CrewAI** | Linear multi-agent workflows, fast prototyping | 60% Fortune 500, 100K+ devs, 60M+ monthly executions | Role-based syntax readable by non-engineers |
| **AutoGen (Microsoft)** | Multi-party conversations, consensus-building | Research-heavy orgs | Most diverse conversation patterns |
| **LangGraph** | Complex orchestration, maximum control | Production-grade since v1.0 (Jan 2026) | Durable state, graph-based flow control |
| **Claude Agent SDK** | Claude-native workflows, subagent spawning | Growing, native to Claude Code | Deep model integration, built-in tools |

**Market position as of March 2026**: CrewAI has claimed the "Pragmatist's Choice" throne for business workflows. LangGraph leads for complex orchestration requiring maximum control. AutoGen (now Microsoft Agent Framework) targets enterprise conversational agents. Claude SDK is the natural choice when building within the Claude ecosystem.

Sources:
- [DEV.to: AutoGen vs LangGraph vs CrewAI 2026](https://dev.to/synsun/autogen-vs-langgraph-vs-crewai-which-agent-framework-actually-holds-up-in-2026-3fl8)
- [O-Mega: Top 10 Agent Frameworks](https://o-mega.ai/articles/langgraph-vs-crewai-vs-autogen-top-10-agent-frameworks-2026)
- [Lindy: Top 10 AI Agent Frameworks 2026](https://www.lindy.ai/blog/best-ai-agent-frameworks)

---

## 9. Compound AI System Patterns for Production

The industry consensus for 2026: **the agentic AI field is going through its microservices revolution**. Single all-purpose agents are being replaced by orchestrated teams of specialists.

### Tiered Model Architecture
Production systems need multiple tiers:
- **Tier 1 (Fast/Cheap)**: Classification, extraction, routing decisions -- small models at fraction of cost
- **Tier 2 (Capable)**: Complex reasoning, creative generation -- large models for high-value tasks
- **Request routing** that escalates only complex cases to larger models can **reduce costs 60-70%** without impacting user experience.

### Flow Engineering
Designing agent control flow is now considered **the highest-leverage skill in AI engineering**. Most performance gains come from the orchestration layer: retrieval, tools, memory, verification, and guardrails -- not from model upgrades.

### Market Scale
- 40% of enterprise applications projected to embed AI agents by end of 2026 (up from <5% in 2025)
- 57% of companies already running AI agents in production
- LangGraph 1.0 (January 2026) is the first stable major release in the durable agent framework space

Sources:
- [SitePoint: Agentic Design Patterns 2026](https://www.sitepoint.com/the-definitive-guide-to-agentic-design-patterns-in-2026/)
- [Zen van Riel: AI System Design Patterns 2026](https://zenvanriel.nl/ai-engineer-blog/ai-system-design-patterns-2026/)
- [Comet: Multi-Agent Systems Architecture](https://www.comet.com/site/blog/multi-agent-systems/)
- [NexAI Tech: AI Agent Architecture Patterns](https://nexaitech.com/multi-ai-agent-architecutre-patterns-for-scale/)

---

## 10. Synthesis: What This Means for Creative Production Pipelines

### Architecture Recommendation

For a creative production pipeline like Mirra or Bloom & Bare, the research points to a **hybrid architecture**:

1. **Orchestrator-Worker** for the main pipeline (Python script as deterministic orchestrator, AI models as workers for specific generation tasks)
2. **Blackboard pattern** for design state (shared JSON/file workspace where different quality dimensions are evaluated independently)
3. **Evaluator-Optimizer** for the audit loop (8-dimension audit as the evaluator, retry logic as the optimizer)
4. **Tiered models** for cost efficiency (cheap models for classification/routing, expensive models for generation)

### Critical Rules from the Research

1. **Prompt design is the #1 lever** -- not architecture, not model choice (Anthropic's own finding)
2. **Typed schemas at every boundary** -- never pass unstructured text between pipeline stages (GitHub's finding)
3. **Memory persistence is non-negotiable** -- save plans/state to files before any operation that might truncate context (Anthropic's own practice)
4. **79% of failures are specification/coordination, not technical** -- invest in clear contracts between stages
5. **Start simple, add complexity only when proven necessary** -- Anthropic's canonical advice
6. **Context loss at handoffs is the #1 killer** -- design for explicit state transfer, never implicit
7. **15x token overhead for multi-agent** -- only justified for high-value tasks

### CLAUDE.md Best Practice for Pipelines

- Keep under 150-200 instructions total
- Use `.claude/rules/` for path-scoped rules
- Include compaction survival instructions
- Never put style rules in CLAUDE.md (use linters)
- One-line project context at the top
- Reference specific files for constraints
- Prune anything Claude already does correctly by default

---

*Research conducted 2026-03-10. All claims sourced from search results; URLs provided inline.*
