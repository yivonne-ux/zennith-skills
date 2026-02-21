# Klaviyo Image CDN Pipeline Skill

End-to-end image optimization and CDN deployment for Klaviyo email campaigns.

## Quick Start

```bash
# 1. Source images from Shopify/Google Drive
bash ~/.openclaw/skills/klaviyo-image-pipeline/scripts/source-images.sh

# 2. Compress for email (<200KB, 600px width)
bash ~/.openclaw/skills/klaviyo-image-pipeline/scripts/compress-images.sh

# 3. Upload to CDN (Shopify Files/Cloudfront)
bash ~/.openclaw/skills/klaviyo-image-pipeline/scripts/upload-to-cdn.sh

# 4. Inject URLs into templates
bash ~/.openclaw/skills/klaviyo-image-pipeline/scripts/inject-urls.sh
```

## Requirements

- `imagemagick` or `sharp` (Node.js) for compression
- Shopify API key OR Cloudfront credentials
- Access to product image source (Shopify/Google Drive)

## Image Specs for Email

- **Max width:** 600px (mobile-first)
- **Max file size:** 200KB per image
- **Format:** JPEG 80% quality or WebP
- **Total email size:** <1MB (including all images)

## Error Handling

If any step fails:
1. Log error to `feedback.jsonl`
2. Retry with exponential backoff
3. Escalate to Claude Code if 3 retries fail
