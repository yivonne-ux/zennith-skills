#!/usr/bin/env bash
# image-seed.sh — Image seed bank CLI for GAIA Creative Studio
# Usage: bash image-seed.sh <command> [options]
#
# Commands:
#   add      - Add new image seed to index
#   query    - Query seeds by criteria
#   promote  - Mark seed as winner
#   export   - Export seed to Google Drive
#   list     - List all seeds
#   remove   - Remove seed (soft delete)
#
# Index file: ~/.openclaw/workspace/rag/image-seed-bank.jsonl

set -uo pipefail

INDEX_FILE="$HOME/.openclaw/workspace/rag/image-seed-bank.jsonl"
MAX_SEEDS_PER_BRAND=1000
MAX_FILE_SIZE=$((100 * 1024 * 1024))  # 100MB

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HELPER FUNCTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

init_index() {
  local dir
  dir=$(dirname "$INDEX_FILE")
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    log_info "Created directory: $dir"
  fi

  if [ ! -f "$INDEX_FILE" ]; then
    touch "$INDEX_FILE"
    log_info "Created index file: $INDEX_FILE"
  fi

  # Check file size
  local size
  size=$(stat -f%z "$INDEX_FILE" 2>/dev/null || stat -c%s "$INDEX_FILE" 2>/dev/null || echo 0)
  if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
    log_warn "Index file exceeds 100MB ($size bytes). Run 'compact' command."
  fi
}

generate_id() {
  local prefix="${1:-img}"
  local timestamp
  timestamp=$(date +%s%N | cut -c1-13)
  local random
  random=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')
  echo "${prefix}-${timestamp: -6}-${random:0:4}"
}

count_seeds_by_brand() {
  local brand="$1"
  local c
  c=$(grep -c "\"brand\"" "$INDEX_FILE" 2>/dev/null | tr -d ' ' || true)
  # Use python for accurate JSON brand counting
  python3 -c "
import json, sys
count = 0
try:
    with open('$INDEX_FILE') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                if json.loads(line).get('brand') == '$brand': count += 1
            except: pass
except: pass
print(count)
"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMMAND: ADD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_add() {
  local type brand campaign file_path tags colors mood subject prompt drive_url status created_by

  type=""; brand=""; campaign=""; file_path=""; tags=""; colors=""; mood=""; subject=""; prompt=""; drive_url=""; status="draft"; created_by="unknown"

  while [ $# -gt 0 ]; do
    case "$1" in
      --type) type="$2"; shift 2;;
      --brand) brand="$2"; shift 2;;
      --campaign) campaign="$2"; shift 2;;
      --file-path) file_path="$2"; shift 2;;
      --tags) tags="$2"; shift 2;;
      --colors) colors="$2"; shift 2;;
      --mood) mood="$2"; shift 2;;
      --subject) subject="$2"; shift 2;;
      --prompt) prompt="$2"; shift 2;;
      --drive-url) drive_url="$2"; shift 2;;
      --status) status="$2"; shift 2;;
      --created-by) created_by="$2"; shift 2;;
      --id) shift 2;;  # Allow override but not used
      *) shift;;
    esac
  done

  # Validate required fields (brand and tags are mandatory — force-tag guardrail)
  if [ -z "$brand" ]; then
    log_error "--brand is required. Usage: bash image-seed.sh add --brand <brand> --tags <tags> --type <type> --campaign <id> --file-path <path>"
    return 1
  fi

  if [ -z "$tags" ]; then
    log_error "--tags is required. Usage: bash image-seed.sh add --brand <brand> --tags <tags> --type <type> --campaign <id> --file-path <path>"
    return 1
  fi

  if [ -z "$type" ] || [ -z "$campaign" ] || [ -z "$file_path" ]; then
    log_error "Required fields: --type, --brand, --campaign, --file-path, --tags"
    log_info "Usage: bash image-seed.sh add --type <key_visual|logo|model> --brand <brand> --campaign <id> --file-path <path> --tags <tags> [options]"
    return 1
  fi

  # Check brand limit
  local count
  count=$(count_seeds_by_brand "$brand")
  if [ "$count" -ge "$MAX_SEEDS_PER_BRAND" ]; then
    log_error "Brand '$brand' has reached max seeds ($MAX_SEEDS_PER_BRAND)"
    return 1
  fi

  # Generate ID
  local id
  id=$(generate_id "img")

  # Build JSON entry
  local entry
  entry=$(python3 - "$id" "$type" "$brand" "$campaign" "$file_path" "$tags" "$colors" "$mood" "$subject" "$prompt" "$drive_url" "$status" "$created_by" << 'PYEOF'
import json, sys, time, datetime
id_val, type_val, brand, campaign, file_path, tags_str, colors_str, mood, subject, prompt, drive_url, status, created_by = sys.argv[1:]

# Parse tags
tags = [t.strip() for t in tags_str.split(",") if t.strip()] if tags_str else []

# Parse colors
colors = [c.strip() for c in colors_str.split(",") if c.strip()] if colors_str else []

# Build entry
entry = {
    "id": id_val,
    "ts": int(time.time() * 1000),
    "type": type_val,
    "brand": brand,
    "campaign": campaign,
    "file_path": file_path,
    "tags": tags,
    "colors": colors,
    "mood": mood,
    "subject": subject,
    "nanobanana_prompt": prompt,
    "generation_params": {},
    "parent_seed": None,
    "generation": 1,
    "performance": {"ctr": None, "roas": None, "impressions": None},
    "status": status,
    "created_by": created_by,
    "created_at": datetime.datetime.now().strftime("%Y-%m-%d")
}

if drive_url:
    entry["drive_url"] = drive_url

print(json.dumps(entry, ensure_ascii=False))
PYEOF
  )

  # Append to index
  echo "$entry" >> "$INDEX_FILE"
  log_success "Added seed: $id"
  echo "$entry" | python3 -c "import sys, json; d=json.load(sys.stdin); print(f'  ID: {d[\"id\"]}'); print(f'  Type: {d[\"type\"]}'); print(f'  Brand: {d[\"brand\"]}'); print(f'  Campaign: {d[\"campaign\"]}'); print(f'  Status: {d[\"status\"]}')"

  # Bridge to library.db (bidirectional sync)
  local db_path="$HOME/.openclaw/workspace/apps/gaia-creative-studio/server/data/library.db"
  if [ -f "$db_path" ]; then
    python3 - "$db_path" "$entry" << 'PYEOF'
