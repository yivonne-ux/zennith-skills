---
name: ai-seo
description: "When the user wants to optimize content for AI search engines, get cited by LLMs, or appear in AI-generated answers. Also use when the user mentions 'AI SEO,' 'AEO,' 'GEO,' 'LLMO,' 'answer engine optimization,' 'generative engine optimization,' 'LLM optimization,' 'AI Overviews,' 'optimize for ChatGPT,' 'optimize for Perplexity,' 'AI citations,' 'AI visibility,' 'zero-click search,' 'how do I show up in AI answers,' 'LLM mentions,' or 'optimize for Claude/Gemini.'"
agents:
  - scout
  - dreami
---

# AI SEO -- Get Cited by AI Search Engines

Optimize content for AI search engines (ChatGPT, Perplexity, Claude, Gemini, Google AI Overviews) so GAIA brands get cited as sources in AI-generated answers. Traditional SEO gets you ranked. AI SEO gets you **cited**.

## GAIA Brand Context

Before any AI SEO work, load the brand's DNA:
- `~/.openclaw/brands/{brand}/DNA.json` -- always load first
- Run `brand-voice-check.sh` before publishing any optimized content

**GAIA brand verticals and their top AI citation queries:**

| Vertical | Brands | High-Value AI Queries |
|----------|--------|----------------------|
| F&B / Vegan | pinxin-vegan, wholey-wonder, gaia-eats | "best vegan food KL," "plant-based meal delivery Malaysia" |
| Weight Management | mirra | "healthy meal subscription Malaysia," "weight management bento KL" |
| Wellness / Supplements | dr-stan, rasaya, gaia-supplements, serein | "best wellness supplements Malaysia," "natural health remedies" |
| Spiritual / Oracle | jade-oracle | "oracle card reading online," "spiritual guidance AI" |
| Education | gaia-learn | "AI learning platform," "wellness education online" |
| E-commerce | iris, gaia-print | "custom wellness products," "health-focused e-commerce" |

MIRRA = bento-style weight management meal subscription (NOT skincare, NOT the-mirra.com).

---

## How AI Search Selects Sources

| Platform | Source Selection | Key Factor |
|----------|----------------|------------|
| **Google AI Overviews** | Summarizes top-ranking pages | Strong traditional SEO correlation |
| **ChatGPT** | Searches web, cites sources | Wider range, not just top-ranked |
| **Perplexity** | Always cites with links | Favors authoritative, recent, structured |
| **Gemini** | Google index + Knowledge Graph | Entity recognition matters |
| **Claude** | Brave Search when enabled | Training data + search results |

**Critical stats:**
- AI Overviews appear in ~45% of Google searches
- AI Overviews reduce clicks by up to 58%
- Brands are 6.5x more likely cited via third-party sources than own domains
- Optimized content gets cited 3x more often
- Statistics and citations boost visibility by 40%+

---

## AI Visibility Audit

### Step 1: Check AI Answers for Key Queries

Test 10-20 queries across platforms for the brand:

| Query | Google AIO | ChatGPT | Perplexity | Brand Cited? | Competitors Cited? |
|-------|:----------:|:-------:|:----------:|:------------:|:------------------:|
| [query] | Y/N | Y/N | Y/N | Y/N | [who] |

**Query templates for GAIA brands:**
- "What is [product category]?" -- e.g., "What is a vegan bento subscription?"
- "Best [category] in [location]" -- e.g., "Best vegan restaurant in KL"
- "[Brand] vs [competitor]"
- "How to [problem brand solves]"
- "[Category] pricing Malaysia"

### Step 2: Content Extractability Check

For each priority page, verify:

| Check | Pass/Fail |
|-------|-----------|
| Clear definition in first paragraph? | |
| Self-contained answer blocks (work without context)? | |
| Statistics with sources cited? | |
| Comparison tables for "X vs Y" queries? | |
| FAQ section with natural-language questions? | |
| Schema markup (FAQ, HowTo, Article, Product)? | |
| Expert attribution (author, credentials)? | |
| Updated within 6 months? | |
| Headings match query patterns? | |
| AI bots allowed in robots.txt? | |

### Step 3: AI Bot Access Check

Verify robots.txt allows these crawlers:
- **GPTBot** / **ChatGPT-User** -- OpenAI
- **PerplexityBot** -- Perplexity
- **ClaudeBot** / **anthropic-ai** -- Anthropic
- **Google-Extended** -- Gemini / AI Overviews
- **Bingbot** -- Microsoft Copilot

If blocked, brand loses citation ability on that platform.

---

## Three Pillars of AI SEO

