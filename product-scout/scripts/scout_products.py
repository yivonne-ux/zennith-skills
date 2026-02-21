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
    """Scrape Shopee search results via API interception + DOM fallback."""
    from playwright.sync_api import sync_playwright

    url = build_shopee_url(keyword, country)
    products = []
    api_items = []

    print(f"[scout] Scraping Shopee {country}: {keyword}")

    def handle_response(response):
        """Intercept Shopee search API responses."""
        try:
            resp_url = response.url
            if "search_items" in resp_url or "search/v2" in resp_url or "api/v4/search" in resp_url:
                data = response.json()
                if isinstance(data, dict):
                    items = data.get("items", data.get("data", {}).get("items", []))
                    if isinstance(items, list):
                        api_items.extend(items)
                        print(f"[scout] API intercepted: {len(items)} products")
        except Exception:
            pass

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1280, "height": 900},
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        )
        page = context.new_page()
        page.on("response", handle_response)

        try:
            page.goto(url, wait_until="networkidle", timeout=30000)
            time.sleep(3)

            for _ in range(min(5, max_results // 6)):
                page.evaluate("window.scrollBy(0, 1000)")
                time.sleep(2)

            # Method 1: Use intercepted API data
            if api_items:
                for item in api_items[:max_results]:
                    info = item.get("item_basic", item) if isinstance(item, dict) else {}
                    if not isinstance(info, dict):
                        continue
                    name = info.get("name", info.get("title", ""))
                    if not name:
                        continue
                    price_raw = info.get("price", info.get("price_min", 0))
                    price = price_raw / 100000 if price_raw > 10000 else price_raw / 100 if price_raw > 1000 else price_raw
                    sold = info.get("sold", info.get("historical_sold", 0))
                    rating = info.get("item_rating", {})
                    if isinstance(rating, dict):
                        rating_star = rating.get("rating_star", 0)
                    else:
                        rating_star = 0
                    shop_loc = info.get("shop_location", "")
                    monthly_est = int(sold / 6) if sold else 0

                    products.append({
                        "name": name[:200],
                        "price_myr": round(price, 2),
                        "rating": f"{rating_star:.1f}" if rating_star else "N/A",
                        "sold_total": str(sold) if sold else "N/A",
                        "monthly_sales_est": monthly_est,
                        "shop_location": shop_loc,
                        "url": "",
                    })
                    print(f"[scout] {len(products)}. {name[:50]} — RM{price:.2f} ({sold} sold)")

            # Method 2: DOM fallback with broader selectors
            if not products:
                selectors = [
                    '[data-sqe="item"]',
                    'a[data-sqe="link"]',
                    'li[class*="col-xs"]',
                    'div[class*="product-card"]',
                    'div[class*="search-item"]',
                ]
                cards = []
                for sel in selectors:
                    cards = page.query_selector_all(sel)
                    if cards:
                        print(f"[scout] DOM: found {len(cards)} cards with selector '{sel}'")
                        break

                for card in cards:
                    if len(products) >= max_results:
                        break
                    try:
                        text = card.inner_text().strip()
                        if not text or len(text) < 10:
                            continue
                        lines = [l.strip() for l in text.split("\n") if l.strip()]
                        name = ""
                        price = 0
                        sold = ""
                        rating = ""

                        for line in lines:
                            price_match = re.search(r'(?:RM|rm)\s*([\d,.]+)', line)
                            if price_match and not price:
                                price = float(price_match.group(1).replace(",", ""))
                            sold_match = re.search(r'([\d.]+[KMk]?)\s*sold', line, re.IGNORECASE)
                            if sold_match:
                                sold = sold_match.group(1)
                            rating_match = re.search(r'([\d.]+)\s*(?:stars?|\u2605)', line, re.IGNORECASE)
                            if rating_match:
                                rating = rating_match.group(1)
                            if len(line) > len(name) and not price_match and "sold" not in line.lower():
                                name = line

                        if not name:
                            name = lines[0] if lines else "Unknown"

                        link_elem = card.query_selector("a[href]")
                        product_url = ""
                        if link_elem:
                            href = link_elem.get_attribute("href") or ""
                            if href.startswith("/"):
                                domain = {"MY": "shopee.com.my", "SG": "shopee.sg"}.get(country, "shopee.com.my")
                                product_url = f"https://{domain}{href}"
                            elif href.startswith("http"):
                                product_url = href

                        monthly_est = 0
                        if sold:
                            monthly_est = int(parse_number(sold) / 6)

                        products.append({
                            "name": name[:200],
                            "price_myr": price,
                            "rating": rating or "N/A",
                            "sold_total": sold or "N/A",
                            "monthly_sales_est": monthly_est,
                            "url": product_url,
                            "raw": text[:300],
                        })
                        print(f"[scout] {len(products)}. {name[:50]} — RM{price} ({sold} sold)")
                    except Exception:
                        continue

            # Method 3: Text fallback
            if not products:
                print("[scout] Card extraction failed, trying text fallback...")
                body = page.inner_text("body")
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
        return {
            "total_products_scanned": 0,
            "avg_price": 0,
            "median_price": 0,
            "price_range": "N/A",
            "avg_monthly_sales": 0,
            "market_gap_score": 0,
            "gaps_found": ["No products found — keyword may not exist or scraper blocked"],
            "recommendation": "Check keyword spelling or try alternative terms"
        }

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
