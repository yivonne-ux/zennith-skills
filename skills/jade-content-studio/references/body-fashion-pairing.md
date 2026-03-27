## 4. Body-Fashion Pairing (Vibe Matching)

Tested with 8 Luna variants in production (scores 6-9/10). The vibe matching system is the key to consistent output.

### 4.1 Vibe Classification System

Classify BOTH face ref and body ref by vibe before pairing:

| Vibe | Face Signals | Body Ref Signals |
|------|-------------|-----------------|
| **Spiritual** | Serene expression, natural makeup, candle/crystal setting | Meditation pose, white/cream linen, incense, candles, gold bangles, barefoot |
| **Edgy/Street** | Confident gaze, minimal setting, urban background | B&W photography, tee + jeans, leather, standing/leaning, film grain |
| **Warm/Lifestyle** | Warm smile, cozy setting, natural light, bookshelf | Cardigan, blouse + trousers, books, warm window light, seated relaxed |
| **Editorial/Minimal** | Sharp features, pulled-back hair, clean background | Jumpsuit, structured bags, heels, stone/concrete, clean lines, sunglasses |
| **Boho/Oracle** | Dreamy, flowing hair, earth-toned setting | Kaftan, flowy dress, outdoor garden, statement earrings, barefoot |

### 4.2 The Cardinal Rule: MATCH VIBES

```
GOOD:  Spiritual face + Spiritual body = consistent character (9/10)
GOOD:  Editorial face + Editorial body = consistent character (9/10)
BAD:   Editorial face + Boho body = model confused, loses face OR outfit (6/10)
BAD:   Edgy face + Spiritual body = uncanny mismatch
```

Each face gets exactly 2 body pairings — enough variety without diluting consistency.

### 4.3 Jade's Vibe: Warm/Lifestyle + Spiritual

Jade naturally falls into the warm/lifestyle and spiritual vibes. Her body refs should match:
- Warm cafe settings, cozy apartments, natural light
- Meditation corners, candlelit reading rooms
- Morning routines, journaling, tea

Do NOT pair Jade with edgy/street or editorial/minimal body refs — it breaks her character.

### 4.4 Lens Guide by Shot Type (Migrated from character-body-pairing)

| Shot | Lens | Notes |
|------|------|-------|
| Full body standing/walking | 35mm f/1.8 | Shows environment |
| Medium shot seated | 50mm f/1.4 | Balanced |
| Close portrait + body | 85mm f/1.4 | Flattering compression |
| Editorial fashion | 50mm f/1.4 | Clean, minimal distortion |

### 4.5 Fashion Language That Works

The model ignores numeric measurements ("34-24-35" means nothing). Use fashion/editorial vocabulary:

**WORKS:**
- "decolletage", "silk following every curve", "form-fitting knit hugging her full bust"
- "deep V-neck showing her decolletage, the fabric draping over her naturally full bust"
- "fitted slip dress following her hourglass curves, thin straps showing toned shoulders"
- "oversized oatmeal cashmere cardigan draped off one shoulder"

**DOES NOT WORK:**
- "34D bust", "36-24-36", "115 lbs" — model ignores all of these

### 4.5 Production Results Log

| Face | Body Ref | Vibe Match | Score | Notes |
|------|----------|------------|-------|-------|
| Luna-Wise-C | meditation-incense | spiritual→spiritual | 9/10 | Perfect. Sage pants, golden light, incense smoke |
| Luna-Wise-C | linen-kneeling | spiritual→spiritual | 9/10 | Gold bangles carried over perfectly |
| Luna-Chic-H | bw-tee-jeans | edgy→edgy | 7/10 | B&W prompt refused; retry with "documentary style" worked |
| Luna-Chic-H | polkadot-dress | edgy→casual_cool | 8/10 | Polka dot matched well, platinum updo maintained |
| Luna-Blonde-A | blouse-elegant | warm→warm | 9/10 | Parisian apartment feel nailed |
| Luna-Blonde-A | cardigan-book | warm→intellectual | 9/10 | Camel cardigan, Shakespeare book carried from ref |
| Luna-Chic-C | olive-jumpsuit | editorial→editorial | 9/10 | Silver-grey hair maintained, all accessories matched |
| Luna-Chic-C | olive-vneck-street | editorial→street_chic | 6/10 | FAILURE: body ref dark hair overrode silver-grey hair |

---
