#!/usr/bin/env python3
"""SULTAN: Hanedanın Kaderi — özgün prosedürel dokular.
Tüm dokular bu betikle sıfırdan üretilir (telifsiz, özgün)."""
import math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else "out"
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1453)


def save(name, arr, mode="RGB"):
    arr = np.clip(arr, 0, 1)
    img = Image.fromarray((arr * 255).astype(np.uint8), mode)
    img.save(os.path.join(OUT, name + ".png"), optimize=True)
    print("wrote", name, img.size)


def pnoise(n, beta=2.0, seed=None, m=None):
    """Tileable (periodic) fractal noise via FFT, normalized 0..1"""
    r = np.random.default_rng(seed) if seed is not None else rng
    m = m or n
    fx = np.fft.fftfreq(m)[None, :]
    fy = np.fft.fftfreq(n)[:, None]
    f = np.sqrt(fx * fx + fy * fy)
    f[0, 0] = 1.0
    spec = (r.normal(size=(n, m)) + 1j * r.normal(size=(n, m))) / (f ** (beta / 2.0))
    spec[0, 0] = 0
    out = np.real(np.fft.ifft2(spec))
    out -= out.min()
    out /= out.max()
    return out


def rgb(c):
    return np.array(c, dtype=np.float32)


def lerp3(a, b, t):
    t = t[..., None]
    return a * (1 - t) + b * t


# ------------------------------------------------------------- marble
def marble_field(n, seed, k=1, base=(0.94, 0.93, 0.9), vein=(0.52, 0.52, 0.56), warm=(0.9, 0.85, 0.78)):
    y, x = np.mgrid[0:n, 0:n] / n
    nz = pnoise(n, 3.4, seed)
    nz2 = pnoise(n, 3.0, seed + 1)
    v1 = np.abs(np.sin(np.pi * (x * k + y * 1 + nz * 1.3)))
    v2 = np.abs(np.sin(np.pi * (x * 1 - y * 2 + nz2 * 1.1)))
    veins = np.exp(-v1 * 7.0) * 0.6 + np.exp(-v2 * 10.0) * 0.3
    veins = veins ** 1.3
    cloud = pnoise(n, 3.0, seed + 2)
    col = lerp3(rgb(base), rgb(warm), cloud * 0.7)
    col *= (0.97 + 0.03 * pnoise(n, 1.0, seed + 5))[..., None]
    col = lerp3(col, rgb(vein), np.clip(veins, 0, 1))
    return col


save("marble", marble_field(512, 7))

# marble tiles 2x2 with grout + diamonds
n = 512
tiles = np.zeros((n, n, 3), np.float32)
h = n // 2
variants = [((0.95, 0.94, 0.91), (0.55, 0.55, 0.6)), ((0.86, 0.82, 0.8), (0.5, 0.42, 0.42)),
            ((0.88, 0.87, 0.84), (0.48, 0.5, 0.55)), ((0.96, 0.95, 0.93), (0.6, 0.58, 0.6))]
for i in range(2):
    for j in range(2):
        b_, v_ = variants[i * 2 + j]
        m = marble_field(h, 20 + i * 2 + j, k=1, base=b_, vein=v_, warm=(b_[0] - 0.05, b_[1] - 0.07, b_[2] - 0.1))
        tiles[i * h:(i + 1) * h, j * h:(j + 1) * h] = m
