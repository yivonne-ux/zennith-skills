# Mirra DNA — Continuous Learning Protocol

## Brand voice
- Girlboss, rebellious, independent woman, unapologetic
- Lowercase always. No exclamation marks. No hashtags in quotes.
- Tone: "in her language" — like a smart friend who gets it
- Viral/shareable: quote must work WITHOUT the image. Ask: would she screenshot and send this?
- Structure patterns that work: "[subverted expectation]. [short payoff]." / "[verb] everything. [verb] nothing." / "she [past action]. [consequence] now."

## Copywriting — what NOT to do
- ❌ "respectfully" — dated, overused
- ❌ passive voice for power statements ("the bag secured itself")
- ❌ too literal to the image ("built different. bathes accordingly." for bubble bath image)
- ❌ vague/generic ("the audacity to be exactly herself")
- ❌ melancholic framing ("the love letters are for herself now")
- ❌ weak verbs ("only plays what...")

## Copywriting — approved quotes (cat04-v4)
```
01: her life, her playlist, her rules.
02: building the empire. silently.
03: rest is a power move.
04: mistook her softness for weakness. their loss.
05: the life she used to dream about is just a tuesday now.
07: chaotic. intentional. unstoppable.
09: out of office. in bed. still booked.
10: studying the assignment. obviously.
11: her most used product: self-trust.
12: noise-cancelling everything that doesn't serve her.
14: she retired from caring what you think.
15: she stopped waiting for the invitation.
16: curated everything. compromised nothing.
C1: she doesn't follow trends. she sets them.
C2: she didn't ask for permission to be rich.
C3: she invests in herself first.
C4: her energy is not available to everyone.
```

---

## Filter selection rule — by content type (apply before every batch build)

**The most common failure mode: using the wrong filter for the content type.**
cat04-v5/v6 used `mirra_filter_06` (cat06 UI filter) on real photography → invisible result.
cat04-v7 fixed this by restoring `mirra_filter` v4 → correct blush/sparkle/depth.

| Content type | Category | Filter | Grain |
|---|---|---|---|
| Real photography — lifestyle, styled objects | cat04 | `mirra_filter` v4 (full 6-step: S-curve + shadow overlay + warm tint + clarity + vignette + 22-45 sparkle) | 0.030 |
| Film/animation stills, attitude memes | cat03 | `mirra_filter_03` (gentle S-curve, shadow overlay ov_alpha=28-45, light sparkle 8-14 flares) | 0.022-0.032 |
| Glitter signage / billboards (real photos) | cat02 | S-curve + shadow-protected overlay, warm_strength=0.08, heavy sparkle 24-42 flares | 0.022 |
| UI/interface/graphic design screenshots | cat06 | `mirra_filter_06` mode="warm" (8.6% overlay, 6% desat, NO S-curve, NO sparkle) | 0.014 |
| Physical props for graphic text cards | cat07 | `mirra_filter_06` mode="light" (even lighter than warm) | 0.014 |
| Typographic quotes | cat08 | Shadow-protected, lighter S-curve, sparkle 3-5 flares, per-template ov_alpha | 0.022 |

**Do NOT import a filter across categories.** Each batch file must own its filter function.
If a batch script imports from another category's file, check the filter function name matches the content type above before running.

---

## cat04 — Pure Vibe Sparkle: DNA rules

### Category essence
Real photography aesthetic with sparkle/glitter overlay. Objects are REAL — styled photos of lifestyle objects. NOT CGI, NOT studio product shots, NOT diamonds/gemstones.

### REALISM GLITTER — key rule
- Glitter/sparkle comes from: light hitting real surfaces (glass, sequins, glitter dust, water bubbles, vinyl)
- NOT from: crystal facets, gemstone cuts, CGI diamond geometry
- The sparkle is an OVERLAY on a real photo — it should look like glitter was physically on the scene
- Prompt FLUX with: "real photograph", "authentic styled photo", "soft natural light", "bokeh"
- ❌ NEVER: "crystal facets", "jeweled", "rhinestone-encrusted" in TYPE A/C pure vibe scenes
- ✅ YES: "glitter dust scattered", "sequins catching light", "glass surface reflecting warm light"

