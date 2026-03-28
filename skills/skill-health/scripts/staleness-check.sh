#!/usr/bin/env bash
# staleness-check.sh — Detect stale, broken, or drifted skills
# Inspired by FrancyJGLisboa/agent-skill-creator staleness detection
#
# 3-layer check:
#   1. Review tracking — last modified date vs review interval
#   2. Dependency health — check if referenced scripts/tools exist
#   3. Security scan — detect hardcoded API keys or credentials
#
# Usage:
#   staleness-check.sh                    # Check all skills
#   staleness-check.sh --skill nanobanana # Check one skill
#   staleness-check.sh --fix              # Auto-fix what's possible
#   staleness-check.sh --json             # Output as JSON

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SKILLS_DIR="$HOME/.openclaw/skills"
OUTPUT_JSON=false
FIX_MODE=false
SINGLE_SKILL=""
STALE_DAYS=30  # Skills not modified in 30+ days get flagged

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill) SINGLE_SKILL="$2"; shift 2 ;;
    --json)  OUTPUT_JSON=true; shift ;;
    --fix)   FIX_MODE=true; shift ;;
    --days)  STALE_DAYS="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

# Counters
TOTAL=0
HEALTHY=0
STALE=0
BROKEN_DEPS=0
SECURITY_ISSUES=0
MISSING_AGENTS=0

declare_results() {
  echo ""
  echo "=== SKILL HEALTH REPORT ==="
  echo "Total skills checked: $TOTAL"
  echo "  Healthy:          $HEALTHY"
  echo "  Stale (>${STALE_DAYS}d):    $STALE"
  echo "  Broken deps:      $BROKEN_DEPS"
  echo "  Security issues:  $SECURITY_ISSUES"
  echo "  Missing agents:   $MISSING_AGENTS"
  echo ""
  if [[ $((STALE + BROKEN_DEPS + SECURITY_ISSUES)) -eq 0 ]]; then
    echo "All skills healthy."
  else
    echo "Issues found: $((STALE + BROKEN_DEPS + SECURITY_ISSUES + MISSING_AGENTS)) total"
  fi
}

check_skill() {
  local skill_dir="$1"
  local skill_name
  skill_name=$(basename "$skill_dir")
  local skill_md="${skill_dir}/SKILL.md"

  [[ -f "$skill_md" ]] || return 0

  TOTAL=$((TOTAL + 1))
  local issues=""

  # ── Layer 1: Staleness (last modified date) ──
  local last_modified
  last_modified=$(stat -f %m "$skill_md" 2>/dev/null || stat -c %Y "$skill_md" 2>/dev/null || echo 0)
  local now
  now=$(date +%s)
  local age_days=$(( (now - last_modified) / 86400 ))

  if [[ $age_days -gt $STALE_DAYS ]]; then
    STALE=$((STALE + 1))
    issues="${issues}  STALE: ${skill_name}/SKILL.md not modified in ${age_days} days\n"
  fi

  # ── Layer 2: Dependency health (referenced scripts exist?) ──
  local scripts_dir="${skill_dir}/scripts"
  if [[ -d "$scripts_dir" ]]; then
    # Use grep to extract absolute paths (fast, single pass per skill)
    # Skip paths containing $ (variable refs like $HOME, $OPENCLAW)
    local ref_paths
    ref_paths=$(grep -rhoE '/[^ "]+\.(sh|py|json|md|yaml)' "$scripts_dir" 2>/dev/null | grep -v '[${}]' | sort -u || true)

    while IFS= read -r ref_path; do
      [[ -z "$ref_path" ]] && continue
      if [[ ! -f "$ref_path" ]]; then
        BROKEN_DEPS=$((BROKEN_DEPS + 1))
        issues="${issues}  BROKEN DEP: ${skill_name} references missing file: ${ref_path}\n"
      fi
    done <<< "$ref_paths"
  fi

  # ── Layer 3: Security scan (hardcoded credentials) ──
  local security_patterns=(
    'sk-[a-zA-Z0-9]{20,}'          # OpenAI API key
    'AKIA[A-Z0-9]{16}'             # AWS Access Key
    'ghp_[a-zA-Z0-9]{36}'          # GitHub PAT
    'gho_[a-zA-Z0-9]{36}'          # GitHub OAuth
    'xoxb-[0-9]+-[0-9]+-[a-zA-Z0-9]+' # Slack bot token
    'xoxp-[0-9]+-[0-9]+-[a-zA-Z0-9]+' # Slack user token
    'AIza[0-9A-Za-z_-]{35}'        # Google API key
    'ya29\.[0-9A-Za-z_-]+'         # Google OAuth token
    'EAAz[0-9A-Za-z]+'             # Meta access token
  )

  for pattern in "${security_patterns[@]}"; do
    local matches
    matches=$(grep -rE "$pattern" "$skill_dir" --include="*.sh" --include="*.py" --include="*.md" -l 2>/dev/null | grep -v "\.env" | grep -v "secrets" || true)
    if [[ -n "$matches" ]]; then
      SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
      issues="${issues}  SECURITY: ${skill_name} has hardcoded credential pattern in: $(echo "$matches" | head -1)\n"
    fi
  done

  # ── Layer 4: Agent assignment check ──
  local agents_line
  agents_line=$(grep -A 5 '^agents:' "$skill_md" 2>/dev/null | grep '^\s*-' | head -5)
  if [[ -z "$agents_line" ]]; then
    MISSING_AGENTS=$((MISSING_AGENTS + 1))
    issues="${issues}  NO AGENTS: ${skill_name}/SKILL.md has no agents: field\n"
  fi

  # ── Report ──
  if [[ -z "$issues" ]]; then
    HEALTHY=$((HEALTHY + 1))
    [[ "$OUTPUT_JSON" != "true" ]] && echo "  OK  ${skill_name} (${age_days}d old)"
  else
    printf "  !!  %s (%sd old)\n%b" "$skill_name" "$age_days" "$issues"
  fi
}

echo "=== Skill Health Check ==="
echo "Skills dir: $SKILLS_DIR"
echo "Stale threshold: ${STALE_DAYS} days"
echo ""

if [[ -n "$SINGLE_SKILL" ]]; then
  check_skill "${SKILLS_DIR}/${SINGLE_SKILL}"
else
  for skill_dir in "${SKILLS_DIR}"/*/; do
    [[ -d "$skill_dir" ]] || continue
    [[ -f "${skill_dir}/SKILL.md" ]] || continue
    check_skill "$skill_dir"
  done
fi

declare_results
