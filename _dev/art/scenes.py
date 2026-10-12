"""Illustrated environments (assets/art/scenes/*.svg), 1200x700 with rounded corners baked in.
Text-free: the game overlays company names on the blank plaques at known positions (see PLAQUES)."""
import math, os, random
from lib import SVG, P, light, dark, mix, smooth_closed, smooth_open, blob_d, leaf_d, star_pts
import motifs as M

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "art", "scenes")
W, H = 1200, 700
# plaque rectangles (x, y, w, h) in scene units for the game's name overlay
PLAQUES = {}

VIAL_COLS = ["#f2c94a", "#e79ab3", "#c98b5a", "#8fc1a0", "#b49ae0", "#f08a5d", "#e8dcc0", "#d6953a", "#9fcfe0", "#c4677f", "#f6e7a8", "#7a4a2a"]


def new():
    S = SVG(W, H, 1080, 630)
    clip = S.clip_rrect(0, 0, W, H, 0)
    return S, S.g(clip=clip)


# ------------------------------------------------------------------ shared pieces
def sky(S, top, bottom, h=H):
    S.rect(0, 0, W, h, S.lin([(0, top), (1, bottom)]))


def sun(S, x, y, r, col="#fff1c8"):
    S.circle(x, y, r * 3, S.rad([(0, col, 0.55), (1, col, 0)]))
    S.circle(x, y, r, S.rad([(0, "#fffaf0"), (1, col)]))


def cloud(S, x, y, s=1.0, op=0.85, col="#ffffff"):
    with S.g("translate(%s %s) scale(%s)" % (x, y, s), opacity=op):
        for dx, dy, r in [(-50, 6, 26), (-18, -10, 36), (22, -4, 30), (52, 8, 22), (0, 10, 30)]:
            S.circle(dx, dy, r, col)


def hills(S, y, col, amp=30, seed=1, h=H):
    rnd = random.Random(seed)
    pts = [(0, y)]
    for i in range(1, 9):
        pts.append((i * W / 8, y + rnd.uniform(-amp, amp)))
    d = "M0 %s " % h + "L" + " L".join(P(x, yy) for x, yy in pts) + " L%s %s Z" % (W, h)
    S.path(d, col)


def cypress(S, x, y, h, col="#6f8f5a"):
    S.path("M%s C%s %s %s C%s %s %s Z" % (P(x, y), P(x - h * 0.16, y - h * 0.4), P(x - h * 0.05, y - h * 0.9), P(x, y - h),
                                           P(x + h * 0.05, y - h * 0.9), P(x + h * 0.16, y - h * 0.4), P(x, y)), S.lin([(0, light(col, 0.15)), (1, dark(col, 0.15))], 0, 0, 1, 0))


def round_tree(S, x, y, r, col="#8aab7a", trunk="#8a6a4a"):
    S.rect(x - r * 0.08, y - r * 0.2, r * 0.16, r * 0.9, trunk, rx=3)
    for dx, dy, rr in [(-0.45, 0.05, 0.6), (0.45, 0.08, 0.58), (0, -0.35, 0.7), (0, 0.1, 0.72)]:
        S.circle(x + dx * r, y - r * 0.6 + dy * r, rr * r, S.rad([(0, light(col, 0.25)), (1, dark(col, 0.12))], 0.35, 0.3, 0.8))


def pot_plant(S, x, y, s=1.0, pot="#e9d2bf", leaf_col="#7f9f6a"):
    with S.g("translate(%s %s) scale(%s)" % (x, y, s)):
        S.ellipse(0, 4, 46, 8, "#5a3640", op=0.12)
        for i, a in enumerate(range(-160, -10, 16)):
            r = math.radians(a)
            L = 70 + (i % 3) * 18
            S.path(leaf_d(0, -50, L, 13, r), S.lin([(0, light(leaf_col, 0.2)), (1, dark(leaf_col, 0.2))], 0, 0, 1, 1))
        S.path("M-36 -56 L36 -56 L28 0 L-28 0 Z", S.lin([(0, light(pot, 0.2)), (1, dark(pot, 0.1))], 0, 0, 1, 0))
        S.rect(-40, -64, 80, 12, light(pot, 0.1), rx=4)


def olive_tree(S, x, y, s=1.0):
    with S.g("translate(%s %s) scale(%s)" % (x, y, s)):
        S.ellipse(0, 4, 60, 10, "#5a3640", op=0.12)
        S.path("M-6 -60 C-14 -120 6 -150 -4 -200 M2 -60 C14 -110 30 -130 40 -170", None, "#7a5a3a", 7)
        rnd = random.Random(3)
        for i in range(70):
            cx, cy = rnd.uniform(-70, 80), rnd.uniform(-260, -140)
            S.path(leaf_d(cx, cy, 20, 5, rnd.uniform(0, 6.28)), ["#8ea67a", "#a3b88e", "#7a9468"][i % 3])
        S.path("M-44 -64 L44 -64 L34 0 L-34 0 Z", S.lin([(0, "#f0e2d4"), (1, "#d8bfa8")], 0, 0, 1, 0))
        S.rect(-48, -72, 96, 12, "#f4e8dc", rx=4)


def vial(S, x, y, h, col, cap="#c9a55a", w=None):
    w = w or h * 0.32
    S.rect(x - w / 2, y - h, w, h, "#ffffff", rx=w * 0.3, op=0.55)
    S.rect(x - w / 2 + 1.5, y - h * 0.62, w - 3, h * 0.62 - 1.5, col, rx=w * 0.25, op=0.9)
    S.rect(x - w / 2 - 1, y - h - h * 0.28, w + 2, h * 0.3, cap, rx=2)
    S.rect(x - w / 2 + 2, y - h + 3, 2, h * 0.7, "#ffffff", op=0.6)


def mini_bottle(S, x, y, s, liquid, cap="#c9a55a", shape=0):
    """Small perfume bottle silhouette for scenes (bottom-centre at x,y)."""
    with S.g("translate(%s %s) scale(%s)" % (x, y, s)):
        S.ellipse(0, 2, 26, 4, "#5a3640", op=0.15)
        if shape == 0:
            S.rect(-22, -52, 44, 52, S.lin([(0, light(liquid, 0.5), 0.9), (1, liquid, 0.95)], 0, 0, 1, 0), rx=8)
        elif shape == 1:
            S.ellipse(0, -26, 24, 26, S.lin([(0, light(liquid, 0.5), 0.9), (1, liquid, 0.95)], 0, 0, 1, 0))
        else:
            S.path("M-16 -52 L16 -52 L26 -12 Q26 0 14 0 L-14 0 Q-26 0 -26 -12 Z", S.lin([(0, light(liquid, 0.5), 0.9), (1, liquid, 0.95)], 0, 0, 1, 0))
        S.rect(-14, -40, 28, 16, "#fbf6ee", rx=2, op=0.85)
        S.rect(-16, -6 - 46, 4, 40, "#ffffff", op=0.45) if shape == 0 else None
        S.rect(-6, -60, 12, 9, dark(cap, 0.15))
        S.rect(-10, -80, 20, 22, S.lin([(0, light(cap, 0.35)), (1, dark(cap, 0.2))], 0, 0, 1, 0), rx=3)


def flask(S, x, y, h, liquid, kind="erlen"):
    gl = S.lin([(0, "#ffffff", 0.7), (1, "#e4edf2", 0.7)], 0, 0, 1, 0)
    if kind == "erlen":
        d = "M%s L%s L%s L%s Q%s %s Q%s %s L%s Z" % (P(x - h * 0.1, y - h), P(x + h * 0.1, y - h), P(x + h * 0.1, y - h * 0.62), P(x + h * 0.42, y - h * 0.06),
                                                    P(x + h * 0.46, y), P(x + h * 0.36, y), P(x - h * 0.36, y), P(x - h * 0.46, y), P(x - h * 0.1, y - h * 0.62))
        S.path(d, gl, "#a8bccb", 2)
        S.path("M%s L%s Q%s %s L%s Q%s %s Z" % (P(x - h * 0.3, y - h * 0.3), P(x + h * 0.3, y - h * 0.3), P(x + h * 0.44, y), P(x + h * 0.34, y), P(x - h * 0.34, y), P(x - h * 0.44, y), P(x - h * 0.3, y - h * 0.3)), liquid, op=0.85)
    elif kind == "round":
        S.circle(x, y - h * 0.32, h * 0.32, gl, "#a8bccb", 2)
        S.rect(x - h * 0.07, y - h, h * 0.14, h * 0.42, gl, "#a8bccb", 2)
        S.path("M%s A%s 0 0 0 %s Z" % (P(x - h * 0.3, y - h * 0.28), P(h * 0.3, h * 0.3), P(x + h * 0.3, y - h * 0.28)), liquid, op=0.85)
    else:  # beaker
        S.path("M%s L%s L%s L%s Z" % (P(x - h * 0.3, y - h * 0.8), P(x + h * 0.3, y - h * 0.8), P(x + h * 0.28, y), P(x - h * 0.28, y)), gl, "#a8bccb", 2)
        S.rect(x - h * 0.27, y - h * 0.45, h * 0.54, h * 0.45, liquid, op=0.85)
        for k in range(3):
            S.line(x - h * 0.28, y - h * 0.2 - k * h * 0.15, x - h * 0.16, y - h * 0.2 - k * h * 0.15, "#8aa0b0", 1.5)
    S.line(x - h * 0.05, y - h * 0.9, x - h * 0.05, y - h * 0.5, "#ffffff", 3, 0.7)


