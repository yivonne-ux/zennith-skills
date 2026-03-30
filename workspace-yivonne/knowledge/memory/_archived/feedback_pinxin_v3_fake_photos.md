---
name: Pinxin v3 — Fake Photo Editing + Logo Still Wrong + Study Mirra Engineering
description: v3 photos look fake due to over-processing. Logo STILL wrong (4th time). Need Mirra's weightloss_campaign_50ads engineering approach.
type: feedback
---

v3 batch feedback:
1. **Photos look FAKE** — compositing doesn't match lighting. Over-processed.
2. **Logo STILL WRONG** — 4th correction. STOP getting this wrong.
3. **Study Mirra's weightloss_campaign_50ads** — 4-batch systematic architecture, 20 unique design formats, entity hypothesis per ad

**ROOT CAUSE of fake photos**: Applying editorial_grade + paper_texture + clarity + saturation_bump on NANO output. Mirra does NONE of this. Mirra post-process = resize → logo → grain(0.016). That's it. No color grade. No filter. NANO output is already designed.

**Why:** From Mirra feedback memory: "No color grade on NANO outputs. Logo + grain ONLY."

**How to apply for Pinxin:**
- Post-process: resize(1080×1920) → logo → grain(0.028). NOTHING ELSE.
- No editorial_grade, no paper_texture, no clarity, no saturation_bump
- The NANO prompt must produce the right mood/color — don't try to fix it in post
- Logo: check Pinxin's ACTUAL past work. Emblem or wordmark at VISIBLE size. EXCLUSION ZONE. Test by viewing the output before saving.
- Engineering: 4-batch system with unique entity_hypothesis per ad, reference-matched to design format
