---
name: orchestrate-v2
version: "2.0.0"
description: Zenni's production orchestration discipline. Auto-classify tasks, enforce delegation rules, dispatch to the right agent, track outcomes, compound learnings.
metadata:
  openclaw:
    scope: orchestration
    load_priority: ALWAYS  # Zenni loads this on every session
    guardrails:
      - Zenni NEVER does specialist work herself
      - Every dispatch logged to dispatch-log.jsonl
      - >3 tool calls = DELEGATE (no exceptions)
      - Cheapest capable agent always wins
      - Simple tasks (< 3 tool calls, no judgment) = Myrmidons
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
2. `<3 tool calls + no strategic judgment` → MYRMIDONS
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
│  │   └──▶ MYRMIDONS (always, no debate)│
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
│  Is it research/web/data?   → ARTEMIS   │
│  Is it creative copy/brand? → DREAMI    │
│  Is it visual/social/art?   → IRIS      │
│  Is it strategy/analysis?   → ATHENA    │
│  Is it ads/pricing/revenue? → HERMES    │
│  Is it simple/cheap/bulk?   → MYRMIDONS │
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
| **Myrmidons** | `myrmidons` | `minimax-m2.5` | 💚 Cheapest ($0.14/$0.14/M) | Simple tasks, lookups, git, file ops, health checks |
| **Taoz** | `taoz` | `glm-4.7-flash` | 💚 Budget ($0.06/$0.40/M) | Code, builds, infrastructure, skills (heavy builds via Claude Code CLI) |
| **Artemis** | `artemis` | `kimi-k2.5` | 🟢 Free (Moonshot) | Research, web scraping, competitive intel |
| **Dreami** | `dreami` | `kimi-k2.5` | 🟢 Free (Moonshot) | Creative direction, copy, campaigns, brand voice |
| **Iris** | `iris` | `qwen3-vl-235b` | 🟡 Medium ($0.40/$1.60/M) | Visual content, social media, image gen |
| **Athena** | `athena` | `glm-5` | 🟠 High ($0.80/$2.56/M) | Strategy, analysis, reporting, forecasting |
| **Hermes** | `hermes` | `glm-5` | 🟠 High ($0.80/$2.56/M) | Ads, pricing, revenue optimization |
| **Zenni** | `main` | `glm-4.7-flash` | 💚 Budget ($0.06/$0.40/M) | Orchestration ONLY — never specialist work |

### Cost Efficiency Rule

```
Before dispatching to a premium agent, ask:
"Can Myrmidons do this?"

Myrmidons = $0.14/$0.14 per M tokens
Zenni     = $0.06/$0.40 per M tokens (v4: glm-4.7-flash)

If Myrmidons can do 80% as well → use Myrmidons.
Only escalate if the task genuinely needs specialist capability.
```

---

## 📋 Task Classification Guide

### → MYRMIDONS (always route here first for simple tasks)

```
✅ Route to Myrmidons if ANY of these match:
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

### → ARTEMIS (research tasks)

```
✅ Route to Artemis if ANY of these match:
   - Research [topic/competitor/market]
   - Find information about...
   - Scrape / extract data from web
   - Monitor news / trends
   - Competitor analysis
   - Market data collection
   - Fact-checking
   
