#!/usr/bin/env python3
"""Flux Kontext Pro — Image editing via fal.ai API"""

import sys, os, json, time, base64, argparse
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from pathlib import Path

FAL_API = "https://queue.fal.run/fal-ai/flux-pro/kontext"
FAL_UPLOAD = "https://fal.ai/api/storage/upload"

def load_key():
    key = os.environ.get("FAL_KEY") or os.environ.get("FAL_API_KEY")
    if key:
        return key
    for f in [
        os.path.expanduser("~/.openclaw/.env"),
        os.path.expanduser("~/.openclaw/secrets/fal.env"),
    ]:
        if os.path.exists(f):
            for line in open(f):
                if line.startswith("FAL_API_KEY="):
                    return line.strip().split("=", 1)[1]
    raise RuntimeError("No fal.ai API key found")

def upload_file(file_path, key):
    """Upload file to fal.ai storage and return URL"""
    mime = "image/jpeg" if file_path.lower().endswith((".jpg", ".jpeg")) else "image/png"
    filename = os.path.basename(file_path)

    with open(file_path, "rb") as f:
        data = f.read()

    # Try fal.ai storage upload
    req = Request(
        FAL_UPLOAD,
        data=data,
        headers={
            "Authorization": f"Key {key}",
            "Content-Type": mime,
            "X-Fal-File-Name": filename,
        },
        method="POST",
    )
    try:
        resp = urlopen(req, timeout=60)
        result = json.loads(resp.read())
        url = result.get("url") or result.get("file_url") or result.get("access_url")
        if url:
            return url
    except HTTPError as e:
        body = e.read().decode()
        print(f"  Upload attempt 1 failed ({e.code}): {body[:200]}", file=sys.stderr)

    # Fallback: data URI
    print("  Using base64 data URI fallback...", file=sys.stderr)
    b64 = base64.b64encode(data).decode()
    return f"data:{mime};base64,{b64}"

def submit_edit(image_url, prompt, key, guidance=3.5, safety="4"):
    """Submit Kontext edit via queue API"""
    payload = json.dumps({
        "prompt": prompt,
        "image_url": image_url,
        "guidance_scale": guidance,
        "num_images": 1,
        "output_format": "png",
        "safety_tolerance": safety,
    }).encode()

    req = Request(
        FAL_API,
        data=payload,
        headers={
            "Authorization": f"Key {key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        resp = urlopen(req, timeout=120)
        return json.loads(resp.read())
    except HTTPError as e:
        body = e.read().decode()
        raise RuntimeError(f"Submit failed ({e.code}): {body[:500]}")

def poll_status(request_id, key, max_wait=180):
    """Poll queue for completion"""
    status_url = f"https://queue.fal.run/fal-ai/flux-pro/kontext/requests/{request_id}/status"
    result_url = f"https://queue.fal.run/fal-ai/flux-pro/kontext/requests/{request_id}"

    waited = 0
    while waited < max_wait:
        req = Request(status_url, headers={"Authorization": f"Key {key}"})
        try:
            resp = urlopen(req, timeout=30)
            data = json.loads(resp.read())
            status = data.get("status", "")

            if status == "COMPLETED":
                # Fetch result
                req2 = Request(result_url, headers={"Authorization": f"Key {key}"})
                resp2 = urlopen(req2, timeout=30)
                return json.loads(resp2.read())
            elif status in ("FAILED", "CANCELLED"):
                raise RuntimeError(f"Job {status}: {json.dumps(data)}")
            else:
                logs = data.get("logs", [])
                if logs:
                    print(f"  [{waited}s] {status} — {logs[-1].get('message', '')[:80]}", file=sys.stderr)
                else:
                    print(f"  [{waited}s] {status}...", file=sys.stderr)
        except HTTPError:
            pass

        time.sleep(3)
        waited += 3

    raise RuntimeError(f"Timeout after {max_wait}s")

def download(url, output_path):
    """Download result image"""
    req = Request(url)
    resp = urlopen(req, timeout=60)
    with open(output_path, "wb") as f:
        f.write(resp.read())

def process_one(input_path, prompt, output_dir, key, guidance=3.5, safety="4"):
    """Process a single image"""
    basename = Path(input_path).stem
    output_path = os.path.join(output_dir, f"{basename}-kontext.png")

    print(f"\n[1/3] Uploading {os.path.basename(input_path)}...")
    image_url = upload_file(input_path, key)
    is_data_uri = image_url.startswith("data:")
    print(f"  ✓ {'Data URI' if is_data_uri else image_url[:80]}")

    print(f"[2/3] Submitting Kontext edit...")
    response = submit_edit(image_url, prompt, key, guidance, safety)

    # Check if sync response (has images directly) or async (has request_id)
    if "images" in response:
        result = response
    elif "request_id" in response:
        request_id = response["request_id"]
        print(f"  Queue ID: {request_id}")
        result = poll_status(request_id, key)
    else:
        raise RuntimeError(f"Unexpected response: {json.dumps(response)[:300]}")

    # Extract image URL
    images = result.get("images", [])
    if not images:
        raise RuntimeError(f"No images in result: {json.dumps(result)[:300]}")

    result_url = images[0].get("url", "")
    if not result_url:
        raise RuntimeError("Empty image URL in result")

    print(f"[3/3] Downloading...")
    download(result_url, output_path)
    print(f"  ✓ Saved: {output_path}")
    return output_path

def main():
    parser = argparse.ArgumentParser(description="Flux Kontext image editor")
    parser.add_argument("--input", "-i", required=True, help="Input image or directory")
    parser.add_argument("--prompt", "-p", required=True, help="Edit instruction")
    parser.add_argument("--output", "-o", help="Output directory")
    parser.add_argument("--guidance", "-g", type=float, default=3.5)
    parser.add_argument("--safety", "-s", default="4", help="1=strictest, 6=most permissive")
    args = parser.parse_args()

    key = load_key()
    input_path = args.input
    output_dir = args.output or os.path.dirname(input_path)
    os.makedirs(output_dir, exist_ok=True)

    if os.path.isdir(input_path):
        # Batch mode — process all images in directory
        images = sorted([
            os.path.join(input_path, f)
            for f in os.listdir(input_path)
            if f.lower().endswith((".png", ".jpg", ".jpeg"))
        ])
        print(f"Batch mode: {len(images)} images")
        results = []
        for img in images:
            try:
                out = process_one(img, args.prompt, output_dir, key, args.guidance, args.safety)
                results.append(out)
            except Exception as e:
                print(f"  ✗ FAILED {os.path.basename(img)}: {e}", file=sys.stderr)
        print(f"\n{'='*40}")
        print(f"Done: {len(results)}/{len(images)} succeeded")
        print(f"Output: {output_dir}")
    else:
        process_one(input_path, args.prompt, output_dir, key, args.guidance, args.safety)

if __name__ == "__main__":
    main()
