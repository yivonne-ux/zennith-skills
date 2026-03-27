# CLI Integration & Weekly Research Rhythm

## CLI Commands

```bash
# Log a research session
bash scripts/notebooklm-research.sh log \
  --brand mirra \
  --topic "weight management meal trends" \
  --type trend \
  --findings findings.md

# Generate content brief from research handoff
bash scripts/notebooklm-research.sh brief \
  --brand mirra \
  --research handoff-weight-mgmt-trends-2026-01-15.md \
  --content-type "social-campaign" \
  --platform ig \
  --language en

# Search past research across all brands
bash scripts/notebooklm-research.sh search "turmeric benefits"

# Search research for specific brand
bash scripts/notebooklm-research.sh search "protein" --brand pinxin-vegan

# Generate content brief from Pinxin GrabFood optimization research
bash scripts/notebooklm-research.sh brief \
  --brand pinxin-vegan \
  --research handoff-grabfood-optimization-2026-03-20.md \
  --content-type "listing-copy" \
  --platform grabfood \
  --language en,bm

# List all research for a brand
bash scripts/notebooklm-research.sh list --brand rasaya

# List all research by type
bash scripts/notebooklm-research.sh list --type competitor

# Create handoff document interactively
bash scripts/notebooklm-research.sh handoff \
  --brand mirra \
  --notebook "Weight Management Meal Trends 2025" \
  --content-request "Instagram carousel about weight management meals for office workers"

# Show research stats
bash scripts/notebooklm-research.sh stats

# Generate quarterly research summary
bash scripts/notebooklm-research.sh quarterly --quarter Q1-2026
```

## Weekly Research Rhythm

```
┌─────────────┬────────────────────────────────────────────────────────────────┐
│ Day         │ Research Activity                                             │
├─────────────┼────────────────────────────────────────────────────────────────┤
│ Monday      │ Upload new sources: articles from past week, competitor       │
│             │ updates, new market data. Check content-scraper outputs for   │
│             │ auto-collected sources.                                       │
├─────────────┼────────────────────────────────────────────────────────────────┤
│ Tuesday     │ Generate Audio Overviews for key topics. Listen during        │
│             │ commute or lunch. Jot down surprising insights.               │
├─────────────┼────────────────────────────────────────────────────────────────┤
│ Wednesday   │ Extract insights from Audio Overviews and Q&A sessions.       │
│             │ Create handoff documents. Store in research repo.             │
├─────────────┼────────────────────────────────────────────────────────────────┤
│ Thursday    │ Claude content creation day. Feed handoff docs into Dreami    │
│             │ for copy, Taoz for technical content, Iris for visual briefs. │
├─────────────┼────────────────────────────────────────────────────────────────┤
│ Friday      │ Review content performance from previous cycle. Identify      │
│             │ new research gaps. Update research priorities for next week.   │
│             │ Run: bash scripts/notebooklm-research.sh stats                │
└─────────────┴────────────────────────────────────────────────────────────────┘
```

## Monthly Research Priorities Review:

First Monday of each month:
1. Review all brand notebooks — are sources still current?
2. Check which research areas led to best-performing content
3. Identify new research topics based on brand priorities
4. Archive stale notebooks, create fresh ones for new quarter
5. Cross-reference brand research for multi-brand campaign opportunities
6. Update this skill doc if workflow has evolved

## Integration with Other Skills

### Feeds INTO (research outputs become inputs for):
- `content-supply-chain` — research stage of the content loop
- `campaign-planner` — research-backed campaign briefs
- `campaign-translate` — research informs localization context
- `ad-composer` — evidence-backed ad claims
- `content-seed-bank` — research insights become content seeds
- `creative-factory` — research briefs guide creative production
- `social-publish` — research timing informs posting schedule
- `shopee-listing` — competitor research informs listing optimization
- `edm-engine` — research insights fuel email content

### Receives FROM (these skills provide research inputs):
- `content-scraper` — automated source gathering (articles, competitor pages)
- `learn-youtube` — YouTube video transcripts as research sources
- `ads-competitor` — competitor ad data for analysis
- `growth-engine` — performance data feeds back as research topics
- `content-tuner` — content performance signals new research needs

### Complements:
- `rigour` — research handoffs go through rigour gate before becoming published content
- `brand-voice-check` — research-backed content still must match brand voice
- `knowledge-compound` — research findings compound into institutional knowledge

### Storage:
- Research handoffs: `~/.openclaw/workspace/data/research/{brand}/`
- Cross-brand research: `~/.openclaw/workspace/data/research/_cross-brand/`
- Audio Overview transcripts: `~/.openclaw/workspace/data/research/{brand}/audio/`

## NotebookLM API / Programmatic Access

As of early 2026, NotebookLM does not have a public API. The current workflow is **manual notebook management + export -> automated Claude pipeline**.

### Current Workflow (Human-in-the-Loop):
```
Jenn (manual) --> NotebookLM (manual) --> Export (manual) --> Claude Pipeline (automated)
                  - Upload sources            - Copy/paste        - Content creation
                  - Ask questions              - Download           - Brand voice check
                  - Generate Audio Overview    - Save to repo       - Publishing
```

### Future Workflow (When API Available):
```
content-scraper (auto) --> NotebookLM API (auto) --> Export API (auto) --> Claude Pipeline (auto)
- Scheduled scraping          - Auto-upload sources      - Auto-export          - Fully automated
- Competitor monitoring       - Scheduled Audio Overview  - Direct to handoff    - Human review only
- Market data feeds           - Auto-ask research Qs      - Structured JSON      - at publishing stage
```

### Workarounds Until API:
- **Bookmark sources** — keep a running list in `~/.openclaw/workspace/data/research/_sources-queue.md` for batch upload
- **Template questions** — pre-written research questions per brand (see brand-research-playbooks.md) for efficient Q&A sessions
- **Batch export days** — dedicate Wednesday to bulk export and handoff creation
- **Audio Overview transcription** — use WhisperX to transcribe, then Claude to extract insights
