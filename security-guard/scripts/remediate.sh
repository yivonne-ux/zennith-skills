#!/usr/bin/env bash
# security-guard/scripts/remediate.sh — Auto-remediation for vulnerabilities

set -uo pipefail

PROJECT_DIR="${1:-.}"
REPORT_FILE="/tmp/security-remediate-$(date +%s).log"
LOG_FILE="$HOME/.openclaw/workspace/corp-os/security-log.jsonl"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"

cd "$PROJECT_DIR" || exit 1

echo "🔧 Security Guard — Remediation Started"
echo "   Project: $(pwd)"
echo "   Time: $(date)"
echo ""

# Check for auto-fixable issues
echo "Checking for auto-fixable vulnerabilities..."

# Try npm audit fix --dry-run first
DRY_RUN=$(npm audit fix --dry-run 2>&1)

if echo "$DRY_RUN" | grep -q "fixed"; then
  echo "✓ Auto-fixes available"
  echo "Applying npm audit fix..."
  
  if npm audit fix 2>&1 | tee "$REPORT_FILE"; then
    echo ""
    echo "✅ Auto-fix applied successfully"
    
    # Log success
    node << 'NODEOF'
const fs = require('fs');
const logFile = process.env.LOG_FILE || `${process.env.HOME}/.openclaw/workspace/corp-os/security-log.jsonl`;
const entry = {
  ts: Date.now(),
  type: 'remediation',
  project: process.cwd().split('/').pop(),
  method: 'npm_audit_fix',
  success: true,
  autoFixed: true
};
fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
NODEOF
    
    # Post to room
    echo '{"ts":'$(date +%s)'000,"agent":"security-guard","room":"feedback","type":"security_fix","msg":"Auto-fixed vulnerabilities via npm audit fix"}' >> "$ROOMS_DIR/feedback.jsonl" 2>/dev/null || true
    
    exit 0
  else
    echo "⚠️ npm audit fix had issues - manual review needed"
    exit 1
  fi
else
  echo "ℹ️ No auto-fixable vulnerabilities found"
  echo "   Manual fixes may be required for remaining issues"
  
  # Show remaining high/critical
  npm audit --audit-level=high 2>&1 | head -30
  
  exit 2
fi
