#!/usr/bin/env python3
"""Unicode coverage audit: every non-ASCII character the game authors into a
scene, script or resource must be renderable from a bundled font.

Why this exists: on the desktop the engine silently borrows missing glyphs
from system fonts (`allow_system_fallback`), so a decorative mark like ★, ✓ or
✦ looks fine locally. The web export has no system fonts to borrow from, so
anything outside the bundled fallback chain renders as a blank tofu box. The
bug ships invisibly until it reaches a browser.

The renderable set is the union of the fonts in the runtime fallback chain
(scripts/emoji_font.gd, ``COVERAGE_FONTS``): every UI font falls back through
them, so a glyph any of them covers is safe. A glyph none of them covers is
invisible in the web build — fail before cutting a release.

Exits non-zero on any uncovered character. Wired into tools/all_audits.sh.
"""

import pathlib
import re
import struct
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHAIN_SOURCE = ROOT / "scripts" / "emoji_font.gd"

SOURCE_EXTS = (".gd", ".tscn", ".tres", ".godot", ".cfg", ".shader", ".gdshader")
SKIP_DIRS = {".git", ".godot", "export", "addons", "node_modules", "__pycache__", "tools"}


def read_cmap(path):
    """Return the set of Unicode code points a TTF/OTF advertises. Pure-python
    sfnt/cmap reader (formats 4 and 12) so the audit needs no font library."""
    data = pathlib.Path(path).read_bytes()
    base = 0
    if data[:4] == b"ttcf":
        count = struct.unpack(">I", data[8:12])[0]
        base = struct.unpack(">I", data[12:16])[0] if count else 0

    num_tables = struct.unpack(">H", data[base + 4:base + 6])[0]
    cmap_off = None
    for i in range(num_tables):
        rec = base + 12 + 16 * i
        if data[rec:rec + 4] == b"cmap":
            cmap_off = struct.unpack(">I", data[rec + 8:rec + 12])[0]
            break
    if cmap_off is None:
        return set()

    n = struct.unpack(">H", data[cmap_off + 2:cmap_off + 4])[0]
    subtables = []
    for i in range(n):
        rec = cmap_off + 4 + 8 * i
        plat, enc = struct.unpack(">HH", data[rec:rec + 4])
        sub = cmap_off + struct.unpack(">I", data[rec + 4:rec + 8])[0]
        subtables.append((plat, enc, sub))

    def pick():
        for want in [(3, 10), (0, 6), (0, 4), (3, 1), (0, 3), (0, 2), (0, 1), (0, 0), (3, 0)]:
            for plat, enc, sub in subtables:
                if (plat, enc) == want and struct.unpack(">H", data[sub:sub + 2])[0] in (4, 12):
                    return sub
        for _, _, sub in subtables:
            if struct.unpack(">H", data[sub:sub + 2])[0] in (4, 12):
                return sub
        return None

    sub = pick()
    if sub is None:
        return set()

    fmt = struct.unpack(">H", data[sub:sub + 2])[0]
    codes = set()
    if fmt == 4:
        seg = struct.unpack(">H", data[sub + 6:sub + 8])[0] // 2
        p = sub + 14
        end = struct.unpack(">%dH" % seg, data[p:p + 2 * seg]); p += 2 * seg
        p += 2  # reservedPad
        start = struct.unpack(">%dH" % seg, data[p:p + 2 * seg]); p += 2 * seg
        delta = struct.unpack(">%dh" % seg, data[p:p + 2 * seg]); p += 2 * seg
        range_off = struct.unpack(">%dH" % seg, data[p:p + 2 * seg]); p += 2 * seg
        for i in range(seg):
            for c in range(start[i], min(end[i], 0xFFFF) + 1):
                if range_off[i] == 0:
                    glyph = (c + delta[i]) & 0xFFFF
                else:
                    gp = p + 2 * i + range_off[i] + 2 * (c - start[i])
                    if gp + 2 > len(data):
                        continue
                    glyph = struct.unpack(">H", data[gp:gp + 2])[0]
                    if glyph:
                        glyph = (glyph + delta[i]) & 0xFFFF
                if glyph:
                    codes.add(c)
    elif fmt == 12:
        groups = struct.unpack(">I", data[sub + 12:sub + 16])[0]
        p = sub + 16
        for _ in range(groups):
            s, e, g = struct.unpack(">III", data[p:p + 12]); p += 12
            if g:
                codes.update(range(s, e + 1))
    return codes


def chain_fonts():
    text = CHAIN_SOURCE.read_text(encoding="utf-8")
    paths = re.findall(r'"(res://fonts/[^"]+\.ttf)"', text)
    seen = []
    for p in paths:
        if p not in seen:
            seen.append(p)
    return seen


def main():
    fonts = chain_fonts()
    if not fonts:
        print("[FAIL] no fallback fonts found in %s" % CHAIN_SOURCE.relative_to(ROOT))
        return 1

    covered = set()
    for res in fonts:
        path = ROOT / res[len("res://"):]
        if not path.exists():
            print("[FAIL] fallback font missing on disk: %s" % res)
            return 1
        covered.update(read_cmap(path))
    print("unicode_audit: %d fallback fonts, %d glyphs covered" % (len(fonts), len(covered)))

    failures = 0
    checked = 0
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file() or path.suffix not in SOURCE_EXTS:
            continue
        rel = path.relative_to(ROOT)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        checked += 1
        for lineno, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
            for ch in line:
                cp = ord(ch)
                if cp <= 127:
                    continue
                if cp not in covered:
                    print("[FAIL] %s:%d: U+%04X %r is not covered by the bundled fonts"
                          % (rel, lineno, cp, ch))
                    failures += 1

    if failures:
        print("unicode_audit: %d uncovered character(s) — add a covering font to "
              "COVERAGE_FONTS in scripts/emoji_font.gd" % failures)
        return 1
    print("unicode_audit: %d source files checked, every non-ASCII glyph is bundled" % checked)
    return 0


if __name__ == "__main__":
    sys.exit(main())
