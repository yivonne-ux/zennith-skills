#!/bin/bash
# setup-gemini.sh — Enable Gemini 2.5 Pro when ready
# Run this after adding GOOGLE_API_KEY to ~/.openclaw/.env

set -e

echo "🔧 Gemini 2.5 Pro Setup"
echo "======================"
echo ""

# Check if GOOGLE_API_KEY is set
if [[ -z "$GOOGLE_API_KEY" ]]; then
  echo "❌ GOOGLE_API_KEY not found in environment"
  echo ""
  echo "To enable Gemini 2.5 Pro:"
  echo "1. Get your API key from https://aistudio.google.com/app/apikey"
  echo "2. Add to ~/.openclaw/.env:"
  echo "   GOOGLE_API_KEY=your_key_here"
  echo "3. Run this script again"
  echo ""
  exit 1
fi

echo "✓ GOOGLE_API_KEY found"
echo ""

# Backup current config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup.$(date +%Y%m%d_%H%M%S)

# Enable Google provider in config
# This uses sed to uncomment the google provider section
# For now, I'll provide manual instructions
echo "⚠️  Manual step required:"
echo ""
echo "Add this to your ~/.openclaw/openclaw.json under models.providers:"
echo ""
cat << 'EOF'
      "google": {
        "baseUrl": "https://generativelanguage.googleapis.com/v1beta",
        "apiKey": "${GOOGLE_API_KEY}",
        "auth": "api-key",
        "api": "google-generative-ai",
        "models": [
          {
            "id": "gemini-2.5-pro-exp-03-25",
            "name": "Gemini 2.5 Pro",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 1000000,
            "maxTokens": 65536
          }
        ]
      },
EOF

echo ""
echo "And add this alias under agents.defaults.models:"
echo ""
cat << 'EOF'
        "google/gemini-2.5-pro-exp-03-25": {
          "alias": "gemini25",
          "params": {"temperature": 1}
        }
EOF

echo ""
echo "Then run: openclaw gateway restart"
