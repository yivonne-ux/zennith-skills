---
name: security-guard
version: "1.0.0"
description: Automated security vulnerability scanning, monitoring, and remediation for GAIA CORP-OS. Monitors npm packages, system security, and auto-applies fixes.
metadata:
  openclaw:
    scope: security
    guardrails:
      - Never commit package-lock.json changes without testing
      - Always backup before major version downgrades
      - Log all security actions to feedback room
      - Alert human for critical vulnerabilities
---

# Security Guard — Automated Vulnerability Management

## Purpose

Continuous security monitoring and automated remediation:
1. **Scan** — Regular npm audit scans
2. **Assess** — Classify severity and exploitability  
3. **Remediate** — Auto-apply safe fixes
4. **Alert** — Escalate critical issues
5. **Track** — Maintain vulnerability history

## Vulnerability Severity Levels

| Level | CVSS | Action | Auto-Fix | Human Alert |
|-------|------|--------|----------|-------------|
| CRITICAL | 9.0-10.0 | Immediate patch or downgrade | Yes | Immediate |
| HIGH | 7.0-8.9 | Patch within 24h | Yes | Daily digest |
| MODERATE | 4.0-6.9 | Patch within 7 days | With flag | Weekly |
| LOW | 0.1-3.9 | Patch next maintenance | No | Monthly |

## Architecture

```
npm audit / security scan
        ↓
[1] Parse vulnerabilities
        ↓
[2] Categorize by severity
        ↓
  Critical? ──Yes──→ [3a] Immediate fix attempt
        ↓ No              ↓ Success? ──No──→ Alert human
  High? ──Yes──→ [3b] Auto-fix if safe
        ↓ No              ↓
  Moderate? ──Yes──→ [3c] Queue for maintenance
        ↓ No
  [4] Log and track
        ↓
[5] Update security dashboard
```

## Scan Triggers

1. **Scheduled** — Daily at 06:00 MYT
2. **On deploy** — Before any deployment
3. **On install** — After npm install
4. **Manual** — Via `/security-audit` command

## Auto-Fix Strategies

### Strategy 1: npm audit fix
```bash
npm audit fix --dry-run  # Preview
npm audit fix            # Apply safe fixes
```

### Strategy 2: Package Update
```bash
npm update <package>     # Minor/patch updates
```

### Strategy 3: Downgrade (Major Version)
```bash
npm install <package>@<safe-version>
```
**Requires**: Human approval for production

### Strategy 4: Replace Package
```bash
npm uninstall <vulnerable>
npm install <alternative>
```

## Implementation

### File: `~/.openclaw/skills/security-guard/scripts/audit.sh`

```bash
#!/usr/bin/env bash
# security-guard audit runner

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR" || exit 1

# Run audit
echo "=== Security Audit: $(date) ===" 
npm audit --json > /tmp/audit-$$.json 2>/dev/null

# Parse and categorize
node << 'NODE'
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('/tmp/audit-$$.json', 'utf8'));

const vulns = data.vulnerabilities || {};
const bySeverity = { critical: [], high: [], moderate: [], low: [], info: [] };

for (const [name, info] of Object.entries(vulns)) {
  const sev = info.severity || 'info';
  bySeverity[sev].push({ name, ...info });
}

console.log('CRITICAL:', bySeverity.critical.length);
console.log('HIGH:', bySeverity.high.length);
console.log('MODERATE:', bySeverity.moderate.length);
console.log('LOW:', bySeverity.low.length);

// Exit with count of critical/high
process.exit(bySeverity.critical.length + bySeverity.high.length);
NODE

exit $?
```

### File: `~/.openclaw/skills/security-guard/scripts/remediate.sh`

```bash
#!/usr/bin/env bash
# Auto-remediation based on severity

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR" || exit 1

# Check for auto-fixable issues
if npm audit fix --dry-run 2>&1 | grep -q "fixed"; then
  echo "Applying npm audit fix..."
  npm audit fix
fi

# Check remaining high/critical
HIGH_COUNT=$(npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities.high // 0')
CRIT_COUNT=$(npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities.critical // 0')

if [ "$CRIT_COUNT" -gt 0 ]; then
  echo "CRITICAL: $CRIT_COUNT vulnerabilities remain - manual intervention required"
  exit 2
fi

if [ "$HIGH_COUNT" -gt 0 ]; then
  echo "HIGH: $HIGH_COUNT vulnerabilities remain - queued for maintenance"
  exit 1
fi

echo "All high/critical vulnerabilities resolved"
exit 0
```

## Integration

### Cron Job
```json
{
  "id": "security-daily-audit",
  "schedule": "0 6 * * *",
  "command": "bash ~/.openclaw/skills/security-guard/scripts/audit.sh ~/.openclaw/workspace/apps/boss-dashboard",
  "description": "Daily security vulnerability scan"
}
```

### Room Logging
```javascript
// Log to feedback room
queue.emit(queue.TOPICS.ALERT, {
  type: 'security_audit',
  severity: 'high',
  vulnerabilities: auditResults,
  action: 'auto_fix_applied'
});
```

## Alert Templates

### Critical Alert (Immediate)
```
🚨 SECURITY ALERT — CRITICAL VULNERABILITIES DETECTED

Package: <name>
Severity: CRITICAL (<CVSS>)
Exploit: <yes/no/unknown>
Fix: <available/not available>

Auto-fix attempted: <success/failed>
Manual action required: <yes/no>

Run: npm audit for details
```

### High Alert (Daily Digest)
```
⚠️ SECURITY SUMMARY — High Severity Vulnerabilities

Projects scanned: <N>
New vulnerabilities: <N>
Auto-fixed: <N>
Pending human review: <N>

Top concerns:
1. <package> — <severity> — <brief>
2. ...

Recommended actions: <list>
```

## Security Dashboard

Track in `~/.openclaw/workspace/corp-os/security-log.jsonl`:
```json
{
  "ts": 1707734400000,
  "type": "audit",
  "project": "boss-dashboard",
  "vulnerabilities": { "critical": 0, "high": 5, "moderate": 0 },
  "autoFixed": 0,
  "requiresHuman": true
}
```

## Prevention

1. **Pin versions** — Use exact versions in package.json
2. **Lock files** — Always commit package-lock.json
3. **CI/CD gates** — Block deploy on critical vulnerabilities
4. **Dependency minimalism** — Fewer deps = smaller attack surface

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial: automated npm audit scanning
- Auto-remediation for safe fixes
- Critical vulnerability alerting
- Security dashboard tracking
