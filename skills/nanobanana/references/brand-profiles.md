# Multi-Brand Support & Brand Profiles

## Brand Consistency Framework

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

## Brand Profile Schema

Store brand profiles in: `~/.openclaw/skills/nanobanana/brands/{brand-slug}.json`

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

## Supported Brands
- **gaia-eats** — Vegan/plant-based food (current)
- **gaia-recipes** — Recipe books and cooking content
- **gaia-learn** — Online teaching and courses
- **gaia-print** — Print-on-demand merchandise
- **gaia-supplements** — Health supplements
- **[custom]** — Any new brand added via brand profile

## Integration with Content Factory

- Generated images -> `seed-store.sh add --type image`
- Character sheets -> stored in `~/.openclaw/workspace/data/characters/`
- Brand profiles -> stored in `~/.openclaw/skills/nanobanana/brands/`
- Audit generated images -> `audit-visual.sh audit-image <path>`
- Z-Image Turbo (MCP) used for fast iterations
- NanoBanana Pro (API) used for final quality + character consistency

## Notes
- All Gemini-generated images include SynthID watermarks
- NanoBanana Pro supports "Thinking Mode" for better composition planning
- Use multi-turn conversation for iterative refinement
- Pro model can use Google Search grounding for real-world accuracy
