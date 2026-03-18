#!/bin/bash
# ══════════════════════════════════════════════════════════════
# Zennith OS — One-Command Setup
# Run this on any MacBook to join the team.
#
# Usage: curl -sL https://raw.githubusercontent.com/jennwoei316/zennith-skills/main/setup.sh | bash
#    or: bash setup.sh
# ══════════════════════════════════════════════════════════════

set -euo pipefail

REPO="https://github.com/jennwoei316/zennith-skills.git"
TARGET="$HOME/.openclaw"
CLAUDE_SKILLS="$HOME/.claude/skills"
BACKUP_DIR="$HOME/.openclaw-backup-$(date +%Y%m%d%H%M%S)"

echo ""
echo "  ╔══════════════════════════════════╗"
echo "  ║   Zennith OS — Team Setup        ║"
echo "  ╚══════════════════════════════════╝"
echo ""

# ── Check git
if ! command -v git &>/dev/null; then
  echo "ERROR: git not installed. Install with: xcode-select --install"
  exit 1
fi

# ── Handle existing ~/.openclaw
if [ -d "$TARGET" ]; then
  echo "Found existing ~/.openclaw — backing up to $BACKUP_DIR"
  mv "$TARGET" "$BACKUP_DIR"
  echo "  Backed up."
fi

# ── Clone
echo ""
echo "Cloning Zennith OS..."
git clone "$REPO" "$TARGET"
echo "  Cloned to $TARGET"

# ── Restore local files from backup (if any)
if [ -d "$BACKUP_DIR" ]; then
  echo ""
  echo "Restoring local files from backup..."

  # API keys / config
  if [ -f "$BACKUP_DIR/openclaw.json" ]; then
    cp "$BACKUP_DIR/openclaw.json" "$TARGET/openclaw.json"
    echo "  Restored openclaw.json (API keys)"
  fi

  # Secrets
  if [ -d "$BACKUP_DIR/secrets" ]; then
    cp -r "$BACKUP_DIR/secrets" "$TARGET/secrets"
    echo "  Restored secrets/"
  fi

  # Credentials
  if [ -d "$BACKUP_DIR/credentials" ]; then
    cp -r "$BACKUP_DIR/credentials" "$TARGET/credentials"
    echo "  Restored credentials/"
  fi

  # Media (images, videos, characters — large, local only)
  for dir in images videos characters output; do
    if [ -d "$BACKUP_DIR/workspace/data/$dir" ]; then
      mkdir -p "$TARGET/workspace/data"
      cp -r "$BACKUP_DIR/workspace/data/$dir" "$TARGET/workspace/data/$dir"
      echo "  Restored workspace/data/$dir/"
    fi
  done

  # Agent sessions & memory
  for ws in "$BACKUP_DIR"/workspace-*/sessions; do
    if [ -d "$ws" ]; then
      agent=$(basename "$(dirname "$ws")")
      mkdir -p "$TARGET/$agent"
      cp -r "$ws" "$TARGET/$agent/sessions"
      echo "  Restored $agent/sessions/"
    fi
  done
fi

# ── Link skills to Claude Code
echo ""
echo "Linking skills to Claude Code..."
mkdir -p "$CLAUDE_SKILLS"

linked=0
for skill_dir in "$TARGET/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  # Skip archive, symlinks, hidden dirs
  [[ "$skill_name" == _* ]] && continue
  [[ "$skill_name" == .* ]] && continue

  target_link="$CLAUDE_SKILLS/$skill_name"
  if [ -L "$target_link" ] || [ -d "$target_link" ]; then
    rm -rf "$target_link"
  fi
  ln -sf "$skill_dir" "$target_link"
  linked=$((linked + 1))
done
echo "  Linked $linked skills to ~/.claude/skills/"

# ── Git config (don't override global, just set repo-level)
echo ""
echo "Setting up git..."
cd "$TARGET"
git config pull.rebase false

# ── Summary
echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   Setup complete!                            ║"
echo "  ╠══════════════════════════════════════════════╣"
echo "  ║                                              ║"
echo "  ║   Repo:   ~/.openclaw/                       ║"
echo "  ║   Skills: $linked linked to Claude Code          ║"
echo "  ║   Branch: main                               ║"
echo "  ║                                              ║"
echo "  ║   Daily workflow:                            ║"
echo "  ║     cd ~/.openclaw && git pull               ║"
echo "  ║     ... work with Claude Code ...            ║"
echo "  ║     git add -A && git commit -m 'msg'        ║"
echo "  ║     git push                                 ║"
echo "  ║                                              ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

if [ -d "$BACKUP_DIR" ]; then
  echo "  Your old ~/.openclaw is at: $BACKUP_DIR"
  echo "  Delete it when you're sure everything works."
  echo ""
fi

echo "  Read PROJECT-STATE.md for full context."
echo "  Open Claude Code and start building."
echo ""
