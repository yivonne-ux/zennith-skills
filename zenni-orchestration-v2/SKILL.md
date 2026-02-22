# ZENNI ORCHESTRATION v2 — Delegation Law & Token Economy

**Status:** MANDATORY — Core operational protocol for Zenni (main orchestrator agent)  
**Created:** 2026-02-22  
**Enforcement:** STRICT — No exceptions without human approval

---

## Core Principle: The 2-Tool-Call Rule

**LAW:** If a task requires more than **2 tool calls** to complete, it MUST be spawned as a subagent.

**Why:** Zenni's main session is precious context. Every inline task accumulates tokens. A 10-step workflow done inline = 10k+ tokens burned. Done as subagent = 0 tokens in main session.

**Exceptions (ONLY these):**
- Quick file reads (1-2 files, <100 lines total)
- Single-command deployments (`git push`, `npm run deploy`)
- Simple status checks (`git status`, `ps aux | grep`)
- Emergency debugging when subagent crashed

**Everything else → spawn.**

---

## THE DELEGATION DECISION TREE

**Use this BEFORE touching any tool. No shortcuts.**

```
┌─ Is this task > 2 tool calls?
│  └─ YES → sessions_spawn (isolated context)
│
├─ Is this creative/art work?
│  └─ YES → sessions_spawn Apollo/Daedalus (model: creative-premium or kimi-k2.5)
│
├─ Is this code/script writing?
│  └─ YES → sessions_spawn Taoz (model: claude-opus or coder)
│
├─ Is this analysis of >3 images?
│  └─ YES → sessions_spawn vision agent (model: creative-premium)
│
├─ Is this research/scraping?
│  └─ YES → sessions_spawn Artemis (model: glm-4.7-flash)
│
├─ Is this a file >50 lines to write?
│  └─ YES → sessions_spawn Taoz (model: claude-opus)
│
├─ Will this add >3k tokens to my context?
│  └─ YES → sessions_spawn (any appropriate agent)
│
├─ Can I do it in 1 tool call?
│  └─ YES → do it inline (fast path)
│
└─ Everything else → sessions_spawn (default to isolation)
```

---

## TASK CLASSIFICATION MATRIX

**Use this to pick the right agent + model for delegation:**

| Task Type | Agent | Model | Method | Example |
|-----------|-------|-------|--------|---------|
| **Code/Scripts** | Taoz | `claude-opus-4.6` | `sessions_spawn` | Build nightly.sh, write Notion script |
| **Image Generation (batch)** | Apollo/Daedalus | `kimi-k2.5` or `creative-premium` | `sessions_spawn` | Generate 10 agent sprites |
| **Image Analysis (>3 images)** | Vision Agent | `creative-premium` | `sessions_spawn` | Analyze 18 brand reference images |
| **Research/Scraping** | Artemis | `glm-4.7-flash` | `sessions_spawn` | Competitor analysis, market intel |
| **Deep Analysis** | Athena | `glm-5` | `sessions_spawn` | Boss dashboard audit, strategy report |
| **Brand/Creative Work** | Apollo | `creative-premium` | `sessions_spawn` | Brand brief, UGC scripts, campaign copy |
| **Campaign Strategy** | Calliope | `creative-premium` | `sessions_spawn` | Campaign briefs, content calendars |
| **Visual QA** | Daedalus | `kimi-k2.5` | `sessions_spawn` | Art direction, visual system audit |
| **Social Content** | Iris | `creative-premium` | `sessions_spawn` | Social posts, community replies |
| **Quick Status Check** | Zenni (inline) | `claude-sonnet-4.6` | Direct (1 tool call) | `git status`, read 1 file |
| **Deploy (1 command)** | Zenni (inline) | `claude-sonnet-4.6` | Direct (1 tool call) | `git push`, `wrangler publish` |

---

## SUBAGENT DISPATCH TEMPLATES

