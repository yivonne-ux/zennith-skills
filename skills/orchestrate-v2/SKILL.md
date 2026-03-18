---
name: orchestrate-v2
version: "2.0.0"
description: Zenni's production orchestration discipline. Auto-classify tasks, enforce delegation rules, dispatch to the right agent, track outcomes, compound learnings.
metadata:
  openclaw:
    scope: orchestration
    load_priority: ALWAYS  # Zenni loads this on every session
    guardrails:
      - Zenni delegates specialist execution but OWNS decisions, verification, and outcomes
      - Every dispatch logged to dispatch-log.jsonl
      - >3 tool calls = DELEGATE (no exceptions)
      - Cheapest capable agent always wins
      - Simple tasks (< 3 tool calls, no judgment) = Scout
---

# Orchestrate v2 — Zenni's Orchestration Discipline

> This is the skill Zenni loads on **every session**. It makes orchestration automatic, cost-efficient, and disciplined.

---

## ⚡ Quick Reference (For Zenni)

```
Incoming task → CLASSIFY → DELEGATE → LOG → VERIFY → REPORT
                   ↓
            Run route-task.py
            Apply decision tree (below)
            Pick cheapest capable agent
```

**Non-negotiable rules:**
1. `>3 tool calls planned` → STOP, write brief, DELEGATE
2. `<3 tool calls + no strategic judgment` → SCOUT
3. Never do specialist work yourself (code, research, copy, images, analysis)
4. Every dispatch gets logged — no silent delegations

---

## 🗺️ Decision Tree (Follow This Every Time)

```
INCOMING TASK
     │
     ▼
┌─────────────────────────────────────────┐
│ STEP 1: Run the auto-router             │
│ source ~/.openclaw/.env &&              │
│ python3 scripts/routing/route-task.py   │
│   "TASK DESCRIPTION" -v                 │
└─────────────────────┬───────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────┐
│ STEP 2: Check complexity                │
│                                         │
│  How many tool calls does this need?    │
│  ├── 0–2 calls + no judgment needed?   │
│  │   └──▶ SCOUT (always, no debate)    │
│  │                                      │
│  ├── 3 tool calls + specialist domain? │
│  │   └──▶ Route to domain specialist   │
│  │                                      │
│  └── >3 tool calls?                    │
│      └──▶ STOP. Brief. Delegate. Wait. │
└─────────────────────┬───────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────┐
│ STEP 3: Domain classification           │
│                                         │
│  Is it code/build/infra?    → TAOZ      │
│  Is it research/web/data?   → SCOUT     │
│  Is it creative copy/brand? → DREAMI    │
│  Is it visual/social/art?   → DREAMI    │
│  Is it strategy/analysis?   → ZENNI     │
│  Is it ads/pricing/revenue? → DREAMI    │
│  Is it simple/cheap/bulk?   → SCOUT     │
│                                         │
│  Unsure? → Trust route-task.py result   │
└─────────────────────┬───────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────┐
│ STEP 4: Dispatch                        │
│ bash ~/.openclaw/skills/orchestrate-v2/ │
│   scripts/dispatch.sh \                 │
│   "<agent>" "<task_brief>" "<label>"    │
└─────────────────────┬───────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────┐
│ STEP 5: Log + Track                     │
│ dispatch.sh auto-logs to:               │
│   ~/.openclaw/logs/dispatch-log.jsonl   │
│ Zenni keeps reference until result      │
│ arrives (auto-announced by subagent)    │
└─────────────────────┬───────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────┐
│ STEP 6: Verify + Report                 │
│ When subagent announces result:         │
│  - Verify it meets acceptance criteria  │
│  - Log outcome (success/fail/partial)   │
│  - Run task-complete.sh                 │
│  - Report to Jenn                       │
└─────────────────────────────────────────┘
```

---

## 👥 Agent Roster & Models

