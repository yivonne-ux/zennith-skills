#!/usr/bin/env python3
"""
LOGO GRID BUILDER — Golden Ratio Construction Grids in SVG

Generate mathematical construction grids for logo design:
- Golden ratio circle overlays
- Fibonacci spiral
- Vesica piscis construction
- Root rectangle grid
- Modular grid with golden proportions

Usage:
    python3 logo-grid-builder.py --type golden-circles --size 1000 --output grid.svg
    python3 logo-grid-builder.py --type fibonacci-spiral --size 800
    python3 logo-grid-builder.py --type vesica-piscis --size 600
    python3 logo-grid-builder.py --type all --size 1000 --output all-grids.svg
"""

import svgwrite
import math
import argparse
import os

PHI = 1.6180339887
GRID_COLOR = "#C5A54E"  # Gold
GUIDE_COLOR = "#2D6A4F"  # Jade green
BG_COLOR = "#ffffff"
LIGHT_GRAY = "#e0e0e0"

def golden_ratio_circles(dwg, cx, cy, max_r, depth=8):
    """Draw overlapping golden ratio circles for logo construction."""
    g = dwg.g(id="golden-circles")

    radii = []
    r = max_r
    for i in range(depth):
        radii.append(r)
        r = r / PHI

    # Draw circles from largest to smallest
    for i, r in enumerate(radii):
        opacity = 0.15 + (i * 0.05)
        g.add(dwg.circle(
            center=(cx, cy), r=r,
            fill="none", stroke=GRID_COLOR,
            stroke_width=0.5, opacity=min(opacity, 0.6),
        ))

        # Label
        g.add(dwg.text(
            f"R{i+1}={r:.1f}",
            insert=(cx + r + 5, cy - 3),
            font_size="8px", fill=GRID_COLOR, opacity=0.4,
            font_family="monospace",
        ))

    # Offset circles for intersection-based construction
    for i, r in enumerate(radii[:4]):
        # Right offset
        g.add(dwg.circle(
            center=(cx + r/PHI, cy), r=r,
            fill="none", stroke=GUIDE_COLOR,
            stroke_width=0.3, opacity=0.15,
            stroke_dasharray="4,4",
        ))
        # Left offset
        g.add(dwg.circle(
            center=(cx - r/PHI, cy), r=r,
            fill="none", stroke=GUIDE_COLOR,
            stroke_width=0.3, opacity=0.15,
            stroke_dasharray="4,4",
        ))

    dwg.add(g)

def fibonacci_spiral(dwg, x, y, size, turns=8):
    """Draw Fibonacci spiral using quarter-circle arcs."""
    g = dwg.g(id="fibonacci-spiral")

    fib = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
    unit = size / sum(fib[:turns])

    cx, cy = x + size/2, y + size/2

    # Draw golden rectangles
    current_x, current_y = x, y
    for i in range(min(turns, len(fib))):
        side = fib[i] * unit
        rect_opacity = 0.08 + (i * 0.03)

        g.add(dwg.rect(
            insert=(current_x, current_y), size=(side, side),
            fill="none", stroke=GRID_COLOR,
            stroke_width=0.5, opacity=min(rect_opacity, 0.4),
        ))

        # Quarter circle arc in each square
        direction = i % 4
        if direction == 0:
            arc_cx, arc_cy = current_x + side, current_y + side
        elif direction == 1:
            arc_cx, arc_cy = current_x, current_y + side
        elif direction == 2:
            arc_cx, arc_cy = current_x, current_y
        else:
            arc_cx, arc_cy = current_x + side, current_y

        g.add(dwg.circle(
            center=(arc_cx, arc_cy), r=side,
            fill="none", stroke=GUIDE_COLOR,
            stroke_width=0.8, opacity=0.3,
        ))

        # Move to next position
        if direction == 0:
            current_x += side
        elif direction == 1:
            current_y += side
        elif direction == 2:
            current_x -= fib[min(i+1, len(fib)-1)] * unit
        else:
            current_y -= fib[min(i+1, len(fib)-1)] * unit

    dwg.add(g)

def vesica_piscis(dwg, cx, cy, r):
    """Draw vesica piscis construction — two overlapping circles."""
    g = dwg.g(id="vesica-piscis")

    # Two circles, each center on the other's circumference
    offset = r  # Centers are exactly r apart

    # Left circle
    g.add(dwg.circle(
        center=(cx - offset/2, cy), r=r,
        fill="none", stroke=GRID_COLOR,
        stroke_width=0.8, opacity=0.3,
    ))

    # Right circle
    g.add(dwg.circle(
        center=(cx + offset/2, cy), r=r,
        fill="none", stroke=GRID_COLOR,
        stroke_width=0.8, opacity=0.3,
    ))

    # The vesica piscis intersection points
    h = r * math.sqrt(3)  # Height of vesica
    g.add(dwg.line(
        start=(cx, cy - h/2), end=(cx, cy + h/2),
        stroke=GUIDE_COLOR, stroke_width=0.5, opacity=0.4,
        stroke_dasharray="3,3",
    ))

    # Highlight the vesica piscis shape
    # Using two arcs
    path_data = f"M {cx},{cy - h/2} "
    path_data += f"A {r},{r} 0 0,1 {cx},{cy + h/2} "
    path_data += f"A {r},{r} 0 0,1 {cx},{cy - h/2} Z"

    g.add(dwg.path(
        d=path_data,
        fill=GUIDE_COLOR, fill_opacity=0.05,
        stroke=GUIDE_COLOR, stroke_width=1, opacity=0.4,
    ))

    # Labels
    g.add(dwg.text(
        f"r = {r:.0f}", insert=(cx - offset/2, cy - r - 8),
        font_size="9px", fill=GRID_COLOR, opacity=0.5,
        font_family="monospace", text_anchor="middle",
    ))
    g.add(dwg.text(
        f"Vesica ratio: 1:√3 = 1:{math.sqrt(3):.4f}",
        insert=(cx, cy + h/2 + 20),
        font_size="9px", fill=GRID_COLOR, opacity=0.4,
        font_family="monospace", text_anchor="middle",
    ))

    dwg.add(g)

