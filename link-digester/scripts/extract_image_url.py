#!/usr/bin/env python3
"""Extract the primary image URL from an HTML file.

Usage: python3 extract_image_url.py <html_file> <platform>
Prints the extracted image URL to stdout (empty string if none found).

Platform hints: pinterest, behance, dribbble, instagram, other
"""
import sys
import re
import json

def extract_image_url(html, platform):
    """Try multiple strategies to find the main image URL."""

    image_url = ""

    # ---- Strategy 1: og:image meta tag (universal) ----
    og_patterns = [
        r'<meta[^>]*property=["\']og:image["\'][^>]*content=["\']([^"\']+)["\']',
        r'<meta[^>]*content=["\']([^"\']+)["\'][^>]*property=["\']og:image["\']',
        r'<meta[^>]*name=["\']og:image["\'][^>]*content=["\']([^"\']+)["\']',
        r'<meta[^>]*content=["\']([^"\']+)["\'][^>]*name=["\']og:image["\']',
    ]
    for pat in og_patterns:
        m = re.search(pat, html, re.IGNORECASE)
        if m:
            image_url = m.group(1)
            break

    # ---- Strategy 2: JSON-LD structured data ----
    if not image_url:
        ld_pattern = r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>'
        for m in re.finditer(ld_pattern, html, re.DOTALL | re.IGNORECASE):
            try:
                data = json.loads(m.group(1))
                items = [data] if isinstance(data, dict) else (data if isinstance(data, list) else [])
                for item in items:
                    if not isinstance(item, dict):
                        continue
                    img = item.get("image", "")
                    if isinstance(img, str) and img.startswith("http"):
                        image_url = img
                        break
                    elif isinstance(img, list) and len(img) > 0:
                        first = img[0]
                        if isinstance(first, str) and first.startswith("http"):
                            image_url = first
                            break
                        elif isinstance(first, dict):
                            image_url = first.get("url", first.get("contentUrl", ""))
                            if image_url:
                                break
                    elif isinstance(img, dict):
                        image_url = img.get("url", img.get("contentUrl", ""))
                        if image_url:
                            break
                    if not image_url:
                        thumb = item.get("thumbnailUrl", "")
                        if isinstance(thumb, str) and thumb.startswith("http"):
                            image_url = thumb
                            break
                if image_url:
                    break
            except (json.JSONDecodeError, ValueError):
                continue

    # ---- Strategy 3: Platform-specific CDN URL patterns ----
    img_ext = r"(?:jpg|jpeg|png|webp)"
    img_ext_gif = r"(?:jpg|jpeg|png|webp|gif)"
    no_space = r'[^\s"\'<>]+'

    if not image_url and platform == "pinterest":
        # Try i.pinimg.com URLs, highest resolution first
        for prefix in ["originals/", "736x/", "564x/", ""]:
            pat = r"https?://i\.pinimg\.com/" + prefix + no_space + r"\." + img_ext
            m = re.search(pat, html)
            if m:
                image_url = m.group(0)
                break

    if not image_url and platform == "dribbble":
        pat = r"https?://cdn\.dribbble\.com/" + no_space + r"\." + img_ext_gif
        m = re.search(pat, html)
        if m:
            image_url = m.group(0)

    if not image_url and platform == "behance":
        pat = r"https?://mir-s3-cdn-cf\.behance\.net/" + no_space + r"\." + img_ext_gif
        m = re.search(pat, html)
        if m:
            image_url = m.group(0)

    # ---- Strategy 4: twitter:image meta tag fallback ----
    if not image_url:
        tw_patterns = [
            r'<meta[^>]*(?:property|name)=["\']twitter:image["\'][^>]*content=["\']([^"\']+)["\']',
            r'<meta[^>]*content=["\']([^"\']+)["\'][^>]*(?:property|name)=["\']twitter:image["\']',
        ]
        for pat in tw_patterns:
            m = re.search(pat, html, re.IGNORECASE)
            if m:
                image_url = m.group(1)
                break

    # Unescape HTML entities in URL
    if image_url:
        image_url = image_url.replace("&amp;", "&")

    return image_url


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 extract_image_url.py <html_file> <platform>", file=sys.stderr)
        sys.exit(1)

    html_file = sys.argv[1]
    platform = sys.argv[2]

    try:
        with open(html_file, "r", errors="replace") as f:
            html = f.read()
    except IOError as e:
        print("Error reading file: {}".format(e), file=sys.stderr)
        sys.exit(1)

    result = extract_image_url(html, platform)
    print(result)


if __name__ == "__main__":
    main()
