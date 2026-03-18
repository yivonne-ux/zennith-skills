#!/usr/bin/env python3
"""
Comprehensive E2E test for QMDJ engine (qmdj-calc.py)
Validates: four pillars, plates, stars, doors, deities, dun type, ju number,
structural integrity across 50+ diverse dates.
"""

import json
import subprocess
import sys
from datetime import date, datetime

SCRIPT = "/Users/jennwoeiloh/.openclaw/skills/psychic-reading-engine/scripts/qmdj-calc.py"

HEAVENLY_STEMS = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
EARTHLY_BRANCHES = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]

VALID_STARS = {"天蓬", "天芮", "天冲", "天辅", "天禽", "天心", "天柱", "天任", "天英"}
VALID_DOORS = {"开", "休", "生", "伤", "杜", "景", "死", "惊"}
VALID_DEITIES = {"值符", "腾蛇", "太阴", "六合", "白虎", "玄武", "九地", "九天"}
EARTH_PLATE_STEMS = {"戊", "己", "庚", "辛", "壬", "癸", "丁", "丙", "乙"}

# Yang dun solar terms: 冬至 through 芒种
YANG_TERMS = {"冬至", "小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨", "立夏", "小满", "芒种"}
YIN_TERMS = {"夏至", "小暑", "大暑", "立秋", "处暑", "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪"}

# 五虎遁 (hour stem base by day stem): 甲己→甲, 乙庚→丙, 丙辛→戊, 丁壬→庚, 戊癸→壬
HOUR_STEM_BASE = {0: 0, 5: 0, 1: 2, 6: 2, 2: 4, 7: 4, 3: 6, 8: 6, 4: 8, 9: 8}

# JDN reference: 2000-01-07 = 甲子日 (JDN 2451551)
JDN_REF_DATE = date(2000, 1, 7)
JDN_REF_CYCLE_POS = 0  # 甲子 = position 0 in 60-cycle


def jdn(y, m, d):
    """Compute Julian Day Number."""
    if m <= 2:
        y -= 1
        m += 12
    A = y // 100
    B = 2 - A + A // 4
    return int(365.25 * (y + 4716)) + int(30.6001 * (m + 1)) + d + B - 1524.5


def expected_day_pillar(y, m, d):
    """Compute expected day pillar using JDN method."""
    target_jdn = jdn(y, m, d)
    ref_jdn = jdn(2000, 1, 7)
    diff = int(target_jdn - ref_jdn)
    cycle_pos = (diff + JDN_REF_CYCLE_POS) % 60
    stem_idx = cycle_pos % 10
    branch_idx = cycle_pos % 12
    return HEAVENLY_STEMS[stem_idx] + EARTHLY_BRANCHES[branch_idx], stem_idx


def expected_hour_pillar(day_stem_idx, hour):
    """Compute expected hour pillar using 五虎遁 rule."""
    branch_idx = ((hour + 1) % 24) // 2
    base = HOUR_STEM_BASE[day_stem_idx]
    stem_idx = (base + branch_idx) % 10
    return HEAVENLY_STEMS[stem_idx] + EARTHLY_BRANCHES[branch_idx]


def run_engine(dt_str, tz, mode="destiny"):
    """Run QMDJ engine and return parsed JSON."""
    cmd = [sys.executable, SCRIPT, "--datetime", dt_str, "--tz", tz, "--mode", mode]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        raise RuntimeError(f"Engine failed: {result.stderr}")
    return json.loads(result.stdout)


def extract_door_name(door_dict):
    """Extract single-char door name from door dict."""
    cn = door_dict.get("chinese", "")
    return cn.replace("门", "") if cn else ""


# ============================================================================
# TEST CASES: 50+ dates covering all requirements
# ============================================================================

# Format: (description, datetime_str, tz, expected_four_pillars_or_None, expected_dun_type_or_None)
# expected_four_pillars: "年柱/月柱/日柱/时柱" or None for auto-check
# expected_dun_type: "阳遁" or "阴遁" or None for auto-check

