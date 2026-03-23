"""Photo enhancement pipeline — Joel's 3-step workflow automated.

Step 1: FoodShot AI → professional base (angle, plate, styling)
Step 2: LLM image edit → white background + warm colors (暖色)
Step 3: PIL → exposure boost + resize to GrabFood specs

Can also run Step 2+3 only if merchant already has decent base photos.
"""

import logging
import httpx
from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter

from src.config import (
    PHOTOS_DIR, MENU_PHOTO_SIZE, BANNER_PHOTO_SIZE,
    PHOTO_FORMAT, PHOTO_QUALITY, MAX_PHOTO_SIZE_MB,
    EXPOSURE_BOOST, WARMTH_SHIFT,
    FOODSHOT_API_KEY, GEMINI_API_KEY,
)

log = logging.getLogger("grab.photo")


class PhotoPipeline:
    """3-step food photo enhancement pipeline."""

    def __init__(self, merchant_id: str):
        self.merchant_id = merchant_id
        self.output_dir = PHOTOS_DIR / merchant_id
        self.output_dir.mkdir(parents=True, exist_ok=True)

    # ── Step 1: FoodShot AI ────────────────────────────────────────

    async def foodshot_enhance(self, input_path: str, style: str = "delivery") -> Path:
        """Send photo to FoodShot AI for professional enhancement.

        Args:
            input_path: Path to original food photo
            style: FoodShot style preset (delivery, menu, fine-dining)

        Returns:
            Path to enhanced photo
        """
        if not FOODSHOT_API_KEY:
            log.warning("FoodShot API key not set — skipping Step 1")
            return Path(input_path)

        output_path = self.output_dir / f"{Path(input_path).stem}_foodshot.jpg"

        # FoodShot API call (Enterprise plan)
        # Note: Exact API endpoints TBD — FoodShot may require web automation too
        try:
            async with httpx.AsyncClient(timeout=60) as client:
                with open(input_path, "rb") as f:
                    resp = await client.post(
                        "https://api.foodshot.ai/v1/generate",
                        headers={"Authorization": f"Bearer {FOODSHOT_API_KEY}"},
                        files={"image": f},
                        data={"style": style},
                    )
                if resp.status_code == 200:
                    result = resp.json()
                    image_url = result.get("image_url", "")
                    if image_url:
                        img_resp = await client.get(image_url)
                        output_path.write_bytes(img_resp.content)
                        log.info(f"FoodShot enhanced: {output_path}")
                        return output_path
                else:
                    log.error(f"FoodShot API error: {resp.status_code} {resp.text}")
        except Exception as e:
            log.error(f"FoodShot failed: {e}")

        return Path(input_path)

    # ── Step 2: White BG + Warm Colors ─────────────────────────────

    async def warm_and_clean(self, input_path: str, use_gemini: bool = True) -> Path:
        """Apply white background + warm color grading.

        Two modes:
        - Gemini API (AI-powered, better results)
        - PIL fallback (no API needed, decent results)
        """
        output_path = self.output_dir / f"{Path(input_path).stem}_warm.jpg"

        if use_gemini and GEMINI_API_KEY:
            result = await self._gemini_edit(input_path, output_path)
            if result:
                return result

        # PIL fallback
        return self._pil_warm_colors(input_path, output_path)

    async def _gemini_edit(self, input_path: str, output_path: Path) -> Path | None:
        """Use Gemini image editing for white bg + warm tones."""
        try:
            import base64
            async with httpx.AsyncClient(timeout=60) as client:
                with open(input_path, "rb") as f:
                    img_b64 = base64.b64encode(f.read()).decode()

                resp = await client.post(
                    f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={GEMINI_API_KEY}",
                    json={
                        "contents": [{
                            "parts": [
                                {"text": (
                                    "Edit this food photo: "
                                    "1) Change the background to clean white. "
                                    "2) Make the food colors warmer (暖色) to increase appetite appeal (提高食欲感). "
                                    "3) Keep the food realistic and appetizing. "
                                    "4) Enhance the lighting to look like professional food photography. "
                                    "Return only the edited image."
                                )},
                                {"inline_data": {"mime_type": "image/jpeg", "data": img_b64}},
                            ]
                        }],
                        "generationConfig": {"response_mime_type": "image/jpeg"},
                    },
                )

                if resp.status_code == 200:
                    result = resp.json()
                    for part in result.get("candidates", [{}])[0].get("content", {}).get("parts", []):
                        if "inline_data" in part:
                            img_data = base64.b64decode(part["inline_data"]["data"])
                            output_path.write_bytes(img_data)
                            log.info(f"Gemini warm edit: {output_path}")
                            return output_path
                else:
                    log.error(f"Gemini API error: {resp.status_code}")
        except Exception as e:
            log.error(f"Gemini edit failed: {e}")

        return None

    def _pil_warm_colors(self, input_path: str, output_path: Path) -> Path:
        """PIL fallback: boost warmth + saturation (no AI needed)."""
        img = Image.open(input_path).convert("RGB")

        # Boost color saturation
        img = ImageEnhance.Color(img).enhance(1.2)

        # Add warmth by boosting red/yellow channels
        r, g, b = img.split()
        r = r.point(lambda x: min(255, x + WARMTH_SHIFT))
        g = g.point(lambda x: min(255, x + int(WARMTH_SHIFT * 0.4)))
        img = Image.merge("RGB", (r, g, b))

        # Slight contrast boost
        img = ImageEnhance.Contrast(img).enhance(1.1)

        img.save(str(output_path), PHOTO_FORMAT, quality=PHOTO_QUALITY)
        log.info(f"PIL warm colors: {output_path}")
        return output_path

    # ── Step 3: Exposure Boost + Resize ────────────────────────────

    def finalize(self, input_path: str, size: tuple = MENU_PHOTO_SIZE, item_name: str = "") -> Path:
        """Final step: exposure boost + resize to GrabFood specs.

        This is Joel's "increase exposure to 10" step.
        """
        safe_name = "".join(c if c.isalnum() or c in "-_ " else "" for c in item_name).strip()
        safe_name = safe_name.replace(" ", "_")[:50] or Path(input_path).stem
        output_path = self.output_dir / f"{safe_name}_final.jpg"

        img = Image.open(input_path).convert("RGB")

        # Exposure boost (Joel's step: exposure +10 on phone)
        img = ImageEnhance.Brightness(img).enhance(EXPOSURE_BOOST)

        # Slight sharpness boost for food detail
        img = ImageEnhance.Sharpness(img).enhance(1.15)

        # Resize to GrabFood specs
        img = self._smart_crop_resize(img, size)

        # Save with quality check
        img.save(str(output_path), PHOTO_FORMAT, quality=PHOTO_QUALITY)

        # Check file size
        file_size_mb = output_path.stat().st_size / (1024 * 1024)
        if file_size_mb > MAX_PHOTO_SIZE_MB:
            # Re-save with lower quality
            img.save(str(output_path), PHOTO_FORMAT, quality=80)
            log.warning(f"Reduced quality to fit {MAX_PHOTO_SIZE_MB}MB limit")

        log.info(f"Finalized: {output_path} ({size[0]}x{size[1]}, {file_size_mb:.1f}MB)")
        return output_path

    def _smart_crop_resize(self, img: Image.Image, target_size: tuple) -> Image.Image:
        """Center-crop and resize to target dimensions without distortion."""
        tw, th = target_size
        target_ratio = tw / th

        iw, ih = img.size
        img_ratio = iw / ih

        if img_ratio > target_ratio:
            # Image is wider — crop sides
            new_w = int(ih * target_ratio)
            left = (iw - new_w) // 2
            img = img.crop((left, 0, left + new_w, ih))
        elif img_ratio < target_ratio:
            # Image is taller — crop top/bottom
            new_h = int(iw / target_ratio)
            top = (ih - new_h) // 2
            img = img.crop((0, top, iw, top + new_h))

        return img.resize(target_size, Image.LANCZOS)

    # ── Full Pipeline ──────────────────────────────────────────────

    async def process(
        self,
        input_path: str,
        item_name: str = "",
        size: tuple = MENU_PHOTO_SIZE,
        skip_foodshot: bool = False,
    ) -> Path:
        """Run full 3-step pipeline on one photo.

        Args:
            input_path: Path to original food photo
            item_name: Menu item name (for output filename)
            size: Target dimensions (default 800x800 for menu items)
            skip_foodshot: Skip FoodShot AI step (use when base photo is already decent)

        Returns:
            Path to final optimized photo ready for GrabFood upload
        """
        log.info(f"Processing: {input_path} → {item_name or 'unnamed'}")

        current = input_path

        # Step 1: FoodShot AI (optional)
        if not skip_foodshot:
            current = str(await self.foodshot_enhance(current))

        # Step 2: White bg + warm colors
        current = str(await self.warm_and_clean(current))

        # Step 3: Exposure boost + resize
        final = self.finalize(current, size=size, item_name=item_name)

        log.info(f"Pipeline complete: {final}")
        return final

    async def process_batch(
        self,
        photos: list[dict],
        skip_foodshot: bool = False,
    ) -> list[Path]:
        """Process multiple photos.

        Args:
            photos: List of {"path": str, "name": str, "size": tuple (optional)}
        """
        results = []
        for i, photo in enumerate(photos):
            log.info(f"Batch: {i+1}/{len(photos)}")
            result = await self.process(
                input_path=photo["path"],
                item_name=photo.get("name", f"item_{i+1}"),
                size=photo.get("size", MENU_PHOTO_SIZE),
                skip_foodshot=skip_foodshot,
            )
            results.append(result)
        return results
