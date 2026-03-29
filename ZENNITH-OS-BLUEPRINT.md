# ZENNITH OS — Complete System Blueprint
> THE source of truth. Read this FIRST every session. Every detail preserved.
> Last updated: 2026-03-29 by Taoz (Claude Code Opus 4.6)

---

## 1. WHAT THIS IS

Zennith OS is a multi-agent AI content production system for 14 brands.
It produces images, videos, ads, readings, and social content.
The goal: viral content that converts → customers → revenue.

**The 3 systems that must work as ONE:**
- **Tricia** (video-compiler) — production discipline, AIDA blocks, 100-point QA
- **Yivonne** (creative intelligence) — edit-first, 8 DNA qualities, reference mastery
- **Zennith Core** (this repo) — orchestration, agents, skills, infrastructure

---

## 2. THE 6 AGENTS (Fixed Roles, No Overlap)

| Agent | Name | Role | ONLY Does | NEVER Does |
|-------|------|------|-----------|-----------|
| main | Zenni | Router | Classify, dispatch, acknowledge | Generate content, write code |
| taoz | Taoz | Builder | Code, infra, deploy, test, audit workflows | Creative decisions, copy |
| dreami | Dreami | Creative | Script, copy, visual direction, prompts | Code, deployment |
| scout | Scout | Intel | Research, scrape, analyze, report | Generate, code |
| tricia | Tricia | Video Prod | Video pipeline, blocks, assembly, QA | Image gen, brand voice |
| yivonne | Yivonne | Visual Design | Image production, character lock, style | Video assembly, code |

---

## 3. THE ORCHESTRATOR (content-brain.sh)

**Location:** `~/.openclaw/skills/content-brain/scripts/content-brain.sh`
**Symlink:** `~/zennith-skills/skills/content-brain/scripts/content-brain.sh`

### 3 Modes:
```bash
content-brain.sh produce  --brand X --type Y    # Execute production pipeline
content-brain.sh plan     --brand X              # Weekly content calendar
content-brain.sh brain    --brand X              # Daily intelligence review
```

### The 12-Step Pipeline (produce mode):
```
Step 1:  BRIEF         → creative-reasoning-engine + cre-to-brief.sh
Step 2:  PLAN          → flow-alphabet.json (13 flows A-M) + sequence templates
Step 3:  SCRIPT        → video-script-gen.sh (7 Craft Rules)
Step 4:  SCRIPT QA     → creative-qa.sh script + brand-voice-check.sh
Step 5:  CHARACTERS    → character-lock.sh load + refs (MANDATORY)
Step 6:  REFERENCES    → NanoBanana with face refs (60% rule) + ref frame
Step 7:  VOICEOVER     → ai-voiceover voiceover.sh (Edge TTS free / ElevenLabs premium)
Step 8:  VIDEO CLIPS   → video-gen.sh IMAGE-TO-VIDEO (NEVER text-to-video for characters)
Step 9:  ASSEMBLY      → remotion-render.sh OR video-forge.sh assemble
Step 10: POST-PROD     → video-forge.sh effects (grain LAST) + brand overlay
Step 11: QUALITY GATE  → creative-qa.sh audit (100 points, DELIVER or BLOCK)
Step 12: DISTRIBUTE    → social-publish + block-library register + learnings
```

### CRITICAL RULES IN THE PIPELINE:
1. **Character-lock is MANDATORY** (Step 5) — refuses to run without face refs
2. **Image-to-video ONLY** (Step 8) — when scene refs exist, uses i2v not t2v
3. **Audio FIRST** (Step 7) — VO timestamps lock all block durations
4. **Grain LAST** (Step 10) — always final post-processing step
5. **QA gate is non-negotiable** (Step 11) — DELIVER or BLOCK, no "good enough"

---

## 4. THE CURATOR / CREATIVE INTELLIGENCE

### What It Does:
Decides WHAT to create, WHY, and HOW it should look — BEFORE any generation.

