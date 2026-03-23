---
name: brand-prompt-library
description: Curated prompt packs for AI image generation across all GAIA brands. F&B photography, wellness lifestyle, product shots, and campaign visuals. 200+ tested prompts organized by brand, product type, and use case.
agents: [dreami, taoz]
version: 1.0.0
---

# Brand Prompt Library

Pre-tested, brand-specific prompt templates for NanoBanana (Gemini Image API) that produce consistent, high-quality images. Each prompt is tagged by brand, product type, use case, and platform. 200+ prompts across 14 brands, with focus on F&B/wellness verticals.

---

## 1. Overview

This skill provides a curated library of production-ready image generation prompts, organized by brand, product type, and use case. Every prompt has been tested against NanoBanana (Gemini Image API) and scored for quality. Prompts are designed to be used directly with `nanobanana-gen.sh` or composed into campaigns via `ad-composer`, `product-studio`, `creative-studio`, and `content-supply-chain`.

**Key principles:**
- Every prompt encodes brand DNA (colors, lighting, mood) from `~/.openclaw/brands/{brand}/DNA.json`
- Prompts are modular: swap subject/product while keeping brand anchors intact
- NanoBanana-specific formatting: aspect ratio hints, style seed compatibility, reference image slots
- All prompts tested and scored (minimum 7/10 to be included)

### Workflow SOP

```
INPUT: Brand name + use case (e.g., "hero-shot", "lifestyle", "seasonal")
STEP 1: Load brand DNA → extract colors, mood, typography preferences
STEP 2: Select prompt pack for brand + use case
STEP 3: Apply brand color anchors to prompt template
STEP 4: Add lighting and style presets from brand profile
STEP 5: Generate image using NanoBanana with final prompt
STEP 6: Score output against quality criteria (1-10)
STEP 7: If score >= 7, register in visual-registry; if < 7, regenerate with adjusted prompt
OUTPUT: Production-ready image + prompt logged to learnings for compounding
```

### Output Paths

- Prompts stored at: `~/.openclaw/skills/brand-prompt-library/prompts/{brand}/`
- Generated images at: `~/.openclaw/workspace/data/images/{brand}/prompt-library/`
- Learnings at: `~/.openclaw/workspace/data/auto-research/prompt-quality/`

---

## 2. Prompt Architecture

Every prompt follows this 7-part structure:

```
[Subject] + [Setting/Scene] + [Lighting] + [Style] + [Mood] + [Technical] + [Brand Anchor]
```

**Example breakdown:**
```
[A vibrant acai bowl with arranged toppings of granola, banana slices, and coconut flakes]
+ [on a white marble tabletop with morning sunlight streaming through a window]
+ [bright high-key lighting, clean whites, sunrise tones, 5500K]
+ [editorial food photography, magazine quality, sharp focus]
+ [energetic, fresh, optimistic morning ritual feel]
+ [overhead angle, 1:1 aspect ratio, 4K resolution, shallow depth of field]
+ [Wholey Wonder brand — purple #9C27B0 accent napkin, gold #FFD700 spoon, white background]
```

### Lighting Presets

| Preset | Description | Brands |
|--------|-------------|--------|
| **Food Hero** | Soft diffused top light, slight backlight for steam/freshness, warm 4500K | pinxin-vegan, mirra, gaia-eats, gaia-recipes |
| **Clean E-commerce** | Even white studio lighting, no shadows, 5500K daylight | dr-stan, gaia-supplements, gaia-print |
| **Lifestyle Warm** | Golden hour window light, soft shadows, warm 3500K | gaia-eats, wholey-wonder, gaia-recipes |
| **Wellness Calm** | Soft natural light, airy, high-key, cool 5000K | serein, wholey-wonder, rasaya |
| **Dark Moody** | Dramatic side lighting, deep shadows, rich contrast | jade-oracle, gaia-os, iris, gaia-learn |
| **Flat Lay** | Even overhead lighting, minimal shadow, slightly warm 4500K | all brands (product flat lays) |
| **Heritage Warm** | Warm amber light, soft shadows, kitchen hearth, candlelight 3000K | rasaya |
| **Sacred Futurist** | Dramatic rim lighting, volumetric atmosphere, dual light sources | gaia-os, iris |

### Style Presets

| Preset | Description | Brands |
|--------|-------------|--------|
| **Editorial** | Magazine-quality, styled, aspirational | pinxin-vegan, mirra, gaia-eats |
| **UGC/Authentic** | iPhone-quality, natural, unposed, slightly imperfect | pinxin-vegan, wholey-wonder, gaia-recipes |
| **Minimalist** | Clean, lots of white space, product-focused | dr-stan, gaia-supplements, serein |
| **Vibrant** | Saturated colors, energetic, pop | wholey-wonder, gaia-print, pinxin-vegan |
| **Organic** | Natural textures, earth tones, handmade feel | rasaya, gaia-eats, gaia-recipes |
| **Clinical-Warm** | Science-meets-nature, clean but not sterile | dr-stan, gaia-supplements |
| **Heritage** | Traditional, warm, grandmother's kitchen | rasaya |
| **Sacred Futurist** | Transhumanist baroque, hyper-realistic digital couture | gaia-os, iris |

### NanoBanana Formatting Notes

All prompts in this library are formatted for direct use with `nanobanana-gen.sh`. Key conventions:
- **Aspect ratio**: Noted in `[RATIO]` tag — use with `--ratio` flag
- **Style seed**: Prompts marked `[SEED-COMPATIBLE]` work with `--style-seed` for campaign consistency
- **Reference slots**: Prompts marked `[REF: product|style|logo]` benefit from `--ref-image` hybrid approach
- **Size**: Default 2K for social, 4K for hero/e-commerce unless noted

---

## 3. Prompt Packs by Brand

---

### Pack 1: Pinxin Vegan (Vegan Malaysian Food)

> Brand DNA: Bold, clean, health-forward, proudly Malaysian. Primary #1C372A (dark forest green), gold #d0aa7f, background #F2EEE7 (light beige). Warm natural light, high contrast, steam and smoke visible. AVOID: #4CAF50 (too bright/generic), bland clinical aesthetic, Western plating.

**PXV-001 | Nasi Lemak Hero — Overhead** `[RATIO: 1:1] [SEED-COMPATIBLE] [REF: product|style]`
```
Overhead food photography of a complete vegan nasi lemak plate on a dark banana leaf. Fluffy coconut rice in the center, surrounded by crispy tempeh rendang, sambal tumis, roasted peanuts, cucumber slices, and fried mock anchovies. Wisps of steam rising from the rice. Rich warm natural light from the upper left, high contrast, deep shadows revealing texture. Bold Malaysian street food aesthetic, magazine editorial quality. Rustic wooden table surface with subtle dark forest green #1C372A cloth napkin peeking from the edge. Shot with shallow depth of field, f/2.8, the sambal glistening with oil droplets. 4K resolution.
```

**PXV-002 | Nasi Lemak Hero — 45-Degree** `[RATIO: 4:3] [SEED-COMPATIBLE] [REF: product]`
```
45-degree angle food photography of vegan nasi lemak served on a traditional round plate with banana leaf lining. Coconut rice mound center, surrounded by plant-based rendang, bright red sambal, acar pickles, crispy keropok, and fresh ulam herbs. Warm natural window light from camera left casting gentle shadows, steam rising from rice catching the backlight. Malaysian kopitiam-style setting with marble-top table. Vibrant colors, appetizing textures, bold food photography. The green of the herbs echoing Pinxin's brand dark forest green #1C372A. Close enough to see individual rice grains. 4K resolution.
```

**PXV-003 | Nasi Lemak — Close-Up Sambal** `[RATIO: 4:5] [REF: product]`
```
Extreme close-up macro food photography of sambal tumis in a small stone mortar, glossy chili paste glistening with oil, dried chili flakes scattered around, a wooden spoon resting in the sambal. Warm side lighting from the right revealing the bumpy texture and oil sheen. Shallow depth of field, f/1.8, background completely blurred showing only warm bokeh. Rich reds and deep browns, appetizing and bold. Steam gently rising. Malaysian food photography at its finest — this sambal looks like it could set your tongue on fire. 4K resolution.
```

**PXV-004 | Char Kway Teow Hero** `[RATIO: 3:2] [SEED-COMPATIBLE] [REF: product|style]`
```
Dramatic food photography of vegan char kway teow on a round steel plate, flat rice noodles glistening with dark soy sauce, mixed with bean sprouts, chives, sliced plant-based fishcake, tofu puffs, and fresh cockles substitute. Wok hei smoke rising from the dish, backlit to create a halo of steam. Warm overhead lighting, high contrast, the noodles shining with caramelized soy. Dark background, rustic hawker table setting with a pair of wooden chopsticks resting on the plate edge. Bold, unapologetic Malaysian street food energy. 4K resolution.
```

**PXV-005 | Satay Presentation** `[RATIO: 4:3] [SEED-COMPATIBLE]`
```
Food photography of vegan satay skewers arranged on a long wooden board, six golden-brown skewers of grilled plant-based chicken satay with slight char marks. A bowl of thick peanut sauce centered, garnished with sliced shallots and cucumber. Ketupat (compressed rice cubes) arranged beside. Warm golden light from above and left, emulating a night market charcoal grill glow. Smoky atmosphere, appetizing grill marks visible. Rich warm tones — browns, golds, and the dark forest green #1C372A of a pandan leaf garnish. Malaysian night market vibes, editorial quality. 4K resolution.
```

**PXV-006 | Rendang Serving** `[RATIO: 1:1] [REF: product|style]`
```
Top-down food photography of vegan rendang in a traditional brass serving bowl, dark caramelized coconut gravy coating chunks of jackfruit and mushroom, topped with toasted coconut flakes and a kaffir lime leaf. The rendang is rich, dark, and deeply textured. Warm diffused top light with subtle backlight catching the oil sheen. Surrounding the bowl: a bed of white rice on a banana leaf, a small dish of kerisik, and scattered dried chilies. Earth-toned background, warm gold #d0aa7f textile beneath. Hari Raya feast energy — bold, abundant, proudly Malaysian. 4K resolution.
```

**PXV-007 | Mixed Rice Bento** `[RATIO: 1:1] [SEED-COMPATIBLE] [REF: product]`
```
Overhead food photography of a Pinxin Vegan mixed rice bento in a kraft paper takeaway container. White rice base with four colorful sections: golden turmeric tempeh, bright green kangkung belacan, red sambal tofu, and brown braised mushrooms. A wedge of lime and fresh chili on the side. Clean natural daylight from above, slight warm cast, appetizing and fresh. The kraft container sits on a light wooden surface with a Pinxin dark forest green #1C372A branded sticker visible on the container lid beside it. Delivery-ready, real-food aesthetic, not over-styled. 2K resolution.
```

**PXV-008 | Ingredient Flat Lay** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Overhead flat lay photography of fresh vegan ingredients arranged in a grid pattern on a light wooden cutting board. Blocks of firm white tofu, sliced golden tempeh, bundles of kangkung, bright red chilies, fresh turmeric root, lemongrass stalks, shallots, garlic, ginger, pandan leaves, and a coconut half. Even overhead lighting, minimal shadows, clean and organized. Each ingredient separated with intentional negative space. The arrangement forms a pleasing geometric pattern. Colors are vivid and natural — greens, reds, yellows, whites. Pinxin brand dark forest green #1C372A linen cloth visible at the frame edges. 4K resolution.
```

**PXV-009 | Kitchen Prep Action** `[RATIO: 3:2] [REF: style]`
```
Lifestyle food photography of a Malaysian woman's hands chopping fresh vegetables on a wooden cutting board in a warm home kitchen. Mid-action shot — the knife cutting through bright red bell pepper, with scattered herbs, tofu cubes, and a wok visible in the background. Warm natural window light from the left, creating a golden glow on the scene. Slightly shallow depth of field, the background kitchen softly blurred. A Pinxin Vegan apron in brand dark forest green #1C372A visible at the bottom edge of frame. Authentic cooking energy, not posed — real movement, real food prep. 2K resolution.
```

**PXV-010 | Delivery Packaging Unboxing** `[RATIO: 4:5] [SEED-COMPATIBLE]`
```
Overhead lifestyle photography of a Pinxin Vegan delivery package being unboxed on a kitchen counter. Kraft paper bag opened to reveal neatly packed containers of food — a nasi lemak set, side dishes in small containers, condiments in eco-friendly pouches. The person's hands are pulling out a container, creating a moment of anticipation. Clean natural daylight, bright and inviting. Dark forest green #1C372A branded stickers and gold #d0aa7f tape visible on the packaging. The scene feels exciting, like opening a gift of food. Real-life messy kitchen counter with a phone and keys nearby for authenticity. 2K resolution.
```

**PXV-011 | Customer Enjoying Food — Kopitiam** `[RATIO: 4:5] [REF: style]`
```
Lifestyle photography of a young Malaysian woman in her late 20s enjoying Pinxin Vegan nasi lemak at a traditional kopitiam table. She's mid-bite, eyes slightly closed in satisfaction, natural smile. Marble-top table, traditional kopitiam chairs, morning light streaming through the open-air shopfront. Other dishes and a kopi-o ice visible on the table. Warm natural light, slightly overexposed background creating an airy feel. Authentic, candid, not overly posed — like a friend snapped this on their phone but with better composition. Malaysian everyday life, diverse and real. 2K resolution.
```

**PXV-012 | Customer Enjoying Food — Young Professionals** `[RATIO: 1:1]`
```
Lifestyle photography of a diverse group of three young Malaysian professionals sharing Pinxin Vegan food at an office lunch table. Mixed dishes spread across the table — nasi lemak, char kway teow, curry noodles. One person is laughing mid-conversation, another is taking a photo of the food with their phone. Natural office lighting supplemented by window light. Casual, energetic, social lunch scene. Modern co-working space aesthetic. The food is the hero — vibrant and colorful against the neutral office setting. Brand dark forest green #1C372A appears subtly in a notebook and plant on the table. 2K resolution.
```

**PXV-013 | Hari Raya Special — Ketupat & Rendang** `[RATIO: 4:5] [SEED-COMPATIBLE]`
```
Festive food photography of a complete vegan Hari Raya spread on an elegant table. Central focus: a platter of woven ketupat surrounded by vegan rendang, kuah kacang, serunding kelapa, and acar. Gold and green table decorations, traditional Malay textile runner in songket pattern. Warm amber lighting evoking the glow of pelita oil lamps. Rich, abundant, celebratory. Fresh bunga raya (hibiscus) as garnish. The entire scene radiates Malaysian Eid celebration — warmth, family, tradition. Pinxin dark forest green #1C372A accents woven into the table setting naturally. 4K resolution.
```

**PXV-014 | CNY Special — Yee Sang** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Overhead food photography of a vegan yee sang (prosperity toss salad) on a large round red plate. Colorful julienned vegetables arranged in sections — carrot, daikon, cucumber, pomelo, pickled ginger — with crispy crackers and sesame seeds. Multiple pairs of chopsticks from different directions, mid-toss, creating dynamic movement. Red and gold Chinese New Year decorations visible at the frame edges — mandarin oranges, red packets, gold coins. Warm festive lighting, rich saturated reds and golds. Celebratory, abundant, joyful chaos of the toss. 4K resolution.
```

**PXV-015 | Deepavali Special — Banana Leaf Rice** `[RATIO: 3:2]`
```
Food photography of a vegan banana leaf rice spread. A large banana leaf covering the table surface with white rice in the center, surrounded by an array of vegetable curries — dhal, rasam, cabbage poriyal, bitter gourd, fried papadum, lime pickle, and a fresh banana. Rich warm lighting with golden tones evoking oil lamp warmth. Rangoli pattern visible at the corner of the frame in colored rice powder. Vibrant, abundant, celebratory South Indian-Malaysian feast. The green of the banana leaf naturally echoes Pinxin's brand palette. 4K resolution.
```

**PXV-016 | Laksa Hero** `[RATIO: 4:5] [REF: product]`
```
Food photography of a steaming bowl of vegan curry laksa, rich orange coconut curry broth with thick rice vermicelli, tofu puffs, bean sprouts, shredded plant-based chicken, and a halved hard-boiled egg substitute. Fresh laksa leaf (daun kesum) and a red chili float on the surface. The bowl is a traditional blue-and-white ceramic. Dramatic steam rising, backlit by warm natural light creating a misty halo effect. Dark wooden table, a lime wedge and sambal belacan on the side. Rich, spicy, deeply satisfying visual. 4K resolution.
```

