---
name: Tools & Workflow Preferences
description: User expects proactive tool usage — gstack for reviews, Shopify CLI for store access, deploy immediately don't just build locally
type: feedback
---

## Key Feedback

1. **Deploy immediately** — Don't just build locally. Always get things live so user can test. "u shud get everything up so we can try"

2. **Use gstack skill** for site reviews — User says "gstack review" = invoke the `/gstack` skill for QA/browser testing, not a manual code review

3. **Use Shopify skills** — `shopify-setup`, `shopify-expert`, `shopify-products` are installed. User expects Shopify CLI login and store management via these skills

4. **Full site on Shopify** — User wants jadeoracle.co to be a Shopify store, not a static HTML site. All products, checkout, theme should be on Shopify

5. **Remember across sessions** — User gets frustrated when context is lost. Save important decisions and project state to memory immediately

6. **Shopify CLI auth is interactive** — Requires browser OAuth, can't be done non-interactively from Claude Code. Need to guide user to run in their terminal or use Custom App token approach
