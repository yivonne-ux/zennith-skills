# MIRRA VISUAL DNA
*Content generation guide for mirra.eats — built from deep reference analysis*

---

## CAT04: PURE VIBE SPARKLE — Visual DNA

### What the category IS (from pixel analysis of all 10 refs)

**Camera feel**: Contemporary smartphone / digital camera. NOT film, NOT vintage grain.
Clean, controlled, modern digital capture. Think iPhone or Sony Cybershot Y2K.

**Lighting**: Soft natural window light or warm indoor ambient. No studio flash, no ring light.
Warm golden-hour/afternoon tones. Directional but never harsh.

**Color palette**:
- Warm dominant: amber, golden, peachy-rose, blush pink, dusty mauve
- Secondary: lavender, cream/ivory, champagne gold
- Cool accents: soft blue-gray (for contrast only)
- Post-processing: warmth +15-25%, slight desaturation, contrast -5

**Depth of field**: Shallow to moderate. Macro/close-up capability.
Hero subject sharp. Background softly blurred (not extreme bokeh).

**The sparkle system** (3 tiers):
1. NATURAL: Physical glitter/iridescent material in the photo (cat bath, glitter heart, Y2K device)
2. OVERLAY: Digital lens-flare stars + micro-glitter dots added in post-processing
3. HYBRID: Both (most images)

**Sparkle color**: Pinkish-white `(255, 242, 252)` for lens flares + multicolor micro-dots
(pink, gold, lavender, icy blue) for background texture.

**Subject realness spectrum**:
- 50% real objects in real conditions (balloon, beach, digicam, glitter heart)
- 30% real objects + heavy digital treatment (vinyl, lipstick mirror, roses)
- 20% pure fantasy composition (queen cat, laser cat)

**Objects that fit this category**:
- Animals being dramatically extra (cats with crowns, accessories, reading books)
- Y2K/vintage tech with glitter surfaces (Casio, digicam, pager on pink glitter)
- Hands/nails with crystal embellishments holding small luxury items
- Everyday items given luxury treatment (wine on beach, balloon on concrete)
- Self-love intimate gestures (lipstick on mirror, bath reading)

**Objects that DON'T fit**:
- Professional product/editorial shots (too polished)
- Generic landscapes or travel photography
- Bento boxes or food (wrong category)
- People's faces (cat04 avoids faces — objects and close-ups only)

---

## MODEL RECOMMENDATIONS BY USE CASE

### Best for generating base images matching Mirra aesthetic

**1st choice: FLUX.1 Kontext [max] multi — via fal.ai**
`fal-ai/flux-pro/kontext/max/multi`
- Takes up to 10 reference images as style input
- Generates new subjects in the SAME style/atmosphere as refs
- Cost: ~$0.05–0.08/image
- Python: `pip install fal-client`

**2nd choice: FLUX.1.1 [pro] Ultra with Raw Mode — via fal.ai**
`fal-ai/flux-pro/v1.1-ultra`
- Built specifically to counteract "too polished" problem
- No reference images needed, works from prompt alone
- Cost: ~$0.05–0.06/image

**3rd choice: FLUX.1 [dev] + FilmPortrait LoRA — via fal.ai**
`fal-ai/flux-lora` + `Shakker-Labs/FilmPortrait`
- Cheapest: ~$0.01–0.02/image
- Good for volume/drafting
- Less consistent without reference input

**Avoid for this use case**:
- Gemini (gemini-3-pro-image-preview) — too polished, fights "candid" at architecture level
- Adobe Firefly — trained on curated stock, same problem
- Ideogram — text-in-image specialist, not candid photography

---

## PROMPT FRAMEWORK FOR BASE IMAGE GENERATION

### Layer structure (stack these together):

**Layer 1 — Camera medium declaration:**
```
shot on iPhone close-up | contemporary phone photograph |
casual snapshot | handheld digital photo | natural capture
```

