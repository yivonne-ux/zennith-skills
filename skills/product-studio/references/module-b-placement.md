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

