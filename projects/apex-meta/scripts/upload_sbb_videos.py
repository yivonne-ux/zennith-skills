"""Upload SBB videos to SALES-EN and TEST-CN campaigns.

Uploads 11 SBB videos from batch-2026-03:
- 6 EN videos → SALES-EN / EN-TOP-PERFORMERS ad set
- 5 CN videos → TEST-CN / CN-MIX ad set

Each ad created in PAUSED state for human review before going live.
"""

import json
import os
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path


# --- Config ---
AD_ACCOUNT = "act_830110298602617"
PAGE_ID = "318283048041590"
GRAPH_VERSION = "v21.0"
GRAPH_BASE = f"https://graph.facebook.com/{GRAPH_VERSION}"

# Ad set targets
SALES_EN_ADSET = "120243085921060787"  # EN-TOP-PERFORMERS in SALES-EN
TEST_CN_ADSET = "120242860861020787"   # CN-MIX in TEST-CN

# WhatsApp message templates
EN_WA_TEMPLATE = {
    "page_welcome_message": json.dumps({
        "type": "VISUAL_EDITOR",
        "version": 2,
        "landing_screen_type": "welcome_message",
        "media_type": "text",
        "text_format": {
            "customer_action_type": "autofill_message",
            "message": {
                "autofill": "I'd like to see your menu and package!",
                "text": "Hey there! Welcome to Mirra \ud83c\udf31\n\nWe're all about making healthy eating easy and yummy with our low-cal bento meals.\n\nWhat can I help you with today?"
            }
        }
    })
}

CN_WA_TEMPLATE = {
    "page_welcome_message": json.dumps({
        "type": "VISUAL_EDITOR",
        "version": 2,
        "landing_screen_type": "welcome_message",
        "media_type": "text",
        "text_format": {
            "customer_action_type": "ice_breakers",
            "message": {
                "ice_breakers": [
                    {"title": "\u6211\u6709\u5174\u8da3\u60f3\u8981\u4e86\u89e3 "},
                    {"title": "\u6211\u60f3\u77e5\u9053\u4ef7\u683c"},
                    {"title": "\u6709\u4ec0\u4e48\u4f18\u60e0\u5417\uff1f"}
                ],
                "text": "Hi, {{user_first_name}}! \u6b22\u8fce\u6765\u5230Mirra \ud83c\udf31\n\u60f3\u8981\u4e86\u89e3\u8ba2\u9910\u914d\u5957\u5417\uff1f"
            }
        }
    })
}

# Video files and their ad copy
BATCH_DIR = Path.home() / "Library/CloudStorage/GoogleDrive-love@huemankind.world/My Drive/Mirra/production/batch-2026-03"

