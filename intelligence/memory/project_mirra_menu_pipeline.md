---
name: Mirra Menu Pipeline — Monthly Auto-Menu Production System
description: Full pipeline for monthly menu generation. CSP solver + NANO design + PIL logo. Working dir _WORK/mirra-menu-pipeline/. REF02 editorial style approved. Read WORKFLOW.md first.
type: project
---

## What it is
Autonomous monthly menu pipeline for Mirra plant-based meal subscription.
Working dir: `/Users/yi-vonnehooi/Desktop/_WORK/mirra-menu-pipeline/`

**Why:** Mirra produces a bilingual weekly menu PDF every month. Previously done manually in Canva.
**How to apply:** Run pipeline ~25th of each month. Read WORKFLOW.md in the project root.

## Architecture
1. **Data**: Python CSP solver generates compliant menu (9 rules, 42 slots)
2. **Design**: NANO (Gemini) edit-first on REF02 editorial reference
3. **Composite**: PIL — real MIRRA logo only (15% width, bottom center)
4. **Audit**: JSON compare every dish name vs generated image

## Current State (March 24, 2026)
- April 2026 menu: v4 FINAL approved (3 EN pages)
- CN version: not yet generated
- Design: REF02 editorial magazine style
- Score: 85/100, Grade B, 0 critical violations
- Title format: "Weekly Menu" + "APRIL WEEK X & Y" (all caps) + thin divider between weeks

## Key Learnings (v1→v4)
1. PIL text overlay = ALWAYS BAD for design. Use NANO.
2. Never erase text from rasterized PDFs
3. Never use AI-generated logos — always composite real brand PNG
4. gallery-dl works for Pinterest scraping (WebFetch blocks)
5. Reference = output structure. Need FORMAT-SPECIFIC references.
6. Style-lock: use approved page as reference for subsequent pages
7. NANO hallucinates content in empty space — explicitly say "leave rest EMPTY"
8. Week titles must be locked: same style instruction in every prompt
9. 10-row pages need "tighter spacing" instruction or content gets cut off
10. Logo autocrop needed — source PNG has large whitespace
