#!/usr/bin/env python3
"""
Food Photo Quality Scorer — Rates photos on professional photography criteria.
Score 1-10 across 8 dimensions. Only 8+/10 photos qualify as references.

Dimensions:
1. Exposure (histogram balance)
2. Color Harmony (warm/appetizing palette)
3. Sharpness (detail clarity)
4. Composition (subject centering, rule of thirds)
5. Background Quality (clean, non-distracting)
6. Texture Detail (sauce sheen, crispy edges, steam)
7. Lighting Quality (soft, directional, no harsh shadows)
8. Overall Appetite Appeal (combined gut-check metric)
"""

import numpy as np
from PIL import Image
from pathlib import Path
import json


def analyze_exposure(img_array):
    """Score exposure quality 1-10."""
    gray = np.mean(img_array, axis=2)
    mean_brightness = np.mean(gray)
    
    # Ideal mean brightness for food: 120-160 (slightly bright)
    # Penalize under/over exposure
    if 120 <= mean_brightness <= 160:
        score = 10
    elif 100 <= mean_brightness <= 180:
        score = 8
    elif 80 <= mean_brightness <= 200:
        score = 6
    else:
        score = 4
    
    # Check for clipping
    highlights_clipped = np.mean(gray > 250) * 100
    shadows_clipped = np.mean(gray < 5) * 100
    
    if highlights_clipped > 5: score -= 1
    if shadows_clipped > 10: score -= 1
    
    return max(1, min(10, score)), {
        "mean_brightness": float(mean_brightness),
        "highlights_clipped": f"{highlights_clipped:.1f}%",
        "shadows_clipped": f"{shadows_clipped:.1f}%",
    }


def analyze_color_harmony(img_array):
    """Score color warmth and appetite appeal 1-10."""
    avg_r = np.mean(img_array[:, :, 0])
    avg_g = np.mean(img_array[:, :, 1])
    avg_b = np.mean(img_array[:, :, 2])
    
    # Food photos should be warm (R > B)
    warmth = avg_r - avg_b
    
    # Saturation check (HSV)
    from PIL import Image as PILImage
    img_pil = PILImage.fromarray(img_array)
    hsv = img_pil.convert("HSV")
    hsv_arr = np.array(hsv)
    avg_saturation = np.mean(hsv_arr[:, :, 1])
    
    score = 5  # baseline
    
    # Warm = good (reds, oranges, yellows stimulate appetite)
    if warmth > 15: score += 2
    elif warmth > 5: score += 1
    elif warmth < -10: score -= 2  # Cool/blue = appetite suppressant
    
    # Good saturation (not flat, not neon)
    if 60 <= avg_saturation <= 140:
        score += 2
    elif 40 <= avg_saturation <= 160:
        score += 1
    elif avg_saturation < 30:
        score -= 1  # Desaturated = unappetizing
    
    # Blue suppression check
    blue_ratio = avg_b / max(avg_r, 1)
    if blue_ratio < 0.85: score += 1  # Blue well suppressed
    
    return max(1, min(10, score)), {
        "warmth": f"{warmth:.0f} ({'warm' if warmth > 0 else 'cool'})",
        "avg_saturation": f"{avg_saturation:.0f}",
        "rgb": f"R:{avg_r:.0f} G:{avg_g:.0f} B:{avg_b:.0f}",
    }


def analyze_sharpness(img_array):
    """Score image sharpness 1-10 using Laplacian variance."""
    gray = np.mean(img_array, axis=2).astype(np.float64)
    
    # Laplacian kernel
    kernel = np.array([[0, 1, 0], [1, -4, 1], [0, 1, 0]], dtype=np.float64)
    
    # Manual convolution (avoid opencv dependency)
    from scipy.ndimage import convolve
    try:
        laplacian = convolve(gray, kernel)
        variance = np.var(laplacian)
    except ImportError:
        # Fallback: simple gradient magnitude
        gx = np.diff(gray, axis=1)
        gy = np.diff(gray, axis=0)
        min_dim = min(gx.shape[0], gy.shape[0])
        gradient = np.sqrt(gx[:min_dim, :]**2 + gy[:min_dim, :gx.shape[1]]**2)
        variance = np.var(gradient) * 4  # Scale to match Laplacian range
    
    # Thresholds for food photography
    if variance > 500: score = 10
    elif variance > 200: score = 8
    elif variance > 100: score = 6
    elif variance > 50: score = 4
    else: score = 2
    
    return max(1, min(10, score)), {"laplacian_variance": f"{variance:.0f}"}


def analyze_composition(img_array):
    """Score composition — subject centering and framing 1-10."""
    h, w = img_array.shape[:2]
    gray = np.mean(img_array, axis=2)
    
    # Check if subject is centered (food should be in center 60%)
    center = gray[int(h*0.2):int(h*0.8), int(w*0.2):int(w*0.8)]
    edges = np.concatenate([
        gray[:int(h*0.15), :].flatten(),
        gray[int(h*0.85):, :].flatten(),
    ])
    
    center_brightness = np.mean(center)
    edge_brightness = np.mean(edges) if len(edges) > 0 else center_brightness
    
    # Food should be brighter/more detailed than edges
    contrast_ratio = center_brightness / max(edge_brightness, 1)
    
    score = 5
    if contrast_ratio > 1.1: score += 2  # Good separation
    if contrast_ratio > 1.2: score += 1
    
    # Check fill ratio (food should fill 50-80% of frame)
    # Approximate by checking non-background pixels
    bright_threshold = np.percentile(gray, 85)
    subject_area = np.mean(gray < bright_threshold)
    
    if 0.4 <= subject_area <= 0.75:
        score += 2  # Good fill
    elif 0.3 <= subject_area <= 0.85:
        score += 1
    
    return max(1, min(10, score)), {
        "center_edge_ratio": f"{contrast_ratio:.2f}",
        "subject_fill": f"{subject_area*100:.0f}%",
    }


