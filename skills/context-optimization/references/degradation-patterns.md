# Context Degradation Patterns

Five predictable failure modes. Detect early, mitigate before cascade.

## Pattern 1: Lost-in-Middle

**What:** Information in the center of context gets 10-40% less attention (U-shaped curve).

**Detect:** Model ignores correct information that exists in context. Responses contradict provided data.

**Fix:** Place critical info at beginning and end. Add summary headers before long documents. Append key conclusions after.

## Pattern 2: Context Poisoning

**What:** A hallucination, tool error, or incorrect retrieved fact enters context and compounds through self-reference.

**Detect:** Degraded quality on previously-successful tasks. Hallucinations that persist despite correction.

**Fix:** Remove poisoned content entirely. Do NOT layer corrections on top -- the original errors retain attention weight. Truncate to before the poisoning point or restart with verified-only context.

## Pattern 3: Context Distraction

**What:** Irrelevant content dilutes attention from relevant content. Even one distractor document causes measurable degradation (step function, not linear).

**Detect:** Quality drops after adding documents. Model addresses tangential concerns.

**Fix:** Filter aggressively before loading. Move "might need" content behind tool calls. Prefer just-in-time retrieval over pre-loading.

## Pattern 4: Context Confusion

**What:** Multiple task types in one context cause the model to apply wrong-task constraints -- calling wrong tools, blending requirements from different sources.

**Detect:** Responses address the wrong aspect. Tool calls appropriate for a different task.

**Fix:** Segment tasks into separate context windows. Use explicit "context reset" markers. Isolate objectives, constraints, and tool definitions per task.

## Pattern 5: Context Clash

**What:** Multiple correct-but-contradictory sources (version conflicts, perspective differences). Model resolves contradictions unpredictably.

**Detect:** Inconsistent responses across runs. Silent selection of one source over another.

**Fix:** Establish source priority rules before conflicts arise. Mark contradictions explicitly. Filter outdated versions before they enter context.

## The Four-Bucket Mitigation

| Strategy | When | How |
|----------|------|-----|
| **Write** | Context > 70% capacity | Save to filesystem, return refs |
| **Select** | Distraction/confusion symptoms | Pull only relevant context via retrieval |
| **Compress** | All content is relevant but too large | Summarize, mask, abstract |
| **Isolate** | Confusion/clash symptoms | Split across sub-agents or sessions |
