---
name: lora-trainer
agents:
  - taoz
  - dreami
---

# LoRA Trainer — Zennith OS Skill

## What This Is

Train custom Flux LoRA models on Replicate to lock brand visual DNA. 80-120 images → $2 → 20 minutes → every generation carries YOUR style. Based on timkoda's method.

## When To Use

- Lock a brand character's face/identity across all generations
- Lock a brand's visual style (lighting, colors, composition)
- Lock a product's appearance for consistent shots
- Create AI influencer with consistent identity

## Pipeline

```
1. Prepare images (80-120 best, mixed framings/lighting)
2. Process: resize to 2048px, convert formats, create ZIP
3. Upload to Replicate Files API
4. Launch Flux LoRA training (~$2, ~20 min)
5. Generate with trigger word: "BRANDSTYLE, description..."
```

## Usage

```bash
# Prepare images for training
train-lora.sh prepare --input ./brand-images/ --output ./training-ready.zip

# Train LoRA on Replicate
train-lora.sh train --zip training-ready.zip \
  --model-name "mirra-style" \
  --trigger "MIRRASTYLE" \
  --steps 1000 \
  --rank 16

# Check training status
train-lora.sh status --model-name "mirra-style"

# Generate with trained LoRA
train-lora.sh generate --model-name "mirra-style" \
  --prompt "MIRRASTYLE, woman eating bento bowl, warm lighting, UGC style"

# Generate face-locked character LoRA
train-lora.sh train --zip character-images.zip \
  --model-name "jade-character" \
  --trigger "JADECHAR" \
  --steps 1000 \
  --rank 32
```

## Training Parameters

| Parameter | Style LoRA | Face LoRA | Product LoRA |
|-----------|-----------|-----------|-------------|
| images | 80-120 | 50-80 | 30-50 |
| trigger_word | BRANDSTYLE | CHARNAME | PRODUCTNAME |
| steps | 1000 | 800 | 600 |
| learning_rate | 0.0004 | 0.0004 | 0.0004 |
| lora_rank | 16 | 32 | 16 |
| resolution | 1024 | 1024 | 1024 |
| autocaption | true | true | true |
| cost | ~$2 | ~$1.50 | ~$1 |

## LoRA Strength Guide

- 0.5-0.7: Subtle style influence (blending with base model)
- 0.8-1.0: Full style transfer (recommended)
- >1.0: Artifacts, oversaturation (avoid)

## Image Preparation Rules

**Include:**
- Best work only (not everything)
- Mix framings: close-up, medium, wide, detail
- Mix lighting: your key setups equally represented
- Mix subjects: people, products, environments
- Consistent high quality

**Exclude:**
- Screenshots, UI, interface captures
- Low-quality or blurry images
- Duplicates or near-duplicates
- Images that don't represent target style

## Requirements

- Replicate account + API token (starts with `r8_`)
- $5-10 credit on Replicate
- REPLICATE_API_TOKEN in .env or environment

## Files

```
skills/lora-trainer/
├── SKILL.md
└── scripts/
    └── train-lora.sh
```
