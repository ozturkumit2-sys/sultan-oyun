"""Kıyafet üretici: MakeHuman yardımcı yüzeylerinden (helper-tights, helper-skirt, helper-hair)
entari, kaftan, kuşak, saç gibi giysi ağları üretir. Her makro şekil için aynı işlemler
uygulanıp farklar şekil anahtarı (blend shape) olarak kaydedilir.

Çıktı: out/clothes.json (Godot charbuild.gd okur)
"""
import json
import math
import os
import sys

import numpy as np
from scipy import sparse

sys.path.insert(0, os.path.dirname(__file__))
import mhlib  # noqa: E402
import gen_body as gb  # noqa: E402

OUT = gb.OUT
# giysiler yalnız ana beden şekillerini taşır (boyut: her şekil tüm köşeleri oynatır)
MACRO = ["female", "old", "heavy", "tall"]   # zayıf = -heavy, kısa = -tall (figür tarafında)


def shape_positions():
    b = mhlib.base()
    v0 = mhlib.body_verts(gb.BASE)
    shapes = {}
    for name, ch in gb.MACRO_SHAPES:
        p = dict(gb.BASE)
        p.update(ch)
        shapes[name] = mhlib.body_verts(p)
    p = dict(gb.BASE)
    p.update(gender=0.0, age=0.85)
    f_old = mhlib.body_verts(p)
    shapes["female_old"] = v0 + (f_old - shapes["female"]) - (shapes["old"] - v0)
    p = dict(gb.BASE)
    p.update(gender=0.0, weight=1.0)
    f_h = mhlib.body_verts(p)
    shapes["female_heavy"] = v0 + (f_h - shapes["female"]) - (shapes["heavy"] - v0)
    floor0 = v0[b.group_verts("body")][:, 1].min()
    return v0, shapes, floor0


# ----------------------------------------------------------------- ağ işlemleri (doğrusal)
class Topo:
    """Alt kümeden yeniden indekslenmiş dörtgen ağ + 'kaynak' seyrek matrisi (yeni = M @ eski)."""

    def __init__(self, quads_global, n_global):
        used = np.unique(quads_global)
        remap = -np.ones(n_global, dtype=np.int64)
        remap[used] = np.arange(len(used))
        self.quads = remap[quads_global]
        self.n = len(used)
        self.M = sparse.csr_matrix((np.ones(len(used)), (np.arange(len(used)), used)), shape=(len(used), n_global))

    def subdivide(self):
        q = self.quads
        n = self.n
        edges = {}
        rows, cols, vals = list(range(n)), list(range(n)), [1.0] * n
        new_idx = n
        e_ids = np.zeros((len(q), 4), dtype=np.int64)
        for fi, f in enumerate(q):
            for k in range(4):
                a, c = int(f[k]), int(f[(k + 1) % 4])
                key = (min(a, c), max(a, c))
                if key not in edges:
                    edges[key] = new_idx
                    rows += [new_idx, new_idx]
                    cols += [a, c]
                    vals += [0.5, 0.5]
                    new_idx += 1
                e_ids[fi, k] = edges[key]
        f_ids = np.arange(new_idx, new_idx + len(q))
        for fi, f in enumerate(q):
            for k in range(4):
                rows.append(f_ids[fi])
                cols.append(int(f[k]))
                vals.append(0.25)
        total = new_idx + len(q)
        S = sparse.csr_matrix((vals, (rows, cols)), shape=(total, n))
        nq = []
        for fi, f in enumerate(q):
            c = f_ids[fi]
            e = e_ids[fi]
            nq += [[f[0], e[0], c, e[3]], [e[0], f[1], e[1], c], [c, e[1], f[2], e[2]], [e[3], c, e[2], f[3]]]
        self.quads = np.array(nq, dtype=np.int64)
        self.M = S @ self.M
        self.n = total

    def laplacian(self):
        q = self.quads
        rows, cols = [], []
        for k in range(4):
            a = q[:, k]
            c = q[:, (k + 1) % 4]
            rows += list(a) + list(c)
            cols += list(c) + list(a)
        A = sparse.csr_matrix((np.ones(len(rows)), (rows, cols)), shape=(self.n, self.n))
        A.data[:] = 1.0
        deg = np.asarray(A.sum(1)).ravel()
        deg[deg == 0] = 1
        return sparse.diags(1.0 / deg) @ A

    def boundary_verts(self):
        cnt = {}
        for f in self.quads:
            for k in range(4):
                a, c = int(f[k]), int(f[(k + 1) % 4])
                key = (min(a, c), max(a, c))
                cnt[key] = cnt.get(key, 0) + 1
        bv = set()
        for (a, c), m in cnt.items():
            if m == 1:
                bv.add(a)
                bv.add(c)
        return np.array(sorted(bv), dtype=np.int64)


