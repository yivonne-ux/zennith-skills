#!/usr/bin/env python3
"""Product Scout — Shopee/Lazada marketplace scanner.

Scans for product opportunities across 衣食住行 categories.
Uses Playwright for JS-rendered marketplace pages.

Usage:
    python3 scout_products.py --platform shopee --country MY --category food --keyword "vegan snack"
    python3 scout_products.py --platform shopee --country MY --category all
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from statistics import mean, median


CATEGORY_KEYWORDS = {
    "food": ["vegan", "plant-based", "organic snack", "superfoods", "healthy food",
             "vegan rendang", "plant protein", "granola", "oat milk", "vegan cheese"],
    "fashion": ["graphic tee", "streetwear malaysia", "sustainable fashion",
                "printed tshirt", "custom hoodie", "accessories minimalist"],
    "home": ["home decor minimalist", "aromatherapy diffuser", "sustainable living",
             "wellness kit", "candle soy", "indoor plant accessories"],
    "mobility": ["travel accessories", "commute bag", "portable charger",
                 "travel wellness kit", "gadget organizer"],
}


def check_playwright():
    try:
        from playwright.sync_api import sync_playwright
        return True
    except ImportError:
        print("Error: playwright not installed.")
        return False


def build_shopee_url(keyword: str, country: str = "MY") -> str:
    domains = {"MY": "shopee.com.my", "SG": "shopee.sg", "TH": "shopee.co.th"}
    domain = domains.get(country, "shopee.com.my")
    return f"https://{domain}/search?keyword={keyword.replace(' ', '+')}&sortBy=sales"


def build_lazada_url(keyword: str, country: str = "MY") -> str:
    domains = {"MY": "www.lazada.com.my", "SG": "www.lazada.sg", "TH": "www.lazada.co.th"}
    domain = domains.get(country, "www.lazada.com.my")
    return f"https://{domain}/catalog/?q={keyword.replace(' ', '+')}&sort=order"


def parse_number(text: str) -> float:
    """Parse numbers like '1.2K', '45', '3.4M' into numeric values."""
    text = text.strip().replace(",", "")
    match = re.match(r'([\d.]+)\s*([KMBkmb])?', text)
    if not match:
        return 0
    num = float(match.group(1))
    suffix = (match.group(2) or "").upper()
    if suffix == "K":
        num *= 1000
    elif suffix == "M":
        num *= 1_000_000
    elif suffix == "B":
        num *= 1_000_000_000
    return num


def scrape_shopee(keyword: str, country: str = "MY", max_results: int = 30) -> list:
    """Scrape Shopee search results."""
    from playwright.sync_api import sync_playwright

    url = build_shopee_url(keyword, country)
    products = []

    print(f"[scout] Scraping Shopee {country}: {keyword}")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1280, "height": 900},
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        )
        page = context.new_page()

        try:
            page.goto(url, wait_until="networkidle", timeout=30000)
            time.sleep(3)

            # Scroll to load products
            for _ in range(min(5, max_results // 6)):
                page.evaluate("window.scrollBy(0, 1000)")
                time.sleep(2)

            # Shopee product cards
            cards = page.query_selector_all('[class*="shopee-search-item-result__item"], [data-sqe="item"]')
            if not cards:
                cards = page.query_selector_all('a[data-sqe="link"]')
            if not cards:
                # Broader fallback
                cards = page.query_selector_all('.shopee-search-item-result__items > div')

            for card in cards:
                if len(products) >= max_results:
                    break
                try:
                    text = card.inner_text().strip()
                    if not text or len(text) < 10:
                        continue

                    lines = [l.strip() for l in text.split("\n") if l.strip()]

                    # Parse product data from text
                    name = ""
                    price = 0
                    sold = ""
                    rating = ""

                    for line in lines:
                        # Price detection (RM XX.XX)
                        price_match = re.search(r'(?:RM|rm)\s*([\d,.]+)', line)
                        if price_match and not price:
                            price = float(price_match.group(1).replace(",", ""))
                        # Sold count
                        sold_match = re.search(r'([\d.]+[KMk]?)\s*sold', line, re.IGNORECASE)
                        if sold_match:
                            sold = sold_match.group(1)
                        # Rating
                        rating_match = re.search(r'([\d.]+)\s*(?:stars?|\u2605)', line, re.IGNORECASE)
                        if rating_match:
                            rating = rating_match.group(1)
                        # Name (longest line that isn't price/stats)
                        if len(line) > len(name) and not price_match and "sold" not in line.lower():
                            name = line

                    if not name:
                        name = lines[0] if lines else "Unknown"

                    # Get link
                    link_elem = card.query_selector("a[href]")
                    product_url = ""
                    if link_elem:
                        href = link_elem.get_attribute("href") or ""
                        if href.startswith("/"):
                            domain = {"MY": "shopee.com.my", "SG": "shopee.sg"}.get(country, "shopee.com.my")
                            product_url = f"https://{domain}{href}"
                        elif href.startswith("http"):
                            product_url = href

                    # Estimate monthly sales from "sold" count
                    monthly_est = 0
                    if sold:
                        total_sold = parse_number(sold)
                        monthly_est = int(total_sold / 6)  # Rough estimate: divide total by ~6 months

                    products.append({
                        "name": name[:200],
                        "price_myr": price,
                        "rating": rating or "N/A",
                        "sold_total": sold,
                        "monthly_sales_est": monthly_est,
                        "url": product_url,
                        "raw": text[:300],
                    })
                    print(f"[scout] {len(products)}. {name[:50]} — RM{price} ({sold} sold)")

                except Exception:
                    continue

            # Fallback text extraction
            if not products:
                print("[scout] Card extraction failed, trying text fallback...")
                body = page.inner_text("body")
                # Look for price patterns
                price_blocks = re.findall(r'(.{20,100}RM\s*[\d,.]+.{0,50})', body)
                for block in price_blocks[:max_results]:
                    price_match = re.search(r'RM\s*([\d,.]+)', block)
                    price = float(price_match.group(1).replace(",", "")) if price_match else 0
                    products.append({
                        "name": block[:100].strip(),
                        "price_myr": price,
                        "raw": block,
                    })

        except Exception as e:
            print(f"[scout] Error: {e}")
        finally:
            browser.close()

    return products


def analyze_opportunity(products: list, keyword: str) -> dict:
    """Calculate market gap score and generate opportunity analysis."""
    if not products:
        return {"market_gap_score": 0, "recommendation": "No products found. Check keyword."}

    prices = [p.get("price_myr", 0) for p in products if p.get("price_myr", 0) > 0]
    monthly_sales = [p.get("monthly_sales_est", 0) for p in products if p.get("monthly_sales_est", 0) > 0]

    avg_price = mean(prices) if prices else 0
    med_price = median(prices) if prices else 0
    price_range = f"{min(prices):.2f} - {max(prices):.2f}" if prices else "N/A"
    total_products = len(products)
    avg_monthly = mean(monthly_sales) if monthly_sales else 0

    # Gap scoring
    score = 5.0  # baseline

    # Low competition (fewer than 20 products with reviews)
    reviewed_products = len([p for p in products if p.get("sold_total")])
    if reviewed_products < 10:
        score += 2
    elif reviewed_products < 20:
        score += 1

    # High demand (avg monthly > 100)
    if avg_monthly > 200:
        score += 1.5
    elif avg_monthly > 100:
        score += 0.5

    # Price gaps (large spread = opportunity to position)
    if prices and max(prices) > 3 * min(prices):
        score += 1

    # Quality gap (many products but low ratings)
    ratings = []
    for p in products:
        try:
            r = float(p.get("rating", 0))
            if r > 0:
                ratings.append(r)
        except (ValueError, TypeError):
            pass
    if ratings and mean(ratings) < 4.5:
        score += 0.5

    score = min(10, max(1, score))

    # Find gaps
    gaps = []
    if avg_price > 25 and len([p for p in products if p.get("price_myr", 0) < 15]) < 3:
        gaps.append("Budget segment (<RM15) is underserved")
    if avg_price < 20 and len([p for p in products if p.get("price_myr", 0) > 35]) < 3:
        gaps.append("Premium segment (>RM35) is underserved — room for quality positioning")
    if total_products < 15:
        gaps.append(f"Low product count ({total_products}) suggests emerging category")

    recommendation = ""
    if score >= 7:
        recommendation = f"Strong opportunity. Market gap score {score:.1f}/10. Consider entering with differentiated positioning."
    elif score >= 5:
        recommendation = f"Moderate opportunity. Market gap score {score:.1f}/10. Viable with strong brand/creative differentiation."
    else:
        recommendation = f"Competitive market. Gap score {score:.1f}/10. Need significant differentiation to compete."

    return {
        "total_products_scanned": total_products,
        "avg_price": round(avg_price, 2),
        "median_price": round(med_price, 2),
        "price_range": price_range,
        "avg_monthly_sales": round(avg_monthly),
        "market_gap_score": round(score, 1),
        "gaps_found": gaps,
        "recommendation": recommendation,
    }


def main():
    parser = argparse.ArgumentParser(description="Product Scout — 衣食住行 scanner")
    parser.add_argument("--platform", "-p", default="shopee", choices=["shopee", "lazada"],
                        help="Marketplace platform")
    parser.add_argument("--country", "-c", default="MY", help="Country code (default: MY)")
    parser.add_argument("--category", default="food",
                        choices=["food", "fashion", "home", "mobility", "all"],
                        help="GAIA pillar category")
    parser.add_argument("--keyword", "-k", help="Custom keyword(s), comma-separated")
    parser.add_argument("--max-results", "-n", type=int, default=30, help="Max results per keyword")
    parser.add_argument("--output", "-o", help="Output JSON file path")
    args = parser.parse_args()

    if not check_playwright():
        sys.exit(1)

    # Determine keywords
    if args.keyword:
        keywords = [k.strip() for k in args.keyword.split(",")]
        categories = [args.category]
    elif args.category == "all":
        categories = list(CATEGORY_KEYWORDS.keys())
        keywords = []
        for cat_keywords in CATEGORY_KEYWORDS.values():
            keywords.extend(cat_keywords[:3])  # Top 3 per category
    else:
        keywords = CATEGORY_KEYWORDS.get(args.category, ["product"])
        categories = [args.category]

    all_results = []

    for keyword in keywords:
        if args.platform == "shopee":
            products = scrape_shopee(keyword, args.country, args.max_results)
        else:
            # TODO: Lazada scraper
            print(f"[scout] Lazada scraper not yet implemented. Using Shopee.")
            products = scrape_shopee(keyword, args.country, args.max_results)

        analysis = analyze_opportunity(products, keyword)

        result = {
            "platform": args.platform,
            "country": args.country,
            "category": args.category,
            "keyword": keyword,
            "scraped_at": datetime.now(timezone.utc).isoformat(),
            "products": products,
            "opportunity_analysis": analysis,
        }
        all_results.append(result)
        print(f"\n[scout] {keyword}: {len(products)} products, gap score: {analysis['market_gap_score']}/10")
        time.sleep(2)  # Rate limiting between searches

    # Output
    output = {
        "scan_type": "product-scout",
        "categories": categories,
        "total_keywords_scanned": len(keywords),
        "scraped_at": datetime.now(timezone.utc).isoformat(),
        "results": all_results,
    }

    output_path = args.output or "/tmp/product-scout.json"
    with open(output_path, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    print(f"\n[scout] Full report saved to {output_path}")

    # Summary
    print("\n=== OPPORTUNITY SUMMARY ===")
    for r in all_results:
        a = r["opportunity_analysis"]
        emoji = "🟢" if a["market_gap_score"] >= 7 else "🟡" if a["market_gap_score"] >= 5 else "🔴"
        print(f"{emoji} {r['keyword']}: gap={a['market_gap_score']}/10, avg=RM{a['avg_price']}, products={a['total_products_scanned']}")


if __name__ == "__main__":
    main()
