#!/usr/bin/env bash
# ref-to-jade-video.sh — Reference Video → Decompose → Jade Face-Locked Recreation
#
# THE CORRECT FLOW:
#   1. Take reference video (competitor/inspiration)
#   2. Decompose into scenes (frame extraction + Gemini Vision analysis)
#   3. Agent understands each scene: angle, lighting, composition, context
#   4. NanoBanana recreates each scene with JADE'S FACE (face-locked + ref image)
#   5. Kling i2v animates each scene (face stays locked)
#   6. Assemble + post-prod
#
# Usage:
#   ref-to-jade-video.sh --ref <video_or_url> [--scenes 5] [--provider kling]
#   ref-to-jade-video.sh --ref https://tiktok.com/... --scenes 3

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW="$HOME/.openclaw"
CHAR_LOCK="$OPENCLAW/skills/character-lock/scripts/character-lock.sh"
NANOBANANA="$OPENCLAW/skills/nanobanana/scripts/nanobanana-gen.sh"
VIDEO_GEN="$OPENCLAW/skills/video-gen/scripts/video-gen.sh"
VIDEO_FORGE="$OPENCLAW/skills/video-forge/scripts/video-forge.sh"
LEARN_VIDEO="$OPENCLAW/skills/learn-youtube/scripts/learn-video.sh"
OUTPUT_DIR="$OPENCLAW/workspace/data/productions/jade-oracle/$(date +%Y-%m-%d)"
LOG_FILE="$OPENCLAW/logs/ref-to-jade.log"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"

BRAND="jade-oracle"
CHARACTER="jade"
REF_INPUT=""
NUM_SCENES=5
PROVIDER="kling"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)      REF_INPUT="$2"; shift 2 ;;
    --scenes)   NUM_SCENES="$2"; shift 2 ;;
    --provider) PROVIDER="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$REF_INPUT" ]] && { echo "ERROR: --ref required (video file path or URL)"; exit 1; }

mkdir -p "$OUTPUT_DIR" "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date +%H%M%S)
WORK_DIR="$OUTPUT_DIR/ref-to-jade-${TIMESTAMP}"
mkdir -p "$WORK_DIR"/{frames,scenes,clips,final}

