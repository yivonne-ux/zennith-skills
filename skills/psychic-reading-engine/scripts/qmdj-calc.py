#!/usr/bin/env python3
"""
阴盘奇门遁甲 (Yin Plate Qi Men Dun Jia) Calculator — 长卿 School
Real astronomical solar terms, correct 旬-based Yuan, 三奇六仪 analysis,
proper 值符/值使 rotation, nine palaces, eight doors, nine stars, eight deities.

Yin Plate (阴盘) key differences from Yang Plate (阳盘):
  1. Earth plate uses flying path (sequential 1-9 skip 5), not spiral
  2. 阳遁: 阴盘 stem sequence forward; 阴遁: 阳盘 stem sequence backward
  3. 值符/值使 determined by 遁甲干 position on earth plate (not ju palace)
  4. Stars & heaven stems rotate by same offset (spiral PALACE_ORDER)
  5. Doors: 阳遁 +offset, 阴遁 -offset (spiral)
  6. Deities: 阳遁 forward, 阴遁 backward from hour stem palace (spiral)
  7. 天禽 (center star) follows 天芮 / goes to palace 2
"""

import ephem
import math
import json
import sys
import argparse
from datetime import datetime, date, timedelta
import pytz

try:
    from lunardate import LunarDate
    HAS_LUNARDATE = True
except ImportError:
    HAS_LUNARDATE = False


# ---------------------------------------------------------------------------
# 天干 (Heavenly Stems) and 地支 (Earthly Branches)
# ---------------------------------------------------------------------------

HEAVENLY_STEMS = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
HEAVENLY_STEMS_EN = ["Jia", "Yi", "Bing", "Ding", "Wu", "Ji", "Geng", "Xin", "Ren", "Gui"]

EARTHLY_BRANCHES = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
EARTHLY_BRANCHES_EN = ["Zi", "Chou", "Yin", "Mao", "Chen", "Si", "Wu", "Wei", "Shen", "You", "Xu", "Hai"]

BRANCH_ANIMALS = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
                  "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]

FIVE_ELEMENTS_STEM = {
    "甲": "Wood", "乙": "Wood", "丙": "Fire", "丁": "Fire", "戊": "Earth",
    "己": "Earth", "庚": "Metal", "辛": "Metal", "壬": "Water", "癸": "Water"
}

FIVE_ELEMENTS_BRANCH = {
    "子": "Water", "丑": "Earth", "寅": "Wood", "卯": "Wood", "辰": "Earth", "巳": "Fire",
    "午": "Fire", "未": "Earth", "申": "Metal", "酉": "Metal", "戌": "Earth", "亥": "Water"
}

# Five Element interactions
GENERATES = {"Wood": "Fire", "Fire": "Earth", "Earth": "Metal", "Metal": "Water", "Water": "Wood"}
OVERCOMES = {"Wood": "Earth", "Earth": "Water", "Water": "Fire", "Fire": "Metal", "Metal": "Wood"}


# ---------------------------------------------------------------------------
# 三奇六仪 (Three Wonders & Six Instruments)
# ---------------------------------------------------------------------------

SANQI_LIUYI = {
    "乙": {"type": "三奇", "name": "日奇", "name_en": "Day Marvel", "role": "天德 — heavenly virtue, gentle aid"},
    "丙": {"type": "三奇", "name": "月奇", "name_en": "Moon Marvel", "role": "天威 — heavenly power, authority"},
    "丁": {"type": "三奇", "name": "星奇", "name_en": "Star Marvel", "role": "玉女太阴 — jade maiden, hidden support"},
    "戊": {"type": "六仪", "name": "甲子戊", "name_en": "Jia-Zi Wu", "role": "值符本宫 — chief's own palace"},
    "己": {"type": "六仪", "name": "甲戌己", "name_en": "Jia-Xu Ji", "role": "六合 — harmony and partnership"},
    "庚": {"type": "六仪", "name": "甲申庚", "name_en": "Jia-Shen Geng", "role": "太白 — conflict, obstacle, competitor"},
    "辛": {"type": "六仪", "name": "甲午辛", "name_en": "Jia-Wu Xin", "role": "文曲 — document, punishment, small obstacle"},
    "壬": {"type": "六仪", "name": "甲辰壬", "name_en": "Jia-Chen Ren", "role": "天牢 — imprisonment, constraint"},
    "癸": {"type": "六仪", "name": "甲寅癸", "name_en": "Jia-Yin Gui", "role": "天网 — entanglement, net"},
}

# Special QMDJ formations (格局)
SPECIAL_FORMATIONS = {
    ("乙", "庚"): {"name": "日奇伏吟", "nature": "mixed", "meaning": "Day Marvel meets Metal — gentle overcomes rigid, eventual success through patience"},
    ("丙", "庚"): {"name": "月奇悖格", "nature": "auspicious", "meaning": "Moon Marvel tames Metal — authority subdues opposition, victory through power"},
    ("丁", "庚"): {"name": "星奇入墓", "nature": "auspicious", "meaning": "Star Marvel restrains Metal — wisdom defeats force, strategic advantage"},
    ("庚", "庚"): {"name": "战格", "nature": "inauspicious", "meaning": "Metal clashes Metal — fierce competition, mutual destruction, avoid conflict"},
    ("庚", "甲"): {"name": "值符飞宫", "nature": "inauspicious", "meaning": "Metal attacks Wood — authority challenged, be vigilant"},
    ("丙", "丙"): {"name": "月奇耀辉", "nature": "very_auspicious", "meaning": "Double Fire brilliance — fame, recognition, spectacular success"},
    ("丁", "丁"): {"name": "星奇叠辉", "nature": "auspicious", "meaning": "Double subtle light — deep wisdom, scholarly achievement"},
    ("乙", "乙"): {"name": "日奇同宫", "nature": "auspicious", "meaning": "Double Wood — abundant growth, creativity flourishes"},
}


# ---------------------------------------------------------------------------
# 二十四节气 (24 Solar Terms) — computed astronomically
# ---------------------------------------------------------------------------

SOLAR_TERMS = [
    ("立春", "Lichun", 315),      # Start of Spring
    ("雨水", "Yushui", 330),      # Rain Water
    ("惊蛰", "Jingzhe", 345),     # Awakening of Insects
    ("春分", "Chunfen", 0),       # Spring Equinox
    ("清明", "Qingming", 15),     # Clear and Bright
    ("谷雨", "Guyu", 30),        # Grain Rain
    ("立夏", "Lixia", 45),       # Start of Summer
    ("小满", "Xiaoman", 60),     # Grain Buds
    ("芒种", "Mangzhong", 75),   # Grain in Ear
    ("夏至", "Xiazhi", 90),      # Summer Solstice
    ("小暑", "Xiaoshu", 105),    # Minor Heat
    ("大暑", "Dashu", 120),      # Major Heat
    ("立秋", "Liqiu", 135),      # Start of Autumn
    ("处暑", "Chushu", 150),     # End of Heat
    ("白露", "Bailu", 165),      # White Dew
    ("秋分", "Qiufen", 180),     # Autumn Equinox
    ("寒露", "Hanlu", 195),      # Cold Dew
    ("霜降", "Shuangjing", 210), # Frost's Descent
    ("立冬", "Lidong", 225),     # Start of Winter
    ("小雪", "Xiaoxue", 240),    # Minor Snow
    ("大雪", "Daxue", 255),      # Major Snow
    ("冬至", "Dongzhi", 270),    # Winter Solstice
    ("小寒", "Xiaohan", 285),    # Minor Cold
    ("大寒", "Dahan", 300),      # Major Cold
]