**PXV-017 | Mee Goreng Mamak** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Bold food photography of vegan mee goreng mamak on a steel plate, yellow noodles tossed in rich red tomato-chili sauce with cubed tofu, potato chunks, bean sprouts, fried shallots, and a squeeze of lime. A cracked fried egg substitute on top. The noodles glisten with sauce, slightly charred from the wok. Strong overhead light with dramatic shadows. Rustic mamak stall setting — steel plate on a worn Formica table, a glass of teh tarik blurred in the background. Unapologetically hawker-style, bold and appetizing. 4K resolution.
```

**PXV-018 | Kuih Selection Flat Lay** `[RATIO: 1:1]`
```
Overhead flat lay of traditional Malaysian vegan kuih arranged on a round wooden tray lined with banana leaf. An assortment of nine pieces: onde-onde, kuih lapis, kuih talam, seri muka, kuih dadar, tepung pelita, kuih ketayap, kuih bingka, and angku kuih. Each piece colorful and distinct — greens from pandan, purples from butterfly pea flower, whites from coconut, golden browns from palm sugar. Even soft overhead lighting revealing glossy surfaces and textures. Traditional meets modern food photography. Pinxin brand green echoed naturally in the pandan-colored kuih. 4K resolution.
```

**PXV-019 | Behind-the-Scenes Kitchen** `[RATIO: 16:9] [REF: style]`
```
Documentary-style photography of a busy commercial kitchen preparing Pinxin Vegan dishes. Wide shot showing two kitchen staff in dark forest green #1C372A aprons working at steel prep stations — one packing bento boxes, another plating nasi lemak. Steam rising from multiple woks in the background. Industrial kitchen lighting mixed with warm overhead spots. Authentic, energetic, real kitchen chaos. Stacks of kraft containers, order tickets on clips, ingredients in steel containers. The scene tells a story of a real food business — no glamour, just honest hard work and good food. 2K resolution.
```

**PXV-020 | Menu Board / Social Hero** `[RATIO: 9:16]`
```
Instagram Story format vertical image: a stylish menu board photography concept for Pinxin Vegan. Clean kraft paper background with a featured dish — vegan nasi lemak — photographed at 45 degrees in the center. Above the dish, hand-lettered style text space (leave blank for text overlay). Below, small icons of ingredients. The overall aesthetic is warm, bold, and Malaysian. Dark forest green #1C372A and gold #d0aa7f color accents frame the composition. Warm natural light, soft shadow beneath the plate. Designed for Instagram Story with safe zones respected — key content in center 60% of frame. 2K resolution.
```

---

### Pack 2: Wholey Wonder (Acai & Smoothie Bowls)

> Brand DNA: Energetic, optimistic, clean wellness vibes. Primary #9C27B0 (purple), secondary #FFD700 (gold), background #FFFFFF, accent #7B1FA2. Bright morning light, clean whites, high key, sunrise tones.

**WW-001 | Acai Bowl Overhead — Classic** `[RATIO: 1:1] [SEED-COMPATIBLE] [REF: product|style]`
```
Overhead food photography of a vibrant acai bowl on a white marble surface. Deep purple acai base swirled smooth, topped with artistic arrangement of sliced banana, fresh blueberries, strawberry halves, granola clusters, coconut flakes, chia seeds, and a drizzle of honey. The toppings arranged in clean geometric sections radiating from center. Bright morning sunlight from upper right, high-key, clean white shadows, sunrise warmth. The purple acai #9C27B0 is rich and saturated. A gold #FFD700 spoon rests at the bowl edge. Fresh, energetic, optimistic morning ritual energy. 4K resolution.
```

**WW-002 | Smoothie Pour Shot** `[RATIO: 4:5] [SEED-COMPATIBLE] [REF: product]`
```
Dynamic action photography of a thick purple acai smoothie being poured from a blender jug into a clear glass bowl, the liquid mid-pour creating a smooth flowing ribbon. Frozen berries and banana slices visible through the translucent purple mixture. Bright backlight catching the pour, creating a luminous glow through the smoothie. Clean white kitchen counter setting, morning light flooding from a window. Splashes of purple droplets frozen in time. Energetic, fresh, the moment of creation. Wholey Wonder brand purple #9C27B0 in the smoothie itself. White and gold #FFD700 props. 4K resolution.
```

**WW-003 | Bowl Close-Up Texture** `[RATIO: 1:1] [REF: product]`
```
Extreme close-up macro photography of an acai bowl surface, showing the creamy texture of the blended acai base with granola clusters creating crunchy contrast. A drizzle of almond butter creating golden streaks across the purple surface. Individual chia seeds and bee pollen specks visible. Shallow depth of field, f/2.0, the edges falling into soft purple blur. Bright even lighting from above, no harsh shadows. The texture is the star — velvety smooth acai against crunchy, nutty toppings. Rich saturated purple #9C27B0 dominates. Almost abstract food art. 4K resolution.
```

**WW-004 | Ingredient Spread Flat Lay** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Overhead flat lay photography of smoothie bowl ingredients arranged on a white marble surface. Small glass bowls containing: frozen acai pulp (deep purple), sliced bananas, fresh blueberries, strawberries, granola, coconut flakes, chia seeds, honey in a small jar, almond butter, dragon fruit, mango cubes, and spirulina powder. Arranged in a circular pattern with intentional negative space. Bright, even overhead lighting, clean white aesthetic, high-key. Each ingredient vibrant and fresh. A gold #FFD700 measuring spoon and purple #9C27B0 linen napkin as brand color anchors. 4K resolution.
```

**WW-005 | Hand Holding Smoothie Cup** `[RATIO: 4:5] [REF: style]`
```
Lifestyle photography of a female hand holding a clear plastic cup of thick purple smoothie with a paper straw, held up against a bright morning sky with soft clouds. The sunlight backlights the smoothie, creating a glowing purple-pink translucency. Condensation droplets on the cup surface. The hand has natural nails, relaxed grip. Warm morning light, lens flare kissing the top of the cup. Bright, optimistic, the feeling of starting a great day. A Wholey Wonder branded cup sleeve in purple #9C27B0 with gold #FFD700 logo. Instagram-ready, aspirational but real. 2K resolution.
```

**WW-006 | Cafe Setting Lifestyle** `[RATIO: 4:3] [SEED-COMPATIBLE]`
```
Lifestyle photography of a young woman sitting at a bright, modern cafe window seat enjoying a Wholey Wonder acai bowl. She's mid-bite with a spoon, casual smile, wearing a white top. The cafe has white-and-light-wood minimalist interiors, a potted monstera plant nearby, morning light flooding through large windows. The acai bowl is colorful and vibrant on the white table. Her phone and a tote bag on the table beside her. Bright, airy, high-key photography. The scene feels optimistic and energetic — a great morning routine moment. 2K resolution.
```

**WW-007 | Morning Routine with Bowl** `[RATIO: 9:16]`
```
Vertical Instagram Story format lifestyle photography of a bright morning kitchen scene. A smoothie bowl sits on a clean white counter next to an open laptop, a yoga mat rolled up against the wall, and a water bottle. Morning sunlight streaming through the window casts long soft shadows. The bowl is topped with artistic fruit arrangement and granola. The scene tells a story: this person works out, works hard, and eats well. Bright, clean, aspirational morning energy. Purple #9C27B0 yoga mat and gold #FFD700 water bottle as subtle brand color anchors. 2K resolution.
```

**WW-008 | Colorful Ingredient Prep** `[RATIO: 3:2] [REF: style]`
```
Action food photography of hands blending a smoothie bowl — a high-powered blender with frozen acai, banana, and berries mid-blend, the lid off to show the vibrant purple mixture inside. Fresh fruits scattered on the white counter around the blender — whole strawberries, a sliced mango, blueberry container. Bright kitchen lighting, clean whites, energetic motion. A few frozen berry pieces mid-air, just tossed in. The scene is dynamic, fresh, and real. Morning prep energy. White and bright with pops of purple, pink, yellow from the fruits. 2K resolution.
```

**WW-009 | Seasonal Flavor — Dragon Fruit** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Overhead food photography of a vibrant pink dragon fruit smoothie bowl on a white plate. The base is hot pink blended dragon fruit, topped with sliced kiwi creating green circles, black sesame seeds, coconut chips, and edible flowers in purple and white. The pink is electric and eye-catching. Bright, even overhead lighting, high-key, clean shadows. A white ceramic spoon and a small dish of extra dragon fruit cubes beside the bowl. Fresh mint leaves as garnish. The overall palette is pink, green, white — tropical and energetic. Gold #FFD700 accent in a small honeycomb piece. 4K resolution.
```

**WW-010 | Seasonal Flavor — Matcha Green** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Overhead food photography of a matcha green smoothie bowl on a white surface. Vibrant green matcha-banana-spinach base, smooth and creamy, topped with sliced almonds, fresh raspberries for color contrast, granola, and a dusting of matcha powder in a decorative line. The green is vivid and natural, not artificial. Clean bright lighting, soft shadows, the green against white creating a calming but energetic contrast. A bamboo matcha whisk (chasen) placed artfully beside the bowl. Gold #FFD700 spoon resting on the bowl edge. Clean, modern, wellness-forward. 4K resolution.
```

**WW-011 | Smoothie Flight / Variety** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Wide-format food photography of four smoothie bowls arranged in a row on a long white marble counter, each a different color: deep purple acai, hot pink dragon fruit, vibrant green matcha, and golden mango-turmeric. Each bowl has unique toppings arranged artfully. Bright even lighting, high-key, each bowl casting a subtle soft shadow to the right. The color gradient from purple to gold creates a rainbow effect. Small ingredient bowls scattered between them. Clean, magazine editorial quality, the kind of image that makes you want to try all four. 4K resolution.
```

**WW-012 | Takeaway Cup Stack** `[RATIO: 4:5] [REF: product]`
```
Product photography of three Wholey Wonder branded smoothie cups stacked in a triangular arrangement on a clean white surface. Each cup a different color smoothie visible through the clear cup — purple acai, green matcha, pink berry. Branded cup sleeves in purple #9C27B0 with gold #FFD700 Wholey Wonder logo. Paper straws in matching colors. Bright studio lighting, clean product photography, slight shadow beneath for grounding. Fresh fruit scattered around the base — berries, banana slices, kiwi. E-commerce quality, appetizing, brand-forward. 4K resolution.
```

**WW-013 | Active Lifestyle — Post-Workout** `[RATIO: 4:5]`
```
Lifestyle photography of an athletic young Malaysian woman in workout clothes sitting on a gym bench, enjoying a smoothie bowl from a Wholey Wonder branded container. She's sweaty, glowing, post-workout, looking down at the colorful acai bowl with a satisfied expression. Gym setting softly blurred in background — weights, mirrors, bright lighting. The smoothie bowl pops with color against the neutral gym tones. A gym towel and water bottle nearby. Bright, energetic, health-conscious. The message: this is how winners refuel. 2K resolution.
```

**WW-014 | Family Bowl Moment** `[RATIO: 3:2]`
```
Lifestyle photography of a family of three at a bright kitchen island — mother, father, and young child — each with their own colorful smoothie bowl. The child is reaching for a blueberry topping, parents smiling at each other. Bright morning light, white kitchen with natural wood accents. The three bowls are different colors — purple, pink, green. A blender and scattered fruit visible on the counter. Warm, joyful, domestic morning energy. Clean and bright, high-key. The family feels real, diverse Malaysian, not stock-photo perfect. 2K resolution.
```

**WW-015 | Bowl Art — Creative Arrangement** `[RATIO: 1:1]`
```
Overhead food photography of an artistic acai bowl where the toppings are arranged to create a floral pattern — banana slices forming petals, blueberries as the center, coconut flakes as leaves, granola as the stem, with a thin honey drizzle creating golden spiral lines. The deep purple acai base serves as the canvas. Bright, even overhead lighting, the arrangement is precise and intentional like edible art. Clean white marble surface, a few stray berries scattered for casual imperfection. The kind of bowl art that goes viral. 4K resolution.
```

---

### Pack 3: Mirra (Weight Management Meal Subscription)

> Brand DNA: Warm, feminine, clean. Primary blush #F8BECD, dusty rose #EBAABD, crimson accent #AC374B, warm cream #FFF5EE. Clean natural daylight, slightly warm, no heavy shadows. Real food photography — top-view bento box shots, comparison layouts. NOT skincare. Weight management meal subscription — calorie-controlled bento meals delivered to your door.

**MIR-001 | Bento Box Top-Down — Complete** `[RATIO: 1:1] [SEED-COMPATIBLE] [REF: product|style|logo]`
```
Overhead food photography of a MIRRA bento box in a clean white container, five compartments visible: grilled teriyaki tofu as the protein, fluffy brown rice, stir-fried mixed vegetables in vibrant greens and oranges, a small portion of pickled daikon, and a cherry tomato salad. Each compartment neatly separated, colors vivid and fresh. Clean natural daylight from above, slightly warm cast, no heavy shadows — food looks fresh and appetizing. Soft blush pink #F8BECD background surface. A small weight management calorie tracking badge overlay space in the corner. The bento looks nutritionist-designed for weight management, balanced, and genuinely delicious. 4K resolution.
```

**MIR-002 | Bento Hero 45-Degree** `[RATIO: 4:3] [SEED-COMPATIBLE] [REF: product|style]`
```
45-degree angle food photography of a MIRRA bento box on a warm cream #FFF5EE surface, the lid half-open revealing colorful compartments inside — grilled salmon fillet, quinoa, steamed broccoli, roasted sweet potato cubes, and a small salad with sesame dressing. The bento box is white with clean lines. Soft natural window light from the left, gentle shadows, warm and inviting. A pair of wooden chopsticks resting on the lid. A small sprig of microgreens garnishing the top. The scene feels like a sophisticated, healthy lunch — not hospital food, but genuinely appetizing and beautiful. Dusty rose #EBAABD linen napkin beneath. 4K resolution.
```

**MIR-003 | Single Compartment Close-Up — Protein** `[RATIO: 1:1] [REF: product]`
```
Macro close-up food photography of a single bento compartment containing perfectly grilled chicken breast slices with a honey-miso glaze, glistening with sauce, topped with toasted sesame seeds and a thin slice of red chili. The glaze reflects the light, creating an appetizing sheen. Shallow depth of field, f/2.0, the surrounding compartments in soft blur. Clean natural daylight, slightly warm. The texture of the grill marks is visible, the meat looks juicy and tender. Warm cream background tones. This single compartment makes you want the whole bento. 4K resolution.
```

**MIR-004 | Stacked Bento Boxes** `[RATIO: 4:5] [SEED-COMPATIBLE] [REF: product|logo]`
```
Product photography of three MIRRA bento boxes stacked slightly offset, creating a tiered display. Each box is white, lids removed, showing different meal options: top box has a grain bowl with salmon, middle box has a vegetarian Thai curry with rice, bottom box has a Japanese-inspired teriyaki set. The stacking creates visual depth and variety. Clean natural daylight, soft blush pink #F8BECD background. Small MIRRA logo visible on each box. A "Nutritionist Designed" badge could fit in the corner. The overall message: variety, quality, weight management. MIRRA weight management meal subscription — premium calorie-controlled meals that look like restaurant food. 4K resolution.
```

**MIR-005 | Office Lunch Lifestyle** `[RATIO: 4:3] [REF: style]`
```
Lifestyle photography of a professional Malaysian woman at her modern office desk, opening a MIRRA bento box for lunch. She's smiling, mid-unboxing, the colorful bento revealed. Her desk has a laptop, coffee cup, and notebook. Modern office with natural light from floor-to-ceiling windows. The bento's colors pop against the neutral office grays and whites. Colleagues softly blurred in the background. The scene says: this is what smart, busy professionals eat. Not sad desk lunch — a beautiful, balanced meal. Warm natural light, airy and bright. 2K resolution.
```

**MIR-006 | Meal Prep Spread** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Wide overhead food photography of a weekly MIRRA meal prep spread on a warm cream #FFF5EE kitchen counter. Five bento boxes in a row, each with a different daily menu — Monday through Friday visible on small labels. Each box has unique colorful contents: grain bowls, salads, protein sets, curry rice, and a poke-style bowl. Fresh ingredients scattered around: avocados, cherry tomatoes, herbs, bottles of dressing. Clean, organized, the satisfying visual of having your whole week sorted. Bright natural kitchen light, no harsh shadows. Blush pink #F8BECD napkins. 4K resolution.
```

**MIR-007 | Ingredient Quality Close-Up** `[RATIO: 1:1]`
```
Close-up food photography of premium ingredients used in MIRRA bentos, arranged on a clean white cutting board: a perfectly ripe avocado half with visible seed cavity, fresh wild-caught salmon fillet with beautiful orange marbling, a handful of multicolored cherry tomatoes, baby spinach leaves, quinoa grains scattered, and a drizzle of extra virgin olive oil catching the light. Bright, clean lighting, food-magazine quality. Each ingredient looks pristine and premium. The message: MIRRA uses real, high-quality ingredients. No processed junk. Warm cream #FFF5EE surface underneath the cutting board. 4K resolution.
```

**MIR-008 | Delivery Rider with MIRRA Bag** `[RATIO: 4:5]`
```
Lifestyle photography of a delivery rider on a motorcycle stopped at a residential condo entrance, holding a MIRRA branded delivery bag in warm blush pink #F8BECD with crimson #AC374B logo. The bag is insulated and looks premium — not a generic delivery bag. The rider is smiling, wearing a clean uniform. Bright midday light, urban Malaysian setting with tropical greenery visible. A resident is visible at the door, reaching to receive the delivery with an excited expression. The scene communicates: premium meal delivery, right to your door. Warm, friendly, reliable. 2K resolution.
```

