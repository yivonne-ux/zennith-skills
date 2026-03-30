# Advanced Python Pillow (PIL) Techniques for Professional-Grade Design Output

> Research compiled 2026-03-10. Focused on implementable patterns using Pillow + NumPy.
> Honest about limitations; workarounds included where native support is absent.

---

## Table of Contents
1. [Blend Modes](#1-blend-modes)
2. [Color Grading & Curves](#2-color-grading--curves)
3. [Advanced Shadows](#3-advanced-shadows)
4. [Texture & Pattern Generation](#4-texture--pattern-generation)
5. [Typography Rendering](#5-typography-rendering)
6. [Gradient Techniques](#6-gradient-techniques)
7. [Masking & Compositing](#7-masking--compositing)
8. [Professional Effects](#8-professional-effects)
9. [Performance Optimization](#9-performance-optimization)
10. [Golden Ratio & Fibonacci](#10-golden-ratio--fibonacci-in-code)

---

## 1. Blend Modes

### Native Pillow Support (ImageChops)

Pillow's `ImageChops` module provides built-in blend operations. These are C-optimized and fast, but limited to 8-bit images ("L" and "RGB" modes). Results are always clipped to 0-255.

```python
from PIL import ImageChops

# Built-in operations:
ImageChops.multiply(img1, img2)    # Darkens: pixel = (a * b) / 255
ImageChops.screen(img1, img2)      # Lightens: pixel = 255 - ((255-a)*(255-b))/255
ImageChops.overlay(img1, img2)     # Contrast: uses Hard Light algorithm
ImageChops.add(img1, img2, scale=1, offset=0)
ImageChops.subtract(img1, img2, scale=1, offset=0)
ImageChops.difference(img1, img2)
ImageChops.lighter(img1, img2)     # Max of each pixel
ImageChops.darker(img1, img2)      # Min of each pixel
```

### NumPy Implementations (Full Control)

For blend modes not in ImageChops, implement with NumPy. Always work in float [0.0, 1.0] for precision, convert back to uint8 at the end.

```python
import numpy as np
from PIL import Image

def to_float(img):
    """Convert PIL Image to float numpy array [0.0, 1.0]"""
    return np.array(img).astype(np.float64) / 255.0

def to_pil(arr):
    """Convert float numpy array back to PIL Image"""
    return Image.fromarray(np.clip(arr * 255, 0, 255).astype(np.uint8))

# --- MULTIPLY ---
def blend_multiply(base, top):
    """Darkens. Black stays black, white is transparent."""
    return base * top

# --- SCREEN ---
def blend_screen(base, top):
    """Lightens. White stays white, black is transparent."""
    return 1.0 - (1.0 - base) * (1.0 - top)

# --- OVERLAY ---
def blend_overlay(base, top):
    """Increases contrast. Multiplies darks, screens lights."""
    mask = base < 0.5
    result = np.empty_like(base)
    result[mask] = 2.0 * base[mask] * top[mask]
    result[~mask] = 1.0 - 2.0 * (1.0 - base[~mask]) * (1.0 - top[~mask])
    return result

# --- SOFT LIGHT (Pegtop formula) ---
def blend_soft_light(base, top):
    """Subtle contrast. Gentler than Overlay."""
    return (1.0 - 2.0 * top) * base**2 + 2.0 * top * base

# --- HARD LIGHT ---
def blend_hard_light(base, top):
    """Like Overlay but keyed to the top layer."""
    return blend_overlay(top, base)  # Swap base/top from overlay

# --- COLOR DODGE ---
def blend_color_dodge(base, top):
    """Brightens base to reflect top. Creates blown-out highlights."""
    result = np.where(top < 1.0, np.minimum(1.0, base / (1.0 - top)), 1.0)
    return result

# --- COLOR BURN ---
def blend_color_burn(base, top):
    """Darkens base to reflect top. Creates deep shadows."""
    result = np.where(top > 0.0, 1.0 - np.minimum(1.0, (1.0 - base) / top), 0.0)
    return result

# --- LINEAR BURN ---
def blend_linear_burn(base, top):
    return np.clip(base + top - 1.0, 0.0, 1.0)

# --- LINEAR DODGE (ADD) ---
def blend_linear_dodge(base, top):
    return np.clip(base + top, 0.0, 1.0)

# --- VIVID LIGHT ---
def blend_vivid_light(base, top):
    """Combines Color Dodge and Color Burn."""
    mask = top <= 0.5
    result = np.empty_like(base)
    t = 2.0 * top
    result[mask] = blend_color_burn(base, t)[mask]
    result[~mask] = blend_color_dodge(base, t - 1.0)[~mask]
    return np.clip(result, 0.0, 1.0)
```

### Applying Blend Modes with Opacity

```python
def apply_blend(base_img, top_img, blend_func, opacity=1.0):
    """Apply any blend mode with opacity control."""
    base = to_float(base_img)
    top = to_float(top_img)
    blended = blend_func(base, top)
    # Lerp between base and blended by opacity
    result = base * (1.0 - opacity) + blended * opacity
    return to_pil(result)

# Usage:
result = apply_blend(background, texture, blend_multiply, opacity=0.3)
```

### Third-Party: blend_modes Package

```bash
pip install blend-modes
```

```python
from blend_modes import multiply, screen, overlay, soft_light, hard_light
from blend_modes import dodge, normal, difference
import numpy as np
from PIL import Image

# blend_modes expects float arrays shape (H, W, 4) — RGBA
bg = np.array(background.convert('RGBA')).astype(float)
fg = np.array(foreground.convert('RGBA')).astype(float)
result = multiply(bg, fg, opacity=0.8)
result_img = Image.fromarray(result.astype(np.uint8))
```

### Third-Party: Image4Layer (CSS3 Blend Modes)

```bash
pip install image4layer
```
Implements CSS3 blend modes with Pillow. Supports: normal, multiply, screen, overlay, darken, lighten, color-dodge, color-burn, hard-light, soft-light, difference, exclusion.

---

## 2. Color Grading & Curves

### S-Curve Contrast (Custom Curves via LUT)

The most efficient approach is a 1D lookup table — precompute the curve for all 256 values, then apply with `Image.point()`.

```python
from PIL import Image
import numpy as np

def make_s_curve_lut(strength=0.5):
    """
    Generate S-curve LUT for contrast enhancement.
    strength: 0.0 = linear (no change), 1.0 = strong S-curve
    """
    x = np.linspace(0, 1, 256)
    # Attempt sigmoidal contrast
    # Attempt using sine-based S-curve (smooth, predictable)
    curved = 0.5 + (np.sin((x - 0.5) * np.pi) * 0.5)
    # Blend between linear and curved
    result = x * (1.0 - strength) + curved * strength
    return (result * 255).astype(np.uint8).tolist()

def apply_s_curve(img, strength=0.5):
    """Apply S-curve contrast to an image."""
    lut = make_s_curve_lut(strength)
    if img.mode == 'RGB':
        return img.point(lut * 3)  # Apply same curve to R, G, B
    elif img.mode == 'L':
        return img.point(lut)
    elif img.mode == 'RGBA':
        r, g, b, a = img.split()
        lut3 = lut * 3
        rgb = Image.merge('RGB', (r, g, b)).point(lut3)
        return Image.merge('RGBA', (*rgb.split(), a))
```

### Cubic Bezier Curves (Photoshop-style)

```python
from scipy.interpolate import CubicSpline
import numpy as np

def bezier_curve_lut(control_points):
    """
    Generate LUT from control points like Photoshop curves.
    control_points: list of (x, y) tuples, 0-255 range
    e.g., [(0,0), (64,48), (128,140), (192,220), (255,255)]
    """
    pts = np.array(control_points)
    cs = CubicSpline(pts[:, 0], pts[:, 1], bc_type='clamped')
    x = np.arange(256)
    y = np.clip(cs(x), 0, 255).astype(np.uint8)
    return y.tolist()

# Classic S-curve with control points:
s_lut = bezier_curve_lut([(0, 0), (64, 40), (128, 128), (192, 216), (255, 255)])
```

### Color Channel Manipulation (Warm/Cool Shifts)

```python
def warm_shift(img, intensity=0.1):
    """Add warmth: boost reds/yellows, reduce blues."""
    arr = np.array(img).astype(np.float64)
    arr[:, :, 0] = np.clip(arr[:, :, 0] * (1.0 + intensity * 0.3), 0, 255)  # R up
    arr[:, :, 1] = np.clip(arr[:, :, 1] * (1.0 + intensity * 0.1), 0, 255)  # G slight up
    arr[:, :, 2] = np.clip(arr[:, :, 2] * (1.0 - intensity * 0.2), 0, 255)  # B down
    return Image.fromarray(arr.astype(np.uint8))

def cool_shift(img, intensity=0.1):
    """Add coolness: boost blues, reduce reds."""
    arr = np.array(img).astype(np.float64)
    arr[:, :, 0] = np.clip(arr[:, :, 0] * (1.0 - intensity * 0.2), 0, 255)
    arr[:, :, 2] = np.clip(arr[:, :, 2] * (1.0 + intensity * 0.3), 0, 255)
    return Image.fromarray(arr.astype(np.uint8))
```

### Levels Adjustment (Black Point, White Point, Gamma)

```python
def levels_adjustment(img, black_point=0, white_point=255, gamma=1.0):
    """
    Photoshop-style Levels adjustment.
    black_point: input value that maps to 0 (0-255)
    white_point: input value that maps to 255 (0-255)
    gamma: midtone adjustment (1.0 = no change, <1 = brighter, >1 = darker)
    """
    lut = []
    for i in range(256):
        # Remap to 0-1 range based on black/white points
        v = (i - black_point) / max(white_point - black_point, 1)
        v = max(0.0, min(1.0, v))
        # Apply gamma
        v = v ** (1.0 / gamma)
        lut.append(int(v * 255))

    if img.mode == 'RGB':
        return img.point(lut * 3)
    return img.point(lut)
```

### HSL Adjustments

```python
from PIL import Image
import numpy as np
import colorsys

def adjust_hsl(img, hue_shift=0, saturation_factor=1.0, lightness_factor=1.0):
    """
    Adjust HSL values.
    hue_shift: degrees to rotate hue (-180 to 180)
    saturation_factor: multiply saturation (1.0 = no change)
    lightness_factor: multiply lightness (1.0 = no change)
    """
    arr = np.array(img).astype(np.float64) / 255.0
    h, w, _ = arr.shape

    for y in range(h):
        for x in range(w):
            r, g, b = arr[y, x, :3]
            h_val, l_val, s_val = colorsys.rgb_to_hls(r, g, b)
            h_val = (h_val + hue_shift / 360.0) % 1.0
            s_val = min(1.0, max(0.0, s_val * saturation_factor))
            l_val = min(1.0, max(0.0, l_val * lightness_factor))
            arr[y, x, 0], arr[y, x, 1], arr[y, x, 2] = colorsys.hls_to_rgb(h_val, l_val, s_val)

    return Image.fromarray((arr * 255).astype(np.uint8))

# WARNING: The per-pixel loop above is SLOW for large images.
# Vectorized version using numpy:
def adjust_hsl_fast(img, hue_shift=0, sat_factor=1.0, lightness_offset=0):
    """Faster HSL adjustment using vectorized operations."""
    arr = np.array(img.convert('RGB')).astype(np.float64) / 255.0

    # Convert RGB to HSV (easier to vectorize than HLS)
    # Use PIL's built-in conversion for the heavy lifting
    hsv = img.convert('HSV')
    h, s, v = hsv.split()

    # Adjust hue
    h_arr = (np.array(h).astype(np.float64) + hue_shift * 255.0 / 360.0) % 256
    h = Image.fromarray(h_arr.astype(np.uint8))

    # Adjust saturation
    s_arr = np.clip(np.array(s).astype(np.float64) * sat_factor, 0, 255)
    s = Image.fromarray(s_arr.astype(np.uint8))

    # Adjust value/lightness
    v_arr = np.clip(np.array(v).astype(np.float64) + lightness_offset, 0, 255)
    v = Image.fromarray(v_arr.astype(np.uint8))

    return Image.merge('HSV', (h, s, v)).convert('RGB')
```

### 3D LUT Application (pillow-lut-tools)

```bash
pip install pillow-lut
```

```python
from PIL import Image
from pillow_lut import rgb_color_enhance, load_cube_file

# Generate a color grading LUT from parameters:
lut = rgb_color_enhance(
    11,                 # LUT size (11x11x11)
    exposure=0.2,       # EV adjustment
    contrast=0.15,      # S-curve contrast
    warmth=0.3,         # Warm/cool shift
    saturation=0.1,     # Color saturation
    vibrance=0.2,       # Selective saturation (boosts muted colors more)
    hue=0,              # Hue rotation in degrees
    gamma=1.1           # Gamma correction
)
result = img.filter(lut)

# Load a .cube LUT file (from Photoshop, DaVinci Resolve, etc.):
lut = load_cube_file('film_look.cube')
result = img.filter(lut)
```

### Duotone / Tritone Effects

```python
from PIL import Image, ImageOps

def duotone(img, dark_color, light_color):
    """
    Map grayscale to two colors.
    dark_color/light_color: RGB tuples like (32, 0, 64) and (255, 200, 128)
    """
    gray = img.convert('L')
    return ImageOps.colorize(gray, black=dark_color, white=light_color)

def tritone(img, shadow_color, mid_color, highlight_color):
    """Map shadows, mids, highlights to three colors."""
    gray = img.convert('L')
    return ImageOps.colorize(gray, black=shadow_color, white=highlight_color, mid=mid_color)

# Usage:
result = duotone(photo, (20, 0, 40), (255, 180, 100))  # Deep purple to warm gold
result = tritone(photo, (10, 10, 30), (180, 60, 80), (255, 230, 200))
```

### Gradient Map (Map Luminosity to Color Ramp)

```python
def gradient_map(img, color_stops):
    """
    Map image luminosity to arbitrary color ramp.
    color_stops: list of (position, (r,g,b)) where position is 0.0-1.0
    e.g., [(0.0, (0,0,50)), (0.5, (200,50,50)), (1.0, (255,255,200))]
    """
    gray = np.array(img.convert('L')).astype(np.float64) / 255.0
    positions = [s[0] for s in color_stops]
    colors = np.array([s[1] for s in color_stops])

    result = np.zeros((*gray.shape, 3), dtype=np.float64)
    for ch in range(3):
        result[:, :, ch] = np.interp(gray, positions, colors[:, ch])

    return Image.fromarray(result.astype(np.uint8))
```

---

## 3. Advanced Shadow Techniques

### Multi-Layer Drop Shadow (Contact + Ambient + Directional)

```python
from PIL import Image, ImageFilter

def multi_layer_shadow(element, bg_size=(1080, 1350), position=(100, 100)):
    """
    Create professional three-layer shadow system.
    Returns composited image with shadow layers beneath element.
    """
    canvas = Image.new('RGBA', bg_size, (0, 0, 0, 0))

    # Extract alpha for shadow shapes
    alpha = element.split()[-1] if element.mode == 'RGBA' else None
    if alpha is None:
        return canvas

    # --- Layer 1: Contact shadow (tight, dark, minimal offset) ---
    contact = Image.new('RGBA', bg_size, (0, 0, 0, 0))
    shadow_color = Image.new('RGBA', element.size, (0, 0, 0, 80))  # Semi-transparent
    contact.paste(shadow_color, (position[0]+2, position[1]+2), alpha)
    contact = contact.filter(ImageFilter.GaussianBlur(radius=4))

    # --- Layer 2: Ambient shadow (wider, softer, lower opacity) ---
    ambient = Image.new('RGBA', bg_size, (0, 0, 0, 0))
    shadow_color = Image.new('RGBA', element.size, (0, 0, 0, 40))
    ambient.paste(shadow_color, (position[0]+4, position[1]+6), alpha)
    ambient = ambient.filter(ImageFilter.GaussianBlur(radius=20))

    # --- Layer 3: Directional shadow (longest, lightest, most offset) ---
    directional = Image.new('RGBA', bg_size, (0, 0, 0, 0))
    shadow_color = Image.new('RGBA', element.size, (0, 0, 0, 20))
    directional.paste(shadow_color, (position[0]+8, position[1]+16), alpha)
    directional = directional.filter(ImageFilter.GaussianBlur(radius=40))

    # Composite: directional (back) -> ambient -> contact -> element (front)
    canvas = Image.alpha_composite(canvas, directional)
    canvas = Image.alpha_composite(canvas, ambient)
    canvas = Image.alpha_composite(canvas, contact)
    canvas.paste(element, position, element)

    return canvas
```

### Paper/Card Shadow with Penumbra (Soft Edge Gradient)

```python
def card_shadow(card_size, blur_radius=25, offset=(6, 10), opacity=60,
                penumbra_spread=1.5, shadow_color=(0, 0, 0)):
    """
    Realistic paper card shadow with penumbra effect.
    penumbra_spread: how much wider the shadow is than the card (1.0 = same size)
    """
    w, h = card_size
    # Expand canvas for shadow spread
    pad = int(blur_radius * 3)
    canvas_size = (w + pad * 2, h + pad * 2)

    shadow = Image.new('RGBA', canvas_size, (0, 0, 0, 0))

    # Draw shadow shape slightly larger than card (penumbra spread)
    spread_w = int(w * penumbra_spread)
    spread_h = int(h * penumbra_spread)
    sx = pad + offset[0] - (spread_w - w) // 2
    sy = pad + offset[1] - (spread_h - h) // 2

    shadow_rect = Image.new('RGBA', (spread_w, spread_h),
                            (*shadow_color, opacity))
    shadow.paste(shadow_rect, (sx, sy))

    # Multiple blur passes for smooth penumbra
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=blur_radius))

    return shadow, pad  # Return shadow and padding offset
```

### Inner Shadow Effect

```python
def inner_shadow(img, offset=(3, 3), blur=5, opacity=100, color=(0, 0, 0)):
    """
    Create inner shadow effect (shadow inside the shape).
    Works by creating an inverted alpha shadow and masking it within the original shape.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    w, h = img.size
    alpha = img.split()[3]

    # Create inverted alpha (shadow source = edges from outside pushing in)
    inv_alpha = Image.eval(alpha, lambda x: 255 - x)

    # Offset the inverted alpha
    shadow_alpha = Image.new('L', (w, h), 0)
    shadow_alpha.paste(inv_alpha, offset)

    # Blur it
    shadow_alpha = shadow_alpha.filter(ImageFilter.GaussianBlur(radius=blur))

    # Scale opacity
    shadow_alpha = Image.eval(shadow_alpha, lambda x: min(255, int(x * opacity / 100)))

    # Mask shadow within original shape
    from PIL import ImageChops
    shadow_alpha = ImageChops.multiply(shadow_alpha, alpha)

    # Create colored shadow layer
    shadow_layer = Image.new('RGBA', (w, h), (*color, 0))
    shadow_layer.putalpha(shadow_alpha)

    return Image.alpha_composite(img, shadow_layer)
```

### Long Shadow (Flat Design Trend)

```python
def long_shadow(img, angle=135, length=200, color=(0, 0, 0), opacity_start=80, opacity_end=0):
    """
    Create long shadow extending from element at an angle.
    Popular in flat/material design.
    """
    import math

    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    w, h = img.size
    alpha = img.split()[3]

    # Calculate direction vector
    rad = math.radians(angle)
    dx = math.cos(rad)
    dy = math.sin(rad)

    # Build shadow by stacking offset copies with decreasing opacity
    shadow = Image.new('RGBA', (w + abs(int(dx * length)), h + abs(int(dy * length))), (0, 0, 0, 0))

    for i in range(length, 0, -1):
        t = i / length  # 0.0 at front, 1.0 at back
        current_opacity = int(opacity_start * (1.0 - t) + opacity_end * t)
        offset_x = int(dx * i)
        offset_y = int(dy * i)

        layer = Image.new('RGBA', img.size, (*color, current_opacity))
        shadow.paste(layer, (offset_x, offset_y), alpha)

    # Paste original on top
    shadow.paste(img, (0, 0), img)
    return shadow
```

### Colored Shadows (Brand Color Tint)

```python
def colored_shadow(element, shadow_color=(240, 155, 139), blur=20,
                   opacity=80, offset=(5, 8)):
    """
    Shadow using a brand color instead of black.
    shadow_color: RGB tuple (e.g., coral #F09B8B = (240, 155, 139))
    """
    if element.mode != 'RGBA':
        element = element.convert('RGBA')

    alpha = element.split()[3]

    # Create colored shadow
    canvas = Image.new('RGBA', element.size, (0, 0, 0, 0))
    shadow_layer = Image.new('RGBA', element.size, (*shadow_color, opacity))

    # Expand canvas for offset
    expanded = Image.new('RGBA',
        (element.size[0] + abs(offset[0]) + blur*3,
         element.size[1] + abs(offset[1]) + blur*3), (0, 0, 0, 0))

    expanded.paste(shadow_layer, (blur + offset[0], blur + offset[1]), alpha)
    expanded = expanded.filter(ImageFilter.GaussianBlur(radius=blur))

    # Paste element
    expanded.paste(element, (blur, blur), element)
    return expanded
```

---

## 4. Texture & Pattern Generation

### Perlin Noise (Using perlin-numpy)

```bash
pip install git+https://github.com/pvigier/perlin-numpy
# or: pip install perlin-noise
```

```python
import numpy as np
from PIL import Image

# --- Method 1: Pure numpy Perlin implementation ---
def generate_perlin_noise_2d(shape, res, tileable=(False, False)):
    """
    Generate 2D Perlin noise.
    shape: (height, width) of output
    res: (rows, cols) of noise grid — lower = smoother
    """
    def f(t):
        return 6*t**5 - 15*t**4 + 10*t**3  # Smoothstep

    delta = (res[0] / shape[0], res[1] / shape[1])
    d = (shape[0] // res[0], shape[1] // res[1])

    grid = np.mgrid[0:res[0]:delta[0], 0:res[1]:delta[1]].transpose(1, 2, 0) % 1

    # Gradients
    angles = 2 * np.pi * np.random.rand(res[0]+1, res[1]+1)
    gradients = np.dstack((np.cos(angles), np.sin(angles)))

    if tileable[0]:
        gradients[-1,:] = gradients[0,:]
    if tileable[1]:
        gradients[:,-1] = gradients[:,0]

    g00 = gradients[:-1, :-1].repeat(d[0], 0).repeat(d[1], 1)
    g10 = gradients[1:, :-1].repeat(d[0], 0).repeat(d[1], 1)
    g01 = gradients[:-1, 1:].repeat(d[0], 0).repeat(d[1], 1)
    g11 = gradients[1:, 1:].repeat(d[0], 0).repeat(d[1], 1)

    n00 = np.sum(np.dstack((grid[:,:,0], grid[:,:,1])) * g00, 2)
    n10 = np.sum(np.dstack((grid[:,:,0]-1, grid[:,:,1])) * g10, 2)
    n01 = np.sum(np.dstack((grid[:,:,0], grid[:,:,1]-1)) * g01, 2)
    n11 = np.sum(np.dstack((grid[:,:,0]-1, grid[:,:,1]-1)) * g11, 2)

    t = f(grid)
    n0 = n00*(1-t[:,:,0]) + t[:,:,0]*n10
    n1 = n01*(1-t[:,:,0]) + t[:,:,0]*n11

    return np.sqrt(2) * ((1-t[:,:,1]) * n0 + t[:,:,1] * n1)

def generate_fractal_noise_2d(shape, res, octaves=5, persistence=0.5):
    """Combine multiple octaves of Perlin noise for natural-looking texture."""
    noise = np.zeros(shape)
    frequency = 1
    amplitude = 1
    for _ in range(octaves):
        noise += amplitude * generate_perlin_noise_2d(
            shape, (res[0]*frequency, res[1]*frequency))
        frequency *= 2
        amplitude *= persistence
    return noise
```

### Paper Texture

```python
def paper_texture(size=(1080, 1350), intensity=0.03, grain_size=1):
    """
    Generate subtle paper texture with fiber patterns.
    Returns RGBA image to be composited as overlay.
    """
    w, h = size

    # Base: fine Gaussian noise
    noise = np.random.normal(128, 128 * intensity, (h, w)).astype(np.float64)

    # Add some directional fiber (slight horizontal bias)
    fiber_h = np.random.normal(0, 128 * intensity * 0.5, (h, 1))
    fiber_h = np.tile(fiber_h, (1, w))
    # Blur fiber for softness
    fiber_img = Image.fromarray(np.clip(fiber_h + 128, 0, 255).astype(np.uint8))
    fiber_img = fiber_img.filter(ImageFilter.GaussianBlur(radius=2))
    fiber_h = np.array(fiber_img).astype(np.float64) - 128

    combined = noise + fiber_h * 0.3
    combined = np.clip(combined, 0, 255).astype(np.uint8)

    # Convert to RGBA with low opacity for overlay
    texture = Image.fromarray(combined, mode='L').convert('RGBA')
    # Set alpha for subtlety
    r, g, b, a = texture.split()
    texture = Image.merge('RGBA', (r, g, b, Image.new('L', size, int(255 * intensity * 3))))

    return texture
```

### Halftone Dot Pattern

```python
def halftone_pattern(img, dot_spacing=8, dot_scale=1.5, angle=45):
    """
    Convert image to halftone dot pattern (risograph/screen print look).
    """
    import math

    gray = img.convert('L')
    w, h = gray.size
    arr = np.array(gray).astype(np.float64) / 255.0

    output = Image.new('L', (w, h), 255)
    draw = ImageDraw.Draw(output)

    # Rotate grid for angle
    cos_a = math.cos(math.radians(angle))
    sin_a = math.sin(math.radians(angle))

    for gx in range(-h, w + h, dot_spacing):
        for gy in range(-w, h + w, dot_spacing):
            # Rotate coordinates
            x = int(gx * cos_a - gy * sin_a)
            y = int(gx * sin_a + gy * cos_a)

            if 0 <= x < w and 0 <= y < h:
                # Dot size based on darkness
                darkness = 1.0 - arr[y, x]
                radius = darkness * dot_spacing * dot_scale * 0.5
                if radius > 0.5:
                    draw.ellipse(
                        [x - radius, y - radius, x + radius, y + radius],
                        fill=0
                    )

    return output
```

### Film Grain (High Quality)

```python
def film_grain(size, intensity=0.018, blend_mode='overlay'):
    """
    Generate realistic film grain.
    Uses folded noise (affects midtones most, shadows/highlights less).
    intensity: 0.01 = subtle, 0.03 = noticeable, 0.05 = heavy
    """
    h, w = size[1], size[0]

    # Gaussian noise centered at mid-gray
    grain = np.random.normal(0, 1, (h, w, 3)).astype(np.float64)

    # Scale by intensity
    grain = grain * intensity

    # Convert to image format: shift to 0.5 center (mid-gray)
    grain_img = np.clip(grain + 0.5, 0, 1)

    return Image.fromarray((grain_img * 255).astype(np.uint8))

def apply_grain(img, intensity=0.018):
    """Apply grain to image using overlay blend."""
    grain = film_grain(img.size, intensity)
    base = to_float(img.convert('RGB'))
    top = to_float(grain)

    # Overlay blend: grain affects midtones most, preserves extremes
    blended = blend_overlay(base, top)

    # Gentle application
    result = base * 0.85 + blended * 0.15
    return to_pil(result)
```

### Risograph/Screen Print Texture

```python
def risograph_effect(img, color1=(0, 100, 180), color2=(220, 50, 50),
                     halftone_size=6, misregister=(3, 2)):
    """
    Simulate risograph two-color print with slight misregistration.
    """
    gray = img.convert('L')
    w, h = gray.size

    # Create two color separations
    arr = np.array(gray).astype(np.float64) / 255.0

    # Dark channel (ink 1)
    dark_mask = (1.0 - arr)
    dark_mask = np.clip(dark_mask * 1.5, 0, 1)  # Boost contrast

    # Light channel (ink 2)
    light_mask = arr
    light_mask = np.clip(light_mask * 1.3, 0, 1)

    # Apply halftone to each
    # (simplified — use full halftone_pattern() for production)

    # Color each channel
    result = np.zeros((h, w, 3), dtype=np.float64)
    for c in range(3):
        result[:, :, c] = (dark_mask * color1[c] + light_mask * color2[c])

    # Add misregistration (offset color2)
    result_shifted = np.roll(np.roll(result, misregister[0], axis=1), misregister[1], axis=0)
    result = result * 0.6 + result_shifted * 0.4

    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8))
```

---

## 5. Typography Rendering Excellence

### Anti-Aliased Text (Best Quality)

```python
from PIL import Image, ImageDraw, ImageFont

def render_text_hq(text, font_path, font_size, color=(0, 0, 0),
                   canvas_size=(1080, 1350), supersampling=2):
    """
    Render text at 2x resolution then downsample for crisp anti-aliasing.
    Pillow's native text rendering is decent but supersampling improves edges.
    """
    ss = supersampling
    large = Image.new('RGBA', (canvas_size[0]*ss, canvas_size[1]*ss), (0, 0, 0, 0))
    draw = ImageDraw.Draw(large)
    font = ImageFont.truetype(font_path, font_size * ss)

    draw.text((100*ss, 100*ss), text, font=font, fill=color)

    # Downsample with LANCZOS for best quality
    return large.resize(canvas_size, Image.LANCZOS)
```

### Custom Line Spacing (Leading)

```python
def draw_text_with_leading(draw, position, text, font, fill, leading=1.4):
    """
    Draw multi-line text with custom line spacing.
    leading: multiplier of font size (1.0 = tight, 1.4 = normal, 2.0 = double)
    """
    x, y = position
    lines = text.split('\n')

    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        line_height = bbox[3] - bbox[1]
        draw.text((x, y), line, font=font, fill=fill)
        y += int(line_height * leading)

    return y  # Return final y position
```

### Outlined / Stroked Text (Native Pillow Support)

```python
def stroked_text(draw, position, text, font, fill=(255, 255, 255),
                 stroke_fill=(0, 0, 0), stroke_width=3):
    """
    Draw text with outline stroke. Native Pillow support (v6.2.0+).
    IMPORTANT: Must specify BOTH stroke_width AND stroke_fill.
    If stroke_fill omitted, it defaults to fill color = invisible stroke.
    """
    draw.text(
        position, text, font=font, fill=fill,
        stroke_width=stroke_width,
        stroke_fill=stroke_fill
    )
```

### Text with Shadow / Glow

```python
def text_with_shadow(canvas, position, text, font, fill=(255, 255, 255),
                     shadow_color=(0, 0, 0, 120), shadow_offset=(4, 4),
                     shadow_blur=6):
    """Draw text with soft shadow behind it."""
    # Create shadow layer
    shadow_layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_layer)
    sd.text((position[0] + shadow_offset[0], position[1] + shadow_offset[1]),
            text, font=font, fill=shadow_color)
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=shadow_blur))

    # Composite shadow then text
    canvas = Image.alpha_composite(canvas, shadow_layer)
    draw = ImageDraw.Draw(canvas)
    draw.text(position, text, font=font, fill=fill)
    return canvas

def text_with_glow(canvas, position, text, font, fill=(255, 255, 255),
                   glow_color=(255, 200, 100), glow_radius=10, glow_opacity=150):
    """Draw text with luminous glow effect behind it."""
    glow_layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_layer)
    gd.text(position, text, font=font, fill=(*glow_color, glow_opacity))

    # Multiple blur passes for soft glow
    for _ in range(3):
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=glow_radius))

    canvas = Image.alpha_composite(canvas, glow_layer)
    draw = ImageDraw.Draw(canvas)
    draw.text(position, text, font=font, fill=fill)
    return canvas
```

### Text with Gradient Fill (Clipping Mask Technique)

```python
def gradient_text(text, font, canvas_size, gradient_colors, angle=0):
    """
    Fill text with a gradient using text-as-mask technique.
    gradient_colors: list of (r,g,b) tuples
    """
    import math

    # 1. Render text as white on black (mask)
    mask = Image.new('L', canvas_size, 0)
    draw = ImageDraw.Draw(mask)
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (canvas_size[0] - tw) // 2
    ty = (canvas_size[1] - th) // 2
    draw.text((tx, ty), text, font=font, fill=255)

    # 2. Create gradient image
    gradient = create_linear_gradient(canvas_size, gradient_colors, angle)

    # 3. Use text mask to cut gradient
    result = Image.new('RGBA', canvas_size, (0, 0, 0, 0))
    result.paste(gradient, (0, 0), mask)

    return result
```

### Curved Text (Character-by-Character Rotation)

```python
import math
from PIL import Image, ImageDraw, ImageFont

def text_on_circle(text, font, center, radius, start_angle=0, canvas_size=(1080, 1080)):
    """
    Render text along a circular path.
    Pillow has NO native curved text — this is a manual character-by-character approach.
    """
    canvas = Image.new('RGBA', canvas_size, (0, 0, 0, 0))

    # Calculate total arc length of text
    char_widths = []
    for ch in text:
        bbox = ImageDraw.Draw(canvas).textbbox((0, 0), ch, font=font)
        char_widths.append(bbox[2] - bbox[0])

    total_width = sum(char_widths)
    total_angle = (total_width / (2 * math.pi * radius)) * 360

    current_angle = start_angle - total_angle / 2  # Center the text

    for i, ch in enumerate(text):
        rad = math.radians(current_angle)

        # Position on circle
        x = center[0] + radius * math.cos(rad)
        y = center[1] + radius * math.sin(rad)

        # Render character on small canvas, rotated
        char_img = Image.new('RGBA', (100, 100), (0, 0, 0, 0))
        cd = ImageDraw.Draw(char_img)
        cd.text((20, 20), ch, font=font, fill=(0, 0, 0, 255))

        # Rotate character to follow the curve (tangent angle)
        rotated = char_img.rotate(-current_angle - 90, expand=True,
                                   resample=Image.BICUBIC)

        # Paste onto canvas
        paste_x = int(x - rotated.width // 2)
        paste_y = int(y - rotated.height // 2)
        canvas.paste(rotated, (paste_x, paste_y), rotated)

        # Advance angle by character width
        char_angle = (char_widths[i] / (2 * math.pi * radius)) * 360
        current_angle += char_angle

    return canvas
```

### Letterpress / Emboss Text Effect

```python
def letterpress_text(canvas, position, text, font, depth=2,
                     light_angle=135, base_color=(60, 60, 60)):
    """
    Simulate letterpress/deboss text effect.
    Uses highlight offset above and shadow offset below the text.
    """
    canvas = canvas.convert('RGBA')
    x, y = position

    # Shadow (below/right) — darker
    shadow_layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_layer)
    sd.text((x + depth, y + depth), text, font=font, fill=(0, 0, 0, 80))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=1))

    # Highlight (above/left) — lighter
    highlight_layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(highlight_layer)
    hd.text((x - depth, y - depth), text, font=font, fill=(255, 255, 255, 60))
    highlight_layer = highlight_layer.filter(ImageFilter.GaussianBlur(radius=1))

    # Main text
    text_layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    td = ImageDraw.Draw(text_layer)
    td.text(position, text, font=font, fill=base_color)

    # Composite in order
    canvas = Image.alpha_composite(canvas, shadow_layer)
    canvas = Image.alpha_composite(canvas, highlight_layer)
    canvas = Image.alpha_composite(canvas, text_layer)

    return canvas
```

### OpenType Features

```python
# Pillow supports OpenType feature tags (v6.2.0+)
draw.text(
    (x, y), text, font=font, fill=fill,
    features=[
        'liga',   # Standard ligatures (usually on by default)
        'dlig',   # Discretionary ligatures
        'ss01',   # Stylistic Set 1
        'onum',   # Oldstyle numerals
        'smcp',   # Small capitals
        '-kern',  # DISABLE kerning (prefix with - to disable)
    ]
)
```

---

## 6. Gradient Techniques

### Linear Gradient (Any Angle)

```python
import numpy as np
from PIL import Image
import math

def linear_gradient(size, color_start, color_end, angle=0):
    """
    Create linear gradient at any angle.
    angle: degrees, 0 = left-to-right, 90 = top-to-bottom
    """
    w, h = size

    # Create coordinate grids
    x = np.linspace(0, 1, w)
    y = np.linspace(0, 1, h)
    xv, yv = np.meshgrid(x, y)

    # Rotate gradient direction
    rad = math.radians(angle)
    gradient = xv * math.cos(rad) + yv * math.sin(rad)

    # Normalize to 0-1
    gradient = (gradient - gradient.min()) / (gradient.max() - gradient.min())

    # Interpolate colors
    result = np.zeros((h, w, 3), dtype=np.uint8)
    for c in range(3):
        result[:, :, c] = (color_start[c] * (1 - gradient) +
                           color_end[c] * gradient).astype(np.uint8)

    return Image.fromarray(result)

def multi_stop_linear_gradient(size, stops, angle=0):
    """
    Linear gradient with multiple color stops.
    stops: list of (position, (r,g,b)) where position is 0.0-1.0
    """
    w, h = size
    x = np.linspace(0, 1, w)
    y = np.linspace(0, 1, h)
    xv, yv = np.meshgrid(x, y)

    rad = math.radians(angle)
    gradient = xv * math.cos(rad) + yv * math.sin(rad)
    gradient = (gradient - gradient.min()) / (gradient.max() - gradient.min())

    positions = [s[0] for s in stops]
    result = np.zeros((h, w, 3), dtype=np.float64)
    for c in range(3):
        colors = [s[1][c] for s in stops]
        result[:, :, c] = np.interp(gradient, positions, colors)

    return Image.fromarray(result.astype(np.uint8))
```

### Radial Gradient

```python
def radial_gradient(size, color_center, color_edge, center=None, radius=None):
    """
    Create radial gradient from center outward.
    """
    w, h = size
    if center is None:
        center = (w // 2, h // 2)
    if radius is None:
        radius = max(w, h) * 0.7

    y, x = np.ogrid[:h, :w]
    dist = np.sqrt((x - center[0])**2 + (y - center[1])**2)
    gradient = np.clip(dist / radius, 0, 1)

    result = np.zeros((h, w, 3), dtype=np.uint8)
    for c in range(3):
        result[:, :, c] = (color_center[c] * (1 - gradient) +
                           color_edge[c] * gradient).astype(np.uint8)

    return Image.fromarray(result)
```

### Mesh Gradient Approximation

```python
def mesh_gradient(size, control_points):
    """
    Approximate mesh gradient using weighted distance from control points.
    control_points: list of (x, y, (r, g, b)) — positions are 0.0-1.0

    This is an approximation — true mesh gradients use bicubic patches.
    Uses inverse distance weighting for smooth color blending.
    """
    w, h = size
    x = np.linspace(0, 1, w)
    y = np.linspace(0, 1, h)
    xv, yv = np.meshgrid(x, y)

    result = np.zeros((h, w, 3), dtype=np.float64)
    total_weight = np.zeros((h, w), dtype=np.float64)

    power = 3.0  # Higher = sharper color regions; lower = more blending

    for px, py, color in control_points:
        dist = np.sqrt((xv - px)**2 + (yv - py)**2)
        dist = np.maximum(dist, 0.001)  # Avoid division by zero
        weight = 1.0 / (dist ** power)

        for c in range(3):
            result[:, :, c] += weight * color[c]
        total_weight += weight

    for c in range(3):
        result[:, :, c] /= total_weight

    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8))

# Usage — 4-corner mesh gradient:
mesh = mesh_gradient((1080, 1350), [
    (0.0, 0.0, (245, 240, 232)),   # Top-left: cream
    (1.0, 0.0, (157, 213, 219)),   # Top-right: blue
    (0.0, 1.0, (240, 155, 139)),   # Bottom-left: coral
    (1.0, 1.0, (184, 160, 200)),   # Bottom-right: lavender
    (0.5, 0.5, (245, 240, 232)),   # Center: cream (anchor point)
])
```

### Gradient Map (Luminosity to Color Ramp)

```python
def gradient_map(img, color_stops):
    """
    Map image luminosity to arbitrary color ramp (like Photoshop Gradient Map).
    color_stops: list of (position, (r,g,b)) where position is 0.0-1.0
    """
    gray = np.array(img.convert('L')).astype(np.float64) / 255.0
    positions = [s[0] for s in color_stops]

    result = np.zeros((*gray.shape, 3), dtype=np.float64)
    for ch in range(3):
        colors = [s[1][ch] for s in color_stops]
        result[:, :, ch] = np.interp(gray, positions, colors)

    return Image.fromarray(result.astype(np.uint8))

# Usage — warm-to-cool gradient map:
mapped = gradient_map(photo, [
    (0.0, (20, 10, 40)),      # Shadows: deep navy
    (0.3, (180, 60, 80)),     # Lower mids: warm rose
    (0.6, (240, 180, 100)),   # Upper mids: gold
    (1.0, (255, 250, 240)),   # Highlights: warm white
])
```

---

## 7. Masking & Compositing

### Alpha Compositing with Custom Masks

```python
from PIL import Image, ImageFilter

def composite_with_mask(background, foreground, mask):
    """
    Composite using mask. mask mode 'L': 255=foreground, 0=background.
    Formula: result = (mask/255) * foreground + (1 - mask/255) * background
    """
    return Image.composite(foreground, background, mask)
```

### Feathered / Soft Edge Masks

```python
def feathered_mask(size, shape_bbox, feather_radius=20):
    """
    Create mask with soft feathered edges.
    shape_bbox: (x1, y1, x2, y2) of the sharp shape
    """
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rectangle(shape_bbox, fill=255)

    # Gaussian blur creates the feathered edge
    return mask.filter(ImageFilter.GaussianBlur(radius=feather_radius))

def feathered_ellipse_mask(size, center, radii, feather=30):
    """Feathered elliptical mask for vignette-style selections."""
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    x, y = center
    rx, ry = radii
    draw.ellipse([x-rx, y-ry, x+rx, y+ry], fill=255)
    return mask.filter(ImageFilter.GaussianBlur(radius=feather))
```

### Luminosity Masks

```python
def luminosity_masks(img):
    """
    Generate luminosity masks like Photoshop.
    Returns dict of masks for highlights, midtones, shadows.
    """
    gray = img.convert('L')
    arr = np.array(gray).astype(np.float64) / 255.0

    # Highlights: bright areas
    highlights = np.clip(arr * 255, 0, 255).astype(np.uint8)

    # Shadows: inverse of highlights
    shadows = np.clip((1.0 - arr) * 255, 0, 255).astype(np.uint8)

    # Midtones: peak at 0.5, fall off toward 0 and 1
    midtones = np.clip((1.0 - np.abs(arr - 0.5) * 2) * 255, 0, 255).astype(np.uint8)

    return {
        'highlights': Image.fromarray(highlights),
        'midtones': Image.fromarray(midtones),
        'shadows': Image.fromarray(shadows),
    }

# Usage — selective color grading:
masks = luminosity_masks(photo)
# Warm only the highlights:
warm_highlights = warm_shift(photo, intensity=0.2)
result = Image.composite(warm_highlights, photo, masks['highlights'])
```

### Clipping Mask (Image Inside Text/Shape)

```python
def clip_image_to_text(image, text, font, canvas_size):
    """Put an image inside text (clipping mask)."""
    # Create text mask
    mask = Image.new('L', canvas_size, 0)
    draw = ImageDraw.Draw(mask)
    bbox = draw.textbbox((0, 0), text, font=font)
    tx = (canvas_size[0] - (bbox[2] - bbox[0])) // 2
    ty = (canvas_size[1] - (bbox[3] - bbox[1])) // 2
    draw.text((tx, ty), text, font=font, fill=255)

    # Resize image to fill canvas
    image = image.resize(canvas_size, Image.LANCZOS)

    # Apply mask
    result = Image.new('RGBA', canvas_size, (0, 0, 0, 0))
    result.paste(image, (0, 0), mask)
    return result

def clip_image_to_shape(image, shape_func, canvas_size):
    """
    Clip image to arbitrary shape.
    shape_func: callable that takes (ImageDraw, size) and draws white shape on black.
    """
    mask = Image.new('L', canvas_size, 0)
    draw = ImageDraw.Draw(mask)
    shape_func(draw, canvas_size)

    image = image.resize(canvas_size, Image.LANCZOS)
    result = Image.new('RGBA', canvas_size, (0, 0, 0, 0))
    result.paste(image, (0, 0), mask)
    return result
```

---

## 8. Professional Effects

### Vignette (Radial Darkening)

```python
def vignette(img, strength=0.5, radius=0.8):
    """
    Apply vignette (darken edges, brighten center).
    strength: 0.0 = none, 1.0 = full black corners
    radius: 0.5 = tight focus, 1.0 = wide, gentle falloff
    """
    w, h = img.size

    # Create radial gradient mask
    y, x = np.ogrid[:h, :w]
    cx, cy = w / 2, h / 2

    # Normalized distance from center (elliptical for non-square)
    dist = np.sqrt(((x - cx) / (w * 0.5))**2 + ((y - cy) / (h * 0.5))**2)

    # Smooth falloff curve
    vignette_mask = np.clip((dist - radius) / (1.0 - radius + 0.01), 0, 1)
    vignette_mask = vignette_mask ** 1.5  # Smooth curve
    vignette_mask = vignette_mask * strength

    # Apply darkening
    arr = np.array(img).astype(np.float64)
    arr = arr * (1.0 - vignette_mask[:, :, np.newaxis])

    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
```

### Glow / Bloom on Highlights

```python
def bloom_effect(img, threshold=200, blur_radius=30, intensity=0.4):
    """
    Add bloom/glow to bright areas of image.
    Mimics light bleeding from overexposed highlights.
    """
    arr = np.array(img.convert('RGB')).astype(np.float64)

    # Extract bright areas above threshold
    brightness = np.max(arr, axis=2)
    mask = (brightness > threshold).astype(np.float64)

    # Create bloom from bright areas only
    bright_pixels = arr * mask[:, :, np.newaxis]
    bloom_img = Image.fromarray(bright_pixels.astype(np.uint8))

    # Heavy blur for bloom spread
    bloom_img = bloom_img.filter(ImageFilter.GaussianBlur(radius=blur_radius))

    # Screen blend the bloom back onto original
    bloom_arr = np.array(bloom_img).astype(np.float64)
    result = arr + bloom_arr * intensity

    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8))
```

### Chromatic Aberration

```python
def chromatic_aberration(img, offset=3, radial=True):
    """
    Subtle chromatic aberration (RGB channel separation).
    offset: pixels to shift R and B channels
    radial: if True, effect increases toward edges (more realistic)
    """
    r, g, b = img.split()[:3]
    w, h = img.size

    if radial:
        # Radial: scale channels from center (zoom red in, blue out)
        from PIL import ImageTransform

        # Red: zoom in slightly
        r_scale = 1.0 + offset / max(w, h) * 2
        r_size = (int(w * r_scale), int(h * r_scale))
        r = r.resize(r_size, Image.LANCZOS)
        r = r.crop(((r_size[0]-w)//2, (r_size[1]-h)//2,
                     (r_size[0]-w)//2 + w, (r_size[1]-h)//2 + h))

        # Blue: zoom out slightly
        b_scale = 1.0 - offset / max(w, h) * 2
        b_resized = b.resize((int(w * b_scale), int(h * b_scale)), Image.LANCZOS)
        b = Image.new('L', (w, h), 128)
        bx = (w - b_resized.width) // 2
        by = (h - b_resized.height) // 2
        b.paste(b_resized, (bx, by))
    else:
        # Simple lateral shift
        r = ImageChops.offset(r, offset, 0)
        b = ImageChops.offset(b, -offset, 0)

    return Image.merge('RGB', (r, g, b))
```

### Motion Blur

```python
def motion_blur(img, angle=0, distance=20):
    """Directional motion blur."""
    import math

    # Create motion blur kernel
    kernel_size = distance * 2 + 1
    kernel = Image.new('L', (kernel_size, kernel_size), 0)
    draw = ImageDraw.Draw(kernel)

    cx, cy = distance, distance
    dx = math.cos(math.radians(angle)) * distance
    dy = math.sin(math.radians(angle)) * distance

    draw.line([(cx - dx, cy - dy), (cx + dx, cy + dy)], fill=255, width=1)

    kernel_arr = np.array(kernel).astype(np.float64)
    kernel_arr /= kernel_arr.sum()  # Normalize

    # Apply via scipy (Pillow doesn't have arbitrary kernel convolution easily)
    from scipy.ndimage import convolve
    arr = np.array(img).astype(np.float64)

    for c in range(arr.shape[2]):
        arr[:, :, c] = convolve(arr[:, :, c], kernel_arr)

    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
```

### Film Grain (Professional Quality)

```python
def professional_grain(img, intensity=0.02, size=1.0, color_variation=0.3):
    """
    High-quality film grain.
    - Luminance-aware (more grain in midtones, less in pure black/white)
    - Slight color variation (R/G/B channels vary independently)
    - Optional size control via downscale+upscale
    """
    w, h = img.size
    arr = np.array(img).astype(np.float64) / 255.0

    # Generate base grain at optionally reduced resolution (larger grain)
    gw, gh = int(w / size), int(h / size)

    # Luminance noise (same across channels)
    luma_grain = np.random.normal(0, intensity, (gh, gw, 1))

    # Chroma noise (different per channel, weaker)
    chroma_grain = np.random.normal(0, intensity * color_variation, (gh, gw, 3))

    grain = luma_grain + chroma_grain

    # Upscale if size > 1
    if size != 1.0:
        grain_img = Image.fromarray(((grain + 0.5) * 255).clip(0, 255).astype(np.uint8))
        grain_img = grain_img.resize((w, h), Image.BILINEAR)
        grain = np.array(grain_img).astype(np.float64) / 255.0 - 0.5

    # Luminance mask: reduce grain in pure blacks and whites
    luminance = 0.299 * arr[:,:,0] + 0.587 * arr[:,:,1] + 0.114 * arr[:,:,2]
    grain_mask = 4.0 * luminance * (1.0 - luminance)  # Peaks at 0.5
    grain_mask = np.clip(grain_mask, 0.2, 1.0)  # Keep some grain everywhere

    # Apply grain
    result = arr + grain[:h, :w, :] * grain_mask[:, :, np.newaxis]

    return Image.fromarray(np.clip(result * 255, 0, 255).astype(np.uint8))
```

### Lens Flare (Simplified)

```python
def lens_flare(img, position, intensity=0.8, color=(255, 240, 200)):
    """Simple lens flare centered at position."""
    w, h = img.size

    flare = Image.new('RGB', (w, h), (0, 0, 0))

    # Central bright spot (radial gradient)
    y, x = np.ogrid[:h, :w]
    dist = np.sqrt((x - position[0])**2 + (y - position[1])**2)

    # Core glow
    core = np.exp(-(dist**2) / (2 * 50**2)) * intensity
    # Wider halo
    halo = np.exp(-(dist**2) / (2 * 200**2)) * intensity * 0.3

    combined = np.clip(core + halo, 0, 1)

    flare_arr = np.zeros((h, w, 3), dtype=np.float64)
    for c in range(3):
        flare_arr[:, :, c] = combined * color[c]

    # Screen blend onto image
    img_arr = np.array(img).astype(np.float64)
    result = 255 - ((255 - img_arr) * (255 - flare_arr)) / 255

    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8))
```

---

## 9. Performance Optimization

### NumPy Array Conversion (Fast Path)

```python
import numpy as np
from PIL import Image

# FAST — direct memory sharing when possible:
arr = np.asarray(img)       # Read-only view (fastest, zero-copy)
arr = np.array(img)          # Writable copy (one copy)

# SLOW — avoid these:
# arr = np.array(list(img.getdata()))  # Python list intermediary = slow
# arr = np.array(img.load())           # PixelAccess = slow

# Back to PIL:
result = Image.fromarray(arr)            # uint8 array
result = Image.fromarray(arr, mode='RGB') # Explicit mode
```

### When to Use ImageChops vs NumPy

| Scenario | Use | Why |
|----------|-----|-----|
| Simple multiply/screen/add | `ImageChops` | C-optimized, faster than numpy for single ops |
| Custom blend mode | NumPy | No native support in Pillow |
| Chaining multiple operations | NumPy | Stay in array space, avoid repeated conversions |
| Per-pixel conditional logic | NumPy | Vectorized boolean indexing |
| Single filter application | `ImageFilter` | C-optimized |
| Custom convolution kernel | `ImageFilter.Kernel` or scipy | Pillow has `Kernel` for 3x3/5x5 |

### Efficient Layer Compositing Pipeline

```python
class CompositeStack:
    """Efficient multi-layer compositor. Stays in numpy until final output."""

    def __init__(self, size):
        self.w, self.h = size
        # Work in float RGBA
        self.canvas = np.zeros((self.h, self.w, 4), dtype=np.float64)
        self.canvas[:, :, 3] = 1.0  # Opaque background

    def add_layer(self, img, blend_func=None, opacity=1.0, position=(0, 0)):
        """Add a layer with blend mode and opacity."""
        layer = np.array(img.convert('RGBA')).astype(np.float64) / 255.0

        # Handle positioning
        x, y = position
        lh, lw = layer.shape[:2]

        # Crop to canvas bounds
        cx1 = max(0, x)
        cy1 = max(0, y)
        cx2 = min(self.w, x + lw)
        cy2 = min(self.h, y + lh)

        lx1 = cx1 - x
        ly1 = cy1 - y
        lx2 = lx1 + (cx2 - cx1)
        ly2 = ly1 + (cy2 - cy1)

        region = self.canvas[cy1:cy2, cx1:cx2, :3]
        layer_region = layer[ly1:ly2, lx1:lx2, :3]
        layer_alpha = layer[ly1:ly2, lx1:lx2, 3:4] * opacity

        if blend_func:
            blended = blend_func(region, layer_region)
        else:
            blended = layer_region

        # Alpha composite
        self.canvas[cy1:cy2, cx1:cx2, :3] = (
            region * (1 - layer_alpha) + blended * layer_alpha
        )

    def render(self):
        """Output final PIL Image."""
        result = np.clip(self.canvas[:, :, :3] * 255, 0, 255).astype(np.uint8)
        return Image.fromarray(result)

# Usage:
stack = CompositeStack((1080, 1350))
stack.add_layer(background)
stack.add_layer(texture, blend_func=blend_multiply, opacity=0.15)
stack.add_layer(gradient_overlay, blend_func=blend_screen, opacity=0.3)
stack.add_layer(text_layer, opacity=1.0)
result = stack.render()
```

### Memory Management

```python
# 1. Explicit cleanup for large images
import gc

def process_batch(paths):
    for path in paths:
        img = Image.open(path)
        result = process(img)
        result.save(output_path)
        img.close()
        del img, result
        gc.collect()  # Force cleanup between large images

# 2. Work at target resolution, not source resolution
img = Image.open(path)
if img.size[0] > 2160 or img.size[1] > 2700:
    img.thumbnail((2160, 2700), Image.LANCZOS)  # 2x target for supersampling

# 3. Use float32 instead of float64 for ~half memory (usually sufficient)
arr = np.array(img).astype(np.float32) / 255.0  # vs np.float64

# 4. Process channels separately for very large images
r, g, b = img.split()
# Process each channel independently
```

### Data Type Consistency Rule

```
Pick your working format early and stay in it:
- uint8 [0-255]: ImageChops, simple operations, saving
- float32 [0.0-1.0]: blend modes, color grading, multi-step chains
- float64 [0.0-1.0]: only when precision matters (subtle color shifts)

Every conversion costs time. Avoid ping-ponging between types.
```

---

## 10. Golden Ratio & Fibonacci in Code

### Golden Ratio Grid for 1080x1350

```python
PHI = 1.6180339887  # Golden ratio

def golden_grid(width=1080, height=1350):
    """
    Calculate golden ratio grid lines and intersection points.
    Returns dict with grid lines and power points (intersections).
    """
    # Vertical golden divisions
    v1 = width / PHI                    # ~667.8
    v2 = width - (width / PHI)          # ~412.2

    # Horizontal golden divisions
    h1 = height / PHI                   # ~834.3
    h2 = height - (height / PHI)        # ~515.7

    # Further subdivisions
    v1a = v2 / PHI                      # ~254.7
    v2a = width - v1a                   # ~825.3
    h1a = h2 / PHI                      # ~318.7
    h2a = height - h1a                  # ~1031.3

    grid = {
        'vertical_lines': [v2, v1, v1a, v2a],
        'horizontal_lines': [h2, h1, h1a, h2a],
        'power_points': [
            # Primary intersections (strongest focal points)
            (v2, h2),     # Top-left power point
            (v1, h2),     # Top-right power point
            (v2, h1),     # Bottom-left power point
            (v1, h1),     # Bottom-right power point
            # Secondary intersections
            (v1a, h1a),
            (v2a, h1a),
            (v1a, h2a),
            (v2a, h2a),
        ],
        'center': (width / 2, height / 2),
    }
    return grid

# For 1080x1350:
# Primary power points: (412, 516), (668, 516), (412, 834), (668, 834)
```

### Phi-Based Type Hierarchy

```python
def phi_type_scale(base_size=16, levels=6):
    """
    Generate type sizes using golden ratio.
    Each step up is multiplied by phi.
    """
    sizes = []
    size = base_size
    for i in range(levels):
        sizes.append(round(size))
        size *= PHI

    return sizes

# Result: [16, 26, 42, 68, 110, 178]
# Perfect for: body(16), subtitle(26), h3(42), h2(68), h1(110), display(178)

def phi_spacing_scale(base=8):
    """Generate spacing values using golden ratio."""
    return {
        'xs': round(base),                           # 8
        'sm': round(base * PHI),                      # 13
        'md': round(base * PHI**2),                   # 21
        'lg': round(base * PHI**3),                   # 34
        'xl': round(base * PHI**4),                   # 55
        'xxl': round(base * PHI**5),                  # 89
    }
```

### Fibonacci Spiral for 1080x1350

```python
import math

def fibonacci_spiral_points(canvas_size=(1080, 1350), num_points=100):
    """
    Generate points along a Fibonacci/golden spiral for composition.
    Returns list of (x, y) coordinates.
    """
    w, h = canvas_size
    cx, cy = w / 2, h / 2

    points = []
    golden_angle = math.pi * (3 - math.sqrt(5))  # ~137.5 degrees

    for i in range(num_points):
        # Radius grows with sqrt(i) for even distribution
        r = math.sqrt(i) * min(w, h) / (2 * math.sqrt(num_points))
        theta = i * golden_angle

        x = cx + r * math.cos(theta)
        y = cy + r * math.sin(theta)
        points.append((x, y))

    return points

def golden_spiral_overlay(size=(1080, 1350)):
    """
    Draw golden spiral overlay for composition checking.
    Returns RGBA image with spiral drawn.
    """
    w, h = size
    overlay = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Fibonacci squares sequence
    fib = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]

    # Scale to fit canvas
    total = fib[-1]
    scale = min(w, h) / total

    x, y = 0, 0
    for i, size_val in enumerate(fib):
        s = size_val * scale

        # Draw square outline
        draw.rectangle([x, y, x + s, y + s], outline=(255, 0, 0, 80), width=1)

        # Draw quarter-circle arc in each square
        direction = i % 4
        if direction == 0:
            bbox = [x, y, x + 2*s, y + 2*s]
        elif direction == 1:
            bbox = [x - s, y, x + s, y + 2*s]
        elif direction == 2:
            bbox = [x - s, y - s, x + s, y + s]
        else:
            bbox = [x, y - s, x + 2*s, y + s]

        start = direction * 90
        draw.arc(bbox, start, start + 90, fill=(255, 215, 0, 120), width=2)

        # Move to next square position
        if direction == 0:
            x += s
        elif direction == 1:
            y += s
        elif direction == 2:
            x -= fib[i+1] * scale if i+1 < len(fib) else 0
        else:
            y -= fib[i+1] * scale if i+1 < len(fib) else 0

    return overlay
```

### Element Placement at Golden Intersections

```python
def place_at_golden_point(canvas_size=(1080, 1350), quadrant='top-left'):
    """
    Get the golden ratio intersection point for a given quadrant.
    Use these as anchor points for key visual elements.
    """
    w, h = canvas_size

    points = {
        'top-left':     (w / PHI**2, h / PHI**2),         # ~412, ~516
        'top-right':    (w - w / PHI**2, h / PHI**2),     # ~668, ~516
        'bottom-left':  (w / PHI**2, h - h / PHI**2),     # ~412, ~834
        'bottom-right': (w - w / PHI**2, h - h / PHI**2), # ~668, ~834
        'center-upper': (w / 2, h / PHI),                  # ~540, ~834
        'center-lower': (w / 2, h - h / PHI),              # ~540, ~516
    }

    return points.get(quadrant, points['center-upper'])
```

---

## Pillow Limitations — Honest Assessment

| Capability | Pillow Support | Workaround |
|------------|---------------|------------|
| Blend modes (multiply, screen, overlay) | **Native** via ImageChops | NumPy for full control |
| All 27 Photoshop blend modes | **Partial** (8 native) | NumPy or blend_modes package |
| S-curve / curves adjustment | **No** | LUT via `Image.point()` or pillow-lut |
| 3D LUT color grading | **Yes** via `Color3DLUT` filter | pillow-lut-tools for generation |
| HSL per-channel adjust | **Partial** (HSV convert) | NumPy + colorsys |
| Drop shadow | **No native** | GaussianBlur on offset alpha |
| Inner shadow | **No** | Inverted alpha + blur + mask |
| Gaussian blur | **Yes** via ImageFilter | — |
| Perlin noise | **No** | perlin-numpy package or pure NumPy |
| Text anti-aliasing | **Good** (not great) | 2x supersampling workaround |
| Curved text | **No** | Character-by-character rotation |
| Gradient text fill | **No** | Text mask + gradient composite |
| Stroked/outlined text | **Yes** (stroke_width, stroke_fill) | — |
| OpenType features | **Yes** (features= param) | — |
| Linear gradient | **Basic** (horizontal/vertical only) | NumPy for any angle |
| Radial gradient | **No** | NumPy distance calculation |
| Mesh gradient | **No** | NumPy inverse distance weighting |
| Alpha compositing | **Yes** (alpha_composite, composite) | — |
| Feathered masks | **No native** | GaussianBlur on mask |
| Luminosity masks | **No** | NumPy from grayscale |
| Vignette | **No** | NumPy radial gradient |
| Film grain | **Basic** (effect_noise) | NumPy for realistic grain |
| Chromatic aberration | **No** | Channel split + offset |
| Motion blur | **No directional** | Custom kernel via scipy |
| Bloom/glow | **No** | Threshold + blur + screen blend |

### Key Takeaway

Pillow is a solid foundation but requires NumPy for anything beyond basic operations. The pattern is:
1. **Use Pillow** for: I/O, basic compositing, text rendering, filters, format conversion
2. **Use NumPy** for: blend modes, color math, gradient generation, noise, masks
3. **Use scipy** for: custom convolution kernels, advanced interpolation
4. **Use pillow-lut** for: professional color grading with 3D LUTs
5. **Use blend_modes** package for: drop-in Photoshop-compatible blend modes

---

## Recommended Pip Installs

```bash
pip install Pillow numpy scipy
pip install blend-modes          # Photoshop blend modes with numpy
pip install pillow-lut           # 3D LUT generation and .cube file loading
pip install perlin-noise         # Simple Perlin noise
pip install filmgrainer          # Realistic film grain
pip install python-halftone      # Halftone dot patterns
```

---

## Sources

- [blend-modes PyPI](https://pypi.org/project/blend-modes/)
- [blend_modes GitHub](https://github.com/flrs/blend_modes)
- [Blend Modes Reference Documentation](https://blend-modes.readthedocs.io/en/latest/reference.html)
- [Blend Modes - Wikipedia](https://en.wikipedia.org/wiki/Blend_modes)
- [Image4Layer GitHub (CSS3 Blend Modes)](https://github.com/pashango2/Image4Layer)
- [Pillow ImageChops Documentation](https://pillow.readthedocs.io/en/stable/reference/ImageChops.html)
- [Pillow LUT Tools Documentation](https://pillow-lut-tools.readthedocs.io/)
- [pillow-lut-tools GitHub](https://github.com/homm/pillow-lut-tools)
- [Pillow ImageEnhance Documentation](https://pillow.readthedocs.io/en/stable/reference/ImageEnhance.html)
- [Pillow ImageDraw Documentation](https://pillow.readthedocs.io/en/stable/reference/ImageDraw.html)
- [Pillow ImageFont Documentation](https://pillow.readthedocs.io/en/stable/reference/ImageFont.html)
- [Pillow ImageFilter Documentation](https://pillow.readthedocs.io/en/stable/reference/ImageFilter.html)
- [Pillow Image Module Documentation](https://pillow.readthedocs.io/en/stable/reference/Image.html)
- [Pillow Text Anchors Documentation](https://pillow.readthedocs.io/en/stable/handbook/text-anchors.html)
- [Create Outline Text in Pillow](https://jdhao.github.io/2020/08/18/pillow_create_text_outline/)
- [Gradient Inside Text - Pillow Discussion #6688](https://github.com/python-pillow/Pillow/discussions/6688)
- [Generate Gradient Image with NumPy](https://note.nkmk.me/en/python-numpy-generate-gradation-image/)
- [Draw Gradient Color with Pillow (Gist)](https://gist.github.com/weihanglo/1e754ec47fdd683a42fdf6a272904535)
- [Composite Images with Pillow](https://note.nkmk.me/en/python-pillow-composite/)
- [Alpha Compositing in Pillow](https://jdhao.github.io/2022/04/01/image_alpha_composite_pillow/)
- [Drop Shadows with PIL (ActiveState)](https://code.activestate.com/recipes/474116-drop-shadows-with-pil/)
- [Drop Shadows - Python Imaging Library Wikibook](https://en.wikibooks.org/wiki/Python_Imaging_Library/Drop_Shadows)
- [Pillow Embossing Images](https://www.tutorialspoint.com/python_pillow/python_pillow_embossing_images.htm)
- [perlin-numpy GitHub](https://github.com/pvigier/perlin-numpy)
- [perlin-noise PyPI](https://pypi.org/project/perlin-noise/)
- [python-halftone GitHub](https://github.com/philgyford/python-halftone)
- [filmgrainer GitHub](https://github.com/larspontoppidan/filmgrainer)
- [Pillow effect_noise()](https://www.codecademy.com/resources/docs/pillow/image/effect-noise)
- [BloomEffect GitHub](https://github.com/yoyoberenguer/BloomEffect)
- [kromo - Chromatic Aberration Filter](https://github.com/yoonsikp/kromo)
- [duotone-py GitHub](https://github.com/carloe/duotone-py)
- [ImageOps Colour Effects (PythonInformer)](https://www.pythoninformer.com/python-libraries/pillow/imageops-colour-effects/)
- [Curved Text from Characters (DEV Community)](https://dev.to/dhruvkumardot/creating-curved-text-from-png-images-of-individual-characters-in-python-3a88)
- [Fast Pillow to NumPy Conversion (Uploadcare)](https://uploadcare.com/blog/fast-import-of-pillow-images-to-numpy-opencv-arrays/)
- [Mastering Color Manipulation with Pillow (Bomberbot)](https://www.bomberbot.com/python/mastering-color-manipulation-with-python-pillow-a-comprehensive-guide/)
- [Python Image Manipulation GitHub](https://github.com/ngnnah/python_image_manipulation)
- [Fibonacci Spiral with Python (Medium)](https://medium.com/internet-of-technology/exploring-the-fibonacci-spiral-with-python-and-matplotlib-2dac05a0f79e)
