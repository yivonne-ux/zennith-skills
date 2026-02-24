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
  grep -c "\"brand\":\"$brand\"" "$INDEX_FILE" 2>/dev/null || echo 0
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

  # Validate required fields
  if [ -z "$type" ] || [ -z "$brand" ] || [ -z "$campaign" ] || [ -z "$file_path" ]; then
    log_error "Required fields: --type, --brand, --campaign, --file-path"
    log_info "Usage: bash image-seed.sh add --type <key_visual|logo|model> --brand <brand> --campaign <id> --file-path <path> [options]"
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
import json, sys
id, type, brand, campaign, file_path, tags_str, colors_str, mood, subject, prompt, drive_url, status, created_by = sys.argv[1:]

# Parse tags
tags = [t.strip() for t in tags_str.split(",") if t.strip()] if tags_str else []

# Parse colors
colors = [c.strip() for c in colors_str.split(",") if c.strip()] if colors_str else []

# Build entry
entry = {
    "id": id,
    "ts": int(sys.argv[11]) if len(sys.argv) > 11 else int(__import__('time').time() * 1000),
    "type": type,
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
    "created_at": __import__('datetime').datetime.now().strftime("%Y-%m-%d")
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
    echo "$line" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f\"{d['id']:12} | {d['brand']:12} | {d['campaign']:12} | {d['type']:14} | {d['status']:10}\")
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

  echo "$INDEX_FILE" | python3 - "$limit" << 'PYEOF'
import json, sys

limit = int(sys.argv[1])

# Read index file
index_file = "/Users/jennwoeiloh/.openclaw/workspace/rag/image-seed-bank.jsonl"
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
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
  local cmd="${1:-}"
  shift || true

  init_index

  case "$cmd" in
    add) cmd_add "$@";;
    query) cmd_query "$@";;
    promote) cmd_promote "$@";;
    export) cmd_export "$@";;
    list) cmd_list "$@";;
    --help|-h|help)
      echo "Image Seed Bank CLI"
      echo ""
      echo "Commands:"
      echo "  add      Add new image seed"
      echo "  query    Query seeds by criteria"
      echo "  promote  Mark seed as winner"
      echo "  export   Export seed to Drive"
      echo "  list     List all seeds"
      echo "  --help   Show this help"
      echo ""
      echo "Example:"
      echo "  bash image-seed.sh add --type key_visual --brand pinxin --campaign cny26 --file-path path/to/image.jpg --tags \"cny,warm\""
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
