# Materials Librarian

Tag, organize, search creative assets in the materials/ directory.

## Owner
Calliope

## What It Does
1. Tag and categorize assets: product shot, lifestyle, UGC, graphic, video
2. Track asset usage count + performance score
3. Link assets to seeds table in gaia.db
4. Auto-categorize new files added to materials/generated/
5. Search by brand, type, performance, tags

## Asset Categories
- product-hero: Clean product shots on white/simple background
- lifestyle: Product in real-life context
- ugc: User-generated or UGC-style content
- graphic: Text overlays, infographics, branded graphics
- video-clip: Short video clips for ad assembly
- broll: Background/supplementary video footage

## Directory
`~/.openclaw/materials/`

## Data
Reads from: materials/ directory, seeds table
Writes to: seeds table (asset links), reference_library table
