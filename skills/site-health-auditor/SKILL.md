---
name: site-health-auditor
description: Automated health checking for GAIA OS web properties. Runs URL audits, validates content, checks SSL, reports outages.
agents:
  - taoz
  - scout
---

# Site Health Auditor

## Purpose
Automatically verify GAIA OS sites are live, serving correct content, and report issues.

## Targets
- gaiaos.ai (homepage, privacy, terms)
- studio.gaiaos.ai (Creative Studio)
- Any deployed brand sites

## Check Types

### 1. URL Health Check
```bash
curl -s -o /dev/null -w "%{http_code}" https://gaiaos.ai/privacy/
```
- Expect: 200 or 308 (redirect to /privacy/)
- Fail: 404, 500, timeout

### 2. Content Validation
```bash
curl -s https://gaiaos.ai/privacy/ | grep -c "Privacy Policy"
```
- Expect: >0 matches
- Fail: 0 matches (wrong page served)

### 3. SSL Certificate Check
```bash
curl -sI https://gaiaos.ai 2>&1 | grep -i "ssl\|certificate"
```
- Warn if cert expires in <30 days

## Runbook

### Scout runs every 30 mins via cron:
```json
{
  "schedule": "*/30 * * * *",
  "agent": "scout",
  "skill": "site-health-auditor",
  "targets": ["gaiaos.ai", "studio.gaiaos.ai"]
}
```

### On Failure:
1. Log to `health.jsonl` with timestamp, URL, error type
2. If 3 consecutive failures → notify Zenni immediately
3. Zenni dispatches Taoz for fix or escalates to Jenn

### Report Format:
```json
{
  "ts": 1771846000000,
  "agent": "scout",
  "check": "site-health",
  "target": "gaiaos.ai/privacy/",
  "status": "pass|fail|warn",
  "http_code": 200,
  "content_match": true,
  "ssl_days_left": 89,
  "response_ms": 145
}
```

## Quick Manual Check
```bash
# Check all GAIA sites
for url in https://gaiaos.ai/ https://gaiaos.ai/privacy/ https://gaiaos.ai/terms/ https://studio.gaiaos.ai/; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  echo "$url: $code"
done
```
