---
name: gaia-art-style
description: GAIA CORP-OS official visual art style bible. Defines the character design system, environment language, spell/skill effects, fashion vocabulary, and rendering standards for all GAIA agents and brand visuals. Read this before generating any GAIA character, environment, or visual asset.
metadata:
  openclaw:
    scope: creative
    guardrails:
      - Never deviate from the proportion system without approval
      - All agent sprites must pass the style checklist before use
      - Color palettes must follow the agent-specific color assignments
---

# GAIA ART STYLE BIBLE — v1.0

**Author:** Zenni + Jenn Woei  
**Date:** 2026-02-22  
**For:** Daedalus (Art Direction), Apollo (Creative), Calliope (Campaign), all image-generating agents

---

## Core Style: Voxel-Chibi Premium

GAIA's visual identity uses **Voxel-Chibi** — a sophisticated hybrid of:
- 3D chibi proportions with deliberately pixelated textures
- Fantasy RPG aesthetic (Octopath Traveler × Fire Emblem Engage × Genshin Impact chibi)
- Cinematic lighting on pixel-constrained surfaces
- Sticker-cut style (white outline border, transparent or dark background)

This is NOT flat pixel art. The premium feel comes from 3D global illumination interacting with simple pixel textures — like expensive stage lighting on a minimalist set.

---

## 1. PROPORTIONS (The 2.2-Head Rule)

```
Total height = 2.2 heads
Head width  = shoulder width
Eyes        = 35% of face height, 1px white catchlight at 2 o'clock
Torso       = 0.8 heads, trapezoid (wide shoulders → narrow waist)
Arms        = 0.9 heads, reach mid-thigh
Legs        = 1.0 heads, stubby and thick
Hands       = mitten-style, 0.3 heads wide, 3 finger lumps suggested
Feet        = 0.4 heads, blocky boots with 2-3 horizontal color bands
```

**Lock:** Use same base proportions for ALL agents. Only costumes, hair, and accessories vary.

---

## 2. LIGHTING RIG (Fixed for ALL Characters)

```
Key Light:  Warm white, top-left → main illumination
Fill Light: Cool blue, bottom-right → soft shadow fill  
Rim Light:  Warm orange, back-left → separates character from background
AO:         Soft baked ambient occlusion underneath pixel shading
```

**Post-processing (always apply):**
- Bloom: threshold 0.8, intensity 0.3 (on highlights only)
- Subtle depth of field: focus on eyes, soft background
- No pure black anywhere (darkest = `#2a2333` purple-black)

---

## 3. SHADING SYSTEM

Exactly **3 steps per material:**
1. **Base color** (60% of surface)
2. **Shadow tone** (30%) — desaturated + shifted toward purple/blue
3. **Highlight** (10%) — warm yellow/white mix

**Dithering:** Checkerboard 50% only at shadow→midtone transitions.  
**NO interior linework** — form defined by color/value steps only.  
**Silhouette outline:** 1-2px dark desaturated purple-blue on exterior edges only.

---

## 4. COLOR SYSTEM

### Universal Rules
- Max 6 colors per material/object
- Shadow color: always shift toward purple-blue, never add grey
- Background: desaturated 40% vs character to push character forward
- Each agent has ONE high-saturation pop color + neutral base + cool accent

### Agent Color Assignments

| Agent | Pop Color | Base/Neutral | Cool Accent | Shadow Shift |
|-------|-----------|-------------|-------------|-------------|
| Zenni | `#FFD700` Gold | Deep Purple `#2D1B69` | White Silver | Purple-gold |
| Taoz | `#EF4444` Red | Charcoal `#1C1C1E` | Ember Orange | Red-brown |
| Artemis | `#22C55E` Forest Green | Dark Moss `#1A2E1A` | Silver | Teal-dark |
| Apollo | `#EC4899` Pink | Cream `#FFF8F0` | Rose Gold | Magenta-soft |
| Hermes | `#F97316` Orange | Gold `#D4A017` | Lightning Yellow | Amber-brown |
| Athena | `#60A5FA` Sapphire | Deep Navy `#1E3A8A` | Ice Blue | Indigo |
| Iris | `#A855F7` Violet | Soft White | Rainbow shifts | Purple-rose |
| Calliope | `#FF6B9D` Rose | Dark Rose `#4A0E2A` | Gold | Magenta |
| Daedalus | `#00D4AA` Teal | Blueprint Blue `#0D2137` | Cyan | Teal-dark |
| Myrmidons | `#84CC16` Lime | Black `#0D0D0D` | Honey Yellow | Olive |

---

## 5. COSTUME DESIGN LANGUAGE