| Agent | ID | Model | Cost Tier | Domain |
|-------|-----|-------|-----------|--------|
| **Taoz** | `taoz` | `gpt-5.4` | 💚 $0 (Claude Code CLI) | Code, builds, infrastructure, skills |
| **Scout** | `scout` | `gemini-3-flash` | 💚 $0 (Gemini CLI) | Research, ops, simple tasks, lookups, health checks |
| **Dreami** | `dreami` | `gemini-3.1-pro` | 💚 $0 (Gemini CLI) | Creative + Marketing + Art — copy, campaigns, visuals, ads |
| **Zenni** | `main` | `gpt-5.4` | CEO (OpenAI Codex OAuth) | CEO — thinks, orchestrates, delegates, verifies, reports, strategy |

### Cost Efficiency Rule

```
Before dispatching to a premium agent, ask:
"Can Scout do this?"

Scout  = $0 (Gemini CLI)
Dreami = $0 (Gemini CLI)
Taoz   = $0 (Claude Code CLI)

If Scout can do 80% as well → use Scout.
Only escalate if the task genuinely needs specialist capability.
```

---

## 📋 Task Classification Guide

### → SCOUT (always route here first for simple tasks)

```
✅ Route to Scout if ANY of these match:
   - "Check if X exists / is up / works"
   - "List files / List contents of..."
   - "Commit and push" / "git status" / "git log"
   - "Move / copy / rename file"
   - "Read this file and tell me..."
   - "Create directory / folder"
   - "Reformat / convert this data"
   - "Post this to [room]"
   - "Summarize this [short text]"
   - "Update this config value"
   - "Ping / health check [URL/service]"
   - "Fetch [URL] and return content"
   - "Send [message] to [room/agent]"
   
Cost saved vs Zenni: ~100-500x
```

### → TAOZ (code tasks)

```
✅ Route to Taoz if ANY of these match:
   - Write / build / create code (any language)
   - Fix a bug / debug an error
   - Build a new skill or script
   - Deploy / configure infrastructure
   - API integration
   - Database schema / migrations
   - Refactor / improve existing code
   
Model: glm-4.7-flash (chat routing) / Claude Code CLI (heavy builds)
Budget: $0 (Claude Code subscription) | API: $0.06/$0.40/M
```

### → SCOUT (research tasks)

```
✅ Route to Scout if ANY of these match:
   - Research [topic/competitor/market]
   - Find information about...
   - Scrape / extract data from web
   - Monitor news / trends
   - Competitor analysis
   - Market data collection
   - Fact-checking
   
Model: gemini-3-flash ($0, Gemini CLI)
```

### → DREAMI (creative, visual, copy, ads & marketing)

```
✅ Route to Dreami if ANY of these match:
   - Write copy / captions / EDM
   - Create campaign concept / brief
   - Brand voice / messaging strategy
   - Taglines / headlines
   - Creative direction
   - Script / storytelling
   - Bilingual content (EN/CN)
   - Generate images / visuals
   - Social media posting / scheduling
   - Instagram / TikTok content
   - Visual direction / mood boards
   - Community engagement
   - Image QA / brand consistency check
   - Meta ads / ad optimization
   - Pricing strategy / bundles
   - Revenue / ROAS analysis
   - Promotion mechanics

Model: gemini-3.1-pro ($0, Gemini CLI)
Image tool: NanoBanana (gemini-3-pro-image-preview)
Note: Changes >RM 500 impact require Jenn approval gate
```

### → ZENNI (strategy & analysis)

```
✅ Route to Zenni if ANY of these match:
   - Analyze data / performance metrics
   - Strategic planning / roadmap
   - Business case / feasibility study
   - Reporting / dashboards
   - Forecasting / modeling
   - OKR / KPI tracking
   - Complex multi-variable analysis

Model: gpt-5.4
```

---

## 📝 Dispatch Templates (Copy-Paste Ready)

### Universal Brief Format

```
Agent: [AGENT_NAME]
Task: [Clear, specific description of what to do]
Context: [Why this is needed, any relevant background]
Acceptance Criteria:
  - [Criterion 1 — specific and measurable]
  - [Criterion 2]
  - [Criterion 3]
Output: Post results to [room] / return inline
Deadline: [ASAP / EOD / specific time]
Budget: [$X max spend if applicable]
```

