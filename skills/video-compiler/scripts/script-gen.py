#!/usr/bin/env python3
"""
Script Generation for GAIA Video Compiler.
Uses ad frameworks (PAS/SLAP/UGC/Emotional) to generate structured video scripts.
LLM: Gemini Flash (free tier) or OpenAI as fallback.

Usage:
  python3 script-gen.py --brand mirra --product "Bento Box" --goal conversion \
    --framework pas --variants 3 --output scripts.json
"""
import argparse
import json
import os
import sys
from pathlib import Path

# Load env
for env_path in [
    Path.home() / ".openclaw" / ".env",
    Path.home() / ".openclaw" / "secrets" / "meta-marketing.env",
]:
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())

SKILLS_DIR = Path.home() / ".openclaw" / "skills"
BRANDS_DIR = Path.home() / ".openclaw" / "brands"
SCHEMAS_DIR = SKILLS_DIR / "video-compiler" / "schemas"


def load_brand(brand_name: str) -> dict:
    """Load brand DNA and video blocks."""
    dna_path = BRANDS_DIR / brand_name / "DNA.json"
    if dna_path.exists():
        with open(dna_path) as f:
            return json.load(f)
    return {"name": brand_name}


def load_frameworks() -> dict:
    """Load ad framework templates."""
    path = SCHEMAS_DIR / "framework_templates.json"
    with open(path) as f:
        return json.load(f)


def load_sequences() -> dict:
    """Load sequence templates."""
    path = SCHEMAS_DIR / "sequence_templates.json"
    with open(path) as f:
        return json.load(f)


def select_framework(
    frameworks: dict, goal: str, duration: str, explicit: str = None
) -> str:
    """Auto-select best framework based on goal + duration."""
    if explicit and explicit in frameworks["frameworks"]:
        return explicit

    rules = frameworks["framework_selection_rules"]

    # Try by intent
    by_intent = rules.get("by_intent", {}).get(goal, [])

    # Try by duration
    dur_key = "short" if duration == "short" else ("long" if duration == "long" else "medium")
    by_duration = rules.get("by_duration", {}).get(dur_key, [])

    # Intersection or fallback
    for fw in by_intent:
        if fw in by_duration:
            return fw
    if by_intent:
        return by_intent[0]
    if by_duration:
        return by_duration[0]
    return rules.get("default", "ugc_testimonial")


def select_sequence(sequences: dict, goal: str, duration: str) -> str:
    """Auto-select best sequence template."""
    dur_map = {
        "short": ["quick_ugc_12s"],
        "medium": ["awareness_30s", "transformation_30s", "lifestyle_30s"],
        "long": ["standard_ugc_40s", "conversion_45s", "comparison_40s"],
    }
    dur_key = "short" if duration == "short" else ("long" if duration == "long" else "medium")
    candidates = dur_map.get(dur_key, ["standard_ugc_40s"])

    templates = sequences["templates"]
    for c in candidates:
        if c in templates and goal in templates[c].get("intent", []):
            return c
    return candidates[0]


def build_prompt(
    brand: dict,
    product: str,
    goal: str,
    tone: str,
    framework: dict,
    framework_name: str,
    sequence: dict,
    num_variants: int,
    language: str = "en",
) -> str:
    """Build the LLM prompt for script generation."""
    brand_name = brand.get("name", brand.get("brand_name", "unknown"))
    brand_desc = brand.get("description", brand.get("tagline", ""))
    target = brand.get("target_audience", brand.get("audience", "general audience"))

    blocks = framework["block_structure"]
    block_desc = "\n".join(
        f"  {i+1}. [{b['label'].upper()}] ({b['aida'].upper()}, {b['duration']}): {b['description']}"
        for i, b in enumerate(blocks)
    )

    rules = "\n".join(f"  - {r}" for r in framework.get("prompt_rules", []))

    return f"""You are a UGC video ad copywriter for {brand_name}.

BRAND: {brand_name}
PRODUCT: {product}
{f"DESCRIPTION: {brand_desc}" if brand_desc else ""}
TARGET AUDIENCE: {target}
GOAL: {goal}
TONE: {tone}
LANGUAGE: {"Bahasa Malaysia / Manglish" if language in ("ms", "my", "malay") else "English"}

FRAMEWORK: {framework_name.upper()} ({framework['description']})

Generate {num_variants} video script variants. Each variant MUST follow this block structure:

{block_desc}

COPYWRITING RULES:
{rules}

ADDITIONAL RULES:
- Each block should have 1-3 sentences of dialogue/voiceover
- Word count per block: aim for ~2 words per second of duration
- Include [VISUAL] notes describing what should be shown
- Include [TEXT] notes for any text overlays
- First 3 seconds MUST hook the viewer (no brand name, no logo, just the hook)
- End with clear CTA (link in bio, order now, PM us)

Return a JSON array of {num_variants} variants. Each variant:
{{
  "variant_id": 1,
  "framework": "{framework_name}",
  "total_duration_s": <number>,
  "blocks": [
    {{
      "label": "<label>",
      "aida_phase": "<attention|interest|desire|action>",
      "block_code": "<A1-Act6>",
      "duration_s": <number>,
      "dialogue": "<voiceover text>",
      "visual": "<what to show>",
      "text_overlay": "<on-screen text or null>",
      "gen_type": "<kol_video|broll_video|product_image|text_card>"
    }}
  ]
}}

Return ONLY the JSON array, no markdown fences."""


