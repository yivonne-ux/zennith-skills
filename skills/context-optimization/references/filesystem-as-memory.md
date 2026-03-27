# Filesystem-as-Memory

The filesystem is unlimited context. Write large outputs to files; return compact references.

## Pattern A: Tool Output Offloading

```python
def handle_tool_output(output: str, tool_name: str) -> str:
    if len(output) < 2000:
        return output
    path = f"scratch/{tool_name}_{timestamp}.txt"
    write_file(path, output)
    summary = extract_summary(output, max_tokens=200)
    return f"[Output saved to {path}. Summary: {summary}]"
```

~100 tokens in context. Full output accessible via `grep` or `read_file` with line ranges.

## Pattern B: Plan Persistence

Write plans to files. Re-read at the start of each turn after context refresh.

```yaml
# scratch/current_plan.yaml
objective: "Refactor authentication module"
status: in_progress
steps:
  - id: 1
    description: "Audit current auth endpoints"
    status: completed
  - id: 2
    description: "Design new token validation flow"
    status: in_progress
```

## Pattern C: Sub-Agent Communication

Route findings through filesystem, not message chains. Each agent writes to its own workspace directory. Coordinator reads directly -- no "game of telephone" degradation.

```
workspace/
  agents/
    research_agent/findings.md
    code_agent/changes.md
  coordinator/synthesis.md
```

## Pattern D: Scratch Cleanup

Scratch directories grow unbounded. Implement retention:
- Age-based: delete files older than session duration
- Count-based: keep last N files per tool
- Run cleanup at session boundaries

## GAIA OS Canonical Paths

| What | Where |
|------|-------|
| Scratch files | `~/.openclaw/workspace-{id}/scratch/` |
| Plans | `~/.openclaw/workspace-{id}/scratch/plans/` |
| Agent workspaces | `~/.openclaw/workspace-{id}/` |
| Room logs | `~/.openclaw/workspace/rooms/` |
| Build logs | `~/.openclaw/workspace/rooms/logs/` |