def pendant(S, x, y_top, length, col="#d4a95a", glow=True):
    S.line(x, y_top, x, y_top + length, "#8a6a4a", 2)
    if glow:
        S.circle(x, y_top + length + 30, 120, S.rad([(0, "#fff3d0", 0.55), (1, "#fff3d0", 0)]))
    S.path("M%s Q%s %s L%s Z" % (P(x - 44, y_top + length + 36), P(x, y_top + length - 18), P(x + 44, y_top + length + 36), P(x - 44, y_top + length + 36)), S.lin([(0, light(col, 0.3)), (1, dark(col, 0.2))], 0, 0, 1, 0))
    S.ellipse(x, y_top + length + 37, 30, 6, "#fff6dc")


def plaque(S, name, x, y, w, h, col="#7b2742", border="#d9b77a"):
    S.rect(x - 4, y - 4, w + 8, h + 8, border, rx=8)
    S.rect(x, y, w, h, S.lin([(0, light(col, 0.12)), (1, dark(col, 0.12))]), rx=6)
    S.rect(x + 6, y + 6, w - 12, h - 12, None, rx=4, stroke=border, sw=1.5, op=0.7)
    PLAQUES[name] = [x, y, w, h]


def striped_awning(S, x, y, w, h, c1="#efc6c8", c2="#fbf6ef", n=9):
    sw = w / n
    for i in range(n):
        S.path("M%s L%s L%s Q%s %s Z" % (P(x + i * sw, y), P(x + (i + 1) * sw, y), P(x + (i + 1) * sw + 6, y + h), P(x + i * sw + sw / 2 + 3, y + h + 14), P(x + i * sw + 6, y + h)),
               c1 if i % 2 == 0 else c2, dark(c1, 0.15), 1)


def cobbles(S, y0, y1, col="#e6d8c8"):
    S.rect(0, y0, W, y1 - y0, S.lin([(0, light(col, 0.1)), (1, dark(col, 0.08))]))
    rnd = random.Random(5)
    for r in range(int((y1 - y0) / 18)):
        y = y0 + 8 + r * 18
        off = (r % 2) * 20
        for i in range(32):
            x = off + i * 40 + rnd.uniform(-3, 3)
            S.ellipse(x, y, 17, 6, dark(col, 0.06), op=0.5)


def street_lamp(S, x, y, h, col="#4a3a40"):
    S.rect(x - 4, y - h, 8, h, col)
    S.rect(x - 12, y - 10, 24, 10, col, rx=3)
    S.path("M%s L%s L%s L%s Z" % (P(x - 16, y - h - 34), P(x + 16, y - h - 34), P(x + 10, y - h), P(x - 10, y - h)), "#fff3cf", col, 3)
    S.path("M%s L%s L%s Z" % (P(x - 20, y - h - 34), P(x, y - h - 50), P(x + 20, y - h - 34)), col)
    S.circle(x, y - h - 18, 60, S.rad([(0, "#fff3d0", 0.35), (1, "#fff3d0", 0)]))


def flower_box(S, x, y, w, col="#e7708d"):
    rnd = random.Random(int(x))
    for i in range(int(w / 9)):
        S.circle(x + 6 + i * 9 + rnd.uniform(-2, 2), y - 6 + rnd.uniform(-4, 3), 6, "#7f9f6a")
    for i in range(int(w / 12)):
        S.circle(x + 8 + i * 12 + rnd.uniform(-3, 3), y - 10 + rnd.uniform(-5, 2), 4.5, col)
    S.rect(x, y - 2, w, 12, "#b9876a", rx=2)


def window(S, x, y, w, h, frame="#fbf6ef", glass=None, shutters=None, arch=False, panes=2):
    glass = glass or S.lin([(0, "#cfe3ec"), (1, "#f2e4dc")])
    if shutters:
        S.rect(x - w * 0.42, y, w * 0.4, h, shutters, rx=2)
        S.rect(x + w * 1.02, y, w * 0.4, h, shutters, rx=2)
        for k in range(int(h / 10)):
            S.line(x - w * 0.4, y + 6 + k * 10, x - w * 0.04, y + 6 + k * 10, dark(shutters, 0.15), 1.2, 0.6)
            S.line(x + w * 1.04, y + 6 + k * 10, x + w * 1.4, y + 6 + k * 10, dark(shutters, 0.15), 1.2, 0.6)
    if arch:
        d = "M%s L%s A%s 0 0 1 %s L%s Z" % (P(x, y + h), P(x, y + w / 2), P(w / 2, w / 2), P(x + w, y + w / 2), P(x + w, y + h))
        S.path(d, frame)
        di = "M%s L%s A%s 0 0 1 %s L%s Z" % (P(x + 6, y + h - 6), P(x + 6, y + w / 2), P(w / 2 - 6, w / 2 - 6), P(x + w - 6, y + w / 2), P(x + w - 6, y + h - 6))
        S.path(di, glass)
    else:
        S.rect(x, y, w, h, frame, rx=3)
        S.rect(x + 6, y + 6, w - 12, h - 12, glass)
    S.line(x + w / 2, y + 6, x + w / 2, y + h - 6, frame, 4)
    for k in range(1, panes):
        S.line(x + 6, y + h * k / panes, x + w - 6, y + h * k / panes, frame, 4)
    S.path("M%s L%s" % (P(x + w * 0.15, y + h * 0.75), P(x + w * 0.35, y + h * 0.2)), None, "#ffffff", 5, 0.45)


