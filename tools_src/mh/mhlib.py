"""MakeHuman (CC0) temel mesh, hedef (target), iskelet ve ağırlık yükleyicisi.

Birimler MakeHuman'da desimetredir; burada metreye çevrilir ve ayak tabanı y=0'a oturtulur.
"""
import json
import os
from functools import lru_cache

import numpy as np

MH = "/home/claude/ext/mh/makehuman/data"
SCALE = 0.1


class BaseMesh:
    def __init__(self):
        verts, uvs, faces = [], [], []
        group = None
        with open(os.path.join(MH, "3dobjs/base.obj")) as f:
            for line in f:
                if line.startswith("v "):
                    verts.append([float(x) for x in line.split()[1:4]])
                elif line.startswith("vt "):
                    uvs.append([float(x) for x in line.split()[1:3]])
                elif line.startswith("g "):
                    group = line.split()[1]
                elif line.startswith("f "):
                    vs, ts = [], []
                    for tok in line.split()[1:]:
                        p = tok.split("/")
                        vs.append(int(p[0]) - 1)
                        ts.append(int(p[1]) - 1 if len(p) > 1 and p[1] else -1)
                    faces.append((vs, ts, group))
        self.v = np.array(verts, dtype=np.float64)
        self.uv = np.array(uvs, dtype=np.float64)
        self.faces = faces
        self.groups = {}
        for i, (vs, ts, g) in enumerate(faces):
            self.groups.setdefault(g, []).append(i)

    def group_verts(self, name):
        s = set()
        for fi in self.groups.get(name, []):
            s.update(self.faces[fi][0])
        return np.array(sorted(s), dtype=np.int64)


@lru_cache(maxsize=None)
def base():
    return BaseMesh()


@lru_cache(maxsize=4096)
def load_target(rel):
    path = os.path.join(MH, "targets", rel)
    idx, d = [], []
    with open(path) as f:
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            p = line.split()
            idx.append(int(p[0]))
            d.append([float(p[1]), float(p[2]), float(p[3])])
    return np.array(idx, dtype=np.int64), np.array(d, dtype=np.float64)


def apply_target(v, rel, w):
    if abs(w) < 1e-6:
        return
    idx, d = load_target(rel)
    if len(idx):
        v[idx] += d * w


# ---------------------------------------------------------------- makro değişkenler
def _age_vals(a):
    if a < 0.5:
        young = max(0.0, (a - 0.1875) * 3.2)
        return {"baby": max(0.0, 1 - a * 5.333), "child": max(0.0, min(1.0, 5.333 * a) - young), "young": young, "old": 0.0}
    old = max(0.0, a * 2 - 1)
    return {"baby": 0.0, "child": 0.0, "young": 1 - old, "old": old}


def _tri(x, lo, mid, hi):
    if x < 0.5:
        m = max(0.0, 1 - x * 2)
        return {lo: m, mid: 1 - m, hi: 0.0}
    m = max(0.0, x * 2 - 1)
    return {lo: 0.0, mid: 1 - m, hi: m}


def macro_targets(p):
    """p: gender(0 kadın..1 erkek), age(0.5=25 yaş, 1=90), muscle, weight, height, proportions,
    african, asian, caucasian (toplam 1). (hedef_yolu, ağırlık) listesi döner."""
    g = {"female": 1 - p.get("gender", 0.5), "male": p.get("gender", 0.5)}
    ag = _age_vals(p.get("age", 0.5))
    mu = _tri(p.get("muscle", 0.5), "minmuscle", "averagemuscle", "maxmuscle")
    we = _tri(p.get("weight", 0.5), "minweight", "averageweight", "maxweight")
    h = p.get("height", 0.5)
    hv = {"minheight": max(0.0, 1 - h * 2), "maxheight": max(0.0, h * 2 - 1)}
    pr = p.get("proportions", 0.5)
    pv = {"uncommonproportions": max(0.0, 1 - pr * 2), "idealproportions": max(0.0, pr * 2 - 1)}
    races = {"african": p.get("african", 1 / 3), "asian": p.get("asian", 1 / 3), "caucasian": p.get("caucasian", 1 / 3)}
    out = []
    for gk, gw in g.items():
        for ak, aw in ag.items():
            if gw * aw < 1e-6:
                continue
            for rk, rw in races.items():
                out.append((f"macrodetails/{rk}-{gk}-{ak}.target", gw * aw * rw))
            for mk, mw in mu.items():
                for wk, ww in we.items():
                    base_w = gw * aw * mw * ww
                    if base_w < 1e-6:
                        continue
                    out.append((f"macrodetails/universal-{gk}-{ak}-{mk}-{wk}.target", base_w))
                    for hk, hw in hv.items():
                        if hw > 1e-6:
                            out.append((f"macrodetails/height/{gk}-{ak}-{mk}-{wk}-{hk}.target", base_w * hw))
                    if ak != "baby":
                        for pk, pw in pv.items():
                            if pw > 1e-6:
                                out.append((f"macrodetails/proportions/{gk}-{ak}-{mk}-{wk}-{pk}.target", base_w * pw))
    return [(t, w) for t, w in out if w > 1e-6 and os.path.exists(os.path.join(MH, "targets", t))]


def body_verts(params, extra=None):
    """Makro + ek (yüz) hedefleri uygulanmış ham koordinatlar (MakeHuman birimi)."""
    v = base().v.copy()
    for t, w in macro_targets(params):
        apply_target(v, t, w)
    for t, w in (extra or []):
        apply_target(v, t, w)
    return v


# ---------------------------------------------------------------- iskelet
@lru_cache(maxsize=None)
def skel():
    return json.load(open(os.path.join(MH, "rigs/default.mhskel")))


@lru_cache(maxsize=None)
def weights():
    return json.load(open(os.path.join(MH, "rigs/default_weights.mhw")))["weights"]


def joint_positions(v):
    s = skel()
    out = {}
    for name, idx in s["joints"].items():
        out[name] = v[np.array(idx)].mean(axis=0)
    return out


def to_world(v, floor_y):
    """MakeHuman birimi → metre, tabanı y=0'a oturt."""
    w = v * SCALE
    w[..., 1] -= floor_y * SCALE
    return w
