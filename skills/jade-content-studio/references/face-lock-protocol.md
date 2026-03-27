## 3. Face Lock Protocol

Hard-won rules from Luna Solaris v3 and Jade production. Every rule here was learned from a failure.

### 3.1 The 60% Rule

Face refs must be **>= 60%** of total reference image slots. Below this threshold, face drifts.

| Setup | Face % | Result |
|-------|--------|--------|
| 5 face + 2 body | 71% | GOOD — face holds |
| 3 face + 3 body | 50% | RISKY — face may drift |
| 3 face + 6 body | 33% | BAD — face WILL drift |

### 3.2 Reference Array Pattern (7 Slots)

```
Slot 1: Face ref — close-up, primary anchor (lock-08-v6-body-front.png)
Slot 2: Face ref — different angle (lock-06-tank-pro.png)
Slot 3: Face ref — different lighting (lock-07-seated-cami.png)
Slot 4: Face ref DUPLICATE of Slot 1 (for weight — CRITICAL for consistency)
Slot 5: Face ref DUPLICATE of Slot 2 (for weight)
Slot 6: Body ref (fashion/figure reference)
Slot 7: Optional scene ref (specific setting)
```

### 3.3 Prompt Ref Labeling (MUST include at top of every prompt)

```
Reference images 1-5 show the CHARACTER'S FACE — keep this EXACT face,
bone structure, eyes, jawline, hair. Reference image 6 shows BODY TYPE
and FASHION STYLE only — apply this figure and clothing style.
Do NOT generate a different woman. This must be the SAME person from
references 1-5.
```

### 3.4 Anchor Phrase (MUST include in EVERY generation prompt)

```
EXACT SAME WOMAN from reference images 1-N — do NOT generate a different woman.
Her face, bone structure, eyes, nose, jawline, smile, and hair MUST be identical
to references 1-N.
```

**Jade-specific anchor (append after generic anchor):**
```
Korean woman in her early 30s with long dark brown hair with soft curtain bangs,
warm brown eyes, jade pendant necklace, warm golden natural skin tone,
calm knowing smile
```

### 3.5 Model Selection Rules

| Model | Best For | Face Lock Quality |
|-------|----------|-------------------|
| **NanoBanana Flash** (`gemini-3.1-flash-image-preview`) | Full-body scenes, action shots, multi-element compositions | BEST for complex scenes |
| **NanoBanana Pro** (`gemini-3-pro-image-preview`) | Close-up portraits, headshots, beauty shots | Better detail but drifts more |

**Rules:**
- Full body → use Flash (holds face better in complex compositions)
- Close-up portrait → use Pro (more beautiful output)
- 1K resolution forces consistency — less detail = less room for drift
- Multi-panel in one image keeps face consistent across panels

### 3.6 Known Gotchas (All Learned from Production Failures)

**Gotcha #1: Body ref hair overrides face ref hair color**
When body ref has dark hair and face ref has distinctive/unusual hair color, the model generates the body ref's hair color. Fix: add "DISTINCTIVE" or "STRIKING" before unusual hair colors in the prompt. Or use body refs where the model's hair matches, or crop body ref to exclude the head. This was confirmed on Luna-Chic-C + olive-vneck-street pairing (score 6/10 — hair was wrong).

**Gotcha #2: Too many body refs dilute face signal**
Max 2 body refs per generation. Duplicate face refs for weight instead of adding more body refs.

**Gotcha #3: Brand injection on lifestyle shots**
NanoBanana auto-injects brand elements (QMDJ logo, Jade Oracle box) when `--brand jade-oracle` is set. Use `--use-case character` to skip brand enrichment. If you want pure lifestyle without brand elements, use `--use-case social` or temporarily `--brand gaia-os`.

**Gotcha #4: Face contamination from body ref (CRITICAL — learned 2026-03-24)**
If body ref shows a different person's face (e.g., using Jade's body for Luna's face), the model creates a HYBRID face that is neither character. The auditor in brand mode scores this 10/10 face_quality because it checks photorealism, NOT identity match.

**Fix (mandatory for cross-character body pairing):**
1. ALWAYS crop body refs to remove the head: `crop_headless_body input.png output.png 25` (built into nanobanana-gen.sh)
2. Use 80/20 face/body ratio: 4x face refs + 1x headless body ref
3. nanobanana now auto-detects ref-image and switches to `--mode character` audit with face consistency checking
4. If `face_consistency` score < 6, it flags as FACE-DRIFT defect

**Never pass a full-body ref of a DIFFERENT character with face visible.** The model will blend the two faces.

**Gotcha #5: Style seed + ref images = chaos**
Do NOT use `--style-seed` when doing face+body pairing. Too many references confuse the model.

**Gotcha #6: "Southeast Asian woman" prompt vs locked pale character**
If the prompt says "Southeast Asian" but the locked face refs show fair-skinned Korean, the model gets confused. ALWAYS reverse-prompt first (describe what you see in the ref) rather than what you think the ethnicity should be.

**Gotcha #7: Content refusal on B&W + intimate poses**
Gemini may refuse prompts with "black and white" + certain body poses. Replace with "documentary style portrait, film grain texture". Avoid words: intimate, bedroom, lingerie, revealing. Use: relaxed, casual, confident.

### 3.7 Anti-Drift Rules (Jade-Specific)

1. Hair MUST be dark brown — if output shows lighter hair, REGENERATE
2. Eyes MUST be warm brown — not blue, not grey
3. Jade pendant necklace MUST be visible in every image
4. Expression should be warm/positive — NOT cold editorial
5. Always pass locked face ref as `--ref-image` FIRST image
6. Always end prompt with: `No illustration, no cartoon, no CG.`
7. If using body refs, choose refs with dark hair to avoid hair override

