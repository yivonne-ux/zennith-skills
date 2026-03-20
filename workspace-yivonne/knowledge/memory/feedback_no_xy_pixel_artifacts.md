---
name: No x/y pixel coordinate text in outputs
description: NANO sometimes renders literal "x:350" or "y:1240" coordinate text from the prompt into the artwork. Must phrase safe zones as natural language, never raw coordinates.
type: feedback
---

## Pixel coordinate leak (2026-03-12)

User: "there are appearance of x and y pixel words in some artwork"

NANO is rendering the literal coordinate text from the logo safe zone instruction.
Instead of "x:350 to x:730, y:1240 to y:1350", use natural language:
"Leave the bottom center area completely empty — no text, graphics, or decoration in the lower strip where a logo would typically sit."

Never include raw pixel values (x:, y:, px, 1080, 1350) in NANO prompts.
