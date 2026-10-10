"""Döşenebilir yaprak kümesi dokusu (selvi/ağaç taçları) + normal haritası."""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import math
S = 512
rng = np.random.default_rng(21)
W = S * 2
base = Image.new("RGB", (W, W), (38, 62, 36))
d = ImageDraw.Draw(base)
hmap = Image.new("L", (W, W), 60)
dh = ImageDraw.Draw(hmap)
for i in range(9000):
    x, y = rng.random() * W, rng.random() * W
    l = rng.uniform(10, 26)
    w = l * rng.uniform(0.28, 0.45)
    a = rng.uniform(0, math.tau)
    g = rng.uniform(0.6, 1.25)
    col = (int(42 * g + rng.integers(-6, 6)), int(78 * g + rng.integers(-8, 8)), int(40 * g + rng.integers(-6, 6)))
    pts = []
    for k in range(10):
        t = k / 10 * math.tau
        px, py = math.cos(t) * l * 0.5, math.sin(t) * w * 0.5
        pts.append((x + px * math.cos(a) - py * math.sin(a), y + px * math.sin(a) + py * math.cos(a)))
    for ox in (-W, 0, W):
        for oy in (-W, 0, W):
            q = [(p[0] + ox, p[1] + oy) for p in pts]
            d.polygon(q, fill=col)
            dh.polygon(q, fill=int(90 + 140 * (i / 9000)))
base = base.filter(ImageFilter.GaussianBlur(0.8)).resize((S, S), Image.LANCZOS)
hm = hmap.filter(ImageFilter.GaussianBlur(2)).resize((S, S), Image.LANCZOS)
# derinlik gölgesi: alçak yerler koyu
h = np.array(hm).astype(float) / 255
arr = np.array(base).astype(float) * (0.55 + 0.6 * h[..., None])
Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).save("/home/claude/sultan/assets/textures/foliage.png")
dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * 10
dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * 10
n = np.stack([-dx, dy, np.ones_like(h)], -1)
n /= np.linalg.norm(n, axis=-1, keepdims=True)
Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8)).save("/home/claude/sultan/assets/textures/foliage_n.png")
print("ok")
