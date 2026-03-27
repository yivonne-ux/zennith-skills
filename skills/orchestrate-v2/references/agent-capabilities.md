# Detailed Agent Capabilities & Task Classification

## Agent Roster & Models

| Agent | ID | Model | Cost Tier | Domain |
|-------|-----|-------|-----------|--------|
| **Taoz** | `taoz` | `gpt-5.4` | $0 (Claude Code CLI) | Code, builds, infrastructure, skills |
| **Scout** | `scout` | `gemini-3-flash` | $0 (Gemini CLI) | Research, ops, simple tasks, lookups, health checks |
| **Dreami** | `dreami` | `gemini-3.1-pro` | $0 (Gemini CLI) | Creative + Marketing + Art — copy, campaigns, visuals, ads |
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

## Task Classification Guide

### SCOUT (always route here first for simple tasks)

```
Route to Scout if ANY of these match:
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

### TAOZ (code tasks)

```
Route to Taoz if ANY of these match:
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

### SCOUT (research tasks)

```
Route to Scout if ANY of these match:
   - Research [topic/competitor/market]
   - Find information about...
   - Scrape / extract data from web
   - Monitor news / trends
   - Competitor analysis
   - Market data collection
   - Fact-checking

Model: gemini-3-flash ($0, Gemini CLI)
```

### DREAMI (creative, visual, copy, ads & marketing)

```
Route to Dreami if ANY of these match:
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

### ZENNI (strategy & analysis)

```
Route to Zenni if ANY of these match:
   - Analyze data / performance metrics
   - Strategic planning / roadmap
   - Business case / feasibility study
   - Reporting / dashboards
   - Forecasting / modeling
   - OKR / KPI tracking
   - Complex multi-variable analysis

Model: gpt-5.4
```

## Common Patterns

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
dispatch.sh "scout" "Research competitor ad strategies for vegan brands on Meta" "scout-competitor-ads" &
dispatch.sh "dreami" "Analyze our last 30 days Meta ad performance — ROAS, CPM, CTR trends" "dreami-ad-perf" &
```

### Pattern 3: Simple → Delegate Without Thinking

```bash
"Is our website up?" → scout
"What's in active-tasks.md?" → scout
"Commit and push the skills repo" → scout
"Post this summary to exec room" → scout
"What's the current git status?" → scout
```

## Agent Performance Compounding

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