### Template 1: Code/Script Writing (Taoz)
```javascript
sessions_spawn({
  label: "taoz-[task-name]",
  model: "claude-opus-4.6",
  instructions: `You are Taoz, GAIA's master builder.

TASK: [specific deliverable]

REQUIREMENTS:
- Write to: [exact file path]
- Must pass: bash ~/.openclaw/skills/rigour/scripts/gate.sh [output]
- Git commit when done

OUTPUT EXPECTED:
- [file.ext] written + committed
- Rigour gate report (PASS on all 5 gates)
- Final message: "Taoz complete: [what was built]"`,
  modelOptions: { temperature: 0.3 }
});
```

### Template 2: Image Generation Batch (Apollo/Daedalus)
```javascript
sessions_spawn({
  label: "apollo-image-gen-[batch-name]",
  model: "kimi-k2.5",
  instructions: `You are Apollo, GAIA's creative lead.

TASK: Generate [N] images for [purpose]

STYLE REQUIREMENTS:
- [art style guidelines]
- Color palette: [hex codes]
- Reference: [image paths if available]

OUTPUT:
- [N] images saved to [directory]
- Filenames: [naming convention]
- Dimensions: [WxH]
- Format: [PNG/JPG/SVG]

When done, report: "Apollo complete: [N] images generated at [path]"`
});
```

### Template 3: Image Analysis Batch (Vision Agent)
```javascript
sessions_spawn({
  label: "vision-analysis-[batch-name]",
  model: "creative-premium",
  instructions: `Analyze these [N] images for [purpose].

IMAGES: [list of file paths or URLs]

ANALYSIS GOALS:
- [what to extract/identify]
- [what patterns to find]
- [what to summarize]

OUTPUT:
- Write analysis to: [output-file.md]
- Include: [specific sections]
- Format: [markdown/JSON/etc]

Final message: "Vision analysis complete: [summary]"`
});
```

### Template 4: Research/Scraping (Artemis)
```javascript
sessions_spawn({
  label: "artemis-research-[topic]",
  model: "glm-4.7-flash",
  instructions: `You are Artemis, GAIA's research huntress.

RESEARCH GOAL: [specific intel to gather]

TARGETS:
- [websites/competitors/topics to research]

OUTPUT FORMAT:
- Write to: [output-file.md]
- Include: [sections: summary, key findings, recommendations, sources]
- Cite all sources with URLs

Final message: "Artemis complete: [brief summary]"`
});
```

### Template 5: Deep Analysis (Athena)
```javascript
sessions_spawn({
  label: "athena-analysis-[topic]",
  model: "glm-5",
  instructions: `You are Athena, GAIA's strategic intelligence.

ANALYSIS TASK: [specific question to answer]

DATA SOURCES:
- [files to read]
- [context to consider]

DELIVERABLE:
- Write to: [output-file.md]
- Include: [sections: executive summary, deep dive, recommendations, risks]
- Be quantitative where possible (cite numbers, percentages, metrics)

Final message: "Athena complete: [key insight in 1 sentence]"`
});
```

### Template 6: Brand/Creative Work (Apollo/Calliope)
```javascript
sessions_spawn({
  label: "apollo-creative-[project]",
  model: "creative-premium",
  instructions: `You are Apollo/Calliope, GAIA's creative team.

PROJECT: [campaign/copy/brief to create]

BRAND CONTEXT:
- Brand: [name]
- Voice: [tone/personality]
- Audience: [target demographic]
- Goal: [conversion/awareness/engagement]

DELIVERABLE:
- Write to: [output-file.md]
- Include: [specific sections]
- Follow brand voice from: [reference file if available]

Final message: "Creative complete: [what was delivered]"`
});
```

---

## SESSION HEALTH RULES (MANDATORY)

Zenni must monitor her own token usage and **proactively delegate** when context fills up:

### Health Checkpoints
- **After any major delegation session** → trigger memory save (write to `memory/YYYY-MM-DD.md`)
- **If session >60%** → start declining new inline work, route ALL tasks to subagents
- **If session >75%** → STOP all inline work, dispatch only, prepare reset
- **If session >80%** → immediate reset after current message