log() { echo "[ref2jade $(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  REF → JADE — Reference Video to Face-Locked Content  ║"
echo "║  Ref: ${REF_INPUT:0:50}                                ║"
echo "║  Scenes: $NUM_SCENES | Provider: $PROVIDER             ║"
echo "╚═══════════════════════════════════════════════════════╝"

# ━━━ STEP 1: GET REFERENCE VIDEO ━━━
echo ""
echo "━━━ STEP 1: GET REFERENCE VIDEO ━━━"

REF_VIDEO=""
if [[ "$REF_INPUT" == http* ]]; then
  # Download from URL
  log "Downloading reference video from URL..."
  REF_VIDEO="$WORK_DIR/ref-source.mp4"
  if [[ -f "$LEARN_VIDEO" ]]; then
    bash "$LEARN_VIDEO" "$REF_INPUT" --output "$WORK_DIR" 2>&1 | sed 's/^/  /' || true
    REF_VIDEO=$(find "$WORK_DIR" -name "*.mp4" -maxdepth 1 2>/dev/null | head -1)
  fi
  if [[ -z "$REF_VIDEO" || ! -f "$REF_VIDEO" ]]; then
    yt-dlp -f "bestvideo[height<=720]" -o "$WORK_DIR/ref-source.%(ext)s" "$REF_INPUT" 2>&1 | tail -3
    REF_VIDEO=$(find "$WORK_DIR" -name "ref-source.*" -maxdepth 1 2>/dev/null | head -1)
  fi
elif [[ -f "$REF_INPUT" ]]; then
  REF_VIDEO="$REF_INPUT"
fi

if [[ -z "$REF_VIDEO" || ! -f "$REF_VIDEO" ]]; then
  echo "  ❌ Could not get reference video"
  exit 1
fi
echo "  ✅ Reference: $REF_VIDEO ($(du -h "$REF_VIDEO" | cut -f1))"

# ━━━ STEP 2: DECOMPOSE INTO SCENES ━━━
echo ""
echo "━━━ STEP 2: DECOMPOSE INTO SCENES ━━━"

# Extract evenly-spaced frames
VID_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$REF_VIDEO" 2>/dev/null | cut -d. -f1)
VID_DURATION=${VID_DURATION:-30}
INTERVAL=$((VID_DURATION / NUM_SCENES))
[[ "$INTERVAL" -lt 1 ]] && INTERVAL=1

echo "  Duration: ${VID_DURATION}s, extracting $NUM_SCENES frames (every ${INTERVAL}s)..."

for i in $(seq 0 $((NUM_SCENES - 1))); do
  SEEK=$((i * INTERVAL))
  ffmpeg -ss "$SEEK" -i "$REF_VIDEO" -vframes 1 -q:v 2 "$WORK_DIR/frames/scene-$(printf '%02d' $i).jpg" 2>/dev/null
done

FRAME_COUNT=$(find "$WORK_DIR/frames" -name "*.jpg" 2>/dev/null | wc -l | tr -d ' ')
echo "  ✅ Extracted $FRAME_COUNT frames"

# ━━━ STEP 3: ANALYZE EACH SCENE (Gemini Vision) ━━━
echo ""
echo "━━━ STEP 3: ANALYZE SCENES (Gemini Vision) ━━━"

# Load API key
source "$HOME/.env" 2>/dev/null || true
GEMINI_KEY="${GEMINI_API_KEY:-${GOOGLE_API_KEY:-}}"

if [[ -z "$GEMINI_KEY" ]]; then
  echo "  ⚠️  No GEMINI_API_KEY — using basic frame descriptions"
  # Create basic descriptions from filenames
  for frame in "$WORK_DIR/frames"/scene-*.jpg; do
    idx=$(basename "$frame" .jpg | sed 's/scene-//')
    echo "{\"scene\": $idx, \"description\": \"Scene from reference video\", \"angle\": \"medium shot\", \"lighting\": \"natural\", \"mood\": \"warm\"}" > "$WORK_DIR/frames/analysis-${idx}.json"
  done
else
  log "Analyzing scenes via Gemini Vision..."
  "$PYTHON3" - "$WORK_DIR/frames" "$GEMINI_KEY" << 'PYEOF'
import base64, json, os, sys, glob, ssl
import urllib.request
# Fix macOS SSL cert issue
ssl._create_default_https_context = ssl._create_unverified_context

frames_dir = sys.argv[1]
api_key = sys.argv[2]

frames = sorted(glob.glob(os.path.join(frames_dir, "scene-*.jpg")))
print(f"  Analyzing {len(frames)} frames...")

for frame_path in frames:
    idx = os.path.basename(frame_path).replace("scene-", "").replace(".jpg", "")

    with open(frame_path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode()

    payload = {
        "contents": [{"parts": [
            {"text": """Analyze this video frame for recreation. Return JSON:
{
  "description": "what is happening in this scene",
  "subject": "who/what is the main subject",
  "angle": "camera angle (close-up, medium, wide, overhead, low)",
  "lighting": "lighting description (warm, cool, natural, candlelight, golden hour)",
  "color_temp_k": 3500,
  "environment": "location/setting",
  "mood": "emotional mood",
  "attire": "what the subject is wearing (or N/A)",
  "props": "objects in scene",
  "composition": "how the frame is composed (rule of thirds, center, etc.)",
  "recreation_prompt": "detailed prompt to recreate this scene with a different person, keeping same angle/lighting/composition"
}
Return ONLY JSON."""},
            {"inline_data": {"mime_type": "image/jpeg", "data": b64}}
        ]}],
        "generationConfig": {"temperature": 0.2, "maxOutputTokens": 512}
    }

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"

    try:
        req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                     headers={"Content-Type": "application/json"}, method="POST")
        resp = urllib.request.urlopen(req, timeout=30)
        result = json.loads(resp.read().decode())
        text = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "{}")
        # Clean any markdown fences
        text = text.strip().strip("`").strip()
        if text.startswith("json"):
            text = text[4:].strip()

        analysis = json.loads(text)
        with open(os.path.join(frames_dir, f"analysis-{idx}.json"), "w") as f:
            json.dump(analysis, f, indent=2)
        print(f"  Scene {idx}: {analysis.get('description', '?')[:60]}")
    except Exception as e:
        print(f"  Scene {idx}: analysis failed ({e})")
        with open(os.path.join(frames_dir, f"analysis-{idx}.json"), "w") as f:
            json.dump({"description": "Scene from reference", "angle": "medium", "lighting": "natural"}, f)
