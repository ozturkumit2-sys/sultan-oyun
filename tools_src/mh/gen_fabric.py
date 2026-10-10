"""Döşenebilir kumaş desen maskeleri (özgün, prosedürel).
fabric_patterns.png  R: ogival lale/karanfil ağı, G: çintemani (üç benek + dalga), B: kutnu çizgileri, A: küçük yıldız/benek
fabric_weave.png     L: ince dokuma + hafif düzensizlik (albedo/pürüzlülük çarpanı)
"""
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 512
OUT = "/home/claude/sultan/assets/characters/"


def ss(img, k=4):
    return img.resize((S, S), Image.LANCZOS)


def ogee():
    W = S * 4
    im = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(im)
    # ogival kafes: sinüs eğrileri iki yönde
    for k in range(-2, 4):
        for sign in (1, -1):
            pts = []
            for i in range(0, W + 1, 8):
                y = i
                x = (k * W / 2) + sign * (W / 8) * math.sin(y / W * math.tau * 2) + W / 4
                pts.append((x % (W * 2) - W / 2 if False else x, y))
            d.line(pts, fill=255, width=W // 90)
    # lale motifleri hücre merkezlerinde
    for cy in (W / 4, 3 * W / 4):
        for cx in (W / 4, 3 * W / 4):
            ox = (W / 4) if cy > W / 2 else 0
            x0 = (cx + ox) % W
            for dx in (-W, 0, W):
                X = x0 + dx
                # lale: üç yaprak + sap
                r = W / 16
                d.ellipse([X - r * 0.55, cy - r * 1.1, X + r * 0.55, cy + r * 0.6], fill=255)
                d.ellipse([X - r * 1.2, cy - r * 0.6, X - r * 0.2, cy + r * 0.7], fill=255)
                d.ellipse([X + r * 0.2, cy - r * 0.6, X + r * 1.2, cy + r * 0.7], fill=255)
                d.rectangle([X - r * 0.08, cy + r * 0.5, X + r * 0.08, cy + r * 1.8], fill=255)
                d.ellipse([X - r * 0.9, cy + r * 1.0, X - r * 0.1, cy + r * 1.4], fill=255)
                d.ellipse([X + r * 0.1, cy + r * 1.0, X + r * 0.9, cy + r * 1.4], fill=255)
    return ss(im.filter(ImageFilter.GaussianBlur(2)))


def cintemani():
    W = S * 4
    im = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(im)
    cells = 4
    cw = W / cells
    for j in range(cells):
        for i in range(cells):
            ox = (cw / 2) if j % 2 else 0
            cx = (i * cw + ox + cw / 2) % W
            cy = j * cw + cw * 0.35
            r = cw * 0.11
            for dx, dy in ((-1.1, 0.6), (1.1, 0.6), (0, -0.6)):
                for wx in (-W, 0, W):
                    X, Y = cx + dx * r + wx, cy + dy * r
                    d.ellipse([X - r, Y - r, X + r, Y + r], fill=255)
                    d.ellipse([X - r * 0.45, Y - r * 0.45, X + r * 0.45, Y + r * 0.45], fill=0)
            # kaplan çizgisi benzeri çift dalga
            for wv in (0, 1):
                pts = []
                for t in np.linspace(-0.45, 0.45, 40):
                    x = cx + t * cw
                    y = cy + cw * (0.42 + wv * 0.08) + math.sin(t * math.tau * 1.5) * cw * 0.05
                    pts.append((x, y))
                for wx in (-W, 0, W):
                    d.line([(p[0] + wx, p[1]) for p in pts], fill=255, width=int(cw * 0.04))
    return ss(im.filter(ImageFilter.GaussianBlur(2)))


def kutnu():
    a = np.zeros((S, S))
    x = np.arange(S)[None, :] / S
    # farklı genişlikte çizgiler (kutnu kumaşı)
    for c, w, v in ((0.08, 0.05, 1.0), (0.2, 0.012, 0.6), (0.26, 0.012, 0.6), (0.45, 0.07, 1.0), (0.62, 0.02, 0.7), (0.8, 0.04, 0.9), (0.9, 0.01, 0.5)):
        dd = np.abs(((x - c + 0.5) % 1.0) - 0.5)
        a = np.maximum(a, v * (dd < w))
    # çizgi içinde ince kesik desen
    y = np.arange(S)[:, None] / S
    a *= 0.85 + 0.15 * (np.sin(y * math.tau * 64) > 0)
    return Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))


def stars():
    W = S * 2
    im = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(im)
    n = 8
    cw = W / n
    for j in range(n):
        for i in range(n):
            ox = cw / 2 if j % 2 else 0
            cx = (i * cw + ox + cw / 2)
            cy = j * cw + cw / 2
            r = cw * 0.16
            for wx in (-W, 0, W):
                pts = []
                for k in range(16):
                    ang = k / 16 * math.tau
                    rr = r if k % 2 == 0 else r * 0.45
                    pts.append((cx + wx + math.cos(ang) * rr, cy + math.sin(ang) * rr))
                d.polygon(pts, fill=255)
    return ss(im.filter(ImageFilter.GaussianBlur(1)))


def weave():
    rng = np.random.default_rng(3)
    x = np.arange(S)
    X, Y = np.meshgrid(x, x)
    f = 128
    warp = 0.5 + 0.5 * np.sin(X / S * math.tau * f)
    weft = 0.5 + 0.5 * np.sin(Y / S * math.tau * f)
    w = 0.5 * (np.where((X // 2 + Y // 2) % 2 == 0, warp, weft))
    slub = np.array(Image.fromarray((rng.random((S // 8, S)) * 255).astype(np.uint8)).resize((S, S), Image.BICUBIC)) / 255.0
    v = 0.82 + 0.1 * w + 0.08 * slub
    return Image.fromarray((np.clip(v, 0, 1) * 255).astype(np.uint8))


if __name__ == "__main__":
    r, g, b, a = ogee(), cintemani(), kutnu(), stars()
    Image.merge("RGBA", (r, g, b, a)).save(OUT + "fabric_patterns.png")
    weave().save(OUT + "fabric_weave.png")
    prev = Image.new("RGB", (S * 4, S))
    for i, ch in enumerate((r, g, b, a)):
        prev.paste(ch.convert("RGB"), (i * S, 0))
    prev.save("/tmp/claude-0/shots/fabric_prev.png")
    print("ok")
