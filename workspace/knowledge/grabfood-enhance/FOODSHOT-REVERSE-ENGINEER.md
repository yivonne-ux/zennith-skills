# FoodShot.ai: Deep Forensic Reverse Engineering

## Date: 2026-03-23
## Status: Technical Pipeline Reconstruction from Observable Behavior

---

## THE CORE PUZZLE

**Before**: Hawker wonton mee on red plastic oval plate, blue-grey kopitiam table, flat top-down angle, fluorescent lighting.
**After**: Same PIXEL-IDENTICAL food arrangement on grey speckled ceramic shallow wide bowl, walnut wood table with wooden serving board, 45-degree angle, warm directional side light, background props (water glass, cutting board), depth of field.

The food arrangement is identical between before and after -- every wonton, every char siu slice, every spring onion in the exact same position. This constrains the technical solution space dramatically.

---

## VERDICT: IT IS NOT ONE OPERATION -- IT IS A MULTI-STAGE PIPELINE

FoodShot.ai almost certainly runs a **5-7 stage sequential pipeline**, not a single model call. Each stage handles one transformation. The "magic" is orchestration, not any single model.

---

## RECONSTRUCTED PIPELINE (HIGH CONFIDENCE)

### STAGE 1: SEGMENTATION -- Separate Food from Everything Else

**What happens**: The input image is decomposed into semantic layers:
- Layer A: Food items (wontons, char siu, noodles, spring onions)
- Layer B: Plate/vessel
- Layer C: Table/background
- Layer D: (Optional) Utensils, garnishes, sauces

**How it works**:
- **SAM 2 (Segment Anything Model 2)** or **BiRefNet** generates pixel-precise masks
- SAM 2 uses point/box prompts or automatic mode to identify food vs plate vs background
- BiRefNet (Bilateral Reference Network) is preferred for edge accuracy -- it processes through parallel pathways (global context + local detail) and achieves IoU 0.87 / Dice 0.92, critical for the food-plate boundary where food sits IN the plate
- The food-plate boundary is the hardest part -- noodles drape over edges, sauce pools touch plate walls. This requires **matting** (alpha channel with partial transparency at edges), not just binary masks

**Key insight**: The food mask INCLUDES partial plate pixels at the boundary. This is intentional -- you need a few pixels of overlap to avoid visible seams when compositing later.

**Models**: SAM 2 (meta), BiRefNet (ZhengPeng7/BiRefNet), RMBG-2.0 (briaai), GroundingDINO (for text-prompted segmentation like "food" vs "plate")

**Output**: RGBA images of each layer + alpha masks

---

### STAGE 2: DEPTH ESTIMATION -- Build 2.5D Understanding

**What happens**: A monocular depth map is estimated from the original image, creating a grayscale representation where brightness = proximity to camera.

**How it works**:
- **MiDaS** (Intel) or **Depth Anything V2** (TikTok/ByteDance) generates a depth map
- The depth map captures: food is closest (brightest), plate rim is mid-distance, table surface is furthest (darkest)
- This depth information is used for TWO purposes:
  1. Generating realistic depth-of-field blur later (Stage 6)
  2. Providing geometric understanding for the angle change (Stage 3)

**Critical limitation**: A 2D photo contains NO true 3D information. The depth map is an ESTIMATE. For flat top-down food photos, the depth variation is minimal (food sits ~2-3cm above table). This means...

---

### STAGE 3: ANGLE CHANGE -- The "Impossible" Part (It's Faked)

**THIS IS THE KEY INSIGHT: FoodShot does NOT truly change the camera angle. It GENERATES a new image that LOOKS like a different angle.**

There are three possible technical approaches, in order of likelihood:

#### Approach A: Pure Generation with Subject Conditioning (MOST LIKELY)

**How it works**:
1. The segmented food (from Stage 1) is used as a **reference/condition image**
2. A diffusion model generates a completely NEW scene from a text prompt like "wonton mee on grey ceramic bowl, walnut table, 45-degree angle, warm side lighting"
3. The model is conditioned to preserve the food's appearance using:
   - **IP-Adapter**: Feeds the food image as a visual embedding, forcing the generated image to contain visually similar food
   - **ControlNet Depth**: Uses the estimated depth map to maintain spatial relationships
   - **FLUX Fill / SD Inpainting**: The food region is masked as "keep this", everything else is "generate new"

**Why the food looks "pixel-identical"**: It's NOT pixel-identical at the sub-pixel level. It's perceptually identical because:
- The diffusion model at low denoise (0.25-0.40) preserves most of the original food texture
- IP-Adapter forces visual similarity to the reference food image
- The food was never actually moved -- only the SURROUNDING context changed
- Human perception fills in the gaps -- we see "same food" even if individual pixel values shifted slightly