### The Intelligence Chain:
```
DAILY INTEL (Scout)
├── Competitor monitoring (daily-intel.sh)
├── Trend scraping (content-scraper)
├── Reference gathering + 5-dimension scoring
└── Output: daily-intel digest

CREATIVE REASONING (Dreami)
├── creative-reasoning-engine → concept + hook
├── 5 steps: Persona Audit → Format Library → Concept Collision → Hook Psychology → Diversity Gate
├── cre-to-brief.sh → structured JSON brief
└── Output: brief with concept, hook, format, funnel position

REFERENCE INTELLIGENCE (Yivonne's rules)
├── References = 50% of output quality
├── Score every ref: Angle, Authenticity, Adaptability, Mood, Platform (≥3.0)
├── Deep forensic analysis (WHY it works, not just WHAT)
├── Edit-first framing: "edit this, swap X" not "create inspired by"
└── Output: scored reference set + recreation prompts

STORYBOARD (4-Agent Pre-Gen Check)
├── DIRECTOR: story logic, continuity, scene flow
├── ART DIRECTOR: reference matching, mood consistency
├── WARDROBE: outfit continuity across scenes
├── QC: will audit post-generation against this spec
├── USER APPROVES storyboard BEFORE generation
└── Output: approved scene spec sheets
```

---

## 5. THE AUDIT LOOP (Generate → Audit → Feedback → Regenerate)

This is THE quality system. Never one-shot generate and ship.

```
┌─────────────────────────────────────────────┐
│  INTELLIGENCE A: GENERATES                   │
│  (Dreami/NanoBanana/Kling/Seedance)         │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│  INTELLIGENCE B: AUDITS (cross-agent)        │
│  Checks:                                     │
│  - character-lock: face consistent?          │
│  - brand-voice-check: tone/never-list?       │
│  - creative-qa: 100-point scoring            │
│  - Yivonne's 8 DNA qualities                │
│  - Tricia's AIDA monotonicity               │
│  Result: PASS / FAIL + specific feedback     │
└──────────────────┬──────────────────────────┘
                   ↓
         ┌────────┴────────┐
         │ PASS?           │
         ├── YES → SHIP    │
         └── NO ↓          │
┌─────────────────────────────────────────────┐
│  FEEDBACK: What failed, why, how to fix      │
│  - "Face drifted — hair turned blonde"       │
│  - "Lighting too cool — needs 3200K warm"    │
│  - "Missing jade pendant — add to prompt"    │
│  → Re-engineer prompt/context                │
└──────────────────┬──────────────────────────┘
                   ↓
         REGENERATE (max 2-3 cycles)
                   ↓
         RE-AUDIT → PASS or KILL
```

### Where Audit Happens:
| Step | Generator | Auditor | What's Checked |
|------|-----------|---------|---------------|
| Script | video-script-gen | creative-qa script | 7 Craft Rules, brand voice |
| Character | NanoBanana | character-lock validate | Face, hair, pendant, style |
| Scene image | NanoBanana | Yivonne 8 DNA qualities | Lighting, camera, texture |
| Video clip | Kling/Seedance | Vision QA | Face consistency, artifacts |
| Assembly | Remotion/FFmpeg | creative-qa video | Resolution, codec, safe zones |
| Final | video-forge | Tricia 100-point | Everything |

---

## 6. CHARACTER LOCK SYSTEM

### Jade Oracle Character Spec:
**File:** `~/zennith-skills/skills/character-lock/schemas/jade.character.json`

| Attribute | Value |
|-----------|-------|
| Ethnicity | Korean |
| Age | 31 (early 30s) |
| Hair | DARK BROWN ALMOST-BLACK LONG HAIR PAST SHOULDERS WITH SOFT CURTAIN BANGS |
| Eyes | Warm brown — NOT blue, NOT grey |
| Skin | Fair luminous K-beauty glass skin |
| Expression | Calm knowing smile |
| Signature | Jade teardrop pendant necklace (EVERY image) |
| Style | iPhone candid — NEVER editorial, NEVER studio, NEVER CG |
| Lighting | Natural window light, golden hour, candlelight — NO flash |

