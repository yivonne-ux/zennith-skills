
## 9. Mood Presets Taxonomy (Migrated from style-control)

Reusable mood presets that translate to specific prompt modifiers. Apply per brand to maintain visual consistency.

| Mood | Description | Use For | Prompt Modifiers |
|------|-------------|---------|-----------------|
| **hero** | Bold, high contrast, aspirational | Hero images, ads | Strong directional lighting, high contrast, dramatic composition, saturated colors |
| **lifestyle** | Natural, warm, relatable | Social media, blog | Golden hour window light, soft shadows, warm 3500K, candid framing |
| **product** | Clean, minimal, focused | Product shots, e-commerce | Even white studio lighting, no shadows, 5500K daylight, tight crop |
| **editorial** | Magazine-style, artistic | Content pieces, features | Dramatic side lighting, styled composition, shallow depth of field |
| **seasonal** | Adapts to current season/holiday | Seasonal campaigns | Season-specific color grading, holiday props, festive lighting |
| **dark** | Moody, dramatic, premium | Evening/luxury content | Low-key lighting, deep shadows, rich contrast, warm amber accents |
| **bright** | Airy, light, optimistic | Morning/wellness content | High-key lighting, overexposed whites, cool 5000K, airy negative space |

Each mood preset encodes: lighting direction, color temperature, background treatment, composition style, and post-processing feel.

## 10. Style Comparison Methodology (Migrated from style-control)

When exploring visual directions for a brand, generate the same concept across different moods to find the best direction:

```bash
# Generate the same subject with different mood treatments
nanobanana-gen.sh generate --brand {brand} --prompt "product hero shot, bright airy lighting" --output hero-bright.png
nanobanana-gen.sh generate --brand {brand} --prompt "product hero shot, moody dramatic lighting" --output hero-dark.png
nanobanana-gen.sh generate --brand {brand} --prompt "product hero shot, lifestyle natural setting" --output hero-lifestyle.png
```

Create a comparison grid for review. This helps:
- Identify which mood best matches the brand DNA
- Reveal unexpected style combinations that work
- Build consensus with stakeholders before committing to a style direction
- Ensure no brand bleed between neighboring brands

### Cross-Brand Consistency Check

When working across multiple brands, verify:
- No brand bleed (jade-oracle mystical elements leaking into gaia-eats)
- Each brand has distinct visual identity
- Shared GAIA elements (if any) are intentional
- NanoBanana `--brand` flag produces correct results per brand

## 11. Style Seed Management (Migrated from style-control)

### Style Seed Storage

```
~/.openclaw/workspace/data/images/{brand}/style-seeds/
```

### Creating a Style Seed

Generate a reference image that captures the brand style:

```bash
nanobanana-gen.sh generate \
  --brand {brand} \
  --prompt "{style reference prompt}" \
  --output ~/.openclaw/workspace/data/images/{brand}/style-seeds/seed-001.png
```

Good style seed prompts should:
- Include brand colors explicitly (HEX values from DNA.json)
- Describe the mood and lighting
- Specify textures and materials
- Reference the visual style (cinematic, flat, editorial, etc.)

### Applying a Style Seed

Use a seed for consistent campaign generation:

```bash
nanobanana-gen.sh generate \
  --brand {brand} \
  --style-seed ~/.openclaw/workspace/data/images/{brand}/style-seeds/seed-001.png \
  --prompt "{content prompt}" \
  --output {output_path}
```

### Brand Style Guide Output

Document finalized styles per brand at: `~/.openclaw/brands/{brand}/style-guide.md`

Include: color palette with usage rules, photography/image style, lighting preferences, composition rules, background preferences, color grading direction, do's and don'ts, active style seeds with descriptions, and mood presets with when-to-use guidance.

### Brand Bleed Prevention

From the 2026-03-12 NanoBanana brand injection bugs:
- `--brand gaia-os` + default use_case renders brand name on products
- gaia-os DNA has "sacred futurism" which causes mystical themes to bleed
- **FIX**: Use `--raw` or `--use-case character` to skip brand enrichment when needed
- Always verify generated images match the intended brand, not a neighboring one
