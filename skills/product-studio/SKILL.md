---
name: product-studio
description: Automated product photography, product placement, and model swapping pipeline for all GAIA brands. Pack shots, lifestyle scenes, e-commerce assets, and campaign visuals.
agents: [dreami, taoz]
version: 1.0.0
---

# Product Studio -- Full Product Content Pipeline

Automated product photography, product placement into AI scenes, and model/outfit swapping for all 14 GAIA brands. Takes a product photo (or product name from brand DNA) and generates a complete visual content library: pack shots at multiple angles, lifestyle scenes with product placement, and model shots with demographic diversity.

## How It Works

```
INPUT:  Product name or product photo + brand name
STEP 1: Load brand DNA --> extract colors, mood, typography, avoid-list
STEP 2: Select product type --> load angle/scene/model templates
STEP 3: Generate pack shots (Module A) --> 6-8 images
STEP 4: Generate lifestyle scenes (Module B) --> 4-6 images
STEP 5: Generate model shots (Module C) --> 3-4 images
STEP 6: Quality check --> brand consistency, product accuracy, artifact scan
STEP 7: Export to canonical path + register in visual-registry
OUTPUT: 15-20 production-ready images per product
```

**Image engine:** NanoBanana (Gemini Image API) via `nanobanana-gen.sh`
**Brand data:** `~/.openclaw/brands/{brand}/DNA.json` for colors, mood, style, avoid-list
**Output path:** `~/.openclaw/workspace/data/images/{brand}/product-studio/`
**Naming convention:** `{brand}_{product}_{module}_{angle|scene|pose}_{variant}.png`

---

## Module A: Pack Shot Generator

Generate product photography at multiple angles with consistent lighting, backgrounds, and brand alignment.

### Angle Matrix by Product Type

#### Food Items (bento boxes, vegan meals, prepared dishes, recipe kits)
| Angle | Shot Name | Prompt Modifier | Use Case |
|-------|-----------|----------------|----------|
| 0 (top) | Overhead flatlay | `directly overhead, bird's-eye view` | Instagram feed, menu cards |
| 45 | Hero shot | `45-degree angle, slight elevation, hero product shot` | Hero banner, Shopify listing |
| Front | Packaging front | `straight-on front view, label facing camera` | E-commerce main image |
| Back | Packaging back | `straight-on back view, nutrition label visible` | E-commerce secondary |
| Close-up | Ingredient detail | `extreme close-up, macro detail of textures and ingredients` | Story content, quality proof |
| 15 | Beauty shot | `15-degree tilt, slight angle, subtle shadow beneath` | Ad creative, social |

#### Beverages (jamu, turmeric latte, smoothies, herbal drinks)
| Angle | Shot Name | Prompt Modifier | Use Case |
|-------|-----------|----------------|----------|
| Front | Bottle hero | `straight-on front view, bottle centered, label clearly readable` | E-commerce main |
| 45 | Pour shot | `45-degree angle, liquid being poured into glass, motion captured` | Social, ads |
| Close-up | Condensation detail | `extreme close-up of bottle surface, condensation droplets, cold and refreshing` | Story content |
| Lifestyle | Hold shot | `hand holding bottle/glass at natural angle, casual grip` | UGC-style content |
| Top | Cap/opening | `overhead view of open bottle/glass, liquid color visible` | Ingredient showcase |

#### Supplements & Wellness (capsules, powders, bottles, jars)
| Angle | Shot Name | Prompt Modifier | Use Case |
|-------|-----------|----------------|----------|
| Front | Bottle front | `straight-on front view, label sharp and readable, product centered` | E-commerce main |
| Close-up | Capsule detail | `macro close-up of capsules/powder, texture visible, natural ingredients feel` | Trust-building |
| Spread | Ingredient spread | `overhead flatlay, bottle center with raw ingredients arranged around it` | Ingredient story |
| Shelf | Lifestyle shelf | `product on bathroom shelf or kitchen counter, lifestyle context` | Social lifestyle |
| 45 | Three-quarter | `45-degree angle, premium product photography, subtle shadow` | Shopify hero |

#### Print & Merch (t-shirts, tote bags, mugs, notebooks)
| Angle | Shot Name | Prompt Modifier | Use Case |
|-------|-----------|----------------|----------|
| Flat | Flat lay | `perfectly flat lay on clean surface, garment spread, design visible` | E-commerce main |
| Worn | In-use | `model wearing/using product, natural pose, lifestyle context` | Social, ads |
| Detail | Texture close-up | `extreme close-up of print quality, fabric texture, design detail` | Quality proof |
| Mockup | Product mockup | `professional product mockup, clean white background` | Shopify listing |
| Lifestyle | Styled scene | `product styled in workspace/home setting with complementary props` | Pinterest, lifestyle |

### Background Variants

For each angle, generate two background variants:

**Clean white (e-commerce)**
```
Prompt suffix: "on pure white background (#FFFFFF), clean studio lighting,
soft box from upper-left, subtle shadow beneath product, no props,
product fills 85% of frame, e-commerce listing quality"
```

**Branded background**
```
Prompt suffix: "on {brand_background_color} background, {brand_style} aesthetic,
{brand_lighting_default}, brand-consistent color palette
({brand_primary}, {brand_secondary}, {brand_accent}),
subtle organic shapes or textures matching brand mood"
```

**Shadow/reflection variant**
```
Prompt suffix: "on reflective dark surface, product reflected below,
dramatic rim lighting from behind, premium product photography,
moody but brand-consistent color temperature"
```

### Batch Mode

Generate all angles for all products in one run:
```bash
# Single product, all angles
bash scripts/product-studio.sh packshot --brand mirra --product "bento-box-a"
# Generates: mirra_bento-box-a_packshot_overhead_white.png
#            mirra_bento-box-a_packshot_hero-45_white.png
#            mirra_bento-box-a_packshot_front_white.png
#            mirra_bento-box-a_packshot_back_white.png
#            mirra_bento-box-a_packshot_closeup_white.png
#            mirra_bento-box-a_packshot_overhead_branded.png
#            mirra_bento-box-a_packshot_hero-45_branded.png
#            mirra_bento-box-a_packshot_front_branded.png

# Pinxin Vegan — nasi lemak set, all angles
bash scripts/product-studio.sh packshot --brand pinxin-vegan --product "nasi-lemak-set"
# Generates: pinxin-vegan_nasi-lemak-set_packshot_overhead_white.png
#            pinxin-vegan_nasi-lemak-set_packshot_hero-45_white.png
#            pinxin-vegan_nasi-lemak-set_packshot_front_white.png
#            pinxin-vegan_nasi-lemak-set_packshot_closeup_white.png
#            pinxin-vegan_nasi-lemak-set_packshot_overhead_branded.png
#            pinxin-vegan_nasi-lemak-set_packshot_hero-45_branded.png

# Pinxin Vegan — full product line (rendang, satay, char kway teow, mixed rice)
bash scripts/product-studio.sh packshot --brand pinxin-vegan --all-products

# All products for a brand
bash scripts/product-studio.sh packshot --brand mirra --all-products
```

