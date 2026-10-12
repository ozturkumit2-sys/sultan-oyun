"""Original illustrated portraits for staff, perfumers, influencers and celebrities.
Writes assets/art/people/{std,lab,glam}_{f,m}_NN.svg (square, drawn for a circular crop)."""
import os, random, math
from lib import SVG, P, light, dark, mix, smooth_closed, smooth_open

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "art", "people")

SKINS = ["#f7dac6", "#efc4a3", "#dca27b", "#bd7f56", "#93603f", "#64402b"]
HAIR = ["#2b1d18", "#43291e", "#6e4127", "#9a6a3c", "#d6ad66", "#a9452e", "#8e8984", "#ece5da"]
EYES = ["#4a2f22", "#6b4a2a", "#3f6b4c", "#4b6f93", "#2a1d18"]
LIPS = ["#c45a6a", "#a8324a", "#d9786c", "#b26a72", "#8a3a4a", "#cf6f84"]
CLOTH = ["#7b2742", "#6d3f73", "#2f4a5a", "#4f6f4b", "#3a3438", "#a8604a", "#5a7a9a", "#c9798c", "#8a6a3a", "#e9d8c4"]
BGS = [("#f8e4e6", "#efc6cc"), ("#efe8f8", "#d8c9ee"), ("#e8f1e4", "#c9dcc0"), ("#f8efdc", "#ecd6a8"), ("#e4eff4", "#c3dbe6"), ("#fbeadf", "#f1c9b0")]
GLAM_BGS = [("#ffd9e6", "#f08bb0"), ("#e9dcff", "#a98be0"), ("#ffe9c7", "#f0b85a"), ("#d8f1ff", "#79b8e0"), ("#ffe0d6", "#ef8e7a"), ("#f3e0ff", "#c77fd9")]


def background(S, cols, glam=False, rnd=None):
    S.rect(0, 0, 400, 400, S.rad([(0, light(cols[0], 0.4)), (0.7, cols[0]), (1, cols[1])], 0.5, 0.4, 0.75))
    if glam:
        for i in range(9):
            x, y, r = rnd.uniform(20, 380), rnd.uniform(20, 300), rnd.uniform(10, 34)
            S.circle(x, y, r, S.rad([(0, "#ffffff", 0.55), (1, "#ffffff", 0)]))
        for i in range(6):
            x, y = rnd.uniform(30, 370), rnd.uniform(30, 260)
            sparkle(S, x, y, rnd.uniform(5, 10))
    else:
        # a soft arch behind the head, like a studio portrait backdrop
        S.path("M70 400 L70 190 C70 90 330 90 330 190 L330 400 Z", S.lin([(0, "#ffffff", 0.45), (1, "#ffffff", 0.05)]))


def sparkle(S, x, y, r, col="#ffffff"):
    k = r * 0.18
    S.path("M%s Q%s %s Q%s %s Q%s %s Q%s %s Z" % (
        P(x, y - r), P(x + k, y - k), P(x + r, y), P(x + k, y + k), P(x, y + r), P(x - k, y + k), P(x - r, y), P(x - k, y - k), P(x, y - r)), col, op=0.9)


class Face:
    def __init__(self, rnd, fem, skin, hair, eye, lip):
        self.rnd, self.fem, self.skin, self.hair, self.eye, self.lip = rnd, fem, skin, hair, eye, lip
        self.jaw = rnd.uniform(0.0, 1.0)
        self.cx, self.cy = 200, 178
        self.w = 60 if fem else 64
        self.h = 80


def face_path(f):
    cx, cy, w, h = f.cx, f.cy, f.w, f.h
    jw = w * (0.72 + 0.12 * f.jaw) if not f.fem else w * (0.62 + 0.08 * f.jaw)
    pts = [(cx, cy - h), (cx + w * 0.82, cy - h * 0.72), (cx + w, cy - h * 0.18), (cx + w * 0.96, cy + h * 0.28),
           (cx + jw, cy + h * 0.62), (cx + w * 0.3, cy + h * 0.95), (cx, cy + h), (cx - w * 0.3, cy + h * 0.95),
           (cx - jw, cy + h * 0.62), (cx - w * 0.96, cy + h * 0.28), (cx - w, cy - h * 0.18), (cx - w * 0.82, cy - h * 0.72)]
    return smooth_closed(pts, 0.17)


