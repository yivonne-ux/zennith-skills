---
name: Mirra Social Media Engine — FINAL LOCKED (March 28, 2026)
description: CRITICAL. Complete social media production system. Every yes/no from full calibration session. 14 format families, edit-first pipeline, color ratio, grain, logo, sparkle forensic, content philosophy. READ FIRST for any Mirra social work.
type: feedback
---

## MIRRA SOCIAL MEDIA ENGINE — FINAL LOCKED

### THE NORTH STAR
"Would I follow this page if I didn't know it was a food brand?"
This is NOT an ads page. This is a lifestyle brand page people WANT to follow.
Mirra is present through aesthetic + logo, NEVER through pricing/CTAs/health claims.

---

### ✅ YES — What Works

**Content philosophy:**
1. Engagement-first, NOT conversion-first. Follow > Save > Share > Viral.
2. 70% pure lifestyle/humor, 20% food (educational/aesthetic), 10% brand presence
3. Reference-first: scrape viral/trending → edit/regenerate → Mirra vibes
4. 14 format families (not just illustration)
5. Content from actual viral research + Mirra's Pinterest boards + IG scraping
6. ZERO pricing, ZERO CTAs, ZERO health claims in organic posts

**Format families (14 proven):**
- A. Real photo + quote overlay + Mirra color grade
- B. Pink framed art/poster with quote
- C. Illustrated girl + quote (Korean webtoon ONLY)
- D. Cat/pet meme + sparkle
- E. Pop culture still/movie meme + caption
- F. Bold editorial typography on texture
- G. Dictionary definition format
- H. Handwritten note/card held up
- I. Real-world retro object with text (flip phone, balloon, mirror)
- J. Labeled photo meme (pink labels at angles on objects)
- K. Food education infographic/grid (vegan only)
- L. Myth vs Truth split comparison
- M. Crystal ball / manifesting illustration
- N. Checklist / checkbox format

**Edit pipeline (for photo-based posts — majority):**
1. Take reference image (from Pinterest, IG scrape, or viral source)
2. NANO edit-first: swap text to Mirra voice + color grade to Mirra mood
3. Post-process: crop-to-fit 4:5 + grain + PIL smart logo
4. Done. Do NOT regenerate the scene — edit the reference.

**Illustration pipeline (for illustrated posts — ~15%):**
1. Find viral illustrated reference for LAYOUT
2. Use Korean webtoon style ref for ART STYLE
3. NANO generation mode (aspect_ratio 4:5)
4. Post-process: crop-to-fit + grain 0.028 + PIL smart logo
5. ALL illustrations MUST be Korean webtoon style (warmcorner.ai/gunelisa)

**Color ratio for grid:**
- ~55-60% Mirra signature tones (blush, dusty rose, salmon, coral, Mirra pink — NOT neon hot pink)
- ~25% Warm neutrals (cream, gold, taupe)
- ~15% Accent (sage, burgundy)
- Grid should FEEL Mirra when scrolled — brand recognizable without monotone

**Mirra's SPECIFIC pink is NOT neon hot pink.** It's:
- Blush #F8BECD
- Dusty rose #EBAABD
- Salmon #F7AB9F
- Deep salmon #E88A7E
- Crimson #AC374B (accent, not dominant)
- NOT #FF69B4 or #E84887 (too neon)

**Grain levels:**
- Real photo posts: 0.025 (visible film grain)
- Illustration posts: 0.028
- Typography/graphic posts: 0.020
- Always add grain — it's Mirra's signature texture

**Sparkle forensic (3 types — NEVER big vector stars):**
1. Micro-glitter dust: thousands of 1-3px bright specks (for typography bg, glam photos)
2. Soft bokeh: 5-15px warm round dots, concentrated on subject (for cat/object photos)
3. Thin cross: 8-20px crisp + shapes, sparse (for lifestyle overlay)
- NEVER use big 20-40px diamond/star vector shapes

**Logo placement:**
- PIL smart placement: BR, BL, BC — detect cleanest zone
- Black logo on light backgrounds, white logo on dark
- 110px wide, subtle
- NANO renders ZERO brand text (strongest anti-brand prompt)
- If illustration has NANO-rendered "MIRRA", skip PIL (single logo rule)

**Food rules:**
- ALL food in illustrations must be plant-based/vegan
- No meat, no egg, no dairy, no fish visible EVER
- If using actual Mirra bento: cream 3-compartment tray, pink rice, samosa, curry, greens
- Food education posts = genuine value, NOT product promotion
- Aesthetic food = poetic copy ("comfort in a box"), NO pricing