### Face Lock References (5 locked + 2 body):
```
~/.openclaw/workspace/data/characters/jade-oracle/jade/face-refs/
├── jade-d2-anchor.png       (PRIMARY — 2.3MB)
├── jade-d3-anchor.png       (angle 2 — 2.6MB)
├── jade-ig2-market.png      (lifestyle — 2.5MB)
├── jade-ig3-restaurant.png  (lifestyle — 1.9MB)
└── jade-ig4-journaling.png  (lifestyle — 2.5MB)

~/.openclaw/workspace/data/characters/jade-oracle/jade/
├── body-ref.jpg             (52KB)
└── body-ref-headless.png    (3.1MB)
```

### Commands:
```bash
character-lock.sh load --brand jade-oracle --character jade        # Load spec
character-lock.sh load --brand jade-oracle --character jade --json  # JSON output
character-lock.sh validate --brand jade-oracle --character jade --prompt "..."  # Validate
character-lock.sh refs --brand jade-oracle --character jade         # Get ref paths
character-lock.sh list                                              # All characters
```

### Rules (enforced in code):
- Face refs ≥ 60% of all reference images
- Prompt suffix ALWAYS appended: "Photorealistic iPhone candid quality. DARK BROWN ALMOST-BLACK LONG HAIR..."
- "editorial" in prompt → FAIL (caught by validate)
- style-seed + ref-image together → FORBIDDEN

---

## 7. THE FACE-LOCKED VIDEO PIPELINE

### WRONG way (produces random face):
```bash
video-gen.sh kling text2video --prompt "woman reading cards..."  # ❌ RANDOM FACE
```

### RIGHT way (face stays locked):
```bash
# Step 1: Load character refs
REFS=$(character-lock.sh refs --brand jade-oracle --character jade)
SUFFIX=$(character-lock.sh load --brand jade-oracle --character jade --json | \
  python3 -c "import json,sys; print(json.load(sys.stdin)['rules']['prompt_suffix'])")

# Step 2: Generate scene image with face refs (NanoBanana)
nanobanana-gen.sh generate --brand jade-oracle \
  --prompt "Jade reading oracle cards at café. $SUFFIX" \
  --ref-image "$REFS" --use-case character

# Step 3: Animate with image-to-video (face anchored to image)
video-gen.sh kling image2video --image <scene-image.png> \
  --prompt "Woman places oracle card, warm candlelight. $SUFFIX" \
  --duration 5 --aspect-ratio 9:16
```

### Full automated pipeline:
```bash
# Option A: Direct Jade character video
jade-character-video.sh --scene "reading oracle cards at café" --provider kling

# Option B: Reference-based recreation
ref-to-jade-video.sh --ref https://tiktok.com/video123 --scenes 5 --provider kling
```

---

## 8. ALL SKILL LOCATIONS (Quick Reference)

