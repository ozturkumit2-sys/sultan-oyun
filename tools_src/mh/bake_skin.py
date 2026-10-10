"""Cilt dokusu pişirici: MakeHuman UV düzeninde, 3D konumdan türetilen yüz/el ayrıntıları.

Çıktılar (assets/characters/):
  skin_detail.png  RGB: nötr açık ten varyasyonu x boşluk gölgesi (karakter rengiyle çarpılır)
  skin_masks.png   R: kaş, G: sakal/bıyık bölgesi, B: dudak, A: saçlı deri (kafa)
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
import mhlib  # noqa: E402
import gen_body as gb  # noqa: E402

S = int(os.environ.get("SKIN_RES", "1024"))
OUT = "/home/claude/sultan/assets/characters/"


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def value_noise(shape, cells, seed):
    rng = np.random.default_rng(seed)
    g = rng.random((cells + 1, cells + 1))
    ys = np.linspace(0, cells, shape[0], endpoint=False)
    xs = np.linspace(0, cells, shape[1], endpoint=False)
    y0 = ys.astype(int)
    x0 = xs.astype(int)
    fy = smooth(0, 1, ys - y0)[:, None]
    fx = smooth(0, 1, xs - x0)[None, :]
    a = g[y0][:, x0]
    b = g[y0][:, x0 + 1]
    c = g[y0 + 1][:, x0]
    d = g[y0 + 1][:, x0 + 1]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def rasterize(uv_tris, attr_tris, size):
    """uv_tris (T,3,2) [0..1], attr_tris (T,3,K) → (size,size,K) görüntü + kapsama maskesi."""
    K = attr_tris.shape[2]
    img = np.zeros((size, size, K), dtype=np.float64)
    cov = np.zeros((size, size), dtype=bool)
    P = uv_tris * size
    for t in range(len(P)):
        p = P[t]
        x0, y0 = np.floor(p.min(0)).astype(int)
        x1, y1 = np.ceil(p.max(0)).astype(int)
        x0, y0 = max(x0, 0), max(y0, 0)
        x1, y1 = min(x1, size - 1), min(y1, size - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        a, b, c = p
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-12:
            continue
        w0 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / den
        w1 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
        w2 = 1 - w0 - w1
        m = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
        if not m.any():
            continue
        val = w0[..., None] * attr_tris[t, 0] + w1[..., None] * attr_tris[t, 1] + w2[..., None] * attr_tris[t, 2]
        sub = img[y0:y1 + 1, x0:x1 + 1]
        sub[m] = val[m]
        cov[y0:y1 + 1, x0:x1 + 1] |= m
    return img, cov


def dilate(img, cov, iters=8):
    img = img.copy()
    cov = cov.copy()
    for _ in range(iters):
        acc = np.zeros_like(img)
        cnt = np.zeros(cov.shape)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            sh_img = np.roll(np.roll(img, dy, 0), dx, 1)
            sh_cov = np.roll(np.roll(cov, dy, 0), dx, 1)
            acc += sh_img * sh_cov[..., None]
            cnt += sh_cov
        new = (~cov) & (cnt > 0)
        img[new] = acc[new] / cnt[new][:, None]
        cov |= new
    return img


def main():
    b = mhlib.base()
    v = b.v
    nb = len(v)
    bones, wts, dom = gb.merged_weights(nb)
    body_faces = [b.faces[i] for i in b.groups["body"]]
    quads = np.array([f[0] for f in body_faces if len(f[0]) == 4])
    N = gb.vertex_normals(v, quads)
    # boşluk (konkavlık): komşu ortalamasına göre normal yönünde fark
    nsum = np.zeros_like(v)
    ncnt = np.zeros(nb)
    for f in quads:
        for k in range(4):
            a, c = f[k], f[(k + 1) % 4]
            nsum[a] += v[c]
            ncnt[a] += 1
            nsum[c] += v[a]
            ncnt[c] += 1
    ncnt[ncnt == 0] = 1
    lap = nsum / ncnt[:, None] - v
    cav = np.einsum("ij,ij->i", lap, N)  # >0 içbükey
    # iki kez yumuşat
    for _ in range(2):
        s2 = np.zeros(nb)
        c2 = np.zeros(nb)
        for f in quads:
            for k in range(4):
                a, c = f[k], f[(k + 1) % 4]
                s2[a] += cav[c]
                c2[a] += 1
                s2[c] += cav[a]
                c2[c] += 1
        c2[c2 == 0] = 1
        cav = 0.5 * cav + 0.5 * s2 / c2
    is_hand = np.array([d.startswith(("hand", "fingers", "thumb", "forearm")) for d in dom], dtype=float)
    is_head = np.array([d in ("head", "jaw", "neck") for d in dom], dtype=float)
    # tırnak: parmak uçlarına yakın sırt tarafı
    tips = []
    sk = mhlib.skel()["bones"]
    jp = mhlib.joint_positions(v)
    for s in ("L", "R"):
        for fi in range(1, 6):
            tips.append((jp[sk[f"finger{fi}-3.{s}"]["tail"]], jp[sk[f"finger{fi}-3.{s}"]["head"]]))

    uv_tris, at_tris = [], []
    for vs, ts, _g in body_faces:
        tri_sets = [(0, 1, 2), (0, 2, 3)] if len(vs) == 4 else [(0, 1, 2)]
        for tset in tri_sets:
            uvt = np.array([[b.uv[ts[k]][0], 1 - b.uv[ts[k]][1]] for k in tset])
            att = np.array([[*v[vs[k]], *N[vs[k]], cav[vs[k]], is_hand[vs[k]], is_head[vs[k]]] for k in tset])
            uv_tris.append(uvt)
            at_tris.append(att)
    img, cov = rasterize(np.array(uv_tris), np.array(at_tris), S)
    P = img[..., 0:3]
    Nn = img[..., 3:6]
    CAV = img[..., 6]
    HAND = img[..., 7]
    x, y, z = P[..., 0], P[..., 1], P[..., 2]
    ax = np.abs(x)
    front = smooth(0.6, 1.1, z) * (HAND < 0.5)

    # ---- kaş
    yc = 7.515 - 0.6 * (ax - 0.32) ** 2 - 0.2 * np.clip(0.16 - ax, 0, 1)
    thick = 0.036 - 0.024 * smooth(0.12, 0.58, ax)
    brow = (1 - smooth(thick * 0.35, thick, np.abs(y - yc))) * smooth(0.07, 0.12, ax) * (1 - smooth(0.5, 0.58, ax))
    brow *= smooth(1.15, 1.3, z) * (HAND < 0.5)
    # kıl dokusu: yatayda uzun, dikeyde ince gürültü
    rng = np.random.default_rng(11)
    strands = np.array(Image.fromarray((rng.random((S, S)) * 255).astype(np.uint8)).resize((S, S)).filter(ImageFilter.BoxBlur(1))) / 255.0
    brow *= 0.35 + 0.65 * strands
    brow = np.clip(brow * 1.1, 0, 0.9)

    # ---- dudaklar
    up = ((x / 0.19) ** 2 + ((y - 6.70) / 0.048) ** 2) < 1.0
    up &= y > 6.662 - 0.4 * ax ** 2
    lo = ((x / 0.165) ** 2 + ((y - 6.615) / 0.05) ** 2) < 1.0
    lo &= y < 6.662 - 0.4 * ax ** 2
    lips = (up | lo).astype(float) * smooth(1.42, 1.5, z)
    lips = np.array(Image.fromarray((lips * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(S / 512))) / 255.0

    # ---- sakal bölgesi: yanak çizgisinin altı, çene, üst dudak, çene altı
    cheek_line = 7.02 - 0.18 * smooth(0.15, 0.45, ax) + 0.06 * smooth(0.45, 0.62, ax)
    beard = (y < cheek_line).astype(float)
    beard *= smooth(0.66, 0.6, ax) if False else (1 - smooth(0.6, 0.68, ax))
    beard *= smooth(0.25, 0.6, z)                     # ön yarı
    beard *= smooth(5.95, 6.1, y)                     # boyun alt sınırı
    beard *= 1 - lips
    nose_base = (ax < 0.17) & (y > 6.80)
    beard[nose_base] = 0
    beard *= (HAND < 0.5)
    beard = np.array(Image.fromarray((beard * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(S / 300))) / 255.0

    # ---- saçlı deri
    hairline = 7.86 - 0.35 * smooth(0.35, 0.62, ax)
    scalp_front = (y > hairline) & (z > 0.6)
    scalp_back = (z <= 0.6) & (y > 6.75 + 0.5 * smooth(0.3, 0.7, ax))
    scalp = (scalp_front | scalp_back).astype(float) * (HAND < 0.5)
    scalp = np.array(Image.fromarray((scalp * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(S / 200))) / 255.0

    # ---- nötr ten detayı
    lowf = value_noise((S, S), 9, 3)
    midf = value_noise((S, S), 40, 4)
    pores = value_noise((S, S), S // 3, 5)
    base = np.ones((S, S, 3))
    base *= (0.94 + 0.08 * (lowf[..., None] - 0.5) + 0.05 * (midf[..., None] - 0.5) + 0.05 * (pores[..., None] - 0.5))
    # kızarıklık: yanak, burun, kulak, parmak eklemleri
    blush = np.exp(-(((ax - 0.42) / 0.16) ** 2 + ((y - 6.98) / 0.16) ** 2)) * front
    nose = np.exp(-((x / 0.1) ** 2 + ((y - 6.92) / 0.12) ** 2)) * smooth(1.5, 1.65, z)
    ears = smooth(0.62, 0.72, ax) * (y > 6.75) * (y < 7.5) * (HAND < 0.5)
    red = np.clip(0.55 * blush + 0.5 * nose + 0.35 * ears, 0, 1)
    base[..., 0] *= 1 + 0.05 * red
    base[..., 1] *= 1 - 0.07 * red
    base[..., 2] *= 1 - 0.07 * red
    # göz çevresi hafif koyu/morumsu
    eye_d = np.sqrt(((ax - 0.31) / 0.2) ** 2 + ((y - 7.27) / 0.13) ** 2)
    socket = (1 - smooth(0.7, 1.1, eye_d)) * front
    base *= (1 - 0.12 * socket[..., None] * np.array([0.9, 1.0, 0.85]))
    # boşluk gölgesi
    cavn = np.clip(CAV / 0.05, -1, 1)
    occl = 1 - 0.35 * np.clip(cavn, 0, 1)
    base *= occl[..., None]
    base *= (1 + 0.06 * np.clip(-cavn, 0, 1))[..., None]
    # tırnaklar
    nails = np.zeros((S, S))
    for tip, knuck in tips:
        dirv = tip - knuck
        dirv /= np.linalg.norm(dirv)
        rel = P - (tip - dirv * 0.06)
        along = rel @ dirv
        perp = np.linalg.norm(rel - along[..., None] * dirv, axis=-1)
        nails = np.maximum(nails, (np.abs(along) < 0.07) * (perp < 0.075) * HAND)
    # tırnak yüzeyi yalnız sırtta: normal elin üstüne bakmalı (yaklaşık: y bileşeni > 0 ya da dışa)
    nails *= smooth(-0.2, 0.3, Nn[..., 1] + 0.2)
    base = base * (1 - nails[..., None] * 0.25) + nails[..., None] * np.array([1.08, 0.98, 0.95]) * 0.25

    det = dilate(np.clip(base, 0, 1.2) / 1.2, cov)
    masks = np.stack([brow, beard, lips, scalp], axis=-1)
    msk = dilate(masks, cov)
    Image.fromarray((np.clip(det, 0, 1) * 255).astype(np.uint8)).save(OUT + "skin_detail.png")
    Image.fromarray((np.clip(msk, 0, 1) * 255).astype(np.uint8), "RGBA").save(OUT + "skin_masks.png")
    print("ok", S)


if __name__ == "__main__":
    main()
