#!/usr/bin/env bash
# claude-code-runner.sh — Wraps claude CLI for OpenClaw skill invocation
# Taoz = Claude Code CLI on Jenn's subscription ($0 per token)
# Usage: claude-code-runner.sh <review|code-review|build|dispatch|inbox> <prompt> [cwd/from] [budget/room]

set -euo pipefail

# Load env (cron-safe)
KEYFILE="$HOME/.openclaw/.env.keys"
if [ -f "$KEYFILE" ]; then
  set -a; source "$KEYFILE" 2>/dev/null || true; set +a
fi
# Note: Claude Max subscription doesn't need ANTHROPIC_API_KEY — CLI auth is separate
# Unset nesting guard — this script is always called from OpenClaw (non-Claude) context
unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT 2>/dev/null || true



MODE="${1:?Usage: claude-code-runner.sh <review|code-review|build|dispatch|inbox> <prompt> [cwd] [budget] [--model sonnet|opus|haiku]}"
PROMPT="${2:?Error: prompt is required}"
CWD="${3:-.}"
BUDGET="${4:-}"

# Parse --model flag from remaining args
CLI_MODEL=""
shift 4 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --model) shift; CLI_MODEL="${1:-}" ;;
  esac
  shift 2>/dev/null || true
done

# Set defaults based on mode
case "$MODE" in
  review)
    BUDGET="${BUDGET:-0.50}"
    echo "--- claude-code.review ---"
    echo "Budget: USD $BUDGET | Tools: none (read-only) | Model: opus"
    echo "---"
    env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT PATH="/Users/jennwoeiloh/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin" HOME="$HOME" claude -p --model opus --system-prompt "You are a Red Team Reviewer for GAIA CORP-OS. Analyze the request and output EXACTLY these sections: (1) Risk Register — key risks with severity and likelihood, (2) Failure Modes — what could go wrong, (3) Cost/ROI Critique — financial sanity check, (4) Counter-Options — alternatives considered, (5) Recommendation — approve / reject / modify with conditions. Be concise, structured, and direct." --tools "" "$PROMPT"
    echo ""
    echo "--- claude-code.review complete ---"
    ;;
  code-review)
    # Structured code review mode — checks bugs, security, OWASP, quality, error handling
    # Input: file path, git diff, or inline code via PROMPT
    # Can be called by Argus (QA) or any agent via exec
    BUDGET="${BUDGET:-0.50}"
    REVIEW_MODEL="${CLI_MODEL:-opus}"
    REVIEW_TARGET="$CWD"  # CWD param doubles as the file/dir to review

    echo "--- claude-code.code-review ---"
    echo "Budget: USD $BUDGET | Model: $REVIEW_MODEL | Target: $REVIEW_TARGET"
    echo "---"

    # Build the review input — support file path, git diff, or raw prompt
    REVIEW_INPUT=""
    if [ -f "$REVIEW_TARGET" ]; then
      # File path provided — read it
      REVIEW_INPUT="FILE: $REVIEW_TARGET
---
$(cat "$REVIEW_TARGET" 2>/dev/null | head -c 50000)"
    elif [ -d "$REVIEW_TARGET" ]; then
      # Directory — get git diff if available
      REVIEW_INPUT="DIRECTORY: $REVIEW_TARGET
--- git diff (staged + unstaged) ---
$(cd "$REVIEW_TARGET" && git diff HEAD 2>/dev/null | head -c 50000 || echo '(no git diff available)')"
    else
      # Raw prompt or diff passed directly
      REVIEW_INPUT="$PROMPT"
    fi

    REVIEW_PROMPT="Review the following code. Additional context from the requester: $PROMPT

