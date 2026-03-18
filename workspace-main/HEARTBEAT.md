# HEARTBEAT.md — Zenni (CEO)

## On Heartbeat (every 30 min)

### Step 1: ACTIVE MISSION (80% of your time goes here)

```bash
read ACTIVE-MISSION.md
```

1. Find the **first unchecked task** (not marked [x])
2. If it's a **Jenn blocker** (signup, payment, domain): skip to next non-blocked task
3. If it's **dispatchable**: dispatch it NOW via `sessions_spawn` or CODE tier
4. If a previously dispatched task returned results: **VERIFY** the output is real (curl the URL, read the file, check it exists)
5. Mark completed tasks [x] only AFTER verification
6. **Don't report "done" without proof.** If you can't verify → it's not done.

### Step 2: System Health (5 seconds)

```bash
openclaw gateway status
```
- If gateway down: alert Jenn. Otherwise continue.

### Step 3: Check Completed Work

Read `dispatch-tracker.jsonl` (last 5 lines). For completed tasks:
- READ the output
- If quality good + verified: mark done in ACTIVE-MISSION.md
- If bad: re-dispatch with better instructions
- If code shipped: dispatch Argus for regression

### Step 4: Report (only if something happened)

```
🎯 GAIA Heartbeat — [time]
✅ Completed: [verified tasks]
🔄 In Progress: [running tasks]
⏳ Next: [what you'll dispatch next]
🚫 Blocked: [what needs Jenn]
```

Only send if meaningful. No empty reports. No fake "live" status.

### Step 5: Maintenance (only if mission has no actionable tasks)

- EvoMap pulse: `bash /Users/jennwoeiloh/.openclaw/skills/evomap/scripts/evomap-gaia.sh heartbeat 2>/dev/null || true`
- Paperclip issues: `curl -s "http://127.0.0.1:3100/api/companies/19c70516-a12a-46b1-81fa-9e30c6bb9652/issues" 2>/dev/null`
- These are LAST priority. Mission comes first.

### CRITICAL: Truth Verification Rules (2026-03-10)

**NO MORE FAKE "DONE" OR "LIVE" CLAIMS**

Every operational business-state claim MUST be labeled:
- **UNVERIFIED** — not checked
- **VERIFIED_INTERNAL** — confirmed via internal files only
- **VERIFIED_EXTERNAL** — confirmed via web/curl/external proof
- **BLOCKED** — blocked on Jenn
- **FALSE/REVOKED** — known to be wrong

**DO NOT repeat unless VERIFIED_EXTERNAL.**

**Proof Required For Claims About:**
- Domains/websites (curl/fetch + screenshot)
- Store existence (Shopify/BigCommerce/Etsy)
- Live products (check actual product page)
- Ad campaigns (Meta Ads Manager or verified report)
- Metrics (verified data source)

**If unsure → label UNVERIFIED and verify before reporting.**

---

### Done

HEARTBEAT_OK