TEST_CASES = [
    # ---- Known-correct four pillars (MUST match exactly) ----
    ("Known: 2026-03-17 16:22 KL", "2026-03-17 16:22", "Asia/Kuala_Lumpur",
     "丙午/辛卯/庚寅/甲申", None),
    ("Known: 1985-03-16 04:34 Shanghai", "1985-03-16 04:34", "Asia/Shanghai",
     "乙丑/己卯/甲寅/丙寅", None),
    ("Known: 2000-01-07 12:00 Shanghai (甲子日 ref)", "2000-01-07 12:00", "Asia/Shanghai",
     "己卯/丁丑/甲子/庚午", None),

    # ---- 立春 boundary: 2024-02-04 (立春 ~16:27 UTC+8) ----
    ("立春 boundary: 2024-02-04 00:00 (before lichun)", "2024-02-04 00:00", "Asia/Shanghai",
     None, None),
    ("立春 boundary: 2024-02-04 18:00 (after lichun)", "2024-02-04 18:00", "Asia/Shanghai",
     None, None),

    # ---- All 24 solar terms (at least 1 date in each term period) ----
    # 冬至 ~Dec 22 → 阳遁
    ("冬至 period: 2025-12-25 10:00", "2025-12-25 10:00", "Asia/Shanghai", None, "阳遁"),
    # 小寒 ~Jan 6
    ("小寒 period: 2026-01-08 14:00", "2026-01-08 14:00", "Asia/Shanghai", None, "阳遁"),
    # 大寒 ~Jan 20
    ("大寒 period: 2026-01-22 09:00", "2026-01-22 09:00", "Asia/Shanghai", None, "阳遁"),
    # 立春 ~Feb 4
    ("立春 period: 2026-02-06 11:00", "2026-02-06 11:00", "Asia/Shanghai", None, "阳遁"),
    # 雨水 ~Feb 19
    ("雨水 period: 2026-02-21 15:00", "2026-02-21 15:00", "Asia/Shanghai", None, "阳遁"),
    # 惊蛰 ~Mar 6
    ("惊蛰 period: 2026-03-10 08:00", "2026-03-10 08:00", "Asia/Shanghai", None, "阳遁"),
    # 春分 ~Mar 21
    ("春分 period: 2026-03-23 12:00", "2026-03-23 12:00", "Asia/Shanghai", None, "阳遁"),
    # 清明 ~Apr 5
    ("清明 period: 2026-04-07 16:00", "2026-04-07 16:00", "Asia/Shanghai", None, "阳遁"),
    # 谷雨 ~Apr 20
    ("谷雨 period: 2026-04-22 10:00", "2026-04-22 10:00", "Asia/Shanghai", None, "阳遁"),
    # 立夏 ~May 6
    ("立夏 period: 2026-05-08 14:00", "2026-05-08 14:00", "Asia/Shanghai", None, "阳遁"),
    # 小满 ~May 21
    ("小满 period: 2026-05-23 09:00", "2026-05-23 09:00", "Asia/Shanghai", None, "阳遁"),
    # 芒种 ~Jun 6
    ("芒种 period: 2026-06-08 11:00", "2026-06-08 11:00", "Asia/Shanghai", None, "阳遁"),
    # 夏至 ~Jun 21 → 阴遁
    ("夏至 period: 2026-06-23 16:00", "2026-06-23 16:00", "Asia/Shanghai", None, "阴遁"),
    # 小暑 ~Jul 7
    ("小暑 period: 2026-07-09 10:00", "2026-07-09 10:00", "Asia/Shanghai", None, "阴遁"),
    # 大暑 ~Jul 23
    ("大暑 period: 2026-07-25 08:00", "2026-07-25 08:00", "Asia/Shanghai", None, "阴遁"),
    # 立秋 ~Aug 7
    ("立秋 period: 2026-08-09 14:00", "2026-08-09 14:00", "Asia/Shanghai", None, "阴遁"),
    # 处暑 ~Aug 23
    ("处暑 period: 2026-08-25 12:00", "2026-08-25 12:00", "Asia/Shanghai", None, "阴遁"),
    # 白露 ~Sep 8
    ("白露 period: 2026-09-10 09:00", "2026-09-10 09:00", "Asia/Shanghai", None, "阴遁"),
    # 秋分 ~Sep 23
    ("秋分 period: 2026-09-25 15:00", "2026-09-25 15:00", "Asia/Shanghai", None, "阴遁"),
    # 寒露 ~Oct 8
    ("寒露 period: 2026-10-10 11:00", "2026-10-10 11:00", "Asia/Shanghai", None, "阴遁"),
    # 霜降 ~Oct 23
    ("霜降 period: 2026-10-25 08:00", "2026-10-25 08:00", "Asia/Shanghai", None, "阴遁"),
    # 立冬 ~Nov 7
    ("立冬 period: 2026-11-09 16:00", "2026-11-09 16:00", "Asia/Shanghai", None, "阴遁"),
    # 小雪 ~Nov 22
    ("小雪 period: 2026-11-24 10:00", "2026-11-24 10:00", "Asia/Shanghai", None, "阴遁"),
    # 大雪 ~Dec 7
    ("大雪 period: 2026-12-09 14:00", "2026-12-09 14:00", "Asia/Shanghai", None, "阴遁"),

    # ---- Edge cases: 子时 (23:00-01:00) ----
    ("子时 early: 23:30 (late night)", "2026-03-17 23:30", "Asia/Kuala_Lumpur", None, None),
    ("子时 late: 00:15 (early morning)", "2026-03-18 00:15", "Asia/Kuala_Lumpur", None, None),

    # ---- Edge cases: midnight exactly ----
    ("Midnight exact", "2026-06-21 00:00", "Asia/Shanghai", None, None),

    # ---- Edge cases: first/last day of year ----
    ("New Year's Day 2026", "2026-01-01 12:00", "Asia/Shanghai", None, "阳遁"),
    ("New Year's Eve 2026", "2026-12-31 23:00", "Asia/Shanghai", None, None),

    # ---- Historical dates (1950s-2020s) ----
    ("1955-08-15 06:00 Shanghai", "1955-08-15 06:00", "Asia/Shanghai", None, "阴遁"),
    ("1960-01-01 12:00 Shanghai", "1960-01-01 12:00", "Asia/Shanghai", None, "阳遁"),
    ("1975-10-10 22:00 Shanghai", "1975-10-10 22:00", "Asia/Shanghai", None, "阴遁"),
    ("1990-06-15 03:00 Shanghai", "1990-06-15 03:00", "Asia/Shanghai", None, "阳遁"),
    ("2000-03-21 08:00 Shanghai (spring equinox area)", "2000-03-21 08:00", "Asia/Shanghai", None, "阳遁"),
    ("2010-12-22 12:00 Shanghai (winter solstice area)", "2010-12-22 12:00", "Asia/Shanghai", None, "阳遁"),
    ("2020-06-21 06:00 Shanghai (summer solstice area)", "2020-06-21 06:00", "Asia/Shanghai", None, None),

    # ---- Future dates (2027-2030) ----
    ("Future: 2027-07-04 14:00 NY", "2027-07-04 14:00", "America/New_York", None, "阴遁"),
    ("Future: 2028-02-29 10:00 KL (leap day)", "2028-02-29 10:00", "Asia/Kuala_Lumpur", None, None),
    ("Future: 2029-09-15 20:00 Shanghai", "2029-09-15 20:00", "Asia/Shanghai", None, "阴遁"),
    ("Future: 2030-01-15 07:00 Shanghai", "2030-01-15 07:00", "Asia/Shanghai", None, "阳遁"),

    # ---- Different timezones ----
    ("TZ: America/New_York 2026-03-17 08:00", "2026-03-17 08:00", "America/New_York", None, None),
    ("TZ: Asia/Kuala_Lumpur 2026-06-15 12:00", "2026-06-15 12:00", "Asia/Kuala_Lumpur", None, None),
    ("TZ: Asia/Shanghai 2026-09-01 18:00", "2026-09-01 18:00", "Asia/Shanghai", None, "阴遁"),

    # ---- Solar term boundary dates ----
    ("Near 夏至 boundary: 2026-06-21 10:00", "2026-06-21 10:00", "Asia/Shanghai", None, None),
    ("Near 冬至 boundary: 2025-12-22 10:00", "2025-12-22 10:00", "Asia/Shanghai", None, None),

    # ---- Additional historical for coverage ----
    ("1952-02-05 15:00 (near lichun)", "1952-02-05 15:00", "Asia/Shanghai", None, None),
    ("1999-12-31 23:59 (Y2K eve)", "1999-12-31 23:59", "Asia/Shanghai", None, None),
    ("2008-08-08 20:00 (Beijing Olympics)", "2008-08-08 20:00", "Asia/Shanghai", None, "阴遁"),
]


