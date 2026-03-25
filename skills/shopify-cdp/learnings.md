# Shopify CDP — Session Learnings

## 2026-03-21 — First session (Zenki)

### What worked
- Chrome CDP via Playwright connected to real signed-in session
- Created 5 products, deleted 12 duplicates via browser automation
- `contexts[0].pages[0]` pattern for connecting to existing tab

### What failed
- Playwright on fresh profile: Google OAuth blocks untrusted browser
- `shpss_` (shared secret) ≠ `shpat_` (admin access token). Can't use secret for API auth
- Shopify CLI has NO product management commands — theme only
- `page.wait_for_load_state("networkidle")` times out on Shopify SPA — use `time.sleep(6)` instead
- Chrome rejects `--remote-debugging-port` on its default data directory

### Patterns discovered
- Copy `~/.chrome-cdp/` profile preserves some cookies but NOT active sessions
- Must let user login once in headed mode, then session persists
- Product IDs visible in URL: `/products/8531546636367`
- "More actions" → "Delete product" → confirm dialog = 3-step flow
- Shopify admin React renders take 5-8 seconds — never skip sleep

### Migration to Pinchtab
- Replacing Playwright with Pinchtab v0.8.4
- Pinchtab uses HTTP API + accessibility refs (e0, e5, e12) instead of CSS selectors
- ~100ms per command vs Playwright's heavier WebSocket protocol
- Shell-native: `pinchtab nav`, `pinchtab snap`, `pinchtab click e5`

## 2026-03-21 — Frontpage Collection Fix

### What broke
- /collections/frontpage was empty
- Shopify Polaris React UI prevents programmatic checkbox selection in Browse modal
- JavaScript clicks don't trigger React state updates

### What worked
- /collections/all shows all products correctly (Shopify built-in)
- Created URL redirect: /collections/frontpage → /collections/all
- Automated collections work when conditions match (but "price > 0" condition may not have worked)

### Pattern: Shopify Polaris React UI limitations
- `page.evaluate()` JS clicks don't update React state
- `aria-label="Select: ..."` elements have overlay divs blocking clicks
- Checkboxes wrapped in Polaris components reject Playwright `.check()`
- Save button stays `aria-disabled="true"` until React state changes
- **Workaround**: Use URL redirects or automated collections instead of fighting the manual UI

## 2026-03-23 — Authenticated Browser E2E Testing

### The Answer: Chrome CDP with ~/.chrome-cdp profile
This is the ONE browser approach for all authenticated access.
- Facebook: ✅ LOGGED IN
- Meta Business Suite: ✅ LOGGED IN  
- Shopify Admin: ✅ LOGGED IN
- Launch: `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9222 --user-data-dir="$HOME/.chrome-cdp"`
- Connect: `p.chromium.connect_over_cdp("http://127.0.0.1:9222")`

### What DOESN'T Work
- Pinchtab BRIDGE_HEADLESS=false: still headless (ignores env var)
- gstack /browse: clean Chromium, no auth
- Chrome Default profile + CDP: Chrome rejects CDP on default data dir
- Cookie extraction: macOS Keychain encrypts values

### Rules
- Always use ~/.chrome-cdp as user-data-dir
- User logs in ONCE per service, session persists
- Must quit Chrome before launching with CDP
- Connect via Playwright, not Pinchtab

## Session Compound (Mar 18-25)
- Temp file JSON payloads: ALWAYS use for bash→LLM calls
- Claude CLI fallback: use `claude --print` on MacBook (/bin/zsh OAuth)
- OpenRouter for iMac agents (auto-detect from openclaw.json)
- NEVER Anthropic API key for loops (per-token cost)
- Auto-detect repo root: SCRIPT_DIR → REPO_DIR → SECRETS_DIR pattern