### Pillar 1: Structure -- Make Content Extractable

AI extracts passages, not pages. Every key claim must work standalone.

**Content block patterns:**
- **Definition blocks** for "What is X?" -- lead with direct answer
- **Step-by-step blocks** for "How to X" -- numbered lists
- **Comparison tables** for "X vs Y" -- tables beat prose
- **Pros/cons blocks** for evaluation queries
- **FAQ blocks** for common questions
- **Statistic blocks** with cited sources

**Rules:**
- Lead every section with the direct answer (don't bury it)
- Key answer passages: 40-60 words (optimal for snippet extraction)
- H2/H3 headings should match how people phrase queries
- Each paragraph conveys one clear idea

**GAIA-specific:** For F&B brands, structure menu pages with clear ingredient lists, nutritional data, and pricing tables. AI often cites pages with transparent nutrition info.

### Pillar 2: Authority -- Make Content Citable

Princeton GEO research (KDD 2024) ranked optimization methods:

| Method | Visibility Boost |
|--------|:---------------:|
| Cite sources | +40% |
| Add statistics | +37% |
| Add expert quotations | +30% |
| Authoritative tone | +25% |
| Improve clarity | +20% |
| Technical terms | +18% |
| Keyword stuffing | **-10%** (hurts) |

**Best combination:** Fluency + Statistics = maximum boost. Low-ranking sites benefit up to 115%.

**For GAIA brands:**
- Cite Malaysian health authorities (KKM/MOH), nutritionist credentials
- Include specific numbers: "98% plant-based ingredients," "serves 500+ customers weekly"
- Named expert quotes with titles
- "Last updated: [date]" on every page
- For jade-oracle: cite psychological frameworks, not just metaphysics

### Pillar 3: Presence -- Be Where AI Looks

Third-party citations matter more than your own site.

**Priority channels for GAIA brands:**
- Google Business Profile (critical for F&B -- pinxin-vegan, mirra, wholey-wonder)
- YouTube content for how-to queries (recipes, wellness routines)
- Reddit discussions (r/malaysia, r/vegan, r/MalaysianFood)
- TripAdvisor / Google Maps reviews (F&B brands)
- Industry publications (wellness, plant-based media)
- Shopee/Lazada listings with rich descriptions (e-commerce brands)

---

## Content Types That Get Cited Most

| Content Type | Citation Share | GAIA Application |
|-------------|:------------:|-----------------|
| Comparison articles | ~33% | "Mirra vs [competitor] meal plans" |
| Definitive guides | ~15% | "Complete guide to plant-based eating in Malaysia" |
| Original research/data | ~12% | Customer health outcome data |
| Best-of listicles | ~10% | "Best vegan spots in KL" (get included) |
| Product pages | ~10% | Detailed menu/product pages with specs |
| How-to guides | ~8% | Recipe content, wellness routines |

**Underperformers:** Generic blog posts without structure, gated content, PDF-only, content without dates.

---

## Schema Markup for AI

| Content Type | Schema | GAIA Use |
|-------------|--------|----------|
| Menu / Products | `Product`, `Menu` | F&B product pages |
| Recipes | `Recipe` | gaia-recipes, gaia-eats |
| Articles | `Article`, `BlogPosting` | All brand blogs |
| FAQs | `FAQPage` | Every brand site |
| How-to | `HowTo` | Wellness guides, recipes |
| Reviews | `AggregateRating` | Product/service reviews |
| Local Business | `LocalBusiness`, `Restaurant` | Physical F&B locations |
| Organization | `Organization` | Brand entity recognition |

Content with proper schema shows 30-40% higher AI visibility.

---

## Monitoring AI Visibility

### What to Track

| Metric | How to Check |
|--------|-------------|
| AI Overview presence | Manual check or Semrush/Ahrefs |
| Brand citation rate | Otterly AI, Peec AI, ZipTie |
| Share of AI voice | Compare citations vs competitors |
| Citation sentiment | How AI describes the brand |
| Source attribution | Which pages get cited |

### DIY Monthly Check (No Tools)

1. Pick top 20 queries per brand
2. Run each through ChatGPT, Perplexity, Google
3. Record: cited? who else? which page?
4. Log in spreadsheet, track month-over-month
5. Feed findings back through `seed-store.sh` for content planning

---

## Vertical Playbooks

### Spiritual / Oracle (Jade Oracle)

- Cite psychological frameworks (Jung's archetypes, positive psychology, narrative therapy) -- not just metaphysics
- Handle YMYL/E-E-A-T by positioning the reading methodology as the authority signal, not supernatural claims
- Schema: `Service` for readings, `FAQPage` for "what is oracle reading" queries
- Target queries: "online psychic reading," "oracle card reading," "spiritual guidance online," "tarot vs oracle cards"
- Create content that frames oracle readings through the lens of self-reflection and personal growth
- Include practitioner credentials, years of experience, and number of readings delivered as trust signals
- Avoid "prediction" language -- use "insight," "reflection," "guidance" for E-E-A-T compliance

### Wellness / Supplements (Dr Stan, Serein, Gaia Supplements)

- Cite clinical studies with DOI links or PubMed references for every health claim
- Use `NutritionInformation` schema on all product pages, `Product` with `offers` for e-commerce
- Comply with Malaysian health claim regulations (KKM/MOH) -- never claim "cures" or "treats," use "supports" or "promotes"
- Target queries: "best probiotics Malaysia," "gut health supplements," "immunity boosters," "natural wellness Malaysia"
- Include ingredient sourcing transparency (origin, certifications, third-party testing)
- Add "Reviewed by [qualified nutritionist/pharmacist]" attribution to health content
- Structure comparison pages: "[Brand] vs [competitor]" with objective criteria tables

### F&B / Vegan (Pinxin Vegan, Mirra, Wholey Wonder, Rasaya, Gaia Eats)

- Use `Recipe` schema with full nutrition data, `Product` schema with pricing, `LocalBusiness` for physical locations
- Target queries: "vegan food delivery [city]," "healthy meal plans Malaysia," "[product] recipe," "best vegan restaurant KL"
- Include transparent nutrition info (calories, macros, allergens) -- AI heavily cites pages with structured nutrition data
- Add `Menu` schema for F&B businesses with pricing and dietary labels (vegan, gluten-free, halal)
- Optimise Google Business Profile with menu links, photos, and regular post updates
- Create "vs" content: "meal prep vs MIRRA subscription," "vegan vs plant-based"
- For MIRRA specifically: target "weight management meal plan" and "healthy bento subscription" queries

### E-commerce / D2C (Aerthera, Iris)

- Use `Product` schema with `offers`, `AggregateRating`, `brand` entity, and `Review` markup
- Target queries: "[brand] review," "best [category] Malaysia," "[product] vs [competitor]"
- Build rich product pages with specs, ingredient lists, usage instructions, and customer testimonials
- Create comparison content: "[product] vs [competitor product]" with objective feature tables
- Maintain active presence on Shopee/Lazada with rich descriptions that mirror site content
- Use `Organization` schema to build brand entity recognition across platforms
- Encourage and mark up verified customer reviews -- AI engines heavily weight aggregate ratings

### Handling AI Hallucinations About Your Brand

If AI engines return incorrect information about your brand (wrong products, outdated pricing, competitor confusion), take these steps:

1. **Create a definitive "About [Brand]" page** with correct facts -- founding date, product range, pricing, locations, key differentiators
2. **Cite it across third-party platforms** -- Google Business Profile, LinkedIn, social bios, directory listings should all match
3. **Add `Organization` schema** with `sameAs` links to all official profiles
4. **Re-test monthly** -- query ChatGPT, Perplexity, and Google AI Overviews until the correct information surfaces
5. **If persistent:** publish a structured FAQ ("Is [Brand] a skincare company? No, [Brand] is...") directly addressing the misinformation

---

## Common Mistakes

- **Ignoring AI search** -- 45% of Google searches show AI Overviews
- **No freshness signals** -- undated content loses to dated content
- **Gating all content** -- AI cannot access gated content
- **No structured data** -- schema markup is critical for AI extraction
- **Keyword stuffing** -- actively reduces AI visibility by 10%
- **Blocking AI bots** -- check robots.txt quarterly
- **Generic content without data** -- "best in KL" without proof won't get cited
- **Ignoring third-party presence** -- Google Business Profile, review sites, Reddit

---

## Workflow

1. **Audit** -- Run AI visibility audit for the brand's top queries
2. **Prioritize** -- Rank pages by citation opportunity (high-intent queries without current citations)
3. **Optimize** -- Apply three pillars: Structure, Authority, Presence
4. **Schema** -- Add/fix structured data markup
5. **Monitor** -- Monthly AI visibility check, track improvements
6. **Compound** -- Feed learnings into `knowledge-compound` for cross-brand application

## Related Skills

- **seo-audit** -- Traditional technical and on-page SEO
- **firecrawl-scrape** -- Scrape competitor pages for structure analysis
- **growth** -- SEO + SMO + CRO growth support
- **content-repurpose** -- Reformat content for multi-platform presence
