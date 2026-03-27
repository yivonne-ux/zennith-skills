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
agents:
  - dreami
  - iris
---

# Character Body Pairing — Face + Fashion Reference Fusion

## Purpose
Take a locked character face reference and combine it with body/fashion reference
images to generate photorealistic full-body lifestyle shots. Bridge between
"we have a face" and "we have a full content library."

## When to Use
- Character face is locked (approved by Jenn/art director)
- Need full-body, lifestyle, or fashion content
- Body reference images collected (Pinterest, mood boards, etc.)
- Building out a character's content library for ads/social

---

## Step-by-Step Workflow

### Step 1: Classify the Face Variants
Tag each face with a **vibe category**:

| Vibe | Signals |
|------|---------|
| **Spiritual** | Crystals, candles, meditation setting, serene expression, natural makeup |
| **Edgy/Street** | Urban background, leather, messy hair, confident gaze, minimal setting |
| **Warm/Lifestyle** | Bookshelf, cream tones, warm smile, cozy setting, natural light |
| **Editorial/Minimal** | Gallery, silk, sharp features, pulled-back hair, clean background |

### Step 2: Classify Body References
Tag each body ref with the same vibe categories plus:
- **Boho/Oracle**: Kaftan, flowy dress, earth tones, outdoor garden, statement earrings, barefoot

### Step 3: Match by Vibe (CRITICAL RULE)

**MATCH vibe of face to vibe of body.** Cross-vibe pairing causes the model to
pick one and ignore the other.

```
GOOD:  Spiritual face + Spiritual body = consistent character
BAD:   Editorial face + Boho body = model confused, loses face OR outfit
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

**Face details to always include:** Hair color + style + length, eye color, expression, skin tone
**Body details to always include:** Exact outfit (fabric, color, cut), pose, accessories, setting

**Lens Guide:**
| Shot | Lens |
|------|------|
| Full body standing/walking | 35mm f/1.8 |
| Medium shot seated | 50mm f/1.4 |
| Close portrait + body | 85mm f/1.4 |
| Editorial fashion | 50mm f/1.4 |

### Step 5: Generate with NanoBanana

```bash
nanobanana-gen.sh generate \
  --brand <brand-slug> \
  --use-case lifestyle \
  --prompt "<your prompt from Step 4>" \
  --ref-image "<FACE_REF_PATH>,<BODY_REF_PATH>" \
  --model pro \
  --size 2K \
  --ratio <see ratio guide>
```

**Ratio Guide:** Full body/street/story = 9:16 | Seated/medium = 1:1 or 4:3 | Editorial = 4:3 or 3:2

### Step 6: QA Check

| Check | Pass Criteria | Common Fail |
|-------|--------------|-------------|
| **Face match** | Hair color/style matches face ref | Body ref hair dominates |
| **Outfit match** | Outfit matches body ref | Outfit simplified or wrong color |
| **Photorealism** | Real skin, pores, natural light | Illustration/cartoon style |
| **Hands** | Correct finger count, natural pose | Extra fingers, melted hands |
| **Accessories** | Jewelry/bags as specified | Missing or wrong items |
| **Setting** | Environment matches body ref | Generic background substituted |

> Load `references/gotchas-and-templates.md` for all 7 gotchas (hair override, content refusal, brand injection, face blend, style seed interference, ref dilution, hair color conflicts), 4 proven prompt templates with success rates, and batch generation pattern.

## File Organization

```
workspace/data/images/{brand}/
  ├── {date}_{time}_lifestyle_{pid}.png     # Raw outputs
  └── {character}-body-pairs/               # Organized pairs
```

## Compounding: After Every Session

Update this skill with new gotchas, template success rates, and vibe combos.
Log to: `skills/character-body-pairing/learnings.jsonl`