VIDEOS = [
    # EN videos → SALES-EN
    {
        "file": "BOFU-EN-SBB-Direct-Conversion-Shorts-sbb02/BOFU-EN-SBB-Direct-Conversion.mp4",
        "name": "SALES-VID-SBB-EN-DirectConversion",
        "lang": "EN",
        "body": "she switched to mirra bentos.\ndropped a size in 3 weeks.\nstill ate lunch every single day.",
        "title": "Under 500kcal. From RM19/meal.",
        "description": "50+ rotating dishes. delivered to your door.",
    },
    {
        "file": "FOMO-EN-SBB-Scarcity-Hook-Shorts-sbb04/FOMO-EN-SBB-Scarcity-Hook.mp4",
        "name": "SALES-VID-SBB-EN-ScarcityHook",
        "lang": "EN",
        "body": "everyone asking where she gets her lunch.\nsame answer every time.\n\"it's under 500 cal and i didn't cook it\"",
        "title": "Mirra Bento. From RM19/meal.",
        "description": "low cal bento that actually tastes good.",
    },
    {
        "file": "SHOWCASE-EN-SBB-Product-Showcase-Shorts-sbb06/SHOWCASE-EN-SBB-Product-Showcase.mp4",
        "name": "SALES-VID-SBB-EN-ProductShowcase",
        "lang": "EN",
        "body": "50 dishes. none of them boring.\nunder 500kcal each.\nand she's still full at dinner.",
        "title": "Mirra Diet Bento. From RM19.",
        "description": "dropped a size. kept every lunch.",
    },
    {
        "file": "BOFU-en-SBB-Orders-Surge-130-Lunch-Shorts-3b158557/BOFU-en-SBB-Orders-Surge-130-Lunch-Shorts-3b158557-portrait.mp4",
        "name": "SALES-VID-SBB-EN-OrdersSurge",
        "lang": "EN",
        "body": "130 girls ordered mirra this week.\nnot because it's trendy.\nbecause it actually works.",
        "title": "Under 500kcal. From RM19/meal.",
        "description": "diet bento that fits your jeans and your schedule.",
    },
    {
        "file": "BOFU-en-SBB-Price-Demand-5000-Monthly-Shorts-54ca30eb/BOFU-en-SBB-Price-Demand-5000-Monthly-Shorts-54ca30eb-portrait.mp4",
        "name": "SALES-VID-SBB-EN-PriceDemand",
        "lang": "EN",
        "body": "5,000 bentos a month.\nand it's not because they're cheap.\nit's because they work.",
        "title": "From RM19/meal. Under 500kcal.",
        "description": "50+ dishes. free delivery in KL.",
    },
    {
        "file": "BOFU-en-SBB-Transformation-250-Subscribers-Shorts-879e6466/BOFU-en-SBB-Transformation-250-Subscribers-Shorts-879e6466-portrait.mp4",
        "name": "SALES-VID-SBB-EN-Transformation",
        "lang": "EN",
        "body": "250 girls subscribed this month.\nthey eat lunch every day.\nand they're still losing weight.",
        "title": "Mirra Diet Bento. From RM19.",
        "description": "she eats everything. on purpose.",
    },
    # CN videos → TEST-CN
    {
        "file": "BOFU-CN-SBB-v5-Direct-Conversion-Shorts-sbb09/BOFU-CN-SBB-v5-Direct-Conversion.mp4",
        "name": "MIX-CN-VID-SBB-DirectConversion-v5",
        "lang": "CN",
        "body": "\u5979\u6362\u4e86Mirra\u4fbf\u5f53\u3002\n3\u5468\u5c31\u7626\u4e86\u4e00\u4e2a\u5c3a\u7801\u3002\n\u6bcf\u5929\u8fd8\u662f\u7167\u5e38\u5403\u5348\u9910\u3002",
        "title": "\u4f4e\u4e8e500\u5361\u3002\u4eceRM19/\u9910\u8d77\u3002",
        "description": "50+\u83dc\u5f0f\u6bcf\u5929\u8f6e\u6362\u3002\u514d\u8d39\u9001\u5230\u5bb6\u3002",
    },
    {
        "file": "FOMO-CN-SBB-Scarcity-Hook-Shorts-sbb03/FOMO-CN-SBB-Scarcity-Hook.mp4",
        "name": "MIX-CN-VID-SBB-ScarcityHook",
        "lang": "CN",
        "body": "\u5927\u5bb6\u90fd\u95ee\u5979\u5348\u9910\u54ea\u91cc\u4e70\u7684\u3002\n\u6bcf\u6b21\u90fd\u540c\u4e00\u4e2a\u7b54\u6848\u3002\n\"\u4f4e\u4e8e500\u5361\uff0c\u800c\u4e14\u6211\u4e0d\u7528\u716e\"",
        "title": "Mirra\u4fbf\u5f53\u3002\u4eceRM19/\u9910\u3002",
        "description": "\u4f4e\u5361\u4fbf\u5f53\uff0c\u771f\u7684\u597d\u5403\u3002",
    },
    {
        "file": "SHOWCASE-CN-SBB-Product-Showcase-Shorts-sbb05/SHOWCASE-CN-SBB-Product-Showcase.mp4",
        "name": "MIX-CN-VID-SBB-ProductShowcase",
        "lang": "CN",
        "body": "50\u9053\u83dc\u3002\u6ca1\u6709\u4e00\u9053\u662f\u65e0\u804a\u7684\u3002\n\u6bcf\u4efd\u4f4e\u4e8e500\u5361\u3002\n\u5403\u5230\u665a\u4e0a\u8fd8\u662f\u9971\u7684\u3002",
        "title": "Mirra\u4f4e\u5361\u4fbf\u5f53\u3002\u4eceRM19\u3002",
        "description": "\u7626\u4e86\u4e00\u4e2a\u5c3a\u7801\u3002\u5348\u9910\u4e00\u987f\u6ca1\u843d\u3002",
    },
    {
        "file": "BOFU-cn-SBB-Price-Demand-5000-Monthly-Shorts-cbfffe0f/BOFU-cn-SBB-Price-Demand-5000-Monthly-Shorts-cbfffe0f-portrait.mp4",
        "name": "MIX-CN-VID-SBB-PriceDemand",
        "lang": "CN",
        "body": "\u6bcf\u6708\u5356\u51fa5000\u4efd\u4fbf\u5f53\u3002\n\u4e0d\u662f\u56e0\u4e3a\u4fbf\u5b9c\u3002\n\u662f\u56e0\u4e3a\u771f\u7684\u6709\u6548\u3002",
        "title": "\u4eceRM19/\u9910\u3002\u4f4e\u4e8e500\u5361\u3002",
        "description": "50+\u83dc\u5f0f\u3002KL\u514d\u8d39\u9001\u8d27\u3002",
    },
    {
        "file": "BOFU-cn-SBB-Kitchen-Quality-Sold-Out-Shorts-36e9de07/BOFU-cn-SBB-Kitchen-Quality-Sold-Out-Shorts-36e9de07-portrait.mp4",
        "name": "MIX-CN-VID-SBB-KitchenQuality",
        "lang": "CN",
        "body": "\u4ece\u53a8\u623f\u5230\u4f60\u7684\u684c\u4e0a\u3002\n\u6bcf\u4efd\u90fd\u662f\u65b0\u9c9c\u73b0\u505a\u3002\n\u4f4e\u5361\u4e0d\u4ee3\u8868\u6ca1\u6709\u5473\u9053\u3002",
        "title": "Mirra\u4fbf\u5f53\u3002\u4eceRM19\u8d77\u3002",
        "description": "\u65b0\u9c9c\u73b0\u505a\u3002\u4f4e\u5361\u7f8e\u5473\u3002",
    },
]


