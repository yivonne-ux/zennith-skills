# AI Influencer Production Intelligence
> Compiled: 2026-03-17 | Sources: 4 research agent outputs (9 YouTube videos, 30+ tools, 50+ web sources)

---

## 1. Video Findings

### Video A: "Why My AI Videos Look Ultra Realistic -- Higgsfield AI"
- **Creator**: Dan Kieft (@Dankieft), 85K+ subs, Netherlands-based AI tools reviewer
- **URL**: youtube.com/watch?v=0B_xyflXrwc
- **Core thesis**: Higgsfield's DoP I2V-01 model reconstructs reality (not painting surfaces). Full camera control is the differentiator vs Runway/Pika.
- **Pipeline**: Flux base image -> Higgsfield camera movement (50+ presets: dolly, whip pan, crash zoom, FPV drone, bullet-time) -> style preset (VHS, Super 8, cinematic) -> 3-5 sec clips at 720p
- **Prompting**: Short (10-20 words) with emotion + movement. Example: "man turning head in city at night"
- **Storyboarding**: Popcorn tool generates 8-10 consistent images in narrative arc
- **Monetization angle**: Sells AI Toolkit (30+ tools) via Gumroad

### Video B: "Kling 3.0 Make Insanely Realistic AI Influencer Videos"
- **Creator**: Planet Ai (@planetai217)
- **URL**: youtube.com/watch?v=11hU2AoRA8M
- **Core thesis**: Kling 3.0 + Lucidpic + ElevenLabs is the quality pipeline
- **Pipeline**: Lucidpic/Flux character -> export multi-pose refs -> upload to Kling 3.0 Elements/Director Memory -> 15s 4K video with multi-shot storyboard -> ElevenLabs voice -> Kling native lip sync
- **Key detail**: ElevenLabs voice settings: Stability 45%, Similarity Enhancement 90%, Speech Enhancement 80%, high-authority voices (Marcus/Aria)
- **Kling 3.0 capabilities**: 15s 4K, physics-aware (gravity/collision/inertia), native audio sync (voice + SFX + music in single pass), multi-character with different languages (CN/EN/JP/KR/ES)

### Video C: "She's 100% Fake. (Create VIRAL AI Influencer in 5 Minutes)"
- **Creator**: Alisha Lewis | AI Ads (@AlishaLewisAI)
- **URL**: youtube.com/watch?v=IM7bP9KR6S4
- **Core thesis**: Higgsfield AI Influencer Studio enables zero-prompting character creation in 30 seconds at 4K
- **Pipeline**: Higgsfield preset character -> Soul ID lock -> 30-sec video with built-in voice -> post to socials
- **Key insight**: Zero-prompting removes all technical barriers. Pre-built templates tested for performance.

### Video D: "How to Make an AI Influencer on Instagram That Actually Makes Money"
- **Creator**: DIGITAL INCOME PROJECT (@DIGITALINCOMEPROJECT)
- **URL**: youtube.com/watch?v=gXaF4t4B4ss
- **Most detailed pipeline of all videos**
- **Pipeline**: Define niche -> ChatGPT/DeepSeek backstory -> Midjourney V6/Leonardo/Flux images -> FluxGym LoRA training -> FaceFusion cross-pose consistency -> MiniMax I2V video -> optimize for IG (1080x1080 posts, 1080x1350 portraits) -> post daily with 20-30 hashtags
- **Face consistency stack**: FluxGym LoRA (permanent identity), FaceFusion (cross-pose fix), Discord bot face swap, consistent seed bank (5-10 headshot anchors)
- **Revenue benchmarks**: Aitana Lopez = $10K+/month at 350K followers

### Video E: "I Used Higgsfield AI Influencer Studio to Create an AI Influencer That Looks TOO Real"
- **Creator**: Grow with Dani (@GroWith_Dani)
- **URL**: youtube.com/watch?v=BEa0jyDuTrM
- **Most detailed Higgsfield walkthrough**
- **Character creation detail**: 100K+ customization options across 4 categories (Face, Body, Skin, Style), including heterochromatic eyes, freckle density, scar placement, birthmarks, vitiligo, albinism
- **Motion Control**: Upload reference video of real human -> AI character mimics exact movement while retaining unique appearance -> choose background source (reference or character image)
- **Monetization**: Higgsfield Earn = 3-tier transparent reward system based on views/engagement/watch time. Claims of $100K/month possible.

