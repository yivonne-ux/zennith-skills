#!/usr/bin/env python3
"""clip-scorer.py — LLM-based virality scoring for clip candidates.

Reads WhisperX transcript + scene boundaries, generates candidate clips
via sliding window, scores each via LLM prompt, and outputs ranked candidates.

Uses Gemini Flash (free tier) as primary, OpenAI as fallback.
"""

import argparse
import json
import os
import sys
import re

# --- Config ---
WINDOW_SIZE = 30       # seconds per sliding window
WINDOW_STRIDE = 10     # seconds between window starts
MERGE_GAP = 5          # merge candidates within N seconds of each other
DEFAULT_MIN_SCORE = 60
DEFAULT_MIN_DURATION = 15
DEFAULT_MAX_DURATION = 60

SCORING_PROMPTS = {
    "viral": """Rate this video segment for TikTok/Reels viral potential (0-100) AND tag it for reuse.

TRANSCRIPT: {segment_text}
CONTEXT: {context}
DURATION: {duration:.1f}s

Score these dimensions:
- Hook strength (does it grab attention in first 3 seconds?): 0-30
- Pacing/momentum (does it maintain energy?): 0-25
- Emotional resonance (does it make viewer feel something?): 0-25
- Shareability (would someone share or save this?): 0-20

Also classify for agent reuse:
- topic: 2-3 word topic summary (e.g. "meal prep tips", "brand origin story")
- hook_type: one of [question, shock, reveal, story, tip, testimonial, reaction, statistic, challenge]
- energy: one of [low, medium, high]
- mood: one of [inspiring, funny, educational, emotional, dramatic, calm, urgent, casual]
- reuse_as: 1-3 tags from [intro, hook, explainer, testimonial, cta, reaction, story, tip, broll, highlight, quote, behind-scenes]
- keywords: 3-5 searchable words from the transcript

Return ONLY valid JSON (no markdown, no backticks):
{{"total": N, "hook": N, "pacing": N, "emotion": N, "share": N, "reason": "one line", "topic": "...", "hook_type": "...", "energy": "...", "mood": "...", "reuse_as": ["..."], "keywords": ["..."]}}""",

    "brand": """Rate this video segment for BRAND MARKETING value (0-100). Score generously — authentic testimonials, product demos, real customer stories, behind-the-scenes, and relatable moments are HIGH value for brand trust.

TRANSCRIPT: {segment_text}
CONTEXT: {context}
DURATION: {duration:.1f}s

Score these dimensions (be generous for authentic, real content):
- Authenticity & Trust (real person, genuine emotion, believable story?): 0-30
- Message clarity (is there a clear takeaway or relatable moment?): 0-25
- Emotional connection (does it build trust, empathy, or aspiration?): 0-25
- Reusability (can this clip work as a standalone ad, testimonial, or social post?): 0-20

Scoring guide: 80+ = great brand content, 60-79 = usable, 40-59 = filler, <40 = skip.
Real customer testimonials with genuine emotion should score 80-95.
Product demos with clear benefits should score 75-90.

Also classify for agent reuse:
- topic: 2-3 word topic summary
- hook_type: one of [question, shock, reveal, story, tip, testimonial, reaction, statistic, challenge]
- energy: one of [low, medium, high]
- mood: one of [inspiring, funny, educational, emotional, dramatic, calm, urgent, casual]
- reuse_as: 1-3 tags from [intro, hook, explainer, testimonial, cta, reaction, story, tip, broll, highlight, quote, behind-scenes]
- keywords: 3-5 searchable words from the transcript

Return ONLY valid JSON (no markdown, no backticks):
{{"total": N, "hook": N, "pacing": N, "emotion": N, "share": N, "reason": "one line", "topic": "...", "hook_type": "...", "energy": "...", "mood": "...", "reuse_as": ["..."], "keywords": ["..."]}}""",
}

# Default scoring mode
SCORING_PROMPT = SCORING_PROMPTS["brand"]


def load_transcript(path):
    """Load WhisperX transcript JSON."""
    with open(path) as f:
        data = json.load(f)
    # Handle both {segments: [...]} and raw list formats
    if isinstance(data, list):
        return data
    return data.get("segments", [])


def load_boundaries(path):
    """Load scene boundaries JSON."""
    with open(path) as f:
        data = json.load(f)
    return data


def generate_windows(segments, window_size, stride, min_dur, max_dur):
    """Generate sliding windows over transcript segments."""
    if not segments:
        return []

    total_end = max(s["end"] for s in segments)
    windows = []
    start = 0.0

    while start < total_end - min_dur:
        end = min(start + window_size, total_end)

        # Collect segments in this window
        window_text = []
        window_segments = []
        for seg in segments:
            if seg["end"] > start and seg["start"] < end:
                window_text.append(seg["text"])
                window_segments.append(seg)

        text = " ".join(window_text).strip()
        if text and len(text) > 20:
            windows.append({
                "start": round(start, 3),
                "end": round(end, 3),
                "text": text,
                "segments": window_segments,
            })

        start += stride

    return windows


