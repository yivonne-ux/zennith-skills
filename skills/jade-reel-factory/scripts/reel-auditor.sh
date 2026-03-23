#!/usr/bin/env bash
# reel-auditor.sh — Visual QA "eyes" for Jade Oracle reels
# Extracts keyframes, scores 10 quality dimensions via Claude CLI,
# and produces a pass/fail audit report JSON.
#
# Usage:
#   bash reel-auditor.sh --input VIDEO_PATH [--threshold 7.0] [--dry-run]
#
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}

set -euo pipefail

###############################################################################
# Constants & Paths
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
FACE_REFS_DIR="$OPENCLAW_DIR/workspace/data/characters/jade-oracle/jade/face-refs"
LOG_FILE="$OPENCLAW_DIR/logs/jade-reel-auditor.log"

KEYFRAME_COUNT=5
CLAUDE_MODEL="claude-sonnet-4-6"

mkdir -p "$(dirname "$LOG_FILE")"

###############################################################################
# Logging
###############################################################################

log() {
    local msg="[reel-auditor $(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

err() {
    echo "[reel-auditor $(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
    echo "[reel-auditor $(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE" 2>/dev/null || true
}

###############################################################################
# Defaults
###############################################################################

INPUT=""
DRY_RUN=0
THRESHOLD="7.0"

###############################################################################
# Parse arguments
###############################################################################

usage() {
    cat <<USAGE
Usage: bash reel-auditor.sh --input VIDEO_PATH [OPTIONS]

Required:
  --input PATH          Path to the reel video file to audit

Options:
  --threshold N         Minimum passing score, 0-10 (default: 7.0)
  --dry-run             Show what would be done without scoring

Scores 10 dimensions (0-10 each):
  face_consistency, physics_logic, movement_quality, placement_sense,
  lighting_mood, hand_quality, text_artifacts, transition_smooth,
  music_sync, brand_alignment

Output: JSON audit report saved next to the input video.
USAGE
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --input)
            [ -z "${2:-}" ] && { err "--input requires a path"; usage; }
            INPUT="$2"; shift 2 ;;
        --threshold)
            [ -z "${2:-}" ] && { err "--threshold requires a number"; usage; }
            THRESHOLD="$2"; shift 2 ;;
        --dry-run)
            DRY_RUN=1; shift ;;
        -h|--help)
            usage ;;
        *)
            err "Unknown argument: $1"; usage ;;
    esac
done

###############################################################################
# Validation
###############################################################################

if [ -z "$INPUT" ]; then
    err "--input is required"
    usage
fi

if [ ! -f "$INPUT" ]; then
    err "Input video not found: $INPUT"
    exit 1
fi

# Validate threshold is a number
if ! echo "$THRESHOLD" | grep -qE '^[0-9]+\.?[0-9]*$'; then
    err "Threshold must be a number, got: $THRESHOLD"
    exit 1
fi

# Check ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    err "ffmpeg is required. Install via: brew install ffmpeg"
    exit 1
fi

# Check ffprobe
if ! command -v ffprobe >/dev/null 2>&1; then
    err "ffprobe is required. Install via: brew install ffmpeg"
    exit 1
fi

# Check python3
if ! command -v python3 >/dev/null 2>&1; then
    err "python3 is required"
    exit 1
fi

# Check Claude CLI availability
CLAUDE_CLI=""
if command -v claude >/dev/null 2>&1; then
    CLAUDE_CLI="claude"
fi

###############################################################################
# Create working directory
###############################################################################

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

###############################################################################
# Resolve output path (audit report JSON next to input video)
###############################################################################

INPUT_DIR="$(cd "$(dirname "$INPUT")" && pwd)"
INPUT_BASE="$(basename "$INPUT" .mp4)"
AUDIT_REPORT="$INPUT_DIR/${INPUT_BASE}-audit.json"

###############################################################################
# Step 1: Extract keyframes
###############################################################################

log "=== reel-auditor ==="
log "Input:     $INPUT"
log "Threshold: $THRESHOLD"
log "Dry-run:   $DRY_RUN"

# Get total frame count and duration
TOTAL_FRAMES="$(ffprobe -v error -count_frames -select_streams v:0 \
    -show_entries stream=nb_read_frames -of default=noprint_wrappers=1:nokey=1 \
    "$INPUT" 2>/dev/null || echo "")"

