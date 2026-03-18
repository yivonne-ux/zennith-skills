#!/usr/bin/env bash
# jade-content-factory.sh — End-to-end AI influencer video production pipeline
# Usage: bash jade-content-factory.sh [mode] [options]
#
# Modes:
#   script    — Generate script from hook/topic
#   voice     — Generate voice audio from script
#   video     — Generate talking head video from image + audio
#   broll     — Generate B-roll clips
#   edit      — Assemble final video (talking head + B-roll + captions)
#   full      — Run entire pipeline (script → voice → video → edit)
#   batch     — Produce N videos from a topic list
#
# Examples:
#   bash jade-content-factory.sh script --topic "birth year 1988 reading"
#   bash jade-content-factory.sh voice --script output/scripts/hook-001.txt
#   bash jade-content-factory.sh video --image jade-face.png --audio output/voice/hook-001.mp3
#   bash jade-content-factory.sh full --topic "your birth year reveals your hidden power"
#   bash jade-content-factory.sh batch --topics topics.txt --count 5

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_DIR="$HOME/.openclaw"
CHARACTER_DIR="$OPENCLAW_DIR/workspace/data/characters/jade-oracle/jade"
FACE_REFS="$CHARACTER_DIR/face-refs"
OUTPUT_DIR="$OPENCLAW_DIR/workspace/data/videos/jade-oracle"
SECRETS_DIR="$OPENCLAW_DIR/secrets"
SCRIPTS_OUT="$OUTPUT_DIR/scripts"
VOICE_OUT="$OUTPUT_DIR/voice"
VIDEO_OUT="$OUTPUT_DIR/video"
BROLL_OUT="$OUTPUT_DIR/broll"
FINAL_OUT="$OUTPUT_DIR/final"

# Ensure output dirs exist
mkdir -p "$SCRIPTS_OUT" "$VOICE_OUT" "$VIDEO_OUT" "$BROLL_OUT" "$FINAL_OUT"

# Load API keys from secrets
load_secrets() {
    [[ -f "$SECRETS_DIR/fish-audio.env" ]] && source "$SECRETS_DIR/fish-audio.env"
    [[ -f "$SECRETS_DIR/elevenlabs.env" ]] && source "$SECRETS_DIR/elevenlabs.env"
    [[ -f "$SECRETS_DIR/heygen.env" ]] && source "$SECRETS_DIR/heygen.env"
    [[ -f "$SECRETS_DIR/kling.env" ]] && source "$SECRETS_DIR/kling.env"
    [[ -f "$SECRETS_DIR/openrouter.env" ]] && source "$SECRETS_DIR/openrouter.env"
}

# Timestamp for unique filenames
ts() { date +%Y%m%d-%H%M%S; }

