# Ad Composer

Layout engine for assembling ad creatives from components.

## Owner
Apollo

## What It Does
1. Combine image + text overlay + logo + CTA + brand elements
2. Output Meta-ready images at standard dimensions
3. Apply brand DNA (colors, fonts, spacing) automatically
4. Generate multiple variants from component matrix

## Output Dimensions
- Square: 1080x1080 (IG Feed, FB Feed)
- Portrait: 1080x1920 (IG Stories, IG Reels, TikTok)
- Landscape: 1200x628 (FB Feed, Meta Ads)

## Components
- Background: product photo, lifestyle shot, or solid color
- Text overlay: headline, body copy (brand fonts)
- Logo: brand logo with proper spacing
- CTA: button or text CTA element
- Brand elements: color bar, watermark, social handles

## Tools
- PIL/Pillow for image composition
- Brand DNA JSON for styling rules
- Materials library for source assets

## Data
Reads from: materials/ directory, brand DNA, creatives table
Writes to: materials/generated/graphics/, creatives table
