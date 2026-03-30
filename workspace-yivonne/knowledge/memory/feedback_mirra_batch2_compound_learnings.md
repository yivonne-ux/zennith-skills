---
name: Mirra Batch 2 — Compound Learnings (March 29, 2026)
description: CRITICAL. Every issue found during 37-post batch 2 production. Self-audit findings. Apply to ALL future Mirra and brand-agnostic social production.
type: feedback
---

## BATCH 2 COMPOUND LEARNINGS — SELF-AUDIT

### NEW RULES DISCOVERED

#### 1. CROP DESTROYS EDGE TEXT — The #1 recurring defect
- `crop45()` center-crops to 4:5 ratio, cutting edges
- If NANO renders text near the left/right edges, the crop CUTS IT OFF
- "saving money" becomes "ving money", "SAME CALORIES" becomes "AME CALORIES"
- **FIX:** Add explicit margin instructions to EVERY prompt: "Keep ALL text at least 10% away from all edges. Leave generous margins on all four sides."
- **FIX 2:** After crop, run a text-edge check: if any text touches the crop boundary, flag for regeneration
- This was the single most common defect (hit B2-24, B2-25, B2-28, B2-34)

**Why:** NANO renders at arbitrary aspect ratios. Our crop45 then cuts to 4:5. Text near edges gets sliced.
**How to apply:** Add margin instructions to EVERY prompt. Check post-crop images for edge text cutoff before saving.

#### 2. REFERENCE RESIDUAL TEXT PERSISTS THROUGH EDIT
- Marquee signs, billboards, storefronts have BUILT-IN text that NANO cannot fully remove
- B2-19: "ineari" from original marquee persists even after asking NANO to replace text
- B2-33: "Periods came" from original cat meme reference persists
- **FIX:** For text-heavy references (signs, marquees, billboards), the original text is BAKED IN. Either:
  a. Use refs with MINIMAL or NO original text
  b. Accept the original text will ghost through
  c. Use a GENERATION approach instead of EDIT for these

**Why:** NANO edit preserves structure including embedded text. It can't fully erase complex baked-in text.
**How to apply:** Before using a ref with visible text, assess: can NANO credibly replace ALL of it? If the ref has complex text (marquee letters, neon signs), prefer a cleaner ref.

#### 3. COPYRIGHT-RISK CHARACTERS LEAK FROM REFERENCES
- Pinterest meme refs frequently contain recognizable copyrighted characters (Mean Girls, Bratz, Barbie, Disney)
- NANO PRESERVES these characters when editing — it doesn't know they're copyrighted
- B2-23: Mean Girls character. B2-25: Bratz doll. B2-23 FIX: still generated Barbie-like character
- **FIX:** PRE-SCREEN all scraped references for copyrighted characters BEFORE using them
- Instant-reject refs with: movie screenshots, animated characters, recognizable IP
- Use ONLY: generic lifestyle photos, stock-style images, or original illustrations

**Why:** Scraped Pinterest refs are full of movie stills and copyrighted characters. NANO faithfully reproduces them.
**How to apply:** Add a copyright-screening step to the scrape→classify pipeline. Reject refs with recognizable characters.

#### 4. INAPPROPRIATE CONTENT CAN HIDE IN REFERENCES
- B2-26: A GUN was visible in the reference image, carried through to the output
- The scrape pipeline doesn't filter for inappropriate/unsafe content
- **FIX:** Add safety screening to reference selection. Check for: weapons, violence, nudity, drugs, offensive gestures
- This is a BRAND-CRITICAL issue — one inappropriate post can destroy brand reputation

**Why:** Pinterest refs are unfiltered. Anything can appear in scraped images.
**How to apply:** Visual safety check on EVERY reference before production. Reject refs with any inappropriate elements.

#### 5. AI-GENERATED FOOD vs REAL BENTO PHOTOS
- B2-30 "This or That": NANO generated AI food bowls instead of using real Mirra bento photos
- B2-31 "500 Cal": NANO illustrated the food instead of using the real bento photo
- The "sacred photo" rule was in the prompt but NANO sometimes ignores Image 2 for food posts
- **FIX:** For food comparison/education posts, the REAL bento photo must be composited via PIL, not trusted to NANO
- Use PIL to place the sacred photo, then NANO only for background/text/styling around it

**Why:** NANO sometimes reinterprets Image 2 instead of placing it exactly. Food photos are SACRED and must be pixel-perfect.
**How to apply:** For any post requiring real Mirra bento photos, use PIL composite for the food placement. NANO handles everything else.

