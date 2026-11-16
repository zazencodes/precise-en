"""Combines the single screenshots into the README's two images, mac.png and iphone.png, beside them.

Usage: compose.py DIR
DIR holds mac-review.png, mac-review-answer.png, iphone-review.png,
iphone-review-answer.png, iphone-words.png and iphone-stats.png.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

folder = Path(sys.argv[1])
WIDTH = 1760  # twice the width of GitHub's README column
GAP = 48


def load(name):
    return Image.open(folder / name).convert("RGBA")


def rounded(image):
    """Rounds an iPhone screenshot's corners like the screen's: 55 pt on a 402 pt wide screen."""
    mask = Image.new("L", image.size, 0)
    radius = round(image.width * 55 / 402)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, image.width - 1, image.height - 1), radius, fill=255)
    image.putalpha(mask)
    return image


def row(images, name):
    height = min(image.height for image in images)
    images = [image.resize((round(image.width * height / image.height), height), Image.LANCZOS) for image in images]
    canvas = Image.new("RGBA", (sum(image.width for image in images) + GAP * (len(images) - 1), height))
    x = 0
    for image in images:
        canvas.alpha_composite(image, (x, 0))
        x += image.width + GAP
    canvas.resize((WIDTH, round(height * WIDTH / canvas.width)), Image.LANCZOS).save(folder / name)


row([load("mac-review.png"), load("mac-review-answer.png")], "mac.png")
row([rounded(load(name)) for name in
     ("iphone-review.png", "iphone-review-answer.png", "iphone-words.png", "iphone-stats.png")], "iphone.png")
