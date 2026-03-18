---
name: workflow-automation
version: "1.0.0"
description: "Agent-driven automation layer for GAIA CORP-OS. Agents auto-register new output types, workflows, and production chains without human CLI input. Manages the skill registry, production chains, and workflow templates as machine-readable data."
metadata:
  openclaw:
    scope: infrastructure
    owner: taoz
    callable_by: all
    guardrails:
      - All registrations are validated before writing (required fields enforced)
      - Duplicate IDs are rejected — never overwrite existing output types silently
      - All changes are announced to creative.jsonl room for visibility
      - skill-registry.json is rebuilt nightly or on-demand — never hand-edited
      - production-chains.json is append-only for new chains — existing chains are not modified by registration
---

# Workflow Automation — Agent Self-Registration System

## Purpose

Enable GAIA agents to autonomously register new output types, production workflows, and skills into the production system. When Scout discovers a new ad format from competitor analysis, or Dreami invents a new creative format, they dispatch to this skill to register it — no human CLI input required.

## Owner

**Taoz (CTO/Builder)** — owns and maintains the scripts. Any agent can call them.

## Data Files

| File | Purpose |
|------|---------|
| `~/.openclaw/workspace/data/skill-registry.json` | Machine-readable mapping of skills to agents, output types, and capabilities |
| `~/.openclaw/workspace/data/production-chains.json` | Ordered post-production steps for each output type |
| `~/.openclaw/workspace/data/output-types.json` | Full output type definitions with style params, QA checklists, etc. |
| `~/.openclaw/workspace/data/workflow-templates.json` | Pre-configured production presets for daily content creation |

## Scripts

### register-output-type.sh — Register a new output type

Agents pipe JSON on stdin to register a new output type into the production system.

```bash
echo '{"id":"comparison-ad","name":"Comparison Ad","funnel_stage":"MOFU","aspect_ratios":["9:16","1:1"]}' | \
  bash ~/.openclaw/skills/workflow-automation/scripts/register-output-type.sh
```

**What it does:**
1. Validates JSON input (required: id, name, funnel_stage, aspect_ratios)
2. Rejects duplicate IDs
3. Appends to output-types.json
4. Generates a workflow template and appends to workflow-templates.json
5. Adds any production chain to production-chains.json
6. Updates skill-registry.json — adds output type to relevant skills
7. Posts notification to creative.jsonl room
8. Exits 0 with the new type ID on stdout

**Full input schema:**
```json
{
  "id": "comparison-ad",
  "name": "Comparison Ad",
  "description": "Side-by-side before/after or us-vs-them comparison",
  "funnel_stage": "MOFU",
  "aspect_ratios": ["9:16", "1:1", "4:5"],
  "duration_range": { "min": 15, "max": 30 },
  "style_params": {
    "camera_movement": "static or slow pan",
    "lighting": "bright, even, clinical",
    "editing_style": "split-screen, wipe transitions"
  },
  "generation_tools": ["kling", "sora", "zimage"],
  "post_production_chain": ["caption:comparison", "brand:logo", "effects:split-screen", "export:all"],
  "agent_assignment": {
    "generate": "dreami",
    "copy": "dreami",
    "post_produce": "video-forge",
    "qa": "scout"
  },
  "requested_by": "scout",
  "source": "competitor analysis of Brand X"
}
```

### list-output-types.sh — List registered output types

```bash
bash ~/.openclaw/skills/workflow-automation/scripts/list-output-types.sh
bash ~/.openclaw/skills/workflow-automation/scripts/list-output-types.sh --funnel TOFU
bash ~/.openclaw/skills/workflow-automation/scripts/list-output-types.sh --tool kling
bash ~/.openclaw/skills/workflow-automation/scripts/list-output-types.sh --funnel MOFU --tool sora
```

### update-skill-registry.sh — Rebuild skill registry

Scans all SKILL.md files, reads frontmatter for agent assignments, and rebuilds skill-registry.json. Run nightly or after skill changes.

```bash
bash ~/.openclaw/skills/workflow-automation/scripts/update-skill-registry.sh
```

## Integration

- **Scout** finds new format via competitor scraping -> pipes JSON to register-output-type.sh
- **Dreami** invents creative format -> pipes JSON to register-output-type.sh
- **Dreami** discovers new visual style -> pipes JSON to register-output-type.sh
- **Taoz** runs update-skill-registry.sh after any skill change
- **Scout** runs update-skill-registry.sh nightly via cron

## Agent Dispatch Examples

```
# Scout discovers a competitor's "reaction video" format
{
  "id": "reaction-video",
  "name": "Reaction Video",
  "description": "Split-screen reaction to trending content with brand commentary",
  "funnel_stage": "TOFU",
  "aspect_ratios": ["9:16"],
  "duration_range": {"min": 15, "max": 60},
  "generation_tools": ["kling", "sora"],
  "post_production_chain": ["caption:tiktok", "effects:split-screen", "brand:watermark", "export:9:16"],
  "requested_by": "scout",
  "source": "competitor analysis — Brand Y TikTok"
}

# Dreami invents a "recipe ASMR" format
{
  "id": "recipe-asmr",
  "name": "Recipe ASMR",
  "description": "Close-up food preparation with amplified sounds, no music, minimal text",
  "funnel_stage": "TOFU",
  "aspect_ratios": ["9:16", "1:1"],
  "duration_range": {"min": 30, "max": 60},
  "style_params": {
    "camera_movement": "extreme-close-up, overhead",
    "lighting": "warm, soft, golden hour",
    "editing_style": "slow, lingering, ASMR"
  },
  "generation_tools": ["kling", "sora"],
  "post_production_chain": ["effects:grain-light,warm", "brand:watermark", "export:all"],
  "requested_by": "dreami",
  "source": "creative invention — ASMR food trend adaptation"
}
```
