---
name: Visual Audit — 12-Layer Mastery Gate (v3.0)
description: CRITICAL. World-class pre-flight QA for EVERY generated image. 12 layers. Built from 80+ post production across 2 batches, 10+ rounds of user feedback. Minimum 9/10 gate. ALL brands.
type: feedback
---

## VISUAL AUDIT — 12-LAYER MASTERY GATE (v3.0)
Run ALL 12 layers on EVERY generated image BEFORE presenting to user.
Score each layer 0 or 1. Total must be 11/12+ to pass (9/10 equivalent).
ANY critical layer fail (marked with !) = instant reject regardless of total.

---

### Layer 1: TEXT INTEGRITY (!)
- [ ] All text renders correctly — no garbled characters
- [ ] No residual text from reference image bleeding through
- [ ] No typos or repeated words
- [ ] CN characters render correctly if Chinese post
- [ ] Brand text: only PIL logo OR NANO text, NEVER both
- [ ] **TEXT NOT CROPPED AT ANY EDGE** — all words fully visible with margins
- [ ] If ANY text touches the crop boundary → FAIL

**Batch 2 lesson:** crop45() destroyed edge text on 8+ posts. NANO must generate at 4:5 aspect ratio so no destructive cropping needed.

---

### Layer 2: IMAGE-COPY SEMANTIC MATCH (!)
- [ ] The image VISUALLY MATCHES the copy meaning
- [ ] If copy says "caffeine" → show COFFEE not pills
- [ ] If copy says "food" → show FOOD not shells
- [ ] If copy says "cat" → show a CAT not a newspaper
- [ ] Multi-panel comics: narrative logic is CONSISTENT (punchline tracks)

---

### Layer 3: FOOD PHOTOGRAPHY QUALITY (!)
- [ ] Real bento photos have EDITORIAL enhancement (brightness, warmth, clarity)
- [ ] Food must look APPETIZING — never dull, flat, or grey
- [ ] Enhancement must still look NATURAL — not over-saturated or fake
- [ ] Think food magazine editorial: warm light, vibrant colors, sharp textures
- [ ] **PIL enhancement BEFORE layout:** brightness +10-15%, warmth +5%, slight sharpening
- [ ] Raw unenhanced bento photos = REJECT
- [ ] **NEVER add bling, glitter, gems, pearls, crystals ON the food itself**
- [ ] **NEVER replace or modify the food** — it must be the EXACT Mirra bento photo
- [ ] **NEVER change the food container/plating** — keep as-is from food library
- [ ] Aesthetic treatment goes on BACKGROUND and LABELS only, never on the food
- [ ] The food is SACRED and UNTOUCHABLE — glamour goes AROUND it, not ON it
- [ ] If ANY food pixel has been modified (gems added, color changed, plating swapped) → INSTANT REJECT

**v4 lesson:** Using luxe food refs (jewel toast, pearl pizza) as Image 1 caused NANO to add gems/pearls ON the Mirra bentos. The aesthetic ref must influence BACKGROUND styling only. Food = untouchable.

---

### Layer 4: PHOTO AUTHENTICITY (NEW — !)
- [ ] ALL food in the image must be REAL PHOTOGRAPHY, never AI-generated
- [ ] AI-generated food = too perfect, too clean, plasticky textures, impossible lighting
- [ ] For comparison posts: the "other side" food MUST be real stock photography
- [ ] Mirra bentos: use SACRED real photos only — never let NANO generate food
- [ ] Use PIL composite for food placement, NANO only for background/text/styling
- [ ] If ANY food looks AI-generated → FAIL

**Batch 2 lesson:** B2-27 grab order, B2-28 burger, B2-30 bowls, B2-31 entire image = all AI food. Looks fake.

---

