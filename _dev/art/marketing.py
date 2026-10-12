"""Campaign artwork (9 campaign types), retail channel scenes and the award trophy.
Each campaign/channel artwork keeps an empty, lit "hero slot" where the game draws the actual
product bottle (slot rectangles are written to assets/art/campaigns/slots.json)."""
import os, math, random, json
from lib import SVG, P, light, dark, mix, smooth_closed, leaf_d, star_pts
import motifs as M
import scenes as SC

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT_C = os.path.join(ROOT, "assets", "art", "campaigns")
OUT_CH = os.path.join(ROOT, "assets", "art", "channels")
OUT_M = os.path.join(ROOT, "assets", "art", "misc")
W, H = 800, 500
SLOTS = {}


def new():
    S = SVG(W, H, 640, 400)
    return S


def slot(name, x, y, w, h):
    """Hero slot: bottom-centre at (x, y+h); the game fits a bottle into (x, y, w, h)."""
    SLOTS[name] = [x, y, w, h]


def glow(S, x, y, r, col="#fff6e6", a=0.75):
    S.circle(x, y, r, S.rad([(0, col, a), (1, col, 0)]))


def heart(S, x, y, s, col):
    S.path("M%s C%s %s %s C%s %s %s Z" % (P(x, y + s * 0.9), P(x - s * 1.4, y - s * 0.1), P(x - s * 0.6, y - s * 1.1), P(x, y - s * 0.35),
                                           P(x + s * 0.6, y - s * 1.1), P(x + s * 1.4, y - s * 0.1), P(x, y + s * 0.9)), col)


def bubble(S, x, y, w, h, col="#ffffff", tail=1):
    S.rect(x, y, w, h, col, rx=h / 2)
    S.path("M%s L%s L%s Z" % (P(x + w * (0.2 if tail > 0 else 0.8), y + h - 2), P(x + w * (0.2 if tail > 0 else 0.8) - 8 * tail, y + h + 12), P(x + w * (0.2 if tail > 0 else 0.8) + 10 * tail, y + h - 2)), col)


def lines(S, x, y, w, n, col, gap=14, sw=6):
    for i in range(n):
        S.line(x, y + i * gap, x + w * (1.0 if i < n - 1 else 0.6), y + i * gap, col, sw, 0.9)


def podium(S, x, y, w, top="#ffffff", side="#efe6de"):
    S.ellipse(x, y + 52, w * 0.62, 10, "#3a2433", op=0.12)
    S.rect(x - w / 2, y, w, 52, S.lin([(0, light(side, 0.3)), (0.5, side), (1, dark(side, 0.08))], 0, 0, 1, 0))
    S.ellipse(x, y, w / 2, w * 0.09, top)
    S.ellipse(x, y + 52, w / 2, w * 0.09, side)


# ------------------------------------------------------------------ campaigns
def social():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#fde4ec"), (1, "#f3d0e2")], 0, 0, 1, 1))
    for i, (x, y, r, c) in enumerate([(110, 120, 70, "#f7b6cc"), (690, 380, 90, "#e7c6f2"), (700, 90, 50, "#ffd9b8")]):
        S.circle(x, y, r, c, op=0.6)
    # phone
    S.rect(268, 26, 264, 470, "#2a2230", rx=40)
    S.rect(280, 40, 240, 444, "#fffaf6", rx=30)
    S.rect(362, 46, 76, 14, "#2a2230", rx=7)
    S.circle(310, 92, 16, S.lin([(0, "#f2a7b8"), (1, "#a98be0")]))
    S.rect(334, 84, 90, 8, "#3a2433", rx=4, op=0.7)
    S.rect(334, 98, 60, 6, "#b3a2a5", rx=3)
    S.rect(292, 118, 216, 236, S.lin([(0, "#ffe9f1"), (1, "#f7c4d6")]), rx=8)
    glow(S, 400, 236, 110, "#ffffff", 0.8)
    S.ellipse(400, 330, 70, 10, "#7b2742", op=0.12)
    slot("social", 340, 140, 120, 196)
    heart(S, 306, 376, 11, "#e0587a")
    S.circle(344, 376, 10, None, "#3a2433", 2.5)
    S.path("M376 368 L392 376 L376 384 Z", None, "#3a2433", 2.5)
    lines(S, 296, 404, 200, 3, "#d8c9cc", 16, 7)
    # floating reactions
    for x, y, s in [(560, 150, 20), (600, 230, 14), (210, 200, 17), (190, 300, 12), (620, 320, 11)]:
        S.circle(x, y, s * 1.7, "#ffffff", op=0.9)
        heart(S, x, y + 2, s * 0.7, "#e0587a")
    bubble(S, 545, 380, 150, 46, "#ffffff", -1)
    lines(S, 566, 397, 100, 2, "#d0b8c2", 12, 6)
    return S


