## 2. Prompt Architecture

Every prompt follows this 7-part structure:

```
[Subject] + [Setting/Scene] + [Lighting] + [Style] + [Mood] + [Technical] + [Brand Anchor]
```

**Example breakdown:**
```
[A vibrant acai bowl with arranged toppings of granola, banana slices, and coconut flakes]
+ [on a white marble tabletop with morning sunlight streaming through a window]
+ [bright high-key lighting, clean whites, sunrise tones, 5500K]
+ [editorial food photography, magazine quality, sharp focus]
+ [energetic, fresh, optimistic morning ritual feel]
+ [overhead angle, 1:1 aspect ratio, 4K resolution, shallow depth of field]
+ [Wholey Wonder brand — purple #9C27B0 accent napkin, gold #FFD700 spoon, white background]
```

### Lighting Presets

| Preset | Description | Brands |
|--------|-------------|--------|
| **Food Hero** | Soft diffused top light, slight backlight for steam/freshness, warm 4500K | pinxin-vegan, mirra, gaia-eats, gaia-recipes |
| **Clean E-commerce** | Even white studio lighting, no shadows, 5500K daylight | dr-stan, gaia-supplements, gaia-print |
| **Lifestyle Warm** | Golden hour window light, soft shadows, warm 3500K | gaia-eats, wholey-wonder, gaia-recipes |
| **Wellness Calm** | Soft natural light, airy, high-key, cool 5000K | serein, wholey-wonder, rasaya |
| **Dark Moody** | Dramatic side lighting, deep shadows, rich contrast | jade-oracle, gaia-os, iris, gaia-learn |
| **Flat Lay** | Even overhead lighting, minimal shadow, slightly warm 4500K | all brands (product flat lays) |
| **Heritage Warm** | Warm amber light, soft shadows, kitchen hearth, candlelight 3000K | rasaya |
| **Sacred Futurist** | Dramatic rim lighting, volumetric atmosphere, dual light sources | gaia-os, iris |

### Style Presets

| Preset | Description | Brands |
|--------|-------------|--------|
| **Editorial** | Magazine-quality, styled, aspirational | pinxin-vegan, mirra, gaia-eats |
| **UGC/Authentic** | iPhone-quality, natural, unposed, slightly imperfect | pinxin-vegan, wholey-wonder, gaia-recipes |
| **Minimalist** | Clean, lots of white space, product-focused | dr-stan, gaia-supplements, serein |
| **Vibrant** | Saturated colors, energetic, pop | wholey-wonder, gaia-print, pinxin-vegan |
| **Organic** | Natural textures, earth tones, handmade feel | rasaya, gaia-eats, gaia-recipes |
| **Clinical-Warm** | Science-meets-nature, clean but not sterile | dr-stan, gaia-supplements |
| **Heritage** | Traditional, warm, grandmother's kitchen | rasaya |
| **Sacred Futurist** | Transhumanist baroque, hyper-realistic digital couture | gaia-os, iris |

### NanoBanana Formatting Notes

All prompts in this library are formatted for direct use with `nanobanana-gen.sh`. Key conventions:
- **Aspect ratio**: Noted in `[RATIO]` tag — use with `--ratio` flag
- **Style seed**: Prompts marked `[SEED-COMPATIBLE]` work with `--style-seed` for campaign consistency
- **Reference slots**: Prompts marked `[REF: product|style|logo]` benefit from `--ref-image` hybrid approach
- **Size**: Default 2K for social, 4K for hero/e-commerce unless noted

