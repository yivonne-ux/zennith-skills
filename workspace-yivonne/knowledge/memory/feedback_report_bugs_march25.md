---
name: Report Bugs Found March 25
description: Two bugs in autoads_report.py. Missing campaign + no channel-split ROAS. Fixed campaign, ROAS split needs deeper rework.
type: feedback
---

**BUG 1: MIRRA-TEST-CN-MAR26 missing from all reports (FIXED)**
- Campaign ID `120242860196260787` was spending RM301/day but not monitored
- Caused: report showed RM400+ when actual was RM700+
- Fixed: added to autoads_report.py, autoads_analyzer.py, autoads_forensic.py, midnight script
- **LESSON: Whenever a new campaign is created, it MUST be added to ALL monitoring scripts immediately.**
- **How to prevent: autoads_analyzer.py should auto-discover active campaigns from ad account, not hardcoded list.**

**BUG 2: Pinxin report shows blended ROAS only, no WA vs Website split (TODO)**
- Website purchases tracked by Shopify pixel → clear ROAS per campaign
- WA purchases tracked by Google Sheet → only blended, not per-campaign
- Report shows "Total Revenue" combining both but doesn't break down which channel drove what
- **NEED: Separate "Website ROAS" (pixel) vs "WA ROAS" (sheet) in the report**
- **NEED: Match WA sheet orders to CTWA campaign ads (same attribution issue as Mirra)**

**Future fix: Auto-discover campaigns**
Instead of hardcoding campaign IDs, query `act_{id}/campaigns?status=ACTIVE` at runtime. This prevents missing-campaign bugs when new campaigns are created.
