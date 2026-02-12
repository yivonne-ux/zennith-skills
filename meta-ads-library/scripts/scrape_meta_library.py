#!/usr/bin/env python3
"""Meta Ad Library scraper using Playwright.

Scrapes facebook.com/ads/library (public, no auth required) for:
- Competitor ad creatives
- Ad copy and CTAs
- Active/inactive status
- Landing page URLs

Usage:
    python3 scrape_meta_library.py --keyword "vegan food" --country MY --max-results 20
    python3 scrape_meta_library.py --advertiser "Green Monday" --country MY
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


def check_playwright():
    try:
        from playwright.sync_api import sync_playwright
        return True
    except ImportError:
        print("Error: playwright not installed. Run: pip3 install playwright && python3 -m playwright install chromium")
        return False


def build_url(keyword: str | None, advertiser: str | None, country: str = "MY") -> str:
    """Build Meta Ad Library search URL."""
    base = "https://www.facebook.com/ads/library/"
    params = [
        f"active_status=active",
        f"ad_type=all",
        f"country={country}",
        f"media_type=all",
    ]
    if keyword:
        params.append(f"q={keyword}")
    if advertiser:
        params.append(f"q={advertiser}")
    return base + "?" + "&".join(params)


def scrape_ads(keyword: str | None, advertiser: str | None, country: str = "MY",
               max_results: int = 20, output_dir: str = "/tmp/meta-ads",
               screenshots: bool = True) -> dict:
    """Scrape Meta Ad Library and return structured results."""
    from playwright.sync_api import sync_playwright

    os.makedirs(output_dir, exist_ok=True)
    url = build_url(keyword, advertiser, country)
    ads = []

    print(f"[meta-ads] Navigating to: {url}")
    print(f"[meta-ads] Target: {max_results} ads, country: {country}")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1280, "height": 900},
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        )
        page = context.new_page()

        try:
            page.goto(url, wait_until="networkidle", timeout=30000)
            time.sleep(3)  # Let JS render

            # Dismiss cookie/login popups if they appear
            for selector in ['[data-testid="cookie-policy-manage-dialog-accept-button"]',
                             'button:has-text("Accept")', 'button:has-text("Close")']:
                try:
                    btn = page.query_selector(selector)
                    if btn:
                        btn.click()
                        time.sleep(1)
                except Exception:
                    pass

            # Scroll to load more ads
            scroll_count = 0
            max_scrolls = max(3, max_results // 5)
            while len(ads) < max_results and scroll_count < max_scrolls:
                page.evaluate("window.scrollBy(0, 1000)")
                time.sleep(2)  # Rate limiting
                scroll_count += 1

                # Extract ad cards from the page
                # Meta Ad Library uses various container patterns
                ad_containers = page.query_selector_all('[class*="x1lliihq"]') or \
                                page.query_selector_all('[role="article"]') or \
                                page.query_selector_all('._7jvw') or \
                                page.query_selector_all('[class*="xrvj5dj"]')

                if not ad_containers:
                    # Fallback: try broader selector
                    ad_containers = page.query_selector_all('div[class*="ad"]')

                for i, container in enumerate(ad_containers):
                    if len(ads) >= max_results:
                        break

                    try:
                        # Extract text content
                        text_content = container.inner_text() or ""
                        if len(text_content) < 20:
                            continue  # Skip empty/nav elements

                        # Try to extract specific fields
                        ad_data = {
                            "index": len(ads),
                            "raw_text": text_content[:2000],
                            "advertiser": "",
                            "ad_text": "",
                            "cta": "",
                            "platform": "",
                            "status": "active",
                            "started": "",
                            "landing_url": "",
                            "media_type": "unknown",
                        }

                        # Parse structured data from the text
                        lines = text_content.strip().split("\n")
                        lines = [l.strip() for l in lines if l.strip()]

                        if lines:
                            # First non-empty line is often the advertiser
                            ad_data["advertiser"] = lines[0][:100]

                        # Look for ad body text (usually the longest block)
                        for line in lines:
                            if len(line) > 50 and line != ad_data["advertiser"]:
                                ad_data["ad_text"] = line[:500]
                                break

                        # Look for CTA buttons
                        for cta_text in ["Shop Now", "Learn More", "Sign Up", "Get Offer",
                                         "Download", "Contact Us", "Apply Now", "Book Now",
                                         "Order Now", "Subscribe", "Watch More", "See Menu"]:
                            if cta_text.lower() in text_content.lower():
                                ad_data["cta"] = cta_text
                                break

                        # Look for platform indicators
                        platforms = []
                        if "facebook" in text_content.lower():
                            platforms.append("facebook")
                        if "instagram" in text_content.lower():
                            platforms.append("instagram")
                        if "messenger" in text_content.lower():
                            platforms.append("messenger")
                        ad_data["platform"] = ",".join(platforms) if platforms else "facebook"

                        # Look for date patterns
                        for line in lines:
                            if any(m in line.lower() for m in ["started", "running", "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]):
                                ad_data["started"] = line[:50]
                                break

                        # Extract links
                        links = container.query_selector_all("a[href]")
                        for link in links:
                            href = link.get_attribute("href") or ""
                            if href and "facebook.com" not in href and href.startswith("http"):
                                ad_data["landing_url"] = href
                                break

                        # Detect media type
                        if container.query_selector("video"):
                            ad_data["media_type"] = "video"
                        elif len(container.query_selector_all("img")) > 2:
                            ad_data["media_type"] = "carousel"
                        elif container.query_selector("img"):
                            ad_data["media_type"] = "image"

                        # Screenshot
                        if screenshots:
                            try:
                                ss_path = os.path.join(output_dir, f"ad-{len(ads):03d}.png")
                                container.screenshot(path=ss_path)
                                ad_data["screenshot_path"] = ss_path
                            except Exception:
                                ad_data["screenshot_path"] = ""

                        # Only add if we got meaningful content
                        if ad_data["ad_text"] or ad_data["advertiser"]:
                            ads.append(ad_data)
                            print(f"[meta-ads] Ad {len(ads)}: {ad_data['advertiser'][:40]} — {ad_data['media_type']}")

                    except Exception as e:
                        print(f"[meta-ads] Error extracting ad: {e}")
                        continue

            # Take full page screenshot
            page.screenshot(path=os.path.join(output_dir, "full-page.png"), full_page=True)

        except Exception as e:
            print(f"[meta-ads] Page error: {e}")
        finally:
            browser.close()

    result = {
        "query": keyword or advertiser or "",
        "country": country,
        "scraped_at": datetime.now(timezone.utc).isoformat(),
        "ads": ads,
        "total_found": len(ads),
        "output_dir": output_dir,
    }

    # Save JSON output
    output_file = os.path.join(output_dir, "results.json")
    with open(output_file, "w") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    print(f"\n[meta-ads] Done. {len(ads)} ads saved to {output_file}")

    return result


def main():
    parser = argparse.ArgumentParser(description="Scrape Meta Ad Library")
    parser.add_argument("--keyword", "-k", help="Search keyword (e.g., 'vegan food')")
    parser.add_argument("--advertiser", "-a", help="Advertiser name (e.g., 'Green Monday')")
    parser.add_argument("--country", "-c", default="MY", help="Country code (default: MY)")
    parser.add_argument("--max-results", "-n", type=int, default=20, help="Max ads to extract (default: 20)")
    parser.add_argument("--output-dir", "-o", default="/tmp/meta-ads", help="Output directory")
    parser.add_argument("--no-screenshots", action="store_true", help="Skip taking screenshots")
    parser.add_argument("--json", action="store_true", help="Print JSON to stdout")
    args = parser.parse_args()

    if not args.keyword and not args.advertiser:
        parser.error("Must provide --keyword or --advertiser")

    if not check_playwright():
        sys.exit(1)

    result = scrape_ads(
        keyword=args.keyword,
        advertiser=args.advertiser,
        country=args.country,
        max_results=args.max_results,
        output_dir=args.output_dir,
        screenshots=not args.no_screenshots,
    )

    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
