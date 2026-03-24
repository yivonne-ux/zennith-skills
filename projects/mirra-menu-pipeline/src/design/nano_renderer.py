"""NANO Renderer — Gemini Image API for menu design."""

import base64
import json
import urllib.request
import os
from pathlib import Path
from PIL import Image
import io


GEMINI_KEY = os.environ.get("GOOGLE_API_KEY", "")  # set GOOGLE_API_KEY env var
GEMINI_MODEL = "gemini-3-pro-image-preview"  # Nano Banana Pro — best for image gen
GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"


def _image_to_base64(path: str) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()


def _call_gemini(prompt: str, ref_image_path: str = None, aspect_ratio: str = "3:4") -> bytes:
    """Call Gemini image generation API."""
    parts = []
    
    if ref_image_path:
        img_data = _image_to_base64(ref_image_path)
        ext = Path(ref_image_path).suffix.lower()
        mime = "image/png" if ext == ".png" else "image/jpeg"
        parts.append({
            "inlineData": {
                "mimeType": mime,
                "data": img_data,
            }
        })
    
    parts.append({"text": prompt})
    
    payload = {
        "contents": [{"parts": parts}],
        "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"],
            "imageSizeOptions": {"aspectRatio": aspect_ratio},
        }
    }
    
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        f"{GEMINI_URL}?key={GEMINI_KEY}",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    
    resp = urllib.request.urlopen(req, timeout=120)
    result = json.loads(resp.read())
    
    # Extract image from response
    for candidate in result.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            if "inlineData" in part:
                img_bytes = base64.b64decode(part["inlineData"]["data"])
                return img_bytes
            if "text" in part:
                print(f"  [NANO text]: {part['text'][:200]}")
    
    raise RuntimeError("No image returned from Gemini API")


class MirraMenuNANO:
    """Generate Mirra menu pages using NANO (Gemini Image API)."""

    def generate_edit_first(
        self,
        reference_path: str,
        menu_text_en: str,
        week_label: str,
        output_path: str,
    ) -> str:
        """Version A: Edit the existing March menu to swap in April data."""
        prompt = f"""Edit this image. Keep the EXACT same layout, spacing, composition, background, floral illustrations, and design style.

CHANGES — swap these elements only:
1. Replace ALL dish names and dates with the new menu below
2. Keep the same font style, size, and positioning as the original
3. Keep all chili pepper emoji markers where indicated
4. Keep (New) tags where indicated

NEW MENU TEXT:
{menu_text_en}

PRESERVE — do NOT change:
- The pink/blush watercolor background
- The floral illustrations on the right side
- The "Weekly Menu" header style (italic serif)
- The "{week_label}" header format
- The day labels (MON, TUE, WED, THU, FRI) with large date numbers
- The L - / D - meal format
- The MIRRA logo at bottom right
- The sparkle decorations
- The overall warm, feminine, elegant aesthetic

This should look like someone opened the original Canva file and only swapped the dish names and dates. The STRUCTURE and DESIGN must be pixel-identical to the original."""

        img_bytes = _call_gemini(prompt, ref_image_path=reference_path, aspect_ratio="3:4")
        
        with open(output_path, "wb") as f:
            f.write(img_bytes)
        print(f"  Edit-first: {output_path} ({len(img_bytes) // 1024} KB)")
        return output_path

    def generate_fresh_design(
        self,
        menu_text_en: str,
        week_label: str,
        output_path: str,
    ) -> str:
        """Version B: Fresh design with Mirra brand DNA."""
        prompt = f"""Create a beautiful, world-class weekly meal menu design for MIRRA — a premium plant-based meal subscription service in Kuala Lumpur, Malaysia.

BRAND DNA:
- Feminine, warm, elegant, girlboss energy
- Color palette: blush pink (#F0BFB8), dusty rose (#EBB0B9), soft cream, touches of gold
- Typography: Modern serif for headers (like Playfair Display italic), clean sans-serif for body
- Mood: Like a page from Kinfolk magazine meets a luxury wellness brand
- Logo: "MIRRA" in bold uppercase tracking, bottom right

DESIGN REQUIREMENTS:
- Page size: 9:16 vertical (Instagram story / mobile-first)
- Background: Soft blush pink with subtle paper texture and delicate watercolor floral illustrations
- Flowers: Elegant anemones, poppies, and garden roses in muted coral, cream, purple, and blue
- Sparkle accents: Small 4-point star decorations scattered subtly
- Clean layout with generous whitespace
- Each day shows: day abbreviation + date number on left, L - [lunch dish] and D - [dinner dish] on right
- Spicy dishes marked with a chili pepper emoji 🌶️
- New dishes marked with (New) tag

MENU CONTENT:
{week_label}

{menu_text_en}

DESIGN STYLE REFERENCES:
- Think: Korean café menu meets Scandinavian minimalism meets Malaysian warmth
- Premium but approachable, not cold or clinical
- The kind of menu design that gets saved on Pinterest
- Text must be PERFECTLY legible — crisp, clean, no blur

OUTPUT: A single beautiful menu page image with all text perfectly readable."""

        img_bytes = _call_gemini(prompt, aspect_ratio="3:4")
        
        with open(output_path, "wb") as f:
            f.write(img_bytes)
        print(f"  Fresh design: {output_path} ({len(img_bytes) // 1024} KB)")
        return output_path

    def build_menu_text(self, page_data: dict) -> tuple[str, str]:
        """Build formatted menu text from page data."""
        lines = []
        week_labels = []
        for week in page_data["weeks"]:
            week_labels.append(f"{page_data['month_name']}: Week {week['number']}")
            for day in week["days"]:
                if day.get("is_holiday"):
                    lines.append(f"{day['day_short']} {day['date_num']}  {day['holiday_name']} — No Delivery")
                else:
                    spicy_l = " 🌶️" if day["lunch"]["spicy"] else ""
                    spicy_d = " 🌶️" if day["dinner"]["spicy"] else ""
                    new_l = " (New)" if day["lunch"].get("is_new") else ""
                    new_d = " (New)" if day["dinner"].get("is_new") else ""
                    lines.append(f"{day['day_short']} {day['date_num']}  L - {day['lunch']['name']}{spicy_l}{new_l}")
                    lines.append(f"        D - {day['dinner']['name']}{spicy_d}{new_d}")
            lines.append("")
        
        week_label = " + ".join(week_labels)
        return "\n".join(lines), week_label
