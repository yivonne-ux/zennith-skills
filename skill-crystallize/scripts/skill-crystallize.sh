#!/usr/bin/env bash
# skill-crystallize.sh — Auto-turn workflows into reusable GAIA OS skills
set -euo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
SKILLS_DIR="$OPENCLAW_DIR/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"
GITHUB_REPO="$SKILLS_DIR"  # Git repo root
LOG_FILE="$OPENCLAW_DIR/workspace/logs/skill-crystallize.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null; }
info() { echo "[$1] $2"; log "$1: $2"; }
error() { echo "ERROR: $*" >&2; log "ERROR: $*"; }
die() { error "$@"; exit 1; }

# ─── CREATE COMMAND ─────────────────────────────────────────────────────
cmd_create() {
  local name="" description="" scope="tool-execution" agents="" guardrails=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      --description) description="$2"; shift 2 ;;
      --scope) scope="$2"; shift 2 ;;
      --agents) agents="$2"; shift 2 ;;
      --guardrails) guardrails="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$name" ] && die "Missing --name"
  [ -z "$description" ] && die "Missing --description"

  local skill_dir="$SKILLS_DIR/$name"

  if [ -d "$skill_dir" ]; then
    info "EXISTS" "$skill_dir already exists — skipping create"
    return 0
  fi

  info "CREATE" "Skill: $name"

  # Create directory structure
  mkdir -p "$skill_dir/scripts"

  # Build agents YAML
  local agents_yaml=""
  if [ -n "$agents" ]; then
    agents_yaml="    agents:"
    IFS=',' read -ra AGENT_LIST <<< "$agents"
    for a in "${AGENT_LIST[@]}"; do
      agents_yaml="$agents_yaml
      - $(echo "$a" | tr -d ' ')"
    done
  fi

  # Build guardrails YAML
  local guardrails_yaml=""
  if [ -n "$guardrails" ]; then
    guardrails_yaml="    guardrails:"
    IFS='|' read -ra GUARD_LIST <<< "$guardrails"
    for g in "${GUARD_LIST[@]}"; do
      guardrails_yaml="$guardrails_yaml
      - $(echo "$g" | sed 's/^ *//')"
    done
  else
    guardrails_yaml="    guardrails:
      - Follow the working examples exactly"
  fi

  # Generate SKILL.md
  cat > "$skill_dir/SKILL.md" <<EOF
---
name: $name
version: "0.1.0"
description: >
  $description
metadata:
  openclaw:
    scope: $scope
$guardrails_yaml
${agents_yaml}
---

# $name

## Purpose

$description

## Commands