### Type C generation pitfalls
- **C1 (perfume)**: Do NOT use "crystal stopper" or "jewelled" — use real glass bottles, glitter dust, natural light. Crystal = off-brand CGI look.
- **C2 (gold card)**: ❌ CONCEPT REJECTED — "hand holding gold card" does not resonate with Mirra audience regardless of execution. The subject itself is off. Moved to cat04-v4/_rejected/. Do NOT re-attempt this concept. Find a new C2 subject.
- **C3 (jewelry box)**: Micro glitter=250 is correct for velvet texture
- **C4 (candle)**: Amber-pink moody glow, NOT white studio

### Mirra filter — cat04-v4 architecture (established, do not regress)
```python
# Step 1: S-curve (deepens shadows, lifts highlights)
xp = [0, 45, 128, 200, 255] → fp = [0, 34, 128, 218, 255]

# Step 2: Desaturate (desat=0.72-0.78 per image)

# Step 3: Shadow-protected blush overlay
# ov_weight = clip((lum - 0.18) / 0.38, 0, 1)
# arr = arr + ov_weight * (overlay_alpha/255) * (ov_color - arr)
# ov_color = (248, 190, 205)  — blush pink
# Shadows (lum<0.18) get zero overlay — they stay deep

# Step 4: Luminance-weighted warm peach tint
# wt = clip(lum^0.45, 0, 1) * 0.38
# warm target = (255, 195, 185) — peach
# White glitter/sparkle → turns peach-rose

# Step 5: Clarity (local contrast, NOT sharpening)
# GaussianBlur(radius=40), then: arr + 0.16*(arr - blurred)

# Step 6: Vignette — ALWAYS applied (default strength=22)

# Step 7: Sparkle overlay

# Then: full_finish → gradient → text → logo → grain (grain LAST, over everything)
```

### Key filter lessons
- Flat overlay lifts shadows → makes images muddy/flat. Shadow protection is essential.
- ImageEnhance.Contrast(0.95) REDUCES contrast — was wrong. S-curve replaces this.
- ImageEnhance.Brightness(1.04) lifts everything flat — removed. S-curve handles naturally.
- Grain MUST go after text + logo (confirmed user requirement)
- Warm tint makes white glitter turn peach-pink — this IS the Mirra look

### Logo
- Path: `mirra-pinterest-refs/MIRRA LOGO/Mirra Social Media Logo.png`
- RGBA 1080×1350, logo pre-positioned at bottom-center
- Applied via `Image.alpha_composite(img.convert("RGBA"), logo).convert("RGB")`

### Watermark locations (known)
- SaraShakeel: upper-right, ~1/3 from top → box ~(680, 290, 380, 48)
- Darkjadore: bottom-right angled → box ~(650, 1270, 420, 70)
- goddesssparkles: bottom-right → box ~(620, 1282, 460, 58)
- @VenusCollectsBeats: lower center → box ~(340, 678, 400, 32)

---

## cat08 — Typographic Quote: DNA rules

### Standard finish pipeline (ALL 7 templates — non-negotiable)
- Step N-2: `stamp_logo(img)` — logo bottom-centre always
- Step N-1: `add_grain(img, strength)` — GRAIN IS LAST, over logo
- `LOGO_PATH = mirra-pinterest-refs/MIRRA LOGO/Mirra Social Media Logo.png` (1080×1350 RGBA pre-positioned)

