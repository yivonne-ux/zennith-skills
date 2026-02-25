# GAIA OS — Art Style Lock
> Reverse-engineered from 5 confirmed characters (Zenni, Taoz, Dreami, Hermes, Artee)
> This is the MASTER reference. ALL new characters must match this.

## THE STYLE IN ONE SENTENCE
"Sacred Futurism — religious iconography meets post-human technology, rendered in hyperreal CG with cool-dominant tones and precious-metal warm accents."

## LIGHTING (MANDATORY)
- **Key light:** Frontal, soft, 15-30° above eye level, large diffused source
- **Color temp:** Cool-neutral (5600-6500K) — NOT warm
- **Fill ratio:** Generous 2:1 to 3:1 — shadows never below 30% midtone
- **Rim light:** Subtle cool-blue edges, supplementary not dominant
- **Self-illumination:** EVERY character has warm self-glow (gold/amber/orange) — this is CORE
- **Rule:** Cool ambient light + warm self-illumination = the signature interplay

## BACKGROUND (MANDATORY)
Two modes ONLY:
- **Light mode:** Flat pale grey (#D2D4D7 to #EBEDF0), slightly cool, no warm cream
- **Dark mode:** Deep charcoal to near-black (#0F1520), with atmospheric haze/fog
- **NO architecture, NO horizon, NO objects** — pure studio isolation
- Subtle floating particles/dust motes in dark backgrounds
- Center-bright radial gradient (brighter behind head)

## COLOR GRADING (MANDATORY)
- **Overall:** Desaturated, cool-dominant, 20-35% saturation
- **Rule: 90% monochrome cool + 10% precious-metal warm (gold/amber/copper)**
- **Shadows:** Cool blue-grey (#2A2D35 light bg, #0F1520 dark bg)
- **Highlights:** Cool-neutral on skin, warm-gold on tech/ornament
- **Midtones:** Steel-blue/slate undertone
- **Contrast:** Medium-high, gentle S-curve (lifted blacks, rolled highlights)
- **NO warm shadows. NO high saturation except gold/amber accents.**

## SKIN (MANDATORY)
- Hyper-real CG quality — ALMOST photographic but with intentional digital smoothness
- Pores at 60-70% of macro-lens visibility
- Low-moderate specular (soft, spread, not tight hotspots)
- Subtle SSS at ears, nostrils, lips (warm undertone)
- Skin tone: desaturated and cooled from reality — ethereal, not ruddy
- NO blemishes, NO asymmetry, but texture prevents wax-figure look

## COMPOSITION (MANDATORY)
- **Frontal or near-frontal** (within ±15° of center)
- **Bilaterally symmetrical** — iconic, totemic, ritualistic
- **Dead center placement** — no rule-of-thirds
- **Camera angle:** Slightly below eye level (looking UP = monumental)
- **Focal length:** 85-135mm equivalent, deep DOF
- **Figure fills 70-85% of vertical frame**
- **Negative space above head** (for halos, headpieces, crowns)

## MATERIALS
- **Gold/brass:** High reflectivity, warm specular, engraved detail
- **Black chrome:** Mirror-reflective, "liquid obsidian", deep black with tiny bright specular points
- **Sheer fabrics:** Translucent, ceremonial, gossamer, with embedded details (beading, holographic)
- **Organic + synthetic:** Rendered at SAME fidelity level — biology and technology as equal materials

## MOOD
- Sacred Futurism — deities of a technological pantheon
- Cool, still, contemplative — NO action, NO dynamic motion
- Serene authority on faces — NOT smiling, NOT aggressive
- Timeless — could be 3000 BCE or 3000 CE
- Each character in a state of BEING, not doing — ceremonial stillness
- "You are in the presence of a being that is both ancient and post-human"

## POST-PROCESSING
- Minimal to NO film grain — clean, digital, polished
- Subtle natural vignette (10-15% corner darkening)
- NO chromatic aberration, NO lens flare
- NO analog film effects

## PROMPT TEMPLATE (for recreating this style)

### Base Template
```
[CHARACTER DESCRIPTION]. Sacred futurism aesthetic, hyperreal CG render quality. 
Frontal symmetrical composition, centered figure, slightly low camera angle. 
Cool-neutral key lighting from above (5600K), generous soft fill, subtle cool-blue rim light. 
[LIGHT/DARK] background — [pale grey studio (#D2D4D7) | deep charcoal with atmospheric haze (#0F1520)]. 
Desaturated cool color grading with warm gold/amber accent lighting from [SELF-LIGHT SOURCE]. 
90% monochrome cool tones, 10% precious metal warm accents. 
Skin rendered hyperreal — subtle pores, soft specular, ethereal pallor. 
Materials: [MATERIAL DESCRIPTION — gold filigree, black chrome, sheer translucent fabric]. 
Ceremonial stillness, serene authority, divine presence. 
Medium telephoto lens, deep depth of field, no film grain, clean digital render.
```

### With NanoBanana Multi-Image Reference (8-10 slots)
```
Slot 1: Face reference image (REQUIRED)
Slot 2: Full confirmed character for style reference (e.g., zenni.png)
Slot 3: Second confirmed character for style consistency (e.g., dreami.png)
Slot 4: Attire/costume reference (OPTIONAL)
Slot 5: Body shape reference (OPTIONAL)
Slot 6: Hair reference (OPTIONAL)
Slot 7: Jewelry/accessory reference (OPTIONAL)
Slot 8: Background/mood reference (OPTIONAL — use a confirmed character's background)

Prompt: "Create a new character portrait in EXACTLY the same art style as the reference 
characters provided. Match the lighting, color grading, background treatment, skin rendering, 
and compositional approach precisely. The new character should have: [FACE from Slot 1], 
[ATTIRE from Slot 4], [BODY from Slot 5]. Sacred futurism aesthetic. Frontal symmetrical 
composition, cool-neutral lighting, desaturated tones with gold/amber warm accents."
```