**Evidence**: This is exactly how ZenCtrl (FotographerAI) works -- it takes a subject image + generates new context around it while preserving foreground fidelity.

#### Approach B: Depth-Warp + Inpaint (POSSIBLE FOR SMALL ANGLE CHANGES)

**How it works**:
1. Use depth map to create a 3D point cloud from the 2D image
2. Apply a virtual camera rotation (e.g., from 0-degree top-down to 45-degree)
3. Project back to 2D -- this creates holes/artifacts where occluded areas become visible
4. Use inpainting to fill the holes
5. Use **GenWarp** (Sony, NeurIPS 2024) -- a diffusion model that learns WHERE to warp and WHERE to generate, compensating for ill-warped regions during generation

**Problem with this approach for food**:
- Top-down to 45-degree is a MASSIVE angle change (~45 degrees of rotation)
- The warp would create enormous holes on the far side of the food
- Inpainting would need to hallucinate the side profile of every wonton, the thickness of char siu slices, the depth of the bowl
- Result: would NOT preserve pixel-identical food arrangement
- **This approach only works for SMALL angle changes (5-15 degrees)**

#### Approach C: Novel View Synthesis (UNLIKELY FOR PRODUCTION)

**How it works**:
- **Zero-1-to-3** (Columbia): Diffusion model conditioned on viewpoint change, generates new views of an object from a single image
- **Gaussian Splatting** (SVG3D): Reconstructs 3D gaussians from a single view, enables rendering from any angle

**Problem**:
- These are research-stage models, not production-ready
- They produce noticeable artifacts on complex scenes (food with many small elements)
- They don't reliably preserve fine textures (spring onion threads, noodle strands)
- Zero-1-to-3 is designed for single objects, not complex food arrangements

### STAGE 3 VERDICT

**The "angle change" is almost certainly Approach A**: The food is extracted, the entire surrounding scene (plate, table, background, lighting) is REGENERATED from scratch at the desired angle, and the food is composited back in with perspective-appropriate adjustments. The food itself is NOT reprojected through 3D -- it's kept as-is with minor perspective warping (scale/skew) to sell the illusion.

The reason the food looks identical is because **the food pixels literally ARE the original pixels**, just composited onto a new generated scene.

---

### STAGE 4: PLATE AND SCENE GENERATION

**What happens**: A completely new plate, table, and background are generated.

**How it works**:
1. The food mask defines a "hole" in the center of the frame
2. Everything OUTSIDE the food mask is generated via inpainting:
   - **FLUX Fill** (Black Forest Labs): Best-in-class inpainting, generates coherent scenes around a preserved subject
   - **SD XL Inpainting**: Alternative with more community support
   - Prompt: "grey speckled ceramic shallow wide bowl on walnut wood table with wooden serving board, warm directional side lighting, water glass and cutting board in background, 45-degree food photography angle, professional food styling"
3. The model generates the plate UNDERNEATH the food, the table around the plate, and props in the background
4. **Critical**: The plate generation must account for:
   - The plate rim visible AROUND the food
   - The plate bottom visible BETWEEN food items (gaps between wontons)
   - Shadows cast by food onto the plate
   - Reflections on the plate surface matching the new lighting

**Mask strategy**: The mask is NOT just the food outline. It's an INVERTED food mask -- everything that ISN'T food gets regenerated. The food pixels stay locked.

**Style matching**: FoodShot's "30+ presets" (delivery, restaurant, instagram, fine dining) are essentially different prompt templates + LoRA/style conditioning that produce consistent aesthetic families.

---

### STAGE 5: RELIGHTING -- Match Food Lighting to New Scene

**What happens**: The food was photographed under fluorescent kopitiam lighting. The new scene has warm directional side light. The food must be relit to match.

**How it works**:
- **IC-Light V2** (lllyasviel): The state-of-the-art relighting model
  - Text-conditioned mode: "warm directional side lighting from left, golden hour warmth"
  - Background-conditioned mode: Takes the generated background as lighting reference, relights the food to match
- IC-Light modifies ONLY the lighting (shadows, highlights, color temperature) while preserving texture detail
- Applied ONLY to the food layer, not the already-correctly-lit generated background

**Frequency Separation for Detail Preservation**:
This is the secret sauce for keeping food texture during relighting:
1. Split the food image into HIGH frequency (texture, edges, grain) and LOW frequency (color, tone, shadows)
2. Apply IC-Light relighting to the LOW frequency layer only
3. Recombine: original HIGH frequency (preserving every texture detail) + relit LOW frequency (matching new lighting)
4. Result: food has correct lighting for the new scene but ZERO texture loss

