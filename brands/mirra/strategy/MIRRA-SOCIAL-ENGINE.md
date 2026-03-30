# MIRRA SOCIAL MEDIA PRODUCTION ENGINE
## Autonomous Loop System — v1.0 (March 28, 2026)

---

## READ THIS FIRST — SESSION HANDOFF

When starting a new session, read these files IN ORDER:
1. `~/.claude/projects/-Users-yi-vonnehooi/memory/MEMORY.md` — master index
2. `~/.claude/projects/-Users-yi-vonnehooi/memory/feedback_mirra_brand_specific_learnings.md` — Mirra brand rules
3. `~/.claude/projects/-Users-yi-vonnehooi/memory/feedback_social_production_universal_learnings.md` — 15 universal rules
4. `~/.claude/projects/-Users-yi-vonnehooi/memory/feedback_visual_audit_6layer.md` — 7-layer audit gate
5. `~/.claude/projects/-Users-yi-vonnehooi/memory/feedback_copy_not_imagine_quotes.md` — copy not imagine rule
6. `~/.claude/projects/-Users-yi-vonnehooi/memory/feedback_mirra_42post_production_audit.md` — all yes/no from production
7. This file — current state + next actions

---

## CURRENT STATE

**Volume:** 6 posts/day target (up from 3)
**Posts produced:** 84 total (47 batch 1 + 37 batch 2)
**Batch 1:** 47 posts — scheduled March 28 — April 10
**Batch 2:** 37 posts — 28 pass 9/10 gate, 9 need regression (FAL balance exhausted)
**Schedule:** March 28 — April 17, 2026
**Posting times:** 8am, 10am, 12pm, 3pm, 6pm, 9pm MYT

**Approved formats (proven):**
- Korean webtoon illustrations (viral format refs) — 12 posts ✓
- Glitter/billboard/marquee (COPIED viral quotes) — 3 posts ✓
- Labeled "WHAT'S INSIDE" bento breakdowns — 6 posts ✓
- Calorie volume comparison (1 meal = 2 bentos) — 2 posts ✓
- Premium flat-lay (Daily Dose format) — 1 post ✓
- Casual desk "rate my lunch" — 1 post ✓
- Cat memes with sparkle — 2 posts ✓
- Real photo with pink labels (baguette format) — 1 post ✓
- Pop culture memes (edit-first) — 3 posts ✓
- Handwritten note/card — 2 posts ✓
- Pink cafe A-board (real prop) — 1 post ✓
- Copied tweet on blush bg (@mytherapistsays format) — 1 post ✓

**Rejected formats (never repeat):**
- Pretty bento + generic poetic copy ("comfort in a box")
- Product showcase grids ("your week sorted")
- AI-generated food photos (must use REAL Mirra bentos)
- Dark/moody color grading
- Sage/green/nature backgrounds
- Imagined quotes (must COPY from viral posts)
- Same-calories comparison where Mirra TIES (must WIN — 1 meal = 2 bentos)
- "Frozen food" framing (Mirra is delivery, not frozen)

---

## THE PRODUCTION LOOP

### Stage 1: SCRAPE
```
Sources:
- Pinterest: search trending keywords
- IG: @mytherapistsays, @betches, @thegoodquote, @werenotreallystrangers,
  @thewritersfeelings, @girlzzzclub, @girlyzar, @subliming.jpg
- Web: trending food education, viral formats, calorie comparisons
- XHS: RedNote for Asian viral trends (installed, needs init)

Tools:
- gallery-dl --cookies-from-browser chrome "<url>" -D <output_dir> --range 1-N
- instaloader (for profiles with rate limits)
- WebSearch for trending topics

Output: raw refs in 04_references/curated/17-fresh-viral-scrape/
```

### Stage 2: CLASSIFY REFERENCE
For each scraped ref, classify:
```
Type A: TEXT ONLY — the quote/copy IS the content (tweet screenshot, @thegoodquote)
  → Edit-first: use ref as format, swap text to COPIED viral quote, Mirra palette

Type B: TEXT + VISUAL — both the image and text matter (labeled photo, comparison)
  → Edit-first: keep the real photo, swap/add text, Mirra color grade

Type C: VISUAL ONLY — the image IS the content (food flat-lay, aesthetic scene)
  → Edit-first: swap visual elements, keep format structure, Mirra palette

Type D: FORMAT TEMPLATE — the LAYOUT is the content (comic panels, split comparison)
  → Generation: describe layout in TEXT, use style ref as Image 1
```