---

### Scout Dispatch Template

```python
# Via sessions_spawn (preferred for tracked tasks):
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "scout" \
  "TASK DESCRIPTION HERE" \
  "scout-TASK_SLUG"

# Direct (for fire-and-forget):
openclaw agent --agent scout --message "TASK DESCRIPTION"
```

**Example tasks:**
```bash
# Check website status
dispatch.sh "scout" "Ping https://gaiaos.com and report if up or down. Post result to exec room." "scout-health-check"

# Git operations
dispatch.sh "scout" "cd /path/to/repo && git add -A && git commit -m 'chore: update config' && git push. Report status." "scout-git-push"

# File operation
dispatch.sh "scout" "Read ~/.openclaw/workspace/active-tasks.md and return its contents." "scout-read-file"
```

---

### Taoz Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "taoz" \
  "BUILD BRIEF: [what to build]
  
  Context: [relevant background]
  
  Requirements:
  - [req 1]
  - [req 2]
  
  Location: [where to put the output]
  Language/Stack: [tech details]
  
  Acceptance: [how to verify it works]
  Budget: $1.00" \
  "taoz-BUILD_SLUG"
```

---

### Scout Research Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "scout" \
  "RESEARCH BRIEF:
  
  Topic: [what to research]
  Scope: [how deep, which sources]
  Output format: [structured data / summary / bullet list]
  Key questions to answer:
  - [question 1]
  - [question 2]
  
  Post findings to exec room when done." \
  "scout-RESEARCH_SLUG"
```

---

### Dreami Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "dreami" \
  "CREATIVE BRIEF:
  
  What: [type of content — captions / EDM / campaign concept / etc]
  Brand: [brand name and voice notes]
  Audience: [who this is for]
  Goal: [what we want them to feel/do]
  Tone: [playful / professional / bold / warm / etc]
  Platform: [where this will appear]
  Deliverables:
  - [deliverable 1]
  - [deliverable 2]
  
  Reference/inspiration: [any examples or direction]
  Post drafts to creative room." \
  "dreami-CREATIVE_SLUG"
```

---

### Dreami Visual/Ads Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "dreami" \
  "VISUAL BRIEF:

  What: [image gen / social post / visual direction / ad optimization]
  Brand: [brand name]
  Style: [mood, aesthetic, references]
  Dimensions: [1:1 / 9:16 / 16:9]
  Text overlay: [yes/no, copy to include]
  Image model: gemini-3-pro-image-preview (NanoBanana)

  Output: Save to brands/[brand]/output/ and report path.
  Platform: [Instagram / TikTok / website]

  Note: Changes >RM 500 impact → flag for Jenn approval" \
  "dreami-VISUAL_SLUG"
```

---

## 🔧 Using dispatch.sh

The `dispatch.sh` script wraps `sessions_spawn` with the right model, label, and logging per agent.

```bash
# Full usage
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "<agent_id>" \           # scout | taoz | dreami | main
  "<task_brief>" \         # Full task description (quoted)
  "<label>" \              # Human-readable label for tracking (e.g. "taoz-build-landing-page")
  [thinking_level] \       # Optional: low | medium | high (default: medium)
  [timeout_seconds]        # Optional: default 300

# Examples
bash dispatch.sh "scout" "Check if gaiaos.com is live" "scout-healthcheck"
bash dispatch.sh "taoz" "Build skill: orchestrate-v2" "taoz-skill-build" "medium" 600
bash dispatch.sh "scout" "Research vegan protein brands MY" "scout-vegan-research"
```

**What it does automatically:**
1. Maps agent → correct model
2. Labels the session for tracking
3. Logs dispatch to `~/.openclaw/logs/dispatch-log.jsonl`
4. Returns the session ID for tracking
5. Result is auto-announced back when subagent completes

---

## 📊 Tracking Dispatched Tasks

### Check active dispatches

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh list
```

### Check specific task

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh status <label>
```

