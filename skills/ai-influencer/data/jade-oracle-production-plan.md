# Jade Oracle — Full Production Plan
> Steve Jobs standard. Every detail questioned. Every asset itemized.
> Last updated: 2026-03-17

---

## PART 1: CHARACTER BIBLE (The Person Behind Jade Oracle)

### 1.1 Character Foundation
**Approach**: Find a K-drama / movie actress as base reference, then tweak 3-4 features to create unique identity. This prevents the "AI generic" look and gives natural bone structure + expression range.

**Base Reference Candidates** (pick ONE, mix 2-3 features from others):
| # | Actress / Character | Why | Take From Her |
|---|-------------------|-----|--------------|
| 1 | **Bae Suzy** (Vagabond, Start-Up) | Warm approachable face, mystical aura possible | Jawline, eye shape |
| 2 | **Kim Go-eun** (Goblin, Little Women) | Ethereal, otherworldly quality | Skin tone, facial proportions |
| 3 | **IU / Lee Ji-eun** (Hotel Del Luna) | Literally played a supernatural being | Expressiveness, styling |
| 4 | **Jun Ji-hyun** (My Love from Star) | Strong, commanding, mystical presence | Cheekbone structure, gaze |
| 5 | **Kim Tae-ri** (Twenty-Five Twenty-One) | Modern + classic hybrid | Nose bridge, forehead shape |

**Character Tweaks (to avoid copyright + create uniqueness)**:
- [ ] Adjust eye spacing by 5-8%
- [ ] Mix skin tone between 2 references
- [ ] Unique beauty mark placement (left cheek, near eye)
- [ ] Hair: black with subtle dark auburn highlights (signature)
- [ ] Eye color: deep brown with amber ring (visible in close-ups)

### 1.2 Jade Oracle — Full Character Sheet