**Implementation**: The risunobushi Product Photography Relight v3/v4 ComfyUI workflow implements exactly this -- frequency separation + IC-Light + color matching. The Gaussian blur separates frequencies, IC-Light adjusts the low-frequency layer, then they're recombined.

---

### STAGE 6: DEPTH OF FIELD -- Selective Blur

**What happens**: Background props (water glass, cutting board) are blurred, food stays sharp.

**How it works**:
1. Use the depth map from Stage 2 (or generate a new one for the composite)
2. Create a **blur gradient map**: sharp at food depth, progressively blurrier at increasing depth
3. Apply **lens blur** (NOT Gaussian blur -- lens blur creates realistic bokeh circles):
   - Food zone: 0 blur
   - Near background (plate edge, serving board): 1-3px blur
   - Far background (water glass, cutting board): 8-15px blur
   - Extreme background: 20-30px blur
4. The blur is applied as a CONTINUOUS gradient based on depth, not a binary sharp/blurry split

**Technical implementation**:
```python
# Simplified depth-based blur
from PIL import ImageFilter
import numpy as np

depth_map = estimate_depth(composite_image)  # 0-255, 0=far, 255=near
food_depth = depth_map[food_mask].mean()

for pixel in image:
    depth_diff = abs(depth_map[pixel] - food_depth)
    blur_radius = depth_diff * blur_scale  # e.g., blur_scale = 0.1
    # Apply variable blur per-pixel (or per-tile for performance)
```

**Alternative**: Some pipelines use the depth map as a mask input to a Gaussian blur filter with variable sigma, applied in tiles or concentric rings from the focal point.

---

### STAGE 7: POST-PROCESSING -- Final Polish

**What happens**: Color grading, sharpening, grain, and final compositing.

**Steps**:
1. **DetailTransfer node** (ComfyUI): Transfers fine texture details from the original food photo onto the final composite using soft_light blending mode. Ensures no texture was lost during any generation step.
2. **Color matching**: The food's white balance is adjusted to match the warm lighting of the new scene. Not a full color grade -- just harmonization.
3. **Sharpening**: Unsharp mask or similar on the food region only, to counteract any softening from the pipeline.
4. **Grain**: Subtle film grain (0.01-0.02 intensity) to unify the look and mask any remaining artifacts at composite boundaries.
5. **Edge blending**: The boundary between original food pixels and generated plate/background is feathered using alpha compositing with a slight Gaussian blur on the mask edge (2-4px).

---

## THE COMPLETE PIPELINE IN SEQUENCE

```
INPUT: Smartphone food photo (top-down, plastic plate, bad lighting)
  |
  v
[1] SEGMENT (SAM2 / BiRefNet)
  |-- Food mask (RGBA, with alpha matting at edges)
  |-- Plate mask
  |-- Background mask
  |
  v
[2] DEPTH ESTIMATE (Depth Anything V2 / MiDaS)
  |-- Depth map (grayscale)
  |
  v
[3] EXTRACT FOOD
  |-- Isolated food on transparent background
  |-- Minor perspective warp if angle change needed (affine transform)
  |
  v
[4] GENERATE NEW SCENE (FLUX Fill / SDXL Inpainting)
  |-- Input: inverted food mask + style prompt + optional reference image
  |-- Output: complete new scene with hole where food goes
  |-- New plate, table, props, lighting all generated
  |
  v
[5] COMPOSITE FOOD ONTO SCENE
  |-- Alpha composite food layer onto generated scene
  |-- Feathered edges (2-4px Gaussian on mask boundary)
  |
  v
[6] RELIGHT FOOD (IC-Light V2)
  |-- Frequency separation: split food into hi-freq + lo-freq
  |-- Relight lo-freq to match new scene lighting
  |-- Recombine: original hi-freq + relit lo-freq
  |
  v
[7] DEPTH OF FIELD (Depth-based lens blur)
  |-- Sharp at food focal plane
  |-- Progressive blur based on depth distance from food
  |
  v
[8] POST-PROCESS
  |-- DetailTransfer (recover any lost textures)
  |-- Color harmonization
  |-- Selective sharpening on food
  |-- Subtle grain overlay
  |-- Edge blending at composite boundaries
  |
  v
OUTPUT: "Professional" food photo (new angle, new plate, new lighting, DOF)
```

---

## ANSWERING THE KEY QUESTIONS

### Q: How do they CHANGE THE CAMERA ANGLE while keeping food identical?

