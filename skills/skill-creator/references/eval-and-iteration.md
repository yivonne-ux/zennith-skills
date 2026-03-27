# Eval Loop & Iteration Guide

## Step 4 — Eval Loop

Test the skill by running it with and without the SKILL.md loaded.

### Without Skill (Baseline)

Spawn a subagent with a realistic test prompt but NO access to the skill:

```
Execute this task:
- Task: {realistic user prompt that should trigger this skill}
- Save outputs to: ~/.openclaw/workspace/data/skill-evals/{skill-name}/baseline/
```

Document what the agent does wrong, misses, or handles poorly.

### With Skill

Spawn a subagent with the same prompt AND the skill loaded:

```
Execute this task:
- Skill path: ~/.openclaw/skills/{skill-name}/SKILL.md
- Task: {same prompt}
- Save outputs to: ~/.openclaw/workspace/data/skill-evals/{skill-name}/with-skill/
```

### Grading

Compare the two outputs:

| Dimension | Baseline | With Skill | Pass? |
|-----------|----------|------------|-------|
| Correct structure | ... | ... | Y/N |
| Complete output | ... | ... | Y/N |
| Right agent used | ... | ... | Y/N |
| Trigger accuracy | ... | ... | Y/N |
| Edge case handling | ... | ... | Y/N |

### Automated Scoring Rubric

| Dimension | Score 0 | Score 1 | Weight |
|-----------|---------|---------|--------|
| Correct trigger | Agent ignores skill when it should fire | Agent invokes skill on trigger phrases | 25% |
| Procedure followed | Agent freestyles, ignores steps | Agent follows steps in order | 25% |
| Output quality | Generic, no brand context | Brand-specific, actionable | 25% |
| Edge cases | Fails on unusual inputs | Handles gracefully | 25% |

Overall pass threshold: 75%. If baseline already scores 75%+, the skill may not be worth shipping — the model already handles this well.

If any dimension fails, proceed to Step 5.

## Step 5 — Iterate

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