### Pack Shot Prompt Template (Production-Ready)

```
Professional product photography of {PRODUCT_NAME} by {BRAND_DISPLAY_NAME}.
{ANGLE_PROMPT_MODIFIER}.
{BACKGROUND_VARIANT_PROMPT}.
Sharp focus on product, shallow depth of field background.
{BRAND_LIGHTING_DEFAULT}.
Color palette: {BRAND_COLORS_DESCRIPTION}.
{BRAND_PHOTOGRAPHY_STYLE}.
High-end e-commerce listing quality, {IMAGE_SIZE} resolution.
Absolutely photorealistic, no AI artifacts, no warped text on labels.
```

**With reference image (preferred -- anchors real product):**
```
Reference image 1 shows the EXACT product -- replicate this product faithfully.
Professional product photography of the EXACT product from reference 1.
{ANGLE_PROMPT_MODIFIER}.
{BACKGROUND_VARIANT_PROMPT}.
Maintain exact product shape, color, label design, and proportions from reference 1.
{BRAND_LIGHTING_DEFAULT}.
Color palette: {BRAND_COLORS_DESCRIPTION}.
Photorealistic, production-ready, no AI artifacts.
```

**Pinxin Vegan Pack Shot Example (filled template):**
```
Professional product photography of Pinxin Vegan Nasi Lemak Set by Pinxin Vegan.
45-degree angle, slight elevation, hero product shot.
On dark forest green #1C372A background, bold Malaysian street food aesthetic,
warm natural high-contrast lighting with visible steam,
brand-consistent color palette (dark forest green #1C372A, gold #d0aa7f, light beige #F2EEE7).
Banana leaf lining, sambal glistening, coconut rice steaming.
Sharp focus on product, shallow depth of field background.
High-end e-commerce listing quality, 2K resolution.
Absolutely photorealistic, no AI artifacts, no warped text on labels.
```

---

## Module B: Product Placement Engine

Place real products into AI-generated lifestyle scenes that match brand mood, audience, and context.

### The 3-Step Composite Workflow

**Step 1: Generate base scene**
Generate the background scene WITHOUT the product, matching brand mood from DNA.json.

```
Prompt: "{SCENE_DESCRIPTION}, empty space where product will be placed,
{BRAND_LIGHTING_DEFAULT}, {BRAND_STYLE} aesthetic,
warm and inviting atmosphere, Malaysian context,
photorealistic, {IMAGE_SIZE} resolution.
Color temperature matching {BRAND_COLORS_DESCRIPTION}."
```

**Step 2: Composite product into scene using reference image**
Use the actual product photo as reference input to NanoBanana Pro:

```
Reference image 1 shows the EXACT product to place in the scene.
Reference image 2 shows the target scene/environment style.
Place the EXACT product from reference 1 naturally into a {SCENE_DESCRIPTION}.
Product should appear as if it belongs in the scene -- matching lighting direction,
color temperature, and scale.
{BRAND_LIGHTING_DEFAULT}.
Natural shadows where product meets surface.
Photorealistic integration, no compositing artifacts, no floating effect.
Product label readable, proportions accurate to reference 1.
```

**Step 3: Lighting and color match validation**
After generation, run brand audit to verify:
- Product lighting direction matches scene lighting
- Color temperature is consistent across product and environment
- Shadow direction is consistent
- Product scale is realistic within the scene

### Scene Templates by Brand Category

#### F&B Brands (pinxin-vegan, gaia-eats, mirra, gaia-recipes)

| Scene | Description | Prompt Template | Best For |
|-------|-------------|----------------|----------|
| Kitchen counter | Modern Malaysian kitchen, marble or wood countertop, natural window light | `modern Malaysian kitchen counter, marble surface, natural light from window on left, potted herbs in background, clean and warm` | Hero shots, recipe context |
| Dining table | Set dining table, warm lighting, family meal context | `warm dining table setting, wooden table, warm ambient lighting, napkin and utensils, family meal atmosphere, Malaysian home` | Community/family angle |
| Picnic | Outdoor park setting, blanket, natural daylight | `outdoor picnic setting on woven mat, dappled sunlight through trees, Malaysian park, green grass, relaxed weekend vibe` | Lifestyle, weekend content |
| Hawker stall | Malaysian hawker center, street food context | `Malaysian hawker stall counter, stainless steel, warm fluorescent lighting, authentic kopitiam atmosphere, bustling market` | Heritage, authenticity |
| Office desk | Modern workspace, lunch at desk scenario | `modern office desk, clean workspace, product as healthy lunch option, natural light from window, productivity context` | Working professional persona |
| Food truck | Trendy food truck counter, casual outdoor setting | `food truck serving window, colorful signage, outdoor market atmosphere, casual urban Malaysian setting` | Youth/trendy content |
| Breakfast tray | Bed or couch morning routine, tray with product | `morning breakfast tray on white bedding, product alongside coffee/tea, soft morning light, self-care moment` | Morning routine content |

#### Wellness Brands (dr-stan, gaia-supplements, serein, rasaya)

| Scene | Description | Prompt Template | Best For |
|-------|-------------|----------------|----------|
| Bathroom shelf | Organized bathroom shelf, morning/evening routine | `clean bathroom shelf, organized wellness products, soft diffused light, morning routine setting, modern and calm` | Daily routine angle |
| Yoga mat | Yoga/exercise space, post-workout context | `yoga mat on wooden floor, product beside mat, soft natural light, zen atmosphere, calming wellness space` | Active lifestyle |
| Morning routine | Kitchen or bathroom, first-thing-in-the-morning feel | `bright morning kitchen counter, golden sunrise light, fresh start atmosphere, product as daily ritual` | Habit-building content |
| Gym bag | Open gym bag, active lifestyle items | `open gym bag on bench, product visible among workout essentials, locker room or home entryway, energetic` | Fitness audience |
| Nightstand | Bedside table, evening wind-down | `bedside nightstand, warm lamp light, book and product, calming evening atmosphere, wind-down ritual` | Evening routine |
| Kitchen prep | Kitchen counter with ingredients, preparation moment | `kitchen counter with raw ingredients (turmeric, ginger, herbs), mortar and pestle, product nearby, warm amber light` | Heritage/natural angle |
| Office wellness | Desk with product, mindful work break | `organized desk, product as part of work-day wellness routine, natural light, plant nearby, mindful pause` | Professional persona |

