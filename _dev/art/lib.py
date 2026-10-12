"""Tiny SVG authoring helpers for the game's original vector artwork.
Everything here is plain SVG 1.1 that Godot's ThorVG importer renders (gradients, paths, clip paths,
opacity, transforms) — no filters, no text."""
import math


def fmt(v):
    return ("%.2f" % v).rstrip("0").rstrip(".") if isinstance(v, float) else str(v)


class SVG:
    def __init__(self, w, h, out_w=None, out_h=None):
        self.w, self.h = w, h
        self.out_w = out_w or w
        self.out_h = out_h or h
        self.defs = []
        self.body = []
        self.n = 0
        self.stack = []

    # ------------------------------------------------------------ defs
    def _id(self, p="g"):
        self.n += 1
        return "%s%d" % (p, self.n)

    def lin(self, stops, x1=0, y1=0, x2=0, y2=1, units=None):
        i = self._id("l")
        u = ' gradientUnits="userSpaceOnUse"' if units == "user" else ""
        s = "".join('<stop offset="%s" stop-color="%s" stop-opacity="%s"/>' % (fmt(o), c, fmt(a)) for o, c, a in _stops(stops))
        self.defs.append('<linearGradient id="%s" x1="%s" y1="%s" x2="%s" y2="%s"%s>%s</linearGradient>' % (i, fmt(x1), fmt(y1), fmt(x2), fmt(y2), u, s))
        return "url(#%s)" % i

    def rad(self, stops, cx=0.5, cy=0.5, r=0.5, fx=None, fy=None, units=None):
        i = self._id("r")
        u = ' gradientUnits="userSpaceOnUse"' if units == "user" else ""
        f = ""
        if fx is not None:
            f = ' fx="%s" fy="%s"' % (fmt(fx), fmt(fy))
        s = "".join('<stop offset="%s" stop-color="%s" stop-opacity="%s"/>' % (fmt(o), c, fmt(a)) for o, c, a in _stops(stops))
        self.defs.append('<radialGradient id="%s" cx="%s" cy="%s" r="%s"%s%s>%s</radialGradient>' % (i, fmt(cx), fmt(cy), fmt(r), f, u, s))
        return "url(#%s)" % i

    def clip_rrect(self, x, y, w, h, r):
        i = self._id("c")
        self.defs.append('<clipPath id="%s"><rect x="%s" y="%s" width="%s" height="%s" rx="%s"/></clipPath>' % (i, fmt(x), fmt(y), fmt(w), fmt(h), fmt(r)))
        return "url(#%s)" % i

    def clip_path(self, d):
        i = self._id("c")
        self.defs.append('<clipPath id="%s"><path d="%s"/></clipPath>' % (i, d))
        return "url(#%s)" % i

    # ------------------------------------------------------------ groups
    def g(self, transform="", clip=None, opacity=None):
        a = ""
        if transform:
            a += ' transform="%s"' % transform
        if clip:
            a += ' clip-path="%s"' % clip
        if opacity is not None:
            a += ' opacity="%s"' % fmt(opacity)
        self.body.append("<g%s>" % a)
        return _Group(self)

    # ------------------------------------------------------------ shapes
    def _style(self, fill, stroke=None, sw=None, op=None, extra=""):
        s = ' fill="%s"' % (fill if fill else "none")
        if stroke:
            s += ' stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"' % (stroke, fmt(sw or 1))
        if op is not None:
            s += ' opacity="%s"' % fmt(op)
        return s + extra

    def rect(self, x, y, w, h, fill, rx=0, stroke=None, sw=None, op=None, tr=""):
        t = ' transform="%s"' % tr if tr else ""
        self.body.append('<rect x="%s" y="%s" width="%s" height="%s" rx="%s"%s%s/>' % (fmt(x), fmt(y), fmt(w), fmt(h), fmt(rx), self._style(fill, stroke, sw, op), t))

    def circle(self, cx, cy, r, fill, stroke=None, sw=None, op=None):
        self.body.append('<circle cx="%s" cy="%s" r="%s"%s/>' % (fmt(cx), fmt(cy), fmt(r), self._style(fill, stroke, sw, op)))

    def ellipse(self, cx, cy, rx, ry, fill, stroke=None, sw=None, op=None, rot=0):
        t = ' transform="rotate(%s %s %s)"' % (fmt(rot), fmt(cx), fmt(cy)) if rot else ""
        self.body.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s"%s%s/>' % (fmt(cx), fmt(cy), fmt(rx), fmt(ry), self._style(fill, stroke, sw, op), t))

    def path(self, d, fill, stroke=None, sw=None, op=None, tr="", dash=None):
        t = ' transform="%s"' % tr if tr else ""
        e = ' stroke-dasharray="%s"' % dash if dash else ""
        self.body.append('<path d="%s"%s%s/>' % (d, self._style(fill, stroke, sw, op, e), t))

    def poly(self, pts, fill, stroke=None, sw=None, op=None):
        self.body.append('<polygon points="%s"%s/>' % (" ".join("%s,%s" % (fmt(x), fmt(y)) for x, y in pts), self._style(fill, stroke, sw, op)))

    def line(self, x1, y1, x2, y2, stroke, sw=1, op=None, dash=None):
        e = ' stroke-dasharray="%s"' % dash if dash else ""
        o = ' opacity="%s"' % fmt(op) if op is not None else ""
        self.body.append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"%s%s/>' % (fmt(x1), fmt(y1), fmt(x2), fmt(y2), stroke, fmt(sw), o, e))

    def polyline(self, pts, stroke, sw=1, op=None, fill=None):
        o = ' opacity="%s"' % fmt(op) if op is not None else ""
        self.body.append('<polyline points="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"%s/>' % (" ".join("%s,%s" % (fmt(x), fmt(y)) for x, y in pts), fill or "none", stroke, fmt(sw), o))

    def raw(self, s):
        self.body.append(s)

    def text(self):
        raise RuntimeError("no text in game art")

    def render(self):
        return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %s %s">' % (self.out_w, self.out_h, fmt(self.w), fmt(self.h))
                + "<defs>" + "".join(self.defs) + "</defs>" + "".join(self.body) + "</svg>")

    def save(self, path):
        with open(path, "w") as f:
            f.write(self.render())