# ------------------------------------------------------------------ 1. laboratory
def lab():
    S, g = new()
    with g:
        S.rect(0, 0, W, 540, S.lin([(0, "#f8efe7"), (1, "#efdfd3")]))
        # wainscot
        S.rect(0, 390, W, 150, "#ecdacb")
        S.rect(0, 386, W, 6, "#d9b77a")
        for i in range(8):
            S.rect(20 + i * 150, 410, 130, 110, None, rx=6, stroke="#dcc3b1", sw=2)
        # floor
        S.rect(0, 540, W, 160, S.lin([(0, "#e3c9ac"), (1, "#c9a684")]))
        for i in range(-10, 40):
            S.line(i * 40, 540, i * 40 + 90, 700, "#b8916c", 1.2, 0.35)
        S.ellipse(640, 640, 420, 46, "#e2b7b9", op=0.55)
        S.ellipse(640, 640, 380, 36, None, "#f3dcdc", 3, 0.7)
        # arched window
        x0, y0, ww, hh = 120, 70, 300, 330
        S.path("M%s L%s A150 150 0 0 1 %s L%s Z" % (P(x0 - 14, y0 + hh + 10), P(x0 - 14, y0 + 150), P(x0 + ww + 14, y0 + 150), P(x0 + ww + 14, y0 + hh + 10)), "#fbf6ef")
        clipw = S.clip_path("M%s L%s A150 150 0 0 1 %s L%s Z" % (P(x0, y0 + hh), P(x0, y0 + 150), P(x0 + ww, y0 + 150), P(x0 + ww, y0 + hh)))
        with S.g(clip=clipw):
            S.rect(x0, y0, ww, hh, S.lin([(0, "#cfe5ee"), (0.7, "#f6e6dc"), (1, "#f7dcc8")]))
            sun(S, x0 + 210, y0 + 110, 22)
            S.path("M%s Q%s %s T%s L%s Z" % (P(x0, y0 + 270), P(x0 + 80, y0 + 230), P(x0 + 160, y0 + 260), P(x0 + ww, y0 + 250), P(x0 + ww, y0 + hh)) + " L%s Z" % P(x0, y0 + hh), "#bcd2a8")
            S.path("M%s Q%s %s T%s L%s L%s Z" % (P(x0, y0 + 300), P(x0 + 100, y0 + 270), P(x0 + 180, y0 + 295), P(x0 + ww, y0 + 285), P(x0 + ww, y0 + hh), P(x0, y0 + hh)), "#a6c294")
            for i, cx in enumerate([x0 + 40, x0 + 64, x0 + 230, x0 + 252]):
                cypress(S, cx, y0 + 300, 90 + (i % 2) * 30, "#6f8f5a")
            for i in range(4):
                S.rect(x0 + 120 + i * 22, y0 + 262, 18, 14, "#f3e6d6")
                S.poly([(x0 + 118 + i * 22, y0 + 263), (x0 + 129 + i * 22, y0 + 254), (x0 + 140 + i * 22, y0 + 263)], "#d98a64")
        S.line(x0 + ww / 2, y0, x0 + ww / 2, y0 + hh, "#fbf6ef", 8)
        S.line(x0, y0 + 220, x0 + ww, y0 + 220, "#fbf6ef", 8)
        S.line(x0, y0 + 150, x0 + ww, y0 + 150, "#fbf6ef", 6)
        # sun beam
        S.path("M%s L%s L%s L%s Z" % (P(x0 + 40, y0 + 160), P(x0 + ww, y0 + 120), P(760, 700), P(330, 700)), "#fffaf0", op=0.22)
        # sill with pots
        S.rect(x0 - 24, y0 + hh + 8, ww + 48, 16, "#f4eadf", rx=4)
        for k, cx in enumerate([x0 + 30, x0 + 150, x0 + 260]):
            S.path("M%s L%s L%s L%s Z" % (P(cx - 22, y0 + hh + 8), P(cx + 22, y0 + hh + 8), P(cx + 16, y0 + hh - 22), P(cx - 16, y0 + hh - 22)), "#d9a58a")
            if k == 1:
                with S.g("translate(%s %s) scale(0.55)" % (cx, y0 + hh - 60)):
                    M.lavender(S)
            else:
                for j in range(9):
                    S.path(leaf_d(cx, y0 + hh - 22, 30 + (j % 3) * 6, 6, -1.57 + (j - 4) * 0.28), "#7f9f6a")
        # botanical print
        S.rect(470, 120, 150, 190, "#d9b77a", rx=4)
        S.rect(478, 128, 134, 174, "#fbf6ef")
        with S.g("translate(545 205) scale(0.75)"):
            M.rose(S, "#e48aa0")
        # pendant lamps
        pendant(S, 600, 0, 80)
        pendant(S, 820, 0, 60)
        # perfume organ
        S.path("M760 520 L760 150 Q960 100 1160 150 L1160 520 Z", S.lin([(0, "#9a6a48"), (1, "#7a4e34")]))
        S.path("M776 520 L776 166 Q960 120 1144 166 L1144 520 Z", "#f3e4d6", op=0.25)
        rnd = random.Random(11)
        for t in range(5):
            y = 210 + t * 66
            S.path("M%s Q960 %s %s L%s Q960 %s %s Z" % (P(770, y), y - 34 + t * 2, P(1150, y), P(1150, y + 12), y - 22 + t * 2, P(770, y + 12)), S.lin([(0, "#b07a52"), (1, "#7a4e34")]))
            for i in range(17):
                x = 790 + i * 21.5
                yy = y - 30 * (1 - ((x - 960) / 190) ** 2) + t * 2 + 2
                vial(S, x, yy, 30 + rnd.uniform(-4, 4), rnd.choice(VIAL_COLS), ["#c9a55a", "#3a2a30", "#d4c2b0"][i % 3])
        # workbench
        S.rect(290, 470, 800, 26, S.lin([(0, "#fbf8f4"), (1, "#e6dfd8")]), rx=6)
        S.path("M330 474 Q420 488 520 476 T720 482 T900 476", None, "#cfc6be", 1.5, 0.8)
        S.rect(306, 496, 768, 150, S.lin([(0, "#d6aa7c"), (1, "#b88a5e")]))
        for i in range(4):
            S.rect(322 + i * 190, 512, 172, 120, None, rx=6, stroke="#a87a50", sw=2)
            S.circle(408 + i * 190, 572, 7, "#e6c98a")
        # bench items
        S.rect(330, 452, 90, 18, "#f7f1e8", rx=2)
        S.rect(334, 446, 86, 8, "#7b2742", rx=2)
        S.line(352, 458, 410, 456, "#3a2a30", 2)
        flask(S, 470, 470, 110, "#f2a7b8", "erlen")
        S.rect(548, 360, 6, 110, "#9aa4ae")
        S.rect(530, 466, 60, 6, "#9aa4ae", rx=2)
        S.line(551, 380, 600, 380, "#9aa4ae", 4)
        flask(S, 600, 470, 96, "#f2c46a", "round")
        flask(S, 680, 470, 80, "#c3aee6", "beaker")
        S.rect(730, 440, 90, 30, "#c9a07a", rx=4)
        for k, c in enumerate(["#f2a7b8", "#9fcfe0", "#f2c46a", "#b9d89a", "#c3aee6"]):
            S.rect(738 + k * 16, 392, 10, 64, "#ffffff", rx=5, op=0.7, stroke="#a8bccb", sw=1)
            S.rect(739 + k * 16, 424, 8, 31, c, rx=4)
        S.rect(846, 446, 96, 24, "#f4f2ef", rx=4, stroke="#cfc6be", sw=1.5)
        S.rect(856, 452, 34, 12, "#7fb8b0", rx=2)
        S.ellipse(916, 444, 22, 5, "#d8d4ce")
        mini_bottle(S, 916, 442, 0.45, "#f6d27a", "#c9a55a", 0)
        S.path("M972 470 L966 420 L1000 420 L994 470 Z", "#ffffff", "#a8bccb", 1.5, 0.75)
        for k in range(6):
            S.path("M%s L%s" % (P(978 + k * 3, 424), P(962 + k * 9, 360 - (k % 2) * 8)), None, "#fbf8f2", 5)
            S.path("M%s L%s" % (P(978 + k * 3, 424), P(962 + k * 9, 360 - (k % 2) * 8)), None, "#e6dccf", 1, 0.8)
        S.path("M1030 470 Q1020 440 1036 420 L1060 420 Q1076 440 1066 470 Z", S.lin([(0, "#ffffff", 0.6), (1, "#e4edf2", 0.6)]), "#a8bccb", 1.5)
        for k, (dx, dy, c) in enumerate([(-14, -24, "#e48aa0"), (12, -30, "#c8304f"), (0, -46, "#ef8aa0")]):
            S.line(1048, 430, 1048 + dx * 0.6, 410 + dy * 0.4, "#5f8f4e", 2)
            with S.g("translate(%s %s) scale(0.32)" % (1048 + dx, 404 + dy)):
                M.rose(S, c, False)
        # olive tree
        olive_tree(S, 70, 690, 1.0)
    S.raw("")
    return S


# ------------------------------------------------------------------ 2. HQ tier exteriors
def street_base(S, sky_top, sky_bot, ground="#e6d8c8"):
    sky(S, sky_top, sky_bot)
    cloud(S, 210, 110, 1.0, 0.8)
    cloud(S, 960, 80, 0.8, 0.7)
    cloud(S, 680, 150, 0.6, 0.6)
    S.rect(0, 600, W, 100, "#cdbfb2")
    cobbles(S, 560, 610, ground)
    S.rect(0, 556, W, 6, "#d8c6b4")


def hq1():
    S, g = new()
    with g:
        street_base(S, "#d6e8f0", "#f8e8de")
        # neighbours
        S.rect(40, 230, 260, 330, "#e9dfe8")
        for r in range(2):
            for c in range(3):
                window(S, 64 + c * 80, 270 + r * 120, 50, 80, "#fbf6ef", panes=2)
        S.rect(30, 220, 280, 14, "#d8c8d6")
        S.rect(900, 250, 300, 310, "#f4dccc")
        for r in range(2):
            for c in range(3):
                window(S, 930 + c * 86, 290 + r * 115, 52, 78, "#fbf6ef", shutters="#b9cdb0" if c == 1 else None)
        S.rect(890, 240, 320, 14, "#e6c6b2")
        # main building
        S.rect(330, 170, 540, 390, S.lin([(0, "#f8eee2"), (1, "#efe0cf")]))
        S.path("M310 176 L600 96 L890 176 Z", "#d98a64")
        for k in range(8):
            S.line(330 + k * 70, 176, 600, 100, "#c4745a", 1.2, 0.4)
        S.rect(316, 170, 568, 14, "#e8d4c0")
        # upper floor windows
        for c in range(3):
            x = 380 + c * 170
            window(S, x, 214, 90, 120, "#fbf6ef", shutters="#a9c0a0")
            flower_box(S, x - 6, 344, 102, "#e7708d" if c != 1 else "#b49ae0")
        S.rect(330, 372, 540, 10, "#e3d0bd")
        # shop front
        plaque(S, "hq1", 450, 396, 300, 52)
        striped_awning(S, 360, 456, 480, 34)
        S.rect(372, 496, 290, 64, S.lin([(0, "#e6f0f4"), (1, "#f6e9e2")]), stroke="#7b2742", sw=6)
        for k in range(2):
            S.rect(380, 512 + k * 26, 274, 4, "#d9b77a")
        for i in range(9):
            mini_bottle(S, 398 + i * 30, 512 + (i % 2) * 26, 0.22, VIAL_COLS[i], "#c9a55a", i % 3)
        S.rect(690, 488, 112, 72, "#7b2742", rx=4)
        S.rect(700, 498, 92, 62, S.lin([(0, "#e6f0f4"), (1, "#f6e9e2")]))
        S.line(746, 498, 746, 560, "#7b2742", 4)
        S.circle(738, 532, 3, "#d9b77a")
        S.circle(754, 532, 3, "#d9b77a")
        pot_plant(S, 682, 560, 0.42)
        pot_plant(S, 818, 560, 0.42)
        street_lamp(S, 1000, 600, 170)
        # bicycle
        for cx in (180, 252):
            S.circle(cx, 580, 22, None, "#4a3a40", 3)
        S.path("M180 580 L210 548 L252 580 M210 548 L240 548 L252 580 M206 540 L216 540 M236 540 L246 532", None, "#7b2742", 4)
        S.path("M196 548 Q214 534 232 548", "#d9b77a", op=0.0)
    return S


