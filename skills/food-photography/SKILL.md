---
name: food-photography
description: Professional food photography intelligence for AI image generation. Composition, lighting, camera params, mood, styling — everything needed to make AI-generated food look REAL. Use with NanoBanana ref-image system.
agents: [dreami, taoz]
---

# Food Photography Intelligence

Master reference for generating photorealistic food images via NanoBanana/Gemini. Based on deep research of professional food photography, top AI prompt engineers, and Yivonne's compound learnings.

## THE PROMPT FORMULA

```
[SUBJECT] + [ANGLE] + [COMPOSITION] + [LIGHTING] + [CAMERA] + [MOOD/COLOR] + [STYLING] + [TEXTURE CUES]
```

Every prompt MUST have ALL 8 components. Missing any = fake-looking output.

---

## 1. CAMERA ANGLES (pick ONE)

| Angle | Degrees | Best For | AI Prompt Term |
|-------|---------|----------|----------------|
| **Overhead / Flat-lay** | 90° | Spreads, pizza, bowls, flat dishes | `true overhead flat-lay, camera parallel to surface` |
| **Hero / 3/4** | 45° | Most dishes, universal | `45-degree angle, diner's perspective` |
| **Eye-level / Straight-on** | 0° | Burgers, stacked items, drinks | `straight-on eye-level, camera at table height` |
| **Low angle** | 15-30° | Dramatic, towering dishes | `low angle looking up, emphasizing height` |
| **Dutch / Tilted** | 30° tilt | Dynamic, editorial | `slight dutch angle, 15-degree tilt` |

---

## 2. COMPOSITION RULES (pick 1-2)

| Rule | Description | AI Prompt Term |
|------|-------------|----------------|
| **Rule of Thirds** | Subject at grid intersections | `subject positioned at right-third intersection` |
| **Golden Ratio** | 1:1.618 spiral flow | `golden ratio spiral composition, natural eye flow` |
| **Triangle** | 3 elements forming triangle | `triangular composition with three focal points` |
| **Diagonal** | Movement along diagonal | `diagonal arrangement creating dynamic movement` |
| **C-curve / S-curve** | Flowing line through frame | `S-curve composition guiding eye through frame` |
| **Negative Space** | Intentional empty area | `generous negative space, subject occupying 40% of frame` |
| **Rule of Odds** | 3 or 5 elements | `three bowls arranged with deliberate odd-number balance` |
| **Framing** | Natural frame around subject | `natural framing using props and environment` |
| **Symmetry** | Mirror balance | `symmetrical overhead composition, centered subject` |
| **Leading Lines** | Lines pointing to subject | `chopsticks and utensils creating leading lines toward main dish` |

---

## 3. LIGHTING SETUPS

### Natural Light
| Setup | Description | Mood | AI Prompt |
|-------|-------------|------|-----------|
| **Window side** | Single window, 90° to subject | Soft, editorial | `soft natural window light from camera-left, gentle shadows` |
| **Window back** | Light behind subject | Dramatic, steam glow | `natural backlight from window, rim light on subject, steam illuminated` |
| **Golden hour** | Warm low-angle sun | Warm, nostalgic | `golden hour warm sunlight, long soft shadows, 3200K color temperature` |
| **Overcast** | Diffused daylight | Clean, bright | `soft diffused overcast daylight, even illumination, no harsh shadows` |

### Studio Light
| Setup | Description | Mood | AI Prompt |
|-------|-------------|------|-----------|
| **Key + fill** | Main light + reflector | Professional | `studio key light upper-left, white reflector fill right, controlled shadows` |
| **Rembrandt** | Triangle shadow on face/subject | Dramatic | `Rembrandt lighting, defined triangular shadow, chiaroscuro` |
| **Rim/Edge** | Backlight outline | Separation | `rim light creating bright edge outline, separating subject from dark background` |
| **3-point** | Key + fill + back | Commercial | `3-point lighting at 5500K, balanced contrast` |
| **Low-key** | Minimal light, dark bg | Moody, premium | `low-key lighting, dark background, single dramatic light source` |
| **High-key** | Bright, minimal shadow | Fresh, clean | `high-key lighting, bright white background, minimal shadows, fresh clean feel` |