### Video F (File 1): Claude Code + NotebookLM Tutorial
- Chinese-language video, NOT about AI influencers. About using Claude Code with NotebookLM for research workflows.

---

## 2. Tool Comparison Matrix

### Tier 1: Full AI Influencer Platforms

| Tool | Character Lock | Video Gen | Voice | Lip Sync | API | Monthly Cost | Best For |
|------|---------------|-----------|-------|----------|-----|-------------|----------|
| **Higgsfield** | Soul ID (excellent) | Sora 2/Kling/Veo (high) | Built-in TTS | Yes | Python SDK | Free-$249 | All-in-one social video |
| **HeyGen** | Digital Twin (good) | Avatar IV (high) | ElevenLabs integration | Yes (175+ langs) | REST (mature) | $24-$330 | Talking head + translation |
| **Captions AI** | AI Twin (good) | UGC-style (good) | Built-in | Yes (28+ langs) | REST suite | $15-$115 | UGC ads + editing |
| **Arcads** | Stock actors only | UGC ads (good) | Built-in | Yes | REST | $110-custom | Performance marketing ads |
| **Synthesia** | 230+ stock avatars | Business video (good) | 400+ voices | Yes (140+ langs) | REST | $18-$64 | Corporate training ONLY |
| **InfluencerStudio** | Built-in LoRA | Full pipeline | Integrated | Yes | Unknown | Subscription | End-to-end influencer |
| **Danex.AI** | Persona system | Photo + video | Scripted posts | Yes | Unknown | Subscription | End-to-end influencer |

### Tier 2: Talking Head / Lip Sync Specialists

| Tool | Quality | Speed | API | Monthly Cost | Notes |
|------|---------|-------|-----|-------------|-------|
| **Hedra** (Character-3) | 720p, full-body | Fast | REST + Node.js | $8-$60 | Live avatars $0.05/min via LiveKit |
| **D-ID** | Medium | Fast | REST (mature) | $6-$300 | API-first, best for chatbot integration |
| **Magic Hour** | Best lip-sync accuracy | Medium | Credits | Credits-based | Combines lip sync + face swap + video gen |
| **Fabric** | Excellent micro-expressions | 46-68% faster | $0.15/sec | Pay-per-use | Leads on body language |
| **OmniHuman v1.5** | Film-grade | Slow | Research only | Not available | ByteDance, single image + audio -> full body |

### Tier 3: Image Generation (Character Creation)

| Tool | Identity Lock | Quality | Cost | Notes |
|------|-------------|---------|------|-------|
| **OpenArt** (Character 2.0) | Identity Locking (best) | High | $12-48/mo | One ref image locks jawline/skin/features |
| **Flux 2 Pro + LoRA** | LoRA training (most reliable) | Highest | ~$2-5/training | Portable 50-150MB model file |
| **Midjourney V6** | Character ref (good) | Highest aesthetics | $10-60/mo | Best for initial concept/design |
| **Leonardo AI** | Face Lock (medium) | Good | Free tier | Good free alternative |
| **Lucidpic** | Model training | Good | Varies | AI model generator |
| **RenderNet/Affogato** | FaceLock + TrueTouch | High | Subscription | Skin rendering specialist |

### Tier 4: Voice

| Tool | Quality | Clone Speed | Languages | Monthly Cost | Cost per 1M chars |
|------|---------|-------------|-----------|-------------|-------------------|
| **ElevenLabs** | Gold standard (emotional) | Minutes | 29+ | $5-$330 | ~$165 (Scale plan) |
| **Fish Audio** | Matches ElevenLabs | Fast | Many | **$9.99** (200 min) | ~$15 |
| **PlayHT** | High | Fast | 140+ (cross-lang clone) | Tiered | Competitive |
| **Resemble AI** | High | 10 seconds of audio | 100+ | Pay-per-use | ~3x cheaper than ElevenLabs |
| **Cartesia** | High | Fast | Many | Competitive | Best quality/price balance |
| **Smallest.ai** | Good | Fast | Many | Pay-per-use | **$0.02/min TTS, $0.045/min clone** |

### Tier 5: Video Editing & Distribution