def load_token() -> str:
    token = os.environ.get("META_TOKEN", "")
    if token:
        return token
    p = Path.home() / "Desktop/_WORK/_shared/.meta-token"
    if p.exists():
        return p.read_text().strip()
    print("ERROR: No Meta token found")
    sys.exit(1)


def api_call(url: str, data: dict = None) -> dict:
    """Make a Meta API call."""
    if data:
        encoded = urllib.parse.urlencode(data).encode()
        req = urllib.request.Request(url, data=encoded, method="POST")
    else:
        req = urllib.request.Request(url)

    try:
        resp = urllib.request.urlopen(req, timeout=300)
        return json.loads(resp.read())
    except Exception as e:
        err_body = ""
        if hasattr(e, "read"):
            err_body = e.read().decode()
        print(f"  API ERROR: {e}")
        if err_body:
            try:
                err = json.loads(err_body)
                print(f"  Detail: {err.get('error', {}).get('message', err_body[:300])}")
            except json.JSONDecodeError:
                print(f"  Response: {err_body[:300]}")
        return {}


def upload_video(token: str, video_path: Path, title: str) -> str:
    """Upload video to ad account, return video ID."""
    print(f"  Uploading video: {video_path.name} ({video_path.stat().st_size / 1024 / 1024:.0f}MB)...")

    # For videos, we need multipart upload
    import mimetypes
    boundary = "----FormBoundary7MA4YWxkTrZu0gW"

    video_data = video_path.read_bytes()
    content_type = mimetypes.guess_type(str(video_path))[0] or "video/mp4"

    body_parts = []

    # access_token field
    body_parts.append(f"--{boundary}\r\n")
    body_parts.append(f'Content-Disposition: form-data; name="access_token"\r\n\r\n')
    body_parts.append(f"{token}\r\n")

    # title field
    body_parts.append(f"--{boundary}\r\n")
    body_parts.append(f'Content-Disposition: form-data; name="title"\r\n\r\n')
    body_parts.append(f"{title}\r\n")

    # Convert text parts to bytes
    text_bytes = "".join(body_parts).encode("utf-8")

    # Video file part
    file_header = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="source"; filename="{video_path.name}"\r\n'
        f"Content-Type: {content_type}\r\n\r\n"
    ).encode("utf-8")

    file_footer = f"\r\n--{boundary}--\r\n".encode("utf-8")

    full_body = text_bytes + file_header + video_data + file_footer

    url = f"{GRAPH_BASE}/{AD_ACCOUNT}/advideos"
    req = urllib.request.Request(url, data=full_body, method="POST")
    req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")

    try:
        resp = urllib.request.urlopen(req, timeout=600)
        result = json.loads(resp.read())
        video_id = result.get("id", "")
        if video_id:
            print(f"  Video uploaded: {video_id}")
        return video_id
    except Exception as e:
        err_body = ""
        if hasattr(e, "read"):
            err_body = e.read().decode()
        print(f"  Upload FAILED: {e}")
        if err_body:
            print(f"  Detail: {err_body[:300]}")
        return ""