def body(S, f, outfit, cloth, cloth2, rnd):
    skin = f.skin
    # neck
    S.path("M%s L%s L%s L%s Z" % (P(176, 228), P(224, 228), P(230, 300), P(170, 300)), S.lin([(0, dark(skin, 0.18)), (0.45, skin), (1, skin)]))
    sh = "M24 400 C30 330 92 298 150 290 L250 290 C308 298 370 330 376 400 Z"
    if outfit == "offshoulder":
        S.path(sh, S.lin([(0, light(skin, 0.05)), (1, dark(skin, 0.06))]))
        S.path("M30 400 C40 352 90 336 140 340 C170 352 230 352 260 340 C310 336 360 352 370 400 Z", S.lin([(0, light(cloth, 0.15)), (1, dark(cloth, 0.15))]))
        for i in range(40):
            x, y = rnd.uniform(60, 340), rnd.uniform(352, 398)
            S.circle(x, y, rnd.uniform(1.5, 3.2), "#ffffff", op=rnd.uniform(0.3, 0.7))
        S.path("M120 344 C170 360 230 360 280 344", None, light(cloth, 0.4), 3, op=0.7)
        return
    if outfit == "vneck":
        S.path(sh, S.lin([(0, light(cloth, 0.12)), (1, dark(cloth, 0.12))]))
        S.path("M168 288 L200 350 L232 288 Z", S.lin([(0, dark(skin, 0.1)), (1, skin)]))
        S.path("M150 290 L200 356 L250 290", None, dark(cloth, 0.25), 3, op=0.6)
        return
    if outfit == "turtleneck":
        S.path(sh, S.lin([(0, light(cloth, 0.1)), (1, dark(cloth, 0.14))]))
        S.path("M168 262 C170 300 230 300 232 262 L236 300 C220 312 180 312 164 300 Z", S.lin([(0, light(cloth, 0.22)), (1, cloth)]))
        for i in range(5):
            y = 270 + i * 7
            S.path("M%s C%s %s %s" % (P(170, y), P(190, y + 5), P(210, y + 5), P(230, y)), None, dark(cloth, 0.2), 1.5, op=0.5)
        return
    if outfit in ("blazer", "labcoat"):
        coat = "#fbfaf7" if outfit == "labcoat" else cloth
        S.path(sh, S.lin([(0, light(coat, 0.08)), (1, dark(coat, 0.1 if outfit == "labcoat" else 0.16))]))
        # shirt / top in the opening
        S.path("M162 288 L200 372 L238 288 Z", cloth2)
        if not f.fem and outfit == "blazer" and rnd.random() < 0.55:
            tie = rnd.choice(["#7b2742", "#2f4a5a", "#c9a55a", "#6d3f73"])
            S.path("M194 300 L206 300 L212 360 L200 376 L188 360 Z", S.lin([(0, light(tie, 0.15)), (1, dark(tie, 0.15))]))
            S.path("M190 290 L210 290 L206 304 L194 304 Z", dark(tie, 0.1))
        # collar of the shirt
        S.path("M168 286 L200 312 L186 322 Z M232 286 L200 312 L214 322 Z", light(cloth2, 0.25) if cloth2 != "#ffffff" else "#ffffff", dark(cloth2, 0.2), 1.2)
        # lapels
        lap = dark(coat, 0.08 if outfit == "labcoat" else 0.18)
        S.path("M150 292 L192 380 L176 400 L120 400 C128 360 134 320 150 292 Z", lap)
        S.path("M250 292 L208 380 L224 400 L280 400 C272 360 266 320 250 292 Z", lap)
        S.path("M150 292 L192 380", None, dark(coat, 0.3), 1.5, op=0.5)
        S.path("M250 292 L208 380", None, dark(coat, 0.3), 1.5, op=0.5)
        if outfit == "labcoat":
            S.rect(268, 360, 46, 40, "#f1efe9", rx=4, stroke="#d8d4cc", sw=1.5)
            S.rect(282, 346, 6, 26, "#4b6f93", rx=2)
            S.rect(292, 350, 6, 22, "#c45a6a", rx=2)
        return
    S.path(sh, S.lin([(0, light(cloth, 0.1)), (1, dark(cloth, 0.12))]))


