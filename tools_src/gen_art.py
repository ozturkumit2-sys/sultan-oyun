#!/usr/bin/env python3
"""Ana menü arka planı ve uygulama simgesi (özgün, prosedürel)."""
import math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1]
rng = np.random.default_rng(1299)


def grad(h, stops):
    ys = np.linspace(0, 1, h)
    out = np.zeros((h, 3))
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        m = (ys >= t0) & (ys <= t1)
        t = (ys[m] - t0) / max(t1 - t0, 1e-6)
        out[m] = np.array(c0) * (1 - t[:, None]) + np.array(c1) * t[:, None]
    return out


def dome(d, cx, base_y, r, col, drum=0.25, finial=True):
    d.rectangle([cx - r * 0.95, base_y - r * drum, cx + r * 0.95, base_y + 2], fill=col)
    d.pieslice([cx - r, base_y - r * drum - r * 0.95, cx + r, base_y - r * drum + r * 0.95], 180, 360, fill=col)
    if finial:
        top = base_y - r * drum - r * 0.95
        d.rectangle([cx - r * 0.03, top - r * 0.35, cx + r * 0.03, top + 2], fill=col)
        d.ellipse([cx - r * 0.07, top - r * 0.25, cx + r * 0.07, top - r * 0.11], fill=col)
        cr = r * 0.12
        d.ellipse([cx - cr, top - r * 0.55, cx + cr, top - r * 0.55 + 2 * cr], fill=col)


def minaret(d, x, base_y, h, w, col):
    d.rectangle([x - w / 2, base_y - h, x + w / 2, base_y], fill=col)
    for k in (0.55, 0.78):
        y = base_y - h * k
        d.rectangle([x - w * 0.9, y - w * 0.25, x + w * 0.9, y + w * 0.12], fill=col)
    d.polygon([(x - w * 0.6, base_y - h), (x + w * 0.6, base_y - h), (x, base_y - h - w * 4.2)], fill=col)


def cypress(d, x, base_y, h, w, col):
    pts = []
    for t in np.linspace(0, 1, 20):
        pts.append((x - w * math.sin(t * math.pi) ** 0.7 * (1 - t * 0.3), base_y - h * t))
    for t in np.linspace(1, 0, 20):
        pts.append((x + w * math.sin(t * math.pi) ** 0.7 * (1 - t * 0.3), base_y - h * t))
    d.polygon(pts, fill=col)