def snap_to_boundary(time_val, boundaries, tolerance=2.0):
    """Snap a time value to the nearest scene cut or silence gap."""
    best = time_val
    best_dist = tolerance

    # Check scene boundaries
    for scene in boundaries.get("scenes", []):
        for edge in [scene["start"], scene["end"]]:
            dist = abs(time_val - edge)
            if dist < best_dist:
                best = edge
                best_dist = dist

    # Check silence boundaries
    for silence in boundaries.get("silences", []):
        for edge in [silence["start"], silence["end"]]:
            dist = abs(time_val - edge)
            if dist < best_dist:
                best = edge
                best_dist = dist

    return round(best, 3)


def merge_overlapping(candidates, gap=MERGE_GAP):
    """Merge overlapping or adjacent high-score candidates."""
    if not candidates:
        return []

    # Sort by start time
    sorted_c = sorted(candidates, key=lambda c: c["start"])
    merged = [sorted_c[0].copy()]

    for c in sorted_c[1:]:
        last = merged[-1]
        if c["start"] <= last["end"] + gap:
            # Merge: extend end, keep higher score
            if c["total"] > last["total"]:
                last.update({
                    "end": max(last["end"], c["end"]),
                    "total": c["total"],
                    "hook": c["hook"],
                    "pacing": c["pacing"],
                    "emotion": c["emotion"],
                    "share": c["share"],
                    "reason": c["reason"],
                    "text": last["text"] + " " + c["text"],
                })
            else:
                last["end"] = max(last["end"], c["end"])
                last["text"] = last["text"] + " " + c["text"]
        else:
            merged.append(c.copy())

    return merged


def extract_json(text):
    """Extract JSON object from LLM response, handling markdown fences and thinking tokens."""
    # Strip markdown code fences
    text = re.sub(r"```(?:json)?\s*", "", text)
    text = re.sub(r"```", "", text)
    # Find ALL { ... } blocks and return the longest valid one (most complete JSON)
    matches = re.findall(r"\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}", text, re.DOTALL)
    best = None
    for m in matches:
        try:
            parsed = json.loads(m)
            if isinstance(parsed, dict):
                # Prefer the dict with the most keys (most complete response)
                if best is None or len(parsed) > len(best):
                    best = parsed
        except (json.JSONDecodeError, ValueError):
            continue
    if best is not None:
        return best
    raise ValueError(f"No JSON object found in: {text[:100]}")


def score_with_gemini(prompt, api_key):
    """Score via Google Gemini Flash API."""
    import urllib.request

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
    body = json.dumps({
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.3,
            "maxOutputTokens": 1024,
            "thinkingConfig": {"thinkingBudget": 0},
        },
    }).encode()

    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    resp = urllib.request.urlopen(req, timeout=30)
    data = json.loads(resp.read())

    # Gemini 2.5 may return multiple parts (thinking + response).
    # Iterate all parts, skip thinking parts, and find the one with valid JSON.
    parts = data["candidates"][0]["content"]["parts"]
    best_result = None
    for part in parts:
        # Skip thinking parts (they have a "thought" field set to True)
        if part.get("thought"):
            continue
        text = part.get("text", "").strip()
        if not text:
            continue
        try:
            result = extract_json(text)
            # Prefer the result that has sub-score keys (most complete)
            if best_result is None or "hook" in result:
                best_result = result
        except (ValueError, json.JSONDecodeError):
            continue

    if best_result is not None:
        return best_result

    # Fallback: concatenate all non-thinking parts and try once more
    all_text = " ".join(
        p.get("text", "") for p in parts if not p.get("thought")
    ).strip()
    return extract_json(all_text)


def score_with_openai(prompt, api_key):
    """Score via OpenAI API (fallback)."""
    import urllib.request

    url = "https://api.openai.com/v1/chat/completions"
    body = json.dumps({
        "model": "gpt-4o-mini",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.3,
        "max_tokens": 200,
    }).encode()

    req = urllib.request.Request(url, data=body, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}",
    })
    resp = urllib.request.urlopen(req, timeout=30)
    data = json.loads(resp.read())

    text = data["choices"][0]["message"]["content"].strip()
    return extract_json(text)


