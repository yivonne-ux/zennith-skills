# Gotchas & Hard-Won Learnings

## Gotcha #1: Body Ref Hair OVERRIDES Face Ref Hair
**Problem:** If body ref has dark hair and face ref has silver/blonde hair,
the model often generates dark hair (body ref dominates for hair).

**Fix:** In prompt, EMPHASIZE hair color with extra specificity:
```
"with DISTINCTIVE silver-grey hair pulled back in a low ponytail"
```
Add "DISTINCTIVE" or "STRIKING" before unusual hair colors.

**If still failing:** Use a body ref where the model's hair is similar to
your face ref, OR crop the body ref to exclude the head.

## Gotcha #2: Content Refusal on B&W / Intimate Poses
**Problem:** Gemini may refuse prompts with "black and white" + certain
body poses (reads as potentially sensitive content).

**Fix:** Replace "black and white photograph" with:
```
"documentary style portrait, film grain texture"
```
Avoid words: intimate, bedroom, lingerie, revealing. Use: relaxed, casual, confident.

## Gotcha #3: Brand Injection (FIXED 2026-03-25)
**Problem:** NanoBanana auto-injects brand elements (QMDJ logo, Jade Oracle book/cards)
when `--brand` is set, even for pure lifestyle shots.

**Status:** FIXED in nanobanana-gen.sh. When `--ref-image` is passed, brand enrichment
and use-case templates are now skipped automatically. Character `never` list from
ig-spec.json is loaded and appended as negative prompt.

## Gotcha #4: Two Faces / Face Blend from Body Refs
**Problem:** If body refs show partial face (chin, jaw, lips), model blends those
facial features with the face-lock, producing a hybrid face that matches NEITHER.

**Fix (ENFORCED 2026-03-25):**
- Body refs MUST be cropped torso-only — no chin, no jaw, no lips visible
- NanoBanana now prepends: "The FIRST reference image is the character's face —
  match it EXACTLY. Other references are for body proportions only."
- Choose body refs where face is fully cropped out

## Gotcha #5: Style Seed Interference
**Problem:** If `--style-seed` is also passed alongside ref images,
style seed refs + your refs = too many references, confusing the model.

**Fix:** Do NOT use `--style-seed` when doing face+body pairing.
Let the ref images speak for themselves.

## Gotcha #6: Too Many Body Refs Dilute Face Signal (ADDED 2026-03-25)
**Problem:** Passing 4+ body refs with 1 face-lock = 4:1 body-to-face ratio.
Model treats all refs with roughly equal weight, so face signal gets drowned out.

**Fix (ENFORCED in nanobanana-gen.sh):**
- Max 3 ref images total (1 face + 2 body). Script auto-trims if more passed.
- If you need variety, generate multiple batches with different body pairs.
- Quality > quantity: 1 face + 1 well-matched body > 1 face + 4 mixed bodies.

## Gotcha #7: Body Ref Hair Color Conflicts (REINFORCED 2026-03-25)
**Problem:** Body refs with dark/brown hair cause the model to override the
face-lock's platinum blonde hair. Even partial hair visibility in body refs
pulls the output toward the body ref's hair color.

**Fix:**
- ONLY use body refs with blonde/light hair if character has blonde hair
- If body ref has wrong hair color, crop the image to exclude ALL hair
- In prompt, use "DISTINCTIVE platinum blonde" (emphasis word helps)

---

# Proven Prompt Templates

## Template 1: Spiritual/Meditation
```
Photorealistic full body photograph of a young woman with [HAIR] and [EYES],
seated cross-legged on wooden floor in meditation pose, eyes closed peacefully,
wearing a white ribbed tank top and sage linen wide-leg pants, wisps of incense
smoke curling around her, warm golden sunlight streaming through window,
real skin with pores, 35mm f/1.8, shallow depth of field.
No illustration, no cartoon, no CG.
```
**Success rate:** 100% (1/1) | **Ratio:** 9:16

## Template 2: Fashion Street Style
```
Photorealistic street style photograph of a young woman with [HAIR],
walking on a European cobblestone street, wearing [OUTFIT DETAILS],
aviator sunglasses, [BAG], [EARRINGS], confident stride, old stone
buildings in background, natural daylight, real skin with pores,
35mm f/1.8. No illustration, no cartoon, no CG.
```
**Success rate:** 100% (1/1) | **Ratio:** 9:16
**Note:** Silver hair was overridden to dark — see Gotcha #1.

## Template 3: Elegant Interior
```
Photorealistic photograph of a young woman with [HAIR], sitting on a
leather ottoman in an elegant Parisian apartment, wearing [OUTFIT],
warm natural light from tall windows, Persian rug on floor, bookshelves
in background, serene confident expression, real skin with pores,
35mm f/1.8, cinematic. No illustration, no cartoon, no CG.
```
**Success rate:** 100% (1/1) | **Ratio:** 9:16

## Template 4: Casual/Edgy
```
Photorealistic photograph of a young woman with [HAIR], wearing a classic
white t-shirt and dark denim jeans, leaning casually against a concrete wall,
relaxed confident expression, natural daylight, film grain texture,
50mm f/1.8, documentary style portrait. No illustration, no cartoon, no CG.
```
**Success rate:** 100% after retry (initial B&W prompt was refused) | **Ratio:** 1:1

---

# Batch Generation Pattern

```bash
# Launch all 8 in parallel (4 faces x 2 bodies each)
for i in 1 2 3 4 5 6 7 8; do
  nanobanana-gen.sh generate \
    --brand <brand> \
    --use-case lifestyle \
    --prompt "<prompt_$i>" \
    --ref-image "<face_$i>,<body_$i>" \
    --model pro \
    --size 2K \
    --ratio <ratio_$i> &
done
wait
echo "All pairs complete"
```

**Rate limit:** NanoBanana handles slot-based rate limiting internally (6s between calls).
15 parallel slots max. 8 pairs = well within limits.