def hair_back(S, f, style):
    c = f.hair
    g = S.lin([(0, light(c, 0.12)), (1, dark(c, 0.15))])
    if style == "long":
        S.path("M122 160 C110 70 290 70 278 160 C292 230 300 300 296 340 C260 356 140 356 104 340 C100 300 108 230 122 160 Z", g)
    elif style == "wavy":
        pts = [(122, 150), (200, 82), (278, 150), (290, 210), (304, 250), (292, 290), (306, 330), (270, 352), (200, 340), (130, 352), (94, 330), (108, 290), (96, 250), (110, 210)]
        S.path(smooth_closed(pts, 0.2), g)
    elif style == "bob":
        S.path("M124 170 C108 80 292 80 276 170 C284 210 284 240 270 262 C240 270 160 270 130 262 C116 240 116 210 124 170 Z", g)
    elif style == "curly":
        rnd = random.Random(int(f.cx * 7 + f.jaw * 1000))
        for i in range(26):
            a = math.tau * i / 26
            rx, ry = 92, 96
            x, y = 200 + math.cos(a) * rx, 168 + math.sin(a) * ry * (0.9 if math.sin(a) > 0 else 1.0)
            if y > 250:
                continue
            S.circle(x, y, rnd.uniform(26, 36), S.rad([(0, light(c, 0.15)), (1, dark(c, 0.1))], 0.4, 0.35, 0.7))
        S.circle(200, 150, 88, g)
    elif style == "ponytail":
        S.path("M262 150 C320 170 322 260 296 300 C284 270 286 220 262 190 Z", g)
    elif style == "scarf":
        pass
    elif style == "masc_long":
        S.path("M128 160 C114 76 286 76 272 160 C282 200 284 240 274 266 C250 270 150 270 126 266 C116 240 118 200 128 160 Z", g)


def hair_front(S, f, style, rnd):
    c = f.hair
    g = S.lin([(0, light(c, 0.18)), (1, dark(c, 0.1))])
    hl = light(c, 0.35)
    if style in ("long", "wavy"):
        S.path("M138 150 C140 92 262 84 268 150 C252 118 214 108 186 120 C168 128 152 140 138 150 Z", g)
        S.path("M136 152 C132 190 128 230 126 270 C118 230 116 180 136 152 Z", g)
        S.path("M264 150 C270 190 272 230 274 270 C282 230 284 180 264 150 Z", g)
        S.path("M170 104 C200 96 236 104 252 122", None, hl, 4, op=0.5)
    elif style == "bob":
        S.path("M136 160 C132 96 268 92 266 162 C246 132 230 128 206 126 L196 152 L186 126 C164 128 150 140 136 160 Z", g)
        S.path("M164 106 C190 98 226 100 246 116", None, hl, 4, op=0.5)
    elif style == "bun":
        S.circle(200, 86, 32, g)
        S.path("M140 160 C134 92 266 92 262 160 C244 120 160 118 140 160 Z", g)
        S.path("M176 76 C190 68 212 68 222 78", None, hl, 4, op=0.5)
    elif style == "curly":
        rnd2 = random.Random(int(f.jaw * 999) + 3)
        for i in range(11):
            x = 140 + i * 12
            S.circle(x, 112 + rnd2.uniform(-6, 6) + abs(x - 200) * 0.18, rnd2.uniform(14, 20), S.rad([(0, light(c, 0.2)), (1, c)], 0.4, 0.35, 0.7))
    elif style == "ponytail":
        S.path("M138 160 C132 92 268 90 264 160 C250 124 216 116 190 118 C164 122 148 138 138 160 Z", g)
        S.circle(262, 152, 8, dark(c, 0.2))
        S.path("M166 108 C194 98 230 102 250 118", None, hl, 4, op=0.5)
    elif style == "scarf":
        sc = f.scarf
        S.path("M118 180 C110 70 290 70 282 180 C290 240 300 290 330 330 C300 360 100 360 70 330 C100 290 110 240 118 180 Z", S.lin([(0, light(sc, 0.12)), (1, dark(sc, 0.12))]))
        S.path(face_path(f), "none")
    elif style == "crop":
        S.path("M134 176 C118 92 282 86 266 176 C262 150 256 136 246 130 C224 122 206 128 200 128 C190 122 168 120 154 130 C144 138 138 152 134 176 Z", g)
        S.path("M150 120 C176 96 226 96 250 120", None, light(c, 0.3), 4, op=0.4)
    elif style == "sidepart":
        S.path("M134 176 C118 84 282 80 266 172 C262 146 256 132 240 124 C222 116 196 116 172 126 C154 134 142 150 134 176 Z", g)
        S.path("M150 120 C176 92 236 92 256 126 C228 108 190 108 150 120 Z", light(c, 0.1))
        S.path("M176 102 C206 94 236 100 252 116", None, hl, 4, op=0.5)
    elif style == "slick":
        S.path("M138 160 C130 86 270 84 262 160 C252 126 226 112 200 112 C174 112 148 126 138 160 Z", g)
        for k in range(4):
            S.path("M%s C%s %s %s" % (P(160 + k * 14, 116), P(176 + k * 14, 100), P(206 + k * 10, 98), P(232 + k * 6, 110)), None, hl, 2, op=0.35)
    elif style == "curlyshort":
        rnd2 = random.Random(int(f.jaw * 777) + 5)
        for i in range(16):
            a = math.pi + math.pi * i / 15
            S.circle(200 + math.cos(a) * 62, 150 + math.sin(a) * 50, rnd2.uniform(15, 20), S.rad([(0, light(c, 0.15)), (1, c)], 0.4, 0.35, 0.7))
    elif style == "masc_long":
        S.path("M136 166 C130 92 270 90 264 166 C250 128 222 116 200 116 C176 116 150 128 136 166 Z", g)
        S.path("M170 108 C196 100 230 104 248 120", None, hl, 4, op=0.5)
    elif style == "bald":
        S.path("M146 120 C170 100 230 100 254 120", None, light(f.skin, 0.4), 6, op=0.5)


