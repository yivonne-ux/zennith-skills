---
name: skill-creator
description: "When the user wants to create a new skill, generate a SKILL.md, automate skill creation, turn a process into a skill, or says 'create a skill', 'make a skill', 'new skill', 'skill-creator', 'turn this into a skill', 'skillify'."
agents:
  - taoz
---

# Skill Creator — Meta-Skill for Auto-Generating SKILL.md Files

Turns any process, workflow, or capability into a properly structured GAIA OS skill. Handles the full lifecycle: gathering requirements, generating the SKILL.md, testing with subagents, iterating based on eval results, and packaging into the skills directory with symlinks.

## When to Use

- Creating a new skill from scratch
- Converting a workflow or process into a reusable skill
- Turning a successful Claude Code session into a repeatable skill
- Generating SKILL.md files from verbal descriptions
- Quality-checking existing skills for structure and trigger accuracy

## GAIA OS Skill Format

Every skill in this system follows the same structure:

```
~/.openclaw/skills/{skill-name}/
  SKILL.md              # Required — main skill file
  scripts/              # Optional — executable helpers
  references/           # Optional — heavy docs loaded on demand
  assets/               # Optional — templates, icons, fonts
```

Symlink: `~/.claude/skills/{skill-name}` -> `~/.openclaw/skills/{skill-name}`

## Procedure

### Step 1 — Gather Process Description

Interview the user to capture:

| Question | Purpose |
|----------|---------|
| What should this skill enable an agent to do? | Core capability |
| When should it trigger? What would a user say? | Trigger phrases for description field |
| What agents should run this? | Agent assignment (taoz, scout, dreami, main) |
| What's the expected output? | Success criteria |
| What tools or scripts does it need? | Dependencies |
| Are there edge cases or things to avoid? | Guardrails |
| Is there an existing workflow to capture? | If yes, extract steps from conversation history |

If the current conversation already contains a workflow the user wants to capture (e.g., "turn this into a skill"), extract answers from the conversation history first. The user confirms before proceeding.

---

### Step 2 — Generate SKILL.md

Build the skill file with these components:

#### YAML Frontmatter (Required)

```yaml
---
name: {skill-name}
description: "{ONLY trigger conditions — start with 'When the user...' or list trigger phrases. NEVER summarize the workflow here.}"
agents:
  - {agent1}
  - {agent2}
---
```

**Critical rules for the description field:**
- ONLY trigger conditions — when should this skill activate?
- Include specific user phrases, keywords, and contexts
- NEVER summarize the skill's process or workflow in the description
- Reason: if the description summarizes the workflow, agents may follow the description shortcut instead of reading the full skill body. This was validated by Anthropic's own skill-creator research.
- Keep under 500 characters
- Be slightly "pushy" — include adjacent triggers the user might not think of

**Bad**: "Builds landing pages with hero, benefits, social proof, and CTA sections."
**Good**: "When the user wants to build a landing page, sales page, offer page, or says 'landing page', 'sales copy', 'offer page', 'convert visitors'."

#### Markdown Body

Structure the body with these sections:

```markdown
# {Skill Name} — {One-Line Description}

{2-3 sentence overview of what this skill does and its core principle.}

## When to Use
- {Bullet list of use cases and symptoms}
- {When NOT to use — helps avoid false triggers}

## Procedure
### Step 1 — {Step Name} ({Agent})
{Instructions, tables, templates}
### Step 2 — ...
{Continue for all steps}

## Output Summary
{Table of deliverables and file locations}

## Related Skills
- {skill-name} — {When to use it instead or alongside}
```

#### Style Guidelines

- Use imperative form ("Generate the report" not "The report is generated")
- Explain WHY behind instructions — agents are smart, context helps more than rigid MUSTs
- Include one excellent example per step (not multi-language dilution)
- Use tables for structured data (inputs, outputs, fields)
- Keep under 350 lines total
- If content exceeds 350 lines, move heavy reference to `references/` subdirectory

---

### Step 3 — Add Procedure Details

For each step in the procedure:

1. **Agent role**: Which agent runs this step and why
2. **Inputs**: What the step needs (from user or previous steps)
3. **Process**: Clear instructions the agent follows
4. **Output**: What this step produces (file, data, decision)
5. **Validation**: How to verify the step succeeded

Include:
- **Examples**: Show input/output for at least one step so agents understand the expected format
- **Related skills**: Cross-reference existing skills that complement this one (use skill name only, never @-link to avoid force-loading context)
- **Edge cases**: What happens if the user gives incomplete input? What's the fallback?

---

### Step 4 — Eval Loop

Test the skill by running it with and without the SKILL.md loaded.

#### Without Skill (Baseline)

Spawn a subagent with a realistic test prompt but NO access to the skill:

```
Execute this task:
- Task: {realistic user prompt that should trigger this skill}
- Save outputs to: ~/.openclaw/workspace/data/skill-evals/{skill-name}/baseline/
```

Document what the agent does wrong, misses, or handles poorly.

