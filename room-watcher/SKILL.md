# Room Watcher

**Real-time room monitor and dispatcher — detects new room entries and auto-dispatches subscribed agents**

## What It Does

Watches all room JSONL files using `tail -f` and automatically dispatches subscribed agents when new entries appear. Provides instant agent notification without polling delays.

## Features

- **Real-time monitoring**: Uses `tail -f` on all room files
- **Smart dispatching**: Routes messages to subscribed agents per room
- **Direct addressing**: `"to":"agent_name"` field triggers immediate dispatch
- **Anti-loop guards**: Prevents recursive dispatch storms from control-plane messages
- **Cooldown system**: 5-min cooldown per agent/room to prevent spam
- **Single-instance guard**: Prevents duplicate daemons via lockdir

## Architecture

- **Daemon**: `scripts/room-watcher.sh` (runs continuously)
- **Startup**: Launched by cron or manually via `nohup`
- **Lock**: `~/.openclaw/workspace/locks/room-watcher.lock`
- **Logs**: Combined output shows which agent was dispatched

## Subscriptions

- **build** → artemis + athena
- **exec** → athena + hermes
- **creative** → iris
- **social** → athena
- **Direct addressing** → any agent via `"to":"agent_name"`

## Anti-Loop Protection

Filters out:
- Control-plane messages (`type:dispatch`, `agent:room-watcher`)
- Turn-limit errors
- Auth noise
- Empty lines and file headers

## Usage

```bash
# Check if running
ps aux | grep room-watcher | grep -v grep

# Start manually (if not running)
nohup ~/.openclaw/skills/room-watcher/scripts/room-watcher.sh >> ~/.openclaw/logs/room-watcher.log 2>&1 &

# Stop
pkill -f room-watcher.sh
rm -rf ~/.openclaw/workspace/locks/room-watcher.lock

# View activity
tail -f ~/.openclaw/logs/room-watcher.log
```

## Integration

Called by: System daemon (should always be running)
Calls: `openclaw agent` to dispatch messages
Data: All `~/.openclaw/workspace/rooms/*.jsonl` files