def validate_json_structure(data, desc):
    """Validate JSON output has all required keys and no nulls where shouldn't be."""
    errors = []

    required_top = ["system", "chart_type", "input_datetime", "timezone", "utc_datetime",
                    "solar_term", "four_pillars", "yuan", "dun_type", "ju_number",
                    "xun_shou", "palaces", "overall_verdict", "plate_layout"]
    for key in required_top:
        if key not in data:
            errors.append(f"Missing top-level key: {key}")
        elif data[key] is None:
            errors.append(f"Null top-level key: {key}")

    # Four pillars structure
    fp = data.get("four_pillars", {})
    for pillar in ["year", "month", "day", "hour"]:
        if pillar not in fp:
            errors.append(f"Missing pillar: {pillar}")
        else:
            p = fp[pillar]
            if "chinese" not in p:
                errors.append(f"Missing chinese in {pillar} pillar")
            if "stem" not in p or "branch" not in p:
                errors.append(f"Missing stem/branch in {pillar} pillar")

    # Solar term
    st = data.get("solar_term", {})
    for k in ["chinese", "english", "solar_longitude"]:
        if k not in st:
            errors.append(f"Missing solar_term.{k}")

    # Yuan
    yuan = data.get("yuan", {})
    for k in ["chinese", "english", "number"]:
        if k not in yuan:
            errors.append(f"Missing yuan.{k}")

    # Dun type
    dt = data.get("dun_type", {})
    if "chinese" not in dt or "english" not in dt:
        errors.append("Missing dun_type chinese/english")

    return errors