\`\`\`bash
# TODO: Add commands
$name.sh help
\`\`\`

## CHANGELOG

### v0.1.0 ($(date +%Y-%m-%d))
- Initial creation via skill-crystallize
EOF

  # Generate stub script
  cat > "$skill_dir/scripts/$name.sh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") <command> [options]"
  echo ""
  echo "Commands:"
  echo "  help    Show this help"
}

main() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    help|--help|-h) usage ;;
    *) echo "Unknown command: $cmd"; usage; exit 1 ;;
  esac
}

main "$@"
STUB

  chmod +x "$skill_dir/scripts/$name.sh"

  info "CREATED" "$skill_dir"
  info "FILES" "SKILL.md + scripts/$name.sh"
  echo "$skill_dir"
}

# ─── FROM-SCRIPT COMMAND ───────────────────────────────────────────────
cmd_from_script() {
  local script="" name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --script) script="$2"; shift 2 ;;
      --name) name="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$script" ] && die "Missing --script"
  [ ! -f "$script" ] && die "Script not found: $script"

  # Auto-detect name from script filename
  if [ -z "$name" ]; then
    name=$(basename "$script" .sh)
  fi

  local skill_dir="$SKILLS_DIR/$name"
  mkdir -p "$skill_dir/scripts"

  # Copy script
  cp "$script" "$skill_dir/scripts/$name.sh"
  chmod +x "$skill_dir/scripts/$name.sh"

  # Extract description from script header comments
  local desc
  desc=$(head -5 "$script" | grep "^#" | grep -v "^#!" | head -1 | sed 's/^# *//')
  [ -z "$desc" ] && desc="Skill auto-created from $(basename "$script")"

  # Generate SKILL.md if it doesn't exist
  if [ ! -f "$skill_dir/SKILL.md" ]; then
    cmd_create --name "$name" --description "$desc"
  fi

  info "IMPORTED" "$script → $skill_dir/scripts/$name.sh"
  echo "$skill_dir"
}

# ─── README COMMAND (BILINGUAL EN + CN) ────────────────────────────────
cmd_readme() {
  local skill=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skill) skill="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$skill" ] && die "Missing --skill"

  local skill_dir="$SKILLS_DIR/$skill"
  [ ! -d "$skill_dir" ] && die "Skill not found: $skill_dir"

  local skill_md="$skill_dir/SKILL.md"
  [ ! -f "$skill_md" ] && die "No SKILL.md in $skill_dir"

  info "README" "Generating bilingual README for $skill..."

  # Read SKILL.md content
  local skill_content
  skill_content=$(cat "$skill_md")

  # Extract key fields
  local name desc version
  name=$(echo "$skill_content" | grep "^name:" | head -1 | sed 's/name: *//')
  version=$(echo "$skill_content" | grep "^version:" | head -1 | sed 's/version: *//; s/"//g')
  desc=$(echo "$skill_content" | sed -n '/^description:/,/^[a-z]/p' | head -3 | tail -2 | tr '\n' ' ' | sed 's/^ *//')
  [ -z "$desc" ] && desc=$(echo "$skill_content" | grep "^description:" | sed 's/description: *//')

  # Generate English README
  cat > "$skill_dir/README.md" <<EOF
# $name

> $desc

## Installation

This skill is part of [GAIA CORP-OS](https://github.com/Gaia-eats/gaia-os-skills).

\`\`\`bash
# Skills are auto-discovered from ~/.openclaw/skills/
# Just clone or copy the directory:
cp -r $name ~/.openclaw/skills/
\`\`\`

## Usage

See [SKILL.md](SKILL.md) for full documentation.

## Version

$version — Last updated $(date +%Y-%m-%d)

## License

MIT
EOF

  # Generate Chinese README
  cat > "$skill_dir/README.zh-CN.md" <<EOF
# $name

> $desc

## 安装

此技能是 [GAIA CORP-OS](https://github.com/Gaia-eats/gaia-os-skills) 的一部分。

\`\`\`bash
# 技能从 ~/.openclaw/skills/ 自动发现
# 只需克隆或复制目录：
cp -r $name ~/.openclaw/skills/
\`\`\`

## 使用方法

完整文档请参阅 [SKILL.md](SKILL.md)。

## 版本

$version — 最后更新 $(date +%Y-%m-%d)

## 许可证

MIT
EOF

  info "README" "Generated: README.md + README.zh-CN.md"
}

# ─── PUBLISH COMMAND ───────────────────────────────────────────────────
cmd_publish() {
  local skill="" message=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skill) skill="$2"; shift 2 ;;
      --message) message="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$skill" ] && die "Missing --skill"

  local skill_dir="$SKILLS_DIR/$skill"
  [ ! -d "$skill_dir" ] && die "Skill not found: $skill_dir"

  # Step 1: Validate SKILL.md
  local skill_md="$skill_dir/SKILL.md"
  if [ ! -f "$skill_md" ]; then
    die "No SKILL.md in $skill_dir"
  fi

  # Basic validation
  if ! head -1 "$skill_md" | grep -q "^---"; then
    error "SKILL.md missing YAML frontmatter"
  fi

  if ! grep -q "^name:" "$skill_md"; then
    error "SKILL.md missing 'name:' field"
  fi

  info "VALIDATE" "SKILL.md OK"

  # Step 2: Sync symlinks
  if [ -d "$CLAUDE_SKILLS" ]; then
    local symlink="$CLAUDE_SKILLS/$skill"
    if [ ! -e "$symlink" ]; then
      ln -sf "$skill_dir" "$symlink"
      info "SYMLINK" "$symlink → $skill_dir"
    fi
  fi

  # Step 3: Git commit
  if [ -z "$message" ]; then
    message="feat($skill): auto-crystallized skill"
  fi

  cd "$GITHUB_REPO"
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git add "$skill/" 2>/dev/null || true
    if git diff --cached --quiet 2>/dev/null; then
      info "GIT" "No changes to commit"
    else
      git commit -m "$message" 2>&1 | tail -1
      info "GIT" "Committed: $message"

      # Push
      if git remote -v | grep -q "origin"; then
        git push origin HEAD 2>&1 | tail -2
        info "GIT" "Pushed to origin"
      else
        info "GIT" "No remote — commit only (push manually)"
      fi
    fi
  else
    info "GIT" "Not a git repo — skipping commit"
  fi
}

# ─── CRYSTALLIZE COMMAND (FULL PIPELINE) ───────────────────────────────
cmd_crystallize() {
  local name="" description="" scope="tool-execution" agents="" script=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      --description) description="$2"; shift 2 ;;
      --scope) scope="$2"; shift 2 ;;
      --agents) agents="$2"; shift 2 ;;
      --script) script="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$name" ] && die "Missing --name"

  info "CRYSTALLIZE" "Full pipeline for: $name"

  # Step 1: Create or import
  if [ -n "$script" ] && [ -f "$script" ]; then
    cmd_from_script --script "$script" --name "$name"
  elif [ -n "$description" ]; then
    cmd_create --name "$name" --description "$description" --scope "$scope" ${agents:+--agents "$agents"}
  fi

  # Step 2: Generate README
  cmd_readme --skill "$name"

  # Step 3: Publish
  cmd_publish --skill "$name" --message "feat($name): auto-crystallized — $description"

  info "DONE" "Skill $name crystallized and published"
}

# ─── SCAN COMMAND ──────────────────────────────────────────────────────
cmd_scan() {
  info "SCAN" "Looking for crystallizable patterns..."

  # Check for scripts in workspace that aren't skills yet
  local found=0

  echo "=== Scripts not yet skills ==="
  while IFS= read -r script; do
    local basename
    basename=$(basename "$script" .sh)
    if [ ! -d "$SKILLS_DIR/$basename" ]; then
      echo "  $script → could become skill: $basename"
      found=$((found + 1))
    fi
  done < <(find "$OPENCLAW_DIR/workspace/scripts" -name "*.sh" -type f 2>/dev/null | head -20)

  echo ""
  echo "=== Recent KNOWLEDGE-SYNC entries (potential skills) ==="
  local ksync="$OPENCLAW_DIR/workspace-taoz/KNOWLEDGE-SYNC.md"
  if [ -f "$ksync" ]; then
    grep "^##" "$ksync" | tail -10 | while read -r line; do
      echo "  $line"
    done
  fi

  echo ""
  info "SCAN" "Found $found potential crystallizable scripts"
}

# ─── USAGE ──────────────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
skill-crystallize.sh — Auto-turn workflows into reusable skills

COMMANDS:
  create       Create new skill from description
  from-script  Import existing script as skill
  readme       Generate bilingual README (EN + CN)
  publish      Validate + symlink + git commit + push
  crystallize  Full pipeline (create + readme + publish)
  scan         Find crystallizable patterns

EXAMPLES:
  skill-crystallize.sh create --name my-skill --description "Does cool things"
  skill-crystallize.sh from-script --script ./my-script.sh --name my-skill
  skill-crystallize.sh readme --skill my-skill
  skill-crystallize.sh publish --skill my-skill
  skill-crystallize.sh crystallize --name my-skill --description "Cool things" --scope tool-execution
  skill-crystallize.sh scan
EOF
}

# ─── MAIN ───────────────────────────────────────────────────────────────
main() {
  mkdir -p "$(dirname "$LOG_FILE")"

  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    create) cmd_create "$@" ;;
    from-script|from_script) cmd_from_script "$@" ;;
    readme) cmd_readme "$@" ;;
    publish) cmd_publish "$@" ;;
    crystallize) cmd_crystallize "$@" ;;
    scan) cmd_scan "$@" ;;
    help|--help|-h) usage ;;
    *) error "Unknown command: $cmd"; usage; exit 1 ;;
  esac
}

main "$@"