**Layer 2 — Imperfection signals (fight the "clean render" bias):**
```
soft focus background | slight depth of field blur |
natural exposure | casual framing | handheld slight softness
```
NOTE: Do NOT use grain/film/vintage — cat04 refs are clean digital, not vintage film

**Layer 3 — Color anchors:**
```
warm amber tones | blush pink | soft golden light |
slightly desaturated | peachy-rose palette | champagne warm
```

**Layer 4 — Subject specifics** (keep short, object-focused):
```
[describe the actual object/scene — no faces]
```

**Layer 5 — Lighting:**
```
soft natural window light | warm indoor ambient |
diffused afternoon light | no studio lighting
```

**Negative prompts to always include:**
```
professional photography, studio lighting, studio setup,
commercial product shot, harsh lighting, ring light, softbox,
overly sharp, airbrushed, perfect lighting, stock photo,
CGI, render, 3D, illustration, cartoon
```

### Full assembled prompt example:
```
contemporary phone photograph, close-up, soft natural window light,
a vintage pink Casio organizer lying flat on a surface covered in
dense iridescent pink micro-glitter, warm amber blush tones,
slightly desaturated, shallow depth of field, background blurred softly,
casual framing, handheld softness, real object real photo, no text visible
```

---

## POST-PROCESSING PIPELINE

After AI generates the base image, apply in this order:

1. **Fit to 4:5 (1080×1350)**
2. **Mirra filter stack**:
   - Blush pink overlay: `(245, 225, 218)` at alpha 42–68 depending on existing warmth
   - Desaturation: 0.70–0.75
   - Brightness lift: +4%
   - Contrast: -5%
3. **Sparkle layer** (varies by image tone):
   - Dark backgrounds: lens flares only (22–30, size 8–20px)
   - Light backgrounds: vignette first, then lens flares + micro-glitter dots
   - Dense glitter refs (cat bath, vinyl): lens flares 28–32, size 10–24px
4. **Film grain**: `np.random.normal(0, 0.016 * 255, arr.shape)`
5. **Text overlay**: Mabry Pro Regular, centered at y_frac of visual space

---

## QUOTE TONE GUIDE (CAT04)

Voice: Girlboss. Unapologetic. Soft but sharp. No exclamation marks.
NO brand/food references. NO hard sell. Pure vibe only.

Examples that work:
- "she doesn't need permission."
- "romanticize everything."
- "curate your world carefully."
- "beauty sleep is a business expense."
- "high maintenance is self-respect."
- "she radiates on purpose."

Examples that DON'T work:
- "order your bento today!"
- "healthy eating made fun"
- "mirra eats 🌸"

---

---

## CAT02: GLITTER BILLBOARD QUOTE — Visual DNA

**Camera angle**: 10–30° UPWARD (looking slightly up at sign). OPPOSITE of cat04. Never overhead.

**Text role**: Text IS the architectural surface — billboard/marquee/window/sign. Never a Python overlay added after.

**Sign types**: Fantasy glitter billboard · Real cinema marquee (letter tiles) · Rhinestone 3D marquee · Shop window glass decal · Vintage roadside painted sign

**Two color modes**:
- Warm dusty pink (peach/cream/blush) — cinema, roadside sign
- Contrast pink-on-dramatic-sky (dark blue-purple) — billboard

**Sign occupies 40–70% of frame. Asymmetric composition.**

**Sparkle**: Heavy star-field overlay, 25–42 flares, size 8–28px. More dramatic than cat04.

**Copywriting**: Girlboss energy. Independent woman. Slightly rebellious. High shareability.
Intimate, relatable to women who hustle. 3–6 words max for AI text accuracy.
Examples: "UNBOTHERED IS A LIFESTYLE" · "SHE CHOSE HERSELF" · "BUILDING IN SILENCE"

---

## CAT08: TYPOGRAPHIC QUOTE — Visual DNA

**Core concept**: Typography IS the entire visual. No photo, no background image. Pure type design.

**Always uses MIXED fonts** (never single font throughout):