# ============================================================
# STAGE 1: SCRIPT GENERATION
# ============================================================
# Uses Psychic Samira content formula:
#   0-3s: HOOK (pattern interrupt)
#   3-8s: PAIN POINT
#   8-15s: TEASE
#   15-45s: VALUE (QMDJ insight)
#   45-60s: CTA
# ============================================================
generate_script() {
    local topic="$1"
    local style="${2:-reading}"  # reading, tip, story, testimonial
    local duration="${3:-60}"    # seconds
    local output_file="$SCRIPTS_OUT/script-$(ts).txt"

    echo "[SCRIPT] Generating script for: $topic (style=$style, ${duration}s)"

    # Generate QMDJ insight if reading-style
    local qmdj_context=""
    if [[ "$style" == "reading" ]] && [[ -f "$OPENCLAW_DIR/skills/psychic-reading-engine/scripts/qmdj-calc.py" ]]; then
        qmdj_context=$(python3 "$OPENCLAW_DIR/skills/psychic-reading-engine/scripts/qmdj-calc.py" --mode realtime 2>/dev/null || echo "")
    fi

    # Build prompt
    local prompt
    prompt="You are Jade Oracle, a mystical AI spiritual guide who specializes in QMDJ (奇门遁甲) readings.
Write a ${duration}-second TikTok/Reels script about: ${topic}

Style: ${style}
Voice: warm, mystical, authoritative, gentle but powerful

STRUCTURE (strict timing):
[0-3s] HOOK — Pattern interrupt. Bold claim or question. Must stop the scroll.
[3-8s] PAIN POINT — \"You've been feeling...\" or \"Something shifted in your energy...\"
[8-15s] TEASE — \"What if I told you the stars aligned for you today...\"
[15-45s] VALUE — Actual QMDJ insight, reading, or spiritual tip. Be specific, not generic.
[45-60s] CTA — \"Comment your birth year\" or \"Save this for later\" or \"Link in bio for your full reading\"

${qmdj_context:+QMDJ CONTEXT (use this in the VALUE section):
$qmdj_context}

RULES:
- Write SPOKEN words only (no stage directions)
- Use conversational, spiritual tone
- Include 1 specific number, date, or celestial reference for credibility
- Hook must be under 10 words
- End with engagement-driving CTA
- Output ONLY the script text, nothing else"

    # Use Claude Code if available, otherwise OpenRouter
    if command -v claude &>/dev/null; then
        echo "$prompt" | claude -p --output-format text > "$output_file" 2>/dev/null
    elif [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
        local response
        response=$(/usr/bin/curl -s "https://openrouter.ai/api/v1/chat/completions" \
            -H "Authorization: Bearer $OPENROUTER_API_KEY" \
            -H "Content-Type: application/json" \
            -d "$(python3 -c "
import json, sys
print(json.dumps({
    'model': 'google/gemini-2.5-flash-preview',
    'messages': [{'role': 'user', 'content': sys.stdin.read()}],
    'max_tokens': 500
}))
" <<< "$prompt")")
        echo "$response" | python3 -c "import json,sys; print(json.load(sys.stdin)['choices'][0]['message']['content'])" > "$output_file" 2>/dev/null
    else
        echo "[ERROR] No LLM available. Set OPENROUTER_API_KEY or install claude CLI."
        return 1
    fi

    echo "[SCRIPT] Saved: $output_file"
    echo "$output_file"
}

# ============================================================
# STAGE 2: VOICE GENERATION
# ============================================================
# Priority: Fish Audio ($9.99/mo) > ElevenLabs ($5+/mo)
# Settings (ElevenLabs): Stability=45%, Similarity=90%, Enhancement=80%
# ============================================================
generate_voice() {
    local script_file="$1"
    local voice_provider="${2:-fish}"  # fish, elevenlabs
    local output_file="$VOICE_OUT/voice-$(ts).mp3"

    local text
    text=$(cat "$script_file")
    echo "[VOICE] Generating voice (${voice_provider}) for: $(echo "$text" | head -1)..."

    case "$voice_provider" in
        fish)
            if [[ -z "${FISH_AUDIO_API_KEY:-}" ]]; then
                echo "[ERROR] FISH_AUDIO_API_KEY not set. Add to $SECRETS_DIR/fish-audio.env"
                return 1
            fi
            # Fish Audio TTS API
            /usr/bin/curl -s -X POST "https://api.fish.audio/v1/tts" \
                -H "Authorization: Bearer $FISH_AUDIO_API_KEY" \
                -H "Content-Type: application/json" \
                -d "$(python3 -c "
import json, sys
print(json.dumps({
    'text': sys.stdin.read(),
    'reference_id': '${FISH_VOICE_ID:-}',
    'format': 'mp3',
    'mp3_bitrate': 128
}))
" <<< "$text")" \
                --output "$output_file"
            ;;
        elevenlabs)
            if [[ -z "${ELEVENLABS_API_KEY:-}" ]]; then
                echo "[ERROR] ELEVENLABS_API_KEY not set. Add to $SECRETS_DIR/elevenlabs.env"
                return 1
            fi
            local voice_id="${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"  # Default: Rachel
            /usr/bin/curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$voice_id" \
                -H "xi-api-key: $ELEVENLABS_API_KEY" \
                -H "Content-Type: application/json" \
                -d "$(python3 -c "
import json, sys
print(json.dumps({
    'text': sys.stdin.read(),
    'model_id': 'eleven_multilingual_v2',
    'voice_settings': {
        'stability': 0.45,
        'similarity_boost': 0.90,
        'style': 0.80,
        'use_speaker_boost': True
    }
}))
" <<< "$text")" \
                --output "$output_file"
            ;;
        *)
            echo "[ERROR] Unknown voice provider: $voice_provider (use: fish, elevenlabs)"
            return 1
            ;;
    esac

    # Verify output is valid audio
    if [[ -s "$output_file" ]] && file "$output_file" | grep -qi "audio\|mpeg\|mp3"; then
        echo "[VOICE] Saved: $output_file"
        echo "$output_file"
    else
        echo "[ERROR] Voice generation failed or returned invalid audio"
        [[ -f "$output_file" ]] && cat "$output_file"  # Show error response
        return 1
    fi
}

