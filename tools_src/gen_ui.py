#!/usr/bin/env python3
"""FUSE CHEF — arayüz ikonları ve uygulama simgesi (skia ile vektör çizim).
Kullanım: python3 gen_ui.py <proje_kökü>"""
import math
import os
import sys
import skia

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
OUT = os.path.join(ROOT, "assets/ui/icons")
os.makedirs(OUT, exist_ok=True)
INK = skia.Color(59, 36, 23)
S = 128


def col(h, a=255):
    h = h.lstrip("#")
    return skia.Color(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def lighten(h, k):
    h = h.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    if k >= 0:
        r, g, b = r + (255 - r) * k, g + (255 - g) * k, b + (255 - b) * k
    else:
        r, g, b = r * (1 + k), g * (1 + k), b * (1 + k)
    return skia.Color(int(r), int(g), int(b))


def grad_paint(h, y0, y1, k=0.22):
    p = skia.Paint(AntiAlias=True)
    p.setShader(skia.GradientShader.MakeLinear([(0, y0), (0, y1)], [lighten(h, k), lighten(h, -k * 0.8)]))
    return p


def fill(c, path, h, y0=10, y1=118, k=0.22):
    c.drawPath(path, grad_paint(h, y0, y1, k))


def stroke(c, path, w=7, color=INK):
    p = skia.Paint(AntiAlias=True, Style=skia.Paint.kStroke_Style, StrokeWidth=w, Color=color,
                   StrokeJoin=skia.Paint.kRound_Join, StrokeCap=skia.Paint.kRound_Cap)
    c.drawPath(path, p)


def shape(c, path, h, w=7, y0=10, y1=118, k=0.22):
    fill(c, path, h, y0, y1, k)
    stroke(c, path, w)


def circle_path(x, y, r):
    p = skia.Path()
    p.addCircle(x, y, r)
    return p


def rrect_path(x, y, w, h, r):
    p = skia.Path()
    p.addRRect(skia.RRect.MakeRectXY(skia.Rect.MakeXYWH(x, y, w, h), r, r))
    return p


def poly(pts, close=True):
    p = skia.Path()
    p.moveTo(*pts[0])
    for q in pts[1:]:
        p.lineTo(*q)
    if close:
        p.close()
    return p


def star_path(cx, cy, ro, ri, n=5, rot=-math.pi / 2):
    pts = []
    for i in range(n * 2):
        r = ro if i % 2 == 0 else ri
        a = rot + math.pi * i / n
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return poly(pts)


def shine(c, x, y, rx, ry, a=140):
    p = skia.Paint(AntiAlias=True, Color=skia.Color(255, 255, 255, a))
    c.drawOval(skia.Rect.MakeXYWH(x - rx, y - ry, rx * 2, ry * 2), p)


def dot(c, x, y, r, h):
    c.drawCircle(x, y, r, skia.Paint(AntiAlias=True, Color=col(h)))


def save(name, fn, size=S):
    surf = skia.Surface(size, size)
    c = surf.getCanvas()
    c.clear(skia.Color(0, 0, 0, 0))
    c.scale(size / S, size / S)
    # yumuşak gölge
    sp = skia.Paint(AntiAlias=True, Color=skia.Color(0, 0, 0, 40), MaskFilter=skia.MaskFilter.MakeBlur(skia.kNormal_BlurStyle, 4))
    c.drawOval(skia.Rect.MakeXYWH(24, 108, 80, 12), sp)
    fn(c)
    surf.makeImageSnapshot().save(os.path.join(OUT, name + ".png"), skia.kPNG)
    print("icon", name)


def heart_path(cx, cy, s):
    p = skia.Path()
    p.moveTo(cx, cy + s * 0.9)
    p.cubicTo(cx - s * 1.4, cy, cx - s * 0.9, cy - s * 1.1, cx, cy - s * 0.35)
    p.cubicTo(cx + s * 0.9, cy - s * 1.1, cx + s * 1.4, cy, cx, cy + s * 0.9)
    p.close()
    return p


# ------------------------------------------------------------------ ikonlar
def i_star(c):
    p = star_path(64, 64, 52, 24)
    shape(c, p, "#ffd23f")
    shine(c, 50, 46, 10, 6)


def i_star_empty(c):
    p = star_path(64, 64, 52, 24)
    shape(c, p, "#d9c7b1", k=0.1)


def i_coin(c):
    shape(c, circle_path(64, 64, 48), "#f2b632")
    shape(c, circle_path(64, 64, 34), "#ffd76a", w=4)
    sp = star_path(64, 65, 20, 9)
    c.drawPath(sp, skia.Paint(AntiAlias=True, Color=col("#e09a1a")))
    shine(c, 46, 42, 10, 6)


def i_lock(c):
    stroke(c, rrect_path(40, 18, 48, 64, 24), 20, INK)
    stroke(c, rrect_path(40, 18, 48, 64, 24), 9, col("#b8c2cc"))
    shape(c, rrect_path(24, 54, 80, 58, 14), "#ffb020")
    shape(c, circle_path(64, 78, 8), "#3b2417", w=2)
    stroke(c, poly([(64, 82), (64, 96)], False), 7, INK)


def i_check(c):
    shape(c, circle_path(64, 64, 50), "#3ddc84")
    stroke(c, poly([(40, 66), (58, 82), (90, 46)], False), 20, INK)
    stroke(c, poly([(40, 66), (58, 82), (90, 46)], False), 10, skia.ColorWHITE)


def i_cross(c):
    shape(c, circle_path(64, 64, 50), "#ff4f5e")
    for a, b in (((44, 44), (84, 84)), ((84, 44), (44, 84))):
        stroke(c, poly([a, b], False), 20, INK)
        stroke(c, poly([a, b], False), 10, skia.ColorWHITE)


def i_heart(c):
    shape(c, heart_path(64, 66, 42), "#ff4f7a")
    shine(c, 46, 50, 9, 6)


def i_clock(c):
    shape(c, circle_path(64, 66, 46), "#fff7ea", k=0.05)
    stroke(c, poly([(64, 66), (64, 38)], False), 8, INK)
    stroke(c, poly([(64, 66), (84, 74)], False), 8, INK)
    dot(c, 64, 66, 6, "#ff4f5e")
    shape(c, rrect_path(54, 8, 20, 14, 5), "#ff9b3d", w=5)


def i_pause(c):
    shape(c, rrect_path(30, 24, 24, 80, 10), "#fff7ea", k=0.05)
    shape(c, rrect_path(74, 24, 24, 80, 10), "#fff7ea", k=0.05)


def i_back(c):
    p = poly([(26, 64), (64, 26), (64, 48), (102, 48), (102, 80), (64, 80), (64, 102)])
    shape(c, p, "#fff7ea", k=0.05)


def i_play(c):
    shape(c, poly([(40, 24), (100, 64), (40, 104)]), "#fff7ea", k=0.05)


def i_gear(c):
    pts = []
    for i in range(16):
        r = 50 if i % 2 == 0 else 38
        a = math.pi * 2 * i / 16
        pts.append((64 + math.cos(a) * r, 64 + math.sin(a) * r))
    p = poly(pts)
    shape(c, p, "#9aa6b2")
    shape(c, circle_path(64, 64, 16), "#fff7ea", w=5)


def i_book(c):
    shape(c, rrect_path(20, 22, 88, 86, 10), "#a25cff")
    shape(c, rrect_path(30, 22, 70, 76, 6), "#fff7ea", k=0.05, w=5)
    shape(c, rrect_path(20, 22, 18, 86, 6), "#7c3bd6", w=5)
    for y in (42, 56, 70):
        stroke(c, poly([(48, y), (88, y)], False), 5, col("#c9b8a6"))
    shape(c, star_path(80, 88, 10, 5), "#ffd23f", w=3)


def i_trophy(c):
    shape(c, rrect_path(40, 96, 48, 14, 5), "#a0761c")
    shape(c, rrect_path(56, 72, 16, 28, 4), "#e2b33c", w=5)
    for side in (-1, 1):
        p = skia.Path()
        p.addCircle(64 + side * 36, 46, 14)
        stroke(c, p, 14, INK)
        stroke(c, p, 6, col("#f2c14e"))
    cup = skia.Path()
    cup.moveTo(30, 22)
    cup.lineTo(98, 22)
    cup.cubicTo(98, 70, 80, 80, 64, 80)
    cup.cubicTo(48, 80, 30, 70, 30, 22)
    cup.close()
    shape(c, cup, "#f2c14e")
    shine(c, 46, 40, 6, 12)


def i_flask(c):
    p = skia.Path()
    p.moveTo(52, 16)
    p.lineTo(76, 16)
    p.lineTo(76, 46)
    p.lineTo(104, 98)
    p.cubicTo(108, 106, 102, 112, 94, 112)
    p.lineTo(34, 112)
    p.cubicTo(26, 112, 20, 106, 24, 98)
    p.lineTo(52, 46)
    p.close()
    fill(c, p, "#eaf6ff", k=0.05)
    liq = skia.Path()
    liq.moveTo(37, 74)
    liq.lineTo(91, 74)
    liq.lineTo(104, 98)
    liq.cubicTo(108, 106, 102, 112, 94, 112)
    liq.lineTo(34, 112)
    liq.cubicTo(26, 112, 20, 106, 24, 98)
    liq.close()
    fill(c, liq, "#3ddc84", 70, 112)
    stroke(c, p, 7)
    dot(c, 56, 92, 6, "#c6ffdf")
    dot(c, 74, 84, 4, "#c6ffdf")
    shape(c, rrect_path(46, 10, 36, 12, 5), "#a25cff", w=5)


def i_calendar(c):
    shape(c, rrect_path(18, 26, 92, 84, 12), "#fff7ea", k=0.05)
    shape(c, rrect_path(18, 26, 92, 26, 10), "#ff5fa2", w=6)
    for x in (40, 88):
        stroke(c, poly([(x, 16), (x, 34)], False), 12, INK)
        stroke(c, poly([(x, 16), (x, 34)], False), 5, col("#b8c2cc"))
    shape(c, star_path(64, 80, 20, 9), "#ffd23f", w=4)


def i_chef(c):
    puff = skia.Path()
    puff.addCircle(40, 54, 22)
    puff.addCircle(64, 40, 26)
    puff.addCircle(88, 54, 22)
    puff.addRect(skia.Rect.MakeXYWH(32, 54, 64, 30))
    puff.setFillType(skia.PathFillType.kWinding)
    simple = skia.Op(puff, skia.Path(), skia.PathOp.kUnion_PathOp)
    shape(c, simple, "#ffffff", k=0.08)
    shape(c, rrect_path(30, 80, 68, 24, 8), "#f2ece2", k=0.05)


def i_bag(c):
    stroke(c, rrect_path(42, 16, 44, 50, 20), 14, INK)
    stroke(c, rrect_path(42, 16, 44, 50, 20), 6, col("#ff9b3d"))
    p = skia.Path()
    p.moveTo(22, 42)
    p.lineTo(106, 42)
    p.lineTo(98, 110)
    p.lineTo(30, 110)
    p.close()
    shape(c, p, "#ff5fa2")
    shape(c, heart_path(64, 76, 14), "#fff7ea", w=4)


def i_music(c):
    stroke(c, poly([(48, 92), (48, 28), (96, 18), (96, 82)], False), 14, INK)
    stroke(c, poly([(48, 92), (48, 28), (96, 18), (96, 82)], False), 6, col("#a25cff"))
    for x, y in ((38, 94), (86, 84)):
        p = skia.Path()
        p.addOval(skia.Rect.MakeXYWH(x - 16, y - 12, 32, 24))
        shape(c, p, "#a25cff")


def i_sound(c):
    p = poly([(18, 50), (40, 50), (66, 26), (66, 102), (40, 78), (18, 78)])
    shape(c, p, "#4a9dff")
    for r in (18, 32):
        arc = skia.Path()
        arc.addArc(skia.Rect.MakeXYWH(66 - r, 64 - r, r * 2, r * 2), -50, 100)
        stroke(c, arc, 7)


def i_vibrate(c):
    shape(c, rrect_path(40, 18, 48, 92, 12), "#3b3b4f", k=0.1)
    shape(c, rrect_path(46, 28, 36, 66, 6), "#4ad6ff", w=4)
    for side in (-1, 1):
        stroke(c, poly([(64 + side * 34, 40), (64 + side * 42, 52), (64 + side * 34, 64), (64 + side * 42, 76), (64 + side * 34, 88)], False), 6)


def i_refresh(c):
    arc = skia.Path()
    arc.addArc(skia.Rect.MakeXYWH(24, 24, 80, 80), -60, 290)
    stroke(c, arc, 20, INK)
    stroke(c, arc, 10, col("#3ddc84"))
    shape(c, poly([(84, 12), (108, 34), (78, 44)]), "#3ddc84", w=5)


def i_home(c):
    shape(c, poly([(64, 16), (112, 58), (100, 58), (100, 108), (28, 108), (28, 58), (16, 58)]), "#ff9b3d")
    shape(c, rrect_path(52, 72, 24, 36, 6), "#fff7ea", w=5)


def i_sparkle(c):
    shape(c, star_path(64, 64, 52, 12, 4), "#ffd23f")
    shape(c, star_path(98, 28, 16, 4, 4), "#fff7ea", w=4)
    shape(c, star_path(28, 98, 12, 3, 4), "#fff7ea", w=4)


def i_levelup(c):
    shape(c, circle_path(64, 64, 50), "#3ddc84")
    shape(c, poly([(64, 26), (94, 60), (76, 60), (76, 98), (52, 98), (52, 60), (34, 60)]), "#fff7ea", k=0.05, w=6)


def i_info(c):
    shape(c, circle_path(64, 64, 50), "#4a9dff")
    dot(c, 64, 38, 8, "#ffffff")
    stroke(c, poly([(64, 58), (64, 94)], False), 14, skia.ColorWHITE)


def i_shield(c):
    p = skia.Path()
    p.moveTo(64, 12)
    p.lineTo(106, 28)
    p.cubicTo(106, 74, 88, 100, 64, 116)
    p.cubicTo(40, 100, 22, 74, 22, 28)
    p.close()
    shape(c, p, "#4a7dff")
    p2 = skia.Path()
    p2.moveTo(64, 28)
    p2.lineTo(90, 38)
    p2.cubicTo(90, 70, 80, 88, 64, 98)
    p2.close()
    fill(c, p2, "#8fb4ff")
    shine(c, 46, 42, 7, 12)


def i_swords(c):
    for side in (-1, 1):
        a = (64 - side * 40, 24)
        b = (64 + side * 30, 96)
        stroke(c, poly([a, b], False), 18, INK)
        stroke(c, poly([a, b], False), 9, col("#dfe6ee"))
        stroke(c, poly([(64 + side * 18, 74), (64 + side * 42, 92)], False), 16, INK)
        stroke(c, poly([(64 + side * 18, 74), (64 + side * 42, 92)], False), 7, col("#ff9b3d"))


def i_plate(c):
    p = skia.Path()
    p.addOval(skia.Rect.MakeXYWH(12, 46, 104, 50))
    shape(c, p, "#f4f4f0", k=0.06)
    p2 = skia.Path()
    p2.addOval(skia.Rect.MakeXYWH(30, 54, 68, 30))
    stroke(c, p2, 4, col("#c9c3b8"))
    cl = skia.Path()
    cl.moveTo(28, 70)
    cl.cubicTo(28, 30, 100, 30, 100, 70)
    cl.close()
    shape(c, cl, "#dfe6ee", k=0.15)
    dot(c, 64, 30, 7, "#ff9b3d")


def i_leaf(c):
    p = skia.Path()
    p.moveTo(20, 108)
    p.cubicTo(20, 40, 60, 16, 110, 18)
    p.cubicTo(108, 70, 80, 108, 20, 108)
    p.close()
    shape(c, p, "#3ddc84")
    stroke(c, poly([(26, 102), (96, 32)], False), 5, col("#1f6b3a"))


def i_bulb(c):
    shape(c, circle_path(64, 52, 36), "#ffe14a")
    shape(c, rrect_path(48, 84, 32, 24, 6), "#b8c2cc", w=5)
    shine(c, 52, 40, 8, 10)


def i_mystery(c):
    shape(c, rrect_path(18, 18, 92, 92, 18), "#a25cff")
    p = skia.Path()
    f = skia.Font(None, 76)
    f.setEmbolden(True)
    blob = skia.TextBlob("?", f)
    c.drawTextBlob(blob, 42, 92, skia.Paint(AntiAlias=True, Color=INK))
    c.drawTextBlob(blob, 40, 88, skia.Paint(AntiAlias=True, Color=skia.ColorWHITE))


def i_fire(c):
    p = skia.Path()
    p.moveTo(64, 10)
    p.cubicTo(84, 40, 104, 56, 100, 84)
    p.cubicTo(96, 108, 80, 116, 64, 116)
    p.cubicTo(48, 116, 30, 108, 28, 84)
    p.cubicTo(26, 62, 44, 50, 46, 30)
    p.cubicTo(56, 44, 58, 52, 64, 10)
    p.close()
    shape(c, p, "#ff6a1a")
    p2 = skia.Path()
    p2.moveTo(64, 56)
    p2.cubicTo(76, 72, 84, 84, 80, 96)
    p2.cubicTo(76, 108, 52, 108, 48, 96)
    p2.cubicTo(46, 84, 56, 76, 64, 56)
    p2.close()
    fill(c, p2, "#ffd23f", 56, 108)


def i_plus(c):
    shape(c, circle_path(64, 64, 50), "#3ddc84")
    for a, b in (((64, 38), (64, 90)), ((38, 64), (90, 64))):
        stroke(c, poly([a, b], False), 18, INK)
        stroke(c, poly([a, b], False), 9, skia.ColorWHITE)


def i_arrow(c):
    shape(c, poly([(102, 64), (64, 26), (64, 48), (26, 48), (26, 80), (64, 80), (64, 102)]), "#fff7ea", k=0.05)


def i_fast(c):
    shape(c, poly([(16, 28), (64, 64), (16, 100)]), "#fff7ea", k=0.05)
    shape(c, poly([(60, 28), (108, 64), (60, 100)]), "#fff7ea", k=0.05)


def i_trash(c):
    shape(c, rrect_path(30, 40, 68, 72, 10), "#9aa6b2")
    shape(c, rrect_path(22, 28, 84, 14, 6), "#7d8a9b", w=5)
    shape(c, rrect_path(52, 16, 24, 14, 5), "#7d8a9b", w=5)
    for x in (48, 64, 80):
        stroke(c, poly([(x, 54), (x, 98)], False), 5, col("#4f5b6b"))


def i_fuse(c):
    shape(c, circle_path(64, 64, 50), "#ff9b3d")
    for k in range(3):
        arc = skia.Path()
        r = 14 + k * 11
        arc.addArc(skia.Rect.MakeXYWH(64 - r, 64 - r, r * 2, r * 2), k * 120, 220)
        stroke(c, arc, 8, skia.ColorWHITE)
    shape(c, star_path(64, 64, 10, 4, 4), "#ffd23f", w=3)


def i_palette(c):
    p = skia.Path()
    p.moveTo(64, 14)
    p.cubicTo(100, 14, 116, 44, 112, 68)
    p.cubicTo(108, 88, 88, 80, 82, 92)
    p.cubicTo(76, 104, 90, 114, 64, 114)
    p.cubicTo(30, 114, 14, 90, 14, 64)
    p.cubicTo(14, 36, 34, 14, 64, 14)
    p.close()
    shape(c, p, "#ffe7c2", k=0.08)
    for (x, y, h) in ((44, 42, "#ff4f5e"), (70, 34, "#ffd23f"), (92, 52, "#3ddc84"), (38, 72, "#4a9dff"), (56, 92, "#a25cff")):
        shape(c, circle_path(x, y, 9), h, w=3)


def i_skull(c):
    shape(c, circle_path(64, 56, 42), "#f4f0e6", k=0.08)
    shape(c, rrect_path(44, 82, 40, 26, 8), "#f4f0e6", k=0.08)
    dot(c, 48, 56, 11, "#3b2417")
    dot(c, 80, 56, 11, "#3b2417")
    shape(c, poly([(64, 70), (58, 80), (70, 80)]), "#3b2417", w=2)


def i_map(c):
    p = poly([(14, 30), (46, 18), (82, 30), (114, 18), (114, 98), (82, 110), (46, 98), (14, 110)])
    shape(c, p, "#ffe7c2", k=0.08)
    stroke(c, poly([(46, 18), (46, 98)], False), 4, col("#c9a46a"))
    stroke(c, poly([(82, 30), (82, 110)], False), 4, col("#c9a46a"))
    path = skia.Path()
    path.moveTo(26, 90)
    path.cubicTo(40, 60, 70, 80, 96, 44)
    p2 = skia.Paint(AntiAlias=True, Style=skia.Paint.kStroke_Style, StrokeWidth=5, Color=col("#ff4f5e"),
                    PathEffect=skia.DashPathEffect.Make([8, 7], 0))
    c.drawPath(path, p2)
    shape(c, star_path(96, 42, 12, 5), "#ffd23f", w=3)


def i_dna(c):
    for k in range(9):
        y = 18 + k * 11
        x = math.sin(k * 0.8) * 28
        stroke(c, poly([(64 - x, y), (64 + x, y)], False), 5, col("#c9b8a6"))
    for side, h in ((1, "#ff5fa2"), (-1, "#4a9dff")):
        pts = [(64 + side * math.sin(k * 0.8 / 2) * 28 * (1 if True else 0), 18 + k * 5.5) for k in range(19)]
        pth = skia.Path()
        pts = [(64 + side * math.sin(t * 0.4) * 28, 18 + t * 5.5) for t in range(19)]
        pth.moveTo(*pts[0])
        for q in pts[1:]:
            pth.lineTo(*q)
        stroke(c, pth, 14, INK)
        stroke(c, pth, 7, col(h))


def i_gavel(c):
    stroke(c, poly([(40, 96), (78, 58)], False), 16, INK)
    stroke(c, poly([(40, 96), (78, 58)], False), 8, col("#a8743c"))
    p = rrect_path(56, 18, 56, 34, 8)
    m = skia.Matrix()
    m.setRotate(45, 84, 35)
    p.transform(m)
    shape(c, p, "#c8955c")
    shape(c, rrect_path(20, 100, 52, 14, 5), "#8a5a3b", w=5)


# yöntem ikonları
def m_bake(c):
    shape(c, rrect_path(16, 20, 96, 92, 14), "#e8734a")
    shape(c, rrect_path(28, 46, 72, 54, 8), "#3b2417", k=0.0, w=5)
    fill(c, rrect_path(34, 52, 60, 42, 6), "#ff9b3d", 52, 94, 0.3)
    for x in (34, 54, 74, 94):
        dot(c, x, 32, 5, "#fff7ea")


def m_fry(c):
    stroke(c, poly([(84, 68), (118, 98)], False), 18, INK)
    stroke(c, poly([(84, 68), (118, 98)], False), 9, col("#8a5a3b"))
    p = skia.Path()
    p.addOval(skia.Rect.MakeXYWH(10, 40, 84, 56))
    shape(c, p, "#5a5f6b", k=0.15)
    p2 = skia.Path()
    p2.addOval(skia.Rect.MakeXYWH(20, 48, 64, 38))
    fill(c, p2, "#2f333b", 48, 86, 0.1)
    p3 = skia.Path()
    p3.addOval(skia.Rect.MakeXYWH(36, 56, 32, 20))
    shape(c, p3, "#fff7ea", w=4)
    dot(c, 52, 66, 7, "#ffb020")


def m_freeze(c):
    for k in range(3):
        a = math.pi * k / 3
        dx, dy = math.cos(a) * 46, math.sin(a) * 46
        stroke(c, poly([(64 - dx, 64 - dy), (64 + dx, 64 + dy)], False), 16, INK)
        stroke(c, poly([(64 - dx, 64 - dy), (64 + dx, 64 + dy)], False), 8, col("#7fd3ff"))
    shape(c, circle_path(64, 64, 12), "#bff3ff", w=5)


def m_boil(c):
    for x in (44, 64, 84):
        w2 = skia.Path()
        w2.moveTo(x, 34)
        w2.cubicTo(x - 8, 26, x + 8, 18, x, 8)
        stroke(c, w2, 5, col("#c9c3b8"))
    p = skia.Path()
    p.moveTo(16, 46)
    p.lineTo(112, 46)
    p.lineTo(104, 108)
    p.lineTo(24, 108)
    p.close()
    shape(c, p, "#4a9dff")
    shape(c, rrect_path(10, 38, 108, 16, 8), "#2f6fd6", w=5)
    shape(c, circle_path(46, 76, 8), "#bfe1ff", w=3)


def m_grill(c):
    shape(c, rrect_path(14, 30, 100, 70, 12), "#3b3b4f", k=0.1)
    for x in (32, 52, 72, 92):
        stroke(c, poly([(x, 36), (x, 94)], False), 6, col("#9aa6b2"))
    for x, y in ((40, 104), (88, 104)):
        stroke(c, poly([(x, 98), (x, 118)], False), 8, INK)
    w2 = skia.Path()
    w2.moveTo(46, 26)
    w2.cubicTo(38, 16, 54, 10, 46, 2)
    stroke(c, w2, 5, col("#ff6a1a"))
    w3 = skia.Path()
    w3.moveTo(80, 26)
    w3.cubicTo(72, 16, 88, 10, 80, 2)
    stroke(c, w3, 5, col("#ff6a1a"))


def m_magic(c):
    stroke(c, poly([(24, 104), (82, 46)], False), 18, INK)
    stroke(c, poly([(24, 104), (82, 46)], False), 9, col("#5b4bd6"))
    stroke(c, poly([(70, 58), (82, 46)], False), 9, skia.ColorWHITE)
    shape(c, star_path(90, 38, 26, 11), "#ffd23f")
    shape(c, star_path(40, 40, 10, 4, 4), "#fff7ea", w=3)
    shape(c, star_path(104, 88, 9, 3, 4), "#fff7ea", w=3)


def s_fusion(c):
    i_fuse(c)


def s_defender(c):
    i_shield(c)


def s_artist(c):
    stroke(c, poly([(30, 100), (80, 50)], False), 16, INK)
    stroke(c, poly([(30, 100), (80, 50)], False), 8, col("#c8955c"))
    p = skia.Path()
    p.moveTo(76, 42)
    p.cubicTo(90, 20, 112, 18, 108, 30)
    p.cubicTo(104, 46, 92, 58, 86, 54)
    p.close()
    shape(c, p, "#ff5fa2")
    shape(c, circle_path(28, 104, 10), "#ff5fa2", w=4)


def s_chaos(c):
    shape(c, circle_path(64, 64, 50), "#3ddc84")
    pth = skia.Path()
    pts = []
    for i in range(60):
        a = i * 0.32
        r = 4 + i * 0.66
        pts.append((64 + math.cos(a) * r, 64 + math.sin(a) * r))
    pth.moveTo(*pts[0])
    for q in pts[1:]:
        pth.lineTo(*q)
    stroke(c, pth, 7, skia.ColorWHITE)


ICONS = {"star": i_star, "star_empty": i_star_empty, "coin": i_coin, "lock": i_lock, "check": i_check, "cross": i_cross,
         "heart": i_heart, "clock": i_clock, "pause": i_pause, "back": i_back, "play": i_play, "gear": i_gear, "book": i_book,
         "trophy": i_trophy, "flask": i_flask, "calendar": i_calendar, "chef": i_chef, "bag": i_bag, "music": i_music,
         "sound": i_sound, "vibrate": i_vibrate, "refresh": i_refresh, "home": i_home, "sparkle": i_sparkle, "levelup": i_levelup,
         "info": i_info, "shield": i_shield, "swords": i_swords, "plate": i_plate, "leaf": i_leaf, "bulb": i_bulb,
         "mystery": i_mystery, "fire": i_fire, "plus": i_plus, "arrow": i_arrow, "fast": i_fast, "trash": i_trash, "fuse": i_fuse,
         "palette": i_palette, "skull": i_skull, "map": i_map, "dna": i_dna, "gavel": i_gavel,
         "m_bake": m_bake, "m_fry": m_fry, "m_freeze": m_freeze, "m_boil": m_boil, "m_grill": m_grill, "m_magic": m_magic,
         "s_fusion": s_fusion, "s_defender": s_defender, "s_artist": s_artist, "s_chaos": s_chaos}

for k, fn in ICONS.items():
    save(k, fn)


# ------------------------------------------------------------------ uygulama simgesi (512 + 192)
def app_icon(size):
    surf = skia.Surface(size, size)
    c = surf.getCanvas()
    c.scale(size / 512, size / 512)
    bg = skia.Paint(AntiAlias=True)
    bg.setShader(skia.GradientShader.MakeRadial((256, 200), 380, [col("#ffb35c"), col("#ff5fa2"), col("#7c3bd6")]))
    c.drawRRect(skia.RRect.MakeRectXY(skia.Rect.MakeWH(512, 512), 110, 110), bg)
    # ışınlar
    for i in range(12):
        a0 = i * math.pi / 6
        p = poly([(256, 230), (256 + math.cos(a0) * 500, 230 + math.sin(a0) * 500), (256 + math.cos(a0 + 0.22) * 500, 230 + math.sin(a0 + 0.22) * 500)])
        c.drawPath(p, skia.Paint(AntiAlias=True, Color=skia.Color(255, 255, 255, 26)))
    # tencere
    pot = skia.Path()
    pot.moveTo(110, 270)
    pot.lineTo(402, 270)
    pot.cubicTo(400, 400, 350, 440, 256, 440)
    pot.cubicTo(162, 440, 112, 400, 110, 270)
    pot.close()
    pp = skia.Paint(AntiAlias=True)
    pp.setShader(skia.GradientShader.MakeLinear([(0, 270), (0, 440)], [col("#6aa0ff"), col("#2f5fd6")]))
    c.drawPath(pot, pp)
    stroke(c, pot, 16)
    rim = rrect_path(90, 246, 332, 44, 22)
    shape(c, rim, "#4a7dff", w=16, y0=246, y1=290)
    # köpüren iksir
    goo = skia.Path()
    goo.moveTo(120, 250)
    for i in range(9):
        x = 120 + i * 34
        goo.cubicTo(x + 8, 200 - (i % 2) * 30, x + 26, 200 - (i % 2) * 30, x + 34, 250)
    goo.close()
    gp = skia.Paint(AntiAlias=True)
    gp.setShader(skia.GradientShader.MakeLinear([(0, 170), (0, 250)], [col("#9dff7a"), col("#2fd6a0")]))
    c.drawPath(goo, gp)
    stroke(c, goo, 14)
    for (x, y, r) in ((180, 150, 22), (300, 120, 30), (360, 175, 16), (230, 95, 14)):
        b = circle_path(x, y, r)
        c.drawPath(b, skia.Paint(AntiAlias=True, Color=col("#c6ffdf")))
        stroke(c, b, 9)
    # yıldız
    st = star_path(256, 180, 58, 26)
    shape(c, st, "#ffd23f", w=12, y0=120, y1=240)
    # gözler (kazan yaratığı)
    for x in (206, 306):
        e = circle_path(x, 340, 30)
        c.drawPath(e, skia.Paint(AntiAlias=True, Color=skia.ColorWHITE))
        stroke(c, e, 10)
        dot(c, x + 6, 344, 13, "#3b2417")
    sm = skia.Path()
    sm.moveTo(226, 388)
    sm.quadTo(256, 412, 286, 388)
    stroke(c, sm, 12)
    return surf.makeImageSnapshot()


def adaptive(size=432):
    # arka plan
    surf = skia.Surface(size, size)
    c = surf.getCanvas()
    bg = skia.Paint(AntiAlias=True)
    bg.setShader(skia.GradientShader.MakeRadial((size / 2, size * 0.4), size * 0.75, [col("#ffb35c"), col("#ff5fa2"), col("#7c3bd6")]))
    c.drawRect(skia.Rect.MakeWH(size, size), bg)
    for i in range(12):
        a0 = i * math.pi / 6
        p = poly([(size / 2, size * 0.45), (size / 2 + math.cos(a0) * size, size * 0.45 + math.sin(a0) * size), (size / 2 + math.cos(a0 + 0.22) * size, size * 0.45 + math.sin(a0 + 0.22) * size)])
        c.drawPath(p, skia.Paint(AntiAlias=True, Color=skia.Color(255, 255, 255, 26)))
    surf.makeImageSnapshot().save(os.path.join(ROOT, "assets/ui/icon_bg_432.png"), skia.kPNG)
    # ön plan: uygulama simgesinin ortası, güvenli alanın (%66) içinde
    full = app_icon(512)
    surf2 = skia.Surface(size, size)
    c2 = surf2.getCanvas()
    c2.clear(skia.Color(0, 0, 0, 0))
    # sadece tencere + iksir: arka planı olmayan bir kopya çiz
    c2.translate(size * 0.17, size * 0.17)
    c2.scale(size * 0.66 / 512, size * 0.66 / 512)
    pot = skia.Path()
    pot.moveTo(110, 270)
    pot.lineTo(402, 270)
    pot.cubicTo(400, 400, 350, 440, 256, 440)
    pot.cubicTo(162, 440, 112, 400, 110, 270)
    pot.close()
    pp = skia.Paint(AntiAlias=True)
    pp.setShader(skia.GradientShader.MakeLinear([(0, 270), (0, 440)], [col("#6aa0ff"), col("#2f5fd6")]))
    c2.drawPath(pot, pp)
    stroke(c2, pot, 16)
    shape(c2, rrect_path(90, 246, 332, 44, 22), "#4a7dff", w=16, y0=246, y1=290)
    goo = skia.Path()
    goo.moveTo(120, 250)
    for i in range(9):
        x = 120 + i * 34
        goo.cubicTo(x + 8, 200 - (i % 2) * 30, x + 26, 200 - (i % 2) * 30, x + 34, 250)
    goo.close()
    gp = skia.Paint(AntiAlias=True)
    gp.setShader(skia.GradientShader.MakeLinear([(0, 170), (0, 250)], [col("#9dff7a"), col("#2fd6a0")]))
    c2.drawPath(goo, gp)
    stroke(c2, goo, 14)
    for (x, y, r) in ((180, 150, 22), (300, 120, 30), (360, 175, 16), (230, 95, 14)):
        b = circle_path(x, y, r)
        c2.drawPath(b, skia.Paint(AntiAlias=True, Color=col("#c6ffdf")))
        stroke(c2, b, 9)
    shape(c2, star_path(256, 180, 58, 26), "#ffd23f", w=12, y0=120, y1=240)
    for x in (206, 306):
        e = circle_path(x, 340, 30)
        c2.drawPath(e, skia.Paint(AntiAlias=True, Color=skia.ColorWHITE))
        stroke(c2, e, 10)
        dot(c2, x + 6, 344, 13, "#3b2417")
    sm = skia.Path()
    sm.moveTo(226, 388)
    sm.quadTo(256, 412, 286, 388)
    stroke(c2, sm, 12)
    surf2.makeImageSnapshot().save(os.path.join(ROOT, "assets/ui/icon_fg_432.png"), skia.kPNG)


adaptive()
app_icon(512).save(os.path.join(ROOT, "icon.png"), skia.kPNG)
app_icon(192).save(os.path.join(ROOT, "assets/ui/icon_192.png"), skia.kPNG)
print("app icon ok")