def search():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#e6f0f7"), (1, "#dce4f2")], 0, 0, 1, 1))
    S.rect(70, 40, 660, 430, "#ffffff", rx=18)
    S.rect(70, 40, 660, 44, "#eef1f6", rx=18)
    S.rect(70, 66, 660, 18, "#eef1f6")
    for i, c in enumerate(["#f08a7a", "#f2c94a", "#8fc1a0"]):
        S.circle(100 + i * 22, 62, 7, c)
    S.rect(170, 110, 460, 52, "#f6f8fb", rx=26, stroke="#c9d6e6", sw=2)
    S.circle(202, 136, 11, None, "#6b7f99", 3)
    S.line(210, 144, 220, 154, "#6b7f99", 3.5)
    S.rect(232, 130, 150, 10, "#9aaabf", rx=5)
    # sponsored result card
    S.rect(110, 186, 580, 170, S.lin([(0, "#fff7ef"), (1, "#fde9ee")]), rx=16, stroke="#efc6c8", sw=2)
    S.rect(130, 204, 92, 22, "#f2c94a", rx=11, op=0.9)
    lines(S, 330, 220, 300, 3, "#3a2433", 22, 9)
    S.rect(330, 300, 130, 34, "#7b2742", rx=17)
    glow(S, 250, 280, 90, "#ffffff", 0.9)
    slot("search", 205, 214, 92, 134)
    # organic results
    for k in range(2):
        y = 380 + k * 40
        S.rect(110, y, 70, 26, "#eef1f6", rx=6)
        lines(S, 196, y + 6, 420, 2, "#c9d6e6", 14, 6)
    return S


def display():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#f1ecfa"), (1, "#e3daf4")], 0, 0, 1, 1))
    # laptop
    S.rect(110, 40, 580, 360, "#2a2230", rx=20)
    S.rect(126, 56, 548, 328, "#fbf8fd", rx=8)
    S.path("M60 410 L740 410 L700 446 L100 446 Z", "#d9d2e2")
    S.rect(60, 400, 680, 14, "#c9c0d4", rx=7)
    # site layout
    S.rect(140, 72, 520, 26, "#efe8f6", rx=6)
    for i in range(4):
        S.rect(160 + i * 70, 82, 50, 6, "#b9a8d0", rx=3)
    # banner ad
    S.rect(140, 112, 520, 170, S.lin([(0, "#7b2742"), (1, "#a8457a")], 0, 0, 1, 1), rx=10)
    for x, y, r in [(220, 150, 40), (600, 250, 60), (520, 130, 24)]:
        S.circle(x, y, r, "#ffffff", op=0.08)
    lines(S, 170, 160, 190, 2, "#f6dce6", 26, 12)
    S.rect(170, 222, 120, 32, "#f3dca0", rx=16)
    glow(S, 520, 200, 110, "#ffd9e6", 0.55)
    slot("display", 470, 118, 100, 160)
    for k in range(3):
        S.rect(140 + k * 178, 298, 164, 72, "#f4effa", rx=8)
        S.rect(152 + k * 178, 310, 50, 48, "#e3d6f0", rx=6)
        lines(S, 214 + k * 178, 318, 70, 2, "#c9b8dc", 14, 6)
    # cursor
    S.path("M560 300 L560 340 L570 330 L580 350 L588 346 L578 326 L592 326 Z", "#ffffff", "#2a2230", 2.5)
    SC_sparkle(S, 600, 300, 10, "#f2c94a")
    return S


