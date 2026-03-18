---
name: knowledge-transfer
version: "1.0.0"
description: >
  Protocol for transferring Claude Code learnings into OpenClaw-executable skills.
  Ensures agents can independently reproduce what Claude Code figured out.
metadata:
  openclaw:
    scope: orchestration
    guardrails:
      - Every Claude Code session that produces operational knowledge MUST crystallize
      - Skills must be agent-executable, not just documentation
      - Include gotchas, failure modes, and proven prompts — not just happy path
      - Update classify.sh routing for new skills
    agents: [taoz, scout]
---

# Knowledge Transfer — Claude Code → OpenClaw Agents

## The Problem

Claude Code learns things during sessions:
- Prompt patterns that work/fail
- API gotchas and workarounds
- Decision logic (which ref to pick, which model to use)
- Micro-details that make quality difference

But this knowledge DIES when the session ends unless it's crystallized.
OpenClaw agents (Dreami, Scout, etc.) can't access Claude Code's memory files.

## The Solution: 4-Layer Knowledge Transfer

### Layer 1: SKILL.md (Agent Instructions)
**What:** Step-by-step operational instructions any agent can follow.
**Where:** `~/.openclaw/skills/{skill-name}/SKILL.md`
**Who reads it:** Any OpenClaw agent assigned to this skill domain.
**Format:** YAML frontmatter + markdown with explicit steps, decision trees, templates.

**CRITICAL RULES for SKILL.md:**
- Write for an agent, not a human — be EXPLICIT, not suggestive
- Include exact commands with all flags
- Include decision trees with IF/THEN, not "use your judgment"
- Include proven prompt templates (copy-paste ready)
- Include gotchas with exact error messages and fixes
- Include QA criteria with pass/fail thresholds
- Tag which agents should use this skill in frontmatter

### Layer 2: learnings.jsonl (Compounding Log)
**What:** Structured log of every attempt — what worked, what failed, why.
**Where:** `~/.openclaw/skills/{skill-name}/learnings.jsonl`
**Who reads it:** compound-learning digest (nightly), agents on skill load.
**Format:** One JSON object per line.

```json
{
  "date": "2026-03-12",
  "action": "what was attempted",
  "result": "PASS|FAIL|PARTIAL",
  "score": 8,
  "notes": "why it worked or failed",
  "gotcha": "named gotcha if applicable",
  "prompt_used": "exact prompt",
  "fix_applied": "what fixed it"
}
```

### Layer 3: classify.sh Routing (Discovery)
**What:** Route user/agent requests to the right skill automatically.
**Where:** `~/.openclaw/skills/orchestrate-v2/scripts/classify.sh`
**How:** Add keywords that trigger the skill.

```bash
# Example: route "pair luna with body refs" → character-body-pairing skill
*body*pair*|*face*body*|*character*fashion*)
  echo "SCRIPT|character-body-pairing|..."
  ;;
```

Without this, agents will never DISCOVER the skill exists.

### Layer 4: KNOWLEDGE-SYNC.md (Bridge Summary)
**What:** Human-readable summary for agents that says "new skill available."
**Where:** `~/.openclaw/workspace-taoz/KNOWLEDGE-SYNC.md`
**Who reads it:** All OpenClaw agents on session spawn.

Add entry like:
```markdown
## New Skill: character-body-pairing (2026-03-12)
- Pairs face refs with body/fashion refs for full-body lifestyle images
- Uses nanobanana-gen.sh with dual --ref-image
- 5 documented gotchas (hair override, content refusal, brand injection, two faces, style seed)
- 4 proven prompt templates with success rates
- Agent: Dreami to execute, Taoz to troubleshoot
```

---

## When to Trigger Knowledge Transfer

### AUTOMATIC (after every Claude Code session):
1. Did I learn a new technique? → Create/update SKILL.md
2. Did I discover a gotcha? → Add to learnings.jsonl + SKILL.md gotchas
3. Did I write a prompt that worked? → Add to SKILL.md templates
4. Did I build a new workflow? → Full new skill creation

### Checklist (run before ending session):
- [ ] New learnings captured in `learnings.jsonl`?
- [ ] SKILL.md updated with any new gotchas or templates?
- [ ] classify.sh updated if new keywords needed?
- [ ] KNOWLEDGE-SYNC.md updated with summary?
- [ ] Skill symlinked to `~/.claude/skills/` via sync-skills.sh?

---

## Quality Criteria for Skills

A skill is only useful if an agent can execute it WITHOUT asking for help.

### Test: "Could Dreami do this alone?"
Read the SKILL.md as if you're Dreami (creative director, uses Gemini CLI).
Can you:
1. Understand WHEN to use this skill? (trigger conditions clear)
2. Follow the steps WITHOUT any external context? (no assumed knowledge)
3. Make decisions at branch points? (decision trees, not "use judgment")
4. Know what success looks like? (QA criteria defined)
5. Handle failures? (gotchas with fixes documented)

If any answer is NO → the skill needs more detail.

### Anti-Patterns (skills that DON'T transfer):
- "Use good prompts" → Which prompts? Copy-paste examples needed.
- "Pick the right reference" → What makes it right? Decision tree needed.
- "Adjust if it doesn't look good" → What specifically to adjust? Fixes needed.
- "The model sometimes fails" → When? What error? What's the workaround?

### Good Patterns (skills that DO transfer):
- "If hair color from face ref is unusual (silver, platinum, red), add DISTINCTIVE before the color in prompt"
- "If Gemini refuses with content_policy error, replace 'black and white photograph' with 'documentary style portrait, film grain texture'"
- "Always set --model pro when using dual ref images. Flash loses face consistency."

---

## Skill Anatomy (Template)

```markdown
---
name: skill-name
version: "1.0.0"
description: One line
metadata:
  openclaw:
    scope: creative|orchestration|ops
    agents: [who uses this]
    tools_required: [what CLIs/APIs needed]
    learned_from: "source session/date"
---

# Skill Name — What It Does

## Purpose (1-2 sentences)
## When to Use (trigger conditions)

## Step-by-Step Workflow
### Step 1: ...
### Step 2: ...
(Include exact commands, decision trees, templates)

## Gotchas & Hard-Won Learnings
### Gotcha #1: Name
**Problem:** ...
**Fix:** ...

## Proven Templates
### Template 1: Name
\`\`\`
Exact copy-paste prompt/command
\`\`\`
**Success rate:** X/Y | **Notes:**

## QA Criteria
| Check | Pass | Fail |

## Batch/Automation Pattern
(How to run at scale)

## Compounding
(How to log learnings for improvement)
```

---

## Integration with Existing Systems

| System | Role in Knowledge Transfer |
|--------|---------------------------|
| `skill-crystallize` | Auto-generates skill scaffolding from session notes |
| `knowledge-compound` | Nightly digest of learnings.jsonl across all skills |
| `classify.sh` | Routes requests to skills (discovery layer) |
| `KNOWLEDGE-SYNC.md` | Bridge file agents read on spawn |
| `sync-skills.sh` | Symlinks skills to Claude Code's skill directory |
| `compound-crystallize.sh` | Daily cron that reviews sessions and creates skills |

---

## Action Items for Taoz (Claude Code)

Every session, before closing:
1. `grep -r "learnings.jsonl" ~/.openclaw/skills/ | wc -l` — how many skills have learning logs?
2. Review any new gotchas discovered → update relevant SKILL.md
3. Update KNOWLEDGE-SYNC.md if any significant new capability was built
4. Run `bash ~/.openclaw/workspace/scripts/sync-skills.sh` to sync symlinks
