#!/usr/bin/env python3
"""
Parallel Video Generation Engine for GAIA OS.
Adapted from Tricia's parallel_sora.py — ThreadPool + semaphore + rate limiting.

Supports: Sora 2, Kling 3.0, Wan — via video-gen.sh as execution backend.

Usage:
  python3 parallel-gen.py --plan plan.json [--concurrency 5] [--output-dir ./output]
  python3 parallel-gen.py --jobs jobs.json [--concurrency 3]

Plan JSON format:
  [
    {"id": "block_1", "prompt": "...", "model": "sora", "duration": 8, "ref_image": "path.png"},
    {"id": "block_2", "prompt": "...", "model": "kling", "duration": 5},
    ...
  ]
"""
import argparse
import json
import os
import subprocess
import sys
import time
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Optional

# GAIA paths
SKILLS_DIR = Path.home() / ".openclaw" / "skills"
VIDEO_GEN = SKILLS_DIR / "video-gen" / "scripts" / "video-gen.sh"
NANOBANANA = SKILLS_DIR / "nanobanana" / "scripts" / "nanobanana-gen.sh"

# Config
MAX_CONCURRENT = int(os.environ.get("PARALLEL_GEN_MAX_CONCURRENT", "5"))
SUBMIT_DELAY = 1.5  # seconds between submissions to avoid rate limits
MAX_RETRIES = 3
RETRY_BACKOFF = [5, 15, 45]  # seconds


class JobStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    RETRYING = "retrying"


@dataclass
class Job:
    id: str
    prompt: str
    model: str = "sora"
    duration: int = 8
    ref_image: Optional[str] = None
    gen_type: str = "kol_video"  # kol_video, broll_video, product_image, text_card
    output_path: Optional[str] = None
    status: JobStatus = JobStatus.PENDING
    attempts: int = 0
    error: Optional[str] = None
    start_time: float = 0.0
    end_time: float = 0.0


@dataclass
class BatchResult:
    total: int = 0
    completed: int = 0
    failed: int = 0
    results: list = field(default_factory=list)
    total_cost: float = 0.0
    total_time: float = 0.0


# Thread-safe progress tracking
_lock = threading.Lock()
_progress = {"completed": 0, "failed": 0, "running": 0, "total": 0}


def update_progress(status_change: str):
    with _lock:
        if status_change == "start":
            _progress["running"] += 1
        elif status_change == "complete":
            _progress["running"] -= 1
            _progress["completed"] += 1
        elif status_change == "fail":
            _progress["running"] -= 1
            _progress["failed"] += 1
        done = _progress["completed"] + _progress["failed"]
        total = _progress["total"]
        running = _progress["running"]
        print(f"  [{done}/{total}] running={running} ok={_progress['completed']} fail={_progress['failed']}", flush=True)


def estimate_cost(model: str, duration: int) -> float:
    """Estimate API cost per generation."""
    costs = {
        "sora": 0.10 * duration,  # ~$0.10/s
        "kling": 0.056 * duration,  # ~$0.056/s
        "wan": 0.03 * duration,  # ~$0.03/s
        "nanobanana": 0.0,  # free tier
    }
    return costs.get(model, 0.05 * duration)


