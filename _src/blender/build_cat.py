"""Builds the hero cat 'Tarçın' as a rigid-part toy rig (Astro-style) and exports cat.glb.
Cat faces Blender -Y (glTF +Z). Origin on ground under the body.
Fur vertex colors are MASKS: R=1, G=stripe, B=white. Shader colors them, so one model = many coats."""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import bpy, bmesh
from mathutils import Vector, Matrix, Quaternion
from common import *

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "/root/cati-kedisi/assets/models/cat.glb"

reset()
K = 1.739  # metaball radius factor so ellipsoid 'size' == surface semi-axes

M_FUR = get_mat("Fur", (1, 0.6, 0.2, 1))
M_PINK = get_mat("Pink", (0.95, 0.55, 0.62, 1))
M_NOSE = get_mat("Nose", (0.85, 0.38, 0.48, 1))
M_DARK = get_mat("Dark", (0.12, 0.08, 0.08, 1))
M_WHISK = get_mat("Whisker", (1, 1, 1, 1))
M_EYE = get_mat("Eye", (0.2, 0.6, 0.2, 1))
M_HI = get_mat("Highlight", (1, 1, 1, 1))
M_SCARF = get_mat("Scarf", (0.85, 0.12, 0.15, 1))


def ell(co, size, s=2.0):
    return dict(type="ELLIPSOID", co=co, r=K, size=size, s=s)


def ball(co, rad, s=2.0):
    return dict(type="BALL", co=co, r=rad * K, s=s)


def capsule(co, half_len, rad, rot, s=2.0):
    return dict(type="CAPSULE", co=co, r=rad * K, size=(half_len, 1, 1), rot=rot, s=s)


def finish(me, faces, smooth_it=1):
    me2 = decimate_mesh(me, faces)
    if me2 is not me:
        bpy.data.meshes.remove(me)
    smooth_mesh(me2, smooth_it, 0.35)
    shade_smooth(me2)
    return me2


root = empty("Cat")

# ---------------------------------------------------------------- BODY
BODY_P = Vector((0, 0.0, 0.36))
body = metaball_mesh("Body", [
    ell((0, -0.10, 0.39), (0.175, 0.19, 0.175)),   # chest
    ell((0, 0.14, 0.37), (0.165, 0.18, 0.16)),     # hips
    ell((0, 0.02, 0.36), (0.15, 0.2, 0.14)),       # belly bridge
    ball((0, -0.20, 0.47), 0.10),                  # neck/shoulder
], resolution=0.014)
body = finish(body, 3200)


def body_mask(co, n):
    white = smoothstep(-0.04, -0.16, co.y) * (1 - smoothstep(0.40, 0.48, co.z))
    white = max(white, 1 - smoothstep(0.24, 0.30, co.z))
    sw = math.sin(co.y * 31 + abs(co.x) * 9 + 0.6)
    stripe = smoothstep(0.25, 0.55, sw) * smoothstep(0.33, 0.45, co.z)
    stripe *= (1 - white)
    return (1, stripe, white, 1)


set_colors(body, body_mask)
transform_mesh(body, Matrix.Translation(-BODY_P))
o_body = new_obj("Body", body, root, BODY_P, M_FUR)

# ---------------------------------------------------------------- HEAD
H = Vector((0, -0.30, 0.76))      # head centre (cat space)
NECK = Vector((0, -0.22, 0.54))   # head pivot
head = metaball_mesh("Head", [
    ell(H + Vector((0, 0.02, 0.03)), (0.27, 0.23, 0.22)),
    ball(H + Vector((0.14, -0.07, -0.08)), 0.15),
    ball(H + Vector((-0.14, -0.07, -0.08)), 0.15),
    ball(H + Vector((0.045, -0.19, -0.075)), 0.075),
    ball(H + Vector((-0.045, -0.19, -0.075)), 0.075),
    ball(H + Vector((0, -0.15, -0.13)), 0.07),
    # fluffy cheek tufts
    ball(H + Vector((0.25, -0.0, -0.10)), 0.06, 1.6),
    ball(H + Vector((-0.25, -0.0, -0.10)), 0.06, 1.6),
], resolution=0.011)
head = finish(head, 5200)
print("HEAD dims", [round(v, 3) for v in (max(v.co[i] for v in head.vertices) - min(v.co[i] for v in head.vertices) for i in range(3))])


