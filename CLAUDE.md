# Zennith OS -- Claude Code Agent Context
> Auto-generated 2026-03-20 11:46 MYT from openclaw.json. Do NOT edit manually -- run sync-claude-md.py

## 1. What This Is

Zennith OS is a multi-agent AI operating system running 4 agents across 14 brands.
Human: Jenn Woei (CEO). Brands: dr-stan, gaia-eats, gaia-learn, gaia-os, gaia-print, gaia-recipes, gaia-supplements, iris, jade-oracle, mirra, pinxin-vegan, rasaya, serein, wholey-wonder.
Core F&B/wellness brands: pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein.
MIRRA = bento-style health food (NOT skincare, NOT the-mirra.com).

## 2. Agent Roster

| Agent | Name | Model | Role |
|-------|------|-------|------|
| `main` | Zenni | `gpt-5.4` | Communicator/Router — parses messages, routes via classify.sh, NEVER does specialist work |
| `taoz` | Taoz | `gpt-5.4` | CTO/Builder — glm-5 chat in OpenClaw, Claude Code CLI (Opus/Sonnet, $0) for real builds |
| `dreami` | Dreami | `gemini-3.1-pro-preview` | Creative Director + Copywriter — brand content, ad copy, image prompts, video scripts |
| `scout` | Scout | `gemini-3-flash-preview` | Agent |

## 3. System Architecture

OpenClaw is a multi-agent AI OS with a Node.js gateway at its core.

**Components:**
- **Gateway**: Node.js process managing sessions, dispatch, channels (WhatsApp, Telegram).
  Start: `nohup /usr/local/bin/node ~/.openclaw/../local/lib/node_modules/openclaw/dist/index.js gateway`
- **Agents**: 4 agents, each with SOUL.md (identity), workspace, sessions, memory.
- **Rooms**: JSONL files for async agent communication (`workspace/rooms/*.jsonl`).
- **Skills**: Reusable capabilities in `~/.openclaw/skills/*/SKILL.md` (66+ active).
- **Brands**: 14 brand DNA files at `~/.openclaw/brands/{brand}/DNA.json`.

**Two Systems (critical distinction):**

| System | Purpose | Cost | When |
|--------|---------|------|------|
| **Factory (OpenClaw)** | Daily content production, routing, agent sessions | API-billed per token | 24/7 automated |
| **Builder (Claude Code CLI)** | Code, builds, infrastructure, system improvements | $0 subscription (Claude Max) | On-demand by Jenn |

Claude Code spawns are Builder-side. You are reading this because you are a Builder spawn.
Do NOT use OpenClaw sessions for code tasks. Do NOT use Claude Code for daily content production.

**OpenClaw Native Tools:**
- `sessions_spawn` -- spawn a new agent task (preferred for dispatch)
- `sessions_send` -- message existing session (costs $$$, avoid)
- `exec` -- run shell command via gateway
- Rooms -- async $0 communication via JSONL files

## 4. Dispatch Flow

All user messages flow through Zenni (main), who classifies via `gaia-classify` (symlink to classify.sh).
classify.sh uses keyword matching -- zero LLM cost, 100% deterministic.

**5 Routing Tiers:**

| Tier | What Happens | Example |
|------|-------------|---------|
| RELAY | Zenni replies directly | Greetings, acks, status |
| LOOKUP | Inline data returned | Brand info, quick facts |
| SCRIPT | CLI tool runs via exec (no LLM) | `nanobanana-gen.sh` for images |
| CODE | Claude Code CLI fires via `claude-code-runner.sh` | Code/build tasks |
| DISPATCH | Agent spawned via `sessions_spawn` | Research, strategy, creative |

**Dispatch rules by domain:**
- Code/build/fix/deploy/scripts --> CODE tier (Claude Code CLI, NOT Taoz subagent)
- Image generation --> SCRIPT tier (NanoBanana CLI, no LLM needed)
- Research/scraping --> DISPATCH to Artemis
- Creative/copy/scripts --> DISPATCH to Dreami
- Visual QA/social --> DISPATCH to Iris
- Strategy/analysis --> DISPATCH to Athena
- Ads/pricing/revenue --> DISPATCH to Hermes
- Bulk ops/git/config --> DISPATCH to Myrmidons
- Testing/QA --> DISPATCH to Argus
- Orchestration --> Zenni (main)

## 5. File Rules & Canonical Paths

