#!/usr/bin/env python3
"""
JADE ORACLE — Logo Construction
Built with golden ratio geometry. Not generated — constructed.

The Mark: The Jade Disc (平安扣 ping'an kou)
Two concentric circles. Inner:Outer ratio = 1:φ (1:1.618)
The oldest jade jewelry form. Thousands of years. Protection + completeness.

The Logotype: "jade" in lowercase
The Lockup: disc left + text right, or disc above + text below
"""

import svgwrite
import math
import os

PHI = 1.6180339887  # Golden ratio
OUT = os.path.dirname(os.path.abspath(__file__))

# ── Brand Colors ──
JADE_GREEN = "#2D6A4F"
JADE_DARK = "#1B4332"
WARM_BLACK = "#1A1714"
CREAM = "#F5F0E8"
GOLD = "#C5A54E"
SAGE = "#8FA882"
BURGUNDY = "#722F37"

# ══════════════════════════════════════════════════════════════════
# 1. THE JADE DISC — Logomark
# ══════════════════════════════════════════════════════════════════

def build_jade_disc(filename, size=800, bg=None, color=JADE_GREEN, show_construction=False):
    """Construct the jade disc mark using golden ratio."""
    dwg = svgwrite.Drawing(
        os.path.join(OUT, filename),
        size=(f"{size}px", f"{size}px"),
        viewBox=f"0 0 {size} {size}",
    )

    cx, cy = size / 2, size / 2

    # Golden ratio proportions
    outer_r = size * 0.32          # Outer circle radius
    inner_r = outer_r / PHI        # Inner circle = outer / φ
    ring_width = outer_r - inner_r  # The jade ring width

    # Background
    if bg:
        dwg.add(dwg.rect(insert=(0, 0), size=(size, size), fill=bg))

    # Construction lines (optional — for presentation)
    if show_construction:
        construction = dwg.g(opacity=0.15)
        # Golden rectangle
        rect_w = outer_r * 2
        rect_h = rect_w / PHI
        construction.add(dwg.rect(
            insert=(cx - rect_w/2, cy - rect_h/2),
            size=(rect_w, rect_h),
            fill="none", stroke="#999", stroke_width=0.5,
            stroke_dasharray="4,4"
        ))
        # Construction circles
        for r in [outer_r, inner_r, outer_r / PHI / PHI]:
            construction.add(dwg.circle(
                center=(cx, cy), r=r,
                fill="none", stroke="#999", stroke_width=0.3,
                stroke_dasharray="2,4"
            ))
        # Cross hair
        construction.add(dwg.line(
            start=(cx, cy - outer_r * 1.3), end=(cx, cy + outer_r * 1.3),
            stroke="#999", stroke_width=0.3, stroke_dasharray="2,4"
        ))
        construction.add(dwg.line(
            start=(cx - outer_r * 1.3, cy), end=(cx + outer_r * 1.3, cy),
            stroke="#999", stroke_width=0.3, stroke_dasharray="2,4"
        ))
        # Phi annotation
        construction.add(dwg.text(
            f"φ = {PHI:.4f}", insert=(cx + outer_r + 10, cy),
            font_size="10px", fill="#999", font_family="monospace"
        ))
        construction.add(dwg.text(
            f"R = {outer_r:.1f}", insert=(cx + 5, cy - outer_r - 5),
            font_size="10px", fill="#999", font_family="monospace"
        ))
        construction.add(dwg.text(
            f"r = {inner_r:.1f} (R/φ)", insert=(cx + 5, cy - inner_r - 5),
            font_size="10px", fill="#999", font_family="monospace"
        ))
        dwg.add(construction)

    # The disc — outer circle with inner circle cut out (using mask)
    mask = dwg.defs.add(dwg.mask(id="disc-mask"))
    mask.add(dwg.rect(insert=(0, 0), size=(size, size), fill="white"))
    mask.add(dwg.circle(center=(cx, cy), r=inner_r, fill="black"))

    disc = dwg.g(mask="url(#disc-mask)")
    disc.add(dwg.circle(center=(cx, cy), r=outer_r, fill=color))
    dwg.add(disc)

    dwg.save()
    print(f"  Built: {filename}")


def build_logotype(filename, size=(1200, 400), bg=None, text_color=WARM_BLACK):
    """The word 'jade' as logotype — clean, lowercase, spaced."""
    w, h = size
    dwg = svgwrite.Drawing(
        os.path.join(OUT, filename),
        size=(f"{w}px", f"{h}px"),
        viewBox=f"0 0 {w} {h}",
    )

    if bg:
        dwg.add(dwg.rect(insert=(0, 0), size=(w, h), fill=bg))

    # "jade" in lowercase — using a web-safe serif that captures the vibe
    # In production this would be a custom or licensed typeface
    dwg.add(dwg.text(
        "jade",
        insert=(w / 2, h * 0.58),
        text_anchor="middle",
        font_family="'Cormorant Garamond', 'Georgia', serif",
        font_size="120px",
        font_weight="400",
        letter_spacing="18px",
        fill=text_color,
    ))

    dwg.save()
    print(f"  Built: {filename}")