---

### ❌ NO — What Fails

1. ❌ All illustration grid — need 14 format families, not just 1
2. ❌ NANO edit mode for illustrations — use generation mode
3. ❌ Layout ref as image input — describe layout in TEXT, keep only style ref as image
4. ❌ Big vector sparkle stars (✦) — Mirra uses micro-glitter dust, not vector shapes
5. ❌ Neon hot pink — Mirra's pink is MUTED (blush/dusty rose/salmon)
6. ❌ Pricing in organic posts ("from rm19") — that's ads
7. ❌ CTAs ("text us on whatsapp") — that's ads
8. ❌ Health claims ("380 cal") — that's ads
9. ❌ Over-editing references — KEEP the photo, swap text only, color grade, grain
10. ❌ Generic cartoon/clip art illustrations — MUST be Korean webtoon style
11. ❌ Imagined content from scratch — scrape viral refs first, always
12. ❌ All same pink — need color variety (55% pink + 25% neutral + 15% accent)
13. ❌ Weak grain — need visible film grain on all posts, stronger on photos (0.025)
14. ❌ Disney/Pixar face on illustrations — mature Korean face, 26yo
15. ❌ Curly ringlets hair — straight-wavy Korean idol hair
16. ❌ Faceless illustrations — ALWAYS specify explicit face features
17. ❌ Calling defects "artistic choices" — blank face = defect, flag it
18. ❌ Regenerating what already exists — reuse approved outputs (viral-regen-v2)
19. ❌ Squishing images to 4:5 — CROP to fit, use aspect_ratio="4:5" in NANO API
20. ❌ Non-vegan food in ANY illustration — no meat, egg, dairy, fish

---

### PRODUCTION SPECS

**NANO API call:**
```python
fal_client.subscribe("fal-ai/nano-banana-pro/edit", arguments={
    "prompt": prompt,
    "image_urls": [ref_url],  # 1 ref for edit, 2 for illustration (layout+style)
    "resolution": "2K",
    "aspect_ratio": "4:5"     # CRITICAL — prevents crop issues
})
```

**Post-processing:**
```python
img = crop_to_45(img)         # Center crop (only 6px sides for 1856x2304)
img = add_grain(img, 0.025)   # 0.025 photo / 0.028 illust / 0.020 typo
img = smart_logo(img, "br")   # PIL smart placement
```

**Scraping tools (tested, working):**
- gallery-dl + Chrome cookies → IG posts, Pinterest boards
- instaloader → IG profiles, hashtags
- RedNote-MCP → XHS (installed, needs init)

**Reference sources:**
- User's Pinterest: `pinterest.com/yivonnehooi/mirra-social-media/` (134 pins)
- User's Pinterest: `pinterest.com/yivonnehooi/mirra-ig-board/` (25 pins)
- Mirra's own IG: `instagram.com/mirra.eats/` (scraped)
- Viral girl accounts: @mytherapistsays, @betches, @werenotreallystrangers, @thegoodquote
- Girl empowerment: @girlyzar, @girlzzzclub
- Pinterest search for viral illustrated memes

**Scale: 3 posts/day = 21 posts/week = 42 posts/2 weeks**

---

### KEY FILES
- Content system v2: `_WORK/mirra/MIRRA-SOCIAL-CONTENT-SYSTEM-V2.md`
- Viral research: `_WORK/mirra/03_research/VIRAL-GIRL-CONTENT-FORENSIC-2025-2026.md`
- Viral quotes: `_WORK/mirra/03_research/VIRAL-QUOTES-WOMEN-2025-2026.md`
- Style forensic: `04_references/curated/10-illustration-refs/STYLE-FORENSIC.md`
- Sparkle forensic: `06_exports/pipeline-tests/ZOOM-*.png`
- Social media master strategy: `_shared/intelligence/SOCIAL-MEDIA-MASTER-STRATEGY-2026.md`
- Production scripts: `05_scripts/produce_week1_v2_final.py`
- Smart logo: `05_scripts/smart_logo.py`
- Pinterest refs: `04_references/curated/16-mirra-social-pins/` (134 pins)
- Mirra IG refs: `04_references/curated/14-mirra-ig-top/` (20 posts)
- Week 1 finals: `06_exports/social/week1-v2final/`
- Viral regen v2 (illustrations): `06_exports/social/viral-regen-v2/`
