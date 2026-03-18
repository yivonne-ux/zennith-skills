#!/bin/bash
# pinterest-extract.sh — Download high-res images from a Pinterest pin or board
# Usage: pinterest-extract.sh <pinterest-url> <output-dir>
# macOS compatible (bash 3.2, no GNU extensions)

set -euo pipefail

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# --- Argument validation ---
if [ $# -lt 2 ]; then
    echo "Usage: pinterest-extract.sh <pinterest-url> <output-dir>"
    echo ""
    echo "  <pinterest-url>  A Pinterest pin or board URL"
    echo "  <output-dir>     Directory to save downloaded images"
    exit 1
fi

URL="$1"
OUTPUT_DIR="$2"

# Validate URL looks like Pinterest
case "$URL" in
    *pinterest.com*|*pin.it*)
        ;;
    *)
        echo "ERROR: URL does not appear to be a Pinterest link: $URL"
        exit 1
        ;;
esac

# Create output directory
mkdir -p "$OUTPUT_DIR"

TMPFILE="$(mktemp /tmp/pinterest-html.XXXXXX)"
trap 'rm -f "$TMPFILE" "$TMPFILE.urls" "$TMPFILE.hashes" "$TMPFILE.best"' EXIT

echo "Fetching: $URL"
HTTP_CODE=$(curl -sL -o "$TMPFILE" -w "%{http_code}" \
    -H "User-Agent: $UA" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
    -H "Accept-Language: en-US,en;q=0.9" \
    -H "Cache-Control: no-cache" \
    "$URL")

if [ "$HTTP_CODE" != "200" ]; then
    echo "ERROR: HTTP $HTTP_CODE fetching $URL"
    exit 1
fi

FILE_SIZE=$(wc -c < "$TMPFILE" | tr -d ' ')
echo "Fetched $FILE_SIZE bytes of HTML"

# --- Extract image URLs ---
# Get all i.pinimg.com URLs (jpg and png)
grep -o 'https://i\.pinimg\.com/[^"'"'"'\\]*\.jpg' "$TMPFILE" > "$TMPFILE.urls" 2>/dev/null || true
grep -o 'https://i\.pinimg\.com/[^"'"'"'\\]*\.png' "$TMPFILE" >> "$TMPFILE.urls" 2>/dev/null || true

# Also check for escaped URLs (Pinterest sometimes escapes slashes in JSON)
sed 's/\\u002F/\//g' "$TMPFILE" | grep -o 'https://i\.pinimg\.com/[^"'"'"'\\]*\.jpg' >> "$TMPFILE.urls" 2>/dev/null || true
sed 's/\\u002F/\//g' "$TMPFILE" | grep -o 'https://i\.pinimg\.com/[^"'"'"'\\]*\.png' >> "$TMPFILE.urls" 2>/dev/null || true

# Also try \/ escaped URLs common in JSON
sed 's/\\\//\//g' "$TMPFILE" | grep -o 'https://i\.pinimg\.com/[^"'"'"'\\]*\.jpg' >> "$TMPFILE.urls" 2>/dev/null || true
sed 's/\\\//\//g' "$TMPFILE" | grep -o 'https://i\.pinimg\.com/[^"'"'"'\\]*\.png' >> "$TMPFILE.urls" 2>/dev/null || true

TOTAL_RAW=$(wc -l < "$TMPFILE.urls" | tr -d ' ')
echo "Found $TOTAL_RAW raw image URLs"

if [ "$TOTAL_RAW" -eq 0 ]; then
    echo "No images found. Pinterest may have blocked the request or the page requires JavaScript."
    exit 1
fi

# Deduplicate exact URLs
sort -u "$TMPFILE.urls" > "$TMPFILE.urls.dedup"
mv "$TMPFILE.urls.dedup" "$TMPFILE.urls"

TOTAL_DEDUP=$(wc -l < "$TMPFILE.urls" | tr -d ' ')
echo "After dedup: $TOTAL_DEDUP unique URLs"