$REVIEW_INPUT"

    REVIEW_RESULT=$(env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT \
      PATH="/Users/jennwoeiloh/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin" \
      HOME="$HOME" \
      claude -p \
        --model "$REVIEW_MODEL" \
        --permission-mode bypassPermissions \
        --output-format text \
        --system-prompt "You are a senior code reviewer for GAIA CORP-OS. Perform a thorough code review.

CHECK FOR:
1. **Bugs** — logic errors, off-by-one, null/undefined, race conditions, uninitialized vars
2. **Security (OWASP Top 10)** — injection (SQL/command/XSS), broken auth, sensitive data exposure, XXE, broken access control, security misconfiguration, insecure deserialization, known vulnerable components, insufficient logging
3. **Code Quality** — readability, naming, DRY violations, dead code, complexity, maintainability
4. **Unused Imports** — imports/requires that are never referenced
5. **Error Handling** — uncaught exceptions, missing try/catch, swallowed errors, missing validation
6. **Edge Cases** — empty inputs, boundary values, type coercion, encoding issues

OUTPUT FORMAT (strict — parseable):
---
VERDICT: PASS | FAIL | WARN
ISSUES_COUNT: <number>
CRITICAL: <number>
HIGH: <number>
MEDIUM: <number>
LOW: <number>

## Issues

### [CRITICAL|HIGH|MEDIUM|LOW] <short title>
- **File**: <path>:<line> (if applicable)
- **Category**: Bug | Security | Quality | Unused Import | Error Handling | Edge Case
- **Description**: <what is wrong>
- **Fix**: <how to fix it>

(repeat for each issue)

## Summary
<1-3 sentence overall assessment>
---

Rules:
- VERDICT is FAIL if any CRITICAL or HIGH issues exist
- VERDICT is WARN if only MEDIUM issues exist
- VERDICT is PASS if only LOW or no issues
- Be specific — cite line numbers, variable names, exact problems
- Do NOT pad with praise — only report real issues" \
        "$REVIEW_PROMPT" 2>&1) || true

    # Extract verdict for structured output
    VERDICT=$(echo "$REVIEW_RESULT" | grep -oE 'VERDICT: (PASS|FAIL|WARN)' | head -1 | awk '{print $2}')
    VERDICT="${VERDICT:-UNKNOWN}"
    ISSUES_COUNT=$(echo "$REVIEW_RESULT" | grep -oE 'ISSUES_COUNT: [0-9]+' | head -1 | awk '{print $2}')
    ISSUES_COUNT="${ISSUES_COUNT:-0}"

    echo "$REVIEW_RESULT"
    echo ""
    echo "--- claude-code.code-review complete ---"
    echo "{\"verdict\":\"$VERDICT\",\"issues\":$ISSUES_COUNT,\"model\":\"$REVIEW_MODEL\",\"target\":\"$REVIEW_TARGET\"}"
    ;;
  build)
    BUDGET="${BUDGET:-1.00}"
    echo "--- claude-code.build ---"
    echo "Budget: USD $BUDGET | Tools: Bash,Edit,Read,Write,Glob,Grep | Dir: $CWD | Model: opus"
    echo "---"
    env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT PATH="/Users/jennwoeiloh/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin" HOME="$HOME" claude -p --model opus --system-prompt "You are a Skill Builder for GAIA CORP-OS. Write clean, tested code. Return EXACTLY these sections: (1) Result — what was built/changed (1-3 lines), (2) Proof — build logs or test output, (3) What changed — list of files, (4) Learning — 1 line on what to improve next time." --allowedTools "Bash,Edit,Read,Write,Glob,Grep" --add-dir "$CWD" "$PROMPT"
    echo ""
    echo "--- claude-code.build complete ---"
    ;;
  dispatch)
    # Dispatch mode: receives tasks from OpenClaw agents via dispatch.sh
    # ALL tasks get executed via Claude Code CLI ($0 subscription — NOT API key)
    # No complexity gating — Claude Code handles everything
    unset ANTHROPIC_API_KEY 2>/dev/null || true  # Force CLI subscription auth
    FROM_AGENT="${CWD:-zenni}"  # Reuse CWD param for from_agent
    ROOM="${BUDGET:-build}"      # Reuse BUDGET param for room

    INBOX="$HOME/.openclaw/workspace/taoz-inbox.jsonl"
    ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
    RESULTS_DIR="$HOME/.openclaw/workspace/data/taoz-results"
    RUNNER_LOG="$HOME/.openclaw/logs/claude-code-runner.log"
    mkdir -p "$(dirname "$INBOX")" "$RESULTS_DIR"

    TASK_ID="taoz-$(date +%s)-$$"
    TS_EPOCH=$(date +%s)

    # Queue to inbox (audit trail)
    SAFE_MSG=$(printf '%s' "$PROMPT" | tr '\n' ' ' | sed 's/"/\\"/g' | head -c 2000)
    printf '{"id":"%s","ts":%s000,"from":"%s","room":"%s","status":"running","msg":"%s"}\n' \
      "$TASK_ID" "$TS_EPOCH" "$FROM_AGENT" "$ROOM" "$SAFE_MSG" >> "$INBOX"
    printf '[%s] Running task %s from %s via Claude Code CLI\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" "$FROM_AGENT" >> "$RUNNER_LOG" 2>/dev/null

    # Post acknowledgment to room
    printf '{"ts":%s000,"agent":"taoz","to":"%s","room":"%s","type":"taoz-ack","msg":"[Taoz] Task received (id=%s). Running via Claude Code CLI..."}\n' \
      "$TS_EPOCH" "$FROM_AGENT" "$ROOM" "$TASK_ID" >> "$ROOMS_DIR/${ROOM}.jsonl" 2>/dev/null

    # Emit build-start event for live dashboard monitor
    printf '{"ts":%s000,"agent":"taoz","room":"%s","type":"build-start","task_id":"%s","model":"%s","from":"%s","msg":"%s"}\n' \
      "$TS_EPOCH" "$ROOM" "$TASK_ID" "${CLI_MODEL:-sonnet}" "$FROM_AGENT" "$SAFE_MSG" >> "$ROOMS_DIR/${ROOM}.jsonl" 2>/dev/null

    # Run task via Claude Code CLI ($0 subscription — no API cost)
    RESULT_FILE="$RESULTS_DIR/${TASK_ID}.txt"

    # Inject accumulated knowledge into build context
    # KNOWLEDGE-SYNC.md = bridge between interactive Claude Code and spawned CLI
    KSYNC="$HOME/.openclaw/workspace-taoz/KNOWLEDGE-SYNC.md"
    KSYNC_EXCERPT=""
    if [ -f "$KSYNC" ]; then
      KSYNC_EXCERPT=$(head -c 50000 "$KSYNC" 2>/dev/null || echo "")
    fi

    BUILD_PROMPT="You are Taoz, the builder agent for GAIA CORP-OS. Execute this task dispatched from $FROM_AGENT:

