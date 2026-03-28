#!/usr/bin/env python3
import sys

from PIL import Image


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: add-bg-color.py <input.png> <output.png> <hex>", file=sys.stderr)
        return 1

    input_path, output_path, color = sys.argv[1:4]
    color = color.strip()
    if color.startswith("#"):
        color = color[1:]
    if len(color) != 6:
        print(f"Expected a 6-digit hex color, got: {sys.argv[3]}", file=sys.stderr)
        return 1

    rgb = tuple(int(color[i:i + 2], 16) for i in (0, 2, 4))
    source = Image.open(input_path).convert("RGBA")
    background = Image.new("RGBA", source.size, rgb + (255,))
    composited = Image.alpha_composite(background, source).convert("RGBA")
    composited.save(output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
