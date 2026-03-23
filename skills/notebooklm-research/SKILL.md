---
name: notebooklm-research
description: Deep research pipeline using Google NotebookLM for source analysis and knowledge synthesis, feeding into Claude for content creation. Research → Synthesize → Create → Publish.
agents: [taoz, dreami]
version: 1.0.0
---

# NotebookLM Research — Deep Research Pipeline for Content Creation

**Concept:** NotebookLM does research, Claude writes content.

Google NotebookLM is our **research engine**. It ingests sources (PDFs, websites, YouTube, Google Docs), synthesizes knowledge, and surfaces insights. Claude takes that synthesized knowledge and creates brand-aligned content. This is a human-in-the-loop skill — Jenn manages NotebookLM notebooks, exports feed into the automated Claude pipeline.

Inspired by @claude.world.taiwan's pipeline: trend exploration → deep research → content creation → publishing.

## 1. Overview

NotebookLM is Google's AI research tool that can:
- Ingest PDFs, websites, YouTube videos, Google Docs as sources (up to 50 per notebook)
- Generate "Audio Overview" — podcast-style deep dives (~10 min) with two AI hosts discussing your sources
- Answer questions grounded strictly in uploaded sources (no hallucination beyond sources)
- Create study guides, FAQs, timelines, briefing docs from sources
- Summarize and cross-reference multiple sources to find non-obvious connections

We use it as the **research engine** in our content pipeline. NotebookLM handles the heavy research lifting — reading, cross-referencing, synthesizing. Claude takes the output and creates brand content that matches voice, platform, audience, and language requirements.

**Why NotebookLM + Claude (not just Claude alone)?**
- NotebookLM is grounded in YOUR uploaded sources — no hallucination risk on factual claims
- Ideal for evidence-based content (health claims, ingredient science, market data)
- Audio Overview surfaces unexpected angles a text prompt never would
- NotebookLM is free — zero cost research before spending tokens on content creation
- Persistent notebooks build institutional knowledge over time

## 2. Research Workflow

### Pipeline Architecture

```
SOURCES → NotebookLM (research/synthesis) → Export → Claude (content creation) → Brand Content
   ↑                                                                                    |
   └──────────────── content performance feeds back as new research topics ──────────────┘
```

### Pipeline Steps

```
INPUT: Research topic + brand name + content type needed
STEP 1: Create/open NotebookLM notebook for topic
STEP 2: Upload 5-20 high-quality sources (PDFs, URLs, YouTube)
STEP 3: Generate Audio Overview for deep synthesis
STEP 4: Ask targeted research questions in NotebookLM
STEP 5: Export findings (study guide, FAQ, briefing doc)
STEP 6: Create handoff document for Claude
STEP 7: Claude creates brand content from research
STEP 8: Log research to ~/.openclaw/workspace/data/research/{brand}/
OUTPUT: Research handoff document + brand content drafts
```

### Research Types by Use Case

| Use Case | Sources to Upload | NotebookLM Output | Claude Creates |
|----------|-------------------|-------------------|----------------|
| Competitor Research | Competitor websites, ads, social profiles, Shopee listings | Competitive analysis summary, pricing matrix | Strategy brief, counter-positioning copy, ad angles |
| Trend Research | Industry articles, trend reports, TikTok/Threads posts | Trend synthesis, emerging patterns, timing signals | Trend-riding content calendar, viral hooks |
| Product Research | Scientific papers, ingredient studies, NPRA guidelines | Evidence-based claims, FAQ, risk flags | Product descriptions, health claims, EDM, Shopee listings |
| Audience Research | Survey data, reviews, social listening exports | Audience insights, pain points, language patterns | Persona-targeted ad copy, WhatsApp flows |
| SEO Research | Top-ranking content, SERP analysis, competitor blogs | Content gaps, keyword clusters, topic authority map | SEO-optimized blog posts, meta descriptions |
| Recipe/Menu R&D | Food blogs, nutrition databases, cultural recipe archives | Recipe inspirations, nutritional breakdowns, fusion ideas | Brand recipes, menu descriptions, IG carousel content |
| Health/Wellness Claims | PubMed papers, clinical studies, MOH/NPRA guidelines | Evidence summaries, claim verification, compliance flags | Compliant health marketing copy, supplement labels |
| Campaign Planning | Past campaign data, seasonal trends, cultural calendars | Campaign themes, timing insights, audience readiness | Full campaign briefs, content matrices |
| Brand Positioning | Category reports, competitor DNA, consumer perception data | White space analysis, positioning opportunities | Brand messaging frameworks, taglines, manifesto |