$PROMPT

After completing, summarize what you did in 2-3 sentences.

## Accumulated Knowledge (from KNOWLEDGE-SYNC.md)
$KSYNC_EXCERPT"

    # Claude Max subscription — CLI auth stored in ~/.claude/
    # Don't use env -i (strips auth). Just set PATH explicitly.
    # Model selection: --model flag or default to sonnet
    DISPATCH_MODEL="${CLI_MODEL:-sonnet}"
    # Validate model — only allow subscription models
    case "$DISPATCH_MODEL" in
      sonnet|opus|haiku) ;; # Valid CLI subscription models ($0)
      *) DISPATCH_MODEL="sonnet" ;; # Unknown → safe default
    esac
    printf '[%s] Model: %s (from: %s)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$DISPATCH_MODEL" "${CLI_MODEL:-default}" >> "$RUNNER_LOG" 2>/dev/null

    # Agent Teams enabled for parallel sub-task execution
    # --add-dir ~/.openclaw grants filesystem access (does NOT auto-load CLAUDE.md)
    # CLAUDE.md loads via project dir: ~/.claude/projects/-Users-jennwoeiloh--openclaw/CLAUDE.md (symlinked)
    # Skills in ~/.claude/skills/ auto-load (symlinked from ~/.openclaw/skills/)
    # CWD must be ~/.openclaw so Claude Code loads the project CLAUDE.md + memory
    cd "$HOME/.openclaw" 2>/dev/null || true
    env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT \
    PATH="/Users/jennwoeiloh/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin" \
    HOME="$HOME" \
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 \
    claude -p \
      --model "$DISPATCH_MODEL" \
      --add-dir "$HOME/.openclaw" \
      --append-system-prompt "You are Taoz — GAIA OS's think agent and CTO. The quiet brain keeping the system alive. You see the full picture across all channels. Execute tasks efficiently. Be concise. Read relevant files before changes. Use Agent Teams for parallel sub-tasks.