def head_mask(co, n):
    r = co - H
    d = Vector((r.x / 0.17, (r.y + 0.21) / 0.12, (r.z + 0.10) / 0.105)).length
    white = 1 - smoothstep(0.85, 1.05, d)
    # forehead "M" stripes
    fh = smoothstep(0.45, 0.7, math.cos(r.x * 100)) * smoothstep(0.07, 0.12, r.z) * (1 - smoothstep(0.085, 0.1, abs(r.x)))
    fh *= smoothstep(0.06, -0.06, r.y)
    # cheek stripes
    ck = smoothstep(0.5, 0.8, math.sin((r.z + 0.03) * 52)) * smoothstep(0.20, 0.25, abs(r.x)) * (1 - smoothstep(0.02, 0.08, r.z)) * smoothstep(-0.16, -0.10, r.z)
    # back of head
    bk = smoothstep(0.55, 0.8, math.cos(r.x * 22) * math.cos((r.y - 0.12) * 18)) * smoothstep(0.0, 0.08, r.y) * smoothstep(0.0, 0.1, r.z)
    stripe = min(1.0, fh + ck + bk) * (1 - white)
    return (1, stripe, white, 1)


set_colors(head, head_mask)
o_head_tmp = new_obj("HeadTmp", head, None, (0, 0, 0), M_FUR)
bpy.context.view_layer.update()


def surf(x, z, back=False):
    """surface point on head front at (x, z) offsets from H, raycasting along +Y"""
    origin = Vector((H.x + x, H.y - 1.0, H.z + z))
    ok, loc, nor = ray_surface(o_head_tmp, origin, (0, 1, 0))
    if not ok:
        raise RuntimeError("ray miss %s %s" % (x, z))
    return loc, nor


extra = []  # (mesh, matrix) merged into head (static face parts)

# nose: rounded triangle
nose_p, nose_n = surf(0, -0.045)
nose = uv_sphere("Nose", 1.0, 16, 10, (0.034, 0.02, 0.024))
for v in nose.vertices:
    if v.co.z < 0:
        t = -v.co.z / 0.024
        v.co.x *= (1 - 0.65 * t)
shade_smooth(nose)
nose.materials.append(M_NOSE)
extra.append((nose, Matrix.Translation(nose_p + nose_n * 0.004) @ nose_n.to_track_quat('-Y', 'Z').to_matrix().to_4x4()))

# mouth: little 'w' made of short tubes following the muzzle surface
mouth_pts = []
for i in range(0, 15):
    t = i / 14.0
    x = -0.05 + 0.1 * t
    xx = abs(x)
    z = -0.085 - 0.018 * math.sin(xx / 0.05 * math.pi) if xx > 0.001 else -0.075
    mouth_pts.append((x, z))
pts3 = []
for x, z in mouth_pts:
    p, nn = surf(x, z)
    pts3.append(p + nn * 0.002)
center_top, cn = surf(0, -0.062)
mouth_me = bpy.data.meshes.new("Mouth")
bm = bmesh.new()


def tube(bm, a, b, r=0.0055, segs=6):
    d = (b - a)
    L = d.length
    if L < 1e-5:
        return
    q = d.normalized().to_track_quat('Z', 'Y')
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r, radius2=r, depth=L)
    m = Matrix.Translation((a + b) / 2) @ q.to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=m, verts=res["verts"])


for i in range(len(pts3) - 1):
    tube(bm, pts3[i], pts3[i + 1])
tube(bm, center_top + cn * 0.002, pts3[7])
bm.to_mesh(mouth_me)
bm.free()
shade_smooth(mouth_me)
mouth_me.materials.append(M_DARK)
extra.append((mouth_me, Matrix.Identity(4)))

# whiskers
wh = bpy.data.meshes.new("Whiskers")
bm = bmesh.new()
for side in (-1, 1):
    base, bn = surf(side * 0.085, -0.075)
    base = base + bn * 0.004
    for k, ang in enumerate((-14, 0, 14)):
        a = math.radians(ang)
        dirv = Vector((side * math.cos(a), -0.25, math.sin(a) + 0.05)).normalized()
        tube(bm, base + Vector((0, 0, (k - 1) * 0.012)), base + dirv * 0.22, r=0.0035, segs=4)
bm.to_mesh(wh)
bm.free()
wh.materials.append(M_WHISK)
extra.append((wh, Matrix.Identity(4)))

# merge static face parts into head
head_full = join_meshes("Head", [(head, Matrix.Identity(4))] + extra)
shade_smooth(head_full)
# re-apply fur masks only where material is Fur (others keep white masks -> shader ignores)
set_colors(head_full, lambda co, n: head_mask(co, n))
transform_mesh(head_full, Matrix.Translation(-NECK))
bpy.data.objects.remove(o_head_tmp)
o_head = new_obj("Head", head_full, o_body, NECK - BODY_P)
o_head_tmp = new_obj("HeadTmp2", head, None, (0, 0, 0), M_FUR)  # for eye raycasts
bpy.context.view_layer.update()


def surf2(x, z):
    origin = Vector((H.x + x, H.y - 1.0, H.z + z))
    ok, loc, nor = ray_surface(o_head_tmp, origin, (0, 1, 0))
    return loc, nor


