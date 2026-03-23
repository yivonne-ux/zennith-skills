# Jade Oracle — Quality Gate Checklist

> Every content piece MUST pass all 6 gates before shipping.
> If any gate fails, the piece goes back to the auto-research loop.
> No exceptions. No "good enough." The brand is the moat.

## How to Use This Checklist

```
Before publishing ANY content for @the_jade_oracle:

1. Run through all 6 gates below
2. Each gate is PASS or FAIL — no partial credit
3. If ANY gate fails → fix the issue → re-run that gate
4. Only when all 6 gates show PASS → schedule for posting
5. Log the gate results in the content piece's metadata

Automated: fast-iterate (Gate 5) runs automatically in the pipeline.
Manual: Gates 1, 3, 4 require human or vision-model review.
```

---

## Gate 1: Face Consistency Check

**Reference:** `~/Desktop/gaia-projects/jade-oracle-site/images/jade/v15-v22/` (use v22 as primary lock)

**Check against lock-08 reference for:**

- [ ] **Face shape:** Oval, soft jawline — matches v22 reference
- [ ] **Eyes:** Warm brown, almond-shaped, slight upward tilt — NOT round, NOT light-colored
- [ ] **Hair:** Long dark brown/black, soft curtain bangs — NOT straight-across bangs, NOT short, NOT blonde/red
- [ ] **Skin tone:** Warm, natural Korean skin tone — NOT pale-white, NOT tanned
- [ ] **Expression range:** Within Jade's spectrum (warm, knowing, gentle, contemplative) — NOT pouty, NOT aggressive, NOT vacant
- [ ] **Jade pendant:** ALWAYS visible — necklace with jade stone, sits at collarbone level
- [ ] **Age consistency:** Appears 28-33 — NOT teenage, NOT 40+
- [ ] **Overall recognition:** If placed next to v22, a viewer would say "same person" without hesitation

**How to check:**
- Side-by-side comparison with v22 reference image
- Vision model evaluation: "Does this person look like the same individual as the reference?"
- Quick gut check: Would a returning follower recognize Jade instantly?

**Common failures:**
- AI drift: features subtly change across generations (wider face, different nose bridge)
- Pendant missing: gets dropped when the prompt doesn't explicitly require it
- Bangs wrong: AI defaults to either no bangs or heavy straight-across bangs
- Skin tone shift: changes based on lighting description in prompt

**FAIL action:** Regenerate the image with explicit face-lock reference. Include "MUST match reference face exactly" in the image prompt. Use img2img or LoRA if available.

---

## Gate 2: Anti-Pattern Scan