### Core Production Skills:
```
~/.openclaw/skills/content-brain/scripts/content-brain.sh      # Orchestrator
~/.openclaw/skills/character-lock/scripts/character-lock.sh     # Identity enforcement
~/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh         # Image generation (Gemini)
~/.openclaw/skills/video-gen/scripts/video-gen.sh               # Video generation (5 providers)
~/.openclaw/skills/video-gen/scripts/seedance-gen.sh            # Seedance via PiAPI
~/.openclaw/skills/video-forge/scripts/video-forge.sh           # Post-production (FFmpeg)
~/.openclaw/skills/remotion-renderer/scripts/remotion-render.sh # Remotion ($0 renders)
~/.openclaw/skills/remotion-renderer/scripts/jade-content-gen.sh # Jade templates
~/.openclaw/skills/remotion-renderer/scripts/jade-character-video.sh # Face-locked video
~/.openclaw/skills/video-block-library/scripts/block-library.sh # AIDA block library
~/.openclaw/skills/video-script-gen/scripts/video-script-gen.sh # Script generation
~/.openclaw/skills/creative-qa/scripts/creative-qa.sh           # Quality gate
~/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh # Brand compliance
~/.openclaw/skills/ai-voiceover/scripts/voiceover.sh            # TTS voiceover
~/.openclaw/skills/visual-registry/scripts/visual-registry.sh   # Asset registry
~/.openclaw/skills/lora-trainer/scripts/train-lora.sh           # LoRA training (FAL)
~/.openclaw/skills/social-publish/scripts/social-publish.sh     # IG posting
~/.openclaw/skills/content-brain/scripts/ref-to-jade-video.sh   # Ref → face-locked video
```

### Tricia's System (cloned, for reference):
```
~/tricia-hub-new/Video Compiler/     # 60 Python tools, Remotion, configs
~/tricia-hub-new/Image Pipeline/     # 10 character generation tools
~/tricia-hub-new/TOFU Content/       # Brand-building content framework
~/video-compiler/                    # Original clone (same content)
```

### Key Config Files:
```
~/zennith-skills/skills/remotion-renderer/config/
├── jade-oracle-templates.json       # 4 video templates + hooks library
├── jade-production-spec.md          # Research-backed format specs
├── flow-alphabet.json               # 13 flows A-M
├── text-style-presets.json          # Caption presets (CN/EN)
├── sequence-templates.json          # 6 AIDA assembly recipes
├── format-library.json              # 50+ creative formats
├── block-schema.json                # AIDA block taxonomy
├── color-grades.json                # Color grading presets
└── sfx-mapping.json                 # Sound effect triggers
```

---

## 9. API KEYS

| Key | Status | Location |
|-----|--------|----------|
| PIAPI_KEY | ✅ | ~/.openclaw/secrets/piapi.env |
| GOOGLE_API_KEY | ✅ | ~/.env |
| FAL_KEY | ✅ | ~/.openclaw/secrets/fal.env + ~/.env |
| EACHLABS_API_KEY | ✅ | ~/.openclaw/secrets/eachlabs.env + ~/.env |
| ELEVENLABS_API_KEY | ❌ | Not set (voiceover.sh uses Edge TTS free fallback) |
| REPLICATE_API_TOKEN | ❌ | Not set (lora-trainer uses FAL as primary) |

---

## 10. JADE ORACLE CONTENT STRATEGY

### The Unique Advantage:
Zero English QMDJ consumer content on Western social media. 1,080 gates vs 12 zodiac signs. Real-time divination (moment gate) no competitor can replicate.

### 5 Video Formats:
1. **Daily Oracle Card** (15s, $0 Remotion) — daily automated
2. **Pick-a-Card** (30-60s, $0 Remotion) — 3-part series, highest engagement
3. **Moment Gate** (15s, $0 Remotion) — QMDJ unique "if you're seeing this..."
4. **Hook Reel** (10s, $0 Remotion) — fate/prediction hooks
5. **Jade Character Video** (30-60s, $0.50-2 Kling/Seedance) — face-locked talking head

### Proven Hooks (from research):
1. "If you're seeing this, it's not a coincidence"
2. "Stop scrolling — the cards pulled YOU here"
3. "Pick a card. Trust your intuition"
4. "The cosmos computed this for the exact moment you're watching" (QMDJ unique)

### The Funnel:
Free content (TikTok/IG) → Comment engagement → Auto-reply mini reading →
$1 intro reading (QMDJ auto-generated) → Email nurture →
$97 full reading (auto-generated + video walkthrough) → $497 mentorship

### Content Generator:
```bash
jade-content-gen.sh daily-oracle     # Daily card reel
jade-content-gen.sh pick-a-card      # 3-part card series
jade-content-gen.sh moment-gate      # QMDJ fate hook
jade-content-gen.sh hook             # Random spiritual hook
jade-content-gen.sh batch --count 7  # Full day's content
```

