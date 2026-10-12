"""Reusable illustrated motifs (botanicals, resins, woods, materials). Each motif draws centred on (0,0)
in a local box of roughly ±60 units; callers place it with translate/scale groups."""
import math
from lib import P, leaf_d, blob_d, smooth_closed, smooth_open, star_pts, petal_d, light, dark, mix, rot

GREEN = "#6f9a5a"
GREEN_D = "#3f6b3a"


def shadow(S, cx, cy, rx, ry, a=0.22):
    S.ellipse(cx, cy, rx, ry, S.rad([(0, "#5a3640", a), (1, "#5a3640", 0)]))


def leaf(S, x, y, L, W, ang, c=GREEN, vein=True, curve=0.0):
    g = S.lin([(0, light(c, 0.25)), (1, dark(c, 0.18))], 0, 0, 1, 1)
    S.path(leaf_d(x, y, L, W, ang, curve), g)
    if vein:
        tx, ty = x + math.cos(ang) * L * 0.85, y + math.sin(ang) * L * 0.85
        S.path("M%s Q%s %s" % (P(x, y), P((x + tx) / 2 + math.sin(ang) * W * 0.15, (y + ty) / 2 - math.cos(ang) * W * 0.15), P(tx, ty)), None, dark(c, 0.3), 1.2, 0.55)


def drop(S, cx, cy, r, color, alpha=1.0, hl=True):
    d = ("M%s C%s %s %s A%s 0 1 1 %s C%s %s %s Z" % (
        P(cx, cy - 1.7 * r), P(cx + 0.35 * r, cy - 1.2 * r), P(cx + r, cy - 0.65 * r), P(cx + r, cy),
        P(r, r), P(cx - r, cy), P(cx - r, cy - 0.65 * r), P(cx - 0.35 * r, cy - 1.2 * r), P(cx, cy - 1.7 * r)))
    S.path(d, S.rad([(0, light(color, 0.55), alpha), (0.6, color, alpha), (1, dark(color, 0.2), alpha)], 0.38, 0.55, 0.7))
    if hl:
        S.ellipse(cx - r * 0.38, cy - r * 0.25, r * 0.18, r * 0.32, "#ffffff", op=0.7, rot=20)


def smoke(S, x, y, h, op=0.35):
    for k, dx in enumerate((-6, 6)):
        pts = [(x + dx + math.sin(i * 0.9 + k) * 7, y - i * h / 7) for i in range(8)]
        S.path(smooth_open(pts), None, "#9a8f95", 3 - k, op - k * 0.1)


def badge_synth(S, x=168, y=32):
    S.circle(x, y, 20, "#f1eafb", "#a08cc8", 2)
    pts = [(x + math.cos(math.pi / 6 + i * math.pi / 3) * 9, y + math.sin(math.pi / 6 + i * math.pi / 3) * 9) for i in range(6)]
    S.poly(pts, None, "#6d3f73", 2)
    S.line(pts[0][0], pts[0][1], pts[0][0] + 6, pts[0][1] - 4, "#6d3f73", 2)
    S.circle(pts[0][0] + 7, pts[0][1] - 5, 2.6, "#c4677f")
    S.circle(pts[3][0] - 2, pts[3][1] + 1, 2.2, "#6d3f73")


def badge_accord(S, x=168, y=32):
    S.circle(x, y, 20, "#fbf1dc", "#c9a55a", 2)
    S.circle(x - 6, y + 3, 6, "#e79ab3", op=0.9)
    S.circle(x + 6, y + 3, 6, "#d6953a", op=0.9)
    S.circle(x, y - 6, 6, "#8fc1a0", op=0.9)


# ------------------------------------------------------------------ citrus
def citrus(S, fruit, flesh, leaves=True, small=False):
    r = 30 if small else 38
    shadow(S, 0, 48, 58, 9)
    if leaves:
        leaf(S, -10, -6 - r, 36, 11, -0.55)
        leaf(S, -14, -4 - r, 28, 9, -2.4, "#7fa864")
    S.circle(-12, -6, r, S.rad([(0, light(fruit, 0.5)), (0.55, fruit), (1, dark(fruit, 0.22))], 0.38, 0.32, 0.75))
    for i in range(14):
        a = i * 2.4
        S.circle(-12 + math.cos(a) * r * 0.6 * ((i % 4) / 4 + 0.3), -6 + math.sin(a) * r * 0.55 * ((i % 3) / 3 + 0.4), 0.9, dark(fruit, 0.25), op=0.35)
    S.ellipse(-24, -20, 9, 5, "#ffffff", op=0.45, rot=-35)
    S.rect(-14, -8 - r, 4, 8, "#7a5a36", rx=2)
    # slice
    cx, cy, R = 24, 22, 27
    S.circle(cx, cy, R, S.lin([(0, light(fruit, 0.1)), (1, dark(fruit, 0.15))]))
    S.circle(cx, cy, R - 3, "#fff6e3")
    for i in range(9):
        a0 = i * math.tau / 9 + 0.06
        a1 = (i + 1) * math.tau / 9 - 0.06
        r0, r1 = 3.5, R - 6
        d = "M%s L%s A%s 0 0 1 %s Z" % (P(cx + math.cos(a0) * r0, cy + math.sin(a0) * r0), P(cx + math.cos(a0) * r1, cy + math.sin(a0) * r1), P(r1, r1),
                                          P(cx + math.cos(a1) * r1, cy + math.sin(a1) * r1))
        S.path(d, S.rad([(0, light(flesh, 0.35)), (1, flesh)], 0.5, 0.5, 0.6))
        am = (a0 + a1) / 2
        S.ellipse(cx + math.cos(am) * r1 * 0.6, cy + math.sin(am) * r1 * 0.6, 1.4, 3.2, "#ffffff", op=0.55, rot=math.degrees(am) + 90)
    S.circle(cx, cy, 3, "#fff6e3")


# ------------------------------------------------------------------ herbs & spices
def lavender(S):
    shadow(S, 0, 56, 40, 6)
    stems = [(-22, -48, -0.15), (-6, -58, -0.05), (10, -54, 0.08), (26, -44, 0.2)]
    for k, (x1, y1, bend) in enumerate(stems):
        x0 = -4 + k * 3
        S.path("M%s Q%s %s" % (P(x0, 50), P((x0 + x1) / 2 + bend * 40, 0), P(x1, y1)), None, "#6f8a5a", 2.6)
        for i in range(11):
            t = i / 10
            x = x1 + (x0 - x1) * t * 0.45 + bend * 10 * t
            y = y1 + (50 - y1) * t * 0.45
            sz = 1.0 - t * 0.35 if i > 0 else 0.6
            for sgn in (-1, 1):
                col = ["#8e6cc2", "#a98ad8", "#7a58b0"][(i + k + (sgn > 0)) % 3]
                S.ellipse(x + sgn * 4 * sz, y, 4.2 * (1.1 - t * 0.3), 6 * sz, col, rot=sgn * 25)
    # ribbon
    S.ellipse(-12, 26, 11, 6, "#eab3bf", rot=-25)
    S.ellipse(12, 26, 11, 6, "#eab3bf", rot=25)
    S.path("M-3 28 L-10 46 L-4 43 Z", "#e09aa9")
    S.path("M3 28 L10 46 L4 43 Z", "#e09aa9")
    S.circle(0, 27, 5, "#d98a9b")


