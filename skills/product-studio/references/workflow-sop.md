## Workflow SOP (Step by Step)

### Pre-Flight

Before running any generation:

1. **Verify brand DNA exists:** `cat ~/.openclaw/brands/{brand}/DNA.json | head -5`
2. **Check for existing product photos:** `ls ~/.openclaw/workspace/data/images/{brand}/` -- real photos are ALWAYS preferred as reference input
3. **Determine product type:** food / beverage / supplement / print / digital -- this selects the angle and scene template sets
4. **Check avoid-list:** Read `DNA.json -> visual.avoid` -- these are hard constraints that MUST NOT appear in any generated image

### Full Product Studio Run — Pinxin Vegan Example

```bash
# Generate complete visual library for Pinxin Vegan nasi lemak set
bash scripts/product-studio.sh generate --brand pinxin-vegan --product "nasi-lemak-set"

# This runs the full pipeline:
# Module A (pack shots): overhead flatlay, 45-degree hero, front packaging, close-up sambal texture
#   → dark forest green #1C372A branded backgrounds, warm high-contrast lighting, steam visible
# Module B (lifestyle scenes): hawker stall counter, kopitiam dining, food truck, office lunch
#   → bold Malaysian street food aesthetic, banana leaf lining, warm natural light
# Module C (model shots): health-conscious Malaysian woman 25-45, bold confidence
#   → GrabFood delivery context, Shopee listing hero, WhatsApp catalog image
# Output: ~/.openclaw/workspace/data/images/pinxin-vegan/product-studio/
```

### Step 1: Load Brand DNA

```bash
# Extract all visual parameters from DNA.json
BRAND="mirra"
DNA_FILE="$HOME/.openclaw/brands/${BRAND}/DNA.json"

# Key fields to extract:
# visual.colors.primary, secondary, background, accent
# visual.typography
# visual.photography
# visual.lighting_default
# visual.style
# visual.avoid (HARD CONSTRAINTS)
# visual.badges (if present)
# visual.logo_placement (if present)
# audience.primary
# audience.personas
# products (list of product names)
```

### Step 2: Select Product Type and Templates

Map product to type:
- Bento box, meal set, rendang, laksa, nasi lemak --> **food**
- Jamu, turmeric latte, smoothie, acai bowl --> **beverage**
- Capsule, powder, supplement bottle --> **supplement**
- T-shirt, tote bag, mug --> **print**
- Oracle deck, reading cards --> **specialty** (use jade-oracle specific rules)
- Course, workbook, digital product --> **digital** (screenshot + lifestyle only)

### Step 3: Generate Pack Shots (Module A)

Run pack shot generation for the selected product type. Uses the angle matrix from Module A above.

```bash
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand "${BRAND}" \
  --prompt "${PACKSHOT_PROMPT}" \
  --ref-image "${PRODUCT_PHOTO}" \
  --size 2K \
  --ratio 1:1
```

**Generation order (important for consistency):**
1. Front view on white background FIRST -- this becomes the anchor reference
2. Use output from (1) as additional reference for all subsequent angles
3. Generate remaining angles: 45 hero, overhead, back, close-up
4. Generate branded background variants using front view as ref
5. Generate shadow/reflection variant last

**Expected output:** 6-8 images per product
- `{brand}_{product}_packshot_front_white.png`
- `{brand}_{product}_packshot_hero-45_white.png`
- `{brand}_{product}_packshot_overhead_white.png`
- `{brand}_{product}_packshot_back_white.png`
- `{brand}_{product}_packshot_closeup_white.png`
- `{brand}_{product}_packshot_front_branded.png`
- `{brand}_{product}_packshot_hero-45_branded.png`
- `{brand}_{product}_packshot_front_shadow.png`

### Step 4: Generate Lifestyle Scenes (Module B)

Use the best pack shot from Step 3 as the product reference for placement.

```bash
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand "${BRAND}" \
  --prompt "${PLACEMENT_PROMPT}" \
  --ref-image "${BEST_PACKSHOT},${BRAND_STYLE_REF}" \
  --size 2K \
  --ratio 4:3 \
  --model flash
```

**Scene selection:** Pick 4-6 scenes from the brand-category scene templates in Module B. Prioritize:
1. The scene most aligned with the primary persona in DNA.json
2. One aspirational/lifestyle scene
3. One heritage/authenticity scene (for Malaysian brands)
4. One social-media-optimized scene (9:16 for stories)

**Expected output:** 4-6 images per product
- `{brand}_{product}_placement_kitchen_v1.png`
- `{brand}_{product}_placement_dining_v1.png`
- `{brand}_{product}_placement_office_v1.png`
- `{brand}_{product}_placement_lifestyle_v1.png`
- `{brand}_{product}_placement_story-9x16_v1.png` (vertical format)

### Step 5: Generate Model Shots (Module C)

Use character-lock protocol. Requires either existing locked face refs or new model generation.

```bash
# If generating new model (no existing character):
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh character-sheet \
  --brand "${BRAND}" \
  --description "${MODEL_DESCRIPTION}" \
  --poses "front,side,holding-product"

# Then generate model + product shots:
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand "${BRAND}" \
  --prompt "${MODEL_PROMPT}" \
  --ref-image "${FACE_REFS},${PRODUCT_PHOTO}" \
  --size 2K \
  --ratio 4:5 \
  --model flash
```

**Expected output:** 3-4 images per product
- `{brand}_{product}_model_hold-front_v1.png`
- `{brand}_{product}_model_use-active_v1.png`
- `{brand}_{product}_model_table-near_v1.png`
- `{brand}_{product}_model_share_v1.png` (if applicable)

### Step 6: Quality Check

Run every generated image through the quality checklist (see Section 7 below). Automated via brand-studio audit:

```bash
bash /Users/jennwoeiloh/.openclaw/skills/brand-studio/scripts/audit.sh \
  --brand "${BRAND}" \
  --image "${OUTPUT_IMAGE}"
```

**Reject and regenerate if:**
- Overall score < 7.0/10
- Product shape/color does not match reference
- Brand colors significantly off
- AI artifacts present (extra fingers, warped text, melted objects)
- Lighting inconsistency between product and scene

**Max retries:** 3 per image. If 3 fails, flag for manual review.

### Step 7: Export and Register

```bash
# Move to canonical output path
OUTPUT_DIR="$HOME/.openclaw/workspace/data/images/${BRAND}/product-studio/"
mkdir -p "${OUTPUT_DIR}"
mv generated_images/* "${OUTPUT_DIR}/"

# Register in visual-registry for asset tracking
bash /Users/jennwoeiloh/.openclaw/skills/visual-registry/scripts/register.sh \
  --brand "${BRAND}" \
  --type "product-studio" \
  --path "${OUTPUT_DIR}" \
  --product "${PRODUCT_NAME}"
```

