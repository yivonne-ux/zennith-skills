# Budget Pacing

Monitor daily ad spend vs budget across all 9 Meta ad accounts.

## Owner
Hermes

## Trigger
Cron: every 6 hours

## What It Does
1. Pull current spend from Meta Ads API for all active campaigns
2. Compare against daily budget target per campaign
3. Alert if overspend >110% or underspend <70% of daily target
4. Project monthly spend vs cap
5. Post alerts to exec room

## Alerts
- OVERSPEND: Campaign spending >110% of daily budget -> pause alert
- UNDERSPEND: Campaign spending <70% of daily target -> delivery issue
- PROJECTION: Monthly projection exceeds budget cap -> scale down warning

## Script
`~/.openclaw/workspace/scripts/budget-pacing.py`

## Data
Reads from: Meta Ads API (via meta_ads_api.py), campaigns table in gaia.db
Writes to: exec room, campaigns table (performance_json)