## 3. NotebookLM Setup SOP

### Step 1: Create Research Notebooks

Organize notebooks by brand and research topic. Use this naming convention: `[Brand] — [Topic] [Quarter/Year]`

```
📁 GAIA Research (Google Account: gaia workspace)
│
├── 📁 F&B Brands
│   ├── 📓 Mirra — Competitor Analysis Q1 2026
│   ├── 📓 Mirra — Weight Management Meal Trends MY 2026
│   ├── 📓 Mirra — Weight Management Nutrition Science
│   ├── 📓 Pinxin — Vegan Food Science
│   ├── 📓 Pinxin — MY Vegan Market Landscape
│   ├── 📓 Pinxin — Plant-Based Protein Research
│   ├── 📓 Rasaya — Ayurvedic Ingredients Evidence
│   ├── 📓 Rasaya — Traditional Wellness Modernization
│   ├── 📓 Wholey Wonder — Smoothie Bowl Trends APAC
│   ├── 📓 Wholey Wonder — Superfood Ingredients
│   ├── 📓 Gaia Eats — F&B Delivery Market MY
│   └── 📓 Gaia Eats — Cloud Kitchen Operations
│
├── 📁 Wellness Brands
│   ├── 📓 Dr. Stan — Supplement Ingredient Evidence
│   ├── 📓 Dr. Stan — NPRA Compliance Research
│   ├── 📓 Dr. Stan — Competitor Supplement Brands MY
│   ├── 📓 Serein — Stress & Wellness Science
│   ├── 📓 Serein — Adaptogen Research
│   └── 📓 Gaia Supplements — Formulation Research
│
├── 📁 Creative & Platform
│   ├── 📓 Iris — IG Algorithm & Reels Trends 2026
│   ├── 📓 Jade Oracle — Spiritual Content Landscape
│   ├── 📓 Gaia Print — Design Trends APAC
│   └── 📓 Gaia Learn — EdTech Content Research
│
├── 📁 Market Intelligence
│   ├── 📓 Market — MY F&B Industry Report 2026
│   ├── 📓 Market — Malaysian Health Consumer Behavior
│   ├── 📓 Market — SEA Plant-Based Market
│   ├── 📓 Audience — KL Office Worker Food Habits
│   └── 📓 Audience — Malaysian Millennial Wellness Spending
│
└── 📁 Seasonal & Campaign
    ├── 📓 Seasonal — Hari Raya Campaign Research
    ├── 📓 Seasonal — CNY Health Gifting Research
    ├── 📓 Seasonal — Year-End Wellness Trends
    └── 📓 Campaign — [Active Campaign Name]
```

### Step 2: Source Ingestion Protocol

For each research topic:

1. **Curate 5-20 high-quality sources** — quality over quantity. NotebookLM works best with focused, authoritative sources.
2. **Upload in batches** — add 5 sources, let NotebookLM process, review initial synthesis, then add more targeted sources to fill gaps.
3. **Generate initial summary** — use the notebook guide to see what NotebookLM understood.
4. **Ask targeted research questions** — drill into specific areas (see brand-specific questions below).
5. **Generate Audio Overview** — for complex topics, this surfaces non-obvious connections.
6. **Export findings** — study guide, FAQ, or raw notes depending on content need.

**Source Upload Checklist:**
- [ ] Sources are recent (within 12 months for trends, 3 years for science)
- [ ] Mix of perspectives (not all from same author/publisher)
- [ ] Includes at least one Malaysian/SEA-specific source
- [ ] Competitor sources are current (check last updated dates)
- [ ] Scientific sources are peer-reviewed or from recognized institutions

### Step 3: Quality Sources Guide

**Competitor Research Sources:**
- Their website (upload URL directly)
- Shopee/Grab/FoodPanda listings (screenshot → PDF)
- Meta Ad Library screenshots (download as PDF)
- Social media profiles (Instagram, TikTok — screenshot key posts)
- Customer reviews on Google, Shopee, FoodPanda
- Job postings (reveals their priorities and tech stack)

**Trend Research Sources:**
- Industry reports: Euromonitor, Mintel, Statista, DOSM (Department of Statistics Malaysia)
- Food media: Eater, SAYS.com, The Star Food, TimeOut KL
- TikTok/Threads trend compilations (screenshot → PDF)
- Google Trends exports (download CSV → Google Sheets → upload)
- Trade publications: Food Navigator Asia, NutraIngredients Asia