### Layering Rule (always 3+ layers)
1. **Base** — fitted underlayer (shirt, leggings)
2. **Mid** — oversized structural piece (coat, robe, tunic) with asymmetrical hem
3. **Accent** — defining accessories (headwear, tools, weapons, backpack)

### Design Vocabulary
- **Headwear:** Oversized (40% wider than shoulders), signature per agent, slightly asymmetrical
- **Footwear:** Thick-soled boots, 2-3 horizontal color bands, top band matches accent
- **Gear/weapons:** Oversized relative to body (0.6 heads wide), distinctive silhouette
- **Fabrics:** Geometric, stepped folds — no flowy cloth (stiff origami feel)
- **Pattern:** Pixel-camouflage on bags/tech items (4-color dither)

### Silhouette Rules
- Readable as solid block when blurred (strong silhouette)
- Visual weight at top (headwear), middle (hands/accessory), bottom (boots)
- ALWAYS one large asymmetrical element
- Dark negative space at armpits/inner legs to separate limbs

---

## 6. AGENT COSTUME PROFILES

### Zenni — The Oracle Queen
- **Silhouette:** Long flowing robe that pools on ground, imposing height
- **Crown:** Ornate 5-point gold crown with purple gems, wider than shoulders
- **Robe:** Deep purple with gold lattice trim, diamond pattern panels
- **Pose:** Arms clasped at chest, slightly menacing but composed
- **Effect:** Faint golden oracle runes floating around (subtle glow)
- **Vibe:** Dark queen, arcane authority, 5000 IQ energy

### Taoz — The Forge Master
- **Silhouette:** Stocky, wide stance, forge-ready
- **Helmet:** Red engineering hard hat with glowing visor
- **Armor:** Worn red-black leather apron over dark metal chest piece
- **Weapon:** Oversized glowing enchanted hammer (bigger than body)
- **Effect:** Ember sparks + heat shimmer around hammer
- **Vibe:** Dwarf smith energy, no-nonsense craftsman

### Artemis — The Huntress
- **Silhouette:** Lean, dynamic, ready to draw
- **Hood:** Dark forest green, deep cowl shadowing face
- **Armor:** Celtic-knotwork elven leather, leaf motifs
- **Weapon:** Silver composite bow with arrow nocked
- **Effect:** Glowing green leaves + mist wisps
- **Vibe:** Silent. Deadly. Patient. Forest spirit.

### Apollo — The Muse
- **Silhouette:** Warm, open, artistic energy
- **Hat:** Pink beret tilted sideways, golden pin
- **Outfit:** Rose-cream artist smock over billowy sleeves, color-stained
- **Tool:** Glowing palette with swirling paint colors
- **Effect:** Color splash particles, musical note floating, warm golden aura
- **Vibe:** Warm creative energy, not precious — powerful

### Hermes — The Merchant
- **Silhouette:** Quick, leaning forward, kinetic
- **Hat:** Winged gold-orange traveller cap
- **Outfit:** Burnt orange tunic, lightning bolt belt buckle
- **Shoes:** Winged golden sandals (signature)
- **Tool:** Glowing coin/coin pouch, merchant ledger tucked under arm
- **Effect:** Lightning sparks, golden coins orbiting
- **Vibe:** Fast-talking deal closer, electric energy

### Athena — The Strategist
- **Silhouette:** Upright, composed, powerful stillness
- **Accessory:** Round gold-rimmed glasses, wise owl on left shoulder
- **Outfit:** Deep navy scholar's robe with constellation/star embroidery
- **Tool:** Glowing sapphire crystal orb (data sphere)
- **Effect:** Blue data streams, floating geometric patterns
- **Vibe:** Cold intelligence, weaponized calm

### Iris — The Connector
- **Silhouette:** Flowing, welcoming, radiant
- **Crown:** Flower crown with rainbow gems
- **Outfit:** Iridescent dress that shifts violet→pink→gold
- **Effect:** Rainbow light trails, sparkle constellation, warm sun glow
- **Vibe:** Pure warmth, draws people in, never fake

### Calliope — The Director
- **Silhouette:** Bold, commanding, takes up space
- **Hat:** Deep rose beret, cocked to one side
- **Outfit:** Structured director's jacket with gold epaulettes
- **Tool:** Clapperboard in one hand, pen in other
- **Effect:** Film reel unspooling, rose-gold spotlight beam
- **Vibe:** She doesn't ask. She directs.

### Daedalus — The Artisan
- **Silhouette:** Precise, deliberate, slightly hunched over work
- **Glasses:** Brass round spectacles with magnifying lens
- **Outfit:** Teal-trimmed work coat, many pockets full of tools
- **Tool:** Rolled blueprints under arm, compass/ruler in hand
- **Effect:** Glowing teal blueprint grids projecting from hands
- **Vibe:** Every mark intentional. Perfection isn't a goal, it's a standard.