# ============================================================
# STAGE 3: TALKING HEAD VIDEO
# ============================================================
# Priority: HeyGen API (most mature) > Kling native > Hedra
# Key: Use close-up headshot, negative prompt "should not be talking"
# ============================================================
generate_talking_head() {
    local image_file="$1"
    local audio_file="$2"
    local provider="${3:-heygen}"  # heygen, kling
    local output_file="$VIDEO_OUT/talking-$(ts).mp4"

    echo "[VIDEO] Generating talking head (${provider})..."

    case "$provider" in
        heygen)
            if [[ -z "${HEYGEN_API_KEY:-}" ]]; then
                echo "[ERROR] HEYGEN_API_KEY not set. Add to $SECRETS_DIR/heygen.env"
                return 1
            fi

            # Step 1: Upload the audio
            local audio_upload
            audio_upload=$(/usr/bin/curl -s -X POST "https://api.heygen.com/v1/asset" \
                -H "X-Api-Key: $HEYGEN_API_KEY" \
                -F "file=@$audio_file")
            local audio_asset_id
            audio_asset_id=$(echo "$audio_upload" | python3 -c "import json,sys; print(json.load(sys.stdin).get('data',{}).get('asset_id',''))" 2>/dev/null)

            # Step 2: Upload the image
            local image_upload
            image_upload=$(/usr/bin/curl -s -X POST "https://api.heygen.com/v1/asset" \
                -H "X-Api-Key: $HEYGEN_API_KEY" \
                -F "file=@$image_file")
            local image_asset_id
            image_asset_id=$(echo "$image_upload" | python3 -c "import json,sys; print(json.load(sys.stdin).get('data',{}).get('asset_id',''))" 2>/dev/null)

            # Step 3: Generate video
            local gen_response
            gen_response=$(/usr/bin/curl -s -X POST "https://api.heygen.com/v2/video/generate" \
                -H "X-Api-Key: $HEYGEN_API_KEY" \
                -H "Content-Type: application/json" \
                -d "{
                    \"video_inputs\": [{
                        \"character\": {
                            \"type\": \"photo\",
                            \"photo_asset_id\": \"$image_asset_id\"
                        },
                        \"voice\": {
                            \"type\": \"audio\",
                            \"audio_asset_id\": \"$audio_asset_id\"
                        }
                    }],
                    \"dimension\": {\"width\": 1080, \"height\": 1920},
                    \"aspect_ratio\": \"9:16\"
                }")

            local video_id
            video_id=$(echo "$gen_response" | python3 -c "import json,sys; print(json.load(sys.stdin).get('data',{}).get('video_id',''))" 2>/dev/null)

            if [[ -z "$video_id" ]]; then
                echo "[ERROR] HeyGen video generation failed: $gen_response"
                return 1
            fi

            echo "[VIDEO] HeyGen job submitted: $video_id"
            echo "[VIDEO] Polling for completion..."

            # Poll until done (max 10 min)
            local max_wait=600
            local elapsed=0
            while (( elapsed < max_wait )); do
                sleep 15
                elapsed=$((elapsed + 15))
                local status_resp
                status_resp=$(/usr/bin/curl -s "https://api.heygen.com/v1/video_status.get?video_id=$video_id" \
                    -H "X-Api-Key: $HEYGEN_API_KEY")
                local video_status
                video_status=$(echo "$status_resp" | python3 -c "import json,sys; d=json.load(sys.stdin).get('data',{}); print(d.get('status',''))" 2>/dev/null)

                if [[ "$video_status" == "completed" ]]; then
                    local video_url
                    video_url=$(echo "$status_resp" | python3 -c "import json,sys; print(json.load(sys.stdin)['data']['video_url'])" 2>/dev/null)
                    /usr/bin/curl -s -L "$video_url" -o "$output_file"
                    echo "[VIDEO] Saved: $output_file"
                    echo "$output_file"
                    return 0
                elif [[ "$video_status" == "failed" ]]; then
                    echo "[ERROR] HeyGen video generation failed"
                    echo "$status_resp"
                    return 1
                fi
                echo "[VIDEO] Status: $video_status (${elapsed}s elapsed)"
            done
            echo "[ERROR] HeyGen video generation timed out after ${max_wait}s"
            return 1
            ;;

        kling)
            # Use existing video-gen.sh for Kling
            if [[ -f "$OPENCLAW_DIR/skills/video-gen/scripts/video-gen.sh" ]]; then
                echo "[VIDEO] Using Kling via video-gen.sh..."
                bash "$OPENCLAW_DIR/skills/video-gen/scripts/video-gen.sh" \
                    --provider kling \
                    --image "$image_file" \
                    --prompt "woman speaking directly to camera, close-up headshot, warm mystical lighting, should not be talking" \
                    --output "$output_file" 2>&1
                echo "$output_file"
            else
                echo "[ERROR] video-gen.sh not found"
                return 1
            fi
            ;;

        *)
            echo "[ERROR] Unknown video provider: $provider"
            return 1
            ;;
    esac
}

