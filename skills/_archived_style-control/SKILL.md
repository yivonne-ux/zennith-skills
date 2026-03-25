---
name: style-control
description: Explore and manage GAIA brand styles, mood presets, and generate style-controlled images. Brand visual identity management.
agents:
  - dreami
---

# Style Control — Brand Visual Identity Management

Manage, explore, and apply consistent visual styles across all GAIA brand image generation. Controls mood presets, style seeds, color palettes, and ensures brand visual consistency.

## When to Use

- Ensuring visual consistency across a brand's images
- Exploring different style directions for a brand
- Creating mood boards or style references
- Setting up style seeds for NanoBanana generation
- Debugging visual inconsistency in generated images
- Comparing brand styles side-by-side

## Procedure

### Step 1 — Load Brand Style

Load the brand DNA to understand the visual identity:

```bash
cat ~/.openclaw/brands/{brand}/DNA.json
```

Key visual fields in DNA.json:
- `colors.primary`, `colors.secondary`, `colors.accent`
- `visualStyle.mood` — emotional feel
- `visualStyle.imagery` — recurring visual themes
- `visualStyle.style` — photography, illustration, AI-generated

### Step 2 — Style Seed Management

NanoBanana supports style seeds for consistent visual generation.

#### View Existing Seeds
Check for saved style seeds:
```
~/.openclaw/workspace/data/images/{brand}/style-seeds/
```

#### Create New Style Seed
Generate a reference image that captures the brand style:

```bash
nanobanana-gen.sh generate \
  --brand {brand} \
  --prompt "{style reference prompt}" \
  --output ~/.openclaw/workspace/data/images/{brand}/style-seeds/seed-001.png
```

Good style seed prompts:
- Include brand colors explicitly (HEX values)
- Describe the mood and lighting
- Specify textures and materials
- Reference the visual style (cinematic, flat, editorial, etc.)

#### Apply Style Seed
Use a seed for consistent generation:

```bash
nanobanana-gen.sh generate \
  --brand {brand} \
  --style-seed ~/.openclaw/workspace/data/images/{brand}/style-seeds/seed-001.png \
  --prompt "{content prompt}" \
  --output {output_path}
```

### Step 3 — Mood Presets

Define reusable mood presets per brand:

| Mood | Description | Use For |
|------|-------------|---------|
| hero | Bold, high contrast, aspirational | Hero images, ads |
| lifestyle | Natural, warm, relatable | Social media, blog |
| product | Clean, minimal, focused | Product shots, e-commerce |
| editorial | Magazine-style, artistic | Content pieces, features |
| seasonal | Adapts to current season/holiday | Seasonal campaigns |
| dark | Moody, dramatic, premium | Evening/luxury content |
| bright | Airy, light, optimistic | Morning/wellness content |

Each mood preset translates to specific prompt modifiers:
- Lighting direction
- Color temperature
- Background treatment
- Composition style
- Post-processing feel

### Step 4 — Style Comparison

Generate the same concept across different styles to find the best direction:

```bash
nanobanana-gen.sh generate --brand {brand} --prompt "product hero shot, bright airy lighting" --output hero-bright.png
nanobanana-gen.sh generate --brand {brand} --prompt "product hero shot, moody dramatic lighting" --output hero-dark.png
nanobanana-gen.sh generate --brand {brand} --prompt "product hero shot, lifestyle natural setting" --output hero-lifestyle.png
```

Create a comparison grid for review.

### Step 5 — Brand Style Guide Output

Document the finalized style for the brand:

```markdown
## Visual Style Guide — {Brand}

### Color Palette
- Primary: {color} — used for: {where}
- Secondary: {color} — used for: {where}
- Accent: {color} — used for: {where}

### Photography/Image Style
- Mood: {mood description}
- Lighting: {lighting preference}
- Composition: {rules}
- Backgrounds: {preferences}
- Color grading: {warm/cool/neutral}

### Typography Direction
- Headers: {style}
- Body: {style}

### Do's
- {visual guideline}
...

### Don'ts
- {anti-pattern}
...

### Style Seeds
- seed-001.png: {description, when to use}
- seed-002.png: {description, when to use}

### Mood Presets
- {preset}: {when to use, prompt modifiers}
...
```

Save to: `~/.openclaw/brands/{brand}/style-guide.md`

### Step 6 — Cross-Brand Consistency Check

When working across multiple brands, ensure:

- No brand bleed (jade-oracle mystical elements leaking into gaia-eats)
- Each brand has distinct visual identity
- Shared GAIA elements (if any) are intentional
- NanoBanana `--brand` flag produces correct results per brand

## Agent Role

- **Dreami**: Primary and sole owner. Visual identity is Dreami's core expertise. Manages style seeds, defines mood presets, generates comparison images, creates style guides, and ensures brand visual consistency across all generated content.

## GAIA Brand Style Notes

| Brand | Visual Direction |
|-------|-----------------|
| jade-oracle | Mystical, jade/gold, Eastern aesthetic, candlelight |
| pinxin-vegan | Fresh, green, natural, clean |
| gaia-eats | Warm, appetizing, food photography |
| dr-stan | Professional, trustworthy, medical blue |
| mirra | Clean, bento-style, minimal, Japanese-influenced |
| rasaya | Earthy, wellness, amber/natural tones |
| serein | Calm, light blue/white, peaceful |
| wholey-wonder | Playful, colorful, e-commerce bright |
| gaia-recipes | Kitchen warm, ingredient close-ups, home-style |
| gaia-print | Bold, graphic, print-ready |
| gaia-learn | Educational, structured, inviting |
| gaia-os | Tech, dark mode, futuristic |
| iris | Social-first, vibrant, scroll-stopping |
| gaia-supplements | Clean, scientific, trustworthy |

## Brand Bleed Prevention

From the 2026-03-12 NanoBanana brand injection bugs:
- `--brand gaia-os` + default use_case renders brand name on products
- gaia-os DNA has "sacred futurism" which causes mystical themes to bleed
- **FIX**: Use `--raw` or `--use-case character` to skip brand enrichment when needed
- Always verify generated images match the intended brand, not a neighboring one

## Example

```
Set up style control for jade-oracle.
Create 3 style seeds: mystical dark, warm spiritual, modern clean.
Generate comparison images for a $1 reading ad.
Document in style guide.
```