**Scientific/Health Sources:**
- PubMed (upload PDF of papers directly)
- Google Scholar results
- WHO guidelines, MOH Malaysia advisories
- NPRA (National Pharmaceutical Regulatory Agency) — for supplement compliance
- Cochrane Reviews (for evidence-based health claims)
- Examine.com (for supplement ingredient summaries)

**Audience Research Sources:**
- DOSM population and consumer data
- Brand customer survey exports (Google Forms → Sheets → upload)
- Social media comments/DMs (anonymized, compiled into doc)
- Google Analytics audience reports (export as PDF)
- Shopee/Lazada review compilations
- Chatwoot conversation exports (anonymized)

**Malaysian Market Specific Sources:**
- DOSM (dosm.gov.my) — demographics, spending patterns
- MITI reports — trade and industry data
- MATRADE — export market data
- Bank Negara quarterly reports — consumer spending
- Nielsen Malaysia — retail and FMCG data
- Kantar Worldpanel — household purchase behavior

## 4. Audio Overview Feature (Podcast-Style Research)

NotebookLM's most powerful feature — generates a ~10 minute podcast-style discussion between two AI hosts analyzing your uploaded sources.

### How It Works:
1. Upload sources to notebook
2. Click "Generate Audio Overview" (takes 2-5 minutes to generate)
3. Two AI hosts discuss your sources conversationally
4. They debate, question, connect dots between different sources
5. Often surface insights you wouldn't find from reading alone

### When to Use Audio Overview:

**Always use for:**
- Complex topics with multiple perspectives (e.g., "Is turmeric supplementation effective?")
- Pre-campaign research (listen before planning any major campaign)
- Cross-brand opportunity analysis (upload data from multiple brands)
- Quarterly market review (upload all recent market data)

**Skip for:**
- Simple fact-finding (just ask NotebookLM directly)
- Single-source research (not enough material for meaningful discussion)
- Time-sensitive tasks (generation takes a few minutes)

### Audio Overview → Content Pipeline:

```
Audio Overview
    ↓
Transcribe (WhisperX: bash ~/.openclaw/skills/video-forge/scripts/video-forge.sh transcribe audio.wav)
    ↓
Extract key insights (manually or Claude-assisted)
    ↓
Claude creates content:
    ├── Blog posts from key arguments
    ├── Social media hooks from interesting quotes/takes
    ├── Ad angles from contrarian perspectives
    ├── FAQ from questions the hosts raised
    ├── Carousel content from debate points
    └── Video scripts from the most engaging segments
```

### Customizing Audio Overview:
Before generating, you can give NotebookLM instructions:
- "Focus on the Malaysian market implications"
- "Compare the competing viewpoints on [topic]"
- "Emphasize practical applications for a food business"
- "Discuss the regulatory implications"

### Example: Mirra Weight Management Meal Research Audio Overview

Sources uploaded:
1. PDF: "Asia Pacific Healthy Eating Trends 2025" (Euromonitor)
2. URL: Japanese bento culture article (Saveur)
3. URL: Malaysian office lunch habits survey (DOSM)
4. PDF: Competitor analysis — 5 KL bento delivery brands
5. YouTube: "The Rise of Meal Prep Culture in Asia" (CNA Insider)

Audio Overview surfaced:
- Connection between Japanese bento aesthetics and Instagram shareability
- Gap in market: no brand combining "health-forward" + "aesthetically Malaysian"
- Insight: office workers want healthy BUT also want comfort food textures
- Contrarian take: portion control (bento boxes) is a selling point, not a limitation

These became: 4 Instagram carousels, 2 blog posts, 1 campaign brief for "Beautiful Fuel" positioning.

## 5. Export & Handoff to Claude

### Export Formats from NotebookLM

| Format | Best For | How to Export |
|--------|----------|---------------|
| **Study Guide** | Structured topic overview → content outlines | Click "Study Guide" in notebook tools |
| **FAQ** | Question-answer pairs → brand FAQ, chatbot training, Shopee Q&A | Click "FAQ" in notebook tools |
| **Timeline** | Chronological events → brand story content, history posts | Click "Timeline" in notebook tools |
| **Briefing Doc** | Executive summary → strategy briefs, campaign planning | Click "Briefing Doc" in notebook tools |
| **Table of Contents** | Topic structure → blog series planning, content calendar | Click "Table of Contents" in notebook tools |
| **Raw Q&A** | Specific answers → targeted content pieces | Copy-paste from chat interface |
| **Audio Overview Transcript** | Conversational insights → social content, video scripts | Transcribe via WhisperX |

