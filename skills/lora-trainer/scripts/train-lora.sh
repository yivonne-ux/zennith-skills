#!/usr/bin/env bash
# train-lora.sh — LoRA Training Pipeline for Zennith OS
# Supports FAL.ai (primary) and Replicate (fallback)
# FAL: fal-ai/flux-lora-fast-training (~$2, ~10-15 min)
# Replicate: ostris/flux-dev-lora-trainer (~$2, ~20 min)
#
# Usage:
#   train-lora.sh prepare  --input <dir> --output <zip>
#   train-lora.sh train    --zip <file> --model-name <name> --trigger <word> [options]
#   train-lora.sh status   --request-id <id>
#   train-lora.sh generate --prompt <text> [--lora-url <url>] [--strength 0.8]

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW="$HOME/.openclaw"
OUTPUT_DIR="${OPENCLAW}/workspace/data/lora-models"
LOG_FILE="${OPENCLAW}/logs/lora-trainer.log"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"

# Load API keys
for envfile in "$HOME/.env" "${OPENCLAW}/.env" "${OPENCLAW}/secrets/fal.env" "${OPENCLAW}/secrets/replicate.env"; do
  [[ -f "$envfile" ]] && source "$envfile" 2>/dev/null || true
done
FAL_KEY="${FAL_KEY:-}"
REPLICATE_TOKEN="${REPLICATE_API_TOKEN:-}"

mkdir -p "$OUTPUT_DIR" "$(dirname "$LOG_FILE")"

MODE="${1:-help}"
shift 2>/dev/null || true

# Parse args
INPUT_DIR=""
OUTPUT_FILE=""
ZIP_FILE=""
MODEL_NAME=""
TRIGGER=""
STEPS=1000
RANK=16
LEARNING_RATE="0.0004"
PROMPT=""
STRENGTH="0.8"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)     INPUT_DIR="$2"; shift 2 ;;
    --output|-o) OUTPUT_FILE="$2"; shift 2 ;;
    --zip)       ZIP_FILE="$2"; shift 2 ;;
    --model-name) MODEL_NAME="$2"; shift 2 ;;
    --trigger)   TRIGGER="$2"; shift 2 ;;
    --steps)     STEPS="$2"; shift 2 ;;
    --rank)      RANK="$2"; shift 2 ;;
    --lr)        LEARNING_RATE="$2"; shift 2 ;;
    --prompt)    PROMPT="$2"; shift 2 ;;
    --strength)  STRENGTH="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

log() { echo "[lora $(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }

case "$MODE" in
  prepare)
    [[ -z "$INPUT_DIR" ]] && { echo "ERROR: --input required (directory of images)"; exit 1; }
    [[ ! -d "$INPUT_DIR" ]] && { echo "ERROR: Input directory not found: $INPUT_DIR"; exit 1; }
    [[ -z "$OUTPUT_FILE" ]] && OUTPUT_FILE="${OUTPUT_DIR}/training-$(date +%Y%m%d-%H%M%S).zip"

    log "=== PREPARE IMAGES ==="
    log "Input: $INPUT_DIR"

    "$PYTHON3" - "$INPUT_DIR" "$OUTPUT_FILE" << 'PYEOF'
import sys, os, shutil, zipfile
from pathlib import Path

input_dir = Path(sys.argv[1])
output_zip = sys.argv[2]

# Find all images
IMAGE_EXTS = {'.jpg', '.jpeg', '.png', '.webp', '.avif', '.heic', '.bmp', '.tiff'}
images = [f for f in input_dir.rglob('*') if f.suffix.lower() in IMAGE_EXTS]

print(f"Found {len(images)} images in {input_dir}")

if len(images) < 30:
    print(f"WARNING: Only {len(images)} images. Recommend 80-120 for best results.")
elif len(images) > 200:
    print(f"WARNING: {len(images)} images is a lot. Consider curating to 80-120.")

# Try to import PIL for resizing
try:
    from PIL import Image
    has_pil = True
except ImportError:
    has_pil = False
    print("WARNING: PIL not available — images won't be resized. Install: pip3 install Pillow")

