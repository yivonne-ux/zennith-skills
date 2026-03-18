# Jade Oracle - Production Deployment Guide

## Overview

Jade Oracle psychic reading engine is now production-ready with full webhook integration and email delivery.

## Current Status ✅

### What Works
- ✅ Shopify Order Webhook Handler
- ✅ Psychic Reading Generation (Tarot + Western Astrology + QMDJ)
- ✅ PDF Report Generation
- ✅ Email Service Integration (SendGrid/Mailgun/AWS SES)
- ✅ Webhook Listener (HTTP server on port 3000)
- ✅ Production Startup Script

### What's Pending
- ⏳ Shopify webhook URL configured in Shopify Admin
- ⏳ Email service API key configured (optional - PDF still delivered)
- ⏳ Production deployment (VPS/Cloud)

## Installation

### Prerequisites

1. **Install required tools:**
   ```bash
   brew install jq ngrok
   pip3 install --break-system-packages fpdf2 PyEphem
   ```

2. **Setup environment variables:**

   For SendGrid (recommended):
   ```bash
   export SENDGRID_API_KEY="your-sendgrid-api-key"
   export FROM_EMAIL="support@jadeoracle.com"
   ```

   Or Mailgun:
   ```bash
   export MAILGUN_API_KEY="your-mailgun-api-key"
   export MAILGUN_DOMAIN="your-mailgun-domain"
   export FROM_EMAIL="support@jadeoracle.com"
   ```

   Or AWS SES:
   ```bash
   export AWS_SES_ACCESS_KEY_ID="your-aws-access-key"
   export AWS_SES_SECRET_ACCESS_KEY="your-aws-secret-key"
   export AWS_REGION="ap-southeast-1"
   export FROM_EMAIL="no-reply@yourdomain.com"
   ```

### Start Production

```bash
cd ~/.openclaw/skills/psychic-reading-engine
bash start-production.sh
```

This will:
1. Check all prerequisites
2. Start webhook listener on port 3000
3. Start ngrok to expose webhook URL
4. Display webhook setup instructions

## Shopify Webhook Setup

### Step 1: Get Webhook URL

```bash
# If ngrok is running, get your public URL:
curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url'

# Or manually expose:
ssh -L 3000:localhost:3000 your-server
```

The webhook listener URL is: `http://localhost:3000`

### Step 2: Create Webhook in Shopify

1. Navigate to: **Shopify Admin → Settings → Notifications → Webhooks**

2. Click **Add webhook**

3. Configure:
   - **Topic**: `orders/create`
   - **Callback URL**: `[your ngrok URL or exposed localhost URL]`
   - **Format**: `JSON`

4. Click **Add webhook**

### Step 3: Verify Webhook

1. Test with a sample order:
   ```bash
   curl -X POST http://localhost:3000
   -H 'Content-Type: application/json'
   -H 'X-Webhook-Token: FU8smQuG9NmLAO9/I7is...' # Replace with your token
   -d '{
     "id": 123456,
     "order_number": 10001,
     "email": "customer@example.com",
     "customer": {
       "email": "customer@example.com",
       "first_name": "Test",
       "last_name": "Customer",
       "name": "Test Customer",
       "note": "Birth date: 1990-05-15. Question: What does the future hold?",
       "phone": "+60123456789"
     },
     "line_items": [
       {
         "name": "QMDJ Session",
         "product_type": "reading",
         "vendor": "jade-oracle",
         "properties": [
           {"key": "question", "value": "What does the future hold?"}
         ]
       }
     ],
     "shipping_address": {
       "first_name": "Test",
       "last_name": "Customer",
       "city": "Kuala Lumpur",
       "country": "MY"
     },
     "billing_address": {
       "first_name": "Test",
       "last_name": "Customer",
       "city": "Kuala Lumpur",
       "country": "MY"
     },
     "created_at": "2026-03-10T13:30:00+08:00"
   }'
   ```

2. Check logs:
   ```bash
   tail -f ~/.openclaw/logs/shopify-webhook-listener.log
   tail -f ~/.openclaw/logs/psychic-reading-pipeline.log
   ```

3. Verify PDF generated:
   ```bash
   ls -lh ~/.openclaw/skills/psychic-reading-engine/data/reports/
   ```

## Manual Testing

### Test Without Email

```bash
cd ~/.openclaw/skills/psychic-reading-engine

# Manual test order
bash orchestrate.sh \
  webhooks/test-order.json \
  test@example.com \
  "Test Customer"
```