def wait_for_video(token: str, video_id: str, max_wait: int = 120) -> bool:
    """Wait for video to finish processing."""
    for i in range(max_wait // 5):
        url = f"{GRAPH_BASE}/{video_id}?fields=status&access_token={token}"
        result = api_call(url)
        status = result.get("status", {})
        processing = status.get("video_status", "processing")
        if processing == "ready":
            print(f"  Video {video_id} ready")
            return True
        if processing == "error":
            print(f"  Video {video_id} processing FAILED")
            return False
        time.sleep(5)
    print(f"  Video {video_id} timed out waiting")
    return False


def create_ad_creative(token: str, video_id: str, video_info: dict) -> str:
    """Create ad creative with video + WhatsApp CTA."""
    is_cn = video_info["lang"] == "CN"
    wa_template = CN_WA_TEMPLATE if is_cn else EN_WA_TEMPLATE

    object_story_spec = {
        "page_id": PAGE_ID,
        "video_data": {
            "video_id": video_id,
            "message": video_info["body"],
            "title": video_info["title"],
            "link_description": video_info["description"],
            "call_to_action": {
                "type": "WHATSAPP_MESSAGE",
                "value": {
                    "link": "https://api.whatsapp.com/send?phone=60193837832",
                    **wa_template,
                },
            },
        },
    }

    data = {
        "name": video_info["name"],
        "object_story_spec": json.dumps(object_story_spec),
        "access_token": token,
    }

    url = f"{GRAPH_BASE}/{AD_ACCOUNT}/adcreatives"
    result = api_call(url, data)
    creative_id = result.get("id", "")
    if creative_id:
        print(f"  Creative created: {creative_id}")
    return creative_id


def create_ad(token: str, adset_id: str, creative_id: str, ad_name: str) -> str:
    """Create ad in PAUSED state."""
    data = {
        "name": ad_name,
        "adset_id": adset_id,
        "creative": json.dumps({"creative_id": creative_id}),
        "status": "PAUSED",
        "access_token": token,
    }

    url = f"{GRAPH_BASE}/{AD_ACCOUNT}/ads"
    result = api_call(url, data)
    ad_id = result.get("id", "")
    if ad_id:
        print(f"  Ad created (PAUSED): {ad_id}")
    return ad_id


def main():
    token = load_token()
    print("=" * 60)
    print("SBB VIDEO UPLOAD — SALES-EN + TEST-CN")
    print("=" * 60)
    print(f"Token: ...{token[-10:]}")
    print(f"EN target: SALES-EN / EN-TOP-PERFORMERS ({SALES_EN_ADSET})")
    print(f"CN target: TEST-CN / CN-MIX ({TEST_CN_ADSET})")
    print()

    results = {"success": [], "failed": []}

    for i, video in enumerate(VIDEOS, 1):
        print(f"\n--- [{i}/{len(VIDEOS)}] {video['name']} ({video['lang']}) ---")

        # Check file exists
        video_path = BATCH_DIR / video["file"]
        if not video_path.exists():
            print(f"  FILE NOT FOUND: {video_path}")
            results["failed"].append(video["name"])
            continue

        # 1. Upload video
        video_id = upload_video(token, video_path, video["name"])
        if not video_id:
            results["failed"].append(video["name"])
            continue

        # 2. Wait for processing
        if not wait_for_video(token, video_id):
            results["failed"].append(video["name"])
            continue

        # 3. Create creative
        creative_id = create_ad_creative(token, video_id, video)
        if not creative_id:
            results["failed"].append(video["name"])
            continue

        # 4. Create ad (PAUSED)
        adset_id = SALES_EN_ADSET if video["lang"] == "EN" else TEST_CN_ADSET
        ad_id = create_ad(token, adset_id, creative_id, video["name"])
        if ad_id:
            results["success"].append({"name": video["name"], "ad_id": ad_id, "lang": video["lang"]})
        else:
            results["failed"].append(video["name"])

        # Rate limit
        time.sleep(2)

    # Summary
    print("\n" + "=" * 60)
    print("UPLOAD SUMMARY")
    print("=" * 60)
    print(f"Success: {len(results['success'])}/{len(VIDEOS)}")
    print(f"Failed: {len(results['failed'])}/{len(VIDEOS)}")

    if results["success"]:
        print("\nCreated ads (all PAUSED — review before activating):")
        for ad in results["success"]:
            print(f"  [{ad['lang']}] {ad['name']} → {ad['ad_id']}")

    if results["failed"]:
        print("\nFailed:")
        for name in results["failed"]:
            print(f"  {name}")

    print(f"\nNext: Review in Ads Manager, then activate the ones you approve.")


if __name__ == "__main__":
    main()
