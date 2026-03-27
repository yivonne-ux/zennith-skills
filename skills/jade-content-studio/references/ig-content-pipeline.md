## 5. IG Content Generation Pipeline

### 5.1 Content Calendar (7 Pillars)

| Day | Pillar | Content Type | Example | Jade Outfit |
|-----|--------|-------------|---------|-------------|
| Mon | Educational | QMDJ explainer carousel | "What is Qi Men Dun Jia?" | Cream silk blouse, glasses |
| Tue | Social Proof | Testimonial + reading result | Client transformation story | Professional: black v-neck |
| Wed | Lifestyle | Behind-the-scenes Jade | Morning ritual, reading setup | Oatmeal cardigan, messy bun |
| Thu | Reading Demo | Mini reading (free value) | "Your Thursday Energy Reading" | Burgundy wrap dress, candles |
| Fri | Emotional/Viral | Relatable spiritual content | "When the universe keeps sending signs..." | Sage tank, casual at home |
| Sat | Community | Quiz, poll, Q&A | "Which element are you?" | Fun: off-shoulder knit |
| Sun | Spiritual | Weekly oracle message | "Your Weekly Guidance from Jade" | Silk cami, sacred space |

### 5.2 End-to-End Workflow SOP

```
INPUT: Content brief (pillar + day) OR ad hook + platform
STEP 1: Load Jade character specs from jade-spec-v2.json
STEP 2: Select face refs (slots 1-5) and body ref (slot 6)
STEP 3: Compose prompt with anchor phrase + scene description
STEP 4: Generate image via NanoBanana (Flash for full-body, Pro for portrait)
STEP 5: Run 6-gate quality check
STEP 6: If PASS → export to canonical path + register in visual-registry
STEP 7: Generate caption using brand voice + fast-iterate scoring
OUTPUT: Production-ready image + caption + metadata for publishing
```

### 5.3 IG Image Generation Rules

- **iPhone selfie quality**, NOT editorial/cinematic
- Western city settings ONLY
- 4:5 ratio for Instagram feed, 9:16 for Stories/Reels
- Warm natural lighting always
- Jade pendant necklace MUST be visible (brand signature)
- One clear activity per image (not multiple)
- Genuine emotions — laughing, soft smile, contemplative. NOT posing for camera
- Body-revealing clothing (V-necks, slip dresses, tanks) — figure is part of the brand

### 5.4 Prompt Formula

Every IG prompt follows this exact structure:
```
Authentic iPhone photo of a Korean woman in her early 30s, [HAIR_DESC], [EXPRESSION].
She has a [BODY_DESC via clothing — describe how fabric interacts with body].
[SETTING_DESC — specific Western city location].
She is [ACTIVITY_DESC — one clear relatable action].
[LIGHTING_DESC — warm natural source].
[PROPS — 1-2 real-world objects].
Jade teardrop pendant necklace visible.
Shot on iPhone 16 Pro, natural depth of field, candid moment, warm tones.
Looks like a real Instagram post from a lifestyle influencer.
No illustration, no cartoon, no CG.
```

### 5.5 Scene Library (20 Proven Scenes)

**Daily Life (Western City):**
1. Farmers market — browsing produce, holding flowers, reusable bag, laughing
2. Coffee shop — reading, latte art, window seat, morning light, contemplative
3. Restaurant dinner — candlelit, wine, intimate, date night energy, chin on hand
4. Morning routine — bed journaling, tea, soft light, tank top, selfie angle
5. Cooking at home — modern kitchen, wine glass, herbs, apron over camisole
6. Rooftop sunset — city skyline, glass of wine, golden hour, wrap dress
7. Bookstore — browsing shelves, stack of books, cozy cardigan (open front)
8. Brunch — outdoor cafe, avocado toast, sunglasses pushed up, linen top
9. Park walk — autumn leaves or spring blooms, casual chic, crossbody bag
10. Yoga/stretching — living room, morning light, activewear, mat

**Spiritual (Subtle, Woven Into Life — NOT explicit):**
11. Crystal grid — living room table, casual outfit, arranging crystals
12. Oracle card pull — kitchen counter, morning coffee, single card, contemplative
13. Meditation corner — modern apartment nook, cushion, candles, peaceful
14. Moon ritual — balcony at night, candles, journal, city lights behind
15. Oracle deck spread — couch, cozy blanket, cards spread, wine nearby

**Going Out:**
16. Art gallery — all black outfit, contemplative, white walls
17. Wine bar — bar stool, low-cut blouse, moody lighting, cocktail
18. Night out — city street, leather jacket over dress, confident walk
19. Weekend market — vintage finds, sunhat, flowy dress, browsing stalls
20. Pilates/gym — leaving studio, smoothie in hand, athleisure, glow

### 5.6 Confirmed IG Images (Reverse-Engineered — These Define the Formula)

| Image | Setting | Outfit | Lighting | Vibe |
|-------|---------|--------|----------|------|
| ig2-market | Western farmers market | White wrap blouse (V-neck), jeans | Sunny golden hour, candid | Laughing, holding flowers |
| ig3-restaurant | Western candlelit restaurant | Black spaghetti strap slip dress (deep V) | Warm candlelight, amber | Chin on hand, wine glass |
| ig4-journaling | Modern Western apartment | Cream tank top (bare shoulders) | Morning window light | Selfie angle, journaling, tea |

**What makes them work:**
1. Western city settings — farmers market, restaurant, apartment
2. iPhone selfie quality — natural, slightly imperfect, candid
3. Body-revealing clothing — V-necks, slip dresses, tank tops
4. One clear activity — shopping flowers, dinner date, journaling
5. Warm natural lighting — golden hour, candlelight, morning sun
6. Genuine emotions — laughing, smiling softly, looking up

