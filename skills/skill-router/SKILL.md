---
name: skill-router
description: Intra-agent skill selector. Given a task description, returns the best skill(s) to use. Zero-cost keyword matching with LLM fallback. Used by all agents after classify.sh routes to them.
agents: [main, dreami, taoz, iris]
version: 1.1.0
---

# Skill Router — Intra-Agent Skill Selector

classify.sh routes tasks to agents. Skill Router routes tasks to skills within an agent.

## Problem

Agents have 25+ creative skills and no deterministic way to pick the right one. classify.sh handles
inter-agent routing (which agent?), but once a task lands on an agent, it still needs to decide which
skill(s) to invoke. Without this, agents guess — wasting tokens or picking suboptimal tools.

## How It Works

```
classify.sh                    skill-router.sh
User msg ──→ Which agent? ──→ Agent ──→ Which skill(s)? ──→ Skill(s)
             (keyword match)            (keyword match)
             zero LLM cost             zero LLM cost
```

1. Parse task description
2. Match against keyword patterns (zero cost, like classify.sh)
3. If high confidence (>0.8): return skill directly
4. If ambiguous: return top 2-3 candidates with confidence scores
5. Optional: `--llm` flag uses claude CLI for disambiguation ($0 on Claude Max)

## Workflow SOP

```
INPUT: Task description (string) + agent name (optional)
STEP 1: Parse task description for keywords
STEP 2: Match against 30+ routing rules (ordered by specificity)
STEP 3: Score candidates by confidence (0-1)
STEP 4: If top match > 0.8 → return skill directly
STEP 5: If ambiguous (top 2 within 0.15) → use --llm flag for Claude disambiguation
STEP 6: Return skill name + confidence + reasoning
OUTPUT: Skill name(s) with confidence scores
```

## Brand DNA Awareness

skill-router reads brand DNA.json (`~/.openclaw/brands/{brand}/DNA.json`) to understand which skills
are most relevant per brand category. F&B brands route differently than digital product brands:

- **F&B/wellness brands** (pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein)
  prioritize product-studio, grabfood-enhance, content-repurpose, campaign-translate.
- **Digital/tech brands** (jade-oracle, gaia-os, gaia-learn) prioritize content-supply-chain,
  ad-composer, campaign-planner.
- **Print/recipe brands** (gaia-print, gaia-recipes) prioritize brand-studio, creative-studio.
- **Supplement brands** (gaia-supplements, iris) prioritize product-studio, ad-composer.

When a task mentions a brand name, skill-router loads its DNA.json to bias scoring toward that
brand's typical skill needs.

## Usage

```bash
# Basic — returns best match
skill-router.sh "generate mirra product photos for shopee"
# → product-studio (0.95) — product photography for e-commerce listings

# All candidates with scores
skill-router.sh --all "create a video ad for mirra bento"
# → video-compiler (0.85) — video ad production with AIDA blocks
# → ad-composer (0.70) — multi-model ad generation (image+video)
# → video-gen (0.60) — core video generation engine

# Filter by agent
skill-router.sh --agent dreami "translate campaign copy to bahasa"
# → campaign-translate (0.92) — multilingual transcreation engine

# JSON output for programmatic use
skill-router.sh --json "audit brand images"
# → {"skill":"brand-studio","confidence":0.88,"reason":"brand image audit with visual QA loop"}

# LLM disambiguation when keywords tie
skill-router.sh --llm "create jade character content for instagram"
# → jade-content-studio (0.90) — unified Jade content pipeline (LLM resolved: jade + character + ig)
```

## Flags

| Flag | Description |
|------|-------------|
| `--task "..."` | Explicit task flag (alternative to positional arg) |
| `--agent NAME` | Filter to skills available to that agent |
| `--llm` | Use Claude CLI for disambiguation ($0 on Claude Max) |
| `--json` | Machine-readable JSON output |
| `--all` | Show all candidates with scores, not just top match |

## Brand Coverage — All 14 Brands

skill-router recognises and routes for every Zennith brand. Example routing per brand:

