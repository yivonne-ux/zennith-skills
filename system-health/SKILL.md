# System Health Monitor

**Skill**: system-health
**Owner**: Taoz (Builder Agent)
**Purpose**: Continuous monitoring and automated health checks for GAIA CORP-OS infrastructure

## What This Skill Does

Provides comprehensive system health monitoring across all critical components:

1. **Gateway Health**: RPC probe validation, not just process checks
2. **Agent Session Monitoring**: Track context bloat, auto-reset at thresholds
3. **Disk Space Alerts**: Monitor storage across workspace volumes
4. **Error Pattern Analysis**: Aggregate and classify log errors
5. **Cron Job Validation**: Verify scheduled tasks are running
6. **Memory System Health**: RAG memory size and integrity
7. **Room Activity**: Monitor message flow and agent responsiveness
8. **API Connectivity**: Test critical API endpoints

## Scripts

### health-check.sh
Full system diagnostic scan. Returns JSON report.

```bash
~/.openclaw/skills/system-health/scripts/health-check.sh [--json] [--verbose]
```

### continuous-monitor.sh
Background daemon that runs health checks every 5 minutes.
Posts alerts to `feedback` room when issues detected.

```bash
~/.openclaw/skills/system-health/scripts/continuous-monitor.sh start|stop|status
```

### auto-heal.sh
Automated remediation for common issues:
- Reset bloated agent sessions
- Restart gateway if RPC fails
- Archive old logs
- Clear lock files

```bash
~/.openclaw/skills/system-health/scripts/auto-heal.sh [issue_type]
```

## Integration

- **Cron**: health-check.sh runs every 5 min, posts to feedback room if warnings
- **Watchdog**: calls auto-heal.sh when thresholds exceeded
- **Dashboard**: health metrics exposed via gateway API

## Alert Severity

- **CRITICAL**: Gateway down, config invalid, disk >95%
- **WARNING**: Session >150KB, error rate >100/hr, disk >85%
- **INFO**: Routine maintenance, successful auto-heals

## Data Files

- Health reports: `~/.openclaw/workspace/health/reports/YYYY-MM-DD.jsonl`
- Alert history: `~/.openclaw/workspace/health/alerts.jsonl`
- Metrics: `~/.openclaw/workspace/health/metrics.jsonl`