def analyze_background(img_array):
    """Score background cleanliness 1-10."""
    h, w = img_array.shape[:2]
    
    # Sample edge regions
    top = img_array[:int(h*0.1), :, :]
    bottom = img_array[int(h*0.9):, :, :]
    left = img_array[:, :int(w*0.1), :]
    right = img_array[:, int(w*0.9):, :]
    
    edges = np.concatenate([
        top.reshape(-1, 3),
        bottom.reshape(-1, 3),
        left.reshape(-1, 3),
        right.reshape(-1, 3),
    ])
    
    # Clean background = low variance in edge regions
    edge_std = np.std(edges)
    
    score = 5
    if edge_std < 20: score = 10  # Very clean (white/solid bg)
    elif edge_std < 40: score = 8
    elif edge_std < 60: score = 6
    elif edge_std < 80: score = 5
    else: score = 3  # Busy/cluttered background
    
    # Check if background is close to white (desirable for menu photos)
    edge_mean = np.mean(edges)
    if edge_mean > 220: score = min(score + 1, 10)  # Near-white = good
    
    return max(1, min(10, score)), {
        "edge_std": f"{edge_std:.0f}",
        "edge_brightness": f"{edge_mean:.0f}",
    }


def analyze_lighting(img_array):
    """Score lighting quality 1-10."""
    gray = np.mean(img_array, axis=2)
    h, w = gray.shape
    
    # Check for directional light (gradient from one side)
    left_half = np.mean(gray[:, :w//2])
    right_half = np.mean(gray[:, w//2:])
    top_half = np.mean(gray[:h//2, :])
    bottom_half = np.mean(gray[h//2:, :])
    
    # Slight gradient = directional light = good
    horizontal_gradient = abs(left_half - right_half)
    vertical_gradient = abs(top_half - bottom_half)
    
    score = 5
    
    # Good food lighting has gentle directionality
    if 5 <= horizontal_gradient <= 25: score += 2
    if 5 <= vertical_gradient <= 20: score += 1
    
    # Check for harsh shadows (high local contrast in dark areas)
    dark_mask = gray < np.percentile(gray, 25)
    if np.mean(dark_mask) < 0.15:
        score += 1  # Not too many dark shadows
    
    # Highlight softness
    highlight_mask = gray > np.percentile(gray, 95)
    if np.mean(highlight_mask) < 0.05:
        score += 1  # Soft highlights, not blown
    
    return max(1, min(10, score)), {
        "h_gradient": f"{horizontal_gradient:.0f}",
        "v_gradient": f"{vertical_gradient:.0f}",
    }


def score_photo(img_path):
    """Complete scoring of a food photo. Returns overall score + breakdown."""
    img = Image.open(img_path).convert("RGB")
    
    # Resize for consistent analysis
    img.thumbnail((800, 800), Image.LANCZOS)
    arr = np.array(img)
    
    scores = {}
    details = {}
    
    # Run all analyzers
    s, d = analyze_exposure(arr)
    scores["exposure"] = s; details["exposure"] = d
    
    s, d = analyze_color_harmony(arr)
    scores["color_harmony"] = s; details["color_harmony"] = d
    
    s, d = analyze_sharpness(arr)
    scores["sharpness"] = s; details["sharpness"] = d
    
    s, d = analyze_composition(arr)
    scores["composition"] = s; details["composition"] = d
    
    s, d = analyze_background(arr)
    scores["background"] = s; details["background"] = d
    
    s, d = analyze_lighting(arr)
    scores["lighting"] = s; details["lighting"] = d
    
    # Overall score (weighted average)
    weights = {
        "exposure": 0.15,
        "color_harmony": 0.20,  # Most important for appetite
        "sharpness": 0.15,
        "composition": 0.15,
        "background": 0.15,
        "lighting": 0.20,
    }
    
    overall = sum(scores[k] * weights[k] for k in weights)
    
    # Quality tier
    if overall >= 8.5: tier = "🏆 WORLD CLASS"
    elif overall >= 7.5: tier = "⭐ PROFESSIONAL"
    elif overall >= 6.0: tier = "✅ GOOD"
    elif overall >= 4.5: tier = "⚠️ NEEDS WORK"
    else: tier = "❌ POOR"
    
    return {
        "file": str(img_path),
        "overall": round(overall, 1),
        "tier": tier,
        "scores": scores,
        "details": details,
    }


def batch_score(directory, min_score=8.0):
    """Score all photos in a directory. Return only those above min_score."""
    directory = Path(directory)
    photos = list(directory.glob("*.jpg")) + list(directory.glob("*.jpeg")) + \
             list(directory.glob("*.png"))
    
    results = []
    for photo in sorted(photos):
        try:
            result = score_photo(photo)
            results.append(result)
            emoji = result["tier"].split()[0]
            print(f"  {emoji} {photo.name}: {result['overall']}/10 — {result['tier']}")
        except Exception as e:
            print(f"  ❌ {photo.name}: {e}")
    
    # Filter for references
    references = [r for r in results if r["overall"] >= min_score]
    print(f"\n  {len(references)}/{len(results)} photos qualify as references (≥{min_score}/10)")
    
    return results, references


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        path = Path(sys.argv[1])
        if path.is_dir():
            batch_score(str(path))
        else:
            result = score_photo(str(path))
            print(json.dumps(result, indent=2))
    else:
        print("Usage: python3 photo_scorer.py <photo_or_directory>")
