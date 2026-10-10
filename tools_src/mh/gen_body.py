"""Gövde (baş, boyun, eller, ayaklar) + iskelet + gözler → JSON (Godot inşa betiği okur).

Çıktı: /home/claude/tools/mh/out/body.json
Koordinatlar: Godot (metre, yüz -Z yönüne bakar, taban y=0).
"""
import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import mhlib  # noqa: E402

OUT = "/home/claude/tools/mh/out"
os.makedirs(OUT, exist_ok=True)

ETH = dict(caucasian=0.8, asian=0.1, african=0.1)
BASE = dict(gender=1.0, age=0.5, muscle=0.5, weight=0.5, height=0.5, proportions=0.5, **ETH)

# makro şekiller: (ad, parametre değişikliği) — taban parametreye göre fark
MACRO_SHAPES = [
    ("female", dict(gender=0.0)),
    ("old", dict(age=0.85)),
    ("heavy", dict(weight=1.0)),
    ("thin", dict(weight=0.0)),
    ("muscle", dict(muscle=1.0)),
    ("tall", dict(height=0.65)),
    ("short", dict(height=0.32)),
]
# kadın-yaşlı çapraz terimi: (f_old - f_young) - (m_old - m_young)
FACE_SHAPES = [
    ("nose_wide", ["nose/nose-scale-horiz-incr.target"]),
    ("nose_long", ["nose/nose-scale-vert-incr.target"]),
    ("nose_hump", ["nose/nose-hump-incr.target"]),
    ("chin_prom", ["chin/chin-prominent-incr.target"]),
    ("chin_wide", ["chin/chin-width-incr.target"]),
    ("face_fat", ["head/head-fat-incr.target"]),
    ("face_square", ["head/head-square.target"]),
    ("mouth_wide", ["mouth/mouth-scale-horiz-incr.target"]),
    ("eyes_big", ["eyes/l-eye-scale-incr.target", "eyes/r-eye-scale-incr.target"]),
    ("cheekbones", ["cheek/l-cheek-bones-incr.target", "cheek/r-cheek-bones-incr.target"]),
]
EXPR = "expression/units/caucasian/"
EXPR_SHAPES = [
    ("blink", [EXPR + "eye-left-closure.target", EXPR + "eye-right-closure.target"]),
    ("mouth_open", [EXPR + "mouth-open.target"]),
]

# sadeleştirilmiş iskelet: yeni kemik -> birleşen MakeHuman kemikleri (zincir sırasıyla)
KEEP = [
    ("hips", None, ["root"]),
    ("spine", "hips", ["spine05", "spine04"]),
    ("spine1", "spine", ["spine03", "spine02"]),
    ("chest", "spine1", ["spine01"]),
    ("neck", "chest", ["neck01", "neck02", "neck03"]),
    ("head", "neck", ["head"]),
    ("jaw", "head", ["jaw"]),
]
for s in ("L", "R"):
    KEEP += [
        (f"clavicle.{s}", "chest", [f"clavicle.{s}", f"shoulder01.{s}"]),
        (f"upperarm.{s}", f"clavicle.{s}", [f"upperarm01.{s}", f"upperarm02.{s}"]),
        (f"forearm.{s}", f"upperarm.{s}", [f"lowerarm01.{s}", f"lowerarm02.{s}"]),
        (f"hand.{s}", f"forearm.{s}", [f"wrist.{s}", f"metacarpal2.{s}"]),
        (f"fingers.{s}", f"hand.{s}", [f"finger3-1.{s}", f"finger3-2.{s}", f"finger3-3.{s}"]),
        (f"thumb.{s}", f"hand.{s}", [f"finger1-1.{s}", f"finger1-2.{s}", f"finger1-3.{s}"]),
        (f"thigh.{s}", "hips", [f"upperleg01.{s}", f"upperleg02.{s}"]),
        (f"shin.{s}", f"thigh.{s}", [f"lowerleg01.{s}", f"lowerleg02.{s}"]),
        (f"foot.{s}", f"shin.{s}", [f"foot.{s}"]),
        (f"toes.{s}", f"foot.{s}", [f"toe3-1.{s}", f"toe3-2.{s}", f"toe3-3.{s}"]),
    ]
KEEP_NAMES = [k[0] for k in KEEP]