| Brand | Example Task | Routed Skill | Confidence |
|-------|-------------|--------------|------------|
| **pinxin-vegan** | "pinxin-vegan weekly menu carousel for IG" | content-repurpose | 0.92 |
| **pinxin-vegan** | "pinxin-vegan CNY promo campaign" | campaign-planner | 0.88 |
| **wholey-wonder** | "wholey-wonder new smoothie product shots" | product-studio | 0.94 |
| **wholey-wonder** | "wholey-wonder recipe reel for TikTok" | video-compiler | 0.87 |
| **mirra** | "mirra bento subscription pack shots" | product-studio | 0.95 |
| **mirra** | "mirra meal plan content for FB & IG" | content-repurpose | 0.90 |
| **rasaya** | "rasaya herbal tea Shopee listing photos" | product-studio | 0.93 |
| **rasaya** | "rasaya wellness campaign BM + EN" | campaign-translate | 0.91 |
| **gaia-eats** | "gaia-eats food delivery GrabFood listing" | grabfood-enhance | 0.96 |
| **gaia-eats** | "gaia-eats hawker stall promo video" | video-compiler | 0.85 |
| **dr-stan** | "dr-stan supplement explainer ad" | ad-composer | 0.89 |
| **dr-stan** | "dr-stan health tips content calendar" | content-supply-chain | 0.86 |
| **serein** | "serein wellness retreat brand shoot" | brand-studio | 0.91 |
| **serein** | "serein mindfulness campaign copy EN/BM" | campaign-translate | 0.90 |
| **jade-oracle** | "jade-oracle AI tarot feature launch video" | video-gen | 0.88 |
| **jade-oracle** | "jade-oracle app store screenshots" | product-studio | 0.84 |
| **iris** | "iris visual QA audit for social posts" | brand-studio | 0.90 |
| **iris** | "iris supplement packaging mockup" | creative-studio | 0.86 |
| **gaia-os** | "gaia-os system architecture explainer" | content-supply-chain | 0.82 |
| **gaia-os** | "gaia-os launch announcement campaign" | campaign-planner | 0.87 |
| **gaia-learn** | "gaia-learn course promo reel" | video-compiler | 0.86 |
| **gaia-learn** | "gaia-learn educational carousel" | content-repurpose | 0.89 |
| **gaia-print** | "gaia-print packaging label design" | creative-studio | 0.93 |
| **gaia-print** | "gaia-print brand guidelines refresh" | brand-studio | 0.91 |
| **gaia-recipes** | "gaia-recipes recipe card video" | video-compiler | 0.88 |
| **gaia-recipes** | "gaia-recipes cookbook page layout" | creative-studio | 0.85 |
| **gaia-supplements** | "gaia-supplements product comparison ad" | ad-composer | 0.90 |
| **gaia-supplements** | "gaia-supplements Shopee listing optimise" | product-studio | 0.92 |

## F&B Brand Routing — Deep Examples

The 7 core F&B/wellness brands have specialised routing rules because food content has unique needs
(food photography, GrabFood listings, halal compliance, BM/EN/ZH multilingual).

### pinxin-vegan
- "pinxin-vegan new set lunch menu photos" → product-studio (0.94) — food photography with styling
- "pinxin-vegan weekly social content batch" → content-supply-chain (0.91) — scheduled content pipeline
- "pinxin-vegan GrabFood listing update" → grabfood-enhance (0.96) — GrabFood photo + description optimisation

### mirra (weight management meal subscription)
- mirra routes to **product-studio** for bento pack shots and meal photography
- mirra routes to **content-repurpose** for platform variants (IG carousel, FB post, WhatsApp status)
- mirra routes to **campaign-translate** for EN/BM/ZH multilingual meal plan promotions
- "mirra weekly bento lineup shoot" → product-studio (0.95)
- "mirra weight loss testimonial video" → video-compiler (0.88)

### wholey-wonder
- "wholey-wonder smoothie bowl hero shot" → product-studio (0.95) — food photography
- "wholey-wonder juice cleanse campaign" → campaign-planner (0.89) — multi-channel campaign
- "wholey-wonder new flavour launch reel" → video-compiler (0.87) — short-form video

### rasaya
- "rasaya herbal blend product page" → product-studio (0.93) — e-commerce product shots
- "rasaya traditional remedy explainer" → content-supply-chain (0.85) — educational content
- "rasaya Raya promo campaign BM" → campaign-translate (0.92) — festive campaign in Bahasa

### gaia-eats
- "gaia-eats hawker stall GrabFood optimisation" → grabfood-enhance (0.97) — listing enhancement
- "gaia-eats food delivery promo video" → video-compiler (0.86) — delivery promo content
- "gaia-eats new menu item photography" → product-studio (0.94) — food photography

