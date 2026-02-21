#!/usr/bin/env bash
# compress-images.sh - Optimize images for Klaviyo email campaigns
# Now delegates to the centralized image-optimizer skill.

set -euo pipefail

INPUT_DIR="${1:-$HOME/.openclaw/workspace/klaviyo/images}"
OUTPUT_DIR="${2:-$HOME/.openclaw/workspace/klaviyo/images/compressed}"
OPTIMIZER="$HOME/.openclaw/skills/image-optimizer/scripts/image-optimizer.sh"

if [ ! -f "$OPTIMIZER" ]; then
  echo "ERROR: image-optimizer.sh not found at $OPTIMIZER"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Compressing images for Klaviyo email..."
echo "Input:  $INPUT_DIR"
echo "Output: $OUTPUT_DIR"
echo ""

# Use centralized optimizer with email profile (600px, quality 80)
for img in "$INPUT_DIR"/*.jpg "$INPUT_DIR"/*.jpeg "$INPUT_DIR"/*.png "$INPUT_DIR"/*.webp; do
  [ -f "$img" ] || continue
  filename=$(basename "$img")
  name="${filename%.*}"
  outfile="$OUTPUT_DIR/${name}_600.jpg"

  bash "$OPTIMIZER" optimize "$img" --profile email --output "$outfile" --format jpg
done

echo ""
echo "Compression complete!"
ls -lh "$OUTPUT_DIR" 2>/dev/null | tail -20
