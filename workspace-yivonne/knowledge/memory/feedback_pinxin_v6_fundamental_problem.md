---
name: Pinxin — Fundamental Problem Identified. Reference = Output Structure.
description: After 6 batch iterations, the core issue is clear: using food photo references for ALL designs produces food photo layouts for ALL designs. Need FORMAT-SPECIFIC references.
type: feedback
---

## The Fundamental Problem (after v1 through v6)

**Using food photography references for every design produces food photography layouts for every design.** No matter how creative the prompt text is, NANO's output is structurally determined by the reference image (Image 1).

### What Mirra does RIGHT:
- iPhone Notes ad → uses an actual iPhone Notes SCREENSHOT as reference
- Tinder swipe ad → uses an actual Tinder UI as reference
- Receipt comparison → uses an actual receipt layout as reference
- WhatsApp chat → uses a WhatsApp UI screenshot as reference
- Each design has a FORMAT-SPECIFIC reference that establishes the visual STRUCTURE

### What I did WRONG (6 batches):
- Used the same 5-6 food photography references for everything
- Wrote "make it look like WhatsApp" in the prompt but gave NANO a food photo as Image 1
- NANO always defaults to the reference's structure → food photo with text overlay every time
- Padded 4:5 to 9:16 = lazy cropping, not a complete 9:16 artwork

### The Fix (for next session):
1. **Find/create FORMAT-SPECIFIC references** for each design concept:
   - WhatsApp UI screenshot (real, 9:16)
   - Receipt/bill comparison layout (real, 9:16)
   - Calendar/planner design (real, 9:16)
   - Health app tracker UI (real, 9:16)
   - iPhone Notes screenshot (real, 9:16)
   - Premium product collection shot (real, 9:16)
   - Split-screen comparison (real, 9:16)
   - Overhead family table photo (real, 9:16)
   - Magazine/editorial food layout (real, 9:16)
   - Gift box unboxing (real, 9:16)

2. **All references must be 9:16 natively** — designed as complete artworks for the vertical canvas

3. **Each reference establishes a completely different visual structure** — NANO then fills in Pinxin's brand DNA, food, and copy

4. **Post-process: logo + grain ONLY** (proven in Mirra)

5. **Logo: emblem OR logotype only** — placed inside safe zone (center 1080×1080)

6. **Study Mirra's actual reference folder structure**: `mirra-ads-refs/Type_01` through `Type_17` — each type folder contains references matching that specific ad format

### Technical notes:
- NANO output ratio = reference image ratio. 9:16 ref → 9:16 output.
- Don't fight this — use it. The reference IS the layout DNA.
- Creative variety comes from REFERENCE variety, not prompt variety.
- Prompt describes content/copy. Reference describes structure/layout.
