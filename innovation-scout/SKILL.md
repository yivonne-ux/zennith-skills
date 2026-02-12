---
name: innovation-scout
version: "1.0.0"
description: Daily AI agent innovation scouting loop. Artemis researches the best AI agent ideas from GitHub, Twitter, Product Hunt, HN, Reddit, ArXiv and brings them to Townhall.
metadata:
  openclaw:
    scope: research
    guardrails:
      - Only surface ideas relevant to GAIA's needs
      - Never auto-implement — all ideas go through Zenni's triage
      - Major architecture changes require exec room decision brief
      - Scout reports are informational, not actionable until tagged
---

# Innovation Scout — AI Agent R&D Loop

## Purpose

An always-on R&D loop where Artemis researches the best AI agent innovations and brings them to the Pantheon. The goal: stay ahead of the curve, adopt tools that give GAIA a competitive edge, and never miss a breakthrough.

---

## Daily Scout Cycle

**Trigger:** Cron job, daily at 08:00 Asia/Kuala_Lumpur (morning report before work begins)
**Agent:** Artemis 🏹 (with `site-scraper`, `meta-ads-library`, `tiktok-trends`, `ig-reels-trends`, `youtube-intel`, `product-scout`, `credential-resolver`)

### Scrape Targets

| Source | What to Look For | Method |
|--------|-----------------|--------|
| GitHub Trending | AI agent repos, multi-agent frameworks, MCP tools, new LLM tooling | `firecrawl-search` / `site-scraper` |
| Twitter/X | #AIAgents, #MultiAgent, top AI builders, viral agent demos | `browser-use` / `site-scraper` |
| Product Hunt | New AI agent product launches, automation tools | `site-scraper` |
| Hacker News | AI agent discussions, Show HN agent projects | `firecrawl-search` |
| Reddit | r/LocalLLaMA, r/MachineLearning agent posts, r/ChatGPT tool threads | `site-scraper` |
| ArXiv | Agent architecture papers (summaries only, not full papers) | `firecrawl-search` |

### Output Format — Scout Report

Post to `townhall.jsonl`:

```json
{
  "ts": "<timestamp>",
  "agent": "artemis",
  "room": "townhall",
  "type": "scout-report",
  "msg": "Scout Report — YYYY-MM-DD\n\n[structured ideas list]"
}
```

Each idea in the report follows this structure:

```
### [Idea Title]
- **Source:** [URL or platform + link]
- **Relevance:** [1-10 score]
- **What it does:** [1-2 sentence description]
- **How we could use it:** [specific GAIA application]
- **Effort to adopt:** [low | medium | high]
- **Category:** [e-commerce | social | content | scraping | marketing | multi-agent | infrastructure]
```

### Relevance Filter

Only surface ideas that match GAIA's needs. Relevant categories:
- **E-commerce automation** — order management, listing optimization, pricing tools
- **Social media** — content scheduling, engagement bots, trend detection
- **Content creation** — AI-generated copy, images, videos, A/B testing
- **Web scraping** — data extraction, competitive intelligence tools
- **Performance marketing** — ad optimization, audience targeting, ROAS tools
- **Multi-agent coordination** — orchestration frameworks, agent communication protocols
- **Memory / Learning** — vector databases, knowledge graphs, self-improving systems
- **MCP tools** — Model Context Protocol servers and clients

Ideas that score below 5 on relevance are not included in the report.

---

## Townhall Triage (Zenni)

When Zenni receives a scout report, she tags each idea:

| Tag | Meaning | Next Step |
|-----|---------|-----------|
| `[BUILD]` | Worth building now | Zenni composes task brief → routes to Hephaestus (build room) |
| `[EVALUATE]` | Promising but needs analysis | Athena does cost/benefit analysis → exec room for Jenn's decision |
| `[PARK]` | Interesting but not now | Saved to learning-log for future reference |
| `[SKIP]` | Not relevant enough | No action, archived in scout report |

### Escalation Rules

- **New frameworks that would replace existing tools** → exec room as decision brief with A/B/C options
- **Security-relevant tools** (auth, encryption, sandboxing) → Zenni reviews + Claude Code red-team review
- **Cost-impacting tools** (paid APIs, new subscriptions) → exec room for Jenn's approval
- **Quick wins** (free, easy to adopt, low risk) → Zenni can approve directly, routes to Hephaestus

---

## Build + Show Pipeline

When an idea is tagged `[BUILD]`:

1. **Hephaestus builds a proof-of-concept**
   - Scoped to 2-4 hours of work
   - Must produce working code, not just a plan

2. **Posts to build room with 4-part contract:**
   - **Result:** What was built, what it does
   - **Proof:** Test output, demo screenshot, working command
   - **What Changed:** Files created/modified, dependencies added
   - **Learning:** What we learned during the build (gotchas, surprises, limitations)

3. **Integration decision:**
   - If it works → integrate into the system + git commit + update MEMORY.md
   - If it doesn't → learning-log entry explaining why + what we'd need to make it work

---

## Weekly Innovation Summary

As part of the weekly review (corp-os-compound):
- Aggregate all scout reports from the week
- Count: ideas surfaced, ideas built, ideas parked, ideas skipped
- Identify trends: "This week, 3 separate tools for agent memory appeared — this space is maturing"
- Recommend strategic adjustments if a trend is strong enough

---

## Example Scout Report

```
Scout Report — 2026-02-12

### AgentOps: Open-source agent observability
- Source: GitHub trending (github.com/AgentOps-AI/agentops)
- Relevance: 8/10
- What it does: Tracks agent actions, costs, errors across runs with a dashboard
- How we could use it: Monitor Pantheon agent performance, cost per task, error rates
- Effort to adopt: medium (Python SDK, needs integration with OpenClaw)
- Category: multi-agent

### TikTok Creative Center API
- Source: Product Hunt (new launch)
- Relevance: 9/10
- What it does: Official API for trending sounds, hashtags, and creative insights on TikTok
- How we could use it: Artemis can use this for trend detection instead of scraping
- Effort to adopt: low (REST API, just needs auth)
- Category: social

### ReAct Agent Pattern for E-commerce
- Source: ArXiv paper summary
- Relevance: 6/10
- What it does: Combines reasoning and acting in a loop for complex e-commerce tasks
- How we could use it: Could improve Hermes's pricing optimization workflow
- Effort to adopt: high (architectural change to agent loop)
- Category: e-commerce
```

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: daily scout cycle, relevance filter, townhall triage, build pipeline
