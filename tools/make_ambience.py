#!/usr/bin/env python3
"""Generate the two minigame ambience beds.

Both loops are built from whole numbers of cycles over their length (tones) or
from filters that wrap at the loop point (noise), so they repeat without a click.

  bench_hum.wav  - 8 s  low workshop drone + faint whir (Upcycle)
  reef_swell.wav - 14 s muffled current, slow swell (Reef Rescue)

Usage: python3 tools/make_ambience.py
Writes sound/sfx/bench_hum.wav and sound/sfx/reef_swell.wav
"""
import math
import random
import sys
import wave
from array import array

SR = 22050


def noise(n, seed):
    rng = random.Random(seed)
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def circular_lowpass(x, a):
    y = [0.0] * len(x)
    prev = x[-1]
    for i, s in enumerate(x):
        prev = a * prev + (1.0 - a) * s
        y[i] = prev
    return y


def normalize(x, peak):
    top = max(1e-9, max(abs(v) for v in x))
    g = peak / top
    return [max(-1.0, min(1.0, v * g)) for v in x]


def write_wav(path, samples):
    data = array("h", (int(round(v * 32767)) for v in samples))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"wrote {path}: {len(samples)} samples, {len(samples)/SR:.1f}s @ {SR} Hz")


def bench_hum():
    seconds = 8
    n = SR * seconds
    # Partials chosen in whole Hz: over an 8 s loop every integer frequency is
    # an exact number of cycles, so the tone rejoins itself perfectly.
    partials = [(55.0, 0.42), (110.0, 0.20), (165.0, 0.09), (220.0, 0.055), (275.0, 0.025)]
    whir = circular_lowpass(noise(n, 21), 0.97)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        u = i / n
        # Slow breathing modulation, also periodic over the loop.
        breath = 0.90 + 0.06 * math.sin(TAU * 0.25 * t) + 0.04 * math.sin(TAU * 0.5 * t + 0.7)
        v = 0.0
        for freq, amp in partials:
            v += amp * math.sin(TAU * freq * t)
        # The whir pulses like a fan seen through a window.
        whir_env = 0.5 + 0.5 * math.sin(TAU * 0.25 * t + 1.3)
        out[i] = v * breath + whir[i] * 0.06 * whir_env
    return normalize(out, 0.34)


def reef_swell():
    seconds = 14
    n = SR * seconds
    raw = noise(n, 41)
    rumble = circular_lowpass(circular_lowpass(raw, 0.999), 0.997)
    mid = circular_lowpass(noise(n, 42), 0.93)
    out = [0.0] * n
    for i in range(n):
        u = i / n
        # Two overlapping swells; the second is off-beat so it never feels looped.
        swell = 0.5 + 0.38 * math.sin(TAU * u) + 0.12 * math.sin(TAU * 2.0 * u + 2.0)
        swell = max(0.0, swell)
        out[i] = 0.80 * rumble[i] * swell + 0.20 * mid[i] * (swell ** 2)
    return normalize(out, 0.36)


TAU = 2.0 * math.pi

if __name__ == "__main__":
    write_wav("sound/sfx/bench_hum.wav", bench_hum())
    write_wav("sound/sfx/reef_swell.wav", reef_swell())
