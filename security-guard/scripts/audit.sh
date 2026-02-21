#!/usr/bin/env bash
# security-guard/scripts/audit.sh — Automated vulnerability scanner

set -uo pipefail

PROJECT_DIR="${1:-.}"
REPORT_FILE="/tmp/security-audit-$(date +%s).json"
LOG_FILE="$HOME/.openclaw/workspace/corp-os/security-log.jsonl"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"

mkdir -p "$(dirname "$LOG_FILE")"

cd "$PROJECT_DIR" || {
  echo "ERROR: Cannot access $PROJECT_DIR"
  exit 1
}

echo "🔒 Security Guard — Audit Started"
echo "   Project: $(pwd)"
echo "   Time: $(date)"

# Run npm audit
if ! npm audit --json > "$REPORT_FILE" 2>/dev/null; then
  AUDIT_EXIT=$?
  echo "   npm audit completed (exit: $AUDIT_EXIT)"
else
  echo "   npm audit completed"
fi

# Parse results with Node.js
node << NODEOF
const fs = require('fs');
const path = require('path');

try {
  const data = JSON.parse(fs.readFileSync('$REPORT_FILE', 'utf8'));
  const vulns = data.vulnerabilities || {};
  const metadata = data.metadata || {};
  
  const bySeverity = { critical: [], high: [], moderate: [], low: [], info: [] };
  let fixableCount = 0;
  
  for (const [name, info] of Object.entries(vulns)) {
    const sev = info.severity || 'info';
    bySeverity[sev].push({ name, ...info });
    if (info.fixAvailable) fixableCount++;
  }
  
  console.log('');
  console.log('📊 Vulnerability Summary:');
  console.log('   Critical: ' + bySeverity.critical.length);
  console.log('   High:     ' + bySeverity.high.length);
  console.log('   Moderate: ' + bySeverity.moderate.length);
  console.log('   Low:      ' + bySeverity.low.length);
  console.log('   Fixable:  ' + fixableCount);
  
  // Log to security log
  const logEntry = {
    ts: Date.now(),
    type: 'audit',
    project: path.basename('$PROJECT_DIR'),
    vulnerabilities: {
      critical: bySeverity.critical.length,
      high: bySeverity.high.length,
      moderate: bySeverity.moderate.length,
      low: bySeverity.low.length
    },
    fixable: fixableCount,
    requiresHuman: bySeverity.critical.length > 0 || bySeverity.high.length > 0
  };
  
  fs.appendFileSync('$LOG_FILE', JSON.stringify(logEntry) + '\n');
  
  // Write summary for other scripts
  fs.writeFileSync('/tmp/audit-summary.json', JSON.stringify({
    critical: bySeverity.critical.length,
    high: bySeverity.high.length,
    moderate: bySeverity.moderate.length,
    low: bySeverity.low.length,
    fixable: fixableCount,
    details: bySeverity
  }, null, 2));
  
  // Exit with count of critical/high for automation
  process.exit(bySeverity.critical.length * 10 + bySeverity.high.length);
  
} catch (err) {
  console.error('   ERROR parsing audit:', err.message);
  process.exit(255);
}
NODEOF

exit $?
