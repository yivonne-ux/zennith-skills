# WeChat Integration - Development Guide

## Quick Start

### Prerequisites
- Node.js 18+
- OpenClaw installed
- Gateway running

### Option 1: Personal WeChat (openclaw-wechat)

```bash
# Install plugin
openclaw plugins install @canghe/openclaw-wechat

# Configure
openclaw config set channels.wechat.apiKey "wc_live_xxxxxxxxxxxxxxxx"
openclaw config set channels.wechat.proxyUrl "http://your-ipad-ip:3000"
openclaw config set channels.wechat.enabled true
openclaw config set channels.wechat.deviceType "ipad"

# Restart gateway
openclaw gateway restart
```

### Option 2: Enterprise WeChat (WeCom) - RECOMMENDED

```bash
# Install plugin
openclaw plugins install @sunnoy/wecom

# Configure (edit ~/.openclaw/config.json)
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
      "encodingAesKey": "Your EncodingAESKey"
    }
  }
}

# Restart gateway
openclaw gateway restart
```

## Development Notes

### Testing WeCom Setup

1. Create WeCom application in admin console
2. Configure webhook URL
3. Copy Token and EncodingAESKey
4. Test with simple message

### Plugin Architecture

Both plugins follow OpenClaw's channel pattern:
- Plugins are NPM packages
- Configured via `openclaw.json`
- Gateway handles message routing
- Agents receive messages via configured channels

### Environment Variables

```bash
# ~/.openclaw/secrets/wechat.env (optional)
WECHAT_API_KEY="wc_live_xxxxxxxxxxxxxxxx"
WECHAT_PROXY_URL="http://your-proxy:3000"
WECHAT_TOKEN="Your WeCom Token"
WECHAT_AES_KEY="Your EncodingAESKey"
```

## Current Status

### Completed
- ✅ WeChat integration documented
- ✅ Two options documented (Personal + WeCom)
- ✅ Setup steps documented
- ✅ Configuration examples provided
- ✅ SKILL.md created with full documentation

### Next Steps (Future)
- ⏳ Implement actual plugin wrapper
- ⏳ Add config validation
- ⏳ Test with real WeCom setup
- ⏳ Document plugin installation

## Usage Examples

### Send Message
```bash
# WeCom
openclaw message send \
  --channel wecom \
  --to "user-wechat-id" \
  --message "Hello from OpenClaw!"

# Personal WeChat
openclaw message send \
  --channel wechat \
  --to "user-wechat-id" \
  --message "Hello from OpenClaw!"
```

### Receive Messages
- Gateway automatically routes messages to agents
- Configure in `rooms/` for routing rules

## Troubleshooting

### Gateway Not Starting
- Check configuration in `openclaw.json`
- Verify plugin is installed
- Check logs: `openclaw gateway status`

### Messages Not Receiving
- Verify webhook URL is accessible
- Check WeCom admin console for errors
- Test with webhook testing tool

### QR Code Not Showing
- Restart proxy service
- Check WeChat app is logged in
- Verify deviceType configuration

---

*For questions, contact Taoz (GAIA CORP-OS)*