### Oracle Card Deck (25 cards):
9 Archetypes (mapped from QMDJ 九星): Drifter, Healer, Warrior, Sage, Emperor, Architect, Blade, Mountain, Phoenix
8 Pathways (mapped from QMDJ 八门): Rest, Tomb, Strike, Veil, Stage, Open Road, Alarm, Garden
8 Guardians (mapped from QMDJ 八神): Crown, Serpent, Moon Mother, Union, White Tiger, Dark Warrior, Earth Mother, Sky Father

Data: `~/.openclaw/skills/psychic-reading-engine/data/jade-oracle-card-system.json`

---

## 11. RESEARCH INTEL (All Saved)

### Location: `~/.openclaw/workspace/data/content-intel/`

#### 2026-03-28/:
- MEGA-ANALYSIS.md — 29 posts mapped
- TRICIA-YIVONNE-ANALYSIS.md — 669 lines, 16 upgrades
- VIDEO-ARCHITECTURE-v2.md — 3-tier video pipeline
- ARCHITECTURE-AUDIT.md — 7 critical gaps (all fixed)
- DEEP-EXTRACTION.md — 50+ prompts from 29 posts
- GUIDES-DIGEST-SESSION2.md — Kling [cut], Joey brands, timkoda LoRA

#### 2026-03-29/:
- UNIFIED-OS-PROPOSAL.md — THE architecture document
- TRICIA-DISCIPLINE-RULES.md — 5 rules that make Tricia reliable
- SIRIO-4M-ANALYSIS.md — node editor, wrapper vs workflow
- GRACE-LEUNG-ANALYSIS.md — agent + skills architecture
- CHINESE-AI-FRAMEWORKS-ANALYSIS.md — process + context + roles
- JADE-CONTENT-DIRECTION.md — Jade content strategy
- SPIRITUAL-VIDEO-CONTENT-INTEL.md — hooks, formats, Psychic Samira
- UNIFIED-ASSET-ARCHITECTURE.md — 3-layer asset system

### Video Transcripts + Frames:
```
~/.openclaw/workspace/data/content-intel/2026-03-29/videos/
├── grace-marketing-team.en.srt      # Grace Leung AI Marketing
├── sirio-4m-workflows.en.srt        # Sirio $4M Workflows (31 min)
├── chinese-ai-frameworks.en-zh-Hans.srt  # Chinese AI Frameworks
├── sirio-video.mp4                  # Sirio video (31MB)
└── sirio-frames/                    # 62 frames extracted (key: 27,30,35,40,42,45,50,55)
```

---

## 12. WHAT'S BEEN COMMITTED (This Session)

```
3cd7e1f  Remotion renderer + 4 production skills (9,966 lines)
bbf147e  LoRA trainer + Seedance wiring + 12-step pipeline
dd217c7  Content Brain orchestrator
d065a96  Character Lock + Jade prompt fix
923d561  FAL + EachLabs keys, lip sync
965802c  Real E2E tests pass
dc4e9ef  Jade content generator (4 templates)
69bd18d  Research intel (3 videos + hooks)
495cbcf  CRITICAL: face-lock enforcement in pipeline
1756eb1  Face-locked video pipeline + production spec
2554be4  Ref-to-Jade pipeline
90b31b7  Learnings + asset architecture research
2d609be  Unified OS Architecture Proposal
3c23e7a  Cleanup
```

---

## 13. CONTINUATION COMMAND

```
continue from ZENNITH-OS-BLUEPRINT.md — this is THE source of truth.
Read Sections 3-5 for orchestrator + curator + audit loop.
Priority 1: Build Sirio canvas + audit workflows.
Priority 2: ONE quality Jade video through audit loop.
Priority 3: Tidy up + unify agents.
```
