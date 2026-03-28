# Approved Foodporn Prompt — Visual Standard v1

Tested on 50 photos across 2 merchants. 47/50 passed QA on first attempt.
3 borderline failures auto-fixed with brightness boost.

## Quality Gate Thresholds
- Brightness: >180 (avg 210)
- Sharpness: >200 (avg 800)
- BG whiteness: >210 (avg 240)

## The Prompt

```
You are a world-class food photographer creating images for a premium food delivery app.

Look at this reference dish. Now REGENERATE it as the most MOUTH-WATERING, DELICIOUS-LOOKING food photography you can create.

MAKE THE FOOD LOOK INCREDIBLE:
- Sauce should be THICK, GLOSSY, and GLISTENING — catching the light with an oil sheen
- Prawns should be PLUMP, JUICY, bright coral-pink with a wet glistening sheen
- Noodles should look PERFECTLY COOKED — silky, glossy, each strand visible
- Vegetables should be CRISP and DEWY — like just picked, with tiny water droplets
- Fried items should be GOLDEN CRISPY with visible oil sheen — you can almost hear the crunch
- Egg yolk should be RICH GOLDEN — creamy and inviting
- Steam should be rising gently — the food is HOT and FRESH
- Every surface should have a subtle WET SHEEN — the food looks JUICY and MOIST

PHOTOGRAPHY SETUP:
- Clean modern white ceramic bowl/plate (no patterns, minimal, elegant)
- Pure white seamless background
- 45-degree angle, centered, filling 70% of frame
- Bright soft key light from upper-left with fill light
- Beautiful soft shadow underneath
- SHARP FOCUS everywhere — f/8, everything crisp, no blur
- Warm color temperature — slightly golden

FOR DRINKS: Use clean clear glass on white background, same 45-degree angle, condensation visible if cold.

THE FOOD MUST LOOK SO DELICIOUS THAT ANYONE WHO SEES THIS PHOTO WILL IMMEDIATELY WANT TO ORDER IT.

Think: Michelin restaurant menu photography meets GrabFood hero banner.
```

## Model
`gemini-2.5-flash-image` via Google AI API

## Post-Processing
- Smart crop to 800x800 (center, LANCZOS)
- Sharpness enhance +15%
- Color enhance +5%
- For failed brightness: PIL brightness +12%