### Handoff Template

When passing NotebookLM research to Claude for content creation, use this template. Save to `~/.openclaw/workspace/data/research/{brand}/handoff-{topic}-{date}.md`:

```markdown
## Research Handoff: [Topic]

**Brand:** [brand name from: mirra, pinxin-vegan, rasaya, dr-stan, wholey-wonder, gaia-eats, serein, gaia-supplements, iris, jade-oracle, gaia-print, gaia-learn, gaia-os, gaia-recipes]
**Research Source:** NotebookLM notebook "[notebook name]"
**Sources Count:** [N sources uploaded]
**Date:** [YYYY-MM-DD]
**Research Type:** [competitor/trend/product/audience/seo/recipe/health-claims/campaign/positioning]

### Key Findings
1. [Finding 1 — the most important discovery]
2. [Finding 2 — supporting data point]
3. [Finding 3 — surprising or contrarian insight]
4. [Finding 4+ as needed]

### Insights & Content Angles
- [Insight that could become a carousel post]
- [Contrarian take worth exploring in a blog post]
- [Data point that makes a compelling ad hook]
- [Trend signal that suggests content timing]

### Evidence & Claims (with source attribution)
- "[Specific claim]" — Source: [source name, page/timestamp]
- "[Statistic or data point]" — Source: [source name]
(IMPORTANT: All health/nutrition claims MUST have source attribution for compliance)

### Competitive Intelligence
- [What competitors are doing]
- [Gap in market we can exploit]
- [Positioning opportunity]

### Audience Insights
- [Pain point discovered]
- [Language/phrasing the audience uses]
- [Unmet need or desire]

### Content Request
**Create:** [content type — e.g., IG carousel, blog post, ad copy, EDM, product description]
**Platform:** [IG / FB / TikTok / Shopee / Blog / EDM / WhatsApp / Shopify]
**Brand Voice:** Load from ~/.openclaw/brands/{brand}/DNA.json
**Target Persona:** [persona name or description]
**Language:** [EN / BM / ZH / mixed]
**Tone:** [educational / playful / authoritative / warm / urgent]
**CTA:** [desired call to action]
**Deadline:** [date]

### Raw Notes (optional)
[Paste NotebookLM study guide, FAQ, or raw Q&A output here for Claude to reference]
```

### Quick Handoff (for simple content needs):

```markdown
## Quick Handoff: [Topic]
Brand: [brand] | Date: [date] | Notebook: [name]

**TL;DR:** [One sentence summary of research findings]

**Key stat:** [Most compelling data point]
**Key insight:** [Most interesting angle]
**Key gap:** [Biggest opportunity found]

**Make this:** [content type] for [platform] in [language]
```

## 6. Brand-Specific Research Playbooks

### Mirra (Weight Management Meal Subscription)

**Remember:** MIRRA = weight management meal subscription (calorie-controlled bento-format meals) — NOT cosmetics, NOT the-mirra.com.

**Priority Research Areas:**
- Weight management meal subscription market in Malaysia
- Calorie-controlled meal delivery trends in APAC
- Competitor analysis: other KL healthy meal delivery / weight management brands
- Nutritional science for calorie-controlled, portion-managed meals
- Food photography and plating trends (bento aesthetics)
- Grab/FoodPanda healthy food category data

**NotebookLM Questions to Ask:**
- "What are the top 3 unmet needs for KL office workers at lunchtime?"
- "How do successful weight management meal brands differentiate from regular meal prep?"
- "What nutritional claims can we make about calorie-controlled meal subscriptions?"
- "What food photography styles get the most engagement for healthy food brands?"
- "Compare pricing strategies across KL healthy food delivery brands"
- "What are the most requested dietary accommodations in Malaysian F&B?"

**Research → Content Examples:**
| Research Finding | Content Created |
|-----------------|----------------|
| "73% of KL workers skip lunch due to time" | IG Reel: "Your lunch, solved in 30 seconds" (unboxing) |
| Competitor X has no vegetarian bento option | Ad angle: "Finally, a bento for everyone" |
| Calorie-controlled meal subscriptions remove decision fatigue | Blog: "Why meal subscriptions are the easiest weight management you'll ever try" |
| Instagram aesthetics drive 40% of F&B discovery | Investment in plating + photography for IG grid |