# --- Resolution preference ---
# Pinterest image URL pattern: https://i.pinimg.com/{size}/{hash}.{ext}
# Sizes in ascending quality: 136x136, 236x, 474x, 564x, 736x, 1200x, originals
# Strategy: group by hash, keep highest resolution

# Extract hash from each URL and pair with size priority
# Priority: originals=7, 1200x=6, 736x=5, 564x=4, 474x=3, 236x=2, 136x136=1, other=0
while IFS= read -r img_url; do
    # Extract the filename (hash.ext) — last path component
    filename=$(echo "$img_url" | sed 's|.*/||')
    # Extract the size component
    case "$img_url" in
        */originals/*)   priority=7 ;;
        */1200x/*)       priority=6 ;;
        */736x/*)        priority=5 ;;
        */564x/*)        priority=4 ;;
        */474x/*)        priority=3 ;;
        */236x/*)        priority=2 ;;
        */136x136/*)     priority=1 ;;
        *)               priority=0 ;;
    esac
    echo "$filename $priority $img_url"
done < "$TMPFILE.urls" | sort -t' ' -k1,1 -k2,2nr | awk '
    {
        if ($1 != prev) {
            print $3
            prev = $1
        }
    }
' > "$TMPFILE.best"

TOTAL_BEST=$(wc -l < "$TMPFILE.best" | tr -d ' ')
echo "After resolution dedup: $TOTAL_BEST unique images (highest res per hash)"

# --- Filter out tiny thumbnails ---
# Skip anything from 136x136 unless it is the only version
grep -v '/136x136/' "$TMPFILE.best" > "$TMPFILE.filtered" 2>/dev/null || true
FILTERED_COUNT=$(wc -l < "$TMPFILE.filtered" | tr -d ' ')
if [ "$FILTERED_COUNT" -eq 0 ]; then
    # All images were 136x136, keep them
    cp "$TMPFILE.best" "$TMPFILE.filtered"
fi
mv "$TMPFILE.filtered" "$TMPFILE.best"

TOTAL_FINAL=$(wc -l < "$TMPFILE.best" | tr -d ' ')
echo ""
echo "Downloading $TOTAL_FINAL images to: $OUTPUT_DIR"
echo "---"

# --- Download ---
COUNT=0
FAIL=0
while IFS= read -r img_url; do
    # Generate filename from URL hash
    filename=$(echo "$img_url" | sed 's|.*/||')
    # Prefix with size for clarity
    case "$img_url" in
        */originals/*)   prefix="orig" ;;
        */1200x/*)       prefix="1200" ;;
        */736x/*)        prefix="736" ;;
        */564x/*)        prefix="564" ;;
        */474x/*)        prefix="474" ;;
        */236x/*)        prefix="236" ;;
        *)               prefix="other" ;;
    esac
    outfile="${OUTPUT_DIR}/${prefix}_${filename}"

    if [ -f "$outfile" ]; then
        echo "  SKIP (exists): $outfile"
        COUNT=$((COUNT + 1))
        continue
    fi

    dl_code=$(curl -sL -o "$outfile" -w "%{http_code}" \
        -H "User-Agent: $UA" \
        "$img_url")

    if [ "$dl_code" = "200" ]; then
        fsize=$(wc -c < "$outfile" | tr -d ' ')
        echo "  OK: ${prefix}_${filename} (${fsize} bytes)"
        COUNT=$((COUNT + 1))
    else
        echo "  FAIL (HTTP $dl_code): $img_url"
        rm -f "$outfile"
        FAIL=$((FAIL + 1))
    fi
done < "$TMPFILE.best"

echo ""
echo "=== Summary ==="
echo "Downloaded: $COUNT images"
echo "Failed:     $FAIL"
echo "Output dir: $OUTPUT_DIR"

# List final files
echo ""
echo "Files:"
ls -lh "$OUTPUT_DIR"/ 2>/dev/null | grep -v '^total' | awk '{print "  " $NF " (" $5 ")"}'