import sqlite3, json, sys, os

db_path = sys.argv[1]
entry = json.loads(sys.argv[2])

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Check if asset already exists
    cursor.execute("SELECT id FROM assets WHERE id = ?", (entry.get("id", ""),))
    if cursor.fetchone():
        conn.close()
        sys.exit(0)

    tags_json = json.dumps(entry.get("tags", []))
    file_path = entry.get("file_path", "")
    filename = os.path.basename(file_path) if file_path else ""

    cursor.execute("""
        INSERT OR IGNORE INTO assets
        (id, filename, filepath, brand, format, content_type, mood, status, ai_tags, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        entry.get("id", ""),
        filename,
        file_path,
        entry.get("brand", ""),
        "image",
        entry.get("type", "key_visual"),
        entry.get("mood", ""),
        entry.get("status", "draft"),
        tags_json,
        entry.get("created_at", ""),
        entry.get("created_at", ""),
    ))
    conn.commit()
    conn.close()
    print("  Bridged to library.db")
except Exception as e:
    print(f"  [WARN] library.db bridge failed: {e}", file=sys.stderr)
PYEOF
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMMAND: QUERY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_query() {
  local brand="" tag="" status="" limit=20

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand) brand="$2"; shift 2;;
      --tag) tag="$2"; shift 2;;
      --status) status="$2"; shift 2;;
      --limit) limit="$2"; shift 2;;
      *) shift;;
    esac
  done

  # Read index and filter
  local results
  results=$(python3 - "$INDEX_FILE" "$brand" "$tag" "$status" "$limit" << 'PYEOF'
import json, sys

index_file = sys.argv[1]
brand = sys.argv[2]
tag = sys.argv[3]
status = sys.argv[4]
limit = int(sys.argv[5])

results = []

try:
    with open(index_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except:
                continue

            # Filter by brand
            if brand and entry.get("brand") != brand:
                continue

            # Filter by tag
            if tag:
                entry_tags = entry.get("tags", [])
                if tag not in entry_tags:
                    continue

            # Filter by status
            if status and entry.get("status") != status:
                continue

            results.append(entry)
except Exception as e:
    print(f"Error reading index: {e}", file=sys.stderr)
    sys.exit(1)

# Sort by timestamp (newest first)
results.sort(key=lambda x: x.get("ts", 0), reverse=True)

# Limit results
results = results[:limit]

for entry in results:
    print(json.dumps(entry, ensure_ascii=False))
PYEOF
  )

  if [ -z "$results" ]; then
    log_info "No seeds found matching criteria"
    return 0
  fi

  # Display results
  echo "$results" | while read -r line; do
    echo "$line" | python3 -c '
import json, sys
d = json.load(sys.stdin)
print(f"{d[\"id\"]:12} | {d[\"brand\"]:12} | {d[\"campaign\"]:12} | {d[\"type\"]:14} | {d[\"status\"]:10}")
'
  done

  echo ""
  echo "Total: $(echo "$results" | wc -l) results"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMMAND: PROMOTE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_promote() {
  local id=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --id) id="$2"; shift 2;;
      *) shift;;
    esac
  done

  if [ -z "$id" ]; then
    log_error "Required: --id <seed_id>"
    return 1
  fi

  # Find and update seed
  python3 - "$INDEX_FILE" "$id" << 'PYEOF'
import json, sys

index_file = sys.argv[1]
target_id = sys.argv[2]

updated = False
lines = []

try:
    with open(index_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                if entry.get("id") == target_id:
                    entry["status"] = "winner"
                    updated = True
            except:
                pass
            lines.append(json.dumps(entry, ensure_ascii=False))
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)

if not updated:
    print(f"Seed not found: {target_id}", file=sys.stderr)
    sys.exit(1)

with open(index_file, "w") as f:
    for line in lines:
        f.write(line + "\n")

print(f"Promoted {target_id} to winner")
PYEOF

  log_success "Seed promoted to winner: $id"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMMAND: EXPORT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_export() {
  local id="" drive_path=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --id) id="$2"; shift 2;;
      --drive-path) drive_path="$2"; shift 2;;
      *) shift;;
    esac
  done

  if [ -z "$id" ]; then
    log_error "Required: --id <seed_id>"
    return 1
  fi

  # Find seed and get file path
  local file_path
  file_path=$(python3 - "$INDEX_FILE" "$id" << 'PYEOF'
import json, sys

index_file = sys.argv[1]
target_id = sys.argv[2]

try:
    with open(index_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                if entry.get("id") == target_id:
                    print(entry.get("file_path", ""))
                    sys.exit(0)
            except:
                pass
except:
    pass

sys.exit(1)
PYEOF
  )

  if [ -z "$file_path" ]; then
    log_error "Seed not found: $id"
    return 1
  fi

  log_info "Exporting: $file_path"
  log_info "To Drive: $drive_path"

  # In real implementation, this would upload to Google Drive
  # For now, just mark it as exported
  python3 - "$INDEX_FILE" "$id" << 'PYEOF'
import json, sys

index_file = sys.argv[1]
target_id = sys.argv[2]

updated = False
lines = []

try:
    with open(index_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                if entry.get("id") == target_id:
                    entry["exported_at"] = __import__('datetime').datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
                    updated = True
            except:
                pass
            lines.append(json.dumps(entry, ensure_ascii=False))
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)

if not updated:
    print(f"Seed not found: {target_id}", file=sys.stderr)
    sys.exit(1)

with open(index_file, "w") as f:
    for line in lines:
        f.write(line + "\n")

print(f"Exported {target_id}")
PYEOF

  log_success "Exported seed: $id"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMMAND: LIST
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_list() {
  local limit=50

  while [ $# -gt 0 ]; do
    case "$1" in
      --limit) limit="$2"; shift 2;;
      *) shift;;
    esac
  done

  python3 - "$INDEX_FILE" "$limit" << 'PYEOF'
import json, sys

index_file = sys.argv[1]
limit = int(sys.argv[2])
try:
    with open(index_file) as f:
        lines = f.readlines()
except FileNotFoundError:
    print("Index file not found. Run 'add' to create entries.")
    sys.exit(0)

# Parse entries
entries = []
for line in lines:
    line = line.strip()
    if not line:
        continue
    try:
        entries.append(json.loads(line))
    except:
        pass

# Sort by timestamp (newest first)
entries.sort(key=lambda x: x.get("ts", 0), reverse=True)
entries = entries[:limit]

# Display header
print(f"{'ID':12} | {'Brand':12} | {'Campaign':12} | {'Type':14} | {'Status':10} | {'Created'}")
print("-" * 85)

# Display entries
for e in entries:
    created = e.get("created_at", "-")
    print(f"{e['id']:12} | {e['brand']:12} | {e['campaign']:12} | {e['type']:14} | {e['status']:10} | {created}")

print(f"\nTotal: {len(entries)} entries")
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMMAND: DIGEST (Style Digest — analyze images via Gemini Vision)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_digest() {
  local images="" name="" brand="" tags=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --images) images="$2"; shift 2;;
      --name) name="$2"; shift 2;;
      --brand) brand="$2"; shift 2;;
      --tags) tags="$2"; shift 2;;
      *) shift;;
    esac
  done

  # Validate required fields
  if [ -z "$images" ]; then
    log_error "--images is required. Usage: bash image-seed.sh digest --images \"ref1.jpg,ref2.jpg\" --name \"my style\" --brand mirra [--tags \"instagram,lifestyle\"]"
    return 1
  fi
  if [ -z "$name" ]; then
    log_error "--name is required."
    return 1
  fi
  if [ -z "$brand" ]; then
    log_error "--brand is required."
    return 1
  fi

  # Load Gemini API key from .env
  local GEMINI_API_KEY
  GEMINI_API_KEY=$(python3 -c "
import os
for line in open(os.path.expanduser('~/.openclaw/.env')):
    if line.startswith('GEMINI_API_KEY='):
        print(line.split('=',1)[1].strip().strip('\"'))
        break
" 2>/dev/null)

  if [ -z "${GEMINI_API_KEY:-}" ]; then
    # Try secrets file
    if [ -f "$HOME/.openclaw/secrets/gemini.env" ]; then
      GEMINI_API_KEY=$(grep '^GEMINI_API_KEY=' "$HOME/.openclaw/secrets/gemini.env" | head -1 | cut -d= -f2- | tr -d '"')
    fi
  fi

  if [ -z "${GEMINI_API_KEY:-}" ]; then
    log_error "GEMINI_API_KEY not found in ~/.openclaw/.env or secrets"
    return 1
  fi

  export GEMINI_API_KEY

  log_info "Analyzing images via Gemini Vision..."

  # Validate images exist
  local IFS_SAVE="$IFS"
  IFS=','
  for img in $images; do
    IFS="$IFS_SAVE"
    local trimmed
    trimmed=$(echo "$img" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ ! -f "$trimmed" ]; then
      log_error "Image not found: $trimmed"
      return 1
    fi
  done
  IFS="$IFS_SAVE"

  # Call Gemini Vision via python3 (handles base64, JSON, HTTP)
  # Write python script to temp file to avoid backtick issues in bash 3.2 heredocs
  local py_script
  py_script=$(mktemp /tmp/digest-gemini.XXXXXX.py)
  cat > "$py_script" << 'PYEOF'
import base64, json, urllib.request, sys, os

images_str = sys.argv[1]
api_key = sys.argv[2]
images = [i.strip() for i in images_str.split(",") if i.strip()]

parts = []
for img_path in images:
    with open(img_path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode()
    ext = img_path.rsplit(".", 1)[-1].lower()
    mime = {"jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png", "webp": "image/webp"}.get(ext, "image/jpeg")
    parts.append({"inlineData": {"mimeType": mime, "data": b64}})

parts.append({"text": "Analyze these reference images as a style digest. Return ONLY valid JSON:\n{\n  \"colors\": [\"#hex1\", \"#hex2\", \"#hex3\", \"#hex4\", \"#hex5\"],\n  \"mood\": \"descriptive mood phrase\",\n  \"lighting\": \"lighting description\",\n  \"composition\": \"composition description\",\n  \"style_prompt\": \"A detailed style prompt that could recreate this visual style\"\n}"})

req = urllib.request.Request(
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=%s" % api_key,
    data=json.dumps({"contents": [{"parts": parts}]}).encode(),
    headers={"Content-Type": "application/json"}
)
resp = urllib.request.urlopen(req, timeout=120)
result = json.loads(resp.read())
text = result["candidates"][0]["content"]["parts"][0]["text"]
# Clean markdown fences if present
text = text.strip()
fence = chr(96) * 3
if text.startswith(fence):
    text = text.split("\n", 1)[1]
if text.endswith(fence):
    text = text.rsplit(fence, 1)[0]
print(text.strip())
PYEOF

  local analysis
  analysis=$(python3 "$py_script" "$images" "$GEMINI_API_KEY" 2>&1)
  rm -f "$py_script"

  if [ -z "$analysis" ]; then
    log_error "Gemini Vision returned empty analysis"
    return 1
  fi

  # Generate ID and save
  local seed_id="ss-$(date +%s)"
  local ts_epoch
  ts_epoch=$(date +%s)
  local created_date
  created_date=$(date '+%Y-%m-%d')

  # Parse analysis and save to JSONL + library.db
  python3 - "$INDEX_FILE" "$seed_id" "$name" "$brand" "$tags" "$images" "$analysis" "$ts_epoch" "$created_date" << 'PYEOF'
import json, sys, os, sqlite3

index_file = sys.argv[1]
seed_id = sys.argv[2]
name = sys.argv[3]
brand = sys.argv[4]
tags_str = sys.argv[5]
images_str = sys.argv[6]
analysis_json = sys.argv[7]
ts_epoch = int(sys.argv[8])
created_date = sys.argv[9]

# Parse analysis
try:
    analysis = json.loads(analysis_json)
except:
    print("ERROR: Failed to parse Gemini analysis as JSON", file=sys.stderr)
    print("Raw analysis: " + analysis_json[:500], file=sys.stderr)
    sys.exit(1)

# Parse tags and images
tags = [t.strip() for t in tags_str.split(",") if t.strip()] if tags_str else []
source_images = [i.strip() for i in images_str.split(",") if i.strip()]

# Build JSONL entry
entry = {
    "id": seed_id,
    "ts": ts_epoch * 1000,
    "type": "style_seed",
    "name": name,
    "brand": brand,
    "colors": analysis.get("colors", []),
    "mood": analysis.get("mood", ""),
    "lighting": analysis.get("lighting", ""),
    "composition": analysis.get("composition", ""),
    "style_prompt": analysis.get("style_prompt", ""),
    "source_images": source_images,
    "tags": tags,
    "status": "active",
    "created_by": "cli",
    "created_at": created_date,
}

# Append to JSONL
os.makedirs(os.path.dirname(index_file), exist_ok=True)
with open(index_file, "a") as f:
    f.write(json.dumps(entry, ensure_ascii=False) + "\n")

# Bridge to library.db style_seeds table
db_path = os.path.expanduser("~/.openclaw/workspace/apps/gaia-creative-studio/server/data/library.db")
if os.path.exists(db_path):
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        # Ensure table exists
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS style_seeds (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                brand TEXT,
                colors TEXT,
                mood TEXT,
                lighting TEXT,
                composition TEXT,
                style_prompt TEXT,
                source_images TEXT,
                tags TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        now = created_date + "T00:00:00.000Z"
        cursor.execute("""
            INSERT OR REPLACE INTO style_seeds
            (id, name, brand, colors, mood, lighting, composition, style_prompt, source_images, tags, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            seed_id, name, brand,
            json.dumps(analysis.get("colors", [])),
            analysis.get("mood", ""),
            analysis.get("lighting", ""),
            analysis.get("composition", ""),
            analysis.get("style_prompt", ""),
            json.dumps(source_images),
            json.dumps(tags),
            now, now
        ))
        conn.commit()
        conn.close()
        print("  Bridged to library.db style_seeds table")
    except Exception as e:
        print("  [WARN] library.db bridge failed: %s" % e, file=sys.stderr)