**MIR-009 | Before/After — This vs That** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Split comparison food photography in MIRRA's signature "This vs That" weight management layout. LEFT side: a greasy, heavy nasi lemak with oily fried chicken, thick coconut cream, washed-out lighting, slightly unappealing. Text space for "630 kcal" badge. RIGHT side: a MIRRA weight management bento version — same nasi lemak flavors but calorie-controlled and beautiful: grilled chicken, measured coconut rice, fresh sambal, colorful vegetables. Bright, appetizing lighting. Text space for "380 kcal" badge. Same overhead angle on both sides. A clear dividing line between the two halves. Blush pink #F8BECD border framing. The comparison is stark and compelling — weight management doesn't mean giving up flavor. 4K resolution.
```

**MIR-010 | Customer Unboxing — Instagram Moment** `[RATIO: 4:5]`
```
Lifestyle photography from a first-person perspective — looking down at hands opening a MIRRA bento box on a desk. The lid is half-lifted, revealing a beautifully arranged meal inside. A phone is visible to the side, ready to snap a photo. Natural office light, warm tones. The hands have natural nails, holding the lid with anticipation. Stickers and a small "Enjoy your meal" card visible inside the packaging. The moment right before you eat — peak anticipation, the food looks incredible. Warm cream and blush pink MIRRA packaging tones. UGC-feeling but composed. 2K resolution.
```

**MIR-011 | Weekly Menu Carousel Card** `[RATIO: 4:5] [SEED-COMPATIBLE]`
```
Food photography designed for Instagram carousel: a single MIRRA bento photographed overhead on a blush pink #F8BECD background. The bento contains teriyaki glazed salmon, jasmine rice, edamame, pickled carrot, and a micro-salad. Clean, bright natural light, minimal shadows. Space at the top for "TUESDAY" text overlay and space at the bottom for calorie/macro badges. The bento is centered with generous negative space around it. Clean, consistent, designed to be one card in a 5-day carousel series. Each day would have the same layout but different bento contents. 2K resolution.
```

**MIR-012 | Bento Box — Side Profile** `[RATIO: 16:9]`
```
Side-profile product photography of a sealed MIRRA bento box on a clean surface, showing the box's depth, the snap-lock lid, the MIRRA logo sticker on the front. A warm cream #FFF5EE background. The side angle reveals the generous portion size and the premium packaging quality. Soft studio-natural light from the left, gentle shadow to the right for depth. Clean, minimal, e-commerce quality. Next to the box: a pair of bamboo chopsticks in a branded sleeve and a small soy sauce packet. Professional, premium, not cheap takeaway — this is designed meal delivery. 4K resolution.
```

**MIR-013 | Bento + Drink Combo** `[RATIO: 4:5] [REF: product]`
```
Overhead food photography of a MIRRA lunch combo: an open bento box with grilled tofu, brown rice, stir-fried vegetables, and kimchi, paired with a clear glass bottle of infused water with cucumber and mint slices. Both items on a warm cream #FFF5EE surface with a dusty rose #EBAABD coaster under the bottle. Clean natural daylight, bright and fresh. A small MIRRA calorie card sits between the bento and drink showing the combined nutritional info. Lunch perfection — balanced, hydrated, beautiful. Small fresh herb garnish on the bento. 4K resolution.
```

**MIR-014 | Group Order — Meeting Room** `[RATIO: 3:2]`
```
Lifestyle photography of a corporate meeting room with multiple MIRRA bento boxes distributed around the table, each place setting with a bento, chopsticks, and a bottle of water. The meeting is about to start — laptops open, notebooks ready, but the food is the visual focus. Four different bento varieties visible, each colorful and distinct. Natural office light from large windows. The scene says: upgrade your corporate catering from boring sandwiches to MIRRA. Professional, clean, impressive. Blush pink branded napkins at each place setting. 2K resolution.
```

**MIR-015 | Night-In Bento — Cozy Setting** `[RATIO: 1:1]`
```
Lifestyle food photography of a MIRRA bento box opened on a cozy sofa tray table, paired with a glass of sparkling water and a Netflix screen softly glowing in the background. Warm evening lighting — a table lamp casting golden light, candle flickering nearby. The bento contains comfort food: katsu curry with rice and pickles. A soft throw blanket visible, cozy socks at the bottom of frame. The scene says: even your lazy night in can be healthy and delicious. Warm tones, intimate, relaxed. Dusty rose #EBAABD throw pillow visible. 2K resolution.
```

---

### Pack 4: Rasaya (Ayurvedic Wellness Drinks)

> Brand DNA: Heritage-proud, warm, earthy, handcrafted. Primary #FFBF00 (amber/gold), secondary #5C4033 (dark brown), background #FFF8E7 (warm cream), accent #D4A017. Warm amber light, soft shadows, kitchen hearth warmth, candlelight feel. Bahasa Malaysia 60%.

**RAS-001 | Turmeric Latte Pour Shot** `[RATIO: 4:5] [SEED-COMPATIBLE] [REF: product|style]`
```
Beverage photography of golden turmeric latte being poured from a small traditional brass jug into a ceramic cup, the golden liquid creating a smooth arc mid-pour. The latte is rich amber-gold #FFBF00, slightly frothy from the pour. Steam rising from the cup catching the warm backlight. Dark wooden table surface, warm amber lighting from the left evoking a heritage kitchen hearth. A small dish of raw turmeric root and a cinnamon stick beside the cup. The setting feels traditional Malaysian — grandmother's kitchen wisdom meets modern wellness. Warm, earthy, handcrafted energy. 4K resolution.
```

**RAS-002 | Herbal Drink Condensation Detail** `[RATIO: 1:1] [REF: product]`
```
Extreme close-up product photography of a Rasaya glass bottle of herbal drink, condensation droplets covering the surface, the amber-gold liquid visible through the glass. The label shows Rasaya branding in warm brown #5C4033 tones. A single droplet is mid-roll down the bottle surface. Warm amber side lighting creating golden highlights on the condensation. Dark, rich background — almost black with a warm brown gradient. The bottle looks refreshing and premium. A few raw herbs (turmeric, ginger) blurred in the background. The condensation says: this is fresh, cold, ready to drink. Artisan beverage photography. 4K resolution.
```

**RAS-003 | Ingredient Spread — Heritage** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Overhead flat lay photography of Rasaya's key ingredients arranged on a worn wooden chopping board with character. Fresh turmeric roots (bright orange cross-section visible), ginger knobs, whole cinnamon sticks, cardamom pods, black peppercorns, fresh pandan leaves, lemongrass stalks, palm sugar block (gula Melaka), raw honey in a small clay pot, and dried galangal. Arranged organically, not in a grid — flowing and natural like they were just gathered from a garden. Warm amber overhead light, heritage kitchen warmth. The warm cream #FFF8E7 background peeks through gaps. Every ingredient tells a story of traditional Malay herbal wisdom. 4K resolution.
```

**RAS-004 | Wellness Morning Routine** `[RATIO: 4:5] [REF: style]`
```
Lifestyle photography of a Malay woman in her 40s, wearing a simple baju kurung in earth tones, sitting on her veranda in the early morning, holding a warm cup of Rasaya herbal drink. Soft morning mist visible in the background garden. She's looking out peacefully, steam rising from the cup. Warm golden morning light streaming sideways, creating a gentle glow on her face and the cup. A small tray with a Rasaya bottle, a saucer of raw turmeric, and a folded kain batik nearby. The scene breathes tradition, calm, and ancestral wellness. Heritage warm, not clinical, not trendy. 2K resolution.
```

**RAS-005 | Bottle/Sachet Packaging Hero** `[RATIO: 1:1] [SEED-COMPATIBLE] [REF: product|logo]`
```
Product photography of the Rasaya product range arranged on a dark wooden surface: three glass bottles of different herbal drinks (turmeric gold, ginger brown, pandan green) and a row of individual sachets in kraft paper with amber #FFBF00 and brown #5C4033 branding. Raw ingredients scattered naturally around the products — turmeric root, cinnamon sticks, ginger slices. Warm amber lighting from the upper left, rich shadows on the dark wood. A brass tray partially visible underneath. Premium artisan brand aesthetic — handcrafted, heritage, trustworthy. Each bottle catches a warm highlight. 4K resolution.
```

**RAS-006 | Traditional Meets Modern** `[RATIO: 3:2] [SEED-COMPATIBLE]`
```
Split-scene lifestyle photography: left half shows a traditional Malay kitchen scene — clay pot on a wood fire, grandmother's hands grinding herbs with a batu lesung (stone mortar), warm firelight. Right half shows a modern kitchen counter — the same recipe now in a sleek Rasaya glass bottle, with a young professional picking it up on her way out the door, modern bright kitchen. The two halves share the same warm amber #FFBF00 color temperature, connecting old and new. The message: same wisdom, modern convenience. Heritage meets lifestyle. Warm, cinematic, storytelling. 4K resolution.
```

**RAS-007 | Calm Meditation Setting** `[RATIO: 9:16]`
```
Vertical lifestyle photography of a serene morning meditation scene. A woman sits cross-legged on a woven tikar mat on a wooden floor, eyes closed in meditation. In front of her, a low wooden tray holds a steaming cup of Rasaya herbal tea, a small brass oil lamp (pelita), and a fresh turmeric flower. Morning light streams through sheer curtains creating soft, diffused golden glow. The warm amber light #FFBF00 tones pervade the entire scene. Traditional Malay textiles and natural wood elements frame the shot. Deeply calming, heritage-proud, spiritual but not religious. 2K resolution.
```

**RAS-008 | Jamu Preparation — Action** `[RATIO: 4:3]`
```
Documentary-style photography of traditional jamu preparation: hands pressing fresh turmeric through a stone grinder, the bright orange juice flowing into a clay bowl below. Fresh herbs and roots spread across a worn wooden worktable. Action mid-flow, capturing the physical effort and craft of traditional preparation. Warm amber overhead light, rich earth tones throughout. The hands are weathered and experienced — these have made jamu for decades. Background shows shelves of glass jars with dried herbs. Authentic, heritage, the real craft behind Rasaya's products. Not staged — documentary truth. 2K resolution.
```

**RAS-009 | Ginger Drink — Warming** `[RATIO: 4:5] [REF: product]`
```
Beverage photography of a hot ginger drink in a traditional glass cup, the honey-brown liquid clear with shreds of fresh ginger visible at the bottom. Steam rising dramatically, backlit to create a warm halo. A thin slice of lemon floats on the surface. Dark wood table, a small dish of sliced ginger and a palm sugar chunk beside the cup. Warm amber lighting, cozy and intimate, like a rainy evening remedy. The drink glows golden. A hand wrapped around the cup suggests warmth and comfort. This is the drink your grandmother made when you had a cold. 4K resolution.
```

**RAS-010 | Gift Set Presentation** `[RATIO: 1:1]`
```
Product photography of a Rasaya gift set arranged in a handwoven rattan box: three small bottles of herbal drinks nestled in dried pandan leaves, alongside a small brass measuring cup, a wooden honey dipper, and a card with heritage recipe. Warm amber lighting from above, the rattan texture creating interesting shadow patterns. Dark warm background. The gift set looks premium, artisanal, handcrafted — not mass-produced. Kraft paper and natural fiber wrapping. Gold #FFBF00 ribbon accent. The kind of gift that says "I care about your health." 4K resolution.
```

**RAS-011 | Herbal Latte Art** `[RATIO: 1:1]`
```
Overhead photography of a turmeric latte in a wide ceramic cup, a delicate latte art pattern swirled into the golden foam — a simple fern leaf design in the creamy surface. The golden-amber liquid #FFBF00 creates a warm, rich base. A light dusting of cinnamon powder on one side. The cup sits on a dark wooden saucer with a small cinnamon stick resting beside it. Warm top light, the foam catching highlights beautifully. A single raw turmeric root placed artfully next to the saucer. Artisan cafe quality — modern craft meets ancient ingredient. 4K resolution.
```

**RAS-012 | Night-Time Wellness Ritual** `[RATIO: 4:5]`
```
Lifestyle photography of an evening wellness ritual: a cup of warm Rasaya herbal drink on a bedside table next to a book, reading glasses, and a small brass oil lamp casting warm flickering light. The bed is partially visible with natural linen bedding. Warm, intimate candlelight atmosphere — amber and brown tones dominating. The herbal drink steams gently. A sachet of Rasaya blend and a small jar of honey nearby. The scene whispers: wind down, heal, rest. Heritage warmth in a modern bedroom. Deeply calming, nurturing, traditional wellness before sleep. 2K resolution.
```

---

### Pack 5: Dr. Stan (Supplements & Health)

> Brand DNA: Authoritative, clean, science-backed, modern, trustworthy. Primary #1A237E (deep navy), secondary #FFFFFF, background #F5F7FA, accent #00C853 (green). Clean white light with subtle blue tones, sharp product definition, modern studio.

**DST-001 | Supplement Bottle Hero** `[RATIO: 1:1] [SEED-COMPATIBLE] [REF: product|logo]`
```
Professional product photography of a Dr Stan supplement bottle centered on a clean white #F5F7FA surface. The bottle is matte white with navy #1A237E label and green #00C853 accent stripe. Sharp studio lighting from upper left and right creating even illumination with a subtle shadow beneath for grounding. The bottle is slightly angled at 15 degrees to show both front label and side volume. Clean, clinical-but-warm aesthetic — this looks like it belongs in a premium pharmacy, not a bodybuilding shop. Razor-sharp focus, no distractions. Reflection on the glossy surface beneath. 4K resolution.
```

**DST-002 | Capsule Close-Up** `[RATIO: 1:1] [REF: product]`
```
Macro close-up photography of supplement capsules spilling from a Dr Stan bottle — golden-amber transparent capsules with visible oil inside, scattered on a clean white surface. The bottle is blurred in the background, navy #1A237E label barely readable. Clean white studio lighting with subtle blue undertones, sharp focus on the capsules in the foreground. Each capsule catches a tiny highlight, showing quality and transparency. A few capsules are stacked, others scattered naturally. The image communicates: quality ingredients, nothing to hide. Clinical precision meets visual appeal. 4K resolution.
```

**DST-003 | Ingredient Transparency** `[RATIO: 3:2] [SEED-COMPATIBLE]`
```
Split composition product photography: LEFT side shows a Dr Stan supplement bottle with its label clearly visible. RIGHT side shows the raw ingredients that go into it — fresh turmeric roots, fish oil capsules broken open showing golden oil, vitamin C crystals, spirulina powder in a small dish, and collagen powder. A visual line connects the two sides. Clean white studio lighting, no shadows, scientific and transparent. The message: here's what's inside, no mystery. Navy #1A237E and white color scheme with green #00C853 accents on ingredient labels. Modern, trustworthy, evidence-based. 4K resolution.
```

**DST-004 | Doctor/Expert Setting** `[RATIO: 4:3] [REF: style]`
```
Lifestyle photography of a Dr Stan supplement bottle on a modern medical office desk, with a doctor's white coat draped over the chair behind. A stethoscope, medical journal, and laptop visible on the desk. Clean, bright office lighting with subtle blue undertones. The supplement bottle is the focal point, positioned naturally as if the doctor just recommended it. Professional, authoritative, trustworthy setting. Floor-to-ceiling windows with city view softly blurred. The scene says: this is what medical professionals trust. Navy #1A237E tones in the office decor. 2K resolution.
```

**DST-005 | Morning Routine Shelf** `[RATIO: 4:5]`
```
Lifestyle product photography of a modern bathroom shelf/vanity display: a row of Dr Stan supplement bottles alongside a glass of water, a small potted succulent, and a neatly folded hand towel. Morning light streaming from the side, creating clean bright highlights. The shelf is white marble or light wood. The supplement bottles are lined up like a personal wellness routine — multivitamin, omega-3, vitamin D, collagen. Clean, organized, aspirational morning ritual. The scene is minimal and intentional — everything has a purpose. Navy #1A237E bottles against clean white background. 2K resolution.
```

**DST-006 | Athletic Lifestyle** `[RATIO: 4:5] [REF: style]`
```
Lifestyle photography of a fit Malaysian man in his 30s, post-workout, sitting on a gym bench opening a Dr Stan protein supplement shaker. He's in athletic wear, slightly sweaty, looking healthy and energetic. A Dr Stan supplement bottle visible in his open gym bag beside him. Bright gym lighting, clean modern gym environment. His expression is focused and disciplined. The scene connects supplements with an active, evidence-based approach to health — not bodybuilding, but smart wellness. Green #00C853 accent in his workout gear echoing the brand. 2K resolution.
```

