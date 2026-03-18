#!/usr/bin/env python3
"""
奇门遁甲排盘引擎 — Qi Men Dun Jia Chart Engine
Ported from bigfishmarquis-qimen (TypeScript) to Python.
Modified for 阴盘奇门 (Yin Plate) per yrydai.com school (长卿 lineage).

Key characteristics:
  - 局数 via numeric formula: (年支序+时支序+农历月+农历日) % 9
    Confirmed against yrydai.com (2026-03-17 ✅, 2026-03-18 ✅)
    Bypasses 节气/拆补法 entirely for 局数 determination.
    阳遁/阴遁 still follows the solar term.
  - Earth plate: sequential palace numbers (1→2→3...9 for yang, 9→8→7...1 for yin)
  - Heaven plate: stars rotate along PALACE_CLOCKWISE (洛书 clockwise ring)
  - Doors: rotate along PALACE_CLOCKWISE
  - Deities: yang=PALACE_CLOCKWISE, yin=PALACE_COUNTER_CLOCKWISE
  - 天禽寄天芮: center star always follows 天芮
  - 中五宫寄坤二: palace 5 maps to palace 2 for spirits/stars/doors

Reference: https://github.com/perfhelf/bigfishmarquis-qimen
"""

import ephem
import math
import json
import sys
import os
import argparse
from datetime import datetime, date, timedelta
from typing import Optional, Dict, List, Tuple, Any

try:
    import pytz
    HAS_PYTZ = True
except ImportError:
    HAS_PYTZ = False

try:
    from lunardate import LunarDate
    HAS_LUNARDATE = True
except ImportError:
    HAS_LUNARDATE = False


# ===========================================================================
# A. CONSTANTS
# ===========================================================================

# --- 天干地支 (Heavenly Stems & Earthly Branches) ---

STEMS = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸']
BRANCHES = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥']

# --- 六十甲子表 (60 Sexagenary Cycle) ---
JIAZI_TABLE: List[str] = []
for _i in range(60):
    JIAZI_TABLE.append(STEMS[_i % 10] + BRANCHES[_i % 12])

# --- 三奇六仪 (Three Marvels & Six Instruments) ---
# Fixed sequence: 戊己庚辛壬癸丁丙乙
SAN_QI_LIU_YI = ['戊', '己', '庚', '辛', '壬', '癸', '丁', '丙', '乙']

# --- 六甲旬首→遁干 mapping ---
LIUJIA_XUN = {
    '甲子': '戊', '甲戌': '己', '甲申': '庚',
    '甲午': '辛', '甲辰': '壬', '甲寅': '癸',
}

# --- 九宫 (Nine Palaces) ---
PALACE_CONFIG = {
    1: {'name': '坎', 'element': '水'},
    2: {'name': '坤', 'element': '土'},
    3: {'name': '震', 'element': '木'},
    4: {'name': '巽', 'element': '木'},
    5: {'name': '中', 'element': '土'},
    6: {'name': '乾', 'element': '金'},
    7: {'name': '兑', 'element': '金'},
    8: {'name': '艮', 'element': '土'},
    9: {'name': '离', 'element': '火'},
}

PALACE_NAMES = {k: v['name'] for k, v in PALACE_CONFIG.items()}
PALACE_ELEMENTS = {k: v['element'] for k, v in PALACE_CONFIG.items()}

# --- 九星 (Nine Stars) ---
STAR_CONFIG = {
    '天蓬': {'element': '水', 'home': 1},
    '天芮': {'element': '土', 'home': 2},
    '天冲': {'element': '木', 'home': 3},
    '天辅': {'element': '木', 'home': 4},
    '天禽': {'element': '土', 'home': 5},
    '天心': {'element': '金', 'home': 6},
    '天柱': {'element': '金', 'home': 7},
    '天任': {'element': '土', 'home': 8},
    '天英': {'element': '火', 'home': 9},
}

STAR_ELEMENT = {k: v['element'] for k, v in STAR_CONFIG.items()}
STAR_HOME_PALACE = {k: v['home'] for k, v in STAR_CONFIG.items()}

# Palace number → home star
PALACE_TO_STAR = {v: k for k, v in STAR_HOME_PALACE.items()}

# --- 八门 (Eight Gates/Doors) ---
DOOR_CONFIG = {
    '休门': {'element': '水', 'home': 1},
    '死门': {'element': '土', 'home': 2},
    '伤门': {'element': '木', 'home': 3},
    '杜门': {'element': '木', 'home': 4},
    '景门': {'element': '火', 'home': 9},
    '开门': {'element': '金', 'home': 6},
    '惊门': {'element': '金', 'home': 7},
    '生门': {'element': '土', 'home': 8},
}

DOOR_ELEMENT = {k: v['element'] for k, v in DOOR_CONFIG.items()}
DOOR_HOME_PALACE = {k: v['home'] for k, v in DOOR_CONFIG.items()}

# Palace number → home door
PALACE_TO_DOOR = {v: k for k, v in DOOR_HOME_PALACE.items()}
PALACE_TO_DOOR[5] = '死门'  # 中五寄坤二→死门

# --- 八神 (Eight Deities/Spirits) ---
DEITIES = ['值符', '腾蛇', '太阴', '六合', '白虎', '玄武', '九地', '九天']

GOD_SHORT_NAME = {
    '值符': '符', '腾蛇': '蛇', '太阴': '阴', '六合': '合',
    '白虎': '虎', '玄武': '玄', '九地': '地', '九天': '天',
    '螣蛇': '蛇',
}

# --- 地支↔宫位 mapping ---
BRANCH_TO_PALACE = {
    '子': 1, '丑': 8, '寅': 8, '卯': 3, '辰': 4, '巳': 4,
    '午': 9, '未': 2, '申': 2, '酉': 7, '戌': 6, '亥': 6,
}

PALACE_BRANCHES = {
    1: ['子'], 2: ['未', '申'], 3: ['卯'], 4: ['辰', '巳'],
    5: [], 6: ['戌', '亥'], 7: ['酉'], 8: ['丑', '寅'], 9: ['午'],
}

# --- 洛书 orders ---
# 阳遁飞布: 1→8→3→4→9→2→7→6 (洛书 spiral)
YANG_ORDER = [1, 8, 3, 4, 9, 2, 7, 6]
# 阴遁飞布: 1→6→7→2→9→4→3→8
YIN_ORDER = [1, 6, 7, 2, 9, 4, 3, 8]

# 洛书顺时针: 坤2→兑7→乾6→坎1→艮8→震3→巽4→离9
PALACE_CLOCKWISE = [2, 7, 6, 1, 8, 3, 4, 9]
# 洛书逆时针
PALACE_COUNTER_CLOCKWISE = [2, 9, 4, 3, 8, 1, 6, 7]

# --- Star & Gate rotation sequences (from 天心 start) ---
STAR_SEQUENCE = ['天心', '天蓬', '天任', '天冲', '天辅', '天英', '天芮', '天柱']
GATE_SEQUENCE = ['休门', '生门', '伤门', '杜门', '景门', '死门', '惊门', '开门']

