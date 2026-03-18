#!/usr/bin/env python3
"""
Reading Synthesizer — Master synthesis engine
Combines Western astrology, Qi Men Dun Jia, and Tarot readings.
Cross-references patterns, applies Barnum/Forer psychology, cold reading techniques.
Outputs deeply personal, multi-layered readings.
"""

import json
import sys
import argparse
import random
import math
from datetime import datetime


# ---------------------------------------------------------------------------
# Barnum/Forer Statements — 60+ universal truths weighted by chart data
# ---------------------------------------------------------------------------

BARNUM_STATEMENTS = {
    "personality_core": [
        "You have a great need for other people to like and admire you, yet you tend to be critical of yourself.",
        "While you have some personality weaknesses, you are generally able to compensate for them.",
        "You have considerable unused capacity that you have not turned to your advantage.",
        "Disciplined and self-controlled on the outside, you tend to be worrisome and insecure on the inside.",
        "At times you have serious doubts as to whether you have made the right decision or done the right thing.",
        "You prefer a certain amount of change and variety and become dissatisfied when hemmed in by restrictions and limitations.",
        "You pride yourself as an independent thinker and do not accept others' statements without satisfactory proof.",
        "You have found it unwise to be too frank in revealing yourself to others.",
        "Some of your aspirations tend to be rather unrealistic.",
        "Security is one of your major goals in life.",
    ],
    "emotional_depth": [
        "Beneath your composed exterior, there is a depth of feeling that few people ever see.",
        "You carry emotional wounds from the past that still subtly influence your decisions today.",
        "You have an innate ability to sense the emotional state of those around you, though you don't always trust this ability.",
        "There are moments when you feel profoundly alone, even in a room full of people.",
        "You have experienced at least one significant emotional turning point that fundamentally changed your perspective.",
        "Your relationship with vulnerability is complex — you understand its power but fear its consequences.",
        "You sometimes replay conversations in your head, wishing you had said something different.",
        "There is a part of you that craves deep, meaningful connection, and another part that fears it.",
    ],
    "hidden_potential": [
        "There is a creative talent within you that has not been fully expressed or developed.",
        "You possess leadership qualities that emerge naturally in crisis situations.",
        "Your intuitive abilities are stronger than you give yourself credit for.",
        "You have a natural healing presence that others unconsciously gravitate toward.",
        "A skill or interest you've been neglecting holds the key to your next phase of growth.",
        "You are on the verge of a breakthrough that has been building for longer than you realize.",
        "The very quality you consider your greatest weakness is, when properly channeled, your greatest strength.",
    ],
    "relational": [
        "In relationships, you give more than you receive, though you rarely acknowledge this imbalance.",
        "You attract people who need your stability, yet you yourself search for someone who can match your depth.",
        "There is someone in your life whose opinion of you matters far more than you would publicly admit.",
        "You have outgrown at least one significant relationship but may not have fully released it.",
        "Your standards in love are high — not because you are demanding, but because you know your own worth.",
        "You tend to test people subtly before you let them in, often without realizing you're doing it.",
    ],
    "career_purpose": [
        "You have not yet found the work that fully aligns with your deeper purpose, though you sense what it might be.",
        "Financial security matters to you, but not as much as the feeling that your work means something.",
        "You are capable of far more responsibility than your current position demands.",
        "There is a tension between what you do for money and what you would do if resources were unlimited.",
        "You possess organizational abilities that, if fully deployed, could transform your professional life.",
        "A career opportunity connected to a childhood interest or passion is closer than you think.",
    ],
    "spiritual": [
        "You sense there is more to reality than the material world, even if you can't always articulate what.",
        "You have had at least one experience that logic alone cannot explain.",
        "Your spiritual life goes through seasons — periods of deep connection alternate with periods of doubt.",
        "There is a teacher, book, or experience waiting for you that will catalyze your next spiritual awakening.",
        "You are being called to integrate your spiritual understanding into your everyday life, not keep it separate.",
    ],
    "timing": [
        "The next 3-6 months represent a window of unusual opportunity if you remain open.",
        "A cycle that began approximately 7-9 years ago is reaching its natural conclusion.",
        "The period around your next birthday holds particular significance for course correction.",
        "Something seeded in the past 18 months is about to bear fruit.",
        "The timing you are anxious about is exactly right, even though it doesn't feel that way.",
    ],
}

