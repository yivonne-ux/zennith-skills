#!/usr/bin/env bash
# vision-analyze.sh — Analyze multiple images to extract visual DNA
# Usage: bash vision-analyze.sh <main_image> <ref1_image> [ref2_image] [...]
#
# Outputs: JSON with visual DNA, hooks, trends, and format suggestions
#
# Output format:
# {
#   "main_image": "path/to/image.jpg",
#   "reference_images": ["ref1.jpg", "ref2.jpg"],
#   "visual_dna": {
#     "scene_description": "...",
#     "color_palette": ["#hex", ...],
#     "lighting": "...",
#     "camera_angle": "...",
#     "style": "...",
#     "mood": "...",
#     "vibe": "..."
#   },
#   "hooks": [
#     "hook1: visual hook description",
#     "hook2: motion hook description"
#   ],
#   "trending_formats": [
#     "format: vertical bento topview (TikTok/IG Reels)"
#   ],
#   "suggested_prompts": {
#     "intent": "...",
#     "output": "...",
#     "campaign": "...",
#     "brand": "...",
#     "brief": "...",
#     "test": "..."
#   }
# }

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$HOME/.openclaw/.env"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
  while IFS= read -r line; do
    case "$line" in
      ""|\#*) continue ;;
      *=*) export "$line" ;;
    esac
  done < "$ENV_FILE"
fi

# Check for Gemini API key
if [ -z "${GEMINI_API_KEY:-}" ]; then
  GEMINI_API_KEY=$(grep 'GEMINI_API_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*GEMINI_API_KEY=['\"]*//" | sed "s/['\"].*//" || true)
  export GEMINI_API_KEY
fi

if [ -z "$GEMINI_API_KEY" ]; then
  echo "ERROR: GEMINI_API_KEY required"
  echo "Set in ~/.openclaw/.env or ~/.zshrc"
  exit 1
fi

# Parse arguments
MAIN_IMAGE="${1:-}"
REF_IMAGES=("${@:2}")

if [ -z "$MAIN_IMAGE" ]; then
  echo "ERROR: Main image path required"
  echo "Usage: bash vision-analyze.sh <main_image> [ref1_image] [ref2_image] ..."
  exit 1
fi

if [ ! -f "$MAIN_IMAGE" ]; then
  echo "ERROR: Main image not found: $MAIN_IMAGE"
  exit 1
fi

# Build reference images list
REF_LIST=""
for ref in "${REF_IMAGES[@]}"; do
  if [ -n "$ref" ] && [ -f "$ref" ]; then
    REF_LIST="$REF_LIST --image \"$ref\""
  fi
done

OUTPUT_FILE="${MAIN_IMAGE%.png}_vision_dna.json"
OUTPUT_FILE="${OUTPUT_FILE%.jpg}_vision_dna.json"

echo "=== Vision Analysis ==="
echo "Main:     $MAIN_IMAGE"
echo "References: ${#REF_IMAGES[@]}"
echo "Output:   $OUTPUT_FILE"
echo ""

# Construct analysis prompt for Gemini Vision
GEMINI_PROMPT="You are an expert video creative director with 10+ years of experience creating viral content for social media (TikTok, IG Reels, YouTube Shorts).

Analyze these images and return a JSON object with these exact keys:

{
  \"main_image\": \"path/to/image.jpg\",
  \"reference_images\": [\"ref1.jpg\", \"ref2.jpg\"],
  \"visual_dna\": {
    \"scene_description\": \"Brief description of what's in the main image (subject, action, environment)\",
    \"color_palette\": [\"#hex\", \"#hex\", ...] // Main dominant colors
    \"lighting\": \"Lighting style (warm natural, dramatic, soft, etc.)\",
    \"camera_angle\": \"Camera position (top-down, eye-level, low-angle, drone, etc.)\",
    \"style\": \"Overall visual style (clean, rustic, vibrant, minimal, etc.)\",
    \"mood\": \"Emotional mood/atmosphere (authentic, exciting, relaxing, etc.)\",
    \"vibe\": \"Current vibe trend (authentic, polished, raw, etc.)\"
  },
  \"hooks\": [
    \"Hook 1: Visual/narrative hook that grabs attention (1-2 sentences)\",
    \"Hook 2: Second hook (optional)\"
  ],
  \"trending_formats\": [
    \"Format 1: Best format for this content type (e.g., 'Vertical bento topview for TikTok/IG Reels')\",
    \"Format 2: Alternative format (if applicable)\"
  ],
  \"trending_tones\": [
    \"Tone 1: Current viral tone trend (e.g., 'Raw authentic handheld camera with room tone')\",
    \"Tone 2: Alternative trend (if applicable)\"
  ],
  \"passing_lenses\": [
    \"PAS Lens 1: Problem (what pain point this addresses) - 2 sentences\",
    \"PAS Lens 2: Amplify (the bigger truth this reveals) - 2 sentences\",
    \"PAS Lens 3: Solution (what you're offering that solves it) - 2 sentences\"
  ],
  \"suggested_prompts\": {
    \"intent\": \"What's the main intent? (educate, entertain, sell, inspire)\",
    \"output\": \"What output type? (reels, stories, ads, tutorial, testimonial)\",
    \"campaign\": \"What's the campaign concept? (tagline + angle)\",
    \"brand\": \"What's the brand positioning? (voice, tone, values)\",
    \"brief\": \"What's the creative brief? (3 key directions)\",
    \"test\": \"What's a test concept to validate?\"
  }
}