# Print results
print("ID: %s" % seed_id)
print("Name: %s" % name)
print("Brand: %s" % brand)
print("Colors: %s" % ", ".join(analysis.get("colors", [])))
print("Mood: %s" % analysis.get("mood", ""))
print("Lighting: %s" % analysis.get("lighting", ""))
print("Composition: %s" % analysis.get("composition", ""))
print("Style Prompt: %s" % analysis.get("style_prompt", "")[:200])
PYEOF

  if [ $? -eq 0 ]; then
    log_success "Style seed created: $seed_id"
  else
    log_error "Failed to save style seed"
    return 1
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMMAND: QUERY-STYLE (Search style seeds)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_query_style() {
  local brand="" tags="" name="" limit=20

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand) brand="$2"; shift 2;;
      --tags) tags="$2"; shift 2;;
      --name) name="$2"; shift 2;;
      --limit) limit="$2"; shift 2;;
      *) shift;;
    esac
  done

  # Read from JSONL, filter style_seed entries
  local results
  results=$(python3 - "$INDEX_FILE" "$brand" "$tags" "$name" "$limit" << 'PYEOF'
import json, sys

index_file = sys.argv[1]
brand = sys.argv[2]
tags_filter = sys.argv[3]
name_filter = sys.argv[4]
limit = int(sys.argv[5])

results = []

try:
    with open(index_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except:
                continue

            # Only style_seed entries
            if entry.get("type") != "style_seed":
                continue

            # Filter by brand
            if brand and entry.get("brand") != brand:
                continue

            # Filter by tags (any match)
            if tags_filter:
                filter_tags = [t.strip() for t in tags_filter.split(",") if t.strip()]
                entry_tags = entry.get("tags", [])
                if not any(t in entry_tags for t in filter_tags):
                    continue

            # Filter by name (substring)
            if name_filter:
                entry_name = entry.get("name", "")
                if name_filter.lower() not in entry_name.lower():
                    continue

            results.append(entry)
except Exception as e:
    print("Error reading index: %s" % e, file=sys.stderr)
    sys.exit(1)

# Sort by timestamp (newest first)
results.sort(key=lambda x: x.get("ts", 0), reverse=True)
results = results[:limit]

if not results:
    print("No style seeds found matching criteria")
    sys.exit(0)

# Display header
print("%-16s | %-15s | %-12s | %-30s | %s" % ("ID", "Name", "Brand", "Mood", "Colors"))
print("-" * 100)

for e in results:
    colors = ", ".join(e.get("colors", [])[:3])
    mood_str = str(e.get("mood", "-"))[:30]
    name_str = str(e.get("name", "-"))[:15]
    print("%-16s | %-15s | %-12s | %-30s | %s" % (
        e["id"], name_str, e.get("brand", "-"), mood_str, colors
    ))

print("\nTotal: %d style seeds" % len(results))
PYEOF
  )

  echo "$results"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
  local cmd="${1:-}"
  shift || true

  init_index

  case "$cmd" in
    add) cmd_add "$@";;
    query) cmd_query "$@";;
    digest) cmd_digest "$@";;
    query-style) cmd_query_style "$@";;
    promote) cmd_promote "$@";;
    export) cmd_export "$@";;
    list) cmd_list "$@";;
    --help|-h|help)
      echo "Image Seed Bank CLI"
      echo ""
      echo "Commands:"
      echo "  add          Add new image seed"
      echo "  query        Query seeds by criteria"
      echo "  digest       Analyze images via Gemini Vision, save as style seed"
      echo "  query-style  Search style seeds"
      echo "  promote      Mark seed as winner"
      echo "  export       Export seed to Drive"
      echo "  list         List all seeds"
      echo "  --help       Show this help"
      echo ""
      echo "Examples:"
      echo "  bash image-seed.sh add --type key_visual --brand pinxin --campaign cny26 --file-path path/to/image.jpg --tags \"cny,warm\""
      echo ""
      echo "  bash image-seed.sh digest --images \"ref1.jpg,ref2.jpg\" --name \"mirra ig vibes\" --brand mirra --tags \"instagram,lifestyle\""
      echo ""
      echo "  bash image-seed.sh query-style --brand mirra --tags \"instagram\""
      ;;
    "")
      log_error "No command specified"
      log_info "Run: bash image-seed.sh --help"
      return 1
      ;;
    *)
      log_error "Unknown command: $cmd"
      log_info "Run: bash image-seed.sh --help"
      return 1
      ;;
  esac
}

main "$@"
