#!/usr/bin/env python3
"""
DESIGN CRITIQUE ENGINE — World-Class Art Director Tool

Evaluates design work against art director quality standards.
Uses Claude Vision or Gemini Vision to analyze images.

Scores on 8 dimensions, provides specific feedback,
and rates overall readiness.

Usage:
    python3 design-critique.py image.png
    python3 design-critique.py logo.svg --brand jade-oracle
    python3 design-critique.py --dir ./exports/ --brand jade-oracle
"""

import os
import sys
import json
import base64
import argparse

CRITIQUE_PROMPT = """You are a world-class creative director with 30 years of experience.
You have the taste of Massimo Vignelli, the eye of Paul Rand, and the conviction of Cassandre.
You do NOT give polite feedback. You give HONEST, SPECIFIC, ACTIONABLE critique.

Evaluate this design on these 8 dimensions (score each 1-10):

1. CONCEPT STRENGTH — Is there ONE clear idea? Or is it trying to be multiple things?
2. EMOTIONAL RESONANCE — Does it make you FEEL something? What? Is that the right feeling for the brand?
3. DISTINCTIVENESS — Would you recognize this in a lineup of 100 competitors? What makes it unique?
4. CRAFT — Is the execution precise? Are there optical issues, alignment problems, weight inconsistencies?
5. RESTRAINT — Has anything unnecessary been included? What should be removed?
6. TIME RESISTANCE — Will this look dated in 5 years? What elements are trendy vs timeless?
7. SCALABILITY — Would this work at 16px (favicon) AND 16 feet (billboard)?
8. SYSTEMIC POTENTIAL — Can this generate 1,000 unique executions that all feel like the same brand?

For each dimension:
- Score (1-10)
- One sentence explanation
- One specific improvement suggestion

Then give:
- OVERALL SCORE (average of 8 dimensions)
- VERDICT: "Ship it" / "Refine it" / "Rethink it" / "Kill it"
- THE ONE THING that would improve this most
- What a designer at Pentagram would say about this in one sentence

Format as structured JSON:
{
  "scores": {
    "concept": {"score": N, "note": "...", "improve": "..."},
    ...
  },
  "overall_score": N,
  "verdict": "...",
  "one_thing": "...",
  "pentagram_take": "..."
}
"""

BRAND_CONTEXT = {
    "jade-oracle": {
        "feeling": "grounded wisdom, quiet power, earned luxury",
        "concept": "Luxury oracle house — the Byredo of divination",
        "audience": "Women 25-45, spiritually curious, aesthetically demanding, actual wealth",
        "colors": "Jade green #2D6A4F, gold #C5A54E, cream #F5F0E8, warm black #1A1714",
        "avoid": "Mystical cliches, purple gradients, crystal balls, sacred geometry as decoration, cosmic/galaxy, 3D renders",
        "references": "Aesop (restraint), Bottega (craft as identity), The Row (absence), Diptyque (heritage imperfection)",
    }
}

def encode_image(path):
    """Encode image to base64 for vision API."""
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def critique_with_fal(image_path, brand=None):
    """Use fal.ai vision model for critique."""
    import fal_client

    fal_key = os.environ.get("FAL_KEY")
    if not fal_key:
        # Try to load from known locations
        for env_file in ["~/.env", "~/Desktop/mirra-workflow/.env", "~/Desktop/video-compiler/.env"]:
            expanded = os.path.expanduser(env_file)
            if os.path.exists(expanded):
                with open(expanded) as f:
                    for line in f:
                        if line.startswith("FAL_KEY="):
                            os.environ["FAL_KEY"] = line.strip().split("=", 1)[1]
                            break

    prompt = CRITIQUE_PROMPT
    if brand and brand in BRAND_CONTEXT:
        ctx = BRAND_CONTEXT[brand]
        prompt += f"\n\nBRAND CONTEXT:\n"
        for k, v in ctx.items():
            prompt += f"- {k}: {v}\n"
        prompt += f"\nEvaluate this design specifically for the {brand} brand."

    # Encode image
    img_b64 = encode_image(image_path)
    ext = os.path.splitext(image_path)[1].lower()
    mime = {"png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg",
            "svg": "image/svg+xml", "webp": "image/webp"}.get(ext.lstrip("."), "image/png")

    try:
        result = fal_client.subscribe("fal-ai/any-llm/vision", arguments={
            "model": "google/gemini-2.5-flash",
            "prompt": prompt,
            "image_url": f"data:{mime};base64,{img_b64}",
        })
        return result.get("output", str(result))
    except Exception as e:
        return f"Vision API error: {e}"

def print_critique(result, image_path):
    """Print formatted critique."""
    print(f"\n{'='*60}")
    print(f"  DESIGN CRITIQUE: {os.path.basename(image_path)}")
    print(f"{'='*60}\n")

    try:
        # Try to parse as JSON
        if isinstance(result, str):
            # Find JSON in the response
            start = result.find("{")
            end = result.rfind("}") + 1
            if start >= 0 and end > start:
                data = json.loads(result[start:end])
            else:
                print(result)
                return
        else:
            data = result

        scores = data.get("scores", {})
        for dim, info in scores.items():
            score = info.get("score", "?")
            bar = "█" * score + "░" * (10 - score)
            print(f"  {dim:>20}  {bar}  {score}/10")
            print(f"  {'':>20}  {info.get('note', '')}")
            print(f"  {'':>20}  → {info.get('improve', '')}\n")

        overall = data.get("overall_score", "?")
        verdict = data.get("verdict", "?")
        print(f"  {'OVERALL':>20}  {'█' * int(overall)}{'░' * (10 - int(overall))}  {overall}/10")
        print(f"\n  VERDICT: {verdict}")
        print(f"  ONE THING: {data.get('one_thing', '?')}")
        print(f"  PENTAGRAM: \"{data.get('pentagram_take', '?')}\"")

    except (json.JSONDecodeError, TypeError):
        print(result)

    print()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Design critique engine")
    parser.add_argument("image", nargs="?", help="Image file to critique")
    parser.add_argument("--brand", help="Brand context (e.g., jade-oracle)")
    parser.add_argument("--dir", help="Critique all images in directory")
    parser.add_argument("--list-brands", action="store_true", help="List available brand contexts")
    args = parser.parse_args()

    if args.list_brands:
        print("Available brand contexts:")
        for brand, ctx in BRAND_CONTEXT.items():
            print(f"  {brand}: {ctx['concept']}")
        sys.exit(0)

    if args.dir:
        images = [f for f in os.listdir(args.dir)
                  if f.lower().endswith(('.png', '.jpg', '.jpeg', '.svg', '.webp'))]
        for img in sorted(images):
            path = os.path.join(args.dir, img)
            result = critique_with_fal(path, args.brand)
            print_critique(result, path)
    elif args.image:
        result = critique_with_fal(args.image, args.brand)
        print_critique(result, args.image)
    else:
        parser.print_help()
