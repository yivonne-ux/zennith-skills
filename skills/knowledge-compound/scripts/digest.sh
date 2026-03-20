#!/usr/bin/env bash
# digest.sh — Intake + digest any knowledge source into the compound learning loop
#
# Usage:
#   bash digest.sh --source "robonuggets/R34" --type "workflow" --file analysis.md --agent "dreami"
#   bash digest.sh --source "user-correction" --type "brand-fix" --fact "MIRRA is bento, not skincare" --agent "dreami,iris"
#   bash digest.sh --source "session/dreami/2026-03-01" --type "session-learning" --fact "NanoBanana needs --ref-image for brand consistency"
#   bash digest.sh list [--type workflow] [--agent dreami] [--source robonuggets]
#   bash digest.sh search "callback async pattern"

set -uo pipefail

DB="$HOME/.openclaw/workspace/vault/vault.db"
LEGACY_DB="$HOME/.openclaw/workspace/gaia-db/gaia.db"
LOG="$HOME/.openclaw/logs/knowledge-compound.log"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TS_EPOCH=$(date +%s)

mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

# ── Vault DB already has tables + FTS5 triggers ─────────────────────────────
# vault table: id, source_type, source_ref, source_path, brand, category, agent, entry_type, text, metadata, ts, created_at
# vault_fts: text, brand, category, agent, entry_type (auto-indexed via triggers)
# No table creation needed — vault.db is the unified store

# ── Parse args ──────────────────────────────────────────────────────────────
ACTION="${1:-}"
SOURCE=""
TYPE=""
FACT=""
TAGS=""
AGENT=""
FILE=""
PATTERN_NAME=""
NAMESPACE=""
ENTRY_PATH=""

if [[ "$ACTION" == "list" || "$ACTION" == "search" || "$ACTION" == "stats" || "$ACTION" == "recent" || "$ACTION" == "add" ]]; then
    shift
else
    ACTION="add"
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)  SOURCE="$2"; shift 2 ;;
        --type)    TYPE="$2"; shift 2 ;;
        --fact)    FACT="$2"; shift 2 ;;
        --tags)    TAGS="$2"; shift 2 ;;
        --agent)   AGENT="$2"; shift 2 ;;
        --file)    FILE="$2"; shift 2 ;;
        --pattern) PATTERN_NAME="$2"; shift 2 ;;
        --namespace) NAMESPACE="$2"; shift 2 ;;
        --path)    ENTRY_PATH="$2"; shift 2 ;;
        --source-type) TYPE="$2"; shift 2 ;;
        --text)    FACT="$2"; shift 2 ;;
        *)
            if [[ "$ACTION" == "search" ]]; then
                FACT="$1"; shift
            else
                echo "Unknown arg: $1"; exit 1
            fi
            ;;
    esac
done

# ── Commands ────────────────────────────────────────────────────────────────