def build_lockup_horizontal(filename, size=(1600, 500), bg=None,
                             disc_color=JADE_GREEN, text_color=WARM_BLACK):
    """Horizontal lockup: disc + jade + the oracle."""
    w, h = size
    dwg = svgwrite.Drawing(
        os.path.join(OUT, filename),
        size=(f"{w}px", f"{h}px"),
        viewBox=f"0 0 {w} {h}",
    )

    if bg:
        dwg.add(dwg.rect(insert=(0, 0), size=(w, h), fill=bg))

    # Disc on the left
    disc_cx = w * 0.18
    disc_cy = h * 0.48
    outer_r = h * 0.28
    inner_r = outer_r / PHI

    mask = dwg.defs.add(dwg.mask(id="lockup-mask"))
    mask.add(dwg.rect(insert=(0, 0), size=(w, h), fill="white"))
    mask.add(dwg.circle(center=(disc_cx, disc_cy), r=inner_r, fill="black"))

    disc = dwg.g(mask="url(#lockup-mask)")
    disc.add(dwg.circle(center=(disc_cx, disc_cy), r=outer_r, fill=disc_color))
    dwg.add(disc)

    # "jade" to the right
    text_x = w * 0.38
    dwg.add(dwg.text(
        "jade",
        insert=(text_x, h * 0.55),
        font_family="'Cormorant Garamond', 'Georgia', serif",
        font_size="110px",
        font_weight="400",
        letter_spacing="14px",
        fill=text_color,
    ))

    # "the oracle" smaller below
    dwg.add(dwg.text(
        "the oracle",
        insert=(text_x + 4, h * 0.72),
        font_family="'DM Sans', 'Helvetica Neue', sans-serif",
        font_size="22px",
        font_weight="300",
        letter_spacing="8px",
        fill=text_color,
        opacity=0.4,
    ))

    dwg.save()
    print(f"  Built: {filename}")


def build_lockup_stacked(filename, size=(800, 900), bg=None,
                          disc_color=JADE_GREEN, text_color=WARM_BLACK):
    """Stacked lockup: disc above, text below."""
    w, h = size
    dwg = svgwrite.Drawing(
        os.path.join(OUT, filename),
        size=(f"{w}px", f"{h}px"),
        viewBox=f"0 0 {w} {h}",
    )

    if bg:
        dwg.add(dwg.rect(insert=(0, 0), size=(w, h), fill=bg))

    # Disc centered, upper portion
    disc_cx = w / 2
    disc_cy = h * 0.38
    outer_r = w * 0.22
    inner_r = outer_r / PHI

    mask = dwg.defs.add(dwg.mask(id="stacked-mask"))
    mask.add(dwg.rect(insert=(0, 0), size=(w, h), fill="white"))
    mask.add(dwg.circle(center=(disc_cx, disc_cy), r=inner_r, fill="black"))

    disc = dwg.g(mask="url(#stacked-mask)")
    disc.add(dwg.circle(center=(disc_cx, disc_cy), r=outer_r, fill=disc_color))
    dwg.add(disc)

    # "jade" centered below disc
    dwg.add(dwg.text(
        "jade",
        insert=(w / 2, h * 0.72),
        text_anchor="middle",
        font_family="'Cormorant Garamond', 'Georgia', serif",
        font_size="90px",
        font_weight="400",
        letter_spacing="14px",
        fill=text_color,
    ))

    # "the oracle"
    dwg.add(dwg.text(
        "the oracle",
        insert=(w / 2, h * 0.82),
        text_anchor="middle",
        font_family="'DM Sans', 'Helvetica Neue', sans-serif",
        font_size="18px",
        font_weight="300",
        letter_spacing="7px",
        fill=text_color,
        opacity=0.4,
    ))

    dwg.save()
    print(f"  Built: {filename}")


def build_app_icon(filename, size=512, bg=WARM_BLACK, color=JADE_GREEN):
    """App icon / profile picture — disc mark only."""
    dwg = svgwrite.Drawing(
        os.path.join(OUT, filename),
        size=(f"{size}px", f"{size}px"),
        viewBox=f"0 0 {size} {size}",
    )

    # Background with rounded corners (app icon)
    dwg.add(dwg.rect(
        insert=(0, 0), size=(size, size),
        fill=bg, rx=size * 0.18, ry=size * 0.18
    ))

    cx, cy = size / 2, size / 2
    outer_r = size * 0.30
    inner_r = outer_r / PHI

    mask = dwg.defs.add(dwg.mask(id="icon-mask"))
    mask.add(dwg.rect(insert=(0, 0), size=(size, size), fill="white"))
    mask.add(dwg.circle(center=(cx, cy), r=inner_r, fill="black"))

    disc = dwg.g(mask="url(#icon-mask)")
    disc.add(dwg.circle(center=(cx, cy), r=outer_r, fill=color))
    dwg.add(disc)

    dwg.save()
    print(f"  Built: {filename}")


