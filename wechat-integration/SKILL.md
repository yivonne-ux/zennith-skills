# WeChat Integration Skill

**OpenClaw skill for WeChat and WeCom integration**

## Overview

This skill integrates WeChat into OpenClaw for messaging and automation. Two options available:

1. **Personal WeChat** via `openclaw-wechat` plugin
2. **Enterprise WeChat (WeCom)** via `@sunnoy/wecom` plugin

## Option 1: Personal WeChat (openclaw-wechat)

### Prerequisites
- OpenClaw installed and running
- Access to personal WeChat account

### Installation

```bash
openclaw plugins install @canghe/openclaw-wechat
```

### Setup Steps

1. **Start the proxy service** on your iPad/Mac:
   ```bash
   # On your iPad or Mac
   npm install -g openclaw-wechat
   openclaw-wechat
   ```

2. **Configure OpenClaw**:
   ```bash
   openclaw config set channels.wechat.apiKey "wc_live_xxxxxxxxxxxxxxxx"
   openclaw config set channels.wechat.proxyUrl "http://your-ipad-ip:3000"
   openclaw config set channels.wechat.enabled true
   openclaw config set channels.wechat.deviceType "ipad"
   ```

3. **Restart OpenClaw Gateway**:
   ```bash
   openclaw gateway restart
   ```

4. **QR Code Login**:
   - The proxy will display a QR code
   - Scan with your personal WeChat app
   - Gateway will connect once verified

### Configuration

```json
{
  "channels": {
    "wechat": {
      "enabled": true,
      "apiKey": "wc_live_xxxxxxxxxxxxxxxx",
      "proxyUrl": "http://your-ipad-ip:3000",
      "webhookHost": "your-server-ip",
      "webhookPort": 18790,
      "deviceType": "ipad"
    }
  }
}
```

### Usage

**Send message:**
```bash
openclaw message send --channel wechat --to "user-wechat-id" --message "Hello from OpenClaw!"
```

**Receive messages:**
- Gateway automatically receives messages via webhook
- Messages route to appropriate agent based on room configuration

### Limitations
- Requires API key purchase from plugin author
- Requires running proxy service (iPad/Mac)
- Uses unofficial iPad/Mac protocol (moderate ban risk)

---

## Option 2: Enterprise WeChat / WeCom (RECOMMENDED)

### Prerequisites
- OpenClaw installed and running
- WeCom (企业微信) admin account

### Installation

```bash
openclaw plugins install @sunnoy/wecom
```

### Setup Steps

1. **Create WeCom Application**:
   - Log in to [WeCom Admin Console](https://work.weixin.qq.com/)
   - Navigate to "Application Management" → "Create Application" → "Intelligent Robot"
   - Configure application details

2. **Configure Webhook**:
   - Webhook URL: `https://your-domain.com/webhooks/wecom`
   - Copy the generated Token and EncodingAESKey

3. **Configure OpenClaw**:
   ```json
   {
     "plugins": {
       "entries": {
         "wecom": { "enabled": true }
       }
     },
     "channels": {
       "wecom": {
         "enabled": true,
         "token": "Your Token",
         "encodingAesKey": "Your EncodingAESKey",
         "adminUsers": ["admin-userid"],
         "commands": {
           "enabled": true,
           "allowlist": ["/new", "/status", "/help", "/compact"]
         }
       }
     }
   }
   ```

4. **Restart OpenClaw Gateway**:
   ```bash
   openclaw gateway restart
   ```

### Configuration

**Basic Setup (Minimal):**
```json
{
  "plugins": {
    "entries": {
      "wecom": { "enabled": true }
    }
  },
  "channels": {
    "wecom": {
      "enabled": true,
      "token": "YOUR_TOKEN",
      "encodingAesKey": "YOUR_AES_KEY"
    }
  }
}
```

**Advanced Setup:**
```json
{
  "channels": {
    "wecom": {
      "enabled": true,
      "token": "YOUR_TOKEN",
      "encodingAesKey": "YOUR_AES_KEY",
      "adminUsers": ["admin1", "admin2"],
      "commands": {
        "enabled": true,
        "allowlist": ["/new", "/status", "/help", "/compact"]
      }
    }
  }
}
```

### Usage

**Send message:**
```bash
openclaw message send --channel wecom --to "user-wechat-id" --message "Hello from OpenClaw!"
```

### Features
- ✅ Official WeCom API (no ban risk)
- ✅ Streaming responses (typewriter-style)
- ✅ Dynamic agents (per-user isolation)
- ✅ Rich message types (text, image, voice, file)
- ✅ AES decryption for images
- ✅ Admin controls (command allowlist)

---

## Comparison

| Feature | Personal WeChat | WeCom |
|---------|----------------|-------|
| **API Type** | iPad Protocol | Official WeCom API |
| **Risk** | Medium (unofficial) | Low (official) |
| **Cost** | Paid API key | Free |
| **Setup** | Proxy service required | Admin console setup |
| **Reliability** | Good | Excellent |
| **Best For** | Personal use | Business/Enterprise |

---

## Troubleshooting

### Proxy Connection Failed
- Ensure proxy service is running on iPad/Mac
- Check firewall allows connection
- Verify proxyUrl IP address is correct

### WeCom Webhook Not Receiving
- Verify webhook URL is publicly accessible
- Check WeCom admin console for errors
- Test with webhook testing tool

### QR Code Not Showing
- Restart proxy service
- Check WeChat app is logged in
- Verify deviceType configuration

---

## Support

- **Personal WeChat Plugin:** https://github.com/freestylefly/openclaw-wechat
- **WeCom Plugin:** https://github.com/sunnoy/openclaw-plugin-wecom

---

*Built for GAIA CORP-OS by Taoz*