def hq2():
    S, g = new()
    with g:
        street_base(S, "#f1dfe6", "#fbeee2")
        round_tree(S, 90, 560, 110, "#9ab88a")
        round_tree(S, 1110, 560, 110, "#8aab7a")
        bx, bw = 230, 740
        # mansard roof
        S.path("M%s L%s L%s L%s Z" % (P(bx - 10, 150), P(bx + 40, 70), P(bx + bw - 40, 70), P(bx + bw + 10, 150)), S.lin([(0, "#8e98ac"), (1, "#6e788c")]))
        for c in range(5):
            x = bx + 70 + c * 140
            S.path("M%s L%s A20 20 0 0 1 %s L%s Z" % (P(x, 140), P(x, 100), P(x + 40, 100), P(x + 40, 140)), "#fbf6ef")
            S.path("M%s L%s A14 14 0 0 1 %s L%s Z" % (P(x + 6, 136), P(x + 6, 102), P(x + 34, 102), P(x + 34, 136)), "#cfe0ea")
        S.rect(bx - 14, 146, bw + 28, 12, "#e2d4c2")
        S.rect(bx, 156, bw, 404, S.lin([(0, "#f7efe2"), (1, "#eadcc8")]))
        for k in range(14):
            S.line(bx, 170 + k * 28, bx + bw, 170 + k * 28, "#e0cfb8", 1.2, 0.6)
        for r in range(3):
            for c in range(5):
                x = bx + 50 + c * 140
                y = 176 + r * 92
                window(S, x, y, 70, 76, "#fbf6ef", panes=2)
                S.rect(x - 10, y + 76, 90, 6, "#e4d4c0")
                if r == 0:
                    for k in range(9):
                        S.line(x - 8 + k * 10.5, y + 82, x - 8 + k * 10.5, y + 100, "#3a2a30", 2)
                    S.line(x - 10, y + 82, x + 80, y + 82, "#3a2a30", 3)
                    S.line(x - 10, y + 100, x + 80, y + 100, "#3a2a30", 3)
        # ground floor
        S.rect(bx, 452, bw, 108, "#efe3d2")
        S.rect(bx, 448, bw, 8, "#d9b77a")
        for c in range(4):
            x = bx + 34 + c * (180 if c < 2 else 180) + (100 if c >= 2 else 0)
            S.path("M%s L%s A50 50 0 0 1 %s L%s Z" % (P(x, 560), P(x, 510), P(x + 100, 510), P(x + 100, 560)), "#7b2742")
            S.path("M%s L%s A42 42 0 0 1 %s L%s Z" % (P(x + 8, 560), P(x + 8, 512), P(x + 92, 512), P(x + 92, 560)), S.lin([(0, "#e6f0f4"), (1, "#f6e9e2")]))
            S.rect(x + 12, 530, 76, 3, "#d9b77a")
            for i in range(4):
                mini_bottle(S, x + 22 + i * 19, 530, 0.17, VIAL_COLS[(i + c) % 12], "#c9a55a", i % 3)
            striped_awning(S, x - 6, 462, 112, 22, "#9b3550", "#f4e6dc", 6)
        # entrance
        ex = bx + bw / 2 - 50
        S.rect(ex, 486, 100, 74, "#3a2a30", rx=4)
        S.rect(ex + 8, 494, 40, 66, "#5a4a52")
        S.rect(ex + 52, 494, 40, 66, "#5a4a52")
        S.path("M%s L%s L%s L%s Z" % (P(ex - 20, 486), P(ex + 120, 486), P(ex + 110, 470), P(ex - 10, 470)), "#d9b77a")
        plaque(S, "hq2", ex - 70, 392, 240, 48)
        for fx in (bx + 20, bx + bw - 20):
            S.line(fx, 300, fx + (30 if fx < 600 else -30), 280, "#8a6a4a", 3)
            S.rect(fx + (30 if fx < 600 else -78), 270, 48, 30, "#7b2742")
        pot_plant(S, ex - 40, 560, 0.5)
        pot_plant(S, ex + 140, 560, 0.5)
        street_lamp(S, 180, 600, 160)
        street_lamp(S, 1020, 600, 160)
    return S


def hq3():
    S, g = new()
    with g:
        sky(S, "#f6dcc8", "#fbeee2")
        sun(S, 980, 140, 40, "#ffe2b0")
        cloud(S, 260, 120, 1.0, 0.7)
        # background towers
        for x, w, h, c in [(40, 140, 300, "#e2d6e6"), (170, 110, 380, "#d8cfe2"), (980, 160, 340, "#e6d8e0"), (1100, 120, 260, "#ddd2e2")]:
            S.rect(x, 560 - h, w, h, c)
            for r in range(int(h / 30)):
                S.line(x + 10, 580 - h + r * 30, x + w - 10, 580 - h + r * 30, "#ffffff", 2, 0.5)
        # main building
        bx, bw, top = 330, 540, 90
        S.rect(bx, top, bw, 470, "#ece2d6")
        S.rect(bx + 30, top + 20, bw - 60, 360, S.lin([(0, "#a9c4dc"), (0.5, "#c9d4ea"), (1, "#e9d2dc")], 0, 0, 1, 1))
        for c in range(9):
            S.line(bx + 30 + c * 60, top + 20, bx + 30 + c * 60, top + 380, "#d9b77a", 4)
        for r in range(12):
            S.line(bx + 30, top + 20 + r * 30, bx + bw - 30, top + 20 + r * 30, "#f6f0ea", 1.5, 0.8)
        S.path("M%s L%s L%s L%s Z" % (P(bx + 60, top + 20), P(bx + 200, top + 20), P(bx + 60, top + 260), P(bx + 30, top + 260)), "#ffffff", op=0.25)
        S.path("M%s L%s L%s L%s Z" % (P(bx + 260, top + 20), P(bx + 320, top + 20), P(bx + 140, top + 380), P(bx + 80, top + 380)), "#ffffff", op=0.18)
        plaque(S, "hq3", bx + bw / 2 - 150, top - 64, 300, 52, "#2f2a3a", "#d9b77a")
        # lobby
        S.rect(bx, top + 380, bw, 90, "#f6f0ea")
        S.rect(bx + 40, top + 392, bw - 80, 78, S.lin([(0, "#dfe9f1"), (1, "#f6e6e0")]))
        for c in range(7):
            S.line(bx + 40 + c * 76, top + 392, bx + 40 + c * 76, top + 470, "#d9b77a", 3)
        S.rect(bx + bw / 2 - 40, top + 410, 80, 60, "#7b2742", op=0.85)
        S.rect(bx - 30, top + 376, bw + 60, 10, "#d9b77a")
        # plaza & fountain
        S.rect(0, 560, W, 140, S.lin([(0, "#efe4d6"), (1, "#dccdbd")]))
        for i in range(12):
            S.line(i * 110, 560, i * 140 - 300, 700, "#cbb9a6", 1.5, 0.5)
        S.ellipse(600, 640, 170, 30, "#c9b6a2")
        S.ellipse(600, 636, 160, 24, S.lin([(0, "#a9d3e2"), (1, "#7fb6cc")]))
        for k in range(7):
            x = 470 + k * 43
            S.path("M%s Q%s %s %s" % (P(600, 630), P((600 + x) / 2, 560 - abs(k - 3) * 6), P(x, 632), ""), None, "#e6f4fa", 3, 0.85)
        S.rect(594, 600, 12, 36, "#d9d0c4")
        for fx, col in [(150, "#7b2742"), (210, "#d9b77a"), (270, "#6d3f73")]:
            S.rect(fx, 380, 5, 200, "#b8b0a8")
            S.path("M%s Q%s %s %s L%s Q%s %s %s Z" % (P(fx + 5, 386), P(fx + 30, 378), P(fx + 60, 390), "", P(fx + 60, 420), P(fx + 30, 410), P(fx + 5, 416), ""), col)
        round_tree(S, 960, 600, 90, "#9ab88a")
        round_tree(S, 1100, 610, 100, "#8aab7a")
        round_tree(S, 60, 620, 90, "#a3bd92")
    return S


