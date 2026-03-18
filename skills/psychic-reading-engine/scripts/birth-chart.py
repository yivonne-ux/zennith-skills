#!/usr/bin/env python3
"""
Western Astrology Birth Chart Engine
Uses PyEphem for real astronomical computation.
Computes planetary positions, houses (Placidus), aspects, dignities, element/modality balance.
"""

import ephem
import math
import json
import sys
import argparse
from datetime import datetime
import pytz


# ---------------------------------------------------------------------------
# Zodiac helpers
# ---------------------------------------------------------------------------

SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer",
    "Leo", "Virgo", "Libra", "Scorpio",
    "Sagittarius", "Capricorn", "Aquarius", "Pisces"
]

SIGN_ELEMENTS = {
    "Aries": "Fire", "Taurus": "Earth", "Gemini": "Air", "Cancer": "Water",
    "Leo": "Fire", "Virgo": "Earth", "Libra": "Air", "Scorpio": "Water",
    "Sagittarius": "Fire", "Capricorn": "Earth", "Aquarius": "Air", "Pisces": "Water"
}

SIGN_MODALITIES = {
    "Aries": "Cardinal", "Taurus": "Fixed", "Gemini": "Mutable",
    "Cancer": "Cardinal", "Leo": "Fixed", "Virgo": "Mutable",
    "Libra": "Cardinal", "Scorpio": "Fixed", "Sagittarius": "Mutable",
    "Capricorn": "Cardinal", "Aquarius": "Fixed", "Pisces": "Mutable"
}

SIGN_RULERS = {
    "Aries": "Mars", "Taurus": "Venus", "Gemini": "Mercury",
    "Cancer": "Moon", "Leo": "Sun", "Virgo": "Mercury",
    "Libra": "Venus", "Scorpio": "Pluto", "Sagittarius": "Jupiter",
    "Capricorn": "Saturn", "Aquarius": "Uranus", "Pisces": "Neptune"
}

# Dignities: domicile, detriment, exaltation, fall
DIGNITIES = {
    "Sun":     {"domicile": ["Leo"], "detriment": ["Aquarius"], "exaltation": ["Aries"], "fall": ["Libra"]},
    "Moon":    {"domicile": ["Cancer"], "detriment": ["Capricorn"], "exaltation": ["Taurus"], "fall": ["Scorpio"]},
    "Mercury": {"domicile": ["Gemini", "Virgo"], "detriment": ["Sagittarius", "Pisces"], "exaltation": ["Virgo"], "fall": ["Pisces"]},
    "Venus":   {"domicile": ["Taurus", "Libra"], "detriment": ["Scorpio", "Aries"], "exaltation": ["Pisces"], "fall": ["Virgo"]},
    "Mars":    {"domicile": ["Aries", "Scorpio"], "detriment": ["Libra", "Taurus"], "exaltation": ["Capricorn"], "fall": ["Cancer"]},
    "Jupiter": {"domicile": ["Sagittarius", "Pisces"], "detriment": ["Gemini", "Virgo"], "exaltation": ["Cancer"], "fall": ["Capricorn"]},
    "Saturn":  {"domicile": ["Capricorn", "Aquarius"], "detriment": ["Cancer", "Leo"], "exaltation": ["Libra"], "fall": ["Aries"]},
    "Uranus":  {"domicile": ["Aquarius"], "detriment": ["Leo"], "exaltation": ["Scorpio"], "fall": ["Taurus"]},
    "Neptune": {"domicile": ["Pisces"], "detriment": ["Virgo"], "exaltation": ["Leo"], "fall": ["Aquarius"]},
    "Pluto":   {"domicile": ["Scorpio"], "detriment": ["Taurus"], "exaltation": ["Aries"], "fall": ["Libra"]},
}

ASPECT_DEFS = [
    {"name": "Conjunction", "angle": 0,   "orb": 8, "symbol": "0"},
    {"name": "Sextile",     "angle": 60,  "orb": 6, "symbol": "*"},
    {"name": "Square",      "angle": 90,  "orb": 7, "symbol": "[]"},
    {"name": "Trine",       "angle": 120, "orb": 8, "symbol": "/\\"},
    {"name": "Opposition",  "angle": 180, "orb": 8, "symbol": "||"},
]

