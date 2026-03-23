#!/usr/bin/env python3
"""
Instagram Graph API Publisher for GAIA brands.

Supports: single image, carousel (up to 10), reel (video).
Uses Meta Graph API v21.0.

Usage:
  python3 ig-publish.py image --image-url URL --caption "text"
  python3 ig-publish.py image --image-path /local/path.jpg --caption "text"
  python3 ig-publish.py carousel --image-urls "url1,url2,url3" --caption "text"
  python3 ig-publish.py reel --video-url URL --caption "text"
  python3 ig-publish.py validate  # check token + permissions

Env vars (from ~/.openclaw/secrets/meta-marketing.env):
  META_ACCESS_TOKEN, IG_USER_ID, META_APP_ID
"""

import argparse
import json
import os
import sys
import time
import urllib.request
import urllib.parse
import urllib.error
import subprocess
from pathlib import Path

API_VERSION = "v21.0"
GRAPH_URL = f"https://graph.facebook.com/{API_VERSION}"

# Load secrets
SECRETS_FILE = Path.home() / ".openclaw" / "secrets" / "meta-marketing.env"
if SECRETS_FILE.exists():
    for line in SECRETS_FILE.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip())


def get_env(key):
    val = os.environ.get(key, "")
    if not val:
        print(f"ERROR: {key} not set. Run meta-token-manager.sh first.", file=sys.stderr)
        sys.exit(1)
    return val


def graph_api(method, endpoint, params=None, data=None):
    """Make a Graph API request."""
    token = get_env("META_ACCESS_TOKEN")
    url = f"{GRAPH_URL}{endpoint}"

    if params is None:
        params = {}
    params["access_token"] = token

    if method == "GET":
        qs = urllib.parse.urlencode(params)
        url = f"{url}?{qs}"
        req = urllib.request.Request(url)
    elif method == "POST":
        encoded = urllib.parse.urlencode(params).encode("utf-8")
        req = urllib.request.Request(url, data=encoded, method="POST")
    else:
        raise ValueError(f"Unsupported method: {method}")

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        print(f"API Error {e.code}: {body}", file=sys.stderr)
        try:
            return json.loads(body)
        except:
            return {"error": {"message": body, "code": e.code}}


def upload_image_to_hosting(image_path):
    """Upload local image to a public URL via imgbb or similar.
    For now, uses a simple file server approach.
    Returns publicly accessible URL."""
    # Try to use ngrok URL if available
    ngrok_url = os.environ.get("NGROK_URL", "")
    if ngrok_url:
        # Copy to a served directory
        serve_dir = Path.home() / ".openclaw" / "workspace" / "data" / "serve"
        serve_dir.mkdir(parents=True, exist_ok=True)
        import shutil
        dest = serve_dir / Path(image_path).name
        shutil.copy2(image_path, dest)
        return f"{ngrok_url}/serve/{dest.name}"

    # Fallback: upload to freeimage.host (free, permanent)
    try:
        result = subprocess.run(
            ["curl", "-s", "-X", "POST",
             "-F", f"source=@{image_path}",
             "-F", "type=file",
             "-F", "action=upload",
             "https://freeimage.host/api/1/upload?key=6d207e02198a847aa98d0a2a901485a5"],
            capture_output=True, text=True, timeout=120
        )
        data = json.loads(result.stdout)
        url = data.get("image", {}).get("url", "")
        if url.startswith("http"):
            print(f"[ig-publish] Uploaded to freeimage.host: {url}")
            return url
    except Exception as e:
        print(f"[ig-publish] freeimage.host upload failed: {e}", file=sys.stderr)

    print(f"ERROR: Cannot upload {image_path} to a public URL.", file=sys.stderr)
    print("Set NGROK_URL or provide --image-url instead of --image-path", file=sys.stderr)
    sys.exit(1)


def wait_for_container(container_id, max_wait=120):
    """Poll container status until FINISHED or timeout."""
    ig_user_id = get_env("IG_USER_ID")
    start = time.time()
    while time.time() - start < max_wait:
        result = graph_api("GET", f"/{container_id}", {"fields": "status_code,status"})
        status = result.get("status_code", "")
        if status == "FINISHED":
            return True
        if status == "ERROR":
            print(f"Container error: {result}", file=sys.stderr)
            return False
        if status in ("EXPIRED", ""):
            # Sometimes status_code is missing, check after brief wait
            pass
        time.sleep(3)
    print(f"Container timed out after {max_wait}s", file=sys.stderr)
    return False