def peppercorns(S, col="#e2577a"):
    shadow(S, 0, 48, 50, 8)
    S.path("M-40 30 Q-10 0 30 -40", None, "#8a6a4a", 2.5)
    S.path("M-10 6 Q10 6 22 -6", None, "#8a6a4a", 2)
    leaf(S, 18, -30, 28, 7, -0.3, "#8fa86a")
    leaf(S, -26, 18, 24, 6, 2.6, "#8fa86a")
    import random
    rnd = random.Random(4)
    for i in range(26):
        a = rnd.uniform(0, math.tau)
        rr = rnd.uniform(0, 26)
        x, y = -2 + math.cos(a) * rr, 2 + math.sin(a) * rr * 0.8
        c = col if i % 4 else dark(col, 0.25)
        S.circle(x, y, 6.2, S.rad([(0, light(c, 0.45)), (0.7, c), (1, dark(c, 0.3))], 0.35, 0.3, 0.7))
        S.circle(x - 2, y - 2, 1.4, "#ffffff", op=0.6)


def cardamom(S):
    shadow(S, 0, 46, 54, 8)
    pods = [(-26, 8, -30), (0, -6, 10), (24, 12, 40)]
    for x, y, a in pods:
        S.ellipse(x, y, 13, 24, S.lin([(0, "#b9cf86"), (1, "#7f9a4c")], 0, 0, 1, 0), rot=a)
        for k in (-1, 0, 1):
            dx, dy = rot(x + k * 5, y - 20, x, y, math.radians(a))
            ex, ey = rot(x + k * 5, y + 20, x, y, math.radians(a))
            S.path("M%s Q%s %s" % (P(dx, dy), P(x + k * 7, y), P(ex, ey)), None, "#6f8a3e", 1.2, 0.6)
    # open pod with seeds
    S.ellipse(10, 38, 18, 10, "#d7e2a8", "#8aa25a", 1.5)
    for i in range(7):
        S.circle(-2 + i * 4, 38 + (i % 2) * 3 - 1.5, 3, "#3a2a20")


def cloves(S):
    shadow(S, 0, 48, 52, 8)
    for i, (x, y, a) in enumerate([(-28, 10, -25), (-6, 0, -5), (16, 12, 20), (32, -2, 40), (0, 26, 70)]):
        with S.g("translate(%s %s) rotate(%s)" % (x, y, a)):
            S.path("M-3 0 L-1.5 34 L1.5 34 L3 0 Z", S.lin([(0, "#8b5434"), (1, "#5d321d")], 0, 0, 1, 0))
            for k in range(4):
                ang = k * math.pi / 2 + math.pi / 4
                S.ellipse(math.cos(ang) * 5, -2 + math.sin(ang) * 3, 4.5, 3, "#7a4529", rot=math.degrees(ang))
            S.circle(0, -6, 5.5, S.rad([(0, "#b47a4e"), (1, "#6a3a22")], 0.4, 0.35, 0.7))


def saffron(S):
    shadow(S, 0, 50, 50, 7)
    S.ellipse(4, 34, 40, 12, S.lin([(0, "#f3ead8"), (1, "#d9c6a6")]))
    S.ellipse(4, 31, 34, 8, "#efe2c8")
    for i in range(9):
        x = -22 + i * 6
        S.path("M%s Q%s %s" % (P(x, 30), P(x + 8, 20 - (i % 3) * 3), P(x + 14 - (i % 2) * 6, 26)), None, "#c8322b" if i % 2 else "#e04a2c", 2.4)
    # crocus
    S.path("M-26 20 Q-30 -10 -28 -24", None, "#6f9a5a", 2.5)
    for k, a in enumerate((-2.1, -1.57, -1.05)):
        S.path(petal_d(-28, -22, 26, 8, a, 0.8), S.lin([(0, "#b49ae0"), (1, "#7a58b0")]))
    for a in (-1.85, -1.3):
        S.path("M%s L%s" % (P(-28, -22), P(-28 + math.cos(a) * 18, -22 + math.sin(a) * 18)), None, "#e0402c", 1.8)


def coriander(S):
    shadow(S, 0, 48, 50, 7)
    import random
    rnd = random.Random(9)
    for i in range(16):
        x, y = rnd.uniform(-34, 34), rnd.uniform(14, 40)
        S.circle(x, y, 6, S.rad([(0, "#efdcae"), (1, "#bf9c5e")], 0.4, 0.35, 0.7))
        S.path("M%s Q%s %s" % (P(x - 4, y), P(x, y - 2), P(x + 4, y)), None, "#a8824a", 0.8, 0.7)
    S.path("M0 14 Q2 -20 -4 -50", None, "#7a9a5a", 2)
    for i in range(7):
        a = -math.pi / 2 + (i - 3) * 0.35
        x, y = -4 + math.cos(a) * 20, -50 + math.sin(a) * 12 + 14
        S.path("M%s L%s" % (P(-4, -40), P(x, y)), None, "#7a9a5a", 1)
        for j in range(5):
            S.circle(x + math.cos(j * 1.26) * 3, y + math.sin(j * 1.26) * 3, 1.8, "#ffffff" if j % 2 else "#f3d7e4")


def galbanum(S):
    shadow(S, 0, 50, 50, 7)
    for i, a in enumerate(range(-150, -20, 18)):
        r = math.radians(a)
        S.path("M0 30 Q%s %s" % (P(math.cos(r) * 30, 30 + math.sin(r) * 50), P(math.cos(r) * 52, 30 + math.sin(r) * 70)), None, "#7fa864", 2)
        for k in range(1, 6):
            px, py = math.cos(r) * 10 * k, 30 + math.sin(r) * 14 * k
            S.path(leaf_d(px, py, 10, 2.5, r - 0.7), "#9cbf74")
            S.path(leaf_d(px, py, 10, 2.5, r + 0.7), "#86ad62")
    resin_tears(S, "#c9cf7a", seed=3, n=5, cy=36, spread=26)


def resin_tears(S, col, seed=1, n=7, cy=26, spread=30, size=1.0):
    import random
    rnd = random.Random(seed)
    items = sorted([(rnd.uniform(-spread, spread), cy + rnd.uniform(-10, 12), rnd.uniform(9, 15) * size, rnd.randint(1, 99)) for _ in range(n)], key=lambda t: t[1])
    for x, y, r, sd in items:
        d = blob_d(x, y, r, 8, 0.22, sd, 1.0, 0.8)
        S.path(d, S.rad([(0, light(col, 0.5), 0.95), (0.6, col, 0.95), (1, dark(col, 0.3), 1)], 0.35, 0.3, 0.75))
        S.ellipse(x - r * 0.35, y - r * 0.3, r * 0.25, r * 0.15, "#ffffff", op=0.65, rot=-30)