ASPECT_NATURES = {
    "Conjunction": "neutral",
    "Sextile": "harmonious",
    "Square": "challenging",
    "Trine": "harmonious",
    "Opposition": "challenging",
}


# ---------------------------------------------------------------------------
# Conversion utilities
# ---------------------------------------------------------------------------

def ecliptic_lon_to_sign(lon_deg):
    """Convert ecliptic longitude (0-360) to sign + degree within sign."""
    lon_deg = lon_deg % 360
    sign_index = int(lon_deg / 30)
    degree_in_sign = lon_deg - sign_index * 30
    return SIGNS[sign_index], degree_in_sign, sign_index


def deg_to_dms(deg):
    """Convert decimal degrees to degrees/minutes/seconds string."""
    d = int(deg)
    m_float = (deg - d) * 60
    m = int(m_float)
    s = (m_float - m) * 60
    return f"{d}\u00b0{m:02d}'{s:04.1f}\""


def normalize_angle(a):
    """Normalize angle to 0-360."""
    return a % 360


def angle_diff(a, b):
    """Smallest angular difference between two longitudes."""
    d = abs(normalize_angle(a) - normalize_angle(b))
    if d > 180:
        d = 360 - d
    return d


# ---------------------------------------------------------------------------
# Sidereal time / Ascendant / Houses (Placidus)
# ---------------------------------------------------------------------------

def compute_lst(jd, lon_deg):
    """Compute Local Sidereal Time in degrees from Julian Date and longitude."""
    # Greenwich Mean Sidereal Time using IAU formula
    T = (jd - 2451545.0) / 36525.0
    gmst_sec = (
        280.46061837
        + 360.98564736629 * (jd - 2451545.0)
        + 0.000387933 * T * T
        - T * T * T / 38710000.0
    )
    gmst_deg = gmst_sec % 360
    lst_deg = (gmst_deg + lon_deg) % 360
    return lst_deg


def compute_ascendant(lst_deg, lat_rad):
    """Compute Ascendant from LST (degrees) and latitude (radians).
    Formula: tan(ASC) = -cos(LST) / (sin(LST)*cos(obliquity) + tan(lat)*sin(obliquity))
    """
    obliquity = math.radians(23.4393)  # mean obliquity
    lst_rad = math.radians(lst_deg)

    numerator = -math.cos(lst_rad)
    denominator = (
        math.sin(lst_rad) * math.cos(obliquity)
        + math.tan(lat_rad) * math.sin(obliquity)
    )

    asc_rad = math.atan2(numerator, denominator)
    asc_deg = math.degrees(asc_rad) % 360

    return asc_deg


def compute_mc(lst_deg):
    """Compute Medium Coeli (MC / Midheaven) from LST.
    Formula: tan(MC) = tan(LST) / cos(obliquity)
    """
    obliquity = math.radians(23.4393)
    lst_rad = math.radians(lst_deg)

    mc_rad = math.atan2(math.sin(lst_rad), math.cos(lst_rad) * math.cos(obliquity))
    mc_deg = math.degrees(mc_rad) % 360

    return mc_deg


def placidus_cusp(house_num, mc_deg, asc_deg, lat_rad, lst_deg):
    """Compute Placidus house cusps using semi-arc method with iterative refinement."""
    obliquity = math.radians(23.4393)

    if house_num in (1, 7):
        return asc_deg if house_num == 1 else (asc_deg + 180) % 360
    if house_num in (10, 4):
        return mc_deg if house_num == 10 else (mc_deg + 180) % 360

    # For intermediate houses use semi-arc division
    # Houses 11,12 are above horizon (MC to ASC)
    # Houses 2,3 are below horizon (ASC to IC)
    if house_num in (11, 12, 2, 3):
        if house_num == 11:
            fraction = 1.0 / 3.0
            ramc = math.radians(lst_deg)
            target_ra = ramc + fraction * _semi_arc_diurnal(mc_deg, obliquity, lat_rad)
        elif house_num == 12:
            fraction = 2.0 / 3.0
            ramc = math.radians(lst_deg)
            target_ra = ramc + fraction * _semi_arc_diurnal(mc_deg, obliquity, lat_rad)
        elif house_num == 2:
            fraction = 1.0 / 3.0
            ramc = math.radians(lst_deg)
            ic_ra = ramc + math.pi
            target_ra = ic_ra + fraction * _semi_arc_nocturnal(mc_deg, obliquity, lat_rad)
        elif house_num == 3:
            fraction = 2.0 / 3.0
            ramc = math.radians(lst_deg)
            ic_ra = ramc + math.pi
            target_ra = ic_ra + fraction * _semi_arc_nocturnal(mc_deg, obliquity, lat_rad)

        # Convert RA to ecliptic longitude
        target_ra_norm = target_ra % (2 * math.pi)
        lon = math.atan2(
            math.sin(target_ra_norm) * math.cos(obliquity),
            math.cos(target_ra_norm)
        )
        return math.degrees(lon) % 360

    # Opposite houses
    opposite = {5: 11, 6: 12, 8: 2, 9: 3}
    if house_num in opposite:
        base = placidus_cusp(opposite[house_num], mc_deg, asc_deg, lat_rad, lst_deg)
        return (base + 180) % 360

    return 0


