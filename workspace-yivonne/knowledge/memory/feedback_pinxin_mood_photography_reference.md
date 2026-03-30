---
name: Pinxin Photography Mood — Reference-Based Color Direction
description: CRITICAL. 4 mood reference images define Pinxin's color/photography DNA. Use as Image 1 structural anchor for ALL Pinxin production. Prompt-only color direction failed — must be reference-based.
type: feedback
---

## PINXIN PHOTOGRAPHY MOOD — REFERENCE-BASED (March 24, 2026)

**Prompt-only color direction FAILED.** Adding "natural daylight 5200K, muted, not reddish" to prompts did NOT fix the warm/golden cast. NANO's training data defaults to "food blog" warmth. The ONLY reliable fix is using a mood reference image as Image 1 — NANO copies the color palette from whatever it sees.

### 4 MOOD REFERENCES (saved to both locations)

| File | Mood | Color DNA | Best For |
|------|------|-----------|----------|
| `mood-lakehouse-burgundy.jpg` | Private dining, elegant | Burgundy/terracotta bg, cream ceramics, warm but restrained | Single hero dish, editorial |
| `mood-qing-chiaroscuro.jpg` | Magazine editorial | Black surface + terracotta wall, dramatic side light | Dark/dramatic ads, food-forward |
| `mood-nanhotpot-green-gold.jpg` | Luxury Chinese restaurant | Deep forest green + gold hardware, textured bg | PX Green palette ads, multi-dish |
| `mood-leehoma-sage-heritage.jpg` | Heritage cultural dining | Sage/celadon green, warm wood, vintage props | Heritage/cultural ads, family energy |

**Locations:**
- Pinxin: `04_references/format-specific/mood-photography/`
- Shared: `_WORK/_shared/references/mood-photography/`

### COMMON DNA ACROSS ALL 4

1. **Deep rich backgrounds** — burgundy, forest green, sage, black. NEVER white/cream backgrounds.
2. **Muted overall saturation** — food pops because BACKGROUND is desaturated, not because food is over-graded
3. **Shallow depth of field** — food sharp, background soft
4. **Single directional light** — dramatic but natural, coming from window/left
5. **Cool shadows** — shadows have blue/grey undertone, not warm brown
6. **Chinese heritage props** — ceramics, dark wood chopsticks, linen napkins, gold spoons
7. **Magazine editorial quality** — NOT "food blog", NOT "instagram", NOT "home kitchen"
8. **Tactile surfaces** — visible wood grain, ceramic texture, fabric weave

### HOW TO APPLY — Reference-Based Workflow

```
OLD (failed): Mood in prompt text → NANO ignores, outputs warm/golden anyway
NEW (correct): Mood reference as Image 1 → NANO copies the color palette from the image
```

**For each ad concept, choose the mood ref that best matches:**
- BOFU promo/identity gimmick → `mood-nanhotpot-green-gold.jpg` (PX Green + gold)
- Food hero/editorial → `mood-lakehouse-burgundy.jpg` or `mood-qing-chiaroscuro.jpg`
- Family/abundance → `mood-leehoma-sage-heritage.jpg`
- Retarget → `mood-nanhotpot-green-gold.jpg` (dark, premium urgency)

**Production flow with mood reference:**
1. Choose mood ref based on ad concept
2. Resize mood ref to 4:5 (1080×1350)
3. Upload as Image 1 (structural + color anchor)
4. Upload food cutout as Image 2
5. Prompt describes the AD CONCEPT but NANO inherits color from Image 1
6. Two-pass: 4:5 → extend → 9:16

### WHAT THIS REPLACES
- Removes `COLOR_DIRECTION` text block from prompts (didn't work)
- Format-specific references (receipt, bold-typography, etc) are now SECONDARY to mood
- The mood reference sets the COLOR, the concept prompt sets the LAYOUT

### W3 BATCH FAILURE ANALYSIS
- Round 1-4: All outputs too warm/golden/reddish despite text-based color instructions
- User provided 4 mood references showing the CORRECT direction
- The gap was fundamental: NANO's color output is driven by what it SEES (Image 1), not what it READS (prompt text)
- Same lesson as "reference = output structure" — reference = output COLOR too
