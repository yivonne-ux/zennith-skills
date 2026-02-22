#!/bin/bash
# Rigour Gate Runner — GAIA CORP-OS
# Usage: bash gate.sh <file_or_dir>

TARGET=${1:-.}
PASS=true
REPORT=""

check_file() {
  local file=$1
  local ext="${file##*.}"
  
  # Gate 1: Syntax
  case $ext in
    js|mjs)
      if node --check "$file" 2>/dev/null; then
        REPORT+="  ✅ Syntax OK: $file\n"
      else
        REPORT+="  ❌ Syntax FAIL: $file\n"
        PASS=false
      fi
      ;;
    py)
      if python3 -m py_compile "$file" 2>/dev/null; then
        REPORT+="  ✅ Syntax OK: $file\n"
      else
        REPORT+="  ❌ Syntax FAIL: $file\n"
        PASS=false
      fi
      ;;
    sh)
      if bash -n "$file" 2>/dev/null; then
        REPORT+="  ✅ Syntax OK: $file\n"
      else
        REPORT+="  ❌ Syntax FAIL: $file\n"
        PASS=false
      fi
      ;;
    json)
      if python3 -m json.tool "$file" > /dev/null 2>&1; then
        REPORT+="  ✅ JSON valid: $file\n"
      else
        REPORT+="  ❌ JSON invalid: $file\n"
        PASS=false
      fi
      ;;
  esac

  # Gate 4: Security scan
  if grep -qE "(api_key|password|secret)\s*=\s*['\"][^'\"]{8,}|tvly-|sk-proj-|Bearer [A-Za-z]" "$file" 2>/dev/null; then
    REPORT+="  ⚠️  Possible secret in: $file — review manually\n"
    PASS=false
  fi
  if grep -qE "rm -rf /|chmod 777|curl.*\| sh|eval \(" "$file" 2>/dev/null; then
    REPORT+="  ⚠️  Dangerous command in: $file — review manually\n"
  fi
}

echo "🔒 RIGOUR GATE RUNNER"
echo "Target: $TARGET"
echo "---"

if [ -f "$TARGET" ]; then
  check_file "$TARGET"
elif [ -d "$TARGET" ]; then
  find "$TARGET" -type f \( -name "*.js" -o -name "*.mjs" -o -name "*.py" -o -name "*.sh" -o -name "*.json" \) | while read f; do
    check_file "$f"
  done
fi

echo -e "$REPORT"
if [ "$PASS" = true ]; then
  echo "🟢 OVERALL: PASS — safe to ship"
  exit 0
else
  echo "🔴 OVERALL: FAIL — fix issues before shipping"
  exit 1
fi
