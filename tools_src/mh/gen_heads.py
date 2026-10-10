"""Başlıklar (sarık, kavuk, kallavi, börk, takke, hotoz, yemeni...) ve sakallar.

Başlıklar başa (head kemiği) bağlı katı ağlardır; her şekil anahtarı için kafa ölçüsüne
göre yeniden oturtulur. Sakallar yüz derisinden türetilen kabuklardır (gövdeyle aynı
şekil anahtarlarını taşır: ağız açılınca sakal da hareket eder).
Çıktı: out/heads.json
"""
import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import mhlib  # noqa: E402
import gen_body as gb  # noqa: E402
import gen_clothes as gc  # noqa: E402

OUT = gb.OUT
SEG = 40


def shapes_all():
    """gen_body ile aynı şekil kümesi (makro + yüz + ifade)."""
    b = mhlib.base()
    v0 = mhlib.body_verts(gb.BASE)
    out = {}
    for name, ch in gb.MACRO_SHAPES:
        p = dict(gb.BASE)
        p.update(ch)
        out[name] = mhlib.body_verts(p)
    p = dict(gb.BASE)
    p.update(gender=0.0, age=0.85)
    f_old = mhlib.body_verts(p)
    out["female_old"] = v0 + (f_old - out["female"]) - (out["old"] - v0)
    p = dict(gb.BASE)
    p.update(gender=0.0, weight=1.0)
    out["female_heavy"] = v0 + (mhlib.body_verts(p) - out["female"]) - (out["heavy"] - v0)
    for name, tl in gb.FACE_SHAPES + gb.EXPR_SHAPES:
        out[name] = mhlib.body_verts(gb.BASE, [(t, 1.0) for t in tl])
    floor0 = v0[b.group_verts("body")][:, 1].min()
    return v0, out, floor0


def to_godot(P, floor):
    G = np.asarray(P, dtype=np.float64) * mhlib.SCALE
    G[..., 0] *= -1
    G[..., 2] *= -1
    G[..., 1] -= floor * mhlib.SCALE
    return G


def rot_n(N):
    N = np.array(N, dtype=np.float64)
    N[..., 0] *= -1
    N[..., 2] *= -1
    return N


def quad_normals(P, quads):
    return gb.vertex_normals(P, quads)


# ------------------------------------------------------------------ kafa bandı
HEAD_V = None


def head_verts():
    global HEAD_V
    if HEAD_V is None:
        b = mhlib.base()
        _bo, _w, dom = gb.merged_weights(len(b.v))
        body = b.group_verts("body")
        HEAD_V = np.array([i for i in body if dom[i] in ("head",)])
    return HEAD_V


def fit_band(P_all, front_up=0.30, back_up=-0.25, gap=0.06):
    """Alnın üstünden kulak üstlerine, enseye inen eğik bant. MH biriminde
    (merkez, eksen n, ön yön u, yan yön w, θ başına yarıçap) döner."""
    jp = mhlib.joint_positions(P_all)
    sk = mhlib.skel()["bones"]
    eyeL = jp[sk["eye.L"]["head"]]
    eyeR = jp[sk["eye.R"]["head"]]
    eye = (eyeL + eyeR) * 0.5
    hv = P_all[head_verts()]
    top = hv[:, 1].max()
    cz = hv[hv[:, 1] > eye[1] + 0.5][:, 2].mean()
    y_front = eye[1] + 0.40 + front_up
    y_back = eye[1] + 0.10 + back_up
    # eğik düzlem: ön (z büyük) yukarıda
    c = np.array([0.0, (y_front + y_back) * 0.5, cz])
    slope = (y_front - y_back) / 1.9
    n = np.array([0.0, 1.0, -slope])
    n /= np.linalg.norm(n)
    u = np.array([0.0, 0.0, 1.0])
    u = u - n * np.dot(u, n)
    u /= np.linalg.norm(u)
    w = np.cross(n, u)
    rel = hv - c
    h = rel @ n
    pu = rel @ u
    pw = rel @ w
    ang = np.arctan2(pw, pu)
    rad = np.sqrt(pu ** 2 + pw ** 2)
    r = np.zeros(SEG)
    for k in range(SEG):
        th = k / SEG * math.tau - math.pi
        da = np.abs(np.angle(np.exp(1j * (ang - th))))
        m = (da < 0.22) & (np.abs(h) < 0.22)
        r[k] = (rad[m].max() if m.any() else 0.9) + gap
    # yumuşat (kulak çıkıntılarını düzle)
    for _ in range(3):
        r = 0.5 * r + 0.25 * (np.roll(r, 1) + np.roll(r, -1))
    return {"c": c, "n": n, "u": u, "w": w, "r": r, "top": top, "eye": eye}