# 12 节 (Jie) solar terms that define month boundaries
MONTH_JIE_TERMS = [
    ("立春", 315, 0),    # 寅月 start
    ("惊蛰", 345, 1),    # 卯月 start
    ("清明", 15, 2),     # 辰月 start
    ("立夏", 45, 3),     # 巳月 start
    ("芒种", 75, 4),     # 午月 start
    ("小暑", 105, 5),    # 未月 start
    ("立秋", 135, 6),    # 申月 start
    ("白露", 165, 7),    # 酉月 start
    ("寒露", 195, 8),    # 戌月 start
    ("立冬", 225, 9),    # 亥月 start
    ("大雪", 255, 10),   # 子月 start
    ("小寒", 285, 11),   # 丑月 start
]


def sun_ecliptic_lon(dt_utc):
    """Get Sun's ecliptic longitude at a UTC datetime using PyEphem."""
    s = ephem.Sun()
    s.compute(ephem.Date(dt_utc))
    ecl = ephem.Ecliptic(s, epoch=ephem.Date(dt_utc))
    return math.degrees(float(ecl.lon)) % 360


def find_solar_term(dt_utc):
    """Find the most recent solar term before the given datetime."""
    sun_lon = sun_ecliptic_lon(dt_utc)

    best_term = None
    best_diff = 999

    for cn, en, lon in SOLAR_TERMS:
        diff = (sun_lon - lon) % 360
        if diff < best_diff:
            best_diff = diff
            best_term = (cn, en, lon)

    return {
        "chinese": best_term[0],
        "english": best_term[1],
        "solar_longitude": best_term[2],
        "sun_actual_longitude": round(sun_lon, 4),
        "degrees_past_term": round(best_diff, 4),
    }


def find_solar_term_precise(dt_utc):
    """Find precise datetime of the most recent solar term using bisection."""
    term_info = find_solar_term(dt_utc)
    target_lon = term_info["solar_longitude"]

    lo = dt_utc - timedelta(days=20)
    hi = dt_utc

    for _ in range(50):
        mid = lo + (hi - lo) / 2
        mid_lon = sun_ecliptic_lon(mid)
        diff = (mid_lon - target_lon) % 360
        if diff < 180:
            hi = mid
        else:
            lo = mid

    return term_info, hi


def determine_month_from_solar_terms(dt_utc):
    """Determine the Chinese month index using 节气 (Jie) boundaries.
    Returns month_idx: 0=寅月, 1=卯月, ... 11=丑月
    """
    sun_lon = sun_ecliptic_lon(dt_utc)

    best_month = 11  # default to 丑月 (before 立春)
    best_diff = 999

    for _, lon, month_idx in MONTH_JIE_TERMS:
        diff = (sun_lon - lon) % 360
        if diff < best_diff:
            best_diff = diff
            best_month = month_idx

    return best_month


def is_before_lichun(dt_utc):
    """Check if date is before 立春 (Start of Spring) in its year."""
    month = dt_utc.month
    if month >= 3:
        return False
    if month >= 2 and dt_utc.day > 10:
        return False

    sun_lon = sun_ecliptic_lon(dt_utc)
    return sun_lon < 315 and sun_lon >= 270


# ---------------------------------------------------------------------------
# 六十甲子 Sexagenary cycle computation
# ---------------------------------------------------------------------------

def cycle_pos_from_stem_branch(stem_idx, branch_idx):
    """Compute the 60-cycle position from stem and branch indices."""
    for p in range(60):
        if p % 10 == stem_idx and p % 12 == branch_idx:
            return p
    return 0


def sexagenary_year(year, before_lichun=False):
    """Compute 天干地支 for year. If before 立春, use previous year."""
    y = year - 1 if before_lichun else year
    stem_idx = (y - 4) % 10
    branch_idx = (y - 4) % 12
    return stem_idx, branch_idx


def sexagenary_month(year, month_idx, before_lichun=False):
    """Compute 天干地支 for month.
    month_idx: 0=寅(Feb/Mar), 1=卯(Mar/Apr)...11=丑(Jan/Feb)
    """
    y = year - 1 if before_lichun else year
    year_stem = (y - 4) % 10
    month_stem_base = [2, 4, 6, 8, 0, 2, 4, 6, 8, 0]
    stem_idx = (month_stem_base[year_stem] + month_idx) % 10
    branch_idx = (month_idx + 2) % 12  # 寅=2
    return stem_idx, branch_idx


def sexagenary_day(year, month, day):
    """Compute 天干地支 for day using the standard epoch."""
    ref = date(1900, 1, 1)
    target = date(year, month, day)
    delta = (target - ref).days
    cycle_pos = (delta + 10) % 60  # Jan 1 1900 = 甲戌 = position 10
    stem_idx = cycle_pos % 10
    branch_idx = cycle_pos % 12
    return stem_idx, branch_idx, cycle_pos


def sexagenary_hour(day_stem_idx, hour):
    """Compute 天干地支 for 时辰 (2-hour period)."""
    branch_idx = ((hour + 1) % 24) // 2
    hour_stem_base = [0, 2, 4, 6, 8, 0, 2, 4, 6, 8]
    stem_idx = (hour_stem_base[day_stem_idx] + branch_idx) % 10
    return stem_idx, branch_idx


def format_ganzi(stem_idx, branch_idx):
    """Format a Heavenly Stem + Earthly Branch pair."""
    return {
        "chinese": HEAVENLY_STEMS[stem_idx] + EARTHLY_BRANCHES[branch_idx],
        "pinyin": HEAVENLY_STEMS_EN[stem_idx] + EARTHLY_BRANCHES_EN[branch_idx],
        "stem": {"chinese": HEAVENLY_STEMS[stem_idx], "index": stem_idx,
                 "element": FIVE_ELEMENTS_STEM[HEAVENLY_STEMS[stem_idx]]},
        "branch": {"chinese": EARTHLY_BRANCHES[branch_idx], "index": branch_idx,
                    "animal": BRANCH_ANIMALS[branch_idx],
                    "element": FIVE_ELEMENTS_BRANCH[EARTHLY_BRANCHES[branch_idx]]},
    }


# ---------------------------------------------------------------------------
# 阴盘奇门遁甲 Core Constants
# ---------------------------------------------------------------------------

PALACE_DIRECTIONS = {
    1: "坎/North", 2: "坤/Southwest", 3: "震/East",
    4: "巽/Southeast", 5: "中/Center", 6: "乾/Northwest",
    7: "兑/West", 8: "艮/Northeast", 9: "离/South"
}

PALACE_TRIGRAMS = {
    1: "坎☵", 2: "坤☷", 3: "震☳", 4: "巽☴",
    5: "中宫", 6: "乾☰", 7: "兑☱", 8: "艮☶", 9: "离☲"
}

# Door info
DOOR_INFO = {
    "休门": ("Rest Gate", "auspicious"),
    "死门": ("Death Gate", "inauspicious"),
    "伤门": ("Harm Gate", "inauspicious"),
    "杜门": ("Block Gate", "neutral"),
    "景门": ("Scene Gate", "neutral"),
    "惊门": ("Shock Gate", "inauspicious"),
    "开门": ("Open Gate", "auspicious"),
    "生门": ("Life Gate", "auspicious"),
}

# Door home palaces
DOOR_HOME = {
    "休门": 1, "死门": 2, "伤门": 3, "杜门": 4,
    "景门": 9, "惊门": 7, "开门": 6, "生门": 8,
}

