# IG Character Gen — Scene Library & Reference Setup

## Scene Library (10 Categories)

### Daily Life (Western City)
1. Farmers market — browsing produce, holding flowers, reusable bag
2. Coffee shop — reading, latte art, window seat, morning light
3. Restaurant dinner — candlelit, wine, intimate, date night energy
4. Morning routine — bed journaling, tea, soft light, tank top
5. Cooking at home — modern kitchen, wine glass, herbs, apron over camisole
6. Rooftop sunset — city skyline, glass of wine, golden hour, wrap dress
7. Bookstore — browsing shelves, stack of books, cozy cardigan (open front)
8. Brunch — outdoor cafe, avocado toast, sunglasses pushed up, linen top
9. Park walk — autumn leaves or spring blooms, casual chic, crossbody bag
10. Yoga/stretching — living room, morning light, activewear, mat

### Spiritual (Subtle, Woven Into Life)
11. Crystal grid — living room table, casual outfit, arranging crystals
12. Tarot pull — kitchen counter, morning coffee, single card, contemplative
13. Meditation corner — modern apartment nook, cushion, candles, peaceful
14. Moon ritual — balcony at night, candles, journal, city lights behind
15. Oracle deck — couch, cozy blanket, cards spread, wine nearby

### Going Out
16. Art gallery — all black outfit, contemplative, white walls
17. Wine bar — bar stool, low-cut blouse, moody lighting, cocktail
18. Night out — city street, leather jacket over dress, heels, confident walk
19. Weekend market — vintage finds, sunhat, flowy dress, browsing stalls
20. Pilates/gym — leaving studio, smoothie in hand, athleisure, glow

## Reference Image Setup (from character-lock skill)

### Face Lock Protocol
- Face refs in slots 1-3 (highest priority)
- Body ref in slot 4-5
- Face refs must be >= 60% of total refs
- Duplicate primary face ref if needed for weight

### Recommended Ref Array (7 slots)
```
Slot 1: face-ref-1 (close-up, primary anchor)
Slot 2: face-ref-2 (different angle)
Slot 3: face-ref-3 (different lighting)
Slot 4: face-ref-1 (DUPLICATE for weight)
Slot 5: face-ref-2 (DUPLICATE for weight)
Slot 6: body-ref (fashion/figure reference)
Slot 7: [optional scene ref for specific setting]
```

### Prompt Ref Labeling
Always include at top of prompt:
```
Reference images 1-5 show the CHARACTER'S FACE — keep this EXACT face, bone structure, eyes, jawline, hair.
Reference image 6 shows BODY TYPE and FASHION STYLE only — apply this figure and clothing style.
Do NOT generate a different woman. This must be the SAME person from references 1-5.
```

## File Conventions

```
# Character spec
workspace/data/characters/{brand}/{character}/ig-spec.json

# Face refs (locked)
workspace/data/characters/{brand}/{character}/face-refs/

# Body ref
workspace/data/characters/{brand}/{character}/body-ref.jpg

# Generated IG content
workspace/data/images/{brand}/ig-library/{character}/YYYYMMDD_*.png

# Scene prompts used
workspace/data/characters/{brand}/{character}/ig-prompts.jsonl
```
