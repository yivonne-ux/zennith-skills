# fal.ai API Research — Food Photo Enhancement Pipeline

**Date:** 2026-03-23
**Goal:** Segment food -> white plate -> white background -> professional lighting -> export

---

## TABLE OF CONTENTS

1. [Background Removal / Segmentation](#1-background-removal--segmentation)
2. [Inpainting Endpoints (Mask-Based)](#2-inpainting-endpoints-mask-based)
3. [Image Editing (Prompt-Based)](#3-image-editing-prompt-based)
4. [Relighting](#4-relighting)
5. [Upscaling / Enhancement](#5-upscaling--enhancement)
6. [Product Photography](#6-product-photography)
7. [Object Manipulation](#7-object-manipulation)
8. [Pipeline Architecture Recommendation](#8-pipeline-architecture-recommendation)

---

## 1. BACKGROUND REMOVAL / SEGMENTATION

### 1a. BiRefNet v2 (BEST — most options)
- **Endpoint:** `fal-ai/birefnet/v2`
- **Pricing:** Not disclosed (likely per-request)
- **Parameters:**
  - `image_url` (string, required)
  - `model` (enum, default "General Use (Light)")
    - `BiRefNet` — General Use (Light) — default, fast
    - `BiRefNet_lite-2K` — General Use (Light 2K) — trained on 2K images
    - `BiRefNet_lite` — General Use (Heavy) — slower, more accurate
    - `BiRefNet-matting` — Matting mode (soft edges, transparency)
    - `BiRefNet-portrait` — Optimized for portraits
    - `BiRefNet_dynamic` — Dynamic resolution 256x256 to 2304x2304
  - `operating_resolution` (enum: "1024x1024", "2048x2048", "2304x2304")
  - `output_format` (enum: "png", "webp", "gif")
  - `output_mask` (boolean, default false) — **returns segmentation mask separately**
  - `refine_foreground` (boolean, default true) — edge refinement
  - `sync_mode` (boolean)
- **Output:** `{ image: {url, width, height}, mask_image: {url, ...} }`
- **Key:** Can return both the cutout AND the mask. Mask can be fed to inpainting models.
- **Also has:** Video endpoint (`/v2/video`), realtime WebSocket (`/v2/realtime`)

### 1b. Bria RMBG 2.0 (Commercial-safe)
- **Endpoint:** `fal-ai/bria/background/remove`
- **Pricing:** $0.018 per generation
- **Parameters:**
  - `image_url` (string, required)
  - `sync_mode` (boolean)
- **Output:** `{ image: {url, ...} }`
- **Key:** Trained on licensed data only. Simplest API. No mask output option.

### 1c. rembg (Classic, cheapest)
- **Endpoint:** `fal-ai/imageutils/rembg`
- **Pricing:** Compute-based (GPU-A6000)
- **Parameters:**
  - `image_url` (string, required)
  - `crop_to_bbox` (boolean, default false) — crop to subject bounding box
  - `sync_mode` (boolean)
- **Output:** `{ image: {url, ...} }`
- **Key:** Classic U2-Net based. Fast and cheap. No mask output.

### 1d. Pixelcut Background Removal
- **Endpoint:** `pixelcut/background-removal`
- **Pricing:** Not disclosed
- **Parameters:**
  - `image_url` (string, required)
  - `output_format` (enum: "rgba", "alpha", "zip") — **"alpha" returns mask only!**
  - `sync_mode` (boolean, default true)
- **Output:** `{ image: {url, ...} }` or `{ file: {...} }` for zip
- **Key:** Can output alpha-only mask. Good for pipeline chaining.

### 1e. SAM2 (Segment Anything — Interactive)
- **Endpoint:** `fal-ai/sam2/image`
- **Parameters:**
  - `image_url` (string, required)
  - `prompts` (array of PointPrompt) — `{x, y, label}` where label=1 foreground, label=0 background
  - `box_prompts` (array of BoxPrompt) — `{x_min, y_min, x_max, y_max}`
  - `apply_mask` (boolean, default false) — apply mask to image
  - `output_format` (enum: "png", "jpeg", "webp")
- **Output:** `{ image: {url, ...} }`
- **Key:** Interactive segmentation with point/box prompts. Can click on the food to segment it precisely. Auto-segment endpoint also available at `/auto-segment`.

---

## 2. INPAINTING ENDPOINTS (MASK-BASED)

### 2a. FLUX.1 [pro] Fill (BEST quality, simplest)
- **Endpoint:** `fal-ai/flux-pro/v1/fill`
- **Pricing:** $0.05/megapixel
- **Parameters:**
  - `prompt` (string, required)
  - `image_url` (string, required) — must match mask dimensions
  - `mask_url` (string, required) — white=fill, black=keep
  - `seed` (integer)
  - `num_images` (integer, 1-4)
  - `output_format` (enum: "jpeg", "png")
  - `safety_tolerance` (enum: 1-6)
  - `enhance_prompt` (boolean)
- **Output:** `{ images: [{url, width, height}], seed, prompt }`
- **Best for:** High-quality fill. Replace plate, replace background behind food.

### 2b. FLUX.1 [pro] Fill Fine-tuned
- **Endpoint:** `fal-ai/flux-pro/v1/fill-finetuned`
- **Key:** Same as Fill but with fine-tuned weights. Check for specific improvements.

### 2c. FLUX.1 [dev] Inpainting with LoRAs
- **Endpoint:** `fal-ai/flux-lora/inpainting`
- **Pricing:** Per megapixel (cheaper than pro)
- **Parameters:**
  - `prompt` (string, required)
  - `image_url` (string, required)
  - `mask_url` (string, required)
  - `strength` (float, default 0.85) — 0=preserve, 1=full remake
  - `num_inference_steps` (integer, default 28)
  - `guidance_scale` (float, default 3.5)
  - `loras` (array) — custom LoRA weights for style control
  - `seed`, `num_images`, `output_format`, `acceleration`
- **Best for:** Custom style via LoRAs. Food photography LoRA possible.

### 2d. FLUX.1 [dev] General Inpainting (MOST PARAMETERS)
- **Endpoint:** `fal-ai/flux-general/inpainting`
- **Parameters:** All of 2c PLUS:
  - `real_cfg_scale` (float, default 3.5) — classical CFG
  - `use_real_cfg` (boolean)
  - `use_cfg_zero` (boolean) — CFG-zero init
  - `controlnets` (array) — ControlNet configs
  - `controlnet_unions` (array) — Union ControlNet
  - `ip_adapters` (array) — IP-Adapter for style reference
  - `easycontrols` (array) — canny, depth, pose controls
  - `reference_image_url` (string) — reference-only guidance
  - `reference_strength` (float, default 0.65)
  - `negative_prompt` (string)
  - `nag_scale` (float, default 3)
  - `scheduler` (enum: "euler", "dpmpp_2m")
- **Best for:** Maximum control. Reference image + inpainting + ControlNet all in one call.

### 2e. FLUX Kontext LoRA Inpaint
- **Endpoint:** `fal-ai/flux-kontext-lora/inpaint`
- **Parameters:**
  - `image_url` (string, required)
  - `prompt` (string, required)
  - `reference_image_url` (string, required) — reference for context
  - `mask_url` (string, required) — **YES, supports masks**
  - `strength` (float, default 0.88)
  - `num_inference_steps` (integer, default 30)
  - `guidance_scale` (float, default 2.5)
  - `loras` (array) — custom LoRAs
  - `acceleration` (enum: "none", "regular", "high")
- **Best for:** Context-aware inpainting with reference image style transfer.

### 2f. Fooocus Inpainting (Feature-rich SD-based)
- **Endpoint:** `fal-ai/fooocus/inpaint`
- **Parameters:**
  - `prompt`, `negative_prompt` (strings)
  - `inpaint_image_url` (string, required)
  - `mask_image_url` (string)
  - `inpaint_mode` (enum: "Inpaint or Outpaint (default)", others)
  - `inpaint_engine` (enum: "v1", "v2.5", "v2.6")
  - `inpaint_strength` (float, default 1)
  - `inpaint_respective_field` (float, default 0.618)
  - `styles` (array) — 200+ style presets
  - `performance` (enum: "Speed", "Quality", "Extreme Speed", "Lightning")
  - `guidance_scale` (float, default 4)
  - `sharpness` (float, default 2)
  - `loras` (array, up to 5)
  - `refiner_model`, `refiner_switch`
- **Best for:** Style presets, SD ecosystem, high customization.

### 2g. SD Inpainting (Generic)
- **Endpoint:** `fal-ai/inpaint`
- **Parameters:**
  - `model_name` (string, required) — HuggingFace model ID
  - `prompt`, `negative_prompt` (strings)
  - `image_url` (string, required)
  - `mask_url` (string, required) — black=keep, white=inpaint
  - `num_inference_steps` (integer, default 30)
  - `guidance_scale` (float, default 7.5)
  - `seed`
- **Best for:** Any SD model from HuggingFace. Maximum model flexibility.

### 2h. Bria Eraser (Object removal)
- **Endpoint:** `fal-ai/bria/eraser`
- **Parameters:**
  - `image_url` (string, required)
  - `mask_url` (string, required) — area to clean/erase
  - `mask_type` (enum: "manual", "automatic") — manual for user masks, automatic for SAM-generated
  - `preserve_alpha` (boolean, default false)
- **Best for:** Clean removal/fill of masked areas. Commercial-safe.

### 2i. Bria Fibo Edit (JSON + Mask + Image)
- **Endpoint:** `bria/fibo-edit/edit`
- **Pricing:** $0.04 per image
- **Parameters:**
  - `image_url` (string)
  - `mask_url` (string) — **YES, supports masks**
  - `instruction` (string) — natural language edit
  - `structured_instruction` (JSON) — structured control
  - `seed` (integer, default 5555)
  - `steps_num` (integer, default 30, range 20-50)
  - `negative_prompt` (string)
  - `guidance_scale` (float, default 5)
- **Output:** `{ image, images, structured_instruction }`
- **Best for:** Structured edits with maximum controllability. Mask + text + JSON.

---

## 3. IMAGE EDITING (PROMPT-BASED, NO MASK)

### 3a. FLUX.1 Kontext [pro] (Best prompt-based editor)
- **Endpoint:** `fal-ai/flux-pro/kontext`
- **Pricing:** $0.055/megapixel
- **Parameters:**
  - `prompt` (string, required) — "specify what you want to change"
  - `image_url` (string, required) — reference image
  - `guidance_scale` (float, default 3.5)
  - `aspect_ratio` (enum: 21:9 to 9:21)
  - `num_images` (integer, 1-4)
  - `output_format`, `safety_tolerance`, `enhance_prompt`
- **NO MASK SUPPORT** — uses natural language only
- **Best for:** "Change the plate to white porcelain" type edits without needing a mask.

### 3b. FLUX.2 [dev] Edit (Multi-reference)
- **Endpoint:** `fal-ai/flux-2/edit`
- **Pricing:** $0.012/megapixel (input + output)
- **Parameters:**
  - `prompt` (string, required)
  - `image_urls` (array, max 4 images) — multi-reference
  - `guidance_scale` (float, default 2.5)
  - `num_inference_steps` (integer, default 28)
  - `image_size` (enum/object, 512-2048)
  - `acceleration` (enum: "none", "regular", "high")
  - `enable_prompt_expansion` (boolean)
- **NO explicit mask** — prompt-driven editing with multi-image context
- **Best for:** Cheapest FLUX edit. Style transfer from reference images.

### 3c. Nano Banana Pro Edit (Google Gemini 3 Pro Image)
- **Endpoint:** `fal-ai/nano-banana-pro/edit`
- **Pricing:** $0.15 per image ($1 = ~7 images); 4K = 2x
- **Parameters:**
  - `prompt` (string, required, 3-50,000 chars)
  - `image_urls` (array, required) — up to 14 reference images
  - `num_images` (integer, 1-4)
  - `aspect_ratio` (enum: auto to 9:16)
  - `resolution` (enum: "1K", "2K", "4K")
  - `output_format` (enum: "jpeg", "png", "webp")
  - `seed`, `safety_tolerance`
  - `enable_web_search` (boolean) — web data for context
  - `limit_generations` (boolean)
- **NO MASK SUPPORT** — prompt-driven only
- **Best for:** Complex multi-image edits. "Combine these ingredients into a dish on a white plate." Up to 14 reference images. Reasoning-based (understands complex instructions).

### 3d. Nano Banana Pro Generate (Text-to-Image)
- **Endpoint:** `fal-ai/nano-banana-pro`
- **Pricing:** $0.15 per image
- **Same params as edit minus image_urls**

### 3e. Qwen-Image-2 Edit
- **Endpoint:** `fal-ai/qwen-image-2/edit`
- **Details:** Text-driven editing. Not fully documented yet.

### 3f. Seedream (ByteDance) Edit
- **Endpoint:** `bytedance/seedream/v5/lite/edit` and `bytedance/seedream/v4/edit`
- **Details:** ByteDance's latest editing model.

### 3g. Reve Edit
- **Endpoint:** `fal-ai/reve/edit`
- **Details:** Text-driven image transformation.

---

## 4. RELIGHTING

### 4a. IC-Light V2 (Best — directional control)
- **Endpoint:** `fal-ai/iclight-v2`
- **Parameters:**
  - `prompt` (string, required) — relighting scene description
  - `image_url` (string, required)
  - `negative_prompt` (string)
  - `initial_latent` (enum: "None", "Left", "Right", "Top", "Bottom") — **lighting direction**
  - `num_inference_steps` (integer, default 28)
  - `guidance_scale` (float, default 5)
  - `cfg` (float, default 1, range 0.01-5)
  - `enable_hr_fix` (boolean) — high-res enhancement
  - `lowres_denoise` (float, default 0.98)
  - `highres_denoise` (float, default 0.95)
  - `hr_downscale` (float, default 0.5)
  - `image_size` (enum/object)
  - `num_images` (integer, 1-4)
  - `output_format` (enum: "jpeg", "png")
- **Best for:** Precise directional lighting. "Top" lighting for food photography overhead look.

### 4b. Image Apps Relighting (Simple presets)
- **Endpoint:** `fal-ai/image-apps-v2/relighting`
- **Parameters:**
  - `image_url` (string, required)
  - `lighting_style` (enum) — **18 presets:**
    natural, studio, golden_hour, blue_hour, dramatic, soft, hard,
    backlight, side_light, front_light, rim_light, sunset, sunrise,
    neon, candlelight, moonlight, spotlight, ambient
  - `aspect_ratio` (enum: 1:1, 16:9, 9:16, 4:3, 3:4)
- **Best for:** Quick preset-based relighting. "studio" preset for food.

### 4c. Bria Fibo Edit Relight
- **Endpoint:** `bria/fibo-edit/relight`
- **Parameters:**
  - `image_url` (string, required)
  - `light_direction` (enum: "front", "side", "bottom", "top-down")
  - `light_type` (enum) — **13 types:**
    midday, blue hour light, low-angle sunlight, sunrise light,
    spotlight on subject, overcast light, soft overcast daylight lighting,
    cloud-filtered lighting, fog-diffused lighting, moonlight lighting,
    starlight nighttime, soft bokeh lighting, harsh studio lighting
- **Best for:** Structured relighting with separate direction + type control. Commercial-safe.

---

## 5. UPSCALING / ENHANCEMENT

### 5a. Topaz Upscale (BEST — professional grade)
- **Endpoint:** `fal-ai/topaz/upscale/image`
- **Pricing:** $0.08 (up to 24MP), $0.16 (48MP), $0.32 (96MP), up to $1.36 (512MP)
- **Parameters:**
  - `image_url` (string, required)
  - `model` (enum) — **10 models:**
    - `Standard V2` — default, general purpose
    - `Low Resolution V2` — very low-res inputs
    - `High Fidelity V2` — maximum detail preservation
    - `CGI` — computer graphics
    - `Text Refine` — text clarity (with `strength` param)
    - `Recovery` — damaged/compressed images
    - `Recovery V2` — improved recovery (with `detail` param)
    - `Redefine` — creative enhancement (with `creativity`, `texture` params)
    - `Standard MAX` — maximum quality
    - `Wonder` — AI-enhanced upscale
  - `upscale_factor` (float, 1-4x)
  - `subject_detection` (enum: "All", "Foreground", "Background")
  - `face_enhancement` (boolean, default true)
  - `face_enhancement_strength` (float, default 0.8)
  - `sharpen` (float, 0-1)
  - `denoise` (float, 0-1)
  - `fix_compression` (float, 0-1) — artifact removal
  - `prompt` (string) — generative guidance
  - `autoprompt` (boolean) — auto-generate prompt
- **Best for:** Final export quality. Denoise + sharpen + upscale in one call.

### 5b. Real-ESRGAN
- **Endpoint:** `fal-ai/esrgan`
- **Pricing:** $0.00111/compute second (GPU-A6000)
- **Parameters:**
  - `image_url` (string, required)
  - `scale` (float, default 2, range 1-8)
  - `tile` (integer, default 0) — tile size for large images
  - `face` (boolean) — face enhancement
  - `model` (enum):
    - `RealESRGAN_x4plus` (default)
    - `RealESRGAN_x2plus`
    - `RealESRGAN_x4plus_anime_6B`
    - `RealESRGAN_x4_v3`, `x4_wdn_v3`, `x4_anime_v3`
  - `output_format` (enum: "png", "jpeg")
- **Best for:** Cheap batch upscaling. Good enough for most uses.

### 5c. SeedVR2
- **Endpoint:** `fal-ai/seedvr/upscale/image`
- **Parameters:**
  - `image_url` (string, required)
  - `upscale_mode` (enum: "factor", "target")
  - `upscale_factor` (float, default 2, range 1-10)
  - `target_resolution` (enum: "720p", "1080p", "1440p", "2160p")
  - `noise_scale` (float, default 0.1)
  - `output_format` (enum: "png", "jpg", "webp")
- **Best for:** Target resolution mode (e.g., "make this exactly 1080p").

### 5d. AuraSR
- **Endpoint:** `fal-ai/aura-sr`
- **Parameters:**
  - `image_url` (string, required)
  - `upscale_factor` (integer, default 4)
  - `overlapping_tiles` (boolean) — better quality, 2x slower
  - `checkpoint` (enum: "v1", "v2")
- **Best for:** 4x upscaling with good detail generation.

### 5e. Recraft Crisp Upscale
- **Endpoint:** `fal-ai/recraft/upscale/crisp`
- **Parameters:**
  - `image_url` (string, required) — **must be PNG**
  - `enable_safety_checker` (boolean)
- **Best for:** Simplest possible upscale. PNG input only.

---

## 6. PRODUCT PHOTOGRAPHY

### 6a. Image Apps Product Photography
- **Endpoint:** `fal-ai/image-apps-v2/product-photography`
- **Parameters:**
  - `product_image_url` (string, required) — product on transparent/simple bg
  - `aspect_ratio` (enum: 1:1, 16:9, 9:16, 4:3, 3:4)
- **Output:** `{ images: [{url, ...}] }`
- **Best for:** One-click studio product shots. Feed it a cutout, get a studio photo.

---

## 7. OBJECT MANIPULATION

### 7a. Bria Fibo Edit — Add Object by Text
- **Endpoint:** `bria/fibo-edit/add_object_by_text`
- **Parameters:**
  - `image_url` (string, required)
  - `instruction` (string, required) — "Place a white porcelain plate under the food"
- **Best for:** Adding objects to scenes without mask.

### 7b. Bria Fibo Edit — Erase by Text
- **Endpoint:** `bria/fibo-edit/erase_by_text`
- **Parameters:**
  - `image_url` (string, required)
  - `object_name` (string, required) — "plate", "background clutter"
- **Best for:** Removing objects by name without mask.

---

## 8. PIPELINE ARCHITECTURE RECOMMENDATION

### Goal: GrabFood photo -> Premium white-plate studio shot

```
PIPELINE A: Mask-Based (Maximum Control)
=========================================

Step 1: SEGMENT FOOD
  -> SAM2 (`fal-ai/sam2/image`)
     Point-click on food item(s) to get precise mask
  -> OR BiRefNet v2 (`fal-ai/birefnet/v2`)
     output_mask=true, get both cutout + mask

Step 2: REMOVE/REPLACE BACKGROUND
  -> FLUX.1 [pro] Fill (`fal-ai/flux-pro/v1/fill`)
     image=original, mask=inverted_food_mask (everything except food)
     prompt="pristine white background, soft studio lighting,
             professional food photography, clean white surface"

Step 3: REPLACE PLATE (if needed)
  -> FLUX.1 [pro] Fill (`fal-ai/flux-pro/v1/fill`)
     image=result_from_step2, mask=plate_area_mask
     prompt="elegant white porcelain plate, minimalist,
             professional food styling"

Step 4: RELIGHT
  -> IC-Light V2 (`fal-ai/iclight-v2`)
     initial_latent="Top" (overhead food photography lighting)
     prompt="professional food photography, soft overhead lighting,
             subtle shadows, appetizing warm tones"
  -> OR Image Apps Relighting (`fal-ai/image-apps-v2/relighting`)
     lighting_style="studio"

Step 5: UPSCALE + ENHANCE
  -> Topaz (`fal-ai/topaz/upscale/image`)
     model="High Fidelity V2", upscale_factor=2,
     sharpen=0.3, denoise=0.2, fix_compression=0.3


PIPELINE B: Prompt-Based (Simpler, Less Control)
=================================================

Step 1: REMOVE BACKGROUND
  -> BiRefNet v2 (`fal-ai/birefnet/v2`)
     Get food cutout on transparent bg

Step 2: PRODUCT PHOTOGRAPHY
  -> Product Photography (`fal-ai/image-apps-v2/product-photography`)
     Feed cutout, get studio shot automatically

Step 3: REFINE WITH KONTEXT
  -> FLUX Kontext [pro] (`fal-ai/flux-pro/kontext`)
     prompt="Change to white porcelain plate, studio lighting"

Step 4: UPSCALE
  -> Topaz or ESRGAN


PIPELINE C: All-in-One Edit (Fastest)
======================================

Step 1: NANO BANANA PRO EDIT
  -> (`fal-ai/nano-banana-pro/edit`)
     image_urls=[original_food_photo]
     prompt="Transform this into professional food photography:
             place the food on an elegant white porcelain plate,
             pure white background, soft overhead studio lighting,
             food magazine quality, appetizing presentation"

Step 2: UPSCALE
  -> Topaz


PIPELINE D: Hybrid (RECOMMENDED)
=================================

Step 1: SEGMENT
  -> BiRefNet v2 with output_mask=true
     Get: food_cutout.png + food_mask.png

Step 2: COMPOSITE
  -> Python/Pillow: Place food cutout on white canvas

Step 3: INPAINT PLATE
  -> FLUX.1 [pro] Fill
     Mask the plate area, prompt for white porcelain

Step 4: RELIGHT
  -> Bria Fibo Relight
     light_direction="top-down"
     light_type="soft overcast daylight lighting"

Step 5: FINAL ENHANCE
  -> Topaz upscale
     model="Standard V2", sharpen=0.3
```

### Cost Estimate Per Image (Pipeline D)
| Step | Endpoint | Est. Cost |
|------|----------|-----------|
| BiRefNet v2 | fal-ai/birefnet/v2 | ~$0.01 |
| FLUX Fill | fal-ai/flux-pro/v1/fill | $0.05 |
| Fibo Relight | bria/fibo-edit/relight | $0.04 |
| Topaz | fal-ai/topaz/upscale/image | $0.08 |
| **TOTAL** | | **~$0.18/image** |

---

## APPENDIX: COMPLETE ENDPOINT QUICK REFERENCE

### Background Removal
| Endpoint | Mask Output | Commercial | Cost |
|----------|-------------|------------|------|
| `fal-ai/birefnet/v2` | YES (output_mask) | Yes | ~$0.01 |
| `fal-ai/bria/background/remove` | No | Yes (licensed data) | $0.018 |
| `fal-ai/imageutils/rembg` | No | Yes | Compute |
| `pixelcut/background-removal` | YES (alpha mode) | Yes | Unknown |
| `fal-ai/sam2/image` | YES (mask) | Yes | Unknown |

### Inpainting (Mask-Based)
| Endpoint | Mask | LoRA | ControlNet | Cost |
|----------|------|------|------------|------|
| `fal-ai/flux-pro/v1/fill` | YES | No | No | $0.05/MP |
| `fal-ai/flux-pro/v1/fill-finetuned` | YES | No | No | ~$0.05/MP |
| `fal-ai/flux-lora/inpainting` | YES | YES | No | Per MP |
| `fal-ai/flux-general/inpainting` | YES | YES | YES | Per MP |
| `fal-ai/flux-kontext-lora/inpaint` | YES | YES | No | Per MP |
| `fal-ai/fooocus/inpaint` | YES | YES (5) | No | Compute |
| `fal-ai/inpaint` | YES | No | No | Compute |
| `fal-ai/bria/eraser` | YES | No | No | Unknown |
| `bria/fibo-edit/edit` | YES | No | No | $0.04 |

### Editing (No Mask)
| Endpoint | Multi-Ref | Cost |
|----------|-----------|------|
| `fal-ai/flux-pro/kontext` | No | $0.055/MP |
| `fal-ai/flux-2/edit` | YES (4) | $0.012/MP |
| `fal-ai/nano-banana-pro/edit` | YES (14) | $0.15/img |

### Relighting
| Endpoint | Control Type | Best For |
|----------|-------------|----------|
| `fal-ai/iclight-v2` | Directional (L/R/T/B) | Precise control |
| `fal-ai/image-apps-v2/relighting` | 18 presets | Quick/simple |
| `bria/fibo-edit/relight` | Direction + Type | Food photography |

### Upscaling
| Endpoint | Max Scale | Special |
|----------|-----------|---------|
| `fal-ai/topaz/upscale/image` | 4x | Denoise, sharpen, 10 models |
| `fal-ai/esrgan` | 8x | Cheapest, fast |
| `fal-ai/seedvr/upscale/image` | 10x | Target resolution mode |
| `fal-ai/aura-sr` | 4x | Good detail gen |
| `fal-ai/recraft/upscale/crisp` | Auto | Simplest (PNG only) |