def features(S, f, rnd, glam=False, glasses=None, beard=None):
    cx, cy = f.cx, f.cy
    skin = f.skin
    ink = "#2a1c1c"
    # ears
    for sx in (-1, 1):
        S.ellipse(cx + sx * (f.w - 2), cy + 6, 11, 19, dark(skin, 0.08))
        S.ellipse(cx + sx * (f.w - 2), cy + 6, 5, 11, dark(skin, 0.18), op=0.5)
    S.path(face_path(f), S.rad([(0, light(skin, 0.1)), (0.75, skin), (1, dark(skin, 0.1))], 0.45, 0.4, 0.75))
    # under-chin shadow
    S.path("M%s C%s %s %s" % (P(cx - 40, cy + 68), P(cx - 20, cy + 92), P(cx + 20, cy + 92), P(cx + 40, cy + 68)), None, dark(skin, 0.15), 3, op=0.25)
    # cheeks
    S.circle(cx - 34, cy + 30, 16, S.rad([(0, "#ff7a8a", 0.28 if f.fem else 0.12), (1, "#ff7a8a", 0)]))
    S.circle(cx + 34, cy + 30, 16, S.rad([(0, "#ff7a8a", 0.28 if f.fem else 0.12), (1, "#ff7a8a", 0)]))
    # eyes
    ey = cy + 4
    for sx in (-1, 1):
        ex = cx + sx * 26
        S.path("M%s C%s %s %s C%s %s %s Z" % (P(ex - 13, ey), P(ex - 6, ey - 9), P(ex + 6, ey - 9), P(ex + 13, ey),
                                               P(ex + 6, ey + 6), P(ex - 6, ey + 6), P(ex - 13, ey)), "#fffdf9")
        S.circle(ex + sx * 0.5, ey - 1, 6.6, S.rad([(0, light(f.eye, 0.25)), (1, f.eye)]))
        S.circle(ex + sx * 0.5, ey - 1, 3.2, "#1a1212")
        S.circle(ex + sx * 0.5 + 2.2, ey - 3.4, 1.8, "#ffffff")
        S.path("M%s C%s %s %s" % (P(ex - 14, ey + 1), P(ex - 6, ey - 11), P(ex + 6, ey - 11), P(ex + 14, ey + 1)), None, ink, 3.2 if f.fem else 2.6)
        if f.fem:
            S.path("M%s L%s" % (P(ex + sx * 13, ey - 1), P(ex + sx * 19, ey - 6)), None, ink, 2.6)
        # brows
        bc = dark(f.hair, 0.25) if f.hair not in ("#ece5da", "#8e8984") else "#6b5a52"
        bw = 5.6 if not f.fem else 3.6
        S.path("M%s C%s %s %s" % (P(ex - 15, ey - 16 + (2 if sx < 0 else 2)), P(ex - 6, ey - 24), P(ex + 6, ey - 24), P(ex + 15, ey - 17)), None, bc, bw)
    # nose
    S.path("M%s C%s %s %s C%s %s %s" % (P(cx - 2, ey + 6), P(cx - 4, ey + 20), P(cx - 10, ey + 28), P(cx - 6, ey + 32), P(cx - 2, ey + 35), P(cx + 4, ey + 34), P(cx + 8, ey + 31)), None, dark(skin, 0.28), 2.4)
    # mouth
    my = cy + 50
    if f.fem:
        lip = f.lip
        S.path("M%s C%s %s %s C%s %s %s C%s %s %s C%s %s %s Z" % (P(cx - 17, my), P(cx - 10, my - 7), P(cx - 4, my - 6), P(cx, my - 3),
                                                                 P(cx + 4, my - 6), P(cx + 10, my - 7), P(cx + 17, my),
                                                                 P(cx + 8, my + 10), P(cx - 8, my + 10), P(cx - 17, my),
                                                                 P(cx - 17, my), P(cx - 17, my), P(cx - 17, my)), S.lin([(0, light(lip, 0.1)), (1, dark(lip, 0.15))]))
        S.path("M%s C%s %s %s" % (P(cx - 16, my), P(cx - 6, my + 2), P(cx + 6, my + 2), P(cx + 16, my)), None, dark(lip, 0.35), 1.6)
        S.ellipse(cx + 4, my + 5, 5, 2, "#ffffff", op=0.35)
    else:
        S.path("M%s C%s %s %s" % (P(cx - 14, my), P(cx - 5, my + 6), P(cx + 5, my + 6), P(cx + 14, my)), None, dark(skin, 0.4), 2.8)
        S.path("M%s C%s %s %s" % (P(cx - 8, my + 7), P(cx - 3, my + 9), P(cx + 3, my + 9), P(cx + 8, my + 7)), None, dark(skin, 0.2), 2, op=0.6)
    if beard == "stubble":
        S.path("M%s C%s %s %s C%s %s %s C%s %s %s Z" % (P(cx - 52, cy + 30), P(cx - 46, cy + 80), P(cx - 20, cy + 92), P(cx, cy + 92),
                                                      P(cx + 20, cy + 92), P(cx + 46, cy + 80), P(cx + 52, cy + 30), P(cx + 10, cy + 60), P(cx - 10, cy + 60), P(cx - 52, cy + 30)), f.hair, op=0.18)
    elif beard == "full":
        S.path("M%s C%s %s %s C%s %s %s C%s %s %s C%s %s %s Z" % (P(cx - 58, cy + 18), P(cx - 56, cy + 80), P(cx - 26, cy + 100), P(cx, cy + 102),
                                                                 P(cx + 26, cy + 100), P(cx + 56, cy + 80), P(cx + 58, cy + 18),
                                                                 P(cx + 34, cy + 52), P(cx - 34, cy + 52), P(cx - 58, cy + 18),
                                                                 P(cx - 58, cy + 18), P(cx - 58, cy + 18), P(cx - 58, cy + 18)), S.lin([(0, light(f.hair, 0.1)), (1, dark(f.hair, 0.1))]))
        S.path("M%s C%s %s %s C%s %s %s" % (P(cx - 16, my + 2), P(cx - 6, my + 8), P(cx + 6, my + 8), P(cx + 16, my + 2), P(cx + 6, my - 2), P(cx - 6, my - 2), P(cx - 16, my + 2)), dark(f.skin, 0.35))
        S.path("M%s C%s %s %s C%s %s %s Z" % (P(cx - 24, my - 6), P(cx - 10, my - 14), P(cx + 10, my - 14), P(cx + 24, my - 6), P(cx + 8, my - 4), P(cx - 8, my - 4), P(cx - 24, my - 6)), f.hair)
    elif beard == "mustache":
        S.path("M%s C%s %s %s C%s %s %s Z" % (P(cx - 22, my - 3), P(cx - 10, my - 14), P(cx + 10, my - 14), P(cx + 22, my - 3), P(cx + 8, my - 5), P(cx - 8, my - 5), P(cx - 22, my - 3)), f.hair)
    if glasses == "round":
        for sx in (-1, 1):
            S.circle(cx + sx * 26, ey, 17, "#ffffff", "#3a2a2a", 3, op=0.9)
            S.circle(cx + sx * 26, ey, 17, "#ffffff", op=0.12)
        S.path("M%s C%s %s %s" % (P(cx - 9, ey - 2), P(cx - 4, ey - 6), P(cx + 4, ey - 6), P(cx + 9, ey - 2)), None, "#3a2a2a", 3)
    elif glasses == "square":
        for sx in (-1, 1):
            S.rect(cx + sx * 26 - 18, ey - 13, 36, 26, "#ffffff", rx=7, stroke="#2a2030", sw=3.5, op=0.9)
            S.rect(cx + sx * 26 - 18, ey - 13, 36, 26, "#ffffff", rx=7, op=0.1)
        S.line(cx - 8, ey - 2, cx + 8, ey - 2, "#2a2030", 3)
    elif glasses == "sun":
        for sx in (-1, 1):
            S.path("M%s C%s %s %s C%s %s %s C%s %s %s Z" % (P(cx + sx * 6, ey - 12), P(cx + sx * 26, ey - 16), P(cx + sx * 44, ey - 14), P(cx + sx * 44, ey - 4),
                                                         P(cx + sx * 42, ey + 14), P(cx + sx * 18, ey + 16), P(cx + sx * 8, ey + 4),
                                                         P(cx + sx * 6, ey - 4), P(cx + sx * 6, ey - 8), P(cx + sx * 6, ey - 12)),
                   S.lin([(0, "#3a2433"), (1, "#7b2742")]), "#c9a55a", 2)
            S.path("M%s L%s" % (P(cx + sx * 16, ey - 8), P(cx + sx * 34, ey - 10)), None, "#ffffff", 3, op=0.35)
        S.line(cx - 7, ey - 8, cx + 7, ey - 8, "#c9a55a", 3)


