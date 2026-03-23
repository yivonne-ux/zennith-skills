---
name: klaviyo-engine
description: Full Klaviyo automation CLI. Create flows, templates, lists, manage subscribers, send campaigns. Just setup your API key and go.
version: 1.0.0
agents: [main, dreami, hermes]
evolves: true
---

# Klaviyo Engine — Full Email Marketing CLI

## Quick Start
```bash
# 1. Setup (one time)
bash ~/.openclaw/skills/klaviyo-engine/scripts/klaviyo.sh setup pk_YOUR_API_KEY

# 2. Use
bash ~/.openclaw/skills/klaviyo-engine/scripts/klaviyo.sh status
bash ~/.openclaw/skills/klaviyo-engine/scripts/klaviyo.sh lists
bash ~/.openclaw/skills/klaviyo-engine/scripts/klaviyo.sh flows
```

## Commands

| Command | What |
|---------|------|
| `setup <api_key>` | Save API key |
| `status` | Account overview |
| `lists` | List all lists |
| `list-create <name>` | Create list |
| `templates` | List templates |
| `flows` | List flows |
| `flow-create <name> <trigger_metric_id> <template_ids...>` | Create flow |
| `metrics` | List metrics (for triggers) |
| `subscribe <list_id> <email> [name]` | Add subscriber |

## API Key
Stored at `~/.openclaw/secrets/klaviyo-api-key`. Get from Klaviyo dashboard → Account → Settings → API Keys.