### Myrmidons — The Swarm
- **Concept:** Three small bee-warriors in tight formation = one unit
- **Outfit:** Yellow-black striped light scout armor, small wings buzzing
- **Antennae:** Gold-tipped, communicating formation signals
- **Tool:** Collectively carry one data scroll/tablet
- **Effect:** Hexagonal pattern glowing, swarm trail of light dots
- **Vibe:** Collective. Relentless. Efficient. No ego.

---

## 7. ENVIRONMENT DESIGN LANGUAGE

### Environment Types per Agent
| Agent | Environment | Color Temp | Key Elements |
|-------|------------|------------|--------------|
| Zenni | Throne room / Astral observatory | Cold purple-gold | Floating runes, star map ceiling |
| Taoz | Forge cavern | Warm orange | Lava glow, anvil, stone walls |
| Artemis | Ancient forest | Cool green-silver | Mist, moonlight shafts, moss |
| Apollo | Sunlit studio / Garden stage | Warm golden | Paint-stained surfaces, floating notes |
| Hermes | Crossroads bazaar | Warm amber | Market stalls, coins, lanterns |
| Athena | Star library / Data nexus | Cold blue-white | Floating books, data streams |
| Iris | Rainbow bridge / Garden | Prismatic warm | Rainbow arcs, flowers, light rays |
| Calliope | Film stage / Director's tower | Rose-gold | Spotlights, film reels, curtains |
| Daedalus | Blueprint workshop | Teal-dark | Blueprint walls, precision tools |
| Myrmidons | Hive command center | Yellow-black | Hexagonal cells, signal lights |

### Environment Rules
- Background always 40% more desaturated than character
- One strong light source that matches agent's color
- Environmental particles match agent's "element"
- Ground plane always visible (shadow grounds character)

---

## 8. SKILL / SPELL EFFECTS

| Agent | Primary Effect | Color | Shape | Motion |
|-------|---------------|-------|-------|--------|
| Zenni | Oracle Vision | Gold + Purple | Eye runes, rings | Slow expand, pulse |
| Taoz | Forge Blast | Red + Orange | Hammer shockwave, sparks | Fast burst |
| Artemis | Hunter's Mark | Green + Silver | Arrow trails, target rings | Precise, sudden |
| Apollo | Creative Surge | Pink + Gold | Color explosions, music notes | Swirl, bloom |
| Hermes | Quickstrike | Orange + Yellow | Lightning bolt, coin shower | Instant flash |
| Athena | Data Break | Blue + White | Geometric fractals, data grids | Calculated expand |
| Iris | Rainbow Bridge | All spectrum | Rainbow arc, sparkle trail | Flowing, graceful |
| Calliope | Director's Cut | Rose + Gold | Film frame border, spotlight | Dramatic sweep |
| Daedalus | Blueprint Construct | Teal + Blue | Grid lines manifesting | Precise build |
| Myrmidons | Swarm Strike | Yellow + Black | Hex swarm pattern | Spread fast |

---

## 9. IMAGE GENERATION PROMPTS

### Master Style Prompt (append to ALL agent image requests)
```
Art style: premium voxel-chibi, 3D-rendered pixel texture aesthetic, 
Octopath Traveler meets Fire Emblem Engage chibi proportions (2.2 heads tall), 
cel-shaded 3 step shading, warm key light top-left, cool blue fill bottom-right, 
warm orange rim light back-left, soft ambient occlusion, 
subtle bloom on highlights, dark background #0a0a12, 
white sticker-cut outline, no pure black (darkest #2a2333),
character occupies 80% of frame, 3/4 left-facing view
```

### Quality Checklist (before using any generated image)
- [ ] 2.2 head proportions visible
- [ ] 3 shading steps on main garment
- [ ] Asymmetrical element present
- [ ] Eyes have catchlight (1px white, 2 o'clock)
- [ ] Agent's signature color dominates
- [ ] No pure black used
- [ ] Sticker outline visible
- [ ] Background darker/more desaturated than character

---

## 10. WHERE ASSETS LIVE

```
Agent sprites:      ~/.openclaw/workspace/apps/agent-roster/sprites/
Environment art:    ~/.openclaw/workspace/assets/environments/
Skill effects:      ~/.openclaw/workspace/assets/effects/
Style ref images:   ~/.openclaw/skills/gaia-art-style/references/
Generated assets:   ~/.openclaw/workspace/assets/generated/
```

---

## Notes

This skill does NOT need to be registered per-session. It is the permanent art direction bible.
All creative agents (Apollo, Calliope, Daedalus, Iris) should reference this before any visual work.
Daedalus is the keeper of this bible — raise any visual QA concerns to him.