def root_rectangles(dwg, x, y, base_w):
    """Draw root rectangle system (√1 through √5 + golden)."""
    g = dwg.g(id="root-rectangles")

    rectangles = [
        ("√1 (square)", 1.0),
        ("√2 (A4/ISO)", math.sqrt(2)),
        ("√3 (vesica)", math.sqrt(3)),
        ("φ (golden)", PHI),
        ("√4 (2:1)", 2.0),
        ("√5", math.sqrt(5)),
    ]

    base_h = base_w * 0.5
    spacing = 10

    for i, (label, ratio) in enumerate(rectangles):
        rect_h = base_h
        rect_w = base_h * ratio

        rx = x + (i * (base_w / len(rectangles) + spacing))
        ry = y

        g.add(dwg.rect(
            insert=(rx, ry), size=(rect_w, rect_h),
            fill="none", stroke=GRID_COLOR,
            stroke_width=0.8, opacity=0.4,
        ))

        # Inner square reference
        g.add(dwg.rect(
            insert=(rx, ry), size=(rect_h, rect_h),
            fill="none", stroke=GUIDE_COLOR,
            stroke_width=0.3, opacity=0.2,
            stroke_dasharray="3,3",
        ))

        g.add(dwg.text(
            label, insert=(rx + rect_w/2, ry + rect_h + 15),
            font_size="8px", fill=GRID_COLOR, opacity=0.5,
            font_family="monospace", text_anchor="middle",
        ))
        g.add(dwg.text(
            f"1:{ratio:.4f}", insert=(rx + rect_w/2, ry + rect_h + 25),
            font_size="7px", fill=GRID_COLOR, opacity=0.3,
            font_family="monospace", text_anchor="middle",
        ))

    dwg.add(g)

def crosshair_grid(dwg, cx, cy, size):
    """Add crosshair guides and phi-grid lines."""
    g = dwg.g(id="guides", opacity=0.1)

    # Center crosshair
    g.add(dwg.line(start=(cx, 0), end=(cx, size), stroke=LIGHT_GRAY, stroke_width=0.5))
    g.add(dwg.line(start=(0, cy), end=(size, cy), stroke=LIGHT_GRAY, stroke_width=0.5))

    # Phi grid (38.2% and 61.8%)
    phi_lines = [size * 0.382, size * 0.618]
    for pos in phi_lines:
        g.add(dwg.line(start=(pos, 0), end=(pos, size), stroke=GRID_COLOR,
                       stroke_width=0.3, stroke_dasharray="6,6"))
        g.add(dwg.line(start=(0, pos), end=(size, pos), stroke=GRID_COLOR,
                       stroke_width=0.3, stroke_dasharray="6,6"))

    dwg.add(g)

def build_grid(grid_type, size=1000, output=None):
    """Build the specified grid type."""
    if output is None:
        output = f"logo-grid-{grid_type}.svg"

    dwg = svgwrite.Drawing(
        output,
        size=(f"{size}px", f"{size}px"),
        viewBox=f"0 0 {size} {size}",
    )

    cx, cy = size/2, size/2

    # Background
    dwg.add(dwg.rect(insert=(0, 0), size=(size, size), fill=BG_COLOR))

    # Always add crosshair
    crosshair_grid(dwg, cx, cy, size)

    if grid_type == "golden-circles" or grid_type == "all":
        golden_ratio_circles(dwg, cx, cy, size * 0.4)

    if grid_type == "fibonacci-spiral" or grid_type == "all":
        fibonacci_spiral(dwg, size * 0.1, size * 0.1, size * 0.8)

    if grid_type == "vesica-piscis" or grid_type == "all":
        vesica_piscis(dwg, cx, cy, size * 0.25)

    if grid_type == "root-rectangles":
        root_rectangles(dwg, size * 0.05, size * 0.3, size * 0.9)

    # Title
    dwg.add(dwg.text(
        f"Construction Grid: {grid_type}  |  φ = {PHI:.6f}  |  {size}×{size}",
        insert=(10, size - 10),
        font_size="9px", fill=GRID_COLOR, opacity=0.3,
        font_family="monospace",
    ))

    dwg.save()
    print(f"Built: {output} ({os.path.getsize(output) // 1024}KB)")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate logo construction grids")
    parser.add_argument("--type", default="golden-circles",
                        choices=["golden-circles", "fibonacci-spiral", "vesica-piscis",
                                 "root-rectangles", "all"],
                        help="Grid type")
    parser.add_argument("--size", type=int, default=1000, help="Canvas size in px")
    parser.add_argument("--output", help="Output SVG filename")
    args = parser.parse_args()

    output = args.output or f"logo-grid-{args.type}.svg"
    build_grid(args.type, args.size, output)
