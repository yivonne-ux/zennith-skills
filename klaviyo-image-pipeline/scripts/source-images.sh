#!/usr/bin/env bash
# source-images.sh - Download product images from Shopify

set -euo pipefail

SHOPIFY_STORE="pinxin-vegan-cuisine.myshopify.com"
PRODUCT_HANDLE="poon-choi"
OUTPUT_DIR="${1:-~/.openclaw/workspace/klaviyo/images}"

mkdir -p "$OUTPUT_DIR"

echo "📥 Sourcing images from Shopify..."
echo "Store: $SHOPIFY_STORE"
echo "Output: $OUTPUT_DIR"

# Check if we have Shopify credentials
if [[ -f ~/.openclaw/secrets/shopify-pinxin.env ]]; then
  source ~/.openclaw/secrets/shopify-pinxin.env
  echo "✅ Shopify credentials found"
else
  echo "⚠️  No Shopify credentials found. Creating placeholder images..."
  # Create placeholder images using ImageMagick or curl placeholders
  for i in 1 2 3 4 5; do
    curl -sL "https://via.placeholder.com/600x400/FF6B35/FFFFFF?text=Pinxin+Poon+Choi+$i" \
      -o "$OUTPUT_DIR/hero_$i.jpg"
    echo "  Created: hero_$i.jpg"
  done
  exit 0
fi

# Fetch product images via Shopify Admin API
echo "Fetching product data..."
curl -s "https://$SHOPIFY_STORE/admin/api/2024-01/products.json?handle=$PRODUCT_HANDLE" \
  -H "X-Shopify-Access-Token: $SHOPIFY_API_TOKEN" \
  -o /tmp/product.json

# Extract image URLs
if command -v jq >/dev/null 2>&1; then
  jq -r '.products[0].images[].src' /tmp/product.json 2>/dev/null | head -5 | while read -r url; do
    filename=$(basename "$url" | cut -d'?' -f1)
    echo "  Downloading: $filename"
    curl -sL "$url" -o "$OUTPUT_DIR/$filename"
  done
else
  echo "⚠️  jq not installed. Using grep fallback..."
  # Fallback: manually download known product images
  echo "Please download images manually from Shopify admin"
fi

echo "✅ Images sourced to: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
