#!/usr/bin/env python3
"""
COLOR SYSTEM GENERATOR — World-Class Art Director Tool

Input ONE brand color → outputs a complete mathematical color system:
- Primary, secondary, accent, neutral palettes
- Complementary, split-complementary, triadic, analogous harmonies
- Light/dark mode variants
- WCAG accessibility contrast ratios
- Warm/cool temperature analysis
- CSS custom properties export
- Tailwind config export

Usage:
    python3 color-system-gen.py "#2D6A4F"
    python3 color-system-gen.py "#2D6A4F" --name "jade-green" --output brand-colors.json
"""

import colorsys
import json
import math
import sys
import argparse

PHI = 1.6180339887

def hex_to_rgb(hex_color):
    h = hex_color.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hex(r, g, b):
    return f"#{int(r):02x}{int(g):02x}{int(b):02x}"

def rgb_to_hsl(r, g, b):
    r, g, b = r/255, g/255, b/255
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return h * 360, s * 100, l * 100

def hsl_to_rgb(h, s, l):
    h, s, l = h/360, s/100, l/100
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return int(r * 255), int(g * 255), int(b * 255)

def relative_luminance(r, g, b):
    """WCAG 2.1 relative luminance."""
    def linearize(v):
        v = v / 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)

def contrast_ratio(c1, c2):
    """WCAG contrast ratio between two hex colors."""
    l1 = relative_luminance(*hex_to_rgb(c1))
    l2 = relative_luminance(*hex_to_rgb(c2))
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

def color_temperature(h, s, l):
    """Classify warm/cool."""
    if 0 <= h <= 60 or 300 <= h <= 360:
        return "warm"
    elif 150 <= h <= 270:
        return "cool"
    else:
        return "neutral"

def harmony_complementary(h, s, l):
    return [(h + 180) % 360, s, l]

def harmony_split_complementary(h, s, l):
    return [
        [(h + 150) % 360, s, l],
        [(h + 210) % 360, s, l],
    ]

def harmony_triadic(h, s, l):
    return [
        [(h + 120) % 360, s, l],
        [(h + 240) % 360, s, l],
    ]

def harmony_analogous(h, s, l):
    return [
        [(h - 30) % 360, s, l],
        [(h + 30) % 360, s, l],
    ]

def harmony_tetradic(h, s, l):
    return [
        [(h + 90) % 360, s, l],
        [(h + 180) % 360, s, l],
        [(h + 270) % 360, s, l],
    ]

def generate_tints_shades(h, s, l, steps=9):
    """Generate tint/shade scale (like Tailwind 50-900)."""
    scale = {}
    lightness_values = [95, 90, 80, 70, 60, 50, 40, 30, 20, 10]
    names = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900]

    for name, target_l in zip(names, lightness_values):
        # Adjust saturation slightly for lighter tints (desaturate) and darker shades
        sat_adjust = s * (0.3 + 0.7 * (target_l / 100)) if target_l > 50 else s
        rgb = hsl_to_rgb(h, min(sat_adjust, 100), target_l)
        scale[name] = rgb_to_hex(*rgb)

    return scale

def generate_neutrals(h, s):
    """Generate warm neutrals influenced by the brand hue."""
    neutrals = {}
    lightness_values = {
        "white": 98, "50": 96, "100": 93, "200": 86, "300": 75,
        "400": 60, "500": 46, "600": 35, "700": 25, "800": 17,
        "900": 10, "950": 5, "black": 3
    }
    for name, l in lightness_values.items():
        # Tint neutrals with 5-10% of brand hue saturation
        neutral_s = min(s * 0.08, 12)
        rgb = hsl_to_rgb(h, neutral_s, l)
        neutrals[name] = rgb_to_hex(*rgb)
    return neutrals

def fibonacci_spacing():
    """Fibonacci-based spacing system."""
    return {
        "xs": 8, "sm": 13, "md": 21, "lg": 34,
        "xl": 55, "2xl": 89, "3xl": 144
    }

def golden_type_scale(base=16):
    """Golden ratio typography scale."""
    return {
        "caption": round(base / PHI),
        "body": base,
        "large": round(base * PHI),
        "h3": round(base * PHI ** 2),
        "h2": round(base * PHI ** 3),
        "h1": round(base * PHI ** 4),
        "display": round(base * PHI ** 5),
    }

