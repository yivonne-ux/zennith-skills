---
name: context-optimization
description: >
  Use when: "optimize context", "reduce tokens", "context too long", "running out of context",
  "KV-cache", "observation masking", "compaction", "context budget", "token cost", "context degradation",
  "lost in middle", "context poisoning", "progressive disclosure", "filesystem as memory",
  "elide observations", "compress conversation", "context window full".
  Do NOT use for: general prompt engineering, few-shot examples, or model selection.
agents: [taoz, main]
version: 1.0.0
---

# Context Optimization — GAIA OS Agent Protocol

Reduce token waste. Extend effective context. Prevent degradation.
Every agent in GAIA OS follows these patterns to stay within budget and maintain output quality across long sessions.

---

## 1. KV-Cache Ordering

KV-cache stores Key/Value tensors from prior inference. When consecutive requests share an identical prefix, cached tensors are reused -- saving cost and latency. A single whitespace change in the prefix invalidates everything downstream.

### The Rule: Stable Prefix, Dynamic Suffix

Order every prompt this way (most stable first):

```
1. System prompt          (NEVER changes within a session)
2. Tool definitions       (stable across requests)
3. Skill content / few-shot examples  (stable per task)
4. Conversation history   (grows but shares prefix with prior turns)
5. Current query          (always last -- least stable)
```

### Mandatory Practices

- **Pin system prompts as immutable strings.** No timestamps, no session IDs, no version numbers, no `Current date: {today}` interpolation. Move dynamic metadata into a user message after the stable prefix.
- **Never change system prompt whitespace between deploys.** Even a newline change invalidates the entire cache block. Diff templates byte-for-byte.
- **Keep tool definitions in a fixed order.** Reordering tools between requests breaks the cache.
- **Roll out prompt changes gradually.** Cache miss cost spikes 2-5x until the new cache warms. Monitor hit rate during deployments.

### Target

70%+ cache hit rate for stable workloads = 50%+ cost reduction + 40%+ latency reduction on cached tokens.

---

## 2. Observation Masking

Tool outputs consume 80%+ of tokens in typical agent trajectories. Masking replaces verbose outputs with compact references once their purpose has been served.

### Format

```
[Obs:{ref_id} elided. Key: {one-line summary}]
```

### When to Mask

| Condition | Action |
|-----------|--------|
| Output from 3+ turns ago, key points already extracted | Mask |
| Repeated / duplicate outputs | Mask immediately |
| Boilerplate headers and footers | Mask immediately |
| Output already summarized in conversation | Mask |
| **Most recent turn's output** | **NEVER mask** |
| **Active debugging -- error outputs** | **NEVER mask** |
| **Output in active reasoning chain** | **NEVER mask** |

### Implementation

```python
def mask_observation(output: str, ref_id: str) -> str:
    if len(output) > 2000:
        key = extract_key_finding(output)
        store_to_file(f"scratch/obs_{ref_id}.txt", output)
        return f"[Obs:{ref_id} elided. Key: {key}]"
    return output
```

### Target

60-80% reduction in masked observations. Less than 2% quality impact. Full content remains retrievable via ref_id.

---

## 3. Progressive Disclosure

Never stuff all skills, docs, or instructions into the system prompt. Load on demand in three levels.

### The Three Levels

| Level | What Loads | When | Token Cost |
|-------|-----------|------|------------|
| **L1 -- Metadata** | Skill name + one-line description | Session start (always present) | ~5 tokens per skill |
| **L2 -- Summary** | Purpose, trigger conditions, key rules | Agent recognizes relevance | ~100-200 tokens |
| **L3 -- Full** | Complete SKILL.md content | Task explicitly matches trigger | Full file |

### GAIA OS Implementation

L1 is what goes in SOUL.md skill listings:
```
Available skills (load with read_file when relevant):
- context-optimization: Token reduction + context window management
- rigour: Quality gate before shipping code
- brand-studio: Generate + audit + refine brand assets
```

L2 loads the YAML frontmatter + first section only.
L3 loads the entire SKILL.md via `read_file`.

### Rules

- If a skill activates, load L3 fully. Partial loads create confusing gaps.
- Set strict activation thresholds. Loading "potentially relevant" skills recreates context stuffing.
- For documents: load summaries first, fetch detail sections only when reasoning needs them.
- For tool results: keep the 5 most recent in full; compress or evict older ones.

---

## 4. Compaction

When context utilization crosses 70-80%, compress old content to reclaim space. This is lossy -- apply it after masking has already removed low-value bulk.

### Compression Priority (highest first)

1. **Tool outputs** -- consume 80%+ of tokens; compress first
2. **Old conversation turns** -- retain decisions, drop filler and exploratory back-and-forth
3. **Retrieved documents** -- keep claims and data points, drop supporting evidence
4. **NEVER compress**: system prompt, tool definitions, active error traces

### Structured Summary Template

After compaction, the summary MUST include these sections:

```markdown
## Session Intent
[What the user is trying to accomplish]

## Files Modified
- path/to/file.ts: What changed (include function names)

## Decisions Made
- Decision 1: rationale
- Decision 2: rationale

## Current State
- What works, what doesn't, blockers

## Next Steps
1. Immediate next action
2. Following action
```

### Trigger Strategy

| Strategy | When to Use |
|----------|-------------|
| Fixed threshold (70-80%) | Default -- simple and reliable |
| Sliding window (last N turns + summary) | Coding agents -- predictable context size |
| Task-boundary (compress at logical completions) | Sessions with clear phases |

### Critical Gotchas

