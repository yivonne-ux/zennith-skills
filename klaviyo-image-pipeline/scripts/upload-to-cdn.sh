#!/usr/bin/env bash
# upload-to-cdn.sh - Upload images to CDN

set -euo pipefail

INPUT_DIR="${1:-~/.openclaw/workspace/klaviyo/images/compressed}"
CDN_BASE_URL="${CDN_BASE_URL:-}"

echo "☁️  Uploading to CDN..."
echo "Source: $INPUT_DIR"

# Option 1: Shopify Files API
if [[ -n "${SHOPIFY_API_TOKEN:-}" && -n "${SHOPIFY_STORE:-}" ]]; then
  echo "✅ Using Shopify Files API"
  
  for img in "$INPUT_DIR"/*.jpg; do
    [[ -f "$img" ]] || continue
    filename=$(basename "$img")
    
    echo "  Uploading: $filename"
    
    # Upload to Shopify Files
    response=$(curl -s -X POST \
      "https://$SHOPIFY_STORE/admin/api/2024-01/files.json" \
      -H "X-Shopify-Access-Token: $SHOPIFY_API_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"file\": {
          \"filename\": \"$filename\",
          \"content\": \"$(base64 -i "$img")\",
          \"content_type\": \"image/jpeg\"
        }
      }" 2>/dev/null || echo "{}")
    
    # Extract URL from response
    url=$(echo "$response" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [[ -n "$url" ]]; then
      echo "    → $url"
      echo "$filename|$url" >> ~/.openclaw/workspace/klaviyo/image-urls.txt
    else
      echo "    ❌ Upload failed"
    fi
  done

# Option 2: Local static server (fallback)
else
  echo "⚠️  No CDN credentials found. Setting up local static server..."
  
  STATIC_DIR="~/.openclaw/workspace/klaviyo/static"
  mkdir -p "$STATIC_DIR"
  
  # Copy images to static directory
  cp "$INPUT_DIR"/*.jpg "$STATIC_DIR/" 2>/dev/null || true
  
  # Check if static server is running
  if ! curl -s http://localhost:19801 >/dev/null 2>&1; then
    echo "  Starting local static server on port 19801..."
    
    # Start a simple Python or Node.js static server
    if command -v python3 >/dev/null 2>&1; then
      (cd "$STATIC_DIR" && python3 -m http.server 19801 &) >/dev/null 2>&1
    elif command -v npx >/dev/null 2>&1; then
      (cd "$STATIC_DIR" && npx serve -l 19801 &) >/dev/null 2>&1
    fi
    
    sleep 2
  fi
  
  # Generate URLs
  for img in "$STATIC_DIR"/*.jpg; do
    [[ -f "$img" ]] || continue
    filename=$(basename "$img")
    url="http://localhost:19801/$filename"
    echo "$filename|$url" >> ~/.openclaw/workspace/klaviyo/image-urls.txt
    echo "  → $url"
  done
  
  echo ""
  echo "⚠️  Note: Local server URLs won't work for production emails!"
  echo "    Set up Shopify Files or Cloudfront for real campaigns."
fi

echo ""
echo "✅ Upload complete!"
echo "URLs saved to: ~/.openclaw/workspace/klaviyo/image-urls.txt"