| Attribute | Detail |
|-----------|--------|
| **Full name** | Jade Lin (林玉) |
| **Age appearance** | 28-32 |
| **Ethnicity look** | Korean-Chinese mixed |
| **Height impression** | 5'6" (from framing) |
| **Voice** | Warm, slightly husky, measured pace, mystical but not breathy |
| **Accent** | Slight East Asian lilt, English fluent |
| **Signature look** | Minimalist gold jewelry, jade pendant, earth tones |
| **Personality** | Calm authority, gentle wisdom, occasional playful smile |
| **Catchphrase** | "The stars already know..." |
| **Brand color** | Deep jade green (#0A6847) + gold (#C5A662) + cream (#FFF8E7) |
| **Font** | Cormorant Garamond (headings) + Inter (body) |

### 1.3 World Building — Jade's Universe

Every detail must be consistent across ALL content. Generate these ONCE, reuse forever.

#### Living Space (appears in B-roll + lifestyle content)
| Asset | Description | When Used |
|-------|-------------|-----------|
| **Apartment overview** | Modern minimalist, floor-to-ceiling windows, city skyline at dusk, warm wood + white + jade accents | Establishing shots |
| **Reading nook** | Velvet green armchair, side table with crystal ball + incense, bookshelf with ancient texts | Close-up readings |
| **Desk/workspace** | Clean desk, Macbook, jade plant, Lo Shu grid artwork on wall, golden lamp | "Working" shots |
| **Altar/sacred space** | Low wooden table, candles, compass (luopan), crystals, dried flowers, incense smoke | Ritual/ceremony content |
| **Kitchen** | Bright morning light, matcha latte, minimal, one jade mug | Casual lifestyle |
| **Balcony** | City view, golden hour, plants, meditation cushion | Meditation content |

#### Favorite Places (B-roll locations)
| Place | Description | Content Type |
|-------|-------------|-------------|
| **Tea house** | Traditional Asian tea ceremony setting | Wisdom/storytelling |
| **Temple garden** | Stone path, bamboo, water feature, lanterns | Spiritual teachings |
| **Bookstore** | Cozy, warm light, ancient texts section | "What I'm reading" |
| **Mountain overlook** | Misty peaks, golden sunrise | Inspirational/motivational |
| **Night market** | Lanterns, warm glow, crowd blurred | Casual personality |

#### Best Friends / Recurring Characters
| Character | Role | Appears In |
|-----------|------|-----------|
| **Luna** | Best friend, Western spiritual counterpart | Collab content, "my friend says..." |
| **A black cat** | Pet/mascot, named "Yinyin" (阴阴) | Background in home shots, merch |
| **Grandmother (flashback)** | Taught Jade QMDJ as child | Origin story content |

#### Wardrobe (5 signature outfits, generate ALL)
| # | Outfit | When |
|---|--------|------|
| 1 | Cream silk blouse + jade pendant + gold earrings | Daily readings |
| 2 | Burgundy kaftan + long hair down | Evening/deep readings |
| 3 | White linen + minimal, hair up | Morning/casual content |
| 4 | Black turtleneck + gold chain | "Serious" predictions |
| 5 | Traditional hanfu-inspired dress | Special/ceremony content |

---

## PART 2: ASSET GENERATION CHECKLIST

### 2.1 Must-Generate Images (before ANY video production)

**Priority 1 — Face Lock (BLOCKING)**
- [ ] Front-facing headshot, neutral expression, studio lighting (MASTER REF)
- [ ] Front-facing, warm smile
- [ ] Front-facing, serious/contemplative
- [ ] 3/4 left turn
- [ ] 3/4 right turn
- [ ] Looking up (for "mystical gaze" shots)
- [ ] Looking down (for "reading" shots)
- [ ] Close-up eyes only (for transitions)
- [ ] Full body, standing, outfit #1
- [ ] Full body, standing, outfit #2
- [ ] Full body, seated, reading position
**Method**: Flux + LoRA training on these 11 images → portable .safetensors file
**Where**: `workspace/data/characters/jade-oracle/jade/face-refs/`

**Priority 2 — Environments (generate ONCE)**
- [ ] Apartment living room (wide shot)
- [ ] Reading nook (medium shot)
- [ ] Desk/workspace (medium shot)
- [ ] Sacred altar space (close-up)
- [ ] Kitchen morning scene
- [ ] Balcony golden hour
- [ ] Tea house interior
- [ ] Temple garden path
- [ ] Bookstore corner
- [ ] Mountain sunrise overlook
- [ ] Night market scene
**Method**: Flux/Midjourney, consistent style seed, save as "location pack"
**Where**: `workspace/data/characters/jade-oracle/environments/`

**Priority 3 — Props & Details**
- [ ] Jade pendant close-up (for merch mockup too)
- [ ] Luopan (feng shui compass) on table
- [ ] Crystal ball with mist
- [ ] Ancient book open to Lo Shu grid
- [ ] Incense smoke wisps
- [ ] Matcha latte in jade-colored mug
- [ ] Black cat "Yinyin" in various poses (3-5)
- [ ] Gold earrings close-up
**Where**: `workspace/data/characters/jade-oracle/props/`

**Priority 4 — Merch Mockups (for Shopify)**
- [ ] Phone wallpaper (jade aesthetic)
- [ ] Lo Shu grid poster
- [ ] "The stars already know" quote print
- [ ] Jade Oracle branded notebook
- [ ] Crystal set product photo
**Where**: `workspace/data/characters/jade-oracle/merch/`

### 2.2 Must-Generate Audio
- [ ] Voice clone sample (30-60s, warm mystical tone) → Fish Audio
- [ ] Voice ID saved in `secrets/fish-audio.env`
- [ ] Test phrases: "Your birth year reveals...", "The stars have aligned...", "Welcome to your reading..."
- [ ] Background music: Lo-fi mystical ambient (royalty free, 3 tracks)
**Where**: `workspace/data/characters/jade-oracle/voice/`

### 2.3 Must-Generate Video Templates
- [ ] 5-second intro animation (Jade Oracle logo + mystical particles)
- [ ] 3-second outro ("Follow for daily readings" + socials)
- [ ] Transition template (mystical smoke/stars wipe)
- [ ] Lower third template (name + "QMDJ Master")
**Where**: `workspace/data/characters/jade-oracle/templates/`

---

## PART 3: COMFYUI PIPELINE

### 3.1 Workflows We Have / Need

| Workflow | Source | Status | File |
|----------|--------|--------|------|
| **Enhancor Skin Fix** | Sirio Berati / HuggingFace | DOWNLOADED | `data/comfyui-enhancor-skin-fix.json` |
| **Consistent Character** | RunComfy (IPAdapter + InstantID + ControlNet) | NEED TO BUILD | — |
| **Lip Sync (LatentSync)** | ByteDance / ComfyUI wrapper | NEED TO DOWNLOAD | GitHub: ShmuelRonen/ComfyUI-LatentSyncWrapper |
| **Lip Sync (InfiniteTalk)** | RunComfy (Wan 2.1 + MultiTalk) | NEED TO DOWNLOAD | RunComfy workflow |
| **Wan 2.2 Animate + Swap** | RunComfy | NEED TO DOWNLOAD | RunComfy workflow ID 1307 |
| **Flux + LoRA** | Civitai / community | NEED TO BUILD | Custom for Jade face |

### 3.2 Enhancor Skin Fix Settings (from Sirio)
```
Denoise: 0.30-0.35 (preserve original, fix texture only)
CFG: 0.7-2.0 (lower = more natural blending)
Steps: 30 (sweet spot)
Method: Portrait segmentation → masked denoising → CFG-guided sampling → upscale
```

### 3.3 ComfyUI Hardware Note
Our iMac: Intel i5, 8GB RAM, NO NVIDIA GPU.
**Options**:
1. **Cloud GPU**: RunPod ($0.50-2/hr), Vast.ai ($0.20-1/hr) — run ComfyUI there
2. **RunComfy**: Browser-based ComfyUI hosting ($9.99/mo)
3. **Skip ComfyUI**: Use API-based tools (Flux via fal.ai, lip sync via HeyGen API)

**Recommendation**: Use fal.ai for Flux generation + HeyGen API for lip sync. ComfyUI only when we need the Enhancor skin fix post-processing. Run on RunPod when needed.

---

## PART 4: A2A BRIDGE (Jade VPS ↔ Zennith iMac)

### 4.1 Current State
| Component | Location | Status |
|-----------|----------|--------|
| Jade Oracle Bot | jade-os.fly.dev (Singapore) | LIVE, @Jade4134bot |
| QMDJ Engine | jade-os.fly.dev | LIVE, minimax-m2.5 |
| Zennith OS | iMac (local) | LIVE, 4 agents |
| OpenClaw Gateway | iMac localhost:3777 | LIVE |
| Bridge | ??? | DOES NOT EXIST |

### 4.2 A2A Architecture Needed

```
┌─────────────────────────┐     ┌──────────────────────────┐
│    JADE VPS (fly.dev)    │     │   ZENNITH iMAC (local)   │
│                          │     │                          │
│  Telegram Bot            │     │  OpenClaw Gateway :3777  │
│  ├─ User messages        │────▶│  ├─ Zenni (router)       │
│  ├─ QMDJ readings       │     │  ├─ Taoz (builder)       │
│  └─ Customer support     │     │  ├─ Dreami (creative)    │
│                          │◀────│  └─ Scout (research)     │
│  Webhook receiver        │     │                          │
│  ├─ Content posts        │     │  Content Factory         │
│  ├─ Schedule updates     │     │  ├─ jade-content-factory │
│  └─ Reading results      │     │  ├─ video-gen.sh         │
│                          │     │  └─ nanobanana-gen.sh    │
│  Self-Learning Store     │     │                          │
│  ├─ Q&A pairs           │     │  vault.db (knowledge)    │
│  ├─ Feedback log        │     │                          │
│  └─ Reading history     │     │                          │
└─────────────────────────┘     └──────────────────────────┘
```

### 4.3 Bridge Implementation (3 options)

| Option | Method | Pros | Cons |
|--------|--------|------|------|
| **A: Webhook relay** | VPS calls iMac webhook (ngrok/Cloudflare tunnel) | Simple, real-time | Needs tunnel, iMac must be on |
| **B: Shared room file** | Both read/write to a shared JSONL on Fly.dev volume | Decoupled, async | Polling delay, volume limit |
| **C: Fly.dev → OpenRouter → iMac** | VPS posts tasks to a queue, iMac polls | No tunnel needed | Higher latency, API cost |

**Recommended**: Option A (webhook relay via Cloudflare Tunnel)
- Free, persistent, no port forwarding
- `cloudflared tunnel` on iMac → exposes localhost:3777
- VPS posts to `https://zennith.{tunnel}.cfargotunnel.com/api/dispatch`

### 4.4 What Must Flow Between Them

| Direction | Data | Trigger |
|-----------|------|---------|
| VPS → iMac | New customer question (needs deeper reading) | Auto (complexity threshold) |
| VPS → iMac | Negative comment detected | Auto (sentiment filter) |
| VPS → iMac | Reading request ($97/$497 paid) | Auto (payment webhook) |
| iMac → VPS | Generated video content (URL) | Scheduled (3x/day) |
| iMac → VPS | Updated QMDJ knowledge | After vault.db digest |
| iMac → VPS | Customer resolution (refund/response) | After agent processes |

---

## PART 5: OPERATIONS & RESILIENCE

### 5.1 Comment Moderation Bot

```
TRIGGER: New comment/mention on TikTok/IG/YT
    ↓
SCAN: Sentiment analysis (negative? spam? scam? complaint?)
    ↓
CLASSIFY:
  ├─ POSITIVE → Auto-heart, queue for "thank you" reply
  ├─ QUESTION → Queue for Jade auto-reply (QMDJ mini-reading)
  ├─ NEGATIVE → Alert to Zenni, assess severity
  │   ├─ MILD (criticism) → Empathetic reply template
  │   ├─ MEDIUM (complaint) → Escalate to customer support flow
  │   └─ SEVERE (threat/harassment) → Hide comment, log, report
  ├─ REFUND REQUEST → Auto-create ticket, process refund, DM customer
  └─ SPAM/SCAM → Delete, block, report
```

**Implementation**: TikTok/IG comment APIs → Scout agent (sentiment) → auto-action

### 5.2 Self-Learning Q&A System

```
Every customer interaction:
  1. Log Q&A pair to jade-os.fly.dev:/data/qa-pairs.jsonl
  2. After 100 new pairs → trigger digest
  3. Digest extracts patterns:
     - Common questions → pre-built responses
     - Unique questions → flag for Jade personality expansion
     - Failed responses (negative follow-up) → improve
  4. Update QMDJ knowledge base on VPS
  5. Sync learnings to iMac vault.db via bridge
```

### 5.3 Crash Recovery Plan

| Failure | Detection | Auto-Recovery | Manual Fallback |
|---------|-----------|--------------|----------------|
| **Jade VPS down** | Fly.dev health check (built-in) | Auto-restart (Fly machines) | `fly apps restart jade-os` |
| **OpenRouter down** | API 5xx / timeout | Fallback: minimax-m2.5 → deepseek → qwen (chain) | Switch model in VPS env |
| **Telegram webhook fails** | No messages for 30min | Re-register webhook via cron | `curl telegram API setWebhook` |
| **iMac offline** | VPS can't reach tunnel | Queue messages on VPS, replay when iMac returns | Turn on iMac |
| **Gateway crash** | keepalive cron (every 5min) | Auto-restart via LaunchAgent | `openclaw gateway restart` |
| **Content pipeline fails** | Script exit code != 0 | Retry once, then alert Jenn via Telegram | Run manually |
| **API key expired** | 401 response | Alert Jenn, pause auto-posting | Renew key |
| **Rate limited** | 429 response | Exponential backoff, switch to free model | Wait or upgrade |
| **Payment webhook missed** | Customer paid but no reading | Shopify webhook retry (48h) + daily reconciliation | Manual check |
| **QMDJ calc wrong** | User reports bad reading | Flag, review, adjust calc, retrain | Manual review |

### 5.4 Monitoring Dashboard (minimum viable)

```
Every 15 minutes, Scout checks:
  □ jade-os.fly.dev/health → 200?
  □ VPS model responding? (test prompt)
  □ Telegram webhook registered?
  □ Last customer message < 6h ago? (if expecting traffic)
  □ OpenRouter balance > $5?
  □ Content queue has videos for next 24h?
```

---

## PART 6: BUSINESS OPERATIONS

### 6.1 Revenue Pipeline

```
FREE CONTENT (TikTok/IG/YT)
  ↓ "Comment your birth year"
  ↓ Auto-reply with mini teaser reading
  ↓ "Get your full reading → link in bio"
  ↓
$1 INTRO READING (Shopify)
  ↓ Deliver via email (auto-generated QMDJ report)
  ↓ Upsell in report: "Your full destiny map..."
  ↓
$97 FULL READING (Shopify)
  ↓ Detailed QMDJ destiny analysis (auto + human QA)
  ↓ Include video walkthrough by Jade (auto-generated)
  ↓ Upsell: "Monthly guidance program..."
  ↓
$497 MENTORSHIP (Shopify)
  ↓ Monthly QMDJ guidance
  ↓ Private Telegram group access
  ↓ Weekly personalized readings
  ↓ Priority response from Jade
```

### 6.2 Shopify Integration Needed
- [ ] Custom app "Jade Oracle Engine" (shpat_ token) — WAITING on Jenn
- [ ] jadeoracle.co domain connection — WAITING on Jenn
- [ ] Product pages: $1 intro, $97 full, $497 mentorship
- [ ] Payment webhook → VPS (trigger reading generation)
- [ ] Email delivery (Shopify email or SendGrid)
- [ ] Auto-generated PDF reading report

### 6.3 Content Calendar (Week 1 Pilot)

| Day | TikTok (3x) | IG Reels (1x) | YT Shorts (1x) |
|-----|-------------|---------------|-----------------|
| Mon | Birth year hook, QMDJ tip, Engagement bait | Best of 3 TikToks | Best of 3 TikToks |
| Tue | Monthly energy, Story, Birth year hook | Best performer | Best performer |
| Wed | Prediction, Spiritual tip, Q&A reply | Best performer | Best performer |
| Thu | Birth year hook, Behind scenes, QMDJ deep | Best performer | Best performer |
| Fri | Weekend energy, Engagement, Birth year | Best performer | Best performer |
| Sat | Saturday reading, Lifestyle, Spiritual | Best performer | Best performer |
| Sun | Weekly forecast, Reflection, Teaser for Mon | Best performer | Best performer |

**Week 1 = 21 TikToks + 7 Reels + 7 Shorts = 35 pieces**
**At $0.30-5/video = $10.50-175 for week 1 pilot**

---

## PART 7: ACTION PLAN (ORDERED)

### Phase 0: Accounts & Keys (Jenn does, today)
- [ ] Sign up Fish Audio → https://fish.audio → get API key
- [ ] Record 30-60s voice sample (warm, mystical, measured) → upload to Fish Audio → get voice ID
- [ ] Sign up HeyGen → https://heygen.com → $5 API deposit → Settings > API > get key
- [ ] Save keys to `~/.openclaw/secrets/fish-audio.env` and `~/.openclaw/secrets/heygen.env`
- [ ] Create Shopify custom app "Jade Oracle Engine" → get shpat_ token
- [ ] Connect jadeoracle.co domain

### Phase 1: Character Lock (Taoz builds, day 1-2)
- [ ] Select base actress reference(s) and define character tweaks
- [ ] Generate 11 face-lock images (master refs) via Flux/NanoBanana
- [ ] Run Enhancor skin fix on all generated faces (ComfyUI on RunPod or skip if quality sufficient)
- [ ] Train LoRA on face refs (FluxGym on fal.ai, ~$2-5)
- [ ] Generate 5 outfit variations
- [ ] Generate 11 environment images
- [ ] Generate 8 props images
- [ ] Store all in `workspace/data/characters/jade-oracle/`

### Phase 2: Voice & Templates (day 2-3)
- [ ] Clone voice on Fish Audio with recorded sample
- [ ] Test 5 script recordings, QA for naturalness
- [ ] Generate intro/outro/transition video templates
- [ ] Create lower-third overlay template (FFmpeg)

### Phase 3: Pilot Videos (day 3-5)
- [ ] Generate 5 scripts using `jade-content-factory.sh script`
- [ ] Generate voice for all 5 using `jade-content-factory.sh voice`
- [ ] Generate talking head for all 5 using `jade-content-factory.sh video`
- [ ] Assemble with `jade-content-factory.sh edit`
- [ ] QA: face consistency, lip sync quality, audio clarity, brand voice
- [ ] Speed-adjust if needed (1.2-1.5x)
- [ ] Add captions via video-forge.sh

### Phase 4: A2A Bridge (day 5-7)
- [ ] Install cloudflared on iMac
- [ ] Create persistent tunnel to localhost:3777
- [ ] Add relay endpoint on VPS (receive from iMac, send to iMac)
- [ ] Test: VPS sends task → iMac receives → processes → returns result
- [ ] Wire up content delivery: iMac generates video → uploads to CDN → VPS posts link

### Phase 5: Launch (day 7-10)
- [ ] Create TikTok account (@jadeoracle or similar)
- [ ] Create IG account (@thejadeoracle)
- [ ] Create YT channel (Jade Oracle)
- [ ] Post first 5 pilot videos
- [ ] Monitor engagement for 48h
- [ ] Adjust hooks/CTAs based on performance
- [ ] Scale to 3x/day TikTok cadence

### Phase 6: Automation (day 10-14)
- [ ] Set up `batch` mode with topic list rotation
- [ ] Wire comment moderation bot
- [ ] Set up Shopify payment webhook → reading generation
- [ ] Enable self-learning Q&A loop
- [ ] Deploy monitoring dashboard
- [ ] Set up crash recovery crons

---

## PART 8: COST PROJECTION

### Monthly Operating Cost (at scale)

| Item | Cost | Notes |
|------|------|-------|
| Fish Audio | $9.99/mo | 200 min voice (enough for ~200 videos) |
| HeyGen API | $99/mo | ~100 credits = ~100 min video |
| Kling (B-roll) | ~$30/mo | ~100 clips via fal.ai |
| RunPod (ComfyUI) | ~$10/mo | Occasional skin fix runs |
| Fly.dev VPS | $5/mo | Jade bot hosting |
| OpenRouter | ~$10/mo | Backup model access |
| Shopify | $39/mo | Basic plan |
| Domain | $12/yr | jadeoracle.co |
| **TOTAL** | **~$204/mo** | |

### Break-Even
- At $1/reading, need 204 readings/month to break even
- At 10K followers + 2% conversion = 200 readings/month
- **Target: 10K followers by month 3** (realistic with 3x/day posting)

### Revenue Potential (month 6+)
- 50K followers, $1 readings: $1,000/mo
- + $97 upsells (5%): $4,850/mo
- + $497 mentorship (1%): $2,485/mo
- **Potential: $8,335/mo at 50K followers**