class _Group:
    def __init__(self, s):
        self.s = s

    def __enter__(self):
        return self.s

    def __exit__(self, *a):
        self.s.body.append("</g>")


def _stops(stops):
    out = []
    for st in stops:
        if len(st) == 2:
            out.append((st[0], st[1], 1))
        else:
            out.append(st)
    return out


# ---------------------------------------------------------------- colour helpers
def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def rgb2hex(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(round(v * 255)))) for v in c)


def mix(a, b, t):
    ca, cb = hex2rgb(a), hex2rgb(b)
    return rgb2hex(tuple(ca[i] + (cb[i] - ca[i]) * t for i in range(3)))


def light(c, t):
    return mix(c, "#ffffff", t)


def dark(c, t):
    return mix(c, "#000000", t)


# ---------------------------------------------------------------- geometry helpers
def P(x, y):
    return "%s %s" % (fmt(float(x)), fmt(float(y)))


def rot(px, py, cx, cy, a):
    ca, sa = math.cos(a), math.sin(a)
    dx, dy = px - cx, py - cy
    return cx + dx * ca - dy * sa, cy + dx * sa + dy * ca


def leaf_d(x, y, length, width, ang, curve=0.0):
    """Pointed leaf from base (x,y) along angle ang (radians)."""
    tip = (x + math.cos(ang) * length, y + math.sin(ang) * length)
    nx, ny = -math.sin(ang), math.cos(ang)
    mx, my = x + math.cos(ang) * length * 0.45, y + math.sin(ang) * length * 0.45
    c1 = (mx + nx * width + math.cos(ang) * length * curve, my + ny * width)
    c2 = (mx - nx * width, my - ny * width + math.sin(ang) * length * curve)
    return "M%s Q%s %s Q%s %s Z" % (P(x, y), P(*c1), P(*tip), P(*c2), P(x, y))


def blob_d(cx, cy, r, n=9, jitter=0.18, seed=1, sx=1.0, sy=1.0):
    import random
    rnd = random.Random(seed)
    pts = []
    for i in range(n):
        a = math.tau * i / n
        rr = r * (1 + rnd.uniform(-jitter, jitter))
        pts.append((cx + math.cos(a) * rr * sx, cy + math.sin(a) * rr * sy))
    return smooth_closed(pts)


def smooth_closed(pts, k=0.18):
    """Catmull-Rom style closed smooth path through points."""
    n = len(pts)
    d = "M%s " % P(*pts[0])
    for i in range(n):
        p0 = pts[(i - 1) % n]
        p1 = pts[i]
        p2 = pts[(i + 1) % n]
        p3 = pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) * k * 1.0, p1[1] + (p2[1] - p0[1]) * k)
        c2 = (p2[0] - (p3[0] - p1[0]) * k, p2[1] - (p3[1] - p1[1]) * k)
        d += "C%s %s %s " % (P(*c1), P(*c2), P(*p2))
    return d + "Z"


def smooth_open(pts, k=0.18):
    n = len(pts)
    d = "M%s " % P(*pts[0])
    for i in range(n - 1):
        p0 = pts[max(0, i - 1)]
        p1 = pts[i]
        p2 = pts[i + 1]
        p3 = pts[min(n - 1, i + 2)]
        c1 = (p1[0] + (p2[0] - p0[0]) * k, p1[1] + (p2[1] - p0[1]) * k)
        c2 = (p2[0] - (p3[0] - p1[0]) * k, p2[1] - (p3[1] - p1[1]) * k)
        d += "C%s %s %s " % (P(*c1), P(*c2), P(*p2))
    return d


def star_pts(cx, cy, r1, r2, n, a0=-math.pi / 2):
    pts = []
    for i in range(n * 2):
        r = r1 if i % 2 == 0 else r2
        a = a0 + math.pi * i / n
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def petal_d(cx, cy, length, width, ang, roundness=0.55):
    """Rounded petal from centre outward."""
    tip = (cx + math.cos(ang) * length, cy + math.sin(ang) * length)
    nx, ny = -math.sin(ang), math.cos(ang)
    a1 = (cx + math.cos(ang) * length * 0.35 + nx * width, cy + math.sin(ang) * length * 0.35 + ny * width)
    a2 = (cx + math.cos(ang) * length * 0.35 - nx * width, cy + math.sin(ang) * length * 0.35 - ny * width)
    t1 = (tip[0] + nx * width * roundness, tip[1] + ny * width * roundness)
    t2 = (tip[0] - nx * width * roundness, tip[1] - ny * width * roundness)
    return "M%s C%s %s %s C%s %s %s Z" % (P(cx, cy), P(*a1), P(*t1), P(*tip), P(*t2), P(*a2), P(cx, cy))
