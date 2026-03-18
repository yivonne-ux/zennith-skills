# Meta Ads Upload Flow — Quick Reference

## Fast Commands

```bash
# Full performance loop (one command)
performance-loop.sh run --campaign-set "MIR W10 EN1 M2" --brand mirra --auto-upload --auto-analyze

# Extract patterns from existing briefs
campaign-ingest.sh extract-patterns --campaign-set "MIR W10 EN1 M2" --lookback-weeks 2

# Package campaigns for manual upload
campaign-uploader.sh upload --campaign-ids "CP-MIR-W10-EN1-M2-A,CP-MIR-W10-EN1-M2-B" --file-format local

# Check version history
campaign-uploader.sh logs --campaign-set "MIR W10 EN1 M2" --limit 20

# Diagnose issues
performance-loop.sh diagnose --campaign-set "MIR W10 EN1 M2" --issue "low-roas"
```

## File Locations

| What | Where |
|------|-------|
| Campaign briefs | `~/.openclaw/workspace/data/campaign-tracker.jsonl` |
| Upload bundles | `~/.openclaw/workspace/data/campaign-uploads/bundles/` |
| Upload logs | `~/.openclaw/workspace/data/campaign-uploads/logs/` |
| Version history | `~/.openclaw/workspace/data/campaign-uploads/versions/` |
| Extracted patterns | `~/.openclaw/workspace/data/campaign-uploads/extracted-patterns/` |

## Workflow

```
1. Generate briefs (Hermes):
   campaign-planner.sh create --brand mirra --direction en-1 --template-type M2 --variants 5

2. Run performance loop (Taoz):
   performance-loop.sh run --campaign-set "MIR W10 EN1 M2" --auto-analyze

3. Review results:
   cat ~/.openclaw/workspace/data/campaign-uploads/extracted-patterns/MIR-W10-EN1-M2-summary.md
```

## Version Tracking

Every upload is versioned. Check history:
```bash
cat ~/.openclaw/workspace/data/campaign-uploads/versions/MIR-W10-EN1-M2.jsonl
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No campaigns found | Run `campaign-planner.sh create` first |
| Upload failed | Check logs: `campaign-uploader.sh logs --campaign-set "..."` |
| Low ROAS | Diagnose: `performance-loop.sh diagnose --campaign-set "..." --issue "low-roas"` |

## Scripts

| Script | Purpose |
|--------|---------|
| `campaign-uploader.sh` | Package + upload campaigns |
| `campaign-ingest.sh` | Pattern extraction + analysis |
| `performance-loop.sh` | Full orchestration |
| `campaign-planner.sh` | Generate briefs (Hermes) |