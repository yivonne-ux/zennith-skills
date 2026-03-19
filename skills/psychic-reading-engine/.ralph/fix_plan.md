# Jade Oracle — Fix Plan (Ready-to-Sell)

## Phase 1: Bot Hardening (make it bulletproof)

- [ ] **P1-1: LLM error handling** — Bot silently fails if DeepSeek times out or returns error. Add: retry with fallback model (claude-sonnet-4-6), user-friendly error message ("the energies are swirling... try again in a moment"), log errors to console. Files: `scripts/jade-bot-v3.js` (llmChat function)
- [ ] **P1-2: Rate limiting per user** — No abuse protection. Add: max 10 readings/hour per chatId, friendly message when exceeded ("you've been super active! let things settle for a bit"). Currently RATE_LIMIT_READINGS=10 exists but checkRateLimit() may not be working correctly. Verify and fix. File: `scripts/jade-bot-v3.js`
- [ ] **P1-3: Input sanitization** — Ensure no injection via user messages passed to LLM. Truncate messages > 500 chars. Strip any markdown/HTML that could confuse the bot. File: `scripts/jade-bot-v3.js` (handleMessage)
- [ ] **P1-4: Graceful /start command** — New Telegram users send /start automatically. Ensure it triggers a warm welcome, not a reading. Check handleTelegramUpdate for /start handling. File: `scripts/jade-bot-v3.js`
- [ ] **P1-5: Deploy + regression** — Deploy bot to VPS, run `jade-regression.sh`, verify 10/10 pass

## Phase 2: PDF Report Pipeline (the paid product)

- [ ] **P2-1: Test PDF generation locally** — Run `python3 scripts/generate_pdf.py` with sample reading data. Verify it produces a valid PDF. Check dependencies (fpdf2). Fix any import errors or missing data paths. Create a test script: `tests/test_pdf_gen.sh`
- [ ] **P2-2: Wire PDF into bot order flow** — In processOrder() in jade-bot-v3.js, after generating the reading, call generate_pdf.py via child_process to create PDF. Save PDF to readings/ directory. File: `scripts/jade-bot-v3.js` (processOrder function)
- [ ] **P2-3: Test /test endpoint E2E** — POST to `https://jade-os.fly.dev/test` with sample order JSON. Verify: order parsed → chart computed → reading generated → PDF created. Create test: `tests/test_order_e2e.sh`
- [ ] **P2-4: Deploy PDF gen to VPS** — Upload `generate_pdf.py` to VPS data dir. Verify Python + fpdf2 available. Test end-to-end.

## Phase 3: Email Delivery (get reading to customer)

- [ ] **P3-1: Test email sender locally** — Run `python3 scripts/send-email-klaviyo.py` with test data. It supports Resend (free 3000/mo), Klaviyo, Gmail SMTP. Verify Resend path works. File: `scripts/send-email-klaviyo.py`
- [ ] **P3-2: Wire email into order pipeline** — In order-handler.sh, after PDF generation, call send-email-klaviyo.py to email PDF to customer. OR integrate directly into processOrder() in the bot JS. Decide: shell pipeline vs JS-native.
- [ ] **P3-3: Set up Resend API key on VPS** — Get Resend API key (free tier), add to VPS env vars. Do NOT put in code or git. Test send.
- [ ] **P3-4: Email template** — Create HTML email template for reading delivery. Brand: Jade Oracle, warm psychic tone, include CTA for next reading. File: `scripts/email-template.html` (new)
- [ ] **P3-5: Deploy + test E2E** — Full flow: /test endpoint → reading → PDF → email arrives in inbox

## Phase 4: Shopify Integration (payment → auto-reading)

- [ ] **P4-1: Verify Shopify webhook handler** — The bot has POST /webhook/order endpoint. Test with sample Shopify order JSON from `webhooks/test-order.json`. Verify it parses correctly: customer email, name, birth data from note_attributes, product type.
- [ ] **P4-2: Product mapping** — Map Shopify product titles to reading types (intro/love/career/wealth/health/general). Verify against `data/shopify-products.json` product catalog.
- [ ] **P4-3: Full webhook E2E test** — Simulate: Shopify order webhook → bot processes → reading computed → PDF generated → email sent. Create: `tests/test_webhook_e2e.sh`
- [ ] **P4-4: Shopify webhook secret validation** — Verify HMAC signature checking works in the bot's verifyShopifyWebhook(). The SHOPIFY_WEBHOOK_SECRET is set in startup.sh on VPS.

## Phase 5: Bot → Store Funnel (upsell)

- [ ] **P5-1: Add upsell message after free reading** — After delivering a 时盘 reading, add a soft CTA: "want a full deep-dive report with your birth chart? check out jadeoracle.co/readings" (once per session, not every reading)
- [ ] **P5-2: /buy command** — Add /buy or /readings command that links to Shopify store product page
- [ ] **P5-3: Reading quality tiers** — Free (Telegram, 时盘, ~200 words) vs Paid (PDF, 命盘+时盘, ~2000 words, full cards + guidance). Ensure free readings are good enough to hook, paid readings are worth $21+.

## Phase 6: Monitoring & Ops

- [ ] **P6-1: Structured logging** — Add JSON-formatted logs with timestamp, chatId, action, duration. Currently just console.log. File: `scripts/jade-bot-v3.js`
- [ ] **P6-2: Health check cron** — Script that pings /health every 5 min, alerts if down. File: `scripts/jade-health-cron.sh` (new)
- [ ] **P6-3: Usage analytics** — Track: readings/day, unique users, topics distribution, conversion (free→paid). Save to `readings/analytics.json` daily.

## Completed
- [x] QMDJ engine — 100% accurate, 5/5 validated
- [x] Interpretation engine — 25 Oracle Cards, stem readings, focus palaces
- [x] Telegram bot live on VPS
- [x] Persistent user store (birth data, gender, name)
- [x] Default to 时盘 (moment reading)
- [x] Birth chart offer after 3rd reading
- [x] Debug endpoint (/debug-interpret)
- [x] Regression test suite (10/10)
- [x] Cards bug fixed (findDayStemPalace compatibility)
- [x] Travel topic added to parseTopic
- [x] Ralph enabled

## Notes
- VPS Machine ID: 7843e55c614918
- VPS App: jade-os (Fly.io, sin region)
- Bot: @Jade4134bot on Telegram
- NEVER commit API keys. VPS env vars only.
- Boot time ~15-20s (installs Python deps on cold start)
- Competitor reference: Psychic Samira ($21 intro, $47 career, $197 mentorship)