- **Trigger at 70-80%, not 90%+.** Under-pressure compaction (85%+) loses critical state because the model performing summarization is itself degraded.
- **Never regenerate summaries from scratch.** Summarize only newly truncated content and merge into existing summary. Full regeneration drifts -- each pass loses details.
- **Protect early turns.** First few turns contain task setup and constraints that cannot be re-derived. Extract into a persistent preamble.
- **Artifact trail is the weakest link.** File paths, function names, error codes get paraphrased or dropped. Preserve identifiers verbatim in dedicated sections, never embedded in prose.

### Optimization Target

Optimize for **tokens-per-task** (total tokens from start to completion), NOT tokens-per-request. Aggressive compression that forces re-fetching wastes more than it saves.

---

## 5. Context Degradation Patterns

Five predictable failure modes. Detect early, mitigate before cascade.

### Pattern 1: Lost-in-Middle

**What:** Information in the center of context gets 10-40% less attention (U-shaped curve).

**Detect:** Model ignores correct information that exists in context. Responses contradict provided data.

**Fix:** Place critical info at beginning and end. Add summary headers before long documents. Append key conclusions after.

### Pattern 2: Context Poisoning

**What:** A hallucination, tool error, or incorrect retrieved fact enters context and compounds through self-reference.

**Detect:** Degraded quality on previously-successful tasks. Hallucinations that persist despite correction.

**Fix:** Remove poisoned content entirely. Do NOT layer corrections on top -- the original errors retain attention weight. Truncate to before the poisoning point or restart with verified-only context.

### Pattern 3: Context Distraction

**What:** Irrelevant content dilutes attention from relevant content. Even one distractor document causes measurable degradation (step function, not linear).

**Detect:** Quality drops after adding documents. Model addresses tangential concerns.

**Fix:** Filter aggressively before loading. Move "might need" content behind tool calls. Prefer just-in-time retrieval over pre-loading.

### Pattern 4: Context Confusion

**What:** Multiple task types in one context cause the model to apply wrong-task constraints -- calling wrong tools, blending requirements from different sources.

**Detect:** Responses address the wrong aspect. Tool calls appropriate for a different task.

**Fix:** Segment tasks into separate context windows. Use explicit "context reset" markers. Isolate objectives, constraints, and tool definitions per task.

### Pattern 5: Context Clash

**What:** Multiple correct-but-contradictory sources (version conflicts, perspective differences). Model resolves contradictions unpredictably.

**Detect:** Inconsistent responses across runs. Silent selection of one source over another.

**Fix:** Establish source priority rules before conflicts arise. Mark contradictions explicitly. Filter outdated versions before they enter context.

### The Four-Bucket Mitigation

| Strategy | When | How |
|----------|------|-----|
| **Write** | Context > 70% capacity | Save to filesystem, return refs |
| **Select** | Distraction/confusion symptoms | Pull only relevant context via retrieval |
| **Compress** | All content is relevant but too large | Summarize, mask, abstract |
| **Isolate** | Confusion/clash symptoms | Split across sub-agents or sessions |

---

## 6. Filesystem-as-Memory

The filesystem is unlimited context. Write large outputs to files; return compact references.

### Pattern A: Tool Output Offloading

```python
def handle_tool_output(output: str, tool_name: str) -> str:
    if len(output) < 2000:
        return output
    path = f"scratch/{tool_name}_{timestamp}.txt"
    write_file(path, output)
    summary = extract_summary(output, max_tokens=200)
    return f"[Output saved to {path}. Summary: {summary}]"
```

~100 tokens in context. Full output accessible via `grep` or `read_file` with line ranges.

### Pattern B: Plan Persistence

Write plans to files. Re-read at the start of each turn after context refresh.

```yaml
# scratch/current_plan.yaml
objective: "Refactor authentication module"
status: in_progress
steps:
  - id: 1
    description: "Audit current auth endpoints"
    status: completed
  - id: 2
    description: "Design new token validation flow"
    status: in_progress
```

### Pattern C: Sub-Agent Communication

Route findings through filesystem, not message chains. Each agent writes to its own workspace directory. Coordinator reads directly -- no "game of telephone" degradation.

```
workspace/
  agents/
    research_agent/findings.md
    code_agent/changes.md
  coordinator/synthesis.md
```

### Pattern D: Scratch Cleanup

Scratch directories grow unbounded. Implement retention:
- Age-based: delete files older than session duration
- Count-based: keep last N files per tool
- Run cleanup at session boundaries

### GAIA OS Canonical Paths

| What | Where |
|------|-------|
| Scratch files | `~/.openclaw/workspace-{id}/scratch/` |
| Plans | `~/.openclaw/workspace-{id}/scratch/plans/` |
| Agent workspaces | `~/.openclaw/workspace-{id}/` |
| Room logs | `~/.openclaw/workspace/rooms/` |
| Build logs | `~/.openclaw/workspace/rooms/logs/` |

---

## Quick Reference Card

```
BEFORE EVERY REQUEST:
  1. Is system prompt byte-identical to last request?  (KV-cache)
  2. Any tool outputs from 3+ turns ago still in full? (Mask them)
  3. Context utilization > 70%?                        (Compact)
  4. Loading a skill/doc? Is it truly needed NOW?      (Progressive disclosure)
  5. Tool returning > 2000 tokens?                     (Write to file)

WHEN QUALITY DROPS:
  → Check for lost-in-middle (move critical info to edges)
  → Check for poisoning (remove bad data, don't correct on top)
  → Check for distraction (remove irrelevant docs)
  → Check for confusion (isolate task contexts)
  → Check for clash (establish source priority)
```

---

## Companion Script

```bash
bash ~/.openclaw/skills/context-optimization/scripts/context-audit.sh {agent-id}
```

Runs a quick token audit on any agent's context. Reports breakdown, warnings at 70% threshold, and top consumers.

---

## Skill Metadata

**Created**: 2026-03-27
**Author**: Taoz (Builder)
**Version**: 1.0.0
