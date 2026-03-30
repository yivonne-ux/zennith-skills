---
name: Zennith Social Scraping Tools — IG + XHS + multi-platform
description: Installed tools for reading/scraping Instagram and XHS content. Location, capabilities, setup status. For competitive forensic, viral reference scraping, content analysis.
type: reference
---

## SOCIAL MEDIA SCRAPING TOOLS (installed March 27, 2026)

All tools at: `/Users/yi-vonnehooi/Desktop/_WORK/_shared/tools/`

### Instagram

| Tool | Location | Type | Capabilities |
|------|----------|------|-------------|
| **instagrapi** | `pip3` installed | Python library | Full IG Private API — posts, reels, stories, metrics, comments, hashtags. Read + write. |
| **Instaloader** | `pip3` installed | Python library | Bulk download posts, videos, captions, metadata, stories, highlights, reels. |
| **instagram-server-next-mcp** | `tools/instagram-server-next-mcp/` | MCP server (Node) | Claude reads IG content via Chrome session. Needs `npm install` + MCP config. |

### XHS (Xiaohongshu 小红书)

| Tool | Location | Type | Capabilities |
|------|----------|------|-------------|
| **MediaCrawler** | `tools/MediaCrawler/` | Python app | **45k stars.** XHS + Douyin + Bilibili + Weibo. Notes, images, comments, metrics. Playwright browser. |
| **XHS-Downloader** | `tools/XHS-Downloader/` | Python app | Bulk download XHS content — images, videos, text. Link extraction. |

### Multi-platform

| Tool | Location | Type | Capabilities |
|------|----------|------|-------------|
| **x-reader** | `tools/x-reader/` | Python + MCP | Reads XHS + WeChat + X + YouTube + Bilibili + Telegram + RSS. Normalized output. |

### Use Cases

| Task | Tool to use |
|------|-----------|
| Forensic competitor's IG content | instagrapi (metrics) + Instaloader (download) |
| Read IG posts from Claude Code | instagram-server-next-mcp (MCP) |
| Scrape XHS viral content/trends | MediaCrawler |
| Download XHS reference images | XHS-Downloader |
| Multi-platform competitive intel | x-reader |
| Scrape viral meme/comic references | Instaloader (IG) + MediaCrawler (XHS) |

### Setup Notes
- instagrapi + Instaloader: `pip3 install instagrapi instaloader`
- MediaCrawler: needs `pip install -r requirements.txt` + Playwright browsers
- MCP servers: need Node.js + config in `.claude/settings.json`
- Login credentials needed for most tools (IG account for instagrapi, XHS cookies for MediaCrawler)