**DST-007 | Lab/Science Clean** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Wide-format product photography with a laboratory aesthetic: Dr Stan supplement bottles arranged on a clean white lab bench. Behind them, slightly blurred: laboratory glassware — beakers, test tubes with colored liquids, a microscope. Clean fluorescent-white lighting with cool blue undertones. The composition is symmetrical and precise. Everything is spotlessly clean. Small green #00C853 plant specimen in a petri dish adds a touch of natural origin. The scene communicates: science-backed, rigorously tested, pharmaceutical grade. Navy #1A237E lab notebook visible. 4K resolution.
```

**DST-008 | Product Line Array** `[RATIO: 16:9] [SEED-COMPATIBLE] [REF: product|logo]`
```
Professional product photography of the complete Dr Stan supplement range — eight bottles arranged in a gentle arc on a clean white #F5F7FA surface. Each bottle has a consistent navy #1A237E label with a different colored accent stripe for each variant (green for general, orange for energy, blue for sleep, purple for focus). Clean, even studio lighting, each bottle casting a precise small shadow. The arrangement shows the breadth of the range while maintaining visual consistency. Premium, authoritative, a brand you can build a routine around. 4K resolution.
```

**DST-009 | Supplement + Healthy Breakfast** `[RATIO: 1:1]`
```
Lifestyle flat lay photography of a healthy morning routine from above: a Dr Stan daily multivitamin bottle opened with two capsules beside it, a glass of water, a bowl of overnight oats with berries, a halved avocado, and a small black coffee. Arranged on a clean light gray #F5F7FA surface with a white linen napkin. Bright, clean morning light, no harsh shadows. Everything arranged with intentional minimalism — this person is organized and health-conscious. Navy #1A237E of the supplement bottle provides the color anchor. Smart, simple, daily wellness. 2K resolution.
```

**DST-010 | Infographic-Ready Product** `[RATIO: 4:5]`
```
Clean product photography of a single Dr Stan supplement bottle isolated on pure white background, shot for infographic use. The bottle is perfectly centered, front label clearly readable, cap visible. Even lighting from all sides eliminating shadows completely. Space around the bottle for text overlays — ingredient callouts, benefit arrows, dosage information. The bottle occupies 60% of frame, leaving room for graphic design elements. Navy #1A237E label, white bottle, green #00C853 accent. Clinical precision, designed for marketing team to add overlays. 4K resolution.
```

**DST-011 | Trust Signals — Certifications** `[RATIO: 1:1]`
```
Product photography of a Dr Stan supplement bottle with certification badges and trust symbols arranged around it on a clean white surface: a "GMP Certified" badge, a "Lab Tested" icon, a "No Artificial Additives" seal, and a small certificate of analysis document. Clean studio lighting, the bottle as the hero with the trust signals as supporting elements. The arrangement is clean and organized, not cluttered. Navy #1A237E tones throughout. The overall message: verified, certified, trustworthy. Designed for e-commerce listings or landing pages. 4K resolution.
```

**DST-012 | Family Wellness** `[RATIO: 3:2]`
```
Lifestyle photography of a diverse Malaysian family in a bright modern kitchen — parents and two children at the breakfast table. The father is handing a Dr Stan vitamin to the mother, children eating breakfast. Multiple Dr Stan bottles on the counter — a family range. Bright morning light through large windows, warm but clean. The family looks healthy, happy, energetic. Modern kitchen with navy #1A237E accents in the decor. Not clinical — warm family moment, but the supplements are naturally integrated into their daily routine. Trustworthy, approachable, science-meets-life. 2K resolution.
```

---

### Pack 6: Serein (Wellness & Self-Care)

> Brand DNA: Tranquil, mindful, soft-spoken luxury, nature-inspired serenity. Primary #BCE3C5 (soft sage), secondary #FFE4E1 (misty rose), background #FEFEFA, accent #A8D5BA. Soft diffused light, warm whites, gentle shadows, candlelit ambience.

**SER-001 | Self-Care Ritual Flat Lay** `[RATIO: 1:1] [SEED-COMPATIBLE] [REF: product|style]`
```
Overhead flat lay photography of a complete self-care ritual arrangement on a clean white #FEFEFA surface. A jade gua sha tool, a small bottle of essential oil, dried lavender sprigs, a lit beeswax candle, a folded soft sage #BCE3C5 face towel, a ceramic cup of chamomile tea, a small potted succulent, and a journal with a pen. Arranged with generous negative space, organic flow rather than rigid grid. Soft diffused overhead light, barely-there shadows, airy and gentle. The palette is soft sage greens and misty rose #FFE4E1 pinks against white. Everything whispers calm, ritual, intention. Magazine-quality mindful lifestyle. 4K resolution.
```

**SER-002 | Spa/Bathroom Setting** `[RATIO: 4:5] [REF: style]`
```
Lifestyle photography of a serene bathroom spa corner: a freestanding white bathtub partially visible, a wooden bath tray across it holding a candle, a book, and a small Serein product. Fresh eucalyptus branches hanging from the shower head, their green leaves creating soft sage #BCE3C5 tones against white tile. Soft, diffused natural light from a frosted window, warm whites, no harsh edges. Steam or mist softly visible in the air. White fluffy towels stacked on a wooden stool. The scene is quiet, unhurried, deeply calming — a sanctuary. Misty rose #FFE4E1 bath mat on the floor. 2K resolution.
```

**SER-003 | Morning Routine — Window Light** `[RATIO: 4:5] [SEED-COMPATIBLE]`
```
Lifestyle photography of a woman's hands applying a serum or oil to her face, standing near a bright window with sheer white curtains. Morning golden light creating a soft glow on her skin. Only her lower face, neck, and hands visible — intimate, focused on the ritual not the person. A small Serein product bottle on the windowsill, catching the light. Her nails are natural, skin real with visible texture. The light is ethereal, almost dreamy. Soft sage #BCE3C5 curtain edge visible. The moment is private, peaceful, the first act of self-love each day. 2K resolution.
```

**SER-004 | Evening Routine — Candlelit** `[RATIO: 1:1]`
```
Lifestyle photography of an evening self-care scene on a bedside table: a lit candle casting warm golden light, a small Serein product jar, a sleeping mask in soft sage #BCE3C5, a ceramic cup of herbal tea with steam rising, and a dried flower arrangement. The background is soft and dark — a bedroom in gentle shadow. The candlelight creates intimate, warm pools of light. White linen bedding visible at the bottom of frame. The entire scene is deeply calming — the visual equivalent of a deep exhale. Misty rose #FFE4E1 ceramic saucer under the candle. 2K resolution.
```

**SER-005 | Mindfulness/Meditation** `[RATIO: 9:16]`
```
Vertical lifestyle photography of a woman in comfortable white linen clothing, sitting in a meditation pose on a light wooden floor, hands resting on knees, eyes closed, serene expression. Soft natural light from a large window behind her creating a gentle backlight halo. A Serein candle and a small plant arranged near her on the floor. The room is minimal — white walls, a single piece of art, lots of empty space. Airy, high-key, the light almost overexposed for a dreamy effect. Soft sage #BCE3C5 and whites dominate. Profound stillness captured in a photograph. 2K resolution.
```

**SER-006 | Product Arrangement — Shelf** `[RATIO: 3:2] [SEED-COMPATIBLE] [REF: product|logo]`
```
Product photography of Serein products arranged on a floating white shelf against a clean #FEFEFA wall. Five products in a curated line: a candle in sage green glass, an essential oil roller in misty rose packaging, a face mist spray bottle, a body oil in clear glass with sage #BCE3C5 label, and a small ceramic diffuser. A small potted trailing plant frames one end, a dried lavender bundle the other. Soft, even natural light from the side, gentle shadows beneath each product. The arrangement looks editorial, curated, intentional. Minimal but not cold — warm and inviting. 4K resolution.
```

**SER-007 | Nature Connection** `[RATIO: 4:3]`
```
Lifestyle photography of a woman's hands cupping water from a gentle stream in a forest setting, Serein product visible in a small bag on a mossy rock beside her. Dappled sunlight filtering through forest canopy creating pools of warm light. Fresh green ferns and moss everywhere. The water is crystal clear, catching sparkles of sunlight. The scene connects wellness to nature at its source. Soft focus throughout, dreamy and ethereal. The palette is all natural greens, earth browns, and the soft sage #BCE3C5 of the Serein bag echoing the surrounding moss. 2K resolution.
```

**SER-008 | Calm Environment — Reading Nook** `[RATIO: 4:5]`
```
Lifestyle photography of a serene reading nook: a comfortable armchair by a large window with sheer curtains, a stack of books on the armrest, a warm throw blanket in misty rose #FFE4E1 draped over the chair, a small side table with a Serein candle lit and a cup of tea. Afternoon light streaming through, creating long, soft shadows on the light wood floor. A small potted fern nearby. The chair is empty — inviting you to sit down and disappear into a book. Deeply calming, aspirational quietude. Soft sage #BCE3C5 cushion on the chair. 2K resolution.
```

**SER-009 | Journaling Ritual** `[RATIO: 1:1]`
```
Overhead flat lay of a journaling ritual: an open journal with handwritten gratitude notes visible (slightly blurred for privacy), a pen resting diagonally, a Serein essential oil bottle, a small crystal cluster, dried flowers pressed flat, and a cup of matcha in a ceramic bowl. All arranged on white linen. Soft, even overhead light, no harsh shadows. The handwriting adds a deeply personal, authentic touch. Soft sage #BCE3C5 and misty rose #FFE4E1 accents in the dried flowers and oil bottle label. The scene says: slow down, reflect, care for yourself. 2K resolution.
```

**SER-010 | Bath Ritual Ingredients** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Overhead flat lay photography of bath ritual ingredients arranged on white marble: a glass jar of bath salts in soft sage #BCE3C5 green, dried rose petals in misty pink #FFE4E1, oat milk powder in a small ceramic bowl, a muslin bag, fresh lavender sprigs, sliced citrus rounds, a body brush, and a Serein bath oil bottle. Arranged in an organic, flowing pattern with generous white space. Soft, diffused overhead lighting, almost shadowless. The textures are the stars — crystalline salts, velvety petals, rough brush bristles, smooth glass. A visual invitation to ritualize the everyday. 4K resolution.
```

**SER-011 | Gift Set — Self-Care Box** `[RATIO: 1:1] [REF: product]`
```
Product photography of a Serein self-care gift box, lid removed to reveal contents nestled in shredded kraft paper: a mini candle, a face mist, a sleep mask in sage #BCE3C5 silk, dried lavender sachet, and a small gratitude journal. The box is white with minimal branding in soft gray. A satin ribbon in misty rose #FFE4E1 drapes from the lid. Shot from a 30-degree angle to show both the interior and the elegant exterior. Soft natural light, gentle shadows. Premium, thoughtful, the kind of gift that makes someone feel truly seen. 4K resolution.
```

**SER-012 | Sunrise Yoga** `[RATIO: 16:9]`
```
Wide lifestyle photography of a woman practicing yoga on a wooden deck overlooking a misty morning landscape — green hills, soft clouds, golden sunrise light. She's in warrior pose, silhouetted partially against the sunrise. A small Serein setup nearby: a rolled sage #BCE3C5 mat, a water bottle, a small towel. The morning mist creates layers of atmospheric depth. Warm sunrise light paints everything in soft gold and pink #FFE4E1 tones. The scene is aspirational but attainable — a real moment of morning peace. Wide and cinematic, breathing room in the composition. 2K resolution.
```

---

### Pack 7: Gaia Eats (Food Delivery Marketplace)

> Brand DNA: Warm, natural, appetizing, accessible. Primary #8FBC8F (sage green), secondary #DAA520 (gold), background #FFFDD0 (cream), accent #2E8B57. Warm natural light, soft shadows, golden hour feel.

**GE-001 | Restaurant Variety Spread** `[RATIO: 16:9] [SEED-COMPATIBLE] [REF: style]`
```
Wide overhead food photography of a diverse meal spread from multiple restaurants on a large wooden table: a nasi lemak from one vendor, a grain bowl from another, a burger, a Thai curry, and a poke bowl — five distinct cuisines in five distinct containers. Each dish colorful and appetizing. Warm natural light, golden hour tones, the food glowing with freshness. The table has a warm cream #FFFDD0 cloth. The variety is the hero — something for everyone. Small delivery bags and receipts scattered naturally to show these all arrived together. GAIA Eats sage green #8FBC8F branded elements visible. 4K resolution.
```

**GE-002 | Delivery App Lifestyle** `[RATIO: 4:5]`
```
Lifestyle photography of a young Malaysian woman on a sofa, phone in hand showing a food delivery app interface (blurred/generic), looking excited at the options. A GAIA Eats delivery bag in sage green #8FBC8F on the coffee table beside her, partially unpacked, colorful food containers visible. Warm living room lighting, evening casual setting. Her expression is the key — that excited anticipation of food arriving. A throw blanket, some cushions, a cozy home setting. The scene says: ordering in is the best decision you'll make tonight. Warm, relatable, authentic. 2K resolution.
```

**GE-003 | Family Dinner from Delivery** `[RATIO: 3:2] [SEED-COMPATIBLE]`
```
Lifestyle photography of a Malaysian family gathered around a dining table unpacking a GAIA Eats delivery order. Multiple food containers being opened simultaneously — hands reaching, passing dishes, excited conversation. A variety of foods: Malay, Chinese, Indian cuisines all on one table. Warm overhead pendant lamp lighting mixed with window light. The family is diverse in age — grandparents, parents, kids. The energy is joyful, noisy, alive. This is not fine dining — this is real family dinner made easy. Sage green #8FBC8F delivery bag on the floor nearby. Warm gold #DAA520 tones in the lighting. 2K resolution.
```

**GE-004 | Office Group Order** `[RATIO: 4:3]`
```
Lifestyle photography of a group of young Malaysian professionals in a modern office breakroom, gathered around a table with multiple GAIA Eats delivery containers. Everyone has a different dish — Indian biryani, Japanese bento, Western salad, Chinese claypot rice. They're eating, laughing, sharing. Casual Friday energy — smart casual clothing. Bright office lighting with warm accents. The scene shows the social power of group ordering — everyone gets what they want, and lunch becomes a bonding moment. GAIA Eats branded bags and napkins in sage green #8FBC8F visible. 2K resolution.
```

**GE-005 | Speed/Convenience — Door Delivery** `[RATIO: 4:5]`
```
Lifestyle photography of a GAIA Eats delivery arriving at an apartment door: a delivery rider's hand extending a sage green #8FBC8F branded bag toward the resident who is reaching from inside. The door frame creates a natural framing. The delivery bag looks substantial and well-packed. Warm evening hallway lighting. The resident is in home clothes, genuinely happy to receive the food. Quick, seamless, the best part of the day has arrived. The focus is on the handoff moment — connection between service and satisfaction. Gold #DAA520 in the hall light fixture as a warm accent. 2K resolution.
```

**GE-006 | Late Night Cravings** `[RATIO: 1:1]`
```
Moody lifestyle food photography of a late-night GAIA Eats order on a coffee table: a burger, fries, and a drink in branded packaging, lit by the glow of a TV screen and a small table lamp. Warm, intimate, slightly dark with pools of golden light. A person's feet in socks visible on the sofa in the background. The food is the hero — glistening, indulgent, satisfying. Remote control and phone on the table. This is the 10pm "treat yourself" moment. Sage green #8FBC8F branded container visible. Warm, cozy, no judgment. 2K resolution.
```