#### 6. LOGO OVERLAP — PREDICTABLE, PREVENTABLE
- B2-10 original: logo overlapped "standing on business" text at bottom
- **FIX:** When text is at the bottom, force logo to "tr" (top-right). Check prompt text position against logo position BEFORE generating.
- Build a simple rule: if prompt says "text at bottom" → logo = "tr". If "text at top" → logo = "br" or "bc".

**Why:** Smart logo picks cleanest zone, but if text fills the bottom, "cleanest" might still overlap.
**How to apply:** Add text-position-aware logo routing to the production script.

### WHAT WORKED WELL (KEEP DOING)

1. **Korean webtoon illustrations are CONSISTENTLY high quality** — 10/10 illustrations all passed first round. The style DNA + face render prompts are locked in.
2. **Labeled bento format is reliable** — real photos + pink labels on blush bg is a proven formula. 6/6 passed (after label accuracy fix).
3. **Glitter/billboard format converts well** — glitter text on warm bg is eye-catching and shareable. 4/5 passed.
4. **Multi-layer color grading prompts work** — no "flat overlay" issues in batch 2 (was a major problem in batch 1).
5. **ANTI_BRAND prompt block is effective** — no unwanted brand text leaked in any illustration.
6. **Typography posts with editorial photo refs are strong** — B2-35 and B2-37 both passed first round.
7. **Cat memes with sparkle/bow overlays are consistently cute** — B2-32 was 9.5/10 first try.

#### 7. NEVER REUSE REFERENCES — EVERY POST NEEDS A UNIQUE REF
- B2-17 through B2-21 all used refs from the same `02-glitter-billboard-quote` folder
- User flagged: "you need to always be scrapping for viral/trending/aesthetic posts"
- EVERY post must have its own freshly scraped, unique reference
- Same folder = same aesthetic = same feel = boring repetitive feed
- **FIX:** Scrape MORE references (at least 2x the number of posts needed). Use each ref ONCE only.
- Track which refs have been used — never pick the same one twice
- The IG grid should feel VARIED — each post distinct, never repetitive

**Why:** User wants variety in the feed. Reusing refs from the same folder creates visual monotony.
**How to apply:** Before production, verify: does every post have a UNIQUE ref from a DIFFERENT source? If two posts share a ref folder, scrape more.

#### 8. ASPECT RATIO MUST BE SET IN NANO API CALL
- The `crop45()` function was destructively cropping NANO outputs that came back at wrong aspect ratios
- Text at edges got cut off — "saving money" became "ving money"
- **ROOT CAUSE:** Missing `"aspect_ratio": "4:5"` in NANO API calls
- **FIX:** Always pass `"aspect_ratio": "4:5"` to every NANO call. Then `crop45()` only needs to resize, not crop.
- This was fixed in both `produce_batch2_37.py` and `regen_batch2_fixes.py`

**Why:** Without aspect_ratio param, NANO generates at arbitrary dimensions based on the reference image. Our crop then destroys edge content.
**How to apply:** EVERY NANO API call must include `"aspect_ratio": "4:5"` for IG feed posts.

#### 9. BENTO PHOTOS NEED EDITORIAL ENHANCEMENT BEFORE LAYOUT
- Raw bento photos look dull, flat, and unappetizing
- B2-12 nasi lemak: sambal looks dark, rice looks grey, overall lifeless
- **FIX:** PIL editorial enhancement BEFORE placing into layout:
  - Brightness: +10-15%
  - Warmth: +5% (shift toward golden)
  - Clarity/sharpening: slight increase for texture
  - Subtle vignette for focus
  - Must still look NATURAL — never over-saturated or HDR-fake
- Think food magazine photography — warm, vibrant, appetizing

**Why:** User said "the pic looks dull and the food not enhanced (but still need to look natural, editorial style)"
**How to apply:** Add a PIL `enhance_bento()` function that applies these adjustments to every food photo BEFORE it enters the NANO pipeline.

#### 10. REFERENCE PASSTHROUGH = REJECT
- B2-35: The output IS the scraped reference photo with text overlaid — not transformed
- B2-36: NANO passed the reference through completely unchanged
- If the output is just "reference + text swap" = lazy editing, not brand transformation
- **FIX:** The output must be TRANSFORMED to brand palette. If you can identify the exact ref photo in the output → reject.
- Typography posts especially: the PHOTO CONTENT must be different from the ref, not just text changed

