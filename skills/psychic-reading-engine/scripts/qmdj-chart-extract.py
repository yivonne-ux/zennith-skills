#!/usr/bin/env python3
"""
QMDJ Chart Image Extractor
Extracts Ba Men (8 Doors), Jiu Xing (9 Stars), Ba Shen (8 Deities),
and Tian Gan (Heavenly Stems) from a Qi Men Dun Jia chart image.

Two modes:
  --mode vision  : Use Gemini Vision API (GOOGLE_API_KEY required)
  --mode manual  : Output the embedded parsed data (for known charts)

Usage:
  python3 qmdj-chart-extract.py --image <path> [--output <json>]
  python3 qmdj-chart-extract.py --image <path> --mode vision [--output <json>]
"""

import json
import sys
import os
import argparse
from datetime import datetime

# ---------------------------------------------------------------------------
# Domain knowledge for validation & enrichment
# ---------------------------------------------------------------------------

BA_MEN = {
    "休": {"name_en": "Rest Door",    "element": "Water", "palace": 1, "quality": "auspicious"},
    "生": {"name_en": "Life Door",    "element": "Earth", "palace": 8, "quality": "very_auspicious"},
    "伤": {"name_en": "Injury Door",  "element": "Wood",  "palace": 3, "quality": "neutral"},
    "杜": {"name_en": "Obstruct Door","element": "Wood",  "palace": 4, "quality": "neutral"},
    "景": {"name_en": "View Door",    "element": "Fire",  "palace": 9, "quality": "neutral"},
    "死": {"name_en": "Death Door",   "element": "Earth", "palace": 2, "quality": "inauspicious"},
    "惊": {"name_en": "Shock Door",   "element": "Metal", "palace": 7, "quality": "inauspicious"},
    "开": {"name_en": "Open Door",    "element": "Metal", "palace": 6, "quality": "auspicious"},
}

JIU_XING = {
    "蓬": {"full": "天蓬", "name_en": "Tian Peng", "element": "Water", "quality": "inauspicious"},
    "任": {"full": "天任", "name_en": "Tian Ren",  "element": "Earth", "quality": "auspicious"},
    "冲": {"full": "天冲", "name_en": "Tian Chong","element": "Wood",  "quality": "neutral"},
    "辅": {"full": "天Fu", "name_en": "Tian Fu",   "element": "Wood",  "quality": "auspicious"},
    "禽": {"full": "天禽", "name_en": "Tian Qin",  "element": "Earth", "quality": "neutral"},
    "心": {"full": "天心", "name_en": "Tian Xin",  "element": "Metal", "quality": "very_auspicious"},
    "柱": {"full": "天柱", "name_en": "Tian Zhu",  "element": "Metal", "quality": "inauspicious"},
    "芮": {"full": "天芮", "name_en": "Tian Rui",  "element": "Earth", "quality": "inauspicious"},
    "英": {"full": "天英", "name_en": "Tian Ying", "element": "Fire",  "quality": "neutral"},
}

BA_SHEN = {
    "值符": {"name_en": "Zhi Fu",   "element": "Earth", "quality": "very_auspicious"},
    "腾蛇": {"name_en": "Teng She", "element": "Fire",  "quality": "inauspicious"},
    "太阴": {"name_en": "Tai Yin",  "element": "Metal", "quality": "auspicious"},
    "六合": {"name_en": "Liu He",   "element": "Wood",  "quality": "auspicious"},
    "白虎": {"name_en": "Bai Hu",  "element": "Metal", "quality": "inauspicious"},
    "玄武": {"name_en": "Xuan Wu",  "element": "Water", "quality": "inauspicious"},
    "九地": {"name_en": "Jiu Di",   "element": "Earth", "quality": "auspicious"},
    "九天": {"name_en": "Jiu Tian", "element": "Metal", "quality": "auspicious"},
}

DEITY_SHORT_MAP = {
    "六": "六合", "白": "白虎", "玄": "玄武", "阴": "太阴",
    "地": "九地", "蛇": "腾蛇", "符": "值符", "天": "九天",
}