def _semi_arc_diurnal(mc_deg, obliquity, lat_rad):
    """Approximate diurnal semi-arc."""
    mc_rad = math.radians(mc_deg)
    dec = math.asin(math.sin(obliquity) * math.sin(mc_rad))
    cos_ha = -math.tan(lat_rad) * math.tan(dec)
    cos_ha = max(-1, min(1, cos_ha))
    return math.acos(cos_ha)


def _semi_arc_nocturnal(mc_deg, obliquity, lat_rad):
    """Approximate nocturnal semi-arc."""
    return math.pi - _semi_arc_diurnal(mc_deg, obliquity, lat_rad)


def compute_houses(lst_deg, lat_deg):
    """Compute all 12 Placidus house cusps."""
    lat_rad = math.radians(lat_deg)
    mc_deg = compute_mc(lst_deg)
    asc_deg = compute_ascendant(lst_deg, lat_rad)

    cusps = {}
    for h in range(1, 13):
        cusps[h] = placidus_cusp(h, mc_deg, asc_deg, lat_rad, lst_deg)

    return cusps, asc_deg, mc_deg


def planet_in_house(planet_lon, cusps):
    """Determine which house a planet falls in given cusps dict."""
    planet_lon = planet_lon % 360
    house_order = sorted(cusps.keys())

    for i in range(12):
        h = house_order[i]
        h_next = house_order[(i + 1) % 12]
        cusp_start = cusps[h] % 360
        cusp_end = cusps[h_next] % 360

        if cusp_start < cusp_end:
            if cusp_start <= planet_lon < cusp_end:
                return h
        else:  # wraps around 0
            if planet_lon >= cusp_start or planet_lon < cusp_end:
                return h

    return 1  # fallback


# ---------------------------------------------------------------------------
# Planetary position computation
# ---------------------------------------------------------------------------

PLANETS = {
    "Sun": ephem.Sun,
    "Moon": ephem.Moon,
    "Mercury": ephem.Mercury,
    "Venus": ephem.Venus,
    "Mars": ephem.Mars,
    "Jupiter": ephem.Jupiter,
    "Saturn": ephem.Saturn,
    "Uranus": ephem.Uranus,
    "Neptune": ephem.Neptune,
    "Pluto": ephem.Pluto,
}


def compute_planet_positions(date_utc, lat, lon):
    """Compute ecliptic longitude for all planets using PyEphem."""
    observer = ephem.Observer()
    observer.lat = str(lat)
    observer.lon = str(lon)
    observer.date = date_utc
    observer.pressure = 0  # no atmospheric refraction for astrology

    positions = {}
    for name, planet_class in PLANETS.items():
        body = planet_class()
        body.compute(observer)

        # PyEphem gives heliocentric ecliptic lon via hlon for planets,
        # but for astrological geocentric longitude we use a different approach.
        # We compute ecliptic coordinates from RA/Dec using the observer epoch.
        ecl = ephem.Ecliptic(body, epoch=date_utc)
        lon_deg = math.degrees(float(ecl.lon)) % 360

        sign, deg_in_sign, sign_idx = ecliptic_lon_to_sign(lon_deg)

        # Determine retrograde (only for planets, not luminaries)
        is_retrograde = False
        if name not in ("Sun", "Moon"):
            # Check if planet RA is decreasing by computing a day ahead
            observer2 = ephem.Observer()
            observer2.lat = str(lat)
            observer2.lon = str(lon)
            observer2.date = date_utc + 1
            observer2.pressure = 0
            body2 = planet_class()
            body2.compute(observer2)
            ecl2 = ephem.Ecliptic(body2, epoch=date_utc + 1)
            lon_next = math.degrees(float(ecl2.lon)) % 360
            diff = lon_next - lon_deg
            if diff > 180:
                diff -= 360
            elif diff < -180:
                diff += 360
            is_retrograde = diff < 0

        # Dignity
        dignity = get_dignity(name, sign)

        positions[name] = {
            "longitude": round(lon_deg, 4),
            "sign": sign,
            "degree_in_sign": round(deg_in_sign, 4),
            "degree_display": deg_to_dms(deg_in_sign),
            "sign_index": sign_idx,
            "retrograde": is_retrograde,
            "dignity": dignity,
        }

    return positions