### Layer 5: COLOR + TEXTURE + ATMOSPHERE QUALITY (!)
- [ ] NOT a flat single-color overlay — must have tonal depth AND texture
- [ ] Shadows, midtones, highlights each have DIFFERENT tones
- [ ] Film grain visible (not digital noise)
- [ ] Colors match brand palette
- [ ] No ugly drop shadows on text
- [ ] **TEXTURE IS MANDATORY** — never flat/clinical. Must have: sparkle, glitter, bokeh, watercolor wash, fabric texture, light leaks, or atmospheric depth
- [ ] **Brand-specific warmth** — check brand DNA for correct warmth type (Mirra = candlelit sparkle glamour, NOT sunlit airy)
- [ ] **Feed variety:** no more than 2 posts in a row with same dominant color
- [ ] If the output looks like it could be any generic brand → FAIL (needs brand-specific atmospheric treatment)

**v3 lesson:** "Clean bright airy" is a wellness brand, not Mirra. Mirra = sparkle glamour with warm-dark richness. Check brand DNA for correct atmosphere.

---

### Layer 6: VIRAL HOOK CHECK
- [ ] Would someone DM this to 5 friends? If no → reject
- [ ] Is the concept TRENDING right now (2026), not 2024-era stale?
- [ ] Does it have a SPECIFIC hook (not generic "eat well")
- [ ] Comparison formats: the GAP must be funny/shocking enough
- [ ] EVERY post must have PURPOSE: viral humor, education, emotion, or identity
- [ ] Pretty product shots + generic poetic copy = REJECT
- [ ] Food posts must give GENUINE VALUE, not just aesthetic
- [ ] All quotes COPIED from proven viral posts, NEVER imagined

---

### Layer 7: FORMAT FIDELITY
- [ ] Labeled photo → REAL PHOTO with labels, not illustration
- [ ] Typography → editorial serif, not decorative script
- [ ] Illustration → Korean semi-realistic, NOT Disney/Pixar/chibi
- [ ] All faces fully rendered (no blank/featureless faces)
- [ ] Aspect ratio 4:5 (1080×1350) — generated at 4:5, not cropped to 4:5
- [ ] Labels ACCURATE — each label points to CORRECT item
- [ ] Food education → labeled/viral format, NOT plain text infographic

---