### Stage 3: PRODUCE
```
Pipeline per post:
1. Select viral ref (from scrape)
2. Classify ref type (A/B/C/D)
3. Write prompt:
   - ANTI_BRAND block
   - COPIED viral quote (never imagined)
   - Multi-layer color grading (shadows/midtones/highlights)
   - BRIGHT warm Mirra palette
   - Sacred photo preservation (if using real Mirra bentos)
4. NANO API call (edit or generate)
5. Post-process: crop45 → grain → smart_logo PIL
6. Save to 06_exports/social/
```

### Stage 4: AUDIT (7-Layer Gate — minimum 9/10)
```
Layer 1: TEXT INTEGRITY — no garbled, no residual, no typos
Layer 2: IMAGE-COPY MATCH — visual serves the copy
Layer 3: COLOR GRADING — multi-layer, not flat, BRIGHT
Layer 4: VIRAL HOOK — would someone DM this? COPY not imagined?
Layer 5: FORMAT MATCH — correct format executed
Layer 6: BRAND CONSISTENCY — Mirra palette, blush bg, vegan
Layer 7: VALUE CHECK — purpose, meaning, not empty

Score < 9/10 → REGRESSION:
  - Log reason of failure
  - Identify which layer failed
  - Compound learning: what to avoid next time
  - Regenerate with fix
  - Re-audit
  - Loop until 9/10+
```

### Stage 5: USER GATE
```
Present batch to user with:
- Each post image
- Score breakdown
- Source ref (which viral post it's copied from)
- Any flags

User can:
- Approve → proceed to schedule
- Flag issues → compound learning + regression
- Add knowledge → save to memory files
```

### Stage 6: COMPOUND LEARNING
```
After every user interaction:
1. Save ALL yes/no to feedback_mirra_42post_production_audit.md
2. Update feedback_visual_audit_6layer.md if new rule discovered
3. Update feedback_social_production_universal_learnings.md if brand-agnostic
4. Update feedback_mirra_brand_specific_learnings.md if Mirra-only
5. Update this file (MIRRA-SOCIAL-ENGINE.md) with current state

The system gets SMARTER every round. No mistake repeated twice.
```

---

## HANDOFF TEMPLATE (for new sessions)

```
You are continuing Mirra social media production.

READ FIRST:
- ~/Desktop/_WORK/mirra/MIRRA-SOCIAL-ENGINE.md (this file — current state + system)
- All memory files listed in "READ THIS FIRST" section above

CURRENT OBJECTIVE: [what to do next]
LAST COMPLETED: [what was done in previous session]
NEXT ACTION: [specific next step]

RULES:
- COPY viral quotes, never imagine
- SCRAPE → CLASSIFY → PRODUCE → AUDIT (9/10 min) → USER GATE → COMPOUND LEARN
- Multi-layer color grading (never flat)
- Real Mirra bentos = SACRED photos
- Mirra bg = blush/cream/coral ONLY
- BRIGHT and WARM always
- Every post must have PURPOSE (viral hook, education value, or emotional trigger)
- All labels must be ACCURATE (verify ingredient names with user)
```

---

## NEXT BATCH NEEDED

**Target:** 6 posts/day × 14 days = 84 posts total
**Already produced:** 47
**Still needed:** 37 more posts

**Format mix for remaining 37:**
- ~10 more illustrations (viral format refs, trending concepts)
- ~6 more labeled bentos (different dishes)
- ~5 more glitter/billboard/marquee (COPIED viral quotes)
- ~5 more edit-first lifestyle/meme (scraped refs)
- ~5 more calorie comparisons / food education
- ~3 more cat memes
- ~3 more typography (COPIED quotes, real viral refs)

**Posting times for 6/day:** 8am, 10am, 12pm, 3pm, 6pm, 9pm MYT