| Tool | Auto-Chop | Captions | Scheduling | Monthly Cost |
|------|-----------|---------|------------|-------------|
| **OpusClip** | Yes + virality score | Yes | 6+ platforms | Free-$69 |
| **Submagic** | Yes | 99% accuracy | Auto-publish | $19-49 |
| **quso.ai** | Yes | Yes | 7 platforms | Subscription |
| **CapCut** | Yes | Yes | No | Free/Pro |
| **VEED** | Yes | Yes | No | $18-59 |

---

## 3. Higgsfield Deep Dive

### Company
- Founded by ex-Snap AI team
- $1.3B valuation (unicorn)
- 15M+ users, 4.5M videos/day
- $200M annual revenue within 9 months of launch
- 85% of users are social media marketers

### Core Technology
- NOT its own AI model. Packages: OpenAI GPT-4.1/GPT-5 (planning) + Sora 2 (video) + Kling + Veo 3.1 + Minimax
- Proprietary motion transfer technology
- DoP I2V-01 model for camera reconstruction

### Soul ID (Character Consistency)
- Lock character identity from a single generation
- Maintains 100% facial consistency across ALL future content
- Works across different outfits, scenarios, lighting conditions
- Persists permanently once saved

### AI Influencer Studio
- Zero-prompting character creation via dropdown presets
- 100+ adjustable parameters (body type, aesthetics, fantasy/realistic)
- 4 customization categories: Face, Body, Skin, Style
- Extreme detail: heterochromatic eyes, freckle density, scar placement, birthmarks, vitiligo
- Gender options: Male, Female, Non-binary, Trans
- Ethnicity: African, Asian, European, Middle Eastern (or combine)
- Character types: human, fantasy creature, hybrid, non-human
- 4K output, ~30 second processing

### Cinema Studio 2.0
- 50+ camera movement presets (dolly, whip pan, crash zoom, FPV drone, bullet-time)
- Visual style presets (VHS, Super 8mm, cinematic, abstract)
- Combine multiple camera movements without post-editing

### Motion Control
- Upload reference video of real human movement
- AI character mimics exact movement while retaining unique appearance
- Choose background: reference video or character image
- Text prompts for additional scene elements

### Popcorn (Storyboarding)
- Generate 8-10 consistent shots in narrative arc
- Character consistency maintained across entire storyboard

### Higgsfield Earn (Monetization)
- Built-in revenue tracking
- 3-tier transparent reward system
- Compensation: views + engagement + watch time
- Claims of creators hitting $100K/month

### API
- **Endpoint**: `cloud.higgsfield.ai`
- **SDK**: `higgsfield-client` (Python, pip install)
- **Requirements**: Python 3.8+
- **Auth**: Dashboard API key
- **Features**: Sync/async, batch processing, webhook callbacks, custom parameter presets
- **Documentation**: Described as "sparse"
- **Access**: Enterprise plan for full API

### Pricing

| Plan | Monthly | Annual | Credits | Notes |
|------|---------|--------|---------|-------|
| Free | $0 | -- | 40/day (10 in some sources) | No watermarks |
| Basic | $9 | -- | 150 | 2 concurrent gens |
| Pro | $17-29 | $17.40/mo | 600 | Lip Sync studio |
| Ultimate | $29-49 | -- | 1,200 | All features |
| Creator | $119-249 | $49.80/mo | 6,000 | Bulk discounts |
| Enterprise | Custom | Custom | Custom | API access |

Credit costs: Images 0.25-5 credits, Videos 20-50 credits, Voice/sound 1 credit. **Credits do NOT roll over.**

### WARNINGS
- Higgsfield charges ~4.5x more than using Kling/Sora/Veo directly
- GitHub repo documents fraud claims, fake unlimited plans, mass bans, predatory billing
- Non-consensual deepfake allegations
- Unpaid creator complaints in Higgsfield Earn program

---

## 4. HeyGen Deep Dive

### Product
- Leading AI avatar video platform
- Specializes in realistic talking-head videos, digital twins, translations, real-time streaming

### Key Features
- **Avatar IV**: Photorealistic with expressive facial motion, natural head movement
- **Digital Twin**: Clone yourself from recorded footage
- **Video Agent**: One-shot endpoint -- natural language prompt to finished video
- **Video Translation**: Translate with lip-sync in 175+ languages
- **Streaming API**: Real-time avatar via WebRTC/LiveKit (sub-second latency)
- **Template API**: Dynamic variable population for batch personalization
- **Photo Avatar**: Animate any still image
- **ElevenLabs voice integration**: Multiple voice models

