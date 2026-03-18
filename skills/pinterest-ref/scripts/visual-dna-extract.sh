#!/bin/bash
# visual-dna-extract.sh — Generate a visual DNA analysis template from reference images
# Usage: visual-dna-extract.sh <image-dir> <output-file>
# macOS compatible (bash 3.2, no GNU extensions)
#
# This script creates a TEMPLATE. An agent with vision capability must
# view the images and fill in the analysis sections.

set -euo pipefail

# --- Argument validation ---
if [ $# -lt 2 ]; then
    echo "Usage: visual-dna-extract.sh <image-dir> <output-file>"
    echo ""
    echo "  <image-dir>    Directory containing downloaded reference images"
    echo "  <output-file>  Path for the output markdown analysis template"
    exit 1
fi

IMAGE_DIR="$1"
OUTPUT_FILE="$2"

if [ ! -d "$IMAGE_DIR" ]; then
    echo "ERROR: Image directory does not exist: $IMAGE_DIR"
    exit 1
fi

# --- Count images ---
IMG_COUNT=0
IMG_LIST=""
for ext in jpg jpeg png webp; do
    for f in "$IMAGE_DIR"/*."$ext" "$IMAGE_DIR"/*."$(echo "$ext" | tr '[:lower:]' '[:upper:]')"; do
        if [ -f "$f" ] 2>/dev/null; then
            IMG_COUNT=$((IMG_COUNT + 1))
            basename_f=$(basename "$f")
            IMG_LIST="${IMG_LIST}- \`${basename_f}\`
"
        fi
    done
done

if [ "$IMG_COUNT" -eq 0 ]; then
    echo "ERROR: No images found in $IMAGE_DIR"
    echo "Supported formats: jpg, jpeg, png, webp"
    exit 1
fi

echo "Found $IMG_COUNT reference images"

# --- Create output directory if needed ---
OUTPUT_DIR_PATH=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR_PATH"

# --- Generate timestamp ---
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")

# --- Write template ---
cat > "$OUTPUT_FILE" << TEMPLATE_EOF
# Visual DNA Analysis

**Source directory:** \`${IMAGE_DIR}\`
**Generated:** ${TIMESTAMP}
**Reference images:** ${IMG_COUNT}

---

## Reference Images

${IMG_LIST}
---

## Instructions for Agent

View each reference image listed above using your vision/image tool, then fill in every section below. Be specific and actionable. This analysis will be used to generate character specs and image prompts.

---

## 1. Color Palette

### Primary Colors
- [ ] Color 1: _name, hex estimate, where it appears_
- [ ] Color 2: _name, hex estimate, where it appears_
- [ ] Color 3: _name, hex estimate, where it appears_

### Secondary/Accent Colors
- [ ] Accent 1: _name, hex estimate, usage_
- [ ] Accent 2: _name, hex estimate, usage_

### Color Temperature
- [ ] Overall: _warm / cool / neutral / mixed_
- [ ] Dominant tone: _description_

### Color Relationships
- [ ] Contrast level: _high / medium / low_
- [ ] Harmony type: _complementary / analogous / triadic / monochromatic_
- [ ] Saturation tendency: _vivid / muted / desaturated / mixed_

---

## 2. Mood and Atmosphere

- [ ] Primary mood: _e.g., mysterious, ethereal, powerful, serene_
- [ ] Secondary mood: _e.g., luxurious, ancient, spiritual_
- [ ] Emotional weight: _heavy / light / balanced_
- [ ] Energy level: _high / medium / low / contemplative_
- [ ] Narrative feeling: _what story does this tell?_

---

## 3. Lighting

- [ ] Primary light source: _natural / artificial / mystical / ambient_
- [ ] Direction: _front / side / back / top / diffuse_
- [ ] Quality: _hard / soft / dramatic / flat_
- [ ] Special effects: _glow, rim light, volumetric, lens flare, none_
- [ ] Shadow character: _deep / subtle / absent / colored_
- [ ] Time of day feel: _dawn / day / golden hour / dusk / night / timeless_

---

## 4. Fashion and Styling

### Clothing
- [ ] Style era: _modern / vintage / futuristic / traditional / mixed_
- [ ] Silhouette: _fitted / flowing / structured / oversized_
- [ ] Key garments: _list specific items_
- [ ] Fabrics: _silk, leather, cotton, metallic, sheer, etc._
- [ ] Patterns: _solid / geometric / floral / abstract / none_

### Accessories
- [ ] Jewelry: _type, style, materials_
- [ ] Headwear: _type if any_
- [ ] Other accessories: _list_

### Hair and Beauty
- [ ] Hair style: _description_
- [ ] Hair color: _description_
- [ ] Makeup style: _natural / bold / editorial / none_
- [ ] Key beauty notes: _description_

---

## 5. Composition and Framing

- [ ] Dominant framing: _close-up / medium / full body / wide / aerial_
- [ ] Perspective: _eye level / low angle / high angle / Dutch angle_
- [ ] Rule of thirds: _followed / broken / centered_
- [ ] Negative space: _abundant / balanced / minimal_
- [ ] Depth: _shallow DOF / deep DOF / layered / flat_
- [ ] Movement: _static / implied motion / dynamic_

---

## 6. Cultural and Symbolic Elements

- [ ] Cultural references: _specific traditions, regions, time periods_
- [ ] Symbolic objects: _list any recurring symbols_
- [ ] Mythological/spiritual references: _list if present_
- [ ] Text or typography: _present / absent, style if present_
- [ ] Architectural elements: _list if present_
- [ ] Nature elements: _flora, fauna, landscapes, elements_

---

## 7. Texture and Material Quality

- [ ] Dominant textures: _smooth / rough / organic / metallic / crystalline_
- [ ] Surface quality: _matte / glossy / iridescent / translucent_
- [ ] Material richness: _luxurious / raw / industrial / natural_
- [ ] Detail level: _hyper-detailed / painterly / minimal / mixed_
- [ ] Rendering style: _photorealistic / illustrated / 3D / mixed media_

---

## 8. Recurring Patterns and Motifs

- [ ] Visual motifs: _elements that repeat across references_
- [ ] Color motifs: _recurring color combinations_
- [ ] Compositional patterns: _layout tendencies_
- [ ] Thematic throughlines: _unifying themes_

---

## Synthesis

### Visual DNA Summary (3-5 sentences)
_Write a concise summary that captures the essential visual identity. This should be detailed enough to guide image generation._

### Prompt Keywords
_List 15-25 keywords/phrases for image generation prompts, ordered by importance._

### Anti-Keywords (What to Avoid)
_List 5-10 things that would break the visual identity._

### NanoBanana Prompt Seed
_Write a single paragraph prompt that captures this visual DNA for NanoBanana generation._

---

_This template was generated by visual-dna-extract.sh. An agent with vision capability must fill in all sections after viewing the reference images._
TEMPLATE_EOF

echo "Template written to: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  1. Agent views each image in $IMAGE_DIR using vision tool"
echo "  2. Agent fills in all [ ] checklist items in $OUTPUT_FILE"
echo "  3. Agent writes synthesis section"
echo "  4. Use completed analysis for character specs and NanoBanana prompts"