def hq4():
    S, g = new()
    with g:
        sky(S, "#d8c8e8", "#fbe2c8")
        sun(S, 600, 300, 60, "#ffe0a8")
        hills(S, 360, "#c9b8d8", 18, 4)
        hills(S, 390, "#b9c9a8", 14, 7)
        # palace
        cx = 600
        S.rect(170, 220, 860, 190, S.lin([(0, "#fbf3e6"), (1, "#efdfca")]))
        S.rect(160, 208, 880, 16, "#e6d2b8")
        S.path("M150 214 L1050 214 L1030 190 L170 190 Z", "#9aa2b6")
        for c in range(12):
            x = 196 + c * 70 if c < 6 else 250 + c * 70 + 40
            if 470 < x < 730:
                continue
            S.path("M%s L%s A18 18 0 0 1 %s L%s Z" % (P(x, 330), P(x, 262), P(x + 36, 262), P(x + 36, 330)), "#fbf6ef")
            S.path("M%s L%s A13 13 0 0 1 %s L%s Z" % (P(x + 5, 326), P(x + 5, 263), P(x + 31, 263), P(x + 31, 326)), S.lin([(0, "#f6d8a8"), (1, "#f2c48a")]))
            S.rect(x - 4, 334, 44, 5, "#e2cfb6")
            S.rect(x + 5, 350, 26, 40, "#fbf6ef")
            S.rect(x + 9, 354, 18, 32, "#f2d0a0")
        # central pavilion
        S.rect(cx - 140, 150, 280, 260, S.lin([(0, "#fdf6ea"), (1, "#f0e0cc")]))
        S.path("M%s L%s L%s Z" % (P(cx - 160, 156), P(cx, 96), P(cx + 160, 156)), "#f4e8d8", "#d9b77a", 3)
        S.path("M%s A110 110 0 0 1 %s Z" % (P(cx - 100, 100), P(cx + 100, 100)), S.lin([(0, "#e8c47a"), (1, "#b8873e")], 0, 0, 1, 0))
        S.rect(cx - 4, -24, 8, 30, "#d9b77a")
        S.circle(cx, -26, 8, "#f2d48a")
        for k in range(6):
            S.line(cx - 90 + k * 36, 100 - (60 if 1 <= k <= 4 else 30), cx - 90 + k * 36, 100, "#a8783a", 2, 0.5)
        for k in range(6):
            x = cx - 120 + k * 48
            S.rect(x, 200, 16, 200, S.lin([(0, "#ffffff"), (1, "#e6d6c0")], 0, 0, 1, 0))
            S.rect(x - 4, 196, 24, 8, "#e6d2b8")
        S.path("M%s L%s A40 40 0 0 1 %s L%s Z" % (P(cx - 40, 410), P(cx - 40, 320), P(cx + 40, 320), P(cx + 40, 410)), "#7b2742")
        S.path("M%s L%s A32 32 0 0 1 %s L%s Z" % (P(cx - 32, 410), P(cx - 32, 322), P(cx + 32, 322), P(cx + 32, 410)), S.lin([(0, "#f6d8a8"), (1, "#e8b878")]))
        plaque(S, "hq4", cx - 130, 160, 260, 30, "#7b2742", "#e8c47a")
        for k in range(5):
            S.rect(cx - 120 - k * 14, 410 + k * 8, 240 + k * 28, 8, "#efe2d0" if k % 2 == 0 else "#e6d6c2")
        # formal garden
        S.rect(0, 450, W, 250, S.lin([(0, "#cfe0bc"), (1, "#a9c494")]))
        for k in range(10):
            S.path("M%s L%s L%s L%s Z" % (P(cx - 30 - k * 60, 460), P(cx - 10 - k * 60, 460), P(cx - 160 - k * 130, 700), P(cx - 110 - k * 130, 700)), "#b49ae0" if k % 2 else "#9b80cc", op=0.9)
            S.path("M%s L%s L%s L%s Z" % (P(cx + 10 + k * 60, 460), P(cx + 30 + k * 60, 460), P(cx + 110 + k * 130, 700), P(cx + 160 + k * 130, 700)), "#b49ae0" if k % 2 else "#9b80cc", op=0.9)
        S.path("M%s L%s L%s L%s Z" % (P(cx - 24, 450), P(cx + 24, 450), P(cx + 110, 700), P(cx - 110, 700)), "#efe4d4")
        S.ellipse(cx, 600, 120, 28, "#d9cbb8")
        S.ellipse(cx, 596, 108, 20, S.lin([(0, "#bfe0ea"), (1, "#8ec2d4")]))
        S.path("M%s Q%s %s" % (P(cx - 50, 594), P(cx, 470), P(cx + 50, 594)), None, "#eaf6fa", 4, 0.9)
        S.line(cx, 594, cx, 500, "#eaf6fa", 5, 0.9)
        for x in (300, 420, 780, 900):
            S.path("M%s L%s L%s Z" % (P(x - 18, 470), P(x, 400), P(x + 18, 470)), S.lin([(0, "#7f9f6a"), (1, "#5d7f4c")], 0, 0, 1, 0))
            S.rect(x - 14, 470, 28, 14, "#e6d6c2")
        for x, s in [(60, 1.1), (1140, 1.1)]:
            cypress(S, x, 520, 220 * s, "#6f8f5a")
    return S


# ------------------------------------------------------------------ 3. factory
def factory():
    S, g = new()
    with g:
        S.rect(0, 0, W, H, S.lin([(0, "#eef1f4"), (1, "#e3e6ea")]))
        for c in range(4):
            x = 60 + c * 290
            S.rect(x, 50, 250, 220, "#f8f9fb", stroke="#cfd6dd", sw=4)
            for k in range(1, 4):
                S.line(x + k * 62.5, 50, x + k * 62.5, 270, "#cfd6dd", 3)
            S.line(x, 160, x + 250, 160, "#cfd6dd", 3)
            S.path("M%s L%s L%s L%s Z" % (P(x + 10, 60), P(x + 110, 60), P(x + 20, 260), P(x + 10, 260)), "#ffffff", op=0.4)
        S.rect(0, 290, W, 12, "#c9d0d8")
        S.path("M0 320 L1200 320", None, "#b9c2cc", 10)
        S.path("M0 336 L1200 336", None, "#d9b77a", 6)
        S.rect(0, 520, W, 180, S.lin([(0, "#dde2e7"), (1, "#c9d0d8")]))
        for i in range(-6, 30):
            S.line(i * 60, 520, i * 60 - 120, 700, "#ffffff", 2, 0.3)
        # tanks
        for i, (x, h, liq) in enumerate([(130, 260, "#f2a7b8"), (290, 300, "#f2c46a"), (450, 240, "#c3aee6")]):
            S.ellipse(x, 540, 76, 12, "#8a96a2", op=0.3)
            S.rect(x - 64, 540 - h, 128, h - 40, S.lin([(0, "#f4f6f8"), (0.35, "#c9d0d8"), (0.7, "#e8ecf0"), (1, "#a8b2bc")], 0, 0, 1, 0))
            S.ellipse(x, 540 - h, 64, 22, S.lin([(0, "#f4f6f8"), (1, "#b8c2cc")]))
            S.rect(x - 64, 540 - h * 0.62, 128, 8, "#b8c2cc")
            S.rect(x - 40, 460, 10, 80, "#9aa4ae")
            S.rect(x + 30, 460, 10, 80, "#9aa4ae")
            S.circle(x, 540 - h * 0.4, 18, "#ffffff", "#8a96a2", 3)
            S.line(x, 540 - h * 0.4, x + 10, 540 - h * 0.4 - 8, "#7b2742", 3)
            S.rect(x + 50, 540 - h + 40, 10, h - 120, "#ffffff", rx=5, op=0.6, stroke="#a8b2bc", sw=1.5)
            S.rect(x + 51, 540 - h * 0.55, 8, h * 0.55 - 82, liq, rx=4)
            S.path("M%s L%s L%s" % (P(x, 540 - h - 20), P(x, 340), P(x + 160, 340)), None, "#b8c2cc", 8)
        # filling line
        S.rect(560, 450, 640, 26, "#4a4a56", rx=13)
        for k in range(22):
            S.circle(574 + k * 29, 463, 8, "#6a6a78")
        S.rect(560, 476, 640, 60, "#d4d9de")
        for k in range(3):
            S.rect(600 + k * 200, 476, 10, 60, "#aab2ba")
        S.rect(640, 300, 260, 110, S.lin([(0, "#fbf8f4"), (1, "#e6e0d8")]), rx=10, stroke="#cfc6be", sw=2)
        S.rect(660, 316, 90, 54, "#2f3a46", rx=6)
        S.path("M668 356 L690 336 L708 346 L740 324", None, "#7fd3c0", 3)
        for k in range(3):
            S.circle(790 + k * 30, 336, 9, ["#7b2742", "#d9b77a", "#7fb8b0"][k])
        for k in range(4):
            x = 670 + k * 60
            S.rect(x, 410, 16, 22, "#9aa4ae")
            S.path("M%s L%s L%s Z" % (P(x, 432), P(x + 16, 432), P(x + 8, 442)), "#9aa4ae")
        for k in range(9):
            x = 590 + k * 66
            mini_bottle(S, x, 450, 0.42, ["#f2a7b8", "#f2c46a", "#c3aee6"][k % 3], "#c9a55a", k % 3)
        # boxes
        for r in range(3):
            for c in range(3 - r):
                x = 960 + c * 70 + r * 35
                y = 640 - r * 54
                S.rect(x, y - 52, 66, 52, "#7b2742" if (r + c) % 2 == 0 else "#d8b48a", rx=3)
                S.rect(x + 22, y - 52, 22, 52, "#d9b77a" if (r + c) % 2 == 0 else "#c9a070", op=0.6)
        S.rect(560, 560, 300, 90, "#c9a070", rx=4)
        for k in range(4):
            S.line(560, 580 + k * 20, 860, 580 + k * 20, "#a8824a", 2, 0.5)
    return S