def revolve(band, profile, H, rings, extra=None, close_top=True, h0=0.0):
    """band çevresinde dönel yüzey. profile(t)->yarıçap çarpanı, H yükseklik (MH)."""
    c, n, u, w, r = band["c"], band["n"], band["u"], band["w"], band["r"]
    verts = []
    for i in range(rings + 1):
        t = i / rings
        for k in range(SEG):
            th = k / SEG * math.tau - math.pi
            rr = r[k] * profile(t, th)
            if extra is not None:
                rr += extra(t, th)
            p = c + n * (h0 + H * t) + (u * math.cos(th) + w * math.sin(th)) * rr
            verts.append(p)
    quads = []
    for i in range(rings):
        for k in range(SEG):
            a = i * SEG + k
            b2 = i * SEG + (k + 1) % SEG
            quads.append([a, b2, b2 + SEG, a + SEG])
    verts = np.array(verts)
    if close_top:
        topc = c + n * (h0 + H)
        ci = len(verts)
        verts = np.vstack([verts, topc])
        base = rings * SEG
        tris = []
        for k in range(SEG):
            tris.append([base + k, base + (k + 1) % SEG, ci])
        return verts, np.array(quads), np.array(tris)
    return verts, np.array(quads), np.zeros((0, 3), dtype=np.int64)


def tris_of(quads, extra_tris=None):
    out = []
    for f in quads:
        out += [[f[0], f[1], f[2]], [f[0], f[2], f[3]]]
    if extra_tris is not None and len(extra_tris):
        out += [list(t) for t in extra_tris]
    return np.array(out, dtype=np.int64)


def tri_normals(P, tris):
    n = np.zeros_like(P)
    a, b, c = P[tris[:, 0]], P[tris[:, 1]], P[tris[:, 2]]
    fn = np.cross(b - a, c - a)
    for k in range(3):
        np.add.at(n, tris[:, k], fn)
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    ln[ln < 1e-12] = 1
    return n / ln


# ------------------------------------------------------------------ başlık tanımları
def turban(band, size=1.0, height=1.9, wraps=5, bulge=0.55, cap_h=0.0):
    """Sarık: spiral sargılar. Dönen parçalar: [(yüzey, verts, tris)]."""
    def prof(t, th):
        # soğan profili: alt bant ~1, ortada şişkin, üste doğru kapanır
        s = 1.0 + bulge * math.sin(min(t, 1.0) * math.pi * 0.85) ** 1.3
        if t > 0.75:
            s *= 1.0 - ((t - 0.75) / 0.25) ** 2 * 0.55
        return s * size

    def ex(t, th):
        phase = t * wraps + (th + math.pi) / math.tau * 1.0
        return 0.16 * abs(math.sin(math.pi * phase)) ** 0.5 - 0.09

    V, Q, T = revolve(band, prof, height, 18, ex, True)
    parts = [("hat", V, tris_of(Q, T))]
    if cap_h > 0:
        # tepede görünen renkli kavuk/külah
        def prof2(t, th):
            return 0.55 * (1.0 - t ** 2 * 0.85)
        V2, Q2, T2 = revolve(band, prof2, cap_h, 6, None, True, h0=height * 0.62)
        parts.append(("cap", V2, tris_of(Q2, T2)))
    return parts


