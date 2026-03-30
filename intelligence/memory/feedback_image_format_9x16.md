---
name: 4:5 → 9:16 pipeline — NEVER generate directly at 9:16
description: UNIVERSAL RULE. NANO generates at 4:5 (1080×1350), then PIL extend_45_to_916() extends to 9:16 with blurred edge bleed. NEVER generate directly at 9:16. Applies to ALL brands.
type: feedback
---

## The Rule

NEVER generate ad creatives directly at 9:16. Always use the two-step pipeline:

1. **NANO generates at 4:5** (1080×1350) — all design content lives here
2. **PIL `extend_45_to_916()`** extends to 9:16 (1080×1920) — pure Pillow, no AI

**Why:** Generating directly at 9:16 puts design content outside Meta's safe zone. Meta crops to 4:5 for Feed placement — so text, CTA, pricing in the top/bottom 285px get cut off. The 4:5→9:16 extension ensures all critical content stays visible in EVERY placement (Feed, Reels, Stories).

**How `extend_45_to_916()` works** (from `Creative Intelligence Module/tools/safe_zone.py`):
- Takes 1080×1350 image, creates 1080×1920 canvas
- Samples top 40px strip → stretches to 285px → GaussianBlur(50)
- Samples bottom 40px strip → stretches to 285px → GaussianBlur(50)
- Pastes original 4:5 centered between blurred strips
- Result: seamless blurred edge bleed, no AI hallucination risk

**The pipeline in code:**
```python
from tools.safe_zone import extend_45_to_916

# Step 1: NANO at 4:5
result = fal_client.subscribe("fal-ai/nano-banana-pro/edit",
    arguments={"prompt": prompt, "image_urls": image_urls, "resolution": "2K"})

# Step 2: PIL extend
img_45 = Image.open(raw_path).convert("RGB")
img = extend_45_to_916(img_45)

# Step 3: Post-process (logo + grain ONLY)
img = post_process(img)
```

**How to apply:**
- Every ad production script MUST import `extend_45_to_916` from `tools.safe_zone`
- NANO prompt should NOT mention 9:16 or 1920 — it generates at 4:5 naturally
- All critical content (text, CTA, pricing, logo) stays within the 4:5 frame
- Top/bottom 285px = blurred edge bleed only — no essential info
- One creative works across Feed (4:5 crop) AND Reels/Stories (9:16 full)
- Applies to ALL brands: Mirra, Pinxin, Bloom & Bare, Jade Oracle, any future brand
