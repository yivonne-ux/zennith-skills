## 18. Appendix: Prompt Templates (Copy-Paste Ready)

### A. IG Lifestyle Post
```
Authentic iPhone photo of a Korean woman in her early 30s, long dark brown hair
with soft curtain bangs, warm brown eyes, calm knowing smile.
She has a petite hourglass figure — [OUTFIT: e.g., deep V-neck silk cami, the thin
fabric draping naturally over her full bust, high-waisted cream linen trousers].
[SETTING: e.g., Modern Western apartment living room, green velvet armchair,
bookshelves, plants, warm morning light through floor-to-ceiling windows].
She is [ACTIVITY: e.g., curled up reading a book, steaming matcha latte on side table].
Jade teardrop pendant necklace visible at her collarbone.
Warm golden natural lighting, shallow depth of field.
Shot on iPhone 16 Pro, candid moment, warm tones, slight imperfect framing.
Looks like a real Instagram post from a lifestyle influencer.
4:5 aspect ratio. No illustration, no cartoon, no CG.
```

### B. Face-Locked Generation (with refs)
```
[PREPEND — ref labeling]
Reference images 1-5 show the CHARACTER'S FACE — keep this EXACT face,
bone structure, eyes, jawline, hair.
Reference image 6 shows BODY TYPE and FASHION STYLE only.
EXACT SAME WOMAN from reference images 1-5 — do NOT generate a different woman.
Her face, bone structure, eyes, nose, jawline, smile, and hair MUST be identical
to references 1-5.

[MAIN PROMPT — scene description]
Korean woman in her early 30s with long dark brown hair with soft curtain bangs,
warm brown eyes, jade pendant necklace, warm golden natural skin tone.
[REST OF SCENE PROMPT]
No illustration, no cartoon, no CG.
```

### C. Ad Creative (TikTok/Reels)
```
iPhone-quality selfie video thumbnail of a Korean woman in her early 30s,
looking directly at camera with knowing smile, slightly raised eyebrow,
dark brown hair with curtain bangs, warm brown eyes, jade pendant visible.
She appears to be about to share a secret.
Text overlay space at top: "[HOOK TEXT]"
Warm natural lighting, modern apartment background blurred.
Shot on iPhone, vertical 9:16, authentic TikTok/Reels style.
No illustration, no cartoon, no CG.
```

### D. Spiritual Scene (Subtle)
```
Authentic iPhone photo of a Korean woman in her early 30s, long dark brown hair
in a low messy bun with loose strands, warm brown eyes, peaceful expression.
She wears an oversized oatmeal cashmere cardigan draped off one shoulder,
thin silk cami underneath, the fabric following her natural curves.
She sits cross-legged on a meditation cushion in a modern apartment nook,
two small candles lit on a low wooden table, oracle cards spread in front of her.
City lights visible through the window behind her.
Jade teardrop pendant necklace visible.
Warm ambient candlelight mixed with blue evening light from window.
Shot on iPhone 16 Pro, candid, intimate moment, warm tones.
4:5 aspect ratio. No illustration, no cartoon, no CG.
```

### E. Character Sheet (Multiple Angles)
```
Four different views of this character: front view, 3/4 left, 3/4 right, profile.
Korean woman in her early 30s, long dark brown hair with soft curtain bangs,
warm brown eyes, jade pendant necklace, fair luminous skin, calm knowing smile.
Same lighting, same outfit [SPECIFY], white/neutral background.
Portrait photography, consistent lighting across all four views.
Real skin with pores, photorealistic.
No illustration, no cartoon, no CG.
```

---

## 19. Cross-Brand Applications

This character pipeline was built for jade-oracle but the face lock protocol, body pairing, and IG generation workflows are reusable for brand mascots across all GAIA brands. The vibe matching system (Section 4), quality gates (Section 6), and prompt templates (Section 18) are brand-agnostic — only the character specs and brand DNA change.

### Adaptation Guide by Brand

| Brand | Character Archetype | Vibe | Notes |
|-------|-------------------|------|-------|
| **mirra** | Weight management meal subscription persona — friendly nutritionist who preps bento-style health food | Warm/Lifestyle | mirra sells bento health meals for weight management; the character should embody clean eating, portion control, and Malaysian home-cooking warmth. mirra content targets busy KL professionals who want healthy food delivered. |
| **pinxin-vegan** | Bold Malaysian vegan food brand ambassador — energetic, proud, unapologetically plant-based | Edgy/Street + Warm | pinxin-vegan is a bold Malaysian vegan brand; the character needs to break stereotypes that vegan food is boring. pinxin-vegan content should feel like a hawker stall rebel — loud flavors, zero apologies. |
| **wholey-wonder** | Energetic fitness persona — active, glowing, always moving | Warm/Lifestyle | wholey-wonder sells wholefood wellness products; the character radiates natural energy. wholey-wonder content pairs well with workout scenes, smoothie prep, and morning routines. |
| **rasaya** | Heritage wellness elder — wise, grounded, keeper of traditional recipes | Spiritual + Warm | rasaya is a heritage Ayurvedic/traditional wellness brand; the character should feel like a wise grandmother who knows every remedy. rasaya content leans into traditional Malaysian and South Asian wellness practices. |
| **dr-stan** | Health expert character — credible, approachable, science-meets-wellness | Editorial/Minimal | dr-stan is a health/wellness authority brand; the character must look trustworthy and knowledgeable. dr-stan content needs clinical credibility balanced with warmth. |
| **gaia-eats** | Delivery cheerful face — friendly, fast, always smiling with food | Warm/Lifestyle | gaia-eats is a food delivery and meal service brand; the character is the face customers see on GrabFood and Shopee listings. gaia-eats content should make you hungry and feel good about ordering. |
| **gaia-recipes** | Home cook character — relatable, messy kitchen, real meals | Warm/Lifestyle | gaia-recipes shares plant-based recipes; the character cooks in a real Malaysian kitchen, not a studio. gaia-recipes content should feel like your friend sharing her Hari Raya or CNY recipes. |
| **gaia-supplements** | Active lifestyle model — fit, natural, outdoors | Warm/Lifestyle | gaia-supplements sells wellness supplements; the character embodies the active life the products enable. |
| **gaia-print** | Creative artist — expressive, colorful, maker energy | Boho/Oracle | gaia-print handles print and packaging design; the character is an artistic creator. |
| **gaia-learn** | Educator — patient, clear, inspiring | Warm/Lifestyle | gaia-learn is the educational content arm; the character teaches and guides. |
| **gaia-os** | Tech guide — sharp, efficient, system-builder | Editorial/Minimal | gaia-os is the AI operating system itself; the character represents the platform. |
| **iris** | Art director — visually precise, aesthetic-obsessed, quality guardian | Editorial/Minimal | iris handles visual QA and brand consistency across all brands. |
| **serein** | Calm wellness guide — serene, mindful, centered | Spiritual + Warm | serein is a calm wellness and mindfulness brand; the character radiates tranquility. serein content should feel like a deep breath — calming, grounding, with soft natural tones. |

