---
name: Mirra cook video — session state March 17-18 2026
description: Full state of the "6:20 PM" After Hours video project. Story locked, pipeline built, needs real reference images to ground the art direction. Resume from here.
type: project
---

## PROJECT: "6:20 PM" — After Hours Mirra Video

### Status: V2 FINAL delivered + HOOK version. Need more scene references for next iteration.

### DELIVERED VIDEOS
- `mirra_6_20_PM_v2.mp4` — 5 shots, Kling PRO, full pipeline
- `mirra_HOOK_5kg.mp4` — "i lost 5kg eating dinner every night" hook version
- `mirra_6_20_PM_FINAL.mp4` — trimmed, speed varied, lighter grain, clean BGM

### REFERENCE SCRAPING SYSTEM
- Pinterest scraper: WORKS (playwright, `pinterest_scraper.py`)
- YouTube scene extraction: WORKS (playwright, seek + screenshot video element)
- XHS: session saved at `~/.playwright_xhs_session/`. Can browse explore + search. Need to fix clicking INTO notes.
- IG: session saved. Need to fix clicking INTO reels.
- Gemini Vision: can analyze screenshots for forensic. Saved analysis at `GEMINI_FORENSIC.md`.
- 220+ screenshots in `vlog_screenshots/`

### TOOLS INSTALLED
- gstack `/browse` — headless Chromium with cookie support. Binary: `~/.claude/skills/gstack/browse/dist/browse`
- Bun: `~/.bun/bin/bun` (MUST add to PATH: `export PATH="$HOME/.bun/bin:$PATH"`)
- Pinterest scraper: `~/Desktop/Creative Intelligence Module/engine/scraper/pinterest_scraper.py`
- XHS Python package: `pip install xhs` (needs cookies for auth)
- Playwright persistent sessions: `~/.playwright_xhs_session/`

### SCRAPING STATUS
- XHS: IP blocked on headless. Need VPN or fresh IP. Non-headless Playwright with saved session DID work earlier (got explore + search screenshots). gstack browse got blocked too.
- IG: Cookies imported via gstack `/setup-browser-cookies`. 12 IG cookies saved. But browser session tainted by XHS block — need restart.
- YouTube: Playwright video-element screenshot method WORKS. Got 60+ scene screenshots from diet vlogs.
- Pinterest: Playwright scraper WORKS perfectly. 50+ refs scraped.

### NEXT SESSION PRIORITIES
1. Fresh `/setup-browser-cookies` for IG — import instagram.com cookies clean
2. Use gstack `/browse` to navigate IG reels → `snapshot -a` → `click @eN` into reels → `screenshot` scenes
3. For XHS: try with VPN or use the non-headless Playwright approach that worked before
4. Need: woman working, coming home, POV daily life, diet vlog face-to-camera, what I eat in a day — ACTUAL video scenes not grids
5. Once refs collected → forensic with Gemini Vision → build hook version
6. Hook: "i lost 5kg eating dinner every night" with food-first frame
7. Find better BGM (lo-fi casual, not yoga)

### NEW VIDEO: "i lost 5kg eating these everyday" (LUNCH BENTO)
Full brief at: `.tmp/mirra_cook/BRIEF_LOST_5KG.md`
- 13 scenes, 2 locations (condo + co-working), 5 Mirra bento food shots
- Persona: 30yo Chinese-Malaysian, marketing dept, drives to work
- Co-working: Common Ground Damansara Heights style
- Hook: weigh scale + "i lost 5kg eating these everyday"
- 5 bentos with dish names + calorie counts (all under 500 cal)
- Ending: mirror shot morning — she lost weight
- References: 98 screenshots + 2-4 actual videos in `reference_vids/`
- yt-dlp WORKS for TikTok + IG downloads — use this for all future reference gathering
- Pinterest scraper got 30 refs across all scene types in `pinterest_refs/lost5kg/`

### The story (LOCKED)
She comes home from a busy day → winds down → Mirra dinner is already waiting.
Subtle convenience message: she didn't cook. It was ready. Beautiful, nourishing, for her.

