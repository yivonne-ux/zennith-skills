---
name: notebooklm-research
description: Deep research pipeline using Google NotebookLM for source analysis and knowledge synthesis, feeding into Claude for content creation. Research → Synthesize → Create → Publish.
agents: [taoz, dreami]
version: 1.0.0
---

# NotebookLM Research — Deep Research Pipeline for Content Creation

**Concept:** NotebookLM does research, Claude writes content.

Google NotebookLM is our **research engine**. It ingests sources (PDFs, websites, YouTube, Google Docs), synthesizes knowledge, and surfaces insights. Claude takes that synthesized knowledge and creates brand-aligned content. This is a human-in-the-loop skill — Jenn manages NotebookLM notebooks, exports feed into the automated Claude pipeline.

## Why NotebookLM + Claude (not just Claude alone)?
- NotebookLM is grounded in YOUR uploaded sources — no hallucination risk on factual claims
- Ideal for evidence-based content (health claims, ingredient science, market data)
- Audio Overview surfaces unexpected angles a text prompt never would
- NotebookLM is free — zero cost research before spending tokens on content creation
- Persistent notebooks build institutional knowledge over time

## Pipeline Architecture

```
SOURCES → NotebookLM (research/synthesis) → Export → Claude (content creation) → Brand Content
   ↑                                                                                    |
   └──────────────── content performance feeds back as new research topics ──────────────┘
```

## Pipeline Steps

```
INPUT: Research topic + brand name + content type needed
STEP 1: Create/open NotebookLM notebook for topic
STEP 2: Upload 5-20 high-quality sources (PDFs, URLs, YouTube)
STEP 3: Generate Audio Overview for deep synthesis
STEP 4: Ask targeted research questions in NotebookLM
STEP 5: Export findings (study guide, FAQ, briefing doc)
STEP 6: Create handoff document for Claude
STEP 7: Claude creates brand content from research
STEP 8: Log research to ~/.openclaw/workspace/data/research/{brand}/
OUTPUT: Research handoff document + brand content drafts
```

## Research Types by Use Case

| Use Case | Sources to Upload | NotebookLM Output | Claude Creates |
|----------|-------------------|-------------------|----------------|
| Competitor Research | Competitor websites, ads, social profiles | Competitive analysis summary | Strategy brief, counter-positioning copy |
| Trend Research | Industry articles, trend reports | Trend synthesis, timing signals | Content calendar, viral hooks |
| Product Research | Scientific papers, NPRA guidelines | Evidence-based claims, FAQ | Product descriptions, health claims |
| Audience Research | Survey data, reviews, social listening | Audience insights, pain points | Persona-targeted ad copy |
| SEO Research | Top-ranking content, SERP analysis | Content gaps, keyword clusters | SEO-optimized blog posts |
| Recipe/Menu R&D | Food blogs, nutrition databases | Recipe inspirations, nutritional breakdowns | Brand recipes, menu descriptions |
| Health/Wellness Claims | PubMed papers, clinical studies | Evidence summaries, compliance flags | Compliant health marketing copy |
| Campaign Planning | Past campaign data, seasonal trends | Campaign themes, timing insights | Full campaign briefs |
| Brand Positioning | Category reports, competitor DNA | White space analysis | Brand messaging frameworks |

## Core Workflow

### 1. Setup Notebooks
Naming convention: `[Brand] — [Topic] [Quarter/Year]`
> Load `references/notebook-setup-sop.md` for full notebook organization, source ingestion protocol, and quality sources guide.

### 2. Audio Overview
Generate ~10 min podcast-style deep dives for complex topics. Always use for pre-campaign research and cross-brand analysis. Skip for simple fact-finding.
> Load `references/audio-overview-guide.md` for Audio Overview workflow, customization tips, and content pipeline.

### 3. Export & Handoff
Save handoff to `~/.openclaw/workspace/data/research/{brand}/handoff-{topic}-{date}.md`
> Load `references/handoff-templates.md` for full and quick handoff templates, export format guide.

### 4. Brand-Specific Research
Each brand has priority research areas, suggested NotebookLM questions, and research-to-content examples.
> Load `references/brand-research-playbooks.md` for all brand playbooks (Mirra, Pinxin, Rasaya, Dr. Stan, Wholey Wonder, Serein, Gaia Eats, Creative Brands).

### 5. Compound Learning
Research compounds over time. Never delete notebooks. Add performance data back. Cross-reference notebooks.
> Load `references/compound-learning.md` for repository structure, tagging, and quality checklist.

## CLI Quick Reference

```bash
bash scripts/notebooklm-research.sh log --brand <brand> --topic "<topic>" --type <type> --findings findings.md
bash scripts/notebooklm-research.sh brief --brand <brand> --research <handoff-file> --content-type "<type>" --platform <platform>
bash scripts/notebooklm-research.sh search "<query>" [--brand <brand>]
bash scripts/notebooklm-research.sh list --brand <brand>
bash scripts/notebooklm-research.sh stats
```

> Load `references/cli-and-scheduling.md` for full CLI examples, weekly rhythm, monthly review, skill integrations, and API status.

## Storage Paths

- Research handoffs: `~/.openclaw/workspace/data/research/{brand}/`
- Cross-brand research: `~/.openclaw/workspace/data/research/_cross-brand/`
- Audio Overview transcripts: `~/.openclaw/workspace/data/research/{brand}/audio/`
