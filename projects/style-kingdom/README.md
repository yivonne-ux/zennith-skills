# Style Kingdom — Asian Fashion Tycoon + Contest

A mobile-first Roblox game where you build an Asian fashion boutique, serve NPC customers, and compete in runway contests.

## Quick Start (Rojo)

```bash
# Install toolchain
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
rokit install

# Install packages
wally install

# Serve to Roblox Studio
rojo serve
```

1. Install the **Rojo** plugin in Roblox Studio
2. Click "Connect" in Studio's Rojo plugin
3. Install [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) into `ServerStorage`
4. Replace placeholder `assetId` values in `ItemCatalog.luau` with Roblox asset IDs
5. Replace placeholder GamePass/DevProduct IDs in `Constants.luau`
6. Hit Play (F5) to test

## Project Structure (24 source files)

```
src/
├── ServerScriptService/           # Server (7 scripts)
│   ├── GameManager                # Remote creation, outfit equip, system init
│   ├── DataManager                # ProfileStore persistence + offline earnings
│   ├── EconomyManager             # Currency, purchases, fusion, prestige
│   ├── ContestManager             # 15-min runway contest state machine
│   ├── CustomerManager            # 16 NPC templates, spawning, scoring
│   ├── ProductHandler             # GamePass/DevProduct Robux monetization
│   └── DailyChallengeManager      # 3 daily challenges (easy/medium/hard)
│
├── ReplicatedStorage/Shared/      # Shared modules (6 modules)
│   ├── Types                      # All type definitions (13 types)
│   ├── Constants                  # Game balance + pricing
│   ├── ItemCatalog                # 50+ Asian fashion items
│   ├── ThemeCatalog               # 18 contest themes with tag scoring
│   ├── Utils                      # Helpers (XP, payments, formatting)
│   └── SoundManager               # BGM + SFX with volume control
│
├── ReplicatedStorage/Shared/UI/   # UI framework (8 modules)
│   ├── UILib                      # Component factory (720+ LOC)
│   ├── HUD                        # Currency, level, contest timer, nav bar
│   ├── ShopScreen                 # Category/style filters, item cards, buy modal
│   ├── WardrobeScreen             # 9 equipment slots, outfit save/load
│   ├── ContestScreen              # 6-phase contest UI
│   ├── BoutiqueScreen             # Stats, upgrade, customer queue
│   ├── ProfileScreen              # Stats grid, daily challenges, prestige
│   └── Notifications              # Toasts, daily reward, lucky box, level up
│
├── StarterPlayerScripts/          # Client (2 scripts)
│   ├── ClientController           # Master orchestrator, event→UI routing
│   └── CameraController           # Default/boutique/runway camera modes
│
└── StarterCharacterScripts/       # Character (1 script)
    └── CharacterAppearance        # Outfit visuals, runway walk animation
```

## Toolchain

| Tool | Version | Purpose |
|------|---------|---------|
| Rokit | 1.2.0 | Toolchain manager |
| Rojo | 7.4.0 | VS Code ↔ Studio sync |
| Wally | 0.3.2 | Package manager |
| Selene | 0.26.1 | Luau linter |
| StyLua | 0.20.0 | Code formatter |
| Darklua | 0.12.1 | Code processor |
| Luau LSP | 1.27.1 | VS Code IntelliSense |

## Packages (via Wally)

- **Knit** 1.6.0 — Game framework
- **Promise** 4.0.0 — Async patterns
- **Signal** 2.0.1 — Event system
- **Trove** 1.1.0 — Cleanup/disposal

## Key Systems

- **Tag-Based Scoring**: Items have tags, themes/customers have weighted desired tags. Same system drives both contests and customer satisfaction.
- **Dual Currency**: StyleCoins (earned) + GlamGems (premium). All transactions server-validated.
- **7 Boutique Tiers**: Market Stall → Fashion Empire. Each unlocks more customers, mannequins, earnings.
- **15-Minute Contest Cycle**: Theme → Dress (90s) → Runway → Vote (60s) → Results.
- **50+ Items**: K-fashion, J-fashion, SEA (batik, kebaya, baju kurung), formal. 5 rarity tiers.
- **Item Fusion**: Combine 3 same-tier items → 1 next-tier item.
- **Prestige**: At Level 100 + Fashion Empire, reset for permanent earnings multiplier (up to 5x).
- **Daily Challenges**: 3 challenges (easy/medium/hard) refreshed daily with SC + XP rewards.
- **Full UI**: Code-based UI system — no Studio ScreenGui work needed.

## Commands

```bash
rojo serve                        # Live sync to Studio
rojo build build.project.json -o game.rbxl  # Build .rbxl file
selene src/                       # Lint all code
stylua src/                       # Format all code
stylua --check src/               # Check formatting
wally install                     # Install/update packages
```

## Still Needed (in Studio)

1. **ProfileStore** — download from GitHub, place in ServerStorage
2. **3D models** — boutique building, runway stage, mannequins, NPCs
3. **Clothing textures** — design and upload to Roblox (fill `assetId` fields)
4. **GamePass/DevProduct IDs** — create in Studio, update `Constants.luau`
5. **Sound assets** — upload BGM + SFX, update `SoundManager.luau`
6. **Animations** — runway walk, shopping browse, celebration
