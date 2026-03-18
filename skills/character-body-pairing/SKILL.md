---
name: character-body-pairing
version: "1.0.0"
description: >
  Pair AI character face references with body/fashion references to generate
  consistent full-body lifestyle images. Includes vibe-matching logic,
  proven prompts, gotchas, and QA criteria.
metadata:
  openclaw:
    scope: creative
    guardrails:
      - Always use --ref-image with BOTH face + body ref (comma-separated)
      - Always use --model pro (flash loses face consistency)
      - Always end prompt with "No illustration, no cartoon, no CG."
      - Never pair more than 2 body refs per face in a single batch
    agents: [dreami, taoz]
    tools_required: [nanobanana-gen.sh]
    learned_from: "claude-code-session-2026-03-12 (Luna v3 body pairing)"
---

# Character Body Pairing — Face + Fashion Reference Fusion

## Purpose
Take a locked character face reference and combine it with body/fashion reference
images to generate photorealistic full-body lifestyle shots. This is the bridge
between "we have a face" and "we have a full content library."

## When to Use
- Character face is locked (approved by Jenn/art director)
- Need full-body, lifestyle, or fashion content
- Body reference images collected (Pinterest, mood boards, etc.)
- Building out a character's content library for ads/social

---

## Step-by-Step Workflow

### Step 1: Classify the Face Variants
Before pairing, tag each face with a **vibe category**:

| Vibe | Signals | Example |
|------|---------|---------|
| **Spiritual** | Crystals, candles, meditation setting, serene expression, natural makeup | Luna-Wise-C |
| **Edgy/Street** | Urban background, leather, messy hair, confident gaze, minimal setting | Luna-Chic-H |
| **Warm/Lifestyle** | Bookshelf, cream tones, warm smile, cozy setting, natural light | Luna-Blonde-A |
| **Editorial/Minimal** | Gallery, silk, sharp features, pulled-back hair, clean background | Luna-Chic-C |

### Step 2: Classify Body References
Tag each body ref with the same vibe categories:

| Vibe | Body Ref Signals |
|------|-----------------|
| **Spiritual** | Meditation pose, white/cream linen, incense, candles, gold bangles, barefoot, floor-seated |
| **Edgy/Street** | B&W photography, tee + jeans, leather, standing/leaning, urban setting, film grain |
| **Warm/Lifestyle** | Cardigan, blouse + trousers, books, elegant interior, warm window light, seated relaxed |
| **Editorial/Minimal** | Jumpsuit, structured bags, heels, stone/concrete, clean lines, walking pose, sunglasses |
| **Boho/Oracle** | Kaftan, flowy dress, earth tones, outdoor garden, statement earrings, barefoot |

### Step 3: Match by Vibe (CRITICAL RULE)

**MATCH vibe of face to vibe of body.** Cross-vibe pairing causes the model to
pick one and ignore the other.

```
GOOD:  Spiritual face + Spiritual body = consistent character
GOOD:  Editorial face + Editorial body = consistent character
BAD:   Editorial face + Boho body = model confused, loses face OR outfit
BAD:   Edgy face + Spiritual body = uncanny mismatch
```

**Each face gets exactly 2 body pairings** — enough variety without diluting consistency.

### Step 4: Write the Prompt

**Prompt Structure (MANDATORY):**
```
Photorealistic [shot type] photograph of a young woman with [FACE DETAILS FROM REF],
[POSE/ACTION from body ref], wearing [OUTFIT DETAILS from body ref],
[ACCESSORIES from body ref], [SETTING from body ref],
[LIGHTING description], real skin with pores, [LENS] f/[APERTURE],
[DEPTH OF FIELD]. No illustration, no cartoon, no CG.
```

**Face details to always include:**
- Hair color + style + length
- Eye color
- Expression type
- Skin tone (if distinctive)

**Body details to always include:**
- Exact outfit description (fabric, color, cut)
- Pose (seated, standing, walking, meditation)
- Accessories (jewelry, bags, shoes)
- Setting/environment

**Lens Guide by Shot Type:**
| Shot | Lens | Notes |
|------|------|-------|
| Full body standing/walking | 35mm f/1.8 | Shows environment |
| Medium shot seated | 50mm f/1.4 | Balanced |
| Close portrait + body | 85mm f/1.4 | Flattering compression |
| Editorial fashion | 50mm f/1.4 | Clean, minimal distortion |

### Step 5: Generate with NanoBanana

```bash
nanobanana-gen.sh generate \
  --brand <brand-slug> \
  --use-case lifestyle \
  --prompt "<your prompt from Step 4>" \
  --ref-image "<FACE_REF_PATH>,<BODY_REF_PATH>" \
  --model pro \
  --size 2K \
  --ratio <see ratio guide below>
```

**Ratio Guide:**
| Content Type | Ratio | Why |
|-------------|-------|-----|
| Full body standing | 9:16 | Vertical, shows full outfit |
| Seated/medium | 1:1 or 4:3 | Balanced framing |
| Street style walking | 9:16 | Shows stride + outfit |
| Editorial fashion | 4:3 or 3:2 | Magazine feel |
| Social media story | 9:16 | IG/TikTok native |

### Step 6: QA Check

After generation, verify:

