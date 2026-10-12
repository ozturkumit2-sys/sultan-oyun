"""Draws the original launcher icon (gold perfume bottle on deep plum) at high resolution.
Run: python3 _dev/gen_icons.py"""
from PIL import Image, ImageDraw, ImageFilter
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")
UI = os.path.join(ROOT, "assets", "ui")
os.makedirs(UI, exist_ok=True)
S = 1728  # 4x of 432
GOLD = (201, 165, 90)
GOLD2 = (236, 214, 156)
DARK = (23, 19, 27)


def background(size):
    img = Image.new("RGB", (size, size), (16, 13, 18))
    d = ImageDraw.Draw(img)
    cx, cy = size * 0.5, size * 0.42
    for i in range(120, 0, -1):
        r = size * 0.95 * i / 120
        t = i / 120
        col = (int(16 + (70 - 16) * (1 - t) ** 1.6), int(13 + (34 - 13) * (1 - t) ** 1.6), int(18 + (58 - 18) * (1 - t) ** 1.6))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)
    return img.filter(ImageFilter.GaussianBlur(size / 80))


def bottle_mask(size, scale=1.0):
    """Faceted bottle + cap + collar silhouette, centered, as an L mask."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    c = size / 2
    u = size / 432 * scale
    # body: rounded faceted shape
    bw, bh, by = 190 * u, 175 * u, c + 55 * u
    d.rounded_rectangle([c - bw / 2, by - bh / 2, c + bw / 2, by + bh / 2], radius=34 * u, fill=255)
    # shoulders
    d.polygon([(c - bw / 2 + 18 * u, by - bh / 2 + 4 * u), (c - 34 * u, by - bh / 2 - 26 * u), (c + 34 * u, by - bh / 2 - 26 * u), (c + bw / 2 - 18 * u, by - bh / 2 + 4 * u)], fill=255)
    # neck / collar
    d.rectangle([c - 24 * u, by - bh / 2 - 50 * u, c + 24 * u, by - bh / 2 - 22 * u], fill=255)
    # cap: tall faceted stopper
    d.polygon([(c - 44 * u, by - bh / 2 - 54 * u), (c - 30 * u, by - bh / 2 - 128 * u), (c + 30 * u, by - bh / 2 - 128 * u), (c + 44 * u, by - bh / 2 - 54 * u)], fill=255)
    return m


def gold_fill(size):
    g = Image.new("RGB", (size, size))
    d = ImageDraw.Draw(g)
    for y in range(size):
        t = y / size
        a = 0.5 + 0.5 * __import__("math").cos(t * 6.0)
        col = tuple(int(GOLD[i] + (GOLD2[i] - GOLD[i]) * a) for i in range(3))
        d.line([(0, y), (size, y)], fill=col)
    return g


def details(img, size, scale=1.0, col=DARK):
    d = ImageDraw.Draw(img)
    c = size / 2
    u = size / 432 * scale
    by, bh, bw = c + 55 * u, 175 * u, 190 * u
    # inner window of the bottle (liquid)
    d.rounded_rectangle([c - bw / 2 + 22 * u, by - bh / 2 + 30 * u, c + bw / 2 - 22 * u, by + bh / 2 - 22 * u], radius=20 * u, outline=col + (255,) if len(col) == 3 else col, width=int(7 * u))
    # monogram: stylised "PE" drop
    r = 30 * u
    d.ellipse([c - r, by - r + 8 * u, c + r, by + r + 8 * u], outline=col + (255,) if len(col) == 3 else col, width=int(7 * u))
    d.polygon([(c, by - 46 * u), (c - 21 * u, by - 12 * u), (c + 21 * u, by - 12 * u)], fill=col)
    # collar band
    d.rectangle([c - 30 * u, by - bh / 2 - 34 * u, c + 30 * u, by - bh / 2 - 26 * u], fill=col)
    # cap facets
    d.line([(c, by - bh / 2 - 124 * u), (c, by - bh / 2 - 58 * u)], fill=col, width=int(5 * u))


def foreground(size, scale):
    fg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    m = bottle_mask(size, scale)
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 150), (0, 0), m.filter(ImageFilter.GaussianBlur(size / 60)))
    fg = Image.alpha_composite(fg, shadow.transform(shadow.size, Image.AFFINE, (1, 0, 0, 0, 1, -size / 70)))
    gold = gold_fill(size).convert("RGBA")
    gold.putalpha(m)
    fg = Image.alpha_composite(fg, gold)
    details(fg, size, scale, DARK)
    # highlight on the left shoulder
    hl = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    u = size / 432 * scale
    c = size / 2
    hd.rounded_rectangle([c - 82 * u, c + 10 * u, c - 70 * u, c + 100 * u], radius=6 * u, fill=(255, 245, 220, 110))
    fg = Image.alpha_composite(fg, hl)
    return fg


def save(img, name, px):
    img.resize((px, px), Image.LANCZOS).save(os.path.join(UI, name))


bg = background(S)
fg = foreground(S, 0.82)       # adaptive foreground: keep inside the 66% safe zone
save(bg, "icon_bg_432.png", 432)
save(fg, "icon_fg_432.png", 432)
mono = Image.new("RGBA", (S, S), (0, 0, 0, 0))
mm = bottle_mask(S, 0.82)
mono.paste((255, 255, 255, 255), (0, 0), mm)
details(mono, S, 0.82, (0, 0, 0, 0))
save(mono, "icon_mono_432.png", 432)
full = bg.convert("RGBA")
full = Image.alpha_composite(full, foreground(S, 1.05))
# legacy icon: rounded square
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=S * 0.2, fill=255)
legacy = Image.new("RGBA", (S, S), (0, 0, 0, 0))
legacy.paste(full, (0, 0), mask)
save(legacy, "icon_192.png", 192)
save(legacy, "icon_512.png", 512)
legacy.resize((256, 256), Image.LANCZOS).save(os.path.join(ROOT, "icon.png"))
print("icons written")
