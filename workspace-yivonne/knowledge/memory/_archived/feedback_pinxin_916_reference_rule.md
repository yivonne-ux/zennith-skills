---
name: References MUST be 9:16 before NANO — never crop output
description: NANO outputs at same ratio as input reference. Non-9:16 refs = non-9:16 output = cropped/stretched final. ALWAYS pre-process refs to 9:16 via blur-extend BEFORE sending to NANO.
type: feedback
---

## References MUST be 9:16 before NANO (2026-03-19)

User said: "image all stretched" then "all cropped. PLEASE COMPARE TO PREVIOUS APPROVED AND TELL ME WHATS WRONG"

**Why:** NANO generates output at approximately the same aspect ratio as the input reference image. If reference is square → output is square → force-resize to 9:16 = stretched/cropped content with text cut off at edges.

The approved 50 ads had 9:16 references (or used two-pass blur-extend system), so NANO output was already 9:16. No force-crop needed.

**How to apply:**
1. BEFORE sending any reference to NANO, pre-process it to 9:16 (1080×1920) using blur-extend:
   - Resize reference to fit within 1080 width
   - Create 1080×1920 canvas with gaussian-blurred version as background
   - Paste sharp reference centered
2. This gives NANO a 9:16 input → it outputs ~9:16 → resize is minor, no cropping
3. NEVER force-crop or force-resize NANO output to a different aspect ratio
4. NEVER use square or landscape references directly — always convert to 9:16 first
5. The post-process is ONLY: minor resize to exact 1080×1920 → logo → grain
