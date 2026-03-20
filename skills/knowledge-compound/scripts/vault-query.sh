#!/usr/bin/env bash
# vault-query.sh — Unified L0/L1/L2 memory query tool for Zennith OS vault.db
#
# Usage:
#   vault-query.sh search "nanobanana batch mode"                    # L0 results (default)
#   vault-query.sh search "nanobanana batch mode" --detail           # L1 results
#   vault-query.sh search "nanobanana batch mode" --full             # L2 full text
#   vault-query.sh search "nanobanana batch mode" --namespace agent  # filter by namespace
#   vault-query.sh search "nanobanana batch mode" --path "agent/taoz/*"  # filter by path
#   vault-query.sh browse "agent/taoz/skills/"                       # list entries under path
#   vault-query.sh stats                                             # namespace/path breakdown
#   vault-query.sh stats --json                                      # JSON output

set -uo pipefail

DB="$HOME/.openclaw/workspace/vault/vault.db"

if [ ! -f "$DB" ]; then
    echo "ERROR: vault.db not found at $DB" >&2
    exit 1
fi

# ── Parse action ──────────────────────────────────────────────────────────────
ACTION="${1:-help}"
shift 2>/dev/null || true

# ── Parse flags ───────────────────────────────────────────────────────────────
QUERY=""
DETAIL_LEVEL="l0"  # l0, l1, l2
NAMESPACE=""
PATH_FILTER=""
JSON_OUTPUT=0
LIMIT=20

while [ $# -gt 0 ]; do
    case "$1" in
        --detail)     DETAIL_LEVEL="l1"; shift ;;
        --full)       DETAIL_LEVEL="l2"; shift ;;
        --namespace)  NAMESPACE="$2"; shift 2 ;;
        --path)       PATH_FILTER="$2"; shift 2 ;;
        --json)       JSON_OUTPUT=1; shift ;;
        --limit)      LIMIT="$2"; shift 2 ;;
        *)
            if [ -z "$QUERY" ]; then
                QUERY="$1"
            else
                QUERY="$QUERY $1"
            fi
            shift
            ;;
    esac
done

# ── Helper: build WHERE clause ────────────────────────────────────────────────
build_filters() {
    local where=""
    if [ -n "$NAMESPACE" ]; then
        local safe_ns
        safe_ns=$(printf '%s' "$NAMESPACE" | sed "s/'/''/g")
        where="$where AND v.namespace='$safe_ns'"
    fi
    if [ -n "$PATH_FILTER" ]; then
        # Convert glob * to SQL % for LIKE
        local safe_path
        safe_path=$(printf '%s' "$PATH_FILTER" | sed "s/'/''/g" | sed 's/\*/%/g')
        where="$where AND v.path LIKE '$safe_path'"
    fi
    printf '%s' "$where"
}

# ── Helper: select columns based on detail level ─────────────────────────────
detail_columns() {
    case "$DETAIL_LEVEL" in
        l0) echo "v.id, v.namespace, v.path, v.l0_abstract as abstract" ;;
        l1) echo "v.id, v.namespace, v.path, v.l0_abstract as abstract, v.l1_overview as overview" ;;
        l2) echo "v.id, v.namespace, v.path, v.l0_abstract as abstract, v.text" ;;
    esac
}