# ------------------------------------------------------------------ 4. boutique
def boutique():
    S, g = new()
    with g:
        S.rect(0, 0, W, 520, S.lin([(0, "#f8ece6"), (1, "#f1ddd6")]))
        S.rect(0, 0, W, 40, "#efdcd2")
        S.rect(0, 36, W, 6, "#d9b77a")
        # niches
        for i, x in enumerate([120, 470, 820]):
            w, top = 260, 110
            S.path("M%s L%s A%s 0 0 1 %s L%s Z" % (P(x, 470), P(x, top + w / 2), P(w / 2, w / 2), P(x + w, top + w / 2), P(x + w, 470)), "#d9b77a")
            S.path("M%s L%s A%s 0 0 1 %s L%s Z" % (P(x + 8, 470), P(x + 8, top + w / 2), P(w / 2 - 8, w / 2 - 8), P(x + w - 8, top + w / 2), P(x + w - 8, 470)),
                   S.rad([(0, "#fff6e6"), (1, "#f3dccf")], 0.5, 0.35, 0.7))
            for r in range(3):
                y = 250 + r * 76
                S.rect(x + 20, y, w - 40, 6, "#ffffff", op=0.85)
                S.rect(x + 20, y + 6, w - 40, 3, "#d9cfc6", op=0.8)
                for k in range(5):
                    mini_bottle(S, x + 48 + k * 41, y, 0.36, VIAL_COLS[(i * 5 + r * 3 + k) % 12], ["#c9a55a", "#3a2a30", "#e8dcc8"][k % 3], (k + r) % 3)
        # chandelier
        S.line(600, 40, 600, 100, "#c9a55a", 3)
        S.circle(600, 150, 140, S.rad([(0, "#fff3d0", 0.5), (1, "#fff3d0", 0)]))
        S.path("M520 120 Q600 170 680 120", None, "#c9a55a", 4)
        S.path("M540 100 Q600 140 660 100", None, "#c9a55a", 3)
        for k in range(7):
            x = 526 + k * 24.6
            y = 122 + 18 * (1 - ((x - 600) / 74) ** 2)
            S.line(x, y, x, y + 20, "#e8dccf", 1.5)
            M.drop(S, x, y + 28, 4, "#f6eeff", 0.9)
            S.circle(x, y - 6, 5, "#fff6dc")
        # floor
        S.rect(0, 520, W, 180, "#f2e6e0")
        for r in range(5):
            for c in range(16):
                if (r + c) % 2 == 0:
                    y0, y1 = 520 + r * 36, 520 + (r + 1) * 36
                    x0 = (c - 8) * 80 * (1 + r * 0.25) + 600
                    x1 = (c - 7) * 80 * (1 + r * 0.25) + 600
                    x2 = (c - 7) * 80 * (1 + (r + 1) * 0.25) + 600
                    x3 = (c - 8) * 80 * (1 + (r + 1) * 0.25) + 600
                    S.poly([(x0, y0), (x1, y0), (x2, y1), (x3, y1)], "#ead2cf")
        # counter
        S.rect(330, 470, 540, 26, S.lin([(0, "#fbf8f4"), (1, "#e6dfd8")]), rx=6)
        S.path("M360 476 Q460 488 560 478 T800 484", None, "#cfc6be", 1.5, 0.8)
        S.rect(350, 496, 500, 124, S.lin([(0, "#8b3050"), (1, "#6a2038")]))
        S.rect(350, 496, 500, 8, "#d9b77a")
        for k in range(5):
            S.rect(370 + k * 98, 516, 82, 90, None, rx=4, stroke="#a84a68", sw=2)
        mini_bottle(S, 520, 470, 0.7, "#f2a7b8", "#c9a55a", 0)
        mini_bottle(S, 600, 470, 0.85, "#f6d27a", "#3a2a30", 2)
        mini_bottle(S, 680, 470, 0.7, "#c3aee6", "#c9a55a", 1)
        S.rect(410, 450, 70, 20, "#fbf6ee", rx=3)
        S.rect(410, 446, 70, 6, "#7b2742", rx=2)
        # pouf & vase
        S.ellipse(1040, 640, 90, 20, "#5a3640", op=0.12)
        S.path("M960 640 Q950 570 1040 566 Q1130 570 1120 640 Z", S.lin([(0, "#9b3550"), (1, "#6a2038")], 0, 0, 1, 0))
        S.ellipse(1040, 572, 80, 14, "#b04a68")
        S.path("M150 640 Q130 560 170 520 L210 520 Q250 560 230 640 Z", S.lin([(0, "#ffffff", 0.7), (1, "#e4edf2", 0.7)]), "#a8bccb", 2)
        for k, (dx, dy, c) in enumerate([(-30, -40, "#e48aa0"), (20, -60, "#c8304f"), (0, -90, "#ef8aa0"), (40, -20, "#f2c2cf"), (-50, -80, "#e7708d")]):
            S.line(190, 530, 190 + dx * 0.7, 520 + dy * 0.7, "#5f8f4e", 2.5)
            with S.g("translate(%s %s) scale(0.45)" % (190 + dx, 500 + dy)):
                M.rose(S, c, False)
    return S


# ------------------------------------------------------------------ 5. studio (marketing)
def studio():
    S, g = new()
    with g:
        S.rect(0, 0, W, H, S.lin([(0, "#efe6ee"), (1, "#e6dce6")]))
        S.path("M300 0 L900 0 L900 470 Q900 560 1000 600 L200 600 Q300 560 300 470 Z", S.lin([(0, "#f6d6dc"), (1, "#f1c2cc")]))
        S.rect(0, 600, W, 100, S.lin([(0, "#e0d4dc"), (1, "#cfc2cc")]))
        S.rect(296, 0, 8, 24, "#8a7a80")
        S.rect(896, 0, 8, 24, "#8a7a80")
        # plinth
        S.rect(500, 470, 200, 130, S.lin([(0, "#fbf8f4"), (1, "#e2dad2")], 0, 0, 1, 0))
        S.ellipse(600, 470, 100, 16, "#ffffff")
        S.circle(600, 330, 170, S.rad([(0, "#fff8ee", 0.6), (1, "#fff8ee", 0)]))
        mini_bottle(S, 600, 470, 2.2, "#e48aa0", "#c9a55a", 2)
        with S.g("translate(470 590) rotate(-20) scale(0.4)"):
            M.rose_petals(S)
        # softboxes
        for x, flip in [(130, 1), (1070, -1)]:
            S.line(x, 640, x, 260, "#3a3440", 5)
            S.line(x, 640, x - 40, 690, "#3a3440", 4)
            S.line(x, 640, x + 40, 690, "#3a3440", 4)
            with S.g("translate(%s 220) rotate(%s)" % (x, 18 * flip)):
                S.rect(-70, -90, 140, 180, "#3a3440", rx=6)
                S.rect(-62, -82, 124, 164, S.rad([(0, "#ffffff"), (1, "#f6eee6")]), rx=4)
            S.circle(x + 60 * flip, 240, 160, S.rad([(0, "#ffffff", 0.35), (1, "#ffffff", 0)]))
        # camera on tripod
        S.line(860, 700, 900, 520, "#2f2a34", 6)
        S.line(980, 700, 920, 520, "#2f2a34", 6)
        S.line(910, 700, 910, 520, "#2f2a34", 6)
        S.rect(860, 470, 110, 60, "#2f2a34", rx=8)
        S.rect(880, 456, 40, 18, "#2f2a34", rx=4)
        S.circle(880, 500, 30, "#4a4450")
        S.circle(880, 500, 20, S.rad([(0, "#8aa0c0"), (1, "#2a3040")], 0.4, 0.35, 0.7))
        S.circle(874, 494, 5, "#ffffff", op=0.7)
        # reflector
        S.ellipse(330, 560, 70, 40, S.lin([(0, "#f6e2a8"), (1, "#d9b77a")]), rot=-15)
        S.ellipse(330, 560, 70, 40, None, "#ffffff", 3, 0.6, rot=-15)
        # poster frame
        S.rect(960, 70, 200, 260, "#d9b77a", rx=4)
        S.rect(968, 78, 184, 244, S.lin([(0, "#3a2433"), (1, "#7b2742")]))
        S.circle(1060, 180, 70, S.rad([(0, "#f6d6dc", 0.6), (1, "#f6d6dc", 0)]))
        mini_bottle(S, 1060, 270, 1.1, "#f6d27a", "#c9a55a", 0)
        S.rect(990, 290, 140, 6, "#d9b77a", op=0.8)
        S.rect(1010, 302, 100, 4, "#d9b77a", op=0.5)
    return S


