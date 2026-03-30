# Programmatic Design: Comprehensive Technical Guide
## Professional-Quality Design Generation with Code

*Researched March 2026. Directly applicable to the Bloom & Bare production pipeline.*

---

## Table of Contents

1. [Python/Pillow Advanced Text Rendering](#1-pythonpillow-advanced-text-rendering)
2. [Advanced Compositing & Color Grading](#2-advanced-compositing--color-grading)
3. [Shape Drawing & Pattern Generation](#3-shape-drawing--pattern-generation)
4. [Image Effects Library](#4-image-effects-library)
5. [DrawBot for Design](#5-drawbot-for-design)
6. [Cairo/PyCairo for Design](#6-cairopycairo-for-design)
7. [SVG Generation](#7-svg-generation)
8. [Professional Design Automation Tools](#8-professional-design-automation-tools)
9. [Batch Production Patterns](#9-batch-production-patterns)
10. [Generative Art Techniques](#10-generative-art-techniques)
11. [Tool Comparison Matrix](#11-tool-comparison-matrix)

---

## 1. Python/Pillow Advanced Text Rendering

### 1.1 Kerning & Character Spacing

**Problem:** Pillow disregards kerning tables in font files by default. The `spacing` parameter only controls line spacing, not letter spacing.

**Solution A — Enable Raqm layout engine:**
```python
from PIL import ImageFont

# Raqm provides proper OpenType kerning via HarfBuzz
font = ImageFont.truetype("MabryPro-Bold.ttf", size=48,
                          layout_engine=ImageFont.Layout.RAQM)
# Now kerning pairs are respected automatically
```

**Requirements for Raqm:** Install libraqm, HarfBuzz, and FriBidi. Check availability:
```python
from PIL import features
print(features.check_feature("raqm"))  # True if available
```

**Solution B — Manual character-by-character positioning:**
```python
from PIL import Image, ImageDraw, ImageFont

def draw_text_with_tracking(draw, position, text, font, fill, tracking=0):
    """Draw text with custom letter-spacing (tracking).
    tracking: extra pixels between each character (can be negative)."""
    x, y = position
    for char in text:
        draw.text((x, y), char, font=font, fill=fill)
        bbox = font.getbbox(char)
        char_width = bbox[2] - bbox[0]
        x += char_width + tracking

# Usage
img = Image.new("RGBA", (1080, 1350), (245, 240, 232, 255))
draw = ImageDraw.Draw(img)
font = ImageFont.truetype("DXLactos.ttf", 72)
draw_text_with_tracking(draw, (100, 100), "BLOOM & BARE", font, "#1A1A1A", tracking=4)
```

### 1.2 Drop Shadows on Text

```python
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def draw_text_with_shadow(img, position, text, font, text_color,
                          shadow_color=(0, 0, 0, 80),
                          shadow_offset=(4, 4), shadow_blur=6):
    """Render text with a soft drop shadow."""
    # Create shadow layer
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)

    # Draw shadow text at offset position
    sx = position[0] + shadow_offset[0]
    sy = position[1] + shadow_offset[1]
    shadow_draw.text((sx, sy), text, font=font, fill=shadow_color)

    # Blur the shadow
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=shadow_blur))

    # Composite shadow onto image
    img = Image.alpha_composite(img, shadow)

    # Draw actual text on top
    text_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    text_draw = ImageDraw.Draw(text_layer)
    text_draw.text(position, text, font=font, fill=text_color)
    img = Image.alpha_composite(img, text_layer)

    return img
```

**Key parameters to tune:**
- `shadow_offset`: (4, 4) for subtle, (8, 8) for dramatic
- `shadow_blur`: 4-6 for tight, 10-15 for diffuse
- `shadow_color`: Use alpha channel for opacity — `(0, 0, 0, 60)` = 24% opacity black

### 1.3 Gradient Text Fill (Mask Compositing)

```python
from PIL import Image, ImageDraw, ImageFont

def draw_gradient_text(size, text, font, color_top, color_bottom, position=(0, 0)):
    """Render text filled with a vertical gradient."""
    # Get text dimensions
    temp = Image.new("RGBA", (1, 1))
    temp_draw = ImageDraw.Draw(temp)
    bbox = temp_draw.textbbox(position, text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]

    # Create vertical gradient image
    gradient = Image.new("RGB", (tw, th))
    for y in range(th):
        ratio = y / th
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * ratio)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * ratio)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * ratio)
        for x in range(tw):
            gradient.putpixel((x, y), (r, g, b))

    # Render text as alpha mask
    mask = Image.new("L", (tw, th), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.text((0, 0), text, font=font, fill=255)

    # Compose: gradient visible only where text mask is white
    result = Image.new("RGBA", size, (0, 0, 0, 0))
    text_img = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    text_img.paste(gradient, (0, 0), mask)
    result.paste(text_img, position, text_img)
    return result
```

**Performance tip:** For large images, use NumPy to generate the gradient:
```python
import numpy as np
gradient_array = np.linspace(color_top, color_bottom, th, dtype=np.uint8)
gradient_array = np.tile(gradient_array[:, np.newaxis, :], (1, tw, 1))
gradient = Image.fromarray(gradient_array, "RGB")
```

### 1.4 Outlined / Stroked Text

**Native support since Pillow 6.2.0:**
```python
draw.text((x, y), "PLAY TIME",
          font=font,
          fill=(255, 255, 255),        # Inner fill color
          stroke_width=3,               # Outline thickness in pixels
          stroke_fill=(26, 26, 26))     # Outline color
```

**Multi-color stroke trick** (outer stroke + inner stroke + fill):
```python
# Draw outer stroke first (thicker)
draw.text((x, y), text, font=font, fill=outer_color, stroke_width=6, stroke_fill=outer_color)
# Draw inner stroke
draw.text((x, y), text, font=font, fill=inner_color, stroke_width=3, stroke_fill=inner_color)
# Draw fill text last
draw.text((x, y), text, font=font, fill=fill_color)
```

### 1.5 CJK Text Rendering (Chinese/Japanese/Korean)

**Critical:** Pillow has NO font fallback mechanism. A single font file must contain ALL glyphs needed.

**Solution for bilingual EN/CN content (Bloom & Bare):**
```python
# Use Noto Sans SC for Chinese text — must be a single .ttf/.otf with all needed glyphs
font_cn = ImageFont.truetype("NotoSansSC-Regular.otf", 36)
font_en = ImageFont.truetype("MabryPro-Regular.ttf", 36)

def draw_bilingual_text(draw, position, en_text, cn_text, font_en, font_cn, fill, spacing=8):
    """Draw English and Chinese text side by side with correct fonts."""
    x, y = position
    draw.text((x, y), en_text, font=font_en, fill=fill)
    en_width = draw.textlength(en_text, font=font_en)
    draw.text((x + en_width + spacing, y), cn_text, font=font_cn, fill=fill)
```

**Alternative: Use Source Han Sans** — covers Latin + CJK in one file (15MB+), so both languages can use the same font object.

### 1.6 Variable Font Support

```python
font = ImageFont.truetype("MabryPro-Variable.ttf", 48)

# Query available variation axes
axes = font.get_variation_axes()
# Returns: [{'tag': 'wght', 'name': 'Weight', 'minimum': 100, 'default': 400, 'maximum': 900}, ...]

# Set by axis values
font.set_variation_by_axes([700])  # Set weight to 700

# Or set by named instance
names = font.get_variation_names()  # ['Light', 'Regular', 'Bold', ...]
font.set_variation_by_name("Bold")
```

### 1.7 Text Auto-Sizing & Word Wrap

```python
import textwrap

def auto_size_text(text, font_path, max_width, max_height, max_font_size=120, min_font_size=16):
    """Find the largest font size that fits text within a bounding box."""
    for size in range(max_font_size, min_font_size - 1, -2):
        font = ImageFont.truetype(font_path, size)
        # Estimate characters per line
        avg_char_width = font.getlength("M")
        chars_per_line = max(1, int(max_width / avg_char_width))
        wrapped = textwrap.fill(text, width=chars_per_line)

        # Measure actual rendered size
        temp = Image.new("RGB", (1, 1))
        temp_draw = ImageDraw.Draw(temp)
        bbox = temp_draw.multiline_textbbox((0, 0), wrapped, font=font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]

        if text_w <= max_width and text_h <= max_height:
            return font, wrapped, size
    return ImageFont.truetype(font_path, min_font_size), textwrap.fill(text, width=20), min_font_size

def word_wrap_text(text, font, max_width):
    """Wrap text word-by-word to fit within max_width pixels."""
    words = text.split()
    lines = []
    current_line = ""
    for word in words:
        test_line = f"{current_line} {word}".strip()
        if font.getlength(test_line) <= max_width:
            current_line = test_line
        else:
            if current_line:
                lines.append(current_line)
            current_line = word
    if current_line:
        lines.append(current_line)
    return "\n".join(lines)
```

### 1.8 Text Along a Curved Path

Pillow has NO native curved-text support. Manual implementation required:

```python
import math

def draw_text_on_arc(img, text, font, center, radius, start_angle, fill):
    """Draw text along a circular arc path."""
    draw = ImageDraw.Draw(img)
    # Calculate angular width of each character
    char_angles = []
    for char in text:
        char_width = font.getlength(char)
        angle = char_width / radius  # arc length to angle (radians)
        char_angles.append(angle)

    total_angle = sum(char_angles)
    current_angle = start_angle - total_angle / 2  # Center the text

    for i, char in enumerate(text):
        # Calculate position on arc
        x = center[0] + radius * math.cos(current_angle)
        y = center[1] + radius * math.sin(current_angle)

        # Create rotated character image
        char_img = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
        char_draw = ImageDraw.Draw(char_img)
        char_draw.text((20, 20), char, font=font, fill=fill)

        # Rotate to match arc tangent
        rotation = -math.degrees(current_angle + math.pi / 2)
        char_img = char_img.rotate(rotation, expand=True, resample=Image.BICUBIC)

        # Paste onto main image
        paste_x = int(x - char_img.width / 2)
        paste_y = int(y - char_img.height / 2)
        img.paste(char_img, (paste_x, paste_y), char_img)

        current_angle += char_angles[i]
    return img
```

### 1.9 OpenType Features

```python
# Requires Raqm layout engine
font = ImageFont.truetype("MabryPro-Regular.ttf", 48,
                          layout_engine=ImageFont.Layout.RAQM)
draw = ImageDraw.Draw(img)

# Enable stylistic alternates
draw.text((x, y), text, font=font, fill=color, features=["ss01"])

# Enable discretionary ligatures
draw.text((x, y), text, font=font, fill=color, features=["dlig"])

# Disable default kerning
draw.text((x, y), text, font=font, fill=color, features=["-kern"])

# Multiple features
draw.text((x, y), text, font=font, fill=color, features=["ss01", "dlig", "smcp"])
```

---

## 2. Advanced Compositing & Color Grading

### 2.1 Blending Modes in Pillow

**Built-in (ImageChops module):**
```python
from PIL import ImageChops

result = ImageChops.multiply(base, overlay)      # Darken
result = ImageChops.screen(base, overlay)         # Lighten
result = ImageChops.soft_light(base, overlay)     # Subtle contrast
result = ImageChops.hard_light(base, overlay)     # Strong contrast
result = ImageChops.overlay(base, overlay)        # Mid-tone contrast
result = ImageChops.add(base, overlay, scale=2)   # Additive
result = ImageChops.difference(base, overlay)     # Difference
```

**Extended blending with `blend-modes` package:**
```python
# pip install blend-modes
import numpy as np
from blend_modes import soft_light, multiply, screen, overlay, dodge, addition

# Convert PIL images to float numpy arrays (H, W, 4) in RGBA order
bg = np.array(base_img.convert("RGBA")).astype(float)
fg = np.array(overlay_img.convert("RGBA")).astype(float)

# Apply blend mode with opacity
blended = soft_light(bg, fg, opacity=0.6)

# Convert back to PIL
result = Image.fromarray(blended.astype(np.uint8))
```

**Manual Photoshop-style blending (NumPy):**
```python
import numpy as np

def blend_multiply(base, overlay, opacity=1.0):
    """Photoshop Multiply blend mode."""
    b = np.array(base).astype(float) / 255
    o = np.array(overlay).astype(float) / 255
    result = b * o
    result = b * (1 - opacity) + result * opacity  # Apply opacity
    return Image.fromarray((result * 255).astype(np.uint8))

def blend_screen(base, overlay, opacity=1.0):
    """Photoshop Screen blend mode."""
    b = np.array(base).astype(float) / 255
    o = np.array(overlay).astype(float) / 255
    result = 1 - (1 - b) * (1 - o)
    result = b * (1 - opacity) + result * opacity
    return Image.fromarray((result * 255).astype(np.uint8))

def blend_overlay(base, overlay, opacity=1.0):
    """Photoshop Overlay blend mode."""
    b = np.array(base).astype(float) / 255
    o = np.array(overlay).astype(float) / 255
    mask = b < 0.5
    result = np.where(mask, 2 * b * o, 1 - 2 * (1 - b) * (1 - o))
    result = b * (1 - opacity) + result * opacity
    return Image.fromarray((result * 255).astype(np.uint8))

def blend_soft_light(base, overlay, opacity=1.0):
    """Photoshop Soft Light blend mode (W3C formula)."""
    b = np.array(base).astype(float) / 255
    o = np.array(overlay).astype(float) / 255
    mask = o <= 0.5
    result = np.where(
        mask,
        b - (1 - 2 * o) * b * (1 - b),
        b + (2 * o - 1) * (np.where(b <= 0.25,
                                      ((16 * b - 12) * b + 4) * b,
                                      np.sqrt(b)) - b)
    )
    result = b * (1 - opacity) + result * opacity
    return Image.fromarray((result * 255).astype(np.uint8))
```

### 2.2 S-Curve Color Grading with Lookup Tables

```python
import numpy as np
from PIL import Image

def make_s_curve_lut(strength=0.5):
    """Generate an S-curve lookup table for contrast enhancement.
    strength: 0.0 = no effect, 1.0 = maximum S-curve."""
    x = np.linspace(0, 1, 256)
    # Attempt a sigmoid-like S-curve
    midpoint = 0.5
    # Use a modified sine curve for natural S-shape
    curved = 0.5 + 0.5 * np.sin(np.pi * (x - 0.5)) * strength + x * (1 - strength)
    curved = np.clip(curved * 255, 0, 255).astype(np.uint8)
    return list(curved)

def apply_s_curve(img, strength=0.5):
    """Apply S-curve contrast to an RGB image."""
    lut = make_s_curve_lut(strength)
    # Apply same LUT to R, G, B channels
    return img.point(lut * 3)  # Repeat LUT for each channel

# More precise: per-channel control
def apply_color_curves(img, r_lut=None, g_lut=None, b_lut=None):
    """Apply separate lookup tables to each channel."""
    identity = list(range(256))
    r_lut = r_lut or identity
    g_lut = g_lut or identity
    b_lut = b_lut or identity
    return img.point(r_lut + g_lut + b_lut)
```

**Using `pillow-lut-tools` for 3D LUTs:**
```python
# pip install pillow-lut
from pillow_lut import load_cube_file, load_hald_image

# Load a .cube LUT file (standard color grading format)
lut = load_cube_file("film_emulation.cube")
graded = img.filter(lut)

# Load from Hald image (generated by e.g. darktable)
lut = load_hald_image("hald_clut.png")
graded = img.filter(lut)

# Generate LUT from basic color settings
from pillow_lut import rgb_color_enhance
lut = rgb_color_enhance(
    11,                    # LUT size
    brightness=0.05,       # -1.0 to 1.0
    contrast=0.1,          # -1.0 to 1.0
    warmth=0.08,           # -1.0 to 1.0
    saturation=0.15,       # -1.0 to 1.0
    vibrance=0.1,          # -1.0 to 1.0
)
graded = img.filter(lut)
```

### 2.3 Gradient Overlays

```python
import numpy as np
from PIL import Image

def create_linear_gradient(width, height, color_top, color_bottom, direction="vertical"):
    """Create a gradient image. direction: vertical, horizontal, or diagonal."""
    arr = np.zeros((height, width, 4), dtype=np.uint8)

    for i in range(4):  # RGBA
        if direction == "vertical":
            col = np.linspace(color_top[i], color_bottom[i], height, dtype=np.uint8)
            arr[:, :, i] = col[:, np.newaxis]
        elif direction == "horizontal":
            row = np.linspace(color_top[i], color_bottom[i], width, dtype=np.uint8)
            arr[:, :, i] = row[np.newaxis, :]

    return Image.fromarray(arr, "RGBA")

# Example: dark-to-transparent gradient overlay for text readability
gradient = create_linear_gradient(
    1080, 1350,
    color_top=(0, 0, 0, 0),       # Transparent at top
    color_bottom=(0, 0, 0, 160)   # 63% black at bottom
)
result = Image.alpha_composite(photo.convert("RGBA"), gradient)
```

### 2.4 Vignette Effect

```python
import numpy as np
from PIL import Image, ImageFilter

def apply_vignette(img, intensity=0.7, radius=0.8):
    """Apply a vignette (darkened edges) effect.
    intensity: 0-1, how dark the edges get
    radius: 0-1, how far the light area extends from center"""
    w, h = img.size
    # Create radial gradient mask using numpy
    Y, X = np.ogrid[:h, :w]
    cx, cy = w / 2, h / 2
    # Normalized distance from center (0 at center, ~1 at corners)
    dist = np.sqrt((X - cx)**2 / cx**2 + (Y - cy)**2 / cy**2)
    # Apply smooth falloff
    mask = np.clip(1 - (dist - radius) / (1 - radius), 0, 1)
    mask = (mask * 255).astype(np.uint8)

    vignette_mask = Image.fromarray(mask, "L")
    vignette_mask = vignette_mask.filter(ImageFilter.GaussianBlur(radius=40))

    # Create dark layer
    dark = Image.new("RGBA", img.size, (0, 0, 0, int(255 * intensity)))

    # Apply mask to dark layer
    dark.putalpha(ImageChops.invert(vignette_mask) if False else
                  Image.fromarray(255 - np.array(vignette_mask.filter(
                      ImageFilter.GaussianBlur(radius=30)))))

    # Simpler approach: multiply original by mask
    img_array = np.array(img.convert("RGB")).astype(float)
    mask_array = np.array(vignette_mask).astype(float) / 255
    mask_3d = np.stack([mask_array] * 3, axis=2)
    # Blend: vignetted = img * mask + black * (1 - mask)
    result_array = img_array * (mask_3d * (1 - intensity) + intensity * mask_3d)
    # Simplified: just darken based on mask
    darkened = img_array * (1 - intensity * (1 - mask_3d))
    return Image.fromarray(darkened.astype(np.uint8), "RGB")
```

**Cleaner vignette implementation:**
```python
def vignette(img, strength=0.4):
    """Clean vignette using Pillow's radial_gradient."""
    mask = Image.radial_gradient("L")  # 256x256, white center to black edge
    mask = mask.resize(img.size, Image.LANCZOS)
    # Strengthen: compress the gradient range
    mask_arr = np.array(mask).astype(float) / 255
    mask_arr = np.clip(mask_arr * (1 + strength), 0, 1)
    mask_final = Image.fromarray((mask_arr * 255).astype(np.uint8), "L")

    dark = Image.new("RGB", img.size, (0, 0, 0))
    return Image.composite(img.convert("RGB"), dark, mask_final)
```

---

## 3. Shape Drawing & Pattern Generation

### 3.1 Rounded Rectangles (Native Pillow 8.2+)

```python
from PIL import Image, ImageDraw

img = Image.new("RGBA", (1080, 1350), (245, 240, 232, 255))
draw = ImageDraw.Draw(img)

# Basic rounded rectangle
draw.rounded_rectangle(
    [(100, 200), (980, 600)],
    radius=30,
    fill=(240, 214, 55, 255),    # B&B yellow
    outline=(26, 26, 26, 255),
    width=3
)

# Custom corner selection: (top_left, top_right, bottom_right, bottom_left)
draw.rounded_rectangle(
    [(100, 700), (980, 900)],
    radius=20,
    fill=(157, 213, 219, 255),   # B&B blue
    corners=(True, True, False, False)  # Only round top corners
)
```

**Anti-aliased rounded rectangle (supersample technique):**
```python
def draw_aa_rounded_rect(size, rect, radius, fill, outline=None, width=1, scale=4):
    """Draw an anti-aliased rounded rectangle by supersampling."""
    # Draw at 4x size
    big = Image.new("RGBA", (size[0]*scale, size[1]*scale), (0, 0, 0, 0))
    big_draw = ImageDraw.Draw(big)
    scaled_rect = [(r[0]*scale, r[1]*scale) for r in [rect[0:2], rect[2:4]]]
    big_draw.rounded_rectangle(
        [tuple(scaled_rect[0]), tuple(scaled_rect[1])],
        radius=radius*scale, fill=fill, outline=outline, width=width*scale
    )
    # Downscale with antialiasing
    return big.resize(size, Image.LANCZOS)
```

### 3.2 Organic Blob Shapes (Perlin Noise Contours)

```python
import math
import numpy as np
from PIL import Image, ImageDraw

def generate_blob(center, base_radius, num_points=64, wobble=0.3, seed=42):
    """Generate organic blob shape using sine wave perturbation.
    wobble: 0-1, how irregular the blob shape is.
    Returns list of (x, y) polygon points."""
    rng = np.random.RandomState(seed)
    # Generate random frequency components for organic look
    n_harmonics = 5
    amplitudes = rng.uniform(0.3, 1.0, n_harmonics) * wobble * base_radius
    frequencies = rng.choice(range(2, 8), n_harmonics, replace=False)
    phases = rng.uniform(0, 2 * math.pi, n_harmonics)

    points = []
    for i in range(num_points):
        angle = 2 * math.pi * i / num_points
        r = base_radius
        for a, f, p in zip(amplitudes, frequencies, phases):
            r += a * math.sin(f * angle + p)
        x = center[0] + r * math.cos(angle)
        y = center[1] + r * math.sin(angle)
        points.append((x, y))
    return points

# Usage
img = Image.new("RGBA", (1080, 1350), (245, 240, 232, 255))
draw = ImageDraw.Draw(img)
blob_points = generate_blob((540, 675), base_radius=200, wobble=0.25, seed=7)
draw.polygon(blob_points, fill=(240, 155, 139, 200))  # B&B coral
```

**Using Perlin noise for more natural blobs:**
```python
# pip install noise
from noise import pnoise1

def perlin_blob(center, base_radius, num_points=100, scale=3.0, amplitude=0.3, seed=0):
    """Generate blob using 1D Perlin noise for radius modulation."""
    points = []
    for i in range(num_points):
        angle = 2 * math.pi * i / num_points
        # Sample Perlin noise along the angle dimension
        noise_val = pnoise1(angle * scale + seed, octaves=3)
        r = base_radius * (1 + amplitude * noise_val)
        x = center[0] + r * math.cos(angle)
        y = center[1] + r * math.sin(angle)
        points.append((x, y))
    return points
```

### 3.3 Wavy Lines and Organic Borders

```python
import math
from PIL import Image, ImageDraw

def draw_wavy_line(draw, start, end, amplitude=10, frequency=0.05,
                   fill=(26, 26, 26), width=3):
    """Draw a wavy line between two points."""
    dx = end[0] - start[0]
    dy = end[1] - start[1]
    length = math.sqrt(dx**2 + dy**2)
    steps = int(length)

    points = []
    for i in range(steps):
        t = i / steps
        # Base position along straight line
        bx = start[0] + dx * t
        by = start[1] + dy * t
        # Perpendicular offset (wave)
        wave = amplitude * math.sin(2 * math.pi * frequency * i)
        # Perpendicular direction
        nx = -dy / length
        ny = dx / length
        points.append((bx + wave * nx, by + wave * ny))

    draw.line(points, fill=fill, width=width)

# Wavy horizontal separator
draw_wavy_line(draw, (50, 500), (1030, 500), amplitude=15, frequency=0.03)
```

### 3.4 Pattern Fills (Stripes, Dots, Crosshatch)

```python
import numpy as np
from PIL import Image, ImageDraw

def create_stripe_pattern(width, height, stripe_width=20, gap=20,
                          color1=(240, 214, 55), color2=(245, 240, 232),
                          angle=45):
    """Create a diagonal stripe pattern."""
    # Create larger canvas to handle rotation
    diag = int(math.sqrt(width**2 + height**2))
    pattern = Image.new("RGB", (diag, diag), color2)
    draw = ImageDraw.Draw(pattern)

    for x in range(-diag, diag * 2, stripe_width + gap):
        draw.rectangle([(x, 0), (x + stripe_width, diag)], fill=color1)

    # Rotate and crop to final size
    pattern = pattern.rotate(angle, expand=False, fillcolor=color2)
    cx, cy = pattern.width // 2, pattern.height // 2
    return pattern.crop((cx - width//2, cy - height//2,
                         cx + width//2, cy + height//2))

def create_dot_pattern(width, height, dot_radius=4, spacing=24,
                       dot_color=(157, 213, 219, 100), bg_color=(0, 0, 0, 0)):
    """Create a polka dot pattern."""
    pattern = Image.new("RGBA", (width, height), bg_color)
    draw = ImageDraw.Draw(pattern)
    for y in range(0, height, spacing):
        offset = spacing // 2 if (y // spacing) % 2 else 0  # Offset alternate rows
        for x in range(offset, width, spacing):
            draw.ellipse([(x-dot_radius, y-dot_radius),
                          (x+dot_radius, y+dot_radius)], fill=dot_color)
    return pattern

def create_crosshatch(width, height, spacing=16, line_width=1,
                      color=(26, 26, 26, 40)):
    """Create crosshatch texture."""
    pattern = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(pattern)
    # Diagonal lines (top-left to bottom-right)
    for i in range(-height, width + height, spacing):
        draw.line([(i, 0), (i + height, height)], fill=color, width=line_width)
    # Diagonal lines (top-right to bottom-left)
    for i in range(-height, width + height, spacing):
        draw.line([(i, height), (i + height, 0)], fill=color, width=line_width)
    return pattern
```

### 3.5 Bezier Curves with aggdraw

```python
# pip install aggdraw
import aggdraw
from PIL import Image

img = Image.new("RGBA", (1080, 1350), (245, 240, 232, 255))
d = aggdraw.Draw(img)

# Smooth bezier curve
pen = aggdraw.Pen((240, 155, 139), width=4)  # B&B coral
brush = aggdraw.Brush((240, 155, 139, 80))   # Semi-transparent fill

# Create path with cubic bezier
path = aggdraw.Path()
path.moveto(100, 500)
path.curveto(300, 200, 700, 800, 980, 500)  # Cubic bezier
path.lineto(980, 700)
path.curveto(700, 900, 300, 400, 100, 700)
path.close()

d.path(path, pen, brush)
d.flush()
```

### 3.6 Starburst / Sunburst Shape

```python
import math
from PIL import Image, ImageDraw

def draw_starburst(draw, center, outer_radius, inner_radius, num_points,
                   fill, rotation=0):
    """Draw a starburst/sunburst shape."""
    points = []
    for i in range(num_points * 2):
        angle = math.pi * i / num_points + math.radians(rotation)
        r = outer_radius if i % 2 == 0 else inner_radius
        x = center[0] + r * math.cos(angle)
        y = center[1] + r * math.sin(angle)
        points.append((x, y))
    draw.polygon(points, fill=fill)

# Usage — playful starburst badge for promotions
draw_starburst(draw, (540, 675), outer_radius=150, inner_radius=100,
               num_points=12, fill=(240, 214, 55), rotation=15)
```

---

## 4. Image Effects Library

### 4.1 Film Grain Simulation

```python
import numpy as np
from PIL import Image, ImageFilter

def add_film_grain(img, intensity=0.018, grain_size=1.0, monochrome=True):
    """Add realistic film grain to an image.
    intensity: 0.01 = subtle, 0.03 = heavy
    grain_size: 1.0 = fine, 2.0 = coarse (simulates larger film format)
    monochrome: True for silver halide look, False for chromatic noise"""
    arr = np.array(img).astype(float)

    if grain_size > 1:
        # Generate at smaller size and upscale for coarser grain
        small_h = int(img.height / grain_size)
        small_w = int(img.width / grain_size)
    else:
        small_h, small_w = img.height, img.width

    if monochrome:
        noise = np.random.normal(0, intensity * 255, (small_h, small_w))
        noise = np.stack([noise] * 3, axis=2)
    else:
        noise = np.random.normal(0, intensity * 255, (small_h, small_w, 3))

    if grain_size > 1:
        noise_img = Image.fromarray(np.clip(noise + 128, 0, 255).astype(np.uint8))
        noise_img = noise_img.resize((img.width, img.height), Image.BILINEAR)
        noise = np.array(noise_img).astype(float) - 128

    result = np.clip(arr + noise, 0, 255).astype(np.uint8)
    return Image.fromarray(result)
```

**More realistic grain (using filmgrainer algorithm):**
```python
def add_realistic_grain(img, sigma=12, grain_size=1.5):
    """Film grain that fuses like actual silver halide crystals."""
    w, h = img.size
    # Generate at reduced size
    gw, gh = int(w / grain_size), int(h / grain_size)
    grain = np.random.normal(0, sigma, (gh, gw)).astype(np.float32)

    # Apply slight Gaussian blur to fuse grain particles
    grain_img = Image.fromarray(np.clip(grain + 128, 0, 255).astype(np.uint8), "L")
    grain_img = grain_img.filter(ImageFilter.GaussianBlur(radius=0.6))

    # Upscale to match image size
    grain_img = grain_img.resize((w, h), Image.BILINEAR)
    grain_arr = np.array(grain_img).astype(float) - 128

    # Apply grain with luminosity-dependent intensity
    # (more visible in midtones, less in shadows/highlights — like real film)
    img_arr = np.array(img.convert("RGB")).astype(float)
    luminance = 0.299 * img_arr[:,:,0] + 0.587 * img_arr[:,:,1] + 0.114 * img_arr[:,:,2]
    # Bell curve: maximum grain in midtones (luminance ~128)
    midtone_mask = 1 - ((luminance - 128) / 128) ** 2
    midtone_mask = np.clip(midtone_mask * 1.5, 0.3, 1.0)

    grain_3d = np.stack([grain_arr * midtone_mask] * 3, axis=2)
    result = np.clip(img_arr + grain_3d, 0, 255).astype(np.uint8)
    return Image.fromarray(result)
```

### 4.2 Gaussian, Box, and Motion Blur

```python
from PIL import ImageFilter

# Gaussian blur
blurred = img.filter(ImageFilter.GaussianBlur(radius=5))

# Box blur (uniform, faster)
blurred = img.filter(ImageFilter.BoxBlur(radius=5))

# Motion blur (custom kernel)
def motion_blur(img, size=15, angle=0):
    """Apply directional motion blur."""
    kernel = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(kernel)
    cx, cy = size // 2, size // 2
    dx = int(math.cos(math.radians(angle)) * size / 2)
    dy = int(math.sin(math.radians(angle)) * size / 2)
    draw.line([(cx - dx, cy - dy), (cx + dx, cy + dy)], fill=255, width=1)
    kernel_data = list(kernel.getdata())
    total = sum(kernel_data)
    if total > 0:
        kernel_data = [v / total for v in kernel_data]
    return img.filter(ImageFilter.Kernel((size, size), kernel_data))
```

### 4.3 Duotone / Tritone Effect

```python
import numpy as np
from PIL import Image

def apply_duotone(img, dark_color, light_color):
    """Apply duotone effect: maps shadows to dark_color, highlights to light_color."""
    gray = np.array(img.convert("L")).astype(float) / 255

    result = np.zeros((*gray.shape, 3), dtype=np.uint8)
    for i in range(3):
        result[:, :, i] = np.clip(
            dark_color[i] * (1 - gray) + light_color[i] * gray,
            0, 255
        ).astype(np.uint8)

    return Image.fromarray(result, "RGB")

def apply_tritone(img, shadow_color, mid_color, highlight_color):
    """Three-color tone mapping."""
    gray = np.array(img.convert("L")).astype(float) / 255
    result = np.zeros((*gray.shape, 3), dtype=np.uint8)

    for i in range(3):
        # Shadow to midtone (0-0.5)
        lower = shadow_color[i] * (1 - gray * 2) + mid_color[i] * (gray * 2)
        # Midtone to highlight (0.5-1.0)
        upper = mid_color[i] * (1 - (gray - 0.5) * 2) + highlight_color[i] * ((gray - 0.5) * 2)
        result[:, :, i] = np.where(gray < 0.5, lower, upper).clip(0, 255).astype(np.uint8)

    return Image.fromarray(result, "RGB")

# B&B brand duotone example
duotone = apply_duotone(photo, dark_color=(26, 26, 26), light_color=(240, 214, 55))
```

### 4.4 Color Halftone Effect

```python
# pip install halftones
# OR use the python-halftone library:
# pip install python-halftone

# Manual implementation:
import numpy as np
from PIL import Image, ImageDraw

def halftone_effect(img, dot_spacing=8, scale=2):
    """CMYK-style halftone effect."""
    img = img.convert("CMYK")
    result = Image.new("RGB", (img.width * scale, img.height * scale), (255, 255, 255))
    draw = ImageDraw.Draw(result)

    channels = img.split()
    colors = [(0, 255, 255), (255, 0, 255), (255, 255, 0), (0, 0, 0)]
    angles = [15, 75, 0, 45]  # Traditional halftone screen angles

    for channel, color, angle in zip(channels, colors, angles):
        ch_arr = np.array(channel)
        for y in range(0, img.height, dot_spacing):
            for x in range(0, img.width, dot_spacing):
                # Sample region
                region = ch_arr[y:y+dot_spacing, x:x+dot_spacing]
                intensity = region.mean() / 255  # 0 = no ink, 1 = full ink
                r = int(intensity * dot_spacing * scale * 0.5)
                if r > 0:
                    cx = (x + dot_spacing // 2) * scale
                    cy = (y + dot_spacing // 2) * scale
                    draw.ellipse([(cx-r, cy-r), (cx+r, cy+r)], fill=color)

    return result.resize(img.size, Image.LANCZOS)
```

### 4.5 Paper/Canvas Texture Overlay

```python
import numpy as np
from PIL import Image, ImageFilter

def generate_paper_texture(width, height, roughness=0.5):
    """Generate a subtle paper texture."""
    # Base noise
    noise = np.random.normal(128, 8 * roughness, (height, width)).astype(np.uint8)
    texture = Image.fromarray(noise, "L")

    # Smooth slightly for paper-like quality
    texture = texture.filter(ImageFilter.GaussianBlur(radius=1.5))

    # Convert to RGBA overlay
    tex_arr = np.array(texture).astype(float)
    alpha = ((tex_arr - 128).clip(-20, 20) + 20) / 40 * 30  # Subtle alpha
    rgba = np.stack([
        np.full((height, width), 128, dtype=np.uint8),
        np.full((height, width), 128, dtype=np.uint8),
        np.full((height, width), 128, dtype=np.uint8),
        alpha.astype(np.uint8)
    ], axis=2)

    return Image.fromarray(rgba, "RGBA")

def apply_texture_overlay(img, texture, blend_mode="soft_light", opacity=0.1):
    """Overlay a texture onto an image."""
    texture = texture.resize(img.size, Image.LANCZOS)
    if blend_mode == "soft_light":
        return blend_soft_light(img.convert("RGB"), texture.convert("RGB"), opacity)
    elif blend_mode == "multiply":
        return blend_multiply(img.convert("RGB"), texture.convert("RGB"), opacity)
```

### 4.6 Perlin Noise Texture Generation

```python
# pip install noise
import numpy as np
from noise import pnoise2
from PIL import Image

def generate_perlin_texture(width, height, scale=100, octaves=6,
                            persistence=0.5, lacunarity=2.0, seed=0):
    """Generate a Perlin noise texture."""
    arr = np.zeros((height, width))
    for y in range(height):
        for x in range(width):
            arr[y][x] = pnoise2(
                x / scale, y / scale,
                octaves=octaves,
                persistence=persistence,
                lacunarity=lacunarity,
                base=seed
            )
    # Normalize to 0-255
    arr = ((arr - arr.min()) / (arr.max() - arr.min()) * 255).astype(np.uint8)
    return Image.fromarray(arr, "L")

# Colorized Perlin noise for backgrounds
def perlin_background(width, height, color1, color2, scale=80, seed=0):
    """Generate organic background using Perlin noise color mapping."""
    noise = generate_perlin_texture(width, height, scale=scale, seed=seed)
    noise_arr = np.array(noise).astype(float) / 255
    result = np.zeros((height, width, 3), dtype=np.uint8)
    for i in range(3):
        result[:, :, i] = (color1[i] * (1 - noise_arr) + color2[i] * noise_arr).astype(np.uint8)
    return Image.fromarray(result, "RGB")

# B&B cream background with subtle texture
bg = perlin_background(1080, 1350, (245, 240, 232), (238, 232, 220), scale=200)
```

---

## 5. DrawBot for Design

### 5.1 Overview & When to Use

**DrawBot** is a macOS-native Python tool for programmatic graphic design. It excels at typography-heavy work.

| Feature | DrawBot | Pillow |
|---------|---------|--------|
| Text rendering quality | Excellent (CoreText) | Good (FreeType) |
| OpenType features | Full native support | Requires Raqm |
| Variable fonts | Full support | Basic support |
| Kerning | Automatic (system-level) | Manual or Raqm |
| Bezier paths | Native, smooth | Via aggdraw |
| Output formats | PDF, SVG, PNG, GIF, MP4 | PNG, JPEG, TIFF |
| Pixel manipulation | Limited | Excellent |
| Cross-platform | macOS only | All platforms |
| Headless operation | Yes (module mode) | Yes |

**Use DrawBot when:** Typography is the star (display type, complex text layout).
**Use Pillow when:** Pixel manipulation, image compositing, photo processing.

### 5.2 Headless DrawBot Usage

```python
# pip install git+https://github.com/typemytype/drawbot
import drawBot

with drawBot.drawing():
    drawBot.newPage(1080, 1350)

    # Background
    drawBot.fill(0.961, 0.941, 0.910)  # B&B cream
    drawBot.rect(0, 0, 1080, 1350)

    # Typography with full OpenType control
    drawBot.font("DX Lactos", 72)
    drawBot.fill(0.102, 0.102, 0.102)  # B&B black
    drawBot.openTypeFeatures(liga=True, ss01=True)
    drawBot.tracking(2)  # Letter spacing in points
    drawBot.text("BLOOM & BARE", (100, 1200))

    # Variable font axis control
    drawBot.font("Mabry Pro")
    drawBot.fontVariations(wght=600)  # Set weight axis

    # Text box with automatic word wrap
    drawBot.fontSize(28)
    drawBot.textBox(
        "Creative sensory play for curious little minds",
        (100, 400, 880, 200)  # x, y, width, height
    )

    # Bezier path
    path = drawBot.BezierPath()
    path.moveTo((100, 300))
    path.curveTo((300, 100), (700, 500), (980, 300))
    drawBot.fill(0.941, 0.608, 0.545, 0.5)  # B&B coral, 50% opacity
    drawBot.drawPath(path)

    drawBot.saveImage("~/Desktop/output.png")
```

### 5.3 Cross-Platform Alternative: drawbot-skia

```python
# pip install drawbot-skia
# Works on macOS, Windows, Linux

import drawBot  # Same API if drawbot-skia is installed

# Caveat: textBox() has limited support due to Skia's low-level text handling
# Best for simpler text operations and geometric drawing
```

### 5.4 Coldtype (Advanced Alternative)

```python
# pip install coldtype
from coldtype import *

@renderable((1080, 1350))
def poster(r):
    return (StSt("BLOOM & BARE",
                 Font.Find("DX Lactos"), 72,
                 wght=700, fill=hsl(0.1, 0.8, 0.5))
            .align(r, "NW")
            .chain(
                StSt("Play Space", Font.Find("Mabry Pro"), 36)
                .align(r, "SW")
            ))
```

**Coldtype advantages:**
- Method-chaining API for composable typography
- First-class variable font support
- Built for animation pipelines
- Works cross-platform
- Can output to DrawBot, Skia, or Cairo backends

---

## 6. Cairo/PyCairo for Design

### 6.1 Vector Rendering Quality

Cairo is a 2D graphics library with support for multiple output devices including SVG, PDF, PNG, and PostScript. Text rendering uses system fonts via FreeType with optional HarfBuzz shaping.

```python
# pip install pycairo
import cairo

# Create PNG surface
surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 1080, 1350)
ctx = cairo.Context(surface)

# Background
ctx.set_source_rgb(0.961, 0.941, 0.910)
ctx.paint()

# Text with precise control
ctx.select_font_face("Mabry Pro", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
ctx.set_font_size(48)
ctx.set_source_rgb(0.102, 0.102, 0.102)
ctx.move_to(100, 200)
ctx.show_text("BLOOM & BARE")

# Smooth bezier curves
ctx.set_source_rgba(0.941, 0.608, 0.545, 0.6)
ctx.set_line_width(3)
ctx.move_to(100, 400)
ctx.curve_to(300, 200, 700, 600, 980, 400)  # Cubic bezier
ctx.stroke()

# Filled shape with gradient
gradient = cairo.LinearGradient(0, 500, 0, 800)
gradient.add_color_stop_rgba(0, 0.941, 0.839, 0.216, 1)  # B&B yellow
gradient.add_color_stop_rgba(1, 0.910, 0.541, 0.227, 1)  # B&B orange
ctx.set_source(gradient)
ctx.rectangle(100, 500, 880, 300)
ctx.fill()

surface.write_to_png("output.png")
```

### 6.2 Cairo Porter-Duff Compositing

Cairo supports all 14 Porter-Duff operators:

```python
# Key operators for design work:
ctx.set_operator(cairo.OPERATOR_OVER)       # Normal (default)
ctx.set_operator(cairo.OPERATOR_MULTIPLY)   # Darken/rich color
ctx.set_operator(cairo.OPERATOR_SCREEN)     # Lighten
ctx.set_operator(cairo.OPERATOR_OVERLAY)    # Contrast
ctx.set_operator(cairo.OPERATOR_SOFT_LIGHT) # Subtle adjustments
ctx.set_operator(cairo.OPERATOR_SOURCE)     # Replace
ctx.set_operator(cairo.OPERATOR_DEST_OVER)  # Draw behind
ctx.set_operator(cairo.OPERATOR_CLEAR)      # Erase
```

### 6.3 Cairo Gradients & Patterns

```python
# Radial gradient (spotlight effect)
radial = cairo.RadialGradient(540, 675, 50, 540, 675, 400)
radial.add_color_stop_rgba(0, 0.941, 0.839, 0.216, 1)   # Center: yellow
radial.add_color_stop_rgba(1, 0.941, 0.839, 0.216, 0)   # Edge: transparent
ctx.set_source(radial)
ctx.paint()

# Mesh gradient (tensor-product patch — advanced)
mesh = cairo.MeshPattern()
mesh.begin_patch()
mesh.move_to(0, 0)
mesh.line_to(1080, 0)
mesh.line_to(1080, 1350)
mesh.line_to(0, 1350)
mesh.set_corner_color_rgba(0, 0.961, 0.941, 0.910, 1)  # Top-left: cream
mesh.set_corner_color_rgba(1, 0.941, 0.839, 0.216, 1)  # Top-right: yellow
mesh.set_corner_color_rgba(2, 0.941, 0.608, 0.545, 1)  # Bottom-right: coral
mesh.set_corner_color_rgba(3, 0.490, 0.773, 0.569, 1)  # Bottom-left: green
mesh.end_patch()
ctx.set_source(mesh)
ctx.paint()
```

### 6.4 Cairo + Pillow Hybrid Pipeline

```python
import cairo
import numpy as np
from PIL import Image

def cairo_to_pillow(surface):
    """Convert Cairo surface to PIL Image."""
    buf = surface.get_data()
    arr = np.ndarray(shape=(surface.get_height(), surface.get_width(), 4),
                     dtype=np.uint8, buffer=buf)
    # Cairo uses BGRA, Pillow uses RGBA
    arr_rgba = arr[:, :, [2, 1, 0, 3]].copy()
    return Image.fromarray(arr_rgba, "RGBA")

def pillow_to_cairo(img):
    """Convert PIL Image to Cairo surface."""
    img_rgba = img.convert("RGBA")
    arr = np.array(img_rgba)
    # Convert RGBA to BGRA for Cairo
    arr_bgra = arr[:, :, [2, 1, 0, 3]].copy()
    surface = cairo.ImageSurface.create_for_data(
        arr_bgra, cairo.FORMAT_ARGB32, img.width, img.height
    )
    return surface

# Workflow: Cairo for text/vectors -> Pillow for pixel effects
# 1. Render text and shapes with Cairo (superior text quality)
# 2. Convert to Pillow
# 3. Apply grain, color grading, compositing with Pillow
```

---

## 7. SVG Generation

### 7.1 svgwrite — Programmatic SVG Creation

```python
# pip install svgwrite
import svgwrite

dwg = svgwrite.Drawing("design.svg", size=(1080, 1350))

# Background
dwg.add(dwg.rect(insert=(0, 0), size=(1080, 1350), fill="#F5F0E8"))

# Gradient definition
gradient = dwg.defs.add(dwg.linearGradient(id="brand_gradient",
                                            start=(0, 0), end=(1, 1)))
gradient.add_stop_color(offset="0%", color="#F0D637")    # B&B yellow
gradient.add_stop_color(offset="100%", color="#E88A3A")  # B&B orange

# Shape with gradient fill
dwg.add(dwg.rect(insert=(100, 200), size=(880, 400),
                  rx=30, ry=30, fill="url(#brand_gradient)"))

# Text
dwg.add(dwg.text("BLOOM & BARE", insert=(540, 500),
                  font_family="DX Lactos", font_size=72,
                  text_anchor="middle", fill="#1A1A1A"))

# Text on path
path = dwg.path(d="M 100 800 Q 540 600 980 800", fill="none", id="text_path")
dwg.defs.add(path)
text_path = dwg.add(dwg.text("creative play for little minds",
                              font_family="Mabry Pro", font_size=24, fill="#1A1A1A"))
text_path.add(dwg.textPath(path, text="creative play for little minds"))

# Filter effects (drop shadow)
shadow_filter = dwg.defs.add(dwg.filter(id="shadow"))
shadow_filter.feGaussianBlur(in_="SourceAlpha", stdDeviation=4, result="blur")
shadow_filter.feOffset(in_="blur", dx=3, dy=3, result="offset")
merge = shadow_filter.feMerge()
merge.feMergeNode(in_="offset")
merge.feMergeNode(in_="SourceGraphic")

# Apply shadow to a group
g = dwg.add(dwg.g(filter="url(#shadow)"))
g.add(dwg.text("Shadowed Text", insert=(200, 1000),
               font_size=48, fill="#1A1A1A"))

dwg.save()
```

### 7.2 SVG Pattern Definitions

```python
# Polka dot pattern
pattern = dwg.defs.add(dwg.pattern(id="dots", size=(20, 20),
                                    patternUnits="userSpaceOnUse"))
pattern.add(dwg.circle(center=(10, 10), r=3, fill="#9DD5DB", opacity=0.4))

# Use pattern
dwg.add(dwg.rect(insert=(0, 0), size=(1080, 1350), fill="url(#dots)"))
```

### 7.3 SVG to PNG Conversion

```python
# Option A: CairoSVG (pip install cairosvg)
import cairosvg
cairosvg.svg2png(url="design.svg", write_to="design.png",
                 output_width=1080, output_height=1350)

# Option B: With scale
cairosvg.svg2png(url="design.svg", write_to="design@2x.png", scale=2)

# Option C: From string
svg_string = dwg.tostring()
cairosvg.svg2png(bytestring=svg_string.encode(), write_to="output.png")
```

---

## 8. Professional Design Automation Tools

### 8.1 Tool Landscape Overview

| Tool | Type | Best For | Pricing Model |
|------|------|----------|---------------|
| **Remotion** | React framework | Video + image from React components | Open source + Cloud pricing |
| **Polotno SDK** | JS SDK | White-label design editors | License-based |
| **htmlcsstoimage** | API | HTML/CSS to PNG/JPEG | Pay-per-image |
| **Figma API** | REST API | Design system integration | Free tier + paid |
| **Canva Connect** | REST API | Bulk design generation | Enterprise |
| **IMG.LY CE.SDK** | JS SDK | Full editor + automation | License-based |
| **Puppeteer/Playwright** | Browser automation | Screenshot-based generation | Open source |
| **Node-canvas** | JS library | Server-side Canvas rendering | Open source |

### 8.2 Remotion for Static Images (Stills)

```jsx
// remotion.config.ts + composition setup
import { AbsoluteFill, Img, staticFile } from "remotion";

export const SocialPost = ({ title, subtitle, mascot, bgColor }) => {
  return (
    <AbsoluteFill style={{
      backgroundColor: bgColor || "#F5F0E8",
      padding: 80,
      fontFamily: "Mabry Pro",
    }}>
      <h1 style={{
        fontFamily: "DX Lactos",
        fontSize: 72,
        color: "#1A1A1A",
        marginBottom: 20,
      }}>
        {title}
      </h1>
      <p style={{ fontSize: 32, color: "#1A1A1A" }}>{subtitle}</p>
      <Img src={staticFile(`mascots/${mascot}.png`)}
           style={{ position: "absolute", bottom: 80, right: 80, width: 200 }} />
    </AbsoluteFill>
  );
};

// Render as still image:
// npx remotion still SocialPost --props='{"title":"Play Time!"}' --output=post.png
```

**Remotion advantages for batch production:**
- Full CSS layout engine (flexbox, grid)
- Perfect text rendering (browser-quality)
- React component reusability
- Data-driven with JSON props
- Render thousands of variations programmatically

### 8.3 HTML/CSS to Image (Screenshot-Based Pipeline)

```python
# Option A: htmlcsstoimage API
import requests

HCTI_API_USER = "your-user-id"
HCTI_API_KEY = "your-api-key"

html = """
<div style="width:1080px; height:1350px; background:#F5F0E8;
            font-family:'Mabry Pro'; padding:80px; box-sizing:border-box;">
  <h1 style="font-family:'DX Lactos'; font-size:72px; color:#1A1A1A;">
    BLOOM & BARE
  </h1>
  <div style="background:#F0D637; border-radius:30px; padding:40px;
              margin-top:40px;">
    <p style="font-size:28px; color:#1A1A1A;">
      Creative sensory play for curious little minds
    </p>
  </div>
</div>
"""

response = requests.post(
    "https://hcti.io/v1/image",
    auth=(HCTI_API_USER, HCTI_API_KEY),
    json={"html": html, "css": "", "google_fonts": "Mabry Pro"}
)
print(response.json()["url"])  # URL to generated PNG
```

```python
# Option B: Playwright (free, local)
# pip install playwright && playwright install chromium
from playwright.sync_api import sync_playwright

def html_to_image(html_content, output_path, width=1080, height=1350):
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": width, "height": height})
        page.set_content(html_content)
        page.screenshot(path=output_path, type="png")
        browser.close()

# For batch: reuse browser instance
with sync_playwright() as p:
    browser = p.chromium.launch()
    for i, data in enumerate(posts_data):
        page = browser.new_page(viewport={"width": 1080, "height": 1350})
        html = render_template(data)  # Your template function
        page.set_content(html)
        page.screenshot(path=f"output/post_{i:03d}.png")
        page.close()
    browser.close()
```

### 8.4 Figma API for Design Generation

```python
import requests

FIGMA_TOKEN = "your-personal-access-token"
FILE_KEY = "your-figma-file-key"

headers = {"X-Figma-Token": FIGMA_TOKEN}

# Export a specific node as PNG
node_id = "123:456"
response = requests.get(
    f"https://api.figma.com/v1/images/{FILE_KEY}?ids={node_id}&format=png&scale=2",
    headers=headers
)
image_url = response.json()["images"][node_id]

# Download the exported image
img_data = requests.get(image_url).content
with open("exported_design.png", "wb") as f:
    f.write(img_data)

# Figma MCP Server (2025+): AI agents can read native Figma properties
# including variables, design tokens, components, variants, auto layout rules
```

### 8.5 Polotno SDK — JSON-to-Design

```javascript
// Node.js server-side rendering
const { createInstance } = require("polotno-node");

async function generateDesign(data) {
  const instance = await createInstance({ key: "YOUR_API_KEY" });

  // Load or create design from JSON schema
  const json = {
    width: 1080,
    height: 1350,
    pages: [{
      children: [
        {
          type: "rect",
          x: 0, y: 0, width: 1080, height: 1350,
          fill: "#F5F0E8",
        },
        {
          type: "text",
          x: 100, y: 200, width: 880,
          text: data.title,
          fontSize: 72,
          fontFamily: "DX Lactos",
          fill: "#1A1A1A",
        },
        {
          type: "image",
          x: 440, y: 800, width: 200, height: 200,
          src: data.mascotUrl,
        }
      ]
    }]
  };

  await instance.jsonToDataURL(json);
  // Or export as file
  const dataUrl = await instance.jsonToDataURL(json);
  instance.close();
  return dataUrl;
}
```

---

## 9. Batch Production Patterns

### 9.1 Data-Driven Template Architecture

The core pattern for all batch design production:

```
[Data Source] -> [Template Engine] -> [Renderer] -> [Post-Process] -> [QA] -> [Export]
     CSV/JSON      Python class       Pillow/etc     Grain/filter      Audit    PNG
```

**Template class pattern (what Bloom & Bare pipeline uses):**
```python
from dataclasses import dataclass, field
from typing import Optional, List, Tuple
from PIL import Image, ImageDraw, ImageFont

@dataclass
class DesignToken:
    """Parameterized design variables — like CSS custom properties."""
    bg_color: Tuple[int, ...] = (245, 240, 232)
    text_color: Tuple[int, ...] = (26, 26, 26)
    accent_color: Tuple[int, ...] = (240, 214, 55)
    heading_font: str = "DXLactos.ttf"
    body_font: str = "MabryPro-Regular.ttf"
    heading_size: int = 72
    body_size: int = 28
    padding: int = 80
    corner_radius: int = 30
    grain_intensity: float = 0.016

@dataclass
class PostData:
    """Content that varies per post."""
    heading: str = ""
    subheading: str = ""
    body: str = ""
    cta: str = ""
    mascot: Optional[str] = None  # Filename of mascot PNG
    logo_variant: str = "primary"
    template_type: str = "T1"    # T1-T8 archetype

class TemplateRenderer:
    """Base class for all template renderers."""
    WIDTH = 1080
    HEIGHT = 1350

    def __init__(self, tokens: DesignToken):
        self.tokens = tokens
        self.img = Image.new("RGBA", (self.WIDTH, self.HEIGHT),
                             tokens.bg_color + (255,))
        self.draw = ImageDraw.Draw(self.img)

    def render(self, data: PostData) -> Image.Image:
        """Override in subclass. Returns final composited image."""
        raise NotImplementedError

    def _load_font(self, path, size):
        return ImageFont.truetype(f"assets/fonts/{path}", size)

    def _composite_mascot(self, mascot_name, position, size):
        mascot = Image.open(f"assets/mascots/{mascot_name}.png")
        mascot = mascot.resize(size, Image.LANCZOS)
        self.img.paste(mascot, position, mascot)

    def _composite_logo(self, variant, position):
        logo = Image.open(f"assets/logos/{variant}.png")
        self.img.paste(logo, position, logo)

    def _add_pill_badge(self, text, position, bg_color, text_color, font_size=20):
        font = self._load_font(self.tokens.body_font, font_size)
        text_w = font.getlength(text)
        pad_x, pad_y = 24, 12
        rect = [
            (position[0], position[1]),
            (position[0] + text_w + pad_x * 2, position[1] + font_size + pad_y * 2)
        ]
        self.draw.rounded_rectangle(rect, radius=font_size,
                                     fill=bg_color, outline=None)
        self.draw.text((position[0] + pad_x, position[1] + pad_y),
                       text, font=font, fill=text_color)

    def _post_process(self):
        """Apply grain — always last in pipeline."""
        self.img = add_film_grain(self.img.convert("RGB"),
                                  intensity=self.tokens.grain_intensity)
        return self.img
```

### 9.2 Batch Runner

```python
import csv
import json
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor

def load_content_from_csv(csv_path):
    """Load post data from CSV file."""
    posts = []
    with open(csv_path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            posts.append(PostData(
                heading=row["heading"],
                subheading=row.get("subheading", ""),
                body=row.get("body", ""),
                cta=row.get("cta", ""),
                mascot=row.get("mascot"),
                template_type=row.get("template", "T1")
            ))
    return posts

def render_single(args):
    """Render a single post (for parallel execution)."""
    idx, data, tokens = args
    template_map = {
        "T1": ScheduleTemplate,
        "T2": QuoteTemplate,
        "T3": EventPosterTemplate,
        "T4": PromoTemplate,
        # ... T5-T8
    }
    renderer_class = template_map[data.template_type]
    renderer = renderer_class(tokens)
    img = renderer.render(data)
    output_path = f"exports/{data.template_type}_{idx:03d}.png"
    img.save(output_path, "PNG")
    return output_path

def batch_render(csv_path, output_dir="exports/"):
    """Render all posts from a CSV file in parallel."""
    Path(output_dir).mkdir(exist_ok=True)
    posts = load_content_from_csv(csv_path)
    tokens = DesignToken()

    args = [(i, post, tokens) for i, post in enumerate(posts)]

    with ProcessPoolExecutor(max_workers=8) as executor:
        results = list(executor.map(render_single, args))

    print(f"Rendered {len(results)} designs")
    return results
```

### 9.3 Design Tokenization for Bulk Variations

```python
# Generate color variations from a base palette
from itertools import product

def generate_variations(base_tokens: DesignToken, variations: dict) -> list:
    """Generate all combinations of design variations.

    variations = {
        "accent_color": [(240,214,55), (157,213,219), (125,197,145)],
        "heading_size": [60, 72, 84],
    }
    """
    keys = list(variations.keys())
    combos = list(product(*[variations[k] for k in keys]))
    result = []
    for combo in combos:
        token_dict = {k: getattr(base_tokens, k) for k in base_tokens.__dataclass_fields__}
        for key, val in zip(keys, combo):
            token_dict[key] = val
        result.append(DesignToken(**token_dict))
    return result

# Example: Generate 18 style variations (6 colors x 3 sizes)
variations = {
    "accent_color": [
        (240, 214, 55),   # Yellow
        (157, 213, 219),  # Blue
        (125, 197, 145),  # Green
        (240, 155, 139),  # Coral
        (184, 160, 200),  # Lavender
        (232, 138, 58),   # Orange
    ],
    "heading_size": [60, 72, 84],
}
all_tokens = generate_variations(DesignToken(), variations)
# -> 18 unique DesignToken instances
```

### 9.4 Visual QA Automation

```python
from PIL import Image
import numpy as np

def qa_check_design(img_path, expected_tokens: DesignToken):
    """Automated quality checks for batch-produced designs."""
    img = Image.open(img_path)
    results = {}

    # 1. Check dimensions
    results["dimensions_ok"] = img.size == (1080, 1350)

    # 2. Check background color (sample corners)
    arr = np.array(img)
    corner_samples = [arr[10, 10], arr[10, -10], arr[-10, 10], arr[-10, -10]]
    bg = expected_tokens.bg_color
    results["bg_color_ok"] = all(
        np.allclose(sample[:3], bg, atol=20) for sample in corner_samples
    )

    # 3. Check image is not blank (has sufficient color variance)
    results["not_blank"] = arr.std() > 10

    # 4. Check for text presence (high-contrast regions)
    gray = np.mean(arr[:, :, :3], axis=2)
    contrast = gray.max() - gray.min()
    results["has_content"] = contrast > 100

    # 5. Check safe zones (top 5%, bottom 5% should have content or be intentional)
    top_zone = arr[:67, :, :]     # Top 5%
    bottom_zone = arr[-67:, :, :] # Bottom 5%
    results["safe_zones_clear"] = True  # Customize per template

    # 6. File size sanity check
    import os
    file_size = os.path.getsize(img_path)
    results["file_size_ok"] = 100_000 < file_size < 10_000_000  # 100KB - 10MB

    passed = all(results.values())
    return {"passed": passed, "checks": results}

def batch_qa(output_dir, tokens):
    """Run QA on all designs in a directory."""
    from pathlib import Path
    failures = []
    for img_path in sorted(Path(output_dir).glob("*.png")):
        result = qa_check_design(str(img_path), tokens)
        if not result["passed"]:
            failures.append((img_path.name, result["checks"]))
            print(f"FAIL: {img_path.name} - {result['checks']}")
        else:
            print(f"PASS: {img_path.name}")
    print(f"\n{len(failures)} failures out of {len(list(Path(output_dir).glob('*.png')))} designs")
    return failures
```

---

## 10. Generative Art Techniques for Design

### 10.1 Perlin Noise for Organic Textures

See Section 4.6 above for basic Perlin noise generation. Advanced applications:

```python
# Domain warping — distorted Perlin noise for fluid organic textures
def warped_noise(x, y, scale=100, warp_strength=50, seed=0):
    """Domain-warped Perlin noise for fluid, organic patterns."""
    # First pass: base noise
    n1 = pnoise2(x / scale, y / scale, octaves=4, base=seed)
    # Second pass: warp coordinates using first noise
    wx = x + warp_strength * pnoise2(x / scale + 5.2, y / scale + 1.3, octaves=4, base=seed)
    wy = y + warp_strength * pnoise2(x / scale + 9.7, y / scale + 2.8, octaves=4, base=seed)
    # Sample noise at warped coordinates
    return pnoise2(wx / scale, wy / scale, octaves=4, base=seed)

def generate_fluid_texture(width, height, color_map, scale=80, warp=60):
    """Generate organic fluid texture using domain-warped noise."""
    arr = np.zeros((height, width, 3), dtype=np.uint8)
    for y in range(height):
        for x in range(width):
            val = (warped_noise(x, y, scale, warp) + 1) / 2  # Normalize to 0-1
            # Map to color gradient
            idx = int(val * (len(color_map) - 1))
            idx = min(idx, len(color_map) - 1)
            arr[y, x] = color_map[idx]
    return Image.fromarray(arr, "RGB")
```

### 10.2 Voronoi Diagrams for Geometric Patterns

```python
from scipy.spatial import Voronoi
import numpy as np
from PIL import Image, ImageDraw

def draw_voronoi_pattern(width, height, num_points=50, colors=None, seed=42):
    """Generate a Voronoi diagram pattern."""
    rng = np.random.RandomState(seed)
    points = rng.rand(num_points, 2) * [width, height]

    # Add mirror points to handle edges
    mirrored = np.concatenate([
        points, points * [1, -1], points * [-1, 1], points * [-1, -1],
        points + [width, 0], points + [0, height],
        points + [width, height], points - [width, 0], points - [0, height]
    ])
    vor = Voronoi(mirrored)

    img = Image.new("RGB", (width, height), (245, 240, 232))
    draw = ImageDraw.Draw(img)

    if colors is None:
        colors = [
            (240, 214, 55), (157, 213, 219), (125, 197, 145),
            (240, 155, 139), (184, 160, 200), (232, 138, 58)
        ]

    for i, region_idx in enumerate(vor.point_region[:num_points]):
        region = vor.regions[region_idx]
        if not region or -1 in region:
            continue
        polygon = [(vor.vertices[v][0], vor.vertices[v][1]) for v in region]
        color = colors[i % len(colors)]
        draw.polygon(polygon, fill=color, outline=(26, 26, 26), width=2)

    return img
```

### 10.3 Mathematical Patterns

```python
import numpy as np
from PIL import Image

def spirograph(width, height, R=200, r=80, d=150, color=(240, 214, 55)):
    """Generate a spirograph (hypotrochoid) pattern."""
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = width // 2, height // 2

    t = np.linspace(0, 2 * np.pi * r / math.gcd(int(R), int(r)), 10000)
    x = (R - r) * np.cos(t) + d * np.cos((R - r) / r * t) + cx
    y = (R - r) * np.sin(t) - d * np.sin((R - r) / r * t) + cy

    points = list(zip(x.astype(int), y.astype(int)))
    draw.line(points, fill=color, width=2)
    return img

def concentric_waves(width, height, num_waves=8, base_color=(245, 240, 232)):
    """Generate concentric wave pattern (moiré-like)."""
    cx, cy = width / 2, height / 2
    Y, X = np.ogrid[:height, :width]
    dist = np.sqrt((X - cx)**2 + (Y - cy)**2)
    wave = np.sin(dist * 2 * np.pi / 40)  # Period = 40px
    normalized = ((wave + 1) / 2 * 255).astype(np.uint8)
    return Image.fromarray(normalized, "L")
```

---

## 11. Tool Comparison Matrix

### For the Bloom & Bare Pipeline

| Capability | Current (Pillow) | + Cairo | + DrawBot | + Remotion |
|-----------|-----------------|---------|-----------|------------|
| Text quality | Good | Better | Best (macOS) | Best (browser) |
| Kerning control | Manual/Raqm | System fonts | Automatic | CSS native |
| CJK support | Single font file | System fallback | System fallback | Browser native |
| Variable fonts | Basic | Limited | Full | CSS native |
| Blend modes | ImageChops + NumPy | Porter-Duff native | Limited | CSS mix-blend-mode |
| SVG output | No | Via PyCairo | Yes | No (raster only) |
| Pixel effects | Excellent | Limited | Limited | Via Canvas API |
| Batch speed | Fast | Fast | Medium | Slower (browser) |
| Cross-platform | Yes | Yes | macOS only | Yes |
| Learning curve | Low | Medium | Low | High (React) |

### Recommendation for Bloom & Bare

**Keep Pillow as the core renderer** — it handles the pipeline's needs well:
- Mascot/logo compositing (paste with alpha)
- Color grading and grain (NumPy + point())
- Shape drawing (rounded_rectangle, polygon)
- Badge/pill rendering

**Add Cairo for:**
- High-quality gradient backgrounds (mesh gradients)
- Vector shape generation (bezier curves)
- Text-on-path rendering

**Consider Remotion if:**
- Moving to animated content (Reels/Stories)
- Need CSS-quality text layout
- Want component-based template system

**Do NOT switch away from Pillow for:**
- Film grain (NumPy-based is faster and more controllable)
- Batch production (Pillow's render speed is superior)
- Post-processing pipeline (existing grain/filter code works)

---

## Key Libraries to Install

```bash
# Core
pip install Pillow numpy

# Enhanced text rendering
# (requires system libraqm + harfbuzz + fribidi)
# macOS: brew install libraqm

# Blending modes
pip install blend-modes

# Anti-aliased drawing
pip install aggdraw

# Perlin noise
pip install noise

# 3D Color LUTs
pip install pillow-lut

# SVG generation + conversion
pip install svgwrite cairosvg

# Cairo bindings
pip install pycairo

# DrawBot (macOS only, headless)
pip install git+https://github.com/typemytype/drawbot

# DrawBot cross-platform alternative
pip install drawbot-skia

# Advanced typography
pip install coldtype

# Halftone effects
pip install halftones

# Screenshot-based rendering
pip install playwright
playwright install chromium

# Film grain (dedicated library)
pip install filmgrainer
```

---

## Sources

- [Pillow ImageDraw Documentation](https://pillow.readthedocs.io/en/stable/reference/ImageDraw.html)
- [Pillow ImageFont Documentation](https://pillow.readthedocs.io/en/stable/reference/ImageFont.html)
- [Pillow Kerning Issue #6175](https://github.com/python-pillow/Pillow/issues/6175)
- [Adding Shadows and Outlines to Text - DEV Community](https://dev.to/francozanardi/python-tutorial-adding-shadows-and-outlines-to-text-on-images-1n9a)
- [Gradient Inside Text - Pillow Discussion #6688](https://github.com/python-pillow/Pillow/discussions/6688)
- [Create Outline Text in Pillow](https://jdhao.github.io/2020/08/18/pillow_create_text_outline/)
- [Pillow CJK Rendering Issue](https://community.openai.com/t/pillow-library-fails-to-render-chinese-japanese-and-korean-text-properly-displays-as-block-characters/989137)
- [Pillow Font Fallback Issue #4808](https://github.com/python-pillow/Pillow/issues/4808)
- [blend-modes Package](https://pypi.org/project/blend-modes/)
- [Image4Layer (CSS3 Blend Modes)](https://github.com/pashango2/Image4Layer)
- [Pillow ImageChops Documentation](https://pillow.readthedocs.io/en/stable/reference/ImageChops.html)
- [pillow-lut-tools](https://github.com/homm/pillow-lut-tools)
- [Pillow Rounded Rectangle Anti-aliasing Issue #5577](https://github.com/python-pillow/Pillow/issues/5577)
- [Pillow Text Auto-sizing Issue #5669](https://github.com/python-pillow/Pillow/issues/5669)
- [Perlin Noise Introduction](https://www.gmschroeder.com/blog/intro_pyart1.html)
- [filmgrainer Library](https://github.com/larspontoppidan/filmgrainer)
- [DrawBot Documentation](https://www.drawbot.com/)
- [drawbot-skia](https://github.com/justvanrossum/drawbot-skia)
- [Coldtype](https://github.com/coldtype/coldtype)
- [PyCairo Documentation](https://pycairo.readthedocs.io/en/latest/)
- [Cairo Compositing Operators](https://www.cairographics.org/operators/)
- [PyCairo Linear Gradients](https://www.geeksforgeeks.org/pycairo-linear-gradients/)
- [svgwrite Documentation](https://svgwrite.readthedocs.io/en/latest/svgwrite.html)
- [CairoSVG](https://cairosvg.org/)
- [Remotion](https://www.remotion.dev/)
- [Polotno SDK](https://polotno.com/docs/overview)
- [HTML/CSS to Image API](https://htmlcsstoimage.com/)
- [Figma Connect APIs](https://www.canva.dev/docs/connect/)
- [Canva Connect APIs](https://www.canva.dev/docs/connect/)
- [IMG.LY CreativeEditor SDK](https://img.ly/products/creative-sdk)
- [Playwright Screenshots](https://playwright.dev/docs/screenshots)
- [Pillow Drawing and Text Rendering - DeepWiki](https://deepwiki.com/python-pillow/Pillow/2.4-drawing-and-font-support)
- [Design Tokens - Material Design 3](https://m3.material.io/foundations/design-tokens)
- [Pillow Drop Shadow - Wikibooks](https://en.wikibooks.org/wiki/Python_Imaging_Library/Drop_Shadows)
