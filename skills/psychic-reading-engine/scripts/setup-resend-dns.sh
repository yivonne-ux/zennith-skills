#!/bin/bash
#
# Add Resend DKIM DNS records to Cloudflare for jadeoracle.co
#
# Usage:
#   1. Sign up at https://resend.com (free — 3000 emails/month)
#   2. Add domain "jadeoracle.co" in Resend dashboard → Domains
#   3. Copy the 3 DKIM CNAME records Resend gives you
#   4. Run: bash setup-resend-dns.sh <record1_name> <record1_value> <record2_name> <record2_value> <record3_name> <record3_value>
#   5. Save your Resend API key: echo "re_XXXXX" > ~/.openclaw/secrets/resend.key
#
# Example:
#   bash setup-resend-dns.sh \
#     "resend._domainkey.jadeoracle.co" "resend._domainkey.xxx.dkim.resend.dev" \
#     "s1._domainkey.jadeoracle.co" "s1._domainkey.xxx.dkim.resend.dev" \
#     "s2._domainkey.jadeoracle.co" "s2._domainkey.xxx.dkim.resend.dev"

set -euo pipefail

if [ $# -lt 6 ]; then
    echo "Usage: $0 <name1> <value1> <name2> <value2> <name3> <value3>"
    echo ""
    echo "Get these 3 CNAME records from Resend dashboard → Domains → jadeoracle.co"
    exit 1
fi

source /Users/jennwoeiloh/.openclaw/secrets/cloudflare.env
ZONE_ID="c94d84ba3bb8d2bd0efa001f3e37b8dc"

for i in 1 2 3; do
    name_idx=$(( (i-1)*2 + 1 ))
    val_idx=$(( (i-1)*2 + 2 ))
    NAME="${!name_idx}"
    VALUE="${!val_idx}"

    echo "Adding CNAME: $NAME → $VALUE"
    RESULT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
      -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
      -H "X-Auth-Key: $CLOUDFLARE_GLOBAL_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"type\": \"CNAME\",
        \"name\": \"$NAME\",
        \"content\": \"$VALUE\",
        \"ttl\": 1,
        \"proxied\": false
      }")

    if echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); exit(0 if d.get('success') else 1)" 2>/dev/null; then
        echo "  OK"
    else
        echo "  FAILED: $RESULT"
    fi
done

echo ""
echo "Done! Go back to Resend dashboard and click 'Verify DNS Records'."
echo "Then save your API key: echo 're_XXXXX' > ~/.openclaw/secrets/resend.key"