def SC_sparkle(S, x, y, r, col):
    S.poly(star_pts(x, y, r, r * 0.3, 4), col)


def billboard():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#f6c7b8"), (0.55, "#e9b9d6"), (1, "#b9a8e0")]))
    glow(S, 640, 300, 160, "#ffe9c8", 0.6)
    rnd = random.Random(4)
    x = 0
    while x < W:
        w = rnd.uniform(50, 110)
        h = rnd.uniform(140, 300)
        S.rect(x, H - 60 - h, w, h + 60, rnd.choice(["#9a86c4", "#8f7bb8", "#a693cc"]), op=0.85)
        for wy in range(int(H - 50 - h), H - 80, 22):
            for wx in range(int(x + 10), int(x + w - 10), 18):
                if rnd.random() < 0.5:
                    S.rect(wx, wy, 8, 10, "#ffe9b0", op=0.8)
        x += w + 4
    S.rect(0, H - 50, W, 50, "#6f5f8a")
    # billboard
    S.rect(380, 300, 14, 160, "#4a3a50")
    S.rect(560, 300, 14, 160, "#4a3a50")
    S.rect(250, 70, 450, 240, "#3a2a40", rx=6)
    S.rect(262, 82, 426, 216, S.lin([(0, "#2a1a2a"), (1, "#7b2742")], 0, 0, 1, 1))
    glow(S, 560, 190, 120, "#ffd9a8", 0.45)
    lines(S, 292, 140, 170, 2, "#f3dca0", 30, 14)
    S.rect(292, 222, 110, 10, "#f3dca0", rx=5, op=0.6)
    slot("billboard", 510, 96, 100, 190)
    for k in range(4):
        lx = 290 + k * 120
        S.path("M%s L%s L%s Z" % (P(lx, 66), P(lx - 18, 50), P(lx + 18, 50)), "#4a3a50")
        S.path("M%s L%s L%s Z" % (P(lx, 70), P(lx - 60, 300), P(lx + 60, 300)), "#fff3cf", op=0.08)
    # street lamps and cars
    for lx in (120, 720):
        S.rect(lx - 3, 330, 6, 120, "#3a2a40")
        S.circle(lx, 326, 12, "#fff3cf")
        glow(S, lx, 326, 50, "#fff3cf", 0.5)
    for cx, col in [(160, "#e0587a"), (620, "#5a8bd6")]:
        S.rect(cx - 60, 430, 120, 30, col, rx=12)
        S.path("M%s L%s L%s L%s Z" % (P(cx - 36, 432), P(cx - 22, 410), P(cx + 26, 410), P(cx + 40, 432)), dark(col, 0.1))
        S.circle(cx - 34, 462, 11, "#2a2230")
        S.circle(cx + 34, 462, 11, "#2a2230")
    return S