**Canonical locations (source of truth):**
- SOUL.md: `~/.openclaw/workspace-{id}/SOUL.md` (symlinked FROM `agents/{id}/agent/SOUL.md`)
- HEARTBEAT.md: `~/.openclaw/workspace-{id}/HEARTBEAT.md` (symlinked same way)
- Config: `~/.openclaw/openclaw.json` -- THE source of truth for agents, models, fallbacks
- Shared Protocol: `~/.openclaw/workspace/SHARED-PROTOCOL.md` -- all team rules
- Brands: `~/.openclaw/brands/{brand}/DNA.json` -- always load before brand-specific work
- Rooms: `~/.openclaw/workspace/rooms/*.jsonl` -- JSONL format, append-only
- Skills: `~/.openclaw/skills/*/SKILL.md` -- also symlinked to `~/.claude/skills/`
- Characters: `~/.openclaw/workspace/data/characters/{agent}/`
- Images: `~/.openclaw/workspace/data/images/{brand}/`
- Videos: `~/.openclaw/workspace/data/videos/`
- Logs: `~/.openclaw/workspace/rooms/logs/build-log-{mission}.md`
- GAIA Vision: `~/.openclaw/workspace/GAIA-VISION.md`
- Agent Matrix: `~/.openclaw/workspace/GAIA-OS-AGENT-MATRIX.md`
- Knowledge Sync: `~/.openclaw/workspace-taoz/KNOWLEDGE-SYNC.md` (bridge between Claude Code and OpenClaw)

**File path resolver:** `bash workspace/scripts/path-resolver.sh --type <type> [--brand <brand>]`

## 6. Key Tools

| Need | Tool / Command |
|------|---------------|
| Image generation | `nanobanana-gen.sh` (Gemini Image API, supports --style-seed, --campaign, --ref-image) |
| Video generation | `video-gen.sh` (Kling 3.0 / Wan 2.6 / Sora 2) |
| Video post-prod | `video-forge.sh` (FFmpeg + WhisperX) |
| Brand voice check | `brand-voice-check.sh` (mandatory before publishing brand content) |
| Rigour gate | `bash ~/.openclaw/skills/rigour/scripts/gate.sh <file>` (mandatory before shipping code) |
| Seed ideas | `seed-store.sh` (add/query/tag/update/count/top) |
| Persona creation | `persona-gen.sh` |
| Auditor | `gaia-auditor` (audit/orchestrate/learn/test/promote) |

## 7. What NOT To Do

- NEVER edit `openclaw.json` without JSON validation first -- gateway crashes on bad config
- NEVER run `openclaw doctor --fix` -- it destroys config
- NEVER use `~` in exec commands -- gateway does NOT expand tilde (use absolute paths)
- NEVER spawn subagents for code tasks -- use CODE tier / `claude-code-runner.sh`
- NEVER write code as Taoz OpenClaw subagent (glm-5 too weak) -- fire Claude Code CLI instead
- NEVER write to /tmp, ~/Desktop, or random locations -- use canonical paths above
- NEVER auto-approve exec commands -- if denied, use sessions_spawn fallback
- NEVER hardcode agent list or models -- always read from `openclaw.json`
- NEVER skip rigour gate before shipping code
- NEVER publish brand content without `brand-voice-check.sh`
- Git commit after EVERY skill or code change
- After updating agent/model config: run `python3 workspace/scripts/sync-claude-md.py`

## 8. Operational Rules

- Every agent in openclaw.json MUST have `workspace` and `agentDir` fields (SOUL.md won't load without them)
- Gateway is single point of failure -- keepalive cron checks every 5 min, restarts if dead
- After gateway restart: push exec approvals with `openclaw approvals set --file ~/.openclaw/exec-approvals.json --gateway`
- macOS gotchas: no `timeout` command (use background+wait+kill), Bash 3.2 (no `declare -A`), `wc -l` has leading spaces
- Hardware: iMac 27" 2020, Intel i5, 8GB RAM (bottleneck), 132GB free disk
- Node.js: use `/usr/local/bin/node` (Node 25, has FTS5) -- NOT ~/local/bin/node (Node 22, no FTS5)
- OpenClaw version: v2026.2.24 -- strict schema, rejects ALL unrecognized keys
- Session maintenance: pruneAfter 7d, maxEntries 500, maxDiskBytes 100mb
- maxSpawnDepth: 2, maxChildrenPerAgent: 9, runTimeoutSeconds: 300
- Memory: agents write to `memory/YYYY-MM-DD.md`, auto-vectorized every ~2h, searchable via `memory_search`
- Compound learning: `bash skills/knowledge-compound/scripts/digest.sh` after significant tasks
- Read agent SOUL.md before acting as that agent
- Log work to `rooms/logs/build-log-{mission}.md`

---
> 4 agents | 14 brands | Generated by sync-claude-md.py | 2026-03-20 11:46 MYT