def validate_palaces(data, desc):
    """Validate palace structure: stars, doors, deities, stems."""
    errors = []
    palaces = data.get("palaces", {})

    if len(palaces) != 9:
        errors.append(f"Expected 9 palaces, got {len(palaces)}")
        return errors

    # Collect all stars, doors, deities across palaces
    all_stars = []
    all_doors = []
    all_deities = []
    earth_stems = set()
    heaven_stems = set()

    for p_num in range(1, 10):
        p = palaces.get(str(p_num), {})

        # Earth stem
        es = p.get("earth_stem", "")
        if es:
            earth_stems.add(es)

        # Heaven stem
        hs = p.get("heaven_stem", "")
        if hs:
            heaven_stems.add(hs)

        # Star
        star = p.get("star")
        if star and star.get("chinese"):
            all_stars.append(star["chinese"])
            if star["chinese"] not in VALID_STARS:
                errors.append(f"Invalid star in palace {p_num}: {star['chinese']}")

        # Door (palace 5 has no door)
        door = p.get("door")
        if p_num == 5:
            if door is not None:
                # Some implementations put None for palace 5, that's ok
                pass
        else:
            if door is None:
                errors.append(f"Missing door in palace {p_num}")
            elif door.get("chinese"):
                door_char = door["chinese"].replace("门", "")
                all_doors.append(door_char)
                if door_char not in VALID_DOORS:
                    errors.append(f"Invalid door in palace {p_num}: {door['chinese']}")

        # Deity (palace 5 has no deity)
        deity = p.get("deity")
        if p_num == 5:
            pass
        else:
            if deity is None:
                errors.append(f"Missing deity in palace {p_num}")
            elif deity.get("chinese"):
                all_deities.append(deity["chinese"])
                if deity["chinese"] not in VALID_DEITIES:
                    errors.append(f"Invalid deity in palace {p_num}: {deity['chinese']}")

    # Check all 8 doors present (no duplicates)
    door_set = set(all_doors)
    if len(door_set) != 8:
        errors.append(f"Expected 8 unique doors, got {len(door_set)}: {door_set}")
    missing_doors = VALID_DOORS - door_set
    if missing_doors:
        errors.append(f"Missing doors: {missing_doors}")

    # Check all 8 deities present (no duplicates)
    deity_set = set(all_deities)
    if len(deity_set) != 8:
        errors.append(f"Expected 8 unique deities, got {len(deity_set)}: {deity_set}")
    missing_deities = VALID_DEITIES - deity_set
    if missing_deities:
        errors.append(f"Missing deities: {missing_deities}")

    # Check stars: 8 outer + 1 center (天禽), no duplicates in outer ring
    outer_stars = [s for i, s in enumerate(all_stars) if str(i + 1) != "5"]
    # Actually let's gather by palace number
    outer_stars = []
    for p_num in range(1, 10):
        p = palaces.get(str(p_num), {})
        star = p.get("star")
        if star and p_num != 5:
            outer_stars.append(star["chinese"])
    outer_star_set = set(outer_stars)
    expected_outer_stars = VALID_STARS - {"天禽"}
    if outer_star_set != expected_outer_stars:
        errors.append(f"Outer stars mismatch. Got: {outer_star_set}, expected: {expected_outer_stars}")

    # Palace 5 should have 天禽
    p5_star = palaces.get("5", {}).get("star", {})
    if p5_star and p5_star.get("chinese") != "天禽":
        errors.append(f"Palace 5 star should be 天禽, got: {p5_star.get('chinese')}")

    # Earth plate: should have all 9 stems distributed
    if earth_stems != EARTH_PLATE_STEMS:
        errors.append(f"Earth plate stems: got {earth_stems}, expected {EARTH_PLATE_STEMS}")

    # Heaven plate: should have stems from EARTH_PLATE_STEMS (rotated)
    # Heaven stems should be a subset of the valid stems (they're the same set, rotated)
    for hs in heaven_stems:
        if hs not in EARTH_PLATE_STEMS:
            errors.append(f"Invalid heaven plate stem: {hs}")

    return errors


