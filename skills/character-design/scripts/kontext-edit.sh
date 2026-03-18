#!/bin/bash
# kontext-edit.sh — Edit images using fal.ai Flux Kontext Pro
# Usage: kontext-edit.sh --input <image> --prompt "<edit instruction>" --output <dir> [--guidance 3.5] [--safety 4]

set -euo pipefail

# --- Config ---
FAL_MODEL="fal-ai/flux-pro/kontext"
FAL_API="https://api.fal.ai"
DEFAULT_GUIDANCE=3.5
DEFAULT_SAFETY=4  # 1=strictest, 6=most permissive

# --- Load API key ---
load_key() {
    if [[ -n "${FAL_KEY:-}" ]]; then return; fi
    if [[ -n "${FAL_API_KEY:-}" ]]; then FAL_KEY="$FAL_API_KEY"; return; fi

    local key_files=(
        "$HOME/.openclaw/.env"
        "$HOME/.openclaw/secrets/fal.env"
    )
    for f in "${key_files[@]}"; do
        if [[ -f "$f" ]]; then
            local val
            val=$(grep -E '^FAL_API_KEY=' "$f" 2>/dev/null | head -1 | cut -d= -f2-)
            if [[ -n "$val" ]]; then
                FAL_KEY="$val"
                return
            fi
        fi
    done

    echo "ERROR: No fal.ai API key found. Set FAL_KEY or add FAL_API_KEY to ~/.openclaw/.env"
    exit 1
}

# --- Upload file to fal.ai storage ---
upload_file() {
    local file_path="$1"
    local mime_type="image/png"
    [[ "$file_path" == *.jpg ]] || [[ "$file_path" == *.jpeg ]] && mime_type="image/jpeg"

    local filename
    filename=$(basename "$file_path")

    # Use fal.ai REST upload endpoint
    local upload_url
    upload_url=$(curl -s -X POST "${FAL_API}/storage/upload/initiate" \
        -H "Authorization: Key ${FAL_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"file_name\": \"${filename}\", \"content_type\": \"${mime_type}\"}" 2>/dev/null)

    # Check if initiate endpoint works
    local upload_target
    upload_target=$(echo "$upload_url" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('upload_url',''))" 2>/dev/null || true)

    if [[ -n "$upload_target" ]]; then
        # Two-step upload: initiate then PUT
        local file_url
        file_url=$(echo "$upload_url" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('file_url',''))" 2>/dev/null)

        curl -s -X PUT "$upload_target" \
            -H "Content-Type: ${mime_type}" \
            --data-binary "@${file_path}" > /dev/null 2>&1

        echo "$file_url"
    else
        # Fallback: direct upload
        local response
        response=$(curl -s -X POST "${FAL_API}/storage/upload" \
            -H "Authorization: Key ${FAL_KEY}" \
            -H "Content-Type: ${mime_type}" \
            -H "X-Fal-File-Name: ${filename}" \
            --data-binary "@${file_path}" 2>/dev/null)

        # Try to extract URL from response
        local url
        url=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('url', d.get('file_url', d.get('access_url', ''))))" 2>/dev/null || true)

        if [[ -n "$url" ]]; then
            echo "$url"
        else
            # Last resort: base64 data URI
            local b64
            b64=$(base64 < "$file_path")
            echo "data:${mime_type};base64,${b64}"
        fi
    fi
}

# --- Submit Kontext edit job ---
submit_edit() {
    local image_url="$1"
    local prompt="$2"
    local guidance="${3:-$DEFAULT_GUIDANCE}"
    local safety="${4:-$DEFAULT_SAFETY}"

    local payload
    payload=$(python3 -c "
import json
print(json.dumps({
    'prompt': '''${prompt}''',
    'image_url': '${image_url}',
    'guidance_scale': float('${guidance}'),
    'num_images': 1,
    'output_format': 'png',
    'safety_tolerance': '${safety}'
}))
")

    # Submit and get request ID (async)
    local response
    response=$(curl -s -X POST "${FAL_API}/${FAL_MODEL}" \
        -H "Authorization: Key ${FAL_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>/dev/null)

    echo "$response"
}

# --- Poll for result ---
poll_result() {
    local request_id="$1"
    local max_wait=120
    local waited=0

    while [[ $waited -lt $max_wait ]]; do
        local status_resp
        status_resp=$(curl -s "${FAL_API}/${FAL_MODEL}/requests/${request_id}/status" \
            -H "Authorization: Key ${FAL_KEY}" 2>/dev/null)

        local status
        status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null || true)

        if [[ "$status" == "COMPLETED" ]]; then
            # Get result
            curl -s "${FAL_API}/${FAL_MODEL}/requests/${request_id}" \
                -H "Authorization: Key ${FAL_KEY}" 2>/dev/null
            return 0
        elif [[ "$status" == "FAILED" ]]; then
            echo "ERROR: Job failed: $status_resp" >&2
            return 1
        fi

        sleep 3
        waited=$((waited + 3))
    done

    echo "ERROR: Timeout after ${max_wait}s" >&2
    return 1
}

# --- Download result image ---
download_image() {
    local url="$1"
    local output="$2"
    curl -sL "$url" -o "$output"
}

# --- Main ---
main() {
    local input="" prompt="" output_dir="" guidance="$DEFAULT_GUIDANCE" safety="$DEFAULT_SAFETY"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --input|-i) input="$2"; shift 2 ;;
            --prompt|-p) prompt="$2"; shift 2 ;;
            --output|-o) output_dir="$2"; shift 2 ;;
            --guidance|-g) guidance="$2"; shift 2 ;;
            --safety|-s) safety="$2"; shift 2 ;;
            *) echo "Unknown arg: $1"; exit 1 ;;
        esac
    done

    if [[ -z "$input" ]] || [[ -z "$prompt" ]]; then
        echo "Usage: kontext-edit.sh --input <image> --prompt '<edit>' --output <dir>"
        exit 1
    fi

    [[ -z "$output_dir" ]] && output_dir=$(dirname "$input")
    mkdir -p "$output_dir"

    load_key

    local basename
    basename=$(basename "$input" | sed 's/\.[^.]*$//')

    echo "[1/3] Uploading $(basename "$input") to fal.ai..."
    local image_url
    image_url=$(upload_file "$input")

    if [[ -z "$image_url" ]]; then
        echo "ERROR: Upload failed"
        exit 1
    fi
    echo "  ✓ Uploaded: ${image_url:0:80}..."

    echo "[2/3] Submitting Kontext edit..."
    echo "  Prompt: ${prompt:0:100}..."

    local response
    response=$(submit_edit "$image_url" "$prompt" "$guidance" "$safety")

    # Check if it's a direct response (sync) or needs polling (async)
    local request_id
    request_id=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('request_id',''))" 2>/dev/null || true)

    if [[ -n "$request_id" ]]; then
        echo "  Async job: $request_id — polling..."
        response=$(poll_result "$request_id")
    fi

    # Extract image URL from response
    local result_url
    result_url=$(echo "$response" | python3 -c "
import sys, json
d = json.load(sys.stdin)
images = d.get('images', d.get('data', {}).get('images', []))
if images:
    print(images[0].get('url', ''))
else:
    print(d.get('image', {}).get('url', ''))
" 2>/dev/null || true)

    if [[ -z "$result_url" ]]; then
        echo "ERROR: No image in response"
        echo "Response: $response"
        exit 1
    fi

    echo "[3/3] Downloading result..."
    local output_file="${output_dir}/${basename}-kontext-edit.png"
    download_image "$result_url" "$output_file"

    echo "  ✓ Saved: $output_file"
    echo "$output_file"
}

main "$@"
