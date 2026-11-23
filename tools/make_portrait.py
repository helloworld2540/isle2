#!/usr/bin/env python3
"""Generate dialogue portraits from world-map NPC art.

Takes a full-art NPC sheet (sprites/wm_npc/wm_<name>.png, 256x384), crops a
256x256 window starting at y=54, scales it to 140x140 and centres it on a
160x160 transparent canvas, then lays sprites/npc/frame.png on top. That is
exactly how the shipped portraits (portrait_kai.png, ...) were built, so the
result drops straight into the dialogue card.

Usage:
    python3 tools/make_portrait.py oda            # sprites/wm_npc/wm_oda.png -> sprites/npc/portrait_oda.png
    python3 tools/make_portrait.py oda kai        # several at once
    python3 tools/make_portrait.py --all          # every wm_npc/*.png that has art
    python3 tools/make_portrait.py --input a.png --output b.png

Paths are resolved relative to the project root (this tool's parent directory),
so it can be run from anywhere. Requires Pillow.
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
WM_DIR = ROOT / "sprites" / "wm_npc"
NPC_DIR = ROOT / "sprites" / "npc"
FRAME = NPC_DIR / "frame.png"

CROP_Y = 54          # top edge of the square crop in the source sheet
CROP_SIZE = 256      # crop width/height (full width of the 256px sheets)
SCALE = 140          # portrait art is scaled to this square
CANVAS = 160         # final image size
OFFSET = (CANVAS - SCALE) // 2  # centre the scaled art; 10 for 140 on 160


def build(source: Path, frame: Path = FRAME) -> Image.Image:
    art = Image.open(source).convert("RGBA")

    # Crop the square window, horizontally centred if the sheet is wider.
    cw, _ = art.size
    x0 = max(0, (cw - CROP_SIZE) // 2)
    crop = art.crop((x0, CROP_Y, x0 + CROP_SIZE, CROP_Y + CROP_SIZE))

    art_scaled = crop.resize((SCALE, SCALE), Image.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(art_scaled, (OFFSET, OFFSET))

    if frame.exists():
        canvas.alpha_composite(Image.open(frame).convert("RGBA"))
    else:
        print(f"warning: frame not found at {frame}, writing art only", file=sys.stderr)

    return canvas


def portrait_for(name: str, frame: Path = FRAME) -> Path:
    source = WM_DIR / f"wm_{name}.png"
    if not source.exists():
        raise FileNotFoundError(source)
    dest = NPC_DIR / f"portrait_{name}.png"
    build(source, frame).save(dest)
    print(f"{source.relative_to(ROOT)} -> {dest.relative_to(ROOT)}")
    return dest


def names_with_art() -> list[str]:
    return sorted(
        p.stem.removeprefix("wm_")
        for p in WM_DIR.glob("wm_*.png")
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("names", nargs="*",
                        help="islander names, e.g. oda (wm_oda.png -> portrait_oda.png)")
    parser.add_argument("--all", action="store_true",
                        help="regenerate every world-map NPC that has a sheet")
    parser.add_argument("--input", type=Path,
                        help="explicit source sheet (single portrait mode)")
    parser.add_argument("--output", type=Path,
                        help="explicit destination (single portrait mode)")
    parser.add_argument("--frame", type=Path, default=FRAME,
                        help=f"overlay frame (default: {FRAME.relative_to(ROOT)})")
    args = parser.parse_args()

    if args.input or args.output:
        if not args.input or not args.output:
            parser.error("--input and --output must be used together")
        build(args.input, args.frame).save(args.output)
        print(f"{args.input} -> {args.output}")
        return 0

    if args.all:
        names = names_with_art()
    elif args.names:
        names = args.names
    else:
        parser.error("give one or more names, or --all")

    for name in names:
        portrait_for(name, args.frame)
    return 0


if __name__ == "__main__":
    sys.exit(main())