### How to Adapt the Pipeline

1. **Create character spec** — Follow the Jade character bible format (Section 2) but swap ethnicity, personality, wardrobe, and brand colors to match the target brand DNA.
2. **Lock the face** — Use the same face lock protocol (Section 3): 60% rule, anchor phrase, ref labeling. The protocol is brand-agnostic.
3. **Match vibes** — Use the vibe classification system (Section 4.1) to pair the new character's face with appropriate body/fashion refs.
4. **Generate content** — Use the same NanoBanana pipeline and prompt formula, substituting the brand-specific prompt elements.
5. **Quality gate** — Run the same 6-gate check (Section 6), replacing Jade-specific checks with the new brand's visual rules.

### F&B Brand Content Focus

For core F&B brands (pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein), the character pipeline is especially valuable because food brands thrive on personality-driven content. A recognizable brand face builds trust for meal subscriptions (mirra bento meals), restaurant visits (pinxin-vegan), supplement purchases (dr-stan health authority), food delivery orders (gaia-eats on GrabFood), recipe sharing (gaia-recipes home cook), traditional wellness products (rasaya heritage remedies), and mindful eating content (serein calm wellness). Each F&B brand character should be photographed with the brand's signature dishes or products — pinxin-vegan with bold plant-based Malaysian dishes, mirra with portion-controlled bento boxes, wholey-wonder with wholefood smoothie bowls, gaia-eats with delivery packaging, rasaya with traditional herbal preparations, dr-stan with health supplements and clinical settings, and serein with calming herbal teas and mindful meals.

---

## 20. Malaysian Market Context

While Jade Oracle targets a global English-speaking audience, the Malaysian market (where GAIA OS is based) provides a unique cross-cultural advantage — Malaysian Chinese diaspora are naturally drawn to QMDJ (Qi Men Dun Jia), making Malaysia a strong seed market for Jade Oracle before expanding to US/EU. Shopee Malaysia and Lazada are secondary sales channels for physical oracle products.

### Why Malaysia Matters for Jade Oracle

1. **Cultural resonance:** Malaysia has a large Chinese diaspora community deeply familiar with Chinese metaphysics, feng shui, and QMDJ. This audience requires zero education on the concept — they already believe. Malaysian Chinese consumers are early adopters for QMDJ-based products.
2. **Seed market strategy:** Test pricing, messaging, and funnel conversion in Malaysia first (lower ad costs on Meta/TikTok MY), then scale winning creatives to US/EU/AU markets.
3. **Cross-platform commerce:** Beyond Shopify, physical oracle products (card decks, journals, jade pendants) can be listed on Shopee Malaysia and Lazada for local fulfillment. Malaysian e-commerce shoppers expect free shipping and COD options — factor this into pricing.
4. **Local calendar hooks:** Content tied to Hari Raya, Chinese New Year (CNY), Deepavali, and other Malaysian festivals drives seasonal engagement spikes. For example, "Your CNY 2027 QMDJ forecast" or "Hari Raya energy reading for your family" are high-engagement hooks for the Malaysian audience.
5. **F&B cross-promotion:** GAIA's F&B brands (pinxin-vegan, mirra, gaia-eats) operate in the Malaysian hawker and food delivery ecosystem. Jade Oracle can cross-promote with these brands — e.g., "Your QMDJ element is Wood — here's your ideal meal from Pinxin Vegan" — creating a wellness-meets-food flywheel unique to the Malaysian market.

### Malaysian Content Adaptations

- **Language:** Primary content in English (global reach), but Malaysian market content can include Manglish phrases and bilingual captions (EN/ZH) for relatability.
- **Timing:** Malaysian audience is active 8-11pm MYT. Schedule Malaysia-targeted posts separately from the US-optimized 7-9am MYT window.
- **Platforms:** TikTok MY, Instagram, and Xiaohongshu (for Chinese-literate Malaysian audience). Shopee and GrabFood integration for cross-brand promotions.
- **Partnerships:** Malaysian metaphysics influencers, feng shui masters, and wellness hawker stall owners are potential collaboration partners.

---

*Consolidated: 2026-03-23 from 5 months of production experience across 5 skills.*
*Character locked: 2026-03-13. Brand face: Jade (Korean, early 30s, jade pendant).*
*Secondary character: Luna Solaris v3 (platinum blonde, ice eyes, edgy-chic).*
*Source skills: character-design, character-lock, character-body-pairing, ig-character-gen, ai-influencer.*
