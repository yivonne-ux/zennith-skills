---
name: verify-task
version: "1.0.0"
description: Test-and-Verify Protocol — validates every task completion has real proof before marking done.
metadata:
  openclaw:
    scope: verification
    guardrails:
      - Never mark a task as complete without proof
      - Never fabricate proof — if proof is missing, reject and re-open
      - Proof must be machine-verifiable where possible (exit codes, HTTP status, row counts)
---

# Verify Task — Test-and-Verify Protocol

## Purpose

Every task in GAIA CORP-OS must be verified before it is considered complete. "Done" means "proven done." No exceptions.

## How It Works

When an agent reports a task as complete, Zenni (or any verifier) invokes this protocol:

1. **Check proof exists** — the completion message must include proof matching the task type
2. **Validate proof quality** — proof must be specific, not vague ("it works" is not proof)
3. **Verdict** — `VERIFIED`, `INSUFFICIENT`, or `REJECTED`
4. If `INSUFFICIENT` or `REJECTED` → task is re-opened with specific feedback on what's missing

## Proof Requirements by Task Type

### Code / Skill Creation
- **Required:** Test output showing success + exit code 0
- **Required:** File paths of created/modified files
- **Required:** `openclaw skills reload` output (for skills)
- **Good to have:** Before/after comparison

```
Example proof:
  Files: ~/.openclaw/skills/my-skill/SKILL.md (new)
  Test: $ openclaw skills reload → "12 skills loaded"
  Exit code: 0
```

### API Integration
- **Required:** HTTP response status (200/201)
- **Required:** Response body snippet (redact secrets)
- **Required:** Endpoint URL called

```
Example proof:
  Endpoint: GET https://gateway.maton.ai/klaviyo/api/accounts
  Status: 200
  Body: {"data":[{"type":"account","id":"XYZ","attributes":{"contact_information":{"organization_name":"Pinxin Vegan Cuisine"}}}]}
```

### Content Creation
- **Required:** Draft text (full or substantial excerpt)
- **Required:** Format matches target platform requirements
- **Required:** Word/character count if platform has limits

```
Example proof:
  Platform: Instagram caption
  Character count: 287/2200
  Draft: "This Valentine's Day, give the gift that nourishes..."
```

### Scraping / Data Collection
- **Required:** Structured data output (table or JSON)
- **Required:** Row/item count
- **Required:** Source URLs
- **Required:** Data quality notes (methodology, confidence)

```
Example proof:
  Source: Shopee search "vegan snack" (top 50 results)
  Rows: 47 products scraped
  Format: JSON array [{brand, product, price_myr, reviews, est_monthly_sales}]
  Data quality: Medium — monthly sales estimated from review velocity (1:8 ratio)
```

### Deployment
- **Required:** Health check URL returns 200
- **Required:** Deployed URL accessible
- **Good to have:** Before/after screenshots

```
Example proof:
  URL: https://gaia-dashboard.vercel.app
  Health: GET /api/health → 200 {"gateway":"online"}
  Deploy: Vercel deployment ID dep_abc123
```

### Analytics / Reporting
- **Required:** Data source cited (Sheet name, tab, date range)
- **Required:** Key numbers with comparison baseline
- **Required:** Methodology for any calculations

```
Example proof:
  Source: Google Sheets "GAIA Sales" → MY tab, rows 200-245
  Period: Feb 3-9, 2026
  GMV: RM 18,420 (vs RM 16,158 prior week, +14.0%)
  Method: Sum of column F (Gross Sales), filtered by date range
```

## Verification Template

When verifying a task, use this format:

```
## Verification: [Task Name]

**Task type:** [code | api | content | scraping | deployment | analytics]
**Agent:** [who reported completion]
**Proof provided:**
- [ ] Matches required proof for task type
- [ ] Specific (not vague)
- [ ] Machine-verifiable where applicable
- [ ] Data sources cited

**Verdict:** VERIFIED | INSUFFICIENT | REJECTED
**If not verified:** [What specific proof is missing]
```

## Integration with Rooms

- Verification results are posted to the same room where the task was completed
- `REJECTED` tasks also get a feedback room entry for learning
- All verification failures feed into the nightly review for pattern detection

## What "Real Data" Means

Agents must pull from actual sources, never hardcoded/seed data:
- **Sales data** → Google Sheets (Sheet 1 + Sheet 2 from MEMORY.md)
- **Klaviyo metrics** → Maton OAuth via `klaviyo` skill
- **Channel performance** → Shopee/Lazada/TikTok seller dashboards (via scraping)
- **Competitor data** → Live scraping via `site-scraper` / `firecrawl-search`

If an agent cites a number, they must cite the source. "Shopee orders: 347" must include where that number came from.

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: proof requirements for 6 task types, verification template, real data policy