def kallavi(band):
    """Vezir kallavisi: uzun, yukarı genişleyen silindir + çapraz sırma şerit."""
    def prof(t, th):
        return 1.08 + 0.22 * t
    V, Q, T = revolve(band, prof, 3.6, 14, lambda t, th: 0.025 * math.sin(th * 14), True)
    parts = [("hat", V, tris_of(Q, T))]

    # çapraz şerit (sırma): dar bir eğik halka
    def prof_b(t, th):
        return 1.12 + 0.22 * (0.5 + 0.35 * math.cos(th))
    band2 = dict(band)
    V2, Q2, T2 = revolve(band2, prof_b, 0.32, 2, None, False, h0=1.4)
    # eğiklik: θ'ya göre yüksekliği kaydır
    n = band["n"]
    for i in range(len(V2)):
        k = i % SEG
        th = k / SEG * math.tau - math.pi
        V2[i] = V2[i] + n * (0.9 * math.sin(th))
    parts.append(("trim", V2, tris_of(Q2, T2)))
    return parts


def bork(band):
    """Yeniçeri börkü: uzun keçe başlık + arkaya düşen yatırma."""
    def prof(t, th):
        return 1.04 + 0.08 * t
    V, Q, T = revolve(band, prof, 2.6, 10, None, True)
    parts = [("hat", V, tris_of(Q, T))]
    # yatırma: tepeden arkaya-aşağı sarkan kumaş
    c, n, u, w, r = band["c"], band["n"], band["u"], band["w"], band["r"]
    top_back = c + n * 2.5 - u * r[0] * 1.0
    rows, cols = 12, 8
    verts = []
    for i in range(rows + 1):
        t = i / rows
        for j in range(cols + 1):
            s = (j / cols - 0.5)
            width = 0.75 - 0.15 * t
            p = top_back - u * (0.35 * math.sin(t * 1.6)) - np.array([0, 1, 0]) * (t * 3.4) + w * s * width * 2
            p = p - u * (0.15 * (1 - abs(s * 2)) ** 2)
            verts.append(p)
    quads = []
    for i in range(rows):
        for j in range(cols):
            a = i * (cols + 1) + j
            quads.append([a, a + 1, a + cols + 2, a + cols + 1])
    parts.append(("flap", np.array(verts), tris_of(np.array(quads))))
    # önde sırma kaşıklık
    def prof_f(t, th):
        return 1.1 * (1 if abs(th) < 0.5 else 0.0) + 0.0
    return parts


def cap(band, H=0.9, s=1.0):
    def prof(t, th):
        return s * (1.0 - 0.45 * t ** 2.2)
    V, Q, T = revolve(band, prof, H, 8, None, True, h0=-0.05)
    return [("hat", V, tris_of(Q, T))]


def tall_cap(band, H=2.6, top=1.25):
    def prof(t, th):
        return 1.0 + (top - 1.0) * t
    V, Q, T = revolve(band, prof, H, 8, lambda t, th: 0.04 * math.sin(th * 10) * t, True)
    return [("hat", V, tris_of(Q, T))]


def brim_hat(band):
    def prof(t, th):
        return 1.02 - 0.12 * t
    V, Q, T = revolve(band, prof, 1.4, 6, None, True)
    parts = [("hat", V, tris_of(Q, T))]
    # kenar (siper): halka disk
    c, n, u, w, r = band["c"], band["n"], band["u"], band["w"], band["r"]
    verts = []
    for ring, scale in ((0, 1.0), (1, 1.75)):
        for k in range(SEG):
            th = k / SEG * math.tau - math.pi
            rr = r[k] * scale
            verts.append(c + n * (0.05 - 0.12 * ring) + (u * math.cos(th) + w * math.sin(th)) * rr)
    quads = [[k, (k + 1) % SEG, SEG + (k + 1) % SEG, SEG + k] for k in range(SEG)]
    parts.append(("trim", np.array(verts), tris_of(np.array(quads))))
    return parts


