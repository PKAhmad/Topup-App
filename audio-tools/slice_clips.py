#!/usr/bin/env python3
"""Slice one ElevenLabs generation (items separated by pauses) into per-key
clip files, compressed for speech, with loudness verification.

Usage:
  slice_clips.py INPUT.mp3 KEYS.txt OUTDIR [--noise -35] [--mindur 0.30] [--dry]
Exit 2 when the detected segment count != the key count (adjust --noise/--mindur).
"""
import re
import subprocess
import sys
from pathlib import Path


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def duration(path):
    r = run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "csv=p=0", str(path)])
    return float(r.stdout.strip())


def segments(path, noise_db, min_sil):
    dur = duration(path)
    r = run(["ffmpeg", "-i", str(path), "-af",
             f"silencedetect=noise={noise_db}dB:d={min_sil}", "-f", "null", "-"])
    starts, ends = [], []
    for line in r.stderr.splitlines():
        m = re.search(r"silence_start: ([\d.]+)", line)
        if m:
            starts.append(float(m.group(1)))
        m = re.search(r"silence_end: ([\d.]+)", line)
        if m:
            ends.append(float(m.group(1)))
    # Speech intervals = gaps between silences.
    bounds = []
    prev_end = 0.0
    for i, s in enumerate(starts):
        e = ends[i] if i < len(ends) else dur
        if s - prev_end >= 0.12:
            bounds.append((prev_end, s))
        prev_end = max(prev_end, e)
    if dur - prev_end >= 0.12:
        bounds.append((prev_end, dur))
    return bounds, dur


def mean_volume(path):
    r = run(["ffmpeg", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"])
    m = re.search(r"mean_volume: (-?[\d.]+) dB", r.stderr)
    return float(m.group(1)) if m else None


def main():
    src = Path(sys.argv[1])
    keys = [k.strip() for k in Path(sys.argv[2]).read_text().splitlines() if k.strip()]
    outdir = Path(sys.argv[3])
    noise = "-35"
    mindur = "0.30"
    dry = "--dry" in sys.argv
    for i, a in enumerate(sys.argv):
        if a == "--noise":
            noise = sys.argv[i + 1]
        if a == "--mindur":
            mindur = sys.argv[i + 1]
    segs, dur = segments(src, noise, float(mindur))
    print(f"{src.name}: duration {dur:.1f}s, {len(segs)} segments, {len(keys)} keys expected")
    for i, (a, b) in enumerate(segs):
        print(f"  seg {i + 1:2d}: {a:7.2f} -> {b:7.2f}  ({b - a:.2f}s)")
    if len(segs) != len(keys):
        print("COUNT MISMATCH — not writing files. Adjust --noise / --mindur.")
        sys.exit(2)
    if dry:
        return
    outdir.mkdir(parents=True, exist_ok=True)
    pad = 0.05
    bad = []
    for key, (a, b) in zip(keys, segs):
        out = outdir / f"{key}.mp3"
        r = run(["ffmpeg", "-y", "-v", "error", "-ss", str(max(0.0, a - pad)),
                 "-to", str(b + pad), "-i", str(src),
                 "-ac", "1", "-ar", "24000", "-b:a", "32k", str(out)])
        if r.returncode != 0:
            print(f"  ENCODE FAIL {key}: {r.stderr[:200]}")
            bad.append(key)
            continue
        mv = mean_volume(out)
        d = duration(out)
        flag = "  <-- SUSPECT" if (mv is None or mv < -45) else ""
        if flag:
            bad.append(key)
        print(f"  {key:22s} {d:5.2f}s  mean {mv} dB{flag}")
    if bad:
        print("SUSPECT/FAILED:", ", ".join(bad))
        sys.exit(3)
    print("ALL CLIPS OK")


if __name__ == "__main__":
    main()