PALACE_META = {
    1: {"trigram": "坎", "direction": "N",  "direction_zh": "北"},
    2: {"trigram": "坤", "direction": "SW", "direction_zh": "西南"},
    3: {"trigram": "震", "direction": "E",  "direction_zh": "东"},
    4: {"trigram": "巽", "direction": "SE", "direction_zh": "东南"},
    5: {"trigram": "中", "direction": "C",  "direction_zh": "中"},
    6: {"trigram": "乾", "direction": "NW", "direction_zh": "西北"},
    7: {"trigram": "兑", "direction": "W",  "direction_zh": "西"},
    8: {"trigram": "艮", "direction": "NE", "direction_zh": "东北"},
    9: {"trigram": "离", "direction": "S",  "direction_zh": "南"},
}

# ---------------------------------------------------------------------------
# Gemini Vision extraction
# ---------------------------------------------------------------------------

GEMINI_PROMPT = """
You are a Qi Men Dun Jia (奇门遁甲) expert. Analyze this QMDJ chart image and extract the data.

Return ONLY a JSON object with this exact structure:

{
  "chart_meta": {
    "date": "<YYYY-MM-DD HH:MM>",
    "lunar_date": "<string>",
    "solar_term": "<string>",
    "plate_type": "<时盘/日盘/月盘/年盘>",
    "ju_type": "<阳遁/阴遁>",
    "ju_number": <1-9>,
    "jia_cycle": "<string>",
    "duty_symbol": "<值符 star name>",
    "duty_door": "<值使 door name>",
    "horse_star": "<马星 branch>",
    "void_branches": "<空亡 branches>",
    "si_zhu": {
      "year": "<stem+branch>",
      "month": "<stem+branch>",
      "day": "<stem+branch>",
      "hour": "<stem+branch>"
    }
  },
  "direction_stems": {
    "N": "<stem>", "S": "<stem>", "E": "<stem>", "W": "<stem>",
    "NE": "<stem>", "NW": "<stem>", "SE": "<stem>", "SW": "<stem>"
  },
  "palaces": {
    "1": { "palace": 1, "direction": "N",  "deity": "<full deity name>", "star": "<single char>", "door": "<single char>", "tian_gan": ["<stems>"], "life_states": ["<states>"], "void": false },
    "2": { "palace": 2, "direction": "SW", ... },
    "3": { "palace": 3, "direction": "E",  ... },
    "4": { "palace": 4, "direction": "SE", ... },
    "5": { "palace": 5, "direction": "C",  "deity": null, "star": "禽", "door": null, "tian_gan": [], "life_states": [] },
    "6": { "palace": 6, "direction": "NW", ... },
    "7": { "palace": 7, "direction": "W",  ... },
    "8": { "palace": 8, "direction": "NE", ... },
    "9": { "palace": 9, "direction": "S",  ... }
  }
}

Grid layout in image (standard QMDJ):
  Top row    (left→right): Palace 4(SE), Palace 9(S),  Palace 2(SW)
  Middle row (left→right): Palace 3(E),  Palace 5(C),  Palace 7(W)
  Bottom row (left→right): Palace 8(NE), Palace 1(N),  Palace 6(NW)

For deity names use full form: 值符/腾蛇/太阴/六合/白虎/玄武/九地/九天
For void indicator: if you see a ○ circle in the palace, set "void": true
Extract ALL heavenly stems visible in each palace cell into tian_gan array.
Extract life state annotations (生/沐/冠/临/旺/衰/病/死/墓/绝/胎/养) into life_states.
"""


def extract_via_gemini(image_path: str) -> dict:
    """Call Gemini Vision API to extract chart data."""
    import base64
    import urllib.request
    import urllib.error

    # Load API key
    api_key = os.environ.get("GOOGLE_API_KEY") or os.environ.get("GEMINI_API_KEY")
    if not api_key:
        env_file = os.path.expanduser("~/.openclaw/secrets/gemini.env")
        if os.path.exists(env_file):
            with open(env_file) as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("GOOGLE_API_KEY=") or line.startswith("GEMINI_API_KEY="):
                        api_key = line.split("=", 1)[1].strip().strip('"').strip("'")
                        break

    if not api_key:
        raise RuntimeError("GOOGLE_API_KEY not found. Set it or place in ~/.openclaw/secrets/gemini.env")

    # Read and encode image
    with open(image_path, "rb") as f:
        img_bytes = f.read()
    img_b64 = base64.b64encode(img_bytes).decode()

    # Detect mime type
    ext = os.path.splitext(image_path)[1].lower()
    mime = {"jpg": "image/jpeg", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
            ".png": "image/png", ".webp": "image/webp"}.get(ext, "image/jpeg")

    payload = json.dumps({
        "contents": [{
            "parts": [
                {"text": GEMINI_PROMPT},
                {"inline_data": {"mime_type": mime, "data": img_b64}}
            ]
        }],
        "generationConfig": {"temperature": 0.1, "maxOutputTokens": 4096}
    }).encode()

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            result = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"Gemini API error {e.code}: {e.read().decode()}")

    text = result["candidates"][0]["content"]["parts"][0]["text"]

    # Strip markdown fences if present
    text = text.strip()
    if text.startswith("```"):
        text = text[text.index("{"):]
    if text.endswith("```"):
        text = text[:text.rindex("}") + 1]

    return json.loads(text)