def normals(P, quads):
    return gb.vertex_normals(P, quads)


def taubin(P, L, iters, lam=0.5, mu=-0.53, fixed=None):
    P = P.copy()
    for _ in range(iters):
        for f in (lam, mu):
            D = L @ P - P
            if fixed is not None:
                D[fixed] = 0
            P = P + f * D
    return P


# ----------------------------------------------------------------- giysi tanımları
_SEGS = None


def _skel_segments():
    global _SEGS
    if _SEGS is None:
        v = mhlib.base().v
        jp = mhlib.joint_positions(v)
        segs = []
        for bn, bd in mhlib.skel()["bones"].items():
            if bn.startswith(("finger", "toe", "tongue", "oris", "levator", "oculi", "orbicularis", "risorius", "temporalis", "special", "eye", "breast", "metacarpal")):
                continue
            segs.append((jp[bd["head"]], jp[bd["tail"]]))
        _SEGS = (np.array([a for a, _ in segs]), np.array([c for _, c in segs]))
    return _SEGS


def _orient_out(quads, v):
    """Yüzleri iskeletten dışarı bakacak şekilde çevir (yardımcı yüzeylerde karışık yönler var)."""
    A, B = _skel_segments()
    AB = B - A
    L2 = (AB ** 2).sum(1)
    L2[L2 < 1e-9] = 1e-9
    out = []
    for f in quads:
        p = v[f]
        c = p.mean(0)
        n = np.cross(p[1] - p[0], p[2] - p[0]) + np.cross(p[2] - p[0], p[3] - p[0])
        t = np.clip(((c - A) * AB).sum(1) / L2, 0, 1)
        q = A + AB * t[:, None]
        d = ((c - q) ** 2).sum(1)
        ref = c - q[np.argmin(d)]
        out.append(list(f) if np.dot(n, ref) >= 0 else [f[0], f[3], f[2], f[1]])
    return np.array(out, dtype=np.int64)


def face_sel(b, group, pred):
    out = []
    for fi in b.groups[group]:
        vs = b.faces[fi][0]
        if len(vs) == 4 and pred(vs):
            out.append(vs)
    return _orient_out(np.array(out, dtype=np.int64), b.v)


class Garment:
    def __init__(self, name, topo, bones_src, weights_src):
        self.name = name
        self.topo = topo
        self.bw = (bones_src, weights_src)


def merged_weight_matrix(nb):
    """Her MH köşesi için sadeleştirilmiş kemik ağırlık vektörü (n, B)."""
    bones, wts, _dom = gb.merged_weights(nb)
    B = len(gb.KEEP_NAMES)
    W = np.zeros((nb, B))
    for k in range(4):
        np.add.at(W, (np.arange(nb), bones[:, k]), wts[:, k])
    return W


def finalize_weights(W):
    """(n,B) → ilk 4 kemik + normalleştirme."""
    idx = np.argsort(-W, axis=1)[:, :4]
    w = np.take_along_axis(W, idx, axis=1)
    s = w.sum(1, keepdims=True)
    s[s == 0] = 1
    return idx.astype(np.int32), (w / s).astype(np.float32)


def ring_center(P, y, band=0.25):
    m = np.abs(P[:, 1] - y) < band
    if not m.any():
        return np.array([0.0, y, 0.0])
    c = P[m].mean(0)
    c[0] = 0.0
    return c