# ------------------------------------------------------------------ 6. botanical fields (ingredients)
def garden():
    S, g = new()
    with g:
        sky(S, "#cfe3ee", "#fbe6d6")
        sun(S, 900, 120, 46, "#fff0c8")
        cloud(S, 300, 100, 1.0, 0.8)
        cloud(S, 640, 70, 0.7, 0.7)
        hills(S, 250, "#c9c4dc", 30, 2)
        hills(S, 290, "#bcd2a8", 22, 3)
        # farmhouse
        S.rect(820, 250, 120, 70, "#f6ecdc")
        S.path("M810 252 L880 210 L950 252 Z", "#d98a64")
        S.rect(860, 280, 22, 40, "#9b6a4a")
        for k in range(2):
            S.rect(828 + k * 70, 266, 22, 18, "#cfe0ea")
        cypress(S, 790, 320, 120, "#6f8f5a")
        cypress(S, 970, 320, 100, "#6f8f5a")
        S.path("M0 320 Q300 290 600 310 T1200 300 L1200 700 L0 700 Z", "#c9dab4")
        # lavender rows in perspective
        for k in range(14):
            x_far = 600 + (k - 7) * 40
            x_near = 600 + (k - 7) * 190
            S.path("M%s Q%s %s %s L%s Q%s %s %s Z" % (P(x_far - 6, 320), P((x_far + x_near) / 2 - 20, 500), P(x_near - 60, 700), "", P(x_near + 60, 700), P((x_far + x_near) / 2 + 20, 500), P(x_far + 6, 320), ""),
                   S.lin([(0, "#b6a2dc"), (1, "#8e6cc2")]))
            for j in range(9):
                t = (j + 1) / 10
                cx = x_far + (x_near - x_far) * t * t
                cy = 320 + 380 * t * t
                S.circle(cx, cy - 6 * t, 10 * t + 2, "#a98ad8", op=0.7)
        # rose bushes foreground left
        for x, y, s in [(70, 640, 0.55), (170, 670, 0.6), (40, 560, 0.45)]:
            S.circle(x, y, 80 * s, S.rad([(0, "#8ab07a"), (1, "#5f8f4e")]))
            with S.g("translate(%s %s) scale(%s)" % (x - 20 * s, y - 30 * s, s * 0.5)):
                M.rose(S, "#e7708d", False)
            with S.g("translate(%s %s) scale(%s)" % (x + 30 * s, y - 10 * s, s * 0.45)):
                M.rose(S, "#c8304f", False)
        # citrus tree right
        round_tree(S, 1100, 640, 130, "#7f9f6a")
        rnd = random.Random(4)
        for i in range(12):
            S.circle(1100 + rnd.uniform(-90, 90), 640 - 100 + rnd.uniform(-60, 40), 9, S.rad([(0, "#f7c46a"), (1, "#e9952e")], 0.35, 0.3, 0.8))
        # basket
        S.path("M480 690 Q470 620 520 610 L680 610 Q730 620 720 690 Z", S.lin([(0, "#d9b07a"), (1, "#a8824a")]))
        for k in range(6):
            S.line(490 + k * 40, 612, 486 + k * 42, 690, "#8a6a3a", 2, 0.5)
        S.path("M500 630 Q600 650 700 630", None, "#8a6a3a", 2, 0.5)
        S.path("M500 612 Q600 580 700 612 Z", "#e7708d")
        rnd = random.Random(9)
        for i in range(20):
            S.ellipse(510 + i * 9.5, 606 - rnd.uniform(0, 18), 9, 6, ["#e7708d", "#f2a7b8", "#c8304f"][i % 3], rot=rnd.uniform(0, 180))
    return S


