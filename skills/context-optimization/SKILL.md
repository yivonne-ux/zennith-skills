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

KV-cache stores Key/Value tensors from prior inference. When consecutive requests share an identical prefix, cached tensors are reused -- saving cost and latency. A single whitespace change invalidates everything downstream.

### The Rule: Stable Prefix, Dynamic Suffix

```
1. System prompt          (NEVER changes within a session)
2. Tool definitions       (stable across requests)
3. Skill content / few-shot examples  (stable per task)
4. Conversation history   (grows but shares prefix with prior turns)
5. Current query          (always last -- least stable)
```

### Mandatory Practices
- **Pin system prompts as immutable strings.** No timestamps, session IDs, or `Current date: {today}` interpolation. Move dynamic metadata into a user message.
- **Never change system prompt whitespace between deploys.** Diff templates byte-for-byte.
- **Keep tool definitions in a fixed order.** Reordering breaks the cache.
- **Roll out prompt changes gradually.** Cache miss cost spikes 2-5x until warm.

**Target:** 70%+ cache hit rate = 50%+ cost reduction + 40%+ latency reduction.

---

## 2. Observation Masking

Tool outputs consume 80%+ of tokens. Masking replaces verbose outputs with compact references.

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
| **Most recent turn's output** | **NEVER mask** |
| **Active debugging -- error outputs** | **NEVER mask** |
| **Output in active reasoning chain** | **NEVER mask** |

**Target:** 60-80% reduction in masked observations. <2% quality impact.

---

## 3. Progressive Disclosure

Never stuff all skills, docs, or instructions into the system prompt. Load on demand in three levels.

| Level | What Loads | When | Token Cost |
|-------|-----------|------|------------|
| **L1 -- Metadata** | Skill name + one-line description | Session start | ~5 tokens/skill |
| **L2 -- Summary** | Purpose, trigger conditions, key rules | Agent recognizes relevance | ~100-200 tokens |
| **L3 -- Full** | Complete SKILL.md content | Task explicitly matches trigger | Full file |

### Rules
- If a skill activates, load L3 fully. Partial loads create confusing gaps.
- Set strict activation thresholds. Loading "potentially relevant" skills recreates context stuffing.
- For tool results: keep 5 most recent in full; compress or evict older ones.

---

## 4. Compaction

When context utilization crosses 70-80%, compress old content. Apply after masking has removed low-value bulk.

### Compression Priority (highest first)
1. **Tool outputs** -- consume 80%+ of tokens; compress first
2. **Old conversation turns** -- retain decisions, drop filler
3. **Retrieved documents** -- keep claims and data points, drop supporting evidence
4. **NEVER compress**: system prompt, tool definitions, active error traces

### Structured Summary Template

```markdown
## Session Intent
[What the user is trying to accomplish]

## Files Modified
- path/to/file.ts: What changed (include function names)

## Decisions Made
- Decision 1: rationale

## Current State
- What works, what doesn't, blockers

## Next Steps
1. Immediate next action
```

### Critical Gotchas
- **Trigger at 70-80%, not 90%+.** Under-pressure compaction loses critical state.
- **Never regenerate summaries from scratch.** Summarize only newly truncated content and merge.
- **Protect early turns.** First few turns contain task setup that cannot be re-derived.
- **Preserve identifiers verbatim** (file paths, function names, error codes) in dedicated sections.

**Optimize for tokens-per-task (total), NOT tokens-per-request.**

---

## 5. Context Degradation Patterns

Five predictable failure modes: Lost-in-Middle, Context Poisoning, Context Distraction, Context Confusion, Context Clash.

> Load `references/degradation-patterns.md` for full descriptions, detection methods, fixes, and the Four-Bucket Mitigation strategy.

---

## 6. Filesystem-as-Memory

The filesystem is unlimited context. Write large outputs to files; return compact references.

> Load `references/filesystem-as-memory.md` for implementation patterns (tool output offloading, plan persistence, sub-agent communication, scratch cleanup) and GAIA OS canonical paths.

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
  -> Check for lost-in-middle (move critical info to edges)
  -> Check for poisoning (remove bad data, don't correct on top)
  -> Check for distraction (remove irrelevant docs)
  -> Check for confusion (isolate task contexts)
  -> Check for clash (establish source priority)
```

## Companion Script

```bash
bash ~/.openclaw/skills/context-optimization/scripts/context-audit.sh {agent-id}
```

**Created**: 2026-03-27 | **Author**: Taoz (Builder) | **Version**: 1.0.0