def run_video_gen(job: Job, output_dir: Path) -> str:
    """Execute video-gen.sh for a single job. Returns output path."""
    output_dir.mkdir(parents=True, exist_ok=True)

    if job.gen_type == "product_image":
        # Use nanobanana for images
        cmd = [
            "bash", str(NANOBANANA),
            "--prompt", job.prompt,
            "--output", str(output_dir / f"{job.id}.png"),
        ]
        if job.ref_image:
            cmd.extend(["--ref-image", job.ref_image])
    elif job.gen_type == "text_card":
        # Text cards: generate image with ImageMagick, then convert to video
        out_file = output_dir / f"{job.id}.mp4"
        img_file = output_dir / f"{job.id}_card.png"
        # Use Python PIL/Pillow to render text card (more portable than FFmpeg drawtext)
        try:
            from PIL import Image, ImageDraw, ImageFont
            img = Image.new("RGB", (1080, 1920), color=(10, 10, 15))
            draw = ImageDraw.Draw(img)
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 56)
            except Exception:
                font = ImageFont.load_default()
            # Word-wrap text
            words = job.prompt.split()
            lines, line = [], ""
            for w in words:
                test = f"{line} {w}".strip()
                bbox = draw.textbbox((0, 0), test, font=font)
                if bbox[2] - bbox[0] > 900:
                    lines.append(line)
                    line = w
                else:
                    line = test
            if line:
                lines.append(line)
            text = "\n".join(lines)
            bbox = draw.textbbox((0, 0), text, font=font)
            tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
            x, y = (1080 - tw) // 2, (1920 - th) // 2
            draw.text((x, y), text, fill="white", font=font)
            img.save(str(img_file))
        except ImportError:
            # Fallback: plain black frame (no text)
            cmd_img = ["ffmpeg", "-y", "-f", "lavfi", "-i",
                        f"color=c=black:s=1080x1920:d=1", "-frames:v", "1",
                        str(img_file)]
            subprocess.run(cmd_img, capture_output=True, timeout=10)
        # Convert image to video
        cmd = [
            "ffmpeg", "-y",
            "-loop", "1", "-i", str(img_file),
            "-t", str(job.duration),
            "-c:v", "libx264", "-preset", "fast", "-crf", "23",
            "-pix_fmt", "yuv420p",
            str(out_file),
        ]
    else:
        # Video generation via video-gen.sh
        # Syntax: video-gen.sh <provider> <command> "prompt" [flags]
        model = job.model or "sora"
        prompt = job.prompt

        # Sora-specific prompt engineering (from Tricia's 22 production learnings)
        if model == "sora":
            # Stabilize: steady camera, no zoom (zoom-in = #1 AI tell)
            if not any(kw in prompt.lower() for kw in ["steady", "tripod", "static", "locked"]):
                prompt = f"Steady, locked camera on tripod. {prompt}"
            # Audio fix: prefix "With audio." reduces silent video rate to ~0%
            if not prompt.lower().startswith("with audio"):
                prompt = f"With audio. {prompt}"

        if job.ref_image:
            # Image-to-video: ref image = starting frame
            # KEY LEARNING: Don't describe food appearance when using ref_image —
            # the reference carries the visual. Text descriptions override and conflict.
            cmd = [
                "bash", str(VIDEO_GEN),
                model, "image2video",
                "--image", job.ref_image,
                "--prompt", prompt,
                "--duration", str(job.duration),
            ]
            # Always portrait (9:16) — user: "must be all portrait"
            cmd.extend(["--aspect-ratio", "9:16"])
        else:
            # Pure text-to-video
            if model == "sora":
                subcmd = "generate"
            else:
                subcmd = "text2video"

            cmd = [
                "bash", str(VIDEO_GEN),
                model, subcmd, prompt,
                "--duration", str(job.duration),
            ]
            # Always portrait (9:16)
            cmd.extend(["--aspect-ratio", "9:16"])

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=600,  # 10 min max per job
    )

    if result.returncode != 0:
        raise RuntimeError(f"Generation failed: {result.stderr[:500]}")

    stdout = result.stdout.strip()

    # Find output file
    if job.gen_type == "text_card":
        return str(output_dir / f"{job.id}.mp4")

    # Strategy 1: Parse stdout for file path (video-gen.sh prints path on last line)
    for line in reversed(stdout.split("\n")):
        line = line.strip()
        if line and os.path.isfile(line):
            # Rename to job ID for consistency
            src = Path(line)
            target = output_dir / f"{job.id}{src.suffix}"
            if src != target:
                import shutil
                shutil.move(str(src), str(target))
            return str(target)
        # Also check "Video saved: /path" or "Downloaded: /path" patterns
        for prefix in ["Video saved: ", "Downloaded: "]:
            if prefix in line:
                fpath = line.split(prefix, 1)[-1].strip()
                if os.path.isfile(fpath):
                    src = Path(fpath)
                    target = output_dir / f"{job.id}{src.suffix}"
                    if src != target:
                        import shutil
                        shutil.move(str(src), str(target))
                    return str(target)

    # Strategy 2: Look for the generated file by job ID
    for ext in [".mp4", ".png", ".jpg"]:
        candidate = output_dir / f"{job.id}{ext}"
        if candidate.exists():
            return str(candidate)

    # Strategy 3: Find newest file in output dir
    files = sorted(output_dir.glob("*.*"), key=lambda f: f.stat().st_mtime, reverse=True)
    for f in files:
        if f.suffix in [".mp4", ".png", ".jpg"] and f.stat().st_mtime > job.start_time:
            # Rename to job ID for consistency
            target = output_dir / f"{job.id}{f.suffix}"
            f.rename(target)
            return str(target)

    raise RuntimeError(f"No output file found in {output_dir}. stdout: {stdout[:200]}")


