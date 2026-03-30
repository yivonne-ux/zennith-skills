---
name: Viral Wisdom Production Pipeline Learnings
description: Complete YES/NO from PX v1-v4 viral wisdom production. Reference-first, art style lock, format variety, scraping workflow. Brand-agnostic.
type: feedback
---

## VIRAL WISDOM POST PRODUCTION — ALL LEARNINGS (Brand-Agnostic)

### THE PIPELINE (proven order)
1. **Scrape** viral accounts (XHS/IG) using tools (MediaCrawler, x-reader, Instaloader)
2. **Audit scraped refs** — separate legit format posts from junk (selfies, vlogs, mixed content)
3. **Classify by layout type** — map ALL distinct formats (dual-panel, single portrait, action, scene, contrast, dialogue)
4. **Lock character forensic** — exact hair, clothing, accessories, age, face from brand's OWN artwork
5. **Use DIFFERENT scraped ref as Image 1** per layout type (not same ref for all)
6. **Brand artwork as Image 2** (style anchor — the RICH version, not simplified vector sheets)
7. **Generate → Vision audit → Fix → Regenerate**
8. **Each post uses a DIFFERENT layout type** from the taxonomy

### ART STYLE — CRITICAL RULES
- **Use the RICHEST brand artwork** as style ref, not simplified vector character sheets
- Rich painterly > flat vector clipart. If brand has "concept art quality" illustrations, USE THOSE
- The style ref (Image 2) determines rendering quality — weak ref = weak output
- **Why:** v1-v3 used simplified vector character PNG → output looked like Canva clipart. v4 improved but still flat. Pinterest concept art + "Made With Love" = the actual brand quality bar

### CHARACTER LOCK — EVERY DETAIL MATTERS
- Get character details FROM THE USER, not from assumptions
- Hair style (bun vs bob vs long) changes the entire character read
- Ask: "Is this the character?" before generating a full batch
- **YES:** Hair tied in bun (not bob), beret (not headband), no glasses, ~40s
- **NO:** Bob hair (user corrected: it's a bun), round glasses (wrong character), age 55-60 (too old)

### FORMAT VARIETY — NOT ALL SAME LAYOUT
- Viral accounts use 6+ distinct layout types, not just one
- If you copy only 1 format for all posts = looks like template spam, not viral variety
- Map ALL layout types from scraped refs before producing
- Assign DIFFERENT layout type per post in the batch
- **YES:** Mix of dual-panel, single portrait, action/prop, scene+text, contrast, dialogue
- **NO:** All dual-panel top/bottom (v3 mistake — 10 posts same layout)

### SCRAPING — QUALITY OVER QUANTITY
- Scraper grabs EVERYTHING from search results — not all is relevant
- Account operators post mixed content (granny posts + personal vlogs + ads)
- Cover images from search are MORE reliable than clicking into individual posts
- Always AUDIT scraped refs before using as format references
- Delete: selfies, lifestyle vlogs, food reviews, ads. Keep: actual illustrated wisdom posts
- **150 files scraped → only 16 were legit format refs.** 90% was junk.

### CONTENT CONTEXT — NOT JUST "NICE MOM"
- Viral granny accounts have EDGE: sassy, bold, 人间清醒 (clear-headed)
- Content pillars: relationships (sharp advice), boundaries (self-protection), workplace (anti-boss), healing (permission-giving), humor (observational wit)
- Props add personality: wine glass, walking stick, cigarette, crystal ball, boxing gloves
- Character should have ATTITUDE, not just warmth
- **NO:** All posts = "family dinner is nice" energy. Too safe, too generic.
- **YES:** Mix of sassy, tender, funny, sharp, healing

### REFERENCE-FIRST — NEVER FROM IMAGINATION
- Image 1 = scraped viral post (FORMAT/COMPOSITION template)
- Image 2 = brand's own artwork (ART STYLE anchor)
- Prompt = describes WHAT to generate using Image 1's layout + Image 2's rendering
- NEVER generate from text description alone — the layout WILL be wrong
- **Why:** v1-v2 had wrong layouts because I described the format in text. v3 used actual scraped ref as Image 1 → layout immediately matched.

### SCRAPING TOOLS (Python 3.9 vs 3.12)
- MediaCrawler + XHS-Downloader need Python 3.10+ (match/case syntax)
- Use `uv venv --python 3.12` to create compatible venvs
- x-reader works for XHS with browser session login (`x-reader login xhs`)
- Instaloader works on Python 3.9 for public IG profiles (no login needed)
- instagrapi needs Python 3.10+ (union type syntax)
- browser_cookie3 can extract cookies from Chrome but may only get partial cookies
- MediaCrawler CDP mode uses SEPARATE browser profile — user's Chrome login doesn't carry over

### DUAL-LAYER AUDIT
- Layer 1: Programmatic (Laplacian variance for blank zones, logo count, color saturation)
- Layer 2: Vision AI (character consistency, brand text, vegan compliance, production readiness)
- Without API credits, use own vision via Read tool — but be STRICT, not lenient
- Art style mismatch = FAIL, not "close enough"

### NANO STYLE LOCK — THE BREAKTHROUGH (v5)
- **Image 1 DOMINATES art style.** Whatever you pass as Image 1, NANO copies its rendering.
- If Image 1 = scraped granny post (ink wash) → output = ink wash. WRONG.
- If Image 1 = brand's own approved output → output = brand style. CORRECT.
- **PROVEN FORMULA:** Image 1 = PX-W1-03-charV.png, Image 2 = aunty uncle vector character.png
- Standard NANO call (NO "resolution": "2K" override — that changed the output)
- Prompt in Chinese (治愈系插画 descriptions)
- Grain = 0.028
- Viral layout described in PROMPT TEXT only — NEVER as image input

### EYE STYLE — #1 INDICATOR OF ART STYLE MATCH
- CORRECT: Soft curved arcs, often CLOSED or half-closed. Simplified. Small relative to face.
- WRONG: Fully open realistic eyes with iris/pupil/catchlight. Anime-sized. Disney/Pixar.
- If eyes look like a 20-year-old → character is too young. Must look ~40.
- Check eyes FIRST in every audit. Eyes wrong = entire output wrong.

### CHARACTER DETAILS THAT WERE CORRECTED
- Hair = BUN (not bob) — user corrected this explicitly
- No glasses — earlier versions had glasses, user removed
- Age ~40 (not 55-60) — user's "Made With Love" artwork showed younger mother
- Beret (not thin fabric headband) — user's reference showed cap/beret style

### FOLDER HYGIENE
- Keep only PRODUCTION files in main folders
- Move ALL old iterations to `_rejected/` immediately after new batch approved
- Name rejected folders by version: `_rejected/viral-v1-v4/v1/` etc.
- Style tests go to `_rejected/style-tests/`
- Never leave 90+ junk files alongside 12 production files

**How to apply:** Run this checklist before ANY viral content production batch. Every step is non-negotiable.
