---
name: nanobanana
description: NanoBanana (Gemini Image API) best practices for character-consistent, multi-scene, brand-aligned image generation across use cases.
---

# NanoBanana — Image Generation Best Practices

NanoBanana is Google's Gemini image generation system. This skill contains best practices for generating high-quality, brand-consistent images across all GAIA brands.

## Models

| Model | ID | Best For | Max Refs |
|-------|-----|----------|----------|
| **NanoBanana** (fast) | `gemini-3-pro-image-preview` | High-volume, quick iterations | Limited |
| **NanoBanana Pro** (quality) | `gemini-3-pro-image-preview` | Professional assets, character consistency, 4K | 14 images, 5 humans |

## API

```
Endpoint: https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
Auth: x-goog-api-key: $GEMINI_API_KEY
```

### Key Parameters
- `response_modalities`: `["TEXT", "IMAGE"]`
- `aspect_ratio`: "1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"
- `image_size`: "1K", "2K", "4K" (uppercase K)

---

## 1. Character Consistency (The Core Technique)

### Step 1: Create Base Character
Define your character with MAXIMUM specificity in the first prompt:
```
A young Malaysian woman, 28 years old, with shoulder-length black hair, warm brown eyes,
wearing a sage green apron over a cream blouse, friendly smile, semi-realistic style,
soft natural lighting, clean background.
```

### Step 2: Lock Core Features
In EVERY follow-up prompt, repeat the defining traits:
```
Same character (28yo Malaysian woman, shoulder-length black hair, sage green apron,
cream blouse, warm brown eyes, friendly smile) — now shown [new scene description]
```

### Step 3: Use Reference Images (Pro only)
Upload previous outputs as reference images to anchor identity:
- Up to 14 reference images total
- Up to 5 human characters tracked simultaneously
- Up to 6 object references for product consistency

### Step 4: One Change at a Time
When editing, change ONE element per iteration:
- "Keep the character details the same (hair, apron, blouse, expression) but change the BACKGROUND to a modern kitchen"
- NOT: "Change the background, outfit, and lighting" (too many changes = drift)

### Anchoring Phrases
Always include these in prompts for consistency:
- "same character"
- "maintain facial features"
- "preserve proportions"
- "keep identity"
- "consistent with reference"

---

## 2. Multi-Scene Generation (12-Panel Storyboard)

### Technique: Sequential Scene Prompts
Describe multiple scenarios while maintaining character anchors.

### 12-Scene Campaign Template
```
Scene 1:  [Character] in morning kitchen, reaching for GAIA product on shelf
Scene 2:  Close-up of [Character]'s hands opening the product package
Scene 3:  [Character] reading the back of the package, curious expression
Scene 4:  Overhead flat lay of ingredients laid out on wooden cutting board
Scene 5:  [Character] cooking, stirring pot, steam rising, warm lighting
Scene 6:  Close-up of the dish being plated, vibrant colors
Scene 7:  [Character] tasting, delighted expression, thumbs up
Scene 8:  [Character] serving to family/friends at table, everyone smiling
Scene 9:  Close-up of the finished dish on table, styled beauty shot
Scene 10: [Character] taking photo of food with phone (meta/UGC feel)
Scene 11: Phone screen showing social media post of the dish
Scene 12: [Character] relaxing with meal, satisfied, GAIA logo visible
```

### Tips for Multi-Scene Consistency
- Generate Scene 1 first, approve it, then use as reference for all subsequent scenes
- Keep the same lighting description across scenes (e.g., "warm natural kitchen light")
- Keep the same art style descriptor (e.g., "semi-realistic, soft focus, magazine quality")
- Describe the character identically in each scene — copy-paste the character description

---

## 3. Use Case Prompt Templates

### Product Photography
```
Professional product photography of [PRODUCT NAME] by GAIA Eats.
Clean white/cream background, soft studio lighting from upper left.
Product centered, slight 15-degree angle, subtle shadow beneath.
Sharp focus on product, shallow depth of field.
Color palette: sage green packaging, gold accents, cream label.
High-end e-commerce listing quality, 4K resolution.
```