def magazine():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#f5e9df"), (1, "#ecd9cb")]))
    # table texture
    for i in range(6):
        S.line(0, 80 + i * 80, W, 70 + i * 80, "#e2cbb9", 2, 0.6)
    S.ellipse(400, 452, 330, 22, "#5a3640", op=0.12)
    # open magazine
    S.path("M90 70 L400 92 L400 452 L90 430 Z", "#fffdf9")
    S.path("M400 92 L710 70 L710 430 L400 452 Z", "#fbf6f0")
    S.path("M392 92 L408 92 L408 452 L392 452 Z", S.lin([(0, "#e8dccf"), (0.5, "#cdbcab"), (1, "#e8dccf")], 0, 0, 1, 0))
    # left page: editorial
    S.rect(120, 110, 250, 160, S.lin([(0, "#f7d6dc"), (1, "#e7b8c6")]), rx=4)
    for x, y, r in [(170, 180, 34), (300, 150, 22)]:
        S.circle(x, y, r, "#ffffff", op=0.25)
    with S.g("translate(250 260) scale(0.55)"):
        M.rose(S, "#d6456a")
    lines(S, 120, 300, 250, 6, "#cdbfc4", 18, 7)
    # right page: the ad
    S.path("M418 106 L690 88 L690 412 L418 432 Z", S.lin([(0, "#3a2433"), (1, "#7b2742")], 0, 0, 1, 1))
    glow(S, 554, 240, 120, "#ffd9e6", 0.35)
    slot("magazine", 506, 128, 96, 210)
    S.rect(470, 370, 170, 10, "#f3dca0", rx=5, op=0.8)
    S.rect(500, 388, 110, 7, "#f3dca0", rx=3, op=0.5)
    # coffee & flowers
    S.circle(744, 400, 40, "#ffffff", "#e2d4c8", 3)
    S.circle(744, 400, 28, "#8a5a3a")
    S.circle(738, 394, 8, "#c79a74", op=0.6)
    with S.g("translate(52 420) scale(0.5) rotate(-15)"):
        M.jasmine(S)
    return S


def tv():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#f3ece4"), (1, "#eadfd2")]))
    S.rect(0, 380, W, 120, S.lin([(0, "#d9c3ad"), (1, "#c9ad94")]))
    # wall art & lamp
    S.rect(52, 70, 90, 120, "#d9b77a", rx=4)
    S.rect(58, 76, 78, 108, S.lin([(0, "#bcd8dc"), (1, "#f1d9c9")]))
    S.line(700, 140, 700, 360, "#8a6a4a", 4)
    S.path("M660 140 L740 140 L722 96 L678 96 Z", "#f3dca0")
    glow(S, 700, 150, 90, "#fff3d0", 0.5)
    SC.pot_plant(S, 90, 380, 0.9)
    # console & TV
    S.rect(170, 360, 460, 44, "#9a6a4a", rx=6)
    S.rect(180, 404, 12, 30, "#6a4a32")
    S.rect(608, 404, 12, 30, "#6a4a32")
    S.rect(186, 60, 428, 268, "#1f1a24", rx=12)
    S.rect(198, 72, 404, 244, S.lin([(0, "#f9d9e3"), (1, "#c9a8e8")], 0, 0, 1, 1))
    glow(S, 400, 190, 130, "#ffffff", 0.7)
    for k in range(5):
        a = -0.9 + k * 0.45
        S.path("M400 190 L%s L%s Z" % (P(400 + math.cos(a - 0.08) * 260, 190 + math.sin(a - 0.08) * 260), P(400 + math.cos(a + 0.08) * 260, 190 + math.sin(a + 0.08) * 260)), "#ffffff", op=0.12)
    podium(S, 400, 268, 130)
    slot("tv", 352, 106, 96, 162)
    S.rect(380, 328, 40, 32, "#2a2230")
    S.circle(588, 300, 4, "#e0587a")
    return S


