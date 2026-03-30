---
name: Visual Semantic QA Gate — Image Must Match Message
description: CRITICAL. Every generated image must be visually verified to match its intended message before publishing. Random photo selection without semantic checking produces contradictions.
type: feedback
---

**RULE: Every image-text pair must pass visual-semantic coherence check before publishing.**

**Why:** On 2026-03-24, BB "Social Skills" carousel slide showed ONE child alone in foam — contradicting the message about "sharing, taking turns, working together." The script randomly picked a photo from the birthday folder without checking if the photo actually demonstrated the claimed skill. This is embarrassing if published.

**How to apply:**
1. **Photo selection must be semantic, not random.** When picking photos for a specific message, the photo must VISUALLY DEMONSTRATE the message. "Social skills" = multiple kids together. "Fine motor" = hands gripping/pinching. "Confidence" = proud expression.
2. **Visual QA tool built:** `visual_qa.py` at `05_scripts/` — Claude Vision judge scores image-text alignment 1-10 on 5 dimensions. Use for any brand.
3. **Pre-publish gate:** Run visual_qa_gate() on every final image before scheduling for publication.
4. **Photo curation > random selection.** For educational/claim-making content, manually curate photo assignments or use multi-photo selection with AI filtering.
5. **The cascade:** For high-volume production, use the 3-tier cascade (CLIPScore → VQAScore → Claude Vision) when API credits are available.

**Universal rule — ALL brands:**
- If the text makes a CLAIM (social skills, confidence, motor control), the image MUST show evidence of that claim
- If the text is emotional/mood (messy play is fun), the image can be more loosely matched
- Claims require literal visual proof. Moods require tonal alignment.