def earrings(S, f, kind, col="#e2c071"):
    for sx in (-1, 1):
        x, y = f.cx + sx * (f.w - 2), f.cy + 26
        if kind == "pearl":
            S.circle(x, y, 5.5, S.rad([(0, "#ffffff"), (1, "#e8e0d8")], 0.35, 0.35, 0.7))
        elif kind == "hoop":
            S.circle(x, y + 10, 11, None, col, 3)
        elif kind == "drop":
            S.line(x, y - 2, x, y + 12, col, 2)
            S.path("M%s C%s %s %s C%s %s %s Z" % (P(x, y + 10), P(x + 8, y + 20), P(x + 6, y + 30), P(x, y + 32), P(x - 6, y + 30), P(x - 8, y + 20), P(x, y + 10)), S.lin([(0, "#f6e7a8"), (1, col)]))


def necklace(S, kind):
    if kind == "pearls":
        for i in range(15):
            a = math.pi * (0.15 + 0.7 * i / 14)
            S.circle(200 - math.cos(a) * 46, 292 + math.sin(a) * 34, 4.4, S.rad([(0, "#ffffff"), (1, "#e2dad2")], 0.35, 0.35, 0.7))
    elif kind == "pendant":
        S.path("M156 290 C176 330 224 330 244 290", None, "#d6b25e", 2)
        S.path("M200 326 L208 336 L200 348 L192 336 Z", "#c9798c", "#d6b25e", 1.5)