def event():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#2a1a2e"), (1, "#4a2440")]))
    # curtains
    for side in (-1, 1):
        x0 = 0 if side < 0 else W
        for k in range(6):
            x = x0 - side * (k * 22)
            S.path("M%s L%s Q%s %s %s L%s Z" % (P(x, 0), P(x - side * 30, 0), P(x - side * 20, 220), P(x - side * 60, 440), P(x - side * 40, 440), P(x, 440)),
                   "#7b2742" if k % 2 == 0 else "#6a1f38")
    S.path("M0 0 L800 0 L800 46 Q600 80 400 50 Q200 80 0 46 Z", "#8a2a4a")
    # spotlight beams
    for bx, ex in [(140, 360), (660, 440), (400, 400)]:
        S.path("M%s L%s L%s Z" % (P(bx, 0), P(ex - 110, 420), P(ex + 110, 420)), "#fff3d0", op=0.13)
    glow(S, 400, 300, 170, "#ffe2b8", 0.45)
    # stage
    S.path("M90 400 L710 400 L760 460 L40 460 Z", "#3a2a3a")
    S.rect(40, 458, 720, 12, "#2a1e2a")
    podium(S, 400, 336, 160, "#fff6ec", "#efe0d4")
    slot("event", 348, 150, 104, 186)
    # crowd
    rnd = random.Random(8)
    for i in range(26):
        x = 10 + i * 31 + rnd.uniform(-6, 6)
        y = 470 + rnd.uniform(-6, 10)
        S.circle(x, y, 18, "#1a1220")
        S.rect(x - 24, y + 12, 48, 40, "#1a1220", rx=18)
    # confetti
    for i in range(46):
        x, y = rnd.uniform(60, 740), rnd.uniform(40, 380)
        S.rect(x, y, 8, 4, rnd.choice(["#f3dca0", "#f2a7b8", "#ffffff", "#c9a8e8"]), rx=1, op=0.85, tr="rotate(%d %s %s)" % (rnd.randint(0, 180), x, y))
    return S


def pr():
    S = new()
    S.rect(0, 0, W, H, "#f7f1ea")
    # step-and-repeat wall (abstract monograms, no text)
    for r in range(6):
        for c in range(9):
            x, y = 40 + c * 90 + (45 if r % 2 else 0), 40 + r * 70
            S.circle(x, y, 16, None, "#c9a55a", 2.5, op=0.5)
            S.path("M%s L%s L%s Z" % (P(x, y - 8), P(x - 7, y + 6), P(x + 7, y + 6)), "#7b2742", op=0.25)
    S.rect(0, 400, W, 100, S.lin([(0, "#8a2a4a"), (1, "#6a1f38")]))
    S.rect(0, 396, W, 8, "#c9a55a")
    glow(S, 400, 260, 170, "#ffffff", 0.75)
    podium(S, 400, 330, 140, "#ffffff", "#efe6de")
    slot("pr", 352, 140, 96, 190)
    # microphones
    for i, (x, a) in enumerate([(230, 30), (290, 18), (520, -18), (580, -30)]):
        with S.g("rotate(%d %s 420)" % (a, x)):
            S.rect(x - 4, 330, 8, 90, "#2a2230")
            S.rect(x - 14, 300, 28, 40, ["#e0587a", "#5a8bd6", "#2a2230", "#c9a55a"][i], rx=12)
            S.rect(x - 16, 340, 32, 16, "#f6efe6", rx=4)
    # camera flashes
    for x, y, r in [(110, 160, 26), (700, 120, 30), (660, 300, 18), (150, 330, 20)]:
        glow(S, x, y, r * 3, "#ffffff", 0.9)
        SC_sparkle(S, x, y, r, "#ffffff")
    return S