#### Print & Creative (gaia-print, gaia-os, iris)

| Scene | Description | Prompt Template | Best For |
|-------|-------------|----------------|----------|
| Workspace | Creative desk, design tools, inspiration board | `creative workspace desk, product displayed, design tools nearby, inspiration board in background, modern and artistic` | Creative persona |
| Gallery wall | Product displayed on wall or shelf as art | `modern gallery-style white wall, product displayed as focal piece, track lighting, curated aesthetic` | Premium display |
| Gift wrapping | Product as gift, wrapping materials, occasion context | `gift wrapping scene, kraft paper and twine, product as thoughtful gift, warm holiday or birthday atmosphere` | Seasonal/gifting |
| Street style | Urban outdoor, product in real-world context | `urban Malaysian street scene, product in use/visible, street style photography, trendy and authentic` | Youth marketing |
| Flat lay styled | Overhead arranged with complementary lifestyle items | `overhead flat lay, product center, styled with complementary items (coffee, sunglasses, phone), magazine quality` | Instagram feed |

### Product Placement Prompt Engineering

**Key principle:** Describe the product's relationship to the scene, not just its presence.

Good: `"MIRRA bento box sitting naturally on the kitchen counter, slightly angled as if just placed down, condensation on container suggesting freshness"`

Good: `"Pinxin Vegan nasi lemak on a banana leaf at a hawker stall, steam rising from the coconut rice, sambal glistening under warm fluorescent light, a kopi-o ice sweating beside it"`

Bad: `"MIRRA bento box on kitchen counter"` (too vague, product will look pasted in)

**Interaction words that create natural placement:**
- "resting on", "sitting naturally beside", "placed casually on"
- "leaning against", "tucked into", "peeking out of"
- "being reached for", "just set down", "in the middle of being opened"

**Environmental integration cues:**
- "matching the warm color temperature of the room"
- "catching the same directional light as surrounding objects"
- "casting a natural shadow consistent with the scene lighting"
- "slightly reflecting the ambient colors of the environment"

---

## Module C: Model & Outfit Swap

Generate models interacting with products, maintaining product consistency while varying demographics, poses, and outfits.

### Character Consistency Technique

Uses the character-lock skill protocol (see `~/.openclaw/skills/character-lock/SKILL.md`):

1. **Face refs dominate** -- face references must be 60%+ of total refs
2. **Ref ordering matters** -- face refs in slots 1-3, product refs in slots 4-5, body refs in slots 6-7
3. **Explicit ref labeling** -- tell the model which refs are face, which are product
4. **One change at a time** -- swap model OR outfit OR pose, never all three simultaneously
5. **Flash for full-body** -- use `gemini-3.1-flash-image-preview` for full-body model shots (better face lock)
6. **Pro for close-ups** -- use `gemini-3-pro-image-preview` for portrait/close-up (better beauty)

### Ref Image Setup for Model Shots

```
Slot 1: Face ref (primary)
Slot 2: Face ref (angle 2)
Slot 3: Face ref (angle 3)      -- 3 face = anchors identity
Slot 4: Product photo            -- anchors product appearance
Slot 5: Product photo (angle 2)  -- reinforces product
Slot 6: Body type ref (optional) -- anchors physique
Slot 7: Style ref (optional)     -- anchors outfit/scene mood
```

Face percentage: 3/5 = 60% (minimum) or 3/7 = 43% (add duplicates to reach 60%).

### Model Swap Workflow

Keep product constant, swap the human model:

```
EXACT SAME PRODUCT from reference images 4-5 -- do NOT change the product.
Reference images 1-3 show the NEW MODEL's face -- keep this EXACT face.
{MODEL_DESCRIPTION} holding/using the EXACT product from references 4-5.
{POSE_DESCRIPTION}.
{SCENE_CONTEXT}.
Product label must remain readable, product shape and color unchanged from refs 4-5.
{BRAND_LIGHTING_DEFAULT}.
Photorealistic, editorial quality, natural interaction between model and product.
```

### Outfit Swap Workflow

Keep model AND product constant, change only clothing:

```
EXACT SAME PERSON from reference images 1-3 -- keep this EXACT face, hair, and proportions.
EXACT SAME PRODUCT from reference images 4-5 -- product unchanged.
Same person now wearing {NEW_OUTFIT_DESCRIPTION}.
Same pose, same lighting, same background.
Change ONLY the outfit -- face, body, product, scene all remain identical.
{BRAND_STYLE} aesthetic.
Photorealistic, no identity drift.
```

### Demographic Diversity Matrix

For inclusive marketing, generate each product shot with diverse representation:

| Demographic Group | Description Anchor | Recommended For |
|------------------|-------------------|-----------------|
| Malay woman 25-35 | `young Malay woman, hijab/without hijab, warm smile, professional` | All Malaysian brands |
| Chinese woman 28-40 | `Chinese Malaysian woman, modern, confident, natural look` | All Malaysian brands |
| Indian woman 25-35 | `Indian Malaysian woman, vibrant, warm expression` | All Malaysian brands |
| Man 28-40 | `Malaysian man, friendly, health-conscious, modern casual` | Fitness, supplements |
| Mature woman 45-55 | `mature Malaysian woman, elegant, warm, experienced` | Heritage brands (rasaya) |
| Young adult 20-25 | `young Malaysian adult, energetic, Gen Z style, expressive` | gaia-print, wholey-wonder |
| Family group | `Malaysian family (mother, father, child), warm interaction` | Family meal brands |
| Fitness-focused | `fit Malaysian adult, athletic build, active lifestyle look` | wholey-wonder, dr-stan |

### Pose Library