# ------------------------------------------------------------------ flowers
def rose(S, base="#d6456a", leaves=True):
    if leaves:
        leaf(S, -18, 26, 40, 13, 2.55, "#5f8f4e")
        leaf(S, 16, 28, 40, 13, 0.55, "#6f9a5a")
    for i in range(5):
        a = math.radians(i * 72 - 90)
        cx, cy = math.cos(a) * 17, math.sin(a) * 15
        S.ellipse(cx, cy, 25, 21, S.rad([(0, light(base, 0.35)), (0.7, base), (1, dark(base, 0.12))], 0.5, 0.5, 0.65), rot=math.degrees(a))
        e0 = rot(cx + 20, cy - 10, cx, cy, a)
        e1 = rot(cx + 20, cy + 10, cx, cy, a)
        S.path("M%s Q%s %s" % (P(*e0), P(*rot(cx + 27, cy, cx, cy, a)), P(*e1)), None, light(base, 0.5), 2, 0.7)
    for i in range(4):
        a = math.radians(i * 90 + 45)
        S.ellipse(math.cos(a) * 8, math.sin(a) * 7, 17, 13, S.rad([(0, light(base, 0.15)), (1, dark(base, 0.15))], 0.5, 0.4, 0.7), rot=math.degrees(a))
        S.path("M%s Q%s %s" % (P(math.cos(a - 0.6) * 18, math.sin(a - 0.6) * 15), P(math.cos(a) * 24, math.sin(a) * 20), P(math.cos(a + 0.6) * 18, math.sin(a + 0.6) * 15)), None, light(base, 0.45), 1.8, 0.75)
    S.circle(0, 0, 11, S.rad([(0, dark(base, 0.35)), (1, dark(base, 0.1))]))
    S.path("M-7 2 C-7 -9 9 -9 9 0 C9 8 -3 9 -4 2 C-4 -3 4 -3 4 1", None, light(base, 0.35), 2.2)


def rose_petals(S, base="#e48aa0"):
    shadow(S, 0, 46, 54, 8)
    for i, (x, y, a, sz) in enumerate([(-26, 20, 20, 1), (4, 8, -30, 1.15), (28, 24, 60, 0.9), (-6, 34, 120, 0.95), (20, -10, -80, 0.8)]):
        c = base if i % 2 else dark(base, 0.08)
        with S.g("translate(%s %s) rotate(%s) scale(%s)" % (x, y, a, sz)):
            S.path("M0 -20 C16 -22 22 -4 14 10 C8 20 -8 20 -14 10 C-22 -4 -16 -22 0 -20 Z", S.rad([(0, light(c, 0.4)), (1, c)], 0.4, 0.3, 0.8))
            S.path("M0 -16 Q2 0 0 14", None, light(c, 0.5), 1, 0.6)


def star_flower(S, x, y, r, col="#ffffff", centre="#f1d36b", n=5, width=0.33, edge="#e2d6c2"):
    for i in range(n):
        a = -math.pi / 2 + i * math.tau / n
        S.path(petal_d(x, y, r, r * width, a, 0.7), S.lin([(0, col), (1, mix(col, "#efe5d6", 0.6))]), edge, 0.8)
    S.circle(x, y, r * 0.16, centre)


def jasmine(S):
    shadow(S, 0, 50, 50, 7)
    S.path("M-30 46 Q-10 10 -18 -12", None, "#5f8f4e", 2)
    S.path("M-14 30 Q10 20 20 6", None, "#5f8f4e", 2)
    S.path("M-20 20 Q-10 30 0 28", None, "#5f8f4e", 2)
    for args in [(-38, 30, 22, 2.6), (-2, 40, 22, 0.4), (30, -6, 20, -0.6), (-34, -2, 18, -2.6)]:
        leaf(S, args[0], args[1], args[2], 7, args[3], "#5d8b4c")
    star_flower(S, -18, -16, 22)
    star_flower(S, 22, 4, 20)
    star_flower(S, 2, 28, 18)
    for x, y, a in [(-34, -30, -40), (36, -22, 30)]:
        S.ellipse(x, y, 4, 11, S.lin([(0, "#f2c2cf"), (1, "#ffffff")]), rot=a)


def neroli(S):
    shadow(S, 0, 50, 50, 7)
    for args in [(-30, 30, 30, 2.5), (10, 34, 30, 0.6), (-8, -40, 26, -1.9)]:
        leaf(S, args[0], args[1], args[2], 10, args[3], "#4f7f45")
    S.circle(30, 26, 16, S.rad([(0, "#f7c46a"), (0.6, "#e9952e"), (1, "#a8b04a")], 0.35, 0.3, 0.8))
    for (x, y, r) in [(-14, -6, 24), (16, -18, 18)]:
        for i in range(5):
            a = -math.pi / 2 + i * math.tau / 5
            S.path(petal_d(x, y, r, r * 0.42, a, 0.95), S.lin([(0, "#ffffff"), (1, "#f1e9dc")]), "#e4d7c4", 0.8)
        for i in range(10):
            a = i * math.tau / 10
            S.line(x, y, x + math.cos(a) * r * 0.45, y + math.sin(a) * r * 0.45, "#c6b04a", 1)
            S.circle(x + math.cos(a) * r * 0.48, y + math.sin(a) * r * 0.48, 1.6, "#e2a72a")
        S.circle(x, y, 3.5, "#9ab84e")


def tuberose(S):
    shadow(S, 0, 54, 40, 6)
    for a, L in [(-1.9, 50), (-1.25, 46), (-2.3, 34), (-0.85, 36)]:
        S.path(leaf_d(0, 54, L, 5, a), "#6f9a5a")
    S.path("M0 54 Q4 0 0 -56", None, "#6f9a5a", 3)
    for i, (x, y, r) in enumerate([(-14, 6, 15), (14, -8, 15), (-12, -26, 13), (12, -40, 11), (0, 22, 12)]):
        S.path("M%s Q%s %s" % (P(0, y + 8), P(x * 0.5, y + 6), P(x, y)), None, "#7aa264", 1.8)
        star_flower(S, x, y, r, "#fffdf8", "#f2d7c8", 6, 0.3, "#ead7cf")
    S.ellipse(2, -54, 4, 9, "#f6e5e0")
    S.ellipse(-6, -50, 3.5, 8, "#f2d6d6", rot=-20)


def ylang(S):
    shadow(S, 0, 54, 46, 7)
    leaf(S, -6, -30, 46, 14, 2.7, "#3f6b3a")
    leaf(S, 6, -30, 46, 14, 0.5, "#4f7f45")
    S.path("M0 -54 Q4 -40 0 -30", None, "#5d7d3a", 3)
    for i in range(6):
        a = math.radians(55 + i * 14)
        x1, y1 = math.cos(a) * 54, -30 + math.sin(a) * 70
        mx_, my_ = math.cos(a) * 26 + (8 if i % 2 else -8), -30 + math.sin(a) * 30
        d = "M%s Q%s %s Q%s %s Z" % (P(-2, -30), P(mx_ - 6, my_), P(x1 - 30, y1 - 4), P(mx_ + 6, my_ + 6), P(2, -28))
        S.path(d, S.lin([(0, "#d8d65a"), (1, "#f2e27a")]), "#b9b24a", 0.8)
    S.circle(0, -30, 6, "#8a7a2a")


def violet_flower(S, x, y, r, col="#7a4fb0"):
    for a, s in [(-2.2, 1.0), (-0.95, 1.0)]:
        S.path(petal_d(x, y, r * 1.1, r * 0.55, a, 1.0), S.lin([(0, light(col, 0.25)), (1, dark(col, 0.15))]))
    for a in (-2.9, -0.25):
        S.path(petal_d(x, y, r * 0.95, r * 0.45, a, 1.0), S.lin([(0, light(col, 0.35)), (1, col)]))
    S.path(petal_d(x, y, r * 1.05, r * 0.6, 1.57, 1.0), S.lin([(0, light(col, 0.45)), (1, col)]))
    for k in (-1, 0, 1):
        S.line(x, y + 2, x + k * 3, y + r * 0.6, "#ffffff", 1, 0.8)
    S.circle(x, y, r * 0.15, "#f3d34a")