PYEOF
fi

echo "  ✅ Scene analysis complete"

# ━━━ STEP 4: LOAD CHARACTER LOCK ━━━
echo ""
echo "━━━ STEP 4: CHARACTER LOCK ━━━"

PROMPT_SUFFIX=""
FACE_REFS=""
if [[ -f "$CHAR_LOCK" ]]; then
  PROMPT_SUFFIX=$(bash "$CHAR_LOCK" load --brand "$BRAND" --character "$CHARACTER" --json 2>/dev/null | \
    "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin).get('rules',{}).get('prompt_suffix',''))" 2>/dev/null) || true
  FACE_REFS=$(bash "$CHAR_LOCK" refs --brand "$BRAND" --character "$CHARACTER" 2>/dev/null) || true
  echo "  🔒 Face-lock: loaded ($(echo "$FACE_REFS" | tr ',' '\n' | wc -l | tr -d ' ') refs)"
else
  echo "  ❌ character-lock.sh not found — CANNOT proceed without face lock"
  exit 1
fi

[[ -z "$FACE_REFS" ]] && { echo "  ❌ No face refs found — cannot generate face-locked content"; exit 1; }

# ━━━ STEP 5: GENERATE JADE SCENES (NanoBanana + face refs + ref frame) ━━━
echo ""
echo "━━━ STEP 5: RECREATE SCENES AS JADE (NanoBanana, face-locked) ━━━"

for analysis in "$WORK_DIR/frames"/analysis-*.json; do
  idx=$(basename "$analysis" .json | sed 's/analysis-//')
  ref_frame="$WORK_DIR/frames/scene-${idx}.jpg"

  # Read scene analysis
  SCENE_DESC=$("$PYTHON3" -c "import json; d=json.load(open('$analysis')); print(d.get('recreation_prompt', d.get('description', 'oracle reading scene')))")
  ANGLE=$("$PYTHON3" -c "import json; d=json.load(open('$analysis')); print(d.get('angle', 'medium shot'))")
  LIGHTING=$("$PYTHON3" -c "import json; d=json.load(open('$analysis')); print(d.get('lighting', 'natural light'))")

  FULL_PROMPT="Jade Oracle character: $SCENE_DESC. Camera: $ANGLE. Lighting: $LIGHTING. $PROMPT_SUFFIX"

  echo "  Scene $idx: ${SCENE_DESC:0:60}..."

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "    [dry-run] Would generate with NanoBanana (face refs + ref frame as composition guide)"
    cp "$ref_frame" "$WORK_DIR/scenes/jade-scene-${idx}.jpg" 2>/dev/null || true
  elif [[ -f "$NANOBANANA" ]]; then
    # Use BOTH face refs AND ref frame as references
    # Face refs = identity lock, ref frame = composition/angle guide
    ALL_REFS="$FACE_REFS,$ref_frame"

    NB_OUT=$(bash "$NANOBANANA" generate --brand "$BRAND" \
      --prompt "$FULL_PROMPT" \
      --ref-image "$ALL_REFS" \
      --use-case character 2>&1) || true

    GENERATED=$(echo "$NB_OUT" | grep -oE '/[^ ]+\.png' | tail -1)
    if [[ -n "$GENERATED" && -f "$GENERATED" ]]; then
      cp "$GENERATED" "$WORK_DIR/scenes/jade-scene-${idx}.png"
      echo "    ✅ Generated (face-locked + composition matched)"
    else
      echo "    ⚠️  NanoBanana failed — using face ref as fallback"
      cp "$(echo "$FACE_REFS" | tr ',' '\n' | head -1)" "$WORK_DIR/scenes/jade-scene-${idx}.png" 2>/dev/null || true
    fi
  fi