### Test PDF Only

```bash
# Generate PDF from existing reading
python3 scripts/generate_pdf.py \
  data/readings/reading-20260310-122216.json \
  data/reports/reading-test.pdf
```

## Monitoring

### View Logs

```bash
# Webhook listener logs
tail -f ~/.openclaw/logs/shopify-webhook-listener.log

# Pipeline logs
tail -f ~/.openclaw/logs/psychic-reading-pipeline.log

# All logs combined
tail -f ~/.openclaw/logs/jade-oracle*.log
```

### Check Webhook Listener Status

```bash
# Health check
curl http://localhost:3000/health | jq

# Get service status
curl http://localhost:3000 | jq
```

### Check Running Processes

```bash
ps aux | grep -E "(webhook-listener|psychic-reading|ngrok)"
```

## Stop Production

```bash
# Stop using PIDs
kill $(cat ~/.openclaw/logs/jade-oracle-webhook.pid)

# Or find and kill manually
pkill -f webhook-listener.sh
pkill -f "python3.*webhook"
pkill ngrok
```

## Troubleshooting

### Webhook Not Receiving Orders

1. **Check webhook listener:**
   ```bash
   curl http://localhost:3000/health
   ```

2. **Check ngrok exposure:**
   ```bash
   curl http://localhost:4040/api/tunnels
   ```

3. **Check Shopify webhook status:**
   - In Shopify Admin → Settings → Notifications → Webhooks
   - Look for orders/create webhook
   - Check "Status" column

4. **Verify Shopify webhook logs:**
   - Shopify Admin → Settings → Notifications → Webhooks logs
   - Check for failed deliveries

### Email Not Sending

1. **Check if email service is configured:**
   ```bash
   echo "SendGrid: $SENDGRID_API_KEY"
   echo "Mailgun: $MAILGUN_DOMAIN"
   echo "AWS SES: $AWS_SES_ACCESS_KEY_ID"
   ```

2. **Test email service manually:**
   ```bash
   # Test SendGrid
   export SENDGRID_API_KEY="your-key"
   sendgrid mail send \
     --from "support@jadeoracle.com" \
     --to "your-email@example.com" \
     --subject "Test Email" \
     --text "This is a test"
   ```

3. **Check logs:**
   ```bash
   tail -f ~/.openclaw/logs/psychic-reading-pipeline.log | grep email
   ```

### PDF Generation Fails

1. **Check PDF dependencies:**
   ```bash
   python3 -c "import fpdf2; print('fpdf2 OK')"
   ```

2. **Check reading JSON exists:**
   ```bash
   ls -lh ~/.openclaw/skills/psychic-reading-engine/data/readings/
   ```

3. **Generate PDF manually:**
   ```bash
   python3 scripts/generate_pdf.py \
     data/readings/reading-DATE-TIME.json \
     data/reports/test.pdf
   ```

## Production Deployment

### VPS Setup (AWS Lightsail/EC2)

1. **Deploy VPS:**
   - 1GB RAM minimum
   - Ubuntu 22.04 LTS
   - Public IP or Elastic IP

2. **Install dependencies:**
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip jq curl
   pip3 install --break-system-packages fpdf2 PyEphem
   ```

3. **Install ngrok (if needed):**
   ```bash
   wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.tgz
   tar xzf ngrok-stable-linux-amd64.tgz
   sudo mv ngrok /usr/local/bin/
   ```

4. **Clone repository:**
   ```bash
   git clone <your-repo-url> ~/jade-oracle
   cd ~/jade-oracle
   ```

5. **Start services:**
   ```bash
   # Start in background
   nohup bash start-production.sh > /tmp/jade-oracle.log 2>&1 &
   
   # Save PID
   echo $! > ~/jade-oracle.pid
   ```

6. **Setup systemd service (recommended):**
   ```bash
   sudo nano /etc/systemd/system/jade-oracle.service
   ```
   
   ```ini
   [Unit]
   Description=Jade Oracle Webhook Listener
   After=network.target

   [Service]
   Type=simple
   User=ubuntu
   WorkingDirectory=/home/ubuntu/jade-oracle
   Environment="SENDGRID_API_KEY=your-key"
   ExecStart=/bin/bash start-production.sh
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   ```

7. **Enable and start:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable jade-oracle
   sudo systemctl start jade-oracle
   sudo systemctl status jade-oracle
   ```