# ---------------------------------------------------------------- EYES
EYE_SIZE = (0.075, 0.04, 0.092)
for side, nm in ((1, "EyeL"), (-1, "EyeR")):
    p, nrm = surf2(side * 0.105, 0.025)
    nrm = (nrm + Vector((0, -1, 0)) * 1.2).normalized()
    eye = uv_sphere(nm, 1.0, 44, 30, EYE_SIZE)

    def eye_col(co, n, side=side):
        if co.y > 0.004:
            return (0.05, 0.05, 0.06, 1)
        u = co.x / EYE_SIZE[0]
        w = co.z / EYE_SIZE[2]
        rr = math.sqrt(u * u + w * w)
        # painted highlights (same light direction for both eyes)
        h1 = math.hypot(u + 0.34, w - 0.36)
        h2 = math.hypot(u - 0.30, w + 0.40)
        if h1 < 0.2 or h2 < 0.09:
            return (1.0, 1.0, 1.0, 1)
        pupil = (u / 0.56) ** 2 + (w / 0.72) ** 2
        if pupil < 1.0:
            return (0.015, 0.015, 0.03, 1)
        g = 0.55 + 0.3 * (-w)
        if rr > 0.9:
            return (0.05, 0.16, 0.05, 1)
        return (0.25 * g, 0.62 * g + 0.1, 0.16 * g, 1)

    set_colors(eye, eye_col)
    shade_smooth(eye)
    q = nrm.to_track_quat('-Y', 'Z')
    eo = new_obj(nm, eye, o_head, (p - NECK) - nrm * 0.012, M_EYE)
    eo.rotation_mode = 'QUATERNION'
    eo.rotation_quaternion = q

# ---------------------------------------------------------------- EARS
for side, nm in ((1, "EarL"), (-1, "EarR")):
    base_local = Vector((side * 0.155, 0.02, 0.16))  # from H
    ear = cone(nm, 0.11, 0.008, 0.215, 20)
    # cone points along +Z, base at -depth/2 -> shift so base at 0
    transform_mesh(ear, Matrix.Translation((0, 0, 0.1075)))
    transform_mesh(ear, Matrix.Diagonal((1, 0.62, 1, 1)))
    for v in ear.vertices:  # round the tip a bit and curve
        t = v.co.z / 0.215
        v.co.y += 0.02 * t * t
    inner = cone(nm + "In", 0.075, 0.004, 0.16, 16)
    transform_mesh(inner, Matrix.Translation((0, 0, 0.08 + 0.012)))
    transform_mesh(inner, Matrix.Diagonal((1, 0.35, 1, 1)))
    transform_mesh(inner, Matrix.Translation((0, -0.033, 0)))

    def ear_mask(co, n):
        tip = smoothstep(0.15, 0.19, co.z)
        return (1, tip, 0, 1)

    set_colors(ear, ear_mask)
    ear.materials.append(M_FUR)
    inner.materials.append(M_PINK)
    set_colors(inner, lambda co, n: (1, 0, 0, 1))
    ear_full = join_meshes(nm, [(ear, Matrix.Identity(4)), (inner, Matrix.Identity(4))])
    shade_smooth(ear_full)
    eo = new_obj(nm, ear_full, o_head, (H + base_local) - NECK)
    eo.rotation_mode = 'XYZ'
    eo.rotation_euler = (math.radians(-12), math.radians(side * 24), 0)

bpy.data.objects.remove(o_head_tmp)

# ---------------------------------------------------------------- SCARF
SC_C = Vector((0, -0.19, 0.52))
scarf = bpy.data.meshes.new("Scarf")
bm = bmesh.new()
R, r, nU, nV = 0.165, 0.042, 32, 10
verts = []
for i in range(nU):
    u = i / nU * 2 * math.pi
    row = []
    for j in range(nV):
        v = j / nV * 2 * math.pi
        rr = r * (1 + 0.15 * math.sin(u * 3))
        x = (R + rr * math.cos(v)) * math.cos(u)
        y = (R + rr * math.cos(v)) * math.sin(u) * 0.92
        z = rr * math.sin(v) * 1.25
        row.append(bm.verts.new((x, y, z)))
    verts.append(row)
for i in range(nU):
    for j in range(nV):
        a = verts[i][j]; b = verts[(i + 1) % nU][j]; c = verts[(i + 1) % nU][(j + 1) % nV]; d = verts[i][(j + 1) % nV]
        bm.faces.new((a, b, c, d))