**Reference:** `~/.openclaw/skills/art-director/knowledge/anti-patterns.md` (Yivonne's 63 anti-patterns)

**Scan for these high-risk anti-patterns (Jade Oracle specific):**

### Visual Anti-Patterns
- [ ] **AP-35:** AI gradient blob — no generic AI backgrounds
- [ ] **AP-36:** AI-perfect symmetry — needs organic imperfection, natural warmth
- [ ] **AP-37:** AI text garbling — ALL text in images rendered by design tools, never AI-generated text
- [ ] **AP-38:** AI stock humans — check for wrong hands, blended teeth, extra fingers, no pores
- [ ] **AP-46:** Sage-and-crystal starter pack — Jade's aesthetic is editorial, not Canva-wellness
- [ ] **AP-48:** Appropriated sacred symbols — QMDJ symbols used accurately, not decoratively
- [ ] **AP-50:** Desktop-designed mobile content — MUST look good on phone first
- [ ] **AP-52:** Text-heavy social cards — max 15-20 words on image overlays
- [ ] **AP-53:** Ignoring platform safe zones — text within safe area for grid, Stories, Reels
- [ ] **AP-54:** Generic stock photography — Jade should feel uniquely HER, not stock

### Brand Anti-Patterns
- [ ] **AP-09:** Font vomit — Cormorant Garamond + Jost only, no third typeface
- [ ] **AP-18:** Too many colors — jade green + gold + cream + burgundy + sage. No more.
- [ ] **AP-24:** Fear of white space — let the design breathe
- [ ] **AP-30:** Branding as decoration — every design element serves the message
- [ ] **AP-34:** Generic brand voice — if you replace "Jade Oracle" with a competitor name and it still works, rewrite it
- [ ] **AP-44:** Discount visuals on premium brand — Jade is premium-warm, never cheap-looking
- [ ] **AP-47:** Unsubstantiated claims — no "guaranteed results", no medical/financial promises

**How to check:**
- Run visual through art-director design-critique script: `python3 ~/.openclaw/skills/art-director/scripts/design-critique.py <image_path>`
- Manual scan against the checklist above (takes 60 seconds)
- If in doubt about a specific anti-pattern, it's probably a fail

**FAIL action:** Identify which anti-pattern was triggered. Fix the specific issue. Do not regenerate from scratch unless multiple anti-patterns fire simultaneously.

---

## Gate 3: Brand Voice Check

**Reference:** `~/.openclaw/brands/jade-oracle/DNA.json` — voice section

**The voice IS:**
- [ ] **Warm:** Feels like a friend who genuinely cares — not performative
- [ ] **Wise:** Shares insight from experience and ancient knowledge — not preachy
- [ ] **Approachable:** Uses simple language for complex concepts — not jargon-heavy
- [ ] **Grounded:** Rooted in real practice and real systems — not vague "vibes"
- [ ] **Gently mysterious:** Hints at depth without being gatekeeping — not cryptic

**The voice is NOT:**
- [ ] **NOT corporate:** No "leverage", "optimize", "unlock your potential", "we believe"
- [ ] **NOT witchy:** No "spell", "hex", "dark moon ritual", "coven", "blessed be"
- [ ] **NOT salesy:** No ALL CAPS urgency, no "LAST CHANCE", no "don't miss out!!!"
- [ ] **NOT cosmic:** No "the universe is conspiring", no galaxy imagery, no "manifest"
- [ ] **NOT clinical:** No "studies show", no detached analytical tone
- [ ] **NOT New Age generic:** No "raise your vibration", no "shift your energy", no "quantum"

**Language litmus tests:**
- [ ] Read the caption aloud. Does it sound like a real person talking to a friend? (Not a brand talking to a "community")
- [ ] Remove the brand name. Would you know this is Jade Oracle and not Psychic Samira or a generic astrology account?
- [ ] Is there at least one moment of genuine warmth or vulnerability?
- [ ] Are Chinese metaphysics terms (QMDJ, BaZi, 奇门遁甲) used naturally, not as exotic decoration?

**How to check:**
- `bash ~/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh --brand jade-oracle --content <file>`
- Read the caption as if Jade is saying it directly to one person sitting across the table
- If any phrase makes you cringe or sounds like marketing, flag it

**FAIL action:** Rewrite the flagged sections. Keep the structure; change the voice. Common fix: replace abstract claims with specific stories or personal moments.

---

## Gate 4: Physical Realism Check

**This gate catches AI-generated visual artifacts that break immersion.**

- [ ] **Hands:** Correct number of fingers (5 per hand), natural positioning, no melting/merging
- [ ] **Face:** No asymmetric artifacts, no blurred features, no uncanny smooth skin patches
- [ ] **Objects:** All objects have correct physics — cups sit on surfaces, cards don't float, candles have flames pointing up
- [ ] **Text in image:** Any text overlay is sharp, correctly spelled, properly kerned. If AI generated the text in the image: FAIL immediately (AP-37)
- [ ] **Lighting consistency:** Shadows all fall in the same direction. No object is lit from a different angle than the rest of the scene
- [ ] **Background:** No impossible architecture, no warped lines, no melting edges, no clone-stamp repetition
- [ ] **Jade pendant:** Physically plausible — hangs from a chain, doesn't float, reflects light consistently with scene
- [ ] **Proportions:** Body proportions are natural. Arms are correct length relative to body. Head size is realistic.
- [ ] **Reflections/mirrors:** If any reflective surface is present, reflection matches the scene. If this is impossible to get right, remove the reflective surface.
- [ ] **Scene coherence:** The overall scene "could exist in a photo taken by a real photographer with a real camera"

**How to check:**
- Zoom to 100% and scan the image quadrant by quadrant
- Pay special attention to: hands, fingers, pendant, eyes, background edges
- If using a vision model for evaluation: "List every physically impossible element in this image"
- Ask: "Would a professional photographer's output ever look like this?"

**FAIL action:** Regenerate with explicit instructions addressing the specific artifact. For hands: "show hands clearly with exactly 5 fingers each, natural relaxed pose." For text: remove AI text, add clean text overlay in Figma/Canva post-generation.

---

## Gate 5: Copy Quality Check (fast-iterate)

**Minimum score: 8/10 criteria passing**

- [ ] Run fast-iterate on the caption copy:
  ```bash
  bash ~/.openclaw/skills/fast-iterate/scripts/fast-iterate.sh \
    --task "Polish this Instagram caption for Jade Oracle" \
    --criteria "hook_power,clarity,emotion,brand_voice,cta_strength,social_proof,cultural_sensitivity,platform_native,specificity,scannability" \
    --brand jade-oracle \
    --rounds 3 \
    --variants 3
  ```
- [ ] Final score >= 8/10 (0.8 or higher)
- [ ] Hook scores YES on `hook_power` specifically (this is non-negotiable)
- [ ] `brand_voice` scores YES (this is non-negotiable)
- [ ] `cultural_sensitivity` scores YES (this is non-negotiable)

**Three non-negotiable criteria (instant FAIL if any is NO):**
1. Hook power — if the hook doesn't stop a scroll, nothing else matters
2. Brand voice — if it doesn't sound like Jade, it damages the brand
3. Cultural sensitivity — if it appropriates or misrepresents, it causes real harm

**How to check:**
- fast-iterate runs automatically as part of the pipeline
- Check the `scoring_log.json` output for the final score
- Review the prompt evolution to understand what the system learned

**FAIL action:** The fast-iterate loop should self-correct. If after 3 rounds the score is still below 8/10, the content concept itself may be flawed. Go back to the content calendar and try a different angle for that day's theme.

---

## Gate 6: Platform Spec Check

**Instagram Feed Post:**
- [ ] Image: 1080 x 1080px (square) or 1080 x 1350px (portrait, preferred — takes more screen space)
- [ ] Carousel: max 10 slides, all same dimensions
- [ ] Caption: under 2,200 characters
- [ ] Hashtags: 15-20, grouped at end of caption or in first comment
- [ ] Alt text: written (accessibility + SEO)

**Instagram Reel:**
- [ ] Dimensions: 1080 x 1920px (9:16 vertical)
- [ ] Duration: 30-90 seconds (sweet spot: 45-60 seconds)
- [ ] Safe zones: no text in top 250px (username overlay) or bottom 400px (CTA/music bar)
- [ ] Cover image: selected frame or designed cover that works on grid (center-crop square)
- [ ] Captions/subtitles: burned in or auto-generated (70%+ watch without sound)
- [ ] Audio: original audio or licensed music (no copyrighted tracks)

**Instagram Stories:**
- [ ] Dimensions: 1080 x 1920px (9:16)
- [ ] Safe zones: no text in top 200px or bottom 250px
- [ ] Text readable at arm's length on mobile
- [ ] Interactive elements used (poll, quiz, question, slider)

**Image Quality:**
- [ ] Resolution: minimum 1080px on shortest edge
- [ ] Format: JPG (photos) or PNG (text overlays/graphics)
- [ ] File size: under 8MB for images, under 100MB for videos
- [ ] Color profile: sRGB (not CMYK or Adobe RGB)
- [ ] No visible compression artifacts

**How to check:**
- Verify dimensions in image/video metadata
- Preview on a phone screen (not desktop) before finalizing
- Use Instagram's preview/draft feature to check safe zones
- Run through video compiler specs if using Remotion pipeline

**FAIL action:** Resize/reformat to correct specifications. Never publish off-spec content — it signals amateur quality.

---

## Gate Summary Scorecard

Use this template when logging gate results:

```
Content: [Brief description]
Date: [YYYY-MM-DD]
Content Type: [educational/social_proof/lifestyle/reading_demo/emotional/community/spiritual]

Gate 1 — Face Consistency:    [PASS/FAIL] Notes: ___
Gate 2 — Anti-Pattern Scan:   [PASS/FAIL] Notes: ___
Gate 3 — Brand Voice:         [PASS/FAIL] Notes: ___
Gate 4 — Physical Realism:    [PASS/FAIL] Notes: ___
Gate 5 — Copy Quality:        [PASS/FAIL] Score: _/10
Gate 6 — Platform Specs:      [PASS/FAIL] Notes: ___

Overall: [SHIP / FIX / SCRAP]
Reviewed by: [Agent name or "Jenn Woei"]
```

---

## Escalation Protocol

| Scenario | Action |
|----------|--------|
| 1 gate fails, easy fix | Fix and re-check that gate |
| 2+ gates fail | Send back to auto-research loop for full regeneration |
| Gate 3 (brand voice) fails repeatedly | Review brand DNA — voice may need calibration |
| Gate 4 (realism) fails repeatedly | Switch image generation approach (different model, img2img, or manual composite) |
| All gates pass but "something feels off" | Trust the gut. Run one more fast-iterate round. Or sleep on it. |

---

*This quality gate is non-negotiable. Every piece of content that represents Jade Oracle
must earn the right to be published. The brand's trust is built one post at a time
and destroyed by one bad one.*

*Last updated: 2026-03-22*
*Anti-patterns source: `~/.openclaw/skills/art-director/knowledge/anti-patterns.md`*
*Brand DNA source: `~/.openclaw/brands/jade-oracle/DNA.json`*
