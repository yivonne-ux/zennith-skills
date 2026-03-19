# Jade Oracle — Gstack Audit Report
> Date: 2026-03-18 | Auditor: Taoz (Claude Code)

---

## 1. VPS Health — PASS

| Check | Result |
|-------|--------|
| Uptime | 3738s (~62 min since last restart) |
| Root endpoint | v3, all systems running |
| QMDJ engine | Loaded, computing charts |
| Interpretation engine | Loaded, generating narratives |
| LLM model | deepseek/deepseek-chat-v3-0324 |
| Active chats | 0 (idle) |
| Bot | @Jade4134bot — live on Telegram |
| Machine | 7843e55c614918 (shared-cpu-1x:2048MB, sin region) |

**No issues.** Bot is healthy, all engines loaded.

---

## 2. QMDJ Engine — PASS (5/5 validated)

| Date | Type | Engine | Reference App | Match |
|------|------|--------|---------------|-------|
| 2026-03-17 16:22 | 时盘 | 阳遁1局 | 阳遁1局 | ✅ |
| 2026-03-18 15:43 | 时盘 | 阳遁2局 | 阳遁2局 | ✅ |
| 1991-12-08 | 命盘 | 阴遁4局 | 阴遁4局 | ✅ |
| 1998-10-30 | 命盘 | 阴遁3局 | 阴遁3局 | ✅ |
| 2026-03-18 18:13 | 时盘 | 阳遁3局 | 阳遁3局 | ✅ all 8 palaces |

**Engine accuracy: 100%.** Lineage: 阴盘, 长卿 school, formula `(年支序+时支序+农历月+农历日) % 9`.

---

## 3. Interpretation Engine — PASS with 1 bug

**Working:**
- Oracle narrative generates correctly (1991+ chars)
- Card names appear in narrative (Archetype, Pathway, Guardian)
- Stem interactions (十干克应) resolve
- Use gods (用神) route correctly by topic
- Focus palace selection by topic works
- Gender-aware love reading routing works

**Bug: `cards.*.data` may be null on VPS**
- Root cause: `jade-oracle-card-system.json` must be at `DATA_DIR/jade-oracle-card-system.json` OR `DATA_DIR/reading-engine/data/jade-oracle-card-system.json`
- If the file isn't at either path on VPS, `getCardData()` returns null
- Card names still populate (from STAR_TO_CARD/DOOR_TO_CARD/DEITY_TO_CARD maps) — the narrative works
- Only structured `data` (keywords, light/shadow, career/wealth/relationships) would be missing
- **Impact: LOW** — narrative is the main output, LLM gets card names regardless
- **Fix: Verify file exists on VPS.** If not, redeploy data files.

---

## 4. User Persistence — PASS

| Feature | Status |
|---------|--------|
| User JSON files on disk | ✅ `users/{chatId}.json` |
| Birth data saved | ✅ (tested: Yi-Vonne, chat 5056806774) |
| Gender saved | ✅ persistent, never re-asked |
| Name tracked | ✅ from Telegram username |
| lastSeen updated | ✅ every message |
| shipanCount tracking | ✅ increments per reading |
| Birth chart offer (3rd reading) | ✅ one-time, casual tone |
| Data survives restart | ✅ persisted to disk |

**1 user in production** (Yi-Vonne). Store working as designed.

---

## 5. Bot Conversation Flow — PASS

| Flow | Status | Notes |
|------|--------|-------|
| Default to 时盘 | ✅ | No birth data needed for any question |
| Topic auto-detect | ✅ | parseTopic() handles EN + CN + emoji + number |
| Gender only for love | ✅ | Saved to profile, never re-asked |
| /reading → birth data | ✅ | Collects DOB, time, place, saves to disk |
| /bazi → birth data | ✅ | Same flow as /reading |
| Chat (no reading intent) | ✅ | Falls through to casual LLM chat |
| 3rd reading offer | ✅ | Proactive birth chart offer, one-time |
| Max 1 question pre-read | ✅ | Just topic, or gender for love |

---

## 6. Business Model Gap Analysis — Jade vs Psychic Samira

