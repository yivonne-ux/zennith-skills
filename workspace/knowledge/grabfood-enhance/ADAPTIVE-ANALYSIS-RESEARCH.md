# Adaptive Image Quality Analyzer — Research & Code Patterns

> Python implementation patterns for automatic food photo analysis and adaptive enhancement recommendations.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Exposure Analysis](#2-exposure-analysis)
3. [White Balance & Color Temperature](#3-white-balance--color-temperature)
4. [Contrast Analysis](#4-contrast-analysis)
5. [Saturation Analysis](#5-saturation-analysis)
6. [Sharpness Detection](#6-sharpness-detection)
7. [Noise Level Estimation](#7-noise-level-estimation)
8. [Dominant Color Cast](#8-dominant-color-cast)
9. [Lighting Type Classification](#9-lighting-type-classification)
10. [Background Complexity](#10-background-complexity)
11. [Adaptive Recommendation Engine](#11-adaptive-recommendation-engine)
12. [Complete Analyzer Class](#12-complete-analyzer-class)
13. [Dependencies](#13-dependencies)

---

## 1. Architecture Overview

```
Input Image (BGR)
    |
    +-- Convert to LAB, HSV, Grayscale
    |
    +-- Per-channel histograms (R, G, B, L, S, V)
    |
    +-- Analysis modules (parallel, independent):
    |       Exposure | WB | Contrast | Saturation
    |       Sharpness | Noise | Color Cast | Lighting | BG
    |
    +-- Aggregate into AnalysisResult dict
    |
    +-- Recommendation engine (maps scores -> adjustments)
    |
    Output: { analysis: {...}, recommendations: {...} }
```

### Required imports

```python
import cv2
import numpy as np
from PIL import Image
from skimage.restoration import estimate_sigma
from skimage.filters import laplace
from skimage import img_as_float
from dataclasses import dataclass, field
from typing import Dict, Tuple, Optional
```

---

## 2. Exposure Analysis

**Goal:** Determine if image is underexposed, correctly exposed, or overexposed.

### Core technique: Luminance histogram percentile analysis

```python
def analyze_exposure(img_bgr: np.ndarray) -> dict:
    """
    Analyze exposure using LAB lightness channel.
    Returns exposure level and specific metrics.
    """
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB)
    L = lab[:, :, 0]  # Lightness channel, range 0-255

    mean_L = np.mean(L)
    median_L = np.median(L)
    std_L = np.std(L)

    # Percentile analysis — more robust than mean alone
    p5 = np.percentile(L, 5)
    p25 = np.percentile(L, 25)
    p75 = np.percentile(L, 75)
    p95 = np.percentile(L, 95)

    # Histogram for clipping detection
    hist = cv2.calcHist([L], [0], None, [256], [0, 256]).flatten()
    total_pixels = L.size

    # Clipping: pixels at extreme ends
    shadow_clip = np.sum(hist[:10]) / total_pixels   # % pixels near black
    highlight_clip = np.sum(hist[245:]) / total_pixels  # % pixels near white

    # Classification
    # Ideal mean_L for well-exposed image: ~120-140 (on 0-255 scale)
    if mean_L < 80:
        level = "underexposed"
        severity = (80 - mean_L) / 80  # 0-1 scale
    elif mean_L > 180:
        level = "overexposed"
        severity = (mean_L - 180) / 75
    else:
        level = "correct"
        severity = 0.0

    # EV adjustment estimate (stops of light)
    # Target mean_L ~127 (middle gray)
    target_L = 127
    if mean_L > 0:
        ev_adjustment = np.log2(target_L / mean_L)
    else:
        ev_adjustment = 3.0  # severely underexposed

    return {
        "level": level,
        "severity": min(severity, 1.0),
        "mean_luminance": float(mean_L),
        "median_luminance": float(median_L),
        "std_luminance": float(std_L),
        "shadow_clipping_pct": float(shadow_clip),
        "highlight_clipping_pct": float(highlight_clip),
        "ev_adjustment": float(np.clip(ev_adjustment, -3, 3)),
        "percentiles": {"p5": float(p5), "p25": float(p25),
                        "p75": float(p75), "p95": float(p95)}
    }
```

### Key thresholds

| Metric | Underexposed | Correct | Overexposed |
|--------|-------------|---------|-------------|
| mean_L | < 80 | 80-180 | > 180 |
| shadow_clip | > 0.15 | < 0.05 | — |
| highlight_clip | — | < 0.05 | > 0.15 |

### Brightness adjustment formula

```python
def calc_brightness_adjustment(mean_L: float, target: float = 127) -> float:
    """Returns multiplier for brightness correction."""
    if mean_L < 1:
        return 2.0
    ratio = target / mean_L
    # Clamp to reasonable range
    return float(np.clip(ratio, 0.5, 2.5))
```

---

## 3. White Balance & Color Temperature

**Goal:** Detect warm/cool cast and estimate approximate Kelvin temperature.

### Core technique: Gray-world assumption + LAB a/b channel analysis

```python
def analyze_white_balance(img_bgr: np.ndarray) -> dict:
    """
    Analyze white balance using LAB color space.
    LAB a channel: negative=green, positive=red/magenta
    LAB b channel: negative=blue, positive=yellow
    """
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB)
    L, a, b = cv2.split(lab)

    # a channel: 128 = neutral. <128 = green cast, >128 = magenta cast
    # b channel: 128 = neutral. <128 = blue/cool, >128 = yellow/warm
    mean_a = float(np.mean(a)) - 128  # Center around 0
    mean_b = float(np.mean(b)) - 128  # Center around 0

    # Gray-world assumption: average of all channels should be neutral gray
    avg_bgr = np.mean(img_bgr, axis=(0, 1))  # [B, G, R]
    avg_b_ch, avg_g_ch, avg_r_ch = avg_bgr

    # R/B ratio indicates color temperature
    # Higher R/B = warmer (tungsten ~2700K), Lower R/B = cooler (daylight ~6500K)
    if avg_b_ch > 0:
        rb_ratio = avg_r_ch / avg_b_ch
    else:
        rb_ratio = 1.0

    # Estimate Kelvin from R/B ratio (approximate)
    # These are empirical mappings, not physically precise
    kelvin = estimate_kelvin_from_rb(rb_ratio)

    # Classify temperature
    if mean_b > 8:
        temperature = "warm"
    elif mean_b < -8:
        temperature = "cool"
    else:
        temperature = "neutral"

    # Tint (green-magenta axis)
    if mean_a > 5:
        tint = "magenta"
    elif mean_a < -5:
        tint = "green"
    else:
        tint = "neutral"

    # WB correction: shift needed to neutralize
    wb_shift_warm_cool = -mean_b  # Positive = warm it up, negative = cool it down
    wb_shift_tint = -mean_a       # Positive = add magenta, negative = add green

    return {
        "temperature": temperature,
        "tint": tint,
        "kelvin_estimate": int(kelvin),
        "mean_a_offset": float(mean_a),  # green(-) to magenta(+)
        "mean_b_offset": float(mean_b),  # cool(-) to warm(+)
        "rb_ratio": float(rb_ratio),
        "correction_warm_cool": float(np.clip(wb_shift_warm_cool, -30, 30)),
        "correction_tint": float(np.clip(wb_shift_tint, -20, 20)),
        "avg_rgb": {"r": float(avg_r_ch), "g": float(avg_g_ch), "b": float(avg_b_ch)}
    }


def estimate_kelvin_from_rb(rb_ratio: float) -> float:
    """
    Approximate Kelvin from R/B ratio.
    Based on Tanner Helland's algorithm (reverse mapping).

    Empirical lookup (approximate):
      rb_ratio ~1.8 -> ~2700K (tungsten, very warm)
      rb_ratio ~1.3 -> ~4000K (warm white)
      rb_ratio ~1.0 -> ~5500K (daylight neutral)
      rb_ratio ~0.85 -> ~6500K (cloudy/cool)
      rb_ratio ~0.7 -> ~8000K (shade, blue sky)
      rb_ratio ~0.5 -> ~10000K+ (very cool)
    """
    # Piecewise linear interpolation
    points = [
        (2.0, 2000), (1.8, 2700), (1.5, 3500), (1.3, 4000),
        (1.1, 5000), (1.0, 5500), (0.9, 6000), (0.85, 6500),
        (0.75, 7500), (0.65, 9000), (0.5, 12000)
    ]
    # Sort by rb_ratio descending
    if rb_ratio >= points[0][0]:
        return points[0][1]
    if rb_ratio <= points[-1][0]:
        return points[-1][1]

    for i in range(len(points) - 1):
        r1, k1 = points[i]
        r2, k2 = points[i + 1]
        if r2 <= rb_ratio <= r1:
            t = (rb_ratio - r2) / (r1 - r2)
            return k1 * t + k2 * (1 - t)

    return 5500  # fallback
```

### Kelvin-to-RGB conversion (Tanner Helland algorithm)

```python
def kelvin_to_rgb(kelvin: float) -> Tuple[int, int, int]:
    """Convert color temperature to RGB. Valid range: 1000-40000K."""
    temp = kelvin / 100.0

    # Red
    if temp <= 66:
        red = 255
    else:
        red = 329.698727446 * ((temp - 60) ** -0.1332047592)

    # Green
    if temp <= 66:
        green = 99.4708025861 * np.log(temp) - 161.1195681661
    else:
        green = 288.1221695283 * ((temp - 60) ** -0.0755148492)

    # Blue
    if temp >= 66:
        blue = 255
    elif temp <= 19:
        blue = 0
    else:
        blue = 138.5177312231 * np.log(temp - 10) - 305.0447927307

    return (
        int(np.clip(red, 0, 255)),
        int(np.clip(green, 0, 255)),
        int(np.clip(blue, 0, 255))
    )
```

---

## 4. Contrast Analysis

**Goal:** Determine if image is flat, normal, or high contrast.

### Core technique: Histogram spread + percentile range in LAB L channel

```python
def analyze_contrast(img_bgr: np.ndarray) -> dict:
    """
    Analyze contrast using multiple metrics.
    """
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB)
    L = lab[:, :, 0].astype(np.float64)

    # 1. Standard deviation of luminance (primary metric)
    std_L = np.std(L)

    # 2. Percentile range (dynamic range)
    p2 = np.percentile(L, 2)
    p98 = np.percentile(L, 98)
    dynamic_range = p98 - p2  # 0-255 scale

    # 3. Michelson contrast (for more nuanced measurement)
    L_max = np.max(L)
    L_min = np.min(L)
    if (L_max + L_min) > 0:
        michelson = (L_max - L_min) / (L_max + L_min)
    else:
        michelson = 0

    # 4. RMS contrast
    mean_L = np.mean(L)
    rms_contrast = np.sqrt(np.mean((L - mean_L) ** 2)) / 255.0

    # Classification
    if std_L < 35:
        level = "flat"
        severity = (35 - std_L) / 35
    elif std_L > 70:
        level = "high"
        severity = (std_L - 70) / 30
    else:
        level = "normal"
        severity = 0.0

    # Recommendation: target std_L ~50-55 for food photography
    target_std = 52
    if std_L > 0:
        contrast_multiplier = target_std / std_L
    else:
        contrast_multiplier = 1.5

    return {
        "level": level,
        "severity": min(float(severity), 1.0),
        "std_luminance": float(std_L),
        "dynamic_range": float(dynamic_range),
        "michelson_contrast": float(michelson),
        "rms_contrast": float(rms_contrast),
        "contrast_multiplier": float(np.clip(contrast_multiplier, 0.6, 2.0)),
        "p2_p98_range": {"low": float(p2), "high": float(p98)}
    }
```

### Thresholds

| Metric | Flat | Normal | High |
|--------|------|--------|------|
| std_L | < 35 | 35-70 | > 70 |
| dynamic_range | < 120 | 120-220 | > 220 |
| rms_contrast | < 0.14 | 0.14-0.28 | > 0.28 |

### Adaptive contrast adjustment (CLAHE parameters)

```python
def calc_clahe_params(contrast_level: str, std_L: float) -> dict:
    """Recommend CLAHE parameters based on analysis."""
    if contrast_level == "flat":
        clip_limit = np.clip(3.0 + (35 - std_L) * 0.1, 2.0, 6.0)
        tile_size = (8, 8)
    elif contrast_level == "high":
        clip_limit = 1.0  # Gentle
        tile_size = (16, 16)  # Larger tiles = less local contrast
    else:
        clip_limit = 2.0
        tile_size = (8, 8)

    return {"clip_limit": float(clip_limit), "tile_grid_size": tile_size}
```

---

## 5. Saturation Analysis

**Goal:** Determine if colors are desaturated, normal, or oversaturated.

### Core technique: HSV saturation channel statistics

```python
def analyze_saturation(img_bgr: np.ndarray) -> dict:
    """
    Analyze saturation using HSV color space.
    """
    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    S = hsv[:, :, 1].astype(np.float64)  # Saturation, 0-255

    mean_S = np.mean(S)
    median_S = np.median(S)
    std_S = np.std(S)
    p10 = np.percentile(S, 10)
    p90 = np.percentile(S, 90)

    # Histogram of saturation for distribution shape
    hist = cv2.calcHist([hsv[:, :, 1]], [0], None, [256], [0, 256]).flatten()
    total = S.size

    # Check for oversaturation clipping
    oversat_pct = np.sum(hist[240:]) / total
    undersat_pct = np.sum(hist[:15]) / total

    # Classification
    # Food photography ideal: mean_S ~100-150 (vibrant but not neon)
    if mean_S < 60:
        level = "desaturated"
        severity = (60 - mean_S) / 60
    elif mean_S > 180:
        level = "oversaturated"
        severity = (mean_S - 180) / 75
    else:
        level = "normal"
        severity = 0.0

    # Saturation adjustment factor
    target_S = 120  # Good for food photography
    if mean_S > 0:
        sat_multiplier = target_S / mean_S
    else:
        sat_multiplier = 1.5

    return {
        "level": level,
        "severity": min(float(severity), 1.0),
        "mean_saturation": float(mean_S),
        "median_saturation": float(median_S),
        "std_saturation": float(std_S),
        "oversat_clipping_pct": float(oversat_pct),
        "undersat_clipping_pct": float(undersat_pct),
        "saturation_multiplier": float(np.clip(sat_multiplier, 0.5, 2.0)),
        "percentiles": {"p10": float(p10), "p90": float(p90)}
    }
```

### PIL-based saturation adjustment

```python
from PIL import ImageEnhance

def adjust_saturation_pil(img_pil: Image.Image, multiplier: float) -> Image.Image:
    """Apply saturation adjustment. 1.0 = no change."""
    enhancer = ImageEnhance.Color(img_pil)
    return enhancer.enhance(multiplier)
```

---

## 6. Sharpness Detection

**Goal:** Classify as blurry, soft, sharp, or oversharpened.

### Core technique: Laplacian variance (primary) + gradient magnitude (secondary)

```python
def analyze_sharpness(img_bgr: np.ndarray) -> dict:
    """
    Analyze sharpness using multiple methods.
    """
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)

    # 1. Variance of Laplacian (most reliable single metric)
    laplacian = cv2.Laplacian(gray, cv2.CV_64F)
    lap_var = laplacian.var()
    lap_mean = np.mean(np.abs(laplacian))

    # 2. Gradient magnitude (Sobel)
    sobelx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
    sobely = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
    gradient_mag = np.sqrt(sobelx**2 + sobely**2)
    mean_gradient = np.mean(gradient_mag)

    # 3. High-frequency energy (FFT-based)
    f_transform = np.fft.fft2(gray.astype(np.float64))
    f_shift = np.fft.fftshift(f_transform)
    magnitude = np.abs(f_shift)
    rows, cols = gray.shape
    crow, ccol = rows // 2, cols // 2
    # Mask out low frequencies (center 10%)
    r = int(min(rows, cols) * 0.1)
    mask = np.ones((rows, cols), dtype=bool)
    mask[crow-r:crow+r, ccol-r:ccol+r] = False
    hf_energy = np.mean(magnitude[mask])
    total_energy = np.mean(magnitude)
    hf_ratio = hf_energy / total_energy if total_energy > 0 else 0

    # 4. Tenengrad (Sobel-based focus measure)
    tenengrad = np.mean(sobelx**2 + sobely**2)

    # Classification
    # These thresholds work for 1080p food photos; scale for other resolutions
    if lap_var < 50:
        level = "blurry"
        severity = (50 - lap_var) / 50
    elif lap_var < 200:
        level = "soft"
        severity = (200 - lap_var) / 150
    elif lap_var > 1500:
        level = "oversharpened"
        severity = (lap_var - 1500) / 1000
    else:
        level = "sharp"
        severity = 0.0

    # Detect oversharpening halos
    # Oversharpened images have very high laplacian values at edges
    lap_p99 = np.percentile(np.abs(laplacian), 99)
    halo_indicator = lap_p99 / (lap_var + 1)  # High ratio = halo artifacts

    return {
        "level": level,
        "severity": min(float(severity), 1.0),
        "laplacian_variance": float(lap_var),
        "laplacian_mean": float(lap_mean),
        "mean_gradient": float(mean_gradient),
        "hf_energy_ratio": float(hf_ratio),
        "tenengrad": float(tenengrad),
        "halo_indicator": float(halo_indicator),
    }
```

### Resolution-adaptive thresholds

```python
def get_sharpness_thresholds(width: int, height: int) -> dict:
    """
    Laplacian variance scales with resolution.
    Base thresholds for 1080x1350 (IG feed).
    Scale proportionally for other sizes.
    """
    base_pixels = 1080 * 1350
    actual_pixels = width * height
    scale = actual_pixels / base_pixels

    return {
        "blurry": 50 * scale,
        "soft": 200 * scale,
        "sharp_min": 200 * scale,
        "oversharpened": 1500 * scale
    }
```

---

## 7. Noise Level Estimation

**Goal:** Quantify noise level as clean, slight, or noisy.

### Core technique: scikit-image `estimate_sigma` (wavelet-based)

```python
def analyze_noise(img_bgr: np.ndarray) -> dict:
    """
    Estimate noise level using wavelet-based sigma estimation.
    Uses scikit-image's estimate_sigma (median absolute deviation
    of wavelet detail coefficients).
    """
    # Convert to float [0, 1]
    img_float = img_as_float(img_bgr)

    # Estimate sigma per channel and average
    sigma_est = estimate_sigma(img_float, channel_axis=2, average_sigmas=True)

    # Per-channel breakdown
    sigma_channels = estimate_sigma(img_float, channel_axis=2, average_sigmas=False)

    # Also measure in grayscale
    gray_float = img_as_float(cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY))
    sigma_gray = estimate_sigma(gray_float, channel_axis=None)

    # Alternative: local variance method
    # Compute variance in small patches — high uniform variance = noise
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY).astype(np.float64)
    kernel_size = 5
    local_mean = cv2.blur(gray, (kernel_size, kernel_size))
    local_sqmean = cv2.blur(gray**2, (kernel_size, kernel_size))
    local_var = local_sqmean - local_mean**2
    # Noise estimate from smooth regions (low gradient areas)
    gradient = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)**2 + \
               cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)**2
    smooth_mask = gradient < np.percentile(gradient, 30)  # Bottom 30% gradient
    if np.sum(smooth_mask) > 100:
        noise_in_smooth = np.sqrt(np.mean(local_var[smooth_mask]))
    else:
        noise_in_smooth = 0

    # Classification (sigma is on 0-1 float scale)
    if sigma_est < 0.01:
        level = "clean"
        severity = 0.0
    elif sigma_est < 0.03:
        level = "slight"
        severity = (sigma_est - 0.01) / 0.02
    else:
        level = "noisy"
        severity = min((sigma_est - 0.03) / 0.05, 1.0)

    # Noise reduction strength recommendation
    # Maps to denoising filter strength parameter
    if level == "clean":
        denoise_h = 0
    elif level == "slight":
        denoise_h = int(np.clip(sigma_est * 300, 3, 7))
    else:
        denoise_h = int(np.clip(sigma_est * 300, 7, 15))

    return {
        "level": level,
        "severity": float(severity),
        "sigma_estimate": float(sigma_est),
        "sigma_per_channel": {
            "b": float(sigma_channels[0]),
            "g": float(sigma_channels[1]),
            "r": float(sigma_channels[2])
        },
        "sigma_grayscale": float(sigma_gray),
        "noise_in_smooth_regions": float(noise_in_smooth),
        "recommended_denoise_h": denoise_h  # For cv2.fastNlMeansDenoisingColored
    }
```

### Applying noise reduction

```python
def apply_denoising(img_bgr: np.ndarray, h: int) -> np.ndarray:
    """
    Apply Non-Local Means denoising.
    h: filter strength. Higher = more smoothing. 3-7 for slight, 7-15 for noisy.
    """
    if h <= 0:
        return img_bgr
    return cv2.fastNlMeansDenoisingColored(
        img_bgr,
        None,
        h=h,
        hForColorComponents=h,
        templateWindowSize=7,
        searchWindowSize=21
    )
```

---

## 8. Dominant Color Cast

**Goal:** Identify any unwanted color cast (yellow, blue, green, magenta, neutral).

### Core technique: LAB a/b deviation + per-channel histogram analysis

```python
def analyze_color_cast(img_bgr: np.ndarray) -> dict:
    """
    Detect dominant color cast using LAB color space.
    More granular than white balance analysis.
    """
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB)
    L, a, b = cv2.split(lab)

    # Center around 0 (128 = neutral in OpenCV's LAB)
    a_centered = a.astype(np.float64) - 128
    b_centered = b.astype(np.float64) - 128

    mean_a = np.mean(a_centered)
    mean_b = np.mean(b_centered)
    std_a = np.std(a_centered)
    std_b = np.std(b_centered)

    # Magnitude of cast
    cast_magnitude = np.sqrt(mean_a**2 + mean_b**2)

    # Direction of cast (angle in LAB a-b plane)
    cast_angle = np.degrees(np.arctan2(mean_b, mean_a))  # -180 to 180

    # Classify cast direction
    # LAB a-b plane:
    #   a+, b+ = warm/orange-yellow
    #   a+, b- = magenta/pink
    #   a-, b+ = yellow-green
    #   a-, b- = blue-cyan/cool
    if cast_magnitude < 3:
        cast = "neutral"
    elif mean_b > 5 and abs(mean_a) < mean_b:
        cast = "yellow"
    elif mean_b < -5 and abs(mean_a) < abs(mean_b):
        cast = "blue"
    elif mean_a < -5 and abs(mean_b) < abs(mean_a):
        cast = "green"
    elif mean_a > 5 and mean_b > 3:
        cast = "orange"
    elif mean_a > 5 and mean_b < -3:
        cast = "magenta"
    else:
        cast = "slight"  # Ambiguous direction

    # Per-channel mean (RGB) — another perspective
    avg_bgr = np.mean(img_bgr, axis=(0, 1))
    channel_balance = {
        "b": float(avg_bgr[0]),
        "g": float(avg_bgr[1]),
        "r": float(avg_bgr[2])
    }

    # Correction vector (negate the cast to correct it)
    correction_a = -mean_a
    correction_b = -mean_b

    return {
        "cast": cast,
        "cast_magnitude": float(cast_magnitude),
        "cast_angle_degrees": float(cast_angle),
        "mean_a": float(mean_a),
        "mean_b": float(mean_b),
        "std_a": float(std_a),
        "std_b": float(std_b),
        "channel_balance_bgr": channel_balance,
        "correction_a": float(np.clip(correction_a, -20, 20)),
        "correction_b": float(np.clip(correction_b, -20, 20))
    }
```

### Applying color cast correction in LAB

```python
def correct_color_cast(img_bgr: np.ndarray, corr_a: float, corr_b: float,
                       strength: float = 0.7) -> np.ndarray:
    """
    Apply color cast correction in LAB space.
    strength: 0-1, how much of the correction to apply (0.7 = 70%).
    """
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB).astype(np.float64)
    lab[:, :, 1] += corr_a * strength  # a channel
    lab[:, :, 2] += corr_b * strength  # b channel
    lab = np.clip(lab, 0, 255).astype(np.uint8)
    return cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
```

---

## 9. Lighting Type Classification

**Goal:** Classify as natural, fluorescent, tungsten, or flash lighting.

### Core technique: Color temperature + highlight analysis + histogram shape

```python
def analyze_lighting(img_bgr: np.ndarray) -> dict:
    """
    Classify lighting type based on multiple cues.
    Not perfectly reliable — best-guess classification.
    """
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB)
    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    L = lab[:, :, 0].astype(np.float64)
    a = lab[:, :, 1].astype(np.float64) - 128
    b = lab[:, :, 2].astype(np.float64) - 128
    S = hsv[:, :, 1].astype(np.float64)

    mean_b = np.mean(b)
    mean_a = np.mean(a)
    mean_L = np.mean(L)

    # --- Cue 1: Color temperature (from WB analysis) ---
    avg_bgr = np.mean(img_bgr, axis=(0, 1))
    rb_ratio = avg_bgr[2] / (avg_bgr[0] + 1e-6)  # R/B
    kelvin = estimate_kelvin_from_rb(rb_ratio)

    # --- Cue 2: Highlight analysis (flash detection) ---
    # Flash creates bright specular highlights with neutral color
    bright_mask = L > 230  # Very bright areas
    bright_pct = np.sum(bright_mask) / L.size

    if np.sum(bright_mask) > 50:
        bright_sat = np.mean(S[bright_mask])  # Low sat highlights = flash
    else:
        bright_sat = 128

    # --- Cue 3: Shadow characteristics ---
    dark_mask = L < 40
    dark_pct = np.sum(dark_mask) / L.size

    # --- Cue 4: Luminance histogram shape ---
    hist_L = cv2.calcHist([lab[:, :, 0]], [0], None, [256], [0, 256]).flatten()
    hist_L = hist_L / hist_L.sum()

    # Bimodal histogram suggests flash (bright subject + dark background)
    top_half_energy = np.sum(hist_L[128:])
    bottom_half_energy = np.sum(hist_L[:128])
    if top_half_energy > 0 and bottom_half_energy > 0:
        bimodality = min(top_half_energy, bottom_half_energy) / max(top_half_energy, bottom_half_energy)
    else:
        bimodality = 0

    # --- Cue 5: Green tint (fluorescent indicator) ---
    green_cast = mean_a < -3  # Green shift in LAB a channel

    # --- Classification logic ---
    scores = {
        "natural": 0.0,
        "tungsten": 0.0,
        "fluorescent": 0.0,
        "flash": 0.0
    }

    # Natural: daylight kelvin (5000-7000K), moderate contrast
    if 4500 < kelvin < 7500:
        scores["natural"] += 3.0
    if 35 < np.std(L) < 65:
        scores["natural"] += 1.0

    # Tungsten: warm (2500-3500K), high R/B ratio
    if kelvin < 3800:
        scores["tungsten"] += 3.0
    if mean_b > 10:
        scores["tungsten"] += 1.5

    # Fluorescent: green tint, mid-range kelvin
    if green_cast:
        scores["fluorescent"] += 3.0
    if 3500 < kelvin < 5500 and mean_a < -2:
        scores["fluorescent"] += 2.0

    # Flash: bright highlights with low saturation, high contrast
    if bright_pct > 0.02 and bright_sat < 40:
        scores["flash"] += 3.0
    if dark_pct > 0.15 and bright_pct > 0.01:
        scores["flash"] += 1.5  # Sharp falloff = flash
    if np.std(L) > 60:
        scores["flash"] += 1.0

    lighting_type = max(scores, key=scores.get)
    confidence = scores[lighting_type] / (sum(scores.values()) + 1e-6)

    return {
        "type": lighting_type,
        "confidence": float(confidence),
        "scores": {k: float(v) for k, v in scores.items()},
        "kelvin_estimate": int(kelvin),
        "highlight_pct": float(bright_pct),
        "highlight_saturation": float(bright_sat),
        "shadow_pct": float(dark_pct),
        "green_tint": bool(green_cast),
    }
```

---

## 10. Background Complexity

**Goal:** Classify background as clean, busy, dark, or light.

### Core technique: Edge density + variance in periphery regions

```python
def analyze_background(img_bgr: np.ndarray) -> dict:
    """
    Analyze background complexity.
    Assumes food subject is roughly centered.
    Analyzes border/periphery regions.
    """
    h, w = img_bgr.shape[:2]
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)

    # Define periphery mask (outer 25% on each side)
    margin_y = int(h * 0.25)
    margin_x = int(w * 0.25)
    periphery_mask = np.zeros((h, w), dtype=bool)
    periphery_mask[:margin_y, :] = True   # Top
    periphery_mask[-margin_y:, :] = True  # Bottom
    periphery_mask[:, :margin_x] = True   # Left
    periphery_mask[:, -margin_x:] = True  # Right

    periphery = gray[periphery_mask].astype(np.float64)

    # 1. Luminance of periphery
    bg_mean_L = np.mean(periphery)
    bg_std_L = np.std(periphery)

    # 2. Edge density in periphery
    edges = cv2.Canny(gray, 50, 150)
    edge_density_full = np.sum(edges > 0) / edges.size
    edge_density_bg = np.sum(edges[periphery_mask] > 0) / np.sum(periphery_mask)

    # 3. Texture complexity (local variance)
    local_var = cv2.blur(gray.astype(np.float64)**2, (15, 15)) - \
                cv2.blur(gray.astype(np.float64), (15, 15))**2
    bg_texture = np.mean(local_var[periphery_mask])

    # 4. Color variety in background (HSV hue std)
    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    bg_hue_std = np.std(hsv[:, :, 0][periphery_mask])

    # Classification
    if bg_mean_L < 50:
        bg_type = "dark"
    elif bg_mean_L > 200:
        bg_type = "light"
    elif edge_density_bg > 0.08 or bg_std_L > 50:
        bg_type = "busy"
    else:
        bg_type = "clean"

    # Complexity score 0-1
    complexity = float(np.clip(
        (edge_density_bg * 5 + bg_std_L / 80 + bg_hue_std / 60) / 3,
        0, 1
    ))

    return {
        "type": bg_type,
        "complexity_score": complexity,
        "mean_luminance": float(bg_mean_L),
        "std_luminance": float(bg_std_L),
        "edge_density": float(edge_density_bg),
        "texture_variance": float(bg_texture),
        "hue_variety": float(bg_hue_std),
    }
```

---

## 11. Adaptive Recommendation Engine

**Goal:** Convert analysis results into specific, actionable adjustments.

```python
def generate_recommendations(analysis: dict) -> dict:
    """
    Generate specific adjustment recommendations based on all analysis modules.
    Returns adjustment parameters ready to apply.
    """
    recs = {}

    # --- Exposure ---
    exp = analysis["exposure"]
    if exp["level"] == "underexposed":
        recs["brightness"] = {
            "action": "increase",
            "multiplier": exp["ev_adjustment"],
            "method": "gamma" if exp["severity"] < 0.5 else "curves",
            "gamma_value": 1.0 / (1.0 - exp["severity"] * 0.4),  # Lighten
            "description": f"Brighten by ~{exp['ev_adjustment']:.1f} EV"
        }
    elif exp["level"] == "overexposed":
        recs["brightness"] = {
            "action": "decrease",
            "multiplier": exp["ev_adjustment"],
            "method": "gamma",
            "gamma_value": 1.0 + exp["severity"] * 0.5,  # Darken
            "description": f"Darken by ~{abs(exp['ev_adjustment']):.1f} EV"
        }

    # --- White Balance ---
    wb = analysis["white_balance"]
    if wb["temperature"] != "neutral" or wb["tint"] != "neutral":
        recs["white_balance"] = {
            "action": "correct",
            "shift_warm_cool": wb["correction_warm_cool"],
            "shift_tint": wb["correction_tint"],
            "current_kelvin": wb["kelvin_estimate"],
            "target_kelvin": 5500,
            "method": "lab_shift",
            "description": f"Shift {'warmer' if wb['correction_warm_cool'] > 0 else 'cooler'} "
                           f"by {abs(wb['correction_warm_cool']):.0f} units"
        }

    # --- Contrast ---
    con = analysis["contrast"]
    if con["level"] != "normal":
        clahe_params = calc_clahe_params(con["level"], con["std_luminance"])
        recs["contrast"] = {
            "action": "increase" if con["level"] == "flat" else "decrease",
            "multiplier": con["contrast_multiplier"],
            "clahe_clip_limit": clahe_params["clip_limit"],
            "clahe_tile_size": clahe_params["tile_grid_size"],
            "method": "clahe" if con["level"] == "flat" else "gamma_compress",
            "description": f"{'Add' if con['level'] == 'flat' else 'Reduce'} contrast "
                           f"(current std: {con['std_luminance']:.0f})"
        }

    # --- Saturation ---
    sat = analysis["saturation"]
    if sat["level"] != "normal":
        recs["saturation"] = {
            "action": "increase" if sat["level"] == "desaturated" else "decrease",
            "multiplier": sat["saturation_multiplier"],
            "method": "pil_enhance",
            "description": f"{'Boost' if sat['level'] == 'desaturated' else 'Reduce'} "
                           f"saturation by {abs(sat['saturation_multiplier'] - 1) * 100:.0f}%"
        }

    # --- Sharpness ---
    sharp = analysis["sharpness"]
    if sharp["level"] in ("blurry", "soft"):
        # Unsharp mask parameters
        strength = 0.5 + sharp["severity"] * 1.0
        recs["sharpness"] = {
            "action": "sharpen",
            "method": "unsharp_mask",
            "radius": 1.5 if sharp["level"] == "soft" else 2.0,
            "amount": float(np.clip(strength, 0.3, 2.0)),
            "threshold": 3,
            "description": f"Apply unsharp mask (amount: {strength:.1f})"
        }
    elif sharp["level"] == "oversharpened":
        recs["sharpness"] = {
            "action": "blur_slightly",
            "method": "gaussian",
            "sigma": 0.5 + sharp["severity"] * 0.5,
            "description": "Apply slight Gaussian blur to reduce halo artifacts"
        }

    # --- Noise ---
    noise = analysis["noise"]
    if noise["level"] != "clean":
        recs["noise_reduction"] = {
            "action": "denoise",
            "method": "nlmeans",
            "h_luminance": noise["recommended_denoise_h"],
            "h_color": noise["recommended_denoise_h"],
            "description": f"Apply NLMeans denoising (h={noise['recommended_denoise_h']})"
        }

    # --- Color Cast ---
    cast = analysis["color_cast"]
    if cast["cast"] != "neutral":
        recs["color_cast"] = {
            "action": "neutralize",
            "method": "lab_shift",
            "correction_a": cast["correction_a"],
            "correction_b": cast["correction_b"],
            "strength": 0.7,  # Don't fully neutralize — preserve some character
            "description": f"Reduce {cast['cast']} cast (magnitude: {cast['cast_magnitude']:.1f})"
        }

    # --- Processing order recommendation ---
    recs["processing_order"] = [
        "noise_reduction",      # First: reduce noise before other operations
        "white_balance",        # Then: correct color
        "color_cast",           # Then: fine-tune color
        "brightness",           # Then: fix exposure
        "contrast",             # Then: adjust contrast
        "saturation",           # Then: color vibrancy
        "sharpness",            # Last: sharpen (after all other processing)
    ]

    return recs
```

---

## 12. Complete Analyzer Class

```python
class AdaptiveImageAnalyzer:
    """
    Complete adaptive image quality analyzer for food photography.

    Usage:
        analyzer = AdaptiveImageAnalyzer()
        result = analyzer.analyze("food_photo.jpg")
        print(result["analysis"]["exposure"])
        print(result["recommendations"])
    """

    def __init__(self, food_photo_mode: bool = True):
        """
        Args:
            food_photo_mode: Use thresholds optimized for food photography.
        """
        self.food_photo_mode = food_photo_mode

    def analyze(self, image_path: str) -> dict:
        """Run full analysis pipeline on an image."""
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError(f"Could not read image: {image_path}")

        return self.analyze_array(img)

    def analyze_array(self, img_bgr: np.ndarray) -> dict:
        """Run full analysis pipeline on a BGR numpy array."""
        analysis = {
            "exposure": analyze_exposure(img_bgr),
            "white_balance": analyze_white_balance(img_bgr),
            "contrast": analyze_contrast(img_bgr),
            "saturation": analyze_saturation(img_bgr),
            "sharpness": analyze_sharpness(img_bgr),
            "noise": analyze_noise(img_bgr),
            "color_cast": analyze_color_cast(img_bgr),
            "lighting": analyze_lighting(img_bgr),
            "background": analyze_background(img_bgr),
        }

        recommendations = generate_recommendations(analysis)

        # Overall quality score (0-100)
        quality_score = self._compute_quality_score(analysis)

        return {
            "analysis": analysis,
            "recommendations": recommendations,
            "quality_score": quality_score,
            "image_size": {
                "width": img_bgr.shape[1],
                "height": img_bgr.shape[0]
            }
        }

    def _compute_quality_score(self, analysis: dict) -> float:
        """
        Compute overall quality score 0-100.
        Higher = better quality, fewer issues.
        """
        penalties = 0.0

        # Exposure penalty
        if analysis["exposure"]["level"] != "correct":
            penalties += analysis["exposure"]["severity"] * 25

        # WB penalty
        wb_mag = abs(analysis["white_balance"]["mean_b_offset"]) + \
                 abs(analysis["white_balance"]["mean_a_offset"])
        penalties += min(wb_mag / 3, 15)

        # Contrast penalty
        if analysis["contrast"]["level"] != "normal":
            penalties += analysis["contrast"]["severity"] * 15

        # Saturation penalty
        if analysis["saturation"]["level"] != "normal":
            penalties += analysis["saturation"]["severity"] * 10

        # Sharpness penalty
        if analysis["sharpness"]["level"] in ("blurry", "oversharpened"):
            penalties += analysis["sharpness"]["severity"] * 20
        elif analysis["sharpness"]["level"] == "soft":
            penalties += analysis["sharpness"]["severity"] * 10

        # Noise penalty
        if analysis["noise"]["level"] != "clean":
            penalties += analysis["noise"]["severity"] * 15

        # Color cast penalty
        penalties += min(analysis["color_cast"]["cast_magnitude"] / 2, 10)

        return float(max(100 - penalties, 0))

    def apply_recommendations(self, img_bgr: np.ndarray,
                               recommendations: dict,
                               strength: float = 1.0) -> np.ndarray:
        """
        Apply recommended adjustments to image.
        strength: 0-1, how aggressively to apply corrections.
        """
        result = img_bgr.copy()
        order = recommendations.get("processing_order", [])

        for step in order:
            if step not in recommendations:
                continue

            rec = recommendations[step]
            s = strength  # Scale all adjustments

            if step == "noise_reduction" and rec.get("method") == "nlmeans":
                h = int(rec["h_luminance"] * s)
                if h > 0:
                    result = cv2.fastNlMeansDenoisingColored(
                        result, None, h, h, 7, 21
                    )

            elif step == "white_balance" and rec.get("method") == "lab_shift":
                lab = cv2.cvtColor(result, cv2.COLOR_BGR2LAB).astype(np.float64)
                lab[:, :, 2] += rec["shift_warm_cool"] * s  # b channel
                lab[:, :, 1] += rec["shift_tint"] * s        # a channel
                lab = np.clip(lab, 0, 255).astype(np.uint8)
                result = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)

            elif step == "color_cast" and rec.get("method") == "lab_shift":
                corr_strength = rec.get("strength", 0.7) * s
                result = correct_color_cast(
                    result, rec["correction_a"], rec["correction_b"], corr_strength
                )

            elif step == "brightness":
                gamma = rec.get("gamma_value", 1.0)
                gamma = 1.0 + (gamma - 1.0) * s  # Scale toward 1.0
                if gamma != 1.0:
                    inv_gamma = 1.0 / gamma
                    table = np.array([
                        ((i / 255.0) ** inv_gamma) * 255
                        for i in range(256)
                    ]).astype("uint8")
                    result = cv2.LUT(result, table)

            elif step == "contrast" and rec.get("method") == "clahe":
                clip = rec.get("clahe_clip_limit", 2.0)
                clip = 1.0 + (clip - 1.0) * s
                tile = rec.get("clahe_tile_size", (8, 8))
                lab = cv2.cvtColor(result, cv2.COLOR_BGR2LAB)
                clahe = cv2.createCLAHE(clipLimit=clip, tileGridSize=tile)
                lab[:, :, 0] = clahe.apply(lab[:, :, 0])
                result = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)

            elif step == "saturation":
                mult = rec.get("multiplier", 1.0)
                mult = 1.0 + (mult - 1.0) * s
                hsv = cv2.cvtColor(result, cv2.COLOR_BGR2HSV).astype(np.float64)
                hsv[:, :, 1] *= mult
                hsv[:, :, 1] = np.clip(hsv[:, :, 1], 0, 255)
                result = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR)

            elif step == "sharpness":
                if rec.get("action") == "sharpen":
                    radius = rec.get("radius", 1.5)
                    amount = rec.get("amount", 1.0) * s
                    blurred = cv2.GaussianBlur(result, (0, 0), radius)
                    result = cv2.addWeighted(result, 1.0 + amount, blurred, -amount, 0)
                elif rec.get("action") == "blur_slightly":
                    sigma = rec.get("sigma", 0.5) * s
                    result = cv2.GaussianBlur(result, (0, 0), sigma)

        return result
```

### Usage example

```python
# Analyze
analyzer = AdaptiveImageAnalyzer(food_photo_mode=True)
result = analyzer.analyze("/path/to/food_photo.jpg")

# Print summary
a = result["analysis"]
print(f"Quality Score: {result['quality_score']:.0f}/100")
print(f"Exposure: {a['exposure']['level']} (mean L: {a['exposure']['mean_luminance']:.0f})")
print(f"White Balance: {a['white_balance']['temperature']} (~{a['white_balance']['kelvin_estimate']}K)")
print(f"Contrast: {a['contrast']['level']} (std: {a['contrast']['std_luminance']:.0f})")
print(f"Saturation: {a['saturation']['level']} (mean S: {a['saturation']['mean_saturation']:.0f})")
print(f"Sharpness: {a['sharpness']['level']} (lap var: {a['sharpness']['laplacian_variance']:.0f})")
print(f"Noise: {a['noise']['level']} (sigma: {a['noise']['sigma_estimate']:.4f})")
print(f"Color Cast: {a['color_cast']['cast']} (magnitude: {a['color_cast']['cast_magnitude']:.1f})")
print(f"Lighting: {a['lighting']['type']} ({a['lighting']['confidence']:.0%})")
print(f"Background: {a['background']['type']} (complexity: {a['background']['complexity_score']:.2f})")

# Print recommendations
for key, rec in result["recommendations"].items():
    if key != "processing_order" and isinstance(rec, dict):
        print(f"  -> {key}: {rec.get('description', '')}")

# Apply corrections
img = cv2.imread("/path/to/food_photo.jpg")
corrected = analyzer.apply_recommendations(img, result["recommendations"], strength=0.8)
cv2.imwrite("/path/to/corrected.jpg", corrected)
```

---

## 13. Dependencies

```
pip install opencv-python numpy Pillow scikit-image
```

| Library | Version | Purpose |
|---------|---------|---------|
| opencv-python | >= 4.5 | Histogram, LAB/HSV conversion, CLAHE, Canny, Laplacian, denoising |
| numpy | >= 1.21 | All statistical operations, array math |
| Pillow | >= 9.0 | ImageEnhance for saturation, format I/O |
| scikit-image | >= 0.19 | `estimate_sigma` (wavelet noise estimation), `img_as_float` |

### Optional (not required but useful)

| Library | Purpose |
|---------|---------|
| scipy | `scipy.stats` for histogram matching, statistical tests |
| rawpy | RAW file support for higher quality analysis |
| colour-science | Accurate color temperature / CRI calculations |

---

## Key Numerical Reference

### LAB Color Space (OpenCV encoding)

- L: 0-255 (lightness, 0=black, 255=white)
- a: 0-255 (128=neutral, <128=green, >128=red/magenta)
- b: 0-255 (128=neutral, <128=blue/cool, >128=yellow/warm)

### HSV Color Space (OpenCV encoding)

- H: 0-179 (hue, 0=red, 30=yellow, 60=green, 90=cyan, 120=blue, 150=magenta)
- S: 0-255 (saturation, 0=gray, 255=pure color)
- V: 0-255 (value/brightness)

### Food Photography Ideal Ranges

| Metric | Ideal Range | Notes |
|--------|-------------|-------|
| mean_L | 110-150 | Slightly bright, appetizing |
| std_L | 40-60 | Moderate contrast |
| mean_S | 100-150 | Vibrant but not neon |
| Kelvin | 4500-6000 | Slightly warm of daylight |
| sigma_noise | < 0.015 | Clean |
| lap_var | 300-1000 | Sharp but natural |

---

## Sources

- [Automatic Color Correction with OpenCV - PyImageSearch](https://pyimagesearch.com/2021/02/15/automatic-color-correction-with-opencv-and-python/)
- [Image Quality Assessment: BRISQUE - LearnOpenCV](https://learnopencv.com/image-quality-assessment-brisque/)
- [OpenCV Histogram Equalization and CLAHE - PyImageSearch](https://pyimagesearch.com/2021/02/01/opencv-histogram-equalization-and-adaptive-histogram-equalization-clahe/)
- [image-quality PyPI](https://pypi.org/project/image-quality/)
- [Correcting Image White Balance with Python PIL and Numpy](https://codeandlife.com/2019/08/17/correcting-image-white-balance-with-python-pil-and-numpy/)
- [Kelvin to RGB - Tanner Helland Algorithm](https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html)
- [Kelvin to RGB Python Gist](https://gist.github.com/petrklus/b1f427accdf7438606a6)
- [Color Temperature Estimation - Image.sc Forum](https://forum.image.sc/t/how-to-calculate-measure-the-color-temperature-of-an-image/50359)
- [Blur Detection Using Laplacian Variance - TheAILearner](https://theailearner.com/2021/10/30/blur-detection-using-the-variance-of-the-laplacian-method/)
- [scikit-image Denoising (estimate_sigma)](https://scikit-image.org/docs/stable/auto_examples/filters/plot_denoise.html)
- [skimage.restoration API (estimate_sigma)](https://scikit-image.org/docs/stable/api/skimage.restoration.html)
- [Noise Estimation ICCV 2015 - GitHub](https://github.com/zsyOAOA/noise_est_ICCV2015)
- [Top 4 Methods for Auto Brightness/Contrast - SQLPey](https://sqlpey.com/python/top-4-methods-to-automatically-adjust-brightness-and-contrast/)
- [OpenCV White Balance Algorithms](https://docs.opencv.org/3.0-beta/modules/xphoto/doc/colorbalance/whitebalance.html)
- [How to Evaluate Image Quality in Python - Medium](https://medium.com/@jaikochhar06/how-to-evaluate-image-quality-in-python-a-comprehensive-guide-e486a0aa1f60)
- [Simple Color Balance Algorithm - GitHub Gist](https://gist.github.com/hobson/e3b8805a558d974d48336e133dfb2bdd)
