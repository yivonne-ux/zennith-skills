#!/usr/bin/env python3
"""
TYPOGRAPHY SCALE CALCULATOR — World-Class Art Director Tool

Generate mathematically harmonious type scales for any brand.
Supports: Golden Ratio, Perfect Fourth, Major Third, Minor Third,
          Perfect Fifth, Augmented Fourth, Custom ratio.

Also generates: line-heights, spacing, max-width recommendations.

Usage:
    python3 type-scale-calc.py --base 16 --scale golden
    python3 type-scale-calc.py --base 18 --scale perfect-fourth --output type-system.json
"""

import json
import argparse
import math

PHI = 1.6180339887

SCALES = {
    "minor-second":     {"ratio": 1.067, "feel": "Subtle, almost imperceptible. For dense UI."},
    "major-second":     {"ratio": 1.125, "feel": "Gentle. Good for body-heavy content."},
    "minor-third":      {"ratio": 1.200, "feel": "Balanced. The web's workhorse scale."},
    "major-third":      {"ratio": 1.250, "feel": "Confident. Clear hierarchy without drama."},
    "perfect-fourth":   {"ratio": 1.333, "feel": "Strong. Editorial, magazine-like pacing."},
    "augmented-fourth": {"ratio": 1.414, "feel": "√2. Mathematical precision. ISO paper proportions."},
    "perfect-fifth":    {"ratio": 1.500, "feel": "Bold jumps. High-contrast editorial."},
    "golden":           {"ratio": PHI,   "feel": "φ. Maximum natural harmony. Luxury standard."},
    "major-sixth":      {"ratio": 1.667, "feel": "Dramatic. Display-heavy, headline-forward."},
    "octave":           {"ratio": 2.000, "feel": "Extreme. Only for the most dramatic layouts."},
}

def generate_scale(base, ratio, steps_up=6, steps_down=2):
    """Generate type scale from base size."""
    sizes = {}

    names_down = ["micro", "caption"][-steps_down:]
    names_up = ["body", "large", "h4", "h3", "h2", "h1", "display", "hero"][:steps_up]

    all_names = names_down + names_up

    for i, name in enumerate(all_names):
        step = i - steps_down
        size = base * (ratio ** step)
        sizes[name] = round(size, 1)

    return sizes

def line_height_for_size(size):
    """Optimal line-height based on size.
    Larger text = tighter line-height. Smaller text = looser."""
    if size <= 14:
        return 1.8
    elif size <= 18:
        return 1.7
    elif size <= 24:
        return 1.6
    elif size <= 36:
        return 1.4
    elif size <= 48:
        return 1.25
    elif size <= 72:
        return 1.15
    else:
        return 1.05

def optimal_line_length(size):
    """Optimal line length in characters (45-75ch ideal)."""
    # Based on research: 2.5 alphabets (65 chars) is ideal
    # Wider type needs fewer chars per line
    if size <= 14:
        return {"min": 50, "ideal": 70, "max": 85}
    elif size <= 18:
        return {"min": 45, "ideal": 65, "max": 75}
    elif size <= 24:
        return {"min": 35, "ideal": 55, "max": 65}
    else:
        return {"min": 20, "ideal": 40, "max": 55}

def spacing_system(base):
    """Generate spacing system from base size."""
    fib = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
    unit = max(4, round(base / 4))  # Quarter of base as unit

    return {
        "unit": unit,
        "fibonacci": {f"{v}": v * unit for v in [1, 2, 3, 5, 8, 13, 21]},
        "8pt-grid": {f"{i}": i * 8 for i in range(1, 13)},
    }

