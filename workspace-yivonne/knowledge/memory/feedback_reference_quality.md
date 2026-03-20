---
name: Reference quality filtering required
description: Scraped Pinterest refs include icons, stock photos, irrelevant brands — must pre-filter refs before using as NANO input. Bad refs contaminate outputs.
type: feedback
---

## References must be actual ads, not random images (2026-03-12)

User flagged that most references in the 10-ref test were "not content type nor ads, just icons and pictures."

### Problem
The scraped Pinterest refs library (`~/Desktop/mirra-ads-refs/Type_01–Type_17/`) contains:
- Stock icons (clock, search mockups)
- Store opening posters (Wings Corner)
- Other brand ads (ClassikChops Nigerian food, ShopeeFood, Lotteria)
- Canva template screenshots
- Random food photography without ad context

### Rule
- References must be ACTUAL ADS or branded content — not stock photos, icons, or random images
- Before using a reference, validate it is: (1) an ad or branded content piece, (2) has a layout/composition worth following, (3) is relevant to the target ad type
- Use `tools/analyze_reference.py` to pre-score refs and reject low-quality ones
- Output quality correlates STRONGLY with reference quality (proven in 10-ref test: best ref → best output)

### Impact
- Bad ref → NANO has nothing useful to adapt from → falls back entirely on prompt (sometimes works, sometimes doesn't)
- Good editorial food photography ref → NANO produces campaign-ready output
