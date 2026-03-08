# Gemini CLI — Creative Engine for GAIA CORP-OS

**Owner:** Dreami (primary), Iris, Hermes
**Cost:** $0 (Gemini CLI uses Google OAuth, free tier)
**Model:** Gemini 2.5 Pro (default via CLI)

## Purpose

Gemini CLI is wired as a **creative thinking engine** — the counterpart to Claude Code CLI (builder engine).

| Engine | CLI | Purpose | Owner |
|--------|-----|---------|-------|
| Claude Code | `claude-code-runner.sh` | Code, builds, infrastructure | Taoz |
| Gemini CLI | `gemini-runner.sh` | Creative ideation, copy, adaptation | Dreami/Iris/Hermes |

## Modes

```bash
# Creative content generation (copy, headlines, scripts)
bash ~/.openclaw/skills/gemini-cli/scripts/gemini-runner.sh creative \
  "Write 5 MOFU ad headlines for office workers" dreami creative --brand mirra

# Open-ended brainstorming with scoring
bash ~/.openclaw/skills/gemini-cli/scripts/gemini-runner.sh brainstorm \
  "10 viral hook ideas for bento health food" dreami creative --brand mirra

# Content adaptation (translate, reformat, channel-adapt)
bash ~/.openclaw/skills/gemini-cli/scripts/gemini-runner.sh adapt \
  "Adapt this IG caption for TikTok: [caption]" iris creative --brand mirra

# Full dispatch (inbox tracking, room posting, knowledge sync)
bash ~/.openclaw/skills/gemini-cli/scripts/gemini-runner.sh dispatch \
  "Generate full MOFU M2 ad set copy" hermes creative --brand mirra
```

## Context Loading

gemini-runner.sh automatically loads:
1. **GEMINI.md** — project context (via CWD = ~/.openclaw)
2. **Brand DNA** — `brands/{brand}/DNA.json` (injected into prompt)
3. **Campaign directions** — `brands/{brand}/campaigns/directions.json`
4. **Compound learnings** — via `resolve-learnings.py --brand`
5. **KNOWLEDGE-SYNC.md** — bridge from Claude Code builds

## Integration with OpenClaw

OpenClaw agents can invoke via `exec`:
```bash
exec bash ~/.openclaw/skills/gemini-cli/scripts/gemini-runner.sh creative "prompt" agent_id room --brand brand
```

Or via classify.sh SCRIPT tier (future):
```
SCRIPT:gemini_creative
CMD:bash ~/.openclaw/skills/gemini-cli/scripts/gemini-runner.sh creative "prompt" ...
```

## Output

Results stored at: `workspace/data/gemini-results/{task_id}.txt`
Inbox log: `workspace/gemini-inbox.jsonl`
Room posts: Automatic ack + result to specified room

## Compound Learning

Every gemini-runner task:
1. Writes to KNOWLEDGE-SYNC.md
2. Feeds task-complete.sh for daily learning log
3. Triggers digest.sh for pattern extraction