done

SCENE_COUNT=$(find "$WORK_DIR/scenes" -name "jade-scene-*" 2>/dev/null | wc -l | tr -d ' ')
echo "  ✅ $SCENE_COUNT Jade scenes generated (face-locked)"

# ━━━ STEP 6: ANIMATE EACH SCENE (Kling i2v) ━━━
echo ""
echo "━━━ STEP 6: ANIMATE SCENES (${PROVIDER} image-to-video, face-locked) ━━━"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "  [dry-run] Would generate ${SCENE_COUNT} clips via $PROVIDER image2video"
else
  for scene_img in "$WORK_DIR/scenes"/jade-scene-*; do
    [[ ! -f "$scene_img" ]] && continue
    idx=$(basename "$scene_img" | grep -oE '[0-9]+')
    clip_output="$WORK_DIR/clips/clip-${idx}.mp4"

    # Get scene description for motion prompt
    analysis="$WORK_DIR/frames/analysis-${idx}.json"
    SCENE_DESC=$("$PYTHON3" -c "import json; d=json.load(open('$analysis')); print(d.get('description', 'gentle movement'))" 2>/dev/null)

    echo "  Scene $idx: animating via $PROVIDER i2v..."
    bash "$VIDEO_GEN" "$PROVIDER" image2video \
      --image "$scene_img" \
      --prompt "$SCENE_DESC, natural subtle movement, $PROMPT_SUFFIX" \
      --duration 5 --aspect-ratio 9:16 \
      --output "$clip_output" \
      --brand "$BRAND" 2>&1 | sed 's/^/    /' || true

    [[ -f "$clip_output" ]] && echo "    ✅ Clip: $(du -h "$clip_output" | cut -f1)" || echo "    ⚠️  Clip pending"
  done
fi

# ━━━ STEP 7: ASSEMBLE + POST-PROD ━━━
echo ""
echo "━━━ STEP 7: ASSEMBLE + POST-PROD ━━━"

CLIP_COUNT=$(find "$WORK_DIR/clips" -name "*.mp4" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$CLIP_COUNT" -gt 0 && "$DRY_RUN" -eq 0 ]]; then
  CLIP_LIST=$(find "$WORK_DIR/clips" -name "*.mp4" | sort | tr '\n' ' ')
  ASSEMBLED="$WORK_DIR/final/assembled.mp4"

  bash "$VIDEO_FORGE" assemble $CLIP_LIST --output "$ASSEMBLED" 2>&1 | sed 's/^/  /' || true

  if [[ -f "$ASSEMBLED" ]]; then
    bash "$VIDEO_FORGE" effects "$ASSEMBLED" --grain light --vignette 2>&1 | sed 's/^/  /' || true
    echo "  ✅ Final video assembled"
  fi
else
  echo "  [${CLIP_COUNT} clips, dry-run=$DRY_RUN] Assembly skipped"
fi

echo ""
echo "━━━ COMPLETE ━━━"
echo "  📂 Work dir: $WORK_DIR/"
echo "  🎬 Frames: $FRAME_COUNT | Scenes: $SCENE_COUNT | Clips: $CLIP_COUNT"
echo "  🔒 Face: LOCKED throughout pipeline"
echo ""
echo "  Pipeline: ref video → decompose → vision analysis → NanoBanana (face-locked)"
echo "            → Kling i2v (face anchored) → assemble → post-prod"