temp_dir = Path(output_zip).parent / "lora-prep-temp"
temp_dir.mkdir(parents=True, exist_ok=True)

processed = 0
skipped = 0

for img_path in images:
    try:
        out_name = f"img_{processed:04d}.jpg"
        out_path = temp_dir / out_name

        if has_pil:
            img = Image.open(img_path).convert('RGB')
            # Resize to max 2048px
            max_dim = max(img.size)
            if max_dim > 2048:
                scale = 2048 / max_dim
                new_size = (int(img.width * scale), int(img.height * scale))
                img = img.resize(new_size, Image.LANCZOS)
            img.save(out_path, 'JPEG', quality=95)
        else:
            shutil.copy2(img_path, out_path)

        processed += 1
    except Exception as e:
        print(f"  Skip {img_path.name}: {e}")
        skipped += 1

# Create ZIP
print(f"Creating ZIP ({processed} images)...")
os.makedirs(os.path.dirname(output_zip), exist_ok=True)
with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zf:
    for f in sorted(temp_dir.glob('*.jpg')):
        zf.write(f, f.name)

# Cleanup
shutil.rmtree(temp_dir)

zip_size = os.path.getsize(output_zip) / (1024 * 1024)
print(f"\nPrepared: {output_zip} ({zip_size:.1f}MB)")
print(f"  Images: {processed} processed, {skipped} skipped")
print(f"\nNext: train-lora.sh train --zip {output_zip} --model-name <name> --trigger <word>")
PYEOF
    ;;

  train)
    [[ -z "$ZIP_FILE" ]] && { echo "ERROR: --zip required"; exit 1; }
    [[ -z "$MODEL_NAME" ]] && { echo "ERROR: --model-name required"; exit 1; }
    [[ -z "$TRIGGER" ]] && { echo "ERROR: --trigger required (unique word like MYSTYLE)"; exit 1; }

    # FAL is primary, Replicate is fallback
    if [[ -n "$FAL_KEY" ]]; then
      log "=== TRAIN LORA (FAL) ==="
      log "Model: $MODEL_NAME | Trigger: $TRIGGER | Steps: $STEPS | Rank: $RANK"

      "$PYTHON3" - "$ZIP_FILE" "$MODEL_NAME" "$TRIGGER" "$STEPS" "$RANK" "$FAL_KEY" "$OUTPUT_DIR" << 'PYEOF'
import sys, os, json, time, base64
from datetime import datetime

zip_file = sys.argv[1]
model_name = sys.argv[2]
trigger = sys.argv[3]
steps = int(sys.argv[4])
rank = int(sys.argv[5])
fal_key = sys.argv[6]
output_dir = sys.argv[7]

try:
    import requests
except ImportError:
    print("ERROR: pip3 install requests"); sys.exit(1)

headers = {"Authorization": f"Key {fal_key}", "Content-Type": "application/json"}

# Upload images as data URL (FAL accepts zip via URL or base64)
zip_size = os.path.getsize(zip_file) / (1024 * 1024)
print(f"Training LoRA via FAL.ai")
print(f"  ZIP: {zip_file} ({zip_size:.1f}MB)")
print(f"  Trigger: {trigger} | Steps: {steps} | Rank: {rank}")

# First upload to FAL storage
print(f"\nUploading to FAL storage...")
upload_resp = requests.post(
    "https://fal.run/fal-ai/file-upload",
    headers={"Authorization": f"Key {fal_key}"},
    files={"file": (os.path.basename(zip_file), open(zip_file, 'rb'), "application/zip")}
)
if upload_resp.status_code in (200, 201):
    file_url = upload_resp.json().get("url", "")
    print(f"  Uploaded: {file_url[:80]}...")
else:
    # Fallback: use base64 data URI
    print(f"  Direct upload failed ({upload_resp.status_code}), using data URI...")
    with open(zip_file, 'rb') as f:
        b64 = base64.b64encode(f.read()).decode()
    file_url = f"data:application/zip;base64,{b64}"
    print(f"  Encoded as data URI ({len(b64) // 1024}KB)")

