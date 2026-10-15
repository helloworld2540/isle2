#!/usr/bin/env python3.15

# simple tool to create spritesheet from sprites
# usage: python3 spritesheet.py output input...

import argparse
from PIL import Image
from logging import info, warning as warn, root, INFO
from time import perf_counter
from math import gcd

root.setLevel(INFO)
def combine(input_paths: list[str], output_path: str):
    t: float = perf_counter()
    images: list[Image.Image] = []
    info(f"Processing {len(input_paths)} files")

    for path in input_paths:
        try:
            images.append(Image.open(path))
        except IsADirectoryError:
            warn(f"skip: {path} is a directory")

    sizes = []
    for image in images:
        sizes.append(image.size) if image.size not in sizes else ...

    info(f"Image sizes: {', '.join([f'{x}x{y}' for x, y in sizes])}")

    gx, gy = zip(*sizes)
    gx, gy = gcd(*gx), gcd(*gy)

    # TODO: smart positioning for larger sprites,
    #       e.g. 8x8 and 16x8 sprite in same sheet

    info(f"Detected sprite size: {gx}x{gy}")

    # TODO: find a smarter way to calculate rows*columns,
    #       maybe approximate square?
    columns = 5
    rows = ((len(images) - 1) // columns)

    width = columns * gx
    height = rows * gy

    info(f"Created {width}x{height} spritesheet with {columns}x{rows} sprites")

    sheet = Image.new("RGBA", (width, height), (0, 0 , 0, 0))

    for idx, image in enumerate(images):
        row = idx // columns
        column = idx % columns

        x = column * gx
        y = row * gy

        sheet.paste(image, (x, y))

    sheet.save(output_path)
    info(f"Compiled {len(input_paths)} files in {perf_counter() - t}s")


def main():
    parser = argparse.ArgumentParser(description="simple tool to create spritesheet from sprites")
    parser.add_argument("output", help="file to write spritesheet")
    parser.add_argument("input", nargs="*", help="files to combine into spritesheet")
    
    args = parser.parse_args()

    combine(args.input, args.output)

if __name__ == "__main__":
    main()