### Samira's Model (reference: $500K+/mo)
| Product | Price | Notes |
|---------|-------|-------|
| Intro Reading | $21 (was $28) | Hook product, 67K+ customers |
| Full Reading | ~$47-97 | Upsell after intro |
| Mentorship | $497 | High ticket |
| Affiliate Program | % commission | Army of promoters |
| TikTok/IG Content | Free | 89M+ views, AI persona, daily posts |

### Jade Oracle Today
| Product | Price | Notes |
|---------|-------|-------|
| Telegram Bot | FREE | No monetization |
| Shopify Store | NOT BUILT | Product pages, checkout don't exist |
| PDF Reports | Code exists | Not connected to bot |
| Email Delivery | Code exists | No API keys |
| Web Login | NOT BUILT | No auth |
| Ad Campaigns | NOT BUILT | No content pipeline for Jade |

### Gap Priority (what to build next)
| # | Gap | Impact | Effort |
|---|-----|--------|--------|
| 1 | **Shopify store + $1 intro reading** | Revenue unlock | Medium |
| 2 | **PDF report generation → email** | Deliverable product | Low (code exists) |
| 3 | **Payment → reading trigger** | Automation | Medium |
| 4 | **TikTok/IG content pipeline** | Customer acquisition | High |
| 5 | **Upsell flow in bot** | Revenue per customer | Low |
| 6 | **Affiliate/referral program** | Scale | Medium |

---

## 7. Fix & Improve Plan

### CRITICAL (do now)
| # | Item | Action | Owner |
|---|------|--------|-------|
| C1 | Verify card data files on VPS | SSH, check `reading-engine/data/jade-oracle-card-system.json` exists | Taoz |
| C2 | Add test endpoint to bot | Add `/debug-interpret` endpoint that returns raw interpretation JSON | Taoz |

### HIGH (this week)
| # | Item | Action | Owner |
|---|------|--------|-------|
| H1 | Shopify store setup | Create store, add $1 intro reading product | Jenn |
| H2 | Wire PDF report gen to bot | Connect existing PDF code to `/reading` flow | Taoz |
| H3 | Webhook: Shopify order → reading | Existing webhook handler, needs testing | Taoz |
| H4 | Travel topic missing from parseTopic | Add travel/trip/vacation/flight keywords | Taoz |

### MEDIUM (this sprint)
| # | Item | Action | Owner |
|---|------|--------|-------|
| M1 | Error handling for LLM failures | Bot silently fails if deepseek is down, add fallback msg | Taoz |
| M2 | Rate limiting | No protection against spam/abuse | Taoz |
| M3 | Logging/monitoring | No structured logs, hard to debug prod issues | Taoz |
| M4 | Multi-language support | Bot is English-only, market is global | Future |

### LOW (backlog)
| # | Item | Action | Owner |
|---|------|--------|-------|
| L1 | Western astrology integration | Engine exists, not wired to bot | Future |
| L2 | Tarot integration | Engine exists, not wired | Future |
| L3 | Group reading mode | Telegram group support | Future |
| L4 | Voice messages | Whisper transcribe → reading | Future |

---

## 8. Regression Testing Plan

### E2E Test Cases

#### A. Bot Flow Tests (manual via Telegram)
```
TEST-A1: New user says "hi"
  Expected: Jade greets, asks what's on their mind
  Verify: users/{chatId}.json created with firstSeen

TEST-A2: User asks "will i get promoted?"
  Expected: Auto-detect career topic, immediate 时盘 reading
  Verify: No questions asked before reading, reading mentions career energy

TEST-A3: User asks about love (first time, no gender saved)
  Expected: Jade asks gender, then reads
  Verify: Gender saved to users/{chatId}.json, never asked again

TEST-A4: User asks about love (gender already saved)
  Expected: Immediate reading, no gender question
  Verify: Uses saved gender from profile

TEST-A5: User types /reading
  Expected: Birth data collection (DOB → time → place), then destiny reading
  Verify: Birth data saved to users/{chatId}.json

TEST-A6: User with birth data asks a question
  Expected: Uses 命盘 (destiny chart) instead of 时盘
  Verify: Reading references birth chart energy

TEST-A7: 3rd shipan reading for new user
  Expected: Casual birth chart offer after reading
  Verify: birthChartOffered = true in user profile, message only once

TEST-A8: User sends photo
  Expected: Jade acknowledges photo, offers reading
  Verify: No crash, graceful handling

TEST-A9: User sends gibberish
  Expected: Jade responds naturally, not a reading
  Verify: Falls through to chat, not shipan
```

