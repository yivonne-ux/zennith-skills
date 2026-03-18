---
name: spawn-templates
description: Spawn temporary specialist sub-agents on demand — QA, regression, copy, ads, research, scrape, batch, diagnose. No permanent sub-agents.
version: 1.0.0
agents: [main, taoz, dreami, scout]
---

# Spawn Templates — On-Demand Specialist Workers

## Philosophy

No permanent sub-agents. Spawn a worker, it does the job, it dies. Zero idle cost, zero memory leaks.

## Available Templates

| Template | Hosted By | What It Does |
|----------|-----------|-------------|
| `qa` | Scout | Review work for quality — brand voice, code, content |
| `regression` | Taoz | Run test suites, report pass/fail |
| `copy` | Dreami | Write ad/brand copy (3-5 variants) |
| `ads` | Dreami | Create/audit ad campaigns |
| `research` | Scout | Deep research with web search + scrapling |
| `scrape` | Scout | Scrape websites (auto-selects fetch/stealth/dynamic) |
| `batch` | Scout | Execute a list of tasks (Myrmidon-style) |
| `diagnose` | Taoz | Debug system issues (logs, config, gateway) |

## Usage

```bash
bash spawn-worker.sh <template> "<task>" [parent_agent] [timeout_seconds]

# Examples:
bash spawn-worker.sh qa "Review jade-oracle ad creative for brand voice" dreami 120
bash spawn-worker.sh regression "Run all routing tests after classify.sh change" taoz 300
bash spawn-worker.sh copy "Write 5 TikTok ad hooks for jade-oracle" main 180
bash spawn-worker.sh scrape "Extract all products from psychicsamira.com" main 300
bash spawn-worker.sh diagnose "Gateway returning 502 errors" main 120
```

## When Agents Should Spawn Workers

| Situation | Template |
|-----------|----------|
| After creating content | `qa` |
| After changing classify.sh or code | `regression` |
| Need ad copy for a campaign | `copy` |
| Need full campaign setup | `ads` |
| Need competitor/market info | `research` |
| Need data from websites | `scrape` |
| Have a list of repetitive tasks | `batch` |
| Something is broken | `diagnose` |

## Script Path

`~/.openclaw/skills/spawn-templates/scripts/spawn-worker.sh`
