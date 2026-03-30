---
name: Never batch-publish — always confirm schedule before publishing
description: ABSOLUTE RULE. Never publish multiple posts at once. Always confirm publish schedule with user before ANY irreversible publish action.
type: feedback
---

**RULE: NEVER publish multiple posts simultaneously. ALWAYS confirm the exact schedule with the user before publishing ANYTHING.**

**Why:** On 2026-03-24, published all 4 BB posts to Instagram at once instead of scheduling 1 per day. User wanted 1 post/day cadence. All 4 went live simultaneously — irreversible. This floods the feed and wastes content that should have been spread across 4 days.

**How to apply:**
1. When user says "schedule" or "post", ALWAYS ask: "What schedule? Which post first? What time?"
2. NEVER auto-decide posting schedule — the user controls timing
3. For multiple posts, use the cron publisher (`pending_posts.json`) with specific `publish_at` timestamps
4. Present the proposed schedule as a table for user approval BEFORE any API calls
5. Publishing is IRREVERSIBLE — treat it like `git push --force`. Confirm first.
6. Default cadence suggestion: 1 post/day, alternating morning (9am MYT) and evening (8pm MYT)
7. If user says "schedule", that means FUTURE publishing, not immediate