### API (Most Mature in Category)
- **Base URL**: `docs.heygen.com`
- **Auth**: API key from dashboard

**Key Endpoints:**
```
POST /v2/video/generate          -- Studio video generation
POST /v2/video/av4/generate      -- Avatar IV video
POST /v1/video_agent/generate    -- One-shot from text prompt
POST /v1/video_translate/translate -- Video translation with lip-sync
```

**Streaming API**: Via LiveKit SDK, WebRTC, sub-second latency

**Template API**: Create template once, populate variables dynamically for batch personalization (name, message, product)

### Pricing
- API starts at **$5 pay-as-you-go**
- 1 credit = 1 minute standard avatar video
- Avatar IV: 1 credit per 10 seconds (~6 credits/minute)
- Video translation: 3 credits/minute
- Scale API: from **$330/mo**
- Enterprise: custom rates

### Best Use Cases
- Talking-head marketing videos at volume
- Personalized outreach (sales, onboarding)
- Video translation for global content
- Real-time interactive avatar (customer service, education)

---

## 5. Open Source Stack

### Image Generation
| Tool | What | GitHub | Hardware | Notes |
|------|------|--------|----------|-------|
| **Stable Diffusion** | Base image gen | stability-ai/stablediffusion | GPU (8GB+ VRAM) | Foundation for most OS pipelines |
| **ComfyUI** | Node-based workflow | comfyanonymous/ComfyUI | GPU | Visual pipeline builder for SD/Flux |
| **Fooocus** | Simple SD interface | lllyasviel/Fooocus | GPU (4GB+) | Built-in FaceSwap capability |
| **FluxGym** | LoRA training | -- | GPU (12GB+) | Train custom character LoRA models |
| **FaceFusion** | Face swap/consistency | facefusion/facefusion | GPU | Maintain features across poses |

### Talking Head / Lip Sync (Open Source)
| Tool | What | GitHub | Quality | Speed |
|------|------|--------|---------|-------|
| **SadTalker** | Single image + audio -> talking head | OpenTalker/SadTalker | Medium | Fast |
| **Wav2Lip** | Lip sync on existing video | Rudrabha/Wav2Lip | Good sync, low resolution | Fast |
| **LivePortrait** | Portrait animation from single image | KwaiVGI/LivePortrait | High | Real-time capable |
| **MuseTalk** | Real-time lip sync | TMElyralab/MuseTalk | Good | Real-time |
| **OmniHuman v1.5** | Film-grade digital humans | ByteDance (research) | Highest | Slow |

### Voice (Open Source)
| Tool | What | GitHub | Notes |
|------|------|--------|-------|
| **XTTS** | Multi-language voice cloning | coqui-ai/TTS | Clone from ~6 seconds, 17 languages |
| **Bark** | Text-to-speech with emotion | suno-ai/bark | Laughter, music, nonverbal sounds |
| **WhisperX** | Speech-to-text (for sync) | m-bain/whisperX | Word-level timestamps |

### Recommended Open Source Pipeline
1. **Character**: Flux via ComfyUI + FluxGym LoRA training
2. **Face consistency**: FaceFusion for cross-pose fixing
3. **Voice**: XTTS for cloning, Bark for emotional TTS
4. **Lip sync**: LivePortrait (quality) or MuseTalk (speed)
5. **Video gen**: Kling 3.0 or Runway API (no good open-source video gen yet)
6. **Editing**: ffmpeg + Python scripting

**Cost**: $0 (minus GPU compute). Requires NVIDIA GPU with 8-12GB+ VRAM or cloud GPU rental (~$0.50-2/hr).

---

## 6. Production Pipeline (RECOMMENDED)

### Tier 1: Zero-Cost Quick Start (5 min/video)
1. Higgsfield free tier (40 credits/day)
2. Create character via presets -> Soul ID lock
3. Generate 30-sec video with built-in voice
4. Post to socials manually
- **Cost**: $0
- **Quality**: Good
- **Volume**: ~2 videos/day

### Tier 2: Quality Production ($50-100/mo, 30 min/video)
1. **Character**: OpenArt Identity Lock or Flux + LoRA (one-time training)
2. **Script**: Claude/GPT-5.4 for hooks + storytelling
3. **Voice**: Fish Audio ($9.99/mo) -- matches ElevenLabs at 10x lower cost
4. **Video**: Kling 3.0 with Director Memory (15s 4K clips)
5. **Lip sync**: Kling native sync
6. **Editing**: OpusClip (auto-chop + captions + virality score)
7. **Posting**: OpusClip scheduler (6+ platforms)
- **Cost**: ~$60-100/month
- **Quality**: High
- **Volume**: 1-2 videos/day