### Pinxin Vegan

**Priority Research Areas:**
- Malaysian vegan/plant-based market growth
- Vegan nutrition science (protein, B12, iron in plant-based diets)
- Competitor analysis: MY vegan restaurants and delivery
- Cultural barriers to veganism in Malaysia
- Vegan ingredient sourcing in SEA
- Plant-based meat alternative trends
- GrabFood / Shopee Food optimization for vegan listings
- Vegan food science: texture replication (rendang, satay, char kway teow)
- Malaysian hawker food veganization techniques

**NotebookLM Questions to Ask:**
- "What are the most common nutritional concerns Malaysians have about going vegan?"
- "How are successful vegan brands in SEA overcoming the 'boring/tasteless' stigma?"
- "What Malaysian traditional dishes can be authentically veganized?"
- "Compare plant-based protein sources available in Malaysia by cost and nutrition"
- "What role does religious dietary practice (Buddhist vegetarianism, halal) play in plant-based adoption?"
- "What are the fastest-growing vegan product categories in Malaysia?"
- "What GrabFood listing optimization tactics drive the most orders for F&B brands in KL?"
- "How do top-performing vegan restaurants on GrabFood structure their menus and descriptions?"
- "What food photography styles get the highest click-through rates on delivery platforms?"
- "Compare tempeh vs jackfruit vs mushroom as rendang protein bases — cost, texture, nutrition"

**Suggested Notebooks:**
- `Pinxin — GrabFood Listing Optimization Q1 2026` (competitor GrabFood listings, delivery platform best practices, listing SEO)
- `Pinxin — Vegan Food Science & Texture` (plant-based meat replication, Malaysian dish veganization, ingredient science)
- `Pinxin — MY Vegan Consumer Behavior` (audience surveys, social listening, review analysis)

**Research → Content Examples:**
| Research Finding | Content Created |
|-----------------|----------------|
| Buddhist vegetarian population = untapped vegan-curious audience | Campaign targeting Buddhist communities during Vesak |
| "Protein anxiety" is #1 barrier to trying vegan | Carousel: "Where do you get your protein? Everywhere." |
| Malaysian rendang can be made vegan with jackfruit | Recipe video: "Rendang, but make it plants" |
| Vegan food delivery grew 180% in KL since 2023 | Business case content for B2B catering pitch |
| GrabFood top vegan listings use bold close-up hero images with visible steam | Updated all Pinxin GrabFood listing photos with steam/smoke shots |
| "Nasi lemak" is the #1 searched food term on GrabFood KL | Pinxin nasi lemak set promoted to top of GrabFood menu with SEO-optimized description |
| Customers who see "100% plant-based" badge order 23% more often | Added plant-based badge to all Shopee and GrabFood listings |

### Rasaya (Ayurvedic Wellness)

**Priority Research Areas:**
- Ayurvedic ingredients with scientific evidence
- Traditional Malay/Indian wellness practices meeting modern science
- Competitor analysis: Malaysian wellness brands
- Adaptogen research (ashwagandha, turmeric, holy basil)
- Consumer attitudes toward traditional wellness in urban MY
- Regulatory landscape for traditional wellness products in Malaysia

**NotebookLM Questions to Ask:**
- "Which ayurvedic ingredients have the strongest clinical evidence?"
- "How are modern wellness brands making traditional remedies appealing to millennials?"
- "What is the regulatory status of ayurvedic products under NPRA Malaysia?"
- "Compare the efficacy evidence for turmeric/curcumin across different formulations"
- "What traditional Malay jamu ingredients overlap with ayurvedic ingredients?"
- "How do successful DTC wellness brands build trust through education?"

**Research → Content Examples:**
| Research Finding | Content Created |
|-----------------|----------------|
| Curcumin bioavailability 2000% higher with piperine | Product callout: "We add black pepper extract — here's why" |
| Jamu and Ayurveda share 12 common ingredients | Blog series: "Where Jamu meets Ayurveda" |
| 68% of MY millennials interested in "traditional + modern" wellness | Brand positioning: "Ancient wisdom, modern science" |
| NPRA requires specific disclaimers for traditional products | Compliance checklist for all marketing copy |

### Dr. Stan (Supplements)

**Priority Research Areas:**
- Supplement ingredient efficacy (clinical evidence levels)
- NPRA Malaysia supplement regulations and compliance
- Competitor supplement brands in Malaysia (pricing, claims, channels)
- Consumer supplement buying behavior in MY
- Ingredient sourcing and quality certifications
- E-commerce supplement market (Shopee, Lazada trends)

