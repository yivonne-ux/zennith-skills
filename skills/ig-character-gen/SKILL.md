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

| Image | Setting | Outfit | Body | Lighting | Vibe |
|-------|---------|--------|------|----------|------|
| ig2-market | Western farmers market | White wrap blouse (V-neck), jeans | Shows figure via wrap neckline | Sunny golden hour, candid | Laughing, holding flowers, natural |
| ig3-restaurant | Western candlelit restaurant | Black spaghetti strap slip dress (deep V) | Cleavage visible, 33D figure clear | Warm candlelight, amber tones | Chin on hand, wine glass, intimate |
| ig4-journaling | Modern Western apartment bedroom | Cream tank top (bare shoulders) | Shoulders/upper body visible | Morning window light, soft warm | Selfie angle, journaling, steaming tea |

### What Makes Them Work
1. **WESTERN city settings** — farmers market, restaurant, apartment. NEVER Asian-themed (no tea ceremony, zen garden, calligraphy)
2. **iPhone selfie quality** — natural, slightly imperfect, candid angles. NOT editorial/cinematic/CG
3. **Body-revealing clothing** — V-necks, slip dresses, tank tops. Character's figure is PART of the brand
4. **One clear activity** — shopping flowers, dinner date, morning journaling. Relatable daily life
5. **Warm natural lighting** — golden hour, candlelight, morning sun. Never flash, never studio
6. **Genuine emotions** — laughing, smiling softly, looking up. Not posing for camera

### What FAILS
- Asian/Eastern-themed settings for characters living in Western world
- Editorial/fashion photography quality (looks fake on IG)
- Modest/covered clothing that hides the character's figure
- Multiple activities in one image (confusing)
- Cool/blue lighting (feels clinical)
- Direct-to-camera model poses (not authentic IG)

---

## Character Spec Format

Each character needs a JSON spec file at:
`~/.openclaw/workspace/data/characters/{brand}/{character}/ig-spec.json`

```json
{
  "name": "Jade",
  "brand": "jade-oracle",
  "ethnicity": "Korean",
  "age": "early 30s",
  "hair": "dark brown, long, soft bangs, slightly tousled",
  "eyes": "warm brown, gentle",
  "skin": "warm golden, natural glow",
  "body": "curvy, full 33D bust, slim waist, hourglass silhouette",
  "body_language": "fabric descriptions — deep V showing decolletage, silk following curves, form-fitting knits",
  "vibe": "poised, calm confidence, warm",
  "world": "Western city — NYC/LA/Melbourne lifestyle",
  "spiritual_angle": "Eastern wisdom (QMDJ, I Ching) subtly woven into modern life",
  "fashion_refs": ["burgundy kaftan with deep V", "white linen wrap tops", "black slip dresses", "earth tones", "jade jewelry"],
  "face_refs": "~/.openclaw/workspace/data/characters/jade-oracle/jade/face-refs/",
  "body_ref": "~/.openclaw/workspace/data/characters/jade-oracle/jade/body-ref.jpg",
  "never": ["tea ceremony", "zen garden", "calligraphy", "temple", "Asian market", "kimono", "hanbok"]
}
```

---

## Prompt Formula

Every prompt follows this exact structure:

```
[PHOTO QUALITY] of [ETHNICITY] woman, [AGE], [HAIR], [FACE/EXPRESSION].
[BODY DESCRIPTION via clothing] — [outfit that reveals figure].
[SETTING] — [specific Western city location].
[ACTIVITY] — [one clear relatable action].
[LIGHTING] — [warm natural source].
[PROPS] — [1-2 real-world objects].
Shot on iPhone, candid, slightly imperfect framing, authentic Instagram post.
4:5 aspect ratio.
```

### Prompt Template (copy-paste ready)

```
Authentic iPhone photo of a [ETHNICITY] woman in her [AGE], [HAIR_DESC], [EXPRESSION].
She has a [BODY_DESC] — [OUTFIT showing figure].
[SETTING_DESC].
She is [ACTIVITY_DESC].
[LIGHTING_DESC].
[PROPS if any].
Shot on iPhone 16 Pro, natural depth of field, candid moment, warm tones.
Looks like a real Instagram post from a lifestyle influencer.
```

### Body Description Rules (from character-lock skill)
- NEVER use measurements ("34D", "36-24-36") — model ignores numbers
- USE fashion/editorial language: "decolletage", "silk following every curve", "form-fitting knit hugging her full bust"
- Describe how CLOTHING interacts with BODY, not the body itself
- Examples:
  - "deep V-neck showing her decolletage, the fabric draping over her naturally full bust"
  - "fitted slip dress following her hourglass curves, thin straps showing toned shoulders"
  - "cropped tank top, her curvy frame clearly visible"

---

## Scene Library (10 Categories)

