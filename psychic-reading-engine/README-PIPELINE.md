# Automated Reading Generation Pipeline

End-to-end pipeline that transforms Shopify orders into personalized PDF psychic reading reports.

## Overview

This pipeline automates the creation of psychic readings from customer orders:

1. **Shopify Webhook Capture**: Receives order data (name, DOB, questions) from Shopify
2. **Reading Generation**: Runs psychic-reading.sh with customer data (Tarot + Western Astrology)
3. **PDF Generation**: Creates beautiful PDF reports with:
   - Cover page with customer name
   - Cross-system themes analysis
   - Tarot section (with placeholder for card images)
   - Western astrology section (birth chart insights)
   - Qi Men Dun Jia (QMDJ) section (with placeholder for chart)
   - Synthesis + actionable guidance
   - Upsell CTAs
4. **Email Delivery**: Sends PDF to customer (24-72hr turnaround)

## Directory Structure

```
skills/psychic-reading-engine/
├── scripts/
│   ├── psychic-reading.sh          # Main reading generation
│   ├── birth-chart.py              # Western astrology engine
│   ├── qmdj-calc.py                # QMDJ engine
│   ├── tarot-engine.py             # Tarot engine
│   ├── reading-synthesizer.py      # Cross-system synthesis
│   └── generate_pdf.py             # PDF report generator
├── webhooks/
│   ├── shopify-webhook.sh          # Shopify webhook handler
│   └── test-order.json             # Sample order payload
├── data/
│   ├── readings/                   # Generated readings (JSON)
│   └── reports/                    # Final PDF reports
├── SKILL.md                        # Psychic reading engine skill
└── README-PIPELINE.md              # This file
```

## Usage

### 1. Manual Reading Generation

```bash
# Generate reading for a specific customer
bash scripts/psychic-reading.sh \
  --name "Alice Chen" \
  --date "1990-05-15" \
  --time "14:30" \
  --lat 3.1390 \
  --lon 101.6869 \
  --tz "Asia/Kuala_Lumpur" \
  --spread celtic-cross \
  --question "career" \
  --output json
```

### 2. Shopify Webhook Handler

```bash
# Process a Shopify order webhook
bash webhooks/shopify-webhook.sh handle order.json data/readings

# Test with sample data
bash webhooks/shopify-webhook.sh test

# Start webhook listener for development
bash webhooks/shopify-webhook.sh listen 3000
```

### 3. PDF Generation

```bash
# Generate PDF from reading JSON
python3 scripts/generate_pdf.py readings/reading-20260309-102658.json reports/reading-20260309-102658.pdf
```

### 4. Full Pipeline Orchestrator

```bash
# Run full pipeline with sample data
bash orchestrate.sh test

# Run with specific order file
bash orchestrate.sh run webhooks/test-order.json customer@example.com "Alice Chen"
```

## Shopify Webhook Configuration

### Manual Webhook Setup

1. **Create webhook in Shopify Admin**:
   - Navigate to Settings → Notifications → Webhooks
   - Click "Add webhook"
   - Choose topic: `orders/create`
   - Callback URL: `[your ngrok URL]/api/shopify/webhook`
   - Content type: `application/json`

2. **Expose with ngrok**:
   ```bash
   ngrok http 3000
   # Output URL: https://abc123.ngrok.io
   ```

3. **Enter webhook URL in Shopify**:
   ```
   https://abc123.ngrok.io/api/shopify/webhook
   ```

### Webhook Payload Format

```json
{
  "id": 123456789,
  "order_number": 10001,
  "email": "customer@example.com",
  "customer": {
    "email": "customer@example.com",
    "first_name": "Alice",
    "last_name": "Chen",
    "name": "Alice Chen",
    "note": "Birth date: 1990-05-15. Question: What does the future hold for my career?"
  },
  "line_items": [
    {
      "name": "QMDJ Session - Career Guidance",
      "product_type": "reading",
      "vendor": "gaia-psychic",
      "properties": [
        {"key": "question", "value": "What does the future hold for my career?"}
      ]
    }
  ]
}
```

## Output

### JSON Reading