# knot at the back
res = bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=0.05)
bmesh.ops.scale(bm, vec=(1.1, 0.9, 1.0), verts=res["verts"])
bmesh.ops.translate(bm, vec=(0, R + 0.02, 0.01), verts=res["verts"])
bm.to_mesh(scarf)
bm.free()
transform_mesh(scarf, Matrix.Rotation(math.radians(25), 4, 'X'))
shade_smooth(scarf)
set_colors(scarf, lambda co, n: (1, 0, 0, 1))
o_scarf = new_obj("Scarf", scarf, o_body, SC_C - BODY_P, M_SCARF)
# scarf tails (flutter)
knot_world = SC_C + (Matrix.Rotation(math.radians(25), 3, 'X') @ Vector((0, R + 0.04, 0.0)))
for side, nm in ((1, "ScarfTailL"), (-1, "ScarfTailR")):
    t = bpy.data.meshes.new(nm)
    bm = bmesh.new()
    segs = 6
    rows = []
    for i in range(segs + 1):
        s = i / segs
        w = 0.05 * (1 - 0.5 * s) + 0.012
        y = 0.20 * s
        z = -0.03 * s
        rows.append([bm.verts.new((-w, y, z + 0.0)), bm.verts.new((w, y, z)),
                     bm.verts.new((w, y, z + 0.018)), bm.verts.new((-w, y, z + 0.018))])
    for i in range(segs):
        a, b = rows[i], rows[i + 1]
        for k in range(4):
            bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
    bm.faces.new(rows[0][::-1])
    bm.faces.new(rows[-1])
    bm.to_mesh(t)
    bm.free()
    shade_smooth(t)
    set_colors(t, lambda co, n: (1, 0, 0, 1))
    so = new_obj(nm, t, o_scarf, knot_world - SC_C, M_SCARF)
    so.rotation_mode = 'XYZ'
    so.rotation_euler = (math.radians(-35), 0, math.radians(side * 18))

# ---------------------------------------------------------------- LEGS
q_vert = Quaternion((0, 1, 0), math.radians(90))  # capsule X axis -> Z
for nm, pos, front in (("LegFL", (0.105, -0.17, 0.30), True), ("LegFR", (-0.105, -0.17, 0.30), True),
                       ("LegBL", (0.12, 0.17, 0.30), False), ("LegBR", (-0.12, 0.17, 0.30), False)):
    P = Vector(pos)
    els = [capsule(P + Vector((0, 0, -0.13)), 0.11, 0.062 if front else 0.066, q_vert),
           ell(P + Vector((0, -0.025, -0.255)), (0.07, 0.085, 0.05))]  # paw
    if not front:
        els.append(ell(P + Vector((0, 0.01, 0.0)), (0.09, 0.1, 0.1)))  # thigh
    else:
        els.append(ball(P + Vector((0, 0.0, 0.0)), 0.075))
    leg = metaball_mesh(nm, els, resolution=0.012)
    leg = finish(leg, 700)

    def leg_mask(co, n):
        white = 1 - smoothstep(0.075, 0.11, co.z)
        stripe = smoothstep(0.35, 0.65, math.sin(co.z * 60 + 1.0)) * smoothstep(0.12, 0.16, co.z) * (1 - smoothstep(0.24, 0.27, co.z))
        return (1, stripe * (1 - white), white, 1)

    set_colors(leg, leg_mask)
    transform_mesh(leg, Matrix.Translation(-P))
    new_obj(nm, leg, o_body, P - BODY_P, M_FUR)

# ---------------------------------------------------------------- TAIL (chain along local +Y)
TAIL_BASE = Vector((0, 0.29, 0.43))
seg_len = [0.11, 0.105, 0.10, 0.10]
rads = [0.052, 0.048, 0.046, 0.046]
q_y = Quaternion((0, 0, 1), math.radians(90))  # capsule X -> Y
parent = o_body
parent_origin = BODY_P
acc = 0.0
total = sum(seg_len)
for i, L in enumerate(seg_len):
    els = [capsule((0, L / 2, 0), L / 2, rads[i], q_y)]
    if i == len(seg_len) - 1:
        els.append(ball((0, L, 0), rads[i] * 1.05))
    seg = metaball_mesh("Tail%d" % (i + 1), els, resolution=0.011)
    seg = finish(seg, 360)
    a0 = acc

    def tail_mask(co, n, a0=a0):
        t = a0 + co.y
        white = smoothstep(total - 0.03, total + 0.02, t)
        stripe = smoothstep(0.2, 0.55, math.sin(t * 46)) * (1 - white)
        return (1, stripe, white, 1)

    set_colors(seg, tail_mask)
    loc = (TAIL_BASE - BODY_P) if i == 0 else Vector((0, seg_len[i - 1], 0))
    o = new_obj("Tail%d" % (i + 1), seg, parent, loc, M_FUR)
    o.rotation_mode = 'XYZ'
    o.rotation_euler = (math.radians(48 if i == 0 else 14), 0, 0)
    parent = o
    acc += L

bpy.context.view_layer.update()
for ob in bpy.data.objects:
    print("OBJ", ob.name, ob.type, tuple(round(c, 3) for c in ob.matrix_world.translation))
export_glb(OUT)