| Pose Code | Description | Prompt Anchor | Best Product Types |
|-----------|-------------|--------------|-------------------|
| `hold-front` | Holding product in front, facing camera | `holding {product} in both hands at chest height, facing camera, friendly smile` | All |
| `hold-side` | Casual side hold, lifestyle feel | `casually holding {product} at side, relaxed stance, looking at camera with slight smile` | Beverages, print |
| `use-active` | Actively using/consuming the product | `in the middle of using/eating/drinking {product}, natural candid moment` | Food, beverages |
| `table-near` | Product on table, model nearby | `seated at table, {product} on table in front, reaching for it or looking at it` | Food, supplements |
| `bag-peek` | Product visible in bag or hand while moving | `walking, {product} visible in tote bag or hand, urban lifestyle, on-the-go` | Print, beverages |
| `prep-cook` | Preparing/cooking with product | `in kitchen, preparing meal with {product}, cooking action, warm atmosphere` | Food brands |
| `morning` | Morning routine with product | `morning routine, just woke up, {product} on counter, reaching for it` | Supplements, wellness |
| `share` | Sharing product with another person | `offering/sharing {product} with friend, warm interaction, genuine smile` | All (community angle) |

### Brand-Specific Model Guidelines

Load from DNA.json `audience.personas` to match model casting to target demographic:

| Brand | Primary Model Profile | Secondary | Style Notes |
|-------|----------------------|-----------|-------------|
| mirra | Woman 25-45, KL professional, weight-management-conscious | Mom, fitness persona | Warm, feminine, relatable -- NOT model-perfect. Weight management meal subscription brand. |
| pinxin-vegan | Health-conscious Malaysian 25-45, bold | Home cook, foodie | Bold confidence, proudly Malaysian |
| wholey-wonder | Urban millennial 22-38, active | Fitness enthusiast, social media native | Energetic, bright, optimistic |
| rasaya | Woman 30-60, heritage-connected | Young adult reconnecting with tradition | Warm, nurturing, timeless |
| gaia-eats | Malaysian 25-45, food passionate | Working professional, parent | Warm, authentic, community feel |
| dr-stan | Adult 30-55, evidence-minded | Health professional, fitness-focused | Authoritative but approachable |
| serein | Urban professional 28-50, self-care | Mindfulness practitioner | Tranquil, gentle, soft luxury |
| gaia-supplements | Adult 25-50, wellness-focused | Fitness enthusiast, parent | Clean, trustworthy, premium feel |
| gaia-recipes | Home cook 20-50, enthusiastic | Beginner cook, busy parent | Encouraging, warm, approachable |
| gaia-print | Gen Z / millennial 18-35 | University student, eco-activist | Bold, edgy, streetwear-meets-sustainable |
| gaia-learn | Aspiring professional 25-55 | Health professional, entrepreneur | Authoritative, empowering |
| jade-oracle | Woman 25-45, spiritual seeker | Chinese diaspora entrepreneur | Warm, editorial, Korean beauty aesthetic |
| gaia-os | N/A (system brand) | N/A | Sacred futurism, digital deity -- no human models |
| iris | N/A (agent brand) | N/A | Tech-minimalist -- no human models, use geometric/portal imagery |

---

## Brand Matrix

Complete reference for what to generate per brand.

| Brand | Category | Primary Products | Pack Shot Angles | Scene Types | Model Demographics | Style Notes |
|-------|----------|-----------------|-----------------|-------------|-------------------|-------------|
| **pinxin-vegan** | F&B | Vegan rendang, laksa paste, satay sauce, tempeh chips, nasi lemak kit | Overhead flatlay, 45 hero, front/back packaging, ingredient close-up | Kitchen counter, hawker stall, dining table, food truck | Malay/Chinese/Indian women 25-45, bold and confident | Bold Malaysian street food aesthetic, warm high-contrast, steam visible |
| **mirra** | F&B (weight management meal subscription) | Calorie-controlled meals, weekly meal plans, weight management bentos | Overhead flatlay (primary), 45 hero, front packaging, ingredient close-up | Kitchen counter, office desk lunch, dining table, breakfast tray | Women 25-45 KL professionals, moms, fitness personas | Warm feminine pink/cream, comparison layouts, calorie badges, NOT skincare/cosmetics |
| **wholey-wonder** | F&B (wellness) | Acai bowls, smoothies, superfood blends, wellness drinks | Overhead flatlay, pour shot, hold shot, ingredient spread | Yoga mat, morning routine, gym, bright kitchen, outdoor | Urban millennials 22-38, fitness-focused, social media savvy | Bright energetic purple/gold, clean whites, sunrise tones |
| **rasaya** | F&B (heritage) | Jamu drinks, herbal blends, traditional remedies, turmeric paste | Bottle hero, pour shot, ingredient spread, heritage mortar & pestle | Heritage kitchen, kitchen prep, morning routine, market | Women 30-60, heritage-connected, nurturing | Warm amber, earthy, grandmother's kitchen, heritage-proud |
| **gaia-eats** | F&B | Plant-based meals, meal kits, cooking pastes, snacks | Overhead flatlay, 45 hero, front/back packaging, recipe step | Kitchen counter, dining table, picnic, food truck | Malaysian 25-45, food lovers, community | Warm natural sage green/gold, magazine editorial, appetizing |
| **gaia-recipes** | F&B (content) | Recipe kits, ingredient sets, cooking tools | Overhead flatlay, step-by-step sequence, ingredient spread | Home kitchen, cooking in progress, ingredient prep, dining table | Home cooks 20-50, beginners to experienced | Warm, instructional, bright kitchen light, inviting |
| **dr-stan** | Wellness | Supplements, health products, evidence-based nutrition | Bottle front, capsule close-up, ingredient spread, lifestyle shelf | Bathroom shelf, morning routine, office wellness, kitchen | Adults 30-55, evidence-based, professional | Clean authoritative navy/white/green, modern studio, science-meets-lifestyle |
| **gaia-supplements** | Wellness | Capsules, powders, wellness bottles, natural vitamins | Bottle front, capsule detail, ingredient spread, shelf lifestyle | Bathroom shelf, kitchen counter, gym bag, morning routine | Adults 25-50, wellness-focused, fitness | Clean clinical-warm green, premium, science-meets-nature |
| **serein** | Wellness | Wellness sets, calming products, self-care rituals | Product front, texture detail, lifestyle shelf, ritual setup | Bathroom shelf, nightstand, yoga mat, morning/evening routine | Urban professionals 28-50, self-care enthusiasts | Soft mint/pink, tranquil, diffused light, spa-like |
| **gaia-print** | Merch | T-shirts, tote bags, mugs, notebooks, stickers | Flat lay, mockup, worn/in-use, detail texture, lifestyle | Workspace, street style, flat lay styled, gift wrapping | Gen Z / millennials 18-35, eco-conscious | Bold streetwear-meets-sustainable, modern, trendy |
| **gaia-learn** | Education | Course materials, workbooks, digital products | Product front, open book/screen, lifestyle desk, flat lay | Workspace, classroom, home study desk, cafe | Aspiring professionals 25-55 | Clean modern educational, bright and professional |
| **jade-oracle** | Spiritual | Reading cards, oracle decks, spiritual guides, digital products | Card spread, close-up detail, lifestyle altar, ritual | Home altar, cozy reading nook, tea ceremony, warm study | Women 25-45, spiritual seekers, Korean beauty editorial | Warm jade/cream/burgundy, editorial, NOT cosmic/galaxy |
| **gaia-os** | Technology | Digital system, AI platform (no physical products) | UI screenshots, system diagrams, concept art | Dark futuristic environments, digital spaces | No human models -- system/avatar imagery only | Sacred futurism, dark palette, gold accents, volumetric light |
| **iris** | Agent | AI agent identity (no physical products) | Geometric art, portal imagery, identity visuals | Tech-minimalist environments, digital spaces | No human models -- geometric/abstract imagery | Dark tech-minimalist, purple/blue, concentric circles |