def score_window(window, context, gemini_key, openai_key):
    """Score a single window using available LLM."""
    prompt = SCORING_PROMPT.format(
        segment_text=window["text"][:500],
        context=context[:200],
        duration=window["end"] - window["start"],
    )

    try:
        if gemini_key:
            return score_with_gemini(prompt, gemini_key)
        elif openai_key:
            return score_with_openai(prompt, openai_key)
        else:
            # Fallback: heuristic scoring (no API key available)
            return heuristic_score(window)
    except Exception as e:
        print(f"  LLM scoring failed: {e}, using heuristic", file=sys.stderr)
        return heuristic_score(window)


def heuristic_score(window):
    """Simple heuristic scoring when no LLM available."""
    text = window["text"].lower()
    score = {"total": 0, "hook": 0, "pacing": 0, "emotion": 0, "share": 0, "reason": "heuristic"}

    # Hook: questions, exclamations, strong openers
    if any(w in text[:50] for w in ["?", "!", "secret", "never", "always", "best", "worst", "how to", "why"]):
        score["hook"] = 20
    else:
        score["hook"] = 10

    # Pacing: shorter sentences = better pacing
    sentences = [s for s in text.split(".") if s.strip()]
    avg_words = sum(len(s.split()) for s in sentences) / max(len(sentences), 1)
    score["pacing"] = min(25, max(5, 25 - int(avg_words)))

    # Emotion: emotional keywords
    emotion_words = ["love", "hate", "amazing", "terrible", "beautiful", "scary", "crazy", "insane",
                     "shocking", "unbelievable", "incredible", "heartbreak", "joy", "tears"]
    emotion_hits = sum(1 for w in emotion_words if w in text)
    score["emotion"] = min(25, 5 + emotion_hits * 5)

    # Shareability: actionable or surprising content
    share_words = ["tip", "hack", "trick", "secret", "lesson", "mistake", "truth", "fact",
                   "try this", "you need", "stop doing", "instead"]
    share_hits = sum(1 for w in share_words if w in text)
    score["share"] = min(20, 5 + share_hits * 5)

    score["total"] = score["hook"] + score["pacing"] + score["emotion"] + score["share"]
    score["reason"] = f"heuristic: hook={score['hook']}, words/sent={avg_words:.0f}"

    # Heuristic semantic tags
    score["hook_type"] = "question" if "?" in text[:80] else "tip" if any(w in text for w in ["tip", "hack", "how to"]) else "story"
    score["energy"] = "high" if score["pacing"] >= 18 else "low" if score["pacing"] <= 8 else "medium"
    score["mood"] = "educational" if any(w in text for w in ["learn", "how", "tip", "step"]) else "emotional" if emotion_hits >= 2 else "casual"

    # Extract top keywords (most frequent non-stopwords)
    stopwords = {"the", "a", "an", "is", "are", "was", "were", "i", "you", "we", "they", "it", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "that", "this", "so", "do", "not", "be", "have", "has", "had"}
    words = [w for w in re.findall(r'[a-z]+', text) if len(w) > 3 and w not in stopwords]
    from collections import Counter
    top_words = [w for w, _ in Counter(words).most_common(5)]
    score["keywords"] = top_words

    # Topic from first sentence
    first_sent = sentences[0].strip() if sentences else text[:40]
    topic_words = [w for w in first_sent.split()[:4] if w not in stopwords]
    score["topic"] = " ".join(topic_words[:3]) if topic_words else "general"

    # Reuse tags
    reuse = []
    if score["hook"] >= 20:
        reuse.append("hook")
    if any(w in text for w in ["tip", "hack", "how to", "step", "learn"]):
        reuse.append("tip")
    if any(w in text for w in ["story", "remember", "once", "when i"]):
        reuse.append("story")
    if "?" in text:
        reuse.append("explainer")
    if not reuse:
        reuse.append("highlight")
    score["reuse_as"] = reuse

    return score