### Mirra filter for T1–T4 (AI-generated text images)
- Shadow-protected pipeline (same logic as cat04, lighter weights)
- S-curve: xp=[0,64,128,192,255] → fp=[0,56,128,208,255] (gentler than cat04)
- Desaturate per template (script=0.83, notecard=0.78, display=0.82, list=0.85)
- Shadow-protected blush overlay: ov_weight=clip((lum-0.18)/0.38,0,1), ov_color=(248,190,205)
- Warm peach tint: wt * 0.12 (lighter than cat04's 0.38 — keeps text legible)
- Vignette: strength=14
- ❌ NEVER flat overlay (lifts shadows, kills depth)
- ❌ NEVER ImageEnhance.Contrast(0.95) or Brightness(1.03) without S-curve

### T5 Poster gradient — pixel-analysed from both refs
- _T5_GRAD_CENTER = (229, 78, 123) — deep saturated rose-pink (from gradient-believe-yours center)
- _T5_GRAD_EDGE   = (244, 217, 227) — soft cream-blush (corner average both refs)
- power = 0.78, hotspot at H*0.50 (dead-centre, refs are symmetric)
- Vignette strength=18, then logo, then grain=0.016

### T6 Editorial Serif
- Source template: `mirra-pinterest-refs/08-typographic-quote/editorial-serif-be-picky.png`
- Ref text: ["Be picky about", "your time", "and friends"], caption "and your brows too <3"
- Workflow: nano_edit(ref) → vignette(12) → logo → grain=0.018
- ❌ NO mirra_filter (editorial aesthetic is clean/refined, no blush overlay)
- ❌ NO pure Python gradient (must use nano_edit to preserve real satin bg + serif font)

### T7 Block Bold
- Source template: `mirra-pinterest-refs/08-typographic-quote/block-bold-more-self-love.jpg`
- Ref text: ["MORE", "SELF", "LOVE"] — hot fuchsia/magenta background
- Workflow: nano_edit(ref) → _t7_peach_grade() → logo → grain=0.065 (heavy grain)
- _t7_peach_grade: Step1=blend 40% toward warm_neutral(210,180,175), Step2=lum-weighted peach tint 0.35→(255,205,190)
- ❌ NO pure Python bg=(212,111,171) — must use nano_edit for correct rounded block font

### Template sources (ALL 8 use nano_edit) — H-batch / cat08-v4/
- T1: cat08-full/A1-script-ai.png — prev: ["she is always going to","choose herself","in the end."]
- T2: cat08-full/A2-notecard-ai.png — prev: "you came too far to only settle for less. xx"
- T3: cat08-full/A3-display-ai.png — prev: ("choose","YOUR","peace now.")
- T4: cat08-full/A4-list-ai.png — prev: building/selective/becoming/enough/the plan/arriving/her own magic/the energy/YOU
- T5: mirra-pinterest-refs/08-typographic-quote/gradient-believe-yours.jpg — prev: ["BELIEVE","ITS","ALREADY","YOURS"] — workflow: nano_edit → vignette(18) → logo → grain=0.016
- T6: mirra-pinterest-refs/08-typographic-quote/editorial-serif-be-picky.png — workflow: nano_edit → mirra_filter(ov_alpha=32, desat=0.82, sparkle_n=3) → logo → grain=0.018 ← mirra_filter REQUIRED to restore warm blush-satin bg colour
- T7: mirra-pinterest-refs/08-typographic-quote/block-bold-more-self-love.jpg — workflow: nano_edit → peach_grade → logo → grain=0.065
- T8: mirra-pinterest-refs/mirra photo type/cf0ed5c1abbd2601296fabccae3539c4.jpg — "DREAM UNTIL ITS YOUR REALITY" — dark olive-grey wall, mauve-pink rhinestone hand-formed ALL CAPS. Workflow: nano_edit → logo → grain=0.028. IS Mirra-appropriate when using nano_edit (preserves warm mauve-pink rhinestones). ❌ ONLY rejected if generated from scratch with cold colours.

### Brand DNA — confirmed by full pixel-level ref study (H-batch calibration)
- **Colour**: warm cream/bone bg (#F5EEE6), deep wine text (#8B2635), blush/rose-gold accents. NEVER cold, NEVER fuchsia.
- **Typography**: mixed-weight serif + flowing script for emotional keywords. Deep wine on cream = Mirra signature. Script = Great Vibes / Pacifico energy.
- **Sparkle**: 4-point star lens flares + warm gold/peach micro-dot scatter. Physical sparkle (rhinestones, sequins, glitter). Warm not cold/rainbow.
- **Photo type**: warm-toned real photography (rose gold sunset, mocha, peach). Styled everyday objects elevated. Quote-on-architecture format. Moody not bright studio.
- **Typography refs**: striped pink bg + serif/script mix; clean cream + editorial mixed-weight; bone white + bow motif; pink billboard bold sans-serif; dark wall rhinestone; pink brush-script.

### fal.ai API
- Model: fal-ai/nano-banana-pro/edit
- Parameter: `image_urls` (array, NOT `image_url` singular) → 422 error if wrong
- Used for ALL 8 templates (T1–T8). Balance exhausts — top up at fal.ai before running.

---

## cat02 — Glitter Billboard Quote: DNA rules

### 7 usable templates (M-batch / cat02-v1/)
- M1: `a02cacad` — pink glitter vintage diner roadside sign. Lowercase mixed-case.
- M2: `billboard-do-not-take-yourself-seriously` — CGI billboard, dark blue-purple sky, 4-point star sparkles
- M3: `window-main-character-energy` — shop window golden sunset, rose-gold glitter decal
- M4: `marquee-stay-focused-extra-sparkly` — 3D rhinestone crystal letters, mauve-purple theatre facade
- M5: `cinema-you-are-bigger-than-anxious` — Cinegrill cinema marquee, warm peach glow
- M6: `cf0ed5c1` — dark slate rhinestone wall. **2-line max rule** (same as cat08 T8)
- M7: `3035d6a8` — holographic silver glitter sticker letters on grey card

### Excluded refs (NOT Mirra brand)
- ✗ `9326f80997` — "boy, you got me walkin' side to side" (boy-focused content)
- ✗ `c9b278d2` — "look at you, boy I invented you" (boy-focused content)

### cat02 filter — upgraded pipeline (cat02_batch.py)
- OLD (cat02_full.py): flat overlay + ImageEnhance.Contrast/Brightness → muddy
- NEW (cat02_batch.py): S-curve + shadow-protected overlay + warm tint (same DNA as cat08/cat04)
- **Heavy sparkle preserved**: 24–42 lens flares (cat02 is a GLITTER series)
- S-curve: xp=[0,40,128,200,255] → fp=[0,30,128,220,255] (moderate, for real photography)
- shadow-protected overlay: ov_weight=clip((lum-0.18)/0.38,0,1), ov_color=(248,190,205)
- warm_strength=0.08–0.10 (lighter than cat04/cat08 — scenes already have warm tones)
- Vignette: cinema=55, wall=40, others=0
- Model: nano_edit (fal-ai/nano-banana-pro/edit) — same as cat08

### Batch sequence
- cat08 L-batch (cat08-L/) = Warm Champagne Gold tone, BATCH_PREFIX="L"
- cat02 M-batch (cat02-v1/) = standard blush, BATCH_PREFIX="M" ← current

---

## cat03 — Attitude Meme Still: DNA rules

### 8 templates (N-batch / cat03-v1/)
| File | Scene type | Text style | Colour mood |
|------|-----------|-----------|-------------|
| blair-waldorf | Gossip Girl TV still, tiara + Chanel | Bold white italic centred | Warm dark moody |
| mean-girls | Mean Girls pink heart mirror | Subtitle bar bottom | Blush pink soft |
| 2b9044d7 (bubble bath) | Vintage film, bubble bath + teacup | Bottom subtitle text | Warm blush pink |
| 51a052f7 (vintage film 2-panel) | 1960s film split panels | Subtitle both panels | Warm grain vintage |
| pink-bunny / 737f (same file) | Modern editorial, bunny ears + fur | iOS notification bubble | All-pink editorial |
| 907db8f4 (Sleeping Beauty) | Disney animation, purple sparkle | Direct text overlay | Purple violet glitter |
| f2880c3472 (glowtoons femme) | Vintage animation, femme fatale | Direct text overlay | Dark moody purple |

Note: 737f8599 and pink-bunny-editorial-girl.jpg are duplicates — use pink-bunny-editorial-girl.jpg

### Workflow rules
- **Type A** (filter only): keep iconic quote as-is. These memes are famous — the quote IS the content.
- **Type B** (nano_edit): swap fresh Mirra quote onto same character/scene
- NO Python text overlay — text is always part of the scene, subtitle, or notification bubble
- iOS bubble (pink bunny) = nano_edit changes text inside the white rounded bubble
- Animation stills = nano_edit swaps the overlaid text
- glowtoons watermark: bottom-right → remove before processing

### cat03 filter pipeline
- Finish: nano_edit (if text swap) → mirra_filter_03 → stamp_logo → add_grain (LAST)
- **S-curve**: very gentle — xp=[0,50,128,200,255] → fp=[0,42,128,215,255] (scenes already styled)
- **Blush overlay**: shadow-protected, ov_color=(248,190,205), ov_alpha=28–45
- **Warm tint**: warm_strength=0.08–0.12 (light — don't fight existing colour mood)
- **Grain**: 0.022–0.032 (heavier for film stills to enhance vintage feel)
- **Vignette**: 18–28 (always — deepens the scene, adds cinematic quality)
- **Sparkle**: LIGHT — 8–14 flares only. This is attitude/character content, not a glitter series.
  sparkle_color=(255,220,230) — soft pink-white, not harsh white
- Purple animation refs (Sleeping Beauty, glowtoons): lower warm_strength (0.06) — don't kill the purple mood, just add Mirra blush warmth at the edges

### Copywriting tone — cat03 specific
Core energy: **self-obsession as empowerment** — unapologetic, funny, sharp, a little narcissistic
- Self-love that's confident not soft: "obsessed with me too", "I'm so iconic"
- Money + soft life in the same breath: "inner peace, healing, and money"
- Selective filter expressed with zero apology: "if it's not making me richer/hotter/happier, I don't want it"
- Protection with attitude: "be careful who you invite into your soul"
- Trending vocab that fits: era, aura, locked in, for the plot, delulu, soft life, that girl, romanticize
- Format that works: lowercase, under 12 words, one-two sentence max
- ❌ NO "girl boss" / "queen" / "slay" (dated)
- ❌ NO relationship/boy content
- ❌ NOT too literal to character (don't write about sleeping just because Sleeping Beauty is shown)

### Approved quote examples for cat03 voice
- "she's not for everyone. that was always the point."
- "aura farming. no days off."
- "locked in. unavailable for anything that doesn't match her energy."
- "stayed delulu. look at her now."
- "soft life, hard standards."
- "not chasing anything. building something worth coming to."
- "she chose herself. again."
- "for the plot. always for the plot."
- "in her not explaining era."
- "her aura does the talking."

---

## Trending viral phrases — Mirra-approved (2025)
Researched March 2026. Use these — all confirmed high-share velocity:
- **"era"** — most flexible: "in her [x] era." / "locked-in era" / "not explaining era"
- **"delulu"** — "stayed delulu. look at her now." / "delulu is the solulu."
- **"aura" / "aura farming"** — "her aura does the talking." / "aura farming. no days off."
- **"lock in" / "locked in"** — "locked in. unavailable." discipline as identity
- **"for the plot"** — bold action reframed as narrative adventure
- **"not chasing. attracting."** — anti-hustle 2025 peak
- **"soft life"** — "the soft life was always the plan." choosing ease as power
- **"that girl"** — aspirational identity, still strong Pinterest
- **"romanticize"** — "romanticized herself first. the rest followed."
- **"black cat energy"** — mysterious, independent, doesn't chase
- **"she ate. no crumbs."** — flawless execution, viral phrase
- **"protect your peace"** — evergreen high-save
- **"understood the assignment"** — still recognized, use sparingly
- ❌ DO NOT use: girlboss (earnestly), brat (word, not spirit), very demure (past peak), girl math/dinner (past peak), boss babe, queen, killing it

---

## Drive upload — rclone configured
- Binary: `~/bin/rclone`
- Remote: `mirra-drive` (authorized with u/1 account, NOT yivonne@gaiaeats.com)
- Target folder ID: `1-dId20c-p4LCE25U-Np1282wwvSvBeQe`
- Upload command: `~/bin/rclone copy [folder]/ "mirra-drive:[subfolder-name]" --drive-root-folder-id 1-dId20c-p4LCE25U-Np1282wwvSvBeQe --exclude "_rejected/**" --exclude ".DS_Store"`
- drive_upload.py: wraps this command, auto-excludes _rejected/

---

## cat09 — Emoji Scene: DNA rules

### Category essence
Clean cream canvas + relatable text hook + 2-4 AI-generated emoji/sticker objects.
The objects ARE the punchline. Format is a visual joke: question/setup in text, answer via emoji.

### Two visual sub-types
| Type | Look | When to use |
|------|------|-------------|
| `3d` | Apple Memoji clay-render — smooth, rounded, warm 3D lighting | Girl character, people, expressive figures |
| `sticker` | Flat 2D cartoon — thick outline, pastel, illustrated | Objects, food, props, decorative items |

### Generation — ranked tools
1. **gpt-image-1** (OpenAI API, `background="transparent"`) — best quality, native alpha. Use if `OPENAI_API_KEY` in env.
2. **fal-ai/flux-lora** + `EvanZhouDev/open-genmoji` LoRA — Apple emoji style. Trigger word: `emoji,` prefix. Scale 1.0. → then **fal-ai/birefnet** Heavy + `refine_foreground=True`.
3. **fal-ai/flux-pro** (fallback) — with style prefix in prompt → fal-ai/birefnet.
- BiRefNet mode: `"General Use (Heavy)"` — preserves soft shadow edges on 3D objects. Never use default u2net.

### The Mirra girl locked prompt
Use `_MIRRA_GIRL.format(pose="...")` — swap only the `{pose}` portion, keep all other descriptors IDENTICAL across templates to maintain character consistency:
```
"Apple iOS Memoji 3D clay render style, stylish young woman, warm caramel-brown skin,
long wavy dark brown hair past shoulders, almond-shaped eyes, small gold hoop earrings,
fashionable minimal outfit, {pose}, smooth simplified rounded features, large expressive eyes,
soft warm studio lighting, transparent PNG, isolated character figure,
no background, no text, no words, no watermark"
```

### Filter — mirra_filter_emoji (minimal)
```python
arr = arr + 0.04 * (warm_cream - arr)  # 4% warm cream wash ONLY
# NO S-curve, NO desaturation, NO vignette, NO sparkle
# grain=0.016 separately, always LAST
```
Why minimal: emoji objects must keep their bright, saturated original colours. Any desaturation makes them look muddy. The cream bg (248,243,235) is already warm enough.

### Composition rules
- Text in top 25-30% (y < 380px)
- Objects in lower 65-70% — LARGE, they are the content (target_h 135-460px)
- 3 objects = optimal viral rhythm
- Battery frame for "question+answer inside battery" format: BLUSH_FRAME = (195, 135, 148)

### Typography
- Italic serif question: `InstrumentSerif-Italic.ttf`
- Bold italic rose punchline: `PlayfairDisplay-BoldItalic.ttf` in ROSE (172,55,75)
- ALL CAPS meme format: `BebasNeue-Regular.ttf`

### Voice for cat09 (different from cat03)
- Format: punchline is the OBJECT not the text — text sets up, emoji delivers
- Question format: "How do you [X]?" → me: [emoji objects]
- Reaction format: "[quote]" / [reaction] → [supporting emoji objects]
- Aspiration list format: "what she ordered:" → [objects representing desires]
- Keep text under 8 words per line — must be readable at scroll speed
- The joke should work as an emoji reply in a chat — that's the share trigger

### Refs
- `09-emoji-scene/0c9321351...jpg` — battery + Memoji shopping girl (layout ref E01)
- `09-emoji-scene/a4998717...jpg` — floating sticker objects + quote (layout ref E02)

## scan_refs.py — auto classifier
- Uses Google Gemini (`gemini-2.0-flash`) vision via `google.genai`
- `types.Part.from_bytes(data=img_bytes, mime_type=mime)` for inline image
- `GOOGLE_API_KEY` in .env
- Triggered by launchd `com.mirra.scan-refs` watching refs root folder
- Manifest: `scan_refs_manifest.json`
- Categories 01-08 mapped to subfolder names
