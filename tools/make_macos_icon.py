#!/usr/bin/env python3
"""Draws the macOS application icon (packaging/macos/exam1.icns) from the design of
resources/icons/exam1.png, at 1024 px and following the macOS icon grid (824 px body,
100 px margin, soft drop shadow). Requires Pillow.

Usage: python3 tools/make_macos_icon.py [--png preview.png]
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "resources/fonts/AtkinsonHyperlegible-BoldItalic.ttf"
OUT = ROOT / "packaging/macos/exam1.icns"

SLATE = (29, 39, 51, 255)
YELLOW = (255, 212, 0, 255)
SHEET = (255, 254, 206, 255)
LINE = (190, 193, 196, 255)
SHADOW = (140, 144, 150, 255)   # grey shadow of the letters, as the original shows it

SS = 2                      # supersampling factor
CANVAS = 1024 * SS
BODY = 824 * SS             # macOS icon grid: 824 px body centred on 1024 px
MARGIN = (CANVAS - BODY) // 2

# The original 256 px design: body from 10 to 245, everything else relative to it.
SRC0, SRC_SIZE = 10, 236
K = BODY / SRC_SIZE


def p(v):
    """Maps a coordinate of the 256 px design to the supersampled canvas."""
    return MARGIN + (v - SRC0) * K


def draw_icon() -> Image.Image:
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))

    # Soft drop shadow under the body, as on standard macOS icons.
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (p(10), p(10) + 12 * SS, p(246), p(246) + 12 * SS), radius=51 * K, fill=(0, 0, 0, 90))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14 * SS)))

    body = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle((p(10), p(10), p(246), p(246)), radius=51 * K, fill=SLATE)

    # "E'1" with its shadow offset by (4, 4) in the original design.
    font = ImageFont.truetype(str(FONT), round(106 * K))
    bb = d.textbbox((0, 0), "E'1", font=font)
    tx, ty = p(57) - bb[0], p(38) - bb[1]
    text_shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(text_shadow).text((tx + 4 * K, ty + 4 * K), "E'1", font=font, fill=SHADOW)
    body.alpha_composite(text_shadow)
    d = ImageDraw.Draw(body)
    d.text((tx, ty), "E'1", font=font, fill=YELLOW)

    # Answer sheet with three lines.
    d.rounded_rectangle((p(43), p(141), p(213), p(215)), radius=7 * K, fill=SHEET)
    for y, x_end in ((162.5, 187), (177.5, 162), (192.5, 174)):
        h = 6 * K
        d.rounded_rectangle((p(58), p(y) - h / 2, p(x_end), p(y) + h / 2), radius=h / 2, fill=LINE)

    canvas.alpha_composite(body)
    return canvas.resize((1024, 1024), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--png", help="also save a 1024 px PNG preview")
    args = ap.parse_args()
    icon = draw_icon()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    icon.save(OUT, format="ICNS")
    print(f"Written {OUT}")
    if args.png:
        icon.save(args.png)
        print(f"Preview {args.png}")


if __name__ == "__main__":
    main()
