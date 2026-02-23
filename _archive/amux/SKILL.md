---
name: amux
description: >
  Parallel coding agent sessions via amux TUI. Run multiple Claude Code (or Codex/Gemini)
  instances simultaneously in isolated workspaces. 2-3x Taoz throughput for divergent
  coding tasks. Installed at ~/local/bin/amux (v0.0.14).
metadata:
  clawdbot:
    emoji: ⚡
    requires:
      bins: [amux, tmux]
    agents: [taoz]
---

# amux — Parallel Agent Multiplexer for Taoz

**Binary:** `~/local/bin/amux` (v0.0.14)
**GitHub:** https://github.com/andyrewlee/amux
**What it does:** Runs multiple Claude Code / Codex / Gemini agents in parallel, each in
its own workspace, with shared git context. No wrappers, no lock-in.

---

## Taoz Rule: When to Use Parallel vs Sequential

| Use Parallel (amux) | Use Sequential |
|---------------------|----------------|
| Building 2 independent skills | Skill B depends on Skill A output |
| Writing tests + writing code simultaneously | Debugging (need to see each step) |
| Research across multiple topics | Review/QA pass (needs full context) |
| Generating multiple creative variants | Fixing a specific bug |
| Divergent tasks with no shared state | Any task where order matters |

**Core principle:** Parallel = generating options. Sequential = deciding/converging.

---

## Quick Start

### Launch amux TUI
```bash
~/local/bin/amux
```

Keyboard shortcuts inside amux:
- `n` — New agent pane
- `q` — Quit
- Arrow keys — Navigate panes
- Enter — Select/focus pane

### Start amux server (required before TUI)
```bash
~/local/bin/amux server start
```

### Check status
```bash
~/local/bin/amux server status
```

---

## Taoz Parallel Workflow

### Example: Build 2 skills simultaneously

**Step 1: Plan the parallel tasks**
Before starting, verify tasks are truly independent (no shared file writes, no dependencies).

**Step 2: Start amux server**
```bash
~/local/bin/amux server start
```

**Step 3: Launch amux TUI in a tmux session**
```bash
# If not already in tmux:
tmux new-session -s amux-work

# Then launch
~/local/bin/amux
```

**Step 4: In amux TUI, press `n` for each task**
Each pane gets its own workspace. Type your prompt and pick agent (Claude Code).

**Step 5: Collect outputs**
Wait for both agents to finish. Review each output in their respective panes.

**Step 6: Merge/review**
Come back to the main session, review both outputs, integrate the best parts.

---

## CLI Usage (Non-TUI)

```bash
# List available commands
~/local/bin/amux --help

# List workspaces
~/local/bin/amux workspace list

# Create a named workspace
~/local/bin/amux workspace create skill-build-1

# Run agent in a workspace (non-interactive)
~/local/bin/amux run --workspace skill-build-1 -- claude -p "Build X skill"
```

---

## Integration with Claude Code

amux works natively with Claude Code. When in an amux pane:
```bash
claude  # Launches Claude Code in that pane's workspace
```

Or run non-interactively:
```bash
~/local/bin/amux run -- claude -p "YOUR TASK" --allowedTools "Bash,Edit,Read,Write"
```

---

## GAIA Use Cases for Taoz

1. **Parallel skill builds:** Build `rag-anything` skill while fixing a bug in `ad-performance` skill
2. **Multi-brand research:** Research Pinxin and Wholey Wonder simultaneously
3. **Test + implement:** One agent writes tests, another writes the implementation
4. **Review swarm:** Run multiple review passes on a PR simultaneously

---

## Notes
- amux requires tmux to be installed (`brew install tmux` if missing)
- Each workspace is isolated — agents won't clobber each other
- Workspaces are git-aware (separate worktrees)
- Max recommended parallel agents: 3 (keeps context clean, avoids token bloat)