| Design | Font System | Character |
|--------|------------|-----------|
| Script handlettering | Flowing casual script (Sacramento/Dancing Script) on near-white | Sweet, personal, encouraging |
| Document/form | Bold condensed header + tracked sans labels + gestural script body | Intimate note-to-self, paper texture |
| Mixed display | Small elegant script accent + MASSIVE high-contrast display serif (hero word fills frame) | Editorial, fashion, maximalist |
| Rhythmic contrast list | Bold sans "She is" + Italic serif descriptors, repeating | Pinterest-perfect affirmation list |
| Full-bleed poster | Single ultra-heavy display font, one word per line, radial gradient bg | Maximum impact, shareable poster |

**Color system**: Monochromatic per image. One text color, one/gradient bg.
- Original refs: deep crimson `(185, 25, 40)` on pale pink / candy pink / gradient
- Mirra version: warm dusty rose `(172, 55, 75)` on Mirra blush / candy pink / blush-lavender gradient

**Mirra filter adaptation for typography**:
- Sparkle: MINIMAL (3–6 flares only, corners only, NEVER over text)
- Overlay alpha: 20–30 (much lighter than photo-based cats)
- Desaturation: 0.85–0.92 (subtle)
- Film grain: lighter (0.012 × 255)

**Fonts in use (mirra-workflow/fonts/):**
- `Sacramento-Regular.ttf` — casual handlettering script (designs 1, 3 accent)
- `DancingScript-Bold.ttf` — gestural marker script (design 2 body)
- `BodoniModa-BoldItalic.ttf` — HIGH CONTRAST display serif (design 3 hero word)
- `CormorantGaramond-BoldItalic.ttf` — elegant italic serif (design 3 support)
- `ClashDisplay-Medium.ttf` — bold contemporary sans (design 4 labels)
- `InstrumentSerif-Italic.ttf` — classic book italic (design 4 descriptors)
- `Fraunces-BlackItalic.ttf` — editorial heavy italic (design 5 poster)
- `BebasNeue-Regular.ttf` — ultra condensed caps (design 2 header)

**Generation method**: Pure Python/PIL — ZERO AI models needed. All typography is programmatic.

---

## MODEL SELECTION RULES (learned from production)

### By image source type:

| Source | Best model | Why |
|--------|-----------|-----|
| AI-composite / stylized image | `fal-ai/nano-banana-pro/edit` | Gemini 3 Pro understands scene semantically, ~94% text accuracy |
| REAL photograph (physical signs, marquees, painted text) | `fal-ai/flux-pro/kontext/max` | Edits pixel-by-pixel, new text inherits material texture/depth/lighting |
| Generate new scene with text in it | `fal-ai/ideogram/v3` with `magic_prompt_option: "OFF"` | Best text-in-scene, 90–95% accuracy, supports 3 style refs |
| New photorealistic candid scene (no text) | `fal-ai/flux-pro/v1.1-ultra` with `raw: True` | Counteracts "too polished" bias |
| Edit existing image (any element) | `fal-ai/flux-pro/kontext/max` (highest fidelity) or `/kontext` (faster) | Preserves scene context |

### Text accuracy tips:
- **Always wrap exact text in single quotes**: `"Replace 'OLD' with 'NEW'"`
- **Spell out letters**: `"T-H-E A-U-D-A-C-I-T-Y T-O T-H-R-I-V-E"`
- **3–6 word quotes** have highest AI text accuracy. 7+ words degrades quickly.
- **Nano Banana Pro edit**: use `resolution: "2K"` for better text detail
- **FLUX Kontext max**: use `guidance_scale: 4.0`, `num_inference_steps: 40`

---

## CONTENT CATEGORIES (all 8)

| Cat | Name | Status |
|-----|------|--------|
| cat01 | tbd | pending |
| **cat02** | **glitter-billboard-quote** | **done** |
| cat03 | tbd | pending |
| **cat04** | **pure-vibe-sparkle** | **done** |
| cat05 | tbd | pending |
| cat06 | tbd | pending |
| cat07 | tbd | pending |
| **cat08** | **typographic-quote** | **in progress** |
