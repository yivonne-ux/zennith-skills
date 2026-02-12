---
name: boss-dashboard
description: Boss monitoring dashboard for GAIA CORP-OS. Two modes — boss-dashboard.status (text report) and boss-dashboard.web (start the game-style web UI).
metadata:
  openclaw:
    requires:
      bins: [node]
    scope: monitoring
    guardrails:
      - Read-only. Never modify session files, logs, or config.
      - Never expose API keys, secrets, or credentials in output.
      - Cost data is approximate and for internal reference only.
---

# Boss Dashboard (GAIA CORP-OS)

Monitoring tool for Jenn to check agent status, activity, and costs.

## Skill 1 — boss-dashboard.status (Text Report)

**When to use:**
- Jenn asks "what's happening", "status", "status report", "what are the agents doing"
- Periodic check-in on agent health
- Can be triggered from WhatsApp, terminal, or any channel

**How to generate the report:**

Read these data sources and compile a structured report:

1. **Gateway health:** run `openclaw health`
2. **Session index:** read `~/.openclaw/agents/main/sessions/sessions.json` — check updatedAt, totalTokens for recent activity
3. **Recent activity:** read the last 20 lines of the 3 most recently modified `*.jsonl` files in `~/.openclaw/agents/main/sessions/`
4. **Fetcher activity:** same for `~/.openclaw/agents/zenni-fetcher/sessions/`

**Output format:**
```
GAIA CORP-OS — Status Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AGENTS
  Zenni Prime (Kimi 2.5)  ● Online    Last: Xm ago
  Fetcher (Qwen3)          ● Online    Last: Xm ago
  Claude Code              ○ On-call
  Qwen Swarm               ○ Standby

RECENT ACTIVITY (last 6h)
  HH:MM  Agent   Action summary
  HH:MM  Agent   Action summary
  ...

SYSTEM
  Gateway: online/offline
  Orchestrator: moonshot/kimi-k2.5
  Worker: openrouter/qwen/qwen3-coder-next
```

## Skill 2 — boss-dashboard.web (Web Dashboard)

**When to use:**
- Jenn asks to "open the dashboard", "show me the dashboard", "open boss view"
- Starting the pixel-art web monitoring UI

**How to start:**
```bash
cd ~/.openclaw/workspace/apps/boss-dashboard && node server.js &
```

Then tell Jenn to open: **http://localhost:19800**

The web dashboard shows:
- Agent station cards with live status
- Scrolling activity feed (auto-refresh 15s)
- Gateway health bar
- Pixel-art game aesthetic

**How to stop:**
```bash
pkill -f "boss-dashboard/server.js"
```

## For Deployment (Zenni — when Jenn asks)

The web dashboard can be hosted publicly:

1. **Push to GitHub:** Use the `github` skill to create a repo
2. **Deploy to Vercel:**
   - The `server.js` can be adapted to Vercel serverless functions
   - Static files go to `public/`
   - API routes go to `api/`
3. **Data sync:** Set up a cron job to push session summaries to a hosted DB (Supabase or similar)
4. **Auth:** Add simple password or token auth to protect the hosted dashboard

When Jenn asks to host this, create a deployment plan and ask for approval first.