# --- 旬首表 (Xun Shou Table) ---
XUN_SHOU_TABLE = [
    {'xun_shou': '甲子', 'liu_yi': '戊', 'palace': 1, 'star': '天蓬', 'door': '休门'},
    {'xun_shou': '甲戌', 'liu_yi': '己', 'palace': 2, 'star': '天芮', 'door': '死门'},
    {'xun_shou': '甲申', 'liu_yi': '庚', 'palace': 3, 'star': '天冲', 'door': '伤门'},
    {'xun_shou': '甲午', 'liu_yi': '辛', 'palace': 4, 'star': '天辅', 'door': '杜门'},
    {'xun_shou': '甲辰', 'liu_yi': '壬', 'palace': 5, 'star': '天禽', 'door': '死门'},  # 天禽寄坤2
    {'xun_shou': '甲寅', 'liu_yi': '癸', 'palace': 6, 'star': '天心', 'door': '开门'},
]

# --- 驿马 (Post Horse) ---
YI_MA_MAP = {
    '申': '寅', '子': '寅', '辰': '寅',
    '巳': '亥', '酉': '亥', '丑': '亥',
    '寅': '申', '午': '申', '戌': '申',
    '亥': '巳', '卯': '巳', '未': '巳',
}

# --- 五行→墓库宫位 (Element → Grave Palace) ---
# 火墓戌→乾6, 水墓辰→巽4, 金墓丑→艮8, 木墓未→坤2, 土墓辰→巽4
GRAVE_MAP = {
    '火': [6], '水': [4], '金': [8], '木': [2], '土': [4],
}

# --- 十二长生墓 (Stem → Grave Palace via 12-phase cycle) ---
STEM_GRAVE = {
    '甲': 2, '乙': 6, '丙': 6, '丁': 8, '戊': 6,
    '己': 8, '庚': 8, '辛': 4, '壬': 4, '癸': 2,
}

# --- 天干五行 (Stem → Element) ---
STEM_WX = {
    '甲': '木', '乙': '木', '丙': '火', '丁': '火', '戊': '土',
    '己': '土', '庚': '金', '辛': '金', '壬': '水', '癸': '水',
}

# --- 洛书九宫格 (Luoshu Grid for display) ---
LUOSHU_GRID = [
    [4, 9, 2],
    [3, 5, 7],
    [8, 1, 6],
]

# --- 节气局数表 ---
# 阳遁 (冬至→芒种): [上元, 中元, 下元]
YANG_DUN_TABLE = {
    '冬至': [1, 7, 4], '惊蛰': [1, 7, 4],
    '小寒': [2, 8, 5],
    '大寒': [3, 9, 6], '春分': [3, 9, 6],
    '立春': [8, 5, 2],
    '雨水': [9, 6, 3],
    '清明': [4, 1, 7], '立夏': [4, 1, 7],
    '谷雨': [5, 2, 8], '小满': [5, 2, 8],
    '芒种': [6, 3, 9],
}

# 阴遁 (夏至→大雪): [上元, 中元, 下元]
YIN_DUN_TABLE = {
    '夏至': [9, 3, 6], '白露': [9, 3, 6],
    '小暑': [8, 2, 5],
    '大暑': [7, 1, 4], '秋分': [7, 1, 4],
    '立秋': [2, 5, 8],
    '处暑': [1, 4, 7],
    '寒露': [6, 9, 3], '立冬': [6, 9, 3],
    '霜降': [5, 8, 2], '小雪': [5, 8, 2],
    '大雪': [4, 7, 1],
}

YANG_DUN_TERMS = set(YANG_DUN_TABLE.keys())

# --- 天干五行颜色 (for grid display) ---
STEM_COLORS = {
    '甲': '\033[32m', '乙': '\033[32m',   # green (wood)
    '丙': '\033[31m', '丁': '\033[31m',   # red (fire)
    '戊': '\033[33m', '己': '\033[33m',   # yellow (earth)
    '庚': '\033[37m', '辛': '\033[37m',   # white (metal)
    '壬': '\033[34m', '癸': '\033[34m',   # blue (water)
}
COLOR_RESET = '\033[0m'
COLOR_RED = '\033[31m'
COLOR_YELLOW = '\033[33m'
COLOR_CYAN = '\033[36m'
COLOR_GREEN = '\033[32m'
COLOR_DIM = '\033[2m'


# ===========================================================================
# B. FIVE ELEMENT INTERACTION FUNCTIONS
# ===========================================================================

def wx_restricts(a: str, b: str) -> bool:
    """五行相克: does element `a` restrict (克) element `b`?"""
    table = {'金': '木', '木': '土', '土': '水', '水': '火', '火': '金'}
    return table.get(a) == b


def wx_generates(a: str, b: str) -> bool:
    """五行相生: does element `a` generate (生) element `b`?"""
    table = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'}
    return table.get(a) == b


def is_yang_dun_term(solar_term: str) -> bool:
    """Check if a solar term is 阳遁 (yang dun)."""
    return solar_term in YANG_DUN_TERMS


# ===========================================================================
# B2. SOLAR TERMS CALCULATOR (PyEphem-based)
# ===========================================================================

SOLAR_TERMS = [
    ("立春", 315), ("雨水", 330), ("惊蛰", 345), ("春分", 0),
    ("清明", 15), ("谷雨", 30), ("立夏", 45), ("小满", 60),
    ("芒种", 75), ("夏至", 90), ("小暑", 105), ("大暑", 120),
    ("立秋", 135), ("处暑", 150), ("白露", 165), ("秋分", 180),
    ("寒露", 195), ("霜降", 210), ("立冬", 225), ("小雪", 240),
    ("大雪", 255), ("冬至", 270), ("小寒", 285), ("大寒", 300),
]

# 12 节 (Jie) solar terms that define month boundaries
MONTH_JIE_TERMS = [
    ("立春", 315, 0), ("惊蛰", 345, 1), ("清明", 15, 2),
    ("立夏", 45, 3), ("芒种", 75, 4), ("小暑", 105, 5),
    ("立秋", 135, 6), ("白露", 165, 7), ("寒露", 195, 8),
    ("立冬", 225, 9), ("大雪", 255, 10), ("小寒", 285, 11),
]


def sun_ecliptic_lon(dt_utc: datetime) -> float:
    """Get Sun's ecliptic longitude at a UTC datetime using PyEphem."""
    s = ephem.Sun()
    s.compute(ephem.Date(dt_utc))
    ecl = ephem.Ecliptic(s, epoch=ephem.Date(dt_utc))
    return math.degrees(float(ecl.lon)) % 360


def find_solar_term(dt_utc: datetime) -> Dict[str, Any]:
    """Find the most recent solar term before the given datetime."""
    sun_lon = sun_ecliptic_lon(dt_utc)
    best_term = None
    best_diff = 999.0

    for cn, lon in SOLAR_TERMS:
        diff = (sun_lon - lon) % 360
        if diff < best_diff:
            best_diff = diff
            best_term = (cn, lon)

    return {
        'chinese': best_term[0],
        'solar_longitude': best_term[1],
        'sun_actual_longitude': round(sun_lon, 4),
        'degrees_past_term': round(best_diff, 4),
    }