def menu_bg(W=1920, H=1080):
    sky = grad(H, [(0.0, (0.03, 0.05, 0.12)), (0.35, (0.09, 0.1, 0.24)), (0.55, (0.42, 0.2, 0.3)), (0.66, (0.93, 0.52, 0.27)), (0.7, (0.98, 0.74, 0.4)), (1.0, (0.98, 0.74, 0.4))])
    img = np.repeat(sky[:, None, :], W, axis=1)
    # sun glow
    yy, xx = np.mgrid[0:H, 0:W]
    sx, sy = W * 0.68, H * 0.66
    dist = np.sqrt((xx - sx) ** 2 + ((yy - sy) * 1.3) ** 2)
    glow = np.exp(-dist / (W * 0.18))
    img = img + glow[..., None] * np.array([0.5, 0.32, 0.12]) * 0.8
    img[dist < 46] = (1.0, 0.92, 0.7)
    # stars
    for _ in range(260):
        x, y = rng.integers(0, W), rng.integers(0, int(H * 0.38))
        b = rng.random() * 0.8
        img[y, x] = img[y, x] * (1 - b) + b
    im = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    horizon = int(H * 0.7)
    # far hills
    far = (64, 44, 70)
    pts = [(0, horizon)]
    for x in range(0, W + 1, 20):
        pts.append((x, horizon - 30 - 25 * math.sin(x / 210.0) - 15 * math.sin(x / 77.0 + 1)))
    pts.append((W, horizon))
    d.polygon(pts, fill=far)
    # distant city on far shore
    for i in range(12):
        x = 120 + i * 140 + rng.integers(-30, 30)
        if 1150 < x < 1450:
            continue
        dome(d, x, horizon - 40, 16 + (i % 3) * 6, (52, 34, 58), 0.3)
        if i % 2 == 0:
            minaret(d, x + 30, horizon - 38, 70, 6, (52, 34, 58))
    # sea
    sea = grad(H - horizon, [(0, (0.55, 0.32, 0.3)), (0.35, (0.2, 0.17, 0.28)), (1, (0.04, 0.06, 0.12))])
    arr = np.asarray(im).astype(np.float32) / 255
    arr[horizon:] = np.repeat(sea[:, None, :], W, axis=1)
    # sun reflection
    for y in range(horizon, H):
        t = (y - horizon) / (H - horizon)
        width = 40 + t * 260
        wob = np.sin(np.arange(W) / 7.0 + y * 0.8) * 0.5 + 0.5
        m = np.abs(np.arange(W) - sx) < width
        arr[y, m] = arr[y, m] * 0.55 + np.array([1.0, 0.75, 0.42])[None, :] * (0.45 * wob[m] * (1 - t) ** 1.5)[:, None]
    im = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    # palace silhouette on cliff (left)
    sil = (14, 12, 22)
    cliff = [(0, H), (0, int(H * 0.74)), (980, int(H * 0.74)), (1060, int(H * 0.8)), (1120, int(H * 0.86)), (1180, H)]
    d.polygon(cliff, fill=sil)
    base = int(H * 0.745)
    d.rectangle([60, base - 120, 940, base], fill=sil)
    d.rectangle([140, base - 170, 520, base - 110], fill=sil)
    # arcade windows (glowing)
    for k in range(16):
        x = 90 + k * 52
        d.rectangle([x, base - 80, x + 22, base - 30], fill=(250, 190, 100))
        d.pieslice([x, base - 92, x + 22, base - 68], 180, 360, fill=(250, 190, 100))
    for k in range(7):
        x = 170 + k * 50
        d.rectangle([x, base - 155, x + 16, base - 125], fill=(240, 170, 90))
    dome(d, 330, base - 170, 120, sil, 0.25)
    dome(d, 160, base - 120, 55, sil, 0.3)
    dome(d, 520, base - 120, 60, sil, 0.3)
    dome(d, 700, base - 120, 75, sil, 0.3)
    dome(d, 860, base - 120, 45, sil, 0.3)
    for x in (610, 790):
        for k in range(3):
            dome(d, x + k * 24 - 24, base - 120, 10, sil, 0.2, False)
    minaret(d, 60, base, 420, 20, sil)
    minaret(d, 600, base - 100, 330, 16, sil)
    # chimneys
    for k in range(5):
        x = 640 + k * 34
        d.rectangle([x, base - 175, x + 12, base - 110], fill=sil)
        d.polygon([(x - 6, base - 175), (x + 18, base - 175), (x + 6, base - 195)], fill=sil)
    for x, hh in ((990, 210), (1030, 170), (950, 160), (1080, 130)):
        cypress(d, x, int(H * 0.79) + 20, hh, 18, sil)
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    # vignette
    arr = np.asarray(im).astype(np.float32) / 255
    vy = np.linspace(-1, 1, H)[:, None]
    vx = np.linspace(-1, 1, W)[None, :]
    v = 1 - 0.35 * (vx ** 2 + vy ** 2)
    arr *= v[..., None]
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, "menu_bg.jpg"), quality=88)
    print("menu_bg")


def icon(S=512):
    ss = 4
    im = Image.new("RGBA", (S * ss, S * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    N = S * ss
    # navy rounded square with gold border
    d.rounded_rectangle([0, 0, N - 1, N - 1], radius=N * 0.2, fill=(13, 22, 48, 255))
    d.rounded_rectangle([N * 0.04, N * 0.04, N * 0.96, N * 0.96], radius=N * 0.17, outline=(210, 168, 82, 255), width=int(N * 0.018))
    gold = (222, 178, 88, 255)
    # dome
    base = N * 0.72
    dome(d, N * 0.5, base, N * 0.27, gold, 0.18)
    d.rectangle([N * 0.18, base, N * 0.82, base + N * 0.08], fill=gold)
    for k in range(5):
        x = N * 0.22 + k * N * 0.13
        d.rectangle([x, base + N * 0.015, x + N * 0.05, base + N * 0.08], fill=(13, 22, 48, 255))
        d.pieslice([x, base - N * 0.01, x + N * 0.05, base + N * 0.04], 180, 360, fill=(13, 22, 48, 255))
    minaret(d, N * 0.14, base + N * 0.08, N * 0.42, N * 0.035, gold)
    minaret(d, N * 0.86, base + N * 0.08, N * 0.42, N * 0.035, gold)
    im = im.resize((S, S), Image.LANCZOS)
    im.save(os.path.join(OUT, "icon.png"))
    print("icon")


menu_bg()
icon()
