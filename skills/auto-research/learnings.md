# Auto-Research — Compounding Learnings

> This file captures meta-learnings across all auto-research runs.
> Updated manually or by agents after significant runs.
> These learnings inform future configs and criteria design.

## Meta-Patterns (Updated as discovered)

_No patterns discovered yet. This section grows as the system runs experiments._

### Template: How to Log a Meta-Pattern

```
### Pattern: [Short Name]
- **Discovered**: [Date] from [which config/run]
- **Observation**: [What was observed across multiple runs]
- **Implication**: [How this should change future configs or criteria]
- **Confidence**: [Low/Medium/High] based on [N] data points
```

## Config Design Learnings

_What makes a good auto-research config? Lessons learned._

## Criteria Design Learnings

_Which criteria produce the most useful signal? Which are too vague?_

## Model Performance Notes

_How different models perform as generators vs evaluators._

## 2026-03-22 — OpenClaw E2E Testing Session

### What Works
- classify.sh routes "auto-research" → taoz ✅
- dispatch.sh spawns agents correctly ✅  
- Agents receive task, write RECEIPT, produce output, write DONE ✅
- fast-iterate.sh works on both MacBook (claude CLI) and iMac (API) ✅
- auto-loop.sh works on both machines ✅

### What's Broken
- `exec` blocked by gateway approval policy even with "*" wildcard
- Agent falls back to manual generation (works but loses the script benefits)
- `timeout` command doesn't exist on macOS — use background+wait
- `openclaw` not in SSH PATH — must use full path `/Users/jennwoeiloh/local/bin/openclaw`
- `node` not in SSH PATH — must export PATH in dispatch.sh
- Gateway restart doesn't seem to reload exec-approvals.json

### Fixes Applied
- dispatch.sh: removed `timeout`, added full PATH, full openclaw path
- fast-iterate.sh + auto-loop.sh: claude CLI fallback (MacBook), temp file JSON payloads
- exec-approvals.json: all agents have "*" wildcard, skill scripts added to approved list

### Still Needs
- Fix exec approval system — agents need to actually run bash scripts
- The exec security model may need `"host": "local"` instead of `"host": "gateway"` 
- Or exec-approvals.json needs to be pushed via the gateway socket, not file
