#!/usr/bin/env node
/**
 * Shopify Webhook Server for The Jade Oracle
 *
 * Listens for Shopify order/created webhooks and triggers the reading pipeline.
 *
 * Start: node server.js [--port 3847]
 *
 * Shopify webhook URL: https://jadeoracle.co/webhook/order
 * (Or use ngrok/Tailscale for local dev)
 */

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

// Config
const PORT = parseInt(process.argv.find((_, i, a) => a[i - 1] === '--port') || '3847');
const SECRETS_DIR = path.join(process.env.HOME, '.openclaw/secrets');
const ORDER_HANDLER = path.join(__dirname, 'order-handler.sh');
const ORDERS_DIR = path.join(process.env.HOME, '.openclaw/workspace/data/readings/incoming');
const LOG_FILE = path.join(process.env.HOME, '.openclaw/workspace/rooms/webhook.jsonl');

// Load Shopify webhook secret (set after store creation)
let SHOPIFY_WEBHOOK_SECRET = '';
try {
  const envFile = fs.readFileSync(path.join(SECRETS_DIR, 'shopify-jade.env'), 'utf8');
  const match = envFile.match(/SHOPIFY_WEBHOOK_SECRET=["']?([^"'\n]+)/);
  if (match) SHOPIFY_WEBHOOK_SECRET = match[1];
} catch (e) {
  console.warn('⚠️  No shopify-jade.env found — webhook signature verification disabled');
}

// Ensure dirs exist
fs.mkdirSync(ORDERS_DIR, { recursive: true });

function log(msg, data = {}) {
  const entry = { ts: Date.now(), msg, ...data };
  console.log(`[${new Date().toISOString()}] ${msg}`, Object.keys(data).length ? JSON.stringify(data) : '');
  try { fs.appendFileSync(LOG_FILE, JSON.stringify(entry) + '\n'); } catch (e) {}
}

function verifyWebhook(body, hmacHeader) {
  if (!SHOPIFY_WEBHOOK_SECRET) return true; // Skip verification if no secret
  if (!hmacHeader) return false;
  const hash = crypto.createHmac('sha256', SHOPIFY_WEBHOOK_SECRET)
    .update(body, 'utf8')
    .digest('base64');
  const expected = Buffer.from(hash);
  const received = Buffer.from(hmacHeader);
  if (expected.length !== received.length) return false;
  return crypto.timingSafeEqual(expected, received);
}

function processOrder(orderData) {
  const orderId = orderData.id || 'unknown';
  const orderNum = orderData.order_number || orderId;
  const email = orderData.email || orderData.customer?.email || '';

  log(`Processing order #${orderNum}`, { orderId, email });

  // Save order JSON
  const orderFile = path.join(ORDERS_DIR, `order-${orderNum}-${Date.now()}.json`);
  fs.writeFileSync(orderFile, JSON.stringify(orderData, null, 2));

  // Run order handler in background
  const child = execFile('bash', [ORDER_HANDLER, orderFile], {
    timeout: 120000, // 2 min timeout
    env: { ...process.env, PATH: `/usr/local/bin:${process.env.PATH}` }
  }, (error, stdout, stderr) => {
    if (error) {
      log(`❌ Order #${orderNum} failed`, { error: error.message, stderr: stderr?.substring(0, 500) });
    } else {
      log(`✅ Order #${orderNum} delivered`, { stdout: stdout?.substring(stdout.length - 200) });
    }
  });

  return { orderId, orderNum, email, status: 'processing' };
}

// HTTP server
const server = http.createServer((req, res) => {
  // Health check
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, service: 'jade-oracle-webhook', uptime: process.uptime() }));
    return;
  }

  // Webhook endpoint
  if (req.method === 'POST' && (req.url === '/webhook/order' || req.url === '/webhook')) {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        // Verify Shopify HMAC
        const hmac = req.headers['x-shopify-hmac-sha256'];
        if (SHOPIFY_WEBHOOK_SECRET && !verifyWebhook(body, hmac)) {
          log('⚠️  Invalid webhook signature');
          res.writeHead(401);
          res.end('Unauthorized');
          return;
        }

        const orderData = JSON.parse(body);

        // Check if this is a paid order (not just created)
        const financialStatus = orderData.financial_status || '';
        if (financialStatus === 'pending' || financialStatus === 'voided') {
          log(`Skipping unpaid order`, { financial_status: financialStatus });
          res.writeHead(200);
          res.end('OK - skipped unpaid');
          return;
        }

        const result = processOrder(orderData);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));
      } catch (e) {
        log('❌ Webhook error', { error: e.message });
        res.writeHead(500);
        res.end('Internal error');
      }
    });
    return;
  }

  // Test endpoint — manually trigger a reading
  if (req.method === 'POST' && req.url === '/test') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        // Create a mock Shopify order
        const mockOrder = {
          id: `test-${Date.now()}`,
          order_number: `TEST-${Date.now()}`,
          email: data.email || 'test@jadeoracle.co',
          financial_status: 'paid',
          customer: {
            first_name: data.name?.split(' ')[0] || 'Test',
            last_name: data.name?.split(' ').slice(1).join(' ') || 'User',
            email: data.email || 'test@jadeoracle.co'
          },
          line_items: [{
            title: data.product || 'Intro Reading',
            variant_title: '',
            price: data.price || '1.00'
          }],
          note_attributes: [
            { name: 'birth_date', value: data.birth_date || '1990-06-15' },
            { name: 'birth_time', value: data.birth_time || '14:30' },
            { name: 'birth_place', value: data.birth_place || 'Kuala Lumpur' },
            { name: 'question', value: data.question || '' }
          ]
        };
        const result = processOrder(mockOrder);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ...result, test: true }));
      } catch (e) {
        res.writeHead(400);
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

server.listen(PORT, '0.0.0.0', () => {
  log(`🔮 Jade Oracle webhook server running on port ${PORT}`);
  log(`   Health: http://localhost:${PORT}/health`);
  log(`   Webhook: POST http://localhost:${PORT}/webhook/order`);
  log(`   Test: POST http://localhost:${PORT}/test`);
});