def build():
    b = mhlib.base()
    nb = len(b.v)
    v0, shapes, floor0 = shape_positions()
    _bones, _w, dom = gb.merged_weights(nb)
    Wfull = merged_weight_matrix(nb)
    BI = {n: i for i, n in enumerate(gb.KEEP_NAMES)}

    lower = {"thigh.L", "thigh.R", "shin.L", "shin.R", "foot.L", "foot.R", "toes.L", "toes.R"}
    skirt_top = v0[b.group_verts("helper-skirt")][:, 1].max()

    JP0 = mhlib.joint_positions(v0)
    SKB = mhlib.skel()["bones"]
    NB = JP0[SKB["neck01"]["head"]]
    HJ = JP0[SKB["head"]["head"]]

    def neck_r(p):
        zc = NB[2] + np.clip(p[1] - NB[1], -1.0, 0.6) * 0.41
        return math.sqrt(p[0] ** 2 + (p[2] - zc) ** 2)

    def upper_pred(vs):
        for i in vs:
            if dom[i] in lower:
                return False
            if v0[i][1] > NB[1] + 0.23:      # dik yaka: boyun silindiri (kenar sonra düzlenir)
                return False
            if v0[i][1] < skirt_top - 0.9:
                return False
        return True

    tights_up = face_sel(b, "helper-tights", upper_pred)
    skirt_q = face_sel(b, "helper-skirt", lambda vs: True)
    def hair_pred(vs):
        c = v0[vs].mean(0)
        # yüzün önüne düşen perçemleri at
        if c[2] > HJ[2] + 0.64 and c[1] < HJ[1] + 1.33 and abs(c[0]) < 0.72:
            return False
        return True

    hair_q = face_sel(b, "helper-hair", hair_pred)
    foot_set = {"foot.L", "foot.R", "toes.L", "toes.R"}
    ank_y = mhlib.joint_positions(v0)[mhlib.skel()["bones"]["foot.L"]["head"]][1]
    shoe_q = face_sel(b, "helper-tights", lambda vs: all((dom[i] in foot_set) or (v0[i][1] < ank_y + 0.35) for i in vs))
    print("faces tights_up", len(tights_up), "skirt", len(skirt_q), "hair", len(hair_q))

    out = {"shapes": MACRO, "surfaces": [], "meshes": {}}

    # ---- üst gövde + kollar ve etek ayrı topolojiler; aynı giysi ağında birleşir
    def make_topo(q, subdiv):
        t = Topo(q, nb)
        for _ in range(subdiv):
            t.subdivide()
        return t

    T_up = make_topo(tights_up, 0)
    T_sk = make_topo(skirt_q, 1)
    T_hair = make_topo(hair_q, 1)
    L_up = T_up.laplacian()
    L_sk = T_sk.laplacian()
    L_hair = T_hair.laplacian()
    bnd_up = T_up.boundary_verts()

    rng = np.random.default_rng(42)
    fold_phase = rng.random(64) * math.tau
    fold_amp = 0.6 + 0.8 * rng.random(64)

    def skirt_positions(P_all, off, flare, hem_y, fold, open_front=0.0):
        P = T_sk.M @ P_all
        N = normals(P, T_sk.quads)
        P = P + N * off
        P = taubin(P, L_sk, 6)
        top = P[:, 1].max()
        bot = P[:, 1].min()
        # boyu uzat: alt halkalar etek ucuna (hem_y)
        t = np.clip((top - P[:, 1]) / (top - bot), 0, 1)
        P[:, 1] = top - t * (top - hem_y)
        c_top = ring_center(P, top - 0.3, 0.3)
        cz = c_top[2]
        ang = np.arctan2(P[:, 0], P[:, 2] - cz)
        rad = np.sqrt(P[:, 0] ** 2 + (P[:, 2] - cz) ** 2)
        k = 1 + flare * t ** 1.6
        # kıvrımlar: aşağı doğru artan dikey dalgalanma
        fphase = fold_phase[(np.floor((ang + math.pi) / math.tau * 18).astype(int)) % 64]
        f = fold * (t ** 1.2) * np.sin(ang * 18 + fphase * 0.35) * fold_amp[(np.floor((ang + math.pi) * 3).astype(int)) % 64]
        rad2 = rad * k + f
        P[:, 0] = np.sin(ang) * rad2
        P[:, 2] = cz + np.cos(ang) * rad2
        return P, t, ang

    P_up_base = T_up.M @ v0
    sk_b = mhlib.skel()["bones"]

    def _bclass(P):
        jp = mhlib.joint_positions(v0)
        wl = jp[sk_b["wrist.L"]["head"]]
        wr = jp[sk_b["wrist.R"]["head"]]
        neck_b, cuff_l, cuff_r = [], [], []
        for vi in bnd_up:
            q = P[vi]
            if q[1] > NB[1] - 0.49 and neck_r(q) < 1.3:
                neck_b.append(vi)
            elif np.linalg.norm(q - wl) < 1.6:
                cuff_l.append(vi)
            elif np.linalg.norm(q - wr) < 1.6:
                cuff_r.append(vi)
        return np.array(neck_b), np.array(cuff_l), np.array(cuff_r)

    NECK_B, CUFF_L, CUFF_R = _bclass(P_up_base)
    print("boundary neck/cuffL/cuffR", len(NECK_B), len(CUFF_L), len(CUFF_R))

    def upper_positions(P_all, off, smooth_it):
        P = T_up.M @ P_all
        N = normals(P, T_up.quads)
        P = P + N * off
        P = taubin(P, L_up, smooth_it, fixed=bnd_up)
        # kenarları düzle: yaka yatay halka, kol ağızları bilek düzleminde
        jpn = mhlib.joint_positions(P_all)[SKB["neck01"]["head"]]
        for vi in NECK_B:
            zc = jpn[2] + np.clip(P[vi, 1] - jpn[1], -1.0, 0.6) * 0.41
            th = math.atan2(P[vi, 0], P[vi, 2] - zc)
            P[vi, 1] = jpn[1] + 0.13 - 0.08 * math.cos(th)
        jp = mhlib.joint_positions(P_all)
        for side, idx in (("L", CUFF_L), ("R", CUFF_R)):
            if len(idx) == 0:
                continue
            w = jp[sk_b["wrist." + side]["head"]]
            e = jp[sk_b["lowerarm01." + side]["head"]]
            n = (w - e) / np.linalg.norm(w - e)
            c = w - n * 0.15
            d = (P[idx] - c) @ n
            P[idx] -= d[:, None] * n[None, :]
        return P

    def to_godot(P, floor):
        G = P * mhlib.SCALE
        G[:, 0] *= -1
        G[:, 2] *= -1
        G[:, 1] -= floor * mhlib.SCALE
        return G

    def weights_for(T, P_rest, skirt=False, t=None):
        W = T.M @ Wfull
        # ağırlıkları kumaş boyunca yumuşat: koltuk altı/omuzda katlanmayı azaltır
        L = T.laplacian()
        for _ in range(4):
            W = 0.5 * W + 0.5 * (L @ W)
        if skirt:
            # eteği bacaklara daha az bağla: kalça/omurgaya karıştır
            a = 0.35 + 0.15 * (1 - t)
            hips = np.zeros_like(W)
            hips[:, BI["hips"]] = 1.0
            W = W * (1 - a[:, None]) + hips * a[:, None]
        return finalize_weights(W)

    def tris_of(quads, keep=None):
        out = []
        for fi, f in enumerate(quads):
            if keep is not None and not keep[fi]:
                continue
            out += [[f[0], f[1], f[2]], [f[0], f[2], f[3]]]
        return np.array(out, dtype=np.int64)

    def emit(name, parts):
        """parts: [(surface_name, P_base(G), P_shapes{name:G}, N(G), tris, bones, weights, rest(G))]"""
        mesh = []
        for sname, P, PS, N, tris, bo, we, rest, rnorm in parts:
            used = np.unique(tris)
            remap = -np.ones(len(P), dtype=np.int64)
            remap[used] = np.arange(len(used))
            e = {"name": sname, "positions": P[used].flatten().round(5).tolist(),
                 "normals": N[used].flatten().round(4).tolist(),
                 "custom0": np.concatenate([rest[used], np.zeros((len(used), 1))], 1).flatten().round(4).tolist(),
                 "custom1": np.concatenate([rnorm[used], np.zeros((len(used), 1))], 1).flatten().round(4).tolist(),
                 "bones": bo[used].flatten().tolist(), "weights": we[used].flatten().round(4).tolist(),
                 "indices": remap[tris].flatten().tolist(), "shapes": {}}
            for sn, Q in PS.items():
                d = Q[used] - P[used]
                if np.abs(d).max() > 1e-5:
                    e["shapes"][sn] = d.flatten().round(5).tolist()
            mesh.append(e)
        out["meshes"][name] = mesh
        print(name, sum(len(m["indices"]) // 3 for m in mesh), "tris")

    def rot_n(N):
        N = N.copy()
        N[:, 0] *= -1
        N[:, 2] *= -1
        return N

    # ---------------------------------------------------- entari (iç uzun giysi) ve kaftan (dış)
    body_v = b.group_verts("body")
    neck_v = np.array([i for i in body_v if dom[i] in ("neck",)])
    SEG = 36

    def collar_positions(P_all, Pu):
        rings = [[], [], [], []]
        nv = P_all[neck_v]
        for k in range(SEG):
            th = k / SEG * math.tau
            d = np.array([math.sin(th), 0.0, math.cos(th)])
            y_in = 5.72 - 0.17 * math.cos(th)
            zc = 0.068 + np.clip(y_in - 5.89, -1.0, 0.6) * 0.41
            c = np.array([0.0, y_in, zc])
            rel = nv - c
            m = np.abs(rel[:, 1]) < 0.18
            ang = np.arctan2(rel[m, 0], rel[m, 2])
            da = np.abs(np.angle(np.exp(1j * (ang - th))))
            sel = da < 0.35
            r_in = (np.sqrt(rel[m][sel][:, 0] ** 2 + rel[m][sel][:, 2] ** 2).max() if sel.any() else 0.6) + 0.07
            inner = c + d * r_in
            # dış kenar: giysi yüzeyinde bu açıdaki en yüksek nokta (omuz/göğüs üstü)
            relu = Pu - c
            ru = np.sqrt(relu[:, 0] ** 2 + relu[:, 2] ** 2)
            au = np.arctan2(relu[:, 0], relu[:, 2])
            du = np.abs(np.angle(np.exp(1j * (au - th))))
            mu = (du < 0.3) & (ru > r_in + 0.25) & (ru < r_in + 0.75) & (Pu[:, 1] > 4.6)
            if mu.any():
                cand = Pu[mu]
                outer = cand[np.argmax(cand[:, 1])] + np.array([0.0, 0.05, 0.0])
            else:
                outer = c + d * (r_in + 0.45) + np.array([0.0, -0.25, 0.0])
            mid = inner * 0.45 + outer * 0.55 + np.array([0.0, 0.07, 0.0])
            top = inner + np.array([0.0, 0.22, 0.0]) + d * 0.02
            rings[0].append(outer)
            rings[1].append(mid)
            rings[2].append(inner)
            rings[3].append(top)
        return np.array(rings).reshape(-1, 3)

    cq = []
    for r in range(3):
        for k in range(SEG):
            a = r * SEG + k
            b2 = r * SEG + (k + 1) % SEG
            cq.append([a, a + SEG, b2 + SEG, b2])
    cq = np.array(cq)

    def robe(name, off_up, off_sk, flare, hem, fold, open_ang, cuff_len, trim_w, inner_only=False):
        def gen(P_all):
            Pu = upper_positions(P_all, off_up, 4)
            Ps, t, ang = skirt_positions(P_all, off_sk, flare, hem, fold)
            return Pu, Ps, t, ang

        Pu0, Ps0, t0, ang0 = gen(v0)
        fl0 = floor0
        G_u0 = to_godot(Pu0, fl0)
        G_s0 = to_godot(Ps0, fl0)
        shp_u, shp_s = {}, {}
        for sn in MACRO:
            Pu, Ps, _t, _a = gen(shapes[sn])
            shp_u[sn] = to_godot(Pu, fl0)
            shp_s[sn] = to_godot(Ps, fl0)
        Nu = rot_n(normals(Pu0, T_up.quads))
        Ns = rot_n(normals(Ps0, T_sk.quads))
        bu, wu = weights_for(T_up, Pu0)
        bs, ws = weights_for(T_sk, Ps0, True, t0)
        # yüz seçimi: ön açıklık, kenar süsleri (trim)
        fc_ang = ang0[T_sk.quads].mean(1)
        fc_t = t0[T_sk.quads].mean(1)
        lim = open_ang * np.clip((fc_t - 0.02) / 0.3, 0, 1) ** 0.7
        keep = np.abs(fc_ang) > lim if open_ang > 0 else np.ones(len(fc_ang), bool)
        trim = (fc_t > 1 - trim_w) | ((np.abs(fc_ang) < lim + 0.16) & (open_ang > 0) & (fc_t > 0.03))
        # kol ağzı süsü: üst gövdede bilek yakınındaki yüzler
        sk = mhlib.skel()["bones"]
        jp = mhlib.joint_positions(v0)
        wl = jp[sk["wrist.L"]["head"]]
        wr = jp[sk["wrist.R"]["head"]]
        fcu = Pu0[T_up.quads].mean(1)
        cuff = (np.linalg.norm(fcu - wl, axis=1) < cuff_len) | (np.linalg.norm(fcu - wr, axis=1) < cuff_len)
        collar_f = (fcu[:, 1] > NB[1] - 0.11) & (np.array([neck_r(c) for c in fcu]) < 1.0)
        up_trim = cuff | collar_f
        if open_ang > 0:
            kept_v = np.zeros(T_sk.n, bool)
            kept_v[T_sk.quads[keep].ravel()] = True
            cut_v = np.zeros(T_sk.n, bool)
            cut_v[T_sk.quads[~keep].ravel()] = True
            edge_v = np.where(kept_v & cut_v)[0]

            def snap(P_all_g, Ps_raw, ang_raw, t_raw, floor):
                # açıklık sınırındaki köşeleri sınır açısına yerleştir (Godot koordinatında)
                Pm = Ps_raw.copy()
                c_top = ring_center(Pm, Pm[:, 1].max() - 0.3, 0.3)
                cz = c_top[2]
                for vi in edge_v:
                    a = ang_raw[vi]
                    lv = open_ang * np.clip((t_raw[vi] - 0.02) / 0.3, 0, 1) ** 0.7
                    na = math.copysign(lv, a if abs(a) > 1e-6 else 1.0)
                    r = math.hypot(Pm[vi, 0], Pm[vi, 2] - cz)
                    Pm[vi, 0] = math.sin(na) * r
                    Pm[vi, 2] = cz + math.cos(na) * r
                return to_godot(Pm, floor)

            G_s0 = snap(None, Ps0, ang0, t0, fl0)
            for sn in MACRO:
                Pu, Ps, tt, aa = gen(shapes[sn])
                shp_s[sn] = snap(None, Ps, aa, tt, fl0)
        up_vis = np.ones(len(T_up.quads), bool)
        if inner_only:
            # kaftanın altında kalan gövde/kol yüzlerini at: yalnız yaka çevresi ve bilekler görünür
            near_neck = (fcu[:, 1] > NB[1] - 0.7) & (np.array([neck_r(c) for c in fcu]) < 1.25)
            near_wrist = (np.linalg.norm(fcu - wl, axis=1) < 1.0) | (np.linalg.norm(fcu - wr, axis=1) < 1.0)
            up_vis = near_neck | near_wrist
        parts = [
            ("cloth", G_u0, shp_u, Nu, tris_of(T_up.quads, ~up_trim & up_vis), bu, wu, Pu0 * 0.1, rot_n(normals(Pu0, T_up.quads))),
            ("trim", G_u0, shp_u, Nu, tris_of(T_up.quads, up_trim & up_vis), bu, wu, Pu0 * 0.1, rot_n(normals(Pu0, T_up.quads))),
            ("cloth_sk", G_s0, shp_s, Ns, tris_of(T_sk.quads, keep & ~trim), bs, ws, Ps0 * 0.1, rot_n(normals(Ps0, T_sk.quads))),
            ("trim_sk", G_s0, shp_s, Ns, tris_of(T_sk.quads, keep & trim), bs, ws, Ps0 * 0.1, rot_n(normals(Ps0, T_sk.quads))),
        ]
        emit(name, [p for p in parts if len(p[4])])

    hem_long = floor0 + 0.45        # tabana 4.5 cm
    robe("entari_in", 0.12, 0.10, 0.10, hem_long, 0.10, 0.0, 0.35, 0.03, inner_only=True)
    robe("kaftan", 0.30, 0.26, 0.22, hem_long + 0.15, 0.16, 0.42, 0.55, 0.06)

    # ---------------------------------------------------- kuşak
    def sash_positions(P_all):
        Ps, t, ang = skirt_positions(P_all, 0.10, 0.10, hem_long, 0.0)
        top = Ps[:, 1].max()
        yc = top - 0.55
        c = ring_center(Ps, yc, 0.2)
        m = np.abs(Ps[:, 1] - yc) < 0.25
        a = np.arctan2(Ps[m, 0], Ps[m, 2] - c[2])
        r = np.sqrt(Ps[m, 0] ** 2 + (Ps[m, 2] - c[2]) ** 2)
        segs = 40
        rings = []
        heights = [-0.55, -0.35, 0.0, 0.35, 0.55]
        bulge = [0.0, 0.18, 0.26, 0.18, 0.0]
        for hi, h in enumerate(heights):
            ring = []
            for s in range(segs):
                th = s / segs * math.tau - math.pi
                # o açıya en yakın yarıçap
                dd = np.abs(np.angle(np.exp(1j * (a - th))))
                rr = r[np.argsort(dd)[:3]].mean() + 0.18 + bulge[hi]
                ring.append([math.sin(th) * rr, yc + h, c[2] + math.cos(th) * rr])
            rings.append(ring)
        return np.array(rings).reshape(-1, 3), segs, len(heights)

    S0, segs, nh = sash_positions(v0)
    quads = []
    for i in range(nh - 1):
        for s in range(segs):
            a = i * segs + s
            b2 = i * segs + (s + 1) % segs
            quads.append([a, b2, b2 + segs, a + segs])
    quads = np.array(quads)
    G0 = to_godot(S0, floor0)
    shp = {sn: to_godot(sash_positions(shapes[sn])[0], floor0) for sn in MACRO}
    NS = rot_n(normals(S0, quads))
    bo = np.zeros((len(S0), 4), np.int32)
    bo[:, 0] = BI["spine"]
    we = np.zeros((len(S0), 4), np.float32)
    we[:, 0] = 1.0
    # sarkan uçlar (önde, düğüm): iki şerit
    emit("sash", [("sash", G0, shp, NS, tris_of(quads), bo, we, S0 * 0.1, rot_n(normals(S0, quads)))])

    # ---------------------------------------------------- uzun saç (kadınlar için; başlığın altından)
    def hair_positions(P_all):
        P = T_hair.M @ P_all
        N = normals(P, T_hair.quads)
        P = P + N * 0.06
        P = taubin(P, L_hair, 14)
        return P

    H0 = hair_positions(v0)
    Wh = T_hair.M @ Wfull
    # saç: baş + boyun/omurga
    bh, wh = finalize_weights(Wh)
    GH = to_godot(H0, floor0)
    shp = {sn: to_godot(hair_positions(shapes[sn]), floor0) for sn in MACRO}
    NH = rot_n(normals(H0, T_hair.quads))
    # (uzun saç yardımcı ağı artık kullanılmıyor: hair_f)

    # ---------------------------------------------------- ayakkabı (çedik/pabuç): taytın ayak kısmı
    T_sh = make_topo(shoe_q, 0)
    L_sh = T_sh.laplacian()

    def shoe_positions(P_all):
        P = T_sh.M @ P_all
        N = normals(P, T_sh.quads)
        P = P + N * 0.07
        P = taubin(P, L_sh, 4)
        return P

    F0 = shoe_positions(v0)
    bf, wf = finalize_weights(T_sh.M @ Wfull)
    GF = to_godot(F0, floor0)
    shp = {sn: to_godot(shoe_positions(shapes[sn]), floor0) for sn in MACRO}
    NF = rot_n(normals(F0, T_sh.quads))
    emit("shoes", [("shoe", GF, shp, NF, tris_of(T_sh.quads), bf, wf, F0 * 0.1, NF)])

    json.dump(out, open(os.path.join(OUT, "clothes.json"), "w"))


if __name__ == "__main__":
    build()