# ---------------------------------------------------------------------------
# Manually extracted data for chart b2ac499d (2026-03-17 20:46)
# Extracted by Taoz (Claude Code Sonnet 4.6) from direct image analysis
# ---------------------------------------------------------------------------

CHART_B2AC499D = {
    "chart_meta": {
        "date": "2026-03-17 20:46",
        "lunar_date": "一月廿九",
        "solar_term": "惊蛰2026.03.05 21:58 ~ 春分2026.03.20 22:45",
        "plate_type": "时盘",
        "ju_type": "阳遁",
        "ju_number": 3,
        "monthly_general": "亥",
        "jia_cycle": "甲申庚",
        "duty_symbol": "天禽",
        "duty_door": "死门",
        "horse_star": "申",
        "void_branches": "午未",
        "si_zhu": {
            "year":  "丙午",
            "month": "辛卯",
            "day":   "庚寅",
            "hour":  "丙戌"
        }
    },
    "direction_stems": {
        "N":  "戊",
        "S":  "壬",
        "E":  "丁",
        "W":  "丙",
        "SE": "乙庚",
        "SW": "辛",
        "NE": "己",
        "NW": "癸"
    },
    "palaces": {
        "4": {
            "palace": 4, "direction": "SE",
            "deity": "六合",
            "star": "蓬",
            "door": "伤",
            "tian_gan": ["丙", "己"],
            "life_states": ["冠", "临", "旺", "衰"],
            "void": False,
            "notes": "六合+天蓬+伤门 in SE palace"
        },
        "9": {
            "palace": 9, "direction": "S",
            "deity": "白虎",
            "star": "任",
            "door": "杜",
            "tian_gan": ["癸", "丁"],
            "life_states": ["绝", "临"],
            "void": True,
            "notes": "白虎+天任+杜门 in S palace — 空亡(void)"
        },
        "2": {
            "palace": 2, "direction": "SW",
            "deity": "玄武",
            "star": "冲",
            "door": "景",
            "tian_gan": ["戊", "乙庚"],
            "life_states": ["衰", "病", "胎", "养", "冠", "临"],
            "void": True,
            "notes": "玄武+天冲+景门 in SW palace — 空亡(void)"
        },
        "3": {
            "palace": 3, "direction": "E",
            "deity": "太阴",
            "star": "心",
            "door": "生",
            "tian_gan": ["辛", "戊"],
            "life_states": ["绝", "沐"],
            "void": False,
            "notes": "太阴+天心+生门 in E palace — 戊 highlighted (大格?)"
        },
        "5": {
            "palace": 5, "direction": "C",
            "deity": None,
            "star": "禽",
            "door": None,
            "tian_gan": [],
            "life_states": [],
            "void": False,
            "notes": "Center palace (寄宫 — 天禽 rests here; active 天禽 follows 天芮)"
        },
        "7": {
            "palace": 7, "direction": "W",
            "deity": "九地",
            "star": "辅",
            "door": "死",
            "tian_gan": ["己", "壬"],
            "life_states": ["生", "沐"],
            "void": False,
            "notes": "九地+天辅+死门 in W palace"
        },
        "8": {
            "palace": 8, "direction": "NE",
            "deity": "腾蛇",
            "star": "柱",
            "door": "休",
            "tian_gan": ["壬", "癸"],
            "life_states": ["衰", "病", "沐", "冠"],
            "void": False,
            "notes": "腾蛇+天柱+休门 in NE palace"
        },
        "1": {
            "palace": 1, "direction": "N",
            "deity": "值符",
            "star": "芮",
            "door": "开",
            "tian_gan": ["乙庚", "丙"],
            "life_states": ["病", "死", "胎"],
            "void": False,
            "notes": "值符+天芮+开门 in N palace — 病死 (inauspicious life states, red)"
        },
        "6": {
            "palace": 6, "direction": "NW",
            "deity": "九天",
            "star": "英",
            "door": "惊",
            "tian_gan": ["丁", "辛"],
            "life_states": ["胎", "养", "沐", "冠"],
            "void": False,
            "notes": "九天+天英+惊门 in NW palace"
        }
    }
}


