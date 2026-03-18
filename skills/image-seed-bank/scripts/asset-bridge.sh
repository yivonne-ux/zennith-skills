#!/usr/bin/env bash
# asset-bridge.sh — Bidirectional sync between library.db and image-seed-bank.jsonl
# Usage: bash asset-bridge.sh [--direction db-to-jsonl|jsonl-to-db|both] [--dry-run]
#
# Syncs assets between:
#   - library.db (SQLite, GAIA Creative Studio)
#   - image-seed-bank.jsonl (CLI skills)
#
# macOS Bash 3.2 compatible. No jq, no declare -A, no timeout.

set -uo pipefail

DB_PATH="$HOME/.openclaw/workspace/apps/gaia-creative-studio/server/data/library.db"
JSONL_PATH="$HOME/.openclaw/workspace/rag/image-seed-bank.jsonl"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
DIRECTION="both"
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --direction) DIRECTION="$2"; shift 2;;
    --dry-run) DRY_RUN=1; shift;;
    --help|-h)
      echo "asset-bridge.sh — Bidirectional sync between library.db and image-seed-bank.jsonl"
      echo ""
      echo "Usage: bash asset-bridge.sh [--direction db-to-jsonl|jsonl-to-db|both] [--dry-run]"
      echo ""
      echo "Options:"
      echo "  --direction <dir>  Sync direction: db-to-jsonl, jsonl-to-db, or both (default: both)"
      echo "  --dry-run          Show what would sync without writing"
      echo "  --help             Show this help"
      exit 0
      ;;
    *) shift;;
  esac
done

# Validate direction
case "$DIRECTION" in
  db-to-jsonl|jsonl-to-db|both) ;;
  *)
    log_error "Invalid direction: $DIRECTION"
    log_info "Must be: db-to-jsonl, jsonl-to-db, or both"
    exit 1
    ;;
esac

# Check prerequisites
if [ ! -f "$DB_PATH" ]; then
  log_error "library.db not found at: $DB_PATH"
  exit 1
fi

# Ensure JSONL exists
if [ ! -f "$JSONL_PATH" ]; then
  mkdir -p "$(dirname "$JSONL_PATH")"
  touch "$JSONL_PATH"
  log_info "Created JSONL file: $JSONL_PATH"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DB-TO-JSONL: Library.db assets -> JSONL seed bank
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

