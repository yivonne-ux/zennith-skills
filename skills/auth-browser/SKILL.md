---
name: auth-browser
description: Universal authenticated browser. Access Facebook, Meta, Instagram, Shopify, Google Ads — any service you're logged into. Chrome CDP with persistent sessions.
version: 1.0.0
agents: [main, taoz, dreami, scout, hermes]
evolves: true
---

# Auth Browser — Universal Authenticated Browser Access

## Quick Start
```bash
# 1. Launch browser (first time — log into your services)
bash ~/.openclaw/skills/auth-browser/scripts/browser.sh start

# 2. Check what's authenticated
bash ~/.openclaw/skills/auth-browser/scripts/browser.sh services

# 3. Navigate and interact
bash ~/.openclaw/skills/auth-browser/scripts/browser.sh nav "https://business.facebook.com"
bash ~/.openclaw/skills/auth-browser/scripts/browser.sh text
bash ~/.openclaw/skills/auth-browser/scripts/browser.sh screenshot /tmp/meta.jpg
```

## Commands

| Command | What |
|---------|------|
| `start` | Launch Chrome with CDP (headed, persistent profile) |
| `stop` | Quit Chrome |
| `check` | Is CDP running? |
| `nav <url>` | Navigate to URL |
| `text` | Get page text |
| `screenshot [path]` | Take screenshot |
| `services` | Check which services are authenticated |
| `login <service>` | Open login page for a service |
| `run <script.py>` | Run Playwright script against CDP |

## Supported Services
facebook, meta, instagram, shopify, google-ads, klaviyo, tiktok

## How It Works
Uses your REAL Chrome browser with `~/.chrome-cdp` profile. Sessions persist forever. Log in once per service.

## Key Rule
Must quit Chrome before starting (`browser.sh stop` then `browser.sh start`). Can't share Chrome between normal use and CDP.