def sampling():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#fbefe6"), (1, "#f4e0d6")]))
    # mirror arch & shelves
    S.path("M520 420 L520 150 C520 50 760 50 760 150 L760 420 Z", "#e9d2bf")
    S.path("M536 420 L536 154 C536 72 744 72 744 154 L744 420 Z", S.lin([(0, "#f7fbfd"), (1, "#e6eef3")]))
    for k in range(3):
        S.rect(546, 200 + k * 70, 188, 6, "#d9b77a")
        for j in range(5):
            SC.mini_bottle(S, 568 + j * 36, 200 + k * 70, 0.42, SC.VIAL_COLS[(k * 5 + j) % 12], "#c9a55a", j % 3)
    # counter
    S.rect(40, 330, 720, 26, "#fffaf4", rx=6)
    S.rect(60, 356, 680, 120, S.lin([(0, "#7b2742"), (1, "#5e1d33")]))
    for k in range(4):
        S.rect(80 + k * 170, 372, 150, 88, "#6a2139", rx=8, stroke="#c9a55a", sw=1.5)
    # sample tray with vials
    S.rect(80, 300, 250, 34, "#efe2d4", rx=8)
    for j in range(9):
        SC.vial(S, 100 + j * 26, 312, 46, SC.VIAL_COLS[j % 12])
    # blotter strips in a cup
    S.rect(370, 256, 50, 76, "#ffffff", rx=6, stroke="#e2d4c8", sw=2)
    for k in range(5):
        S.line(380 + k * 8, 258, 372 + k * 12, 196 - (k % 2) * 14, "#ffffff", 7)
        S.line(380 + k * 8, 258, 372 + k * 12, 196 - (k % 2) * 14, "#e2d4c8", 1)
    glow(S, 470, 230, 110, "#ffffff", 0.7)
    slot("sampling", 430, 136, 84, 194)
    # gift bag
    S.path("M620 330 L700 330 L708 420 L612 420 Z", "#f2a7b8")
    S.path("M640 330 C640 300 680 300 680 330", None, "#c9a55a", 4)
    return S


# ------------------------------------------------------------------ retail channels
def ch_online():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#e9f2f6"), (1, "#dbe8ef")]))
    S.rect(160, 50, 480, 300, "#2a2230", rx=16)
    S.rect(174, 64, 452, 272, "#ffffff", rx=6)
    S.rect(174, 64, 452, 34, "#f1f4f8")
    for k in range(3):
        x = 196 + k * 144
        S.rect(x, 116, 126, 150, "#f8f3ee", rx=8)
        glow(S, x + 63, 180, 50, "#ffffff", 0.8)
        SC.mini_bottle(S, x + 63, 224, 0.9, SC.VIAL_COLS[k * 3 + 1], "#c9a55a", k)
        S.rect(x + 14, 276, 98, 22, "#7b2742", rx=11)
    S.path("M110 360 L690 360 L650 390 L150 390 Z", "#d2d8e0")
    # parcels
    for x, y, w, h, c in [(560, 330, 120, 90, "#d9b07a"), (640, 380, 110, 80, "#c9a06a"), (520, 400, 100, 70, "#e2bd8a")]:
        S.rect(x, y, w, h, c, rx=4)
        S.rect(x + w / 2 - 8, y, 16, h, "#f6e7c8", op=0.8)
    slot("ch_dtc", 0, 0, 0, 0)
    return S


def ch_store():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#dfeaf2"), (1, "#f4e6e6")]))
    S.rect(0, 420, W, 80, "#e6d8c8")
    S.rect(110, 90, 580, 340, "#fbf6ef")
    S.rect(110, 90, 580, 60, "#e0587a")
    SC.striped_awning(S, 110, 150, 580, 36, "#f2a7b8", "#ffffff", 12)
    for k in range(2):
        x = 150 + k * 300
        S.rect(x, 210, 200, 190, S.lin([(0, "#cfe3ec"), (1, "#f2e4dc")]), stroke="#ffffff", sw=8)
        for j in range(4):
            SC.mini_bottle(S, x + 34 + j * 44, 300, 0.6, SC.VIAL_COLS[(k * 4 + j) % 12], "#c9a55a", j % 3)
            SC.mini_bottle(S, x + 34 + j * 44, 380, 0.6, SC.VIAL_COLS[(k * 4 + j + 5) % 12], "#c9a55a", (j + 1) % 3)
    S.rect(360, 250, 80, 170, "#7b2742", rx=4)
    S.circle(424, 340, 5, "#f3dca0")
    SC.pot_plant(S, 70, 430, 0.8)
    SC.pot_plant(S, 740, 430, 0.8)
    return S