yy, xx = np.mgrid[0:n, 0:n]
grout = ((xx % h) < 3) | ((xx % h) > h - 3) | ((yy % h) < 3) | ((yy % h) > h - 3)
tiles[grout] = (0.32, 0.3, 0.28)
# diamonds at intersections
for cy in (0, h, n):
    for cx in (0, h, n):
        d = np.abs((xx - cx + n // 2) % n - n // 2) + np.abs((yy - cy + n // 2) % n - n // 2)
        tiles[d < 26] = (0.16, 0.18, 0.22)
        tiles[(d >= 26) & (d < 30)] = (0.72, 0.6, 0.35)
save("marble_tiles", tiles)

# ------------------------------------------------------------- wood
def wood_grain(n, m, seed, dark=(0.25, 0.15, 0.09), light=(0.45, 0.29, 0.17), lines=40):
    y, x = np.mgrid[0:n, 0:m]
    nz = pnoise(n, 2.4, seed, m)
    g = np.sin(2 * np.pi * (y / n * lines + nz * 1.6)) * 0.5 + 0.5
    g = g ** 1.2
    fine = pnoise(n, 0.6, seed + 3, m)
    streak = fine.copy()
    for k in range(1, 24):
        streak += np.roll(fine, k * 3, axis=1)
    streak /= 24.0
    streak = (streak - streak.min()) / (streak.max() - streak.min() + 1e-6)
    col = lerp3(rgb(dark), rgb(light), np.clip(g * 0.65 + streak * 0.45, 0, 1))
    return col


save("wood", wood_grain(512, 512, 11, lines=26))

# planked floor
n = 512
floor = np.zeros((n, n, 3), np.float32)
planks = 6
ph = n // planks
for p in range(planks):
    seg = wood_grain(ph, n, 40 + p, dark=(0.33, 0.2, 0.11), light=(0.55, 0.36, 0.2), lines=5)
    shade = 0.85 + 0.3 * rng.random()
    seg = seg * shade
    off = int(rng.integers(0, n))
    seg = np.roll(seg, off, axis=1)
    floor[p * ph:(p + 1) * ph] = seg
    floor[p * ph:p * ph + 2] = (0.12, 0.07, 0.04)
    cut = (off + n // 2) % n
    floor[p * ph:(p + 1) * ph, max(cut - 1, 0):cut + 1] = (0.12, 0.07, 0.04)
save("wood_floor", floor)

# ------------------------------------------------------------- plaster / stone
n = 256
pl = lerp3(rgb((0.9, 0.85, 0.76)), rgb((0.96, 0.93, 0.86)), pnoise(n, 1.4, 5))
pl *= (0.96 + 0.04 * pnoise(n, 0.5, 6))[..., None]
save("plaster", pl)

# stone paving: periodic voronoi
def voronoi_tile(n, pts_count, seed):
    r = np.random.default_rng(seed)
    pts = r.random((pts_count, 2)) * n
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    best = np.full((n, n), 1e9, np.float32)
    second = np.full((n, n), 1e9, np.float32)
    idx = np.zeros((n, n), np.int32)
    for i, (px, py) in enumerate(pts):
        dx = np.abs(xx - px); dx = np.minimum(dx, n - dx)
        dy = np.abs(yy - py); dy = np.minimum(dy, n - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < best
        second = np.where(closer, best, np.minimum(second, d))
        idx = np.where(closer, i, idx)
        best = np.where(closer, d, best)
    return idx, second - best

n = 512
idx, edge = voronoi_tile(n, 22, 3)
cols = rng.random((22, 1)) * 0.16 + rng.random((22, 3)) * 0.03
base = rgb((0.74, 0.68, 0.58))
pav = base + cols[idx] - 0.09
pav *= (0.88 + 0.22 * pnoise(n, 1.5, 9))[..., None]
pav[edge < 3.5] = (0.36, 0.32, 0.27)
pav[(edge >= 3.5) & (edge < 5.5)] *= 0.85
save("stone_paving", pav)

# ashlar blocks
n = 512
blk = np.zeros((n, n, 3), np.float32)
rows = 6
rh = n // rows
for rr in range(rows):
    x = int(rng.integers(0, 80))
    widths = []
    total = 0
    while total < n:
        w = int(rng.integers(90, 170))
        widths.append(w)
        total += w
    widths[-1] -= total - n
    pos = x
    for w in widths:
        tone = 0.9 + 0.18 * rng.random()
        c = rgb((0.8, 0.74, 0.63)) * tone
        xs = (np.arange(pos, pos + w) % n)
        blk[rr * rh:(rr + 1) * rh][:, xs] = c
        blk[rr * rh:(rr + 1) * rh][:, xs[:3]] = (0.45, 0.4, 0.34)
        pos += w
    blk[rr * rh:rr * rh + 3] = (0.45, 0.4, 0.34)
blk *= (0.85 + 0.25 * pnoise(n, 1.7, 13))[..., None]
save("stone_block", blk)

# grass
n = 512
g1 = pnoise(n, 1.2, 21)
g2 = pnoise(n, 2.4, 22)
grass = lerp3(rgb((0.17, 0.32, 0.1)), rgb((0.42, 0.58, 0.22)), np.clip((g1 * 0.6 + g2 * 0.4 - 0.5) * 1.8 + 0.5, 0, 1))
blades = pnoise(n, 0.3, 23)
grass *= (0.85 + 0.3 * blades)[..., None]
save("grass", grass)

# lead
n = 512
ld = lerp3(rgb((0.5, 0.53, 0.57)), rgb((0.62, 0.65, 0.68)), pnoise(n, 1.6, 31))
for i in range(0, n, n // 16):
    ld[:, i:i + 3] *= 0.72
    ld[:, i + 3:i + 5] *= 1.08
for j in range(0, n, n // 4):
    ld[j:j + 2, :] *= 0.8
save("lead", ld)


# ------------------------------------------------------------- drawn patterns (PIL, 4x supersample)
def canvas(w, h, bg, ss=4):
    im = Image.new("RGBA", (w * ss, h * ss), bg)
    return im, ImageDraw.Draw(im), ss


def finish(im, w, h, name, mode="RGB"):
    im = im.resize((w, h), Image.LANCZOS)
    if mode == "RGB":
        im = im.convert("RGB")
    im.save(os.path.join(OUT, name + ".png"), optimize=True)
    print("wrote", name, im.size)


def tulip(d, cx, cy, s, col, leaf, ss):
    # stylized tulip: three petals + stem + leaves
    d.line([(cx, cy), (cx, cy + s * 1.6)], fill=leaf, width=max(1, int(s * 0.12)))
    d.ellipse([cx - s * 0.9, cy + s * 0.6, cx - s * 0.1, cy + s * 1.5], fill=leaf)
    d.ellipse([cx + s * 0.1, cy + s * 0.7, cx + s * 0.9, cy + s * 1.6], fill=leaf)
    d.polygon([(cx - s * 0.5, cy), (cx - s * 0.6, cy - s * 0.9), (cx - s * 0.2, cy - s * 0.4), (cx, cy - s * 1.0),
               (cx + s * 0.2, cy - s * 0.4), (cx + s * 0.6, cy - s * 0.9), (cx + s * 0.5, cy), (cx, cy + s * 0.25)], fill=col)


def rosette(d, cx, cy, r, petal, center, n=8):
    for k in range(n):
        a = 2 * math.pi * k / n
        px, py = cx + math.cos(a) * r * 0.55, cy + math.sin(a) * r * 0.55
        d.ellipse([px - r * 0.38, py - r * 0.38, px + r * 0.38, py + r * 0.38], fill=petal)
    d.ellipse([cx - r * 0.35, cy - r * 0.35, cx + r * 0.35, cy + r * 0.35], fill=center)


def iznik(name, primary, secondary, accent, bg=(246, 243, 236, 255)):
    W = 256
    im, d, ss = canvas(W, W, bg)
    S = W * ss
    # quarter medallions at corners (form full medallion across 4 tiles)
    for (cx, cy) in [(0, 0), (S, 0), (0, S), (S, S)]:
        d.ellipse([cx - S * 0.36, cy - S * 0.36, cx + S * 0.36, cy + S * 0.36], fill=primary)
        d.ellipse([cx - S * 0.3, cy - S * 0.3, cx + S * 0.3, cy + S * 0.3], fill=bg)
        rosette(d, cx, cy, S * 0.22, secondary, accent, 8)
    # central composition
    c = S / 2
    for k in range(4):
        a = math.pi / 2 * k + math.pi / 4
        px, py = c + math.cos(a) * S * 0.2, c + math.sin(a) * S * 0.2
        d.ellipse([px - S * 0.07, py - S * 0.14, px + S * 0.07, py + S * 0.14], fill=secondary)
    rosette(d, c, c, S * 0.15, primary, accent, 10)
    d.ellipse([c - S * 0.035, c - S * 0.035, c + S * 0.035, c + S * 0.035], fill=bg)
    # tulips on edges midpoints
    for (tx, ty) in [(c, S * 0.03), (c, S * 0.97)]:
        tulip(d, tx, ty - S * 0.06, S * 0.06, accent, secondary, ss)
    # saz leaves arcs
    for k in range(4):
        a0 = k * 90
        d.arc([c - S * 0.42, c - S * 0.42, c + S * 0.42, c + S * 0.42], a0 + 20, a0 + 70, fill=primary, width=int(S * 0.02))
    # border
    d.rectangle([0, 0, S - 1, S - 1], outline=primary, width=int(S * 0.012))
    finish(im, W, W, name)


iznik("iznik", (31, 64, 150, 255), (35, 150, 160, 255), (190, 45, 40, 255))
iznik("iznik_blue", (24, 50, 135, 255), (60, 110, 190, 255), (30, 130, 170, 255))
iznik("iznik_green", (30, 110, 85, 255), (40, 150, 150, 255), (180, 50, 45, 255))

# wood ceiling: octagon & star lattice
W = 512
im, d, ss = canvas(W, W, (70, 42, 24, 255))
S = W * ss
cell = S / 2
for gy in range(-1, 3):
    for gx in range(-1, 3):
        cx, cy = gx * cell + cell / 2, gy * cell + cell / 2
        r = cell * 0.42
        pts = [(cx + r * math.cos(math.pi / 8 + k * math.pi / 4), cy + r * math.sin(math.pi / 8 + k * math.pi / 4)) for k in range(8)]
        d.polygon(pts, fill=(120, 74, 40, 255), outline=(200, 160, 80, 255))
        r2 = cell * 0.3
        star = []
        for k in range(16):
            rr = r2 if k % 2 == 0 else r2 * 0.55
            a = k * math.pi / 8
            star.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
        d.polygon(star, fill=(95, 55, 30, 255), outline=(215, 175, 90, 255))
        d.ellipse([cx - cell * 0.05, cy - cell * 0.05, cx + cell * 0.05, cy + cell * 0.05], fill=(210, 170, 80, 255))
        # small square stars at corners
        sx, sy = cx + cell / 2, cy + cell / 2
        q = cell * 0.12
        d.polygon([(sx, sy - q), (sx + q, sy), (sx, sy + q), (sx - q, sy)], fill=(140, 30, 30, 255), outline=(215, 175, 90, 255))
for k in range(0, S, int(cell)):
    d.line([(k, 0), (k, S)], fill=(50, 28, 15, 255), width=ss * 2)
    d.line([(0, k), (S, k)], fill=(50, 28, 15, 255), width=ss * 2)
finish(im, W, W, "wood_ceiling")
# add grain
wc = np.asarray(Image.open(os.path.join(OUT, "wood_ceiling.png"))).astype(np.float32) / 255
wc *= (0.88 + 0.2 * pnoise(512, 1.0, 77))[..., None]
save("wood_ceiling", wc)


# carpets
def carpet(name, field, border, medal, accent, light=(236, 212, 150, 255)):
    Wc, Hc = 512, 512
    im, d, ss = canvas(Wc, Hc, field)
    S = Wc * ss
    H = Hc * ss
    b1 = S * 0.1
    d.rectangle([0, 0, S, H], fill=border)
    d.rectangle([S * 0.025, S * 0.025, S - S * 0.025, H - S * 0.025], outline=light, width=ss * 4)
    # border motif: repeating small rosettes and diamonds
    step = S * 0.08
    for t in np.arange(step / 2, S, step):
        for (x, y) in [(t, b1 * 0.55), (t, H - b1 * 0.55)]:
            rosette(d, x, y, step * 0.38, accent, light, 6)
    for t in np.arange(step / 2, H, step):
        for (x, y) in [(b1 * 0.55, t), (S - b1 * 0.55, t)]:
            rosette(d, x, y, step * 0.38, accent, light, 6)
    d.rectangle([b1, b1, S - b1, H - b1], fill=field, outline=light, width=ss * 5)
    # field lattice of small motifs
    st = S * 0.09
    for y in np.arange(b1 + st / 2, H - b1, st):
        for x in np.arange(b1 + st / 2, S - b1, st):
            d.polygon([(x, y - st * 0.22), (x + st * 0.16, y), (x, y + st * 0.22), (x - st * 0.16, y)], fill=accent)
            d.ellipse([x - st * 0.05, y - st * 0.05, x + st * 0.05, y + st * 0.05], fill=light)
    # central medallion (star)
    cx, cy = S / 2, H / 2
    R = S * 0.24
    pts = []
    for k in range(16):
        rr = R if k % 2 == 0 else R * 0.72
        a = k * math.pi / 8
        pts.append((cx + rr * math.cos(a), cy + rr * 1.15 * math.sin(a)))
    d.polygon(pts, fill=medal, outline=light)
    d.ellipse([cx - R * 0.5, cy - R * 0.55, cx + R * 0.5, cy + R * 0.55], fill=field, outline=light, width=ss * 3)
    rosette(d, cx, cy, R * 0.35, medal, light, 8)
    # pendants
    for sgn in (-1, 1):
        py = cy + sgn * R * 1.35
        d.polygon([(cx, py - sgn * R * 0.3), (cx + R * 0.18, py), (cx, py + sgn * R * 0.12), (cx - R * 0.18, py)], fill=medal, outline=light)
    # corner quarter medallions
    for (qx, qy) in [(b1, b1), (S - b1, b1), (b1, H - b1), (S - b1, H - b1)]:
        d.pieslice([qx - R * 0.6, qy - R * 0.6, qx + R * 0.6, qy + R * 0.6], 0, 360, fill=medal)
        d.ellipse([qx - R * 0.35, qy - R * 0.35, qx + R * 0.35, qy + R * 0.35], fill=field)
    d.rectangle([b1, b1, S - b1, H - b1], outline=light, width=ss * 5)
    finish(im, Wc, Hc, name)
    a = np.asarray(Image.open(os.path.join(OUT, name + ".png"))).astype(np.float32) / 255
    a *= (0.9 + 0.12 * pnoise(512, 0.6, hash(name) % 1000))[..., None]
    save(name, a)


carpet("carpet_red", (150, 28, 32, 255), (28, 38, 80, 255), (25, 40, 95, 255), (205, 150, 60, 255))
carpet("carpet_blue", (30, 45, 100, 255), (140, 30, 35, 255), (150, 30, 40, 255), (200, 160, 70, 255))
carpet("carpet_green", (28, 92, 64, 255), (120, 30, 32, 255), (160, 40, 40, 255), (210, 175, 90, 255))

# flowers bed
W = 256
im, d, ss = canvas(W, W, (52, 92, 36, 255))
S = W * ss
r2 = np.random.default_rng(5)
cols = [(200, 30, 40, 255), (230, 190, 40, 255), (240, 235, 225, 255), (130, 40, 120, 255), (220, 90, 40, 255)]
for i in range(140):
    x, y = r2.random() * S, r2.random() * S
    c = cols[i % len(cols)]
    s = S * (0.025 + r2.random() * 0.02)
    for ox in (-S, 0, S):
        for oy in (-S, 0, S):
            d.ellipse([x + ox - s * 0.7, y + oy - s, x + ox + s * 0.7, y + oy + s * 0.6], fill=c)
            d.ellipse([x + ox - s * 0.25, y + oy - s * 0.2, x + ox + s * 0.25, y + oy + s * 0.25], fill=(60, 40, 20, 255))
finish(im, W, W, "flowers")

# gold with filigree
W = 256
gb = lerp3(rgb((0.72, 0.55, 0.24)), rgb((0.95, 0.8, 0.45)), pnoise(W, 1.2, 55))
im = Image.fromarray((gb * 255).astype(np.uint8)).convert("RGBA").resize((W * 4, W * 4))
d = ImageDraw.Draw(im)
S = W * 4
for k in range(6):
    y0 = k * S / 6
    pts = [(x, y0 + S / 12 + math.sin(x / S * 4 * math.pi) * S / 18) for x in range(0, S + 1, 8)]
    d.line(pts, fill=(120, 85, 30, 255), width=6)
    for j in range(8):
        x = j * S / 8 + S / 16
        y = y0 + S / 12 + math.sin(x / S * 4 * math.pi) * S / 18
        d.ellipse([x - 18, y - 30, x + 18, y + 4], outline=(120, 85, 30, 255), width=5)
finish(im, W, W, "gold")

# brocade (çintemani) – açık tonlu, renk çarpanıyla boyanır
W = 256
im, d, ss = canvas(W, W, (150, 150, 150, 255))
S = W * ss
motif = (252, 246, 228, 255)
for (cx, cy) in [(S * 0.25, S * 0.25), (S * 0.75, S * 0.75)]:
    for (ox, oy) in [(-0.06, -0.035), (0.06, -0.035), (0, 0.065)]:
        x, y = cx + ox * S, cy + oy * S
        d.ellipse([x - S * 0.045, y - S * 0.045, x + S * 0.045, y + S * 0.045], fill=motif)
        d.ellipse([x - S * 0.018, y - S * 0.018, x + S * 0.018, y + S * 0.018], fill=(150, 150, 150, 255))
for (cx, cy) in [(S * 0.75, S * 0.25), (S * 0.25, S * 0.75)]:
    for k in (-1, 1):
        pts = [(cx - S * 0.12 + t * S * 0.24, cy + k * S * 0.035 + math.sin(t * math.pi * 2) * S * 0.03) for t in np.linspace(0, 1, 24)]
        d.line(pts, fill=motif, width=int(S * 0.022))
finish(im, W, W, "brocade")

# dome painting (u around, v top->bottom)
Wd, Hd = 1024, 512
im, d, ss = canvas(Wd, Hd, (238, 228, 205, 255))
S, H = Wd * ss, Hd * ss
navy = (25, 40, 95, 255); red = (160, 35, 35, 255); gold = (205, 160, 70, 255); teal = (30, 120, 125, 255)
d.rectangle([0, 0, S, H * 0.12], fill=navy)
for k in range(32):
    x = k * S / 32 + S / 64
    d.ellipse([x - S / 90, H * 0.04, x + S / 90, H * 0.08], fill=gold)
d.rectangle([0, H * 0.12, S, H * 0.14], fill=gold)
lobes = 16
for k in range(lobes):
    x0 = k * S / lobes
    xm = x0 + S / lobes / 2
    d.polygon([(x0 + S * 0.004, H * 0.48), (xm, H * 0.16), (x0 + S / lobes - S * 0.004, H * 0.48)], fill=red if k % 2 == 0 else navy, outline=gold)
    d.polygon([(x0 + S * 0.012, H * 0.47), (xm, H * 0.23), (x0 + S / lobes - S * 0.012, H * 0.47)], outline=(240, 220, 170, 255))
    rosette(d, xm, H * 0.38, S * 0.012, gold, (240, 230, 210, 255), 6)
    tulip(d, xm, H * 0.28, S * 0.008, (240, 230, 210, 255), teal, ss)
d.rectangle([0, H * 0.5, S, H * 0.62], fill=navy)
# pseudo-calligraphic band (soyut çizgiler; okunabilir metin değildir)
for k in range(48):
    x = k * S / 48
    d.line([(x + S * 0.004, H * 0.6), (x + S * 0.004, H * 0.52)], fill=gold, width=ss * 3)
    d.arc([x - S * 0.006, H * 0.55, x + S * 0.014, H * 0.61], 0, 180, fill=gold, width=ss * 3)
d.rectangle([0, H * 0.62, S, H * 0.64], fill=gold)
for k in range(64):
    x = k * S / 64
    pts = [(x + t * S / 64, H * 0.72 + math.sin(t * math.pi * 2) * H * 0.04) for t in np.linspace(0, 1, 10)]
    d.line(pts, fill=teal, width=ss * 3)
    rosette(d, x + S / 128, H * 0.72, S * 0.006, red, gold, 5)
d.rectangle([0, H * 0.86, S, H], fill=red)
d.rectangle([0, H * 0.86, S, H * 0.875], fill=gold)
finish(im, Wd, Hd, "dome_paint")

# books
W = 512
im, d, ss = canvas(W, W, (60, 35, 20, 255))
S = W * ss
r3 = np.random.default_rng(9)
bcols = [(130, 30, 30), (30, 70, 45), (90, 55, 30), (30, 40, 85), (160, 120, 50), (95, 25, 55), (60, 60, 60), (150, 60, 30)]
shelves = 4
sh = S / shelves
for s_ in range(shelves):
    x = 0
    top = s_ * sh + sh * 0.12
    bot = (s_ + 1) * sh - sh * 0.06
    while x < S:
        w = S * (0.025 + r3.random() * 0.03)
        hh = (bot - top) * (0.72 + r3.random() * 0.28)
        c = bcols[int(r3.integers(0, len(bcols)))]
        tone = 0.75 + r3.random() * 0.45
        cc = tuple(int(min(255, v * tone)) for v in c) + (255,)
        d.rectangle([x, bot - hh, min(x + w, S), bot], fill=cc)
        d.rectangle([x, bot - hh * 0.8, min(x + w, S), bot - hh * 0.76], fill=(200, 160, 70, 255))
        d.rectangle([x, bot - hh * 0.25, min(x + w, S), bot - hh * 0.22], fill=(200, 160, 70, 255))
        x += w + S * 0.002
    d.rectangle([0, bot, S, (s_ + 1) * sh], fill=(85, 52, 28, 255))
finish(im, W, W, "books")

# stained glass window (arched)
W = 256
im, d, ss = canvas(W, W, (10, 10, 14, 255))
S = W * ss
d.rectangle([S * 0.12, S * 0.45, S * 0.88, S * 0.97], fill=(240, 220, 160, 255))
d.ellipse([S * 0.12, S * 0.05, S * 0.88, S * 0.85], fill=(240, 220, 160, 255))
gl = [(200, 40, 50, 255), (40, 90, 200, 255), (40, 160, 90, 255), (240, 200, 60, 255), (250, 240, 220, 255)]
r4 = np.random.default_rng(3)
for i in range(70):
    x, y = S * (0.15 + r4.random() * 0.7), S * (0.15 + r4.random() * 0.8)
    rr = S * (0.03 + r4.random() * 0.04)
    d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=gl[i % 5], outline=(40, 30, 20, 255), width=ss * 2)
rosette(d, S / 2, S * 0.4, S * 0.18, (200, 40, 50, 255), (240, 200, 60, 255), 8)
d.line([(S / 2, S * 0.45), (S / 2, S * 0.97)], fill=(40, 30, 20, 255), width=ss * 3)
mask = Image.new("L", im.size, 0)
md = ImageDraw.Draw(mask)
md.rectangle([S * 0.12, S * 0.45, S * 0.88, S * 0.97], fill=255)
md.ellipse([S * 0.12, S * 0.05, S * 0.88, S * 0.85], fill=255)
dark = Image.new("RGBA", im.size, (14, 12, 12, 255))
im = Image.composite(im, dark, mask)
finish(im, W, W, "stained_glass")

# lattice (RGBA) – 8 köşeli yıldız geçmeli kafes
W = 256
im, d, ss = canvas(W, W, (0, 0, 0, 0))
S = W * ss
gcol = (230, 190, 100, 255)
lw = int(S * 0.035)
for (cx, cy) in [(0, 0), (S, 0), (0, S), (S, S), (S / 2, S / 2)]:
    r = S * 0.36
    for rot in (0, math.pi / 4):
        pts = [(cx + r * math.cos(rot + k * math.pi / 2), cy + r * math.sin(rot + k * math.pi / 2)) for k in range(4)]
        d.line(pts + [pts[0]], fill=gcol, width=lw)
d.line([(0, S / 2), (S, S / 2)], fill=gcol, width=lw)
d.line([(S / 2, 0), (S / 2, S)], fill=gcol, width=lw)
d.rectangle([0, 0, S - 1, S - 1], outline=gcol, width=lw)
finish(im, W, W, "lattice", mode="RGBA")
print("done")