---

## Workflow SOP (Step by Step)

### Pre-Flight

Before running any generation:

1. **Verify brand DNA exists:** `cat ~/.openclaw/brands/{brand}/DNA.json | head -5`
2. **Check for existing product photos:** `ls ~/.openclaw/workspace/data/images/{brand}/` -- real photos are ALWAYS preferred as reference input
3. **Determine product type:** food / beverage / supplement / print / digital -- this selects the angle and scene template sets
4. **Check avoid-list:** Read `DNA.json -> visual.avoid` -- these are hard constraints that MUST NOT appear in any generated image

### Full Product Studio Run — Pinxin Vegan Example

```bash
# Generate complete visual library for Pinxin Vegan nasi lemak set
bash scripts/product-studio.sh generate --brand pinxin-vegan --product "nasi-lemak-set"

# This runs the full pipeline:
# Module A (pack shots): overhead flatlay, 45-degree hero, front packaging, close-up sambal texture
#   → dark forest green #1C372A branded backgrounds, warm high-contrast lighting, steam visible
# Module B (lifestyle scenes): hawker stall counter, kopitiam dining, food truck, office lunch
#   → bold Malaysian street food aesthetic, banana leaf lining, warm natural light
# Module C (model shots): health-conscious Malaysian woman 25-45, bold confidence
#   → GrabFood delivery context, Shopee listing hero, WhatsApp catalog image
# Output: ~/.openclaw/workspace/data/images/pinxin-vegan/product-studio/
```

### Step 1: Load Brand DNA

```bash
# Extract all visual parameters from DNA.json
BRAND="mirra"
DNA_FILE="$HOME/.openclaw/brands/${BRAND}/DNA.json"

# Key fields to extract:
# visual.colors.primary, secondary, background, accent
# visual.typography
# visual.photography
# visual.lighting_default
# visual.style
# visual.avoid (HARD CONSTRAINTS)
# visual.badges (if present)
# visual.logo_placement (if present)
# audience.primary
# audience.personas
# products (list of product names)
```

### Step 2: Select Product Type and Templates

Map product to type:
- Bento box, meal set, rendang, laksa, nasi lemak --> **food**
- Jamu, turmeric latte, smoothie, acai bowl --> **beverage**
- Capsule, powder, supplement bottle --> **supplement**
- T-shirt, tote bag, mug --> **print**
- Oracle deck, reading cards --> **specialty** (use jade-oracle specific rules)
- Course, workbook, digital product --> **digital** (screenshot + lifestyle only)

### Step 3: Generate Pack Shots (Module A)

Run pack shot generation for the selected product type. Uses the angle matrix from Module A above.

```bash
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand "${BRAND}" \
  --prompt "${PACKSHOT_PROMPT}" \
  --ref-image "${PRODUCT_PHOTO}" \
  --size 2K \
  --ratio 1:1
```

**Generation order (important for consistency):**
1. Front view on white background FIRST -- this becomes the anchor reference
2. Use output from (1) as additional reference for all subsequent angles
3. Generate remaining angles: 45 hero, overhead, back, close-up
4. Generate branded background variants using front view as ref
5. Generate shadow/reflection variant last

**Expected output:** 6-8 images per product
- `{brand}_{product}_packshot_front_white.png`
- `{brand}_{product}_packshot_hero-45_white.png`
- `{brand}_{product}_packshot_overhead_white.png`
- `{brand}_{product}_packshot_back_white.png`
- `{brand}_{product}_packshot_closeup_white.png`
- `{brand}_{product}_packshot_front_branded.png`
- `{brand}_{product}_packshot_hero-45_branded.png`
- `{brand}_{product}_packshot_front_shadow.png`

### Step 4: Generate Lifestyle Scenes (Module B)

Use the best pack shot from Step 3 as the product reference for placement.

```bash
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand "${BRAND}" \
  --prompt "${PLACEMENT_PROMPT}" \
  --ref-image "${BEST_PACKSHOT},${BRAND_STYLE_REF}" \
  --size 2K \
  --ratio 4:3 \
  --model flash
```

**Scene selection:** Pick 4-6 scenes from the brand-category scene templates in Module B. Prioritize:
1. The scene most aligned with the primary persona in DNA.json
2. One aspirational/lifestyle scene
3. One heritage/authenticity scene (for Malaysian brands)
4. One social-media-optimized scene (9:16 for stories)

**Expected output:** 4-6 images per product
- `{brand}_{product}_placement_kitchen_v1.png`
- `{brand}_{product}_placement_dining_v1.png`
- `{brand}_{product}_placement_office_v1.png`
- `{brand}_{product}_placement_lifestyle_v1.png`
- `{brand}_{product}_placement_story-9x16_v1.png` (vertical format)

### Step 5: Generate Model Shots (Module C)

Use character-lock protocol. Requires either existing locked face refs or new model generation.

```bash
# If generating new model (no existing character):
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh character-sheet \
  --brand "${BRAND}" \
  --description "${MODEL_DESCRIPTION}" \
  --poses "front,side,holding-product"

# Then generate model + product shots:
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand "${BRAND}" \
  --prompt "${MODEL_PROMPT}" \
  --ref-image "${FACE_REFS},${PRODUCT_PHOTO}" \
  --size 2K \
  --ratio 4:5 \
  --model flash
```

