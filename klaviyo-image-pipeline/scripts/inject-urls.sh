#!/usr/bin/env bash
# inject-urls.sh - Replace placeholders with real URLs in templates
# Bash 3.2 compatible (macOS) — no declare -A, no ${var,,}

set -euo pipefail

TEMPLATES_DIR="${1:-~/.openclaw/workspace/klaviyo/postcny_final}"
URLS_FILE="${2:-~/.openclaw/workspace/klaviyo/image-urls.txt}"

echo "📝 Injecting image URLs into templates..."
echo "Templates: $TEMPLATES_DIR"
echo "URLs: $URLS_FILE"
echo ""

# Check if URLs file exists
if [[ ! -f "$URLS_FILE" ]]; then
  echo "❌ URLs file not found: $URLS_FILE"
  echo "Run upload-to-cdn.sh first!"
  exit 1
fi

# Read URLs into parallel arrays (bash 3.2 compatible)
# Cannot use declare -A (associative arrays) on macOS bash 3.2
FILENAMES=()
URLS=()
while IFS='|' read -r filename url; do
  FILENAMES+=("$filename")
  URLS+=("$url")
  echo "  Mapped: $filename → $url"
done < "$URLS_FILE"

echo ""

# Update templates
for template in "$TEMPLATES_DIR"/Email*_with_hero.html; do
  [[ -f "$template" ]] || continue
  
  filename=$(basename "$template")
  echo "Processing: $filename"
  
  # Create backup
  cp "$template" "$template.backup"
  
  # Replace placeholders with URLs
  # PLACEHOLDER_IMAGE_URL_1, PLACEHOLDER_IMAGE_URL_2, etc.
  
  counter=1
  for i in "${!FILENAMES[@]}"; do
    placeholder="PLACEHOLDER_IMAGE_URL_$counter"
    url="${URLS[$i]}"
    
    if grep -q "$placeholder" "$template" 2>/dev/null; then
      sed -i.bak "s|$placeholder|$url|g" "$template" 2>/dev/null || \
        sed -i '' "s|$placeholder|$url|g" "$template"
      echo "  Replaced $placeholder with $url"
    fi
    
    counter=$((counter + 1))
  done
  
  # Clean up backup files
  rm -f "$template.bak" "$template.backup"
done

echo ""
echo "✅ Templates updated!"
echo ""
echo "Next steps:"
echo "1. Review templates: ls -la $TEMPLATES_DIR"
echo "2. Test send via Klaviyo"
echo "3. Verify images render correctly"