### How to Check Session Health
```bash
# Run this periodically (every 10-15 messages):
openclaw session_status
```

Look for:
- `context_usage` → if >120k/200k (60%), start delegating aggressively
- `token_count` → if growing >5k per message, you're doing too much inline

### Memory Save Protocol
When context is high (>60%), before reset:
```markdown
# Add to memory/YYYY-MM-DD.md

## [HH:MM] — Session Reset
**Reason:** [token overflow / planned / crash recovery]
**Context usage:** [X/200k]

**Completed today:**
- [task 1]
- [task 2]

**Pending:**
- [task 3 - status]

**Lessons:**
- [what went wrong, if applicable]
- [what to do differently next time]
```

---

## SELF-AUDIT CHECKLIST

**Run this BEFORE any response that involves >2 tool calls:**

- [ ] **Could this be a subagent?** (If yes → spawn, don't do inline)
- [ ] **Will this add >3k tokens to my context?** (If yes → spawn)
- [ ] **Am I doing Taoz's job?** (Code/scripts → spawn Taoz)
- [ ] **Am I doing Apollo's job?** (Creative/art → spawn Apollo)
- [ ] **Am I doing Artemis's job?** (Research/scraping → spawn Artemis)
- [ ] **Am I doing Athena's job?** (Deep analysis → spawn Athena)
- [ ] **Is this a file >50 lines?** (If yes → spawn Taoz)
- [ ] **Is this >3 images to analyze?** (If yes → spawn vision agent)
- [ ] **Can I finish this in 1-2 tool calls?** (Only if YES → do inline)

**If ANY of the first 7 questions = YES → spawn a subagent.**

---

## COMMON MISTAKES TO AVOID

**From 2026-02-22 audit (164k tokens burned):**

❌ **NEVER do these inline (main session):**
- Run Python scripts for generation tasks (10 agent sprites → should be Apollo subagent)
- Write multi-file scripts (nightly.sh → should be Taoz subagent)
- Build Notion/API integration scripts (→ Taoz subagent)
- Analyze 10+ images in a loop (→ vision subagent)
- Heavy file editing sessions (>5 files, >200 lines total → Taoz subagent)
- Research loops (competitor analysis → Artemis subagent)

✅ **OK to do inline:**
- Read 1-2 files for context (<100 lines total)
- Single command deploy (`git push`, `npm run build`)
- Quick status check (`git status`, `ls -la`)
- Write/edit tiny files (<20 lines, <2 files)
- Update a single JSON key
- Fix a typo in existing file

---

## DELEGATION WORKFLOW (3-TURN RULE)

Zenni handles each task in **max 3 turns:**

### Turn 1: PLAN
- Read request
- Break into steps
- Identify which agent owns each step
- Check: Can I do this in 1-2 tool calls? If no → prepare to spawn

### Turn 2: DISPATCH
- Spawn subagent(s) with clear instructions
- OR write dispatch to room (if using room-based workflow)
- Set label, model, deliverable path
- Include success criteria ("done" = file written + committed + report sent)

### Turn 3: QA + REPORT
- Subagent auto-announces completion (push-based, don't poll)
- Zenni reads output, verifies quality
- Summarize to human: "Task complete. [deliverable] ready at [path]."

**If a task needs >3 turns in Zenni's session → it's the wrong workflow. Spawn a subagent.**

---

## WORKFLOW EXAMPLES

### Example 1: Good (Efficient Delegation)
**Request:** "Build a script to create Notion databases for all our brands."

**Zenni's turns:**
1. **Plan:** This is code writing (>50 lines), multi-step (read brands, generate script, test). → Taoz subagent.
2. **Dispatch:** `sessions_spawn({ label: "taoz-notion-db-script", model: "claude-opus-4.6", instructions: "..." })`
3. **QA:** Taoz reports completion → Zenni reads script, verifies Rigour pass → reports to human.

**Tokens used in Zenni's session:** ~2k (plan + dispatch + QA)

---

### Example 2: Bad (What NOT to Do)
**Request:** "Build a script to create Notion databases for all our brands."

**Zenni's turns (WRONG):**
1. Read brands/registry.json (500 tokens)
2. Write notion-create.js inline (3k tokens)
3. Test script, debug errors (2k tokens)
4. Update script with fixes (1k tokens)
5. Write documentation (1k tokens)
6. Git commit (500 tokens)

**Tokens used in Zenni's session:** ~8k

**Mistake:** Zenni did Taoz's job. Should have spawned Taoz after Turn 1.

---

### Example 3: Good (Inline, Fast Path)
**Request:** "Check if nightly-review cron is still active."

**Zenni's turn:**
1. **Check:** `exec crontab -l | grep nightly-review` → reports result.

**Tokens used:** ~200

**Why OK:** 1 tool call, <500 tokens, status check (not building). This is Zenni's job.

---

### Example 4: Bad (Inline When Should Delegate)
**Request:** "Analyze these 18 brand reference images and create a brand brief."

**Zenni's turns (WRONG):**
1. Analyze image 1-6 inline (6k tokens)
2. Analyze image 7-12 inline (6k tokens)
3. Analyze image 13-18 inline (6k tokens)
4. Write brand brief inline (4k tokens)

**Tokens used:** ~22k

**What should have happened:**
1. **Plan:** 18 images = vision batch. Brand brief = Apollo creative work.
2. **Dispatch:** Spawn vision agent for analysis → output to analysis.md. Then spawn Apollo to write brand brief from analysis.md.
3. **QA:** Read final brand brief, report to human.

**Tokens saved:** ~20k (only ~2k used for orchestration)

---

## INTEGRATION WITH EXISTING PROTOCOLS

This skill supplements (does not replace):
- **PROTOCOL.md** — Still governs agent collaboration, handoffs, escalation
- **AGENTS.md** — Still defines boot sequence, memory system, safety rules
- **GAIA-OS-AGENT-MATRIX.md** — Still locks model assignments per agent

**Hierarchy:**
1. **AGENTS.md** — Core identity, boot, memory (foundational)
2. **PROTOCOL.md** — Agent collaboration, handoff rules (governance)
3. **zenni-orchestration-v2** — Delegation decision-making, token economy (operational)

**Conflicts:** If this skill conflicts with PROTOCOL.md or AGENTS.md, escalate to human. Don't resolve autonomously.

---

## SUCCESS METRICS

**Track these weekly:**
- Avg tokens/day in Zenni main session (target: <50k/day)
- % of tasks delegated vs done inline (target: >80% delegated)
- Subagent spawn count per day (target: 5-15)
- Session resets due to overflow (target: <1/week)

**Log to:** `memory/metrics/delegation-health.json`

```json
{
  "week": "2026-02-17",
  "zenni_tokens_per_day_avg": 48000,
  "tasks_delegated_pct": 85,
  "subagent_spawns_per_day_avg": 12,
  "session_overflows": 0
}
```

---

## EMERGENCY OVERRIDE

**Only use when:**
- Subagent system is down (gateway crash, spawn failures)
- Human explicitly says "do it yourself, don't delegate"
- Time-critical issue where spawn overhead is too high (<5 min to fix, spawn takes 30s)

**Document override in memory:**
```markdown
## [HH:MM] — ORCHESTRATION OVERRIDE
**Reason:** [why delegation was skipped]
**Task:** [what was done inline]
**Tokens used:** [estimate]
**Justification:** [why this was the right call]
```

**Default:** If unsure, delegate. Bias toward spawning.

---

## REVISION HISTORY

- **v2.0** (2026-02-22) — Initial skill creation post-164k token burn audit
- Future updates: Track changes here

---

**END OF SKILL**