#### With Skill

Spawn a subagent with the same prompt AND the skill loaded:

```
Execute this task:
- Skill path: ~/.openclaw/skills/{skill-name}/SKILL.md
- Task: {same prompt}
- Save outputs to: ~/.openclaw/workspace/data/skill-evals/{skill-name}/with-skill/
```

#### Grading

Compare the two outputs:

| Dimension | Baseline | With Skill | Pass? |
|-----------|----------|------------|-------|
| Correct structure | ... | ... | Y/N |
| Complete output | ... | ... | Y/N |
| Right agent used | ... | ... | Y/N |
| Trigger accuracy | ... | ... | Y/N |
| Edge case handling | ... | ... | Y/N |

#### Automated Scoring Rubric

| Dimension | Score 0 | Score 1 | Weight |
|-----------|---------|---------|--------|
| Correct trigger | Agent ignores skill when it should fire | Agent invokes skill on trigger phrases | 25% |
| Procedure followed | Agent freestyles, ignores steps | Agent follows steps in order | 25% |
| Output quality | Generic, no brand context | Brand-specific, actionable | 25% |
| Edge cases | Fails on unusual inputs | Handles gracefully | 25% |

Overall pass threshold: 75%. If baseline already scores 75%+, the skill may not be worth shipping — the model already handles this well.

If any dimension fails, proceed to Step 5.

---

### Step 5 — Iterate

Based on eval results:

1. **Identify failures**: What specific instructions did the agent misinterpret or ignore?
2. **Diagnose cause**: Is it unclear wording, missing context, or wrong agent assignment?
3. **Fix loopholes**: Add explicit counters for observed rationalizations
4. **Rewrite, don't patch**: If more than 3 fixes are needed, rewrite the section rather than layering patches
5. **Re-run eval**: Test again with the same prompts — verify fixes work without breaking passing tests

**Iteration principles** (from Anthropic's skill-creator):
- Generalize from feedback — don't overfit to test cases
- Keep the prompt lean — remove instructions that aren't pulling weight
- Explain the why — rigid MUST/NEVER rules are a yellow flag; explain reasoning instead
- Look for repeated work — if every test run writes the same helper script, bundle it in `scripts/`

Repeat Steps 4-5 until all dimensions pass.

---

### Step 6 — Package and Deploy

Once the skill passes eval:

#### Save

```bash
# Skill file is already at the right path
ls ~/.openclaw/skills/{skill-name}/SKILL.md
```

#### Symlink

```bash
ln -sf ~/.openclaw/skills/{skill-name} ~/.claude/skills/{skill-name}
```

#### Verify symlink

```bash
ls -la ~/.claude/skills/{skill-name}
```

#### Git commit

```bash
cd ~/.openclaw && git add skills/{skill-name}/ && git commit -m "Add {skill-name} skill"
```

#### Announce

Tell the user:
- Skill is live at `~/.openclaw/skills/{skill-name}/SKILL.md`
- Symlinked to `~/.claude/skills/{skill-name}`
- Trigger phrases: {list from description}
- Agents: {list from frontmatter}

---

## Output Summary

| Deliverable | Location |
|-------------|----------|
| SKILL.md | `~/.openclaw/skills/{skill-name}/SKILL.md` |
| Symlink | `~/.claude/skills/{skill-name}` |
| Eval results | `~/.openclaw/workspace/data/skill-evals/{skill-name}/` |
| Scripts (if any) | `~/.openclaw/skills/{skill-name}/scripts/` |
| References (if any) | `~/.openclaw/skills/{skill-name}/references/` |

## Quality Checklist

Before shipping any skill, verify:

- [ ] YAML frontmatter has `name`, `description`, and `agents` fields
- [ ] Description contains ONLY trigger conditions (no workflow summary)
- [ ] Description is under 500 characters
- [ ] Skill body is under 350 lines
- [ ] Each procedure step has agent role, inputs, process, output
- [ ] At least one example included
- [ ] Related skills listed (no @-links)
- [ ] Eval run completed (baseline vs with-skill)
- [ ] Symlink created to `~/.claude/skills/`
- [ ] Git committed

## Versioning

When updating an existing skill, increment the version in frontmatter. Keep a CHANGELOG.md in the skill directory if changes are significant.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Description summarizes workflow | Rewrite to only list trigger conditions |
| Too many MUST/NEVER/ALWAYS | Explain the reasoning instead |
| Skill over 500 lines | Move heavy reference to `references/` subdirectory |
| No eval run | Always test baseline vs with-skill before shipping |
| @-linking other skills | Use skill name only — @-links force-load context |
| Generic agent assignment | Assign specific agents with reasons |
| Missing "When NOT to use" | Add to prevent false triggers |

## Related Skills

- `rigour` — Run quality gate on any scripts bundled with the skill
- `skill-router` — The system that matches user queries to skills at runtime
- `knowledge-transfer` — For transferring Claude Code learnings into OpenClaw-executable skills
- `workflow-automation` — For registering the skill in the production chain