### dr-stan
- "dr-stan collagen supplement ad for Meta" → ad-composer (0.91) — paid ad creative
- "dr-stan health tip carousel" → content-repurpose (0.88) — multi-platform content
- "dr-stan ingredient explainer video" → video-gen (0.84) — educational video

### serein
- "serein wellness tea brand campaign" → campaign-planner (0.90) — brand awareness campaign
- "serein mindful morning routine reel" → video-compiler (0.87) — lifestyle content
- "serein calming ritual product shots" → product-studio (0.93) — product photography

## Integration Map

**Feeds FROM:** classify.sh (agent routing) — classify.sh picks the agent, skill-router picks the skill.

**Feeds INTO:** All creative skills. skill-router is the dispatch layer that connects agent-level
routing to skill-level execution.

**Downstream skills used:**
- `nanobanana` — image generation (Gemini Image API)
- `video-gen` — core video generation engine (Kling 3.0 / Wan 2.6 / Sora 2)
- `brand-studio` — brand visual identity and audits
- `creative-studio` — design and layout tasks
- `ad-composer` — multi-model ad generation (image + video + copy)
- `campaign-planner` — multi-channel campaign orchestration
- `content-supply-chain` — scheduled content production pipeline
- `video-forge` — FFmpeg + WhisperX post-production
- `video-compiler` — AIDA-structured video ad assembly
- `clip-factory` — short-form clip extraction from long videos

## Malaysian Market Routing

Malaysian market tasks have specialised routing rules:

- **Shopee listing tasks** → product-studio (Shopee-optimised product photography and listing copy)
- **GrabFood optimisation** → grabfood-enhance (food photo enhancement + listing description)
- **Manglish content** → campaign-translate with `--tone manglish` (code-switching EN/BM casual tone)
- **Festive campaigns** (CNY, Raya, Deepavali) → campaign-planner with `--market MY`
- **BM/EN/ZH multilingual** → campaign-translate (transcreation, not literal translation)

## Quality Checklist

Routing quality is validated on every invocation. The gate ensures accurate skill selection and graceful fallback when confidence is low. Verification runs automatically — no manual quality check needed.

| Criterion | Threshold | Fallback |
|-----------|-----------|----------|
| Routing accuracy | Top-1 match correct ≥ 90% of the time | Log misroutes to routing-log.jsonl for pattern review |
| Confidence threshold | Minimum 0.6 to return a result | Below 0.6 → return "ambiguous" + top 3 candidates |
| High-confidence cutoff | ≥ 0.8 → auto-route without confirmation | Between 0.6–0.8 → suggest but flag for review |
| Disambiguation | Top-2 within 0.15 of each other | Trigger `--llm` fallback for Claude resolution |
| Fallback behaviour | No match found | Return generic skill suggestion + log for rule addition |
| Brand DNA loaded | Brand mentioned in task | Load DNA.json before scoring; fail gracefully if missing |
| Multi-skill tasks | Task spans 2+ skills | Return ordered list with pipeline suggestion |
| Validation pass rate | All routing decisions logged | Weekly validation review against actual skill usage |

## Output Paths

Routing logs stored at `~/.openclaw/workspace/data/skill-router/routing-log.jsonl`

Each log entry contains:
```json
{
  "timestamp": "2026-03-23T10:15:00+08:00",
  "task": "mirra bento pack shots for Shopee",
  "brand": "mirra",
  "agent": "dreami",
  "routed_skill": "product-studio",
  "confidence": 0.95,
  "candidates": [
    {"skill": "product-studio", "confidence": 0.95},
    {"skill": "brand-studio", "confidence": 0.72}
  ],
  "llm_used": false
}
```

## Data

- `data/skill-index.json` — structured index of all skills with capabilities, used by `--llm` mode
- Keyword rules are embedded in the script (like classify.sh) for zero-cost matching
- `~/.openclaw/workspace/data/skill-router/routing-log.jsonl` — append-only routing log

## Integration (Programmatic)

Agents can call skill-router before invoking a skill:

```bash
SKILL=$(skill-router.sh --json "$TASK" | jq -r '.skill')
bash ~/.openclaw/skills/$SKILL/scripts/*.sh "$@"
```

Multi-skill pipeline example:

```bash
# Task spans multiple skills — route returns ordered pipeline
SKILLS=$(skill-router.sh --all --json "mirra bento photo + shopee listing + IG carousel")
# → [{"skill":"product-studio","confidence":0.93}, {"skill":"product-studio","confidence":0.88}, {"skill":"content-repurpose","confidence":0.85}]
# Agent executes in pipeline order
```