### Tier 3: Maximum Control ($100-200/mo, 2-3 hrs/video)
1. **Character**: FluxGym LoRA training (15-30 ref images, ~$2-5 cloud compute)
2. **Consistency**: FaceFusion cross-pose fix + 5-10 seed bank headshots
3. **Script**: Claude/GPT-5.4 + NotebookLM research-to-script
4. **Voice**: ElevenLabs (hero content) + Fish Audio (volume)
5. **Video**: Kling 3.0 multi-shot storyboard + Higgsfield Cinema Studio camera control
6. **B-roll**: Runway Gen-3 Alpha (commercial use cleared) + Kling identity lock
7. **Lip sync**: Kling native or Magic Hour (best accuracy)
8. **Editing**: OpusClip + CapCut for fine adjustments
9. **Posting**: OpusClip + Zapier/Make for custom workflows
10. **Analytics**: HypeAuditor for audience intelligence
- **Cost**: ~$100-200/month
- **Quality**: Near-professional
- **Volume**: 1 video/day

### Tier 4: Full Automation Pipeline (API-driven)
1. **Script**: Claude API -> generate hooks/scripts
2. **Voice**: Fish Audio API or ElevenLabs API -> generate audio
3. **Character images**: Flux API (fal.ai or Replicate) with LoRA -> consistent character images
4. **Video**: HeyGen API `/v2/video/generate` -> talking head with lip sync
5. **B-roll**: Runway API -> lifestyle/product scenes
6. **Edit**: Captions AI API (auto-cut, captions, music)
7. **Post**: Buffer/Hootsuite API or platform-native APIs
8. **Monitor**: HypeAuditor API for performance
- **Cost**: ~$200-400/month
- **Quality**: High, consistent
- **Volume**: 5-10 videos/day (fully automated)

### Critical Production Notes
- **Lip sync prep**: Use open-mouth base images. Add "she should not be talking" as negative prompt for base video.
- **Speed fix**: AI-generated video has slower character movement than real humans. Speed up 1.2-1.5x for realism.
- **Audio length**: Audio MUST be shorter than video duration or it gets trimmed.
- **Close-up priority**: Close-up headshots produce best lip sync accuracy.
- **Generation time**: 10s clip = ~5 min generation. 1-minute video = ~30 min total production.
- **Lip sync is still the weakest link** in every pipeline despite massive improvements.

---

## 7. Monetization Strategies

### Revenue Streams (from creator videos + market research)

| Stream | Monthly Potential | Difficulty | Time to Revenue |
|--------|-------------------|------------|-----------------|
| Brand sponsorships | $500-$10K+ per post | Medium | 3-6 months (need 10K+ followers) |
| Affiliate marketing | $100-$5K+ | Easy | 1-2 months |
| Digital products (Gumroad/Etsy) | $100-$2K+ | Medium | 1-3 months |
| UGC ad creation for brands | $500-$5K+ per client | Medium | Immediate (cold outreach) |
| Content licensing | $200-$5K+ | Medium | 3-6 months |
| Subscription (FanView/Patreon) | $500-$10K+ | Medium | 3-6 months |
| Higgsfield Earn | $100-$100K+ (views-based) | Easy | Immediate |
| Course/toolkit sales | $500-$5K+ | Hard | 3-6 months |

### Benchmarks
- **Aitana Lopez** (Spanish AI influencer): $10K+/month, 350K+ followers
- **Virtual influencer market**: $2.3B (2024) -> $38B projected by 2030
- **AI influencer platform market**: $6.95B (2025) -> $52.10B projected by 2033
- **Brands already using AI influencers**: Prada, Samsung, Calvin Klein
- **Production cost savings**: 30-50% vs traditional influencer partnerships

### Monetization Playbook
1. **Months 1-2**: Post daily, build follower base, test content types. Use free tools. Revenue: $0.
2. **Months 2-3**: Start affiliate marketing (Amazon Associates, niche affiliates). Offer UGC ad creation on Fiverr/Upwork. Revenue: $100-500/mo.
3. **Months 3-6**: Pitch brand sponsorships at 10K+ followers. Launch digital products (presets, templates). Revenue: $500-2K/mo.
4. **Months 6+**: Scale with automation pipeline. Multiple AI characters across niches. License content. Revenue: $2K-10K+/mo.