def hotoz(band, H=1.9, top=1.25, veil_len=4.5):
    """Kadın hotozu: yukarı genişleyen başlık, sırma bant ve arkaya düşen tül/yaşmak."""
    def prof(t, th):
        return 1.0 + (top - 1.0) * t
    V, Q, T = revolve(band, prof, H, 8, None, True)
    parts = [("hat", V, tris_of(Q, T))]

    def prof_b(t, th):
        return 1.06
    V2, Q2, _ = revolve(band, prof_b, 0.35, 1, None, False, h0=0.0)
    parts.append(("trim", V2, tris_of(Q2)))
    # tül: tepenin arka yarısından omuzlara
    c, n, u, w, r = band["c"], band["n"], band["u"], band["w"], band["r"]
    rows, cols = 14, 16
    verts = []
    for i in range(rows + 1):
        t = i / rows
        for j in range(cols + 1):
            th = math.pi * 0.5 + (j / cols) * math.pi  # arka yarım daire
            k = int(((th + math.pi) % math.tau) / math.tau * SEG) % SEG
            rr = r[k] * (top * (1 - t * 0.2) + t * 0.55)
            p = c + n * (H * (1 - t * 0.15)) + (u * math.cos(th) + w * math.sin(th)) * rr
            p = p - np.array([0, 1, 0]) * (veil_len * t ** 1.1)
            # kıvrımlar
            p = p + (u * math.cos(th) + w * math.sin(th)) * 0.08 * math.sin(j * 1.7) * t
            verts.append(p)
    quads = []
    for i in range(rows):
        for j in range(cols):
            a = i * (cols + 1) + j
            quads.append([a, a + cols + 1, a + cols + 2, a + 1])
    parts.append(("veil", np.array(verts), tris_of(np.array(quads))))
    return parts


HEADWEAR = {
    "sultan": lambda b: turban(fit_band(b, 0.25, -0.2, 0.06), 1.08, 2.4, 6, 0.75, 1.1),
    "sarik": lambda b: turban(fit_band(b, 0.25, -0.2, 0.05), 1.0, 1.8, 5, 0.55, 0.8),
    "sarik_small": lambda b: turban(fit_band(b, 0.25, -0.2, 0.04), 0.98, 1.3, 4, 0.35, 0.6),
    "kadi": lambda b: turban(fit_band(b, 0.2, -0.2, 0.06), 1.12, 2.0, 6, 1.0, 0.7),
    "vezir": lambda b: kallavi(fit_band(b, 0.25, -0.2, 0.05)),
    "bork": lambda b: bork(fit_band(b, 0.25, -0.25, 0.05)),
    "takke": lambda b: cap(fit_band(b, 0.45, 0.05, 0.03), 0.9, 1.0),
    "cook": lambda b: tall_cap(fit_band(b, 0.3, -0.15, 0.04), 2.4, 1.3),
    "foreign_hat": lambda b: brim_hat(fit_band(b, 0.35, -0.1, 0.05)),
    "hotoz": lambda b: hotoz(fit_band(b, 0.3, -0.05, 0.05), 1.8, 1.3, 4.6),
    "valide": lambda b: hotoz(fit_band(b, 0.3, -0.05, 0.06), 2.5, 1.4, 5.2),
}


# ------------------------------------------------------------------ yemeni/örtü (kafa derisinden kabuk)
def scarf_faces():
    b = mhlib.base()
    v = b.v  # ham taban koordinatları (yüz işaretleri bu ölçüyle)
    _bo, _w, dom = gb.merged_weights(len(v))
    out = []
    for fi in b.groups["body"]:
        vs = b.faces[fi][0]
        if len(vs) != 4:
            continue
        ok = True
        for i in vs:
            p = v[i]
            if dom[i] not in ("head", "neck", "jaw"):
                ok = False
                break
            ax = abs(p[0])
            # yüz açıklığı: kaşların biraz üstünden çenenin altına, yanaklar dışarıda
            in_face = (p[2] > 0.55) and (p[1] < 7.62) and (p[1] > 6.0) and (ax < 0.62)
            if in_face or p[1] < 5.75:
                ok = False
                break
        if ok:
            out.append(vs)
    return np.array(out, dtype=np.int64)


