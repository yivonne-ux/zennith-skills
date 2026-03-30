---
name: NANO Production Pipeline v2 Learnings
description: All yes/no from andromeda batch 1-3 production. Logo, aspect ratio, food, compression fixes. Apply to ALL future NANO production.
type: feedback
---

## NANO Production Pipeline — Compound Learnings (March 28-29, 2026)

### LOGO RULES (CRITICAL — took 4 iterations to fix)
1. **NANO ALWAYS generates fake logos** even with "NO LOGO" in prompt. Text instructions do NOT override what NANO sees.
2. **FIX: Blank logo zones in reference image BEFORE uploading to NANO.** Paint over top-left, top-right, and top bar with background color. NANO can't copy what it can't see.
3. **NEVER ask NANO to render any logo, ginkgo, emblem, badge, seal, stamp, or icon.** Remove ALL such instructions from prompts.
4. **PIL places the REAL logo AFTER NANO finishes.** Use `place_logo()` with real `logomark-*.png` at 80px, top-right, margin 30px.
5. **Never put logo instructions in the NANO prompt** — no "place ginkgo top-right", no "brand badge bottom-right", no "circle with leaf". These ALL cause NANO to render its own fake version.

**Why:** NANO is an image-to-image model. It copies what it SEES in Image 1, not what it READS in the prompt. If the reference has a logo, NANO will reproduce a garbled version. Blanking the logo zone is the only reliable prevention.

**How to apply:** Every production script must: (1) blank logo zones on reference, (2) zero logo mentions in prompt, (3) PIL composite real logo post-NANO.

### ASPECT RATIO (CRITICAL — took 3 iterations)
1. **NEVER use `resize((1080, 1350))`** — this STRETCHES/SQUEEZES if NANO outputs at a different ratio.
2. **Set `aspect_ratio="4:5"` in the NANO API call** — forces native 4:5 output.
3. **After NANO: scale to 1080px wide (maintain ratio), then CENTER-CROP height to 1350.** Never stretch.
4. **NANO at "4K" resolution outputs ~3712×4608** for 4:5. Downscale to 1080×1350 is clean.

**Why:** NANO outputs at unpredictable ratios (0.558, 1.833, etc.) when `aspect_ratio` is not set. Forcing resize to 1080×1350 distorts the content — fonts look squeezed, photos compressed.

**How to apply:** Every `nano_edit()` call must include `aspect_ratio="4:5"` (or "9:16" for stories). Post-NANO: scale width → crop height. Never `resize()` to both dimensions.

### REFERENCE IMAGE PREP (feed screenshots)
1. **Crop IG/FB chrome from screenshots** — remove status bar, profile header, like bar, other posts. Keep ONLY the post content.
2. **Do NOT use full phone screenshots as references** — NANO will reproduce the phone UI chrome.
3. **Pre-crop to tight content bounds** — manually per screenshot since chrome heights vary.
4. **Send at ORIGINAL resolution** — no downscale. NANO handles large inputs fine at 4K.
5. **Never apply GaussianBlur() to references** — blur(30) destroys all detail.

**Why:** The user's phone screenshots are ~1206×2622 (9:19.5). Using the full screenshot as Image 1 causes NANO to reproduce IG headers, like bars, and squeeze the actual content. Tight cropping gives NANO only the FORMAT to copy.

**How to apply:** For each feed screenshot, manually identify the post content bounds. Save as `{name}_tight.png` in `04_references/feed-cropped/`.

### FOOD ACCURACY
1. **NANO does NOT faithfully reproduce food from Image 2.** It interprets and generates its own version.
2. **Add FOOD_SIGNATURES per dish** — explicit visual markers NANO must preserve (e.g., "GREEN PETAI BEANS", "PURPLE EGGPLANT", "dark braised chunks with RED CHILI FLAKES").
3. **State clearly: "Image 2 is a REAL PHOTOGRAPH. Copy it EXACTLY."**
4. **Single hero dish = best preservation.** Multi-dish prompts cause NANO to generate generic food.
5. **Different platewares per creative** — same dish on white/black/claypot/banana leaf = visual variety = more Andromeda Entity IDs.

**Why:** NANO prioritizes layout reproduction (from Image 1) and treats food (Image 2) as secondary. Without explicit signature markers, it generates generic Chinese food that may not be Pinxin or may not be vegan.

### PACKAGING RULES (ABSOLUTE)
1. **NEVER let NANO generate packaging.** It always creates wrong/fake packaging.
2. **Use real `pkg-*.png` from local-cache ONLY.** Composite via PIL post-production.
3. **If a creative needs packaging visible, add it via PIL AFTER NANO.** Same as logo.

### AI-GENERATED HUMANS (REJECTED × 3)
1. **NANO-generated faces are detected as fake** — too smooth, too perfect, uncanny.
2. **NEVER use AI faces for trust/testimonial/social proof posts.** Destroys credibility.
3. **Alternatives:** hands-only (with jade bracelet), back-of-head, soft-focus/blurred faces, or real customer photos.
4. **Founder posts REQUIRE real founder photo.** Skip format if unavailable.

### COMPRESSION RULES
1. **PNG compress_level=1** (minimal) for all outputs.
2. **NANO resolution="4K"** — always. "2K" is visibly lower quality.
3. **output_format="png"** in NANO API call — avoid JPEG intermediary.
4. **Final output: 1080×1350 (4:5) or 1080×1920 (9:16).** Scale down from 4K, never up.

### PRODUCTION PIPELINE ORDER (LOCKED)
```
1. Crop reference (remove chrome/logos)
2. Blank logo zones on reference
3. Upload reference as Image 1 (original resolution)
4. Upload food cutout as Image 2
5. Build prompt: format layout + FOOD_SIGNATURES + NO_LOGO + VEGAN_GATE + COLOR_MOOD
6. NANO edit (resolution="4K", aspect_ratio="4:5", output_format="png")
7. Scale output to 1080 wide, center-crop height
8. PIL composite REAL logo (80px, top-right)
9. Add grain (0.018)
10. Save PNG (compress_level=1)
```

### BATCH 1-3 SCORECARD
- Batch 1 (16 produced): 6 PASS, 10 NEEDS FIX (logo), 0 REJECT. Fixed with PIL logo.
- Batch 2 (12 produced): 7 PASS, 2 NEEDS FIX, 3 REJECT (AI faces).
- Batch 3 (5 produced): Pipeline fixes tested. Logo, squeeze, compression all resolved.
- **Total deployable: ~25 creatives across 20+ format families.**
- **Status: NOT YET DEPLOYED to Meta. Pending user approval.**