def execute_job(job: Job, output_dir: Path, semaphore: threading.Semaphore) -> Job:
    """Execute a single generation job with retries and rate limiting."""
    with semaphore:
        job.status = JobStatus.RUNNING
        job.start_time = time.time()
        update_progress("start")

        for attempt in range(MAX_RETRIES):
            job.attempts = attempt + 1
            try:
                output_path = run_video_gen(job, output_dir)
                job.output_path = output_path
                job.status = JobStatus.COMPLETED
                job.end_time = time.time()
                update_progress("complete")
                elapsed = job.end_time - job.start_time
                print(f"  [{job.id}] OK in {elapsed:.1f}s → {os.path.basename(output_path)}", flush=True)
                return job

            except Exception as e:
                error_msg = str(e)
                job.error = error_msg

                # Rate limit detection
                if "429" in error_msg or "rate" in error_msg.lower():
                    wait = RETRY_BACKOFF[min(attempt, len(RETRY_BACKOFF) - 1)] * 2
                    print(f"  [{job.id}] Rate limited, waiting {wait}s...", flush=True)
                    time.sleep(wait)
                    continue

                if attempt < MAX_RETRIES - 1:
                    wait = RETRY_BACKOFF[min(attempt, len(RETRY_BACKOFF) - 1)]
                    job.status = JobStatus.RETRYING
                    print(f"  [{job.id}] Attempt {attempt + 1} failed, retrying in {wait}s: {error_msg[:100]}", flush=True)
                    time.sleep(wait)
                else:
                    job.status = JobStatus.FAILED
                    job.end_time = time.time()
                    update_progress("fail")
                    print(f"  [{job.id}] FAILED after {MAX_RETRIES} attempts: {error_msg[:200]}", flush=True)

        return job


def generate_batch(jobs: list[Job], output_dir: Path, concurrency: int = MAX_CONCURRENT) -> BatchResult:
    """Run all jobs in parallel with controlled concurrency."""
    result = BatchResult(total=len(jobs))
    _progress["total"] = len(jobs)
    _progress["completed"] = 0
    _progress["failed"] = 0
    _progress["running"] = 0

    semaphore = threading.Semaphore(concurrency)
    start_time = time.time()

    print(f"\n{'='*60}")
    print(f"PARALLEL GENERATION: {len(jobs)} jobs, concurrency={concurrency}")
    print(f"{'='*60}")

    # Estimate total cost
    total_est = sum(estimate_cost(j.model, j.duration) for j in jobs)
    print(f"Estimated cost: ${total_est:.2f}")
    print()

    with ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = {}
        for i, job in enumerate(jobs):
            # Stagger submissions
            if i > 0:
                time.sleep(SUBMIT_DELAY)
            future = executor.submit(execute_job, job, output_dir, semaphore)
            futures[future] = job

        for future in as_completed(futures):
            job = future.result()
            result.results.append({
                "id": job.id,
                "status": job.status.value,
                "output": job.output_path,
                "attempts": job.attempts,
                "error": job.error,
                "duration_s": round(job.end_time - job.start_time, 1) if job.end_time else 0,
            })
            if job.status == JobStatus.COMPLETED:
                result.completed += 1
                result.total_cost += estimate_cost(job.model, job.duration)
            else:
                result.failed += 1

    result.total_time = round(time.time() - start_time, 1)

    print(f"\n{'='*60}")
    print(f"DONE: {result.completed}/{result.total} succeeded, {result.failed} failed")
    print(f"Total time: {result.total_time}s, Est cost: ${result.total_cost:.2f}")
    print(f"{'='*60}\n")

    return result


def load_plan(plan_path: str) -> list[Job]:
    """Load jobs from a plan JSON file."""
    with open(plan_path) as f:
        data = json.load(f)

    jobs = []
    for item in data:
        jobs.append(Job(
            id=item["id"],
            prompt=item["prompt"],
            model=item.get("model", "sora"),
            duration=item.get("duration", 8),
            ref_image=item.get("ref_image"),
            gen_type=item.get("gen_type", "kol_video"),
        ))
    return jobs


def main():
    parser = argparse.ArgumentParser(description="Parallel Video Generation for GAIA OS")
    parser.add_argument("--plan", help="Path to plan JSON file with job definitions")
    parser.add_argument("--jobs", help="Alias for --plan")
    parser.add_argument("--concurrency", type=int, default=MAX_CONCURRENT, help=f"Max concurrent jobs (default: {MAX_CONCURRENT})")
    parser.add_argument("--output-dir", default="./generated", help="Output directory for generated files")
    parser.add_argument("--dry-run", action="store_true", help="Show plan without executing")
    args = parser.parse_args()

    plan_path = args.plan or args.jobs
    if not plan_path:
        print("Error: --plan or --jobs required")
        sys.exit(1)

    jobs = load_plan(plan_path)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.dry_run:
        print(f"DRY RUN: {len(jobs)} jobs")
        total_cost = 0
        for job in jobs:
            cost = estimate_cost(job.model, job.duration)
            total_cost += cost
            print(f"  {job.id}: {job.model} {job.duration}s ({job.gen_type}) ~${cost:.2f}")
        print(f"\nTotal estimated cost: ${total_cost:.2f}")
        return

    result = generate_batch(jobs, output_dir, args.concurrency)

    # Save results
    results_path = output_dir / "generation_results.json"
    with open(results_path, "w") as f:
        json.dump({
            "total": result.total,
            "completed": result.completed,
            "failed": result.failed,
            "total_time_s": result.total_time,
            "estimated_cost": round(result.total_cost, 2),
            "jobs": result.results,
        }, f, indent=2)
    print(f"Results saved to: {results_path}")


if __name__ == "__main__":
    main()