# Fallback: estimate from duration and fps
if [ -z "$TOTAL_FRAMES" ] || ! echo "$TOTAL_FRAMES" | grep -qE '^[0-9]+$'; then
    VIDEO_DURATION="$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null | cut -d. -f1)"
    VIDEO_FPS="$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate \
        -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null)"
    if [ -n "$VIDEO_DURATION" ] && [ -n "$VIDEO_FPS" ]; then
        # r_frame_rate comes as fraction like "30/1"
        FPS_NUM="$(echo "$VIDEO_FPS" | cut -d/ -f1)"
        FPS_DEN="$(echo "$VIDEO_FPS" | cut -d/ -f2)"
        if [ -n "$FPS_NUM" ] && [ -n "$FPS_DEN" ] && [ "$FPS_DEN" -gt 0 ] 2>/dev/null; then
            TOTAL_FRAMES=$((VIDEO_DURATION * FPS_NUM / FPS_DEN))
        else
            TOTAL_FRAMES=$((VIDEO_DURATION * 30))
        fi
    else
        TOTAL_FRAMES=150  # fallback: assume 5s at 30fps
    fi
fi

# Calculate interval between keyframes
if [ "$TOTAL_FRAMES" -le "$KEYFRAME_COUNT" ]; then
    INTERVAL=1
else
    INTERVAL=$((TOTAL_FRAMES / KEYFRAME_COUNT))
fi

log "Total frames: ~$TOTAL_FRAMES, extracting $KEYFRAME_COUNT at interval $INTERVAL"

if [ "$DRY_RUN" -eq 1 ]; then
    echo ""
    echo "=== DRY RUN ==="
    echo "Would extract $KEYFRAME_COUNT keyframes from: $INPUT"
    echo "Would score 10 dimensions via Claude CLI ($CLAUDE_MODEL)"
    echo "Threshold: $THRESHOLD"
    echo "Report would be: $AUDIT_REPORT"
    echo ""
    echo "Dimensions:"
    echo "  face_consistency, physics_logic, movement_quality, placement_sense,"
    echo "  lighting_mood, hand_quality, text_artifacts, transition_smooth,"
    echo "  music_sync, brand_alignment"
    exit 0
fi

# Extract frames
ffmpeg -y -i "$INPUT" \
    -vf "select='not(mod(n\,$INTERVAL))',setpts=N/FRAME_RATE/TB" \
    -frames:v "$KEYFRAME_COUNT" -q:v 2 \
    "$WORK_DIR/frame_%02d.jpg" 2>/dev/null || {
    err "Failed to extract keyframes"
    exit 1
}

# Verify we got frames
EXTRACTED_COUNT="$(find "$WORK_DIR" -name 'frame_*.jpg' -type f 2>/dev/null | wc -l | tr -d ' ')"
if [ "$EXTRACTED_COUNT" -eq 0 ]; then
    err "No keyframes were extracted"
    exit 1
fi

log "Extracted $EXTRACTED_COUNT keyframes"

###############################################################################
# Step 1b: Extract audio waveform info for music_sync scoring
###############################################################################

AUDIO_INFO="$WORK_DIR/audio_info.txt"
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels,duration \
    -of default=noprint_wrappers=1 "$INPUT" 2>/dev/null > "$AUDIO_INFO" || {
    echo "no_audio=true" > "$AUDIO_INFO"
}

# Get audio loudness stats
AUDIO_STATS="$WORK_DIR/audio_stats.txt"
ffmpeg -i "$INPUT" -af "volumedetect" -f null /dev/null 2>&1 | \
    grep -E "mean_volume|max_volume" > "$AUDIO_STATS" 2>/dev/null || {
    echo "no_stats=true" > "$AUDIO_STATS"
}

###############################################################################
# Step 1c: Gather Jade face reference description
###############################################################################

JADE_REF_DESC=""
if [ -d "$FACE_REFS_DIR" ]; then
    JADE_REF_COUNT="$(find "$FACE_REFS_DIR" -maxdepth 1 \( -name '*.png' -o -name '*.jpg' -o -name '*.webp' \) -type f 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$JADE_REF_COUNT" -gt 0 ]; then
        JADE_REF_DESC="Jade Oracle face reference images are available ($JADE_REF_COUNT refs in $FACE_REFS_DIR). Jade is a young Malaysian-Chinese woman with a mystical, warm aesthetic."
    fi
fi
if [ -z "$JADE_REF_DESC" ]; then
    JADE_REF_DESC="No face reference images available. Jade Oracle is a young Malaysian-Chinese woman with a mystical, warm aesthetic. Score face_consistency based on whether any human face looks consistent across frames."