### Food Photography (Vegan)
```
Appetizing food photography of [DISH NAME], plant-based/vegan.
Styled on rustic wooden table with natural linen napkin.
Warm natural light from window, soft shadows.
Fresh herbs and ingredients scattered artfully around dish.
Steam or moisture visible for freshness.
Colors: vibrant greens, warm earth tones, GAIA sage green accent.
Magazine editorial quality, makes viewer hungry.
```

### Lifestyle Shot
```
Lifestyle photography: [CHARACTER DESCRIPTION] in [SETTING].
Candid, natural moment — not posed.
Using/enjoying GAIA [PRODUCT] as part of daily routine.
Warm, inviting atmosphere, Malaysian home/cafe setting.
Natural lighting, slightly warm color temperature.
Aspirational but relatable, Instagram-worthy.
```

### Flat Lay
```
Overhead flat lay photography on [SURFACE: marble/wood/linen].
Arranged: GAIA [PRODUCT] center, surrounded by [INGREDIENTS/PROPS].
Geometric arrangement, pleasing negative space.
Consistent lighting, no harsh shadows.
Brand colors: sage green, gold, cream accents.
Clean, organized, Pinterest-worthy composition.
```

### Before/After
```
Split image comparison:
LEFT: [Before state — plain/boring/unhealthy meal]
RIGHT: [After state — vibrant GAIA meal, colorful, appetizing]
Same angle, same lighting, same table setting.
Clear visual contrast between boring and exciting.
Dividing line or arrow between halves.
```

### Packaging Design
```
Product packaging mockup for GAIA [BRAND] [PRODUCT].
[Package type: pouch/box/jar/bottle] on [surface].
Brand colors: sage green primary, gold accents, cream background.
Clean typography, modern minimalist design.
Logo placement: [top center/bottom right].
Lifestyle context visible in background (kitchen/shelf).
Professional packaging photography quality.
```

### Recipe Step-by-Step (4-6 images)
```
Step [N] of [RECIPE NAME] recipe:
[Action description — chopping/mixing/cooking/plating].
Overhead angle, hands visible performing action.
Same cutting board/workspace as previous steps.
Same lighting (warm natural from left).
Ingredients clearly visible and identifiable.
Clean, instructional, easy to follow visually.
```

### Character/Mascot Design
```
Brand mascot character design for GAIA [BRAND]:
[Character type: animal/person/food item].
Style: [cute/modern/minimal/illustrated/3D].
Expression: friendly, approachable, warm.
Colors: sage green (#8FBC8F), gold (#DAA520), cream (#FFFDD0).
Poses: [front view / 3/4 view / waving / holding product].
White background, character sheet format.
Suitable for social media, packaging, stickers.
```

### Print-on-Demand Mockup
```
[Product type: t-shirt/mug/tote bag/notebook] mockup.
GAIA [BRAND] design featuring [DESIGN ELEMENT].
Product shown on [model wearing it / flat surface / lifestyle context].
Clean, professional e-commerce mockup style.
Design clearly visible, colors accurate.
Background: [white/lifestyle/contextual].
```

### E-Commerce Listing
```
E-commerce product listing image for GAIA [PRODUCT].
Main image: product on white background, centered, well-lit.
Product fills 85% of frame.
No text overlays, no props, clean isolation.
Multiple angles: front, back, side, detail close-up.
Consistent lighting across all angles.
Suitable for Shopee/Lazada/Amazon listing standards.
```

### Social Media Content
```
Instagram [feed/story/reel cover] image for GAIA [BRAND].
[Format: 1:1 for feed, 9:16 for story].
On-brand aesthetic: warm, natural, plant-based lifestyle.
Safe zones: avoid text/important elements in top 100px and bottom 250px.
Eye-catching, thumb-stopping visual.
Brand colors present but not overwhelming.
```