Model: kimi-k2.5 (FREE on Moonshot)
```

### → DREAMI (creative copy & direction)

```
✅ Route to Dreami if ANY of these match:
   - Write copy / captions / EDM
   - Create campaign concept / brief
   - Brand voice / messaging strategy
   - Taglines / headlines
   - Creative direction (not visual, that's Iris)
   - Script / storytelling
   - Bilingual content (EN/CN)
   
Model: kimi-k2.5
```

### → IRIS (visual & social)

```
✅ Route to Iris if ANY of these match:
   - Generate images / visuals
   - Social media posting / scheduling
   - Instagram / TikTok content
   - Visual direction / mood boards
   - Community engagement
   - Image QA / brand consistency check
   
Model: qwen3-vl-235b
Image tool: NanoBanana (gemini-3-pro-image-preview)
```

### → ATHENA (strategy & analysis)

```
✅ Route to Athena if ANY of these match:
   - Analyze data / performance metrics
   - Strategic planning / roadmap
   - Business case / feasibility study
   - Reporting / dashboards
   - Forecasting / modeling
   - OKR / KPI tracking
   - Complex multi-variable analysis
   
Model: glm-5 ($0.80/$2.56/M)
```

### → HERMES (ads & pricing)

```
✅ Route to Hermes if ANY of these match:
   - Meta ads / ad optimization
   - Pricing strategy / bundles
   - Revenue / ROAS analysis
   - Shopee / Lazada channel ops
   - Promotion mechanics
   - Budget allocation
   
Model: glm-5 ($0.80/$2.56/M)
Note: Changes >RM 500 impact require Jenn approval gate
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

### Myrmidons Dispatch Template

```python
# Via sessions_spawn (preferred for tracked tasks):
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "myrmidons" \
  "TASK DESCRIPTION HERE" \
  "myrm-TASK_SLUG"

# Direct (for fire-and-forget):
openclaw agent --agent myrmidons --message "TASK DESCRIPTION"
```

**Example tasks:**
```bash
# Check website status
dispatch.sh "myrmidons" "Ping https://gaiaos.com and report if up or down. Post result to exec room." "myrm-health-check"

# Git operations  
dispatch.sh "myrmidons" "cd /path/to/repo && git add -A && git commit -m 'chore: update config' && git push. Report status." "myrm-git-push"

# File operation
dispatch.sh "myrmidons" "Read ~/.openclaw/workspace/active-tasks.md and return its contents." "myrm-read-file"
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

### Artemis Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "artemis" \
  "RESEARCH BRIEF:
  
  Topic: [what to research]
  Scope: [how deep, which sources]
  Output format: [structured data / summary / bullet list]
  Key questions to answer:
  - [question 1]
  - [question 2]
  
  Post findings to exec room when done." \
  "artemis-RESEARCH_SLUG"
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

### Iris Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "iris" \
  "VISUAL BRIEF:
  
  What: [image gen / social post / visual direction]
  Brand: [brand name]
  Style: [mood, aesthetic, references]
  Dimensions: [1:1 / 9:16 / 16:9]
  Text overlay: [yes/no, copy to include]
  Image model: gemini-3-pro-image-preview (NanoBanana)
  
  Output: Save to brands/[brand]/output/ and report path.
  Platform: [Instagram / TikTok / website]" \
  "iris-VISUAL_SLUG"
```

---

### Athena Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "athena" \
  "ANALYSIS BRIEF:
  
  Question: [what strategic question to answer]
  Data available: [what data to use]
  Time period: [date range if applicable]
  
  Deliver:
  - Executive summary (3–5 bullets)
  - Key findings with supporting data
  - Recommended actions
  
  Post to exec room when complete." \
  "athena-ANALYSIS_SLUG"
```

---

### Hermes Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "hermes" \
  "ADS/PRICING BRIEF:
  
  Task: [ad optimization / pricing / revenue analysis]
  Brand: [brand name]
  Channel: [Meta / Shopee / Lazada / etc]
  Current situation: [current spend / ROAS / pricing]
  Goal: [target ROAS / margin / revenue]
  
  Constraints:
  - Budget cap: RM [X]
  - Changes >RM 500 impact → flag for Jenn approval
  
  Deliver recommendation with math to exec room." \
  "hermes-ADS_SLUG"
```

---

## 🔧 Using dispatch.sh

The `dispatch.sh` script wraps `sessions_spawn` with the right model, label, and logging per agent.

```bash
# Full usage
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "<agent_id>" \           # myrmidons | taoz | artemis | dreami | iris | athena | hermes
  "<task_brief>" \         # Full task description (quoted)
  "<label>" \              # Human-readable label for tracking (e.g. "taoz-build-landing-page")
  [thinking_level] \       # Optional: low | medium | high (default: medium)
  [timeout_seconds]        # Optional: default 300

# Examples
bash dispatch.sh "myrmidons" "Check if gaiaos.com is live" "myrm-healthcheck"
bash dispatch.sh "taoz" "Build skill: orchestrate-v2" "taoz-skill-build" "medium" 600
bash dispatch.sh "artemis" "Research vegan protein brands MY" "artemis-vegan-research"
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
# Step 1: Research (Artemis)
dispatch.sh "artemis" "Research top 5 vegan protein brands in Malaysia — market share, pricing, social presence. Post to exec room." "artemis-vegan-MY"

# Step 2 (after Artemis reports): Brief Dreami with research findings
dispatch.sh "dreami" "Write 5 Instagram captions for Pinxin based on this research: [paste Artemis output]. Brand voice: bold, clean, health-forward. Post to creative room." "dreami-pinxin-ig"

# Step 3 (after Dreami drafts): Iris posts
dispatch.sh "iris" "Post approved captions from creative room to Pinxin Instagram schedule. Report confirmation." "iris-pinxin-post"
```

### Pattern 2: Parallel Research + Analysis

```bash
# Fire both simultaneously (different domains = no dependency)
dispatch.sh "artemis" "Research competitor ad strategies for vegan brands on Meta" "artemis-competitor-ads" &
dispatch.sh "athena" "Analyze our last 30 days Meta ad performance — ROAS, CPM, CTR trends" "athena-ad-perf" &
# Both auto-announce when done. Synthesize → brief Hermes.
```

### Pattern 3: Simple → Delegate Without Thinking

```bash
# Never think twice about these — just dispatch.sh to Myrmidons:
"Is our website up?" → myrmidons
"What's in active-tasks.md?" → myrmidons  
"Commit and push the skills repo" → myrmidons
"Post this summary to exec room" → myrmidons
"What's the current git status?" → myrmidons
```

---

## 📈 Compounding: Track Agent Performance

Every completed dispatch should log:

```json
{
  "ts": "2026-02-26T02:00:00+08:00",
  "agent": "artemis",
  "task_type": "market-research",
  "label": "artemis-vegan-MY",
  "outcome": "success",
  "duration_seconds": 45,
  "cost_saved_vs_zenni": "estimated $0.50 vs $3.00",
  "learning": "Artemis handles competitive research in <60s. Use for all brand scouting."
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
3. **When in doubt → Myrmidons first**, escalate if they fail
4. **Never override "simple task = Myrmidons" rule** to give work to Zenni

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