def find_solar_term_precise(dt_utc: datetime) -> Tuple[Dict[str, Any], datetime]:
    """Find precise datetime of the most recent solar term using bisection."""
    term_info = find_solar_term(dt_utc)
    target_lon = term_info['solar_longitude']

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


def determine_month_from_solar_terms(dt_utc: datetime) -> int:
    """Determine the Chinese month index using 节气 (Jie) boundaries.
    Returns month_idx: 0=寅月, 1=卯月, ... 11=丑月
    """
    sun_lon = sun_ecliptic_lon(dt_utc)
    best_month = 11
    best_diff = 999.0

    for _, lon, month_idx in MONTH_JIE_TERMS:
        diff = (sun_lon - lon) % 360
        if diff < best_diff:
            best_diff = diff
            best_month = month_idx

    return best_month


# ===========================================================================
# B3. GAN-ZHI CALCULATORS
# ===========================================================================

def gz_index(stem: str, branch: str) -> int:
    """Get 0-59 index in the sexagenary cycle from stem+branch strings."""
    si = STEMS.index(stem) if stem in STEMS else -1
    bi = BRANCHES.index(branch) if branch in BRANCHES else -1
    if si == -1 or bi == -1:
        return -1
    for n in range(60):
        if n % 10 == si and n % 12 == bi:
            return n
    return -1


def gz_from_index(n: int) -> Tuple[str, str]:
    """Get stem+branch strings from a 0-59 index."""
    return STEMS[n % 10], BRANCHES[n % 12]


def year_stem_branch(year: int, before_lichun: bool = False) -> Tuple[int, int]:
    """Compute 天干地支 indices for year. If before 立春, use previous year."""
    y = year - 1 if before_lichun else year
    stem_idx = (y - 4) % 10
    branch_idx = (y - 4) % 12
    return stem_idx, branch_idx


def month_stem_branch(year: int, month_idx: int, before_lichun: bool = False) -> Tuple[int, int]:
    """Compute 天干地支 indices for month.
    month_idx: 0=寅(Feb/Mar), 1=卯(Mar/Apr)...11=丑(Jan/Feb)
    """
    y = year - 1 if before_lichun else year
    year_stem = (y - 4) % 10
    month_stem_base = [2, 4, 6, 8, 0, 2, 4, 6, 8, 0]
    stem_idx = (month_stem_base[year_stem] + month_idx) % 10
    branch_idx = (month_idx + 2) % 12  # 寅=2
    return stem_idx, branch_idx


def day_stem_branch(year: int, month: int, day: int) -> Tuple[int, int, int]:
    """Compute 天干地支 indices for day using the standard epoch.
    Returns (stem_idx, branch_idx, cycle_pos).
    """
    ref = date(1900, 1, 1)
    target = date(year, month, day)
    delta = (target - ref).days
    cycle_pos = (delta + 10) % 60  # Jan 1 1900 = 甲戌 = position 10
    stem_idx = cycle_pos % 10
    branch_idx = cycle_pos % 12
    return stem_idx, branch_idx, cycle_pos


def hour_stem_branch(day_stem_idx: int, hour: int) -> Tuple[int, int]:
    """Compute 天干地支 indices for 时辰 (2-hour period).
    hour: 0-23 clock hour.
    """
    branch_idx = ((hour + 1) % 24) // 2
    hour_stem_base = [0, 2, 4, 6, 8, 0, 2, 4, 6, 8]
    stem_idx = (hour_stem_base[day_stem_idx] + branch_idx) % 10
    return stem_idx, branch_idx


def is_before_lichun(dt_utc: datetime) -> bool:
    """Check if date is before 立春 (Start of Spring) in its year."""
    if dt_utc.month >= 3:
        return False
    if dt_utc.month >= 2 and dt_utc.day > 10:
        return False
    sun_lon = sun_ecliptic_lon(dt_utc)
    return sun_lon < 315 and sun_lon >= 270


# ===========================================================================
# C. CORE ENGINE (ported from shijia.ts)
# ===========================================================================

def layout_earth_plate(ju_number: int, is_yang_dun: bool) -> Dict[int, str]:
    """布地盘 — Layout earth plate with 三奇六仪.

    Earth plate uses sequential palace numbers:
    - 阳遁: N → N+1 → N+2 ... (1→2→3→4→5→6→7→8→9 cycle)
    - 阴遁: N → N-1 → N-2 ... (9→8→7→6→5→4→3→2→1 cycle)
    """
    result = {}
    if is_yang_dun:
        for i, stem in enumerate(SAN_QI_LIU_YI):
            pos = ((ju_number - 1 + i) % 9) + 1
            result[pos] = stem
    else:
        for i, stem in enumerate(SAN_QI_LIU_YI):
            pos = ju_number - i
            while pos < 1:
                pos += 9
            result[pos] = stem
    return result