fi

###############################################################################
# Step 2: Score dimensions via Claude CLI
###############################################################################

# Build frame descriptions listing
FRAME_LIST=""
frame_idx=1
while [ "$frame_idx" -le "$EXTRACTED_COUNT" ]; do
    padded="$(printf '%02d' "$frame_idx")"
    FRAME_LIST="$FRAME_LIST
Frame $frame_idx: $WORK_DIR/frame_${padded}.jpg"
    frame_idx=$((frame_idx + 1))
done

AUDIO_CONTEXT="$(cat "$AUDIO_INFO" 2>/dev/null || echo 'no audio stream detected')"
AUDIO_LOUDNESS="$(cat "$AUDIO_STATS" 2>/dev/null || echo 'no loudness stats')"

# Build the scoring prompt
SCORING_PROMPT="$WORK_DIR/scoring_prompt.txt"
cat > "$SCORING_PROMPT" << 'PROMPTEOF'
You are a visual QA auditor for Jade Oracle brand reels (Instagram vertical video content).

Analyze the following keyframes extracted from a reel and score each dimension from 0-10.

## Keyframes
PROMPTEOF

echo "$FRAME_LIST" >> "$SCORING_PROMPT"

cat >> "$SCORING_PROMPT" << PROMPTEOF2

## Audio context
$AUDIO_CONTEXT
$AUDIO_LOUDNESS

## Brand context
$JADE_REF_DESC
Jade Oracle brand palette: deep greens, gold accents, cream/warm white, mystical purple hints.
Mood: warm, cozy, mystical, grounded, intimate.

## Score these 10 dimensions (0-10 each):

1. **face_consistency** — Does the face look consistent across all frames? Does it look like the same person?
2. **physics_logic** — Are objects obeying gravity? No floating items, impossible positions?
3. **movement_quality** — Do sequential frames suggest natural, smooth motion (not glitchy/jumpy)?
4. **placement_sense** — Are objects placed where they should be? Good composition?
5. **lighting_mood** — Is lighting warm, consistent across frames, and brand-aligned?
6. **hand_quality** — If hands are visible, are they natural? No extra fingers or weird poses?
7. **text_artifacts** — Is the scene free of gibberish text, garbled letters, or strange symbols?
8. **transition_smooth** — Do transitions between scenes look clean? No harsh cuts or artifacts?
9. **music_sync** — Based on audio data: is there audio? Does it seem present and at reasonable levels?
10. **brand_alignment** — Does the overall look match Jade Oracle's green/gold/cream palette and mystical mood?

## Response format
Reply ONLY with valid JSON, no markdown fences, no commentary:
{
  "face_consistency": N,
  "physics_logic": N,
  "movement_quality": N,
  "placement_sense": N,
  "lighting_mood": N,
  "hand_quality": N,
  "text_artifacts": N,
  "transition_smooth": N,
  "music_sync": N,
  "brand_alignment": N,
  "feedback": ["specific issue 1", "specific issue 2", ...]
}
PROMPTEOF2

log "Scoring via Claude CLI ($CLAUDE_MODEL)..."

SCORES_RAW="$WORK_DIR/scores_raw.json"

if [ -n "$CLAUDE_CLI" ]; then
    # Use Claude CLI with --print to get direct output
    "$CLAUDE_CLI" --print --model "$CLAUDE_MODEL" < "$SCORING_PROMPT" > "$SCORES_RAW" 2>/dev/null || {
        err "Claude CLI scoring failed"
        # Create fallback scores
        log "Using fallback placeholder scores"
        echo '{"face_consistency":5,"physics_logic":5,"movement_quality":5,"placement_sense":5,"lighting_mood":5,"hand_quality":5,"text_artifacts":5,"transition_smooth":5,"music_sync":5,"brand_alignment":5,"feedback":["Automated scoring unavailable - manual review required"]}' > "$SCORES_RAW"
    }
else
    log "WARNING: Claude CLI not available. Using placeholder scores."
    echo '{"face_consistency":5,"physics_logic":5,"movement_quality":5,"placement_sense":5,"lighting_mood":5,"hand_quality":5,"text_artifacts":5,"transition_smooth":5,"music_sync":5,"brand_alignment":5,"feedback":["Claude CLI not available - manual review required"]}' > "$SCORES_RAW"
fi

# Clean the response — strip any markdown fences or extra text
python3 << 'PYEOF' "$SCORES_RAW" "$WORK_DIR/scores_clean.json"
import json, sys, re