def heart_leaf(S, x, y, s, ang, c="#3f6b3a"):
    with S.g("translate(%s %s) rotate(%s) scale(%s)" % (x, y, ang, s)):
        S.path("M0 30 C-30 6 -30 -24 -10 -26 C-4 -26 0 -20 0 -16 C0 -20 4 -26 10 -26 C30 -24 30 6 0 30 Z", S.lin([(0, light(c, 0.25)), (1, dark(c, 0.15))], 0, 0, 1, 1))
        S.path("M0 -16 L0 28", None, light(c, 0.35), 1.2, 0.7)
        for k in (-1, 1):
            S.path("M0 0 Q%s %s %s %s" % (k * 10, -6, k * 18, -10), None, light(c, 0.35), 1, 0.6)
            S.path("M0 12 Q%s %s %s %s" % (k * 9, 8, k * 15, 2), None, light(c, 0.35), 1, 0.6)


def violet_leaves(S):
    shadow(S, 0, 52, 52, 7)
    heart_leaf(S, -18, 10, 1.15, -20, "#3f6b3a")
    heart_leaf(S, 18, 14, 1.05, 18, "#4f7f45")
    heart_leaf(S, 0, -12, 0.95, 180 + 5, "#5d8b4c")
    violet_flower(S, 30, -30, 14)


def violets(S):
    shadow(S, 0, 52, 52, 7)
    heart_leaf(S, -22, 26, 0.8, -40, "#4f7f45")
    heart_leaf(S, 24, 28, 0.75, 40, "#5d8b4c")
    for x, y, r, c in [(-18, -8, 18, "#7a4fb0"), (16, -18, 17, "#8e5fc2"), (0, 18, 16, "#6a3f9e")]:
        violet_flower(S, x, y, r, c)


def geranium(S):
    shadow(S, 0, 52, 52, 7)
    pts = []
    for i in range(36):
        a = i * math.tau / 36
        r = 34 + (4 if i % 4 < 2 else -1)
        pts.append((-10 + math.cos(a) * r, 14 + math.sin(a) * r * 0.9))
    S.path(smooth_closed(pts), S.rad([(0, "#86b06a"), (1, "#4f7f45")]))
    S.ellipse(-10, 14, 20, 18, None, "#3d5f30", 5, 0.35)
    for i in range(7):
        a = i * math.tau / 7
        S.line(-10, 14, -10 + math.cos(a) * 30, 14 + math.sin(a) * 27, "#3d6a35", 1.2, 0.6)
    for x, y in [(18, -24), (30, -10), (8, -38), (28, -36), (12, -10), (38, -24)]:
        for i in range(5):
            a = -math.pi / 2 + i * math.tau / 5
            S.path(petal_d(x, y, 9, 4.5, a, 1.0), "#e7708d")
        S.circle(x, y, 2, "#c43c62")


def iris(S):
    shadow(S, 0, 54, 50, 7)
    S.path(leaf_d(-8, 54, 70, 5, -1.75), "#6f9a5a")
    S.path(leaf_d(6, 54, 60, 5, -1.35), "#7fa864")
    S.path("M0 54 L0 -6", None, "#6f9a5a", 3)
    for a in (-2.2, -1.57, -0.94):
        S.path(petal_d(0, -14, 34, 11, a, 0.9), S.lin([(0, "#c7b4ec"), (1, "#8d6cc8")]))
    for a in (2.4, 0.74):
        S.path(petal_d(0, -12, 34, 13, a, 1.0), S.lin([(0, "#7a4fb0"), (1, "#a98ad8")]))
    S.path(petal_d(0, -12, 30, 12, 1.57, 1.0), S.lin([(0, "#6a3f9e"), (1, "#9b7ad0")]))
    for a in (2.4, 1.57, 0.74):
        S.line(0, -12, math.cos(a) * 14, -12 + math.sin(a) * 14, "#f2c94a", 3)
    # orris root
    S.path(blob_d(14, 40, 18, 9, 0.25, 7, 1.6, 0.6), S.lin([(0, "#efe1c4"), (1, "#c9ad84")]))
    for k in range(4):
        S.path("M%s Q%s %s" % (P(-6 + k * 10, 38), P(-2 + k * 10, 44), P(2 + k * 10, 40)), None, "#a8885e", 1, 0.7)


def lily_of_valley(S):
    shadow(S, 0, 54, 46, 7)
    S.path(leaf_d(-6, 54, 86, 16, -1.85), S.lin([(0, "#7fb06a"), (1, "#3f6b3a")]))
    S.path(leaf_d(4, 54, 80, 14, -1.25), S.lin([(0, "#8ebd76"), (1, "#4f7f45")]))
    S.path("M-2 54 Q-6 -10 24 -44", None, "#6f9a5a", 2.5)
    for i in range(6):
        t = i / 6
        x = -4 + t * 26 - math.sin(t * 3) * 6
        y = 10 - t * 54
        bx, by = x - 10 + t * 4, y + 12
        S.path("M%s Q%s %s" % (P(x, y), P(bx, y - 2), P(bx, by - 6)), None, "#6f9a5a", 1.2)
        rr = 8 - t * 3
        S.path("M%s C%s %s %s Q%s %s Q%s %s Z" % (
            P(bx - rr, by + rr * 0.6), P(bx - rr, by - rr), P(bx + rr, by - rr), P(bx + rr, by + rr * 0.6),
            P(bx + rr * 0.5, by + rr * 1.05), P(bx, by + rr * 0.6), P(bx - rr * 0.5, by + rr * 1.05), P(bx - rr, by + rr * 0.6)),
            S.rad([(0, "#ffffff"), (1, "#e8efe0")], 0.4, 0.3, 0.8), "#d2dcc8", 0.8)


def hibiscus(S, x, y, r):
    for i in range(5):
        a = -math.pi / 2 + i * math.tau / 5
        S.path(petal_d(x, y, r, r * 0.6, a, 1.1), S.lin([(0, "#f8e27a"), (1, "#eec24a")]), "#d9a83a", 0.8)
    S.circle(x, y, r * 0.25, "#7a1f2e")
    S.line(x, y, x + 3, y - r * 0.6, "#f2d36b", 2)


# ------------------------------------------------------------------ green & leaves
def patchouli(S):
    shadow(S, 0, 52, 52, 7)
    for i, a in enumerate((-2.6, -2.0, -1.5, -1.0, -0.45, 0.2, 2.9)):
        c = ["#3f6b3a", "#4f7f45", "#365e33", "#5d8b4c"][i % 4]
        L = 40 if i < 6 else 30
        S.path(leaf_d(0, 18, L, 15, a), S.lin([(0, light(c, 0.2)), (1, dark(c, 0.2))], 0, 0, 1, 1), dark(c, 0.25), 1.2)
        tx, ty = math.cos(a) * L * 0.85, 18 + math.sin(a) * L * 0.85
        S.line(0, 18, tx, ty, light(c, 0.3), 1, 0.6)
    for x, y, a in [(-28, 42, 20), (-6, 46, -10), (18, 44, 30), (34, 40, -40)]:
        S.path(leaf_d(x - 8, y, 18, 6, math.radians(a)), "#9a7448", "#6f5030", 0.8)