# ------------------------------------------------------------------ sakal
def beard_mask_raw(p, kind):
    x, y, z = p
    ax = abs(x)
    cheek_line = 7.02 - 0.18 * gb_smooth(0.15, 0.45, ax) + 0.06 * gb_smooth(0.45, 0.62, ax)
    m = 1.0 if y < cheek_line else 0.0
    m *= 1 - gb_smooth(0.58, 0.66, ax)
    m *= gb_smooth(0.3, 0.6, z)
    m *= gb_smooth(5.95, 6.1, y)
    if kind == "mustache":
        m *= (ax < 0.30) * (y > 6.70) * (y < 6.86)
    lips_up = ((x / 0.19) ** 2 + ((y - 6.70) / 0.048) ** 2) < 1.0 and y > 6.662
    lips_lo = ((x / 0.165) ** 2 + ((y - 6.615) / 0.05) ** 2) < 1.0 and y < 6.662
    if lips_up or lips_lo:
        m = 0.0
    if ax < 0.17 and y > 6.80:
        m = 0.0
    return m


def gb_smooth(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
    return t * t * (3 - 2 * t)


def build():
    b = mhlib.base()
    nb = len(b.v)
    v0, shapes, floor0 = shapes_all()
    head_i = gb.KEEP_NAMES.index("head")
    out = {"shapes": list(shapes.keys()), "meshes": {}}

    def emit(name, parts_by_shape, weights=None):
        """parts_by_shape: {shape_name or None: [(surf, V, tris)]} — topoloji aynı olmalı."""
        base_parts = parts_by_shape[None]
        mesh = []
        for pi, (sname, V, tris) in enumerate(base_parts):
            G = to_godot(V, floor0)
            N = rot_n(tri_normals(V, tris))
            n = len(G)
            if weights is None:
                bo = np.zeros((n, 4), np.int32)
                bo[:, 0] = head_i
                we = np.zeros((n, 4), np.float32)
                we[:, 0] = 1.0
            else:
                bo, we = weights(sname, V)
            e = {"name": sname, "positions": G.flatten().round(5).tolist(), "normals": N.flatten().round(4).tolist(),
                 "custom0": np.concatenate([V * 0.1, np.zeros((n, 1))], 1).flatten().round(4).tolist(),
                 "custom1": np.concatenate([tri_normals(V, tris), np.zeros((n, 1))], 1).flatten().round(4).tolist(),
                 "bones": bo.flatten().tolist(), "weights": we.flatten().round(4).tolist(),
                 "indices": tris.flatten().tolist(), "shapes": {}}
            for sn, parts in parts_by_shape.items():
                if sn is None:
                    continue
                d = to_godot(parts[pi][1], floor0) - G
                if np.abs(d).max() > 1e-5:
                    e["shapes"][sn] = d.flatten().round(5).tolist()
            mesh.append(e)
        out["meshes"][name] = mesh
        print(name, sum(len(m["indices"]) // 3 for m in mesh), "tris")

    head_shapes = ["female", "old", "heavy", "tall", "face_fat"]
    for hname, fn in HEADWEAR.items():
        pbs = {None: fn(v0)}
        for sn in head_shapes:
            pbs[sn] = fn(shapes[sn])

        def wfun(sname, V):
            n = len(V)
            bo = np.zeros((n, 4), np.int32)
            we = np.zeros((n, 4), np.float32)
            bo[:, 0] = head_i
            if sname in ("veil", "flap"):
                # aşağı sarktıkça boyna/göğse bağlan
                ytop = V[:, 1].max()
                t = np.clip((ytop - V[:, 1]) / 4.0, 0, 1)
                bo[:, 1] = gb.KEEP_NAMES.index("neck")
                bo[:, 2] = gb.KEEP_NAMES.index("chest")
                we[:, 0] = 1 - t
                we[:, 1] = t * 0.4
                we[:, 2] = t * 0.6
            else:
                we[:, 0] = 1.0
            return bo, we

        emit("hw_" + hname, pbs, wfun)

    # --- yemeni (baş örtüsü): kafa/boyun derisinden kabuk
    _bo, _w, dom = gb.merged_weights(nb)
    Wfull = gc.merged_weight_matrix(nb)
    sq = gc._orient_out(scarf_faces(), b.v)
    T = gc.Topo(sq, nb)
    L = T.laplacian()
    bnd = T.boundary_verts()

    def scarf_pos(P_all):
        P = T.M @ P_all
        N = quad_normals(P, T.quads)
        P = P + N * 0.16
        P = gc.taubin(P, L, 10, fixed=None)
        return P

    S0 = scarf_pos(v0)
    tris = tris_of(T.quads)
    pbs = {None: [("scarf", S0, tris)]}
    for sn in head_shapes:
        pbs[sn] = [("scarf", scarf_pos(shapes[sn]), tris)]
    Ws = T.M @ Wfull
    for _ in range(3):
        Ws = 0.5 * Ws + 0.5 * (L @ Ws)
    bs, ws = gc.finalize_weights(Ws)
    emit("hw_scarf", pbs, lambda sname, V: (bs, ws))

    # --- saç (kadın): kafa derisinden kabuk + arkada uzun saç
    def hair_faces():
        v = b.v
        res = []
        for fi in b.groups["body"]:
            vs = b.faces[fi][0]
            if len(vs) != 4:
                continue
            ok = True
            for i in vs:
                p = v[i]
                ax = abs(p[0])
                if dom[i] not in ("head",):
                    ok = False
                    break
                hairline = 7.86 - 0.35 * gb_smooth(0.35, 0.62, ax)
                front = p[2] > 0.55
                if front and p[1] < hairline:
                    ok = False
                    break
                if (not front) and p[1] < 6.75 + 0.5 * gb_smooth(0.3, 0.7, ax):
                    ok = False
                    break
                if ax > 0.55 and 6.8 < p[1] < 7.5 and p[2] > -0.2:   # kulaklar açık
                    ok = False
                    break
            if ok:
                res.append(vs)
        return np.array(res, dtype=np.int64)

    hq = gc._orient_out(hair_faces(), b.v)
    T = gc.Topo(hq, nb)
    L = T.laplacian()
    bndh = T.boundary_verts()

    def hair_pos(P_all):
        P = T.M @ P_all
        N = quad_normals(P, T.quads)
        P = P + N * 0.12
        P = gc.taubin(P, L, 6, fixed=None)
        return P

    def hair_back(P_all):
        """Enseden sırta inen saç paneli (12x10 ızgara)."""
        jp = mhlib.joint_positions(P_all)
        sk = mhlib.skel()["bones"]
        hj = jp[sk["head"]["head"]]
        nb_ = jp[sk["neck01"]["head"]]
        hv = P_all[head_verts()]
        back = hv[hv[:, 2] < hj[2] - 0.3]
        zb = back[:, 2].min()
        rows, cols = 10, 12
        verts = []
        for i in range(rows + 1):
            t = i / rows
            y = hj[1] + 0.6 - t * (hj[1] + 0.6 - (nb_[1] - 2.6))
            for j in range(cols + 1):
                s_ = j / cols - 0.5
                wdt = 1.25 - 0.2 * t
                x = s_ * wdt * 2
                # kafanın arkasını, sonra sırtı izle
                z = zb - 0.12 - 0.35 * math.cos(s_ * math.pi) * (1 - t) ** 2 + 0.25 * t
                if t > 0.35:
                    z = min(z, nb_[2] - 0.75 - 0.1 * (t - 0.35))
                verts.append([x, y, z - 0.06 * abs(math.sin(j * 1.9))])
        quads = []
        for i in range(rows):
            for j in range(cols):
                a = i * (cols + 1) + j
                quads.append([a, a + cols + 1, a + cols + 2, a + 1])
        return np.array(verts), np.array(quads)

    H0 = hair_pos(v0)
    tris = tris_of(T.quads)
    Bk0, bq = hair_back(v0)
    btris = tris_of(bq)
    pbs = {None: [("hair", H0, tris), ("hair", Bk0, btris)]}
    for sn in head_shapes:
        pbs[sn] = [("hair", hair_pos(shapes[sn]), tris), ("hair", hair_back(shapes[sn])[0], btris)]
    Wh = T.M @ Wfull
    bh, wh = gc.finalize_weights(Wh)

    def hw(sname, V):
        if len(V) == len(H0):
            return bh, wh
        n = len(V)
        bo = np.zeros((n, 4), np.int32)
        we = np.zeros((n, 4), np.float32)
        ytop = V[:, 1].max()
        t = np.clip((ytop - V[:, 1]) / 3.0, 0, 1)
        bo[:, 0] = head_i
        bo[:, 1] = gb.KEEP_NAMES.index("neck")
        bo[:, 2] = gb.KEEP_NAMES.index("chest")
        we[:, 0] = 1 - t
        we[:, 1] = t * 0.3
        we[:, 2] = t * 0.7
        return bo, we

    emit("hair_f", pbs, hw)

    # --- sakallar: yüz derisi kabuğu
    raw = b.v
    body_f = [b.faces[i][0] for i in b.groups["body"] if len(b.faces[i][0]) == 4]
    for kind, base_th, length in (("beard_short", 0.07, 0.0), ("beard_long", 0.11, 0.9), ("beard_full", 0.13, 1.6), ("mustache", 0.05, 0.0)):
        mk = "mustache" if kind == "mustache" else "full"
        mask = {}
        sel = []
        for f in body_f:
            ms = []
            for i in f:
                if i not in mask:
                    mask[i] = beard_mask_raw(raw[i], mk)
                ms.append(mask[i])
            if min(ms) > 0.05 or (max(ms) > 0.5 and np.mean(ms) > 0.4):
                sel.append(f)
        sel = gc._orient_out(np.array(sel, dtype=np.int64), raw)
        T = gc.Topo(sel, nb)
        L = T.laplacian()
        mvec = np.array([mask.get(i, 0.0) for i in range(nb)])
        mT = T.M @ mvec
        bndT = T.boundary_verts()
        edge = np.zeros(T.n)
        edge[bndT] = 1.0
        for _ in range(3):
            edge = np.maximum(edge, 0.6 * (L @ edge))
        rawT = T.M @ raw

        def beard_pos(P_all):
            P = T.M @ P_all
            N = quad_normals(P, T.quads)
            th = base_th * np.clip(mT, 0, 1) * (1 - 0.85 * edge)
            # çeneye doğru kalınlaşır
            chin = np.clip((6.55 - rawT[:, 1]) / 0.4, 0, 1)
            th = th * (1 + 1.2 * chin)
            P = P + N * th[:, None]
            if length > 0:
                drop = length * chin ** 1.5 * (1 - edge * 0.7) * np.clip((0.45 - np.abs(rawT[:, 0])) / 0.45, 0.15, 1)
                P[:, 1] -= drop
                P[:, 2] += drop * 0.25
            P = gc.taubin(P, L, 3, fixed=bndT)
            return P

        B0 = beard_pos(v0)
        tris = tris_of(T.quads)
        pbs = {None: [("beard", B0, tris)]}
        for sn in head_shapes + ["mouth_open", "chin_prom", "chin_wide"]:
            pbs[sn] = [("beard", beard_pos(shapes[sn]), tris)]
        bb, wb = gc.finalize_weights(T.M @ Wfull)
        emit(kind, pbs, lambda sname, V, bb=bb, wb=wb: (bb, wb))

    json.dump(out, open(os.path.join(OUT, "heads.json"), "w"))


if __name__ == "__main__":
    build()
