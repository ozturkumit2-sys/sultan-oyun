"""Doku parlaklığından yükseklik → normal haritası (döşenebilir, kenar sarmalı)."""
import numpy as np
from PIL import Image, ImageFilter
import sys
SRC = "/home/claude/sultan/assets/textures/"
# doku: (güç, bulanıklık, ters [koyu=çukur ise False])
SPEC = {
    "marble": (1.2, 1.0, False),
    "marble_tiles": (3.0, 1.0, False),
    "stone_paving": (4.0, 1.5, False),
    "plaster": (2.0, 2.0, False),
    "wood": (1.5, 0.8, False),
    "wood_floor": (2.5, 0.8, False),
    "wood_ceiling": (2.0, 1.0, False),
    "stone_block": (4.0, 1.5, False),
    "iznik": (1.5, 1.0, False),
    "iznik_blue": (1.5, 1.0, False),
    "iznik_green": (1.5, 1.0, False),
    "grass": (2.5, 0.6, False),
    "lead": (2.0, 1.2, False),
    "brocade": (1.2, 0.6, False),
    "carpet_red": (1.5, 0.6, False),
    "carpet_blue": (1.5, 0.6, False),
    "carpet_green": (1.5, 0.6, False),
}

def normal_from(img, strength, blur):
    g = np.array(img.convert("L").filter(ImageFilter.GaussianBlur(blur))).astype(np.float64) / 255.0
    dx = (np.roll(g, -1, 1) - np.roll(g, 1, 1)) * 0.5
    dy = (np.roll(g, -1, 0) - np.roll(g, 1, 0)) * 0.5
    nx = -dx * strength * 8
    ny = -dy * strength * 8
    nz = np.ones_like(g)
    l = np.sqrt(nx * nx + ny * ny + nz * nz)
    n = np.stack([nx / l, -ny / l, nz / l], -1)   # OpenGL tarzı (Godot)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8))

for name, (st, bl, inv) in SPEC.items():
    try:
        im = Image.open(SRC + name + ".png")
    except FileNotFoundError:
        print("yok", name); continue
    normal_from(im, st, bl).save(SRC + name + "_n.png")
    print("ok", name, im.size)