def vetiver(S):
    shadow(S, 0, 54, 46, 7)
    for i in range(9):
        a = -1.57 + (i - 4) * 0.12
        x1, y1 = math.cos(a) * 70 + (i - 4) * 3, 4 + math.sin(a) * 66
        S.path("M%s Q%s %s Q%s %s Z" % (P(-2 + i * 0.5, 4), P(x1 * 0.5 - 3, y1 * 0.5), P(x1, y1), P(x1 * 0.5 + 3, y1 * 0.5), P(2 + i * 0.5, 4)), "#7fa864" if i % 2 else "#5f8f4e")
    S.rect(-12, 0, 24, 9, "#cfae7a", rx=3)
    S.line(-12, 4, 12, 4, "#a8824a", 1.5)
    import random
    rnd = random.Random(5)
    for i in range(26):
        x0 = rnd.uniform(-10, 10)
        pts = [(x0, 9)]
        for k in range(1, 5):
            pts.append((x0 + rnd.uniform(-14, 14) * k * 0.4, 9 + k * 11))
        S.path(smooth_open(pts), None, ["#b48a4e", "#a07440", "#c9a060"][i % 3], 1.3)


def oakmoss(S):
    shadow(S, 0, 50, 56, 8)
    S.path(blob_d(0, 30, 44, 10, 0.12, 3, 1.25, 0.45), S.lin([(0, "#8a6a4a"), (1, "#5a4030")]))
    for k in range(5):
        S.path("M%s Q%s %s" % (P(-46 + k * 20, 26), P(-40 + k * 20, 34), P(-34 + k * 20, 28)), None, "#4a3426", 1.2, 0.6)
    import random
    rnd = random.Random(8)
    for i in range(16):
        x, y = rnd.uniform(-40, 40), rnd.uniform(-8, 22)
        c = ["#9fb08a", "#b8c6a2", "#8a9c78", "#c9d4b6"][i % 4]
        for k in range(5):
            a = -math.pi / 2 + (k - 2) * 0.5
            S.path("M%s Q%s %s" % (P(x, y + 10), P(x + math.cos(a) * 6, y + math.sin(a) * 6 + 6), P(x + math.cos(a) * 12, y + math.sin(a) * 12 + 4)), None, c, 3.2)
            S.circle(x + math.cos(a) * 12, y + math.sin(a) * 12 + 4, 2.4, light(c, 0.2))


def lemongrass(S):
    for i in range(6):
        a = -1.57 + (i - 2.5) * 0.18
        S.path("M%s Q%s %s Q%s %s Z" % (P(-4 + i * 2, 50), P(math.cos(a) * 30 - 2, 50 + math.sin(a) * 50), P(math.cos(a) * 64, 50 + math.sin(a) * 96), P(math.cos(a) * 30 + 2, 50 + math.sin(a) * 50), P(i * 2, 50)), "#a7c46a" if i % 2 else "#8ab05a")


# ------------------------------------------------------------------ woods & resins
def log(S, wood, ring, bark, x=0, y=10, scale=1.0):
    with S.g("translate(%s %s) scale(%s)" % (x, y, scale)):
        S.path("M-40 -18 L26 -24 A14 26 0 0 1 26 28 L-40 22 Z", S.lin([(0, light(bark, 0.15)), (1, dark(bark, 0.2))]))
        for k in range(5):
            S.path("M%s L%s" % (P(-38, -12 + k * 8), P(20, -16 + k * 9)), None, dark(bark, 0.35), 1.4, 0.5)
        S.ellipse(26, 2, 15, 26, S.rad([(0, light(wood, 0.25)), (1, wood)]))
        for k in range(1, 5):
            S.ellipse(26, 2, 15 - k * 3.2, 26 - k * 5.5, None, ring, 1.1, 0.8)
        S.path("M26 2 L34 -14", None, dark(ring, 0.2), 1.2, 0.7)


def chips(S, col, seed=2, n=6, cy=40, spread=36):
    import random
    rnd = random.Random(seed)
    for i in range(n):
        x, y = rnd.uniform(-spread, spread), cy + rnd.uniform(-5, 6)
        a = rnd.uniform(-40, 40)
        with S.g("translate(%s %s) rotate(%s)" % (x, y, a)):
            S.path("M-9 -3 C-4 -7 6 -6 10 -2 C6 3 -4 4 -9 1 Z", S.lin([(0, light(col, 0.3)), (1, dark(col, 0.12))]))
            S.path("M-6 -2 Q0 -4 7 -2", None, dark(col, 0.25), 0.8, 0.6)


def sandalwood(S, synth=False):
    shadow(S, 0, 50, 54, 8)
    log(S, "#e8c890", "#c9a06a", "#a37b4f", -2, 4)
    chips(S, "#e2c08a", 4, 7)


def cedar(S):
    shadow(S, 0, 50, 54, 8)
    log(S, "#e2a074", "#b56a43", "#6e4430", -4, 8)
    S.path("M-40 -30 Q-10 -40 22 -54", None, "#5a7a46", 2)
    for i in range(7):
        t = i / 6
        x, y = -40 + t * 62, -30 - t * 24 - math.sin(t * 3) * 3
        for sgn in (-1, 1):
            S.path(leaf_d(x, y, 14, 4, -0.5 + sgn * 0.9), "#4f7f45" if sgn > 0 else "#6f9a5a")
    S.ellipse(32, -38, 7, 10, S.lin([(0, "#a8794e"), (1, "#6a4a2e")]), rot=25)


def oud(S, accord=False):
    S.ellipse(0, 40, 50, 12, S.lin([(0, "#efd08a"), (1, "#b88d40")]))
    S.ellipse(0, 36, 44, 8, "#d8b46a")
    import random
    rnd = random.Random(12)
    for i in range(6):
        x, y = rnd.uniform(-30, 30), 22 + rnd.uniform(-10, 10)
        pts = [(x + math.cos(k * 1.1 + i) * rnd.uniform(8, 16), y + math.sin(k * 1.1 + i) * rnd.uniform(5, 10)) for k in range(6)]
        S.poly(pts, S.lin([(0, "#6a4632"), (1, "#24160f")], 0, 0, 1, 1))
        S.line(pts[0][0], pts[0][1], pts[3][0], pts[3][1], "#120a06", 1.6, 0.7)
        S.line(pts[1][0], pts[1][1], pts[4][0], pts[4][1], "#a87a52", 0.8, 0.5)
    smoke(S, -6, 14, 70, 0.4)


def amber_gem(S):
    S.circle(0, 0, 50, S.rad([(0, "#f6c867", 0.5), (1, "#f6c867", 0)]))
    shadow(S, 0, 48, 46, 7)
    pts = [(-30, -6), (-14, -30), (16, -30), (32, -6), (16, 34), (-14, 34)]
    S.poly(pts, "#d9902a")
    S.poly([(-30, -6), (-14, -30), (0, -14)], "#f8d38a")
    S.poly([(-14, -30), (16, -30), (0, -14)], "#f0b54a")
    S.poly([(16, -30), (32, -6), (0, -14)], "#e09a34")
    S.poly([(-30, -6), (0, -14), (-14, 34)], "#e8a640")
    S.poly([(32, -6), (0, -14), (16, 34)], "#b66a1c")
    S.poly([(-14, 34), (0, -14), (16, 34)], "#c97c22")
    S.path("M-22 -10 L-10 -24", None, "#ffffff", 3, 0.7)
    resin_tears(S, "#e3a24a", 6, 3, 42, 40, 0.6)


def benzoin(S):
    shadow(S, 0, 50, 54, 8)
    resin_tears(S, "#e3a24a", seed=21, n=8, cy=22, spread=32, size=1.2)


