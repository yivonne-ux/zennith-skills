#!/usr/bin/env python3
"""
Unified scraping CLI for Zennith OS agents.
Powered by Scrapling (github.com/D4Vinci/Scrapling).

Modes:
  fetch    - Basic HTTP fetch (fast, TLS fingerprint spoofing)
  stealth  - Anti-bot bypass (Cloudflare Turnstile, headless Chrome)
  dynamic  - Full browser rendering (JS-heavy pages, SPAs)
  crawl    - Spider entire site (async, concurrent)
  extract  - Fetch + extract structured data (CSS/XPath selectors)

Usage:
  scrape.py fetch <url> [--selector CSS] [--output json|md|text]
  scrape.py stealth <url> [--selector CSS] [--solve-cloudflare]
  scrape.py dynamic <url> [--selector CSS] [--wait SECONDS]
  scrape.py crawl <url> [--max-pages N] [--selector CSS] [--output-dir DIR]
  scrape.py extract <url> --selectors '{"title":"h1","price":".price"}'
"""

import argparse
import json
import sys
import os
from pathlib import Path
from datetime import datetime

# Add venv to path
VENV = Path(__file__).resolve().parent.parent.parent.parent / "venvs" / "scrapling"
sys.path.insert(0, str(VENV / "lib" / "python3.14" / "site-packages"))

from scrapling.fetchers import Fetcher, StealthyFetcher, DynamicFetcher


def output_result(page, selector=None, output_format="text", selectors_map=None):
    """Extract and format results from a fetched page."""
    result = {
        "url": str(page.url) if hasattr(page, 'url') else "unknown",
        "status": page.status if hasattr(page, 'status') else 200,
        "timestamp": datetime.now().isoformat(),
    }

    if selectors_map:
        # Structured extraction mode
        data = {}
        for key, sel in selectors_map.items():
            elements = page.css(sel)
            if elements:
                texts = [e.text.strip() for e in elements if e.text and e.text.strip()]
                data[key] = texts[0] if len(texts) == 1 else texts
            else:
                data[key] = None
        result["data"] = data
    elif selector:
        elements = page.css(selector)
        texts = [e.text.strip() for e in elements if e.text and e.text.strip()]
        result["data"] = texts
        result["count"] = len(texts)
    else:
        # Full page content
        title_els = page.css("title")
        result["title"] = title_els[0].text.strip() if title_els else ""
        # Get main text content - try get_all_text or fall back to iterating elements
        body = page.css("body")
        if body:
            # Try multiple approaches to get text
            body_el = body[0]
            text = ""
            if hasattr(body_el, 'get_all_text'):
                text = body_el.get_all_text(separator="\n", strip=True)
            elif hasattr(body_el, 'text_content'):
                text = body_el.text_content()
            elif body_el.text:
                text = body_el.text
            if not text:
                # Fallback: collect text from all paragraph-like elements
                for tag in ["p", "h1", "h2", "h3", "h4", "li", "td", "span", "div"]:
                    for el in page.css(tag):
                        if el.text and el.text.strip():
                            text += el.text.strip() + "\n"
                    if len(text) > 3000:
                        break
            result["text"] = text[:5000]
        else:
            result["text"] = page.text[:5000] if page.text else ""

    if output_format == "json":
        print(json.dumps(result, indent=2, ensure_ascii=False))
    elif output_format == "md":
        print(f"# {result.get('title', result['url'])}")
        print(f"**URL**: {result['url']}")
        print(f"**Status**: {result['status']}")
        print(f"**Scraped**: {result['timestamp']}")
        print()
        if "data" in result:
            if isinstance(result["data"], dict):
                for k, v in result["data"].items():
                    print(f"**{k}**: {v}")
            elif isinstance(result["data"], list):
                for item in result["data"]:
                    print(f"- {item}")
        else:
            print(result.get("text", ""))
    else:
        if "data" in result:
            if isinstance(result["data"], dict):
                for k, v in result["data"].items():
                    print(f"{k}: {v}")
            elif isinstance(result["data"], list):
                for item in result["data"]:
                    print(item)
        else:
            print(result.get("text", ""))


def cmd_fetch(args):
    """Basic HTTP fetch with TLS fingerprint spoofing."""
    page = Fetcher.get(args.url)
    output_result(page, args.selector, args.output)


