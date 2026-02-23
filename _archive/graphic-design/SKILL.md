---
name: graphic-design
description: Graphic design capabilities — social templates, banners, packaging, marketing collateral
version: 1.0.0
agent: daedalus
---

# Graphic Design Skill

Enables Daedalus (Art Director) to create graphic design assets beyond photo/video content.

## Capabilities

### 1. Social Media Templates
Platform specs and template generation for brand-consistent social content.

| Platform | Format | Size | Safe Zone |
|----------|--------|------|-----------|
| Instagram Post | Square | 1080x1080 | 60px margin all sides |
| Instagram Story | Vertical | 1080x1920 | 250px top/bottom for UI |
| Instagram Carousel | Square | 1080x1080 | First slide = hook |
| TikTok Cover | Vertical | 1080x1920 | Center 60% for text |
| Facebook Post | Landscape | 1200x630 | Text in center 80% |
| Shopee Banner | Wide | 1200x300 | Product left, text right |
| Lazada Banner | Wide | 1200x400 | Product center, CTA right |
| Website Hero | Full | 1920x600 | Text left 50%, image right |

### 2. Design Composition Rules
When creating designs with text overlays:
- Read Brand DNA typography: `~/.openclaw/brands/{brand}/DNA.json → visual.typography`
- Heading: Use DNA heading font style, max 8 words
- Body: Use DNA body font style, max 20 words
- CTA: Bold, contrasting color (use DNA accent color)
- Logo: Bottom-right corner, 10% of canvas width
- Never place text on busy backgrounds without semi-transparent overlay

### 3. Banner Design
Spec for each banner type:
- **Hero banner**: Full bleed background image + left-aligned text block + CTA button
- **Store banner**: Product hero image (40%) + brand message (40%) + logo (20%)
- **Ad banner**: Hook text (top) + product image (center) + CTA (bottom)

### 4. Packaging Mockup
For product packaging visualization:
- Label design: Product name, brand logo, key benefits, ingredients callout
- Use NanoBanana with product photography style from Brand DNA
- Always include: brand colors, typography, regulatory space placeholder
- Mockup prompt template: "Product packaging design for {product}, {brand} brand colors, clean modern label, studio product photography, white background, premium feel"

### 5. Typography Layouts
For quote cards, stat graphics, announcement posts:
- Center-aligned text on solid or gradient background
- Background: Use Brand DNA background color or mood-specific gradient
- Text: Brand DNA heading font style
- Accent: Thin line or geometric shape in brand accent color

## Usage

Daedalus (Art Director) should reference this skill when Calliope's (Creative Director) brief requests:
- Social media templates/layouts
- Banners for any platform
- Packaging/label concepts
- Marketing materials
- Typography-based content

## Prompt Templates

### Social Template Prompt
```
Clean modern {platform} template for {brand},
{DNA.visual.colors.background} background,
{DNA.visual.typography.heading} heading font style,
product image placeholder [left/center/right],
text area with {DNA.visual.colors.primary} accent elements,
{DNA.visual.style}, minimalist layout,
brand logo bottom-right corner
```

### Packaging Prompt
```
Premium product packaging design for {product},
{brand} brand identity, colors {DNA.visual.colors.primary} and {DNA.visual.colors.accent},
clean modern label, {DNA.visual.photography},
studio product shot, {DNA.visual.lighting_default},
professional packaging mockup
```

## Integration
- Always read Brand DNA before designing: `cat ~/.openclaw/brands/{brand}/DNA.json`
- Store approved designs in seed bank: `bash seed-store.sh add --type image --text "design prompt" --tags "graphic-design,{type}"`
- Run visual audit after generation: `bash audit-visual.sh audit-image /path/to/design.png --brand {brand}`