def olibanum(S):
    shadow(S, 0, 50, 54, 8)
    resin_tears(S, "#f1e2a8", seed=31, n=9, cy=26, spread=32, size=1.1)
    smoke(S, 4, 4, 60, 0.3)


def labdanum(S):
    shadow(S, 0, 52, 54, 8)
    S.path(blob_d(14, 36, 18, 9, 0.2, 2, 1.4, 0.6), S.rad([(0, "#7a4a2a"), (1, "#2e1a10")], 0.4, 0.3, 0.8))
    S.ellipse(8, 30, 6, 2.5, "#ffffff", op=0.5, rot=-15)
    x, y, r = -10, -8, 30
    import random
    rnd = random.Random(2)
    for i in range(5):
        a = -math.pi / 2 + i * math.tau / 5
        S.path(blob_d(x + math.cos(a) * r * 0.5, y + math.sin(a) * r * 0.5, r * 0.55, 9, 0.1, rnd.randint(1, 99)), S.lin([(0, "#ffffff"), (1, "#f2e8e8")]), "#e2d2d2", 0.8)
        S.ellipse(x + math.cos(a) * r * 0.25, y + math.sin(a) * r * 0.25, 4, 3, "#b0243a", rot=math.degrees(a))
    for i in range(12):
        a = i * math.tau / 12
        S.circle(x + math.cos(a) * 7, y + math.sin(a) * 7, 1.8, "#f2c94a")
    S.circle(x, y, 4, "#d9a83a")


def ambergris(S):
    S.path("M-60 40 Q-30 30 0 38 T60 34", None, "#9cc6d6", 3, 0.6)
    S.ellipse(0, 44, 56, 10, S.lin([(0, "#f2e4c8"), (1, "#dcc79e")]))
    S.path(blob_d(0, 16, 34, 10, 0.14, 11, 1.25, 0.8), S.rad([(0, "#e6dfd2"), (0.6, "#b9ae9a"), (1, "#8f8470")], 0.35, 0.3, 0.8))
    import random
    rnd = random.Random(1)
    for i in range(18):
        S.circle(rnd.uniform(-30, 30), 16 + rnd.uniform(-16, 16), rnd.uniform(0.8, 2), "#7a705e", op=0.4)
    S.ellipse(-14, 2, 10, 5, "#ffffff", op=0.4, rot=-20)


def seeds(S, col="#7a6a58", n=12, seed=3):
    import random
    rnd = random.Random(seed)
    for i in range(n):
        x, y = rnd.uniform(-34, 34), 30 + rnd.uniform(-8, 12)
        with S.g("translate(%s %s) rotate(%s)" % (x, y, rnd.uniform(0, 360))):
            S.path("M-6 -3 C-6 -8 6 -8 6 -2 C6 3 2 6 0 3 C-2 6 -6 3 -6 -3 Z", S.rad([(0, light(col, 0.35)), (1, dark(col, 0.15))], 0.4, 0.3, 0.8))


def ambrette(S):
    shadow(S, 0, 50, 52, 8)
    seeds(S, "#6e5f4e", 14, 6)
    leaf(S, -26, -10, 30, 10, -2.5, "#5f8f4e")
    hibiscus(S, 8, -14, 28)


# ------------------------------------------------------------------ gourmand
def vanilla(S, crystals_too=False):
    shadow(S, 0, 50, 56, 8)
    for i, (dy, a) in enumerate([(10, -8), (20, -3), (30, 4)]):
        with S.g("translate(0 %s) rotate(%s)" % (dy, a)):
            S.path("M-54 0 C-30 -8 30 -8 54 -2 C30 4 -30 6 -54 0 Z", S.lin([(0, "#5a3622"), (1, "#24140c")], 0, 0, 0, 1))
            S.path("M-48 -1 C-20 -5 20 -5 48 -2", None, "#8a5a3a", 1, 0.7)
    S.rect(-6, 6, 10, 30, "#d9c49a", rx=2)
    S.line(-6, 12, 4, 10, "#b8a070", 1)
    x, y = 18, -26
    for a in (-2.2, -0.9, 1.7):
        S.path(petal_d(x, y, 22, 7, a, 0.8), S.lin([(0, "#f7f4d2"), (1, "#e3dc9a")]))
    for a in (-2.8, -0.3):
        S.path(petal_d(x, y, 18, 6, a, 0.8), "#f2edc0")
    S.path("M%s C%s %s %s Z" % (P(x - 5, y), P(x - 8, y + 16), P(x + 8, y + 16), P(x + 5, y)), "#f2d36b", "#d9b84a", 0.8)
    leaf(S, -30, -18, 30, 9, -2.8, "#6f9a5a")


def crystals(S, col="#ffffff", x=0, y=20, seed=4, n=7, size=1.0):
    import random
    rnd = random.Random(seed)
    for i in range(n):
        cx, cy = x + rnd.uniform(-26, 26) * size, y + rnd.uniform(-6, 12) * size
        h = rnd.uniform(14, 24) * size
        w = h * 0.45
        a = rnd.uniform(-25, 25)
        with S.g("translate(%s %s) rotate(%s)" % (cx, cy, a)):
            S.poly([(0, -h), (w, -h * 0.6), (w, h * 0.4), (0, h * 0.6), (-w, h * 0.4), (-w, -h * 0.6)], mix(col, "#e8e2f0", 0.3), "#cfc6d8", 0.8)
            S.poly([(0, -h), (w, -h * 0.6), (0, -h * 0.2)], "#ffffff")
            S.poly([(0, -h * 0.2), (w, -h * 0.6), (w, h * 0.4), (0, h * 0.6)], mix(col, "#d8d0e2", 0.5))


def tonka(S, coumarin=False):
    shadow(S, 0, 50, 54, 8)
    import random
    rnd = random.Random(3)
    for i, (x, y, a) in enumerate([(-24, 22, -20), (4, 12, 15), (26, 26, 40), (-6, 34, -60)]):
        with S.g("translate(%s %s) rotate(%s)" % (x, y, a)):
            S.ellipse(0, 0, 22, 9, S.rad([(0, "#6a4430"), (1, "#24150d")], 0.4, 0.3, 0.8))
            for k in range(5):
                S.path("M%s Q%s %s" % (P(-16 + k * 7, -5), P(-13 + k * 7, 0), P(-16 + k * 7, 5)), None, "#8a5e44", 0.9, 0.7)
    with S.g("translate(16 44) rotate(-8)"):
        S.ellipse(0, 0, 18, 8, "#2e1b12")
        S.ellipse(0, 0, 14, 5, S.lin([(0, "#e8d0a8"), (1, "#c9a678")]))


def caramel(S):
    shadow(S, 0, 50, 54, 8)
    for x, y, s in [(-24, 18, 1.0), (12, 26, 1.1), (-2, -4, 0.9)]:
        with S.g("translate(%s %s) scale(%s)" % (x, y, s)):
            S.poly([(0, -20), (18, -11), (0, -2), (-18, -11)], "#f3c27a")
            S.poly([(-18, -11), (0, -2), (0, 20), (-18, 11)], "#d58a34")
            S.poly([(18, -11), (0, -2), (0, 20), (18, 11)], "#b86a22")
            S.path("M-12 -12 L-4 -16", None, "#ffffff", 2, 0.7)
    S.path("M-40 -20 Q-20 -40 0 -26 Q16 -14 30 -32 L32 -26 Q16 -6 -2 -18 Q-20 -30 -36 -14 Z", S.lin([(0, "#c9782a"), (1, "#8a4a1a")]))
    for x, y in [(30, -10), (-36, 4), (38, 8)]:
        S.path("M%s l2 -6 l2 6 l6 2 l-6 2 l-2 6 l-2 -6 l-6 -2 Z" % P(x, y), "#f6e2b0")


