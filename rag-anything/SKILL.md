---
name: rag-anything
description: >
  Multimodal RAG pipeline powered by RAGAnything + LightRAG. Ingests PDFs, images,
  tables, equations, Office docs, and web pages into a persistent knowledge graph.
  Query with natural language. Designed for brand research (Athena) and content
  reference (Dreami). Python venv at ~/.openclaw/venvs/rag-anything.
metadata:
  clawdbot:
    emoji: 🧠
    requires:
      bins: [python3]
      paths: ["~/.openclaw/venvs/rag-anything"]
    agents: [athena, dreami]
---

# RAG-Anything — Multimodal Knowledge Graph for GAIA

**Package:** `raganything` + `lightrag-hku`
**Venv:** `~/.openclaw/venvs/rag-anything`
**GitHub:** https://github.com/HKUDS/RAGAnything

RAG-Anything turns any document (PDF, image, table, web page) into a queryable
knowledge graph. Unlike plain vector search, it builds a GRAPH of relationships —
so "what does Brand X say about sustainability" returns actual connected insights,
not just chunks.

---

## When to Use (Agent Guide)

| Agent | Use Case |
|-------|----------|
| **Athena** | Ingest brand reports, competitor docs, strategy PDFs → query for insights |
| **Dreami** | Ingest brand DNA, style guides, reference content → query for copy angles |
| **Taoz** | Ingest codebase docs, API references → query during builds |

---

## Setup (one-time per working directory)

Each knowledge base lives in its own directory. Create one per brand or project:

```bash
mkdir -p ~/.openclaw/workspace/rag-kb/pinxin
mkdir -p ~/.openclaw/workspace/rag-kb/wholey-wonder
# etc.
```

---

## Ingesting Documents

### Ingest a PDF or file
```python
#!/usr/bin/env python3
# ~/.openclaw/skills/rag-anything/scripts/ingest.py
import asyncio, sys, os
from raganything import RAGAnything

async def ingest(file_path: str, kb_dir: str):
    rag = RAGAnything(working_dir=kb_dir)
    await rag.ainsert_file(file_path)
    print(f"✅ Ingested: {file_path} → {kb_dir}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python ingest.py <file_path> <kb_dir>")
        sys.exit(1)
    asyncio.run(ingest(sys.argv[1], sys.argv[2]))
```

Run it:
```bash
~/.openclaw/venvs/rag-anything/bin/python \
  ~/.openclaw/skills/rag-anything/scripts/ingest.py \
  ~/path/to/brand-report.pdf \
  ~/.openclaw/workspace/rag-kb/pinxin
```

### Ingest a URL (web page)
```bash
# Fetch as text first, then ingest
curl -s "https://example.com/article" | \
  ~/.openclaw/venvs/rag-anything/bin/python \
  ~/.openclaw/skills/rag-anything/scripts/ingest_text.py - \
  ~/.openclaw/workspace/rag-kb/pinxin
```

---

## Querying

### Run a query
```python
#!/usr/bin/env python3
# ~/.openclaw/skills/rag-anything/scripts/query.py
import asyncio, sys
from lightrag import LightRAG, QueryParam
from lightrag.llm.openai import openai_complete_if_cache, openai_embed

async def query(question: str, kb_dir: str, mode: str = "hybrid"):
    rag = LightRAG(working_dir=kb_dir)
    result = await rag.aquery(question, param=QueryParam(mode=mode))
    print(result)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python query.py '<question>' <kb_dir> [mode]")
        sys.exit(1)
    mode = sys.argv[3] if len(sys.argv) > 3 else "hybrid"
    asyncio.run(query(sys.argv[1], sys.argv[2], mode))
```

```bash
~/.openclaw/venvs/rag-anything/bin/python \
  ~/.openclaw/skills/rag-anything/scripts/query.py \
  "What are the brand values and tone of voice?" \
  ~/.openclaw/workspace/rag-kb/pinxin
```

### Query modes
| Mode | Use When |
|------|----------|
| `naive` | Simple chunk retrieval — fast, good for exact facts |
| `local` | Entity-focused — good for specific people/products/terms |
| `global` | Theme-focused — good for strategic overviews |
| `hybrid` | **Default** — best balance for brand research |

---

## GAIA Brand Knowledge Bases

Standard paths:
```
~/.openclaw/workspace/rag-kb/
  pinxin/         ← Pinxin Vegan KB
  wholey-wonder/  ← Wholey Wonder KB
  mirra/          ← MIRRA KB
  rasaya/         ← Rasaya KB
  gaia-eats/      ← Gaia Eats KB
  dr-stan/        ← Dr Stan KB
  serein/         ← Serein KB
  competitors/    ← Competitor intelligence
  market-research/ ← General market docs
```

---

## Athena Workflow — Brand Research

```bash
# 1. Ingest a new brand report
~/.openclaw/venvs/rag-anything/bin/python \
  ~/.openclaw/skills/rag-anything/scripts/ingest.py \
  ~/Downloads/pinxin-market-report-2026.pdf \
  ~/.openclaw/workspace/rag-kb/pinxin

# 2. Query for strategic insights
~/.openclaw/venvs/rag-anything/bin/python \
  ~/.openclaw/skills/rag-anything/scripts/query.py \
  "What are the key growth opportunities for a vegan brand in Malaysia?" \
  ~/.openclaw/workspace/rag-kb/pinxin hybrid

# 3. Use output in strategy report → post to exec room
```

## Dreami Workflow — Content Research

```bash
# 1. Query brand DNA KB before writing copy
~/.openclaw/venvs/rag-anything/bin/python \
  ~/.openclaw/skills/rag-anything/scripts/query.py \
  "What emotional hooks resonate with our target audience?" \
  ~/.openclaw/workspace/rag-kb/pinxin hybrid

# 2. Use output as copy brief context
```

---

## Notes
- LLM calls go through your configured OpenAI-compatible API (OpenRouter)
- Set `OPENAI_API_KEY` and `OPENAI_API_BASE` if using OpenRouter
- First query on a new KB builds the graph — may take 30-60s depending on doc size
- Graphs persist across sessions in the `kb_dir` directory
