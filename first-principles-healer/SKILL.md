---
name: first-principles-healer
version: "1.0.0"
description: Self-improving error resolution system using first principles. Analyzes errors, creates playbooks, compounds knowledge, and auto-heals known issues.
metadata:
  openclaw:
    scope: infrastructure
    guardrails:
      - Never delete user data during healing
      - Always backup before modifying config/code
      - Max budget per unknown error escalation: $2.00
      - Max 3 Claude Code escalations per hour
      - All learning must be logged to feedback room
---

# First Principles Healer — Self-Improving Error Resolution

## Purpose

Most error handling is reactive: see error → fix error → forget. This skill is **proactive and compounding**:

1. **Taxonomize** errors by first principles (root cause, not symptoms)
2. **Playbook** fixes with verification steps
3. **Learn** from every fix and improve playbooks
4. **Compound** knowledge into an error database
5. **Meta-heal** — the skill improves itself

## First Principles Error Taxonomy

All errors reduce to 6 root causes:

| Category | First Principle | Examples |
|----------|----------------|----------|
| **NATIVE** | Compiled binary incompatibility | better-sqlite3, bcrypt, node-sass |
| **NETWORK** | Connectivity/timeout issues | API failures, DNS, SSL |
| **AUTH** | Credential/permission failures | Token expiry, 401/403 errors |
| **CONFIG** | Configuration state mismatch | Missing env vars, wrong paths |
| **RESOURCE** | Resource exhaustion | Disk full, memory OOM, FD limits |
| **CODE** | Logic/runtime errors | TypeError, null pointer, race conditions |

## Architecture

```
Error Detected
      ↓
[1] Classify → Match against error-db.json patterns
      ↓
  Match? ──Yes──→ [2] Load Playbook → [3] Execute Fix → [4] Verify
      ↓ No                                      ↓
  [5] Escalate to Claude Code                  ↓
      ↓                                    Success?
  [6] Create Playbook from fix ────────Yes────→ [7] Update error-db
      ↓ No
  [8] Log learning, alert human
```

## File Structure

```
~/.openclaw/skills/first-principles-healer/
├── SKILL.md                          # This file
├── scripts/
│   └── healer.sh                     # Main healing orchestrator
├── playbooks/
│   ├── native-module-failure.md      # Compiled binary issues
│   ├── network-timeout.md            # Connectivity issues
│   ├── permission-denied.md          # Access/auth issues
│   ├── config-error.md               # Configuration issues
│   ├── resource-exhaustion.md        # Disk/memory/FD limits
│   └── code-runtime-error.md         # Logic/runtime issues
├── error-db.json                     # Error pattern database
├── healing-log.jsonl                 # All healing attempts
└── meta/
    └── self-heal.sh                  # Healer healing itself
```

## Error Database Schema (error-db.json)

```json
{
  "version": "1.0.0",
  "patterns": [
    {
      "id": "native-sqlite-node25",
      "category": "NATIVE",
      "signatures": [
        "better-sqlite3",
        "node-gyp.*rebuild",
        "gyp ERR",
        "binding.gyp not found"
      ],
      "playbook": "native-module-failure",
      "first_seen": "2026-02-12",
      "last_seen": "2026-02-12",
      "fix_count": 0,
      "success_rate": 0.0,
      "auto_fixable": true
    }
  ],
  "stats": {
    "total_errors": 0,
    "auto_fixed": 0,
    "escalated": 0,
    "learned": 0
  }
}
```

## Integration with CORP-OS

### Cron Schedule
```json
{
  "id": "first-principles-healer",
  "schedule": "*/5 * * * *",
  "command": "bash ~/.openclaw/skills/first-principles-healer/scripts/healer.sh",
  "description": "First-principles error detection and healing"
}
```

### Room Integration
- **feedback** — All healing activity logged
- **build** — Playbook creation and updates
- **townhall** — New error types and systemic issues

## Usage

### Manual Invocation
```bash
# Scan and heal recent errors
bash ~/.openclaw/skills/first-principles-healer/scripts/healer.sh

# Verbose mode
bash ~/.openclaw/skills/first-principles-healer/scripts/healer.sh --verbose

# Force escalation (even if pattern matches)
bash ~/.openclaw/skills/first-principles-healer/scripts/healer.sh --escalate
```

### Adding New Error Patterns
Edit `error-db.json` and add a pattern object:

```json
{
  "id": "unique-id",
  "category": "NATIVE|NETWORK|AUTH|CONFIG|RESOURCE|CODE",
  "signatures": ["regex", "string fragments"],
  "playbook": "playbook-filename-without-md",
  "first_seen": "YYYY-MM-DD",
  "auto_fixable": true|false
}
```

Then create the playbook in `playbooks/{playbook}.md`.

## Meta-Healing

The healer can heal itself:

1. If `healer.sh` has errors → `meta/self-heal.sh` repairs it
2. If playbooks are corrupted → recreate from git or Claude Code
3. If error-db is corrupted → rebuild from healing-log.jsonl

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation with 6 error categories
- First entry: better-sqlite3 native module failure on Node 25
- Integration with auto-failover + auto-heal infrastructure
