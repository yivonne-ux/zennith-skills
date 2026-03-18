#!/usr/bin/env python3
"""visual-audit.py — Score generated image against brand DNA + reference via Gemini Vision
Modes:
  brand (default): Full brand compliance audit (11 dimensions)
  character:       Character consistency audit — checks face/body lock against refs
                   Skips logo, food, typography. Adds face_consistency + body_consistency.

Usage:
  visual-audit.py <image> <dna.json> <output.json> [reference_image] [--mode character] [--face-refs path1,path2,...] [--body-refs path1,path2,...]
"""
import sys, json, base64, os, urllib.request, urllib.error, subprocess, tempfile, datetime

def die(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)

def encode_image(path):
    if not path or not os.path.isfile(path):
        return None
    size = os.path.getsize(path)
    actual_path = path
    if size > 1_000_000:
        tmp = tempfile.NamedTemporaryFile(suffix='.jpg', delete=False)
        tmp.close()
        subprocess.run(['sips', '-Z', '1024', path, '--out', tmp.name,
                        '-s', 'format', 'jpeg', '-s', 'formatOptions', '80'],
                       capture_output=True)
        actual_path = tmp.name
    ext = actual_path.rsplit('.', 1)[-1].lower()
    mime_map = {'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png', 'webp': 'image/webp'}
    mime = mime_map.get(ext, 'image/jpeg')
    with open(actual_path, 'rb') as f:
        b64 = base64.b64encode(f.read()).decode()
    return {"inlineData": {"mimeType": mime, "data": b64}}

def parse_args(argv):
    """Parse positional + flag args."""
    positional = []
    mode = "brand"
    face_refs = []
    body_refs = []
    i = 1
    while i < len(argv):
        if argv[i] == "--mode" and i + 1 < len(argv):
            mode = argv[i + 1]
            i += 2
        elif argv[i] == "--face-refs" and i + 1 < len(argv):
            face_refs = [p.strip() for p in argv[i + 1].split(",") if p.strip()]
            i += 2
        elif argv[i] == "--body-refs" and i + 1 < len(argv):
            body_refs = [p.strip() for p in argv[i + 1].split(",") if p.strip()]
            i += 2
        else:
            positional.append(argv[i])
            i += 1
    return positional, mode, face_refs, body_refs