def publish_image(image_url=None, image_path=None, caption=""):
    """Publish a single image to Instagram."""
    ig_user_id = get_env("IG_USER_ID")

    if image_path and not image_url:
        image_url = upload_image_to_hosting(image_path)
        print(f"[ig-publish] Uploaded to: {image_url}")

    if not image_url:
        print("ERROR: Need --image-url or --image-path", file=sys.stderr)
        sys.exit(1)

    # Step 1: Create media container
    print(f"[ig-publish] Creating image container...")
    params = {"image_url": image_url, "caption": caption}
    result = graph_api("POST", f"/{ig_user_id}/media", params)

    if "error" in result:
        print(f"[ig-publish] Container creation failed: {result['error']}", file=sys.stderr)
        return None

    container_id = result.get("id")
    if not container_id:
        print(f"[ig-publish] No container ID returned: {result}", file=sys.stderr)
        return None

    print(f"[ig-publish] Container created: {container_id}")

    # Step 2: Wait for processing
    if not wait_for_container(container_id):
        return None

    # Step 3: Publish
    print(f"[ig-publish] Publishing...")
    pub_result = graph_api("POST", f"/{ig_user_id}/media_publish", {"creation_id": container_id})

    if "error" in pub_result:
        print(f"[ig-publish] Publish failed: {pub_result['error']}", file=sys.stderr)
        return None

    post_id = pub_result.get("id")
    print(f"[ig-publish] Published! Post ID: {post_id}")
    return post_id


def publish_carousel(image_urls, caption=""):
    """Publish a carousel (2-10 images) to Instagram."""
    ig_user_id = get_env("IG_USER_ID")

    if len(image_urls) < 2:
        print("ERROR: Carousel needs at least 2 images", file=sys.stderr)
        sys.exit(1)
    if len(image_urls) > 10:
        print("WARNING: Truncating to 10 images (IG max)", file=sys.stderr)
        image_urls = image_urls[:10]

    # Step 1: Create child containers
    children = []
    for i, url in enumerate(image_urls):
        print(f"[ig-publish] Creating child container {i+1}/{len(image_urls)}...")
        result = graph_api("POST", f"/{ig_user_id}/media", {
            "image_url": url,
            "is_carousel_item": "true"
        })
        if "id" in result:
            children.append(result["id"])
            # Wait for each child
            wait_for_container(result["id"])
        else:
            print(f"[ig-publish] Child {i+1} failed: {result}", file=sys.stderr)

    if len(children) < 2:
        print("ERROR: Need at least 2 successful child containers", file=sys.stderr)
        return None

    # Step 2: Create carousel container
    print(f"[ig-publish] Creating carousel container with {len(children)} items...")
    result = graph_api("POST", f"/{ig_user_id}/media", {
        "caption": caption,
        "media_type": "CAROUSEL",
        "children": ",".join(children)
    })

    container_id = result.get("id")
    if not container_id:
        print(f"[ig-publish] Carousel container failed: {result}", file=sys.stderr)
        return None

    if not wait_for_container(container_id):
        return None

    # Step 3: Publish
    print(f"[ig-publish] Publishing carousel...")
    pub_result = graph_api("POST", f"/{ig_user_id}/media_publish", {"creation_id": container_id})
    post_id = pub_result.get("id")
    print(f"[ig-publish] Published carousel! Post ID: {post_id}")
    return post_id


def publish_reel(video_url, caption="", cover_url=None):
    """Publish a reel (video) to Instagram."""
    ig_user_id = get_env("IG_USER_ID")

    print(f"[ig-publish] Creating reel container...")
    params = {
        "media_type": "REELS",
        "video_url": video_url,
        "caption": caption,
    }
    if cover_url:
        params["cover_url"] = cover_url

    result = graph_api("POST", f"/{ig_user_id}/media", params)
    container_id = result.get("id")
    if not container_id:
        print(f"[ig-publish] Reel container failed: {result}", file=sys.stderr)
        return None

    # Reels take longer to process
    if not wait_for_container(container_id, max_wait=300):
        return None

    print(f"[ig-publish] Publishing reel...")
    pub_result = graph_api("POST", f"/{ig_user_id}/media_publish", {"creation_id": container_id})
    post_id = pub_result.get("id")
    print(f"[ig-publish] Published reel! Post ID: {post_id}")
    return post_id


