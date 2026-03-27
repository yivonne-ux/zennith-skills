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