# Submit training job
print(f"\nSubmitting training job...")
train_resp = requests.post(
    "https://queue.fal.run/fal-ai/flux-lora-fast-training",
    headers=headers,
    json={
        "images_data_url": file_url,
        "trigger_word": trigger,
        "steps": steps,
        "rank": rank,
        "learning_rate": 0.0004,
        "is_style": True if rank <= 16 else False,
        "create_masks": False
    }
)

if train_resp.status_code not in (200, 201):
    print(f"ERROR: {train_resp.status_code} {train_resp.text[:200]}")
    sys.exit(1)

result = train_resp.json()
request_id = result.get("request_id", "")
status_url = result.get("status_url", "")

print(f"\n  Training queued!")
print(f"  Request ID: {request_id}")
print(f"  Status URL: {status_url}")
print(f"  Estimated: 10-15 minutes, ~$2")
print(f"\n  Check: train-lora.sh status --request-id {request_id}")

# Save info
info = {
    "provider": "fal",
    "model_name": model_name,
    "request_id": request_id,
    "status_url": status_url,
    "trigger": trigger,
    "steps": steps,
    "rank": rank,
    "started": datetime.now().isoformat() + "Z"
}
info_file = os.path.join(output_dir, f"{model_name}-training.json")
os.makedirs(output_dir, exist_ok=True)
with open(info_file, 'w') as f:
    json.dump(info, f, indent=2)
print(f"  Info: {info_file}")
PYEOF

    elif [[ -n "$REPLICATE_TOKEN" ]]; then
      log "=== TRAIN LORA (Replicate fallback) ==="
      log "Model: $MODEL_NAME | Trigger: $TRIGGER | Steps: $STEPS | Rank: $RANK"

      "$PYTHON3" - "$ZIP_FILE" "$MODEL_NAME" "$TRIGGER" "$STEPS" "$RANK" "$LEARNING_RATE" "$REPLICATE_TOKEN" "$OUTPUT_DIR" << 'PYEOF'
import sys, os, json, subprocess, time
from datetime import datetime

zip_file = sys.argv[1]
model_name = sys.argv[2]
trigger = sys.argv[3]
steps = int(sys.argv[4])
rank = int(sys.argv[5])
lr = sys.argv[6]
token = sys.argv[7]
output_dir = sys.argv[8]

# Check if replicate CLI or API is available
try:
    import requests
    has_requests = True
except ImportError:
    has_requests = False

if not has_requests:
    print("ERROR: 'requests' package required. Run: pip3 install requests")
    sys.exit(1)

headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
base_url = "https://api.replicate.com/v1"

# Step 1: Check if model exists, create if not
print(f"Checking model {model_name}...")
# Get username
me = requests.get(f"{base_url}/account", headers={"Authorization": f"Bearer {token}"})
if me.status_code != 200:
    print(f"ERROR: Invalid API token (status {me.status_code})")
    sys.exit(1)
username = me.json().get("username")
print(f"  Replicate user: {username}")

model_full = f"{username}/{model_name}"
check = requests.get(f"{base_url}/models/{model_full}", headers={"Authorization": f"Bearer {token}"})
if check.status_code == 404:
    print(f"  Creating model {model_full}...")
    create = requests.post(f"{base_url}/models", headers=headers, json={
        "owner": username,
        "name": model_name,
        "visibility": "private",
        "hardware": "gpu-a40-large"
    })
    if create.status_code not in (200, 201):
        print(f"ERROR creating model: {create.text}")
        sys.exit(1)
    print(f"  Model created: {model_full}")
else:
    print(f"  Model exists: {model_full}")

# Step 2: Upload ZIP to Replicate Files API
print(f"\nUploading {zip_file}...")
zip_size = os.path.getsize(zip_file) / (1024 * 1024)
print(f"  Size: {zip_size:.1f}MB")

upload_resp = requests.post(
    f"{base_url}/files",
    headers={"Authorization": f"Bearer {token}"},
    files={"content": (os.path.basename(zip_file), open(zip_file, 'rb'), "application/zip")}
)
if upload_resp.status_code not in (200, 201):
    print(f"ERROR uploading: {upload_resp.text}")
    sys.exit(1)

file_url = upload_resp.json().get("urls", {}).get("get")
print(f"  Uploaded: {file_url}")