def main():
    positional, mode, face_refs, body_refs = parse_args(sys.argv)

    if len(positional) < 3:
        print("Usage: visual-audit.py <image> <dna.json> <output.json> [reference_image] [--mode character] [--face-refs p1,p2] [--body-refs p1,p2]")
        sys.exit(1)

    # Auto-load GEMINI_API_KEY from secrets if not in env
    if not os.environ.get("GEMINI_API_KEY"):
        secrets_path = os.path.expanduser("~/.openclaw/secrets/gemini.env")
        if os.path.isfile(secrets_path):
            with open(secrets_path) as f:
                for line in f:
                    if line.startswith("GEMINI_API_KEY="):
                        os.environ["GEMINI_API_KEY"] = line.strip().split("=", 1)[1]
                        break

    image_path = positional[0]
    dna_path = positional[1]
    output_path = positional[2]
    ref_path = positional[3] if len(positional) > 3 else None

    api_key = os.environ.get("GEMINI_API_KEY", "")
    if not api_key:
        die("GEMINI_API_KEY not set")

    if not os.path.isfile(image_path):
        die(f"Image not found: {image_path}")
    if not os.path.isfile(dna_path):
        die(f"DNA not found: {dna_path}")

    with open(dna_path) as f:
        dna = json.load(f)

    visual = dna.get("visual", {})
    colors = visual.get("colors", {})
    badges = visual.get("badges", [])
    avoid = visual.get("avoid", [])
    brand_name = dna.get("display_name", "Brand")
    tagline = dna.get("tagline", "")

    # Build parts
    parts = []
    gen_img = encode_image(image_path)
    if gen_img:
        parts.append(gen_img)
        parts.append({"text": "[GENERATED IMAGE above]"})
    else:
        die("Failed to encode generated image")

    if ref_path and os.path.isfile(ref_path):
        ref_img = encode_image(ref_path)
        if ref_img:
            parts.append(ref_img)
            parts.append({"text": "[BRAND REFERENCE IMAGE above]"})

    # Character mode: attach locked face and body refs
    if mode == "character":
        for idx, fp in enumerate(face_refs):
            if os.path.isfile(fp):
                img = encode_image(fp)
                if img:
                    parts.append(img)
                    parts.append({"text": f"[LOCKED FACE REFERENCE {idx+1} above — the character MUST look like this person]"})
        for idx, fp in enumerate(body_refs):
            if os.path.isfile(fp):
                img = encode_image(fp)
                if img:
                    parts.append(img)
                    parts.append({"text": f"[LOCKED BODY REFERENCE {idx+1} above — the character's body type MUST match this]"})

    if mode == "character":
        has_face = len(face_refs) > 0
        has_body = len(body_refs) > 0
        audit_prompt = f"""You are a CHARACTER CONSISTENCY auditor for {brand_name}.

You are checking whether a generated image of a recurring AI character matches the LOCKED reference images.
This is NOT a brand ad — do NOT score logo, badges, food, or typography.

CHARACTER RULES:
- Brand mood: {visual.get('style', 'N/A')}
- MUST AVOID: {', '.join(avoid)}

Score the GENERATED IMAGE on these dimensions (1-10 each):

**AI QUALITY:**
1. **photorealism**: Is this a PHOTOREALISTIC photograph? Score 1 if illustration/sketch/CG. Score 10 if real photo.
2. **face_quality**: Eyes, teeth, facial proportions — natural or uncanny?
3. **hand_quality**: Finger count, fusion, impossible positions. 10 if natural or hidden.
4. **artifacts**: Floating objects, blurred patches, duplicated elements, gibberish text, impossible anatomy.
5. **mood**: Does the vibe match the brand? ({visual.get('style', 'warm, wise, charismatic')})
6. **avoid_violations**: Any violations of the AVOID list? (10 if none)

**CHARACTER CONSISTENCY (CRITICAL):**
7. **face_consistency**: {"Compare the face in the GENERATED IMAGE against the LOCKED FACE REFERENCES. Same person? Same eye shape, nose, jawline, skin tone, ethnicity? Score 10 if clearly the same person. Score 1 if different person." if has_face else "No face refs provided — score based on internal consistency only."}
8. **body_consistency**: {"Compare body type against LOCKED BODY REFERENCES. Same frame, proportions, bust size, shoulder width? Score 10 if matching. Score 1 if clearly different body type." if has_body else "No body refs provided — score based on internal consistency only."}

IMPORTANT RULES:
- If photorealism < 5 OR face_quality < 5 OR face_consistency < 5, the image MUST fail.
- Face consistency is the MOST important dimension. A beautiful image of the wrong person is a FAIL.

Return ONLY valid JSON:
{{"scores": {{"photorealism": <1-10>, "face_quality": <1-10>, "hand_quality": <1-10>, "artifacts": <1-10>, "mood": <1-10>, "avoid_violations": <1-10>, "face_consistency": <1-10>, "body_consistency": <1-10>}}, "overall": <1-10>, "pass": <true/false>, "feedback": "<what matches and what drifted>", "fix_suggestions": ["<fix 1>", "<fix 2>"], "defects": ["<defect 1>", "<defect 2>"], "identity_match": "<same_person|different_person|uncertain>"}}"""
    else:
        audit_prompt = f"""You are a brand compliance auditor for {brand_name}.

BRAND RULES:
- Primary color: {colors.get('primary', 'N/A')}
- Secondary color: {colors.get('secondary', 'N/A')}
- Background color: {colors.get('background', 'N/A')}
- Typography: {visual.get('typography', {}).get('heading', 'N/A')}
- Style: {visual.get('style', 'N/A')}
- Logo placement: {visual.get('logo_placement', 'N/A')}
- Required badges: {', '.join(badges)}
- Tagline: {tagline}
- MUST AVOID: {', '.join(avoid)}

Score the GENERATED IMAGE on these dimensions (1-10 each):

**BRAND COMPLIANCE:**
1. **brand_colors**: Do the colors match the brand palette?
2. **typography**: Is the text in the right font style?
3. **layout**: Is the composition clean, professional, matching brand ad style?
4. **logo_badge**: Is the brand logo present and correctly placed? Are badges visible?
5. **food_quality**: Does the food look appetizing, vibrant, realistic?
6. **mood**: Does the overall vibe match? (warm, feminine, clean, Malaysian)
7. **avoid_violations**: Any violations of the AVOID list? (10 if none)

**AI QUALITY (CRITICAL — these override brand scores):**
8. **photorealism**: Is this a PHOTOREALISTIC photograph? Score 1 if it looks like a sketch, illustration, graphic, digital painting, or CG render. Score 10 if it looks like a real photo with real skin pores, natural light, and realistic textures.
9. **face_quality**: Check eyes (crossed? mismatched? wrong direction? uncanny stare?), teeth (too many? merged?), overall facial realism. Score 1 if eyes are obviously wrong. Score 10 if face looks natural.
10. **hand_quality**: Check hands (wrong number of fingers? fused? impossible positions?). Score 10 if hands look natural or are not visible. Score 1 if obviously deformed.
11. **artifacts**: Any AI artifacts? (floating objects, blurred patches, duplicated elements, gibberish text, impossible anatomy). Score 10 if clean, 1 if major artifacts.

{"Compare against the REFERENCE IMAGE for consistency." if ref_path else ""}

IMPORTANT: If photorealism < 5 OR face_quality < 5, the image MUST fail regardless of brand scores.

Return ONLY valid JSON:
{{"scores": {{"brand_colors": <1-10>, "typography": <1-10>, "layout": <1-10>, "logo_badge": <1-10>, "food_quality": <1-10>, "mood": <1-10>, "avoid_violations": <1-10>, "photorealism": <1-10>, "face_quality": <1-10>, "hand_quality": <1-10>, "artifacts": <1-10>}}, "overall": <1-10>, "pass": <true/false, MUST be false if photorealism<5 or face_quality<5>, "feedback": "<what's good and what needs fixing>", "fix_suggestions": ["<fix 1>", "<fix 2>"], "defects": ["<defect 1>", "<defect 2>"]}}"""

    parts.append({"text": audit_prompt})

    payload = {
        "contents": [{"parts": parts}],
        "generationConfig": {
            "temperature": 0.2,
            "responseMimeType": "application/json"
        }
    }

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json"})

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            result = json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()[:500]
        die(f"Gemini API HTTP {e.code}: {body}")

    try:
        text = result["candidates"][0]["content"]["parts"][0]["text"]
        audit = json.loads(text)
    except (KeyError, IndexError, json.JSONDecodeError) as e:
        raw = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")[:500]
        die(f"Parse error: {e}\nRaw: {raw}")

    # Add metadata
    audit["brand"] = dna.get("brand", "unknown")
    audit["image"] = image_path
    audit["reference"] = ref_path or "none"
    audit["mode"] = mode
    audit["timestamp"] = datetime.datetime.utcnow().isoformat() + "Z"
    if mode == "character":
        audit["face_refs"] = face_refs
        audit["body_refs"] = body_refs

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(audit, f, indent=2)

    # Print results
    overall = audit.get("overall", 0)
    passed = audit.get("pass", False)
    scores = audit.get("scores", {})
    feedback = audit.get("feedback", "")
    status = "PASS" if passed else "FAIL"

    print(f"  Result: {status} ({overall}/10)")
    print(f"  Scores:")
    for k, v in scores.items():
        v = int(v) if isinstance(v, (int, float)) else 0
        bar = "█" * v + "░" * (10 - v)
        print(f"    {k:20s} {bar} {v}/10")
    print(f"  Feedback: {feedback}")
    fixes = audit.get("fix_suggestions", [])
    if fixes:
        print(f"  Fixes:")
        for fix in fixes:
            print(f"    - {fix}")
    print(f"  Saved: {output_path}")

    sys.exit(0 if passed else 1)

if __name__ == "__main__":
    main()