### Lo-fi / Film
| Setup | Description | AI Prompt |
|-------|-------------|-----------|
| **Film grain** | Analog texture | `subtle film grain texture, Kodak Portra 400 color science` |
| **Light leak** | Warm color bleed | `gentle warm light leak from upper corner, analog film feel` |
| **Soft focus** | Dreamy edges | `soft focus edges, sharp center, dreamy atmospheric quality` |
| **Warm desaturated** | Muted warm tones | `warm desaturated color palette, muted earth tones, nostalgic warmth` |

---

## 4. CAMERA PARAMETERS

### Lens Focal Length
| Lens | Use Case | AI Prompt |
|------|----------|-----------|
| **24-35mm** | Full table spread, environment | `shot with 24mm wide-angle lens, full scene visible` |
| **50mm** | Standard, natural perspective | `shot with 50mm lens, natural perspective, no distortion` |
| **85mm** | Single dish hero, compression | `shot with 85mm lens, beautiful background compression, f/2.8` |
| **100mm macro** | Extreme close-up, texture | `shot with 100mm macro lens, extreme detail, visible food texture` |

### Aperture (Depth of Field)
| f-stop | Effect | AI Prompt |
|--------|--------|-----------|
| **f/1.4-f/2** | Extreme bokeh, single element focus | `f/1.8 aperture, creamy bokeh background, razor-thin focus plane` |
| **f/2.8-f/4** | Soft background, dish in focus | `f/2.8 aperture, shallow depth of field, soft background blur` |
| **f/5.6-f/8** | Balanced, multiple dishes readable | `f/5.6 aperture, balanced depth, all dishes readable` |
| **f/11-f/16** | Everything sharp, flat-lay | `f/11 aperture, deep focus, everything sharp edge-to-edge` |

### Color Temperature
| Temp | Feel | AI Prompt |
|------|------|-----------|
| **3200K** | Warm tungsten, candlelight | `warm 3200K color temperature, candlelight warmth` |
| **4500K** | Warm daylight | `warm daylight 4500K, golden tone` |
| **5500K** | Neutral daylight | `neutral daylight 5500K, true colors` |
| **6500K** | Cool daylight, fresh | `cool daylight 6500K, crisp clean colors` |

---

## 5. MOOD & COLOR PALETTES

| Mood | Colors | Background | Props | AI Prompt |
|------|--------|------------|-------|-----------|
| **Dark Moody** | Deep brown, black, gold | Dark wood, black slate | Metal utensils, dark linen | `dark moody atmosphere, deep shadows, warm highlights on food only, dark background` |
| **Bright Airy** | White, cream, pastels | Marble, white wood | White ceramics, fresh herbs | `bright airy atmosphere, soft light, white surfaces, clean fresh feel` |
| **Rustic Warm** | Earth tones, terracotta | Worn wood, burlap | Cast iron, wooden utensils | `rustic warm atmosphere, worn textures, earth tones, cozy homey feel` |
| **Modern Minimal** | Grey, white, accent | Concrete, matte surfaces | Geometric ceramics | `modern minimal styling, clean lines, matte surfaces, single color accent` |
| **Tropical** | Greens, yellows, corals | Banana leaf, rattan | Tropical leaves, coconut | `tropical vibrant atmosphere, lush greens, natural materials` |
| **Malaysian Hawker** | Red, gold, warm brown | Dark wood, metal tray | Kopitiam cups, chopsticks | `Malaysian hawker stall aesthetic, warm ambient, street food elevated to premium` |

---

## 6. STYLING & TEXTURE CUES

### Must-include texture descriptions (makes AI images look REAL):
```
- "visible sauce texture with light catching the gloss"
- "steam rising naturally, backlit and translucent"
- "crispy edges with golden-brown Maillard reaction"
- "fresh herb leaves with visible veins and dewdrops"
- "rice grains individually distinguishable"
- "sauce drip mid-motion, gravity-natural"
- "chopstick lift with sauce trailing"
- "crumbs scattered naturally on surface"
- "oil sheen reflecting light source"
- "charred marks on grilled surface"
```