# ============================================================
# STAGE 4: B-ROLL GENERATION
# ============================================================
generate_broll() {
    local prompt="$1"
    local count="${2:-3}"
    local output_prefix="$BROLL_OUT/broll-$(ts)"

    echo "[B-ROLL] Generating $count clips for: $prompt"

    # Use video-gen.sh if available
    if [[ -f "$OPENCLAW_DIR/skills/video-gen/scripts/video-gen.sh" ]]; then
        for i in $(seq 1 "$count"); do
            local broll_prompt="cinematic mystical scene, ${prompt}, ethereal lighting, spiritual atmosphere, 4K, slow motion"
            bash "$OPENCLAW_DIR/skills/video-gen/scripts/video-gen.sh" \
                --provider wan \
                --prompt "$broll_prompt" \
                --output "${output_prefix}-${i}.mp4" 2>&1 &
        done
        wait
        echo "[B-ROLL] Generated $count clips at: $output_prefix-*.mp4"
    else
        echo "[WARN] video-gen.sh not found. Skipping B-roll."
    fi
}

# ============================================================
# STAGE 5: FINAL EDIT (talking head + B-roll + captions)
# ============================================================
assemble_video() {
    local talking_head="$1"
    local output_file="$FINAL_OUT/jade-$(ts).mp4"

    echo "[EDIT] Assembling final video..."

    # Get all B-roll clips generated in this session
    local broll_files
    broll_files=$(find "$BROLL_OUT" -name "broll-*.mp4" -newer "$talking_head" 2>/dev/null | sort | head -3)

    if [[ -n "$broll_files" ]]; then
        # Create concat list for ffmpeg
        local concat_list="$OUTPUT_DIR/concat-$(ts).txt"
        echo "file '$talking_head'" > "$concat_list"
        while IFS= read -r broll; do
            echo "file '$broll'" >> "$concat_list"
        done <<< "$broll_files"

        # Concatenate with crossfade transitions
        ffmpeg -y -f concat -safe 0 -i "$concat_list" \
            -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:-1:-1:color=black" \
            -c:v libx264 -preset medium -crf 23 \
            -c:a aac -b:a 128k \
            "$output_file" 2>/dev/null

        rm -f "$concat_list"
    else
        # No B-roll, just process the talking head
        ffmpeg -y -i "$talking_head" \
            -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:-1:-1:color=black,setsar=1" \
            -c:v libx264 -preset medium -crf 23 \
            -c:a aac -b:a 128k \
            "$output_file" 2>/dev/null
    fi

    # Add captions via video-forge.sh if available
    if [[ -f "$OPENCLAW_DIR/skills/video-forge/scripts/video-forge.sh" ]]; then
        echo "[EDIT] Adding captions..."
        bash "$OPENCLAW_DIR/skills/video-forge/scripts/video-forge.sh" \
            caption "$output_file" 2>&1 || true
    fi

    # Speed up 1.2x for natural-looking AI movement
    local sped_up="${output_file%.mp4}-final.mp4"
    ffmpeg -y -i "$output_file" \
        -filter_complex "[0:v]setpts=0.833*PTS[v];[0:a]atempo=1.2[a]" \
        -map "[v]" -map "[a]" \
        -c:v libx264 -preset medium -crf 23 \
        -c:a aac -b:a 128k \
        "$sped_up" 2>/dev/null

    if [[ -f "$sped_up" ]]; then
        mv "$sped_up" "$output_file"
    fi

    echo "[EDIT] Final video: $output_file"
    echo "$output_file"
}

