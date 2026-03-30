---
name: No burnt filter on NANO outputs
description: NEVER apply mirra_filter_v4 or any heavy color grade to NANO-generated ad outputs — user rejected it as "burnt". Only resize + grain(0.016) in post-process. Applies to ALL NANO-based ad pipelines including CN ads.
type: feedback
---

## REJECTED: Heavy color filters on NANO ad outputs (2026-03-12, repeated 2026-03-13)

User explicitly rejected the "burnt" look caused by applying `mirra_filter_v4` (S-curve + 12% warm amber tint + shadow overlay + vignette + blush tint + 32 sparkle spots) to NANO-generated ads. **This mistake was repeated on 2026-03-13 when building CN ads batch** — ALL 15 outputs rejected.

**Why:** NANO's native palette IS the aesthetic. The v3 campaign (march_campaign_v3_20260312_131628) and BETTER OUTPUTS folder prove this. Layering any filter destroys NANO's intended look.

**How to apply:** For ANY new ad batch using NANO (EN or CN), the post-processing is ONLY:
```
resize 1080×1350 (LANCZOS) → place_logo(img, position="auto") → grain(0.016) → DONE
```

### Rules (PERMANENT)
- **NO `_apply_filter()`** — no mirra_filter_v4, no mirra_filter_06, no mirra_filter_08
- **YES `place_logo()`** — use the real Mirra PNG logo via `place_logo(img, position="auto")` from assemble_ad.py. This is the actual brand logo, NOT NANO-rendered text.
- **NO color grade of any kind** — no S-curve, no warm overlay, no vignette, no sparkle
- The mirra_filter_* functions are ONLY for mirra-workflow content categories (cat02-cat08) where PIL/FLUX generates the base
- In Creative Intelligence Module AND mirra_cn_ads_batch.py AND mirra_ads_batch.py — NANO generates complete ads with its own color baked in

### When copying from mirra_ads_batch.py
The EN ads batch (`mirra_ads_batch.py`) still has the old pipeline with filters. Do NOT copy that post-processing pipeline. Always use the v3 architecture from `run_march_campaign_v3.py`.