def portrait(kind, fem, i):
    rnd = random.Random((1 if fem else 2) * 1000 + i * 37 + {"std": 0, "lab": 500, "glam": 900}[kind])
    S = SVG(400, 400, 256, 256)
    glam = kind == "glam"
    bgs = GLAM_BGS if glam else BGS
    background(S, bgs[i % len(bgs)], glam, rnd)
    skin = SKINS[(i * 5 + (0 if fem else 2)) % len(SKINS)]
    hair_pool = HAIR[:7] if i % 9 != 4 else HAIR
    hair = hair_pool[(i * 3 + (1 if fem else 0)) % len(hair_pool)]
    if not fem and i % 11 == 7:
        hair = "#8e8984"
    f = Face(rnd, fem, skin, hair, EYES[i % len(EYES)], LIPS[(i * 2) % len(LIPS)])
    f.scarf = rnd.choice(["#7b2742", "#6d3f73", "#2f4a5a", "#c9798c", "#4f6f4b", "#a8604a"])
    if fem:
        style = ["long", "bob", "bun", "curly", "wavy", "ponytail", "long", "scarf", "bob", "wavy", "curly", "bun"][i % 12]
    else:
        style = ["crop", "sidepart", "curlyshort", "slick", "bald", "crop", "masc_long", "sidepart", "curlyshort", "slick"][i % 10]
    if style == "curly" and skin in SKINS[:2]:
        style = "wavy"
    cloth = CLOTH[(i * 7 + (3 if fem else 0)) % len(CLOTH)]
    cloth2 = rnd.choice(["#ffffff", "#f3e6e0", "#e6eef4", "#f6efe0"])
    if kind == "lab":
        outfit = "labcoat"
        cloth2 = rnd.choice(["#c9798c", "#6d3f73", "#5a7a9a", "#4f6f4b", "#e9d8c4"])
    elif glam:
        outfit = "offshoulder" if fem and i % 3 != 2 else ("vneck" if fem else rnd.choice(["blazer", "turtleneck"]))
        cloth = rnd.choice(["#7b2742", "#1f1a24", "#6d3f73", "#c9a55a", "#c9798c", "#2f4a5a"])
        cloth2 = "#1f1a24" if cloth != "#1f1a24" else "#f6efe0"
    else:
        outfit = ["blazer", "vneck", "turtleneck", "blazer"][i % 4] if fem else ["blazer", "turtleneck", "blazer", "vneck"][i % 4]
    hair_back(S, f, style)
    body(S, f, outfit, cloth, cloth2, rnd)
    beard = None
    if not fem:
        beard = [None, "stubble", None, "full", None, "mustache", "stubble", None][i % 8]
        if style == "bald" and beard is None:
            beard = "full"
    glasses = None
    if not glam and i % 5 == 3:
        glasses = "round" if i % 2 else "square"
    if glam and i % 3 == 1:
        glasses = "sun"
    features(S, f, rnd, glam, glasses, beard)
    if style != "scarf":
        hair_front(S, f, style, rnd)
    else:
        hair_front(S, f, style, rnd)
        features(S, f, rnd, glam, glasses, beard)
    if fem and style != "scarf":
        earrings(S, f, ["pearl", "hoop", "drop", None][i % 4] if not glam else ["drop", "hoop", "drop"][i % 3])
    if fem and outfit in ("vneck", "offshoulder"):
        necklace(S, "pearls" if i % 2 == 0 else "pendant")
    if glam:
        # warm rim light
        S.rect(0, 0, 400, 400, S.lin([(0, "#ffffff", 0.0), (0.7, "#ffffff", 0.0), (1, "#ffd9a8", 0.18)], 0, 0, 1, 0))
    return S


def crop(S):
    """Frame head and shoulders tighter so small avatars read well."""
    txt = S.render().replace('viewBox="0 0 400 400"', 'viewBox="56 44 288 288"')
    return txt


def build():
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for kind, count in [("std", 18), ("lab", 10), ("glam", 10)]:
        for fem in (True, False):
            for i in range(count):
                S = portrait(kind, fem, i)
                with open(os.path.join(OUT, "%s_%s_%02d.svg" % (kind, "f" if fem else "m", i)), "w") as fh:
                    fh.write(crop(S))
                n += 1
    return n


if __name__ == "__main__":
    print("portraits:", build())
