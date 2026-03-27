# Dispatch Templates & Room Protocols

## Universal Brief Format

```
Agent: [AGENT_NAME]
Task: [Clear, specific description of what to do]
Context: [Why this is needed, any relevant background]
Acceptance Criteria:
  - [Criterion 1 — specific and measurable]
  - [Criterion 2]
  - [Criterion 3]
Output: Post results to [room] / return inline
Deadline: [ASAP / EOD / specific time]
Budget: [$X max spend if applicable]
```

## Scout Dispatch Template

```bash
# Via sessions_spawn (preferred for tracked tasks):
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "scout" \
  "TASK DESCRIPTION HERE" \
  "scout-TASK_SLUG"

# Direct (for fire-and-forget):
openclaw agent --agent scout --message "TASK DESCRIPTION"
```

**Example tasks:**
```bash
dispatch.sh "scout" "Ping https://gaiaos.com and report if up or down. Post result to exec room." "scout-health-check"
dispatch.sh "scout" "cd /path/to/repo && git add -A && git commit -m 'chore: update config' && git push. Report status." "scout-git-push"
dispatch.sh "scout" "Read ~/.openclaw/workspace/active-tasks.md and return its contents." "scout-read-file"
```

## Taoz Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "taoz" \
  "BUILD BRIEF: [what to build]

  Context: [relevant background]

  Requirements:
  - [req 1]
  - [req 2]

  Location: [where to put the output]
  Language/Stack: [tech details]

  Acceptance: [how to verify it works]
  Budget: $1.00" \
  "taoz-BUILD_SLUG"
```

## Scout Research Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "scout" \
  "RESEARCH BRIEF:

  Topic: [what to research]
  Scope: [how deep, which sources]
  Output format: [structured data / summary / bullet list]
  Key questions to answer:
  - [question 1]
  - [question 2]

  Post findings to exec room when done." \
  "scout-RESEARCH_SLUG"
```

## Dreami Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "dreami" \
  "CREATIVE BRIEF:

  What: [type of content — captions / EDM / campaign concept / etc]
  Brand: [brand name and voice notes]
  Audience: [who this is for]
  Goal: [what we want them to feel/do]
  Tone: [playful / professional / bold / warm / etc]
  Platform: [where this will appear]
  Deliverables:
  - [deliverable 1]
  - [deliverable 2]

  Reference/inspiration: [any examples or direction]
  Post drafts to creative room." \
  "dreami-CREATIVE_SLUG"
```

## Dreami Visual/Ads Dispatch Template

```bash
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "dreami" \
  "VISUAL BRIEF:

  What: [image gen / social post / visual direction / ad optimization]
  Brand: [brand name]
  Style: [mood, aesthetic, references]
  Dimensions: [1:1 / 9:16 / 16:9]
  Text overlay: [yes/no, copy to include]
  Image model: gemini-3-pro-image-preview (NanoBanana)

  Output: Save to brands/[brand]/output/ and report path.
  Platform: [Instagram / TikTok / website]

  Note: Changes >RM 500 impact → flag for Jenn approval" \
  "dreami-VISUAL_SLUG"
```

## Using dispatch.sh

```bash
# Full usage
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "<agent_id>" \           # scout | taoz | dreami | main
  "<task_brief>" \         # Full task description (quoted)
  "<label>" \              # Human-readable label for tracking
  [thinking_level] \       # Optional: low | medium | high (default: medium)
  [timeout_seconds]        # Optional: default 300

# Examples
bash dispatch.sh "scout" "Check if gaiaos.com is live" "scout-healthcheck"
bash dispatch.sh "taoz" "Build skill: orchestrate-v2" "taoz-skill-build" "medium" 600
bash dispatch.sh "scout" "Research vegan protein brands MY" "scout-vegan-research"
```

**What it does automatically:**
1. Maps agent → correct model
2. Labels the session for tracking
3. Logs dispatch to `~/.openclaw/logs/dispatch-log.jsonl`
4. Returns the session ID for tracking
5. Result is auto-announced back when subagent completes

## Tracking Dispatched Tasks

```bash
# Check active dispatches
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh list

# Check specific task
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh status <label>

# Log task outcome
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh done \
  "<label>" \
  "<success|fail|partial>" \
  "<one-line result summary>"

# View recent dispatch history
tail -20 ~/.openclaw/logs/dispatch-log.jsonl | python3 -m json.tool
```

## Emergency Override Rules

If the auto-router and decision tree conflict:
1. **Trust SOUL.md rules** over router scores (SOUL.md = locked by Jenn)
2. **Cheapest capable agent wins** when scores are close (<10% difference)
3. **When in doubt → Scout first**, escalate if they fail
4. **Never override "simple task = Scout" rule** to give work to Zenni

## File Conventions

```
~/.openclaw/logs/
  dispatch-log.jsonl       ← all dispatches ever made
  dispatch-active.jsonl    ← currently running tasks

~/.openclaw/skills/orchestrate-v2/
  SKILL.md                 ← this file
  scripts/
    dispatch.sh            ← main dispatch wrapper
    track.sh               ← track task status
    classify.sh            ← quick classifier (wraps route-task.py)
```