def ch_dept():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#f3e6dc"), (1, "#ead9cc")]))
    S.rect(0, 430, W, 70, "#e2d2c2")
    S.rect(80, 120, 640, 310, "#fbf6ef")
    S.path("M60 120 L740 120 L700 70 L100 70 Z", "#e9dccd")
    S.rect(60, 116, 680, 12, "#d9b77a")
    for k in range(7):
        x = 110 + k * 88
        S.rect(x, 150, 22, 280, S.lin([(0, "#ffffff"), (1, "#e6dccf")], 0, 0, 1, 0))
    for k in range(6):
        x = 140 + k * 88
        SC.window(S, x, 170, 50, 90, "#fbf6ef", arch=True)
        S.rect(x, 300, 50, 110, S.lin([(0, "#f7d6dc"), (1, "#e9c6a8")]))
        SC.mini_bottle(S, x + 25, 400, 0.55, SC.VIAL_COLS[k * 2 % 12], "#c9a55a", k % 3)
    S.rect(330, 300, 140, 130, "#7b2742")
    S.rect(340, 310, 56, 120, S.lin([(0, "#cfe3ec"), (1, "#f2e4dc")]))
    S.rect(404, 310, 56, 120, S.lin([(0, "#cfe3ec"), (1, "#f2e4dc")]))
    for fx in (220, 580):
        S.rect(fx - 2, 40, 4, 80, "#8a6a4a")
        S.path("M%s L%s L%s Z" % (P(fx + 2, 44), P(fx + 50, 58), P(fx + 2, 72)), "#7b2742")
    return S


def ch_drugstore():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#eef5f2"), (1, "#e2ece6")]))
    S.rect(0, 440, W, 60, "#d6e2dc")
    for k in range(4):
        y = 120 + k * 80
        S.rect(60, y, 680, 10, "#b9cbc2")
        for j in range(16):
            x = 80 + j * 41
            c = SC.VIAL_COLS[(j + k * 3) % 12]
            if (j + k) % 3 == 0:
                SC.mini_bottle(S, x + 10, y, 0.5, c, "#b8b8c0", j % 3)
            else:
                S.rect(x, y - 46, 26, 46, light(c, 0.2), rx=5)
                S.rect(x + 4, y - 30, 18, 12, "#ffffff", rx=2, op=0.8)
    S.rect(80, 30, 640, 50, "#4f9a7a", rx=10)
    S.rect(110, 46, 200, 18, "#ffffff", rx=9, op=0.8)
    # basket
    S.path("M560 420 L700 420 L690 480 L570 480 Z", "#e0587a")
    for k in range(4):
        S.line(580 + k * 30, 424, 584 + k * 28, 476, "#c0465f", 3)
    S.path("M570 420 C580 370 680 370 690 420", None, "#c0465f", 5)
    return S


def ch_truck():
    S = new()
    S.rect(0, 0, W, H, S.lin([(0, "#f6e4d6"), (1, "#f1d2c0")]))
    SC.sun(S, 640, 110, 34)
    S.rect(0, 380, W, 120, "#d9c4b2")
    S.rect(0, 420, W, 6, "#ffffff", op=0.6)
    # warehouse
    S.rect(40, 170, 300, 210, "#e9ddd0")
    S.path("M30 170 L190 100 L350 170 Z", "#c9a06a")
    for k in range(3):
        S.rect(70 + k * 90, 260, 70, 120, "#b9a48c")
        for j in range(5):
            S.line(70 + k * 90, 270 + j * 22, 140 + k * 90, 270 + j * 22, "#a08a72", 2)
    # truck
    S.rect(380, 230, 290, 150, "#ffffff", rx=8, stroke="#e2d4c8", sw=3)
    S.rect(400, 260, 140, 18, "#7b2742", rx=9)
    S.rect(400, 290, 90, 10, "#c9a55a", rx=5)
    S.path("M670 270 L740 270 L770 320 L770 380 L670 380 Z", "#7b2742")
    S.path("M684 282 L734 282 L756 320 L684 320 Z", "#cfe3ec")
    for x in (440, 610, 720):
        S.circle(x, 384, 26, "#2a2230")
        S.circle(x, 384, 10, "#c9c0d4")
    for x, y, w, h in [(300, 340, 60, 46), (250, 352, 50, 34)]:
        S.rect(x, y, w, h, "#d9b07a", rx=3)
        S.rect(x + w / 2 - 5, y, 10, h, "#f6e7c8", op=0.8)
    return S