def peach(S):
    shadow(S, 0, 50, 46, 8)
    leaf(S, 6, -32, 34, 11, -0.5, "#6f9a5a")
    S.circle(-4, 8, 38, S.rad([(0, "#fcd9a0"), (0.5, "#f8a878"), (1, "#e05a5a")], 0.3, 0.3, 0.85))
    S.path("M-4 -30 Q-18 6 -4 46", None, "#d0545a", 2, 0.45)
    S.ellipse(-20, -6, 8, 12, "#ffffff", op=0.3, rot=20)
    S.rect(-6, -36, 4, 9, "#7a5a36", rx=2)


def berries(S, col="#3a1f3d"):
    shadow(S, 0, 50, 50, 8)
    pts = []
    for i in range(5):
        a = -math.pi / 2 + i * math.tau / 5
        pts += [(-18 + math.cos(a) * 34, -18 + math.sin(a) * 30), (-18 + math.cos(a + 0.63) * 18, -18 + math.sin(a + 0.63) * 16)]
    S.path(smooth_closed(pts, 0.12), S.lin([(0, "#7fb06a"), (1, "#3f6b3a")], 0, 0, 1, 1))
    S.path("M-18 -18 L-18 18 M-18 -18 L10 -30 M-18 -18 L-44 -30", None, "#2f5a2a", 1.2, 0.6)
    S.path("M-4 -6 Q14 0 24 20", None, "#6a5a3a", 1.8)
    import random
    rnd = random.Random(6)
    for i, (x, y) in enumerate([(4, 18), (18, 12), (26, 26), (12, 30), (-2, 32), (22, 40), (34, 14), (8, 44)]):
        S.circle(x, y, 9, S.rad([(0, light(col, 0.35)), (0.6, col), (1, dark(col, 0.3))], 0.35, 0.3, 0.75))
        S.circle(x - 3, y - 3, 1.8, "#ffffff", op=0.7)
        S.circle(x + 2, y + 6, 1.2, dark(col, 0.4))


def coffee(S):
    shadow(S, 0, 50, 54, 8)
    import random
    rnd = random.Random(7)
    for i in range(9):
        x, y = rnd.uniform(-34, 34), 26 + rnd.uniform(-14, 12)
        with S.g("translate(%s %s) rotate(%s)" % (x, y, rnd.uniform(0, 360))):
            S.ellipse(0, 0, 12, 9, S.rad([(0, "#8a5434"), (0.6, "#5a321c"), (1, "#3a1f10")], 0.4, 0.3, 0.8))
            S.path("M-10 1 C-4 -4 4 6 10 -1", None, "#24130a", 1.8)
    S.circle(0, -18, 22, S.rad([(0, "#c98a5a", 0.25), (1, "#c98a5a", 0)]))


# ------------------------------------------------------------------ musks & textures
def powder_puff(S):
    S.circle(0, 0, 54, S.rad([(0, "#ffffff", 0.7), (1, "#f6e6ee", 0)]))
    shadow(S, 0, 46, 48, 8)
    for i in range(18):
        a = i * math.tau / 18
        S.circle(math.cos(a) * 34, 10 + math.sin(a) * 26, 9, "#f8eef2")
    S.ellipse(0, 10, 36, 28, S.rad([(0, "#ffffff"), (1, "#f3dce6")], 0.4, 0.35, 0.7))
    S.path("M-14 -10 Q0 -40 14 -10", None, "#d9a3b4", 5)
    S.ellipse(0, -12, 10, 5, "#e6b3c3")
    import random
    rnd = random.Random(2)
    for i in range(14):
        S.circle(rnd.uniform(-50, 50), rnd.uniform(-46, 40), rnd.uniform(1, 2.5), "#ffffff", op=0.9)


def cotton(S):
    shadow(S, 0, 50, 52, 8)
    S.path("M-30 54 Q-20 20 -6 4 M20 54 Q18 30 22 -6", None, "#8a6a4a", 2.5)
    for x, y, s in [(-14, -8, 1.0), (22, -16, 0.85), (2, 22, 0.8)]:
        with S.g("translate(%s %s) scale(%s)" % (x, y, s)):
            S.poly(star_pts(0, 14, 22, 9, 5), "#8a6a48")
            for a in range(5):
                ang = -math.pi / 2 + a * math.tau / 5
                S.circle(math.cos(ang) * 11, math.sin(ang) * 10, 13, S.rad([(0, "#ffffff"), (1, "#ebe6ef")], 0.4, 0.35, 0.7))
            S.circle(0, 0, 12, "#ffffff")


def silk(S, col="#f4eef6"):
    shadow(S, 0, 50, 56, 8)
    S.path("M-58 10 C-40 -40 -10 20 10 -20 C24 -46 40 -10 58 -24 L58 30 C40 40 20 20 0 44 C-20 60 -40 30 -58 44 Z",
           S.lin([(0, "#ffffff"), (0.45, col), (0.7, mix(col, "#cfc3dd", 0.5)), (1, col)], 0, 0, 1, 0.3))
    for k in range(4):
        S.path("M%s C%s %s %s" % (P(-50 + k * 6, 24 + k * 4), P(-30, -10 + k * 8), P(0, 30 + k * 4), P(30 + k * 6, -6 + k * 6)), None, "#ffffff", 2, 0.7)


def cashmere(S, c1="#efc6c8", c2="#e8d2bf"):
    shadow(S, 0, 52, 56, 8)
    S.path("M-56 -6 C-30 -30 -6 -2 16 -20 C34 -34 48 -22 58 -30 L58 6 C44 14 30 2 14 16 C-8 34 -32 6 -56 26 Z", S.lin([(0, light(c1, 0.3)), (0.5, c1), (1, mix(c1, "#c98f9a", 0.4))], 0, 0, 1, 0.4))
    S.path("M-56 18 C-30 0 -4 30 18 12 C36 -2 48 14 58 4 L58 34 C46 44 30 30 16 42 C-6 58 -32 32 -56 48 Z", S.lin([(0, light(c2, 0.3)), (0.5, c2), (1, mix(c2, "#b89a80", 0.4))], 0, 0, 1, 0.4))
    for k in range(9):
        x = -48 + k * 12
        S.path("M%s l3 4 l3 -4" % P(x, 20 + math.sin(k) * 6), None, mix(c2, "#a88a70", 0.5), 1, 0.6)
        S.path("M%s l3 4 l3 -4" % P(x, -8 + math.sin(k + 1) * 7), None, mix(c1, "#b07a86", 0.5), 1, 0.6)
    for k in range(7):
        x = 48 + k * 1.5
        S.line(x - 4 + k * 2, 34 + k, x - 2 + k * 2, 50 + k, mix(c2, "#a88a70", 0.4), 1.5, 0.8)