### Props that add realism:
```
- Linen napkin with natural wrinkles (never perfectly folded)
- Wooden chopsticks at casual angle
- Small condiment dish half-used
- Scattered raw ingredients (chilies, herbs, spices)
- Partially visible second dish at frame edge
- Water glass with condensation
- Crumpled receipt or menu corner
```

---

## 7. PINXIN-SPECIFIC SETTINGS

### Brand DNA Application:
```json
{
  "palette": {
    "primary": "#1C372A (dark forest green — for shadows, dark backgrounds)",
    "gold": "#d0aa7f (warm gold — for highlights, sauce sheen, rim light)",
    "background": "#F2EEE7 (light beige — for bright-airy variant)"
  },
  "mood": "Bold, clean, appetizing, proudly Malaysian, health-forward",
  "avoid": ["clinical health food look", "Western plating", "washed-out colors", "generic stock", "preachy vegan"],
  "lighting_default": "Warm natural light, high contrast, steam and smoke visible",
  "photography_style": "Bold food photography, close-up textures, Malaysian street food elevated",
  "surface": "Dark aged wood OR dark slate (moody) | Light wood (bright variant)",
  "ceramics": "Handcrafted earthenware, cream ceramic, dark stoneware — NOT white commercial"
}
```

### Template: Pinxin Hero Shot
```json
{
  "shot": "1:1 square, [ANGLE] shot",
  "subject": "EXACT [DISH] from reference image, in [BOWL TYPE] ceramic bowl",
  "composition": "[COMPOSITION RULE], subject occupying [X]% of frame",
  "lighting": "[LIGHTING SETUP], [COLOR TEMP], shadows falling [DIRECTION]",
  "camera": "shot with [FOCAL]mm lens, f/[APERTURE], [DOF DESCRIPTION]",
  "mood": "Pinxin dark forest green #1C372A mood, gold #d0aa7f warmth in highlights",
  "styling": "[PROPS], [GARNISH], [SCATTERED INGREDIENTS]",
  "texture": "[SPECIFIC TEXTURE DESCRIPTIONS — sauce, steam, crispy, grain]",
  "surface": "[BACKGROUND SURFACE] with visible [TEXTURE]",
  "avoid": "No text, no logos, no AI artifacts, no clinical health food look, no Western plating"
}
```

---

## 8. COMMON MISTAKES (from Yivonne's learnings)

1. **Angles don't match** — Food looks composited because vanishing point doesn't match background. FIX: Use single ref image, let NANO place naturally.
2. **Too many dishes** — NANO hallucinates random food with multi-dish prompts. FIX: Single food cutout as reference, don't prompt for "multiple dishes."
3. **Generic lighting** — No direction specified = flat default lighting. FIX: Always specify direction (upper-left, backlight, etc.)
4. **No texture cues** — Missing sauce gloss, steam, crispy detail. FIX: Always include 3+ texture descriptions.
5. **Wrong color temperature** — Too cool = clinical. FIX: Always specify warm (3200K-4500K) for food.
6. **Reference ratio mismatch** — Ref image ratio ≠ output ratio. FIX: Pre-process refs to match target ratio.

---

## USAGE WITH NANOBANANA

```bash
# Single hero dish (proven best approach)
bash nanobanana-gen.sh generate \
  --brand pinxin-vegan \
  --prompt '{"shot":"1:1 square, 45-degree hero angle","subject":"EXACT curry dish from reference, in dark handcrafted ceramic bowl","composition":"rule of thirds, subject at left-third, right side breathing space","lighting":"soft natural window light from upper-left, warm backlight through steam, 4500K","camera":"85mm lens, f/2.8, shallow depth of field, soft bokeh background","mood":"dark moody, Pinxin forest green shadows, gold warmth on sauce surface","styling":"wooden chopsticks at casual angle, small sambal dish half-used, scattered fresh cilantro and red chilies","texture":"visible curry sauce gloss catching light, steam rising translucent against dark background, crispy mushroom edges with golden-brown color","surface":"dark aged wood table with visible grain and warm patina","avoid":"no text, no logos, no Western plating, no clinical look"}' \
  --ref-image "/path/to/real-pinxin-curry.png" \
  --ratio 1:1 --size 2K --model pro
```