# Palace → door mapping
PALACE_TO_DOOR = {1: "休门", 2: "死门", 3: "伤门", 4: "杜门", 6: "开门", 7: "惊门", 8: "生门", 9: "景门"}

# 九星 (9 Stars) — home palace = key
NINE_STARS = {
    1: ("天蓬", "Tianpeng", "Water", "inauspicious"),
    2: ("天芮", "Tianrui", "Earth", "inauspicious"),
    3: ("天冲", "Tianchong", "Wood", "auspicious"),
    4: ("天辅", "Tianfu", "Wood", "auspicious"),
    5: ("天禽", "Tianqin", "Earth", "neutral"),
    6: ("天心", "Tianxin", "Metal", "auspicious"),
    7: ("天柱", "Tianzhu", "Metal", "inauspicious"),
    8: ("天任", "Tianren", "Earth", "auspicious"),
    9: ("天英", "Tianying", "Fire", "neutral"),
}

# 八神 (8 Deities)
EIGHT_DEITIES = [
    ("值符", "Zhifu", "Chief"),
    ("腾蛇", "Tengshe", "Serpent"),
    ("太阴", "Taiyin", "Moon"),
    ("六合", "Liuhe", "Harmony"),
    ("白虎", "Baihu", "White Tiger"),
    ("玄武", "Xuanwu", "Dark Warrior"),
    ("九地", "Jiudi", "Nine Earth"),
    ("九天", "Jiutian", "Nine Heaven"),
]

# Spiral palace order (Luoshu path) for rotation: 1→8→3→4→9→2→7→6
SPIRAL_ORDER = [1, 8, 3, 4, 9, 2, 7, 6]

# Flying palace path (sequential, skip 5): 1→2→3→4→6→7→8→9
FLYING_ORDER = [1, 2, 3, 4, 6, 7, 8, 9]

# 遁甲 stems
DUNJIA_STEMS = {0: "戊", 10: "己", 20: "庚", 30: "辛", 40: "壬", 50: "癸"}

# Stem sequences
YANG_STEM_SEQ = ["戊", "己", "庚", "辛", "壬", "癸", "丁", "丙", "乙"]  # 阳盘: 六仪+三奇
YIN_STEM_SEQ = ["乙", "丙", "丁", "癸", "壬", "辛", "庚", "己", "戊"]  # 阴盘: 三奇+六仪逆

# 马星 (Traveling Horse) — based on day branch
HORSE_STAR_MAP = {
    "寅": "申", "午": "申", "戌": "申",
    "申": "寅", "子": "寅", "辰": "寅",
    "巳": "亥", "酉": "亥", "丑": "亥",
    "亥": "巳", "卯": "巳", "未": "巳",
}

# Branch to palace mapping
BRANCH_TO_PALACE = {
    "子": 1, "丑": 8, "寅": 8, "卯": 3, "辰": 4, "巳": 4,
    "午": 9, "未": 2, "申": 2, "酉": 7, "戌": 6, "亥": 6,
}


# ---------------------------------------------------------------------------
# Yuan / Dun / Ju determination
# ---------------------------------------------------------------------------