**GE-007 | Multi-Cuisine Grid** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Overhead grid food photography showing nine different dishes arranged in a 3x3 grid, each in a delivery container: nasi lemak, ramen, pizza slice, satay, pad thai, burrito, dim sum, fish and chips, and a poke bowl. Each dish photographed from directly above with consistent lighting across all nine squares. The variety is visually striking — a rainbow of cuisines and colors. Thin sage green #8FBC8F lines separating each grid square. Even, bright overhead lighting, clean and appetizing. The message: whatever you're craving, GAIA Eats has it. Designed for social media grid or banner. 4K resolution.
```

**GE-008 | Rainy Day Comfort Order** `[RATIO: 4:5]`
```
Lifestyle photography of a rainy day scene: view through a rain-streaked window showing a cozy interior where a person is unpacking a warm GAIA Eats delivery. Steamy soup, hot rice, and comforting curry visible in the containers. The rain on the window creates a beautiful bokeh texture. Warm interior lighting contrasts with the gray-blue rain outside. A mug of hot tea beside the food. The scene is deeply comforting — you made the right call ordering in. Sage green #8FBC8F delivery bag catching warm interior light. 2K resolution.
```

**GE-009 | Healthy Options Highlight** `[RATIO: 4:5] [SEED-COMPATIBLE]`
```
Food photography of three health-conscious GAIA Eats delivery options arranged on a clean cream #FFFDD0 surface: a grain bowl with salmon and avocado, a fresh Vietnamese rice paper roll set, and a green smoothie bowl. Fresh ingredients visible, bright colors — greens, pinks, oranges. Clean, bright natural light, appetizing and fresh. Each dish in eco-friendly packaging. Small calorie cards visible beside each dish. The message: eating healthy is easy when it comes to your door. Sage green #8FBC8F branded stickers on the containers. 4K resolution.
```

**GE-010 | Vendor Partner Spotlight** `[RATIO: 3:2]`
```
Lifestyle photography of a hawker stall owner packing orders for GAIA Eats delivery — a Chinese Malaysian uncle at his noodle stall, expertly plating char kway teow into GAIA Eats containers with practiced speed. His stall has the authentic wear of decades of cooking — blackened wok, steel counter, hand-written menu board. Warm, slightly smoky atmosphere. He's focused, skilled, proud of his craft. The scene connects the delivery app to real, passionate food artisans. Warm overhead light, rich textures, documentary authenticity. A stack of sage green #8FBC8F GAIA Eats bags ready for riders. 2K resolution.
```

---

### Pack 8: Gaia Recipes (Recipe Content)

> Brand DNA: Warm, instructional, inviting, home-kitchen feel. Primary #E8A87C (warm peach), secondary #D4A574, background #FFF8F0, accent #C85A17. Bright natural kitchen light, clean workspace.

**GR-001 | Step-by-Step — Chopping** `[RATIO: 1:1] [SEED-COMPATIBLE] [REF: style]`
```
Overhead recipe step photography: hands chopping fresh vegetables on a wooden cutting board — a chef's knife mid-cut through bright red bell pepper, with already-chopped onions, garlic, and carrots in neat piles around the board. Small numbered "Step 1" text space in the corner. Bright natural kitchen light from a window, clean and well-lit. The workspace is organized — a small bowl for scraps, the recipe visible on a tablet stand in the background. Warm peach #E8A87C kitchen towel draped at the edge. Instructional, inviting, "you can do this at home" energy. 2K resolution.
```

**GR-002 | Ingredient Flat Lay with Recipe Card** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Overhead flat lay of all ingredients for a recipe (vegan rendang) arranged on a warm #FFF8F0 surface with a printed recipe card in the center. Each ingredient in a small prep bowl or measured on a cutting board: coconut cream, lemongrass, galangal, turmeric, chili paste, onions, garlic, jackfruit chunks. The recipe card has a warm peach #E8A87C header with the recipe title. Each ingredient positioned near its mention in the recipe. Clean, bright overhead lighting, organized and intentional. The visual says: gather these items, follow these steps, magic happens. 4K resolution.
```

**GR-003 | Finished Dish Hero** `[RATIO: 4:3] [SEED-COMPATIBLE] [REF: product]`
```
Hero food photography of the finished recipe — a bowl of vegan rendang served over fluffy white rice on a rustic ceramic plate. Rich, dark, caramelized coconut gravy glistening, topped with toasted coconut and kaffir lime leaves. Warm natural side light from the left, backlight catching the steam rising from the rice. Styled with a linen napkin, fresh herbs, and a wooden spoon. Warm, inviting, the reward for cooking. Shot at 30-degree angle to show both the dish depth and the beautiful plating. Warm peach #E8A87C background tones. This makes you want to cook. 4K resolution.
```

**GR-004 | Kitchen Action — Stirring** `[RATIO: 4:5]`
```
Lifestyle recipe photography of hands stirring a bubbling curry in a cast iron pot on a stovetop, wooden spoon in motion creating a swirl in the rich sauce. Steam and aromatic wisps visible. The pot contents are vibrant — reds, yellows, greens of herbs and spices. Shot from slightly above, looking down into the pot. Other ingredients and dishes visible on the counter around the stove. Warm kitchen lighting, the stove flame providing a subtle warm glow from below. The smell practically comes through the image. Warm, active, the joy of cooking. 2K resolution.
```

**GR-005 | Before/After — Raw to Cooked** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Wide split-image food photography showing the transformation from raw ingredients to finished dish. LEFT: all raw ingredients arranged neatly on a cutting board — fresh vegetables, tofu, herbs, spices, measuring cups. Clean, bright, organized. RIGHT: the same ingredients now transformed into a beautiful finished dish on a styled plate, garnished and steaming. Same warm natural lighting on both sides, same background surface. An arrow or visual flow from left to right. The magic of cooking captured in one image. Warm peach #E8A87C tones throughout. 4K resolution.
```

**GR-006 | Recipe Card Overlay Ready** `[RATIO: 4:5]`
```
Food photography specifically composed for text overlay: a finished dish (tumeric fried rice with crispy tofu) shot from overhead, positioned in the lower-right two-thirds of the frame. The upper-left third is intentionally blank — a warm #FFF8F0 surface with a subtle linen texture, providing clean space for recipe title, cooking time, and serving size text overlays. The food is colorful and appetizing, positioned to be the visual anchor while leaving room for graphic design. Bright, even lighting for legibility. Peach #E8A87C cloth napkin framing the dish. 2K resolution.
```

**GR-007 | Video Thumbnail — Cooking Moment** `[RATIO: 16:9]`
```
Dynamic food photography designed for YouTube/video thumbnail: a dramatic moment of tossing vegetables in a hot wok, ingredients mid-air with flames licking the pan edge. Motion blur on the flying food, sharp focus on the wok and hands. Bright, saturated colors — reds, greens, oranges of stir-fry vegetables against the dark steel of the wok. Warm dramatic lighting from the stove fire and overhead kitchen light. Energy, excitement, skill. Space on the right side for thumbnail text. The kind of image that makes you click "play." 2K resolution.
```

**GR-008 | Serving Moment** `[RATIO: 4:3]`
```
Lifestyle photography of the moment of serving: hands placing a finished plated dish onto a dining table set for two. The dish is beautifully arranged on a warm ceramic plate. The table has simple settings — wooden placemats, cloth napkins in warm peach #E8A87C, simple cutlery, a small vase of fresh herbs as a centerpiece. Warm golden hour window light from the side. The second place setting waits, creating anticipation. The reward of cooking — sharing. Natural, authentic, aspirational home dining. 2K resolution.
```

**GR-009 | Kitchen Pantry Shot** `[RATIO: 4:5]`
```
Lifestyle photography of an organized kitchen pantry shelf showing GAIA Recipes essential ingredients: glass jars of labeled spices, bottles of sauces and oils, dried herbs, grains in clear containers. Everything organized and aesthetically pleasing with handwritten labels. Warm peach #E8A87C and natural wood tones. Soft side lighting from a nearby window. The pantry door is open, revealing the treasure trove of a home cook. A cookbook (GAIA Recipes branded spine visible) on the shelf. The visual of a well-stocked, well-loved kitchen. Inspiring, organized, homey. 2K resolution.
```

**GR-010 | Seasonal Recipe — Festive** `[RATIO: 1:1]`
```
Overhead food photography of a festive recipe spread: a complete holiday meal preparation in progress. Multiple dishes at different stages — one finished and plated, one still in the pot, ingredients being prepped for the third. Festive decorations framing the workspace — gold ribbon, seasonal flowers, traditional textiles. Bright, warm lighting with golden tones. The controlled chaos of holiday cooking — busy but beautiful. Warm peach #E8A87C and gold #D4A574 tones dominating the palette. The recipe cards visible, flour dusted on the surface, the kitchen alive with creation. 4K resolution.
```

---

### Pack 9: Gaia Supplements

> Brand DNA: Clean, clinical-but-warm, trustworthy, premium, science-meets-nature. Primary #3B7A57 (forest green), secondary #8FBC8F, background #F0FFF0, accent #FFD700. Clean studio lighting, white/light backgrounds, product-focused.

**GS-001 | Product Line Hero** `[RATIO: 16:9] [SEED-COMPATIBLE] [REF: product|logo]`
```
Professional product photography of the GAIA Supplements complete range — six bottles of different sizes and formulations arranged in an ascending arc on a clean white #F0FFF0 surface. Each bottle has consistent forest green #3B7A57 labeling with gold #FFD700 accent bands differentiating variants. Clean studio lighting from multiple angles creating even illumination with precise small shadows. The bottles go from smallest (single ingredient) to largest (comprehensive multi). A subtle gradient of green tones unifies the range. Premium, clinical, trustworthy — a product line you can build a regimen from. 4K resolution.
```

**GS-002 | Individual Product Variants** `[RATIO: 1:1] [SEED-COMPATIBLE] [REF: product]`
```
Clean product photography of a single GAIA Supplements bottle centered on a white surface, with a small pile of its raw ingredient beside it — for a turmeric supplement: the bottle next to fresh turmeric roots, cross-sections showing vibrant orange. Clean studio lighting, sharp focus on both product and ingredient. The visual connection between the raw natural source and the final supplement is clear and direct. Forest green #3B7A57 label, gold #FFD700 cap. A single leaf or botanical element adding a touch of nature. Transparent, trustworthy, science-meets-nature. 4K resolution.
```

**GS-003 | Usage/Dosage Lifestyle** `[RATIO: 4:5]`
```
Lifestyle photography of a hand tipping two capsules from a GAIA Supplements bottle into an open palm, a glass of water on the counter beside them. Clean, bright morning kitchen setting with natural light. The action is simple and daily — taking your supplements. The capsules are visible and look premium (clear capsules with visible natural powder inside). The bottle label is readable, forest green #3B7A57 with gold #FFD700 accent. Simple, no-fuss, this is what a healthy daily routine looks like. Clean white countertop, minimal props. 2K resolution.
```

**GS-004 | Sport/Fitness Context** `[RATIO: 4:5] [REF: style]`
```
Lifestyle product photography of GAIA Supplements protein and recovery products positioned on a gym bench: a green protein shaker with the GAIA logo, a supplement bottle of BCAAs, and a small towel. A dumbbell and yoga mat visible in the soft background. Clean gym lighting, bright and energetic. The products are positioned naturally — like someone just put them down between sets. The scene connects supplements to active, intentional fitness. Forest green #3B7A57 in the shaker and bottle labels, gold #FFD700 in the shaker cap. Active wellness, not bodybuilding extreme. 2K resolution.
```

**GS-005 | Nature/Natural Ingredients** `[RATIO: 3:2] [SEED-COMPATIBLE]`
```
Atmospheric photography of GAIA Supplements products arranged outdoors on a mossy forest log — three bottles nestled among ferns, fallen leaves, and morning dew. Natural forest light filtering through the canopy, creating dappled warm-cool lighting. Mist visible in the background. The products look at home in nature — their forest green #3B7A57 labels blending with the natural surroundings while the gold #FFD700 accents catch sunlight. Mushroom and root ingredients scattered naturally nearby. The message: these supplements come from nature and belong to nature. Premium, organic, trustworthy. 4K resolution.
```

**GS-006 | Supplement Stack — Flat Lay** `[RATIO: 1:1]`
```
Overhead flat lay photography of a personalized supplement stack on a clean marble surface: four GAIA Supplements bottles arranged in a square, each opened with their respective capsules arranged in a daily pillbox beside them. A small glass of water, a notepad with a handwritten "Daily Routine" header, and a pen. Clean, bright overhead lighting, organized and intentional. The visual of someone who takes their health seriously and has a system. Forest green #3B7A57 bottles against white marble and gold #FFD700 pillbox. Premium wellness ritual. 4K resolution.
```

**GS-007 | Lab + Nature Duality** `[RATIO: 16:9]`
```
Wide split-composition photography: LEFT half shows a clean laboratory setting with a beaker, petri dish, and microscope on a white surface — scientific precision. RIGHT half shows a lush garden or forest floor with fresh herbs, roots, and plants — natural abundance. In the CENTER, bridging both worlds, a GAIA Supplements bottle sits on the dividing line, belonging to both contexts. Even lighting across both halves but with different temperatures — cool white for lab, warm green for nature. The message: scientifically formulated from nature's best. 4K resolution.
```

**GS-008 | Seasonal Immunity Kit** `[RATIO: 1:1] [REF: product]`
```
Product photography of a GAIA Supplements seasonal immunity bundle: Vitamin C, Zinc, Elderberry, and Echinacea bottles grouped together in a gift box with tissue paper, surrounded by fresh oranges, ginger root, and elderberries. Clean studio lighting with warm accents. The fresh produce adds life and natural credibility to the supplement bottles. Forest green #3B7A57 labels consistent across all four products. Gold #FFD700 "Immunity Bundle" ribbon on the box. The visual says: cold season is coming, be prepared. Premium, thoughtful, science-backed. 4K resolution.
```

**GS-009 | Wellness Morning Ritual** `[RATIO: 4:5]`
```
Lifestyle photography of a morning wellness counter: a GAIA Supplements bottle open, two capsules beside a glass of lemon water, a halved grapefruit, and a small dish of mixed nuts — all on a clean white counter with morning sunlight streaming in from the right. A yoga mat rolled up against the wall visible in the background. Fresh, bright, energetic morning energy. The supplements are part of a holistic morning routine, not the entire routine. Forest green #3B7A57 bottle as the color anchor. Clean, aspirational, attainable. 2K resolution.
```

**GS-010 | Trust & Transparency** `[RATIO: 4:5]`
```
Product photography of a GAIA Supplements bottle with its label partially "peeled back" (creative concept) to reveal the raw ingredients behind it — as if the bottle is transparent showing the actual herbs, vitamins, and minerals inside. Clean white studio background, sharp lighting. The peeled-back label reveals: spirulina powder, turmeric pieces, vitamin crystals, arranged artistically as if they're inside the bottle. A visual metaphor for ingredient transparency. Forest green #3B7A57 label, gold #FFD700 accents. Clean, clever, trustworthy. 4K resolution.
```

---

### Pack 10: Gaia Print & Creative Brands

> Brand DNA: Bold, modern, streetwear-meets-sustainable, trendy. Primary #2E8B57 (green), secondary #556B2F, background #FAFAF5, accent #DAA520 (gold). Lifestyle model shots, flat lay displays.

**GP-001 | Print Product Flat Lay** `[RATIO: 1:1] [SEED-COMPATIBLE] [REF: product]`
```
Overhead flat lay photography of GAIA Print merchandise collection: a folded graphic t-shirt with bold plant-based design, a tote bag with screen-printed illustration, a sticker set arranged in a grid, a pin badge, and a notebook with botanical cover art. All arranged on a clean #FAFAF5 surface with intentional negative space. Props: a small potted cactus, a pencil, dried flowers. Even overhead lighting, clean product photography quality. Green #2E8B57 tones dominate the designs, gold #DAA520 metallic elements in the pin and notebook foil. Streetwear-meets-sustainable aesthetic. 4K resolution.
```

**GP-002 | T-Shirt — Model Worn** `[RATIO: 4:5] [REF: style]`
```
Lifestyle photography of a young Malaysian man wearing a GAIA Print graphic t-shirt — bold botanical illustration in green #2E8B57 on black cotton. He's leaning against a graffiti-covered wall in a Kuala Lumpur urban setting, casual confident pose. The t-shirt design is clearly visible and eye-catching. Natural daylight with urban shadows. He's wearing the shirt with jeans and white sneakers — effortless streetwear. The vibe is young, bold, conscious — wearing your values without being preachy. Shot at 35mm focal length for environmental context. 2K resolution.
```

**GP-003 | Tote Bag — In Use** `[RATIO: 4:5]`
```
Lifestyle photography of a young Malaysian woman carrying a GAIA Print canvas tote bag at a weekend farmers market. The bag has a bold botanical illustration, screen-printed in green #2E8B57 and gold #DAA520 on natural canvas. She's reaching for fresh produce at a stall, the bag hanging from her shoulder with vegetables and a baguette poking out the top. Bright morning outdoor market light, warm and natural. Bustling market blurred in background. The tote looks durable, stylish, and perfectly sized. Sustainable living made fashionable. 2K resolution.
```

**GP-004 | Workspace Creative Setting** `[RATIO: 3:2]`
```
Lifestyle photography of a creative workspace desk featuring GAIA Print products: a botanical notebook open with sketches, a mug with a bold illustrated design, sticker-covered laptop, a framed GAIA Print art print on the wall. Natural daylight from a side window. The desk also has art supplies — markers, pencils, a plant. The workspace feels creative, personal, curated. A "work where you love" energy. Green #2E8B57 tones throughout the designs, warm wood desk, #FAFAF5 walls. Independent creative spirit, not corporate. 2K resolution.
```

**GP-005 | Gift Packaging** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Product photography of a GAIA Print gift set being unwrapped: a kraft paper box with gold #DAA520 foil stamp logo, tissue paper being pulled aside to reveal a folded t-shirt, sticker pack, and enamel pin nestled inside. Dried botanical elements (pressed leaves, dried flowers) scattered as decorative touches. Clean overhead natural light, warm tones. The unboxing experience is the hero — premium, sustainable packaging that feels special. Recycled kraft paper, cotton drawstring pouch inside. Green #2E8B57 in the products, gold in the packaging details. 4K resolution.
```

**GP-006 | Art Print — Gallery Setting** `[RATIO: 4:3]`
```
Lifestyle photography of a GAIA Print art print in a minimalist frame, hung on a clean white gallery wall with a small spotlight illuminating it. The print features a detailed botanical illustration in green #2E8B57 and gold #DAA520 on cream paper. A person standing to the side, slightly blurred, admiring the work. Gallery-style lighting — focused spot with soft ambient fill. The art print looks museum-worthy. A small description card mounted beside the frame. The merging of art and commerce — this print belongs in a gallery and on your wall. 2K resolution.
```

