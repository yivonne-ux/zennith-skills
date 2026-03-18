#!/usr/bin/env bash
# scrapling-fetch.sh — Anti-bot web scraping via Scrapling (Python)
# Usage:
#   scrapling-fetch.sh fetch "https://example.com"                    # basic fetch
#   scrapling-fetch.sh css "https://example.com" ".product::text"     # CSS selector extract
#   scrapling-fetch.sh stealth "https://cloudflare-protected.com"     # stealth browser fetch
#   scrapling-fetch.sh spider "https://example.com" 10                # crawl up to N pages

set -euo pipefail

VENV="/Users/jennwoeiloh/.openclaw/workspace/venvs/scrapling"
PYTHON="${VENV}/bin/python3"

if [[ ! -f "$PYTHON" ]]; then
  echo "ERROR: Scrapling venv not found. Run: python3 -m venv ${VENV} && ${VENV}/bin/pip install scrapling"
  exit 1
fi

cmd_fetch() {
  local url="$1"
  "$PYTHON" << PYEOF
from scrapling.fetchers import Fetcher
page = Fetcher.get('${url}')
print(page.get_all_text(separator='\n'))
PYEOF
}

cmd_css() {
  local url="$1"
  local selector="$2"
  "$PYTHON" << PYEOF
from scrapling.fetchers import Fetcher
page = Fetcher.get('${url}')
results = page.css('${selector}').getall()
for r in results:
    print(r)
PYEOF
}

cmd_stealth() {
  local url="$1"
  "$PYTHON" << PYEOF
try:
    from scrapling.fetchers import StealthFetcher
    page = StealthFetcher.get('${url}')
    print(page.get_all_text(separator='\n'))
except ImportError:
    # StealthFetcher needs playwright — fall back to regular
    from scrapling.fetchers import Fetcher
    page = Fetcher.get('${url}')
    print(page.get_all_text(separator='\n'))
except Exception as e:
    print(f"ERROR: {e}")
PYEOF
}

cmd_spider() {
  local url="$1"
  local max_pages="${2:-10}"
  "$PYTHON" << PYEOF
from scrapling.fetchers import Fetcher
import json

visited = set()
queue = ['${url}']
results = []
max_pages = ${max_pages}

while queue and len(visited) < max_pages:
    current = queue.pop(0)
    if current in visited:
        continue
    visited.add(current)
    try:
        page = Fetcher.get(current)
        title = ''
        try:
            title = page.css('title::text').get() or ''
        except:
            pass
        text_preview = (page.get_all_text(separator=' ') or '')[:500]
        results.append({'url': current, 'title': title, 'preview': text_preview})

        # Find links on same domain
        try:
            from urllib.parse import urljoin, urlparse
            base_domain = urlparse('${url}').netloc
            for link in page.css('a::attr(href)').getall():
                full = urljoin(current, link)
                if urlparse(full).netloc == base_domain and full not in visited:
                    queue.append(full)
        except:
            pass
    except Exception as e:
        results.append({'url': current, 'error': str(e)})

print(json.dumps(results, indent=2, ensure_ascii=False))
PYEOF
}

case "${1:-help}" in
  fetch)    cmd_fetch "${2:?URL required}" ;;
  css)      cmd_css "${2:?URL required}" "${3:?CSS selector required}" ;;
  stealth)  cmd_stealth "${2:?URL required}" ;;
  spider)   cmd_spider "${2:?URL required}" "${3:-10}" ;;
  help|*)
    echo "Scrapling — Anti-Bot Web Scraping for GAIA OS"
    echo ""
    echo "Usage: scrapling-fetch.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  fetch <url>              Basic HTTP fetch + text extraction"
    echo "  css <url> <selector>     Extract data with CSS selectors"
    echo "  stealth <url>            Stealth fetch (bypasses Cloudflare)"
    echo "  spider <url> [max]       Crawl site up to N pages (default 10)"
    ;;
esac