```json
{
  "reading_for": "Alice Chen",
  "generated_at": "2026-03-09T10:30:00Z",
  "systems_used": ["Western Astrology", "Tarot"],
  "cross_system_themes": [...],
  "dominant_element": "Earth",
  "sections": [
    {
      "section": "overview",
      "core_insight": "...",
      "supporting_evidence": [...],
      "barnum_layer": [...],
      "confidence_level": 85
    }
  ],
  "overall_confidence": 72.9
}
```

### PDF Report

Beautiful 8.9KB PDF report with:
- Dark theme with gold accents
- Professional layout
- All reading sections
- CTA for upsells
- Footer with disclaimer

## Installation

### Dependencies

```bash
# Python packages
pip3 install --break-system-packages fpdf2

# No other dependencies required
# - birth-chart.py uses: PyEphem, pytz
# - All scripts use only Python standard library
```

### Prerequisites

- Python 3.7+
- Bash 4.0+
- fpdf2 library

## Email Delivery

### Configuration Required

Email delivery needs an email service (SendGrid, Mailgun, AWS SES, etc.).

### Current Status

Email sending is a **placeholder** in orchestrate.sh. To enable:

1. **Sign up for email service**
2. **Get API key**
3. **Add email service integration** in generate_pdf.py or orchestrate.sh
4. **Configure from/to/attachment** parameters

### Example Email Service Integration

```bash
# Using SendGrid (example)
curl -X POST https://api.sendgrid.com/v3/mail/send \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "from": {"email": "psychic@gaiacorp.com"},
    "to": [{"email": "customer@example.com"}],
    "subject": "Your Psychic Reading Report",
    "content": [{
      "type": "text/plain",
      "value": "Your personalized reading is attached."
    }],
    "attachments": [{
      "content": "$(base64 < reading.pdf)",
      "filename": "reading.pdf",
      "type": "application/pdf",
      "disposition": "attachment"
    }]
  }'
```

## Troubleshooting

### Issue: PDF generation fails with Unicode errors

**Cause**: Reading data contains non-ASCII characters

**Solution**: generate_pdf.py automatically removes non-ASCII characters for PDF compatibility

### Issue: Shopify webhook not receiving orders

**Cause**: Webhook URL not properly configured

**Solution**:
1. Verify ngrok URL is accessible: `curl https://[ngrok-url]`
2. Check Shopify webhook status in admin
3. Verify Shopify → Settings → Notifications → Webhooks logs

### Issue: Reading generation is slow

**Cause**: Three engines run in parallel but may have dependencies

**Solution**: The script waits for all engines to complete before synthesis. This is normal.

### Issue: QMDJ chart not showing in PDF

**Cause**: Chart visualization is a placeholder (no QMDJ rendering code yet)

**Solution**: See `add_qmdj_section()` in generate_pdf.py for placeholder implementation

### Issue: Tarot card images not showing

**Cause**: No tarot card images exist

**Solution**:
1. Download tarot card images (Rider-Waite deck)
2. Store in `data/tarot-cards/`
3. Update `add_tarot_section()` in generate_pdf.py to reference images

## Future Enhancements

1. **QMDJ Chart Visualization**:
   - Generate ASCII or SVG representation of 9 palaces
   - Add to PDF with chart data

2. **Tarot Card Images**:
   - Integrate with tarot-deck API or local image library
   - Display card images in tarot section

3. **Email Delivery**:
   - Implement SendGrid/Mailgun integration
   - Add email template customization
   - Handle email sending failures

4. **Batch Processing**:
   - Process multiple orders from Shopify export
   - Generate PDFs in batch mode

5. **Analytics**:
   - Track reading completion rates
   - Monitor PDF generation times
   - Email open/click rates (if using tracking)

## Tech Stack

- **Webhook Handler**: Bash + Python
- **Reading Generation**: Bash + Python (PyEphem, QMDJ algorithm, Tarot database)
- **PDF Generation**: fpdf2 (Python)
- **Output**: JSON + PDF
- **Email**: (Pending implementation)

## License

Part of GAIA CORP-OS psychic reading system

## Support

For issues or questions:
1. Check logs: `~/.openclaw/logs/psychic-reading-pipeline.log`
2. Review generated readings: `data/readings/`
3. Check Shopify webhook logs: Shopify Admin → Settings → Notifications → Webhooks

## Version History

- **v1.0** (2026-03-09): Initial pipeline setup
  - Shopify webhook handler
  - Reading generation (Tarot + Western Astrology)
  - PDF report generator
  - Basic orchestrator