**GP-007 | Sticker Collection** `[RATIO: 1:1]`
```
Overhead flat lay photography of a GAIA Print sticker collection arranged on a light #FAFAF5 surface: 12 individual stickers in various shapes — circular, die-cut botanical shapes, rectangular quote stickers — all in the green #2E8B57 and gold #DAA520 palette. Some stickers partially peeled showing the backing paper. A laptop visible at the edge with a few stickers already applied. Clean, bright overhead lighting. The designs range from detailed botanical illustrations to bold typographic statements about sustainability. Fun, collectible, expressive. 4K resolution.
```

**GP-008 | Seasonal Collection Drop** `[RATIO: 9:16]`
```
Vertical product photography for an Instagram Story announcing a new GAIA Print seasonal collection: three new products arranged vertically against a textured concrete wall — a hoodie hung on a wooden hanger at top, a tote bag hung in the middle, a poster rolled and partially unfurled at the bottom. Dramatic directional lighting from the left creating strong shadows on the concrete. Bold, urban, the vibe of a streetwear drop. Green #2E8B57 and gold #DAA520 in all three designs. Space at top and bottom for text overlays. Hype energy. 2K resolution.
```

**GP-009 | Enamel Pin Close-Up** `[RATIO: 1:1]`
```
Macro close-up photography of a GAIA Print enamel pin on a denim jacket collar — a small botanical design with gold #DAA520 metal outline and green #2E8B57 enamel fill. The pin catches the light, showing its glossy enamel surface and raised metal edges. Shallow depth of field, the denim texture visible but the background softly blurred. The pin is small but detailed and premium-looking. Natural side lighting creating tiny highlights on the metal. A subtle, stylish way to represent your values. 4K resolution.
```

**GP-010 | Pop-Up Market Booth** `[RATIO: 16:9]`
```
Wide lifestyle photography of a GAIA Print pop-up market booth at a weekend bazaar: a wooden table displaying t-shirts stacked and hung, tote bags on hooks, prints in frames, sticker packs in bowls. A green #2E8B57 banner with the GAIA Print logo. Bunting and fairy lights above. A customer is browsing, picking up a t-shirt. Warm outdoor market lighting, festive and energetic. Other market stalls visible in the blurred background. The booth looks curated, professional, but approachable — not corporate, indie market energy. 2K resolution.
```

---

### Pack 11: Jade Oracle (AI Influencer/Character)

> Brand DNA: Korean-inspired modern spirituality. Warm, approachable, editorial. Jade green #00A86B, sage #8FA882, burgundy #722F37, cream #F5F0E8, gold accent #D4AF37. Natural window light, warm candlelight, golden hour. PHOTOREALISTIC. NOT mystical fantasy, NOT celestial/cosmic.

**JO-001 | Character Portrait — Editorial** `[RATIO: 4:5] [SEED-COMPATIBLE] [REF: product|style]`
```
Photorealistic editorial portrait of a young East Asian woman, early 30s, with shoulder-length dark hair with subtle burgundy #722F37 tint, warm brown eyes, natural minimal makeup, wearing a cream #F5F0E8 cashmere sweater. She's looking directly at the camera with a warm, knowing half-smile — wise but approachable, like a friend who gives great advice. Natural window light from the left creating soft directional shadows, warm golden tones. Background is a cozy home studio with bookshelves softly blurred. Korean beauty editorial aesthetic — real skin texture, real lighting. Not airbrushed perfection. Jade green #00A86B small pendant visible at her neckline. 4K resolution.
```

**JO-002 | Reading Scene — Mystical-Modern** `[RATIO: 1:1] [REF: style]`
```
Photorealistic lifestyle photography of the Jade Oracle character seated at a round wooden table, hands resting on a spread of traditional Chinese oracle cards (not tarot). Warm candlelight from three candles in brass holders, golden light illuminating her focused expression. She wears sage #8FA882 linen top. The table has a jade green #00A86B cloth runner. A small jade stone and a cup of tea on the table. Background is warm and dark with bookshelves and a potted plant. The scene feels like a cozy reading session with a wise friend — intimate, warm, not dramatic or spooky. Real, editorial photography quality. 4K resolution.
```

**JO-003 | Lifestyle — Coffee Shop Wisdom** `[RATIO: 4:5]`
```
Photorealistic lifestyle photography of the Jade Oracle character in a modern Korean-style cafe, sitting by a window with a latte, looking at her phone with a thoughtful expression. She's wearing casual-elegant clothing in earth tones with a burgundy #722F37 cardigan. Natural afternoon light through the window, warm and soft. The cafe is minimal — light wood, clean lines, a small vase of dried flowers. She looks like an interesting person you'd want to sit with and have a conversation. Approachable, modern, stylish. Cream #F5F0E8 and jade accents in the scene. 2K resolution.
```

**JO-004 | Product Integration — Holding Brand Product** `[RATIO: 4:5] [REF: product|style]`
```
Photorealistic lifestyle photography of the Jade Oracle character holding a GAIA brand product (supplement bottle or food item) naturally — not posed, as if caught mid-use. She's in a kitchen setting, natural morning light, smiling at someone off-camera while holding the product. The product label is readable but not forced. She's wearing casual home clothes in cream #F5F0E8 and sage tones. The scene feels authentic — like a friend showing you something she genuinely uses. Not an ad, a recommendation. Warm, natural, editorial quality. Jade green #00A86B and gold #D4AF37 accents in jewelry. 2K resolution.
```

**JO-005 | Social Media Ready — Mirror Selfie** `[RATIO: 9:16]`
```
Photorealistic Instagram Story format: the Jade Oracle character taking a mirror selfie in a stylish outfit — burgundy #722F37 silk blouse tucked into black trousers, jade #00A86B pendant, small gold #D4AF37 earrings. She's in a modern apartment with warm lighting and a full-length mirror. The phone is visible in her hands. Her expression is confident, warm, the kind of person you'd follow. Natural, not over-filtered. Real skin, real lighting, natural body proportions. A coat rack and shoes visible in the background for authenticity. Korean fashion editorial meets everyday life. 2K resolution.
```

**JO-006 | Content Creation — Behind the Scenes** `[RATIO: 4:3]`
```
Photorealistic lifestyle photography of the Jade Oracle character at a desk creating content: a laptop open with a writing document, a ring light slightly visible, oracle cards spread for reference, a jade stone paperweight, and a cup of herbal tea. She's typing with a focused, creative expression. Warm desk lamp lighting mixed with natural window light. The scene shows the modern content creator who channels ancient wisdom through digital platforms. Burgundy #722F37 journal and gold #D4AF37 pen beside the laptop. Authentic, relatable, aspirational. 2K resolution.
```

**JO-007 | Nature Walk — Contemplative** `[RATIO: 4:5]`
```
Photorealistic outdoor photography of the Jade Oracle character walking on a forest trail, looking up at the tree canopy with a peaceful expression. She's in casual outdoor wear — cream linen shirt, sage #8FA882 scarf, jeans. Dappled sunlight filtering through leaves, warm golden hour tones. She's mid-stride, hair catching a gentle breeze. The forest is lush and green, with jade green #00A86B ferns and moss. The scene is contemplative, grounded, connected to nature. Not fantasy-forest — a real Malaysian hiking trail with tropical vegetation. 2K resolution.
```

**JO-008 | Live Session — Talking to Camera** `[RATIO: 16:9]`
```
Photorealistic screenshot-style image of the Jade Oracle character in a TikTok/Instagram Live setup: she's talking to camera with animated hand gestures, warm expression, sitting in her cozy home studio. A ring light reflection visible in her eyes. Behind her: styled bookshelves with jade objects, candles, oracle cards, and plants. The framing is typical of a live stream — slightly above center, head and shoulders. Warm lighting, cream #F5F0E8 and sage tones. A small "LIVE" badge space in the corner. She looks engaging, relatable, the kind of creator you'd watch for hours. 2K resolution.
```

---

### Pack 12: Iris (Visual/Art Direction)

> Brand DNA: Tech-minimalism-occult. Primary #6B4EE6 (electric purple), secondary #4A90E2 (blue), accent #B895FF (lavender), background #0A0A1A (deep black), highlight #FFFFFF. Calm, knowing, detached yet benevolent.

**IRS-001 | Behind-the-Scenes Creative** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Cinematic photography of a dark creative studio workspace: multiple monitors displaying different brand visuals and color palettes, all glowing in the darkness. A figure silhouetted against the screens, hands hovering over a graphics tablet. The monitors cast electric purple #6B4EE6 and blue #4A90E2 light across the dark workspace. A single desk lamp provides a warm pool of light on sketches and mood boards pinned to a dark wall. The scene is dramatic, minimal, focused — the all-seeing eye of the creative director at work. Deep shadows, precise lighting. Sacred futurist aesthetic. 4K resolution.
```

**IRS-002 | Art Direction Showcase — Grid** `[RATIO: 1:1]`
```
A 3x3 grid of nine different brand visual specimens on a deep black #0A0A1A background, each square showcasing a different GAIA brand's color palette, typography sample, and hero image thumbnail. Each square glows with its respective brand colors — green for Pinxin, purple for Wholey Wonder, pink for MIRRA, amber for Rasaya, navy for Dr Stan. Thin electric purple #6B4EE6 grid lines separating each square. The overall effect is a masterful art direction overview — the all-seeing vision of brand consistency across the portfolio. Clean, precise, authoritative. 4K resolution.
```

**IRS-003 | Visual Storytelling — Moodboard** `[RATIO: 3:2]`
```
Cinematic photography of a physical mood board pinned to a dark wall in a creative studio. The board contains printed photos, fabric swatches, color chips, torn magazine pages, handwritten notes, and string connecting related elements. The content covers a new campaign — food imagery, lifestyle shots, typography samples, and brand color swatches. A single directional spotlight illuminates the board from upper left, creating dramatic shadows. The surrounding wall is deep black #0A0A1A. Purple #6B4EE6 and blue #4A90E2 accent lighting on the wall edges. The creative process made visible. 4K resolution.
```

**IRS-004 | Color Theory — Palette Study** `[RATIO: 16:9]`
```
Abstract product photography of paint swatches, pantone chips, and colored glass specimens arranged in a precise chromatic gradient on a deep black surface. Starting from electric purple #6B4EE6 on the left, transitioning through blue #4A90E2, teal, sage green, peach, pink, amber, to gold on the right — representing all GAIA brand colors in one spectrum. Dramatic overhead lighting creating precise shadows beneath each swatch. A glass prism in the center refracting a beam of white light into a spectrum. The art of color, deconstructed. Lavender #B895FF ambient glow. Scientific beauty. 4K resolution.
```

**IRS-005 | Typography Specimen** `[RATIO: 4:5]`
```
Dark-mode typography showcase: the word "GAIA" displayed in twelve different typefaces, arranged vertically on a deep black #0A0A1A background. Each version represents a different brand mood — bold sans-serif, elegant serif, playful rounded, clinical modern, heritage script. Each word is rendered in its brand's primary color — green, purple, pink, amber, navy. Subtle electric purple #6B4EE6 guidelines visible showing baseline, x-height, and ascender lines. The typography nerd's dream image — precision, craft, the power of letterforms. Minimal, authoritative, art-director-approved. 4K resolution.
```

**IRS-006 | Eye/Observer Motif** `[RATIO: 1:1]`
```
Abstract digital art in Iris's signature style: a stylized eye formed by concentric circles in electric purple #6B4EE6 and blue #4A90E2, radiating outward on a deep black #0A0A1A background. The pupil contains a miniature view of a creative workspace. The iris (of the eye) is composed of thin geometric lines and data visualization patterns — pie charts, grid overlays, golden ratio spirals. Subtle lavender #B895FF glow emanating from the eye. The all-seeing observer of the creative universe. Tech-minimalism meets occult symbolism. Precise, hypnotic, beautiful. 4K resolution.
```

**IRS-007 | Campaign Review — Screen Display** `[RATIO: 16:9]`
```
Cinematic photography of a large screen in a dark room displaying a campaign visual review — multiple brand images arranged in a grid on the screen, with annotation overlays showing composition lines, color analysis hexcodes, and approval stamps. A hand holding a stylus pointing at one image. The screen glow illuminates the dark room in electric purple #6B4EE6 and blue #4A90E2 tones. The scene feels like a mission control for visual quality — every pixel scrutinized, every brand element verified. Dark, precise, authoritative. 2K resolution.
```

**IRS-008 | Brand DNA Visualization** `[RATIO: 1:1]`
```
Abstract data visualization art: a network graph on deep black #0A0A1A background showing all 14 GAIA brands as nodes, connected by thin luminous lines representing shared visual DNA. Each brand node glows in its primary color — a constellation of brand identity. The connecting lines are electric purple #6B4EE6, pulsing with data. Larger nodes for core F&B brands, smaller for secondary brands. At the center, a larger node labeled "GAIA" connects to all others. The network forms an organic, beautiful pattern — the invisible architecture of a brand ecosystem made visible. 4K resolution.
```

---

### Gaia Learn, Gaia OS (Supplementary)

**GL-001 | Educational Content — Clean Infographic** `[RATIO: 4:5]`
```
Clean educational infographic-style image for GAIA Learn: a step-by-step visual guide to "Building Your First Meal Plan," with three numbered sections, each containing a simple illustrated icon and space for text. Teal #4A90A4 and green #7BC5AE color accents on a clean #F5FAFA background. Modern, authoritative sans-serif typography designated areas. Each section has a small lifestyle photography thumbnail — ingredients, cooking, plated meal. Professional, trustworthy, educational. Clear visual hierarchy. Designed for mobile-first readability. 2K resolution.
```

**GL-002 | Online Course Thumbnail** `[RATIO: 16:9]`
```
Course thumbnail design for GAIA Learn: a split composition with a styled food photography shot on the left (colorful healthy meal) and a clean teal #4A90A4 color block on the right with space for course title text. A small circular portrait space in the lower right for the instructor. The food photography is bright, inviting, and professional. The teal block has subtle geometric pattern texture. The overall design is modern, educational platform quality — Udemy/Skillshare aesthetic but elevated. Green #7BC5AE accent line dividing the two halves. 2K resolution.
```

**GO-001 | Sacred Futurist Portrait** `[RATIO: 4:5]`
```
Hyper-realistic digital portraiture in GAIA OS sacred futurist style: a figure composed of iridescent materials and sacred geometry, face partially visible through translucent crystal-like structures. Deep black #0A0A0F background with gold #DAA520 rim lighting creating dramatic silhouette edges. Cyan #00FFFF accent highlights tracing geometric patterns across the figure's surface. Volumetric atmospheric haze adding depth. The figure is contemplative, transcendent — a digital deity. Hasselblad medium-format quality, cinematic depth of field. Transhumanist baroque aesthetic. 4K resolution.
```

**GO-002 | System Interface Visualization** `[RATIO: 16:9]`
```
Wide cinematic visualization of the GAIA OS interface: a dark #1A1A24 background with floating holographic panels displaying agent status, brand metrics, and data flows. Gold #DAA520 accents on interface elements, cyan #00FFFF data streams connecting panels. A central GAIA logo glowing softly. The panels show: agent roster, active campaigns, brand health scores, content pipeline status. Everything floats in a volumetric space with subtle depth-of-field. Sacred geometry pattern underlying the layout — hexagonal grid barely visible. The living operating system, visualized. 4K resolution.
```

---

## 4. Seasonal/Campaign Prompt Packs

---

### Hari Raya Collection

**HR-001 | Ketupat Hero** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Festive food photography of woven ketupat (rice cakes in palm leaf casings) stacked artfully in a brass tray, surrounded by fresh pandan leaves, a small oil lamp (pelita), and traditional Malay kuih. Rich warm amber lighting evoking the glow of Hari Raya morning. Gold and green color palette — emerald songket textile runner beneath the tray. The woven pattern of the ketupat is crisp and detailed. Steam gently rising. Abundance, tradition, celebration. Applicable to all F&B brands — add brand-specific accent. 4K resolution.
```