def call_gemini(prompt: str) -> str:
    """Call Gemini Flash for script generation."""
    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        raise RuntimeError("GOOGLE_API_KEY not set")

    try:
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-2.5-flash")
        response = model.generate_content(
            prompt,
            generation_config={"temperature": 0.7, "max_output_tokens": 8192},
        )
        return response.text
    except ImportError:
        # Fallback to REST API
        import urllib.request
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
        data = json.dumps({
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.7, "maxOutputTokens": 8192},
        }).encode()
        req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
        return result["candidates"][0]["content"]["parts"][-1]["text"]


def call_openai(prompt: str) -> str:
    """Fallback to OpenAI."""
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY not set")

    import urllib.request
    url = "https://api.openai.com/v1/chat/completions"
    data = json.dumps({
        "model": "gpt-4o-mini",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.7,
        "max_tokens": 8192,
    }).encode()
    req = urllib.request.Request(url, data=data, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}",
    })
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read())
    return result["choices"][0]["message"]["content"]


def extract_json(text: str) -> list:
    """Extract JSON array from LLM response."""
    import re
    # Strip markdown fences
    text = re.sub(r"```json\s*", "", text)
    text = re.sub(r"```\s*", "", text)
    text = text.strip()

    # Try direct parse
    try:
        result = json.loads(text)
        if isinstance(result, list):
            return result
        if isinstance(result, dict) and "variants" in result:
            return result["variants"]
        return [result]
    except json.JSONDecodeError:
        pass

    # Try to find JSON array
    match = re.search(r"\[[\s\S]*\]", text)
    if match:
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            pass

    raise ValueError(f"Could not extract JSON from response: {text[:200]}...")


def validate_wpm(variants: list, max_wpm: float = 3.0) -> list:
    """Validate and trim scripts that exceed words-per-second limits."""
    for variant in variants:
        for block in variant.get("blocks", []):
            dialogue = block.get("dialogue", "")
            duration = block.get("duration_s", 5)
            words = len(dialogue.split())
            wps = words / max(duration, 1)

            if wps > max_wpm:
                # Trim to fit
                max_words = int(max_wpm * duration)
                trimmed = " ".join(dialogue.split()[:max_words])
                # Try to end at a natural break
                for punct in [".", "!", "?", ","]:
                    last_punct = trimmed.rfind(punct)
                    if last_punct > len(trimmed) * 0.6:
                        trimmed = trimmed[: last_punct + 1]
                        break
                block["dialogue"] = trimmed
                block["_trimmed"] = True
                block["_original_wps"] = round(wps, 1)
    return variants


def main():
    parser = argparse.ArgumentParser(description="Video Script Generator for GAIA OS")
    parser.add_argument("--brand", required=True, help="Brand name (e.g., mirra)")
    parser.add_argument("--product", required=True, help="Product name/description")
    parser.add_argument("--goal", default="conversion", choices=["awareness", "conversion", "retargeting"])
    parser.add_argument("--tone", default="authentic")
    parser.add_argument("--framework", default=None, help="Force specific framework (pas/slap/ugc_testimonial/emotional_storytelling)")
    parser.add_argument("--duration", default="medium", choices=["short", "medium", "long"])
    parser.add_argument("--variants", type=int, default=3)
    parser.add_argument("--language", default="en")
    parser.add_argument("--output", default="scripts.json")
    args = parser.parse_args()

    # Load configs
    brand = load_brand(args.brand)
    frameworks = load_frameworks()
    sequences = load_sequences()

    # Select framework and sequence
    fw_name = select_framework(frameworks, args.goal, args.duration, args.framework)
    seq_name = select_sequence(sequences, args.goal, args.duration)

    fw = frameworks["frameworks"][fw_name]
    seq = sequences["templates"][seq_name]

    print(f"[script-gen] Brand: {args.brand}")
    print(f"[script-gen] Framework: {fw_name} ({fw['name']})")
    print(f"[script-gen] Sequence: {seq_name} ({seq['name']})")
    print(f"[script-gen] Generating {args.variants} variants...")

    # Build prompt
    prompt = build_prompt(
        brand=brand,
        product=args.product,
        goal=args.goal,
        tone=args.tone,
        framework=fw,
        framework_name=fw_name,
        sequence=seq,
        num_variants=args.variants,
        language=args.language,
    )

    # Call LLM
    try:
        response = call_gemini(prompt)
    except Exception as e:
        print(f"[script-gen] Gemini failed ({e}), trying OpenAI...")
        response = call_openai(prompt)

    # Parse and validate
    variants = extract_json(response)
    variants = validate_wpm(variants)

    # Enrich with metadata
    output = {
        "brand": args.brand,
        "product": args.product,
        "goal": args.goal,
        "tone": args.tone,
        "framework": fw_name,
        "sequence_template": seq_name,
        "variants": variants,
    }

    # Save
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"[script-gen] Generated {len(variants)} variants → {output_path}")

    # Summary
    for i, v in enumerate(variants):
        blocks = v.get("blocks", [])
        total_dur = sum(b.get("duration_s", 0) for b in blocks)
        trimmed = sum(1 for b in blocks if b.get("_trimmed"))
        print(f"  Variant {i+1}: {len(blocks)} blocks, ~{total_dur}s{f' ({trimmed} blocks trimmed)' if trimmed else ''}")


if __name__ == "__main__":
    main()