# ============================================================
# FULL PIPELINE
# ============================================================
run_full_pipeline() {
    local topic="$1"
    local style="${2:-reading}"
    local voice_provider="${3:-fish}"
    local video_provider="${4:-heygen}"

    echo "============================================"
    echo " JADE ORACLE CONTENT FACTORY"
    echo " Topic: $topic"
    echo " Style: $style | Voice: $voice_provider | Video: $video_provider"
    echo "============================================"

    # Pick best face ref
    local face_ref
    face_ref=$(find "$FACE_REFS" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | head -1)
    if [[ -z "$face_ref" ]]; then
        echo "[ERROR] No face refs found in $FACE_REFS"
        echo "[FIX] Add jade face reference images to $FACE_REFS"
        return 1
    fi
    echo "[FACE] Using ref: $(basename "$face_ref")"

    # Stage 1: Script
    local script_file
    script_file=$(generate_script "$topic" "$style")
    if [[ $? -ne 0 ]] || [[ ! -f "$script_file" ]]; then
        echo "[ERROR] Script generation failed"
        return 1
    fi
    echo ""
    echo "--- SCRIPT ---"
    cat "$script_file"
    echo ""
    echo "--- END SCRIPT ---"
    echo ""

    # Stage 2: Voice
    local audio_file
    audio_file=$(generate_voice "$script_file" "$voice_provider")
    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Voice generation failed"
        return 1
    fi

    # Stage 3: Talking Head
    local video_file
    video_file=$(generate_talking_head "$face_ref" "$audio_file" "$video_provider")
    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Video generation failed"
        return 1
    fi

    # Stage 4: B-roll (parallel, non-blocking)
    generate_broll "$topic" 2 &
    local broll_pid=$!

    # Wait for B-roll
    wait "$broll_pid" 2>/dev/null || true

    # Stage 5: Assemble
    local final_video
    final_video=$(assemble_video "$video_file")

    echo ""
    echo "============================================"
    echo " PRODUCTION COMPLETE"
    echo " Final: $final_video"
    echo " Script: $script_file"
    echo " Voice: $audio_file"
    echo " Talking Head: $video_file"
    echo "============================================"
}