def find_xun_shou(stem: str, branch: str) -> str:
    """找旬首 — Find the 旬首 (first day of the 10-day cycle) for any 干支 pair."""
    idx = gz_index(stem, branch)
    if idx < 0:
        return '甲子'
    xun_idx = (idx // 10) * 10
    return JIAZI_TABLE[xun_idx]


def get_zhi_fu_info(xun_shou: str, earth_plate: Dict[int, str]) -> Dict[str, Any]:
    """值符信息 — Find the 值符 star and its position on the earth plate.

    The 值符 star is the star at the palace where the 旬首's 六仪 (dun stem)
    sits on the earth plate.
    """
    zhi_fu_stem = LIUJIA_XUN.get(xun_shou, '戊')
    position = 5  # default to center
    for pos, stem in earth_plate.items():
        if stem == zhi_fu_stem:
            position = pos
            break

    # Find the star at this home palace position
    star = PALACE_TO_STAR.get(position, '天禽')
    return {'star': star, 'position': position, 'stem': zhi_fu_stem}


def get_zhi_fu_luo_gong(shi_gan_zhi: str, xun_shou: str, earth_plate: Dict[int, str]) -> Dict[str, Any]:
    """值符落宫 — Where the 值符 star lands (based on 时干 position on earth plate).

    If 时干 is 甲, substitute with the 旬首's 六仪.
    """
    time_stem_raw = shi_gan_zhi[0]
    actual_time_stem = LIUJIA_XUN.get(xun_shou, '戊') if time_stem_raw == '甲' else time_stem_raw

    raw_position = 5
    for pos, stem in earth_plate.items():
        if stem == actual_time_stem:
            raw_position = pos
            break

    # 中五宫寄坤二
    position = 2 if raw_position == 5 else raw_position
    return {'position': position, 'raw_position': raw_position, 'time_stem': actual_time_stem}


def get_zhi_shi_info(shi_gan_zhi: str, zhi_fu_gong: int, is_yang_dun: bool) -> Dict[str, Any]:
    """值使门信息 — Calculate the 值使 gate position using step counting.

    Core door-flying algorithm:
    1. 值使门 = gate at the 值符's home palace
    2. Count steps from 旬首地支 to 时支
    3. Step from 值符's ORIGINAL palace (not mapped), yang=+1, yin=-1
    4. If lands on palace 5, map to 2
    """
    # 值使门 = 值符本位宫对应的门 (中5宫→寄2=死门)
    actual_zhi_fu_gong = 2 if zhi_fu_gong == 5 else zhi_fu_gong
    zhi_shi_men = PALACE_TO_DOOR.get(actual_zhi_fu_gong, '休门')

    xun_shou = find_xun_shou(shi_gan_zhi[0], shi_gan_zhi[1])
    xun_branch = xun_shou[1]
    shi_branch = shi_gan_zhi[1]
    xun_branch_idx = BRANCHES.index(xun_branch)
    shi_branch_idx = BRANCHES.index(shi_branch)
    steps = (shi_branch_idx - xun_branch_idx + 12) % 12

    # Step from 值符's ORIGINAL palace (including palace 5)
    position = zhi_fu_gong
    for _ in range(steps):
        if is_yang_dun:
            position += 1
            if position > 9:
                position = 1
        else:
            position -= 1
            if position < 1:
                position = 9

    # 步进后若落在中5宫, 映射到坤2
    if position == 5:
        position = 2

    return {'gate': zhi_shi_men, 'position': position}


def arrange_tian_pan(zhi_fu_star: str, zhi_fu_luo_gong: int,
                     earth_plate: Dict[int, str]) -> Dict[int, Dict[str, str]]:
    """天盘九星 — Arrange heaven plate stars along PALACE_CLOCKWISE.

    The 值符 star lands at zhi_fu_luo_gong. Other stars follow in
    STAR_SEQUENCE order along PALACE_CLOCKWISE.

    天禽 always follows 天芮. If 值符 is 天禽, treat as 天芮.
    """
    tian_pan = {}

    # 天禽寄天芮
    effective_star = '天芮' if zhi_fu_star == '天禽' else zhi_fu_star
    zhi_fu_idx = STAR_SEQUENCE.index(effective_star) if effective_star in STAR_SEQUENCE else 0
    luo_gong = 2 if zhi_fu_luo_gong == 5 else zhi_fu_luo_gong
    start_idx = PALACE_CLOCKWISE.index(luo_gong) if luo_gong in PALACE_CLOCKWISE else 0

    for i in range(8):
        palace = PALACE_CLOCKWISE[(start_idx + i) % 8]
        star = STAR_SEQUENCE[(zhi_fu_idx + i) % 8]
        # Carry the earth plate stem from the star's home palace
        origin_palace = STAR_HOME_PALACE[star]
        stem = earth_plate.get(origin_palace, '')
        tian_pan[palace] = {'star': star, 'tian_stem': stem}

    # Palace 5: 天禽 always sits here, carries palace 5's earth stem
    tian_pan[5] = {'star': '天禽', 'tian_stem': earth_plate.get(5, '')}

    return tian_pan


def arrange_gates(zhi_shi_gong: int, zhi_shi_gate: str) -> Dict[int, str]:
    """八门 — Arrange gates along PALACE_CLOCKWISE from 值使门 position."""
    gates = {}
    start_gong = 2 if zhi_shi_gong == 5 else zhi_shi_gong
    start_idx = PALACE_CLOCKWISE.index(start_gong) if start_gong in PALACE_CLOCKWISE else 0
    gate_idx = GATE_SEQUENCE.index(zhi_shi_gate) if zhi_shi_gate in GATE_SEQUENCE else 0

    for i in range(8):
        palace = PALACE_CLOCKWISE[(start_idx + i) % 8]
        gate = GATE_SEQUENCE[(gate_idx + i) % 8]
        gates[palace] = gate

    return gates


def arrange_deities(zhi_fu_luo_gong: int, is_yang_dun: bool) -> Dict[int, str]:
    """八神 — Arrange deities. 阳遁 uses clockwise, 阴遁 uses counter-clockwise."""
    deities_map = {}
    seq = PALACE_CLOCKWISE if is_yang_dun else PALACE_COUNTER_CLOCKWISE
    luo_gong = 2 if zhi_fu_luo_gong == 5 else zhi_fu_luo_gong
    start_idx = seq.index(luo_gong) if luo_gong in seq else 0

    for i, shen in enumerate(DEITIES):
        palace = seq[(start_idx + i) % 8]
        deities_map[palace] = shen

    return deities_map


def get_kong_wang(stem: str, branch: str) -> List[str]:
    """空亡 — Calculate the two void branches for a stem-branch pair."""
    si = STEMS.index(stem) if stem in STEMS else -1
    bi = BRANCHES.index(branch) if branch in BRANCHES else -1
    if si == -1 or bi == -1:
        return []

    xun_start_branch = (bi - si + 12) % 12
    kong1 = BRANCHES[(xun_start_branch + 10) % 12]
    kong2 = BRANCHES[(xun_start_branch + 11) % 12]
    return [kong1, kong2]


def get_yi_ma(hour_branch: str) -> str:
    """驿马 — Get post horse branch from hour branch."""
    return YI_MA_MAP.get(hour_branch, '')


# ===========================================================================
# C2. MAIN SHIJIA GENERATION FUNCTION
# ===========================================================================

def shijia_generate(
    hour_stem: str,
    hour_branch: str,
    ju_number: int,
    is_yang_dun: bool,
    four_pillars: Dict[str, Dict[str, str]],
    solar_term: str = '',
    yuan: str = '',
) -> Dict[str, Any]:
    """时家奇门排盘主函数 — Generate a complete Shi Jia QMDJ chart.

    Args:
        hour_stem: 时干
        hour_branch: 时支
        ju_number: 局数 (1-9)
        is_yang_dun: True for 阳遁, False for 阴遁
        four_pillars: {'year': {'gan': X, 'zhi': Y}, 'month': ..., 'day': ..., 'hour': ...}
        solar_term: 节气 name
        yuan: 上/中/下

    Returns: Complete chart dict with all palace data.
    """
    shi_gan_zhi = hour_stem + hour_branch

    # --- STEP 1: 地盘 (Earth Plate) ---
    earth_plate = layout_earth_plate(ju_number, is_yang_dun)

    # --- STEP 2: 旬首 + 值符 ---
    xun_shou = find_xun_shou(hour_stem, hour_branch)
    zhi_fu_info = get_zhi_fu_info(xun_shou, earth_plate)
    zhi_fu_luo_gong = get_zhi_fu_luo_gong(shi_gan_zhi, xun_shou, earth_plate)

    # --- STEP 3: 值使门 ---
    zhi_shi_info = get_zhi_shi_info(shi_gan_zhi, zhi_fu_info['position'], is_yang_dun)

    # --- STEP 4: 天盘九星 (Heaven Plate Stars) ---
    tian_pan = arrange_tian_pan(zhi_fu_info['star'], zhi_fu_luo_gong['position'], earth_plate)

    # --- STEP 5: 八门 (Gates) ---
    gates = arrange_gates(zhi_shi_info['position'], zhi_shi_info['gate'])

    # --- STEP 6: 八神 (Deities) ---
    gods = arrange_deities(zhi_fu_luo_gong['position'], is_yang_dun)

    # --- STEP 7: 空亡 ---
    kong_wang = get_kong_wang(hour_stem, hour_branch)

    # --- STEP 8: 暗干支 (Hidden Stems — door carries its home palace's earth stem) ---
    xun_branch_offset = BRANCHES.index(xun_shou[1])

    def get_dark_branch(stem: str) -> str:
        idx = STEMS.index(stem) if stem in STEMS else -1
        return BRANCHES[(xun_branch_offset + idx) % 12] if idx >= 0 else ''

    # --- STEP 9: 驿马 ---
    yi_ma_branch = get_yi_ma(hour_branch)
    post_horse_palace = BRANCH_TO_PALACE.get(yi_ma_branch, 0) if yi_ma_branch else 0

    # --- STEP 10: 寄宫 (天禽寄天芮) ---
    ji_gong_target_palace = 0
    ji_gan_stem_value = earth_plate.get(5, '')
    for palace, info in tian_pan.items():
        if info['star'] == '天芮' and palace != 5:
            ji_gong_target_palace = palace
            break

    # --- STEP 11: Build palace data ---
    palaces = []
    for i in range(1, 10):
        is_center = (i == 5)
        di_stem = earth_plate.get(i, '')          # 地盘干
        t_info = tian_pan.get(i)
        tian_stem = t_info['tian_stem'] if t_info else ''  # 天盘干
        star = t_info['star'] if t_info else ('天禽' if is_center else '')
        door = '' if is_center else gates.get(i, '')
        god = '' if is_center else gods.get(i, '')

        # Hidden stems: door → door's home palace → earth plate stem
        hidden_stems = []
        if is_center:
            dark_stem = di_stem
            if dark_stem:
                hidden_stems = [dark_stem, get_dark_branch(dark_stem)]
        elif door:
            original_palace = DOOR_HOME_PALACE.get(door)
            if original_palace:
                dark_stem = earth_plate.get(original_palace, '')
                if dark_stem:
                    hidden_stems = [dark_stem, get_dark_branch(dark_stem)]

        # --- Marks ---
        marks = []
        palace_branches = PALACE_BRANCHES.get(i, [])

        # 空 (空亡): palace branches intersect kong_wang
        if any(b in kong_wang for b in palace_branches):
            marks.append('空')

        # 马 (马星): palace == post_horse_palace
        if i == post_horse_palace:
            marks.append('马')

        # 迫 (门迫): door element restricts palace element
        d_elem = DOOR_ELEMENT.get(door, '')
        p_elem = PALACE_ELEMENTS.get(i, '')
        if d_elem and p_elem and d_elem != p_elem and wx_restricts(d_elem, p_elem):
            marks.append('迫')

        # 刑 (击刑): checks HEAVEN plate stem (tian_stem)
        if not is_center and tian_stem:
            if ((tian_stem == '戊' and i == 3) or
                (tian_stem == '己' and i == 2) or
                (tian_stem == '庚' and i == 8) or
                (tian_stem == '辛' and i == 9) or
                (tian_stem == '壬' and i == 4) or
                (tian_stem == '癸' and i == 4)):
                marks.append('刑')

        # 墓 (入墓): dual mechanism
        has_mu = False
        if not is_center and tian_stem:
            # Mechanism 1: 五行墓 (element → grave palace)
            s_elem = STEM_WX.get(tian_stem, '')
            if s_elem and i in GRAVE_MAP.get(s_elem, []):
                marks.append('墓')
                has_mu = True

        # Mechanism 2: 十二长生墓 (stem → grave palace)
        if not has_mu and not is_center and tian_stem:
            if STEM_GRAVE.get(tian_stem) == i:
                marks.append('墓')

        # --- 寄宫干的墓/刑 (天禽携来的干) ---
        ji_stem = ''
        if ji_gong_target_palace and i == ji_gong_target_palace and not is_center:
            ji_stem = ji_gan_stem_value

        ji_marks = []
        if ji_stem:
            # 寄宫干击刑
            if ((ji_stem == '戊' and i == 3) or (ji_stem == '己' and i == 2) or
                (ji_stem == '庚' and i == 8) or (ji_stem == '辛' and i == 9) or
                (ji_stem == '壬' and i == 4) or (ji_stem == '癸' and i == 4)):
                ji_marks.append('刑')
            # 寄宫干入墓
            ji_wx = STEM_WX.get(ji_stem, '')
            if ji_wx and i in GRAVE_MAP.get(ji_wx, []):
                ji_marks.append('墓')
            elif STEM_GRAVE.get(ji_stem) == i:
                ji_marks.append('墓')

        palace_data = {
            'palace_number': i,
            'palace_name': PALACE_NAMES.get(i, ''),
            'palace_element': PALACE_ELEMENTS.get(i, ''),
            'tian_stem': '' if is_center else tian_stem,  # 天盘干
            'di_stem': di_stem,                           # 地盘干
            'hidden_stems': hidden_stems,
            'star': star,
            'star_element': STAR_ELEMENT.get(star, ''),
            'door': door,
            'door_element': DOOR_ELEMENT.get(door, ''),
            'god': god,
            'god_short': GOD_SHORT_NAME.get(god, ''),
            'marks': marks,
            'ji_marks': ji_marks if ji_marks else None,
            'ji_gan_stem': ji_gan_stem_value if (ji_gong_target_palace and i == ji_gong_target_palace and not is_center) else None,
        }
        palaces.append(palace_data)

    dun_str = 'yang' if is_yang_dun else 'yin'

    return {
        'palaces': palaces,
        'zhi_fu_star': zhi_fu_info['star'],
        'zhi_shi_door': zhi_shi_info['gate'],
        'zhi_fu_palace': zhi_fu_luo_gong['position'],
        'zhi_shi_palace': zhi_shi_info['position'],
        'dun': dun_str,
        'ju_number': ju_number,
        'yuan': yuan,
        'type': 'shijia',
        'kong_wang': kong_wang,
        'solar_term': solar_term,
        'xun_shou': xun_shou,
        'four_pillars': four_pillars,
    }


# ===========================================================================
# D. 拆补法取局 (Chai Bu Ju Method)
# ===========================================================================

def get_yuan_from_branch(branch: str) -> int:
    """Standard 符头 branch → 三元 mapping (阳盘/standard QMDJ).
    子午卯酉 → 上元 (0), 寅申巳亥 → 中元 (1), 辰戌丑未 → 下元 (2)
    """
    shang = {'子', '午', '卯', '酉'}
    zhong = {'寅', '申', '巳', '亥'}
    if branch in shang:
        return 0
    if branch in zhong:
        return 1
    return 2


# --- 阴盘 旬首三合法 (Yin Plate 三合-based yuan mapping) ---
# Based on 三合 (Triple Harmony) grouping of the 6 旬首:
#   水局三合 (申子辰): center 子→中, wings 申辰→上
#   火局三合 (寅午戌): center 午→中, wings 寅戌→下
# Validated against yrydai.com (热卜阴盘奇门) for 3 dates across 2 solar terms.
YINPAN_XUN_YUAN = {
    '甲子': 1,  # 中元 — 水局 center (子)
    '甲戌': 2,  # 下元 — 火局 wing (戌)
    '甲申': 0,  # 上元 — 水局 wing (申)
    '甲午': 1,  # 中元 — 火局 center (午)
    '甲辰': 0,  # 上元 — 水局 wing (辰)
    '甲寅': 2,  # 下元 — 火局 wing (寅)
}


def find_xun_shou_by_idx(stem_idx: int, branch_idx: int) -> str:
    """Find the 旬首 by stem/branch indices (for 三元 determination).

    Returns the 旬首 as a 2-char string like '甲申'.
    """
    # Find position in 60 jiazi
    pos = -1
    for n in range(60):
        if n % 10 == stem_idx and n % 12 == branch_idx:
            pos = n
            break
    xun_start = (pos // 10) * 10
    return JIAZI_TABLE[xun_start]


def find_fu_tou(day_stem_idx: int, day_branch_idx: int) -> Dict[str, Any]:
    """找符头 — Find the nearest 甲/己 day (符头) going backwards.

    符头 = the day whose 天干 is 甲(0) or 己(5).
    """
    stem_offset = day_stem_idx % 5  # distance to nearest 甲 or 己
    branch_idx = ((day_branch_idx - stem_offset) % 12 + 12) % 12
    return {'offset': stem_offset, 'branch': BRANCHES[branch_idx]}


def chai_bu_ju(solar_term: str, day_stem_idx: int, day_branch_idx: int,
               hour: Optional[int] = None,
               method: str = 'yinpan') -> Dict[str, Any]:
    """拆补法取局 — Determine ju_number using the Chai Bu method.

    Args:
        solar_term: Current solar term name (e.g. '惊蛰')
        day_stem_idx: Day stem index (0-9, 甲=0...癸=9)
        day_branch_idx: Day branch index (0-11, 子=0...亥=11)
        hour: Current hour (0-23), for 23:00 day-change handling
        method: 'yinpan' (阴盘 旬首三合法, default) or 'standard' (符头 branch法)

    Returns: dict with is_yang_dun, ju_number, yuan
    """
    effective_stem_idx = day_stem_idx
    effective_branch_idx = day_branch_idx

    # 23:00+ day change: push day forward by one
    if hour is not None and hour >= 23:
        effective_stem_idx = (day_stem_idx + 1) % 10
        effective_branch_idx = (day_branch_idx + 1) % 12

    # Determine 三元
    if method == 'yinpan':
        # 阴盘: use 旬首 (甲 day) with 三合-based yuan mapping
        xun_shou = find_xun_shou_by_idx(effective_stem_idx, effective_branch_idx)
        yuan_idx = YINPAN_XUN_YUAN[xun_shou]
    else:
        # Standard: use 符头 (甲/己 day) branch
        fu_tou = find_fu_tou(effective_stem_idx, effective_branch_idx)
        yuan_idx = get_yuan_from_branch(fu_tou['branch'])

    yuan_names = ['上', '中', '下']
    yuan = yuan_names[yuan_idx]

    # Look up 局数 from solar term table
    is_yang_dun = is_yang_dun_term(solar_term)
    table = YANG_DUN_TABLE.get(solar_term) if is_yang_dun else YIN_DUN_TABLE.get(solar_term)

    if not table:
        return {'is_yang_dun': True, 'ju_number': 1, 'yuan': '上'}

    ju_number = table[yuan_idx]
    return {'is_yang_dun': is_yang_dun, 'ju_number': ju_number, 'yuan': yuan}


def yinpan_numeric_ju(year_branch_idx: int, hour_branch_idx: int,
                      solar_date: date, solar_term: str) -> Dict[str, Any]:
    """阴盘奇门 numeric formula for 局数 determination.

    Formula (documented on Baidu Baike / Zhihu for 阴盘奇门):
        局数 = (年支序 + 时支序 + 农历月 + 农历日) % 9
        If result == 0, use 9.
        年支序/时支序: 子=1, 丑=2, ..., 亥=12

    This bypasses 节气/拆补法 entirely — the 局数 comes directly from
    the formula, NOT from the solar term table + yuan lookup.

    The dun type (阳/阴) still follows the solar term.
    """
    if not HAS_LUNARDATE:
        raise RuntimeError("lunardate package required for yinpan_numeric method. "
                           "Install: pip3 install lunardate")

    ld = LunarDate.fromSolarDate(solar_date.year, solar_date.month, solar_date.day)
    year_seq = year_branch_idx + 1   # 子=0→1, ..., 亥=11→12
    hour_seq = hour_branch_idx + 1

    result = (year_seq + hour_seq + ld.month + ld.day) % 9
    if result == 0:
        result = 9

    is_yang_dun = is_yang_dun_term(solar_term)
    return {
        'is_yang_dun': is_yang_dun,
        'ju_number': result,
        'yuan': f'数({year_seq}+{hour_seq}+{ld.month}+{ld.day})',
        'lunar_month': ld.month,
        'lunar_day': ld.day,
    }


# ===========================================================================
# E. HIGH-LEVEL API
# ===========================================================================

def generate_chart(dt: Optional[datetime] = None,
                   longitude: Optional[float] = None,
                   method: str = 'chaibu') -> Dict[str, Any]:
    """Generate a complete QMDJ chart for a given datetime.

    Args:
        dt: datetime (default: now). Should be timezone-aware.
            If naive, assumed to be UTC+8 (Malaysia/China time).
        longitude: for true solar time adjustment (not yet implemented)
        method: 'chaibu' (default, uses 阴盘 旬首三合法), 'chaibu_standard'
                (standard 符头法), 'maoshan', or 'zhirun'

    Returns: dict with full chart data including four pillars, solar term, etc.
    """
    # --- Handle datetime ---
    if dt is None:
        if HAS_PYTZ:
            myt = pytz.timezone('Asia/Kuala_Lumpur')
            dt = datetime.now(myt)
        else:
            dt = datetime.utcnow() + timedelta(hours=8)

    # Convert to UTC for astronomical calculations
    if dt.tzinfo is not None:
        dt_utc = dt - dt.utcoffset()
        dt_utc = dt_utc.replace(tzinfo=None)
        # Local time for Gan-Zhi
        dt_local = dt.replace(tzinfo=None)
    else:
        # Assume UTC+8
        dt_utc = dt - timedelta(hours=8)
        dt_local = dt

    local_hour = dt_local.hour
    local_year = dt_local.year
    local_month = dt_local.month
    local_day = dt_local.day

    # --- Solar term ---
    term_info = find_solar_term(dt_utc)
    solar_term_cn = term_info['chinese']

    # --- Four Pillars ---
    before_lc = is_before_lichun(dt_utc)
    y_si, y_bi = year_stem_branch(local_year, before_lc)
    month_idx = determine_month_from_solar_terms(dt_utc)
    m_si, m_bi = month_stem_branch(local_year, month_idx, before_lc)
    d_si, d_bi, d_pos = day_stem_branch(local_year, local_month, local_day)
    h_si, h_bi = hour_stem_branch(d_si, local_hour)

    four_pillars = {
        'year': {'gan': STEMS[y_si], 'zhi': BRANCHES[y_bi]},
        'month': {'gan': STEMS[m_si], 'zhi': BRANCHES[m_bi]},
        'day': {'gan': STEMS[d_si], 'zhi': BRANCHES[d_bi]},
        'hour': {'gan': STEMS[h_si], 'zhi': BRANCHES[h_bi]},
    }

    # --- Determine 局数 ---
    if method == 'yinpan_numeric' or method == 'chaibu':
        # 阴盘奇门: numeric formula (confirmed vs yrydai.com 2026-03-18)
        # 局数 = (年支序 + 时支序 + 农历月 + 农历日) % 9
        ju_result = yinpan_numeric_ju(
            y_bi, h_bi,
            date(local_year, local_month, local_day),
            solar_term_cn,
        )
    elif method == 'chaibu_standard':
        ju_result = chai_bu_ju(solar_term_cn, d_si, d_bi, local_hour, method='standard')
    elif method == 'chaibu_xunsan':
        # Old method (旬首三合法) — DISPROVEN, kept for comparison
        ju_result = chai_bu_ju(solar_term_cn, d_si, d_bi, local_hour, method='yinpan')
    elif method == 'maoshan':
        # Maoshan: calculate elapsed hours since solar term
        _, term_dt = find_solar_term_precise(dt_utc)
        elapsed_hours = (dt_utc - term_dt).total_seconds() / 3600
        elapsed_shichen = int(elapsed_hours / 2)
        if elapsed_shichen < 60:
            yuan_idx = 0
        elif elapsed_shichen < 120:
            yuan_idx = 1
        else:
            yuan_idx = 2
        yuan_names_m = ['上', '中', '下']
        is_yang = is_yang_dun_term(solar_term_cn)
        tbl = YANG_DUN_TABLE.get(solar_term_cn) if is_yang else YIN_DUN_TABLE.get(solar_term_cn)
        ju_result = {
            'is_yang_dun': is_yang,
            'ju_number': tbl[yuan_idx] if tbl else 1,
            'yuan': yuan_names_m[yuan_idx],
        }
    else:
        # Default to chaibu
        ju_result = chai_bu_ju(solar_term_cn, d_si, d_bi, local_hour)

    is_yang_dun = ju_result['is_yang_dun']
    ju_number = ju_result['ju_number']
    yuan = ju_result['yuan']

    # --- Generate chart ---
    chart = shijia_generate(
        hour_stem=STEMS[h_si],
        hour_branch=BRANCHES[h_bi],
        ju_number=ju_number,
        is_yang_dun=is_yang_dun,
        four_pillars=four_pillars,
        solar_term=solar_term_cn,
        yuan=yuan,
    )

    # Add metadata
    chart['datetime'] = dt_local.strftime('%Y-%m-%d %H:%M')
    chart['method'] = method
    chart['dun_cn'] = '阳遁' if is_yang_dun else '阴遁'

    return chart


# ===========================================================================
# F. CLI INTERFACE & DISPLAY
# ===========================================================================

def format_four_pillars(fp: Dict) -> str:
    """Format four pillars as a single line."""
    parts = []
    for key in ['year', 'month', 'day', 'hour']:
        p = fp[key]
        parts.append(f"{p['gan']}{p['zhi']}")
    return '  '.join(parts)


def render_grid(chart: Dict[str, Any], use_color: bool = True) -> str:
    """Render the chart as a 3x3 洛书 grid for terminal display.

    Layout matches traditional QMDJ display:
        巽4  离9  坤2
        震3  中5  兑7
        艮8  坎1  乾6
    """
    palaces_by_num = {}
    for p in chart['palaces']:
        palaces_by_num[p['palace_number']] = p

    def c(color_code: str, text: str) -> str:
        if not use_color:
            return text
        return f"{color_code}{text}{COLOR_RESET}"

    col_w = 12  # column width

    def pad(s: str, w: int) -> str:
        """Pad string to width, accounting for double-width CJK characters."""
        visual_len = 0
        for ch in s:
            if '\u4e00' <= ch <= '\u9fff' or '\u3000' <= ch <= '\u303f':
                visual_len += 2
            else:
                visual_len += 1
        padding = w - visual_len
        if padding > 0:
            return s + ' ' * padding
        return s

    def pad_c(raw: str, display: str, w: int) -> str:
        """Pad a colored string. raw=without ANSI, display=with ANSI."""
        visual_len = 0
        for ch in raw:
            if '\u4e00' <= ch <= '\u9fff' or '\u3000' <= ch <= '\u303f':
                visual_len += 2
            else:
                visual_len += 1
        padding = w - visual_len
        if padding > 0:
            return display + ' ' * padding
        return display

    def render_palace(num: int) -> List[str]:
        """Render a single palace as 4 lines."""
        p = palaces_by_num[num]
        lines = []

        # Line 1: Palace name + number + element
        name = p['palace_name']
        elem = p['palace_element']
        header = f"{name}{num} {elem}"
        lines.append(header)

        # Line 2: God short name + marks
        god_short = p.get('god_short', '')
        marks_str = ''
        marks = p.get('marks', [])
        if marks:
            marks_str = ' '.join(marks)
        ji_marks = p.get('ji_marks') or []
        # Combine marks display
        mark_parts = []
        if god_short:
            mark_parts.append(god_short)
        if marks_str:
            mark_parts.append(marks_str)
        lines.append(' '.join(mark_parts) if mark_parts else '')

        # Line 3: Tian stem + Di stem (+ ji_gan if present)
        tian = p.get('tian_stem', '')
        di = p.get('di_stem', '')
        ji_gan = p.get('ji_gan_stem')
        stem_parts = []
        if tian:
            stem_parts.append(tian)
        if di:
            stem_parts.append(di)
        if ji_gan:
            stem_parts.append(ji_gan)
        lines.append('  '.join(stem_parts))

        # Line 4: Star + Door
        star = p.get('star', '')
        door = p.get('door', '')
        if star and door:
            lines.append(f"{star} {door}")
        elif star:
            lines.append(star)
        else:
            lines.append('')

        return lines

    # Build grid
    grid_order = LUOSHU_GRID  # [[4,9,2], [3,5,7], [8,1,6]]
    output_lines = []

    # Top border
    output_lines.append('┌' + '─' * col_w + '┬' + '─' * col_w + '┬' + '─' * col_w + '┐')

    for row_idx, row in enumerate(grid_order):
        palace_lines = [render_palace(num) for num in row]

        # Each palace has 4 lines
        for line_idx in range(4):
            parts = []
            for col_idx in range(3):
                cell = palace_lines[col_idx][line_idx] if line_idx < len(palace_lines[col_idx]) else ''
                parts.append(pad(cell, col_w))
            output_lines.append('│' + '│'.join(parts) + '│')

        # Row separator or bottom border
        if row_idx < 2:
            output_lines.append('├' + '─' * col_w + '┼' + '─' * col_w + '┼' + '─' * col_w + '┤')
        else:
            output_lines.append('└' + '─' * col_w + '┴' + '─' * col_w + '┴' + '─' * col_w + '┘')

    return '\n'.join(output_lines)


def render_summary(chart: Dict[str, Any]) -> str:
    """Render a text summary of the chart."""
    lines = []
    dun_cn = chart.get('dun_cn', '阳遁' if chart['dun'] == 'yang' else '阴遁')
    lines.append(f"{'=' * 50}")
    lines.append(f"奇门遁甲排盘 — {chart.get('datetime', '')}")
    lines.append(f"{'=' * 50}")
    lines.append(f"  {dun_cn}{chart['ju_number']}局  {chart.get('yuan', '')}元  "
                 f"节气: {chart.get('solar_term', '')}")
    lines.append(f"  四柱: {format_four_pillars(chart['four_pillars'])}")
    lines.append(f"  旬首: {chart.get('xun_shou', '')}  "
                 f"值符: {chart['zhi_fu_star']}(宫{chart['zhi_fu_palace']})  "
                 f"值使: {chart['zhi_shi_door']}(宫{chart['zhi_shi_palace']})")
    lines.append(f"  空亡: {' '.join(chart.get('kong_wang', []))}")
    lines.append(f"  取局法: {chart.get('method', 'chaibu')}")
    lines.append('')
    return '\n'.join(lines)


def _run_validation_interactive():
    """Interactive validation: show test dates, user types app result."""
    if not HAS_PYTZ:
        print("ERROR: pytz required for validation mode")
        return

    myt = pytz.timezone('Asia/Kuala_Lumpur')

    # 8 diverse test dates covering yang+yin dun, all 3 yuan, various 节气
    test_dates = [
        '2026-03-18 14:00',  # today
        '2026-03-06 10:00',  # recent, 惊蛰
        '2026-03-01 10:00',  # 雨水
        '2026-04-05 10:00',  # 清明
        '2026-03-21 10:00',  # 春分
        '2025-12-07 14:00',  # 大雪 (阴遁)
        '2025-10-08 14:00',  # 寒露 (阴遁)
        '2025-10-23 14:00',  # 霜降 (阴遁)
    ]

    pass_count = 0
    fail_count = 0
    skip_count = 0

    for dt_str in test_dates:
        dt = myt.localize(datetime.strptime(dt_str, '%Y-%m-%d %H:%M'))
        chart = generate_chart(dt=dt, method='chaibu')
        dun = '阳遁' if chart['dun'] == 'yang' else '阴遁'
        ju = chart['ju_number']
        term = chart.get('solar_term', '')
        yuan = chart.get('yuan', '')
        fp = chart['four_pillars']
        day_gz = fp['day']['gan'] + fp['day']['zhi']
        hour_gz = fp['hour']['gan'] + fp['hour']['zhi']

        print(f"  Date: {dt_str}  (日{day_gz} 时{hour_gz})")
        print(f"  节气: {term}  Engine: {dun}{ju}局 ({yuan}元)")

        try:
            answer = input(f"  App shows 局数 = ? (1-9, Enter=skip, q=quit): ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n\nAborted.")
            break

        if answer.lower() == 'q':
            break
        elif answer == '':
            skip_count += 1
            print(f"  → Skipped\n")
            continue
        else:
            try:
                app_ju = int(answer)
                if app_ju == ju:
                    pass_count += 1
                    print(f"  → ✅ MATCH ({dun}{ju}局)\n")
                else:
                    fail_count += 1
                    print(f"  → ❌ MISMATCH: engine={ju}, app={app_ju}\n")
            except ValueError:
                skip_count += 1
                print(f"  → Invalid input, skipped\n")

    print(f"\n{'=' * 40}")
    print(f"Results: {pass_count} pass, {fail_count} fail, {skip_count} skip")
    if fail_count == 0 and pass_count > 0:
        print("Engine is matching the app! 🎯")
    elif fail_count > 0:
        print("⚠️  Mismatches found — need to investigate.")
    print(f"{'=' * 40}")


def main():
    parser = argparse.ArgumentParser(
        description='奇门遁甲排盘引擎 — QMDJ Chart Engine (Yang Plate)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python3 qmdj-engine.py                          # Current time
  python3 qmdj-engine.py --datetime "2026-03-17 16:22"  # Specific time
  python3 qmdj-engine.py --json                    # JSON output
  python3 qmdj-engine.py --grid                    # 3x3 visual grid
  python3 qmdj-engine.py --method maoshan          # Use Maoshan method
""")
    parser.add_argument('--datetime', '-d', type=str, default=None,
                        help='Datetime string (YYYY-MM-DD HH:MM), assumed UTC+8')
    parser.add_argument('--json', '-j', action='store_true',
                        help='Output as JSON')
    parser.add_argument('--grid', '-g', action='store_true',
                        help='Show 3x3 visual grid')
    parser.add_argument('--method', '-m', type=str, default='chaibu',
                        choices=['chaibu', 'chaibu_standard', 'yinpan_numeric', 'maoshan', 'zhirun'],
                        help='Ju determination method (default: chaibu = 阴盘旬首三合法)')
    parser.add_argument('--compare', action='store_true',
                        help='Compare 旬首三合法 vs numeric formula side by side')
    parser.add_argument('--validate-interactive', action='store_true',
                        help='Interactive validation mode — test against yrydai.com app')
    parser.add_argument('--no-color', action='store_true',
                        help='Disable color output')

    args = parser.parse_args()

    dt = None
    if args.datetime:
        dt = datetime.strptime(args.datetime, '%Y-%m-%d %H:%M')
        # Assumed UTC+8
        if HAS_PYTZ:
            myt = pytz.timezone('Asia/Kuala_Lumpur')
            dt = myt.localize(dt)

    if args.validate_interactive:
        _run_validation_interactive()
        sys.exit(0)

    if args.compare:
        # Side-by-side comparison of both methods
        chart_a = generate_chart(dt=dt, method='chaibu')
        chart_b = generate_chart(dt=dt, method='yinpan_numeric')

        dun_a = f"{'阳遁' if chart_a['dun'] == 'yang' else '阴遁'}{chart_a['ju_number']}局"
        dun_b = f"{'阳遁' if chart_b['dun'] == 'yang' else '阴遁'}{chart_b['ju_number']}局"
        match = '✅ SAME' if chart_a['ju_number'] == chart_b['ju_number'] else '❌ DIFFER'

        print(f"{'=' * 50}")
        print(f"方法比较 — {chart_a.get('datetime', '')}")
        print(f"{'=' * 50}")
        print(f"  四柱: {format_four_pillars(chart_a['four_pillars'])}")
        print(f"  节气: {chart_a.get('solar_term', '')}")
        print(f"")
        print(f"  旬首三合法: {dun_a}  (元: {chart_a.get('yuan', '')})")
        print(f"  数字公式:   {dun_b}  (元: {chart_b.get('yuan', '')})")
        print(f"  结果: {match}")
        print(f"")
        print(f"  → Check yrydai.com for this date/time to determine correct method.")
        sys.exit(0)

    chart = generate_chart(dt=dt, method=args.method)

    if args.json:
        # Clean output for JSON
        print(json.dumps(chart, ensure_ascii=False, indent=2, default=str))
    elif args.grid:
        print(render_summary(chart))
        print(render_grid(chart, use_color=not args.no_color))
    else:
        # Default: summary + grid
        print(render_summary(chart))
        print(render_grid(chart, use_color=not args.no_color))


if __name__ == '__main__':
    main()
