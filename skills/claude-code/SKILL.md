---
name: claude-code
description: Invoke Claude Code (Opus 4.6) locally for red-team reviews and heavy coding tasks. Two modes — claude-code.review (read-only analysis) and claude-code.build (code execution).
metadata:
  openclaw:
    requires:
      bins: [claude]
    scope: tool-execution
    guardrails:
      - Never run claude-code.review AND claude-code.build on the same task simultaneously.
      - Review mode is strictly read-only — no file edits, no bash commands.
      - Build mode is sandboxed to the specified working directory only.
      - No budget limits (unlimited for review, unlimited for build)
      - Do not pass secrets, API keys, or credentials in the prompt text.
      - If Claude Code returns an error or empty output, report failure to the orchestrator — do not retry silently.
---

# Claude Code (GAIA CORP-OS Tool)

Local CLI bridge to Claude Code (Opus 4.6) running on this iMac.
Uses `claude -p` (print mode) for non-interactive, programmatic invocation.

**This is a TOOL, not a persona.** The orchestrator (Zenni Prime) calls it when needed and processes the output.

---

## Skill 1 — claude-code.review (Red Team Reviewer)

**When to use:**
- S1/S2 incidents requiring independent risk analysis
- Money/pricing/vendor decisions needing financial sanity check
- Major architecture changes needing failure mode analysis
- When Jenn explicitly requests a red-team review