def build_card_back(filename, w=750, h=1125, bg=JADE_DARK, color=GOLD):
    """Oracle card back — disc mark centered, minimal."""
    dwg = svgwrite.Drawing(
        os.path.join(OUT, filename),
        size=(f"{w}px", f"{h}px"),
        viewBox=f"0 0 {w} {h}",
    )

    # Card background
    dwg.add(dwg.rect(insert=(0, 0), size=(w, h), fill=bg, rx=20, ry=20))

    # Thin border
    margin = 30
    dwg.add(dwg.rect(
        insert=(margin, margin),
        size=(w - margin * 2, h - margin * 2),
        fill="none", stroke=color, stroke_width=0.5, rx=12, ry=12,
        opacity=0.3
    ))

    # Disc mark centered
    cx, cy = w / 2, h / 2
    outer_r = w * 0.20
    inner_r = outer_r / PHI

    mask = dwg.defs.add(dwg.mask(id="card-mask"))
    mask.add(dwg.rect(insert=(0, 0), size=(w, h), fill="white"))
    mask.add(dwg.circle(center=(cx, cy), r=inner_r, fill="black"))

    disc = dwg.g(mask="url(#card-mask)")
    disc.add(dwg.circle(center=(cx, cy), r=outer_r, fill=color, opacity=0.6))
    dwg.add(disc)

    # Small "jade" text at bottom
    dwg.add(dwg.text(
        "jade",
        insert=(w / 2, h - 60),
        text_anchor="middle",
        font_family="'Cormorant Garamond', 'Georgia', serif",
        font_size="24px",
        font_weight="400",
        letter_spacing="8px",
        fill=color,
        opacity=0.3,
    ))

    dwg.save()
    print(f"  Built: {filename}")


# ══════════════════════════════════════════════════════════════════
# BUILD ALL VARIANTS
# ══════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("JADE ORACLE — Logo Construction")
    print("Golden ratio: φ =", PHI)
    print("=" * 50)

    # 1. Disc mark — standalone
    print("\n--- Logomark (Jade Disc) ---")
    build_jade_disc("jade-disc-green-white.svg", color=JADE_GREEN)
    build_jade_disc("jade-disc-green-black.svg", bg=WARM_BLACK, color=JADE_GREEN)
    build_jade_disc("jade-disc-gold-black.svg", bg=WARM_BLACK, color=GOLD)
    build_jade_disc("jade-disc-cream-jade.svg", bg=JADE_DARK, color=CREAM)
    build_jade_disc("jade-disc-construction.svg", show_construction=True, color=JADE_GREEN)

    # 2. Logotype — word only
    print("\n--- Logotype ---")
    build_logotype("jade-logotype-dark.svg", text_color=WARM_BLACK)
    build_logotype("jade-logotype-cream.svg", bg=WARM_BLACK, text_color=CREAM)
    build_logotype("jade-logotype-green.svg", text_color=JADE_GREEN)

    # 3. Horizontal lockup
    print("\n--- Horizontal Lockup ---")
    build_lockup_horizontal("jade-lockup-h-light.svg")
    build_lockup_horizontal("jade-lockup-h-dark.svg", bg=WARM_BLACK,
                            disc_color=JADE_GREEN, text_color=CREAM)
    build_lockup_horizontal("jade-lockup-h-gold.svg", bg=WARM_BLACK,
                            disc_color=GOLD, text_color=CREAM)

    # 4. Stacked lockup
    print("\n--- Stacked Lockup ---")
    build_lockup_stacked("jade-lockup-v-light.svg")
    build_lockup_stacked("jade-lockup-v-dark.svg", bg=WARM_BLACK,
                          disc_color=JADE_GREEN, text_color=CREAM)

    # 5. App icon
    print("\n--- App Icon ---")
    build_app_icon("jade-icon-dark.svg", bg=WARM_BLACK, color=JADE_GREEN)
    build_app_icon("jade-icon-jade.svg", bg=JADE_DARK, color=GOLD)
    build_app_icon("jade-icon-cream.svg", bg=CREAM, color=JADE_GREEN)

    # 6. Card back
    print("\n--- Oracle Card Back ---")
    build_card_back("jade-card-back.svg")
    build_card_back("jade-card-back-green.svg", bg=JADE_GREEN, color=CREAM)

    print("\n" + "=" * 50)
    print(f"All logos built in: {OUT}")
    print(f"Total files: {len([f for f in os.listdir(OUT) if f.endswith('.svg')])}")
