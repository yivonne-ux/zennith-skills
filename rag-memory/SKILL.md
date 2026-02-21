---
name: rag-memory
version: "1.0.0"
description: Structured memory retrieval for GAIA CORP-OS agents. Replaces raw daily memory dumps with tagged facts that can be searched on demand.
metadata:
  openclaw:
    scope: infrastructure
    guardrails:
      - Never delete memory.jsonl without backing up
      - Facts must have agent, type, and text fields
      - Memory file must stay under 10MB
---

# RAG Memory — Structured Agent Memory

## Purpose

Replaces the old "dump 30 conversation turns into daily .md files" approach with a structured fact store. Agents store atomic facts (decisions, insights, learnings) and retrieve them on demand via grep-based search.

## Architecture

```
Agent needs past context
  → calls memory-search.sh "topic keywords"
  → gets top N matching facts (tagged JSONL)
  → injects relevant facts into current prompt

Session reset
  → recall.sh extracts key facts (not raw turns)
  → calls memory-store.sh to save each fact
  → daily .md gets 1-line pointer only
```

## Data Store

`~/.openclaw/workspace/rag/memory.jsonl` — one fact per line:

```json
{"ts":"2026-02-14T10:00","agent":"zenni","type":"decision","tags":["sales","report"],"text":"Sales report runs 4x daily via API key method","importance":8}
```

### Fact Types
- `decision` — A choice that was made (routing, pricing, strategy)
- `insight` — An observation or finding (market trend, performance data)
- `learning` — A lesson learned (bug fix, gotcha, best practice)
- `task` — A pending or completed task
- `content` — A content atom (hook, caption, brief summary)
- `config` — A system configuration change
- `error` — An error pattern and its resolution

### Importance Scale (1-10)
- 10: Critical business decision, irreversible action
- 8: Strategy change, new capability, major insight
- 6: Standard task completion, routine finding
- 4: Minor observation, temporary context
- 2: Ephemeral detail, will decay

## Scripts

### memory-store.sh — Store a fact
```bash
bash memory-store.sh --agent zenni --type decision --tags "sales,report" --text "Sales report runs 4x daily" --importance 8
```

### memory-search.sh — Search for facts
```bash
bash memory-search.sh "sales report"                    # keyword search
bash memory-search.sh "sales" --agent athena             # filter by agent
bash memory-search.sh "pricing" --type decision          # filter by type
bash memory-search.sh "competitor" --limit 3 --recent 7  # last 7 days, top 3
```

### memory-compact.sh — Weekly maintenance
```bash
bash memory-compact.sh                    # deduplicate + decay
bash memory-compact.sh --dry-run          # preview what would change
```
Cron: Sunday 21:00 MYT (after content-tuner)

## Integration

- **Session-recall**: Modified to extract facts and store via memory-store.sh
- **Agent boot**: Agents query memory-search.sh instead of loading daily .md files
- **Room watcher**: Can optionally index room entries as facts
- **All agents**: Can store learnings via memory-store.sh during tasks