def wood_ribbon(S):
    shadow(S, 0, 52, 56, 8)
    d = "M-54 20 C-40 -30 -6 -34 6 -6 C16 18 40 16 54 -24 L58 -10 C44 34 10 40 -2 10 C-12 -14 -36 -6 -46 30 Z"
    S.path(d, S.lin([(0, "#f0d2a0"), (0.45, "#d49a5a"), (0.75, "#b8783e"), (1, "#e8c08a")], 0, 0, 1, 0.3))
    for k in range(4):
        S.path("M%s C%s %s %s" % (P(-50 + k * 3, 16 + k * 3), P(-34, -22 + k * 5), P(-4, -18 + k * 4), P(4 + k * 2, 2 + k * 2)), None, "#a8683a", 1, 0.45)
    S.path("M-44 4 C-34 -20 -12 -24 -2 -8", None, "#ffffff", 3, 0.55)
    chips(S, "#d9b07a", 5, 5, 44, 34)


def leather(S):
    shadow(S, 0, 50, 56, 8)
    d = "M-50 -24 Q-30 -34 -6 -28 Q20 -36 48 -24 Q54 0 46 30 Q20 40 -4 34 Q-30 42 -50 30 Q-56 2 -50 -24 Z"
    S.path(d, S.rad([(0, "#c8844e"), (0.7, "#9a5a30"), (1, "#6e3a1c")], 0.4, 0.35, 0.8))
    S.path("M-42 -16 Q-30 -24 -6 -20 Q20 -27 40 -16 Q45 0 39 22 Q20 30 -4 26 Q-30 33 -42 22 Q-47 2 -42 -16 Z", None, "#f2d6a8", 1.6, 0.85, dash="4 4")
    S.rect(14, -8, 28, 18, None, "#d8b46a", 4)
    S.line(28, -8, 28, 10, "#d8b46a", 3)


def sparkle(S, x, y, r, col="#e8c66a"):
    S.path("M%s Q%s %s Q%s %s Q%s %s Q%s %s Z" % (P(x, y - r), P(x, y), P(x + r, y), P(x, y), P(x, y + r), P(x, y), P(x - r, y), P(x, y), P(x, y - r)), col)


def bubbles(S, aldehyde=True):
    S.circle(0, 0, 54, S.rad([(0, "#fff6dc", 0.8), (1, "#fff6dc", 0)]))
    import random
    rnd = random.Random(10)
    for i in range(12):
        x, y, r = rnd.uniform(-40, 40), rnd.uniform(-40, 44), rnd.uniform(5, 15)
        S.circle(x, y, r, S.rad([(0, "#ffffff", 0.1), (0.75, "#d8e8f4", 0.4), (0.9, "#f4c8dc", 0.8), (1, "#b8d4ec", 0.9)]))
        S.ellipse(x - r * 0.35, y - r * 0.4, r * 0.25, r * 0.15, "#ffffff", op=0.9, rot=-30)
    for x, y, r in [(-30, -30, 12), (34, -6, 9), (-6, 36, 8), (24, 34, 6)]:
        sparkle(S, x, y, r)


def wave(S):
    S.path("M-60 20 C-40 -10 -20 -10 -4 10 C6 24 20 20 22 6 C24 -6 12 -10 6 -4 C18 -26 50 -16 60 10 L60 50 L-60 50 Z", S.lin([(0, "#8cc6dc"), (1, "#3f8aa8")]))
    S.path("M-60 20 C-40 -10 -20 -10 -4 10 C6 24 20 20 22 6", None, "#ffffff", 3, 0.8)
    for x, y in [(-30, 30), (0, 38), (30, 26)]:
        S.path("M%s q8 -6 16 0" % P(x, y), None, "#ffffff", 2, 0.5)


def melon_slice(S, x, y, s):
    with S.g("translate(%s %s) scale(%s)" % (x, y, s)):
        S.path("M-30 0 A30 30 0 0 0 30 0 Z", "#6f9a5a")
        S.path("M-26 0 A26 26 0 0 0 26 0 Z", "#d8eab0")
        S.path("M-22 0 A22 22 0 0 0 22 0 Z", S.rad([(0, "#f6f0c8"), (1, "#e8e0a0")], 0.5, 0, 1))
        for k in range(6):
            S.ellipse(-12 + k * 5, 6 + abs(k - 2.5) * 1.5, 1.5, 3, "#c9b06a")


# ------------------------------------------------------------------ solvents & auxiliaries
def lab_bottle(S, liquid="#e8f1f6", alpha=0.6):
    shadow(S, 0, 54, 40, 7)
    S.path("M-12 -46 L12 -46 L12 -24 Q36 -12 36 18 Q36 50 0 50 Q-36 50 -36 18 Q-36 -12 -12 -24 Z", S.lin([(0, "#ffffff", 0.75), (1, "#dfe8ee", 0.75)], 0, 0, 1, 0), "#b9c8d2", 2)
    S.path("M-33 10 Q-33 46 0 46 Q33 46 33 10 Z", liquid, op=alpha)
    S.rect(-14, -56, 28, 12, "#c9a07a", rx=3)
    S.path("M-24 -8 Q-30 14 -24 34", None, "#ffffff", 4, 0.8)


def pipette_drop(S, col="#c9e2f2"):
    S.path("M-6 -60 L6 -60 L6 -22 L2 -8 L-2 -8 L-6 -22 Z", S.lin([(0, "#ffffff", 0.85), (1, "#c9d8e4", 0.85)], 0, 0, 1, 0), "#7f97aa", 1.6)
    S.rect(-9, -72, 18, 14, "#e09aa9", rx=5)
    drop(S, 0, 22, 14, col, 0.85)
    S.ellipse(0, 50, 30, 6, S.rad([(0, col, 0.8), (1, col, 0)]))


def oil_drops(S, col):
    shadow(S, 0, 52, 46, 7)
    drop(S, -10, 10, 22, col, 0.92)
    drop(S, 26, 30, 11, col, 0.9)
    drop(S, -32, 36, 8, col, 0.9)


def spoon_drop(S):
    shadow(S, 0, 50, 54, 7)
    S.path("M-56 24 L-6 18 Q10 2 30 4 Q52 8 52 22 Q50 36 28 38 Q8 38 -4 26 L-56 30 Z", S.lin([(0, "#e6e8ee"), (1, "#8d93a0")]), "#7a808c", 1.2)
    S.ellipse(26, 21, 18, 11, S.rad([(0, "#ffffff", 0.95), (1, "#c9d8e6", 0.95)]))
    drop(S, 26, -6, 13, "#cfe0ee", 0.95)


def shield(S, inner="leaf"):
    S.circle(0, 0, 52, S.rad([(0, "#e9f2e4", 0.9), (1, "#e9f2e4", 0)]))
    S.path("M0 -46 L38 -32 Q38 20 0 46 Q-38 20 -38 -32 Z", S.lin([(0, "#9fbf8e"), (1, "#5f8f4e")]), "#ffffff", 3)
    if inner == "leaf":
        leaf(S, -10, 16, 34, 11, -0.9, "#e8f3dc")
    else:
        S.circle(0, 0, 13, "#f6d36a")
        for i in range(8):
            a = i * math.tau / 8
            S.line(math.cos(a) * 18, math.sin(a) * 18, math.cos(a) * 25, math.sin(a) * 25, "#f6d36a", 3)


def sun_rays(S, x, y, r, col="#f2c94a", op=0.6):
    for i in range(12):
        a = i * math.tau / 12
        S.path("M%s L%s L%s Z" % (P(x + math.cos(a - 0.08) * r * 0.5, y + math.sin(a - 0.08) * r * 0.5), P(x + math.cos(a) * r, y + math.sin(a) * r), P(x + math.cos(a + 0.08) * r * 0.5, y + math.sin(a + 0.08) * r * 0.5)), col, op=op)