def cmd_stealth(args):
    """Anti-bot bypass using StealthyFetcher."""
    kwargs = {"headless": True}
    if args.solve_cloudflare:
        kwargs["google_search"] = False
    page = StealthyFetcher.fetch(args.url, **kwargs)
    output_result(page, args.selector, args.output)


def cmd_dynamic(args):
    """Full browser rendering for JS-heavy pages."""
    kwargs = {"headless": True}
    if args.wait:
        kwargs["wait_after_load"] = int(args.wait)
    page = DynamicFetcher.fetch(args.url, **kwargs)
    output_result(page, args.selector, args.output)


def cmd_crawl(args):
    """Crawl an entire site."""
    import asyncio
    from scrapling.spiders import Spider, Request, Response

    results = []
    max_pages = args.max_pages or 20

    class SiteCrawler(Spider):
        name = "zennith-crawler"
        start_urls = [args.url]
        concurrent_requests = 5

        async def parse(self, response: Response):
            page_data = {
                "url": str(response.url),
                "title": response.css("title")[0].text.strip() if response.css("title") else "",
            }
            if args.selector:
                elements = response.css(args.selector)
                page_data["data"] = [e.text.strip() for e in elements if e.text and e.text.strip()]
            results.append(page_data)

            if len(results) < max_pages:
                for link in response.css("a[href]"):
                    href = link.attrib.get("href", "")
                    if href.startswith("/") or href.startswith(args.url):
                        yield Request(url=href, callback=self.parse)

    crawler = SiteCrawler()
    asyncio.run(crawler.run())

    output_dir = args.output_dir
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        out_file = os.path.join(output_dir, "crawl-results.json")
        with open(out_file, "w") as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        print(f"Crawled {len(results)} pages → {out_file}")
    else:
        print(json.dumps(results, indent=2, ensure_ascii=False))


def cmd_extract(args):
    """Fetch + extract structured data using a selector map."""
    selectors_map = json.loads(args.selectors)
    if args.mode == "stealth":
        page = StealthyFetcher.fetch(args.url, headless=True)
    elif args.mode == "dynamic":
        page = DynamicFetcher.fetch(args.url, headless=True)
    else:
        page = Fetcher.get(args.url)
    output_result(page, selectors_map=selectors_map, output_format=args.output)


def main():
    parser = argparse.ArgumentParser(description="Zennith OS Unified Scraper (Scrapling)")
    sub = parser.add_subparsers(dest="command", required=True)

    # fetch
    p = sub.add_parser("fetch", help="Basic HTTP fetch")
    p.add_argument("url")
    p.add_argument("--selector", "-s", help="CSS selector to extract")
    p.add_argument("--output", "-o", choices=["json", "md", "text"], default="json")

    # stealth
    p = sub.add_parser("stealth", help="Anti-bot bypass fetch")
    p.add_argument("url")
    p.add_argument("--selector", "-s", help="CSS selector to extract")
    p.add_argument("--solve-cloudflare", action="store_true")
    p.add_argument("--output", "-o", choices=["json", "md", "text"], default="json")

    # dynamic
    p = sub.add_parser("dynamic", help="Full browser rendering")
    p.add_argument("url")
    p.add_argument("--selector", "-s", help="CSS selector to extract")
    p.add_argument("--wait", type=int, help="Seconds to wait after page load")
    p.add_argument("--output", "-o", choices=["json", "md", "text"], default="json")

    # crawl
    p = sub.add_parser("crawl", help="Spider entire site")
    p.add_argument("url")
    p.add_argument("--max-pages", type=int, default=20)
    p.add_argument("--selector", "-s", help="CSS selector to extract per page")
    p.add_argument("--output-dir", help="Directory to save results")
    p.add_argument("--output", "-o", choices=["json", "md", "text"], default="json")

    # extract
    p = sub.add_parser("extract", help="Structured data extraction")
    p.add_argument("url")
    p.add_argument("--selectors", required=True, help='JSON map: {"name":"CSS","price":".price"}')
    p.add_argument("--mode", choices=["fetch", "stealth", "dynamic"], default="fetch")
    p.add_argument("--output", "-o", choices=["json", "md", "text"], default="json")

    args = parser.parse_args()
    {"fetch": cmd_fetch, "stealth": cmd_stealth, "dynamic": cmd_dynamic,
     "crawl": cmd_crawl, "extract": cmd_extract}[args.command](args)


if __name__ == "__main__":
    main()
