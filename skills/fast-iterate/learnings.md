# Fast-Iterate — Compounding Learnings

> Meta-learnings from fast-iterate runs across all agents and brands.
> These patterns help refine criteria selection and round strategy.

## Prompt Evolution Patterns (Updated as discovered)

_No patterns discovered yet. This section grows as the system runs._

### Template: How to Log a Prompt Evolution Pattern

```
### Pattern: [Short Name]
- **Discovered**: [Date] from [task type]
- **Observation**: [What prompt changes consistently improved scores]
- **Implication**: [Default prompt additions for this task type]
- **Confidence**: [Low/Medium/High] based on [N] runs
```

## Criteria Effectiveness Notes

_Which criteria IDs produce the most useful differentiation between variants?_

## Round Strategy Notes

_How many rounds are optimal for different task types?_
_When does diminishing returns kick in?_

## Agent-Specific Notes

_How different agents (Dreami, Apollo, Hermes) use fast-iterate differently._

## Session Compound (Mar 18-25)
- Temp file JSON payloads: ALWAYS use for bash→LLM calls
- Claude CLI fallback: use `claude --print` on MacBook (/bin/zsh OAuth)
- OpenRouter for iMac agents (auto-detect from openclaw.json)
- NEVER Anthropic API key for loops (per-token cost)
- Auto-detect repo root: SCRIPT_DIR → REPO_DIR → SECRETS_DIR pattern