**HR-002 | Family Open House Table** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Wide food photography of a complete Hari Raya open house spread on a long dining table: rendang, lemang, ketupat, satay, serunding, kuih selection, dodol, and teh tarik. Gold and green Hari Raya decorations framing the table — fairy lights, pelita lamps, fresh flowers. Warm golden hour lighting streaming through open windows with sheer curtains. The table is abundant to the point of overflow — Malaysian hospitality at its finest. Multiple brass serving ware. Songket runner. Room for brand integration — delivery packaging, product placement, or logo. 4K resolution.
```

**HR-003 | Hari Raya Morning — Wellness** `[RATIO: 4:5]`
```
Lifestyle photography of a serene Hari Raya morning moment: a woman in a beautiful baju kurung in soft sage green, sitting on a veranda, holding a warm cup of herbal drink, looking out at a garden decorated with pelita lamps. Morning golden light, fresh and peaceful — the quiet moment before guests arrive. A small prayer mat rolled up beside her. The scene is calm, spiritual, grateful. Applicable to Serein, Rasaya, or any wellness brand — the drink and prayer mat connect wellness to festive tradition. 2K resolution.
```

**HR-004 | Hari Raya Delivery Special** `[RATIO: 4:5]`
```
Product photography of a Hari Raya special delivery package: a premium gift box with green and gold decorations containing festive food items — rendang, kuih, cookies. The box lid is lifted to reveal the contents nestled in gold tissue paper. A "Selamat Hari Raya" card visible. Green and gold ribbon on the box. Clean studio lighting with warm gold accents. Premium, festive, the perfect Hari Raya gift. Applicable to GAIA Eats, Pinxin, Mirra — add brand-specific packaging. 4K resolution.
```

**HR-005 | Raya Fashion + Food** `[RATIO: 4:5]`
```
Lifestyle photography of a young Malaysian woman in a stunning emerald green baju kurung with gold songket details, seated at a beautifully set Raya table, gracefully serving rendang from a brass dish. Her outfit coordinates with the table setting — greens and golds. Warm golden hour side lighting. She's smiling warmly, the perfect hostess. The food is abundant and beautifully arranged. Traditional elegance meets modern celebration. Applicable to any brand — the scene is a canvas for product integration. 2K resolution.
```

**HR-006 | Hari Raya Kuih Gift Box** `[RATIO: 1:1]`
```
Overhead product photography of an open gift box of Hari Raya kuih arranged in rows: bahulu, tart nenas, kuih bangkit, semperit, almond london, and biskut suji. Each kuih in a small paper cup, the colors ranging from golden brown to pale yellow to pink. The box has green silk lining with gold trim. A small Hari Raya greeting card tucked into the lid. Even overhead lighting, warm cast, the kuih look homemade and fresh. A sprig of jasmine flowers beside the box. Traditional, generous, made with love. 4K resolution.
```

**HR-007 | Pelita Lamp Atmosphere** `[RATIO: 9:16]`
```
Atmospheric vertical photography of a row of lit pelita oil lamps on a veranda railing at dusk, their warm flickering flames creating golden pools of light. The background shows a Malay kampung setting softly blurred — wooden house, garden, evening sky with purple and gold sunset colors. The pelita are in traditional colors — green, yellow, red. The scene is deeply nostalgic, warm, spiritual. A table with Raya food softly blurred in the background. Applicable to any brand for Raya-themed storytelling — add product near the pelita. 2K resolution.
```

**HR-008 | Forgiveness Moment** `[RATIO: 4:3]`
```
Lifestyle photography of a tender Hari Raya salam (forgiveness) moment: an elderly Malay parent holding the hands of an adult child, both in beautiful Raya clothing, soft smiles of love and forgiveness. Other family members visible in the background, a festive living room with Raya decorations. Warm, emotional, the human heart of the celebration. Soft natural light, slightly overexposed for a dreamy warmth. Not staged — genuine, tender, the reason for the celebration. Brand-neutral, usable for any wellness or food brand messaging about family and tradition. 2K resolution.
```

**HR-009 | Hari Raya Meal Prep** `[RATIO: 1:1]`
```
Overhead documentary-style photography of Hari Raya meal preparation: a kitchen counter covered with prep — rendang bubbling in a large pot, ketupat being wrapped, kuih being shaped by multiple hands. Flour, spices, coconut cream, banana leaves everywhere. Multiple generations working together — grandmother's experienced hands alongside younger helpers. Warm, busy, the beautiful chaos of cooking for open house. Natural kitchen lighting, authentic and unposed. This is the real labor of love behind every Raya feast. 2K resolution.
```

**HR-010 | Modern Raya — Young Celebration** `[RATIO: 4:5]`
```
Lifestyle photography of a group of young Malaysian friends at a modern Raya gathering — a rooftop or modern apartment, wearing mix of traditional and modern clothing, sharing food and laughter. A GAIA Eats delivery spread on the table (modern twist — ordered Raya food for convenience). Fairy lights, modern greenery, gold accents. The energy is young, fun, connected — Raya celebrated their way. Evening golden hour light. The food is traditional but the setting is contemporary. Selfies being taken, music implied. Modern Malaysia. 2K resolution.
```

---

### Chinese New Year Collection

**CNY-001 | Yee Sang Toss** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Overhead action food photography of a yee sang prosperity toss in full swing — colorful ingredients mid-air, multiple chopsticks from different directions lifting and tossing the salad. Shredded carrots, radish, pomelo, ginger, crushed peanuts, sesame, crispy crackers flying upward. A beautiful mess of prosperity. Red and gold CNY decorations framing the round serving plate. Warm overhead lighting capturing the action frozen in time. Energetic, joyful, abundant. The essential CNY image. Red, gold, and orange dominate. 4K resolution.
```

**CNY-002 | Reunion Dinner Table** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Wide overhead food photography of a complete Chinese New Year reunion dinner spread on a round table with a lazy Susan: whole steamed fish, braised pork belly (or plant-based version), abalone mushrooms, longevity noodles, fat choy soup, mandarin oranges, CNY cookies, and a hot pot in the center. Red tablecloth with gold runners. Steam rising from multiple dishes. The table is abundant, circular, communal. Warm red-gold lighting. Family hands reaching for dishes visible at the edges. The most important meal of the year. 4K resolution.
```

**CNY-003 | Mandarin Oranges Still Life** `[RATIO: 1:1]`
```
Still life food photography of a pyramid of mandarin oranges on a red lacquer plate, with red packets (ang pao) scattered around, gold coins, and a small branch of plum blossoms in a vase. Classic CNY prosperity symbols. Clean, elegant composition on a dark wooden surface. Warm side lighting from the left, creating golden highlights on the orange skin and shadows on the red packets. Rich, luxurious red and gold palette. The oranges are glossy and perfect, leaves still attached. Traditional, auspicious, beautifully composed. 4K resolution.
```

**CNY-004 | Pineapple Tart Close-Up** `[RATIO: 1:1]`
```
Macro close-up food photography of handmade pineapple tarts on a red CNY plate: the golden pastry perfectly crimped, the dark amber pineapple jam glistening on top, a light dusting of powdered sugar on some. Stacked and arranged in a small pyramid. Shallow depth of field, the front tarts sharp, rear ones softly blurred. Warm golden lighting making the pastry glow. A clove stuck in each tart top. The ultimate CNY cookie — homemade, golden, irresistible. The pastry texture and jam shine are the heroes. 4K resolution.
```

**CNY-005 | Lion Dance + Food** `[RATIO: 4:5]`
```
Lifestyle photography of a Chinese New Year street scene: a lion dance performance in the foreground (blurred/motion), with a row of food stalls in the background. A person in the mid-ground holding a container of CNY food from a vendor, watching the performance. Red and gold everywhere — lanterns, banners, the lion costume. Energetic, festive, loud with color. The food connects the celebration to eating — inseparable in Malaysian CNY. Warm daylight with red-gold cast from decorations. 2K resolution.
```

**CNY-006 | Prosperity Bowl** `[RATIO: 1:1]`
```
Food photography of a "prosperity bowl" — a specially crafted rice bowl with auspicious ingredients: golden fried tofu (gold), red dates (prosperity), black mushrooms (abundance), green vegetables (growth), and a golden egg on top. Served in a red ceramic bowl with gold rim. The arrangement is intentional — each ingredient symbolic. Warm lighting with red-gold tones. A pair of ornate chopsticks beside the bowl. Small CNY decorations (firecrackers, plum blossoms) framing the shot. Meaningful, beautiful, delicious. 4K resolution.
```

**CNY-007 | Red Packet + Sweets Flat Lay** `[RATIO: 1:1]`
```
Overhead flat lay of CNY essentials: multiple red packets (ang pao) in various designs fanned out, a bowl of mandarin oranges, CNY cookies in small dishes (pineapple tarts, love letters, kuih kapit), gold chocolate coins, and a small potted kumquat plant. All on a rich red silk surface. Even overhead lighting with warm gold tones. The arrangement is abundant but organized — the elements of prosperity. Red, gold, and orange color palette exclusively. Festive, generous, auspicious. 4K resolution.
```

**CNY-008 | CNY Gift Hamper** `[RATIO: 4:5] [REF: product]`
```
Product photography of a CNY gift hamper in a red wicker basket with gold ribbon: containing a selection of premium food items — cookies, dried fruits, nuts, tea, and a bottle of premium sauce or honey. A small mandarin orange branch perched on top. The hamper is luxurious, overflowing with quality items. Each product visible and appealing. Clean studio lighting with warm red-gold accents. A red silk cloth drapes from the basket. Applicable to any food brand — replace items with brand products. Premium, generous, the gift that impresses. 4K resolution.
```

**CNY-009 | CNY Morning Tea** `[RATIO: 4:3]`
```
Lifestyle photography of a traditional Chinese tea ceremony on CNY morning: an elderly hand pouring tea from a clay teapot into small porcelain cups, steam rising. The tea table has mandarin oranges, kuih kapit (love letters), and red packets. Warm morning light through a window, casting golden beams across the scene. The teapot and cups are antique, well-used, beautiful. The scene is quiet and reverent — the first ritual of the new year. Warm, heritage, deeply Chinese-Malaysian. 2K resolution.
```

**CNY-010 | Modern CNY Party** `[RATIO: 4:5]`
```
Lifestyle photography of a modern CNY celebration: young Malaysian-Chinese friends at a stylish apartment party, wearing red tops, sharing food and drinks. A table with modern CNY food — fusion dishes, craft cocktails garnished with mandarin peel, contemporary takes on traditional cookies. Red and gold decorations mixed with modern minimalist decor. Evening ambient lighting, fairy lights, warm and festive. Phone screens, laughter, selfies. CNY celebrated the millennial way — traditional heart, modern expression. 2K resolution.
```

---

### Deepavali Collection

**DV-001 | Oil Lamp Row** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Atmospheric photography of a row of traditional Deepavali oil lamps (diyas) lit and glowing on a kolam (rangoli) design made of colored rice powder. The kolam pattern is intricate and symmetrical, in vibrant colors — red, yellow, orange, green. The diyas cast warm flickering golden light in the darkness surrounding them. Flower petals (marigold, jasmine) scattered among the lamps. The scene is deeply spiritual, warm, and festive. Rich warm tones against a dark background. The Festival of Lights at its most beautiful. 4K resolution.
```

**DV-002 | Banana Leaf Feast** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Wide overhead food photography of a full Deepavali banana leaf feast: a large banana leaf covered with a mountain of rice, surrounded by an array of South Indian curries — fish curry, chicken varuval, dhal, rasam, sambar, three types of vegetable curries, papadum, pickles, payasam dessert. Fresh curry leaves and dried chilies as garnish. The colors are vivid — yellows, reds, greens, browns. Warm overhead lighting with golden tones. The feast is abundant, generous, festive. Brass cups of water and fresh banana complete the setting. 4K resolution.
```

**DV-003 | Sweet Making — Murukku** `[RATIO: 4:5]`
```
Action food photography of traditional murukku being made: hands pressing dough through a brass murukku press directly into hot oil, the spiral shape forming in the bubbling golden oil. Fresh murukku cooling on a rack in the background, golden and crispy. The warm light of the kitchen, oil splashing slightly, steam and heat visible. Grandmother's hands, experienced and steady. The craft and tradition of Deepavali preparation. Warm, golden tones — the color of friendship and tradition. Rich documentary-style photography. 2K resolution.
```

**DV-004 | Kolam + Welcome** `[RATIO: 1:1]`
```
Overhead photography of a freshly drawn kolam (rangoli) at a doorstep, vibrant colored rice powder in intricate geometric patterns — red, orange, yellow, green, white. A brass oil lamp burning at the center of the pattern. Fresh marigold flowers placed at the four corners. The kolam extends outward from a tiled doorstep, showing the entrance of a home decorated with mango leaves and banana stems. Morning light illuminating the colors from a low angle. The welcome of Deepavali — beauty, tradition, invitation. 4K resolution.
```

**DV-005 | Deepavali Fashion + Food** `[RATIO: 4:5]`
```
Lifestyle photography of a beautiful Indian-Malaysian woman in a stunning saree (jewel tones — deep purple or emerald) holding a brass tray of Deepavali sweets — laddu, jalebi, barfi, arranged in decorative patterns. She's at her home entrance near a lit kolam, smiling warmly, welcoming guests. Warm golden hour light creating a glow on the silks and brass. Gold jewelry glinting. The scene radiates warmth, hospitality, celebration. Traditional, elegant, joyful. 2K resolution.
```

**DV-006 | Sweets Flat Lay** `[RATIO: 1:1]`
```
Overhead flat lay of Deepavali sweets on a brass thali tray: laddu (golden balls), gulab jamun (dark brown), barfi (silver-topped diamonds), jalebi (orange spirals), mysore pak (golden squares), and murukku (crunchy spirals). Arranged in sections on the round tray with flower petals between. Warm golden overhead lighting, rich saturated colors. The sweets look homemade, fresh, irresistible. A small oil lamp and a few marigold flowers at the frame edges. The colors of Deepavali — gold, orange, red, silver. 4K resolution.
```

**DV-007 | Family Prayer Moment** `[RATIO: 4:3]`
```
Lifestyle photography of a family prayer moment during Deepavali: a family gathered around a home altar lit with oil lamps and decorated with flowers. Incense smoke curling in the air, catching golden light. The family is in festive clothing — silks and gold. Their faces are lit by lamplight, expressions peaceful and reverent. Warm, intimate, deeply spiritual. The background is softly blurred, focusing on the family and the light. This is the heart of Deepavali — gratitude, prayer, togetherness. 2K resolution.
```

**DV-008 | Fireworks + Celebration** `[RATIO: 9:16]`
```
Vertical lifestyle photography of Deepavali evening celebration: sparklers held by multiple hands against a dark night sky, creating golden trails of light. Faces illuminated by sparkler glow, expressions of pure joy. In the lower portion of the frame, a table with sweets and oil lamps visible. The sparklers are the hero — dynamic, festive, the magic of the Festival of Lights. Golden, orange, and white against deep blue-black sky. Energetic, celebratory, the joy of lighting up the darkness. 2K resolution.
```

---

### Merdeka / Malaysia Day Collection

**MY-001 | Malaysian Unity Feast** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Wide overhead food photography of a multi-racial Malaysian feast on a long wooden table: nasi lemak, dim sum, banana leaf rice, roti canai, satay, kuih, teh tarik, and cendol all on the same table. Multiple hands of different skin tones reaching for food. Malaysian flag colors (red, blue, yellow, white) subtly woven into the table setting — napkins, small flags, decorations. Warm golden hour lighting. The message: we are different, we eat together, we are Malaysia. Abundant, diverse, united. The most Malaysian image possible. 4K resolution.
```

**MY-002 | Jalur Gemilang + Local Food** `[RATIO: 4:5]`
```
Patriotic food photography: a small Malaysian flag (Jalur Gemilang) planted in a plate of nasi lemak like a mountaintop flag. The nasi lemak is beautifully plated with all the trimmings. Behind it, a line of other Malaysian dishes fading into soft focus — each representing different Malaysian cultures. Warm natural light, the flag lit with pride. The scene is playful but sincere — food IS our national identity. Red, blue, yellow flag colors against the warm food tones. Simple, iconic, shareable. 2K resolution.
```

**MY-003 | Hawker Stall Row** `[RATIO: 16:9]`
```
Wide atmospheric photography of a Malaysian hawker center at golden hour: a row of stalls with different signage (Chinese, Malay, Indian), each stall lit by warm fluorescent and neon lights. Wok flames visible, steam rising, the organized chaos of Malaysian street food culture. Customers of all races sitting at shared tables. The scene is alive, warm, real. Not tourist-sanitized — authentic Malaysian hawker energy. Golden hour light mixing with artificial stall lights creates a warm, magical atmosphere. The soul of Malaysian food culture. 4K resolution.
```

**MY-004 | Teh Tarik Pull Shot** `[RATIO: 4:5]`
```
Action photography of a teh tarik (pulled tea) being "pulled" — the mamak stall worker stretching a long arc of milky tea between two steel mugs, the liquid forming a smooth golden-brown ribbon mid-air. The skill and theater of the pull is captured. Warm hawker stall lighting, slightly smoky atmosphere. The tea maker's face is focused and practiced. Behind him, the mamak stall setting — steel counter, roti canai griddle. This is uniquely Malaysian — an art form, a tradition, a nightly ritual. Warm amber tones. 4K resolution.
```

**MY-005 | Diversity in Food Sharing** `[RATIO: 4:3]`
```
Lifestyle photography of three Malaysian friends — Malay, Chinese, and Indian — sharing each other's food at a hawker center. One is trying satay from the other's plate, another is passing a bowl of cendol. They're laughing, using hands and chopsticks interchangeably. The table is covered with mixed dishes from all three cultures. Natural evening hawker center lighting, warm and authentic. Not staged — real friendship, real food sharing. This is the Malaysia Boleh spirit. Diverse, warm, united through food. 2K resolution.
```