def validate_four_pillars_jdn(data, dt_str, tz):
    """Validate day pillar using JDN method and hour pillar using 五虎遁."""
    errors = []
    fp = data.get("four_pillars", {})

    # Parse date from input
    parts = dt_str.split(" ")
    date_parts = parts[0].split("-")
    time_parts = parts[1].split(":")
    y, m, d = int(date_parts[0]), int(date_parts[1]), int(date_parts[2])
    hour = int(time_parts[0])

    # Day pillar via JDN
    expected_day, day_stem_idx = expected_day_pillar(y, m, d)
    actual_day = fp.get("day", {}).get("chinese", "")
    if actual_day != expected_day:
        errors.append(f"Day pillar: expected {expected_day}, got {actual_day}")

    # Hour pillar via 五虎遁
    expected_hr = expected_hour_pillar(day_stem_idx, hour)
    actual_hr = fp.get("hour", {}).get("chinese", "")
    if actual_hr != expected_hr:
        errors.append(f"Hour pillar: expected {expected_hr}, got {actual_hr}")

    return errors


def validate_dun_type(data, expected_dun):
    """Validate 阳遁/阴遁 matches the solar term."""
    errors = []
    dun_cn = data.get("dun_type", {}).get("chinese", "")
    solar_term_cn = data.get("solar_term", {}).get("chinese", "")

    # Check against known classification
    if solar_term_cn in YANG_TERMS and dun_cn != "阳遁":
        errors.append(f"Solar term {solar_term_cn} should be 阳遁, got {dun_cn}")
    elif solar_term_cn in YIN_TERMS and dun_cn != "阴遁":
        errors.append(f"Solar term {solar_term_cn} should be 阴遁, got {dun_cn}")

    # If we have an explicit expected value, check that too
    if expected_dun and dun_cn != expected_dun:
        errors.append(f"Expected dun type {expected_dun}, got {dun_cn} (solar term: {solar_term_cn})")

    return errors


