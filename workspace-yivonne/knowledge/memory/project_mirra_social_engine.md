---
name: Mirra Social Engine — Autonomous Production System (March 28, 2026)
description: FULL SYSTEM. Autonomous social media production engine. 6 posts/day. Scrape→classify→produce→audit(9/10)→user gate→compound learn. Session handoff doc at MIRRA-SOCIAL-ENGINE.md.
type: project
---

## MIRRA SOCIAL ENGINE

**Working dir:** `/Users/yi-vonnehooi/Desktop/_WORK/mirra/`
**System doc:** `MIRRA-SOCIAL-ENGINE.md` — READ FIRST every session
**Volume:** 6 posts/day, 84 posts per 14-day cycle
**Current state:** 47 posts produced (batch 1), 37 more needed (batch 2)

### The Loop
SCRAPE (world-class viral) → CLASSIFY (text/visual/both/format) → PRODUCE (brand DNA + purpose) → AUDIT (7-layer, 9/10 minimum) → regression if fail → USER GATE → COMPOUND LEARN → next batch

### Session Continuity
`MIRRA-SOCIAL-ENGINE.md` is the handoff document. Any new session reads it + memory files to continue exactly where the last session left off. Contains: current state, approved formats, rejected formats, next batch needs, full production loop spec.

### Key Files
- `05_scripts/post_single.py` — posts 1 image to IG via Graph API
- `05_scripts/schedule_42_posts.py` — batch scheduler
- `06_exports/social/42-posts/` — all produced posts
- `04_references/curated/17-fresh-viral-scrape/` — all scraped refs
- Cron: 45 jobs installed for auto-posting

**Why:** User wants fully autonomous social media production that compounds learning across sessions. Every round gets smarter. No mistake repeated. Scale to 6/day.

**How to apply:** On any new Mirra social production session, read MIRRA-SOCIAL-ENGINE.md first. It tells you exactly what to do next, what's been done, and what rules to follow.