**A: They DON'T truly change the angle.** The food stays at its original angle (or gets a minor affine warp -- scale + skew). The ENTIRE SURROUNDING SCENE is regenerated at the desired angle. Your brain perceives "the angle changed" because:
- The plate perspective matches 45 degrees
- The table has correct perspective lines
- The shadows fall at 45-degree angles
- The background has correct depth perspective

The food itself is essentially "pasted" into a new scene. At 45 degrees vs top-down, food (being relatively flat/low-profile) looks nearly identical. A bowl of noodles viewed from top-down vs 45 degrees doesn't change dramatically in 2D projection -- the top surface looks similar.

For LARGE angle changes (top-down to eye-level), the food WOULD need true 3D reprojection, which current tech can't do well. FoodShot likely limits angle changes to ranges where the food's 2D projection doesn't change dramatically (top-down to ~45 degrees, or 45 to ~30 degrees).

### Q: How do they swap the PLATE without affecting the food ON the plate?

**A: Layered segmentation + inpainting.**
1. Segment food from plate with pixel-precise masks (BiRefNet/SAM2)
2. Extract food as RGBA layer
3. Inpaint a completely new plate+scene in the food's absence (FLUX Fill generates plate visible BETWEEN and AROUND food items)
4. Composite food back ON TOP of new plate
5. The critical trick: the food mask includes a few pixels of overlap with the plate edge, so when composited, there's no visible gap. The mask boundary is feathered.

The food never "knows" the plate changed. It was lifted off, a new plate was painted underneath, and it was placed back.

### Q: How do they add DEPTH OF FIELD blur?

**A: Depth estimation + variable lens blur.**
1. Estimate depth map of final composite (Depth Anything V2)
2. Define focal plane at food depth
3. Apply blur proportional to depth distance from focal plane
4. Use lens blur (disc kernel) not Gaussian blur for realistic bokeh
5. Apply via per-pixel or per-tile variable-radius blur

This is computationally simple -- the hardest part is the depth estimation, which modern models handle well.

### Q: How do they RELIGHT the food?

**A: IC-Light V2 with frequency separation.**
1. Split food into texture layer (high frequency) and tone layer (low frequency)
2. IC-Light relights ONLY the tone layer to match new scene lighting
3. Recombine with original texture layer intact
4. Result: correct lighting + zero texture loss

### Q: One model call or multiple stages?

**A: DEFINITELY multiple stages.** At minimum 5 stages, likely 7-8 including post-processing. No single model can simultaneously segment + change angle + swap plate + relight + add DOF. The "90 seconds" processing time confirms multi-stage pipeline (a single model call would be 5-15 seconds).

### Q: What specific models/checkpoints?

**Best guess based on capability analysis:**
- Segmentation: SAM 2 (meta-ai) or BiRefNet (ZhengPeng7/BiRefNet)
- Depth: Depth Anything V2 (depth-anything/Depth-Anything-V2-Large)
- Inpainting/Scene Gen: FLUX Fill (black-forest-labs) or fine-tuned SDXL inpainting
- Relighting: IC-Light V2 (lllyasviel/IC-Light)
- Detail recovery: Custom frequency separation + DetailTransfer
- Background removal: RMBG-2.0 (briaai) built on BiRefNet
- Possibly: Custom food-specific LoRAs trained on millions of food photos (their claim)

---

## WHAT MAKES FOODSHOT PROPRIETARY

The individual models are all open-source or commercially available. FoodShot's moat is:

1. **Food-specific fine-tuning**: Their models are trained/fine-tuned on "millions of professional food photographs" -- this means custom LoRAs or full fine-tunes that understand food styling conventions, plating aesthetics, and food-specific lighting
2. **Pipeline orchestration**: The specific order, parameters, mask strategies, and handoff between stages
3. **Preset library**: The 30+ style presets are curated prompt+LoRA+parameter combinations
4. **Edge handling**: The food-plate boundary compositing -- getting seamless edges where food meets new plate is the hardest engineering challenge
5. **Speed optimization**: Running 5-7 model inference stages in 90 seconds requires aggressive optimization (quantized models, batched inference, GPU pipeline parallelism)

---

## REPLICATION STACK (OPEN SOURCE)

To build an equivalent pipeline:

```
Segmentation:    BiRefNet + SAM 2 + GroundingDINO
Depth:           Depth Anything V2
Scene Generation: FLUX Fill (or FLUX Dev + ControlNet)
Relighting:      IC-Light V2
Detail Recovery:  Frequency separation (custom) + DetailTransfer
DOF:             Custom depth-based lens blur (Python/OpenCV)
Post-processing: Color matching + sharpening + grain (Pillow/OpenCV)
Orchestration:   ComfyUI (visual) or Python script (production)
```

