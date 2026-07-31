#!/usr/bin/env python3
"""Generate the game's sound effects as small 16-bit mono WAVs."""
import math
import struct
import wave
from pathlib import Path

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sfx"
OUT.mkdir(parents=True, exist_ok=True)


def write_wav(name, samples):
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples
        )
        w.writeframes(frames)
    print(f"wrote {path.name} ({len(samples)/SR:.2f}s)")


def env(i, n, attack=0.01, release=0.3):
    t = i / SR
    dur = n / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (dur - t) / release) if release > 0 else 1.0
    return a * r


def tone(freq_fn, dur, vol=0.5, attack=0.01, release=0.1, harmonics=(1.0,)):
    n = int(SR * dur)
    out = []
    phase = 0.0
    for i in range(n):
        f = freq_fn(i / n)
        phase += 2 * math.pi * f / SR
        s = sum(h * math.sin(phase * (k + 1)) for k, h in enumerate(harmonics))
        out.append(s * vol * env(i, n, attack, release))
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    return [sum(p[i] if i < len(p) else 0.0 for p in parts) for i in range(n)]


def delay(samples, seconds):
    return [0.0] * int(SR * seconds) + samples


# jump: quick upward chirp
write_wav("jump", tone(lambda t: 300 + 500 * t, 0.16, 0.4, 0.005, 0.06, (1.0, 0.3)))

# pickup: two-tone ding
write_wav(
    "pickup",
    mix(
        tone(lambda t: 880, 0.12, 0.35, 0.005, 0.08),
        delay(tone(lambda t: 1320, 0.22, 0.35, 0.005, 0.15), 0.09),
    ),
)

# talk: short soft blip
write_wav("talk", tone(lambda t: 520 - 120 * t, 0.07, 0.25, 0.005, 0.04, (1.0, 0.2)))

# door: descending whoosh
write_wav("door", tone(lambda t: 500 - 260 * t, 0.28, 0.3, 0.02, 0.18, (1.0, 0.4, 0.2)))

# click: UI tick
write_wav("click", tone(lambda t: 900, 0.05, 0.25, 0.002, 0.03))

# splash: filtered noise burst
import random

random.seed(7)
n = int(SR * 0.4)
noise = []
lp = 0.0
for i in range(n):
    lp += 0.25 * (random.uniform(-1, 1) - lp)
    noise.append(lp * 0.9 * env(i, n, 0.01, 0.3))
write_wav("splash", noise)

# medallion: rising arpeggio fanfare
notes = [523, 659, 784, 1047, 1319]
parts = []
for k, f in enumerate(notes):
    parts.append(delay(tone(lambda t, f=f: f, 0.35, 0.28, 0.01, 0.25, (1.0, 0.35, 0.1)), k * 0.12))
write_wav("medallion", mix(*parts))
