---
name: brand-voice-check
description: Quality gate that validates content against brand DNA before publishing. Checks tone, vocabulary, visual style, compliance. MANDATORY before any content goes live.
agents:
  - dreami
  - taoz
---

# Brand Voice Check — Pre-Publish Quality Gate

Validates any content (copy, image prompt, caption, ad) against the brand's DNA.json before publishing. Catches off-brand content, compliance violations, and tone drift.

Referenced by 26+ skills across the system. MANDATORY step before any content goes live.

## When to Use

- Before publishing ANY content to social media
- Before launching ANY ad campaign
- Before sending ANY customer-facing message
- After content-repurpose (ensure adapted content stays on-brand)
- After AI generation (catch AI drift from brand voice)

## Procedure

```bash
# Check text content against brand
bash ~/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh \
  --brand mirra --text "Your weekly bento is here!"

# Check a file
bash ~/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh \
  --brand jade-oracle --file caption.txt

# Check image prompt before generation
bash ~/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh \
  --brand luna --prompt "Photorealistic photo of..."
```

## What It Checks

| Check | What | Fail Example |
|-------|------|-------------|
| Tone match | Voice matches DNA personality | Jade Oracle copy sounds corporate |
| Vocabulary | Uses brand-approved terms | MIRRA called "skincare" (it's meal subscription) |
| Never-list | Avoids prohibited terms | Jade mentioning QMDJ to customers |
| Compliance | Legal/regulatory safety | "Burns fat" for Malaysian health product (RM10K fine) |
| Language mix | Correct bilingual ratio | Pure mainland Chinese for Malaysian audience |
| Visual alignment | Image prompts match brand mood | Luna content looking editorial/studio (should be raw/real) |

## Key Constraints

- Always loads DNA.json as source of truth
- Exit code 0 = PASS, 1 = FAIL with reasons
- Never blocks silently — always explains WHY content failed
- Can run in --strict mode (any warning = fail) or --warn mode (warnings only)