# ============================================================
# BATCH MODE
# ============================================================
run_batch() {
    local topics_file="$1"
    local count="${2:-5}"
    local voice_provider="${3:-fish}"
    local video_provider="${4:-heygen}"

    if [[ ! -f "$topics_file" ]]; then
        echo "[ERROR] Topics file not found: $topics_file"
        return 1
    fi

    echo "[BATCH] Processing $count topics from: $topics_file"
    local i=0
    while IFS= read -r topic && (( i < count )); do
        [[ -z "$topic" ]] && continue
        [[ "$topic" == \#* ]] && continue  # Skip comments
        i=$((i + 1))
        echo ""
        echo "======== VIDEO $i / $count ========"
        run_full_pipeline "$topic" "reading" "$voice_provider" "$video_provider"
    done < "$topics_file"

    echo ""
    echo "[BATCH] Completed $i videos"
}

# ============================================================
# CLI ARGUMENT PARSING
# ============================================================
usage() {
    echo "Usage: bash jade-content-factory.sh <mode> [options]"
    echo ""
    echo "Modes:"
    echo "  script    --topic <topic> [--style reading|tip|story] [--duration 60]"
    echo "  voice     --script <file> [--provider fish|elevenlabs]"
    echo "  video     --image <file> --audio <file> [--provider heygen|kling]"
    echo "  broll     --prompt <text> [--count 3]"
    echo "  edit      --input <video_file>"
    echo "  full      --topic <topic> [--style reading] [--voice fish] [--video heygen]"
    echo "  batch     --topics <file> [--count 5] [--voice fish] [--video heygen]"
    echo ""
    echo "Environment: Set API keys in $SECRETS_DIR/*.env"
    echo "  fish-audio.env:  FISH_AUDIO_API_KEY, FISH_VOICE_ID"
    echo "  elevenlabs.env:  ELEVENLABS_API_KEY, ELEVENLABS_VOICE_ID"
    echo "  heygen.env:      HEYGEN_API_KEY"
    echo "  openrouter.env:  OPENROUTER_API_KEY"
}

main() {
    load_secrets

    local mode="${1:-}"
    shift || true

    # Parse named args
    local topic="" script_file="" image_file="" audio_file="" prompt=""
    local style="reading" duration="60" voice_provider="fish" video_provider="heygen"
    local topics_file="" count="5" input_file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --topic) topic="$2"; shift 2 ;;
            --script) script_file="$2"; shift 2 ;;
            --image) image_file="$2"; shift 2 ;;
            --audio) audio_file="$2"; shift 2 ;;
            --prompt) prompt="$2"; shift 2 ;;
            --style) style="$2"; shift 2 ;;
            --duration) duration="$2"; shift 2 ;;
            --voice|--provider) voice_provider="$2"; shift 2 ;;
            --video) video_provider="$2"; shift 2 ;;
            --topics) topics_file="$2"; shift 2 ;;
            --count) count="$2"; shift 2 ;;
            --input) input_file="$2"; shift 2 ;;
            *) echo "[ERROR] Unknown option: $1"; usage; exit 1 ;;
        esac
    done

    case "$mode" in
        script)
            [[ -z "$topic" ]] && { echo "[ERROR] --topic required"; exit 1; }
            generate_script "$topic" "$style" "$duration"
            ;;
        voice)
            [[ -z "$script_file" ]] && { echo "[ERROR] --script required"; exit 1; }
            generate_voice "$script_file" "$voice_provider"
            ;;
        video)
            [[ -z "$image_file" || -z "$audio_file" ]] && { echo "[ERROR] --image and --audio required"; exit 1; }
            generate_talking_head "$image_file" "$audio_file" "$video_provider"
            ;;
        broll)
            [[ -z "$prompt" ]] && { echo "[ERROR] --prompt required"; exit 1; }
            generate_broll "$prompt" "$count"
            ;;
        edit)
            [[ -z "$input_file" ]] && { echo "[ERROR] --input required"; exit 1; }
            assemble_video "$input_file"
            ;;
        full)
            [[ -z "$topic" ]] && { echo "[ERROR] --topic required"; exit 1; }
            run_full_pipeline "$topic" "$style" "$voice_provider" "$video_provider"
            ;;
        batch)
            [[ -z "$topics_file" ]] && { echo "[ERROR] --topics required"; exit 1; }
            run_batch "$topics_file" "$count" "$voice_provider" "$video_provider"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