### Educational Content
```
Educational infographic-style image about [TOPIC].
Clean layout, easy to read at mobile size.
Numbered steps or sections clearly defined.
GAIA brand colors for accents and highlights.
Illustrations: simple, modern, friendly style.
Text areas with clear contrast for readability.
```

---

## 4. Brand Consistency Framework

### Color Anchors (include in every prompt)
```
GAIA Eats:    sage green (#8FBC8F), gold (#DAA520), cream (#FFFDD0)
Default:      warm natural tones, earth colors, plant greens
```

### Style Anchors (include in every prompt)
```
Style: clean, modern, warm, natural, accessible, not clinical
Lighting: warm natural light, soft shadows, golden hour feel
Photography: magazine editorial quality, appetizing, lifestyle-oriented
```

### Consistency Checklist
1. Same color palette description in every prompt
2. Same lighting description across campaign
3. Same art style descriptor (semi-realistic / photo / illustration)
4. Character descriptions copy-pasted verbatim
5. Reference images used for anchor (Pro only)
6. One change per iteration rule

---

## 5. Multi-Brand Support

This system supports multiple GAIA brands. Store brand profiles in:
`~/.openclaw/skills/nanobanana/brands/{brand-slug}.json`

### Brand Profile Schema
```json
{
  "brand_name": "GAIA Eats",
  "brand_slug": "gaia-eats",
  "tagline": "Plant-based food, Malaysian soul",
  "colors": {
    "primary": "#8FBC8F",
    "secondary": "#DAA520",
    "background": "#FFFDD0",
    "accent": "#2E8B57"
  },
  "style": "warm, natural, appetizing, accessible",
  "lighting": "warm natural light, soft shadows",
  "photography_style": "magazine editorial, lifestyle",
  "character": null,
  "products": ["rendang", "laksa paste", "tempeh chips"],
  "target_audience": "Malaysian health-conscious consumers",
  "languages": ["English", "Bahasa Malaysia"]
}
```

### Supported Brands
- **gaia-eats** — Vegan/plant-based food (current)
- **gaia-recipes** — Recipe books and cooking content
- **gaia-learn** — Online teaching and courses
- **gaia-print** — Print-on-demand merchandise
- **gaia-supplements** — Health supplements
- **[custom]** — Any new brand added via brand profile

---

## 6. Tools

### Generate via API
```bash
bash scripts/nanobanana-gen.sh generate \
  --brand gaia-eats \
  --use-case product \
  --prompt "GAIA rendang paste packaging on marble surface" \
  --size 4K \
  --ratio 1:1
```

### Generate Character Sheet
```bash
bash scripts/nanobanana-gen.sh character-sheet \
  --brand gaia-eats \
  --description "28yo Malaysian woman, friendly, sage green apron" \
  --poses "front,side,waving,cooking,tasting"
```

### Generate 12-Scene Storyboard
```bash
bash scripts/nanobanana-gen.sh storyboard \
  --brand gaia-eats \
  --character "28yo Malaysian woman in sage green apron" \
  --product "rendang paste" \
  --scenes 12
```

### Batch Generate (multiple use cases)
```bash
bash scripts/nanobanana-gen.sh batch \
  --brand gaia-eats \
  --product "rendang paste" \
  --use-cases "product,food,lifestyle,flatlay,social"
```

---

## 7. Integration with Content Factory

- Generated images → `seed-store.sh add --type image`
- Character sheets → stored in `~/.openclaw/workspace/data/characters/`
- Brand profiles → stored in `~/.openclaw/skills/nanobanana/brands/`
- Audit generated images → `audit-visual.sh audit-image <path>`
- Z-Image Turbo (MCP) used for fast iterations
- NanoBanana Pro (API) used for final quality + character consistency

## Notes
- All Gemini-generated images include SynthID watermarks
- NanoBanana Pro supports "Thinking Mode" for better composition planning
- Use multi-turn conversation for iterative refinement
- Pro model can use Google Search grounding for real-world accuracy