# ------------------------------------------------------------------ award trophy
def trophy():
    S = SVG(400, 400, 256, 256)
    S.rect(0, 0, 400, 400, S.rad([(0, "#fff6e6"), (1, "#f3dcc4")], 0.5, 0.45, 0.7))
    for i in range(14):
        a = math.tau * i / 14
        S.path("M200 190 L%s L%s Z" % (P(200 + math.cos(a - 0.08) * 220, 190 + math.sin(a - 0.08) * 220), P(200 + math.cos(a + 0.08) * 220, 190 + math.sin(a + 0.08) * 220)), "#ffffff", op=0.25)
    # laurels
    for side in (-1, 1):
        for k in range(8):
            a = math.radians(110 + k * 14) if side < 0 else math.radians(70 - k * 14)
            x = 200 + math.cos(a) * 120
            y = 230 - math.sin(a) * 110 + 60
            S.path(leaf_d(x, y, 34, 9, a + (math.pi / 2 if side < 0 else -math.pi / 2) * 0.6), S.lin([(0, "#e8c66a"), (1, "#b5873b")]))
    # base
    S.rect(130, 320, 140, 40, S.lin([(0, "#3a2433"), (1, "#7b2742")], 0, 0, 1, 0), rx=6)
    S.rect(150, 296, 100, 30, S.lin([(0, "#4a2a3d"), (1, "#7b2742")], 0, 0, 1, 0), rx=4)
    S.rect(170, 334, 60, 12, "#e8c66a", rx=3)
    # golden flacon statuette
    gold = S.lin([(0, "#fff1b8"), (0.35, "#e8c66a"), (0.7, "#c9973a"), (1, "#8a5a1e")], 0, 0, 1, 0)
    S.path("M160 290 L240 290 L250 200 Q250 150 200 140 Q150 150 150 200 Z", gold)
    S.rect(184, 112, 32, 30, gold, rx=4)
    S.path("M170 112 L230 112 L220 62 L180 62 Z", gold)
    S.path("M168 200 Q170 160 196 152", None, "#fffbe6", 6, 0.7)
    S.circle(200, 222, 26, None, "#8a5a1e", 3, 0.6)
    S.poly(star_pts(200, 222, 16, 6, 5), "#fff1b8")
    for x, y, r in [(110, 110, 10), (300, 90, 8), (320, 230, 7), (80, 240, 6)]:
        SC_sparkle(S, x, y, r, "#e8c66a")
    return S


def build():
    for d in (OUT_C, OUT_CH, OUT_M):
        os.makedirs(d, exist_ok=True)
    n = 0
    for name, fn in [("social", social), ("search", search), ("display", display), ("billboard", billboard), ("magazine", magazine),
                     ("tv", tv), ("event", event), ("pr", pr), ("sampling", sampling)]:
        fn().save(os.path.join(OUT_C, name + ".svg"))
        n += 1
    for name, fn in [("online", ch_online), ("store", ch_store), ("dept", ch_dept), ("drugstore", ch_drugstore), ("distributor", ch_truck)]:
        fn().save(os.path.join(OUT_CH, name + ".svg"))
        n += 1
    trophy().save(os.path.join(OUT_M, "trophy.svg"))
    SLOTS.pop("ch_dtc", None)
    with open(os.path.join(OUT_C, "slots.json"), "w") as f:
        json.dump({"size": [W, H], "slots": SLOTS}, f)
    return n + 1


if __name__ == "__main__":
    print("marketing art:", build())
