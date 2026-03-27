---
name: gaia-ops
description: Background knowledge about GAIA CORP-OS operations — how to interact with the system, agent communication patterns, room protocols, skill invocation.
agents:
  - main
  - taoz
---

# GAIA Ops — Zennith OS Operations Guide

Background knowledge for all agents on how the Zennith OS multi-agent system operates. Covers communication patterns, room protocols, dispatch flow, skill invocation, and operational conventions.

## System Overview

Zennith OS is a 4-agent AI operating system managing 14 brands. It runs on OpenClaw (gateway + agents) with Claude Code CLI as the builder system.

### Agent Roster

| Agent | ID | Role | Engine |
|-------|-----|------|--------|
| Zenni | main | CEO/Router — parses messages, classifies, dispatches | GPT-5.4 (OpenClaw) |
| Taoz | taoz | CTO/Builder — code, infra, systems | Claude Code CLI (Opus 4.6) |
| Dreami | dreami | Creative Director — content, copy, art, marketing | Gemini CLI |
| Scout | scout | Research & Ops — scraping, analysis, data | Gemini Flash |

### Two Systems

| System | Purpose | When |
|--------|---------|------|
| Factory (OpenClaw) | Content production, routing, sessions | 24/7 automated |
| Builder (Claude Code) | Code, builds, infrastructure | On-demand by Jenn |

## Communication Patterns

### Rooms (Async, $0)

Rooms are JSONL files at `~/.openclaw/workspace/rooms/*.jsonl`. Used for:
- Agent-to-agent async communication
- Mission logs and status updates
- Append-only (never edit existing lines)

Format:
```json
{"ts":"2026-03-17T10:00:00Z","from":"dreami","msg":"Jade carousel complete. 5 images in data/images/jade-oracle/carousel-001/"}
```

### Dispatch Flow

All user messages go through Zenni, who classifies via `gaia-classify`:

1. **RELAY**: Zenni responds directly (greetings, acks)
2. **LOOKUP**: Inline data returned (brand info, facts)
3. **SCRIPT**: CLI tool runs via exec (image gen, no LLM)
4. **CODE**: Claude Code CLI fires via `claude-code-runner.sh`
5. **DISPATCH**: Agent spawned via `sessions_spawn` or `dispatch.sh`

### Direct Dispatch

```bash
dispatch.sh {agent} "{task description}" {skill-name}
```

Zenni uses `dispatch.sh` via exec tool (never rely on manual `sessions_spawn` calls — hallucination risk).

## Skill Invocation

Skills live at `~/.openclaw/skills/{name}/SKILL.md`. To use a skill:

1. Agent receives a task that matches a skill
2. Agent reads the SKILL.md for instructions
3. Agent follows the procedure step by step
4. Agent writes output to the specified location

Skills with scripts have executables in `~/.openclaw/skills/{name}/scripts/`.

## Brand Operations

14 brands with DNA files at `~/.openclaw/brands/{brand}/DNA.json`:

| Brand | Type |
|-------|------|
| dr-stan | Wellness / supplements |
| gaia-eats | Food delivery |
| gaia-learn | Education |
| gaia-os | Core OS / tech |
| gaia-print | E-commerce / print |
| gaia-recipes | Recipe content |
| gaia-supplements | Supplements |
| iris | Visual / social |
| jade-oracle | Spiritual / QMDJ readings |
| mirra | Bento health food (NOT skincare) |
| pinxin-vegan | Vegan food |
| rasaya | Wellness |
| serein | Lifestyle / calm |
| wholey-wonder | E-commerce |

**Always load DNA.json before brand-specific work.**

## File Conventions

| Type | Path |
|------|------|
| Brand DNA | `~/.openclaw/brands/{brand}/DNA.json` |
| Room messages | `~/.openclaw/workspace/rooms/{name}.jsonl` |
| Build logs | `~/.openclaw/workspace/rooms/logs/build-log-{mission}.md` |
| Images | `~/.openclaw/workspace/data/images/{brand}/` |
| Videos | `~/.openclaw/workspace/data/videos/` |
| Characters | `~/.openclaw/workspace/data/characters/{name}/` |
| SOUL.md | `~/.openclaw/workspace-{id}/SOUL.md` |
| Config | `~/.openclaw/openclaw.json` |

## Operational Rules

1. **Never edit openclaw.json without validation** — gateway crashes on bad config
2. **Never use `~` in exec commands** — gateway does not expand tilde
3. **Always use absolute paths** in scripts and exec calls
4. **Git commit after every skill or code change**
5. **Run rigour gate before shipping code**: `bash ~/.openclaw/skills/rigour/scripts/gate.sh <file>`
6. **Run brand-voice-check.sh before publishing brand content**
7. **Log work to rooms** — append to relevant JSONL file
8. **Local files are not live products** — verify at source before marking done
9. **After config changes**: run `python3 workspace/scripts/sync-claude-md.py`
10. **After gateway restart**: push exec approvals

## Key Tools

| Need | Tool |
|------|------|
| Image generation | `nanobanana-gen.sh` |
| Video generation | `video-gen.sh` |
| Video post-production | `video-forge.sh` |
| Brand voice check | `brand-voice-check.sh` |
| Code quality gate | `gate.sh` |
| Knowledge digest | `digest.sh` |
| Path resolution | `path-resolver.sh` |

## Anti-Hallucination Protocol

After the 2026-03-10 incident (2,937 fake references):
- **NEVER claim something is live without `curl` or browser verification**
- **Local files are NOT live products**
- **If you dispatch a task, verify the tool call was actually made in gateway logs**
- **When in doubt, verify at source**

## Session Limits

- maxSpawnDepth: 2 (no deeply nested sub-agents)
- maxChildrenPerAgent: 9
- runTimeoutSeconds: 300
- Session pruning: after 7 days, max 500 entries, max 100MB