#### B. QMDJ Engine Tests (automated)
```
TEST-B1: Realtime chart computation
  Endpoint: computeChart('realtime')
  Verify: Returns chart with 9 palaces, each has star/door/deity/stems

TEST-B2: Destiny chart (known DOB)
  Input: 1991-12-08, female
  Verify: 阴遁4局, correct palace arrangement

TEST-B3: Edge case — midnight chart
  Input: 2026-03-18 00:00
  Verify: Correct 时辰 (子时), no off-by-one

TEST-B4: Edge case — 节气 boundary
  Input: Date on solar term boundary
  Verify: Correct 局数 calculation

TEST-B5: Kong wang (空亡) present
  Verify: kongwang array populated in chart output
```

#### C. Interpretation Engine Tests (automated)
```
TEST-C1: Career reading interpretation
  Input: chart + {topic: 'career', gender: 'male'}
  Verify: focusPalace uses 开门, cards populated, narrative > 500 chars

TEST-C2: Love reading (female)
  Input: chart + {topic: 'love', gender: 'female'}
  Verify: focusPalace uses 庚 (husband), gender-specific focus

TEST-C3: Love reading (male)
  Input: chart + {topic: 'love', gender: 'male'}
  Verify: focusPalace uses 乙 (wife)

TEST-C4: General reading
  Input: chart + {topic: 'general'}
  Verify: Uses 日干 palace, all 3 card slots attempted

TEST-C5: Missing card data graceful fallback
  Simulate: cardSystem = null
  Verify: Cards still have names, narrative still generates, no crash

TEST-C6: Special formations detected
  Verify: Auspicious/warning formations flagged when present
```

#### D. VPS Health Tests (automated, cron)
```
TEST-D1: Root endpoint responds
  curl https://jade-os.fly.dev/ → status 200, JSON with qmdj_engine: true

TEST-D2: Health endpoint responds
  curl https://jade-os.fly.dev/health → ok: true

TEST-D3: Uptime > 60s (not crash-looping)
  Verify: uptime field in /health > 60

TEST-D4: Memory usage reasonable
  Verify: Via fly machine status
```

---

## 9. Automated Regression Script (to build)

```bash
#!/bin/bash
# jade-regression.sh — Run after every deploy
# Tests: VPS health, QMDJ accuracy, interpretation output

echo "=== Jade Oracle Regression Suite ==="

# D1: Root endpoint
echo -n "D1 Root endpoint... "
ROOT=$(curl -sf https://jade-os.fly.dev/)
echo "$ROOT" | jq -e '.qmdj_engine == true' > /dev/null && echo "PASS" || echo "FAIL"

# D2: Health
echo -n "D2 Health... "
HEALTH=$(curl -sf https://jade-os.fly.dev/health)
echo "$HEALTH" | jq -e '.ok == true' > /dev/null && echo "PASS" || echo "FAIL"

# D3: Uptime
echo -n "D3 Uptime > 60s... "
UP=$(echo "$HEALTH" | jq '.uptime')
[ "$(echo "$UP > 60" | bc)" = "1" ] && echo "PASS ($UP s)" || echo "FAIL ($UP s)"

echo ""
echo "Manual tests: Run TEST-A1 through TEST-A9 via @Jade4134bot on Telegram"
echo "Engine tests: Requires /debug-interpret endpoint (not yet built)"
```

---

## 10. Next Actions (ordered)

1. **Add `/debug-interpret` test endpoint** to bot — returns raw QMDJ + interpretation JSON
2. **Verify card data files exist on VPS** — check paths
3. **Add `travel` to parseTopic()** — missing keyword
4. **Build regression script** (`jade-regression.sh`) and add to repo
5. **Wire Shopify webhook** to trigger paid readings
6. **Connect PDF report generation** to bot flow
7. **TikTok/IG content pipeline** for Jade character (with Tricia/Dreami)