| Check | Pass Criteria | Common Fail |
|-------|--------------|-------------|
| **Face match** | Hair color/style matches face ref | Body ref hair dominates (see Gotcha #1) |
| **Outfit match** | Outfit matches body ref | Outfit simplified or wrong color |
| **Photorealism** | Real skin, pores, natural light | Illustration/cartoon style |
| **Hands** | Correct finger count, natural pose | Extra fingers, melted hands |
| **Accessories** | Jewelry/bags as specified | Missing or wrong items |
| **Setting** | Environment matches body ref | Generic background substituted |

---

## Gotchas & Hard-Won Learnings

### Gotcha #1: Body Ref Hair OVERRIDES Face Ref Hair
**Problem:** If body ref has dark hair and face ref has silver/blonde hair,
the model often generates dark hair (body ref dominates for hair).

**Fix:** In prompt, EMPHASIZE hair color with extra specificity:
```
"with DISTINCTIVE silver-grey hair pulled back in a low ponytail"
```
Add "DISTINCTIVE" or "STRIKING" before unusual hair colors.

**If still failing:** Use a body ref where the model's hair is similar to
your face ref, OR crop the body ref to exclude the head.

### Gotcha #2: Content Refusal on B&W / Intimate Poses
**Problem:** Gemini may refuse prompts with "black and white" + certain
body poses (reads as potentially sensitive content).

**Fix:** Replace "black and white photograph" with:
```
"documentary style portrait, film grain texture"
```
Avoid words: intimate, bedroom, lingerie, revealing. Use: relaxed, casual, confident.

### Gotcha #3: Brand Injection
**Problem:** NanoBanana auto-injects brand elements (QMDJ logo, Jade Oracle box)
when `--brand` is set, even for pure lifestyle shots.

**Impact:** Usually helpful (product placement), but sometimes distracting.

**Fix:** If you want PURE lifestyle without brand elements, use `--use-case social`
instead of `lifestyle`, or temporarily use `--brand gaia-os` (neutral brand).

### Gotcha #4: Two Faces Generated
**Problem:** If both face ref and body ref show clear faces, model sometimes
generates TWO people or a face-blend.

**Fix:** Choose body refs where the face is:
- Partially hidden (looking down, profile, hair covering)
- Cropped out (torso-only shots)
- OR explicitly state in prompt: "single person, one woman only"

### Gotcha #5: Style Seed Interference
**Problem:** If `--style-seed` is also passed alongside ref images,
style seed refs + your refs = too many references, confusing the model.

**Fix:** Do NOT use `--style-seed` when doing face+body pairing.
Let the ref images speak for themselves.

---

## Proven Prompt Templates

### Template 1: Spiritual/Meditation
```
Photorealistic full body photograph of a young woman with [HAIR] and [EYES],
seated cross-legged on wooden floor in meditation pose, eyes closed peacefully,
wearing a white ribbed tank top and sage linen wide-leg pants, wisps of incense
smoke curling around her, warm golden sunlight streaming through window,
real skin with pores, 35mm f/1.8, shallow depth of field.
No illustration, no cartoon, no CG.
```
**Success rate:** 100% (1/1) | **Ratio:** 9:16

### Template 2: Fashion Street Style
```
Photorealistic street style photograph of a young woman with [HAIR],
walking on a European cobblestone street, wearing [OUTFIT DETAILS],
aviator sunglasses, [BAG], [EARRINGS], confident stride, old stone
buildings in background, natural daylight, real skin with pores,
35mm f/1.8. No illustration, no cartoon, no CG.
```
**Success rate:** 100% (1/1) | **Ratio:** 9:16
**Note:** Silver hair was overridden to dark — see Gotcha #1.

### Template 3: Elegant Interior
```
Photorealistic photograph of a young woman with [HAIR], sitting on a
leather ottoman in an elegant Parisian apartment, wearing [OUTFIT],
warm natural light from tall windows, Persian rug on floor, bookshelves
in background, serene confident expression, real skin with pores,
35mm f/1.8, cinematic. No illustration, no cartoon, no CG.
```
**Success rate:** 100% (1/1) | **Ratio:** 9:16

### Template 4: Casual/Edgy
```
Photorealistic photograph of a young woman with [HAIR], wearing a classic
white t-shirt and dark denim jeans, leaning casually against a concrete wall,
relaxed confident expression, natural daylight, film grain texture,
50mm f/1.8, documentary style portrait. No illustration, no cartoon, no CG.
```
**Success rate:** 100% after retry (initial B&W prompt was refused) | **Ratio:** 1:1

---

## Batch Generation Pattern

For efficiency, generate all pairs in parallel:

```bash
# Launch all 8 in parallel (4 faces × 2 bodies each)
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

---

## File Organization

```
workspace/data/images/{brand}/
  ├── {date}_{time}_lifestyle_{pid}.png     # Raw outputs
  └── {character}-body-pairs/               # Organized pairs
      ├── 01-{face}-{body-desc}.png
      ├── 02-{face}-{body-desc}.png
      └── ...
```

Copy to Desktop for Jenn's review:
```bash
mkdir -p ~/Desktop/{character}-body-pairs/
cp <outputs> ~/Desktop/{character}-body-pairs/
```

---

## Compounding: After Every Session

After generating body pairs, update this skill with:
1. New gotchas discovered
2. Updated success rates on templates
3. New proven prompt templates
4. Face-body vibe combos that worked/failed

Log to: `skills/character-body-pairing/learnings.jsonl`
```json
{"date":"2026-03-12","face":"Luna-Wise-C","body":"meditation-incense","result":"PASS","notes":"perfect spiritual match"}
{"date":"2026-03-12","face":"Luna-Chic-C","body":"olive-vneck-street","result":"PARTIAL","notes":"hair color overridden by body ref"}
```