### Daily Life (Western City)
1. Farmers market — browsing produce, holding flowers, reusable bag
2. Coffee shop — reading, latte art, window seat, morning light
3. Restaurant dinner — candlelit, wine, intimate, date night energy
4. Morning routine — bed journaling, tea, soft light, tank top
5. Cooking at home — modern kitchen, wine glass, herbs, apron over camisole
6. Rooftop sunset — city skyline, glass of wine, golden hour, wrap dress
7. Bookstore — browsing shelves, stack of books, cozy cardigan (open front)
8. Brunch — outdoor cafe, avocado toast, sunglasses pushed up, linen top
9. Park walk — autumn leaves or spring blooms, casual chic, crossbody bag
10. Yoga/stretching — living room, morning light, activewear, mat

### Spiritual (Subtle, Woven Into Life)
11. Crystal grid — living room table, casual outfit, arranging crystals
12. Tarot pull — kitchen counter, morning coffee, single card, contemplative
13. Meditation corner — modern apartment nook, cushion, candles, peaceful
14. Moon ritual — balcony at night, candles, journal, city lights behind
15. Oracle deck — couch, cozy blanket, cards spread, wine nearby

### Going Out
16. Art gallery — all black outfit, contemplative, white walls
17. Wine bar — bar stool, low-cut blouse, moody lighting, cocktail
18. Night out — city street, leather jacket over dress, heels, confident walk
19. Weekend market — vintage finds, sunhat, flowy dress, browsing stalls
20. Pilates/gym — leaving studio, smoothie in hand, athleisure, glow

---

## Reference Image Setup (from character-lock skill)

### Face Lock Protocol
- Face refs in slots 1-3 (highest priority)
- Body ref in slot 4-5
- Face refs must be >= 60% of total refs
- Duplicate primary face ref if needed for weight

### Recommended Ref Array (7 slots)
```
Slot 1: face-ref-1 (close-up, primary anchor)
Slot 2: face-ref-2 (different angle)
Slot 3: face-ref-3 (different lighting)
Slot 4: face-ref-1 (DUPLICATE for weight)
Slot 5: face-ref-2 (DUPLICATE for weight)
Slot 6: body-ref (fashion/figure reference)
Slot 7: [optional scene ref for specific setting]
```

### Prompt Ref Labeling
Always include at top of prompt:
```
Reference images 1-5 show the CHARACTER'S FACE — keep this EXACT face, bone structure, eyes, jawline, hair.
Reference image 6 shows BODY TYPE and FASHION STYLE only — apply this figure and clothing style.
Do NOT generate a different woman. This must be the SAME person from references 1-5.
```

---

## NanoBanana Command

```bash
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand jade-oracle \
  --use-case character \
  --prompt "$PROMPT" \
  --ref-image "$FACE_REF1,$FACE_REF2,$FACE_REF3,$FACE_REF1,$FACE_REF2,$BODY_REF" \
  --model pro \
  --ratio 4:5 \
  --size 2K
```

### Flags
- `--brand <slug>` — Required. Set to the character's brand
- `--use-case character` — MANDATORY. Skips brand enrichment (no GAIA OS watermarks, no brand colors/logos)
- `--model pro` — Better face consistency and beauty for character work
- `--ratio 4:5` — Instagram feed standard
- `--size 2K` — Good quality without excessive file size
- `--ref-image` — Comma-separated, face refs FIRST, body ref LAST

---

## Generation Script

### Quick Generate (Single Image)
```bash
bash ~/.openclaw/skills/ig-character-gen/scripts/ig-gen.sh \
  --character jade \
  --scene "Farmers market, white wrap blouse, jeans, holding wildflowers, laughing" \
  --output ~/Desktop/jade-ig-new/
```

### Batch Generate (Full Library)
```bash
bash ~/.openclaw/skills/ig-character-gen/scripts/ig-gen.sh \
  --character jade \
  --batch 10 \
  --output ~/Desktop/jade-ig-new/
```

---

## QA Checklist (Per Image)

Before accepting any generated image:

| Check | Pass Criteria |
|-------|--------------|
| Face match | Same person as refs (eyes, nose, jawline) |
| Body type | Figure visible, matches body ref proportions |
| Setting | WESTERN location, no Asian-themed elements |
| Clothing | Shows figure (V-neck/slip/tank), matches character fashion |
| Photo quality | iPhone/candid, NOT editorial/cinematic/CG |
| Lighting | Warm natural (golden hour/candle/morning sun) |
| Hands | No deformities, natural positioning |
| Props | Real-world, relatable (wine, flowers, books, coffee) |
| Emotion | Genuine (laughing, soft smile, contemplative) — not posing |
| IG-native | Looks like it belongs on a real influencer's feed |

---

## File Conventions

```
# Character spec
workspace/data/characters/{brand}/{character}/ig-spec.json

# Face refs (locked)
workspace/data/characters/{brand}/{character}/face-refs/

# Body ref
workspace/data/characters/{brand}/{character}/body-ref.jpg

# Generated IG content
workspace/data/images/{brand}/ig-library/{character}/YYYYMMDD_*.png

# Scene prompts used
workspace/data/characters/{brand}/{character}/ig-prompts.jsonl
```

---

## Dependencies

- `nanobanana-gen.sh` — image generation (Gemini Image API)
- `character-lock` skill — face/body consistency rules
- `visual-audit.py` — QA scoring (use `--mode character`)
- `--raw` flag on nanobanana — skips brand injection
