#!/usr/bin/env python3
"""
BRAND DNA TEMPLATE GENERATOR — World-Class Art Director Tool

Generate a structured Brand DNA document for any new brand.
Interactive questionnaire → outputs comprehensive DNA.json + DNA.md

Usage:
    python3 brand-dna-template.py --brand "jade-oracle" --output brands/jade-oracle/DNA-v2.json
    python3 brand-dna-template.py --blank --output template.json  (empty template)
"""

import json
import argparse
import os
from datetime import datetime

def blank_template():
    """Generate a blank brand DNA template with all fields."""
    return {
        "_meta": {
            "template_version": "2.0",
            "created": datetime.now().isoformat(),
            "created_by": "art-director-skill",
            "last_updated": None,
        },

        # ─── LAYER 1: FEELING ───
        "feeling": {
            "_instruction": "One word. What should someone FEEL when they encounter this brand?",
            "primary_emotion": "",  # e.g., "grounded", "exhilarated", "safe", "curious"
            "secondary_emotion": "",
            "anti_emotion": "",  # What it should NEVER feel like
            "temperature": "",  # "warm" / "cool" / "neutral"
            "energy": "",  # "calm" / "energetic" / "contemplative" / "urgent"
        },

        # ─── LAYER 2: CONCEPT ───
        "concept": {
            "_instruction": "One sentence. The single idea that controls every decision.",
            "core_concept": "",  # e.g., "The apothecary for the thinking person"
            "positioning": "",  # How it's different from everything else
            "category": "",  # What category it creates or disrupts
            "competitor_reference": "",  # "Like X but for Y" or "The X of Y"
            "what_we_refuse": [],  # Things the brand will NEVER do
        },

        # ─── LAYER 3: AUDIENCE ───
        "audience": {
            "primary": {
                "description": "",
                "age_range": "",
                "values": [],
                "brands_they_love": [],
                "platforms": [],
            },
            "secondary": {
                "description": "",
            },
            "personas": [],  # List of persona descriptions
        },

        # ─── LAYER 4: VISUAL IDENTITY ───
        "visual": {
            "colors": {
                "_instruction": "Own ONE color completely. Max 5 total.",
                "primary": {"hex": "", "name": "", "pantone": ""},
                "secondary": {"hex": "", "name": ""},
                "accent": {"hex": "", "name": ""},
                "neutral_dark": {"hex": "", "name": ""},
                "neutral_light": {"hex": "", "name": ""},
            },
            "typography": {
                "display": {"font": "", "weight": "", "case": "", "spacing": ""},
                "heading": {"font": "", "weight": ""},
                "body": {"font": "", "weight": "", "size": ""},
                "caption": {"font": "", "weight": "", "spacing": ""},
                "scale_ratio": "",  # e.g., "golden (1.618)" or "perfect-fourth (1.333)"
            },
            "logo": {
                "type": "",  # "wordmark" / "monogram" / "emblem" / "symbol+type"
                "primary_mark": "",
                "secondary_mark": "",
                "lockup_variants": [],
                "construction_method": "",  # "golden ratio circles" / "geometric grid"
            },
            "photography": {
                "style": "",  # e.g., "dark moody editorial" / "bright natural lifestyle"
                "lighting": "",  # e.g., "single source side light, 3200K"
                "color_grade": "",
                "composition": "",
                "subjects": [],
                "never": [],
            },
            "illustration": {
                "style": "",
                "line_weight": "",
                "color_treatment": "",
            },
            "texture_material": {
                "paper": "",  # e.g., "600gsm cotton, deckled edge"
                "finish": "",  # e.g., "blind deboss + spot gold foil"
                "digital_texture": "",  # e.g., "film grain 3-5% opacity"
            },
            "motion": {
                "speed": "",  # "slow (1-2s)" / "medium" / "fast"
                "style": "",  # "dissolve" / "cut" / "morph"
                "feel": "",
            },
            "avoid": [],  # Visual anti-patterns
        },

        # ─── LAYER 5: VERBAL IDENTITY ───
        "voice": {
            "tone": "",  # e.g., "warm, direct, knowing"
            "personality_traits": [],
            "vocabulary": {
                "use": [],  # Words that feel like the brand
                "avoid": [],  # Words that feel wrong
            },
            "caption_formula": "",
            "tagline": "",
            "manifesto": "",
        },

        # ─── LAYER 6: BRAND CHARACTER (if applicable) ───
        "character": {
            "name": "",
            "role": "",
            "appearance": "",
            "personality": "",
            "signature_elements": [],
            "wardrobe": [],
            "ref_path": "",
        },

        # ─── LAYER 7: PRODUCT / SERVICE ───
        "product": {
            "core_offering": "",
            "pricing_tiers": [],
            "delivery_format": "",
            "differentiator": "",
        },

        # ─── LAYER 8: CONTENT STRATEGY ───
        "content": {
            "platforms": [],
            "posting_frequency": "",
            "content_categories": [],
            "grid_strategy": "",
            "hashtag_strategy": [],
            "content_pillars": [],
        },

        # ─── LAYER 9: BRAND RULES ───
        "rules": {
            "non_negotiables": [],  # 5-10 rules that can NEVER be broken
            "quality_gate": [
                "Does it pass the FEELING test?",
                "Does it pass the NAPKIN test? (drawable from memory)",
                "Does it pass the SQUINT test? (recognizable when blurred)",
                "Does it pass the FAX test? (works in B&W)",
                "Does it pass the FAVICON test? (holds at 16x16)",
                "Does it pass the TIME test? (won't date in 5 years)",
                "Does it pass the TASTE test? (would you put it in your home)",
            ],
        },

        # ─── LAYER 10: PRODUCTION SPECS ───
        "specs": {
            "social": {
                "ig_feed": "1080x1350",
                "ig_story": "1080x1920",
                "ig_profile": "320x320",
                "tiktok": "1080x1920",
                "telegram": "512x512",
            },
            "print": {
                "business_card": "3.5x2in, 300dpi, CMYK",
                "letterhead": "8.5x11in, 300dpi",
                "oracle_card": "2.75x4.75in, 300dpi",
            },
            "digital": {
                "favicon": "32x32",
                "app_icon": "512x512",
                "og_image": "1200x630",
            },
        },
    }