**MY-006 | Kampung Morning** `[RATIO: 16:9]`
```
Wide atmospheric lifestyle photography of a traditional kampung (village) morning: a wooden Malay house on stilts, the veranda set with a simple breakfast of nasi lemak in banana leaf, hot kopi-o, and kuih. Morning mist in the background, tropical greenery, a rooster on the fence. Warm morning golden light, mist catching the light. The Malaysia that lives in everyone's heart — simple, beautiful, the kampung. This is the soul of the country, the origin of its food traditions. Nostalgic, warm, deeply patriotic. 4K resolution.
```

**MY-007 | Malaysia Boleh Collage** `[RATIO: 1:1]`
```
A bold 2x2 grid collage showing four iconic Malaysian food scenes: TOP-LEFT: roti canai being flipped mid-air. TOP-RIGHT: nasi lemak wrapped in banana leaf on a newspaper. BOTTOM-LEFT: char kway teow flambe in a wok. BOTTOM-RIGHT: cendol being assembled with shaved ice and gula melaka. Each image warm, bold, appetizing. Thin red and blue lines (Jalur Gemilang colors) separating the grid. Together they tell the story of Malaysian food culture — diverse, bold, unforgettable. 4K resolution.
```

**MY-008 | Sunset Silhouette — Merdeka** `[RATIO: 16:9]`
```
Atmospheric silhouette photography of a group of people holding Malaysian flags, silhouetted against a dramatic sunset sky over a Malaysian landscape (twin towers outline or tropical coastline in far background). A hawker cart or food stall silhouette in the foreground. The sky is painted in bold reds, oranges, and golds. The figures are celebrating — arms raised, flags waving. The mood is pride, unity, hope. No faces needed — the silhouette IS Malaysia. Cinematic, emotional, patriotic. 2K resolution.
```

---

### Generic Promotional Pack

**PROMO-001 | Flash Sale Banner** `[RATIO: 16:9] [SEED-COMPATIBLE]`
```
Eye-catching promotional banner design template: a dynamic diagonal split composition with a hero product image area on the left and bold color block on the right for text overlay. Energetic, attention-grabbing design with motion blur streaks suggesting speed/urgency. Bold accent color burst (adapt to brand). Product shadow creates depth. Clean studio lighting on the product. The design screams "limited time" without needing text. Space for price badge, countdown timer, CTA button. Adaptable to any brand by changing the color block. 2K resolution.
```

**PROMO-002 | New Product Launch** `[RATIO: 1:1] [SEED-COMPATIBLE]`
```
Premium product launch photography: a single product emerging from dramatic atmospheric smoke/mist on a dark surface, lit by a focused spotlight from above creating a halo effect. The product is the undeniable hero. Small particle effects (glitter, dust) catching the light around the product. Clean, cinematic, "this is an event" energy. Dark background with brand-color accent lighting from the sides. Space at top for "NEW" or launch text. The reveal moment — theatrical, premium, noteworthy. Adaptable to any brand product. 4K resolution.
```

**PROMO-003 | Bundle Deal** `[RATIO: 1:1]`
```
Product photography of a bundle arrangement: three to five products from the same brand grouped together on a clean surface, with a visual "bundle" element tying them together — a ribbon, a circle graphic space, or a gift box behind them. Each product clearly visible and identifiable. Clean even studio lighting. Space for a "Save X%" or "Bundle & Save" overlay. The arrangement suggests completeness — these items belong together. Brand colors in the props and background accents. Premium, value-forward, designed for conversion. 4K resolution.
```

**PROMO-004 | Limited Edition** `[RATIO: 4:5]`
```
Premium product photography of a limited edition item on a textured surface (marble, velvet, or leather) with a small numbered card beside it showing "Limited Edition No. ___ of 500." The product has special packaging — gold foil, unique colors, premium materials. Dramatic directional lighting from the side creating a sense of luxury and rarity. Dark, moody, premium. A seal or wax stamp visible. The image communicates exclusivity and urgency — this won't last. Adapt to any brand with appropriate product and brand colors. 4K resolution.
```

**PROMO-005 | Customer Review / Social Proof** `[RATIO: 4:5]`
```
Lifestyle photography designed for social proof: a real-looking person (not model-perfect) holding a brand product, looking genuinely delighted. Shot in their real-looking home (slightly messy background adds authenticity). Natural lighting, slightly warm. The person is mid-reaction — eyes wide, smile genuine, like they just tried the product and love it. A phone nearby suggests they're about to post about it. Authentic UGC aesthetic — not polished, not staged, not perfect. Real enthusiasm, real person, real setting. Adaptable to any brand. 2K resolution.
```

**PROMO-006 | Buy One Get One** `[RATIO: 1:1]`
```
Clean promotional product photography: two identical products side by side on a bright surface, one with a bright "FREE" sticker or tag attached. The product on the left is in normal brand packaging, the one on the right has a bold accent ribbon or tag. Between them, a "+" symbol or visual connector. Clean studio lighting, bright and attention-grabbing. The duplicate creates visual impact — double the value. Large space at the top for "BUY 1 GET 1" text overlay. Colors are bright, energetic, promotional. Adapt product and brand colors per brand. 2K resolution.
```

**PROMO-007 | Countdown / Teaser Reveal** `[RATIO: 9:16]`
```
Vertical Story-format teaser image: a product partially revealed behind a frosted glass or paper tear effect, just enough visible to create intrigue but not fully identified. Dramatic backlighting creating a silhouette and glow effect. Brand-color accent lighting around the edges. Space for a countdown timer (3, 2, 1) or "Launching Soon" text in the center. The mood is anticipation, mystery, excitement. Dark background, the partially hidden product glowing with promise. Designed for Instagram Stories with swipe-up area respected. 2K resolution.
```

**PROMO-008 | Seasonal Sale — Flat Lay** `[RATIO: 1:1]`
```
Overhead flat lay promotional photography: multiple products from a brand arranged on a colored surface with seasonal elements — autumn leaves for year-end, flowers for spring, snowflakes for holiday. A large blank circle or badge space in the center for "XX% OFF" text. Shopping bags, gift tags, and ribbon scattered among the products. Bright, festive, shopping energy. The products are the supporting cast, the deal is the hero. Clean overhead lighting. Adapt seasonal elements and brand products per campaign. 4K resolution.
```

**PROMO-009 | Free Shipping Hero** `[RATIO: 16:9]`
```
Conceptual product photography: a product in its delivery packaging appearing to float or fly across the frame, with motion blur suggesting speed. A stylized delivery truck or airplane shape in the background. The packaging has brand-colored tape and stickers. Clean, bright background with dynamic diagonal lines suggesting movement. Space for "FREE SHIPPING" and conditions text. The image communicates: your product, moving fast, at no extra cost. Energetic, modern, conversion-optimized. 2K resolution.
```

**PROMO-010 | Loyalty/VIP** `[RATIO: 4:5]`
```
Premium photography of a VIP/loyalty reward concept: a product on a dark velvet surface with a gold loyalty card, a small "Thank You" card with handwritten feel, and a bonus mini product as a gift. Everything arranged to suggest exclusivity and appreciation. Warm, intimate lighting — a spotlight on the arrangement, dark surroundings. Gold, black, and brand-accent colors only. The image communicates: you're special, you're rewarded, you're valued. Premium, exclusive, intimate. Adapt product and brand colors per brand. 4K resolution.
```

---

## 5. Usage

```bash
# List all prompts for a brand
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh list --brand mirra

# Get prompts for a specific use case
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh get --brand pinxin-vegan --use-case "hero-shot"

# Random prompt for inspiration
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh random --brand mirra

# Generate image using a library prompt (passes to nanobanana-gen.sh)
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh generate --brand mirra --prompt-id "MIR-001"

# Search prompts across all brands by keyword
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh search "turmeric"

# Search within a specific brand
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh search "bento" --brand mirra

# Add a new tested prompt to the library
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh add \
  --brand rasaya \
  --prompt "Fresh halia bara drink in clay cup..." \
  --tags "hero,drink,lifestyle" \
  --score 8

# List top-scoring prompts
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh top --limit 10

# Get all prompts tagged for a specific platform
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh list --tag "instagram-story"

# Export prompts for a campaign brief
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh export --brand pinxin-vegan --format json > campaign-prompts.json
```

---

## 6. Prompt Testing & Scoring

### Quality Scoring System

Each prompt in the library has a quality score based on test generations:

| Score | Rating | Status |
|-------|--------|--------|
| 9-10 | **Hero** | Top performer — use for hero/primary images |
| 7-8 | **Reliable** | Consistent quality — standard production use |
| 5-6 | **Flagged** | Needs revision — occasionally produces good results |
| 1-4 | **Retired** | Removed from active library — archived for reference |

### Scoring Criteria

1. **Subject Accuracy** (0-2): Does the generated image match the described subject?
2. **Brand Alignment** (0-2): Do colors, mood, and style match brand DNA?
3. **Technical Quality** (0-2): Resolution, focus, composition, no artifacts?
4. **Mood/Emotion** (0-2): Does the image evoke the intended feeling?
5. **Usability** (0-2): Can it be used immediately for the intended platform?

### Testing Protocol

```bash
# Test a prompt and score it
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh test \
  --prompt-id "PXV-001" \
  --iterations 3

# The script generates 3 images, displays them, and asks for scores.
# Average score is saved. Prompts scoring <7 are flagged for revision.
```

### A/B Testing

For critical hero images, generate two prompt variants and compare:

```bash
# A/B test two prompt variants
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh ab-test \
  --prompt-a "PXV-001" \
  --prompt-b "PXV-002" \
  --brand pinxin-vegan

# Generates both, presents side-by-side, records winner.
```

### Promotion Rules

- New prompts enter at "Untested" status
- After 3+ test generations with avg score >= 7: promoted to "Reliable"
- After 5+ test generations with avg score >= 9: promoted to "Hero"
- Hero prompts are prioritized in `random` and `top` commands
- Prompts scoring < 5 on 3 consecutive tests: auto-retired

---

## 7. Integration

### Used By
- **`product-studio`** — pulls product photography prompts for e-commerce
- **`creative-studio`** — sources lifestyle and campaign prompts
- **`content-supply-chain`** — automated content generation pipeline
- **`ad-composer`** — ad creative prompts by funnel stage

### Reads From
- **`~/.openclaw/brands/{brand}/DNA.json`** — brand colors, mood, style, photography direction
- **`~/.openclaw/brands/{brand}/campaigns/{campaign}.json`** — campaign-specific overrides
- **NanoBanana SKILL.md** — generation best practices, API parameters, reference image techniques

### Stores Data
- **Prompt definitions**: `~/.openclaw/skills/brand-prompt-library/prompts/{brand}/`
- **Test results**: `~/.openclaw/skills/brand-prompt-library/prompts/{brand}/test-results/`
- **Score index**: `~/.openclaw/skills/brand-prompt-library/prompts/score-index.json`

### NanoBanana Generation Pipeline

When using `generate` command, the library:

1. Loads the prompt by ID from the library
2. Loads brand DNA from `~/.openclaw/brands/{brand}/DNA.json`
3. Injects brand color anchors if not already present
4. Passes to `nanobanana-gen.sh` with appropriate flags:
   - `--ratio` from the prompt's `[RATIO]` tag
   - `--style-seed` if prompt is `[SEED-COMPATIBLE]` and a campaign seed is active
   - `--ref-image` if prompt has `[REF]` tags and reference images are available
   - `--size` defaults to 2K for social, 4K for hero
5. Auto-registers the output in the image seed bank

### Example Integration Flow

```bash
# Creative Director (Dreami) generating a week of Mirra content:

# Monday: hero shot for Instagram feed
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh generate \
  --brand mirra --prompt-id "MIR-001" --ratio 1:1 --size 4K

# Tuesday: lifestyle for Stories
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh generate \
  --brand mirra --prompt-id "MIR-005" --ratio 9:16 --size 2K

# Wednesday: comparison post
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh generate \
  --brand mirra --prompt-id "MIR-009" --ratio 1:1 --size 4K

# All images auto-registered in seed bank with full metadata.
```

---

## 8. Prompt ID Convention

All prompts follow this ID format:

```
{BRAND_CODE}-{NUMBER}
```

| Brand | Code | Range |
|-------|------|-------|
| Pinxin Vegan | PXV | 001-020 |
| Wholey Wonder | WW | 001-015 |
| MIRRA | MIR | 001-015 |
| Rasaya | RAS | 001-012 |
| Dr. Stan | DST | 001-012 |
| Serein | SER | 001-012 |
| GAIA Eats | GE | 001-010 |
| GAIA Recipes | GR | 001-010 |
| GAIA Supplements | GS | 001-010 |
| GAIA Print | GP | 001-010 |
| Jade Oracle | JO | 001-008 |
| Iris | IRS | 001-008 |
| GAIA Learn | GL | 001-002 |
| GAIA OS | GO | 001-002 |
| Hari Raya | HR | 001-010 |
| Chinese New Year | CNY | 001-010 |
| Deepavali | DV | 001-008 |
| Merdeka | MY | 001-008 |
| Promotional | PROMO | 001-010 |

**Total: 200+ production-ready prompts.**

---

## 9. Mood Presets Taxonomy (Migrated from style-control)

Reusable mood presets that translate to specific prompt modifiers. Apply per brand to maintain visual consistency.

| Mood | Description | Use For | Prompt Modifiers |
|------|-------------|---------|-----------------|
| **hero** | Bold, high contrast, aspirational | Hero images, ads | Strong directional lighting, high contrast, dramatic composition, saturated colors |
| **lifestyle** | Natural, warm, relatable | Social media, blog | Golden hour window light, soft shadows, warm 3500K, candid framing |
| **product** | Clean, minimal, focused | Product shots, e-commerce | Even white studio lighting, no shadows, 5500K daylight, tight crop |
| **editorial** | Magazine-style, artistic | Content pieces, features | Dramatic side lighting, styled composition, shallow depth of field |
| **seasonal** | Adapts to current season/holiday | Seasonal campaigns | Season-specific color grading, holiday props, festive lighting |
| **dark** | Moody, dramatic, premium | Evening/luxury content | Low-key lighting, deep shadows, rich contrast, warm amber accents |
| **bright** | Airy, light, optimistic | Morning/wellness content | High-key lighting, overexposed whites, cool 5000K, airy negative space |

Each mood preset encodes: lighting direction, color temperature, background treatment, composition style, and post-processing feel.

## 10. Style Comparison Methodology (Migrated from style-control)

When exploring visual directions for a brand, generate the same concept across different moods to find the best direction:

```bash
# Generate the same subject with different mood treatments
nanobanana-gen.sh generate --brand {brand} --prompt "product hero shot, bright airy lighting" --output hero-bright.png
nanobanana-gen.sh generate --brand {brand} --prompt "product hero shot, moody dramatic lighting" --output hero-dark.png
nanobanana-gen.sh generate --brand {brand} --prompt "product hero shot, lifestyle natural setting" --output hero-lifestyle.png
```

Create a comparison grid for review. This helps:
- Identify which mood best matches the brand DNA
- Reveal unexpected style combinations that work
- Build consensus with stakeholders before committing to a style direction
- Ensure no brand bleed between neighboring brands

### Cross-Brand Consistency Check

When working across multiple brands, verify:
- No brand bleed (jade-oracle mystical elements leaking into gaia-eats)
- Each brand has distinct visual identity
- Shared GAIA elements (if any) are intentional
- NanoBanana `--brand` flag produces correct results per brand

## 11. Style Seed Management (Migrated from style-control)

### Style Seed Storage

```
~/.openclaw/workspace/data/images/{brand}/style-seeds/
```

### Creating a Style Seed

Generate a reference image that captures the brand style:

```bash
nanobanana-gen.sh generate \
  --brand {brand} \
  --prompt "{style reference prompt}" \
  --output ~/.openclaw/workspace/data/images/{brand}/style-seeds/seed-001.png
```

Good style seed prompts should:
- Include brand colors explicitly (HEX values from DNA.json)
- Describe the mood and lighting
- Specify textures and materials
- Reference the visual style (cinematic, flat, editorial, etc.)

### Applying a Style Seed

Use a seed for consistent campaign generation:

```bash
nanobanana-gen.sh generate \
  --brand {brand} \
  --style-seed ~/.openclaw/workspace/data/images/{brand}/style-seeds/seed-001.png \
  --prompt "{content prompt}" \
  --output {output_path}
```

### Brand Style Guide Output

Document finalized styles per brand at: `~/.openclaw/brands/{brand}/style-guide.md`

Include: color palette with usage rules, photography/image style, lighting preferences, composition rules, background preferences, color grading direction, do's and don'ts, active style seeds with descriptions, and mood presets with when-to-use guidance.

### Brand Bleed Prevention

From the 2026-03-12 NanoBanana brand injection bugs:
- `--brand gaia-os` + default use_case renders brand name on products
- gaia-os DNA has "sacred futurism" which causes mystical themes to bleed
- **FIX**: Use `--raw` or `--use-case character` to skip brand enrichment when needed
- Always verify generated images match the intended brand, not a neighboring one
