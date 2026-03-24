---
name: NEVER use PIL for creative editing — PIL is only for resize and file operations
description: ABSOLUTE RULE. PIL produces forced, amateur, over-contrasted results. ALL creative work (color grading, warmth, vibrance, grain, enhancement) must be done by AI (NANO/ChatGPT/Gemini). PIL only resizes and saves files. No exceptions.
type: feedback
---

## NEVER USE PIL FOR CREATIVE EDITING (2026-03-23)

User said: "Final graded looks bad, forced, over contrast. AND NEVER USE PIL FOR EDITING ANY CREATIVES."

**Why:** PIL applies blanket mathematical operations (multiply R by 1.05, boost saturation by 12%, etc.) that look FORCED and AMATEUR. Real color grading is context-aware, selective, and organic. AI models understand the image and apply natural-looking adjustments. PIL cannot.

**What PIL produced:** Over-contrasted, artificially warm, visibly processed food photos that look worse than the raw NANO output. The "craft" layer RUINED the photo instead of improving it.

**The rule:**

PIL CAN do:
- Resize (800x800, 1080x1920, etc.)
- Save to JPEG/PNG with quality settings
- Read image dimensions
- Create blank canvases for padding

PIL CANNOT do:
- Color grading (warmth, vibrance, saturation)
- Contrast adjustment
- Sharpening
- Film grain
- Shadow/highlight recovery
- Any visual enhancement
- HSL adjustments
- Tone curves
- White balance

**ALL creative editing = AI (NANO, ChatGPT, Gemini, Stable Diffusion)**
**PIL = file operations ONLY**

**Previous violations to remove:**
- grabfood_master.py — professional_grade() function uses PIL ImageEnhance
- grabfood_master_v2.py — color_grade() and film_grain() use PIL/numpy
- grabfood_master_v3.py — same PIL color grading
- pinxin_week2_v2.py — post_process() has PIL sharpness/contrast
- Any add_grain() function that uses PIL/numpy arrays

**How to apply going forward:**
1. NANO/AI does ALL visual work in one or multiple passes
2. Output comes out of AI ready to use
3. PIL only resizes the final output to target dimensions
4. If the AI output needs color/grain/warmth adjustments, do ANOTHER AI pass — never PIL

This overrides ALL previous production pipeline instructions that included PIL color grading, vibrance, contrast, sharpening, or grain functions.
