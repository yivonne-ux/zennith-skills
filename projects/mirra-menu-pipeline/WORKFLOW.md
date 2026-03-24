# Mirra Monthly Menu Production Pipeline

## Overview
Autonomous monthly menu generation: data → design → audit → export.
Produces bilingual (EN/CN) PDF menus for Mirra plant-based meal subscription.

## Architecture
```
[1] DATA LAYER (Python CSP)
    Google Sheet / xlsx → Dish Database → CSP Solver → Compliance Audit → Menu JSON
    
[2] DESIGN LAYER (NANO + Reference)
    Pinterest scrape → Reference audit → NANO edit-first → PIL logo composite → Vision audit
    
[3] OUTPUT
    EN PDF (3 pages) + CN PDF (3 pages) + JSON data export
```

## Monthly Workflow (run on ~25th of each month for next month)

### Step 1: Update Data
- Download latest Google Sheet: `https://docs.google.com/spreadsheets/d/1WzYlUHu0pttd7hlAoJNNVy9gzAcgbNe-826jJ1CurhM/export?format=xlsx`
- Update `src/data/dish_database.py` with any new dishes
- Update `get_march_2026_entries()` → `get_previous_month_entries()` with CURRENT month's actual menu
- Set holidays for target month (check Malaysian public holidays)

### Step 2: Generate Menu Data
```bash
cd ~/Desktop/_WORK/mirra-menu-pipeline
python3 run_pipeline.py generate --month YYYY-MM
```
- CSP solver generates compliant menu (42 slots, 21 days)
- Logic auditor checks all 9 rules
- Outputs: `output/mirra_menu_YYYY-MM.json`

### Step 3: Design Production
1. **Reference**: Use `reference/scraped/ref02_editorial_mag.png` as base style
2. **Style lock**: Use most recent approved page as NANO reference (preserves consistency)
3. **Generate pages**: NANO edit-first, 3 pages (Weeks 1&2, 3&4, 5)
4. **Logo composite**: PIL — real MIRRA logo, 15% width, bottom center
5. **CN version**: Same process with Chinese dish names

### Step 4: Audit
- Visual audit: compare every dish name on generated images vs source JSON
- Check: spicy markers, (New) tags, day labels, week titles
- Check: consistent title styling across all pages
- Check: MIRRA logo visible, not overlapping content
- Check: no hallucinated days (especially partial weeks)

### Step 5: Export
- Final PDF: `output/mirra_menu_YYYY-MM_FINAL.pdf`
- Individual PNGs: `output/april_v4_final_p1.png` etc.
- JSON data: `output/mirra_menu_YYYY-MM.json`

## Key Files
```
run_pipeline.py                     — CLI entry point
src/data/models.py                  — all data models
src/data/dish_database.py           — dish DB + previous month data
src/planner/slot_builder.py         — Mon-Fri slot builder
src/planner/constraint_checker.py   — 9 compliance rules
src/planner/backtracker.py          — CSP solver
src/planner/master_scheduler.py     — orchestrator
src/auditor/logic_auditor.py        — compliance audit
src/design/nano_renderer.py         — NANO (Gemini) image generation
reference/scraped/ref02_editorial_mag.png  — approved design reference
```

## 9 Compliance Rules
1. Date Verification — Mon-Fri only, no gaps
2. Dish Rotation — 14d within, 21d cross-month, max 2x/month
3. Meal Alternation — Cross-month dishes flip L↔D
4. Spice Distribution — No consecutive same-type spicy
5. Cuisine Variety — 4+ cuisines/week, no cuisine >3x/week
6. New Products — 3-4 NEW dishes, Weeks 2-4 only
7. Month Transition — Last week prev ≠ first week curr
8. Documentation — All markers present
9. Base Ingredient — Min 2 non-rice per week

## Design Rules (CRITICAL)
- NEVER use PIL for design work — PIL = logo + resize ONLY
- NEVER use AI-generated logos — always composite real brand PNG
- ALWAYS use gallery-dl for Pinterest scraping (WebFetch blocks)
- ALWAYS use edit-first technique with approved reference
- Title format: "Weekly Menu" (italic serif) + "APRIL WEEK X & Y" (all caps tracking)
- Divider between weeks: thin decorative line, NOT a second title
- MIRRA logo: 15% page width, bottom center, from Mirra Branding/Logo/
- Reference = output structure — use FORMAT-SPECIFIC references

## API Keys
- Gemini (NANO): GOOGLE_API_KEY in `Creative Intelligence Module/.env`
- Model: gemini-3-pro-image-preview (Nano Banana Pro)
- Pinterest scraping: gallery-dl at ~/Library/Python/3.9/bin/gallery-dl

## Brand Assets
- Logo black: `~/Library/CloudStorage/GoogleDrive-love@huemankind.world/My Drive/Mirra/Mirra Branding/Logo/Mirra logo-black.png`
- Logo white: same folder, Mirra logo-white.png
- Google Sheet: `1WzYlUHu0pttd7hlAoJNNVy9gzAcgbNe-826jJ1CurhM`
- Existing menus: `~/Library/CloudStorage/.../Mirra/Content/Mirra Reply SOP/Weekly Menu List/`