def validate_token():
    """Validate current token and check permissions."""
    token = get_env("META_ACCESS_TOKEN")

    print("[ig-publish] Validating token...")

    # Debug token
    result = graph_api("GET", "/debug_token", {"input_token": token})
    data = result.get("data", {})

    if "error" in result and "error" not in data:
        print(f"[ig-publish] Token validation failed: {result['error']}")
        return False

    is_valid = data.get("is_valid", False)
    expires = data.get("expires_at", 0)
    scopes = data.get("scopes", [])

    print(f"[ig-publish] Valid: {is_valid}")
    if expires:
        remaining = expires - int(time.time())
        days = remaining // 86400
        print(f"[ig-publish] Expires in: {days} days")
    print(f"[ig-publish] Scopes: {', '.join(scopes)}")

    # Check required permissions
    required = ["instagram_basic", "instagram_content_publish", "pages_show_list"]
    missing = [p for p in required if p not in scopes]
    if missing:
        print(f"[ig-publish] MISSING permissions: {', '.join(missing)}")
        return False

    # Get IG account info
    ig_user_id = os.environ.get("IG_USER_ID", "")
    if ig_user_id:
        info = graph_api("GET", f"/{ig_user_id}", {"fields": "username,followers_count,media_count"})
        if "username" in info:
            print(f"[ig-publish] Account: @{info['username']}")
            print(f"[ig-publish] Followers: {info.get('followers_count', '?')}")
            print(f"[ig-publish] Posts: {info.get('media_count', '?')}")

    print("[ig-publish] Token is valid and ready!")
    return True


def discover_ig_account():
    """Discover IG User ID from connected Facebook Pages."""
    print("[ig-publish] Discovering Instagram accounts...")

    # Get Pages
    result = graph_api("GET", "/me/accounts", {"fields": "id,name,instagram_business_account"})
    pages = result.get("data", [])

    if not pages:
        print("[ig-publish] No Facebook Pages found. Connect a Page to your IG account first.")
        return None

    for page in pages:
        name = page.get("name", "Unknown")
        page_id = page.get("id")
        ig_account = page.get("instagram_business_account", {})
        ig_id = ig_account.get("id", "")

        print(f"  Page: {name} (ID: {page_id})")
        if ig_id:
            print(f"  -> Instagram Business Account ID: {ig_id}")

            # Get IG username
            ig_info = graph_api("GET", f"/{ig_id}", {"fields": "username"})
            username = ig_info.get("username", "unknown")
            print(f"  -> Instagram: @{username}")

            return {"ig_user_id": ig_id, "page_id": page_id, "username": username}
        else:
            print(f"  -> No Instagram account linked")

    print("[ig-publish] No Instagram Business accounts found.")
    return None


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Instagram Graph API Publisher")
    sub = parser.add_subparsers(dest="command")

    # Image
    img_p = sub.add_parser("image", help="Post a single image")
    img_p.add_argument("--image-url", help="Public URL of image")
    img_p.add_argument("--image-path", help="Local path to image file")
    img_p.add_argument("--caption", default="", help="Post caption")

    # Carousel
    car_p = sub.add_parser("carousel", help="Post a carousel")
    car_p.add_argument("--image-urls", required=True, help="Comma-separated image URLs")
    car_p.add_argument("--caption", default="", help="Post caption")

    # Reel
    reel_p = sub.add_parser("reel", help="Post a reel/video")
    reel_p.add_argument("--video-url", required=True, help="Public URL of video")
    reel_p.add_argument("--caption", default="", help="Post caption")
    reel_p.add_argument("--cover-url", help="Cover image URL")

    # Validate
    sub.add_parser("validate", help="Validate token and permissions")

    # Discover
    sub.add_parser("discover", help="Find IG User ID from Facebook Pages")

    args = parser.parse_args()

    if args.command == "image":
        publish_image(image_url=args.image_url, image_path=args.image_path, caption=args.caption)
    elif args.command == "carousel":
        urls = [u.strip() for u in args.image_urls.split(",") if u.strip()]
        publish_carousel(urls, caption=args.caption)
    elif args.command == "reel":
        publish_reel(args.video_url, caption=args.caption, cover_url=args.cover_url)
    elif args.command == "validate":
        ok = validate_token()
        sys.exit(0 if ok else 1)
    elif args.command == "discover":
        result = discover_ig_account()
        if result:
            print(f"\nAdd to ~/.openclaw/secrets/meta-marketing.env:")
            print(f"IG_USER_ID={result['ig_user_id']}")
            print(f"IG_PAGE_ID={result['page_id']}")
    else:
        parser.print_help()
