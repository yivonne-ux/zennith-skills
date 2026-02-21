# Mission Executor

**Mission control dispatcher — reads missions from mission-control and delegates to appropriate agents**

## What It Does

Processes missions from the mission queue, determines the right agent for each mission, and dispatches work via rooms or Claude Code runner.

## Architecture

- **Mission source**: `~/.openclaw/skills/mission-control/data/missions.txt` (human-readable)
- **Mission log**: `~/.openclaw/skills/mission-executor/data/missions.jsonl` (execution history)
- **Dispatcher**: `scripts/executor.sh`
- **Cron**: Runs every 30 minutes at 3 and 33 past the hour

## Mission Format

```
M001|Mission Name|STATUS|Agent(s)|Priority|Notes
```

Example:
```
M005|System Stability|ACTIVE|Taoz|P0|Check logs, processes, disk, memory
```

## Agent Routing

- **Taoz** → Claude Code CLI (`claude -p`) for code/infrastructure work
- **Artemis** → Research, competitor analysis, trend scouting
- **Athena** → Analytics, measurement, data analysis
- **Iris** → Social content, lifestyle, persona work
- **Calliope** → Creative direction, campaign strategy
- **Daedalus** → Visual content, art direction
- **Apollo** → Content creation, writing
- **Hermes** → Commerce, product research

## Special Handling

- **Taoz missions**: Routed through `taoz-inbox.jsonl` → processed by `claude-code-runner.sh`
- **Other agents**: Posted to appropriate room → dispatched via room-watcher
- **Multi-agent**: Delegates to primary owner first

## Status Values

- `ACTIVE` → process immediately
- `PLANNED` → skip for now
- `IN_PROGRESS` → skip (already delegated)
- `COMPLETED` → archive
- `BLOCKED` → skip with note

## Usage

```bash
# Check missions
cat ~/.openclaw/skills/mission-control/data/missions.txt

# Run executor manually
~/.openclaw/skills/mission-executor/scripts/executor.sh

# View execution history
tail -50 ~/.openclaw/skills/mission-executor/data/missions.jsonl

# Check logs
tail -f ~/.openclaw/logs/executor-cron.log
```

## Integration

Called by: Cron (*/30 at :03 and :33)
Reads: Mission control data
Calls: `openclaw agent`, `claude` CLI, room dispatch
Posts to: build, exec, creative rooms
Works with: mission-control, claude-code-runner
