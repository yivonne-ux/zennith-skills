---
name: link-digester
description: Auto-classify and process links from WhatsApp — YouTube, articles, products, competitors, social
version: 1.0.0
agent: zenni
---

# Link Digester

Automatically processes links shared via WhatsApp. Classifies URL type and routes to the right agent for processing.

## How It Works

1. Zenni receives a message containing a URL
2. `classify-link.sh` determines the URL type (youtube, article, product, competitor, social, general)
3. `digest-link.sh` routes to the appropriate agent and processor
4. Results are posted to the exec room + stored in RAG memory

## Detection Rules

| Pattern | Type | Agent | Room |
|---------|------|-------|------|
| youtube.com, youtu.be | youtube | taoz | exec |
| shopee.*, lazada.*, amazon.* | product | hermes | exec |
| tiktok.com, instagram.com/reel | social | iris | creative |
| Known competitor domains | competitor | artemis | build |
| Blog/article patterns | article | artemis | exec |
| Everything else | general | artemis | exec |

## Instruction Handling

If Jenn sends text alongside a link:
- Text is treated as instructions for the processing agent
- If text mentions an agent name → route directly to that agent
- If text contains urgency words (now, immediately, asap, urgent) → add priority flag
- If just a link with no text → auto-classify and process with default instructions

## Scripts

- `scripts/classify-link.sh <url>` — Returns JSON: `{"type":"...", "agent":"...", "room":"..."}`
- `scripts/digest-link.sh <url> [type] [instructions]` — Full pipeline: classify → dispatch → log

## Usage

Zenni calls this when detecting URLs in messages:
```bash
# Classify a URL
bash ~/.openclaw/skills/link-digester/scripts/classify-link.sh "https://youtube.com/watch?v=..."

# Full digest pipeline
bash ~/.openclaw/skills/link-digester/scripts/digest-link.sh "https://youtube.com/watch?v=..." "" "summarize the key points about branding"
```

## Competitor Domains

Maintain a list of known competitor domains in the script. Default competitors:
- mamee.com (Malaysian snacks)
- gardenia.com.my (bread/bakery)
- farm-fresh.com.my (dairy alternative)
- oatside.com (oat milk)
- myprotein.com.my (supplements)
- Other health food / plant-based brands

## RAG Memory Integration

After processing, store results:
```bash
bash ~/.openclaw/skills/rag-memory/scripts/memory-store.sh \
  --agent zenni \
  --type insight \
  --tags "link-digest,$TYPE,$DOMAIN" \
  --text "Processed $TYPE link: $URL — $SUMMARY" \
  --importance 5
```
