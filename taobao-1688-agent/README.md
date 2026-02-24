# Taobao/1688 Skill - Development Guide

## Quick Start

### Prerequisites
- Node.js 18+
- OpenClaw installed
- OpenClaw browser tool available

### Installation

```bash
# Skill is built into OpenClaw core
# No additional installation required
```

### Development Setup

```bash
cd ~/.openclaw/skills/taobao-1688-agent

# Install dependencies
npm install

# Run tests
npm test
```

## File Structure

```
taobao-1688-agent/
├── SKILL.md              # Skill definition (main documentation)
├── README.md             # Development README
├── index.js              # Main entry point
├── lib/
│   ├── taobao.js         # Taobao-specific handlers (future)
│   ├── 1688.js           # 1688-specific handlers (future)
│   └── extractors.js     # Data extraction utilities (future)
├── templates/
│   └── search-results.hbs # Output formatting (future)
├── package.json          # NPM config
└── test.js               # Test script
```

## Current Implementation

### Core Functions

1. **searchTaobao(options)**
   - Search products on Taobao/1688
   - Returns structured product data
   - Supports keyword, platform, sort options

2. **getProductDetails(options)**
   - Get detailed product information
   - Extracts price, rating, seller, etc.

3. **exportToJson(results, filename)**
   - Export search results to JSON
   - Save to configured export directory

4. **exportToCsv(results, filename)**
   - Export search results to CSV
   - Properly escapes special characters

5. **saveScreenshot(imageData, keyword)**
   - Save screenshot to configured directory
   - Naming convention: `{timestamp}-{keyword}.png`

### Configuration

```json
// config.json
{
  "export_dir": "~/workspace/taobao-results",
  "screenshot_dir": "~/workspace/taobao-screenshots",
  "platforms": ["taobao", "1688"]
}
```

## Next Steps - MVP Implementation

### Phase 1: Browser Automation

```javascript
// Implement actual browser automation
const { browser } = require('openclaw');

async function searchTaobao(options) {
  const { keyword, platform = 'taobao' } = options;
  
  // Navigate to search page
  await browser.navigate(`https://s.${platform}.com/search?q=${encodeURIComponent(keyword)}`);
  
  // Wait for dynamic content
  await browser.wait(3000);
  
  // Screenshot results
  const screenshotPath = await browser.screenshot({ fullPage: true });
  
  // Extract product data
  const products = await browser.evaluate(() => {
    // Use actual DOM selectors
    return Array.from(document.querySelectorAll('.product-item'))
      .map(item => ({
        id: item.dataset.id,
        title: item.querySelector('.title')?.innerText || '',
        price: parseFloat(item.querySelector('.price')?.innerText.replace(/[^0-9.]/g, '')) || 0,
        sales: item.querySelector('.sales')?.innerText || '0',
        rating: parseFloat(item.querySelector('.rating')?.innerText) || 0,
        shop: item.querySelector('.shop')?.innerText || '',
      }));
  });
  
  return { products, screenshot: screenshotPath };
}
```

### Phase 2: Data Extraction

Implement actual data extraction using browser evaluate:
- Product title
- Price (current and original)
- Sales count
- Shop name and location
- Rating
- Product images
- Product URL

### Phase 3: Pagination

```javascript
async function fetchPage(pageNum) {
  await browser.navigate(`https://s.taobao.com/search?q=${keyword}&s=${(pageNum-1)*44}`);
  await browser.wait(2000);
  // Extract products
}

async function fetchAllPages(keyword, maxPages = 3) {
  const allProducts = [];
  for (let i = 1; i <= maxPages; i++) {
    const page = await fetchPage(i);
    allProducts.push(...page.products);
  }
  return allProducts;
}
```

### Phase 4: 1688 Support

1688 has different DOM structure:
- Different class names
- Different layout
- MOQ (minimum order quantity) displayed
- Wholesale pricing

## Testing

### Manual Testing
```bash
# Test with sample data
node -e "
const taobao = require('./index');
taobao.searchTaobao({ keyword: 'test' }).then(console.log);
"
```

### Browser Testing
```bash
# Test browser automation manually
# Start OpenClaw browser and test navigation
```

## Integration with OpenClaw

### Agent Usage
```javascript
// In agent skill
const taobao = require('@openclaw/skill-taobao-1688-agent');

async function searchProducts(task) {
  const results = await taobao.searchTaobao({
    keyword: task.keyword,
    platform: task.platform || 'taobao',
  });
  
  await taobao.exportToJson(results);
  await taobao.saveScreenshot(results.screenshot, task.keyword);
  
  return results;
}
```

### CLI Usage
```bash
openclaw taobao search --keyword "coconut oil" --platform taobao --export json
```

## Common Issues

### Page Not Loading
- Check network connection
- Verify Taobao/1688 is accessible
- Try different user agent

### Data Not Extracting
- Check DOM selectors match actual page structure
- Wait longer for dynamic content
- Try different wait strategy

### Anti-Bot Blocked
- Use stealth browser mode
- Add realistic delays
- Consider residential proxy

## Contributing

1. Test changes manually
2. Update SKILL.md with new features
3. Add to this README for dev notes
4. Submit PR with test output

---

*For questions, contact Taoz (GAIA CORP-OS)*