**NotebookLM Questions to Ask:**
- "What are the evidence levels (A/B/C/D) for our key supplement ingredients?"
- "What claims can we legally make under NPRA guidelines for [ingredient]?"
- "How do top Shopee supplement brands structure their listings and reviews?"
- "What supplement combinations have synergistic evidence?"
- "Compare bioavailability claims across competitor brands — which are substantiated?"
- "What are the most common supplement-related consumer complaints in Malaysia?"

**Research → Content Examples:**
| Research Finding | Content Created |
|-----------------|----------------|
| Vitamin D deficiency common in MY despite sun exposure | IG carousel: "Malaysia is sunny. You're still deficient. Here's why." |
| 4 of 5 competitors make unsubstantiated claims | Positioning: "We only say what the science says" |
| Subscription models increase supplement compliance | Shopee auto-ship campaign launch |
| Magnesium glycinate better absorbed than oxide | Product page copy explaining formulation choices |

### Wholey Wonder (Smoothie Bowls)

**Priority Research Areas:**
- Smoothie bowl and acai bowl trends APAC
- Superfood ingredient research
- Competitor analysis: MY smoothie/bowl brands
- Food styling and social media visual trends
- Nutritional composition of popular superfood ingredients
- Seasonal fruit availability in Malaysia

**NotebookLM Questions to Ask:**
- "What superfood ingredients have the strongest health evidence vs. marketing hype?"
- "How do top smoothie bowl brands create 'Instagrammable' products that also taste good?"
- "What are the profit margins on popular smoothie bowl ingredients in Malaysia?"
- "Compare nutritional profiles: acai vs pitaya vs blue spirulina vs local alternatives"
- "What are the most successful UGC strategies for food brands?"
- "Seasonal tropical fruit calendar for Malaysia — what's in season when?"

### Serein (Wellness)

**Priority Research Areas:**
- Stress and mental wellness trends among Malaysian urban professionals
- Adaptogen and nootropic research
- Competitor wellness brands in SEA
- Sleep science and supplement evidence
- Mindfulness and wellness lifestyle content trends
- Corporate wellness market in Malaysia

**NotebookLM Questions to Ask:**
- "What are the top 3 wellness concerns for Malaysian professionals aged 25-40?"
- "Which adaptogens have clinical evidence for stress reduction?"
- "How are DTC wellness brands building community beyond product sales?"
- "Compare the wellness content strategies of successful SEA brands"
- "What corporate wellness programs are Malaysian companies adopting?"
- "How does the Malaysian work culture impact wellness product marketing?"

### Gaia Eats (F&B Operations)

**Priority Research Areas:**
- Malaysian food delivery market data
- Cloud kitchen operations and economics
- F&B technology trends (ordering, kitchen management)
- Food safety regulations Malaysia (BKKM)
- Multi-brand F&B operations
- Supply chain optimization for F&B

**NotebookLM Questions to Ask:**
- "What are the economics of running a cloud kitchen in KL vs. physical restaurant?"
- "How do multi-brand operators manage consistent quality across brands?"
- "What food delivery platform features drive the most orders in Malaysia?"
- "Compare cloud kitchen models: own kitchen vs. shared kitchen space"
- "What are BKKM compliance requirements for food delivery operations?"

### Creative Brands (Iris, Jade Oracle, Gaia Print, Gaia Learn)

**Iris — Social Media Management:**
- Platform algorithm changes (IG, TikTok, FB)
- Social media engagement benchmarks APAC
- Creator economy trends
- Content format performance data
- Influencer marketing rates and ROI in Malaysia

**Jade Oracle — Spiritual/Tarot Content:**
- Spiritual content landscape on social media
- Astrology/tarot audience demographics
- Competitor spiritual content creators in MY/SEA
- Cultural sensitivity in spiritual content for Malaysian audience

**Gaia Print — Design:**
- Design trends APAC 2026
- Packaging design trends in F&B
- Print-on-demand market
- Malaysian aesthetic preferences

**Gaia Learn — Education:**
- EdTech content trends
- Online learning platform data
- Malaysian education market
- AI-assisted learning tools

## 7. Compound Learning

Research compounds over time. Each notebook builds institutional knowledge that makes future research faster and more insightful.

### Knowledge Compounding Loop:

