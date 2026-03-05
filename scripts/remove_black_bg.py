#!/usr/bin/env python3
"""
Remove black backgrounds from pixel-art PNGs in Xcode asset catalogs.

Uses flood-fill from all four corners to replace pure-black (0,0,0) background
pixels with transparent (0,0,0,0), preserving black pixels enclosed within
the sprite (outlines, interior details).
"""

import os
import sys
from pathlib import Path
from collections import deque
from PIL import Image

ASSET_DIRS = [
    "CouplesQuest/Resources/Equipment.xcassets",
    "CouplesQuest/Resources/Materials.xcassets",
    "CouplesQuest/Resources/Consumables.xcassets",
    "CouplesQuest/Resources/Gems.xcassets",
]

BLACK_THRESHOLD = 10  # RGB values <= this are treated as "black background"


def is_background_black(r, g, b, a):
    """Check if a pixel is part of the black background."""
    return r <= BLACK_THRESHOLD and g <= BLACK_THRESHOLD and b <= BLACK_THRESHOLD and a > 0


def flood_fill_transparent(img):
    """Flood-fill from edges, converting black pixels to transparent."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size

    visited = set()
    queue = deque()

    # Seed from all edge pixels that are black
    for x in range(w):
        for y in [0, h - 1]:
            r, g, b, a = pixels[x, y]
            if is_background_black(r, g, b, a):
                queue.append((x, y))
                visited.add((x, y))
    for y in range(h):
        for x in [0, w - 1]:
            r, g, b, a = pixels[x, y]
            if is_background_black(r, g, b, a) and (x, y) not in visited:
                queue.append((x, y))
                visited.add((x, y))

    while queue:
        cx, cy = queue.popleft()
        pixels[cx, cy] = (0, 0, 0, 0)

        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                r, g, b, a = pixels[nx, ny]
                if is_background_black(r, g, b, a):
                    visited.add((nx, ny))
                    queue.append((nx, ny))

    return img


def process_directory(base_path, asset_dir):
    full_dir = os.path.join(base_path, asset_dir)
    if not os.path.isdir(full_dir):
        print(f"  SKIP (not found): {asset_dir}")
        return 0

    count = 0
    for root, dirs, files in os.walk(full_dir):
        for fname in files:
            if not fname.lower().endswith(".png"):
                continue
            fpath = os.path.join(root, fname)
            try:
                img = Image.open(fpath)
                processed = flood_fill_transparent(img)
                processed.save(fpath)
                count += 1
            except Exception as e:
                print(f"  ERROR processing {fpath}: {e}")
    return count


def main():
    base_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f"Base path: {base_path}")
    total = 0
    for asset_dir in ASSET_DIRS:
        print(f"Processing {asset_dir}...")
        n = process_directory(base_path, asset_dir)
        print(f"  Processed {n} images")
        total += n
    print(f"\nDone! Processed {total} images total.")


if __name__ == "__main__":
    main()
