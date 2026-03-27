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