**Expected output:** 3-4 images per product
- `{brand}_{product}_model_hold-front_v1.png`
- `{brand}_{product}_model_use-active_v1.png`
- `{brand}_{product}_model_table-near_v1.png`
- `{brand}_{product}_model_share_v1.png` (if applicable)

### Step 6: Quality Check

Run every generated image through the quality checklist (see Section 7 below). Automated via brand-studio audit:

```bash
bash /Users/jennwoeiloh/.openclaw/skills/brand-studio/scripts/audit.sh \
  --brand "${BRAND}" \
  --image "${OUTPUT_IMAGE}"
```

**Reject and regenerate if:**
- Overall score < 7.0/10
- Product shape/color does not match reference
- Brand colors significantly off
- AI artifacts present (extra fingers, warped text, melted objects)
- Lighting inconsistency between product and scene

**Max retries:** 3 per image. If 3 fails, flag for manual review.

### Step 7: Export and Register

```bash
# Move to canonical output path
OUTPUT_DIR="$HOME/.openclaw/workspace/data/images/${BRAND}/product-studio/"
mkdir -p "${OUTPUT_DIR}"
mv generated_images/* "${OUTPUT_DIR}/"

# Register in visual-registry for asset tracking
bash /Users/jennwoeiloh/.openclaw/skills/visual-registry/scripts/register.sh \
  --brand "${BRAND}" \
  --type "product-studio" \
  --path "${OUTPUT_DIR}" \
  --product "${PRODUCT_NAME}"
```

---

## CLI Usage

```bash
# Full pipeline for a product (all 3 modules)
bash scripts/product-studio.sh generate \
  --brand mirra \
  --product "bento-box-a" \
  --ref-image /path/to/photo.jpg

# Pack shots only (Module A)
bash scripts/product-studio.sh packshot \
  --brand pinxin-vegan \
  --product "nasi-lemak-set"

# Pack shots with custom angles
bash scripts/product-studio.sh packshot \
  --brand gaia-eats \
  --product "rendang-paste" \
  --angles "front,hero-45,overhead,closeup"

# Product placement only (Module B)
bash scripts/product-studio.sh placement \
  --brand rasaya \
  --product "turmeric-latte" \
  --scene kitchen

# Product placement with multiple scenes
bash scripts/product-studio.sh placement \
  --brand rasaya \
  --product "turmeric-latte" \
  --scenes "kitchen,morning-routine,heritage-prep"

# Model swap (Module C)
bash scripts/product-studio.sh model-swap \
  --brand wholey-wonder \
  --product "acai-bowl" \
  --demographics diverse

# Model swap with specific demographic
bash scripts/product-studio.sh model-swap \
  --brand mirra \
  --product "bento-box-a" \
  --model "Malay woman 30, hijab, professional, warm smile"

# Outfit swap (keep same model, change clothes)
bash scripts/product-studio.sh outfit-swap \
  --brand gaia-print \
  --product "eco-tee-v1" \
  --face-refs "/path/to/locked-face-01.png,/path/to/locked-face-02.png" \
  --outfits "casual-streetwear,office-smart,weekend-outdoor"

# Batch all products for a brand (full pipeline)
bash scripts/product-studio.sh batch --brand mirra

# Batch pack shots only for a brand
bash scripts/product-studio.sh batch --brand mirra --module packshot

# Campaign-specific generation
bash scripts/product-studio.sh generate \
  --brand mirra \
  --product "bento-box-a" \
  --campaign cny-2026 \
  --funnel-stage TOFU

# Dry run (show what would be generated, no API calls)
bash scripts/product-studio.sh generate \
  --brand mirra \
  --product "bento-box-a" \
  --dry-run
```