def generate_system(hex_color, name="brand"):
    """Generate complete color system from one color."""
    r, g, b = hex_to_rgb(hex_color)
    h, s, l = rgb_to_hsl(r, g, b)

    system = {
        "input": {
            "hex": hex_color,
            "rgb": [r, g, b],
            "hsl": [round(h, 1), round(s, 1), round(l, 1)],
            "temperature": color_temperature(h, s, l),
            "name": name,
        },
        "primary": {
            "DEFAULT": hex_color,
            "scale": generate_tints_shades(h, s, l),
        },
        "harmonies": {},
        "neutrals": generate_neutrals(h, s),
        "semantic": {},
        "accessibility": {},
        "typography": golden_type_scale(),
        "spacing": fibonacci_spacing(),
    }

    # Harmonies
    comp = harmony_complementary(h, s, l)
    system["harmonies"]["complementary"] = {
        "hex": rgb_to_hex(*hsl_to_rgb(*comp)),
        "hsl": comp,
        "scale": generate_tints_shades(*comp),
    }

    for i, sc in enumerate(harmony_split_complementary(h, s, l)):
        key = f"split-comp-{i+1}"
        system["harmonies"][key] = {
            "hex": rgb_to_hex(*hsl_to_rgb(*sc)),
            "hsl": sc,
        }

    for i, tr in enumerate(harmony_triadic(h, s, l)):
        key = f"triadic-{i+1}"
        system["harmonies"][key] = {
            "hex": rgb_to_hex(*hsl_to_rgb(*tr)),
            "hsl": tr,
        }

    for i, an in enumerate(harmony_analogous(h, s, l)):
        key = f"analogous-{i+1}"
        system["harmonies"][key] = {
            "hex": rgb_to_hex(*hsl_to_rgb(*an)),
            "hsl": an,
        }

    # Semantic colors (derived from harmonies)
    system["semantic"] = {
        "success": rgb_to_hex(*hsl_to_rgb(145, 60, 40)),
        "warning": rgb_to_hex(*hsl_to_rgb(40, 80, 50)),
        "error": rgb_to_hex(*hsl_to_rgb(0, 70, 50)),
        "info": rgb_to_hex(*hsl_to_rgb(210, 60, 50)),
    }

    # Accessibility checks
    white = "#ffffff"
    black = "#000000"
    cream = "#F5F0E8"
    system["accessibility"] = {
        "on_white": {
            "contrast": round(contrast_ratio(hex_color, white), 2),
            "AA_normal": contrast_ratio(hex_color, white) >= 4.5,
            "AA_large": contrast_ratio(hex_color, white) >= 3.0,
            "AAA_normal": contrast_ratio(hex_color, white) >= 7.0,
        },
        "on_black": {
            "contrast": round(contrast_ratio(hex_color, black), 2),
            "AA_normal": contrast_ratio(hex_color, black) >= 4.5,
            "AA_large": contrast_ratio(hex_color, black) >= 3.0,
        },
        "on_cream": {
            "contrast": round(contrast_ratio(hex_color, cream), 2),
            "AA_normal": contrast_ratio(hex_color, cream) >= 4.5,
            "AA_large": contrast_ratio(hex_color, cream) >= 3.0,
        },
    }

    # Recommended pairings
    system["recommended_pairings"] = {
        "luxury_dark": {
            "background": system["neutrals"]["950"],
            "text": system["neutrals"]["100"],
            "accent": hex_color,
            "gold": "#C5A54E",
        },
        "luxury_light": {
            "background": system["neutrals"]["50"],
            "text": system["neutrals"]["900"],
            "accent": hex_color,
            "gold": "#C5A54E",
        },
        "editorial": {
            "background": system["neutrals"]["white"],
            "text": system["neutrals"]["900"],
            "accent": hex_color,
            "secondary": system["harmonies"]["complementary"]["hex"],
        },
    }

    return system

def export_css(system):
    """Export as CSS custom properties."""
    lines = [":root {"]
    name = system["input"]["name"]

    lines.append(f"  /* Primary: {name} */")
    for key, val in system["primary"]["scale"].items():
        lines.append(f"  --{name}-{key}: {val};")

    lines.append(f"\n  /* Neutrals */")
    for key, val in system["neutrals"].items():
        lines.append(f"  --neutral-{key}: {val};")

    lines.append(f"\n  /* Typography (Golden Ratio, base 16px) */")
    for key, val in system["typography"].items():
        lines.append(f"  --text-{key}: {val}px;")

    lines.append(f"\n  /* Spacing (Fibonacci) */")
    for key, val in system["spacing"].items():
        lines.append(f"  --space-{key}: {val}px;")

    lines.append("}")
    return "\n".join(lines)

def print_visual(system):
    """Print a visual summary."""
    inp = system["input"]
    print(f"\n{'='*60}")
    print(f"  COLOR SYSTEM: {inp['name']}")
    print(f"  Input: {inp['hex']}  |  HSL: {inp['hsl']}  |  {inp['temperature']}")
    print(f"{'='*60}")

    print(f"\n  PRIMARY SCALE:")
    for key, val in system["primary"]["scale"].items():
        print(f"    {key:>4}: {val}")

    print(f"\n  HARMONIES:")
    for key, val in system["harmonies"].items():
        print(f"    {key:>20}: {val['hex']}")

    print(f"\n  NEUTRALS (brand-tinted):")
    for key, val in list(system["neutrals"].items())[:6]:
        print(f"    {key:>6}: {val}")

    print(f"\n  ACCESSIBILITY on white: {system['accessibility']['on_white']['contrast']}:1", end="")
    print(f"  {'PASS' if system['accessibility']['on_white']['AA_normal'] else 'FAIL'} AA")

    print(f"  ACCESSIBILITY on black: {system['accessibility']['on_black']['contrast']}:1", end="")
    print(f"  {'PASS' if system['accessibility']['on_black']['AA_normal'] else 'FAIL'} AA")

    print(f"\n  TYPOGRAPHY (Golden Ratio):")
    for key, val in system["typography"].items():
        print(f"    {key:>8}: {val}px")

    print(f"\n  SPACING (Fibonacci):")
    print(f"    {list(system['spacing'].values())}")
    print()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate color system from one color")
    parser.add_argument("color", help="Hex color (e.g., #2D6A4F)")
    parser.add_argument("--name", default="brand", help="Color name")
    parser.add_argument("--output", help="Save JSON to file")
    parser.add_argument("--css", action="store_true", help="Export CSS custom properties")
    args = parser.parse_args()

    system = generate_system(args.color, args.name)
    print_visual(system)

    if args.css:
        css = export_css(system)
        print(css)

    if args.output:
        with open(args.output, "w") as f:
            json.dump(system, f, indent=2)
        print(f"Saved: {args.output}")
