---
name: DotDot v1-v8 Full Compound — Every YES/NO across 8 rounds
description: CRITICAL. Complete calibration history. 8 rounds, every failure documented, every fix proven. The definitive DotDot production rulebook. Apply before ANY DotDot generation.
type: feedback
---

## DOTDOT CALIBRATION — FULL COMPOUND (v1-v8, 29 March 2026)

### THE IMPROVEMENT TRAJECTORY
v1(0/6) → v2(0/6) → v3(0/6) → v4(5/6) → v5(8/9) → v6(10/10) → v7(8/8) → v8(REJECTED)
Each round taught something. Each failure became a rule.

---

### ✅ PROVEN (never change these)

**Art Style:**
1. Modern flat editorial illustration = correct for DotDot static posts
2. Strokeless shapes, soft gradients, gestural figures = the DNA
3. HK commercial poster typography = multi-color headlines, extreme hierarchy, pill badges
4. DD-T6-v2 typography bar = massive bold TC filling 20-30% of frame
5. East Asian skin tones (light-medium warm) = HK Chinese elderly audience

**Production Pipeline:**
6. Own approved output as Image 1 = best style consistency (Rule 73-74)
7. ONE Image 1 for entire batch = visual cohesion (v7 proved this)
8. Logo on RAW output BEFORE pad-fit = correct positioning (v7 proved this)
9. Pad-fit (never crop) = no content loss (v4 proved this)
10. Post-process: grade(0.96/1.04) → texture(1.8) → grain(2.5) → sharpen = DotDot health brand feel
11. Logo: PIL composite only, max 80px height, 3% margin from edges

**Content:**
12. 3 pillars from brief: Education 40% / Exercise-Tips 40% / Brand-Trust 20%
13. 10 content categories from CONTENT-TAXONOMY.md
14. Medical compliance: no "cure" claims, "support" language, disclaimers
15. Traditional Chinese only (Simplified only for XHS hashtags)
16. 1:1 text copy when adapting client's existing posts — don't paraphrase

---

### ❌ PROVEN FAILURES (never repeat)

**v1-v2: API + Double Logo**
17. ❌ `image_url` (singular) → use `image_urls` (array)
18. ❌ Asking NANO to render logo + PIL compositing = double logo
19. ❌ Prompt mentioning logo/brand name = NANO renders garbled version

**v2: Confetti + Wrong Style**
20. ❌ Sparkles, doodles, squiggly lines in prompt = cluttered output
21. ❌ Different Pinterest ref per template = inconsistent batch

**v3: Crop-fit**
22. ❌ crop-fit resize = cuts off content. ALWAYS pad-fit.
23. ❌ NANO `image_size` param not reliably respected — handle in post-processing

**v4: Text Leak**
24. ❌ Pixel values ("80px", "20px") in prompt = NANO renders them as visible text
25. ❌ Use relative terms ("generous margin") not absolute pixel values

**v5: Skin Tone + Brief Fidelity**
26. ❌ Dark/African skin tones for HK market = wrong audience representation
27. ❌ Paraphrasing brief example text = should be 1:1 copy
28. ❌ Saving raw + final files = only save finals

**v6: Logo Still Overlapping**
29. ❌ Logo variance check alone = still lands on text (text IS high variance)
30. ❌ Different typography refs as Image 1 = different styles per post

**v7: Wrong Mascot**
31. ❌ Pill/capsule shaped mascot = should be ROUND mochi
32. ❌ Teal scarf accessory = original has NO accessories
33. ❌ Mascot generated from text description each time = inconsistent
34. ❌ Landscape mascot ref = NANO outputs landscape → heavy padding

**v8: Product Distortion + Logo + No Character Sheet**
35. ❌ Passing real product PNG to NANO as Image 2 = NANO distorts text on packaging
36. ❌ Same as Bloom & Bare v1: AI destroys dense text after 1 pass
37. ❌ Logo placement doesn't check for TEXT underneath, only variance
38. ❌ Generating mascot posts without character design sheet = inconsistent sizing/proportions
39. ❌ Orange product on orange background = no contrast (Rule 8)

---

### 🔧 THE CORRECT ARCHITECTURE (v9+)

**3 Locked Assets (build BEFORE any post production):**
```
1. Product PNGs — real packaging photos (HAVE: 03_assets/product-photos/)
2. Logo PNG — real brand mark (HAVE: 03_assets/logos/)
3. Mascot PNGs — character design sheet (NEED: front/side/expressions/poses)
```

**Post Production Pipeline:**
```
Step 1: NANO generates BACKGROUND + ILLUSTRATION + TYPOGRAPHY
  - Image 1 = own approved output (style anchor)
  - Prompt describes layout WITH CLEAR ZONES for product + logo + mascot
  - "Leave top-right 150x100px COMPLETELY CLEAR for logo"
  - "Leave center-right zone clear for product placement"

Step 2: PIL composites PRODUCT PNG (if product post)
  - Real packaging, pixel-perfect text preserved
  - Drop shadow: 45° angle, 20px offset, 35px blur, 25% opacity
  - Product at 40-60% of frame height, slight 15° tilt

Step 3: PIL composites MASCOT PNG (if mascot post)
  - From locked character sheet
  - Appropriate pose/expression for content context
  - 25-35% of frame height

Step 4: PIL composites LOGO
  - VERIFY clear zone exists (no text/illustration underneath)
  - If zone is busy: shift to alternate position
  - White pill backing if needed

Step 5: PIL post-processing
  - Grade → texture → grain → sharpen (immutable order)
```

**Color Rules for Product Posts (from 82-rule masterclass):**
- Rule 8: Orange product ≠ orange bg. Use teal or cream.
- Rule 9: German Collagen → teal, deep teal, cream, or near-black bg
- Rule 13: Warm product = cool bg, cool product = warm bg
- Rule 17: Max 3 hues total besides the product

**Logo Smart Placement v2:**
1. Artwork MUST accommodate logo — prompt instructs clear zone
2. After generation, VERIFY zone is clear (check for text/edges)
3. If not clear: try top-left, bottom-right, or bottom-left
4. Logo never fights with content — content adapts to logo, not vice versa

---

### 📋 PRE-FLIGHT CHECKLIST (run before EVERY DotDot batch)

- [ ] Read this file (v1-v8 compound)
- [ ] Read COLOR-DESIGN-MASTERCLASS.md (82 rules)
- [ ] Read feedback_dotdot_mascot_dna.md (mochi character spec)
- [ ] Read feedback_dotdot_typography_hk_commercial.md (typography rules)
- [ ] Confirm: mascot character sheet exists? If not, BUILD FIRST.
- [ ] Confirm: using own approved output as Image 1? (not Pinterest ref)
- [ ] Confirm: product posts use 3-layer stack (NANO bg + PIL product + PIL logo)?
- [ ] Confirm: prompt includes clear zone instructions for logo?
- [ ] Confirm: no orange product on orange bg?
- [ ] Confirm: all text in Traditional Chinese?
- [ ] Confirm: East Asian skin tones for all human figures?
- [ ] Run 6-layer visual audit on EVERY output before showing

### THE INTENTION
Each round we get better. Every rejection = rules that prevent the same failure.
v1 had 0 passes. v6 had 10/10. v8 taught us 3 new rules (product text, logo placement, character sheet).
v9 will be better because we learned from v8.
This is the compound improvement system. It only works if we READ the learnings before acting.

**How to apply:** Read this ENTIRE file before ANY DotDot production. No exceptions.
