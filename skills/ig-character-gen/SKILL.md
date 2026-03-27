---
name: ig-character-gen
description: Instagram content library generator for AI influencer characters. Produces authentic, iPhone-quality daily life images in WESTERN city settings with consistent face/body. Built from reverse-engineering confirmed Jade Oracle IG images.
agents: [dreami, taoz]
version: 1.0.0
---

# IG Character Gen — AI Influencer Instagram Content Library

Generate authentic-looking Instagram daily life content for AI influencer characters. Every image should look like it was taken on an iPhone by the character herself — NOT editorial, NOT cinematic, NOT studio.

## Reverse-Engineered from Confirmed Jade Images

These 3 confirmed IG images defined the formula:

| Image | Setting | Outfit | Lighting | Vibe |
|-------|---------|--------|----------|------|
| ig2-market | Western farmers market | White wrap blouse (V-neck), jeans | Sunny golden hour | Laughing, holding flowers |
| ig3-restaurant | Western candlelit restaurant | Black spaghetti strap slip dress | Warm candlelight | Chin on hand, wine, intimate |
| ig4-journaling | Modern Western apartment | Cream tank top (bare shoulders) | Morning window light | Selfie, journaling, tea |

### What Makes Them Work
1. **WESTERN city settings** — farmers market, restaurant, apartment. NEVER Asian-themed
2. **iPhone selfie quality** — natural, slightly imperfect, candid. NOT editorial/cinematic
3. **Body-revealing clothing** — V-necks, slip dresses, tank tops. Figure is PART of the brand
4. **One clear activity** — shopping flowers, dinner date, morning journaling
5. **Warm natural lighting** — golden hour, candlelight, morning sun
6. **Genuine emotions** — laughing, smiling softly. Not posing for camera

### What FAILS
- Asian/Eastern-themed settings for characters living in Western world
- Editorial/fashion photography quality (looks fake on IG)
- Modest/covered clothing that hides the character's figure
- Multiple activities in one image / cool-blue lighting / direct-to-camera poses

## Character Spec Format

Each character needs a JSON spec at `~/.openclaw/workspace/data/characters/{brand}/{character}/ig-spec.json` with: name, brand, ethnicity, age, hair, eyes, skin, body, body_language, vibe, world, fashion_refs, face_refs, body_ref, never (list of banned themes).

## Prompt Formula

```
[PHOTO QUALITY] of [ETHNICITY] woman, [AGE], [HAIR], [FACE/EXPRESSION].
[BODY DESCRIPTION via clothing] — [outfit that reveals figure].
[SETTING] — [specific Western city location].
[ACTIVITY] — [one clear relatable action].
[LIGHTING] — [warm natural source].
[PROPS] — [1-2 real-world objects].
Shot on iPhone, candid, slightly imperfect framing, authentic Instagram post. 4:5 aspect ratio.
```

### Body Description Rules (from character-lock skill)
- NEVER use measurements ("34D", "36-24-36") — model ignores numbers
- USE fashion/editorial language: "decolletage", "silk following every curve"
- Describe how CLOTHING interacts with BODY, not the body itself

> Load `references/scene-library-and-refs.md` for all 20 scene categories (Daily Life, Spiritual, Going Out), reference image setup protocol, recommended ref array slots, prompt ref labeling, and file conventions.

## NanoBanana Command

```bash
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand jade-oracle --use-case character --prompt "$PROMPT" \
  --ref-image "$FACE_REF1,$FACE_REF2,$FACE_REF3,$FACE_REF1,$FACE_REF2,$BODY_REF" \
  --model pro --ratio 4:5 --size 2K
```

Key flags: `--use-case character` (skips brand enrichment), `--model pro` (better face consistency), `--ref-image` (face refs FIRST, body ref LAST).

## Generation Script

```bash
# Single image
bash ~/.openclaw/skills/ig-character-gen/scripts/ig-gen.sh \
  --character jade --scene "Farmers market, white wrap blouse, jeans, holding wildflowers"

# Batch (full library)
bash ~/.openclaw/skills/ig-character-gen/scripts/ig-gen.sh \
  --character jade --batch 10 --output ~/Desktop/jade-ig-new/
```

## QA Checklist (Per Image)

| Check | Pass Criteria |
|-------|--------------|
| Face match | Same person as refs (eyes, nose, jawline) |
| Body type | Figure visible, matches body ref proportions |
| Setting | WESTERN location, no Asian-themed elements |
| Clothing | Shows figure, matches character fashion |
| Photo quality | iPhone/candid, NOT editorial/cinematic/CG |
| Lighting | Warm natural (golden hour/candle/morning sun) |
| Hands | No deformities, natural positioning |
| Emotion | Genuine (laughing, soft smile) — not posing |

## Dependencies

- `nanobanana-gen.sh` — image generation (Gemini Image API)
- `character-lock` skill — face/body consistency rules
- `visual-audit.py` — QA scoring (use `--mode character`)