**Why:** User said "this is directly the reference?"
**How to apply:** After generation, compare output to input ref. If visual structure is >80% identical (same photo, same bg, same composition) → reject and regenerate with stronger transformation prompt.

#### 11. COLOR VARIETY ACROSS FEED — NOT ALL SALMON
- Too many posts in batch 2 had identical salmon/coral backgrounds
- Creates monotone feed that looks boring when scrolled
- Mirra palette is BROADER: blush, cream, dusty rose, peach, warm white, cream gold
- **FIX:** Plan color distribution across the batch BEFORE generating. Max 2 consecutive posts with same dominant color.

**Why:** User said "non overly salmon colours for mirra"
**How to apply:** Before production, assign color mood to each post ensuring variety. Track used colors and enforce rotation.

#### 12. COMPARISON POSTS NEED REAL STOCK PHOTOS FOR "OTHER SIDE"
- The non-Mirra side of calorie comparisons (nasi goreng, burger, bowls) was AI-generated = looks fake
- AI food: too perfect, too clean, impossible lighting, plasticky textures
- **FIX:** Source REAL stock photos for comparison "other side" food. Download actual food photography from stock sites (Unsplash, Pexels) or scrape from food delivery apps.
- Use PIL composite to place both real photos into the comparison layout. NANO only for text/styling.

**Why:** User said "i dont want ai looking pic, i want real pic"
**How to apply:** For any comparison post, download real food stock photos first. Place via PIL composite. Never let NANO generate food.

#### 13. ALL 37 POSTS NEED aspect_ratio FIX — NOT JUST THE FLAGGED ONES
- I only regenerated the 24 I flagged, but the other 13 "passing" posts ALSO had crop issues
- B2-02, B2-03, B2-05, B2-06, B2-07, B2-08 all cropped — I missed them because I gave them a pass
- **Rule: When a systemic fix is applied (like aspect_ratio), re-run THE ENTIRE BATCH, not just the flagged posts.**

#### 14. CROSS-CHECK QUOTES AGAINST ALL PREVIOUS BATCHES
- B2-22 "how are you" was already used in batch 1 (D01-2)
- Must maintain a `used_refs.json` log of ALL quotes used across ALL batches
- Before assigning a quote to a new post, check the log
- **Rule: Zero quote reuse across batches. Maintain persistent quote log.**

#### 15. CONTENT CONCEPT VARIETY — NO REPEATING SAME FORMAT
- B2-27 and B2-28 are BOTH "same calories different results" — same concept repeated
- B2-30 and B2-31 are BOTH food volume comparisons — same concept
- B2-35, B2-36, B2-37 are ALL "text on gradient" typography — same format
- **Rule: Every post must have a UNIQUE concept. No two posts in a batch should share the same format-concept pair.**
- Food education needs variety: myth vs truth, portion visual, ingredient spotlight, healthy swap, interactive poll — NOT all "same calories"
- Typography needs variety: torn paper, book page, handwritten note, polaroid — NOT all "text on gradient"

#### 16. FOOD IN COMPARISONS MUST BE REAL MIRRA BENTOS
- Some food in comparison posts was NOT actual Mirra bento photos
- If it's not from the `food-library/` folder, it's not Mirra food
- **Rule: Every food photo labeled as Mirra MUST come from the sacred food library. Period.**

#### 17. SCRAPING NEEDS QUALITY GATE
- Raw Pinterest scrapes include: low-res thumbnails, extreme landscapes, duplicates, irrelevant content
- Unfiltered refs → low-quality outputs
- **Rule: Every scrape must pass quality filter: min resolution 600x600, portrait-friendly aspect, min file size 20KB, no duplicates (perceptual hash), no copyrighted characters.**
- Delete failures immediately — don't let bad refs pollute the library

### PRODUCTION STATS (REVISED after user audit)
- 37 posts produced
- 13 pass 9/10 gate with upgraded standards (35% first-pass rate)
- 24 need regen (65% — much higher standard than self-audit)
- Failure breakdown: text cropped (12), AI food (4), dull food photos (6), same ref reuse (4), reference passthrough (2), copyright (2), residual text (2), inappropriate (1), overly salmon (5), format mismatch (1)
- Key insight: self-audit was too lenient. User standard is MUCH higher.
- FAL cost: ~37 initial + 8 fixes = ~45 NANO calls × $0.15 = ~$6.75 before balance exhausted