IDENTITY & OBSESSIONS:
- Keep GAIA OS alive — the loop must never stop: ingest → route → produce → learn → repeat.
- Quality at speed — ship right. Rigour gates on every build. Regression on every change.
- Cost-aware — cheaper is better if quality holds. Keyword routing (\$0) before LLM routing. Free models before paid.
- Win condition: GAIA OS runs 24/7 producing content across 7 brands with zero human intervention for routine ops.

KEY RULES:
- Images: use nanobanana-gen.sh (NEVER raw Gemini API). Up to 14 refs. Tell prompt which ref is what.
- Videos: use video-gen.sh (Sora/Kling/Wan). Sora durations ONLY '4','8','12' (STRINGS not ints).
- Post-prod: use video-forge.sh. NEVER raw ffmpeg.
- Brand content: check brand DNA at ~/.openclaw/brands/{brand}/DNA.json first.
- Skills: check ~/.openclaw/skills/*/SKILL.md before building anything new.
- Routing: classify.sh is the ONLY place routing decisions live. 5 tiers: RELAY, LOOKUP, SCRIPT, CODE, DISPATCH.
- Config: openclaw.json is single source of truth. NEVER hardcode agent names/models.
- Read KNOWLEDGE-SYNC.md at ~/.openclaw/workspace-taoz/KNOWLEDGE-SYNC.md for accumulated learnings. Zenni (CEO) reads this first, then delegates to agents.
- Read SHARED-PROTOCOL.md at ~/.openclaw/workspace/SHARED-PROTOCOL.md for team rules.
- Rigour gate: bash ~/.openclaw/skills/rigour/scripts/gate.sh <file> before shipping code." \
      --allowedTools "Bash,Edit,Read,Write,Glob,Grep,Task" \
      --permission-mode bypassPermissions \
      --output-format text \
      "$BUILD_PROMPT" > "$RESULT_FILE" 2>&1 &

    BGPID=$!
    WAITED=0
    MAX_WAIT=600  # 10 minutes for builds
    LAST_PROGRESS=0
    while kill -0 "$BGPID" 2>/dev/null && [ "$WAITED" -lt "$MAX_WAIT" ]; do
      sleep 5
      WAITED=$((WAITED + 5))
      # Emit build-progress every 30s for live dashboard
      if [ $((WAITED - LAST_PROGRESS)) -ge 30 ]; then
        LAST_PROGRESS=$WAITED
        OUT_LINES=$(wc -l < "$RESULT_FILE" 2>/dev/null | tr -d ' ' || echo "0")
        OUT_BYTES=$(wc -c < "$RESULT_FILE" 2>/dev/null | tr -d ' ' || echo "0")
        printf '{"ts":%s000,"agent":"taoz","room":"%s","type":"build-progress","task_id":"%s","elapsed":%s,"output_lines":%s,"output_bytes":%s}\n' \
          "$(date +%s)" "$ROOM" "$TASK_ID" "$WAITED" "$OUT_LINES" "$OUT_BYTES" >> "$ROOMS_DIR/${ROOM}.jsonl" 2>/dev/null
      fi
    done
    BUILD_DURATION=$WAITED
    if kill -0 "$BGPID" 2>/dev/null; then
      kill "$BGPID" 2>/dev/null || true
      RESULT="[Taoz] Task timed out (${MAX_WAIT}s). Result may be partial — check $RESULT_FILE"
      printf '[%s] TIMEOUT task %s after %ss\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" "$MAX_WAIT" >> "$RUNNER_LOG" 2>/dev/null
      BUILD_STATUS="timeout"
    else
      RESULT=$(cat "$RESULT_FILE" 2>/dev/null | head -c 1500)
      [ -z "$RESULT" ] && RESULT="[Taoz] Task completed (no output captured)."
      printf '[%s] Completed task %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" >> "$RUNNER_LOG" 2>/dev/null
      BUILD_STATUS="completed"
    fi

    # Emit build-complete event for live dashboard
    printf '{"ts":%s000,"agent":"taoz","room":"%s","type":"build-complete","task_id":"%s","status":"%s","duration":%s,"model":"%s"}\n' \
      "$(date +%s)" "$ROOM" "$TASK_ID" "$BUILD_STATUS" "$BUILD_DURATION" "$DISPATCH_MODEL" >> "$ROOMS_DIR/${ROOM}.jsonl" 2>/dev/null

    # Update inbox + post result to room
    printf '{"id":"%s","ts":%s000,"status":"completed","result_file":"%s"}\n' \
      "$TASK_ID" "$(date +%s)" "$RESULT_FILE" >> "$INBOX"
    SAFE_RESULT=$(printf '%s' "$RESULT" | tr '\n' ' ' | sed 's/"/\\"/g' | head -c 1500)
    printf '{"ts":%s000,"agent":"taoz","to":"%s","room":"%s","type":"taoz-result","task_id":"%s","msg":"[Taoz] %s"}\n' \
      "$(date +%s)" "$FROM_AGENT" "$ROOM" "$TASK_ID" "$SAFE_RESULT" >> "$ROOMS_DIR/${ROOM}.jsonl" 2>/dev/null

    # Wake API — notify OpenClaw immediately (don't wait for heartbeat cycle)
    # Fires POST to gateway wake endpoint so Zenni/agents see result instantly
    GW_TOKEN="2a11e48d086d44a061b19b61fbcebabcbe30fd0c9f862a5f"
    curl -s -X POST "http://127.0.0.1:3001/api/cron/wake" \
      -H "Authorization: Bearer $GW_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"agentId\":\"taoz\",\"mode\":\"now\",\"reason\":\"task-complete:$TASK_ID\"}" \
      > /dev/null 2>&1 || true

    # Knowledge write-back to LanceDB memory — closes the knowledge loop
    # Zenni can auto-recall this in future sessions
    OPENCLAW_CLI="$HOME/local/bin/openclaw"
    if [ -x "$OPENCLAW_CLI" ]; then
      MEMORY_TEXT="[Taoz build ${TASK_ID}] Task from ${FROM_AGENT}: $(printf '%s' "$PROMPT" | head -c 200). Model: ${DISPATCH_MODEL}. Result: $(printf '%s' "$RESULT" | head -c 300)"
      "$OPENCLAW_CLI" memory store \
        --scope global \
        --text "$MEMORY_TEXT" \
        --tags "build,taoz,${FROM_AGENT},${DISPATCH_MODEL}" \
        2>/dev/null || true
      printf '[%s] Memory stored for task %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" >> "$RUNNER_LOG" 2>/dev/null
    fi

    # Feed compound learning loop — write to daily log
    TASK_COMPLETE_SH="$HOME/.openclaw/workspace/scripts/learning/task-complete.sh"
    if [ -f "$TASK_COMPLETE_SH" ]; then
      TASK_OUTCOME="success"
      echo "$RESULT" | grep -qiE '(timeout|error|fail|not found|crash)' && TASK_OUTCOME="fail"
      TASK_DESC=$(printf '%s' "$PROMPT" | tr '\n' ' ' | head -c 200)
      bash "$TASK_COMPLETE_SH" "taoz" "task-complete" "$TASK_DESC" "$TASK_OUTCOME" "" "$TS_EPOCH" > /dev/null 2>&1 || true
    fi

    # Compound learning — run immediately after every build (evolve always)
    # 1. Update KNOWLEDGE-SYNC.md with build result
    KSYNC="$HOME/.openclaw/workspace-taoz/KNOWLEDGE-SYNC.md"
    if [ -f "$KSYNC" ]; then
      printf '\n## Build %s (%s) — %s\n- Task: %s\n- Model: %s | Duration: %ss | Status: %s\n- Result: %s\n' \
        "$TASK_ID" "$(date '+%Y-%m-%d %H:%M')" "$TASK_OUTCOME" \
        "$(printf '%s' "$PROMPT" | head -c 150)" "$DISPATCH_MODEL" "$BUILD_DURATION" "$BUILD_STATUS" \
        "$(printf '%s' "$RESULT" | head -c 300 | tr '\n' ' ')" >> "$KSYNC" 2>/dev/null || true
      printf '[%s] KNOWLEDGE-SYNC updated for task %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" >> "$RUNNER_LOG" 2>/dev/null
    fi
    # 2. Sync learnings to rooms (so OpenClaw agents can see)
    SYNC_SCRIPT="$HOME/.openclaw/workspace/scripts/sync-claude-code-learnings.sh"
    if [ -f "$SYNC_SCRIPT" ]; then
      bash "$SYNC_SCRIPT" > /dev/null 2>&1 &
    fi
    # 3. Run compound digest if available (extract patterns, promote to skills)
    DIGEST_SCRIPT="$HOME/.openclaw/skills/knowledge-compound/scripts/digest.sh"
    if [ -f "$DIGEST_SCRIPT" ]; then
      bash "$DIGEST_SCRIPT" --quick > /dev/null 2>&1 &
    fi

    # 4. Log outcome for self-evolving classifier
    EVOLVE_SCRIPT="$HOME/.openclaw/skills/classify-evolve/scripts/classify-evolve.sh"
    if [ -f "$EVOLVE_SCRIPT" ]; then
      bash "$EVOLVE_SCRIPT" log \
        --task "$(printf '%s' "$PROMPT" | head -c 200)" \
        --agent "taoz" --tier "code" --model "$DISPATCH_MODEL" \
        --duration "$BUILD_DURATION" --status "$TASK_OUTCOME" --source "dispatch" \
        > /dev/null 2>&1 || true
      printf '[%s] Evolve outcome logged for task %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" >> "$RUNNER_LOG" 2>/dev/null

      # 4b. Routing self-check — verify classify.sh would have routed correctly
      bash "$EVOLVE_SCRIPT" verify \
        --task "$(printf '%s' "$PROMPT" | head -c 200)" \
        --dispatched-to "taoz" --tier "code" --outcome "$TASK_OUTCOME" \
        > /dev/null 2>&1 || true
      printf '[%s] Routing verify for task %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" >> "$RUNNER_LOG" 2>/dev/null
    fi

    # Auto-trigger regression via Claude Code (replaces Argus glm-5 subagent)
    # Runs bash directly — no LLM needed for test execution
    if [ "$TASK_OUTCOME" = "success" ]; then
      printf '[%s] Running regression for task %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" >> "$RUNNER_LOG" 2>/dev/null
      REGRESSION_RESULT=$(bash "$HOME/.openclaw/workspace/tests/regression/test-dispatch-routing.sh" 2>&1) || true
      printf '[%s] Regression: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$REGRESSION_RESULT" >> "$RUNNER_LOG" 2>/dev/null
      # Post regression result to build room
      SAFE_REGRESSION=$(printf '%s' "$REGRESSION_RESULT" | tr '\n' ' ' | head -c 200)
      printf '{"ts":%s000,"agent":"argus","room":"build","type":"regression","task_id":"%s","msg":"[Argus] %s"}\n' \
        "$(date +%s)" "$TASK_ID" "$SAFE_REGRESSION" >> "$ROOMS_DIR/build.jsonl" 2>/dev/null

      # Also trigger evolve cycle if enough outcomes accumulated (every 10 builds)
      OUTCOMES_FILE="$HOME/.openclaw/skills/classify-evolve/data/classify-outcomes.jsonl"
      if [ -f "$OUTCOMES_FILE" ]; then
        OUTCOME_COUNT=$(wc -l < "$OUTCOMES_FILE" | tr -d ' ')
        if [ "$((OUTCOME_COUNT % 10))" -eq 0 ] && [ "$OUTCOME_COUNT" -gt 0 ]; then
          printf '[%s] Triggering evolve cycle (%s outcomes)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$OUTCOME_COUNT" >> "$RUNNER_LOG" 2>/dev/null
          bash "$EVOLVE_SCRIPT" cycle >> "$RUNNER_LOG" 2>&1 &
        fi
      fi
    fi

    # 5. Post-build sync — keep Claude Code and OpenClaw aligned
    POST_BUILD_SYNC="$HOME/.openclaw/workspace/scripts/post-build-sync.sh"
    if [ -f "$POST_BUILD_SYNC" ]; then
      bash "$POST_BUILD_SYNC" --quick >> "$RUNNER_LOG" 2>&1 &
      printf '[%s] Post-build sync triggered\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$RUNNER_LOG" 2>/dev/null
    fi

    # Legacy: Keep Argus WebSocket trigger for e2e tests (broader than dispatch routing)
    if [ "$TASK_OUTCOME" = "success" ]; then
      node -e "
const WebSocket = require('ws');
const ws = new WebSocket('ws://127.0.0.1:18789', {
  headers: { 'x-openclaw-token': '2a11e48d086d44a061b19b61fbcebabcbe30fd0c9f862a5f' }
});
ws.on('open', () => {
  ws.send(JSON.stringify({
    type: 'agent.run',
    agentId: 'argus',
    message: '[AUTO-REGRESSION after Taoz build $TASK_ID] Taoz just completed a build. Run regression: bash ~/.openclaw/workspace/tests/regression/e2e-test.sh. Post PASS/FAIL to feedback room. Use memory_store to save results.',
    json: true
  }));
  setTimeout(() => { ws.close(); process.exit(0); }, 600000);
});
ws.on('message', (data) => {
  try {
    const msg = JSON.parse(data);
    if (msg.type === 'agent.run' && (msg.status === 'ok' || msg.status === 'error')) {
      ws.close();
      process.exit(0);
    }
  } catch (e) {}
});
ws.on('error', () => process.exit(1));
" > /dev/null 2>&1 &
      # Fire-and-forget — don't block on Argus
    fi

    echo "{\"status\":\"completed\",\"task_id\":\"$TASK_ID\"}"
    ;;
  inbox)
    # Quick inbox check mode
    INBOX="$HOME/.openclaw/workspace/taoz-inbox.jsonl"
    if [ ! -f "$INBOX" ]; then
      echo "No pending tasks."
      exit 0
    fi
    python3 -c "
import json
tasks = {}
with open('$INBOX') as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            e = json.loads(line)
            tid = e.get('id','')
            if not tid: continue
            if 'msg' in e: tasks[tid] = e
            elif e.get('status') == 'completed' and tid in tasks:
                tasks[tid]['status'] = 'completed'
        except: continue
pending = [v for v in tasks.values() if v.get('status') == 'pending']
if not pending:
    print('No pending tasks.')
else:
    for t in sorted(pending, key=lambda x: x.get('ts', 0)):
        print(f\"[{t['id']}] from {t.get('from','?')}: {t.get('msg','')[:120]}\")
    print(f'\\n{len(pending)} pending task(s)')
" 2>/dev/null
    ;;
  *)
    echo "ERROR: Unknown mode '$MODE'. Use 'review', 'code-review', 'build', 'dispatch', or 'inbox'."
    echo "Usage: claude-code-runner.sh <review|code-review|build|dispatch|inbox> <prompt> [cwd/from] [budget/room]"
    exit 1
    ;;
esac