Return ONLY valid JSON with these exact keys. No markdown fences, no explanation."""

# Build multi-part request with main + reference images
echo "Sending to Gemini Vision for analysis..."

python3 << 'PYEOF'
import json, os, sys
import base64
import urllib.request

api_key = os.environ.get("GEMINI_API_KEY", "")
main_image = sys.argv[1]
reference_images = sys.argv[2:]

def encode_image(file_path):
    """Encode image as base64 data URI"""
    mime_type = "image/jpeg"
    if file_path.endswith(".png"):
        mime_type = "image/png"
    elif file_path.endswith(".webp"):
        mime_type = "image/webp"

    with open(file_path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode()

    return f"data:{mime_type};base64,{b64}"

def build_gemini_request(main_img, refs):
    """Build multi-part request for Gemini Vision"""
    parts = []

    # Add text prompt first
    text = """You are an expert video creative director with 10+ years of experience creating viral content for social media (TikTok, IG Reels, YouTube Shorts).

Analyze these images and return a JSON object with these exact keys:

{
  "main_image": "path/to/image.jpg",
  "reference_images": ["ref1.jpg", "ref2.jpg"],
  "visual_dna": {
    "scene_description": "Brief description of what's in the main image (subject, action, environment)",
    "color_palette": ["#hex", "#hex", ...] // Main dominant colors
    "lighting": "Lighting style (warm natural, dramatic, soft, etc.)",
    "camera_angle": "Camera position (top-down, eye-level, low-angle, drone, etc.)",
    "style": "Overall visual style (clean, rustic, vibrant, minimal, etc.)",
    "mood": "Emotional mood/atmosphere (authentic, exciting, relaxing, etc.)",
    "vibe": "Current vibe trend (authentic, polished, raw, etc.)"
  },
  "hooks": [
    "Hook 1: Visual/narrative hook that grabs attention (1-2 sentences)",
    "Hook 2: Second hook (optional)"
  ],
  "trending_formats": [
    "Format 1: Best format for this content type (e.g., 'Vertical bento topview for TikTok/IG Reels')",
    "Format 2: Alternative format (if applicable)"
  ],
  "trending_tones": [
    "Tone 1: Current viral tone trend (e.g., 'Raw authentic handheld camera with room tone')",
    "Tone 2: Alternative trend (if applicable)"
  ],
  "passing_lenses": [
    "PAS Lens 1: Problem (what pain point this addresses) - 2 sentences",
    "PAS Lens 2: Amplify (the bigger truth this reveals) - 2 sentences",
    "PAS Lens 3: Solution (what you're offering that solves it) - 2 sentences"
  ],
  "suggested_prompts": {
    "intent": "What's the main intent? (educate, entertain, sell, inspire)",
    "output": "What output type? (reels, stories, ads, tutorial, testimonial)",
    "campaign": "What's the campaign concept? (tagline + angle)",
    "brand": "What's the brand positioning? (voice, tone, values)",
    "brief": "What's the creative brief? (3 key directions)",
    "test": "What's a test concept to validate?"
  }
}

Return ONLY valid JSON with these exact keys. No markdown fences, no explanation."""

    parts.append({"text": text})

    # Add main image
    main_b64 = encode_image(main_img)
    parts.append({
        "inline_data": {
            "mime_type": main_b64.split(";")[1].split(":")[1] if ";" in main_b64 else "image/jpeg",
            "data": main_b64.split(",")[1] if "," in main_b64 else main_b64
        }
    })

    # Add reference images
    for ref in refs:
        ref_b64 = encode_image(ref)
        parts.append({
            "inline_data": {
                "mime_type": ref_b64.split(";")[1].split(":")[1] if ";" in ref_b64 else "image/jpeg",
                "data": ref_b64.split(",")[1] if "," in ref_b64 else ref_b64
            }
        })

    return parts

# Build request
payload = {
    "contents": [{"parts": build_gemini_request(main_image, reference_images)}],
    "generationConfig": {
        "temperature": 0.3,
        "maxOutputTokens": 2048
    }
}

url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"

try:
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    with urllib.request.urlopen(req, timeout=120) as resp:
        result = json.loads(resp.read().decode())

    text = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")

    # Try to parse as JSON
    try:
        parsed = json.loads(text)
        # Replace relative image paths with absolute paths
        if isinstance(parsed, dict):
            if "main_image" in parsed:
                parsed["main_image"] = main_image
            if "reference_images" in parsed and isinstance(parsed["reference_images"], list):
                parsed["reference_images"] = [ref if os.path.isabs(ref) else os.path.abspath(ref) for ref in parsed["reference_images"]]
        print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError as e:
        # Return raw text with JSON syntax highlighted
        print(json.dumps({"raw_text": text, "parse_error": str(e)}, indent=2))

except Exception as e:
    print(json.dumps({"error": str(e)}, indent=2))
    sys.exit(1)
PYEOF "$MAIN_IMAGE" "${REF_IMAGES[@]}" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
  echo ""
  echo "=== Analysis Complete ==="
  echo "Visual DNA: $OUTPUT_FILE"
  echo ""
  echo "Visual Insights:"
  head -c 300 "$OUTPUT_FILE"
  echo "..."
  echo ""
  echo "Use this file as prompt reference for Dreami/Sora video generation."
else
  echo "ERROR: Vision analysis failed"
  exit 1
fi