def merged_bone_of(orig):
    """Bir MakeHuman kemiğinin hangi sadeleştirilmiş kemiğe katılacağı."""
    sk = mhlib.skel()["bones"]
    direct = {}
    for new, _p, olds in KEEP:
        for o in olds:
            direct[o] = new
    b = orig
    while b is not None:
        if b in direct:
            # yüz kemikleri baş/çeneye, parmaklar ilgili parmağa
            return direct[b]
        if b.startswith("finger1-"):
            return "thumb." + b[-1]
        if b.startswith("finger") or b.startswith("metacarpal"):
            return ("fingers." if b.startswith("finger") else "hand.") + b[-1]
        if b.startswith("toe"):
            return "toes." + b[-1]
        if b.startswith("pelvis."):
            return "hips"
        if b.startswith("breast."):
            return "spine1"
        b = sk[b]["parent"]
    return "hips"


def g(v):
    """MakeHuman → Godot eksenleri (180° Y dönüşü) ve metre."""
    v = np.asarray(v, dtype=np.float64)
    out = v * mhlib.SCALE
    out[..., 0] *= -1
    out[..., 2] *= -1
    return out


def rot(n):
    n = np.array(n, dtype=np.float64)
    n[..., 0] *= -1
    n[..., 2] *= -1
    return n


def vertex_normals(v, faces):
    """faces: (F,4) dörtgen ya da (F,3) üçgen indeksleri. Yüz alanıyla ağırlıklı köşe normalleri."""
    n = np.zeros_like(v)
    f = np.asarray(faces)
    if f.shape[1] == 4:
        tris = np.concatenate([f[:, [0, 1, 2]], f[:, [0, 2, 3]]])
    else:
        tris = f
    a, b, c = v[tris[:, 0]], v[tris[:, 1]], v[tris[:, 2]]
    fn = np.cross(b - a, c - a)
    for k in range(3):
        np.add.at(n, tris[:, k], fn)
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    ln[ln < 1e-12] = 1.0
    return n / ln


def merged_weights(nverts):
    W = mhlib.weights()
    acc = [dict() for _ in range(nverts)]
    for orig, lst in W.items():
        nb = merged_bone_of(orig)
        for vi, w in lst:
            if vi < nverts:
                acc[vi][nb] = acc[vi].get(nb, 0.0) + w
    bones = np.zeros((nverts, 4), dtype=np.int32)
    wts = np.zeros((nverts, 4), dtype=np.float32)
    dom = []
    for i, d in enumerate(acc):
        items = sorted(d.items(), key=lambda kv: -kv[1])[:4]
        s = sum(w for _, w in items) or 1.0
        for k, (nb, w) in enumerate(items):
            bones[i, k] = KEEP_NAMES.index(nb)
            wts[i, k] = w / s
        dom.append(items[0][0] if items else "hips")
    return bones, wts, dom


def bone_rest(jp):
    """Sadeleştirilmiş kemiklerin dünya uzayındaki dinlenme dönüşümleri (Godot koordinatı)."""
    sk = mhlib.skel()["bones"]
    rest = {}
    fwd = np.array([0.0, 0.0, -1.0])
    up = np.array([0.0, 1.0, 0.0])
    for new, parent, olds in KEEP:
        h = g(jp[sk[olds[0]]["head"]])
        t = g(jp[sk[olds[-1]]["tail"]])
        y = t - h
        ln = np.linalg.norm(y)
        y = y / ln if ln > 1e-6 else up.copy()
        ref = fwd if abs(np.dot(y, fwd)) < 0.85 else up
        x = np.cross(y, ref)
        x /= np.linalg.norm(x)
        z = np.cross(x, y)
        rest[new] = {"origin": h, "basis": np.stack([x, y, z], axis=1), "tail": t}
    return rest


