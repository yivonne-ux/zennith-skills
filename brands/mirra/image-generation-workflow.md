# MIRRA Image Generation Workflow (Lovart + Nano Banana Pro)

## Workflow Overview

1. Put reference image in **Lovart** to analyze
2. Paste **JSON prompt from Gemini** (with image analyzer to get JSON prompt with role instruction)
3. In Lovart: **Select reference image in canvas**
4. **Ctrl+click** to point specific parts of reference image to add comments in chat

---

## Prompt Templates

### 1. Four Hands Bento Photography

```json
{
  "shot": "9:16 vertical, straight-on eye-level shot with slight upward angle for depth",
  "visual_hook": "Four hands entering from each corner holding premium Mirra dishes, forming a clean symmetrical X composition",
  "subject": {
    "item": "inside eco kraft bowls",
    "position": "Top-left, top-right, bottom-left, bottom-right corners, angled slightly inward toward the center",
    "interaction": "Hands naturally holding bowls from underneath with relaxed but realistic grip. Bowls tilted 20–30 degrees toward camera. All elements must look photographed together, not composited. The final image should be fitting seamlessly together, no cut and paste in. Match the angle, colour, lighting and shadow."
  },
  "environment": "Solid Mirra Pink background (#F7AB9F), clean seamless studio backdrop with soft natural gradient falloff",
  "lighting": "Soft diffused studio lighting from upper-left, natural skin tones, soft but defined shadows beneath bowls and subtle cast shadows on background",
  "color_strategy": "Mirra Pink dominant background, natural food tones vibrant and realistic, warm balanced skin tones",
  "style_direction": "Premium editorial food photography, clean modern commercial campaign aesthetic",
  "rendering_quality": "Hyper-realistic photography, consistent light direction, accurate ambient occlusion under bowls and hands, crisp food textures, no cutout edges, high resolution"
}
```

### 2. Lifestyle Overhead Flat-Lay

```json
{
  "shot": "9:16 vertical, true overhead flat-lay shot, camera perfectly parallel to table surface",
  "visual_hook": "Three Mirra bentos arranged diagonally across frame creating natural movement and depth",
  "subject": {
    "item": "inside Mirra eco bento containers",
    "position": "One bento in top-left quadrant, one in right-middle area, one in bottom-left quadrant forming a loose triangle composition",
    "interaction": "Natural dining scene with fork and knife resting inside one box, chopsticks in another, subtle food disturbance to look realistically eaten. The final image should be fitting seamlessly together, no cut and paste in. Match the angle, colour, lighting and shadow."
  },
  "environment": "Dark walnut woodgrain tabletop surface with visible texture and warm tone. Linen napkin casually placed with soft folds. Minimal ceramic side dish and small glass cup as subtle props.",
  "lighting": "Strong directional sunlight from upper-left creating defined shadows and dramatic highlights. Warm golden hour tone with crisp shadow edges and natural contrast.",
  "color_strategy": "Warm wood base, neutral beige containers, vibrant food colors naturally popping against warm background. Balanced warmth without orange cast.",
  "style_direction": "High-end editorial food photography, lifestyle dining aesthetic, natural but elevated, not commercial stock look",
  "rendering_quality": "Hyper-realistic, high detail food texture, crisp micro-contrast, realistic ambient occlusion under containers and utensils, natural shadow falloff, high resolution, no cutout artifacts"
}
```

---

## Key Style Requirements

- **Background:** Mirra Pink (#F7AB9F) or Dark walnut wood grain
- **Composition:** Symmetrical X (4 hands), diagonal triangle (3 bentos)
- **Format:** 9:16 vertical (1080x1920px)
- **Style:** Premium editorial food photography, hyper-realistic
- **NO TEXT:** Pure product photography
- **Shadows:** Natural, consistent, no cut-and-paste look
- **Utensils:** Rose gold spoon & fork (no knife)

---

## Iteration Keywords

- Adjust spacing
- Different angle
- Warmer lighting
- Different arrangement
- Closer crop
- More props
- Tighter composition

---

## References

- Loom: https://www.loom.com/share/a6422114c3d14b5a9a1075d71d3b9a47
- Source Doc: https://docs.google.com/document/d/1XOgMbwHumQWCsxWUQ_a2dRwabLJpFJerkBIwqeHRMOY