```
Cycle 1: Upload initial sources → Generate baseline insights
Cycle 2: Add new sources + Cycle 1 findings → Deeper insights, trend confirmation
Cycle 3: Add performance data from content created → Learn what research → content worked
Cycle N: Institutional knowledge builds → Research-to-content gap shrinks
```

### How to Compound:

1. **Never delete notebooks** — archive old ones, they're historical knowledge
2. **Add content performance data back** — which research-backed content performed well?
3. **Cross-reference notebooks** — upload findings from one notebook as source in another
4. **Quarterly review** — listen to Audio Overviews of combined quarterly research
5. **Store key findings** — always save to `~/.openclaw/workspace/data/research/{brand}/`

### Research Repository Structure:

```
~/.openclaw/workspace/data/research/
├── mirra/
│   ├── handoff-weight-mgmt-trends-2026-01-15.md
│   ├── handoff-competitor-q1-2026-03-01.md
│   └── insights-audio-overview-2026-02-10.md
├── pinxin-vegan/
│   ├── handoff-vegan-market-2026-01-20.md
│   └── handoff-protein-science-2026-02-15.md
├── dr-stan/
│   ├── handoff-supplement-evidence-2026-01-10.md
│   └── handoff-npra-compliance-2026-03-05.md
├── rasaya/
├── wholey-wonder/
├── serein/
├── gaia-eats/
├── gaia-supplements/
├── iris/
├── jade-oracle/
├── gaia-print/
├── gaia-learn/
├── gaia-os/
├── gaia-recipes/
└── _cross-brand/
    ├── market-my-f&b-2026-q1.md
    └── audience-health-consumer-2026.md
```

### Tagging Research for Retrieval:

Every handoff doc should include tags for later search:
```yaml
tags: [mirra, competitor, weight-management, meal-subscription, pricing, q1-2026]
research_type: competitor
confidence: high  # high/medium/low based on source quality
actionable: true  # did this lead to content creation?
content_created: [ig-carousel-2026-01-20, blog-bento-guide]
```

## 8. CLI Integration

```bash
# Log a research session
bash scripts/notebooklm-research.sh log \
  --brand mirra \
  --topic "weight management meal trends" \
  --type trend \
  --findings findings.md

# Generate content brief from research handoff
bash scripts/notebooklm-research.sh brief \
  --brand mirra \
  --research handoff-weight-mgmt-trends-2026-01-15.md \
  --content-type "social-campaign" \
  --platform ig \
  --language en

# Search past research across all brands
bash scripts/notebooklm-research.sh search "turmeric benefits"

# Search research for specific brand
bash scripts/notebooklm-research.sh search "protein" --brand pinxin-vegan

# Generate content brief from Pinxin GrabFood optimization research
bash scripts/notebooklm-research.sh brief \
  --brand pinxin-vegan \
  --research handoff-grabfood-optimization-2026-03-20.md \
  --content-type "listing-copy" \
  --platform grabfood \
  --language en,bm

# List all research for a brand
bash scripts/notebooklm-research.sh list --brand rasaya

# List all research by type
bash scripts/notebooklm-research.sh list --type competitor

# Create handoff document interactively
bash scripts/notebooklm-research.sh handoff \
  --brand mirra \
  --notebook "Weight Management Meal Trends 2025" \
  --content-request "Instagram carousel about weight management meals for office workers"

# Show research stats
bash scripts/notebooklm-research.sh stats

# Generate quarterly research summary
bash scripts/notebooklm-research.sh quarterly --quarter Q1-2026
```

## 9. Weekly Research Rhythm

```
┌─────────────┬────────────────────────────────────────────────────────────────┐
│ Day         │ Research Activity                                             │
├─────────────┼────────────────────────────────────────────────────────────────┤
│ Monday      │ Upload new sources: articles from past week, competitor       │
│             │ updates, new market data. Check content-scraper outputs for   │
│             │ auto-collected sources.                                       │
├─────────────┼────────────────────────────────────────────────────────────────┤
│ Tuesday     │ Generate Audio Overviews for key topics. Listen during        │
│             │ commute or lunch. Jot down surprising insights.               │
├─────────────┼────────────────────────────────────────────────────────────────┤
│ Wednesday   │ Extract insights from Audio Overviews and Q&A sessions.       │
│             │ Create handoff documents. Store in research repo.             │
├─────────────┼────────────────────────────────────────────────────────────────┤
│ Thursday    │ Claude content creation day. Feed handoff docs into Dreami    │
│             │ for copy, Taoz for technical content, Iris for visual briefs. │
├─────────────┼────────────────────────────────────────────────────────────────┤
│ Friday      │ Review content performance from previous cycle. Identify      │
│             │ new research gaps. Update research priorities for next week.   │
│             │ Run: bash scripts/notebooklm-research.sh stats                │
└─────────────┴────────────────────────────────────────────────────────────────┘
```