def get_dignity(planet, sign):
    """Return dignity status for a planet in a sign."""
    if planet not in DIGNITIES:
        return None
    d = DIGNITIES[planet]
    if sign in d["domicile"]:
        return "domicile"
    if sign in d["detriment"]:
        return "detriment"
    if sign in d["exaltation"]:
        return "exaltation"
    if sign in d["fall"]:
        return "fall"
    return "peregrine"


# ---------------------------------------------------------------------------
# Aspects
# ---------------------------------------------------------------------------

def compute_aspects(positions):
    """Compute major aspects between all planet pairs."""
    planet_names = list(positions.keys())
    aspects = []

    for i in range(len(planet_names)):
        for j in range(i + 1, len(planet_names)):
            p1 = planet_names[i]
            p2 = planet_names[j]
            lon1 = positions[p1]["longitude"]
            lon2 = positions[p2]["longitude"]
            diff = angle_diff(lon1, lon2)

            for asp in ASPECT_DEFS:
                orb_actual = abs(diff - asp["angle"])
                if orb_actual <= asp["orb"]:
                    # Applying vs separating: check if orb is tightening
                    applying = None
                    if not positions[p1].get("retrograde") and not positions[p2].get("retrograde"):
                        # Rough heuristic: faster planet determines
                        applying = "applying" if lon1 < lon2 else "separating"

                    aspects.append({
                        "planet1": p1,
                        "planet2": p2,
                        "aspect": asp["name"],
                        "exact_angle": asp["angle"],
                        "actual_angle": round(diff, 2),
                        "orb": round(orb_actual, 2),
                        "nature": ASPECT_NATURES[asp["name"]],
                        "applying_separating": applying,
                    })
                    break  # only one aspect per pair

    return aspects


# ---------------------------------------------------------------------------
# Element / Modality balance
# ---------------------------------------------------------------------------

def compute_balance(positions):
    """Compute element and modality distribution weighted by planet importance."""
    # Weights: luminaries > personals > socials > transpersonals
    weights = {
        "Sun": 3, "Moon": 3, "Mercury": 2, "Venus": 2, "Mars": 2,
        "Jupiter": 1.5, "Saturn": 1.5, "Uranus": 1, "Neptune": 1, "Pluto": 1
    }

    elements = {"Fire": 0, "Earth": 0, "Air": 0, "Water": 0}
    modalities = {"Cardinal": 0, "Fixed": 0, "Mutable": 0}

    for planet, data in positions.items():
        sign = data["sign"]
        w = weights.get(planet, 1)
        elements[SIGN_ELEMENTS[sign]] += w
        modalities[SIGN_MODALITIES[sign]] += w

    total_w = sum(weights.values())

    element_pct = {k: round(v / total_w * 100, 1) for k, v in elements.items()}
    modality_pct = {k: round(v / total_w * 100, 1) for k, v in modalities.items()}

    dominant_element = max(elements, key=elements.get)
    dominant_modality = max(modalities, key=modalities.get)

    lacking_elements = [k for k, v in element_pct.items() if v < 12]
    lacking_modalities = [k for k, v in modality_pct.items() if v < 15]

    return {
        "elements": {
            "raw_weights": elements,
            "percentages": element_pct,
            "dominant": dominant_element,
            "lacking": lacking_elements,
        },
        "modalities": {
            "raw_weights": modalities,
            "percentages": modality_pct,
            "dominant": dominant_modality,
            "lacking": lacking_modalities,
        },
    }


# ---------------------------------------------------------------------------
# Chart ruler / other derived data
# ---------------------------------------------------------------------------

