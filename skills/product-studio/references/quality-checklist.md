## Quality Checklist

Every generated image MUST pass ALL of these before being exported:

### Product Accuracy (Critical)
- [ ] Product shape matches reference photo (no warping, no wrong proportions)
- [ ] Product color matches reference (no color drift)
- [ ] Label text is readable and not warped (if label is part of the product)
- [ ] Product scale is realistic in the scene (not too big, not too small)
- [ ] Product orientation makes physical sense (not floating, not defying gravity)

### Brand Consistency (Critical)
- [ ] Color palette matches DNA.json (primary, secondary, accent present or harmonious)
- [ ] Lighting matches `visual.lighting_default` from DNA.json
- [ ] Style matches `visual.style` from DNA.json
- [ ] Photography style matches `visual.photography` from DNA.json
- [ ] NONE of the `visual.avoid` items are present in the image
- [ ] Logo/badge placement follows `visual.logo_placement` if specified
- [ ] Badges present if required (e.g., MIRRA calorie badges, "Nutritionist Designed")

### Lighting Coherence
- [ ] Light direction is consistent across product and scene
- [ ] Shadow direction matches light source
- [ ] Color temperature is consistent (no warm product in cool scene or vice versa)
- [ ] No impossible double-shadows or missing shadows
- [ ] Reflection (if present) matches scene lighting

### AI Artifact Scan
- [ ] No extra fingers or malformed hands on models
- [ ] No warped or melted text on product labels
- [ ] No impossible object geometry (melted bottles, merged items)
- [ ] No seam lines from compositing
- [ ] No plasticky or uncanny skin texture on models
- [ ] No blurred or smudged areas that break photorealism
- [ ] No repeated patterns (texture tiling visible)
- [ ] Hair looks natural (individual strands, not helmet)

### Resolution and Format
- [ ] Minimum 1080x1080 for social media content
- [ ] Minimum 2048px on longest side for e-commerce listings
- [ ] 4K for hero/banner images and print-ready assets
- [ ] Aspect ratio correct for target platform:
  - 1:1 for Instagram feed, Shopee/Lazada listing
  - 4:5 for Instagram feed (portrait)
  - 9:16 for Instagram/TikTok stories and reels
  - 16:9 for website banners and YouTube thumbnails
  - 3:4 for Pinterest pins

### Model-Specific Checks (Module C only)
- [ ] Face matches locked reference (no identity drift)
- [ ] Body proportions consistent across shots
- [ ] Outfit fits naturally (no impossible folds or floating fabric)
- [ ] Skin texture is realistic (pores visible, not plasticky)
- [ ] Expression is natural and on-brand
- [ ] Demographic representation is respectful and authentic