def print_template_summary(dna):
    """Print a summary of the brand DNA."""
    print(f"\n{'='*60}")
    print(f"  BRAND DNA: {dna.get('concept', {}).get('core_concept', 'UNNAMED')}")
    print(f"{'='*60}")

    feeling = dna.get("feeling", {})
    print(f"\n  Feeling: {feeling.get('primary_emotion', '—')}")
    print(f"  Temperature: {feeling.get('temperature', '—')}")
    print(f"  Energy: {feeling.get('energy', '—')}")

    concept = dna.get("concept", {})
    print(f"\n  Concept: {concept.get('core_concept', '—')}")
    print(f"  Category: {concept.get('category', '—')}")

    visual = dna.get("visual", {})
    colors = visual.get("colors", {})
    primary = colors.get("primary", {})
    print(f"\n  Primary Color: {primary.get('hex', '—')} ({primary.get('name', '')})")

    logo = visual.get("logo", {})
    print(f"  Logo Type: {logo.get('type', '—')}")

    voice = dna.get("voice", {})
    print(f"\n  Voice: {voice.get('tone', '—')}")

    rules = dna.get("rules", {})
    non_neg = rules.get("non_negotiables", [])
    if non_neg:
        print(f"\n  Non-Negotiables:")
        for r in non_neg[:5]:
            print(f"    • {r}")

    print()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Brand DNA template")
    parser.add_argument("--brand", help="Brand name")
    parser.add_argument("--output", help="Output file path")
    parser.add_argument("--blank", action="store_true", help="Generate blank template")
    args = parser.parse_args()

    template = blank_template()

    if args.brand:
        template["_meta"]["brand"] = args.brand

    output = args.output or f"brand-dna-{args.brand or 'template'}.json"

    with open(output, "w") as f:
        json.dump(template, f, indent=2)

    print(f"Brand DNA template generated: {output}")
    print(f"Fill in all fields, then use this as the source of truth for all brand decisions.")
    print_template_summary(template)