# ---------------------------------------------------------------------------
# Rainbow Ruse templates (cold reading: "You are X, but also Y")
# ---------------------------------------------------------------------------

RAINBOW_RUSES = [
    ("You can be {positive}, but there are times when you are {shadow}.",
     {"Fire": ("bold and decisive", "impulsive and domineering"),
      "Water": ("deeply empathetic", "overwhelmed by others' emotions"),
      "Air": ("brilliantly analytical", "detached and overthinking"),
      "Earth": ("steady and reliable", "stubbornly resistant to change")}),
    ("People see you as {public}, yet privately you are {private}.",
     {"Fire": ("confident and charismatic", "wrestling with self-doubt"),
      "Water": ("gentle and accommodating", "fiercely protective of your inner world"),
      "Air": ("cool and collected", "anxiously processing a thousand thoughts"),
      "Earth": ("grounded and practical", "yearning for something beyond the material")}),
    ("You value {value1}, but you also need {value2} to feel complete.",
     {"Fire": ("freedom and autonomy", "a witness to your achievements"),
      "Water": ("emotional security", "space for solitude and reflection"),
      "Air": ("intellectual stimulation", "genuine emotional warmth"),
      "Earth": ("material stability", "adventure and spontaneity")}),
]


# ---------------------------------------------------------------------------
# Cross-system pattern matching
# ---------------------------------------------------------------------------

# Map astrological signs to QMDJ elements and Tarot suits
SIGN_ELEMENT_MAP = {
    "Aries": "Fire", "Leo": "Fire", "Sagittarius": "Fire",
    "Taurus": "Earth", "Virgo": "Earth", "Capricorn": "Earth",
    "Gemini": "Air", "Libra": "Air", "Aquarius": "Air",
    "Cancer": "Water", "Scorpio": "Water", "Pisces": "Water",
}

ELEMENT_TO_SUIT = {
    "Fire": "Wands", "Water": "Cups", "Air": "Swords", "Earth": "Pentacles"
}

ELEMENT_TO_WUXING = {
    "Fire": "Fire", "Water": "Water", "Air": "Metal", "Earth": "Earth"
}

# Thematic clusters linking all three systems
THEME_CLUSTERS = {
    "transformation": {
        "astro_triggers": ["Pluto", "Scorpio", "8th house"],
        "qmdj_triggers": ["死门", "Death Gate"],
        "tarot_triggers": ["Death", "The Tower", "Judgement"],
        "theme": "Profound transformation is the dominant energy. Structures must fall so new ones can rise.",
    },
    "new_beginnings": {
        "astro_triggers": ["Aries", "1st house", "Ascendant"],
        "qmdj_triggers": ["生门", "Life Gate"],
        "tarot_triggers": ["The Fool", "Ace of", "The Magician"],
        "theme": "A powerful new beginning is available. The energy of initiation is present across all systems.",
    },
    "authority_career": {
        "astro_triggers": ["Capricorn", "Saturn", "10th house", "Midheaven"],
        "qmdj_triggers": ["开门", "Open Gate"],
        "tarot_triggers": ["The Emperor", "King of Pentacles", "The World"],
        "theme": "Career authority and worldly achievement are highlighted. Structure and discipline yield results.",
    },
    "emotional_depth": {
        "astro_triggers": ["Cancer", "Moon", "4th house", "Pisces", "Neptune"],
        "qmdj_triggers": ["休门", "Rest Gate"],
        "tarot_triggers": ["The High Priestess", "The Moon", "Queen of Cups"],
        "theme": "The emotional and intuitive realms demand attention. Inner work and sensitivity are paramount.",
    },
    "conflict_challenge": {
        "astro_triggers": ["Mars", "Square", "Opposition"],
        "qmdj_triggers": ["伤门", "Harm Gate", "惊门", "Shock Gate"],
        "tarot_triggers": ["The Tower", "5 of Swords", "7 of Wands"],
        "theme": "Conflict and challenge are present. This is not a time for passivity — assert boundaries and fight wisely.",
    },
    "love_union": {
        "astro_triggers": ["Venus", "Libra", "7th house", "Trine"],
        "qmdj_triggers": ["景门", "Scene Gate"],
        "tarot_triggers": ["The Lovers", "2 of Cups", "The Empress"],
        "theme": "Love and partnership energy is strong. Harmony, beauty, and connection are available.",
    },
    "spiritual_awakening": {
        "astro_triggers": ["Neptune", "Pisces", "12th house", "Jupiter"],
        "qmdj_triggers": ["杜门", "Block Gate"],
        "tarot_triggers": ["The Star", "The Hermit", "Temperance"],
        "theme": "A spiritual opening or awakening is indicated. The material veil is thinning.",
    },
}


