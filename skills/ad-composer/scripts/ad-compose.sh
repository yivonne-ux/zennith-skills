#!/usr/bin/env bash
# ad-compose.sh — Shell wrapper for MIRRA Ad Compositor
# Composes real brand assets (logo, product photos, badges) into ad layouts
# Uses Playwright (headless Chrome) to render HTML templates to PNG
#
# Usage:
#   ad-compose.sh comparison --sku fusilli --competitor-preset fried-rice
#   ad-compose.sh hero --sku katsu --headline "Eat Clean, Glow Up"
#   ad-compose.sh grid --skus fusilli,pad-thai,katsu,burrito
#   ad-compose.sh list-skus
#   ad-compose.sh list-templates
#   ad-compose.sh batch-comparisons   # Generate all SKU × competitor combos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_PY="$SCRIPT_DIR/ad-compose.py"

if [[ ! -f "$COMPOSE_PY" ]]; then
    echo "ERROR: ad-compose.py not found at $COMPOSE_PY" >&2
    exit 1
fi

CMD="${1:-help}"
shift 2>/dev/null || true

case "$CMD" in
    comparison|hero|grid|list-skus|list-templates)
        python3 "$COMPOSE_PY" "$CMD" "$@"
        ;;

    batch-comparisons)
        # Generate comparison ads for every SKU × every competitor preset
        SKUS=(bbq-pita curry-konjac burrito fusilli eryngii katsu pad-thai)
        COMPETITORS=(nasi-lemak fried-rice mamak grabfood mcdonalds)
        OUTPUT_DIR="${1:-$HOME/.openclaw/workspace/data/images/mirra/batch-composed}"
        mkdir -p "$OUTPUT_DIR"

        count=0
        for sku in "${SKUS[@]}"; do
            for comp in "${COMPETITORS[@]}"; do
                ts=$(date +%Y%m%d_%H%M%S)
                out="$OUTPUT_DIR/${sku}_vs_${comp}_${ts}.png"
                echo "Generating: $sku vs $comp → $out"
                python3 "$COMPOSE_PY" comparison \
                    --sku "$sku" \
                    --competitor-preset "$comp" \
                    --output "$out" 2>&1 || echo "  FAILED: $sku vs $comp"
                count=$((count + 1))
            done
        done
        echo "Done! Generated $count comparison ads in $OUTPUT_DIR"
        ;;

    batch-heroes)
        SKUS=(bbq-pita curry-konjac burrito fusilli eryngii katsu pad-thai)
        HEADLINES=("Eat Clean, Glow Up" "Your Lunch, Upgraded" "Fuel Your Afternoon" "Treat Yourself Right")
        OUTPUT_DIR="${1:-$HOME/.openclaw/workspace/data/images/mirra/batch-composed}"
        mkdir -p "$OUTPUT_DIR"

        count=0
        for sku in "${SKUS[@]}"; do
            idx=$((RANDOM % ${#HEADLINES[@]}))
            headline="${HEADLINES[$idx]}"
            ts=$(date +%Y%m%d_%H%M%S)
            out="$OUTPUT_DIR/hero_${sku}_${ts}.png"
            echo "Generating hero: $sku → $out"
            python3 "$COMPOSE_PY" hero \
                --sku "$sku" \
                --headline "$headline" \
                --output "$out" 2>&1 || echo "  FAILED: $sku"
            count=$((count + 1))
        done
        echo "Done! Generated $count hero ads in $OUTPUT_DIR"
        ;;

    url-to-ad)
        # URL-to-Ad Pipeline: scrape product URL → extract data → generate ad copy variants + image prompt
        URL=""
        FUNNEL=""
        BRAND=""
        OUTPUT_DIR=""
        while [ $# -gt 0 ]; do
            case "$1" in
                --url)        URL="$2"; shift 2 ;;
                --funnel)     FUNNEL="$2"; shift 2 ;;
                --brand)      BRAND="$2"; shift 2 ;;
                --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
                *) shift ;;
            esac
        done

        if [ -z "$URL" ]; then
            echo "ERROR: --url is required" >&2
            echo "Usage: ad-compose.sh url-to-ad --url <product_url> [--funnel tofu|mofu|bofu|all] [--brand <brand>] [--output-dir <dir>]"
            exit 1
        fi

        FUNNEL="${FUNNEL:-all}"
        OUTPUT_DIR="${OUTPUT_DIR:-$HOME/.openclaw/workspace/data/ads/url-to-ad}"
        mkdir -p "$OUTPUT_DIR"

        echo "=== URL-to-Ad Pipeline ==="
        echo "URL:    $URL"
        echo "Funnel: $FUNNEL"
        echo "Brand:  ${BRAND:-auto-detect}"
        echo ""

        # Step 1: Scrape product page via Jina Reader
        echo "[1/3] Scraping product page..."
        SCRAPED=$(curl -sL "https://r.jina.ai/$URL" 2>/dev/null | head -c 5000)

        if [ -z "$SCRAPED" ] || [ ${#SCRAPED} -lt 50 ]; then
            echo "ERROR: Failed to scrape URL or content too short" >&2
            exit 1
        fi

        echo "  Scraped ${#SCRAPED} chars"

        # Step 2: Extract product data + generate ad variants via Python
        echo "[2/3] Extracting product data & generating ad variants..."
        TS=$(date +%Y%m%d_%H%M%S)
        OUT_FILE="$OUTPUT_DIR/url-to-ad-${TS}.json"

        python3 - "$SCRAPED" "$FUNNEL" "$BRAND" "$OUT_FILE" "$URL" << 'PYEOF'
import json, sys, re, time

scraped = sys.argv[1]
funnel = sys.argv[2]
brand_hint = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else ""
out_file = sys.argv[4]
source_url = sys.argv[5]

# --- Extract product data from scraped markdown ---
lines = scraped.split("\n")

# Try to find title (first # heading, or "Title:" line from Jina, or first non-empty line)
title = ""
for line in lines:
    line = line.strip()
    if line.startswith("# "):
        title = line.lstrip("# ").strip()
        break
    elif line.lower().startswith("title:"):
        title = line.split(":", 1)[1].strip()
        break
    elif line and not title:
        title = line[:80]
# Strip "Title: " prefix if Jina Reader added it
if title.lower().startswith("title:"):
    title = title.split(":", 1)[1].strip()

# Try to find price (look for RM, $, or common price patterns)
price = ""
for line in lines:
    m = re.search(r'(RM\s*[\d,.]+|USD\s*[\d,.]+|\$[\d,.]+|MYR\s*[\d,.]+)', line, re.IGNORECASE)
    if m:
        price = m.group(1).strip()
        break

# Extract key selling points (bullet points or short lines with keywords)
selling_points = []
keywords = ["free", "natural", "organic", "premium", "fresh", "healthy", "halal",
            "no msg", "nutritionist", "handmade", "homemade", "quality", "benefit",
            "vitamin", "protein", "calorie", "kcal", "ingredient", "delivery"]
for line in lines:
    line_clean = line.strip().lstrip("-*• ")
    if not line_clean or len(line_clean) > 120:
        continue
    lower = line_clean.lower()
    if any(kw in lower for kw in keywords) and line_clean not in selling_points:
        selling_points.append(line_clean)
    if len(selling_points) >= 5:
        break

# Fallback selling points
if not selling_points:
    selling_points = ["Quality product", "Great value", "Customer favorite"]

# Auto-detect brand from URL
brand_slugs = {
    "pinxin": "pinxin-vegan", "wholey": "wholey-wonder", "mirra": "mirra",
    "rasaya": "rasaya", "gaia": "gaia-eats", "serein": "serein", "dr-stan": "dr-stan"
}
detected_brand = brand_hint
if not detected_brand:
    url_lower = source_url.lower()
    for slug, brand_name in brand_slugs.items():
        if slug in url_lower:
            detected_brand = brand_name
            break

# --- Generate TOFU / MOFU / BOFU ad copy ---
funnels_to_gen = []
if funnel == "all":
    funnels_to_gen = ["tofu", "mofu", "bofu"]
else:
    funnels_to_gen = [funnel.lower()]

short_title = title[:50] if title else "this product"
sp_text = "; ".join(selling_points[:3])

ad_variants = []
for stage in funnels_to_gen:
    if stage == "tofu":
        hooks = [
            f"Did you know most people struggle with finding quality {short_title.split()[0].lower() if title else 'products'}?",
            f"Stop scrolling — this changes everything about how you think about {short_title.split()[-1].lower() if title else 'food'}.",
            f"What if I told you there's a better way?"
        ]
        body_template = "Most people don't realize {sp}. That's exactly why {title} exists — to solve the problem you didn't know you had."
    elif stage == "mofu":
        hooks = [
            f"Here's why {short_title} is different from everything else.",
            f"3 reasons people are switching to {short_title}:",
            f"We tested dozens of options. {short_title} won."
        ]
        body_template = "What makes it special? {sp}. Real results. Real quality. No gimmicks."
    else:  # bofu
        hooks = [
            f"Get {short_title} now" + (f" — {price}" if price else "") + ". Limited availability.",
            f"Your {short_title} is waiting. " + (f"Only {price}." if price else "Order now."),
            f"Last chance to grab {short_title}. Don't miss out."
        ]
        body_template = "{sp}. Join thousands of happy customers. Order today."

    for i, hook in enumerate(hooks):
        body = body_template.format(sp=sp_text, title=short_title)
        variant = {
            "stage": stage.upper(),
            "variant": chr(65 + i),
            "hook": hook,
            "body": body,
            "cta": "Shop Now" if stage == "bofu" else ("Learn More" if stage == "mofu" else "Discover"),
            "caption_short": f"{hook} {body[:60]}...",
            "caption_long": f"{hook}\n\n{body}\n\n{'Shop now' if stage == 'bofu' else 'Learn more'}: {source_url}"
        }
        ad_variants.append(variant)

# --- Generate image prompt for NanoBanana ---
image_prompt = (
    f"Professional product advertisement photo for {short_title}. "
    f"Clean white background, soft studio lighting, product centered. "
    f"Marketing style, high quality, appetizing"
    + (f", brand colors from {detected_brand}" if detected_brand else "")
    + ". 4:5 aspect ratio, social media ready."
)

output = {
    "source_url": source_url,
    "product": {
        "title": title,
        "price": price,
        "selling_points": selling_points,
    },
    "brand": detected_brand or "unknown",
    "ad_variants": ad_variants,
    "image_prompt": image_prompt,
    "nanobanana_command": f'ad-image-gen.sh generate --model nanobanana --prompt "{image_prompt}" --aspect-ratio 4:5'
        + (f' --brand {detected_brand}' if detected_brand else ''),
    "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S+08:00")
}

with open(out_file, "w") as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

# Pretty-print summary
print(json.dumps(output, indent=2, ensure_ascii=False))
PYEOF

        echo ""
        echo "[3/3] Output saved to: $OUT_FILE"
        echo ""
        echo "Next steps:"
        echo "  1. Review ad variants in the JSON output"
        echo "  2. Generate image: $(python3 -c "import json; d=json.load(open('$OUT_FILE')); print(d.get('nanobanana_command',''))" 2>/dev/null || echo 'See JSON output')"
        echo "  3. Post to Meta/TikTok via meta-ads-manager"
        ;;

    help|--help|-h|"")
        echo "MIRRA Ad Compositor — Compose real brand assets into ads"
        echo ""
        echo "Templates:"
        echo "  comparison          Split 'This vs That' (competitor vs MIRRA)"
        echo "  hero                Single product showcase"
        echo "  grid                Multi-product grid (2-6 products)"
        echo ""
        echo "Pipeline:"
        echo "  url-to-ad           Scrape product URL → generate ad copy + image prompt"
        echo ""
        echo "Batch:"
        echo "  batch-comparisons   All SKU × competitor combos (35 ads)"
        echo "  batch-heroes        Hero ad for each SKU (7 ads)"
        echo ""
        echo "Info:"
        echo "  list-skus           Show available product SKUs"
        echo "  list-templates      Show available templates"
        echo ""
        echo "Key difference from ad-image-gen.sh:"
        echo "  ad-image-gen.sh = AI generates everything from text prompt"
        echo "  ad-compose.sh  = Composites REAL assets (logo, photos, badges)"
        ;;

    *)
        echo "ERROR: Unknown command '$CMD'. Use 'ad-compose.sh help'" >&2
        exit 1
        ;;
esac
