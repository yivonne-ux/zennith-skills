#!/usr/bin/env python3
"""Batch Kontext bust edit for Jade v8 angles"""

import os, sys, json, time
from pathlib import Path

# Compress images first to avoid upload limits
from PIL import Image
import io

def compress_image(path, max_size_mb=3, quality=85):
    """Compress PNG to JPEG, return bytes"""
    img = Image.open(path)
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=quality, optimize=True)
    data = buf.getvalue()
    size_mb = len(data) / (1024 * 1024)
    if size_mb > max_size_mb:
        # Reduce quality further
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=60, optimize=True)
        data = buf.getvalue()
    return data

def main():
    # Load API key
    key = None
    env_path = os.path.expanduser("~/.openclaw/.env")
    if os.path.exists(env_path):
        for line in open(env_path):
            if line.startswith("FAL_API_KEY="):
                key = line.strip().split("=", 1)[1]
    if not key:
        print("ERROR: No FAL_API_KEY in ~/.openclaw/.env")
        sys.exit(1)

    os.environ["FAL_KEY"] = key

    import fal_client

    input_dir = sys.argv[1] if len(sys.argv) > 1 else "/Users/jennwoeiloh/Desktop/jade-face-body-lock/v8-exact-lock08"
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "/Users/jennwoeiloh/Desktop/jade-face-body-lock/v9-kontext-bust"
    os.makedirs(output_dir, exist_ok=True)

    prompt = (
        "Make her bust noticeably fuller and larger, approximately 2 cup sizes bigger "
        "with natural round shape visible through the white tank top. "
        "Keep everything else EXACTLY the same — same face, same hair, same pose, "
        "same grey shorts, same background, same lighting, same skin tone. "
        "Only change: her bust is fuller and more prominent."
    )

    # Get all images
    images = sorted([
        f for f in os.listdir(input_dir)
        if f.lower().endswith((".png", ".jpg", ".jpeg"))
    ])
    print(f"Found {len(images)} images in {input_dir}")
    print(f"Output: {output_dir}")
    print(f"Prompt: {prompt[:100]}...")
    print()

    results = []
    for i, fname in enumerate(images):
        input_path = os.path.join(input_dir, fname)
        output_path = os.path.join(output_dir, fname.replace(".png", "-bust.png").replace(".jpg", "-bust.jpg"))

        print(f"[{i+1}/{len(images)}] {fname}")

        try:
            # Compress to JPEG bytes
            print(f"  Compressing...")
            img_data = compress_image(input_path)
            size_mb = len(img_data) / (1024 * 1024)
            print(f"  Compressed to {size_mb:.1f}MB JPEG")

            # Save temp JPEG for upload
            temp_path = os.path.join(output_dir, f"_temp_{fname}.jpg")
            with open(temp_path, "wb") as f:
                f.write(img_data)

            # Upload via fal_client
            print(f"  Uploading...")
            image_url = fal_client.upload_file(temp_path)
            print(f"  ✓ Uploaded: {image_url[:80]}...")
            os.unlink(temp_path)

            # Submit edit
            print(f"  Submitting Kontext edit...")

            def on_queue_update(update):
                if hasattr(update, 'logs') and update.logs:
                    for log in update.logs:
                        msg = log.get("message", "") if isinstance(log, dict) else str(log)
                        if msg:
                            print(f"    {msg[:80]}")

            result = fal_client.subscribe(
                "fal-ai/flux-pro/kontext",
                arguments={
                    "prompt": prompt,
                    "image_url": image_url,
                    "guidance_scale": 4.0,
                    "num_images": 1,
                    "output_format": "png",
                    "safety_tolerance": "5",
                },
                with_logs=True,
                on_queue_update=on_queue_update,
            )

            # Download result
            if "images" in result and result["images"]:
                result_url = result["images"][0]["url"]
                print(f"  Downloading...")
                import urllib.request
                urllib.request.urlretrieve(result_url, output_path)
                print(f"  ✓ Saved: {output_path}")
                results.append(output_path)
            else:
                print(f"  ✗ No image in result: {json.dumps(result)[:200]}")

        except Exception as e:
            print(f"  ✗ FAILED: {e}")

        print()

    print(f"{'='*50}")
    print(f"Done: {len(results)}/{len(images)} succeeded")
    print(f"Output: {output_dir}")

if __name__ == "__main__":
    main()