def determine_yuan(day_cycle_pos, target_date=None, solar_term_date=None):
    """Determine Upper/Middle/Lower Yuan using 拆补法."""
    xun_start = (day_cycle_pos // 10) * 10

    if target_date is not None and solar_term_date is not None:
        st_s, st_b, st_pos = sexagenary_day(solar_term_date.year, solar_term_date.month, solar_term_date.day)
        stem_idx = st_pos % 10
        days_back_jia = stem_idx % 10
        days_back_ji = (stem_idx - 5) % 10
        days_back = min(days_back_jia, days_back_ji)
        fu_tou_date = solar_term_date - timedelta(days=days_back)

        days_from_fu_tou = (target_date - fu_tou_date).days
        if days_from_fu_tou < 0:
            days_from_fu_tou = 0
        yuan_cycle = (days_from_fu_tou // 5) % 3
        yuan_num = yuan_cycle + 1
    else:
        yuan_map = {0: 1, 30: 1, 50: 2, 20: 2, 40: 3, 10: 3}
        yuan_num = yuan_map.get(xun_start, 1)

    yuan_labels = {1: ("上元", "Upper Yuan"), 2: ("中元", "Middle Yuan"), 3: ("下元", "Lower Yuan")}
    cn, en = yuan_labels[yuan_num]

    return {
        "chinese": cn, "english": en, "number": yuan_num,
        "xun_start": xun_start,
        "xun_name": HEAVENLY_STEMS[xun_start % 10] + EARTHLY_BRANCHES[xun_start % 12],
    }


def determine_dun_type(solar_term_cn):
    """Determine Yin Dun (阴遁) or Yang Dun (阳遁)."""
    yang_terms = ["冬至", "小寒", "大寒", "立春", "雨水", "惊蛰",
                  "春分", "清明", "谷雨", "立夏", "小满", "芒种"]
    if solar_term_cn in yang_terms:
        return "阳遁", "Yang Dun"
    return "阴遁", "Yin Dun"


def determine_ju_number(solar_term_cn, yuan_num):
    """Determine the 局 number (1-9)."""
    term_groups_yang = {
        "冬至": [1, 7, 4], "小寒": [2, 8, 5], "大寒": [3, 9, 6],
        "立春": [8, 5, 2], "雨水": [9, 6, 3], "惊蛰": [3, 9, 6],
        "春分": [1, 7, 4], "清明": [4, 1, 7], "谷雨": [5, 2, 8],
        "立夏": [4, 1, 7], "小满": [5, 2, 8], "芒种": [6, 3, 9],
    }
    term_groups_yin = {
        "夏至": [9, 3, 6], "小暑": [8, 2, 5], "大暑": [7, 1, 4],
        "立秋": [2, 5, 8], "处暑": [1, 4, 7], "白露": [7, 1, 4],
        "秋分": [9, 3, 6], "寒露": [6, 9, 3], "霜降": [5, 8, 2],
        "立冬": [6, 9, 3], "小雪": [5, 8, 2], "大雪": [4, 7, 1],
    }

    if solar_term_cn in term_groups_yang:
        return term_groups_yang[solar_term_cn][yuan_num - 1]
    elif solar_term_cn in term_groups_yin:
        return term_groups_yin[solar_term_cn][yuan_num - 1]
    return 1


def determine_ju_destiny(year_branch_idx, hour_branch_idx, solar_date, dun_type_cn):
    """Determine Ju number for destiny (命盘) mode using 阴盘 formula.

    Formula: (年支序数 + 时支序数 + 农历月 + 农历日) % 9
    If result = 0, use 9.
    年支序数/时支序数: 子=1, 丑=2, ..., 亥=12
    """
    if not HAS_LUNARDATE:
        # Fallback: cannot compute without lunar calendar library
        return None

    try:
        ld = LunarDate.fromSolarDate(solar_date.year, solar_date.month, solar_date.day)
        year_seq = year_branch_idx + 1   # 子=0→1, 丑=1→2, ..., 亥=11→12
        hour_seq = hour_branch_idx + 1
        lunar_month = ld.month
        lunar_day = ld.day

        result = (year_seq + hour_seq + lunar_month + lunar_day) % 9
        if result == 0:
            result = 9
        return result
    except Exception:
        return None


def find_xun_shou(stem_idx, branch_idx):
    """Find the 旬首 for a given stem/branch pair."""
    pos = cycle_pos_from_stem_branch(stem_idx, branch_idx)
    xun_start = (pos // 10) * 10
    xun_stem = HEAVENLY_STEMS[xun_start % 10]
    xun_branch = EARTHLY_BRANCHES[xun_start % 12]
    dunjia = DUNJIA_STEMS.get(xun_start, "戊")

    return {
        "xun_shou": xun_stem + xun_branch,
        "xun_start_pos": xun_start,
        "cycle_pos": pos,
        "dunjia_stem": dunjia,
        "dunjia_stem_en": HEAVENLY_STEMS_EN[HEAVENLY_STEMS.index(dunjia)],
    }


def get_kongwang(stem_idx, branch_idx):
    """Calculate 空亡 branches for a stem-branch pair."""
    pos = cycle_pos_from_stem_branch(stem_idx, branch_idx)
    xun_start = (pos // 10) * 10
    void_b1 = (xun_start + 10) % 12
    void_b2 = (xun_start + 11) % 12
    return EARTHLY_BRANCHES[void_b1], EARTHLY_BRANCHES[void_b2]


def get_hour_dunjia_stem(hour_stem_idx, hour_branch_idx):
    """Get the effective hour stem. If 甲, return the dunjia substitute."""
    hour_stem = HEAVENLY_STEMS[hour_stem_idx]
    if hour_stem == "甲":
        pos = cycle_pos_from_stem_branch(hour_stem_idx, hour_branch_idx)
        xun_start = (pos // 10) * 10
        return DUNJIA_STEMS.get(xun_start, "戊")
    return hour_stem


# ---------------------------------------------------------------------------
# 阴盘 Earth Plate — Flying Path Method
# ---------------------------------------------------------------------------

def build_earth_plate(ju_number, dun_type_cn):
    """Build 地盘 using luoshu spiral path.

    阳遁: 阴盘 stem sequence (乙丙丁癸壬辛庚己戊) placed FORWARD in spiral from ju palace
    阴遁: 阳盘 stem sequence (戊己庚辛壬癸丁丙乙) placed BACKWARD in spiral from ju palace
    """
    # Find ju palace index in SPIRAL_ORDER (luoshu flying path)
    if ju_number == 5:
        ju_spiral_idx = SPIRAL_ORDER.index(2)  # center → use palace 2
    else:
        ju_spiral_idx = SPIRAL_ORDER.index(ju_number)

    plate = {}
    if dun_type_cn == "阳遁":
        seq = YIN_STEM_SEQ  # 乙丙丁癸壬辛庚己戊
        for i in range(8):
            palace = SPIRAL_ORDER[(ju_spiral_idx + i) % 8]
            plate[palace] = seq[i]
        plate[5] = seq[8]  # center gets last stem (戊)
    else:
        seq = YANG_STEM_SEQ  # 戊己庚辛壬癸丁丙乙
        for i in range(8):
            palace = SPIRAL_ORDER[(ju_spiral_idx - i) % 8]
            plate[palace] = seq[i]
        plate[5] = seq[8]  # center gets last stem (乙)

    return plate


# ---------------------------------------------------------------------------
# 值符/值使 Determination (阴盘 method)
# ---------------------------------------------------------------------------

def find_stem_on_earth(stem, earth_plate):
    """Find which palace a stem sits on in the earth plate (non-center palaces).
    If stem is at center (palace 5), return palace 2 (阴盘: center寄坤2宫).
    """
    for palace in FLYING_ORDER:
        if earth_plate.get(palace) == stem:
            return palace
    if earth_plate.get(5) == stem:
        return 2  # center寄坤2宫
    return None


def get_zhifu_zhishi(ju_number, dun_type_cn, hour_dunjia_stem, earth_plate,
                      xun_shou_branch_idx=None):
    """Determine 值符 star and 值使 door for 阴盘奇门.

    In 阴盘 (长卿), 值符/值使 are determined by the 旬首地支's palace.
    旬首 甲申 → 申 → P2, so 值符=天禽(寄坤二宫), 值使=死门.
    天禽 (home P5) 寄坤二宫: when P2 is selected, 值符 displays as 天禽.
    """
    # Primary method: 旬首 branch → palace
    dunjia_palace = None
    if xun_shou_branch_idx is not None:
        xun_branch = EARTHLY_BRANCHES[xun_shou_branch_idx]
        dunjia_palace = BRANCH_TO_PALACE.get(xun_branch)

    # Fallback: dunjia stem position on earth plate
    if dunjia_palace is None:
        dunjia_palace = find_stem_on_earth(hour_dunjia_stem, earth_plate)
    if dunjia_palace is None:
        dunjia_palace = ju_number if ju_number != 5 else 2

    effective_palace = 2 if dunjia_palace == 5 else dunjia_palace

    # 值符 star: when palace = 2, 天禽寄坤二宫 takes precedence
    if effective_palace == 2:
        zhifu_star = "天禽"
        zhifu_star_en = "Tianqin"
    else:
        star_data = NINE_STARS[effective_palace]
        zhifu_star = star_data[0]
        zhifu_star_en = star_data[1]

    # 值使 door = door whose home palace = effective_palace
    zhishi_door_cn = PALACE_TO_DOOR.get(effective_palace, "休门")
    zhishi_door_en, zhishi_door_nature = DOOR_INFO[zhishi_door_cn]

    return {
        "zhifu_star": zhifu_star,
        "zhifu_star_en": zhifu_star_en,
        "zhifu_home": effective_palace,
        "zhishi_door": zhishi_door_cn,
        "zhishi_door_en": zhishi_door_en,
        "zhishi_home": effective_palace,
        "dunjia_palace": dunjia_palace,
    }


# ---------------------------------------------------------------------------
# Rotation Offset Calculation
# ---------------------------------------------------------------------------

def calc_rotation_offset(from_palace, to_palace):
    """Calculate rotation offset in SPIRAL_ORDER from one palace to another."""
    if from_palace not in SPIRAL_ORDER or to_palace not in SPIRAL_ORDER:
        return 0
    from_idx = SPIRAL_ORDER.index(from_palace)
    to_idx = SPIRAL_ORDER.index(to_palace)
    return (to_idx - from_idx) % 8


# ---------------------------------------------------------------------------
# Heaven Plate (天盘) — stems rotate by offset in spiral
# ---------------------------------------------------------------------------

def build_heaven_plate(earth_plate, rotation_offset):
    """Build 天盘. Earth plate stems rotate by +offset in SPIRAL_ORDER."""
    plate = {}
    for i in range(8):
        source_palace = SPIRAL_ORDER[i]
        dest_palace = SPIRAL_ORDER[(i + rotation_offset) % 8]
        plate[dest_palace] = earth_plate.get(source_palace, "")

    # Center: in 阴盘, center stem stays or follows P2
    plate[5] = earth_plate.get(5, "")
    return plate


# ---------------------------------------------------------------------------
# Star Plate (星盘) — stars rotate by same offset in spiral
# ---------------------------------------------------------------------------

def build_star_plate(rotation_offset, zhifu_home):
    """Build 星盘. Stars rotate by +offset in SPIRAL_ORDER.
    天禽 (center, home 5) follows 天芮 (home 2).
    """
    plate = {}
    for i in range(8):
        source_palace = SPIRAL_ORDER[i]
        dest_palace = SPIRAL_ORDER[(i + rotation_offset) % 8]
        star_data = NINE_STARS[source_palace]
        plate[dest_palace] = {
            "chinese": star_data[0],
            "english": star_data[1],
            "element": star_data[2],
            "nature": star_data[3],
            "home_palace": source_palace,
        }

    # 天禽 follows 天芮
    tianrui_palace = None
    for p, s in plate.items():
        if s["chinese"] == "天芮":
            tianrui_palace = p
            break

    plate[5] = {
        "chinese": "天禽", "english": "Tianqin", "element": "Earth",
        "nature": "neutral", "home_palace": 5,
        "follows": f"天芮 at palace {tianrui_palace}" if tianrui_palace else "天芮",
    }
    return plate


# ---------------------------------------------------------------------------
# Door Plate (门盘) — 阳遁 +offset, 阴遁 -offset in spiral
# ---------------------------------------------------------------------------

def build_door_plate(dun_type_cn, rotation_offset):
    """Build 门盘. Doors rotate in SPIRAL_ORDER.
    阳遁: +offset (forward). 阴遁: -offset (backward).
    """
    plate = {}
    for i in range(8):
        source_palace = SPIRAL_ORDER[i]
        door_cn = PALACE_TO_DOOR[source_palace]
        door_en, door_nature = DOOR_INFO[door_cn]

        if dun_type_cn == "阳遁":
            dest_palace = SPIRAL_ORDER[(i + rotation_offset) % 8]
        else:
            dest_palace = SPIRAL_ORDER[(i - rotation_offset) % 8]

        plate[dest_palace] = {
            "chinese": door_cn,
            "english": door_en,
            "nature": door_nature,
            "home_palace": source_palace,
        }
    return plate


# ---------------------------------------------------------------------------
# Deity Plate (神盘) — from hour stem palace, spiral forward/backward
# ---------------------------------------------------------------------------

def build_deity_plate(dun_type_cn, hour_stem_palace):
    """Build 神盘. 值符 deity at hour stem palace.
    阳遁: forward in spiral. 阴遁: backward in spiral.
    """
    if hour_stem_palace not in SPIRAL_ORDER:
        hour_stem_palace = 2  # fallback

    start_idx = SPIRAL_ORDER.index(hour_stem_palace)

    plate = {}
    for i in range(8):
        if dun_type_cn == "阳遁":
            palace = SPIRAL_ORDER[(start_idx + i) % 8]
        else:
            palace = SPIRAL_ORDER[(start_idx - i) % 8]

        plate[palace] = {
            "chinese": EIGHT_DEITIES[i][0],
            "english": EIGHT_DEITIES[i][1],
            "role": EIGHT_DEITIES[i][2],
        }
    return plate


# ---------------------------------------------------------------------------
# 三奇六仪 Analysis
# ---------------------------------------------------------------------------

def analyze_sanqi_liuyi(earth_plate, heaven_plate):
    """Analyze Three Wonders & Six Instruments across all palaces."""
    analysis = {}

    for palace in range(1, 10):
        e_stem = earth_plate.get(palace, "")
        h_stem = heaven_plate.get(palace, "")

        palace_analysis = {"earth_stem": e_stem, "heaven_stem": h_stem}

        # Check for 乙庚合 display
        if set([e_stem, h_stem]) == set(["乙", "庚"]):
            palace_analysis["pair_display"] = "庚乙"

        if e_stem in SANQI_LIUYI:
            info = SANQI_LIUYI[e_stem]
            palace_analysis["earth_type"] = info["type"]
            palace_analysis["earth_name"] = info["name"]
            palace_analysis["earth_name_en"] = info["name_en"]

        if h_stem in SANQI_LIUYI:
            info = SANQI_LIUYI[h_stem]
            palace_analysis["heaven_type"] = info["type"]
            palace_analysis["heaven_name"] = info["name"]
            palace_analysis["heaven_name_en"] = info["name_en"]

        pair = (h_stem, e_stem)
        if pair in SPECIAL_FORMATIONS:
            formation = SPECIAL_FORMATIONS[pair]
            palace_analysis["formation"] = {
                "name": formation["name"],
                "nature": formation["nature"],
                "meaning": formation["meaning"],
            }

        if h_stem and e_stem and h_stem in FIVE_ELEMENTS_STEM and e_stem in FIVE_ELEMENTS_STEM:
            h_elem = FIVE_ELEMENTS_STEM[h_stem]
            e_elem = FIVE_ELEMENTS_STEM[e_stem]
            if h_elem == e_elem:
                palace_analysis["stem_interaction"] = "比和 (harmony)"
            elif GENERATES.get(h_elem) == e_elem:
                palace_analysis["stem_interaction"] = "天生地 (heaven nurtures earth)"
            elif GENERATES.get(e_elem) == h_elem:
                palace_analysis["stem_interaction"] = "地生天 (earth supports heaven)"
            elif OVERCOMES.get(h_elem) == e_elem:
                palace_analysis["stem_interaction"] = "天克地 (heaven controls earth)"
            elif OVERCOMES.get(e_elem) == h_elem:
                palace_analysis["stem_interaction"] = "地克天 (earth resists heaven)"

        if palace_analysis.get("heaven_type") == "三奇":
            palace_analysis["has_wonder"] = True
            palace_analysis["wonder_quality"] = "auspicious"
        else:
            palace_analysis["has_wonder"] = False

        analysis[str(palace)] = palace_analysis

    wonder_locations = {}
    for p, data in analysis.items():
        if data.get("has_wonder"):
            wonder_locations[data["heaven_name"]] = {
                "palace": int(p),
                "direction": PALACE_DIRECTIONS.get(int(p), ""),
                "stem": data["heaven_stem"],
            }

    return analysis, wonder_locations


# ---------------------------------------------------------------------------
# Palace interpretation
# ---------------------------------------------------------------------------

QUESTION_PALACE_MAP = {
    "career": [6, 1], "love": [4, 9], "health": [8, 2],
    "wealth": [8, 6], "travel": [4, 3], "legal": [7, 6],
    "study": [4, 9], "general": [5, 1],
}


def interpret_palace(palace_num, door, star, deity, earth_stem, heaven_stem, question, sanqi_data=None):
    """Generate interpretation for a palace's combination."""
    interpretations = []

    if door:
        if door["nature"] == "auspicious":
            interpretations.append(f"{door['english']} ({door['chinese']}) in Palace {palace_num}: Favorable energy, opportunities opening")
        elif door["nature"] == "inauspicious":
            interpretations.append(f"{door['english']} ({door['chinese']}) in Palace {palace_num}: Caution needed, obstacles present")
        else:
            interpretations.append(f"{door['english']} ({door['chinese']}) in Palace {palace_num}: Neutral energy, outcome depends on action")

    if star:
        if star["nature"] == "auspicious":
            interpretations.append(f"{star['english']} ({star['chinese']}): Heavenly support, favorable timing")
        elif star["nature"] == "inauspicious":
            interpretations.append(f"{star['english']} ({star['chinese']}): Challenging celestial influence, proceed carefully")

    if deity:
        deity_meanings = {
            "Chief": "Direct authority and leadership energy supports this matter",
            "Serpent": "Hidden complications, things are not as they appear",
            "Moon": "Yin energy, subtle influence, patience and timing matter",
            "Harmony": "Cooperation and partnership energy, seek allies",
            "White Tiger": "Aggressive energy, decisive action needed but risk of conflict",
            "Dark Warrior": "Uncertainty and deception possible, verify information",
            "Nine Earth": "Grounding energy, stability, build from foundation",
            "Nine Heaven": "Expansive energy, aim high, breakthrough possible",
        }
        interpretations.append(f"{deity['english']} ({deity['chinese']}): {deity_meanings.get(deity['role'], 'Influence present')}")

    if sanqi_data:
        if sanqi_data.get("has_wonder"):
            interpretations.append(f"✦ {sanqi_data['heaven_name']} ({sanqi_data['heaven_name_en']}) present — {SANQI_LIUYI[sanqi_data['heaven_stem']]['role']}")
        if "formation" in sanqi_data:
            f = sanqi_data["formation"]
            interpretations.append(f"格局 {f['name']}: {f['meaning']}")
        if "stem_interaction" in sanqi_data:
            interpretations.append(f"Stem dynamics: {sanqi_data['stem_interaction']}")
    elif heaven_stem and earth_stem:
        h_elem = FIVE_ELEMENTS_STEM.get(heaven_stem, "")
        e_elem = FIVE_ELEMENTS_STEM.get(earth_stem, "")
        if h_elem == e_elem:
            interpretations.append(f"Stem harmony ({heaven_stem}/{earth_stem}): Inner and outer aligned")
        elif GENERATES.get(h_elem) == e_elem:
            interpretations.append(f"Heaven generates Earth ({h_elem}→{e_elem}): External forces nurture the foundation")
        elif GENERATES.get(e_elem) == h_elem:
            interpretations.append(f"Earth generates Heaven ({e_elem}→{h_elem}): Inner strength supports outer goals")
        else:
            interpretations.append(f"Stem tension ({heaven_stem}/{earth_stem}): {h_elem} vs {e_elem} — internal conflict to resolve")

    return interpretations


# ---------------------------------------------------------------------------
# Mode-specific interpretations
# ---------------------------------------------------------------------------

def interpret_destiny(palaces, four_pillars, solar_term, dun_type, ju, wonder_locations):
    """Generate life-theme interpretations for destiny mode."""
    themes = []

    day_stem = four_pillars["day"]["stem"]
    day_element = day_stem["element"]
    element_identity = {
        "Wood": "Growth-oriented soul — visionary, compassionate, sometimes inflexible",
        "Fire": "Radiant spirit — passionate, inspiring, prone to burnout",
        "Earth": "Grounding presence — reliable, nurturing, can be overly cautious",
        "Metal": "Sharp mind — decisive, principled, risk of rigidity",
        "Water": "Fluid intelligence — adaptive, deep thinker, sometimes unfocused",
    }
    themes.append({
        "theme": "Core Identity (日主)", "element": day_element,
        "day_master": day_stem["chinese"],
        "reading": element_identity.get(day_element, "Complex elemental nature"),
    })

    if dun_type["chinese"] == "阳遁":
        themes.append({
            "theme": "Life Trajectory (遁法)",
            "pattern": "阳遁 Yang Dun — expansive destiny, life builds outward",
            "advice": "Your path favors bold action and visible growth. Early struggles become late triumphs.",
        })
    else:
        themes.append({
            "theme": "Life Trajectory (遁法)",
            "pattern": "阴遁 Yin Dun — deepening destiny, life builds inward",
            "advice": "Your path favors depth and mastery. Quiet persistence yields profound results.",
        })

    if wonder_locations:
        wonder_readings = []
        for wonder_name, loc in wonder_locations.items():
            wonder_readings.append(f"{wonder_name} in Palace {loc['palace']} ({loc['direction']})")
        themes.append({
            "theme": "三奇 (Three Wonders)", "locations": wonder_locations,
            "reading": "Celestial blessings present: " + "; ".join(wonder_readings),
        })
    else:
        themes.append({
            "theme": "三奇 (Three Wonders)",
            "reading": "No Three Wonders in key positions — success comes through effort rather than luck",
        })

    p6 = palaces.get("6", {})
    if p6.get("door") and p6["door"].get("nature") == "auspicious":
        themes.append({"theme": "Career Destiny (乾宫)", "reading": "Strong authority palace — leadership is in your blueprint"})
    elif p6.get("door") and p6["door"].get("nature") == "inauspicious":
        themes.append({"theme": "Career Destiny (乾宫)", "reading": "Career requires patience — authority comes through earned trust"})

    p9 = palaces.get("9", {})
    if p9.get("star") and p9["star"].get("nature") == "auspicious":
        themes.append({"theme": "Visibility & Fame (离宫)", "reading": "Favorable star in Fire palace — public recognition is part of your destiny"})

    p8 = palaces.get("8", {})
    if p8.get("door"):
        door_name = p8["door"].get("english", "")
        if "Life" in door_name:
            themes.append({"theme": "Wealth Destiny (艮宫)", "reading": "Life Gate in its home palace — natural wealth accumulation"})
        else:
            themes.append({"theme": "Wealth Destiny (艮宫)", "reading": f"{door_name} in wealth palace — wealth comes through {p8['door'].get('nature', 'mixed')} channels"})

    themes.append({
        "theme": "Life Phase Pattern (局数)", "ju_number": ju,
        "reading": f"Ju {ju} blueprint — life resonates with Palace {ju} energy ({PALACE_DIRECTIONS.get(ju, 'Unknown')})",
    })

    return themes


def interpret_realtime(palaces, solar_term, dun_type, wonder_locations):
    """Generate present-moment energy reading for realtime mode."""
    energies = []

    energies.append({
        "aspect": "Cosmic Season (节气)", "term": solar_term["chinese"],
        "term_en": solar_term["english"],
        "reading": f"The cosmos is in {solar_term['english']} ({solar_term['chinese']}) — {dun_type['english']} phase",
    })

    auspicious_zones = []
    caution_zones = []
    for p_num in range(1, 10):
        p = palaces.get(str(p_num), {})
        door = p.get("door")
        star = p.get("star")
        if door and star:
            if door.get("nature") == "auspicious" and star.get("nature") == "auspicious":
                auspicious_zones.append({"palace": p_num, "direction": PALACE_DIRECTIONS.get(p_num, ""), "door": door.get("chinese", ""), "star": star.get("chinese", "")})
            elif door.get("nature") == "inauspicious" and star.get("nature") == "inauspicious":
                caution_zones.append({"palace": p_num, "direction": PALACE_DIRECTIONS.get(p_num, ""), "door": door.get("chinese", ""), "star": star.get("chinese", "")})

    energies.append({"aspect": "Auspicious Zones (吉方)", "zones": auspicious_zones, "advice": "These directions are energetically supported now" if auspicious_zones else "No strongly auspicious combinations — neutral moment"})
    energies.append({"aspect": "Caution Zones (凶方)", "zones": caution_zones, "advice": "Avoid major decisions in these directions" if caution_zones else "No strongly negative combinations — generally safe"})

    if wonder_locations:
        energies.append({"aspect": "三奇 Locations", "locations": wonder_locations, "advice": "Move toward or focus on these palace directions for celestial support"})

    p5 = palaces.get("5", {})
    center_star = p5.get("star", {})
    energies.append({
        "aspect": "Core Energy (中宫)", "center_star": center_star.get("chinese", "天禽"),
        "element": center_star.get("element", "Earth"),
        "reading": "Center holds stable Earth energy — grounded moment" if center_star.get("element") == "Earth" else f"Center resonates with {center_star.get('element', 'mixed')} energy",
    })

    return energies


def interpret_reading(palaces, question, focus_palaces_data, wonder_locations):
    """Generate question-specific divination for reading mode."""
    divination = []

    question_door_focus = {
        "career": ("开门", "Open Gate", "Career questions resonate with the Open Gate — authority and opportunity"),
        "love": ("景门", "Scene Gate", "Love illuminates through the Scene Gate — beauty and attraction"),
        "health": ("生门", "Life Gate", "Health anchors to the Life Gate — vitality and renewal"),
        "wealth": ("生门", "Life Gate", "Wealth follows the Life Gate — growth and accumulation"),
        "travel": ("休门", "Rest Gate", "Travel aligns with the Rest Gate — safe passage"),
        "legal": ("开门", "Open Gate", "Legal questions need the Open Gate — fair judgment"),
        "study": ("杜门", "Block Gate", "Study resonates with the Block Gate — deep focus"),
        "general": ("休门", "Rest Gate", "General questions begin at the Rest Gate — equilibrium"),
    }

    door_cn, door_en, door_reading = question_door_focus.get(question, question_door_focus["general"])
    divination.append({"aspect": "Question Gate (用神)", "gate": door_cn, "gate_en": door_en, "reading": door_reading})

    key_door_palace = None
    for p_num in range(1, 10):
        p = palaces.get(str(p_num), {})
        door = p.get("door")
        if door and door.get("chinese") == door_cn:
            key_door_palace = p_num
            break

    if key_door_palace:
        p_data = palaces[str(key_door_palace)]
        star = p_data.get("star", {})
        deity = p_data.get("deity", {})
        sanqi = p_data.get("sanqi_liuyi", {})

        outcome = "favorable" if star.get("nature") == "auspicious" else ("challenging" if star.get("nature") == "inauspicious" else "uncertain")
        divine_support = "supported" if deity.get("role") in ("Chief", "Nine Heaven", "Harmony") else ("hindered" if deity.get("role") in ("Serpent", "Dark Warrior", "White Tiger") else "neutral")

        answer = {
            "aspect": "Answer Formation (断语)", "key_door_palace": key_door_palace,
            "direction": PALACE_DIRECTIONS.get(key_door_palace, ""),
            "star": star.get("chinese", ""), "deity": deity.get("chinese", ""),
            "outcome_tendency": outcome, "divine_support": divine_support,
            "reading": f"Your key gate ({door_en}) sits in Palace {key_door_palace} ({PALACE_DIRECTIONS.get(key_door_palace, '')}) — outcome: {outcome}, support: {divine_support}",
        }

        if sanqi and sanqi.get("has_wonder"):
            answer["wonder_blessing"] = f"{sanqi['heaven_name']} present — adds celestial favor"
            answer["outcome_tendency"] = "very_favorable" if outcome == "favorable" else "favorable"

        divination.append(answer)

    if focus_palaces_data:
        best_palace = focus_palaces_data[0]
        divination.append({
            "aspect": "Timing & Action (择时)", "primary_palace": best_palace.get("palace", ""),
            "direction": best_palace.get("direction", ""),
            "reading": f"Focus energy toward {best_palace.get('direction', 'the center')} — this is where your answer crystallizes",
        })

    return divination


# ---------------------------------------------------------------------------
# Compute chart
# ---------------------------------------------------------------------------

def compute_chart(datetime_str=None, tz_str="Asia/Kuala_Lumpur", mode="destiny",
                  question="general", question_text=""):
    """Compute a full 阴盘奇门 chart."""
    tz = pytz.timezone(tz_str)

    if datetime_str:
        local_dt = datetime.strptime(datetime_str, "%Y-%m-%d %H:%M")
        local_dt = tz.localize(local_dt)
    elif mode == "destiny":
        return {"error": "destiny mode requires datetime (birth datetime)"}
    else:
        local_dt = datetime.now(tz)

    utc_dt = local_dt.astimezone(pytz.UTC)

    # 1. Solar term
    solar_term, term_dt = find_solar_term_precise(utc_dt)

    # 2. Year boundary
    before_lichun = is_before_lichun(utc_dt)

    # 3. Four pillars
    year_s, year_b = sexagenary_year(local_dt.year, before_lichun)
    month_idx = determine_month_from_solar_terms(utc_dt)
    month_s, month_b = sexagenary_month(local_dt.year, month_idx, before_lichun)
    day_s, day_b, day_cycle_pos = sexagenary_day(local_dt.year, local_dt.month, local_dt.day)
    hour_s, hour_b = sexagenary_hour(day_s, local_dt.hour)

    four_pillars = {
        "year": format_ganzi(year_s, year_b),
        "month": format_ganzi(month_s, month_b),
        "day": format_ganzi(day_s, day_b),
        "hour": format_ganzi(hour_s, hour_b),
    }

    # 4. Yuan (拆补法)
    solar_term_local = term_dt.astimezone(tz) if hasattr(term_dt, 'astimezone') else term_dt
    yuan = determine_yuan(
        day_cycle_pos,
        target_date=local_dt.date() if hasattr(local_dt, 'date') else date(local_dt.year, local_dt.month, local_dt.day),
        solar_term_date=solar_term_local.date() if hasattr(solar_term_local, 'date') else date(solar_term_local.year, solar_term_local.month, solar_term_local.day)
    )

    # 5. Dun type & Ju
    dun_cn, dun_en = determine_dun_type(solar_term["chinese"])

    if mode == "destiny":
        # 阴盘命盘 uses special formula: (年支序+时支序+农历月+农历日) % 9
        destiny_ju = determine_ju_destiny(year_b, hour_b, local_dt.date(), dun_cn)
        if destiny_ju is not None:
            ju = destiny_ju
        else:
            # Fallback to 拆补法 if lunar calendar unavailable
            ju = determine_ju_number(solar_term["chinese"], yuan["number"])
    else:
        ju = determine_ju_number(solar_term["chinese"], yuan["number"])

    # 6. Hour xun info
    xun_info = find_xun_shou(hour_s, hour_b)
    hour_dunjia_stem = xun_info["dunjia_stem"]

    # 7. Effective hour stem (甲 → dunjia substitute)
    hour_stem = get_hour_dunjia_stem(hour_s, hour_b)

    # 8. 空亡 and 马星
    kongwang = get_kongwang(hour_s, hour_b)
    day_branch = EARTHLY_BRANCHES[day_b]
    horse_star_branch = HORSE_STAR_MAP.get(day_branch, "")
    horse_star_palace = BRANCH_TO_PALACE.get(horse_star_branch, 0)

    # 9. Build earth plate
    earth_plate = build_earth_plate(ju, dun_cn)

    # 10. Determine 值符/值使 (based on 旬首 branch palace)
    xun_shou_branch_idx = xun_info["xun_start_pos"] % 12
    zz = get_zhifu_zhishi(ju, dun_cn, hour_dunjia_stem, earth_plate,
                           xun_shou_branch_idx=xun_shou_branch_idx)

    # 11. Find hour stem palace and rotation offset
    hour_stem_palace = find_stem_on_earth(hour_stem, earth_plate)
    if hour_stem_palace is None:
        hour_stem_palace = ju if ju != 5 else 2

    # Rotation offset: from 值符's home (dunjia_palace) to hour stem palace
    rotation_offset = calc_rotation_offset(zz["dunjia_palace"], hour_stem_palace)

    # 12. Build remaining plates
    heaven_plate = build_heaven_plate(earth_plate, rotation_offset)
    star_plate = build_star_plate(rotation_offset, zz["zhifu_home"])
    door_plate = build_door_plate(dun_cn, rotation_offset)
    deity_plate = build_deity_plate(dun_cn, hour_stem_palace)

    # 13. 三奇六仪 analysis
    sanqi_analysis, wonder_locations = analyze_sanqi_liuyi(earth_plate, heaven_plate)

    # 14. Assemble palace data
    palaces = {}
    for p in range(1, 10):
        sanqi_data = sanqi_analysis.get(str(p), {})
        e_stem = earth_plate.get(p, "")
        h_stem = heaven_plate.get(p, "")

        palace_data = {
            "number": p,
            "direction": PALACE_DIRECTIONS[p],
            "trigram": PALACE_TRIGRAMS[p],
            "earth_stem": e_stem,
            "heaven_stem": h_stem,
            "door": door_plate.get(p, None),
            "star": star_plate.get(p, None),
            "deity": deity_plate.get(p, None),
            "sanqi_liuyi": sanqi_data,
        }

        # 乙庚合 display — direct pair or center寄宫 pair
        center_earth = earth_plate.get(5, "")
        center_heaven = heaven_plate.get(5, "")
        if sanqi_data.get("pair_display"):
            palace_data["stem_pair_display"] = sanqi_data["pair_display"]
        else:
            # Center寄宫: when center has 乙 and this palace has 庚 (or vice versa)
            if e_stem == "庚" and center_earth == "乙":
                palace_data["earth_stem_display"] = "庚乙"
            if h_stem == "庚" and center_heaven == "乙":
                palace_data["heaven_stem_display"] = "庚乙"

        # Horse star
        if p == horse_star_palace:
            palace_data["horse_star"] = True

        # 空亡
        for void_branch in kongwang:
            void_palace = BRANCH_TO_PALACE.get(void_branch, 0)
            if p == void_palace:
                palace_data["kongwang"] = True
                palace_data["kongwang_branch"] = void_branch

        palace_data["interpretation"] = interpret_palace(
            p, palace_data["door"], palace_data["star"], palace_data["deity"],
            palace_data["earth_stem"], palace_data["heaven_stem"],
            question, sanqi_data
        )

        palaces[str(p)] = palace_data

    # 15. Focus palaces
    focus_palaces = QUESTION_PALACE_MAP.get(question, [5, 1])
    focus_analysis = []
    for fp in focus_palaces:
        p_data = palaces[str(fp)]
        focus_analysis.append({
            "palace": fp,
            "direction": PALACE_DIRECTIONS[fp],
            "summary": " | ".join(p_data["interpretation"][:2]) if p_data["interpretation"] else "No specific reading",
            "door": p_data["door"]["chinese"] if p_data["door"] else "N/A",
            "star": p_data["star"]["chinese"] if p_data["star"] else "N/A",
            "deity": p_data["deity"]["chinese"] if p_data["deity"] else "N/A",
        })

    # 16. Overall verdict
    auspicious_count = sum(1 for p in palaces.values()
                          if p.get("door") and p["door"].get("nature") == "auspicious"
                          and p.get("star") and p["star"].get("nature") == "auspicious")
    inauspicious_count = sum(1 for p in palaces.values()
                            if p.get("door") and p["door"].get("nature") == "inauspicious"
                            and p.get("star") and p["star"].get("nature") == "inauspicious")

    if auspicious_count > inauspicious_count:
        overall = "Favorable"
    elif inauspicious_count > auspicious_count:
        overall = "Challenging"
    else:
        overall = "Mixed"

    mode_labels = {
        "destiny": {"chinese": "命盘", "english": "Destiny Chart", "description": "Permanent life chart based on birth moment"},
        "realtime": {"chinese": "实时盘", "english": "Realtime Chart", "description": "Present cosmic alignment"},
        "reading": {"chinese": "热卜盘", "english": "Divination Chart", "description": "Dynamic reading for a specific question"},
    }

    result = {
        "system": "阴盘奇门遁甲 Yin Plate Qi Men Dun Jia (长卿)",
        "chart_type": mode,
        "chart_type_label": mode_labels[mode],
        "input_datetime": local_dt.strftime("%Y-%m-%d %H:%M"),
        "timezone": tz_str,
        "utc_datetime": utc_dt.strftime("%Y-%m-%d %H:%M:%S UTC"),
        "question_category": question,
        "solar_term": solar_term,
        "four_pillars": four_pillars,
        "yuan": yuan,
        "dun_type": {"chinese": dun_cn, "english": dun_en},
        "ju_number": ju,
        "xun_shou": xun_info,
        "zhifu": {
            "star": zz["zhifu_star"],
            "star_en": zz["zhifu_star_en"],
            "home_palace": zz["zhifu_home"],
            "current_palace": hour_stem_palace,
        },
        "zhishi": {
            "door": zz["zhishi_door"],
            "door_en": zz["zhishi_door_en"],
            "home_palace": zz["zhishi_home"],
            "current_palace": hour_stem_palace,
        },
        "horse_star": {
            "branch": horse_star_branch,
            "palace": horse_star_palace,
        },
        "kongwang": {
            "branches": list(kongwang),
            "palaces": [BRANCH_TO_PALACE.get(b, 0) for b in kongwang],
        },
        "palaces": palaces,
        "sanqi_liuyi_summary": {
            "wonder_locations": wonder_locations,
            "has_wonders": len(wonder_locations) > 0,
        },
        "focus_palaces": focus_analysis,
        "overall_verdict": overall,
        "plate_layout": {
            "description": "Luoshu: top [4,9,2], mid [3,5,7], bot [8,1,6]",
            "visual": [
                [f"P4:{earth_plate.get(4,'')}/{heaven_plate.get(4,'')}", f"P9:{earth_plate.get(9,'')}/{heaven_plate.get(9,'')}", f"P2:{earth_plate.get(2,'')}/{heaven_plate.get(2,'')}"],
                [f"P3:{earth_plate.get(3,'')}/{heaven_plate.get(3,'')}", f"P5:{earth_plate.get(5,'')}/{heaven_plate.get(5,'')}", f"P7:{earth_plate.get(7,'')}/{heaven_plate.get(7,'')}"],
                [f"P8:{earth_plate.get(8,'')}/{heaven_plate.get(8,'')}", f"P1:{earth_plate.get(1,'')}/{heaven_plate.get(1,'')}", f"P6:{earth_plate.get(6,'')}/{heaven_plate.get(6,'')}"],
            ],
        },
    }

    # Mode-specific interpretation
    if mode == "destiny":
        result["destiny_themes"] = interpret_destiny(palaces, four_pillars, solar_term, result["dun_type"], ju, wonder_locations)
    elif mode == "realtime":
        result["realtime_energies"] = interpret_realtime(palaces, solar_term, result["dun_type"], wonder_locations)
    elif mode == "reading":
        result["divination"] = interpret_reading(palaces, question, focus_analysis, wonder_locations)
        if question_text:
            result["question_text"] = question_text

    return result


def main():
    parser = argparse.ArgumentParser(description="阴盘奇门遁甲 (Yin Plate Qi Men Dun Jia) Calculator — 长卿 School")
    parser.add_argument("--datetime", help="Datetime YYYY-MM-DD HH:MM")
    parser.add_argument("--tz", required=True, help="Timezone e.g. Asia/Kuala_Lumpur")
    parser.add_argument("--question", default="general", help="Question category")
    parser.add_argument("--mode", default="destiny", choices=["destiny", "realtime", "reading"],
                        help="Chart mode: destiny/realtime/reading")
    parser.add_argument("--question-text", default="", help="Free-text question")

    args = parser.parse_args()

    result = compute_chart(
        datetime_str=args.datetime,
        tz_str=args.tz,
        mode=args.mode,
        question=args.question,
        question_text=args.question_text,
    )

    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
