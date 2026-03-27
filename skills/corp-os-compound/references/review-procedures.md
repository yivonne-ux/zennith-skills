# Corp-OS Compound — Detailed Review Procedures

## Content Performance Review (added to Nightly + Weekly)

### Nightly Addition (22:30 MYT)

After step 4 (Extract patterns), also:

5b. **Scan seed bank for new performance data**
   - Read `~/.openclaw/workspace/data/seeds.jsonl`
   - Filter seeds updated in last 24h (by ts) with non-null performance data
   - Summarize: N seeds with new metrics, top performer, worst performer
   - Append to nightly review learning-log entry

### Weekly Addition (Sunday 22:30 MYT)

After step 3 (Week in Review), also:

4b. **Content Performance Report**
   Include in the "Week in Review" townhall post:

   ```
   ## Content Performance Report

   ### Top 5 Seeds by ROAS
   [Query: bash seed-store.sh top --metric roas --top 5]

   ### Top 5 Seeds by Engagement
   [Query: bash seed-store.sh top --metric engagement --top 5]

   ### Worst 5 Seeds (learn from these)
   [Query: bash seed-store.sh query --status tested --sort performance --top 5 (reverse)]

   ### Tuning Recommendations Applied This Week
   [Read: ~/.openclaw/workspace/data/tuning-log.jsonl, filter last 7 days]

   ### A/B Test Results
   [Read: ~/.openclaw/workspace/data/ab-tests.jsonl, filter completed in last 7 days]

   ### Seed Bank Stats
   - Total seeds: N
   - Seeds with performance data: N
   - Winners: N
   - New seeds this week: N
   ```

### Integration Commands

```bash
# Seed bank CLI
SEED_STORE="$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh"

# Top performers
bash "$SEED_STORE" top --metric roas --top 5
bash "$SEED_STORE" top --metric ctr --top 5

# Seed bank stats
bash "$SEED_STORE" count
bash "$SEED_STORE" count --status winner
bash "$SEED_STORE" count --status tested

# Winning patterns
cat ~/.openclaw/workspace/data/winning-patterns.jsonl | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        p = json.loads(line.strip())
        if p.get('status') in ('detected','confirmed','promoted'):
            print(f\"  {p['description']} (evidence: {p['evidence_count']})\")
    except: pass
"

# A/B test results
cat ~/.openclaw/workspace/data/ab-tests.jsonl | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        t = json.loads(line.strip())
        if t.get('status','').startswith('winner'):
            r = t.get('results', {})
            print(f\"  {t['test_type']}: {t['status']} (improvement: {r.get('improvement','n/a')})\")
    except: pass
"
```

---

## Skill Auto-Builder

When a nightly review finds a **high-priority** gap in `corp-os/gaps/`:

1. Compose a build brief from the gap file
2. Dispatch to `claude-code.build` (budget: $1.00)
3. Verify: skill file exists + skill reload succeeds
4. Post to build room with 4-part execution contract:
   - **Result:** What was built
   - **Proof:** Test output
   - **What Changed:** Files created/modified
   - **Learning:** What we learned during the build
5. Update gap status to `built`
6. Git commit the new skill with semantic version

**Guardrails:**
- Max 1 auto-build per night
- Only high-priority gaps qualify
- Jenn is notified in townhall with a summary of what was auto-built
- If build fails -> gap status stays `detected`, failure logged to feedback room

---

## Nightly Crystallization Protocol

Every night (cron at 2am), read rooms/feedback.jsonl and:

1. **Extract Patterns**
   - Find insights that appeared 3+ times
   - Find errors that were solved the same way
   - Find wins that can be replicated

2. **Crystallize into Skills**
   - If pattern works 3+ times -> encode into a skill
   - Create or update ~/.openclaw/skills/<pattern-name>/SKILL.md

3. **Update Agent SOUL.md**
   - Add learned behaviors to relevant agent's SOUL.md
   - Example: If Dreami learns a winning hook format, add to her SOUL.md

4. **Update MEMORY.md**
   - Add cross-agent insights to MEMORY.md
   - These become common knowledge

5. **Report to Townhall**
   - Write summary to rooms/townhall.jsonl
   - "Compound Learning Report: X patterns crystallized, Y insights shared"

## Cross-Pollination

Agents should read rooms/feedback.jsonl at session start to learn from others.
