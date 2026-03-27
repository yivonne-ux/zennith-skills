## 7. SPACING, PROPORTION & VISUAL RHYTHM

### The Golden Ratio (phi = 1.618...)

- Ratio between two numbers where a/b = (a+b)/a = 1.618...
- Found throughout nature: nautilus shells, sunflower seeds, hurricanes, galaxies
- Le Corbusier's "Modulor" system: entire architectural proportion system based on golden ratio + human body
- In design: determines relationships between elements, not absolute sizes

**Application rules:**
- Multiply body text by 1.618 for heading size
- Content area to sidebar ratio: 1.618:1
- Padding ratios between nested elements
- Logo construction: proportional relationships between parts

### Fibonacci Sequence in Spacing

0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610...

**Small range (8-55)**: margins, line heights, font sizes, component padding
**Large range (144-987)**: column widths, section dimensions, page proportions

Each number divided by the previous approaches 1.618 — the golden ratio emerges from the sequence itself.

**Practical spacing system using Fibonacci:**
- XS: 8px
- SM: 13px
- MD: 21px
- LG: 34px
- XL: 55px
- XXL: 89px

### Optical vs Mathematical Alignment

**The core truth**: what is mathematically correct can still look WRONG because human perception is full of quirks and biases.

**Key optical adjustments:**
1. **Circle vs square**: Circle of same width/height as a square appears smaller. Must be slightly larger to look equal.
2. **Triangle in square**: Play button centered mathematically appears to lean left. Shift right ~4% of width.
3. **Text baseline**: Optically center text by accounting for ascenders/descenders, not mathematical bounding box.
4. **Rounded letter overshoot**: O, S, C extend slightly beyond baseline and cap height to appear equal to flat letters like H, E.
5. **Weight distribution**: Heavy visual elements need more space below them than above to appear balanced.

**Design mantra**: the eye rules. Adjust until it LOOKS right, then verify your adjustments were consistent.

### Visual Weight and Balance

Visual weight is determined by:
- **Size** — larger = heavier
- **Color** — darker/saturated = heavier; warm colors advance (feel closer/heavier)
- **Texture** — complex textures feel heavier than smooth surfaces
- **Position** — elements further from center carry more visual weight (leverage principle)
- **Isolation** — single element surrounded by space draws more attention = feels heavier
- **Detail** — intricate elements feel heavier than simple ones

**Balance types:**
- **Symmetrical**: equal weight on both sides of center axis. Formal, stable, traditional.
- **Asymmetrical**: unequal but balanced through strategic placement. Dynamic, modern, energetic.
- **Radial**: elements radiate from a center point. Focused, dynamic.

### Whitespace Hierarchy

More space = more importance. The amount of whitespace around an element signals its rank:
- **Macro space** (between major sections): 80-120px or more
- **Meso space** (between groups within a section): 32-64px
- **Micro space** (between related items): 8-24px
- **Intimate space** (within components): 4-16px