### Layer 8: REFERENCE TRANSFORMATION + VIRAL TRACEABILITY (!)
- [ ] Output is NOT a passthrough of the reference with only text swapped
- [ ] The output must be TRANSFORMED to brand palette and aesthetic
- [ ] Typography/glitter posts: text swapped on the SAME aesthetic = OK (that's the format)
- [ ] **No double logo** — if NANO renders brand text, PIL must NOT add logo. Check before saving.
- [ ] **No residual UI elements** from reference (carousel indicators "9/20", play buttons, etc.)
- [ ] **No residual brand text** from reference ("Layla", other brand names on props)
- [ ] **EVERY illustration must trace to a SPECIFIC viral post** — "hot girl walk" as a generic concept = REJECTED. Must be: "THIS specific viral post went viral with THIS format"
- [ ] If a post concept was IMAGINED (not traced to a proven viral post) → REJECT
- [ ] Generic confidence/empowerment illustrations without viral FORMAT reference = REJECT

**v4 lesson:** B2-04 "hot girl walk" and B2-10 "standing on business" = rejected because they're generic concepts, not copied from specific viral posts. B2-17 had double logo (NANO + PIL). B2-32 had "Layla" residual text.

---

### Layer 9: REFERENCE UNIQUENESS (NEW)
- [ ] Every post uses a UNIQUE reference — never two posts from same ref
- [ ] No two posts should look visually similar (same bg, same layout, same aesthetic)
- [ ] Grid variety: scrolling through all posts should feel DIVERSE
- [ ] If any two posts look like "same template different text" → one gets rejected
- [ ] Scrape fresh refs for every batch — don't reuse old folders

**Batch 2 lesson:** B2-17/B2-20 identical aesthetic (glitter on mauve). B2-18/B2-21 identical (billboard+clouds). Feed looked repetitive.

---

### Layer 10: BRAND CONSISTENCY (!)
- [ ] No non-vegan food visible (no meat, fish, eggs, dairy)
- [ ] No pricing, CTAs, health claims in organic posts
- [ ] No copyright-risky characters (movie characters, Bratz, Barbie, Disney, Pixar)
- [ ] No other brand logos/text leaked from reference
- [ ] No inappropriate content (weapons, violence, nudity, drugs)
- [ ] Logo: single PIL placement, correct B/W for background luminance
- [ ] Background must be ON BRAND — warm palette, NOT green/nature/sage
- [ ] **Pre-screen ALL scraped references for copyright and safety BEFORE production**

**Batch 2 lesson:** B2-23 Mean Girls, B2-25 Bratz doll, B2-26 had a gun visible. Pre-screening catches these before they become outputs.

---

### Layer 11: CROP & EDGE SAFETY (NEW)
- [ ] ALL text has minimum 10% margin from all four edges
- [ ] Labels on food photos: fully visible, not truncated at edges
- [ ] Title text at top: fully visible, not cut off
- [ ] Bottom text: fully visible above logo zone
- [ ] **Post-crop check:** after resize, scan edges for truncated text
- [ ] If aspect_ratio was NOT set in NANO call → flag for re-run
- [ ] Labels pointing to items near edges: verify label text is within bounds

**Batch 2 lesson:** "ving money", "AME CALORIES", "oconut rice", "eamed rice", "kled vegetables" — all caused by crop without aspect_ratio.

---

### Layer 12: VALUE & SHAREABILITY
- [ ] Does this post give the VIEWER something? (humor, fact, emotion)
- [ ] "No meaning, no viral factor, no value to customer" = REJECT
- [ ] Pretty photo + generic copy = REJECT
- [ ] Food education must teach something SPECIFIC and SURPRISING
- [ ] Every post earns its spot: SEND it, SAVE it, or COMMENT on it
- [ ] "Would a 26yo Malaysian woman stop scrolling for this?" → if no, REJECT
- [ ] The post must be BETTER than what's already on the brand's feed

---

## SCORING SYSTEM

| Score | Meaning | Action |
|-------|---------|--------|
| 12/12 | Perfect | Ship |
| 11/12 | Excellent | Ship (note the minor issue for learning) |
| 10/12 | Good | Ship only if no critical (!) layers failed |
| 9/12 | Borderline | Regenerate unless all fails are minor |
| <9/12 | Fail | Regenerate. Log failure reason. |
| Any (!) fail | Instant reject | Regenerate regardless of total score |

## CRITICAL (!) LAYERS — instant reject if failed:
- Layer 1: Text Integrity
- Layer 3: Food Photography Quality
- Layer 4: Photo Authenticity
- Layer 8: Reference Transformation
- Layer 10: Brand Consistency

## PRE-PRODUCTION CHECKLIST (run BEFORE generating)
1. [ ] Every post has a UNIQUE reference (no reuse)
2. [ ] All references pre-screened for copyright and safety
3. [ ] All references pre-screened for residual text that may bleed through
4. [ ] NANO API calls include `"aspect_ratio": "4:5"`
5. [ ] Bento photos have PIL editorial enhancement applied BEFORE layout
6. [ ] Comparison posts: real stock photos sourced for "other side" food
7. [ ] Color mood varies across batch — no 3+ posts with same dominant color
8. [ ] All quotes verified as COPIED from proven viral sources

**Why:** 80+ posts across 2 batches, 10+ rounds of user feedback. Every rule is earned from a specific failure. The system gets smarter every round.

**How to apply:** Run ALL 12 layers + pre-production checklist on EVERY image. If ANY critical layer fails, regenerate. Do NOT call defects "artistic choices." Do NOT present dull food, AI food, cropped text, or reference passthroughs.