case "$ACTION" in
    add)
        if [[ -z "$SOURCE" || -z "$TYPE" ]]; then
            echo "Usage: digest.sh --source SOURCE --type TYPE --fact FACT [--agent AGENT] [--tags TAGS]"
            echo "   Or: digest.sh --source SOURCE --type TYPE --file FILE [--agent AGENT]"
            echo ""
            echo "Types: workflow, competitor-intel, user-correction, session-learning,"
            echo "       tool-discovery, brand-update, performance-data, tutorial, pattern"
            echo ""
            echo "Commands: list, search QUERY, stats, recent"
            exit 1
        fi

        # If file provided, read facts from it (one per non-empty line, or whole file as one fact)
        if [[ -n "$FILE" && -f "$FILE" ]]; then
            FACT=$(cat "$FILE" | head -c 10000)
            TAGS="${TAGS:-$(basename "$FILE" | sed 's/\.[^.]*$//')}"
        fi

        if [[ -z "$FACT" ]]; then
            echo "❌ No fact provided (--fact or --file)"
            exit 1
        fi

        # Escape for SQLite
        SAFE_FACT=$(echo "$FACT" | sed "s/'/''/g")
        SAFE_SOURCE=$(echo "$SOURCE" | sed "s/'/''/g")
        SAFE_TAGS=$(echo "$TAGS" | sed "s/'/''/g")

        # Check for duplicate (same category/source + similar text)
        EXISTING=$(sqlite3 "$DB" "SELECT id FROM vault WHERE category='$SAFE_SOURCE' AND source_type='knowledge' AND text LIKE '%$(echo "$SAFE_FACT" | head -c 100 | sed "s/'/''/g")%' LIMIT 1;" 2>/dev/null)

        TS_EPOCH_MS=$((TS_EPOCH * 1000))

        # Auto-classify namespace and path if not provided
        if [[ -z "$NAMESPACE" ]]; then
            case "$TYPE" in
                memory|shared-facts)
                    if [[ -n "$AGENT" ]]; then
                        NAMESPACE="agent"
                        if [[ -z "$ENTRY_PATH" ]]; then
                            _first_agent=$(echo "$AGENT" | cut -d',' -f1 | tr -d ' ')
                            _et="${TYPE:-general}"
                            ENTRY_PATH="agent/${_first_agent}/memory/${_et}"
                        fi
                    else
                        NAMESPACE="resources"
                    fi
                    ;;
                brand-dna)
                    NAMESPACE="resources"
                    [[ -z "$ENTRY_PATH" ]] && ENTRY_PATH="resources/brands/${SOURCE:-unknown}"
                    ;;
                seeds|image-seeds)
                    NAMESPACE="resources"
                    [[ -z "$ENTRY_PATH" ]] && ENTRY_PATH="resources/seeds/${SOURCE:-general}"
                    ;;
                patterns|pattern)
                    NAMESPACE="agent"
                    [[ -z "$ENTRY_PATH" ]] && ENTRY_PATH="agent/system/patterns/${SOURCE:-general}"
                    ;;
                room-exec|room-feedback)
                    NAMESPACE="agent"
                    [[ -z "$ENTRY_PATH" ]] && ENTRY_PATH="agent/system/rooms/${TYPE}"
                    ;;
                knowledge)
                    NAMESPACE="agent"
                    [[ -z "$ENTRY_PATH" ]] && ENTRY_PATH="agent/system/knowledge"
                    ;;
                biz-opportunity)
                    NAMESPACE="resources"
                    [[ -z "$ENTRY_PATH" ]] && ENTRY_PATH="resources/biz-opportunities"
                    ;;
                youtube)
                    NAMESPACE="resources"
                    [[ -z "$ENTRY_PATH" ]] && ENTRY_PATH="resources/youtube"
                    ;;
                *)
                    NAMESPACE="resources"
                    [[ -z "$ENTRY_PATH" ]] && ENTRY_PATH="resources/${TYPE:-other}"
                    ;;
            esac
        fi
        [[ -z "$ENTRY_PATH" ]] && ENTRY_PATH="${NAMESPACE:-resources}/${TYPE:-other}"

        # Generate L0 abstract (first sentence or first 200 chars)
        L0_ABSTRACT=""
        _first_period=$(echo "$FACT" | head -c 300 | grep -o '^[^.]*\.' 2>/dev/null | head -1)
        if [[ -n "$_first_period" && ${#_first_period} -gt 5 ]]; then
            L0_ABSTRACT="$_first_period"
        else
            L0_ABSTRACT=$(echo "$FACT" | head -c 200)
            if [[ ${#FACT} -gt 200 ]]; then
                L0_ABSTRACT="${L0_ABSTRACT}..."
            fi
        fi
        SAFE_L0=$(echo "$L0_ABSTRACT" | sed "s/'/''/g")
        SAFE_NAMESPACE=$(echo "$NAMESPACE" | sed "s/'/''/g")
        SAFE_ENTRY_PATH=$(echo "$ENTRY_PATH" | sed "s/'/''/g")

        if [[ -n "$EXISTING" ]]; then
            echo "📝 Updated existing knowledge #$EXISTING (duplicate from $SOURCE)"
            log "SKIP duplicate knowledge from $SOURCE"
        else
            # Insert into vault
            SAFE_FILE=$(echo "$FILE" | sed "s/'/''/g")
            sqlite3 "$DB" "INSERT INTO vault (source_type, source_ref, source_path, brand, category, agent, entry_type, text, metadata, ts, namespace, path, l0_abstract)
                VALUES ('knowledge', 'digest-${TS_EPOCH}', '$SAFE_FILE', '', '$SAFE_SOURCE', '$AGENT', '$TYPE', '$SAFE_FACT',
                '{\"tags\":\"$SAFE_TAGS\",\"status\":\"active\",\"confidence\":1.0}', $TS_EPOCH_MS, '$SAFE_NAMESPACE', '$SAFE_ENTRY_PATH', '$SAFE_L0');"
            NEW_ID=$(sqlite3 "$DB" "SELECT last_insert_rowid();")
            echo "✅ Knowledge #$NEW_ID digested from $SOURCE ($TYPE)"
            log "ADD knowledge #$NEW_ID: $SOURCE ($TYPE) → agents: $AGENT"
        fi

        # If this is a pattern-type fact, register/increment pattern in vault
        if [[ -n "$PATTERN_NAME" ]]; then
            SAFE_PATTERN=$(echo "$PATTERN_NAME" | sed "s/'/''/g")
            EXISTING_PATTERN=$(sqlite3 "$DB" "SELECT id FROM vault WHERE source_type='pattern' AND source_ref='$SAFE_PATTERN' LIMIT 1;" 2>/dev/null)

            if [[ -n "$EXISTING_PATTERN" ]]; then
                # Read current metadata, increment occurrences
                OLD_META=$(sqlite3 "$DB" "SELECT metadata FROM vault WHERE id=$EXISTING_PATTERN;" 2>/dev/null)
                OLD_COUNT=$(echo "$OLD_META" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('occurrences',1))" 2>/dev/null || echo "1")
                NEW_COUNT=$((OLD_COUNT + 1))

                # Auto-promote status
                if [[ "$NEW_COUNT" -ge 5 ]]; then
                    NEW_STATUS="implemented"
                elif [[ "$NEW_COUNT" -ge 3 ]]; then
                    NEW_STATUS="validated"
                else
                    NEW_STATUS="observed"
                fi

                sqlite3 "$DB" "UPDATE vault SET
                    metadata=json_set(metadata, '$.occurrences', $NEW_COUNT, '$.status', '$NEW_STATUS'),
                    category=category||','||'$SAFE_SOURCE'
                    WHERE id=$EXISTING_PATTERN;"

                if [[ "$NEW_COUNT" -ge 5 && "$NEW_STATUS" == "implemented" ]]; then
                    echo "🚀 Pattern '$PATTERN_NAME' promoted to IMPLEMENTED ($NEW_COUNT occurrences)"
                elif [[ "$NEW_COUNT" -ge 3 && "$NEW_STATUS" == "validated" ]]; then
                    echo "✨ Pattern '$PATTERN_NAME' promoted to VALIDATED ($NEW_COUNT occurrences)"
                else
                    echo "📊 Pattern '$PATTERN_NAME': $NEW_COUNT occurrences ($NEW_STATUS)"
                fi
            else
                sqlite3 "$DB" "INSERT INTO vault (source_type, source_ref, source_path, brand, category, agent, entry_type, text, metadata, ts)
                    VALUES ('pattern', '$SAFE_PATTERN', '', '', '$SAFE_SOURCE', '$AGENT', 'observed', '$SAFE_FACT',
                    '{\"name\":\"$SAFE_PATTERN\",\"occurrences\":1,\"status\":\"observed\"}', $TS_EPOCH_MS);"
                echo "🔍 New pattern observed: '$PATTERN_NAME'"
            fi
        fi
        ;;

    list)
        FILTER="AND source_type IN ('knowledge','pattern')"
        [[ -n "$TYPE" ]] && FILTER="$FILTER AND entry_type='$TYPE'"
        [[ -n "$AGENT" ]] && FILTER="$FILTER AND agent LIKE '%$AGENT%'"
        [[ -n "$SOURCE" ]] && FILTER="$FILTER AND category LIKE '%$SOURCE%'"

        sqlite3 -header -column "$DB" "
            SELECT id, category as source, entry_type as type, substr(text,1,80) as fact_preview, agent, source_type, created_at
            FROM vault WHERE 1=1 $FILTER ORDER BY created_at DESC LIMIT 30;
        " 2>/dev/null
        ;;

    search)
        if [[ -z "$FACT" ]]; then
            echo "Usage: digest.sh search QUERY"
            exit 1
        fi
        sqlite3 -header -column "$DB" "
            SELECT v.id, v.category as source, v.entry_type as type, substr(v.text,1,120) as fact_preview, v.agent
            FROM vault_fts f JOIN vault v ON f.rowid = v.id
            WHERE vault_fts MATCH '$(echo "$FACT" | sed "s/'/''/g")'
            ORDER BY rank LIMIT 20;
        " 2>/dev/null
        ;;

    stats)
        echo "=== Vault Knowledge Stats ==="
        sqlite3 "$DB" "SELECT source_type, COUNT(*) as count FROM vault GROUP BY source_type ORDER BY count DESC;" 2>/dev/null
        echo ""
        echo "=== Pattern Registry ==="
        sqlite3 -header -column "$DB" "
            SELECT source_ref as name,
                   json_extract(metadata, '$.occurrences') as occurrences,
                   json_extract(metadata, '$.status') as status,
                   substr(category,1,60) as sources
            FROM vault WHERE source_type='pattern'
            ORDER BY json_extract(metadata, '$.occurrences') DESC LIMIT 20;
        " 2>/dev/null
        ;;

    recent)
        sqlite3 -header -column "$DB" "
            SELECT id, category as source, entry_type as type, substr(text,1,100) as fact, agent
            FROM vault WHERE source_type IN ('knowledge','pattern')
            ORDER BY created_at DESC LIMIT 10;
        " 2>/dev/null
        ;;

    *)
        echo "Unknown action: $ACTION"
        echo "Commands: add (default), list, search, stats, recent"
        exit 1
        ;;
esac
