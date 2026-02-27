---
name: cso-pipeline
version: "1.0.0"
description: Content Strategy Operation pipeline for GAIA CORP-OS. Replaces n8n CSO workflow with native OpenClaw agent orchestration. Zenni coordinates Artemis, Dreami, Athena, Iris, and Hermes through strategy analysis, content adaptation, and multi-channel publishing.
metadata:
  openclaw:
    scope: orchestration
    guardrails:
      - Always fetch strategy from backend before processing
      - Never skip ANALYSIS step — it is mandatory
      - Never publish without completing ADAPTATION first
      - All progress updates posted to exec room
      - Errors posted to feedback room with FAILED status
      - Strategy status must be updated at each phase transition
---

# CSO Pipeline — Content Strategy Operation

## Purpose

The CSO (Content Strategy Operation) pipeline takes a campaign brief or strategy ID and orchestrates the full content lifecycle: research and analysis, content adaptation for each channel, and multi-channel publishing. It replaces the previous n8n workflow with native OpenClaw agent coordination.

## How It Works

```
Campaign Brief / Strategy ID
        |
        v
  [Fetch Strategy from GAIA Backend]
        |
        v
  [Determine Required Steps]
        |
        +---> IMAGES_ANALYSIS (if attachments exist) --> Dreami
        |
        +---> ANALYSIS (always) -----------------------> Artemis + Athena
        |
        +---> ADAPTATION (always) ---------------------> Dreami
        |
        +---> PUBLISHING (always) ---------------------> Iris + Hermes
        |
        v
  [Strategy Status: COMPLETED]
```

## Agent Mapping

| CSO Step | Agent(s) | What They Do |
|----------|----------|--------------|
| IMAGES_ANALYSIS | Dreami | Analyzes creative prop attachments (images, videos) for brand alignment, quality, and channel suitability |
| ANALYSIS | Artemis + Athena | Artemis researches the market context; Athena analyzes data and produces strategic insights |
| ADAPTATION | Dreami | Rewrites and adapts content for each target channel (IG, TikTok, Shopee, EDM, etc.) |
| PUBLISHING | Iris + Hermes | Iris handles social channels; Hermes handles commerce channels (Shopee, Lazada, website) |

## Triggering the Pipeline

### Option 1: With a Strategy ID

If a strategy already exists in the GAIA backend:

```bash
bash ~/.openclaw/skills/cso-pipeline/scripts/cso-run.sh <strategy_id>
```

### Option 2: With a Campaign Brief

If starting from an idea, brief, or link:

```bash
bash ~/.openclaw/skills/cso-pipeline/scripts/cso-brief.sh "Launch a Valentine's Day vegan gift box campaign targeting Malaysian millennials on IG and TikTok"
```

This creates a new strategy in the backend, then runs the full pipeline.

### Option 3: Via Zenni (WhatsApp or Chat)

Tell Zenni: "Run CSO for strategy 42" or "Create a CSO for: [brief text]"

Zenni will invoke the appropriate script.

## Pipeline Flow — Detailed

### Phase 1: Setup

1. Fetch strategy details from backend: `GET /strategies/{id}`
2. Parse the strategy to extract: title, description, creative props, target channels
3. Check if creative props have attachments (images/videos)
4. Update strategy status to `IN_PROGRESS`

### Phase 2: Steps Creation and Execution

For each required step:

1. **Create the step** via `POST /strategies/{id}/steps` with the step type
2. **Approve the step** via `POST /steps/{step_id}/approve`
3. **Dispatch to the assigned agent** via dispatch.sh
4. **Wait for agent response**
5. **Update strategy progress** via `PATCH /strategies/{id}`

Step execution order:
1. `IMAGES_ANALYSIS` (conditional — only if attachments exist)
2. `ANALYSIS` (always)
3. `ADAPTATION` (always)
4. `PUBLISHING` (always)

### Phase 3: Completion

1. Update strategy status to `COMPLETED`
2. Post summary to exec room
3. Log learnings to feedback room

## API Reference

**Base URL:** `http://ai.gaiafoodtech.com/api/v1/agent`
**Auth Header:** `X-API-Key: oLBye15RiSQt2AyVUNSwHmeglqzIkLHi`

### Endpoints Used

| Method | Path | Description |
|--------|------|-------------|
| GET | `/strategies/{id}` | Fetch strategy details |
| PATCH | `/strategies/{id}` | Update strategy status/progress |
| POST | `/strategies/{id}/steps` | Create a new step for the strategy |
| POST | `/steps/{id}/approve` | Approve a step for execution |
| POST | `/strategies` | Create a new strategy from brief |

### Strategy Status Flow

```
DRAFT --> IN_PROGRESS --> ANALYSIS --> ADAPTATION --> PUBLISHING --> COMPLETED
                                                                        |
                                                                   (or FAILED)
```

### Step Types

| Step Type | Description |
|-----------|-------------|
| `IMAGES_ANALYSIS` | Analyze attached images/videos |
| `ANALYSIS` | Research and data analysis |
| `ADAPTATION` | Content rewriting for channels |
| `PUBLISHING` | Publish to target channels |

## Scripts

### cso-run.sh — Main Pipeline Runner

```bash
bash ~/.openclaw/skills/cso-pipeline/scripts/cso-run.sh <strategy_id>
```

Fetches the strategy, determines steps, creates/approves/executes each step via agent dispatch, and tracks progress through to completion.

### cso-brief.sh — Brief-to-Pipeline

```bash
bash ~/.openclaw/skills/cso-pipeline/scripts/cso-brief.sh "<free_text_brief>"
```

Takes free text (idea, brief, URL) and creates a new strategy in the backend, then hands off to cso-run.sh.

## Error Handling

| Scenario | Action |
|----------|--------|
| API call fails | Retry once after 5s, then mark FAILED and post to feedback room |
| Agent dispatch times out | Log timeout, post to feedback room, continue to next step if possible |
| Strategy not found | Exit with error, post to feedback room |
| Step creation fails | Retry once, then mark strategy FAILED |
| All steps complete but one failed | Mark strategy COMPLETED with notes on partial failure |

## Room Usage

| Room | What Gets Posted |
|------|-----------------|
| `exec` | Pipeline start, phase transitions, completion summary |
| `feedback` | Errors, failures, agent dispatch issues, learnings |
| `creative` | IMAGES_ANALYSIS and ADAPTATION results from Dreami |
| `social` | PUBLISHING results from Iris |

## CHANGELOG

### v1.0.0 (2026-02-13)
- Initial creation: replaces n8n CSO workflow with OpenClaw agent orchestration
- Scripts: cso-run.sh (main pipeline), cso-brief.sh (brief-to-pipeline)
- Agent mapping: Dreami (images/adaptation), Artemis+Athena (analysis), Iris+Hermes (publishing)
- Full API integration with GAIA backend at ai.gaiafoodtech.com