def main():
    parser = argparse.ArgumentParser(description="Score video segments for viral clip potential")
    parser.add_argument("--transcript", required=True, help="Path to transcript.json")
    parser.add_argument("--boundaries", required=True, help="Path to boundaries.json")
    parser.add_argument("--output", required=True, help="Output path for candidates.json")
    parser.add_argument("--min-score", type=int, default=DEFAULT_MIN_SCORE)
    parser.add_argument("--min-duration", type=int, default=DEFAULT_MIN_DURATION)
    parser.add_argument("--max-duration", type=int, default=DEFAULT_MAX_DURATION)
    parser.add_argument("--scoring-mode", choices=["viral", "brand"], default="brand",
                        help="Scoring mode: 'viral' (strict TikTok) or 'brand' (generous, for marketing)")
    parser.add_argument("--window-size", type=int, default=0,
                        help="Override sliding window size in seconds (0 = auto)")
    parser.add_argument("--window-stride", type=int, default=0,
                        help="Override sliding window stride in seconds (0 = auto)")
    args = parser.parse_args()

    # Set scoring prompt based on mode
    global SCORING_PROMPT
    SCORING_PROMPT = SCORING_PROMPTS.get(args.scoring_mode, SCORING_PROMPTS["brand"])

    # Load data
    segments = load_transcript(args.transcript)
    boundaries = load_boundaries(args.boundaries)

    if not segments:
        print("No transcript segments found", file=sys.stderr)
        with open(args.output, "w") as f:
            json.dump({"candidates": [], "total": 0}, f, indent=2)
        return

    print(f"Loaded {len(segments)} transcript segments", file=sys.stderr)

    # Load API keys
    gemini_key = os.environ.get("GOOGLE_API_KEY", "")
    openai_key = os.environ.get("OPENAI_API_KEY", "")

    if not gemini_key and not openai_key:
        print("No LLM API key found (GOOGLE_API_KEY or OPENAI_API_KEY). Using heuristic scoring.", file=sys.stderr)

    # Determine total video duration from transcript
    total_duration = max(s["end"] for s in segments) if segments else 0

    # Adaptive window/stride for short videos
    if args.window_size > 0:
        window_size = args.window_size
    elif total_duration < 300:
        # Short video: use smaller windows (15-20s instead of 30s)
        window_size = max(15, min(20, int(total_duration * 0.3)))
        print(f"Short video ({total_duration:.0f}s < 300s): using window_size={window_size}s", file=sys.stderr)
    else:
        window_size = WINDOW_SIZE

    if args.window_stride > 0:
        window_stride = args.window_stride
    elif total_duration < 300:
        # Short video: smaller stride (5s instead of 10s)
        window_stride = max(3, min(5, int(window_size * 0.25)))
        print(f"Short video ({total_duration:.0f}s < 300s): using window_stride={window_stride}s", file=sys.stderr)
    else:
        window_stride = WINDOW_STRIDE

    # Generate sliding windows
    windows = generate_windows(segments, window_size, window_stride, args.min_duration, args.max_duration)
    print(f"Generated {len(windows)} candidate windows", file=sys.stderr)

    # Score each window
    scored = []
    for i, window in enumerate(windows):
        # Build context from preceding text
        context = ""
        for seg in segments:
            if seg["end"] <= window["start"] and seg["end"] > window["start"] - 30:
                context += seg["text"] + " "

        result = score_window(window, context.strip(), gemini_key, openai_key)

        if result["total"] >= args.min_score:
            scored.append({
                "start": window["start"],
                "end": window["end"],
                "text": window["text"],
                "total": result["total"],
                "hook": result.get("hook", 0),
                "pacing": result.get("pacing", 0),
                "emotion": result.get("emotion", 0),
                "share": result.get("share", 0),
                "reason": result.get("reason", ""),
                "topic": result.get("topic", ""),
                "hook_type": result.get("hook_type", ""),
                "energy": result.get("energy", "medium"),
                "mood": result.get("mood", "casual"),
                "reuse_as": result.get("reuse_as", []),
                "keywords": result.get("keywords", []),
            })

        if (i + 1) % 10 == 0:
            print(f"  Scored {i + 1}/{len(windows)} windows...", file=sys.stderr)

    print(f"Found {len(scored)} windows above threshold ({args.min_score})", file=sys.stderr)

    # Snap boundaries to scene cuts/silences
    for c in scored:
        c["start"] = snap_to_boundary(c["start"], boundaries)
        c["end"] = snap_to_boundary(c["end"], boundaries)

    # Merge overlapping candidates
    merged = merge_overlapping(scored)

    # Filter by duration — hard limits: never < 10s, never > 60s
    hard_min = max(10, args.min_duration)
    hard_max = min(60, args.max_duration)
    filtered = []
    for c in merged:
        dur = c["end"] - c["start"]
        if dur < hard_min:
            continue
        if dur > hard_max:
            # Trim to hard_max instead of discarding
            c["end"] = round(c["start"] + hard_max, 3)
            dur = hard_max
        filtered.append(c)

    # Sort by score descending
    filtered.sort(key=lambda c: c["total"], reverse=True)

    print(f"Final candidates: {len(filtered)} (after merge + duration filter)", file=sys.stderr)

    # Output
    output = {
        "candidates": filtered,
        "total": len(filtered),
        "settings": {
            "min_score": args.min_score,
            "min_duration": args.min_duration,
            "max_duration": args.max_duration,
            "window_size": window_size,
            "window_stride": window_stride,
            "total_duration": round(total_duration, 1),
        },
    }

    with open(args.output, "w") as f:
        json.dump(output, f, indent=2)

    print(f"Wrote {len(filtered)} candidates to {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
