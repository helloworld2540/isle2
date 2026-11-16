#!/usr/bin/env python3
"""Generate the world map's continuous surf bed.

A seamless, loopable mono wash: circularly-filtered noise shaped by a slow,
periodic swell. Because every stage wraps around the loop point, the last sample
flows into the first with no click, so it can loop forever under the BGM.

Usage: python3 tools/make_surf.py [out.wav]
Default output: sound/sfx/surf.wav
"""
import math
import random
import struct
import sys
import wave
from array import array

SR = 22050
SECONDS = 12
N = SR * SECONDS

random.seed(7)  # reproducible asset


def noise(n):
    return [random.uniform(-1.0, 1.0) for _ in range(n)]


def circular_lowpass(x, a):
    """One-pole low-pass that wraps at the loop point, so output stays periodic."""
    y = [0.0] * len(x)
    prev = x[-1]
    for i, s in enumerate(x):
        prev = a * prev + (1.0 - a) * s
        y[i] = prev
    return y


def build():
    raw = noise(N)

    # Deep body: heavily smoothed noise -> the rolling rumble of a swell.
    body = circular_lowpass(circular_lowpass(raw, 0.995), 0.99)

    # Foam: the same source minus its slow trend -> hiss riding on the crest.
    foam = [raw[i] - body[i] * 4.0 for i in range(N)]
    foam = circular_lowpass(foam, 0.55)

    out = [0.0] * N
    for i in range(N):
        t = i / N  # 0..1 over one loop
        # Two periodic swells (one slow, one off-beat) keep it from sounding metronomic.
        swell = 0.5 + 0.36 * math.sin(2.0 * math.pi * t) \
            + 0.14 * math.sin(2.0 * math.pi * 2.0 * t + 1.1)
        swell = max(0.0, swell)
        out[i] = 0.72 * body[i] * swell + 0.28 * foam[i] * (swell ** 2)

    peak = max(1e-9, max(abs(v) for v in out))
    gain = 0.42 / peak  # ~ -7.5 dBFS peak; the node trims further
    return [max(-1.0, min(1.0, v * gain)) for v in out]


def write_wav(path, samples):
    data = array("h", (int(round(v * 32767)) for v in samples))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"wrote {path}: {len(samples)} samples, {len(samples)/SR:.1f}s @ {SR} Hz")


if __name__ == "__main__":
    dest = sys.argv[1] if len(sys.argv) > 1 else "sound/sfx/surf.wav"
    write_wav(dest, build())
