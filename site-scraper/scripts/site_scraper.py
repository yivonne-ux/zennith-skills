#!/usr/bin/env python3
"""site_scraper.py - best-effort site crawler + readable text extractor.

Design goals:
- safe defaults (same-domain, page caps)
- lightweight install
- outputs markdown + json sources

Example:
  python site_scraper.py --url https://example.com --depth 1 --max-pages 10 --out ./out
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import deque
from dataclasses import dataclass
from typing import Dict, List, Optional, Set, Tuple
from urllib.parse import urljoin, urlparse, urldefrag

import httpx
from bs4 import BeautifulSoup


@dataclass
class Page:
    url: str
    title: str
    text: str


def norm_url(base: str, href: str) -> Optional[str]:
    if not href:
        return None
    href = href.strip()
    if href.startswith("mailto:") or href.startswith("tel:") or href.startswith("javascript:"):
        return None
    full = urljoin(base, href)
    full, _frag = urldefrag(full)
    return full


def same_domain(a: str, b: str) -> bool:
    pa, pb = urlparse(a), urlparse(b)
    return pa.netloc == pb.netloc


def extract_readable(html: str) -> Tuple[str, str, List[str]]:
    soup = BeautifulSoup(html, "lxml")
    title = (soup.title.string.strip() if soup.title and soup.title.string else "").strip()

    # Remove non-content
    for tag in soup(["script", "style", "noscript", "svg"]):
        tag.decompose()

    # Prefer <main> then <article>
    main = soup.find("main") or soup.find("article") or soup.body
    text = ""
    if main:
        text = main.get_text("\n", strip=True)

    # Basic cleanup
    lines = [ln.strip() for ln in text.splitlines()]
    lines = [ln for ln in lines if ln]
    text = "\n".join(lines)
    text = re.sub(r"\n{3,}", "\n\n", text).strip()

    links = []
    for a in soup.find_all("a"):
        href = a.get("href")
        if href:
            links.append(href)

    return title, text, links


def crawl(start_url: str, depth: int, max_pages: int, timeout_s: float = 20.0) -> List[Page]:
    client = httpx.Client(follow_redirects=True, timeout=timeout_s, headers={
        "User-Agent": "Mozilla/5.0 (compatible; OpenClawSiteScraper/1.0)"
    })

    seen: Set[str] = set()
    q = deque([(start_url, 0)])
    pages: List[Page] = []

    while q and len(pages) < max_pages:
        url, d = q.popleft()
        if url in seen:
            continue
        seen.add(url)

        try:
            r = client.get(url)
            ct = r.headers.get("content-type", "")
            if "text/html" not in ct:
                continue
            title, text, raw_links = extract_readable(r.text)
            if text:
                pages.append(Page(url=url, title=title, text=text))

            if d < depth:
                for href in raw_links:
                    nu = norm_url(url, href)
                    if not nu:
                        continue
                    if not same_domain(start_url, nu):
                        continue
                    # Skip obvious non-pages
                    if re.search(r"\.(png|jpg|jpeg|gif|webp|pdf|zip|mp4|mov)(\?|$)", nu, re.I):
                        continue
                    if nu not in seen:
                        q.append((nu, d + 1))

        except Exception:
            continue

    client.close()
    return pages


def write_outputs(pages: List[Page], out_dir: str):
    os.makedirs(out_dir, exist_ok=True)

    sources = []
    md_parts = []
    for i, p in enumerate(pages, 1):
        sources.append({"i": i, "url": p.url, "title": p.title, "chars": len(p.text)})
        md_parts.append(f"## {i}. {p.title or p.url}\n\nSource: {p.url}\n\n{p.text}\n")

    with open(os.path.join(out_dir, "sources.json"), "w", encoding="utf-8") as f:
        json.dump(sources, f, ensure_ascii=False, indent=2)

    with open(os.path.join(out_dir, "content.md"), "w", encoding="utf-8") as f:
        f.write("\n\n".join(md_parts).strip() + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", required=True)
    ap.add_argument("--depth", type=int, default=1)
    ap.add_argument("--max-pages", type=int, default=10)
    ap.add_argument("--out", default="./scrape-out")
    args = ap.parse_args()

    pages = crawl(args.url, depth=max(0, args.depth), max_pages=max(1, min(50, args.max_pages)))
    write_outputs(pages, args.out)

    print(f"OK scraped {len(pages)} page(s)")
    print(f"OUT_DIR={os.path.abspath(args.out)}")


if __name__ == "__main__":
    main()