**When NOT to use:**
- Routine tasks, S3 signals, or simple questions
- Tasks that Qwen workers can handle
- Already-approved decisions (don't second-guess after approval)

**Input:** A clear review brief describing what needs to be reviewed, including context, stakes, and what decision is being considered.

**Output (structured):**
1. **Risk Register** — key risks with severity (high/med/low) and likelihood
2. **Failure Modes** — what could go wrong, worst-case scenarios
3. **Cost/ROI Critique** — financial sanity check, unit economics, cashflow risk
4. **Counter-Options** — alternatives the team may not have considered
5. **Recommendation** — approve / reject / modify with conditions

**How to run:**

Option A — using the wrapper script:
```bash
bash ~/.openclaw/skills/claude-code/scripts/claude-code-runner.sh review "Review brief goes here" .
```

Option B — direct CLI (for custom system prompts or longer briefs):
```bash
claude -p \
  --model opus \
  --system-prompt "You are a Red Team Reviewer for GAIA CORP-OS. Output: (1) Risk Register, (2) Failure Modes, (3) Cost/ROI Critique, (4) Counter-Options, (5) Recommendation. Be concise and structured." \
  --tools "" \
  "YOUR REVIEW BRIEF HERE"
```

Option C — pipe a long brief from a file:
```bash
cat /path/to/brief.md | claude -p \
  --model opus \
  --tools "" \
  --system-prompt "You are a Red Team Reviewer for GAIA CORP-OS. Output: (1) Risk Register, (2) Failure Modes, (3) Cost/ROI Critique, (4) Counter-Options, (5) Recommendation."
```

**Constraints:**
- `--tools ""` disables all tools — review is pure analysis, no file access
- No budget limits
- Timeout: 120 seconds default

---

## Skill 2 — claude-code.build (Heavy Coder / Skill Writer)

**When to use:**
- Writing new OpenClaw skills
- Refactoring multi-file code changes
- Complex code generation requiring file reads + edits
- Running tests and returning build proof
- Tool integrations requiring multiple steps

**When NOT to use:**
- Simple scripts or one-off transforms (use Qwen worker)
- Drafting docs or SOPs (use Qwen worker)
- Visual/UI tasks (orchestrator handles these natively)

**Input:** A clear build task with:
- What to build/change
- Acceptance criteria (what "done" looks like)
- Working directory path

**Output (structured):**
1. **Result** — what was built/changed (1-3 lines)
2. **Proof** — build logs, test output, or code snippets proving it works
3. **What changed** — list of files created/modified
4. **Learning** — 1 line on what to improve next time

**How to run:**

Option A — using the wrapper script:
```bash
bash ~/.openclaw/skills/claude-code/scripts/claude-code-runner.sh build "Build task description here" /path/to/project
```

Option B — direct CLI:
```bash
claude -p \
  --model opus \
  --system-prompt "You are a Skill Builder for GAIA CORP-OS. Write clean, tested code. Return: (1) Result summary, (2) Build/test proof, (3) Files changed, (4) One-line learning." \
  --allowedTools "Bash,Edit,Read,Write,Glob,Grep" \
  --add-dir /path/to/project \
  "YOUR BUILD TASK HERE"
```

**Constraints:**
- `--allowedTools` limits to safe coding tools only (no Task, no WebFetch)
- `--add-dir` restricts file access to the specified project directory
- No budget limits
- Timeout: 300 seconds for build tasks

---

## Safety Defaults

| Setting | Review | Build |
|---------|--------|-------|
| Tools | None (read-only) | Bash, Edit, Read, Write, Glob, Grep |
| Budget cap | None (unlimited) | None (unlimited) |
| Timeout | 120s | 300s |
| File access | None | Scoped to --add-dir |
| Model | Opus 4.6 | Opus 4.6 |

---

## Error Handling

- **Claude Code not found:** Ensure `claude` is on PATH (`which claude`). Install via `claude install`.
- **Auth error:** Run `claude setup-token` to re-authenticate.
- **Timeout:** Increase with `--timeout` flag or simplify the task.
- **Budget exceeded:** Task stops mid-stream. Break into smaller subtasks.
- **Empty output:** Report failure to orchestrator. Do not retry the same prompt — rephrase or escalate.

---

## Skill 3 — claude-code.dispatch (Agent-Dispatched Tasks)

**When to use:**
- Other agents dispatch engineering tasks to Taoz via `dispatch.sh`
- Zenni routes WhatsApp engineering requests to Taoz
- Link digester routes YouTube URLs to Taoz for `/learn-youtube` pipeline

**How it works:**
1. Agent calls `dispatch.sh zenni taoz request "TASK" build`
2. dispatch.sh invokes `claude-code-runner.sh dispatch "TASK" FROM_AGENT ROOM`
3. Task is always queued to `~/.openclaw/workspace/taoz-inbox.jsonl`
4. Simple tasks auto-run via `claude -p` (180s timeout, $1 budget)
5. Complex tasks (refactor, debug, investigate, >500 chars) stay queued for interactive session
6. Results post back to the originating room

**How to run:**
```bash
bash ~/.openclaw/skills/claude-code/scripts/claude-code-runner.sh dispatch "Fix the CSS on the dashboard" zenni build
```

**Inbox management:**
```bash
bash ~/.openclaw/skills/claude-code/scripts/taoz-inbox.sh list    # Show pending
bash ~/.openclaw/skills/claude-code/scripts/taoz-inbox.sh peek    # Next task details
bash ~/.openclaw/skills/claude-code/scripts/taoz-inbox.sh done ID # Mark completed
```

---

## Skill 4 — WhatsApp Bridges

### Forward Bridge (Claude Code → Rooms)
- Script: `cc-bridge.sh` (cron every 5 min)
- Reads Claude Code transcripts → posts activity summaries to build room
- Significant activity (>5 tool uses) also posted to exec room

### Reverse Bridge (Rooms → WhatsApp)
- Script: `wa-reverse-bridge.sh` (cron every 2 min)
- Scans rooms for messages with `"to":"jenn"` or `type:"taoz-result"`
- Creates `[WA-RELAY]` entries in exec room for Zenni to forward via WhatsApp
- Capped at 5 relays per run to prevent spam

---

## Definition of Done

A claude-code invocation is complete when:
- Output contains all required sections (risk register for review, result+proof for build)
- No errors or warnings in stderr
- Orchestrator has processed and filed the output
