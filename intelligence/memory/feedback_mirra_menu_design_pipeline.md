---
name: Mirra Menu Design Pipeline — Hard Rules
description: Design production rules learned from v1-v4 menu iterations. NEVER PIL for design. ALWAYS reference-first. ALWAYS real logo.
type: feedback
---

## Hard Rules for Mirra Menu Design

1. **NEVER use PIL for design/layout** — PIL = logo placement + resize ONLY. All design = NANO.
2. **NEVER erase text from rasterized PDFs** — artifacts always remain, looks terrible.
3. **NEVER use AI-generated logos** — always composite the REAL brand logo PNG.
4. **ALWAYS scrape real references first** — use gallery-dl for Pinterest. Never generate references from prompts alone.
5. **ALWAYS use edit-first technique** — feed reference image + swap text only.
6. **ALWAYS style-lock across pages** — use the first approved page as reference for all subsequent pages.
7. **ALWAYS audit after generation** — compare every dish name, spicy marker, (New) tag against source JSON.

**Why:** v1 (PIL text overlay on erased PDF) was a complete failure — wrong fonts, artifacts, tiny logo. v2-v3 (NANO without reference) produced inconsistent titles and hallucinated content. v4 (NANO edit-first on REF02 + style-lock + proper logo composite) was the first acceptable result.

**How to apply:** For any Mirra menu production, read WORKFLOW.md in `_WORK/mirra-menu-pipeline/` first. Follow the 5-step process. Never skip reference scraping or visual audit.

## NANO-specific rules
- Explicitly list "ONLY Mon-Fri, NO Sat/Sun" or NANO adds weekend rows
- Explicitly say "leave rest EMPTY" for partial weeks or NANO fills with hallucinated dishes
- Explicitly say "ALL plant-based" or NANO invents meat/fish dishes
- Use "ROW 1: ... ROW 2: ..." numbering for dense pages (10+ rows) to prevent merging
- Title styling drifts between pages — use identical style instruction in every prompt
- For consistent titles: one title per page ("APRIL WEEK X & Y") + divider, not separate week headers
