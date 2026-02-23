# Autonomous — GAIA CORP-OS Heartbeat System

The autonomous skill makes GAIA agents "alive" — they work toward goals without waiting for human commands.

## Components

### HEARTBEAT.md (`~/.openclaw/workspace/HEARTBEAT.md`)
Read by Zenni every 30 minutes via OpenClaw's built-in heartbeat feature. Contains the checklist Zenni follows each heartbeat cycle: check missions, scan rooms, monitor content pipeline, verify agent health, trigger self-improvement, and suggest proactive ideas.

### daily-schedule.sh (`~/.openclaw/skills/autonomous/scripts/daily-schedule.sh`)
Cron-driven script that dispatches agents at specific times throughout the day.

## Daily Schedule (MYT)

| Time | Task | Agent | What |
|------|------|-------|------|
| 9:00 AM | `morning` | Artemis | Trending topics + competitor scan |
| 10:30 AM | `content` | Calliope | Seed bank freshness check, trigger CSO if stale |
| 1:00 PM | `intel` | Athena | Midday sales + analytics summary |
| 3:00 PM | `creative` | Calliope | Review pending creative drafts |
| 6:00 PM | `evening` | Iris | Social media activity summary |

## Weekly Schedule (MYT)

| Time | Task | Agent | What |
|------|------|-------|------|
| Monday 9:30 AM | `weekly` | Artemis + Athena | Deep competitive research + performance review |
| Sunday 8:00 PM | `improve` | Artemis + Athena | Self-improvement: new techniques + pattern extraction |

## Usage

```bash
# Run a specific task manually
bash ~/.openclaw/skills/autonomous/scripts/daily-schedule.sh morning

# Show available tasks
bash ~/.openclaw/skills/autonomous/scripts/daily-schedule.sh
```

## Cron Entries (UTC times, MYT = UTC+8)

```
0 1 * * 1-5   morning   (9:00 AM MYT)
30 2 * * 1-5   content   (10:30 AM MYT)
0 5 * * 1-5    intel     (1:00 PM MYT)
0 7 * * 1-5    creative  (3:00 PM MYT)
0 10 * * 1-5   evening   (6:00 PM MYT)
30 1 * * 1     weekly    (Monday 9:30 AM MYT)
0 12 * * 0     improve   (Sunday 8:00 PM MYT)
```

## Logs

- Dispatch logs: `~/.openclaw/logs/autonomous.log`
- Cron output: `~/.openclaw/logs/autonomous-cron.log`

## Safety

- Each dispatch has a 5-minute timeout (background+wait+kill pattern for macOS compatibility)
- Content and creative tasks are conditional — only dispatch if there's actual work to do
- Heartbeat posts a summary to exec room every cycle so Jenn can audit
- Agents are staggered to avoid concurrent token burn

## Heartbeat Configuration

OpenClaw's heartbeat reads `HEARTBEAT.md` from the workspace directory natively when the file has content (non-empty, non-comment-only). The `openclaw.json` schema does NOT support a `heartbeat` key -- adding one causes config validation errors. The heartbeat is enabled simply by having content in `~/.openclaw/workspace/HEARTBEAT.md`.

## Dependencies

- OpenClaw gateway must be running
- Room JSONL files must exist
- Seed bank at `~/.openclaw/workspace/data/seeds.jsonl` (for content check)
- MISSIONS.md at `~/.openclaw/workspace/MISSIONS.md` (for heartbeat)

## Notes

- The `morning` task at 9:00 AM MYT runs in parallel with existing Artemis cron-runner (meta-ads-scan). Both dispatch Artemis but with different tasks -- this is intentional for broader morning coverage.
- The `weekly` task on Monday 9:30 AM MYT is close to existing tiktok-trends-scan at the same time. OpenClaw handles concurrent dispatches gracefully.
- The `improve` task on Sunday 8:00 PM MYT runs at the same UTC time as the existing content-tuner. These target different agents (Artemis/Athena vs. tuner script) so no conflict.
