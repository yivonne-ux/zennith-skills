#!/bin/bash
# comprehensive-test.sh — Test all systems until they work
# Run this to verify everything is functioning

set -e

echo "🚀 COMPREHENSIVE SYSTEM TEST"
echo "==========================="
echo ""

# Test 1: Message Logging
echo "📋 TEST 1: Message Logging System"
bash ~/.openclaw/skills/message-logger/scripts/message-logger.sh "test-source" "Test message content" '{"test": true}'
echo ""

# Test 2: Message Search
echo "📋 TEST 2: Message Search System"
bash ~/.openclaw/skills/message-logger/scripts/message-search.sh "Test message" --all
echo ""

# Test 3: OpenClaw Gateway
echo "📋 TEST 3: OpenClaw Gateway Status"
bash ~/.openclaw/skills/test-framework/scripts/test-framework.sh "openclaw-gateway" "openclaw status | head -5" "running"
echo ""

# Test 4: Model availability (OpenRouter)
echo "📋 TEST 4: Model Configuration"
if grep -q "gpt-4o" ~/.openclaw/openclaw.json; then
  echo "✓ GPT-4o configured via OpenRouter"
else
  echo "✗ GPT-4o not found in config"
fi

if grep -q "gemini-2.5-pro" ~/.openclaw/openclaw.json; then
  echo "✓ Gemini 2.5 Pro configured"
else
  echo "✗ Gemini 2.5 Pro not found in config"
fi
echo ""

# Test 5: Claude Code availability
echo "📋 TEST 5: Claude Code Availability"
if command -v claude &>/dev/null; then
  echo "✓ Claude Code installed: $(claude --version 2>/dev/null || echo 'version unknown')"
else
  echo "✗ Claude Code not found on PATH"
fi
echo ""

# Test 6: Obsidian vault created
echo "📋 TEST 6: Obsidian Vault"
if [[ -d "$HOME/.openclaw/workspace/obsidian-messages" ]]; then
  echo "✓ Obsidian vault created"
  ls -la "$HOME/.openclaw/workspace/obsidian-messages" 2>/dev/null | head -5
else
  echo "✗ Obsidian vault not found (will be created on first log)"
fi
echo ""

# Test 7: Vector DB
echo "📋 TEST 7: Vector Database"
if [[ -f "$HOME/.openclaw/workspace/vector-messages.db" ]]; then
  echo "✓ Vector DB exists"
  sqlite3 "$HOME/.openclaw/workspace/vector-messages.db" "SELECT COUNT(*) as total_messages FROM messages;" 2>/dev/null || echo "  (empty or new)"
else
  echo "✗ Vector DB not found (will be created on first log)"
fi
echo ""

echo "==========================="
echo "✅ COMPREHENSIVE TEST COMPLETE"
echo ""
echo "Next steps:"
echo "1. Add GOOGLE_API_KEY to ~/.openclaw/.env for Gemini"
echo "2. Restart OpenClaw to load new model config"
echo "3. Run: openclaw gateway restart"