# ---------------------------------------------------------------------------
# Enrichment: add full names + quality ratings
# ---------------------------------------------------------------------------

def enrich_palace(palace_data: dict) -> dict:
    """Add full names, English translations, and quality data to a palace."""
    p = dict(palace_data)
    meta = PALACE_META.get(p["palace"], {})
    p["trigram"] = meta.get("trigram", "")

    # Deity
    deity = p.get("deity")
    if deity and deity in BA_SHEN:
        p["deity_data"] = BA_SHEN[deity]
    elif deity and deity in DEITY_SHORT_MAP:
        full = DEITY_SHORT_MAP[deity]
        p["deity"] = full
        p["deity_data"] = BA_SHEN.get(full, {})

    # Star
    star = p.get("star")
    if star and star in JIU_XING:
        p["star_data"] = JIU_XING[star]

    # Door
    door = p.get("door")
    if door and door in BA_MEN:
        p["door_data"] = BA_MEN[door]

    return p


def build_summary(chart: dict) -> dict:
    """Build a summary of key formations and auspicious palaces."""
    palaces = chart.get("palaces", {})
    summary = {
        "auspicious_palaces": [],
        "inauspicious_palaces": [],
        "void_palaces": [],
        "key_formations": []
    }

    for pid, p in palaces.items():
        if p.get("void"):
            summary["void_palaces"].append(int(pid))

        door_q = p.get("door_data", {}).get("quality", "")
        deity_q = p.get("deity_data", {}).get("quality", "")
        star_q = p.get("star_data", {}).get("quality", "")

        score = sum([
            2 if q == "very_auspicious" else 1 if q == "auspicious" else
            -2 if q == "inauspicious" else 0
            for q in [door_q, deity_q, star_q]
        ])

        if score >= 2:
            summary["auspicious_palaces"].append(int(pid))
        elif score <= -2:
            summary["inauspicious_palaces"].append(int(pid))

        # Check for Ji Men (击刑 门迫 formations)
        door = p.get("door")
        deity = p.get("deity")
        if door == "死" and deity in ("白虎", "玄武"):
            summary["key_formations"].append({
                "palace": int(pid), "type": "凶格",
                "description": f"Palace {pid}: 死门+{deity} — severe obstruction"
            })
        if door == "生" and deity in ("值符", "六合", "九天"):
            summary["key_formations"].append({
                "palace": int(pid), "type": "吉格",
                "description": f"Palace {pid}: 生门+{deity} — wealth and vitality"
            })
        if door == "开" and deity in ("值符", "九天"):
            summary["key_formations"].append({
                "palace": int(pid), "type": "吉格",
                "description": f"Palace {pid}: 开门+{deity} — opportunity and expansion"
            })

    return summary


