---
name: Meta budget changes and algorithm rules for Malaysian market
description: When budget changes reset learning, 20% rule exceptions, time-of-day irrelevant, restructure = reset anyway. Malaysian market specifics.
type: feedback
---

## Budget change rules

1. **20% rule applies to SCALING winners** — don't increase budget >20% per 48hrs on a performing campaign to avoid learning reset
2. **After major restructure (killing many ads), algorithm resets anyway** — budget increase at same time is fine since learning phase restarts regardless
3. **Time of day doesn't matter** for budget changes — Meta recalibrates within hours, midnight vs midday = no difference
4. **Wait 48 hours between budget changes** — even after a restructure, don't stack multiple changes

**Why:** User asked if midnight is better. It's not — Meta's algorithm is continuous, not batch. The concern should be about FREQUENCY of changes, not timing.

**How to apply:** When restructuring (killing/adding ads), batch the budget change with the restructure. When scaling a winner, use 20% rule with 48hr gaps.

## Malaysian market budget math

| Budget/day | Optimal ads | Imps/ad/day | Signal quality |
|-----------|-------------|-------------|----------------|
| RM300 | 6-8 | 2,500-3,300 | Good |
| RM400 | 8-10 | 2,600-3,300 | Good |
| RM600 | 10-15 | 2,600-4,000 | Good |
| RM1,000 | 15-20 | 3,300-4,400 | Good |

Formula: **Budget ÷ Ads = min RM30-40/ad/day for MY market** (lower CPM means you need less per ad than US)

## Token management
- 60-day exchange via AI Agent app (501769942955037, secret: 12949e3c253635e0c70a22ed8300503e)
- Current token: NEVER EXPIRES (exchanged 2026-03-21)
- Stored in: `/Users/yi-vonnehooi/Desktop/mirra-workflow/.env`
- Debug: `debug_token` endpoint with app_id|app_secret as access_token