def find_cross_system_themes(chart_data, qmdj_data, tarot_data):
    """Find themes that appear across multiple systems."""
    matched_themes = []

    # Build searchable strings from each system
    astro_text = json.dumps(chart_data).lower() if chart_data else ""
    qmdj_text = json.dumps(qmdj_data) if qmdj_data else ""  # Keep Chinese chars
    tarot_text = json.dumps(tarot_data).lower() if tarot_data else ""

    for cluster_name, cluster in THEME_CLUSTERS.items():
        systems_matched = 0
        evidence = []

        # Check astrology
        for trigger in cluster["astro_triggers"]:
            if trigger.lower() in astro_text:
                systems_matched += 1
                evidence.append(f"Astrology: {trigger} present")
                break

        # Check QMDJ
        for trigger in cluster["qmdj_triggers"]:
            if trigger in qmdj_text:
                systems_matched += 1
                evidence.append(f"Qi Men Dun Jia: {trigger} active")
                break

        # Check Tarot
        for trigger in cluster["tarot_triggers"]:
            if trigger.lower() in tarot_text:
                systems_matched += 1
                evidence.append(f"Tarot: {trigger} drawn")
                break

        if systems_matched >= 2:
            matched_themes.append({
                "theme_name": cluster_name,
                "systems_matched": systems_matched,
                "evidence": evidence,
                "interpretation": cluster["theme"],
                "confidence": round(systems_matched / 3 * 100),
            })

    return sorted(matched_themes, key=lambda x: -x["systems_matched"])


# ---------------------------------------------------------------------------
# Section generators
# ---------------------------------------------------------------------------

def extract_dominant_element(chart_data):
    """Extract dominant element from birth chart."""
    if not chart_data:
        return "Fire"  # fallback
    balance = chart_data.get("element_modality_balance", {})
    elements = balance.get("elements", {})
    return elements.get("dominant", "Fire")


def select_barnum(category, chart_data, count=2):
    """Select Barnum statements weighted by chart data."""
    statements = BARNUM_STATEMENTS.get(category, [])
    if not statements:
        return []
    random.shuffle(statements)
    return statements[:count]


def generate_rainbow_ruse(dominant_element):
    """Generate a Rainbow Ruse based on dominant element."""
    ruses = []
    for template, element_map in RAINBOW_RUSES:
        if dominant_element in element_map:
            pos, neg = element_map[dominant_element]
            ruse = template.format(
                positive=pos, shadow=neg,
                public=pos, private=neg,
                value1=pos, value2=neg
            )
            ruses.append(ruse)
    return ruses