raw_path = sys.argv[1]
clean_path = sys.argv[2]

with open(raw_path, 'r') as f:
    raw = f.read().strip()

# Strip markdown code fences if present
raw = re.sub(r'^```(?:json)?\s*', '', raw, flags=re.MULTILINE)
raw = re.sub(r'\s*```\s*$', '', raw, flags=re.MULTILINE)

# Find the JSON object
match = re.search(r'\{[\s\S]*\}', raw)
if match:
    raw = match.group(0)

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    # Fallback
    data = {
        "face_consistency": 5, "physics_logic": 5, "movement_quality": 5,
        "placement_sense": 5, "lighting_mood": 5, "hand_quality": 5,
        "text_artifacts": 5, "transition_smooth": 5, "music_sync": 5,
        "brand_alignment": 5,
        "feedback": ["Failed to parse AI scoring response - manual review required"]
    }

with open(clean_path, 'w') as f:
    json.dump(data, f)
PYEOF

###############################################################################
# Step 3-6: Calculate overall score and generate audit report
###############################################################################

python3 << 'PYEOF' "$WORK_DIR/scores_clean.json" "$AUDIT_REPORT" "$INPUT" "$THRESHOLD"
import json, sys

scores_path = sys.argv[1]
report_path = sys.argv[2]
input_path = sys.argv[3]
threshold = float(sys.argv[4])

with open(scores_path, 'r') as f:
    data = json.load(f)

# Extract dimension scores
dimensions = [
    'face_consistency', 'physics_logic', 'movement_quality', 'placement_sense',
    'lighting_mood', 'hand_quality', 'text_artifacts', 'transition_smooth',
    'music_sync', 'brand_alignment'
]

# Weights: face_consistency and brand_alignment weighted higher
weights = {
    'face_consistency': 1.5,
    'physics_logic': 1.0,
    'movement_quality': 1.2,
    'placement_sense': 1.0,
    'lighting_mood': 1.2,
    'hand_quality': 1.0,
    'text_artifacts': 1.0,
    'transition_smooth': 1.0,
    'music_sync': 0.8,
    'brand_alignment': 1.3
}

scores = {}
weighted_sum = 0.0
total_weight = 0.0

for dim in dimensions:
    score = data.get(dim, 5)
    # Clamp to 0-10
    if isinstance(score, (int, float)):
        score = max(0, min(10, score))
    else:
        score = 5
    scores[dim] = score
    w = weights.get(dim, 1.0)
    weighted_sum += score * w
    total_weight += w

overall = round(weighted_sum / total_weight, 1) if total_weight > 0 else 5.0
passed = overall >= threshold

feedback = data.get('feedback', [])
if not isinstance(feedback, list):
    feedback = [str(feedback)]

# Build recommendation
if passed:
    recommendation = "PASS"
else:
    # Identify weak dimensions (below threshold)
    weak = []
    for dim in dimensions:
        if scores[dim] < threshold:
            weak.append(dim)
    if weak:
        recommendation = "REGENERATE - weak dimensions: %s" % ', '.join(weak)
    else:
        recommendation = "REGENERATE - overall score %.1f below threshold %.1f" % (overall, threshold)

report = {
    "input": input_path,
    "overall_score": overall,
    "pass": passed,
    "threshold": threshold,
    "dimensions": scores,
    "feedback": feedback,
    "recommendation": recommendation
}

with open(report_path, 'w') as f:
    json.dump(report, f, indent=2)

# Print summary to stdout
print(json.dumps(report, indent=2))
PYEOF

REPORT_EXIT=$?

if [ "$REPORT_EXIT" -ne 0 ]; then
    err "Failed to generate audit report"
    exit 1
fi

###############################################################################
# Done
###############################################################################

log "Audit complete: $AUDIT_REPORT"

# Parse pass/fail from report for exit messaging
PASS_STATUS="$(python3 -c "import json; d=json.load(open('$AUDIT_REPORT')); print('PASS' if d.get('pass') else 'FAIL')" 2>/dev/null || echo "UNKNOWN")"
OVERALL_SCORE="$(python3 -c "import json; d=json.load(open('$AUDIT_REPORT')); print(d.get('overall_score', '?'))" 2>/dev/null || echo "?")"

echo ""
echo "=== REEL AUDIT ==="
echo "Input:     $INPUT"
echo "Score:     $OVERALL_SCORE / 10"
echo "Threshold: $THRESHOLD"
echo "Result:    $PASS_STATUS"
echo "Report:    $AUDIT_REPORT"