### Warning
- 89% of marketers say they will NOT work with virtual influencers (emotional connection gap)
- AI detection tools are improving rapidly
- Deepfake laws evolving -- legal gray area
- Most AI influencer accounts fail within 3 months
- Monetization timelines in YouTube videos are consistently overstated

---

## 8. NotebookLM & Audio

### What NotebookLM Does
Google's AI research tool built on Gemini 3. Upload up to 50 sources (PDFs, Docs, Slides, web pages, YouTube transcripts, audio). AI summarizes, answers questions, makes cross-source connections.

### Audio Overviews (Killer Feature)
- One-click podcast generation: two AI hosts discuss your uploaded material
- NOT text-to-speech -- synthesized dialogue with banter, back-and-forth, natural pacing
- Durations: Brief (2-3 min), Standard (5-6 min), Extended (8-10 min)
- **Limitation**: English only, sometimes introduces inaccuracies, non-interruptible

### Programmatic Access

**1. Official -- NotebookLM Enterprise Podcast API (Google Cloud)**
- Released September 2025
- Standalone Podcast API -- does NOT require NotebookLM Enterprise license
- Just needs Google Cloud project + Podcast API User role
- Input: text, images, audio, video (under 100K tokens)
- Output: MP3
- Pricing: Contact Google Cloud sales (not public)
- Access: Limited to select Google Cloud customers

**2. Open Source -- notebooklm-py**
- GitHub: `teng-lin/notebooklm-py`
- PyPI: `pip install notebooklm-py`
- Full programmatic access via Python, CLI
- Agent integration: Claude Code, Codex, OpenClaw
- Exposes capabilities the web UI does not

**3. Third-Party -- AutoContent API**
- "NotebookLM API Alternative"
- Headless: watch folders -> ingest PDFs -> generate podcasts -> publish to Spotify/YouTube
- 50+ languages, voice cloning endpoint
- Make.com + Zapier integration
- **Pricing**: $199/month (1 podcast/month, 15 min max, watermarked). Higher tiers for volume.

**4. MCP Bridge -- notebooklm-mcp-cli**
- GitHub: `jacob-bd/notebooklm-mcp-cli`
- Unified CLI (`nlm`) + MCP server
- Refactored January 2026

### Use Cases for AI Influencer Pipeline
- **Research-to-script**: Upload competitor content, market data -> NotebookLM generates talking points and script outlines
- **Brand knowledge base**: Upload brand guidelines, make searchable/queryable across all content creation
- **Competitive analysis**: Upload competitor sites/ads -> extract comparison tables automatically
- **Content repurposing**: Turn long-form research into blog outlines, social posts, newsletter content
- **Podcast companion content**: Generate audio overviews of influencer research to share as podcast episodes

---

## 9. API Integration Map

### Video Generation APIs

| Provider | Auth | Base URL | Key Endpoints | Pricing Model |
|----------|------|----------|---------------|---------------|
| **HeyGen** | API key (dashboard) | `api.heygen.com` | `POST /v2/video/generate`, `POST /v2/video/av4/generate`, `POST /v1/video_agent/generate`, `POST /v1/video_translate/translate` | Credits (1 credit = 1 min), from $5 PAYG |
| **HeyGen Streaming** | API key + LiveKit SDK | LiveKit WebRTC | Real-time avatar stream | Sub-second latency, from $330/mo |
| **Higgsfield** | API key (dashboard) | `cloud.higgsfield.ai` | Python SDK `higgsfield-client` (sync/async), batch, webhooks | Credits, Enterprise plan |
| **Hedra** | API key | REST API | Character-3 video gen, LiveKit plugin for live | 6 credits/sec, $0.05/min live |
| **D-ID** | API key | `api.d-id.com` | `POST /talks` (talking head), clips, streams | $6-300/mo, 10-65 min |
| **Synthesia** | API key | `api.synthesia.io` | `POST /videos` | 1 credit = 1 min, from $64/mo |
| **Captions/Mirage** | API key | Mirage API | AI Creator, AI Twin, AI Edit, AI Translate endpoints | 1 credit = 1 sec, from $115/mo |
| **Arcads** | clientId + clientSecret | REST API | Product creation, script management, video generation | $110+/mo, rate limit 40 req/sec |
| **Fabric** | API key | REST API | Talking head with micro-expressions | **$0.15/sec** |