# Step 3: Launch training
print(f"\nLaunching Flux LoRA training...")
print(f"  Trigger: {trigger} | Steps: {steps} | Rank: {rank} | LR: {lr}")

training_resp = requests.post(
    f"{base_url}/models/ostris/flux-dev-lora-trainer/versions/d995297071a44dcb72244e6c19462111649ec86a9646c32df56daa7f14801944/trainings",
    headers=headers,
    json={
        "destination": model_full,
        "input": {
            "input_images": file_url,
            "trigger_word": trigger,
            "steps": steps,
            "lora_rank": rank,
            "learning_rate": float(lr),
            "resolution": "1024",
            "autocaption": True,
            "batch_size": 1,
            "wandb_project": "",
        }
    }
)

if training_resp.status_code not in (200, 201):
    print(f"ERROR launching training: {training_resp.text}")
    sys.exit(1)

training = training_resp.json()
training_id = training.get("id")
training_url = training.get("urls", {}).get("get")
status = training.get("status")

print(f"\n  Training launched!")
print(f"  ID: {training_id}")
print(f"  Status: {status}")
print(f"  Track: https://replicate.com/p/{training_id}")
print(f"\n  Estimated time: 15-25 minutes")
print(f"  Estimated cost: ~$2-3")
print(f"\n  Check status: train-lora.sh status --model-name {model_name}")
print(f"  Generate: train-lora.sh generate --model-name {model_name} --prompt \"{trigger}, your description\"")

# Save training info
info = {
    "model": model_full,
    "training_id": training_id,
    "trigger": trigger,
    "steps": steps,
    "rank": rank,
    "started": datetime.utcnow().isoformat() + "Z",
    "status": status
}
info_file = os.path.join(output_dir, f"{model_name}-training.json")
with open(info_file, 'w') as f:
    json.dump(info, f, indent=2)
print(f"  Info saved: {info_file}")
PYEOF
    ;;

  status)
    [[ -z "$MODEL_NAME" ]] && { echo "ERROR: --model-name required"; exit 1; }

    INFO_FILE="${OUTPUT_DIR}/${MODEL_NAME}-training.json"
    if [[ ! -f "$INFO_FILE" ]]; then
      echo "ERROR: No training info found for $MODEL_NAME"
      exit 1
    fi

    "$PYTHON3" - "$INFO_FILE" "$FAL_KEY" "$REPLICATE_TOKEN" << 'PYEOF'
import sys, json, requests

with open(sys.argv[1]) as f:
    info = json.load(f)

fal_key = sys.argv[2]
replicate_token = sys.argv[3]
provider = info.get("provider", "replicate")

print(f"Model: {info.get('model_name', info.get('model', '?'))}")
print(f"Trigger: {info['trigger']}")
print(f"Provider: {provider}")

if provider == "fal":
    status_url = info.get("status_url", "")
    if not status_url:
        request_id = info.get("request_id", "")
        status_url = f"https://queue.fal.run/fal-ai/flux-lora-fast-training/requests/{request_id}/status"
    resp = requests.get(status_url, headers={"Authorization": f"Key {fal_key}"})
    if resp.status_code == 200:
        data = resp.json()
        status = data.get("status", "UNKNOWN")
        print(f"Status: {status}")
        if status == "COMPLETED":
            # Get the result
            result_url = status_url.replace("/status", "")
            result = requests.get(result_url, headers={"Authorization": f"Key {fal_key}"}).json()
            lora_url = result.get("diffusers_lora_file", {}).get("url", "")
            if lora_url:
                print(f"  LoRA weights: {lora_url}")
                print(f"  Generate: train-lora.sh generate --prompt \"{info['trigger']}, description\" --lora-url \"{lora_url}\"")
                # Save lora URL
                info["lora_url"] = lora_url
                info["status"] = "completed"
                with open(sys.argv[1], 'w') as f:
                    json.dump(info, f, indent=2)
        elif status == "FAILED":
            print(f"  Error: {data.get('error', 'unknown')}")
        else:
            pos = data.get("queue_position", "?")
            print(f"  Queue position: {pos}")
    else:
        print(f"ERROR: {resp.status_code}")