def derive_chart_metadata(positions, asc_deg, cusps):
    """Derive chart ruler, stelliums, etc."""
    asc_sign, _, _ = ecliptic_lon_to_sign(asc_deg)
    chart_ruler_planet = SIGN_RULERS.get(asc_sign, "Unknown")

    chart_ruler_data = positions.get(chart_ruler_planet, {})

    # Detect stelliums (3+ planets in same sign)
    sign_counts = {}
    for p, d in positions.items():
        s = d["sign"]
        sign_counts.setdefault(s, []).append(p)
    stelliums = {s: planets for s, planets in sign_counts.items() if len(planets) >= 3}

    # House placements
    house_placements = {}
    for p, d in positions.items():
        h = planet_in_house(d["longitude"], cusps)
        house_placements[p] = h

    return {
        "ascendant_sign": asc_sign,
        "chart_ruler": chart_ruler_planet,
        "chart_ruler_sign": chart_ruler_data.get("sign"),
        "chart_ruler_house": house_placements.get(chart_ruler_planet),
        "stelliums": stelliums,
        "house_placements": house_placements,
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Western Astrology Birth Chart Engine")
    parser.add_argument("--name", required=True, help="Name of the person")
    parser.add_argument("--date", required=True, help="Birth date YYYY-MM-DD")
    parser.add_argument("--time", required=True, help="Birth time HH:MM (24h)")
    parser.add_argument("--lat", required=True, type=float, help="Birth latitude")
    parser.add_argument("--lon", required=True, type=float, help="Birth longitude")
    parser.add_argument("--tz", required=True, help="Timezone e.g. Asia/Kuala_Lumpur")

    args = parser.parse_args()

    # Parse birth datetime in local timezone, convert to UTC
    tz = pytz.timezone(args.tz)
    local_dt = datetime.strptime(f"{args.date} {args.time}", "%Y-%m-%d %H:%M")
    local_dt = tz.localize(local_dt)
    utc_dt = local_dt.astimezone(pytz.UTC)

    # Convert to PyEphem date
    ephem_date = ephem.Date(utc_dt)

    # Compute planetary positions
    positions = compute_planet_positions(ephem_date, args.lat, args.lon)

    # Compute houses
    jd = ephem.julian_date(ephem_date)
    lst_deg = compute_lst(jd, args.lon)
    cusps, asc_deg, mc_deg = compute_houses(lst_deg, args.lat)

    # Format house cusps
    house_data = {}
    for h, cusp_lon in cusps.items():
        sign, deg, _ = ecliptic_lon_to_sign(cusp_lon)
        house_data[str(h)] = {
            "cusp_longitude": round(cusp_lon, 4),
            "sign": sign,
            "degree_in_sign": round(deg, 4),
            "degree_display": deg_to_dms(deg),
        }

    # Aspects
    aspects = compute_aspects(positions)

    # Element/modality balance
    balance = compute_balance(positions)

    # Derived metadata
    metadata = derive_chart_metadata(positions, asc_deg, cusps)

    # Assemble output
    asc_sign, asc_deg_in_sign, _ = ecliptic_lon_to_sign(asc_deg)
    mc_sign, mc_deg_in_sign, _ = ecliptic_lon_to_sign(mc_deg)

    chart = {
        "name": args.name,
        "birth_date": args.date,
        "birth_time": args.time,
        "birth_lat": args.lat,
        "birth_lon": args.lon,
        "timezone": args.tz,
        "utc_datetime": utc_dt.strftime("%Y-%m-%d %H:%M:%S UTC"),
        "julian_date": round(jd, 6),
        "local_sidereal_time_deg": round(lst_deg, 4),
        "ascendant": {
            "longitude": round(asc_deg, 4),
            "sign": asc_sign,
            "degree_in_sign": round(asc_deg_in_sign, 4),
            "degree_display": deg_to_dms(asc_deg_in_sign),
        },
        "midheaven": {
            "longitude": round(mc_deg, 4),
            "sign": mc_sign,
            "degree_in_sign": round(mc_deg_in_sign, 4),
            "degree_display": deg_to_dms(mc_deg_in_sign),
        },
        "planets": positions,
        "houses": house_data,
        "aspects": aspects,
        "element_modality_balance": balance,
        "chart_metadata": metadata,
    }

    print(json.dumps(chart, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
