#!/usr/bin/env python3
"""Lightly dilate dark ink in a Bandage PNG (hairline strokes → readable)."""

import argparse

try:
    from PIL import Image, ImageFilter
except ImportError as e:
    raise SystemExit("Pillow is required (pip/conda install pillow). " + str(e)) from e


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("-i", required=True, help="input PNG")
    ap.add_argument("-o", required=True, help="output PNG")
    ap.add_argument("--rounds", type=int, default=1, help="dilation rounds [default: 1]")
    args = ap.parse_args()

    im = Image.open(args.i).convert("RGBA")
    bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
    bg.paste(im, mask=im.split()[-1])
    rgb = bg.convert("RGB")

    # Ink mask + expand dark colours (invert → MaxFilter → invert)
    ink = rgb.convert("L").point(lambda p: 255 if p < 245 else 0)
    inv = Image.eval(rgb, lambda p: 255 - p)
    for _ in range(max(0, args.rounds)):
        ink = ink.filter(ImageFilter.MaxFilter(5))
        inv = inv.filter(ImageFilter.MaxFilter(5))
    thick = Image.eval(inv, lambda p: 255 - p)
    out = Image.composite(thick, Image.new("RGB", rgb.size, (255, 255, 255)), ink)
    out.save(args.o, optimize=True)
    print(f"Wrote {args.o} ({out.size[0]}x{out.size[1]})")


if __name__ == "__main__":
    main()