else:
    # Replicate fallback
    training_id = info.get("training_id", "")
    resp = requests.get(
        f"https://api.replicate.com/v1/trainings/{training_id}",
        headers={"Authorization": f"Bearer {replicate_token}"}
    )
    if resp.status_code == 200:
        data = resp.json()
        status = data.get("status")
        print(f"Status: {status}")
        if status == "succeeded":
            print(f"  Training complete!")
        elif status == "failed":
            print(f"  Error: {data.get('error', 'unknown')}")
    else:
    print(f"ERROR: {resp.status_code} {resp.text}")
PYEOF
    ;;

  generate)
    [[ -z "$MODEL_NAME" ]] && { echo "ERROR: --model-name required"; exit 1; }
    [[ -z "$PROMPT" ]] && { echo "ERROR: --prompt required (include trigger word)"; exit 1; }
    [[ -z "$REPLICATE_TOKEN" ]] && { echo "ERROR: REPLICATE_API_TOKEN not set"; exit 1; }

    log "=== GENERATE WITH LORA ==="
    log "Model: $MODEL_NAME | Strength: $STRENGTH"

    "$PYTHON3" - "$MODEL_NAME" "$PROMPT" "$STRENGTH" "$REPLICATE_TOKEN" "$OUTPUT_DIR" << 'PYEOF'
import sys, json, requests, time, os
from datetime import datetime

model_name = sys.argv[1]
prompt = sys.argv[2]
strength = float(sys.argv[3])
token = sys.argv[4]
output_dir = sys.argv[5]

headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

# Get username
me = requests.get("https://api.replicate.com/v1/account", headers={"Authorization": f"Bearer {token}"})
username = me.json().get("username")
model_full = f"{username}/{model_name}"

print(f"Generating with {model_full} (strength={strength})...")
print(f"Prompt: {prompt[:100]}...")

# Run prediction
resp = requests.post(
    f"https://api.replicate.com/v1/models/{model_full}/predictions",
    headers=headers,
    json={
        "input": {
            "prompt": prompt,
            "lora_scale": strength,
            "num_outputs": 1,
            "output_format": "png",
            "guidance_scale": 3.5,
            "num_inference_steps": 28,
        }
    }
)

if resp.status_code not in (200, 201):
    print(f"ERROR: {resp.text}")
    sys.exit(1)

pred = resp.json()
pred_id = pred.get("id")
print(f"Prediction: {pred_id}")

# Poll for completion
for i in range(60):
    check = requests.get(
        f"https://api.replicate.com/v1/predictions/{pred_id}",
        headers={"Authorization": f"Bearer {token}"}
    )
    data = check.json()
    status = data.get("status")
    if status == "succeeded":
        outputs = data.get("output", [])
        if outputs:
            # Download image
            img_url = outputs[0] if isinstance(outputs, list) else outputs
            img_resp = requests.get(img_url)
            out_path = os.path.join(output_dir, f"{model_name}-gen-{datetime.now().strftime('%H%M%S')}.png")
            with open(out_path, 'wb') as f:
                f.write(img_resp.content)
            print(f"\nGenerated: {out_path} ({len(img_resp.content) / 1024:.0f}KB)")
        break
    elif status == "failed":
        print(f"ERROR: {data.get('error', 'unknown')}")
        break
    time.sleep(2)
PYEOF
    ;;

  help|*)
    cat << 'HELPEOF'
LoRA Trainer — Brand Visual DNA Lock

Usage:
  train-lora.sh prepare   --input <dir> --output <zip>
  train-lora.sh train     --zip <file> --model-name <name> --trigger <word>
  train-lora.sh status    --model-name <name>
  train-lora.sh generate  --model-name <name> --prompt <text>

Training presets:
  Style LoRA:   80-120 images, rank=16, steps=1000, ~$2
  Face LoRA:    50-80 images, rank=32, steps=800, ~$1.50
  Product LoRA: 30-50 images, rank=16, steps=600, ~$1

Requirements: REPLICATE_API_TOKEN in environment or .env
HELPEOF
    ;;
esac
