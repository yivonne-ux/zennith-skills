---
name: rigour
description: >
  Quality gate protocol for all AI-generated code in GAIA CORP-OS. Mandatory step
  before any Claude Code output reaches production. Runs syntax check, lint,
  basic tests, and security scan. Taoz runs this on every build before reporting
  to Zenni. Inspired by the HN "Rigour" concept for AI code quality gates.
metadata:
  clawdbot:
    emoji: 🔒
    requires:
      bins: [node, python3]
    agents: [taoz]
agents:
  - taoz
---

# Rigour — Quality Gates for GAIA Code

**Purpose:** Every piece of AI-generated code passes through Rigour before it ships.
No exceptions. This is Taoz's mandatory final step before marking any build DONE.

---

## The Gate Checklist (Run in Order)

### Gate 1 — Syntax Check ✅
Does the file parse without errors?

```bash
# JavaScript/Node
node --check <file.js> && echo "✅ JS syntax OK" || echo "❌ Syntax error"

# Python
python3 -m py_compile <file.py> && echo "✅ Python syntax OK" || echo "❌ Syntax error"

# Shell script
bash -n <file.sh> && echo "✅ Bash syntax OK" || echo "❌ Syntax error"

# JSON
python3 -m json.tool <file.json> > /dev/null && echo "✅ JSON valid" || echo "❌ Invalid JSON"
```

### Gate 2 — Sanity Check ✅
Does the code do what it claims? Taoz must verify manually:
- [ ] Read the code — does the logic match the task?
- [ ] Are there hardcoded secrets, API keys, or paths? (Never ship these)
- [ ] Are there obvious infinite loops or missing error handlers?
- [ ] Does it handle empty input gracefully?

### Gate 3 — Smoke Test ✅
Does it run without crashing on basic input?

```bash
# For scripts — run with test input
echo "test" | node <script.js>
python3 <script.py> --help 2>&1 | head -5

# For skills — verify the SKILL.md exists and is valid YAML frontmatter
python3 -c "
import sys
content = open(sys.argv[1]).read()
if not content.startswith('---'):
    print('❌ Missing YAML frontmatter')
    sys.exit(1)
print('✅ SKILL.md structure OK')
" <path/to/SKILL.md>
```

### Gate 4 — Security Scan ✅
Quick check for common vulnerabilities:

```bash
# Check for hardcoded secrets (API keys, passwords, tokens)
grep -rn \
  -e "api_key\s*=\s*['\"][^'\"]\+" \
  -e "password\s*=\s*['\"][^'\"]\+" \
  -e "secret\s*=\s*['\"][^'\"]\+" \
  -e "tvly-\|sk-\|Bearer " \
  <file> && echo "⚠️ Possible hardcoded secret" || echo "✅ No hardcoded secrets"

# Check for dangerous shell commands
grep -n "rm -rf\|dd if\|chmod 777\|curl.*\| sh\|eval " <file> && \
  echo "⚠️ Dangerous command found — review manually" || echo "✅ No dangerous commands"
```

### Gate 5 — Dependency Check ✅
Are all imports/requires available?

```bash
# Node.js
node -e "require('./<module>')" 2>&1 | grep -v "^$" || echo "✅ Module loads OK"

# Python
~/.openclaw/venvs/rag-anything/bin/python3 -c "import <module>" 2>&1 || echo "❌ Missing dependency"

# Shell — check binaries
for cmd in jq python3 node curl; do
  which $cmd > /dev/null && echo "✅ $cmd found" || echo "❌ $cmd missing"
done
```

---

## Rigour Runner Script

Run all gates at once on a file or directory:

```bash
bash ~/.openclaw/skills/rigour/scripts/gate.sh <file_or_dir>
```

Output: PASS ✅ or FAIL ❌ with details on what failed.

---

## PASS / FAIL Criteria

| Result | Meaning | Action |
|--------|---------|--------|
| **PASS** | All 5 gates green | Ship it. Report to Zenni with proof. |
| **FAIL Gate 1** | Syntax broken | Fix syntax, re-run. Never ship broken syntax. |
| **FAIL Gate 2** | Logic looks wrong | Rewrite the problematic section. |
| **FAIL Gate 3** | Crashes on run | Debug crash, fix, re-run. |
| **FAIL Gate 4** | Security issue | Remove secret/dangerous code. Never ship. |
| **FAIL Gate 5** | Missing dependency | Add dependency or update install instructions. |

---

## Taoz Protocol: How to Use Rigour

After every Claude Code build session:

```
1. Identify all new/modified files
2. Run Gate 1 (syntax) on ALL files
3. Run Gate 2 (sanity) manually — read the code
4. Run Gate 3 (smoke test) on entry point
5. Run Gate 4 (security) on all files
6. Run Gate 5 (dependency) on main script
7. If ALL PASS → mark task done, report to Zenni with gate results
8. If ANY FAIL → fix, re-run Rigour, only ship on full PASS
```

Never report a build as "done" to Zenni without a Rigour PASS.

---

## Rigour Report Format

When reporting to Zenni after a Rigour pass:

```
🔒 RIGOUR REPORT — <task name>
Gate 1 Syntax:    ✅ PASS
Gate 2 Sanity:    ✅ PASS (reviewed manually)
Gate 3 Smoke:     ✅ PASS
Gate 4 Security:  ✅ PASS
Gate 5 Deps:      ✅ PASS
OVERALL: ✅ PASS — safe to ship
Files: <list of files checked>
```

---

## Why This Exists

AI agents (including Claude Code) produce code that looks right but:
- Has subtle logic bugs (Gate 2)
- Crashes on edge cases (Gate 3)
- Occasionally leaks secrets or uses unsafe patterns (Gate 4)
- Assumes packages that aren't installed (Gate 5)

Rigour adds the human-equivalent "does this actually work?" check before anything
touches production. Every build that skips Rigour is a liability.
