# Style Kingdom — Deploy & Test Guide

## 1. Local Studio Testing (F5)

### Option A: Open the built .rbxl directly
```bash
open StyleKingdom.rbxl   # Opens in Roblox Studio
```
Then press **F5** (Play) or **F8** (Play Here) to test.

### Option B: Live sync with Rojo (recommended for development)
```bash
# Terminal 1: Start Rojo server
rojo serve

# In Roblox Studio:
# 1. Install Rojo plugin from Creator Store (search "Rojo")
# 2. Click Rojo plugin → "Connect" → localhost:34872
# 3. All code changes sync instantly
# 4. Press F5 to test
```

**Before testing, you need:**
- Install [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) → drag into ServerScriptService
- The game will work without it but data won't persist

---

## 2. Publish to Roblox

### Step 1: Create the game on Roblox
1. Open `StyleKingdom.rbxl` in Roblox Studio
2. File → **Publish to Roblox**
3. Create new experience: "Style Kingdom"
4. Set to **Private** (don't make public yet)
5. Note the **Place ID** (shown in URL: `https://www.roblox.com/games/PLACE_ID`)

### Step 2: Configure game settings in Studio
1. **Game Settings → Access**:
   - Set to Private
   - Enable "Allow Private Servers" → set price to **0** (free private servers)

2. **Game Settings → Monetization**:
   - Create GamePasses (copy IDs from list below)
   - Create Developer Products (copy IDs from list below)
   - Update `Constants.luau` with the real IDs

3. **Game Settings → Basic Info**:
   - Genre: Role Playing
   - Max Players: 20
   - Devices: Computer, Phone, Tablet

### Step 3: Create GamePasses (in Studio → Monetization tab)

| GamePass | Price (R$) | Update in Constants.luau |
|----------|-----------|------------------------|
| Outfit Slots Plus | 49 | `GAME_PASSES.OUTFIT_SLOTS.id` |
| Extra Mannequins | 99 | `GAME_PASSES.EXTRA_MANNEQUINS.id` |
| Auto-Serve | 149 | `GAME_PASSES.AUTO_SERVE.id` |
| Double Income | 449 | `GAME_PASSES.DOUBLE_INCOME.id` |
| VIP Fashion Pass (Permanent) | 799 | `GAME_PASSES.VIP.id` |
| VIP Fashion Pass (Monthly) | 299 | `GAME_PASSES.VIP_MONTHLY.id` |
| Lucky Stylist | 1299 | `GAME_PASSES.LUCKY_STYLIST.id` |

### Step 4: Create Developer Products

| Product | Price (R$) | Update in Constants.luau |
|---------|-----------|------------------------|
| 100 GlamGems | 99 | `DEV_PRODUCTS.GG_100.id` |
| 500 GlamGems | 399 | `DEV_PRODUCTS.GG_500.id` |
| 1200 GlamGems | 799 | `DEV_PRODUCTS.GG_1200.id` |
| 3000 GlamGems | 1699 | `DEV_PRODUCTS.GG_3000.id` |
| 500 StyleCoins | 49 | `DEV_PRODUCTS.SC_500.id` |
| 2000 StyleCoins | 149 | `DEV_PRODUCTS.SC_2000.id` |
| 6000 StyleCoins | 399 | `DEV_PRODUCTS.SC_6000.id` |
| 15000 StyleCoins | 799 | `DEV_PRODUCTS.SC_15000.id` |
| Lucky Fashion Box | 49 | `DEV_PRODUCTS.LUCKY_BOX.id` |
| Instant Expand | 149 | `DEV_PRODUCTS.INSTANT_EXPAND.id` |

### Step 5: Publish updates
After updating Constants.luau with real IDs:
```bash
rojo build build.project.json -o StyleKingdom.rbxl
```
Then open in Studio → File → Publish to Roblox (overwrite existing)

---

## 3. Private Server for Testing

### Create a private server link:
1. Go to your game page: `roblox.com/games/YOUR_PLACE_ID`
2. Click **Servers** tab
3. Under "Private Servers" → Create Private Server
4. Set price to **Free** (0 Robux)
5. Copy the **join link** — share this with testers

### Invite testers:
- Share the private server link directly
- Testers join via the link on desktop or mobile
- Private server = only invited people can join

### Test with multiple accounts:
- Use alt Roblox accounts to simulate multiple players
- For contest testing: need 3+ accounts in the same server
- Open multiple Studio instances or use Roblox Player on separate devices

---

## 4. Mobile Testing

### Test on your own phone:
1. Publish the game to Roblox (Step 2 above)
2. Open **Roblox app** on your phone
3. Search for your game name or join via private server link
4. Test: touch targets, text readability, UI layout, performance

### Test on Studio's mobile emulator:
1. In Roblox Studio: View → **Device Emulator**
2. Select device (iPhone 14, Galaxy S22, iPad, etc.)
3. Press F5 to test with mobile viewport
4. Check: notch safe area, bottom nav bar, button sizes

### Key mobile checks:
- [ ] All buttons tappable (≥44px)
- [ ] Text readable on small screens
- [ ] No UI hidden behind notch/home indicator
- [ ] Shop filter buttons scrollable
- [ ] Contest voting cards large enough
- [ ] Toasts don't overlap with gameplay

---

## 5. Quick Checklist Before Going Public

- [ ] ProfileStore installed in ServerScriptService
- [ ] All GamePass IDs updated in Constants.luau (not 0)
- [ ] All DevProduct IDs updated in Constants.luau (not 0)
- [ ] Clothing asset IDs uploaded and set in ItemCatalog.luau
- [ ] Sound asset IDs uploaded and set in SoundManager.luau
- [ ] Game icon and thumbnails uploaded
- [ ] Game description written
- [ ] Tested on mobile (phone + tablet)
- [ ] Tested with 3+ players (contest system)
- [ ] Private server testing passed
- [ ] Set game to Public when ready to launch