sync_db_to_jsonl() {
  log_info "Syncing: library.db -> image-seed-bank.jsonl"

  python3 << PYEOF
import sqlite3, json, os, sys

db_path = "$DB_PATH"
jsonl_path = "$JSONL_PATH"
dry_run = $DRY_RUN

# Load existing JSONL IDs and file_paths for dedup
existing_ids = set()
existing_paths = set()

if os.path.exists(jsonl_path):
    with open(jsonl_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                if entry.get("id"):
                    existing_ids.add(entry["id"])
                if entry.get("file_path"):
                    existing_paths.add(entry["file_path"])
            except:
                pass

# Query library.db for all assets
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()
cursor.execute("SELECT * FROM assets ORDER BY created_at DESC")
rows = cursor.fetchall()
conn.close()

to_sync = []
for row in rows:
    row_dict = dict(row)
    asset_id = row_dict.get("id", "")
    filepath = row_dict.get("filepath", "")
    filename = row_dict.get("filename", "")

    # Skip if already in JSONL (match by id or filepath)
    if asset_id in existing_ids:
        continue
    if filepath and filepath in existing_paths:
        continue
    if filename and filename in existing_paths:
        continue

    # Parse ai_tags
    tags_list = []
    try:
        ai_tags = json.loads(row_dict.get("ai_tags") or "{}")
        if isinstance(ai_tags, dict):
            # Extract useful tags
            for key in ["contentType", "mood", "subjects", "description"]:
                val = ai_tags.get(key)
                if isinstance(val, list):
                    tags_list.extend(val)
                elif isinstance(val, str) and val:
                    tags_list.append(val)
        elif isinstance(ai_tags, list):
            tags_list = ai_tags
    except:
        pass

    # Build JSONL seed entry
    seed = {
        "id": asset_id,
        "ts": int(__import__('time').time() * 1000),
        "type": row_dict.get("content_type") or "key_visual",
        "file_path": filepath or filename or "",
        "brand": row_dict.get("brand") or "",
        "tags": tags_list,
        "mood": row_dict.get("mood") or "",
        "status": row_dict.get("status") or "draft",
        "created_by": "bridge",
        "created_at": (row_dict.get("created_at") or "")[:10]
    }
    to_sync.append(seed)

if not to_sync:
    print("[INFO] No new assets to sync from library.db to JSONL")
else:
    print(f"[INFO] Found {len(to_sync)} assets to sync from library.db to JSONL")
    for s in to_sync:
        print(f"  + {s['id']} | {s['brand']:12} | {s['type']:14} | {s['file_path'][:40]}")

    if not dry_run:
        with open(jsonl_path, "a") as f:
            for s in to_sync:
                f.write(json.dumps(s, ensure_ascii=False) + "\n")
        print(f"[OK] Appended {len(to_sync)} entries to JSONL")
    else:
        print("[DRY-RUN] Would append entries (no changes made)")
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# JSONL-TO-DB: JSONL seed bank -> Library.db
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

sync_jsonl_to_db() {
  log_info "Syncing: image-seed-bank.jsonl -> library.db"

  python3 << PYEOF
import sqlite3, json, os, sys

db_path = "$DB_PATH"
jsonl_path = "$JSONL_PATH"
dry_run = $DRY_RUN

if not os.path.exists(jsonl_path):
    print("[INFO] JSONL file does not exist, nothing to sync")
    sys.exit(0)

# Load existing DB IDs and filepaths for dedup
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

existing_ids = set()
existing_paths = set()
try:
    cursor.execute("SELECT id, filepath, filename FROM assets")
    for row in cursor.fetchall():
        row_dict = dict(row)
        existing_ids.add(row_dict.get("id", ""))
        fp = row_dict.get("filepath", "")
        fn = row_dict.get("filename", "")
        if fp:
            existing_paths.add(fp)
        if fn:
            existing_paths.add(fn)
except:
    pass

# Read JSONL entries
to_sync = []
with open(jsonl_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except:
            continue

        seed_id = entry.get("id", "")
        file_path = entry.get("file_path", "")

        # Skip if already in DB
        if seed_id in existing_ids:
            continue
        if file_path and file_path in existing_paths:
            continue

        to_sync.append(entry)

if not to_sync:
    print("[INFO] No new seeds to sync from JSONL to library.db")
else:
    print(f"[INFO] Found {len(to_sync)} seeds to sync from JSONL to library.db")
    for s in to_sync:
        print(f"  + {s.get('id','?'):12} | {s.get('brand',''):12} | {s.get('type',''):14}")

    if not dry_run:
        for s in to_sync:
            tags_json = json.dumps(s.get("tags", []))
            try:
                cursor.execute("""
                    INSERT OR IGNORE INTO assets
                    (id, filename, filepath, brand, format, content_type, mood, status, ai_tags, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    s.get("id", ""),
                    os.path.basename(s.get("file_path", "")),
                    s.get("file_path", ""),
                    s.get("brand", ""),
                    "image",
                    s.get("type", "key_visual"),
                    s.get("mood", ""),
                    s.get("status", "draft"),
                    tags_json,
                    s.get("created_at", ""),
                    s.get("created_at", ""),
                ))
            except Exception as e:
                print(f"  [WARN] Failed to insert {s.get('id','?')}: {e}")
        conn.commit()
        print(f"[OK] Inserted {len(to_sync)} entries into library.db")
    else:
        print("[DRY-RUN] Would insert entries (no changes made)")

conn.close()
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info "Asset Bridge — direction: $DIRECTION, dry-run: $DRY_RUN"
echo ""

case "$DIRECTION" in
  db-to-jsonl)
    sync_db_to_jsonl
    ;;
  jsonl-to-db)
    sync_jsonl_to_db
    ;;
  both)
    sync_db_to_jsonl
    echo ""
    sync_jsonl_to_db
    ;;
esac

echo ""
log_success "Asset bridge sync complete"