### Cloud Functions (AWS Lambda / Vercel)

**Note:** Shopify webhooks require HTTPS callbacks, which are not supported by AWS Lambda/Vercel without setup. Use VPS or a webhook proxy instead.

## Configuration File Template

Save as `~/.openclaw/skills/psychic-reading-engine/.env`:

```bash
# Webhook Configuration
WEBHOOK_PORT=3000
WEBHOOK_TOKEN=your-secret-token-here

# Email Configuration (at least one required)
SENDGRID_API_KEY=SG.your-sendgrid-api-key
# MAILGUN_API_KEY=your-mailgun-api-key
# MAILGUN_DOMAIN=your-mailgun-domain
# AWS_SES_ACCESS_KEY_ID=your-aws-access-key
# AWS_SES_SECRET_ACCESS_KEY=your-aws-secret-key
# AWS_REGION=ap-southeast-1

# Email From
FROM_EMAIL=support@jadeoracle.com
```

## Scaling Considerations

### High Volume Orders

For >100 orders/day:

1. **Use a real web server:**
   ```bash
   # Use nginx as reverse proxy
   sudo apt install nginx
   sudo systemctl enable nginx
   sudo systemctl start nginx
   ```

2. **Add database for queue management:**
   ```bash
   pip3 install --break-system-packages redis
   ```

3. **Implement job queue:**
   - Redis
   - RabbitMQ
   - AWS SQS

4. **Horizontal scaling:**
   - Multiple webhook listeners
   - Load balancer
   - Separate worker nodes

### Performance Optimization

1. **Generate PDF in parallel:**
   ```bash
   # Add to orchestrate.sh
   python3 scripts/generate_pdf.py "$reading_file" "$pdf_path" &
   ```

2. **Cache readings:**
   ```bash
   mkdir -p data/cache
   cp "$reading_file" "data/cache/${reading_id}.json"
   ```

3. **Batch processing:**
   ```bash
   # Handle multiple orders at once
   bash orchestrate.sh webhooks/batch-orders.json
   ```

## Security Best Practices

1. **Use HTTPS:**
   - ngrok for development (self-signed)
   - Let's Encrypt for production
   - Reverse proxy with SSL termination

2. **Webhook Verification:**
   ```bash
   # Add Shopify HMAC verification
   python3 <<'VERIFY'
   import hmac
   import hashlib
   import json
   from flask import Flask, request

   def verify_shopify_webhook(hmac_header, payload, shared_secret):
       expected_hmac = hmac.new(
           shared_secret.encode('utf-8'),
           payload,
           hashlib.sha256
       ).hexdigest()
       return hmac.compare_digest(hmac_header, expected_hmac)
   VERIFY
   ```

3. **Rate Limiting:**
   ```bash
   # Add rate limiting
   pip3 install --break-system-packages flask-limiter
   ```

4. **Log Rotation:**
   ```bash
   # Rotate logs daily
   kill -USR1 $(cat ~/.openclaw/logs/jade-oracle-webhook.pid)
   ```

## Cost Considerations

### Free Tier Options

- **SendGrid:** Free tier 100 emails/day
- **Mailgun:** Free tier 5,000 emails/month
- **AWS SES:** Free tier 62,000 emails/month

### Paid Options

- **SendGrid:** $4.95/500 emails
- **Mailgun:** $35/month (10,000 emails)
- **AWS SES:** $0.10 per 1,000 emails

### Estimated Costs (100 orders/day)

- Reading generation: Free
- PDF delivery: 100 emails × $0.10 = $10/month (AWS SES)
- Hosting: $5-20/month (VPS)

Total: ~$15-30/month for production

## Support

For issues or questions:
1. Check logs: `~/.openclaw/logs/*`
2. Verify configuration: `.env` file
3. Test webhook: `curl http://localhost:3000/health`
4. Review Shopify webhook status in admin

## Version History

- **v1.0** (2026-03-10): Initial production deployment
  - Webhook listener
  - Email integration
  - PDF generation
  - Full pipeline orchestration

## Next Steps

1. ✅ Start production system
2. ⏳ Configure Shopify webhook
3. ⏳ Test with real orders
4. ⏳ Set up email service (recommended)
5. ⏳ Deploy to VPS
6. ⏳ Monitor and optimize
7. ⏳ Set up analytics tracking