def font_pairing_guide(scale_name):
    """Suggest font pairings based on scale character."""
    pairings = {
        "golden": {
            "luxury_serif": {
                "display": "Cormorant Garamond / Playfair Display / Instrument Serif",
                "body": "DM Sans Light / Inter Light / Suisse Intl",
                "accent": "Libre Caslon Text Italic",
                "feel": "Warm luxury. Jade Oracle territory.",
            },
            "editorial_serif": {
                "display": "Freight Display / Tiempos Headline / GT Sectra",
                "body": "Freight Text / Tiempos Text / GT Sectra Fine",
                "accent": "GT Sectra Fine Italic",
                "feel": "Intellectual, literary. Aesop territory.",
            },
            "modern_sans": {
                "display": "Neue Haas Grotesk / Suisse Intl / Aktiv Grotesk",
                "body": "Suisse Intl Book / Neue Haas Grotesk Text",
                "accent": "Suisse Intl Medium Italic",
                "feel": "Clean, confident. Stripe/Linear territory.",
            },
        },
        "perfect-fourth": {
            "editorial": {
                "display": "Canela / Noe Display / Austin",
                "body": "Atlas Grotesk / Graphik / Founders Grotesk",
                "feel": "Magazine editorial. Strong hierarchy.",
            },
        },
        "major-third": {
            "approachable": {
                "display": "Circular / Cera Pro / General Sans",
                "body": "Inter / DM Sans / Plus Jakarta Sans",
                "feel": "Friendly, modern. Tech/wellness territory.",
            },
        },
    }
    return pairings.get(scale_name, pairings["golden"])

def print_visual(base, scale_name, sizes):
    """Print visual scale representation."""
    ratio = SCALES[scale_name]["ratio"]
    feel = SCALES[scale_name]["feel"]

    print(f"\n{'='*65}")
    print(f"  TYPOGRAPHY SCALE")
    print(f"  Base: {base}px  |  Scale: {scale_name} ({ratio})")
    print(f"  Feel: {feel}")
    print(f"{'='*65}\n")

    for name, size in sizes.items():
        lh = line_height_for_size(size)
        line_length = optimal_line_length(size)
        bar = "█" * max(1, int(size / 4))
        print(f"  {name:>8}  {size:>6.1f}px  lh:{lh}  {bar}")

    print(f"\n  LINE HEIGHTS:")
    for name, size in sizes.items():
        lh = line_height_for_size(size)
        print(f"    {name:>8}: {size}px × {lh} = {round(size * lh, 1)}px")

    print(f"\n  OPTIMAL LINE LENGTH:")
    body_size = sizes.get("body", base)
    ll = optimal_line_length(body_size)
    print(f"    Body ({body_size}px): {ll['min']}-{ll['max']}ch (ideal: {ll['ideal']}ch)")
    print(f"    At {body_size}px: ~{round(ll['ideal'] * body_size * 0.5)}px max-width")

    print(f"\n  SPACING (Fibonacci × {max(4, round(base/4))}px unit):")
    sp = spacing_system(base)
    for k, v in sp["fibonacci"].items():
        print(f"    {k:>3}× = {v}px")

    print(f"\n  FONT PAIRING SUGGESTIONS:")
    pairings = font_pairing_guide(scale_name)
    for style, fonts in pairings.items():
        print(f"\n    [{style}]")
        for role, font in fonts.items():
            print(f"      {role:>8}: {font}")

    print()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate typography scale")
    parser.add_argument("--base", type=float, default=16, help="Base font size in px")
    parser.add_argument("--scale", default="golden", choices=list(SCALES.keys()),
                        help="Scale type")
    parser.add_argument("--ratio", type=float, help="Custom ratio (overrides --scale)")
    parser.add_argument("--output", help="Save JSON to file")
    parser.add_argument("--list", action="store_true", help="List all available scales")
    args = parser.parse_args()

    if args.list:
        print("\nAvailable scales:")
        for name, info in SCALES.items():
            print(f"  {name:>20}: {info['ratio']:.4f}  — {info['feel']}")
        sys.exit(0)

    if args.ratio:
        SCALES["custom"] = {"ratio": args.ratio, "feel": f"Custom ratio {args.ratio}"}
        scale_name = "custom"
    else:
        scale_name = args.scale

    ratio = SCALES[scale_name]["ratio"]
    sizes = generate_scale(args.base, ratio)

    print_visual(args.base, scale_name, sizes)

    if args.output:
        data = {
            "base": args.base,
            "scale": scale_name,
            "ratio": ratio,
            "sizes": sizes,
            "line_heights": {k: line_height_for_size(v) for k, v in sizes.items()},
            "spacing": spacing_system(args.base),
            "pairings": font_pairing_guide(scale_name),
        }
        with open(args.output, "w") as f:
            json.dump(data, f, indent=2)
        print(f"Saved: {args.output}")