def build():
    b = mhlib.base()
    nb = len(b.v)
    v0 = mhlib.body_verts(BASE)
    floor0 = v0[b.group_verts("body")][:, 1].min()
    bones, wts, dom = merged_weights(nb)

    # --- tutulacak yüzler: baş/boyun, eller (+ön kolun bilek kısmı), ayaklar (+bilek)
    jp0 = mhlib.joint_positions(v0)
    sk = mhlib.skel()["bones"]
    wristL = jp0[sk["wrist.L"]["head"]]
    wristR = jp0[sk["wrist.R"]["head"]]
    ankL = jp0[sk["foot.L"]["head"]]
    ankR = jp0[sk["foot.R"]["head"]]
    neck_base = jp0[sk["neck01"]["head"]]
    keep_dom = {"head", "jaw", "hand.L", "hand.R", "fingers.L", "fingers.R", "thumb.L", "thumb.R"}

    NB = jp0[sk["neck01"]["head"]]

    def neck_r(p):
        zc = NB[2] + np.clip(p[1] - NB[1], -1.0, 0.6) * 0.41
        return math.sqrt(p[0] ** 2 + (p[2] - zc) ** 2)

    def keep_vert(i):
        p = v0[i]
        if dom[i] in keep_dom:
            return True
        if dom[i].startswith("forearm"):
            w = wristL if dom[i].endswith("L") else wristR
            return np.linalg.norm(p - w) < 1.1  # bilekten 11 cm
        if dom[i].startswith("shin"):
            return False
        if dom[i] in ("neck", "chest", "clavicle.L", "clavicle.R", "spine1"):
            # boyun silindiri: yaka deliğinin biraz altına kadar (giysinin altında kalır)
            return p[1] > NB[1] - 0.21 and neck_r(p) < 1.0
        return False

    body_faces = [b.faces[i] for i in b.groups["body"]]
    kept = []
    for vs, ts, _g in body_faces:
        if all(keep_vert(i) for i in vs):
            kept.append((vs, ts))
    # ayak/ayakkabı ve ten ayrımı: ayak bölgesi ayrı yüzey
    def is_shoe(vs):
        return all(dom[i] in ("foot.L", "foot.R", "toes.L", "toes.R") or dom[i].startswith("shin") for i in vs)

    # --- köşe birleştirme (v, vt) çiftleri
    surfaces = {"skin": {}, "shoe": {}}
    for vs, ts in kept:
        sname = "shoe" if is_shoe(vs) else "skin"
        surf = surfaces[sname]
        surf.setdefault("map", {})
        surf.setdefault("corners", [])
        surf.setdefault("tris", [])
        idx = []
        for vi, ti in zip(vs, ts):
            key = (vi, ti)
            if key not in surf["map"]:
                surf["map"][key] = len(surf["corners"])
                surf["corners"].append(key)
            idx.append(surf["map"][key])
        # dörtgeni üçgenle (Godot saat yönü ön yüz: yönü sonra düzeltiriz)
        if len(idx) == 4:
            surf["tris"] += [[idx[0], idx[1], idx[2]], [idx[0], idx[2], idx[3]]]
        else:
            surf["tris"] += [[idx[0], idx[1], idx[2]]]

    # --- şekil hedefleri
    def shape_verts(params=None, extra=None):
        p = dict(BASE)
        if params:
            p.update(params)
        return mhlib.body_verts(p, extra)

    shapes = []
    for name, ch in MACRO_SHAPES:
        shapes.append((name, shape_verts(ch)))
    # kadın-yaşlı çapraz
    f_old = shape_verts(dict(gender=0.0, age=0.85))
    f_y = shapes[0][1]
    m_old = shapes[1][1]
    shapes.append(("female_old", v0 + (f_old - f_y) - (m_old - v0)))
    f_heavy = shape_verts(dict(gender=0.0, weight=1.0))
    shapes.append(("female_heavy", v0 + (f_heavy - f_y) - (shapes[2][1] - v0)))
    for name, tl in FACE_SHAPES + EXPR_SHAPES:
        shapes.append((name, shape_verts(None, [(t, 1.0) for t in tl])))

    jp_shapes = {name: mhlib.joint_positions(sv) for name, sv in shapes}
    rest0 = bone_rest(jp0)

    # taban y kaydırması: g() sonrası tabanı 0'a oturt
    floor_shift = -floor0 * mhlib.SCALE

    def gv(arr):
        out = g(arr)
        out[..., 1] += floor_shift
        return out

    def surf_arrays(surf, verts):
        vi = np.array([c[0] for c in surf["corners"]])
        return gv(verts[vi])

    out = {"bones": [], "surfaces": [], "shapes": [n for n, _ in shapes], "floor_shift": floor_shift}
    for new, parent, _ in KEEP:
        r = rest0[new]
        o = r["origin"].copy()
        o[1] += floor_shift
        out["bones"].append({"name": new, "parent": parent, "basis": r["basis"].T.flatten().tolist(),
                             "origin": o.tolist()})
    # şekil başına kemik kökeni farkları (iskeleti her karaktere uydurmak için)
    out["bone_shape_deltas"] = {}
    for name, _sv in shapes:
        rs = bone_rest(jp_shapes[name])
        out["bone_shape_deltas"][name] = [(rs[k]["origin"] - rest0[k]["origin"]).tolist() for k in KEEP_NAMES]
    # taban farkı (şekil başına): ayak tabanının kayması
    body_idx = b.group_verts("body")
    out["floor_deltas"] = {name: float(-(sv[body_idx][:, 1].min() - floor0) * mhlib.SCALE) for name, sv in shapes}

    body_quads = np.array([b.faces[i][0] for i in b.groups["body"] if len(b.faces[i][0]) == 4])
    N0 = vertex_normals(v0, body_quads)
    shapeN = {name: vertex_normals(sv, body_quads) for name, sv in shapes}
    for sname, surf in surfaces.items():
        if not surf.get("corners"):
            continue
        vi = np.array([c[0] for c in surf["corners"]])
        ti = np.array([c[1] for c in surf["corners"]])
        pos = gv(v0[vi])
        uv = b.uv[ti].copy()
        uv[:, 1] = 1.0 - uv[:, 1]
        tris = np.array(surf["tris"], dtype=np.int64)
        entry = {
            "name": sname,
            "positions": pos.flatten().round(5).tolist(),
            "uvs": uv.flatten().round(5).tolist(),
            "bones": bones[vi].flatten().tolist(),
            "weights": wts[vi].flatten().round(4).tolist(),
            "indices": tris.flatten().tolist(),
            "orig_index": vi.tolist(),
            "normals": rot(N0[vi]).flatten().round(4).tolist(),
            "shapes": {},
            "shape_normals": {},
        }
        for name, sv in shapes:
            d = gv(sv[vi]) - pos
            if np.abs(d).max() < 1e-5:
                continue
            entry["shapes"][name] = d.flatten().round(5).tolist()
            entry["shape_normals"][name] = (rot(shapeN[name][vi]) - rot(N0[vi])).flatten().round(4).tolist()
        out["surfaces"].append(entry)

    # --- gözler (yardımcı göz geometrisine birebir oturan düşük poligonlu göz)
    eyes = build_eyes(v0, gv, shapes)
    out["surfaces"].append(eyes)
    json.dump(out, open(os.path.join(OUT, "body.json"), "w"))
    tri_count = sum(len(s["indices"]) // 3 for s in out["surfaces"])
    print("bones", len(out["bones"]), "shapes", len(shapes), "tris", tri_count,
          "verts", sum(len(s["positions"]) // 3 for s in out["surfaces"]))


def build_eyes(v0, gv, shapes):
    path = os.path.join(mhlib.MH, "eyes/low-poly/")
    lines = open(path + "low-poly.mhclo").read().splitlines()
    refs = []
    on = False
    for ln in lines:
        if ln.startswith("verts"):
            on = True
            continue
        if on:
            p = ln.split()
            if not p:
                continue
            if len(p) == 1:
                refs.append((int(p[0]),))
            elif len(p) >= 9:
                refs.append(tuple(float(x) for x in p[:9]))
            else:
                break
    verts, uvs, faces = [], [], []
    for ln in open(path + "low-poly.obj"):
        if ln.startswith("v "):
            verts.append(ln.split()[1:4])
        elif ln.startswith("vt "):
            uvs.append([float(x) for x in ln.split()[1:3]])
        elif ln.startswith("f "):
            faces.append([[int(x) - 1 for x in t.split("/")[:2]] for t in ln.split()[1:]])

    def fit(vv):
        out = []
        for r in refs:
            if len(r) == 1:
                out.append(vv[r[0]])
            else:
                i = [int(r[0]), int(r[1]), int(r[2])]
                w = r[3:6]
                out.append(vv[i[0]] * w[0] + vv[i[1]] * w[1] + vv[i[2]] * w[2])
        return np.array(out)

    p0 = fit(v0)
    cmap, corners, tris = {}, [], []
    for f in faces:
        idx = []
        for vi, ti in f:
            k = (vi, ti)
            if k not in cmap:
                cmap[k] = len(corners)
                corners.append(k)
            idx.append(cmap[k])
        if len(idx) == 4:
            tris += [[idx[0], idx[1], idx[2]], [idx[0], idx[2], idx[3]]]
        else:
            tris += [idx[:3]]
    vi = np.array([c[0] for c in corners])
    ti = np.array([c[1] for c in corners])
    pos = gv(p0[vi])
    uv = np.array(uvs)[ti]
    uv[:, 1] = 1.0 - uv[:, 1]
    hb = KEEP_NAMES.index("head")
    vq = np.array([[c[0] for c in f] for f in faces if len(f) == 4])
    en = vertex_normals(p0, vq)
    entry = {"name": "eyes", "positions": pos.flatten().round(5).tolist(), "uvs": uv.flatten().round(5).tolist(),
             "normals": rot(en[vi]).flatten().round(4).tolist(), "shape_normals": {},
             "bones": [hb, 0, 0, 0] * len(vi), "weights": [1.0, 0, 0, 0] * len(vi),
             "indices": np.array(tris).flatten().tolist(), "shapes": {}}
    for name, sv in shapes:
        d = gv(fit(sv)[vi]) - pos
        if np.abs(d).max() < 1e-5:
            continue
        entry["shapes"][name] = d.flatten().round(5).tolist()
    return entry


if __name__ == "__main__":
    build()