### Voice APIs

| Provider | Auth | Key Endpoint | Clone Requirement | Cost |
|----------|------|-------------|-------------------|------|
| **ElevenLabs** | API key | `POST /v1/text-to-speech/{voice_id}` | Minutes of audio | $5-330/mo |
| **Fish Audio** | API key | REST API | Short sample | **$9.99/mo** (200 min) |
| **Resemble AI** | API key | REST API | 10 seconds | Pay-per-use (~3x cheaper than EL) |
| **Smallest.ai** | API key | REST API | Short sample | **$0.02/min TTS, $0.045/min clone** |
| **PlayHT** | API key | REST API | Short sample (cross-lang: clone EN, deploy 140+ langs) | Tiered |

### Image Generation APIs

| Provider | Auth | Endpoint | Notes |
|----------|------|----------|-------|
| **fal.ai** (Flux) | API key | `POST /fal-ai/flux-pro` | Cheapest Flux API, LoRA support |
| **Replicate** (Flux/SD) | API key | `POST /v1/predictions` | Wide model selection, LoRA training |
| **OpenArt** | API key | REST API | Identity Lock built-in |
| **Midjourney** | Discord bot (unofficial) or API (waitlist) | -- | No official public API yet |

### Podcast/Audio APIs

| Provider | Auth | Endpoint | Notes |
|----------|------|----------|-------|
| **NotebookLM Enterprise** | Google Cloud IAM | Podcast API | Limited access, contact sales |
| **AutoContent** | API key | REST API | $199+/mo, 50+ languages, voice cloning |
| **ElevenLabs** | API key | `POST /v1/text-to-speech` | For custom podcast voices |

### Editing/Distribution APIs

| Provider | Auth | Endpoint | Notes |
|----------|------|----------|-------|
| **Captions/Mirage** | API key | AI Edit API | Auto-cut, captions, effects |
| **VEED** | API key | Lip sync API | Best lip-sync API per benchmarks |

### Analytics APIs

| Provider | Auth | Endpoint | Notes |
|----------|------|----------|-------|
| **HypeAuditor** | API key | REST API | 35+ metrics, audience demographics |
| **Influencer Hero** | API key | REST API | AI discovery, lookalike modeling |

### Integration Glue

| Tool | Purpose | Cost |
|------|---------|------|
| **Zapier** | Connect any tool to any platform | $20+/mo |
| **Make.com** | Visual automation workflows | $9+/mo |
| **n8n** (self-hosted) | Open-source automation | Free (self-hosted) |

---

## Key Decisions for Our Pipeline

### RECOMMENDED STACK (Cost-Optimized, Quality-First)

| Stage | Tool | Why | Monthly Cost |
|-------|------|-----|-------------|
| Character | Flux 2 Pro + LoRA via fal.ai | Portable, highest consistency, ~$2-5 one-time training | ~$5 |
| Script | Claude/GPT-5.4 (already have) | Best quality, $0 via OAuth | $0 |
| Research | NotebookLM (free) + notebooklm-py | Research-to-script pipeline | $0 |
| Voice | Fish Audio | Matches ElevenLabs at 10x lower cost | $10 |
| Talking Head | HeyGen API (Avatar IV) | Most mature API, best for automation | $24-330 |
| B-Roll | Runway Gen-3 Alpha | Commercial use cleared, consistent | $12-76 |
| Lip Sync | HeyGen built-in or Kling native | Integrated, no extra cost | $0 (included) |
| Editing | OpusClip | Auto-chop + captions + scheduling in one | $19-69 |
| Posting | OpusClip scheduler + Make.com | 6+ platforms, automated | $0-9 |
| Analytics | HypeAuditor | Industry standard | Enterprise |
| **TOTAL** | | | **$70-500/mo** |

### Alternative: Minimum Viable Stack ($0-30/mo)
| Stage | Tool | Cost |
|-------|------|------|
| Character | Higgsfield free (Soul ID) | $0 |
| Script | Claude (OAuth) | $0 |
| Voice | Kling built-in TTS | $0 |
| Video | Higgsfield free (40 credits/day) | $0 |
| Editing | CapCut free | $0 |
| Posting | Manual or Buffer free | $0 |
| **TOTAL** | | **$0** |
