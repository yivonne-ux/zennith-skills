# Taobao/1688 Agent Skill

**OpenClaw skill for autonomous product research on Taobao and 1688**

## Overview

This skill enables OpenClaw to:
- Search products on Taobao (B2C) and 1688 (B2B)
- Extract product details (price, rating, sales, shop name)
- Screenshot product listings
- Export data to JSON/CSV
- Handle pagination and filters

## Installation

```bash
# Skill is built into OpenClaw core
# No additional installation required
```

## Usage

### Basic Search

```bash
# Search on Taobao
openclaw taobao search --keyword "organic coconut oil" --platform taobao

# Search on 1688 (wholesale)
openclaw taobao search --keyword "organic coconut oil" --platform 1688

# With filters
openclaw taobao search \
  --keyword "organic coconut oil" \
  --platform taobao \
  --sort price_asc \
  --min-price 10 \
  --max-price 100
```

### Product Details

```bash
# Get detailed product info
openclaw taobao details --url "https://item.taobao.com/item.htm?id=123456"

# Get 1688 product
openclaw taobao details --url "https://detail.1688.com/offer/123456.html"
```

### Export Options

```bash
# Export to JSON
openclaw taobao search --keyword "coconut oil" --export json

# Export to CSV
openclaw taobao search --keyword "coconut oil" --export csv

# Save screenshots
openclaw taobao search --keyword "coconut oil" --screenshot
```

## Platform Differences

### Taobao (淘宝)
- **Target:** Consumers (B2C)
- **Pricing:** Retail prices
- **MOQ:** Usually 1 unit
- **Use Case:** Product research, competitor analysis

### 1688 (阿里巴巴)
- **Target:** Businesses (B2B)
- **Pricing:** Wholesale prices (30-50% cheaper)
- **MOQ:** Usually 10-1000+ units
- **Use Case:** Bulk purchasing, supplier research

## Output Format

### JSON Output
```json
{
  "platform": "taobao",
  "keyword": "organic coconut oil",
  "timestamp": "2026-02-24T13:19:00.000Z",
  "products": [
    {
      "id": "123456789",
      "title": "Organic Virgin Coconut Oil 500ml",
      "price": 45.99,
      "original_price": 59.99,
      "sales": "1,234",
      "rating": 4.8,
      "shop_name": "Organic Goods Store",
      "shop_location": "Guangdong, China",
      "product_url": "https://item.taobao.com/item.htm?id=123456789",
      "images": ["https://img1.jpg", "https://img2.jpg"]
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 10,
    "products_per_page": 20
  }
}
```

### Screenshot Output
- Saved to: `~/workspace/taobao-screenshots/{timestamp}-{keyword}.png`
- Full-page screenshots of search results
-可用于 visual verification

## Browser Automation

The skill uses OpenClaw's browser tool for:
1. Navigate to search page
2. Wait for dynamic content to load
3. Screenshot results
4. Extract product data from DOM
5. Handle pagination

### Example Browser Workflow
```javascript
// Pseudocode
await browser.navigate('https://s.taobao.com/search?q=organic+coconut+oil');
await browser.wait(3000); // Wait for dynamic content
await browser.screenshot('search-results.png');
const products = await browser.evaluate(() => {
  // Extract product data from DOM
  return Array.from(document.querySelectorAll('.product-item'))
    .map(item => ({
      title: item.querySelector('.title').innerText,
      price: parseFloat(item.querySelector('.price').innerText),
      sales: item.querySelector('.sales').innerText,
    }));
});
```

## Configuration

### Environment Variables
```bash
# ~/.openclaw/secrets/taobao.env
TAOBAO_API_KEY="your-api-key"  # Optional, for official API access
TAOBAO_EXPORT_DIR="~/workspace/taobao-results"
TAOBAO_SCREENSHOT_DIR="~/workspace/taobao-screenshots"
```

### Config File
```json
{
  "taobao": {
    "export_dir": "~/workspace/taobao-results",
    "screenshot_dir": "~/workspace/taobao-screenshots",
    "platforms": ["taobao", "1688"]
  }
}
```

## Features

### Core Functionality
- ✅ Search products on Taobao/1688
- ✅ Extract product details (price, rating, sales, shop)
- ✅ Screenshot product listings
- ✅ Export to JSON/CSV
- ✅ Pagination support
- ✅ Price filters

### Advanced Features (Future)
- ⏳ Price tracking over time
- ⏳ Product comparison across platforms
- ⏳ Image analysis for quality
- ⏳ Seller reputation scoring
- ⏳ Review sentiment analysis

## Challenges & Mitigations

### Anti-Bot Detection
Taobao/1688 use sophisticated bot detection:
- JavaScript challenges
- CAPTCHA
- Device fingerprinting

**Mitigations:**
- Use stealth browser configurations
- Add realistic delays between requests
- Rotate user agents
- Consider residential proxy for heavy use

### Login Requirements
- Cart/purchase actions require login
- Some features may require authentication

**Mitigations:**
- Document manual login process
- Use human-in-the-loop for CAPTCHA

### Rate Limiting
- Aggressive rate limiting enforced
- May block IP for heavy use

**Mitigations:**
- Add delays between requests
- Implement retry logic
- Consider rotating IP addresses

## Usage Examples

### Example 1: Product Research
```bash
# Search for trending products
openclaw taobao search \
  --keyword "organic beauty products" \
  --platform taobao \
  --sort sales \
  --min-rating 4.5 \
  --export json \
  --screenshot
```

### Example 2: Price Comparison
```bash
# Compare Taobao vs 1688 prices
openclaw taobao search \
  --keyword "coconut oil" \
  --platform taobao \
  --export json > taobao-results.json

openclaw taobao search \
  --keyword "coconut oil" \
  --platform 1688 \
  --export json > 1688-results.json
```

### Example 3: Product Details
```bash
# Get detailed info for specific product
openclaw taobao details \
  --url "https://item.taobao.com/item.htm?id=123456789" \
  --screenshot
```

## Output Files

```
~/workspace/
└── taobao-results/
    └── {timestamp}/
        ├── search.json          # Product data
        ├── search.csv           # CSV export
        └── screenshots/
            └── {timestamp}-{keyword}.png
```

## Troubleshooting

### Page Not Loading
- Check internet connection
- Verify Taobao/1688 is accessible
- Try different platform (Taobao vs 1688)

### Data Extraction Failed
- Check website structure (may have changed)
- Increase wait time for dynamic content
- Try different search term

### Screenshot Failed
- Check browser permissions
- Verify export directory exists
- Try different screenshot format

## Support

For issues or feature requests:
- Check OpenClaw documentation
- Review browser automation logs
- Test with manual browser first

---

*Built for GAIA CORP-OS by Taoz*