**ComfyUI workflow reference**: risunobushi's "Product Photo Relight v4" workflow on OpenArt implements Stages 4-8 with frequency separation and detail preservation. Add SAM2 segmentation + Depth Anything V2 as preprocessing stages.

**ZenCtrl** (FotographerAI, open-source on GitHub) implements a similar multi-stage pipeline with agentic task composition -- it handles inpainting, relighting, background generation as composable stages.

---

## WHAT THEY CANNOT DO (LIMITATIONS)

1. **True 3D angle change > 30 degrees**: Food viewed from top-down cannot be convincingly shown from eye-level. The 3D structure of stacked wontons, layered noodles, etc. is not captured in a 2D photo.
2. **Interior plate views**: If food fills a deep bowl, the inner walls of the bowl between food items must be hallucinated -- no reference data exists.
3. **Transparent/reflective elements**: Glass bowls, glossy sauces with reflections of the new environment are extremely hard.
4. **Cast shadows from food**: The shadows food casts on the new plate must be generated correctly for the new lighting direction. IC-Light handles this partially but not perfectly.
5. **Food that references the original plate**: If noodles drape over the OLD plate's rim in a specific way, they'll look odd on a plate with a different rim profile. The food was shaped BY the original container.

---

## SOURCES

- [FoodShot AI](https://foodshot.ai/)
- [ZenCtrl - FotographerAI](https://github.com/FotographerAI/ZenCtrl)
- [BiRefNet - Bilateral Reference Network](https://github.com/ZhengPeng7/BiRefNet)
- [IC-Light - Relighting](https://github.com/lllyasviel/IC-Light)
- [IC-Light V2 on fal.ai](https://fal.ai/models/fal-ai/iclight-v2)
- [SAM + Stable Diffusion Inpainting](https://medium.com/@su-paris/ai-powered-image-editing-with-inpainting-using-sam-and-stable-diffusion-2affd84b2c31)
- [Inpaint Anything (arXiv)](https://arxiv.org/abs/2304.06790)
- [GenWarp - Sony NeurIPS 2024](https://github.com/sony/genwarp)
- [Zero-1-to-3 - Novel View Synthesis](https://zero123.cs.columbia.edu/)
- [Product Photo Relight v4 - ComfyUI Workflow](https://openart.ai/workflows/risunobushi/product-photo-relight-v4---from-photo-to-advertising-preserve-details-color-upscale-and-more/gCMFAhrxCMjqc3Xr3Zsj)
- [Product Photography Relight v3 - Frequency Separation](https://openart.ai/workflows/risunobushi/product-photography-relight-v3---with-internal-frequency-separation-for-keeping-details/YrTJ0JTwCX2S0btjFeEN)
- [ComfyUI Product Photography Guide](https://www.apatero.com/blog/comfyui-for-product-photography-professional-results-2025)
- [FLUX Fill Inpainting](https://www.runcomfy.com/comfyui-workflows/Flux-tools-Flux1-fill-for-inpainting-and-outpainting)
- [Depth ControlNet Guide](https://comfyui-wiki.com/en/tutorial/advanced/how-to-use-depth-controlnet-with-sd1.5)
- [Stable Diffusion Denoising Strength Guide](https://www.aiarty.com/stable-diffusion-guide/denoising-strength-stable-diffusion.htm)
- [AI Product Photography Pipeline - Gary Stafford](https://garystafford.medium.com/ai-powered-product-perfection-part-2-of-2-leveraging-generative-ai-techniques-for-diverse-ba8d5ea7986e)
- [Higgsfield Angles - Camera Perspective Change](https://higgsfield.ai/blog/Change-the-Angle-of-Any-Image)
- [Gaussian Splatting Review](https://arxiv.org/abs/2405.03417)
- [SVG3D - Single View 3D Reconstruction](https://www.nature.com/articles/s41598-025-03200-7)
- [DetailTransfer Node - ComfyUI](https://www.runcomfy.com/comfyui-nodes/ComfyUI-IC-Light/DetailTransfer)
- [RMBG-2.0 - Background Removal](https://huggingface.co/briaai/RMBG-2.0)
- [Frequency Separation Technique](https://www.co3dex.com/blog/Understanding_Frequency_Separation/)
- [IOPaint - Inpainting Tool](https://github.com/Sanster/IOPaint)
- [Inpaint Anything - GitHub](https://github.com/Uminosachi/inpaint-anything)