### CLI Flags Reference

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--brand` | Yes | -- | Brand slug (e.g., mirra, pinxin-vegan) |
| `--product` | Yes* | -- | Product slug (* not needed for batch) |
| `--ref-image` | No | -- | Path to real product photo (comma-separated for multiple) |
| `--module` | No | all | `packshot`, `placement`, `model-swap`, or `all` |
| `--angles` | No | type default | Comma-separated angle list |
| `--scenes` | No | brand default | Comma-separated scene list |
| `--demographics` | No | brand default | `diverse` or specific model description |
| `--model` | No | -- | Specific model description for model-swap |
| `--face-refs` | No | -- | Comma-separated locked face ref paths |
| `--outfits` | No | -- | Comma-separated outfit descriptions for outfit-swap |
| `--campaign` | No | -- | Campaign slug for campaign-specific overrides |
| `--funnel-stage` | No | -- | TOFU / MOFU / BOFU |
| `--size` | No | 2K | Image size: 1K, 2K, 4K |
| `--ratio` | No | 1:1 | Aspect ratio |
| `--all-products` | No | false | Process all products from DNA.json |
| `--dry-run` | No | false | Show plan without generating |
| `--output-dir` | No | canonical | Override output directory |

---

## Prompt Templates (Production-Ready)

### Template 1: Pack Shot -- Food Product (White Background)

```
Professional e-commerce product photography of {PRODUCT_NAME} by {BRAND_DISPLAY_NAME}.
{ANGLE}: {ANGLE_PROMPT_MODIFIER}.
Pure white background (#FFFFFF), professional studio lighting with soft box from upper-left.
Product centered in frame, fills 85% of image area.
Sharp focus on product, razor-sharp label text, shallow depth of field.
Subtle natural shadow beneath product on white surface.
Food looks fresh, appetizing, vibrant colors -- {BRAND_PHOTOGRAPHY_STYLE}.
Absolutely photorealistic, no AI artifacts, no warped text, no unnatural reflections.
Professional commercial photography quality, suitable for Shopee/Lazada/Shopify listing.
```

### Template 2: Pack Shot -- Food Product (Branded Background)

```
Styled product photography of {PRODUCT_NAME} by {BRAND_DISPLAY_NAME}.
{ANGLE}: {ANGLE_PROMPT_MODIFIER}.
Background: {BRAND_BACKGROUND_COLOR} with subtle {BRAND_STYLE} textures.
{BRAND_LIGHTING_DEFAULT}.
Product centered, complementary props from brand aesthetic
(fresh herbs, wooden utensils, linen napkin -- all in {BRAND_COLORS} palette).
Brand color palette visible: {PRIMARY}, {SECONDARY}, {ACCENT}.
Food looks appetizing and inviting, styled for social media.
{BRAND_PHOTOGRAPHY_STYLE}.
Magazine editorial quality, Instagram-ready composition.
```

### Template 3: Pack Shot -- Supplement/Wellness Product

```
Premium product photography of {PRODUCT_NAME} by {BRAND_DISPLAY_NAME}.
{ANGLE}: {ANGLE_PROMPT_MODIFIER}.
Clean {BACKGROUND_TYPE} background, {BRAND_LIGHTING_DEFAULT}.
Product centered, label sharply readable, no text warping.
{IF_CAPSULE: Capsules arranged artfully, showing texture and natural ingredients.}
{IF_BOTTLE: Bottle form clearly visible, label text crisp and legible.}
Premium supplement brand aesthetic -- clean, trustworthy, science-backed.
Color palette: {BRAND_COLORS_DESCRIPTION}.
No cheap supplement brand look. Professional, credible, premium.
Photorealistic, commercial photography quality.
```

### Template 4: Pack Shot -- Print/Merch Product

```
Professional mockup photography of {PRODUCT_NAME} by {BRAND_DISPLAY_NAME}.
{ANGLE}: {ANGLE_PROMPT_MODIFIER}.
{IF_FLAT_LAY: Perfectly flat on clean surface, garment neatly spread, design fully visible.}
{IF_WORN: Model wearing product in natural pose, design visible and undistorted.}
{IF_MOCKUP: Clean product mockup, white background, commercial e-commerce quality.}
Print design clearly visible, colors accurate, fabric texture natural.
{BRAND_STYLE} aesthetic -- bold, modern, {BRAND_PHOTOGRAPHY_STYLE}.
No wrinkles distorting the print, design proportions accurate.
Professional product photography quality.
```

### Template 5: Product Placement -- F&B Scene

```
Reference image 1 shows the EXACT product -- place it faithfully in the scene.
{IF_STYLE_REF: Reference image 2 shows the styling/mood reference.}
Lifestyle photography: {PRODUCT_NAME} by {BRAND_DISPLAY_NAME} naturally placed on {SCENE_SURFACE}.
Scene: {SCENE_DESCRIPTION}.
Product resting naturally on {SURFACE}, slight angle as if just placed down.
{BRAND_LIGHTING_DEFAULT}, same lighting direction on product and scene.
Natural shadows, product integrates seamlessly into environment.
Complementary props: {SCENE_PROPS_FOR_BRAND}.
Malaysian {CONTEXT: home/cafe/hawker/office} setting, authentic and inviting.
Color temperature: warm, matching {BRAND_COLORS_DESCRIPTION}.
The product is the focal point but feels like it belongs in this world.
Photorealistic, no compositing artifacts, no floating product, no scale errors.
```

### Template 6: Product Placement -- Wellness Scene

```
Reference image 1 shows the EXACT product -- place it faithfully in the scene.
Wellness lifestyle photography: {PRODUCT_NAME} by {BRAND_DISPLAY_NAME} in a {SCENE_TYPE} setting.
Scene: {SCENE_DESCRIPTION}.
Product placed naturally on {SURFACE} as part of a daily {ROUTINE_TYPE} ritual.
{BRAND_LIGHTING_DEFAULT}.
Calm, intentional atmosphere -- product feels like an essential part of the routine.
Clean, organized surrounding with minimal but purposeful props.
Color palette: {BRAND_COLORS_DESCRIPTION}.
{BRAND_STYLE} aesthetic.
Photorealistic, natural integration, trustworthy and premium feel.
```

### Template 7: Model with Product -- Hero Shot

```
Reference images 1-3 show the MODEL's FACE -- keep this EXACT face, bone structure, features.
Reference images 4-5 show the EXACT PRODUCT -- do NOT change the product.
{IF_BODY_REF: Reference images 6-7 show BODY TYPE reference ONLY.}

EXACT SAME PERSON from references 1-3 -- do NOT generate a different person.
Her/his face, bone structure, eyes, nose, jawline, smile, and hair MUST be identical to references 1-3.

{MODEL_DESCRIPTION} {POSE_DESCRIPTION} with {PRODUCT_NAME} by {BRAND_DISPLAY_NAME}.
Product clearly visible, label readable, accurate to references 4-5.
{SCENE_CONTEXT}.
{BRAND_LIGHTING_DEFAULT}.
Natural interaction between model and product -- candid, not stiff.
{BRAND_STYLE} aesthetic, {BRAND_PHOTOGRAPHY_STYLE}.
Photorealistic, editorial quality. Natural skin texture, visible pores, individual hair strands.
No plasticky skin, no AI hands, no extra fingers, no warped product labels.
```

### Template 8: Model Swap -- Same Product, Different Person

```
Reference images 1-3 show the NEW MODEL's face -- keep this EXACT face.
Reference images 4-5 show the EXACT PRODUCT from previous shots -- do NOT change it.

New model: {NEW_MODEL_DESCRIPTION}.
EXACT SAME PRODUCT from references 4-5, same angle, same label visibility.
{POSE_DESCRIPTION}.
{SAME_SCENE_AS_PREVIOUS OR NEW_SCENE}.
{BRAND_LIGHTING_DEFAULT}.
Product interaction must look natural and unforced.
Same brand aesthetic as previous shots, {BRAND_STYLE}.
Photorealistic, editorial quality, diverse and inclusive representation.
```

### Template 9: Outfit Swap -- Same Person, Different Clothes

```
Reference images 1-3 show the EXACT SAME PERSON -- keep her/his face IDENTICAL.
Reference images 4-5 show the EXACT SAME PRODUCT -- unchanged.

SAME person, SAME product, SAME background and lighting.
ONLY CHANGE: outfit from {PREVIOUS_OUTFIT} to {NEW_OUTFIT_DESCRIPTION}.
Face, hair, body proportions, expression all remain identical to references 1-3.
Product remains identical to references 4-5.
{BRAND_LIGHTING_DEFAULT}.
One change only. No identity drift.
Photorealistic.
```

### Template 10: Batch Diversity -- Multiple Demographics

```
Reference image 1 shows the EXACT PRODUCT -- this must appear in every shot.

Photo {N} of {TOTAL}: {DEMOGRAPHIC_DESCRIPTION} with {PRODUCT_NAME}.
{POSE_DESCRIPTION}.
EXACT product from reference 1 -- same shape, color, label.
{SCENE_CONTEXT}.
{BRAND_LIGHTING_DEFAULT}.
{BRAND_STYLE} aesthetic.
Natural and relatable, not stock-photo-posed.
Photorealistic, inclusive, authentic Malaysian representation.
```

---

## Quality Checklist

Every generated image MUST pass ALL of these before being exported:

### Product Accuracy (Critical)
- [ ] Product shape matches reference photo (no warping, no wrong proportions)
- [ ] Product color matches reference (no color drift)
- [ ] Label text is readable and not warped (if label is part of the product)
- [ ] Product scale is realistic in the scene (not too big, not too small)
- [ ] Product orientation makes physical sense (not floating, not defying gravity)

### Brand Consistency (Critical)
- [ ] Color palette matches DNA.json (primary, secondary, accent present or harmonious)
- [ ] Lighting matches `visual.lighting_default` from DNA.json
- [ ] Style matches `visual.style` from DNA.json
- [ ] Photography style matches `visual.photography` from DNA.json
- [ ] NONE of the `visual.avoid` items are present in the image
- [ ] Logo/badge placement follows `visual.logo_placement` if specified
- [ ] Badges present if required (e.g., MIRRA calorie badges, "Nutritionist Designed")

### Lighting Coherence
- [ ] Light direction is consistent across product and scene
- [ ] Shadow direction matches light source
- [ ] Color temperature is consistent (no warm product in cool scene or vice versa)
- [ ] No impossible double-shadows or missing shadows
- [ ] Reflection (if present) matches scene lighting

### AI Artifact Scan
- [ ] No extra fingers or malformed hands on models
- [ ] No warped or melted text on product labels
- [ ] No impossible object geometry (melted bottles, merged items)
- [ ] No seam lines from compositing
- [ ] No plasticky or uncanny skin texture on models
- [ ] No blurred or smudged areas that break photorealism
- [ ] No repeated patterns (texture tiling visible)
- [ ] Hair looks natural (individual strands, not helmet)

### Resolution and Format
- [ ] Minimum 1080x1080 for social media content
- [ ] Minimum 2048px on longest side for e-commerce listings
- [ ] 4K for hero/banner images and print-ready assets
- [ ] Aspect ratio correct for target platform:
  - 1:1 for Instagram feed, Shopee/Lazada listing
  - 4:5 for Instagram feed (portrait)
  - 9:16 for Instagram/TikTok stories and reels
  - 16:9 for website banners and YouTube thumbnails
  - 3:4 for Pinterest pins

### Model-Specific Checks (Module C only)
- [ ] Face matches locked reference (no identity drift)
- [ ] Body proportions consistent across shots
- [ ] Outfit fits naturally (no impossible folds or floating fabric)
- [ ] Skin texture is realistic (pores visible, not plasticky)
- [ ] Expression is natural and on-brand
- [ ] Demographic representation is respectful and authentic

---

## Integration

### Feeds Into
- **`content-supply-chain`** (`~/.openclaw/skills/content-supply-chain/`) -- product images flow into the weekly content production pipeline
- **`ad-composer`** (`~/.openclaw/skills/ad-composer/`) -- pack shots and lifestyle scenes become inputs for ad creative generation
- **`creative-studio`** (`~/.openclaw/skills/creative-studio/`) -- model shots feed into campaign visual workflows
- **`brand-studio`** (`~/.openclaw/skills/brand-studio/`) -- generated images can be audited and looped through the brand-studio quality gate

### References (Dependencies)
- **`nanobanana`** (`~/.openclaw/skills/nanobanana/`) -- image generation engine (NanoBanana Flash + Pro via Gemini API). ALWAYS use `nanobanana-gen.sh`, NEVER call Gemini API directly.
- **`style-control`** (`~/.openclaw/skills/style-control/`) -- brand style enforcement, style seed management
- **`character-lock`** (`~/.openclaw/skills/character-lock/`) -- face lock and body consistency protocol for Module C model shots
- **`visual-registry`** (`~/.openclaw/skills/visual-registry/`) -- asset tracking and registration for all generated images
- **Brand DNA files** (`~/.openclaw/brands/{brand}/DNA.json`) -- source of truth for all visual parameters, colors, avoid-lists, and audience data

### Agent Responsibilities
- **Dreami** -- writes creative briefs, selects scenes and model descriptions, art-directs the pipeline
- **Taoz** -- builds and maintains the scripts, handles technical pipeline issues (via Claude Code CLI)
- **Iris** -- runs visual QA audits on generated images, flags quality issues

---

## Cost Estimate

| Operation | Approx Cost | Images |
|-----------|-------------|--------|
| Single pack shot (1 angle) | ~$0.02 | 1 |
| Full pack shot set (8 images) | ~$0.16 | 8 |
| Single placement scene | ~$0.02-0.04 | 1 |
| Full placement set (5 scenes) | ~$0.10-0.20 | 5 |
| Single model shot | ~$0.02-0.04 | 1 |
| Full model set (4 poses) | ~$0.08-0.16 | 4 |
| Quality audit per image | ~$0.01 | -- |
| **Full pipeline (1 product)** | **~$0.50-0.80** | **15-20** |
| **Full pipeline with retries** | **~$0.80-1.50** | **15-20** |
| **Batch (all products, 1 brand)** | **~$3-10** | varies |

All images include SynthID watermarks (Gemini standard). Use NanoBanana Flash for high-volume iterations and NanoBanana Pro for final production assets.

---

## Notes

- **MIRRA is a weight management meal subscription** (bento format) -- NOT cosmetics, NOT skincare, NOT the-mirra.com. Always generate food photography for calorie-controlled meals and weekly meal plans, never beauty/skincare products.
- **gaia-os and iris are non-product brands** -- they are system/agent brands. No physical product photography. Use concept art and digital identity workflows instead.
- **Real product photos as reference are ALWAYS preferred** over text-only prompts. Check `~/.openclaw/workspace/data/images/{brand}/` for existing product photography before generating from scratch.
- **One change at a time** -- when iterating on a generation, change ONE element (angle, lighting, background, model, outfit). Changing multiple elements causes drift.
- **Label text limitation** -- NanoBanana can produce readable text but frequently warps it. For e-commerce images where label text must be pixel-perfect, consider post-production text overlay or using real product photo crops.
- **Face lock is approximate** -- NanoBanana uses reference images as "inspiration" and drifts 20-40%. For critical face consistency across a campaign, use Kling 3.0 elements or LoRA training as fallback.
- **Malaysian context matters** -- scenes should feel authentically Malaysian (kopitiam, mamak, home kitchen, tropical outdoor) unless the brand specifically targets international audiences.
- **Always run `brand-voice-check.sh`** before publishing any image that includes text overlays.
- **Git commit after every significant batch** -- product-studio outputs are tracked in the visual-registry and should be committed.