### Log task outcome

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh done \
  "<label>" \
  "<success|fail|partial>" \
  "<one-line result summary>"
```

### View recent dispatch history

```bash
tail -20 ~/.openclaw/logs/dispatch-log.jsonl | python3 -m json.tool
```

---

## 🚨 The >3 Tool Calls Rule (HARD STOP)

```
IF you find yourself about to make a 4th tool call:

  1. STOP immediately
  2. Write a brief to the exec room:
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

## 💡 Common Patterns

### Pattern 1: Research → Create → Post

```bash
# Step 1: Research (Scout)
dispatch.sh "scout" "Research top 5 vegan protein brands in Malaysia — market share, pricing, social presence. Post to exec room." "scout-vegan-MY"

# Step 2 (after Scout reports): Brief Dreami with research findings
dispatch.sh "dreami" "Write 5 Instagram captions for Pinxin based on this research: [paste Scout output]. Brand voice: bold, clean, health-forward. Post to creative room." "dreami-pinxin-ig"

# Step 3 (after Dreami drafts): Dreami posts
dispatch.sh "dreami" "Post approved captions from creative room to Pinxin Instagram schedule. Report confirmation." "dreami-pinxin-post"
```

### Pattern 2: Parallel Research + Analysis

```bash
# Fire both simultaneously (different domains = no dependency)
dispatch.sh "scout" "Research competitor ad strategies for vegan brands on Meta" "scout-competitor-ads" &
dispatch.sh "dreami" "Analyze our last 30 days Meta ad performance — ROAS, CPM, CTR trends" "dreami-ad-perf" &
# Both auto-announce when done. Synthesize findings.
```

### Pattern 3: Simple → Delegate Without Thinking

```bash
# Never think twice about these — just dispatch.sh to Scout:
"Is our website up?" → scout
"What's in active-tasks.md?" → scout
"Commit and push the skills repo" → scout
"Post this summary to exec room" → scout
"What's the current git status?" → scout
```

---

## 📈 Compounding: Track Agent Performance

Every completed dispatch should log:

```json
{
  "ts": "2026-02-26T02:00:00+08:00",
  "agent": "scout",
  "task_type": "market-research",
  "label": "scout-vegan-MY",
  "outcome": "success",
  "duration_seconds": 45,
  "cost_saved_vs_zenni": "estimated $0.50 vs $3.00",
  "learning": "Scout handles competitive research in <60s. Use for all brand scouting."
}
```

**Review pattern performance weekly** to identify:
- Which agent succeeds most per task type → reinforce routing
- Which agent fails most per task type → adjust or swap model
- Where Zenni is still doing work herself → fix those leaks

---

## ⚡ Emergency Override Rules

If the auto-router and decision tree conflict:
1. **Trust SOUL.md rules** over router scores (SOUL.md = locked by Jenn)
2. **Cheapest capable agent wins** when scores are close (<10% difference)
3. **When in doubt → Scout first**, escalate if they fail
4. **Never override "simple task = Scout" rule** to give work to Zenni

---

## 🗂️ File Conventions

```
~/.openclaw/logs/
  dispatch-log.jsonl       ← all dispatches ever made
  dispatch-active.jsonl    ← currently running tasks
  
~/.openclaw/skills/orchestrate-v2/
  SKILL.md                 ← this file
  scripts/
    dispatch.sh            ← main dispatch wrapper
    track.sh               ← track task status
    classify.sh            ← quick classifier (wraps route-task.py)
```

---

## CHANGELOG

### v2.0.0 (2026-02-26)
- Full rewrite from v1: production-ready orchestration discipline
- Decision tree with explicit flowchart
- Cost efficiency table with real price comparisons
- Ready-to-use dispatch templates for every agent
- dispatch.sh: sessions_spawn wrapper with auto-model mapping
- track.sh: task status tracking with dispatch-log.jsonl
- classify.sh: quick router wrapper
- >3 tool calls hard stop protocol
- Common patterns: research→create→post, parallel, simple
- Compounding: outcome logging format for weekly review