### The sequence (LOCKED)
1. Rain on condo window — arriving home (6:20 PM)
2. Phone face-down on counter — disconnecting
3. Shower — washing the day off (glass panel, steam)
4. After shower — making tea, changed into comfortable clothes
5. Sits down — food is ALREADY there (she didn't make it)
6. Top-down eating — spoon, Mirra food, tea beside it (the payoff)

### The copy (LOCKED)
`6:20 PM. home. the quiet part. already waiting.`
- Mabry Pro Bold, 64-100pt
- 6:20 PM at start. "already waiting." at the food reveal.

### What's BUILT
- Full production pipeline: NANO → Kling 3.0 → FFmpeg grade → librosa beat-sync → Remotion typography → FFmpeg grain → final
- Audio design system: rain + foley SFX per shot + BGM (Sun Salutations) enters late
- Typography: Mabry Pro Bold + DM Serif Display, loaded in Remotion
- Color grade: FFmpeg colorbalance (warm tungsten night + bright morning option)
- 4 ASMR SFX downloaded (ceramic_clink, water_pour, kitchen_ambience, hot_drink)
- Editorial fonts: Bodoni Moda, Cormorant Garamond, DM Serif Display, Libre Caslon Display, Playfair Display

### What FAILED (don't repeat)
- AI-generated refs look staged/spooky/European, not natural KL
- Character inconsistency — each NANO generation creates a different person
- Unsplash stock photos are useless for this — wrong vibe entirely
- Kling standard outputs SQUARE (960x960) not 9:16 — need Kling Pro
- Dark moody lighting ≠ real life. Need BRIGHT NATURAL like actual Korean vlogs.
- "Cinematic" angles (doorframe, overhead, through-laptop) are NOT vlog
- Text always "too cinematic" — real vlogs have casual font, not Mabry Bold 100pt
- Top-down editorial food shot ≠ vlog. Real vlog eating = face visible, food held toward camera

### CRITICAL VLOG ANGLE RULES (from Korean vlog research)
1. **Camera close to face** — front-facing camera at arm's length. NOT tripod distance.
2. **Eating = FACE + FOOD** — she holds food UP toward lens, or eats facing camera. NOT overhead editorial.
3. **Mirror selfie** — classic "just changed" shot. Phone at chest level in mirror.
4. **Selfie walking** — handheld, slightly tilted, real motion.
5. **MIX tripod + selfie + handheld** — variety IS the vlog feel. Not all one type.
6. **Real vlog props** — phone screen showing time, skincare products, real food packaging
7. Use v16_03_sofa as character anchor — same woman in all shots via NANO edit
8. Use pin_07_02 as mood anchor — same warm cream-blush white balance

### V1 DELIVERED
`~/Desktop/video-compiler/.tmp/mirra_cook/build/mirra_6_20_PM.mp4` — 87MB, 14s, 1080x1920
Full pipeline: Kling PRO → FFmpeg grade → librosa beat-sync audio (notification ding!) → Remotion Mabry Pro → FFmpeg grain → final merge

### V2 SHOT LIST (next session — FINAL VERSION)
1. **Arrive** — NEEDS NEW REF. User has a specific image at `~/Desktop/.tmp.driveupload/191109` (couldn't find, ask user to provide). Side view at counter dropping bag.
2. **Mirror selfie** — v17_02_mirror.jpg ✅ APPROVED. After changing to white tee + shorts.
3. **Sofa** — v16_03_sofa.jpg ✅ APPROVED. Start from lying down, no front hair flip.
4. **Eating** — v16_04_eating.jpg ✅ OK. Or try SIDE VIEW — same seat, just camera angle changed to her side/profile. NOT a new location.
5. **Selfie with bento** — NEEDS REDO. Must be FRONT CAMERA POV — camera IS her phone. We see her face looking DOWN at the phone/camera. Like the Taiwan vlog ref (Screenshot 2026-03-18 at 12.57.10 PM). She holds Mirra bento up. Subtle smile. NOT someone else's camera angle.

### CRITICAL FIXES for next gen:
- Selfie = FRONT CAMERA POV. Camera is the phone screen. She looks at US. Not third-person.
- Eating side view = same table, same seat position as v16_04. Just camera moves to her side. She doesn't change position.
- Arrive = user has a specific reference image. Ask them to provide it.
- All same character (dark brown hair, shoulder length, v16 woman)
- All same apartment (cream sofa, blush walls, white coffee table)

### References saved
- Pinterest scrape: `pinterest_refs/` (29 images) + `pinterest_refs/vlog_grid/` (24 images)
- Korean vlog eating refs: `~/Downloads/hq720 (1).jpg`, `~/Downloads/images (4).jpeg`
- Korean vlog style refs: `~/Desktop/Screenshot 2026-03-18 at 12.57.10 PM.png` etc.
- User's own reference images in Downloads + Desktop

### What's NEEDED next session
1. **5-6 REAL reference images** from Korean vlogs, XHS, or Pinterest:
   - Rain on apartment window at night (Asian city)
   - Woman's hand on counter/phone (natural lighting, real kitchen)
   - Shower glass panel with steam (modern bathroom)
   - Woman in white tee making tea (real kitchen, bright)
   - Woman sitting with food already on table (natural, not staged)
   - Top-down eating shot (real, not stock)
2. **NANO edit** each reference into Mirra's world (same woman via character consistency)
3. **Kling Pro** for native 9:16 output (not standard which gives square)
4. Run full pipeline

### Files location
- Working dir: `~/Desktop/video-compiler/.tmp/mirra_cook/`
- Approved V9 product refs (shades, laptop, golden hour): `refs/v9/`
- V11 story refs (rain, phone, shower, tea, sitting, eating): `refs/v11/`
- Pipeline scripts: `generate_final.py`, `pipeline_full.py`
- Remotion comp: `remotion/src/MirraCookComposition.tsx`
- Production bible: `CREATIVE_BRIEF_V10.md`
- All builds: `build/`

### Key memory files to read
- `creative-intelligence-video-art-direction-mastery.md` — READ FIRST. Full video mastery system.
- `feedback_video_craft_v4_learnings.md` — ohneis + Ana forensic learnings

### SYSTEMS BUILT (March 18-19 session)
1. **Production Continuity System** — 4 agents (Director/Art Director/Wardrobe/QC)
2. **Reference Mastery System** — 5-dimension scoring, taxonomy, curation, forensic
3. **Video Template Registry** — 6 templates (T1-T6), reusable for any brand
4. **Storyboard-First Workflow** — spec → storyboard → approve → generate → QC
5. **33 Hard Lessons** — every failure pattern documented
6. **QC Regression** — Gemini Vision audits all outputs against spec (79% fail rate found)
7. **Organized Reference Library** — 94 refs scored + sorted into 13 categories
8. **Scene Spec Sheet** — complete for "Lost 5kg" video with wardrobe + continuity
9. **Character Lock** — v3 approved, documented in CHARACTER_LOST5KG.md
10. **gstack /browse** — installed with cookie import for IG/XHS scraping