def extract_chart(image_path: str, mode: str = "auto") -> dict:
    """
    Extract QMDJ chart data from image.
    mode='vision': always use Gemini
    mode='manual': use embedded data if image matches known hash
    mode='auto': try hash match first, fall back to Gemini
    """
    import hashlib

    # Compute image hash
    with open(image_path, "rb") as f:
        img_hash = hashlib.md5(f.read()).hexdigest()[:8]

    known_charts = {
        "b2ac499d": CHART_B2AC499D,
        # 277bd5fc is a Liu Yao Na Jia table (NOT QMDJ) — extracted JSON at data/chart-277bd5fc-extracted.json
        # Cannot be returned by this extractor (wrong chart type). Use data file directly.
    }

    # Try to match by filename UUID prefix
    basename = os.path.basename(image_path)
    uuid_prefix = basename[:8] if len(basename) >= 8 else basename

    if mode in ("manual", "auto") and uuid_prefix in known_charts:
        print(f"[INFO] Matched known chart by filename prefix: {uuid_prefix}", file=sys.stderr)
        chart = dict(known_charts[uuid_prefix])
    elif mode == "vision" or (mode == "auto" and uuid_prefix not in known_charts):
        print(f"[INFO] Calling Gemini Vision API for extraction...", file=sys.stderr)
        chart = extract_via_gemini(image_path)
    else:
        raise ValueError(f"Unknown mode: {mode}")

    # Enrich palaces
    enriched_palaces = {}
    for pid, palace in chart.get("palaces", {}).items():
        enriched_palaces[pid] = enrich_palace(palace)
    chart["palaces"] = enriched_palaces

    # Add summary
    chart["summary"] = build_summary(chart)

    # Add extraction metadata
    chart["_meta"] = {
        "extracted_at": datetime.now().isoformat(),
        "image_path": image_path,
        "mode": mode,
        "extractor": "qmdj-chart-extract.py v1.0"
    }

    return chart


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def print_chart_table(chart: dict):
    """Pretty-print chart as a readable table."""
    meta = chart.get("chart_meta", {})
    print(f"\n{'='*60}")
    print(f"  QMDJ Chart — {meta.get('date', '?')} ({meta.get('lunar_date', '')})")
    print(f"  {meta.get('ju_type', '')}遁{meta.get('ju_number', '')}局  |  值符:{meta.get('duty_symbol')}  值使:{meta.get('duty_door')}")
    print(f"  空亡: {meta.get('void_branches')}  马星: {meta.get('horse_star')}")
    print(f"{'='*60}")

    grid_order = [
        ["4", "9", "2"],
        ["3", "5", "7"],
        ["8", "1", "6"],
    ]
    dir_stems = chart.get("direction_stems", {})
    palaces = chart.get("palaces", {})

    # Print outer top stem
    top_stem = dir_stems.get("S", "?")
    print(f"                  {top_stem}")
    print(f"  {'─'*52}")

    for row_idx, row in enumerate(grid_order):
        left_dir = ["SE", "E", "NE"][row_idx]
        right_dir = ["SW", "W", "NW"][row_idx]
        left_stem = dir_stems.get(left_dir, " ")
        right_stem = dir_stems.get(right_dir, " ")

        cells = []
        for pid in row:
            p = palaces.get(pid, {})
            deity = p.get("deity", "—") or "—"
            deity_short = deity[:2] if deity else "—"
            star = p.get("star", "—") or "—"
            door = p.get("door", "—") or "—"
            stems = "/".join(p.get("tian_gan", []))
            void_mark = " ○" if p.get("void") else "  "
            cells.append(f"{deity_short}{void_mark} {star}星 {door}门 [{stems}]")

        row_str = " │ ".join(f"{c:<22}" for c in cells)
        print(f"  {left_stem:<4}│ {row_str} │{right_stem}")
        if row_idx < 2:
            print(f"  {'─'*52}")

    print(f"  {'─'*52}")
    bottom_stem = dir_stems.get("N", "?")
    print(f"                  {bottom_stem}")

    # Summary
    s = chart.get("summary", {})
    print(f"\n  吉宫: {s.get('auspicious_palaces', [])}  凶宫: {s.get('inauspicious_palaces', [])}  空亡宫: {s.get('void_palaces', [])}")
    if s.get("key_formations"):
        print(f"  关键格局:")
        for f in s["key_formations"]:
            print(f"    {f['type']}: {f['description']}")
    print()


def main():
    parser = argparse.ArgumentParser(description="QMDJ Chart Image Extractor")
    parser.add_argument("--image", required=True, help="Path to QMDJ chart image")
    parser.add_argument("--mode", choices=["auto", "vision", "manual"], default="auto",
                        help="Extraction mode (default: auto)")
    parser.add_argument("--output", help="Path to save JSON output (optional)")
    parser.add_argument("--table", action="store_true", help="Print human-readable table")
    args = parser.parse_args()

    if not os.path.exists(args.image):
        print(f"Error: image not found: {args.image}", file=sys.stderr)
        sys.exit(1)

    chart = extract_chart(args.image, mode=args.mode)

    if args.table:
        print_chart_table(chart)

    output_json = json.dumps(chart, ensure_ascii=False, indent=2)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output_json)
        print(f"[OK] Chart data saved to: {args.output}", file=sys.stderr)
    else:
        print(output_json)


if __name__ == "__main__":
    main()