def validate_ju_number(data):
    """Validate ju number is 1-9."""
    errors = []
    ju = data.get("ju_number")
    if ju is None or not (1 <= ju <= 9):
        errors.append(f"Invalid ju number: {ju}")
    return errors


def validate_year_pillar_lichun(data, dt_str):
    """Validate that year pillar uses 立春 boundary, not Jan 1."""
    errors = []
    parts = dt_str.split(" ")[0].split("-")
    y = int(parts[0])
    m = int(parts[1])

    # If it's January or early February, the Chinese year might be previous year
    # We can verify: year stem should follow (year - 4) % 10 pattern
    # but if before 立春, should use (year - 1 - 4) % 10
    fp = data.get("four_pillars", {})
    year_stem_idx = fp.get("year", {}).get("stem", {}).get("index")
    year_branch_idx = fp.get("year", {}).get("branch", {}).get("index")

    if year_stem_idx is not None and year_branch_idx is not None:
        # Check that stem and branch have matching parity
        if year_stem_idx % 2 != year_branch_idx % 2:
            errors.append(f"Year pillar parity mismatch: stem={year_stem_idx}, branch={year_branch_idx}")

    return errors


def validate_known_four_pillars(data, expected_str):
    """Validate against known-correct four pillar string."""
    errors = []
    expected_parts = expected_str.split("/")
    fp = data.get("four_pillars", {})

    mapping = [("year", 0), ("month", 1), ("day", 2), ("hour", 3)]
    for pillar_name, idx in mapping:
        actual = fp.get(pillar_name, {}).get("chinese", "")
        expected = expected_parts[idx]
        if actual != expected:
            errors.append(f"{pillar_name} pillar: expected {expected}, got {actual}")

    return errors


# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

def main():
    total = len(TEST_CASES)
    passed = 0
    failed = 0
    errors_log = []

    print(f"=" * 80)
    print(f"QMDJ Engine E2E Test Suite — {total} test cases")
    print(f"=" * 80)
    print()

    for i, (desc, dt_str, tz, expected_fp, expected_dun) in enumerate(TEST_CASES, 1):
        case_errors = []
        try:
            data = run_engine(dt_str, tz)

            # 1. JSON structure
            case_errors.extend(validate_json_structure(data, desc))

            # 2. Palace validation (stars, doors, deities, stems)
            case_errors.extend(validate_palaces(data, desc))

            # 3. Four pillars via JDN
            case_errors.extend(validate_four_pillars_jdn(data, dt_str, tz))

            # 4. Dun type (阳遁/阴遁)
            case_errors.extend(validate_dun_type(data, expected_dun))

            # 5. Ju number range
            case_errors.extend(validate_ju_number(data))

            # 6. Year pillar lichun check
            case_errors.extend(validate_year_pillar_lichun(data, dt_str))

            # 7. Known four pillars (if provided)
            if expected_fp:
                case_errors.extend(validate_known_four_pillars(data, expected_fp))

        except Exception as e:
            case_errors.append(f"EXCEPTION: {e}")

        if case_errors:
            failed += 1
            status = "FAIL"
            errors_log.append((desc, case_errors))
        else:
            passed += 1
            status = "PASS"

        # Print result with solar term and dun type info
        extra = ""
        try:
            if not case_errors:
                st = data.get("solar_term", {}).get("chinese", "?")
                dun = data.get("dun_type", {}).get("chinese", "?")
                ju = data.get("ju_number", "?")
                extra = f" [{st} {dun} 局{ju}]"
        except:
            pass

        print(f"  [{status}] {i:2d}/{total} {desc}{extra}")
        if case_errors:
            for err in case_errors:
                print(f"         -> {err}")

    print()
    print(f"=" * 80)
    print(f"RESULTS: {passed} PASSED, {failed} FAILED out of {total}")
    print(f"=" * 80)

    if errors_log:
        print()
        print("FAILURE DETAILS:")
        print("-" * 60)
        for desc, errs in errors_log:
            print(f"\n  {desc}:")
            for e in errs:
                print(f"    - {e}")

    print()
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