# ── Commands ──────────────────────────────────────────────────────────────────
case "$ACTION" in
    search)
        if [ -z "$QUERY" ]; then
            echo "Usage: vault-query.sh search QUERY [--detail|--full] [--namespace NS] [--path PATTERN]" >&2
            exit 1
        fi

        SAFE_QUERY=$(printf '%s' "$QUERY" | sed "s/'/''/g")
        FILTERS=$(build_filters)
        COLS=$(detail_columns)

        if [ "$JSON_OUTPUT" -eq 1 ]; then
            sqlite3 "$DB" -json "
                SELECT $COLS
                FROM vault_fts f JOIN vault v ON f.rowid = v.id
                WHERE vault_fts MATCH '$SAFE_QUERY' $FILTERS
                ORDER BY rank
                LIMIT $LIMIT;
            " 2>/dev/null
        else
            sqlite3 -header -column "$DB" "
                SELECT $COLS
                FROM vault_fts f JOIN vault v ON f.rowid = v.id
                WHERE vault_fts MATCH '$SAFE_QUERY' $FILTERS
                ORDER BY rank
                LIMIT $LIMIT;
            " 2>/dev/null
        fi
        ;;

    browse)
        if [ -z "$QUERY" ]; then
            # Show top-level paths
            QUERY=""
        fi

        SAFE_PATH=$(printf '%s' "$QUERY" | sed "s/'/''/g")
        FILTERS=$(build_filters)

        if [ -z "$SAFE_PATH" ]; then
            # Show top-level namespace/path summary
            SQL="SELECT DISTINCT
                    substr(path, 1, CASE WHEN instr(substr(path, 1), '/') > 0 THEN instr(path, '/') - 1 ELSE length(path) END) as top_level,
                    COUNT(*) as entries
                 FROM vault
                 WHERE path != ''
                 GROUP BY top_level
                 ORDER BY entries DESC;"
        else
            # Show entries under the given path prefix
            local_like="${SAFE_PATH}%"
            # Calculate depth: count slashes in prefix, then show next level
            SQL="SELECT v.id, v.namespace, v.path, v.l0_abstract as abstract
                 FROM vault v
                 WHERE v.path LIKE '$local_like' $FILTERS
                 ORDER BY v.path
                 LIMIT $LIMIT;"
        fi

        if [ "$JSON_OUTPUT" -eq 1 ]; then
            sqlite3 "$DB" -json "$SQL" 2>/dev/null
        else
            sqlite3 -header -column "$DB" "$SQL" 2>/dev/null
        fi
        ;;

    stats)
        FILTERS=$(build_filters)

        if [ "$JSON_OUTPUT" -eq 1 ]; then
            echo "{"

            # Namespace stats
            echo '  "namespaces": '
            sqlite3 "$DB" -json "
                SELECT namespace, COUNT(*) as count
                FROM vault WHERE 1=1 $(echo "$FILTERS" | sed 's/v\.//g')
                GROUP BY namespace ORDER BY count DESC;
            " 2>/dev/null
            echo ","

            # Path breakdown (2 levels deep)
            echo '  "paths": '
            sqlite3 "$DB" -json "
                SELECT
                    CASE
                        WHEN instr(substr(path, instr(path,'/')+1), '/') > 0
                        THEN substr(path, 1, instr(path,'/') + instr(substr(path, instr(path,'/')+1), '/') - 1)
                        ELSE path
                    END as path_prefix,
                    COUNT(*) as count
                FROM vault
                WHERE path != '' $(echo "$FILTERS" | sed 's/v\.//g')
                GROUP BY path_prefix
                ORDER BY count DESC
                LIMIT 30;
            " 2>/dev/null
            echo ","

            # Totals
            echo '  "total": '
            sqlite3 "$DB" -json "SELECT COUNT(*) as total FROM vault WHERE 1=1 $(echo "$FILTERS" | sed 's/v\.//g');" 2>/dev/null

            echo "}"
        else
            echo "=== Vault Memory Tier Stats ==="
            echo ""
            echo "--- Namespace Distribution ---"
            sqlite3 -header -column "$DB" "
                SELECT namespace, COUNT(*) as count
                FROM vault WHERE 1=1 $(echo "$FILTERS" | sed 's/v\.//g')
                GROUP BY namespace ORDER BY count DESC;
            " 2>/dev/null

            echo ""
            echo "--- Path Breakdown (top 20) ---"
            sqlite3 -header -column "$DB" "
                SELECT
                    CASE
                        WHEN instr(substr(path, instr(path,'/')+1), '/') > 0
                        THEN substr(path, 1, instr(path,'/') + instr(substr(path, instr(path,'/')+1), '/') - 1)
                        ELSE path
                    END as path_prefix,
                    COUNT(*) as count
                FROM vault
                WHERE path != '' $(echo "$FILTERS" | sed 's/v\.//g')
                GROUP BY path_prefix
                ORDER BY count DESC
                LIMIT 20;
            " 2>/dev/null

            echo ""
            echo "--- L0 Coverage ---"
            sqlite3 "$DB" "
                SELECT
                    COUNT(*) as total,
                    SUM(CASE WHEN l0_abstract != '' THEN 1 ELSE 0 END) as has_l0,
                    SUM(CASE WHEN l1_overview != '' THEN 1 ELSE 0 END) as has_l1
                FROM vault;
            " 2>/dev/null

            echo ""
            TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM vault;" 2>/dev/null)
            echo "Total entries: $TOTAL"
        fi
        ;;

    help|--help|-h)
        echo "vault-query.sh — L0/L1/L2 memory query tool for Zennith OS"
        echo ""
        echo "Commands:"
        echo "  search QUERY [flags]   Search vault using FTS5"
        echo "  browse [PATH]          List entries under a path prefix"
        echo "  stats                  Show namespace/path breakdown"
        echo ""
        echo "Flags:"
        echo "  --detail               Return L1 overview (key points, <500 tokens)"
        echo "  --full                 Return L2 full text"
        echo "  --namespace NS         Filter by namespace (user/agent/resources)"
        echo "  --path PATTERN         Filter by path (supports * glob)"
        echo "  --json                 Output as JSON"
        echo "  --limit N              Max results (default: 20)"
        echo ""
        echo "Examples:"
        echo "  vault-query.sh search \"nanobanana batch\""
        echo "  vault-query.sh search \"brand DNA\" --namespace resources --detail"
        echo "  vault-query.sh browse \"agent/system/\""
        echo "  vault-query.sh stats --json"
        ;;

    *)
        echo "Unknown action: $ACTION" >&2
        echo "Run: vault-query.sh help" >&2
        exit 1
        ;;
esac