def generate_section(section_name, chart_data, qmdj_data, tarot_data, themes, dominant_element):
    """Generate a reading section with evidence from all systems."""

    section = {
        "section": section_name,
        "core_insight": "",
        "supporting_evidence": [],
        "barnum_layer": [],
        "cold_reading": [],
        "confidence_level": 0,
        "timing_window": "",
    }

    # Extract relevant data per section
    if section_name == "overview":
        # Core personality from Sun/Moon/Ascendant
        if chart_data:
            planets = chart_data.get("planets", {})
            sun = planets.get("Sun", {})
            moon = planets.get("Moon", {})
            meta = chart_data.get("chart_metadata", {})
            asc = chart_data.get("ascendant", {})

            section["core_insight"] = (
                f"Your Sun in {sun.get('sign', 'unknown')} shapes your core identity — "
                f"the essence of who you are becoming. Your Moon in {moon.get('sign', 'unknown')} "
                f"governs your emotional world and deepest needs. With {asc.get('sign', 'unknown')} "
                f"rising, the world first encounters your {asc.get('sign', 'unknown')} mask."
            )
            section["supporting_evidence"].append({
                "system": "Western Astrology",
                "data": f"Sun {sun.get('sign')} {sun.get('degree_display','')}, "
                        f"Moon {moon.get('sign')} {moon.get('degree_display','')}, "
                        f"ASC {asc.get('sign')} {asc.get('degree_display','')}",
            })

        if qmdj_data:
            verdict = qmdj_data.get("overall_verdict", "")
            dun = qmdj_data.get("dun_type", {})
            section["supporting_evidence"].append({
                "system": "Qi Men Dun Jia",
                "data": f"{dun.get('chinese','')} ({dun.get('english','')}), Verdict: {verdict}",
            })

        if tarot_data:
            energy = tarot_data.get("overall_energy", "")
            section["supporting_evidence"].append({
                "system": "Tarot",
                "data": energy,
            })

        section["barnum_layer"] = select_barnum("personality_core", chart_data, 3)
        section["cold_reading"] = generate_rainbow_ruse(dominant_element)[:2]
        section["confidence_level"] = 85
        section["timing_window"] = "Present moment assessment"

    elif section_name == "love":
        if chart_data:
            planets = chart_data.get("planets", {})
            venus = planets.get("Venus", {})
            moon = planets.get("Moon", {})
            houses = chart_data.get("chart_metadata", {}).get("house_placements", {})
            venus_house = houses.get("Venus", "?")

            section["core_insight"] = (
                f"Venus in {venus.get('sign', '?')} (House {venus_house}) defines your love language "
                f"and what you find beautiful. Combined with Moon in {moon.get('sign', '?')}, "
                f"your emotional needs in partnership center on "
                f"{'security and nurture' if moon.get('sign') in ['Cancer','Taurus','Pisces'] else 'growth and stimulation'}."
            )
            section["supporting_evidence"].append({
                "system": "Western Astrology",
                "data": f"Venus {venus.get('sign')} H{venus_house}, dignity: {venus.get('dignity','')}",
            })

        if qmdj_data:
            palaces = qmdj_data.get("palaces", {})
            # Palace 4 (巽) relates to love/gentle encounters
            p4 = palaces.get("4", {})
            door = p4.get("door", {})
            section["supporting_evidence"].append({
                "system": "Qi Men Dun Jia",
                "data": f"Love palace (巽/P4): {door.get('chinese','')} {door.get('english','')} — {door.get('nature','')}",
            })

        if tarot_data:
            cards = tarot_data.get("cards", [])
            cup_cards = [c for c in cards if c.get("suit") == "Cups" or c.get("card_name") in ["The Lovers", "The Empress"]]
            if cup_cards:
                section["supporting_evidence"].append({
                    "system": "Tarot",
                    "data": f"Love-relevant cards: {', '.join(c['card_name'] for c in cup_cards[:3])}",
                })

        section["barnum_layer"] = select_barnum("relational", chart_data, 2)
        section["cold_reading"] = select_barnum("emotional_depth", chart_data, 1)
        section["confidence_level"] = 75
        section["timing_window"] = "Venus cycle: next 8 weeks"

    elif section_name == "career":
        if chart_data:
            planets = chart_data.get("planets", {})
            mars = planets.get("Mars", {})
            saturn = planets.get("Saturn", {})
            mc = chart_data.get("midheaven", {})
            houses = chart_data.get("chart_metadata", {}).get("house_placements", {})

            section["core_insight"] = (
                f"Your Midheaven in {mc.get('sign', '?')} points to {mc.get('sign','?')}-themed vocations "
                f"as your public legacy. Mars in {mars.get('sign','?')} drives your ambition style, "
                f"while Saturn in {saturn.get('sign','?')} reveals where you must build discipline."
            )
            section["supporting_evidence"].append({
                "system": "Western Astrology",
                "data": f"MC {mc.get('sign')}, Mars {mars.get('sign')} (H{houses.get('Mars','?')}), Saturn {saturn.get('sign')}",
            })

        if qmdj_data:
            palaces = qmdj_data.get("palaces", {})
            p6 = palaces.get("6", {})
            door = p6.get("door", {})
            section["supporting_evidence"].append({
                "system": "Qi Men Dun Jia",
                "data": f"Career palace (乾/P6): {door.get('chinese','')} {door.get('english','')} — {door.get('nature','')}",
            })

        if tarot_data:
            cards = tarot_data.get("cards", [])
            career_cards = [c for c in cards if c.get("suit") == "Pentacles" or
                           c.get("card_name") in ["The Emperor", "The Chariot", "The World", "Wheel of Fortune"]]
            if career_cards:
                section["supporting_evidence"].append({
                    "system": "Tarot",
                    "data": f"Career-relevant cards: {', '.join(c['card_name'] for c in career_cards[:3])}",
                })

        section["barnum_layer"] = select_barnum("career_purpose", chart_data, 2)
        section["confidence_level"] = 80
        section["timing_window"] = "Saturn cycle: next 6-12 months"

    elif section_name == "health":
        if chart_data:
            planets = chart_data.get("planets", {})
            sun = planets.get("Sun", {})
            mars = planets.get("Mars", {})
            balance = chart_data.get("element_modality_balance", {})
            lacking = balance.get("elements", {}).get("lacking", [])

            sign_body_map = {
                "Aries": "head, face, brain", "Taurus": "throat, neck, thyroid",
                "Gemini": "lungs, arms, nervous system", "Cancer": "stomach, breasts, digestion",
                "Leo": "heart, spine, back", "Virgo": "intestines, digestive system",
                "Libra": "kidneys, lower back, skin", "Scorpio": "reproductive system, elimination",
                "Sagittarius": "hips, thighs, liver", "Capricorn": "bones, joints, knees",
                "Aquarius": "circulatory system, ankles", "Pisces": "feet, lymphatic system, immune"
            }

            sun_sign = sun.get("sign", "Aries")
            vulnerable = sign_body_map.get(sun_sign, "general vitality")

            section["core_insight"] = (
                f"Sun in {sun_sign} suggests constitutional attention to: {vulnerable}. "
                f"{'Lacking ' + ', '.join(lacking) + ' element(s) suggests need for ' + ('grounding' if 'Earth' in lacking else 'emotional release' if 'Water' in lacking else 'mental stimulation' if 'Air' in lacking else 'physical activity') + '.' if lacking else 'Elemental balance is good.'}"
            )
            section["supporting_evidence"].append({
                "system": "Western Astrology",
                "data": f"Sun rules {vulnerable}, element lacking: {lacking}",
            })

        if qmdj_data:
            palaces = qmdj_data.get("palaces", {})
            p8 = palaces.get("8", {})
            door = p8.get("door", {})
            section["supporting_evidence"].append({
                "system": "Qi Men Dun Jia",
                "data": f"Health palace (艮/P8): {door.get('chinese','')} — {door.get('nature','')}",
            })

        section["confidence_level"] = 60
        section["timing_window"] = "Seasonal transitions are sensitive periods"

    elif section_name == "spiritual":
        if chart_data:
            planets = chart_data.get("planets", {})
            neptune = planets.get("Neptune", {})
            pluto = planets.get("Pluto", {})
            jupiter = planets.get("Jupiter", {})
            houses = chart_data.get("chart_metadata", {}).get("house_placements", {})

            section["core_insight"] = (
                f"Neptune in {neptune.get('sign','?')} shapes your generation's spiritual longing. "
                f"Jupiter in {jupiter.get('sign','?')} (House {houses.get('Jupiter','?')}) reveals "
                f"where faith and expansion come most naturally. "
                f"Pluto in {pluto.get('sign','?')} marks the deep transformational work of your soul."
            )
            section["supporting_evidence"].append({
                "system": "Western Astrology",
                "data": f"Neptune {neptune.get('sign')}, Jupiter {jupiter.get('sign')}, Pluto {pluto.get('sign')}",
            })

        section["barnum_layer"] = select_barnum("spiritual", chart_data, 2)
        section["confidence_level"] = 70
        section["timing_window"] = "Neptune moves slowly — this is a multi-year spiritual current"

    elif section_name == "timing":
        timing_points = []

        if chart_data:
            # Saturn return hint
            saturn = chart_data.get("planets", {}).get("Saturn", {})
            timing_points.append(f"Saturn in {saturn.get('sign','?')}: discipline themes peak during Saturn return (~ages 29, 58)")

            # Jupiter cycle
            jupiter = chart_data.get("planets", {}).get("Jupiter", {})
            timing_points.append(f"Jupiter in {jupiter.get('sign','?')}: expansion cycle returns every ~12 years")

        if qmdj_data:
            dun = qmdj_data.get("dun_type", {})
            ju = qmdj_data.get("ju_number", 0)
            timing_points.append(f"QMDJ {dun.get('english','')}, Ju {ju}: {'expansion phase' if dun.get('chinese') == '阳遁' else 'consolidation phase'}")

        section["core_insight"] = " | ".join(timing_points) if timing_points else "Multiple timing cycles are active."
        section["barnum_layer"] = select_barnum("timing", chart_data, 2)
        section["confidence_level"] = 65
        section["timing_window"] = "See individual cycle notes above"

    elif section_name == "advice":
        advice_points = []

        # Derive advice from themes
        for theme in themes[:3]:
            if theme["theme_name"] == "transformation":
                advice_points.append("Release what no longer serves you. The universe is clearing space for what comes next.")
            elif theme["theme_name"] == "new_beginnings":
                advice_points.append("Act on the new opportunity presenting itself. Hesitation is the only real risk.")
            elif theme["theme_name"] == "authority_career":
                advice_points.append("Step into greater responsibility. You are more ready than you feel.")
            elif theme["theme_name"] == "emotional_depth":
                advice_points.append("Honor your emotional intelligence. The answers you seek are felt, not thought.")
            elif theme["theme_name"] == "conflict_challenge":
                advice_points.append("Stand your ground with compassion. Conflict is not the enemy — avoidance is.")
            elif theme["theme_name"] == "love_union":
                advice_points.append("Open your heart to the connection available to you. Vulnerability is your strength here.")
            elif theme["theme_name"] == "spiritual_awakening":
                advice_points.append("Create space for silence and reflection. Your next insight comes from stillness, not action.")

        if not advice_points:
            advice_points = [
                "Trust the process. The pieces are falling into place even when it doesn't feel that way.",
                "The balance between effort and surrender is your key lesson right now."
            ]

        section["core_insight"] = " ".join(advice_points)
        section["barnum_layer"] = select_barnum("hidden_potential", chart_data, 2)
        section["confidence_level"] = 75
        section["timing_window"] = "Immediate — the reading itself is the timing"

    return section


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Reading Synthesizer")
    parser.add_argument("--chart", default=None, help="Path to birth chart JSON file")
    parser.add_argument("--qmdj", default=None, help="Path to QMDJ JSON file")
    parser.add_argument("--tarot", default=None, help="Path to tarot reading JSON file")
    parser.add_argument("--name", default="Querent", help="Name of the person")
    parser.add_argument("--seed", type=int, default=None, help="Random seed for reproducibility")

    args = parser.parse_args()

    if args.seed is not None:
        random.seed(args.seed)

    # Load input data
    chart_data = None
    qmdj_data = None
    tarot_data = None

    if args.chart:
        with open(args.chart, "r") as f:
            chart_data = json.load(f)

    if args.qmdj:
        with open(args.qmdj, "r") as f:
            qmdj_data = json.load(f)

    if args.tarot:
        with open(args.tarot, "r") as f:
            tarot_data = json.load(f)

    if not any([chart_data, qmdj_data, tarot_data]):
        print(json.dumps({"error": "At least one input (--chart, --qmdj, --tarot) is required"}))
        sys.exit(1)

    # Cross-system theme analysis
    themes = find_cross_system_themes(chart_data, qmdj_data, tarot_data)

    # Dominant element
    dominant_element = extract_dominant_element(chart_data)

    # Generate all sections
    sections = ["overview", "love", "career", "health", "spiritual", "timing", "advice"]
    reading_sections = []
    for section_name in sections:
        section = generate_section(section_name, chart_data, qmdj_data, tarot_data, themes, dominant_element)
        reading_sections.append(section)

    # Systems used
    systems_used = []
    if chart_data:
        systems_used.append("Western Astrology (PyEphem)")
    if qmdj_data:
        systems_used.append("Qi Men Dun Jia (奇门遁甲)")
    if tarot_data:
        systems_used.append("Tarot (Rider-Waite)")

    # Overall confidence
    avg_confidence = sum(s["confidence_level"] for s in reading_sections) / len(reading_sections)

    result = {
        "reading_for": args.name,
        "generated_at": datetime.now().isoformat(),
        "systems_used": systems_used,
        "cross_system_themes": themes,
        "dominant_element": dominant_element,
        "sections": reading_sections,
        "overall_confidence": round(avg_confidence, 1),
        "methodology_note": (
            "This reading synthesizes real astronomical computation (planetary positions via PyEphem), "
            "traditional Chinese metaphysics (Qi Men Dun Jia sexagenary cycles and palace arrangements), "
            "and Jungian archetypal psychology (Tarot as a mirror of the individuation process). "
            "Barnum/Forer statements are included to enhance personal resonance — "
            "the reader should reflect on which statements genuinely apply rather than accepting all uncritically."
        ),
    }

    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
