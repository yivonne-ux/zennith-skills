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