# ------------------------------------------------------------------ 7. office / atelier (company & people)
def office():
    S, g = new()
    with g:
        S.rect(0, 0, W, 540, S.lin([(0, "#f4f1ea"), (1, "#ebe6dc")]))
        for c in range(3):
            x = 640 + c * 180
            S.rect(x, 60, 160, 330, "#fbf8f2", stroke="#d9cfc2", sw=6)
            S.rect(x + 6, 66, 148, 318, S.lin([(0, "#cfe3ee"), (1, "#f2e6de")]))
            for k, (bx, bw, bh) in enumerate([(20, 30, 160), (60, 40, 220), (110, 30, 130)]):
                S.rect(x + bx, 384 - bh, bw, bh, ["#d8cfe2", "#e6d8e0", "#ddd2e2"][k], op=0.9)
            S.line(x + 80, 66, x + 80, 384, "#fbf8f2", 5)
        # mood board
        S.rect(80, 90, 440, 250, "#e8dccc", rx=6, stroke="#d9b77a", sw=4)
        rnd = random.Random(2)
        for i in range(10):
            x, y = 100 + (i % 5) * 84, 110 + (i // 5) * 110
            c = ["#efc6c8", "#a08cc8", "#7f9f6a", "#f2c94a", "#7b2742", "#e79ab3", "#c98b5a", "#9fcfe0", "#f08a5d", "#d9b77a"][i]
            S.rect(x, y, 70, 90, "#ffffff", tr="rotate(%s %s %s)" % (rnd.uniform(-4, 4), x + 35, y + 45))
            S.rect(x + 6, y + 6, 58, 58, c, op=0.9, tr="rotate(%s %s %s)" % (rnd.uniform(-4, 4), x + 35, y + 45))
            S.circle(x + 35, y + 2, 5, "#c4677f")
        # shelves with samples
        S.rect(80, 380, 440, 10, "#c9a07a")
        for k in range(10):
            mini_bottle(S, 104 + k * 44, 380, 0.34, VIAL_COLS[k], "#c9a55a", k % 3)
        # floor & desk
        S.rect(0, 540, W, 160, S.lin([(0, "#e6d6c4"), (1, "#d2bea8")]))
        S.rect(120, 470, 960, 22, S.lin([(0, "#ffffff"), (1, "#ece6de")]), rx=6)
        S.rect(150, 492, 14, 150, "#c9b9a8")
        S.rect(1036, 492, 14, 150, "#c9b9a8")
        for k, x in enumerate([230, 520, 810]):
            S.rect(x, 420, 120, 50, "#3a3440", rx=6)
            S.rect(x + 6, 426, 108, 38, ["#e6d0de", "#d8e6ec", "#efe2c8"][k], rx=3)
            S.path("M%s L%s L%s Z" % (P(x + 30, 470), P(x + 90, 470), P(x + 60, 460)), "#3a3440")
            # chair
            S.ellipse(x + 60, 640, 50, 10, "#5a3640", op=0.12)
            S.path("M%s Q%s %s %s L%s Z" % (P(x + 18, 600), P(x + 60, 520), P(x + 102, 600), "", P(x + 18, 600)), ["#7b2742", "#7f9f6a", "#a08cc8"][k])
            S.rect(x + 56, 600, 8, 36, "#8a7a80")
        S.rect(410, 440, 40, 30, "#fbf6ee", rx=2)
        S.rect(700, 452, 60, 18, "#7b2742", rx=2)
        pendant(S, 360, 0, 60)
        pendant(S, 840, 0, 60)
        pot_plant(S, 1130, 640, 0.9, "#e6d6c4")
        pot_plant(S, 50, 640, 0.75, "#efc6c8")
    return S


# ------------------------------------------------------------------ 8. skyline (finance)
def skyline():
    S, g = new()
    with g:
        sky(S, "#e6d4ec", "#fbe0c4")
        sun(S, 760, 330, 70, "#ffd9a0")
        rnd = random.Random(6)
        x = -20
        towers = []
        while x < W:
            w = rnd.uniform(60, 130)
            h = rnd.uniform(140, 380)
            towers.append((x, w, h))
            x += w + rnd.uniform(4, 16)
        for x, w, h in towers:
            c = rnd.choice(["#d8c8e2", "#e6d0d8", "#e2d6cc", "#cfc4e0"])
            S.rect(x, 480 - h, w, h, c)
            for r in range(int(h / 22)):
                S.line(x + 8, 490 - h + r * 22, x + w - 8, 490 - h + r * 22, "#ffffff", 2, 0.35)
        S.rect(560, 120, 90, 360, S.lin([(0, "#f2d48a"), (1, "#c99a4a")], 0, 0, 1, 0))
        S.path("M560 120 L605 50 L650 120 Z", "#d9b77a")
        S.line(605, 50, 605, 10, "#c99a4a", 4)
        for r in range(16):
            S.line(566, 140 + r * 21, 644, 140 + r * 21, "#fff2d0", 2, 0.6)
        S.rect(0, 480, W, 220, S.lin([(0, "#cdbcd8"), (1, "#bfaecd")]))
        for x, w, h in towers:
            S.rect(x, 482, w, h * 0.35, "#ffffff", op=0.1)
        S.rect(560, 482, 90, 120, "#f2d48a", op=0.3)
        for k in range(18):
            S.line(rnd.uniform(0, W), 520 + k * 9, rnd.uniform(0, W), 520 + k * 9, "#ffffff", 2, 0.25)
        S.path("M0 470 Q300 400 600 470 Q900 400 1200 470", None, "#7b5a6a", 8)
        for k in range(20):
            xx = k * 60 + 30
            yy = 470 - 70 * (1 - ((xx % 600) - 300) ** 2 / 90000)
            S.line(xx, 470, xx, yy, "#7b5a6a", 2)
        for bx, by in [(300, 160), (330, 150), (360, 168)]:
            S.path("M%s q8 -8 16 0 q8 -8 16 0" % P(bx, by), None, "#6a4a5a", 2.5)
    return S


# ------------------------------------------------------------------ 9. still life (menu hero; bottle overlaid by the game)
def stilllife():
    S = SVG(W, 900, 1080, 810)
    with S.g(clip=S.clip_rrect(0, 0, W, 900, 0)):
        S.rect(0, 0, W, 900, S.lin([(0, "#fbf1e8"), (1, "#f3dcd6")]))
        S.path("M300 900 L300 330 A300 300 0 0 1 900 330 L900 900 Z", "#e8c99a")
        S.path("M316 900 L316 330 A284 284 0 0 1 884 330 L884 900 Z", S.rad([(0, "#fff7ec"), (0.7, "#f6dcd8"), (1, "#efc6c8")], 0.5, 0.4, 0.7))
        S.circle(600, 420, 260, S.rad([(0, "#ffffff", 0.75), (1, "#ffffff", 0)]))
        # pedestal
        S.ellipse(600, 860, 300, 30, "#5a3640", op=0.12)
        S.rect(430, 700, 340, 160, S.lin([(0, "#fbf8f4"), (0.5, "#efe8e0"), (1, "#d8cfc6")], 0, 0, 1, 0))
        S.path("M460 740 Q540 760 600 744 T740 754", None, "#d0c6bc", 2, 0.8)
        S.ellipse(600, 700, 170, 26, S.lin([(0, "#ffffff"), (1, "#ece4dc")]))
        S.rect(430, 850, 340, 10, "#d9b77a")
        # botanicals framing
        with S.g("translate(140 560) scale(2.0)"):
            M.lavender(S)
        with S.g("translate(1060 560) scale(1.9)"):
            M.neroli(S)
        with S.g("translate(190 770) scale(2.5)"):
            M.rose(S, "#e48aa0")
        with S.g("translate(350 850) scale(1.5)"):
            M.rose(S, "#c8304f")
        with S.g("translate(1010 790) scale(2.2)"):
            M.jasmine(S)
        with S.g("translate(870 860) scale(1.2)"):
            M.citrus(S, "#f3962b", "#f7b44c")
        rnd = random.Random(3)
        for i in range(14):
            x, y = rnd.uniform(380, 860), rnd.uniform(860, 895)
            S.ellipse(x, y, 12, 7, ["#e7708d", "#f2a7b8", "#efc6c8"][i % 3], rot=rnd.uniform(0, 180))
        for x, y, r in [(250, 220, 14), (960, 260, 10), (880, 120, 8), (330, 380, 7)]:
            M.sparkle(S, x, y, r, "#e2c47a")
    PLAQUES["stilllife_pedestal"] = [600, 700]
    return S


# ------------------------------------------------------------------ 10. world (markets)
def world():
    S, g = new()
    with g:
        sky(S, "#e9f2f4", "#f6e8e0")
        cloud(S, 180, 120, 1.0, 0.7)
        cloud(S, 1000, 560, 1.2, 0.6)
        cx, cy, r = 600, 360, 270
        S.circle(cx, cy + 20, r + 30, S.rad([(0, "#5a3640", 0.12), (1, "#5a3640", 0)]))
        S.circle(cx, cy, r, S.rad([(0, "#d8eef4"), (0.7, "#a9d3e2"), (1, "#7fb6cc")], 0.4, 0.35, 0.75))
        clip = S.clip_path("M%s A%s 0 1 1 %s A%s 0 1 1 %s Z" % (P(cx - r, cy), P(r, r), P(cx + r, cy), P(r, r), P(cx - r, cy)))
        with S.g(clip=clip):
            for k in range(-3, 4):
                S.ellipse(cx, cy, r, r * abs(k) / 3.5 + 0.01, None, "#ffffff", 1.5, 0.35)
                S.ellipse(cx, cy, r * abs(k) / 3.5 + 0.01, r, None, "#ffffff", 1.5, 0.35)
            for (x, y, rr, sx, sy, col, sd) in [(470, 250, 90, 1.2, 0.8, "#bcd2a8", 1), (520, 400, 70, 0.7, 1.3, "#c9d8b4", 2), (690, 260, 110, 1.3, 0.7, "#d8cfa8", 3),
                                                  (720, 400, 80, 0.9, 1.1, "#e6d4b0", 4), (860, 330, 70, 1.0, 0.8, "#bcd2a8", 5), (380, 420, 60, 0.8, 1.0, "#c9d8b4", 6)]:
                S.path(blob_d(x, y, rr, 10, 0.22, sd, sx, sy), col)
        S.ellipse(cx - 90, cy - 140, 90, 40, "#ffffff", op=0.25, rot=-30)
        pins = [(470, 240), (700, 250), (760, 390), (520, 400), (860, 320)]
        for i in range(len(pins) - 1):
            (x0, y0), (x1, y1) = pins[i], pins[i + 1]
            S.path("M%s Q%s %s" % (P(x0, y0), P((x0 + x1) / 2, min(y0, y1) - 110), P(x1, y1)), None, "#7b2742", 3, 0.7, dash="8 8")
        for x, y in pins:
            S.path("M%s C%s %s %s C%s %s %s Z" % (P(x, y), P(x - 18, y - 22), P(x - 16, y - 44), P(x, y - 46), P(x + 16, y - 44), P(x + 18, y - 22), P(x, y)), "#7b2742")
            S.circle(x, y - 30, 7, "#f3dca0")
        with S.g("translate(640 170) rotate(-20)"):
            S.path("M-30 0 L30 0 L40 -6 L44 0 L40 6 L30 0 Z", "#ffffff", "#8a7a80", 1.5)
            S.path("M-6 0 L10 -26 L18 -26 L10 0 Z M-6 0 L10 26 L18 26 L10 0 Z M-26 0 L-34 -12 L-28 -12 L-18 0 Z", "#ffffff", "#8a7a80", 1.5)
    return S


def build():
    os.makedirs(OUT, exist_ok=True)
    out = {}
    for name, fn in [("lab", lab), ("hq1", hq1), ("hq2", hq2), ("hq3", hq3), ("hq4", hq4), ("factory", factory), ("boutique", boutique),
                     ("studio", studio), ("garden", garden), ("office", office), ("skyline", skyline), ("stilllife", stilllife), ("world", world)]:
        S = fn()
        S.save(os.path.join(OUT, name + ".svg"))
        out[name] = 1
    import json
    with open(os.path.join(OUT, "plaques.json"), "w") as f:
        json.dump({"size": [W, H], "plaques": PLAQUES}, f)
    return len(out)


if __name__ == "__main__":
    print("scenes:", build())