### Monthly Research Priorities Review:

First Monday of each month:
1. Review all brand notebooks — are sources still current?
2. Check which research areas led to best-performing content
3. Identify new research topics based on brand priorities
4. Archive stale notebooks, create fresh ones for new quarter
5. Cross-reference brand research for multi-brand campaign opportunities
6. Update this skill doc if workflow has evolved

## 10. Integration with Other Skills

### Feeds INTO (research outputs become inputs for):
- `content-supply-chain` — research stage of the content loop
- `campaign-planner` — research-backed campaign briefs
- `campaign-translate` — research informs localization context
- `ad-composer` — evidence-backed ad claims
- `content-seed-bank` — research insights become content seeds
- `creative-factory` — research briefs guide creative production
- `social-publish` — research timing informs posting schedule
- `shopee-listing` — competitor research informs listing optimization
- `edm-engine` — research insights fuel email content

### Receives FROM (these skills provide research inputs):
- `content-scraper` — automated source gathering (articles, competitor pages)
- `learn-youtube` — YouTube video transcripts as research sources
- `ads-competitor` — competitor ad data for analysis
- `growth-engine` — performance data feeds back as research topics
- `content-tuner` — content performance signals new research needs

### Complements:
- `rigour` — research handoffs go through rigour gate before becoming published content
- `brand-voice-check` — research-backed content still must match brand voice
- `knowledge-compound` — research findings compound into institutional knowledge

### Storage:
- Research handoffs: `~/.openclaw/workspace/data/research/{brand}/`
- Cross-brand research: `~/.openclaw/workspace/data/research/_cross-brand/`
- Audio Overview transcripts: `~/.openclaw/workspace/data/research/{brand}/audio/`

## 11. NotebookLM API / Programmatic Access

As of early 2026, NotebookLM does not have a public API. The current workflow is **manual notebook management + export → automated Claude pipeline**.

### Current Workflow (Human-in-the-Loop):
```
Jenn (manual) ──→ NotebookLM (manual) ──→ Export (manual) ──→ Claude Pipeline (automated)
                  - Upload sources            - Copy/paste        - Content creation
                  - Ask questions              - Download           - Brand voice check
                  - Generate Audio Overview    - Save to repo       - Publishing
```

### Future Workflow (When API Available):
```
content-scraper (auto) ──→ NotebookLM API (auto) ──→ Export API (auto) ──→ Claude Pipeline (auto)
- Scheduled scraping          - Auto-upload sources      - Auto-export          - Fully automated
- Competitor monitoring       - Scheduled Audio Overview  - Direct to handoff    - Human review only
- Market data feeds           - Auto-ask research Qs      - Structured JSON      - at publishing stage
```

### When API becomes available, we will automate:
1. Source ingestion from `content-scraper` output directly into NotebookLM
2. Scheduled Audio Overview generation (weekly per brand)
3. Direct structured export to Claude pipeline (JSON format)
4. Scheduled research refreshes (monthly for market, weekly for competitors)
5. Cross-notebook analysis (feed Brand A findings into Brand B notebook)
6. Integration with `gaia-auditor` for research quality checks

### Workarounds Until API:
- **Bookmark sources** — keep a running list in `~/.openclaw/workspace/data/research/_sources-queue.md` for batch upload
- **Template questions** — pre-written research questions per brand (see Section 6) for efficient Q&A sessions
- **Batch export days** — dedicate Wednesday to bulk export and handoff creation (see Section 9)
- **Audio Overview transcription** — use WhisperX to transcribe, then Claude to extract insights

## 12. Research Quality Checklist

Before creating content from research, verify:

- [ ] Sources are from the last 12 months (or noted as historical context)
- [ ] At least one Malaysian/SEA-specific source included
- [ ] Health/nutrition claims have peer-reviewed source attribution
- [ ] Competitor data is current (not from archived/outdated pages)
- [ ] Insights are genuinely novel (not just restating obvious facts)
- [ ] Research covers counter-arguments (not just confirmation bias)
- [ ] Handoff document follows template format
- [ ] Handoff is saved to research repo with proper naming
- [ ] Tags are added for future retrieval
- [ ] Content request in handoff specifies brand, platform, language, persona
