"""Builds fish.glb (collectible) and bird.glb (seagull / pigeon, rigid-part rig)."""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import bpy, bmesh
from mathutils import Vector, Matrix, Quaternion
from common import *

OUTDIR = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "/root/cati-kedisi/assets/models"
K = 1.739


def ell(co, size, s=2.0):
    return dict(type="ELLIPSOID", co=co, r=K, size=size, s=s)


def ball(co, rad, s=2.0):
    return dict(type="BALL", co=co, r=rad * K, s=s)


def finish(me, faces, it=1):
    me2 = decimate_mesh(me, faces)
    if me2 is not me:
        bpy.data.meshes.remove(me)
    smooth_mesh(me2, it, 0.35)
    shade_smooth(me2)
    return me2


# =============================================================== FISH (faces -Y)
reset()
M_FISH = get_mat("Fish", (0.6, 0.7, 0.8, 1))
M_EYE = get_mat("Dark", (0.05, 0.05, 0.05, 1))
M_HI = get_mat("Highlight", (1, 1, 1, 1))
root = empty("Fish")
body = metaball_mesh("FishBody", [
    ell((0, 0, 0), (0.09, 0.28, 0.15)),
    ell((0, 0.13, 0), (0.06, 0.16, 0.09)),
], resolution=0.012)
body = finish(body, 900)
# tail fin
fin = bpy.data.meshes.new("Fin")
bm = bmesh.new()
pts = [(0, 0.30, 0.0), (0, 0.48, 0.17), (0, 0.44, 0.0), (0, 0.48, -0.17)]
th = 0.02
top = [bm.verts.new((p[0] + th, p[1], p[2])) for p in pts]
bot = [bm.verts.new((p[0] - th, p[1], p[2])) for p in pts]
bm.faces.new(top)
bm.faces.new(bot[::-1])
for i in range(4):
    j = (i + 1) % 4
    bm.faces.new((top[i], top[j], bot[j], bot[i]))
# dorsal fin
pts2 = [(0, -0.08, 0.12), (0, 0.06, 0.2), (0, 0.14, 0.09)]
t2 = [bm.verts.new((th, p[1], p[2])) for p in pts2]
b2 = [bm.verts.new((-th, p[1], p[2])) for p in pts2]
bm.faces.new(t2)
bm.faces.new(b2[::-1])
for i in range(3):
    j = (i + 1) % 3
    bm.faces.new((t2[i], t2[j], b2[j], b2[i]))
bm.to_mesh(fin)
bm.free()


def fish_mask(co, n):
    # G = darker back, B = light belly
    back = smoothstep(0.02, 0.09, co.z)
    belly = 1 - smoothstep(-0.09, -0.02, co.z)
    return (1, back, belly, 1)


fish = join_meshes("FishMesh", [(body, Matrix.Identity(4)), (fin, Matrix.Identity(4))])
set_colors(fish, fish_mask)
shade_smooth(fish)
fish.materials.clear()
fish.materials.append(M_FISH)
new_obj("FishBody", fish, root, (0, 0, 0))
for side in (1, -1):
    e = uv_sphere("FEye", 1.0, 12, 8, (0.022, 0.03, 0.03))
    shade_smooth(e)
    eo = new_obj("FishEye", e, root, (side * 0.072, -0.17, 0.035), M_EYE)
    h = uv_sphere("FHi", 1.0, 8, 6, (0.008, 0.01, 0.01))
    new_obj("FishHi", h, eo, (side * 0.016, -0.012, 0.012), M_HI)
export_glb(os.path.join(OUTDIR, "fish.glb"))

# =============================================================== BIRD (seagull, faces -Y)
reset()
M_BIRD = get_mat("Bird", (1, 1, 1, 1))
M_BEAK = get_mat("Beak", (1, 0.8, 0.2, 1))
M_EYE = get_mat("Dark", (0.05, 0.05, 0.05, 1))
root = empty("Bird")
B0 = Vector((0, 0, 0.0))
body = metaball_mesh("BirdBody", [
    ell((0, 0.0, 0.0), (0.16, 0.30, 0.15)),
    ell((0, 0.22, 0.03), (0.09, 0.2, 0.06)),   # tail taper
    ball((0, -0.24, 0.12), 0.13),               # head
], resolution=0.012)
body = finish(body, 1400)


def bird_mask(co, n):
    tailtip = smoothstep(0.32, 0.4, co.y)
    return (1, tailtip, 0, 1)


set_colors(body, bird_mask)
body.materials.append(M_BIRD)
beak = cone("Beak", 0.04, 0.005, 0.14, 10)
transform_mesh(beak, Matrix.Rotation(math.radians(90), 4, 'X'))
transform_mesh(beak, Matrix.Translation((0, -0.42, 0.1)))
transform_mesh(beak, Matrix.Diagonal((1, 1, 0.8, 1)))
set_colors(beak, lambda c, n: (1, 0, 0, 1))
beak.materials.append(M_BEAK)
bm_all = join_meshes("BirdMesh", [(body, Matrix.Identity(4)), (beak, Matrix.Identity(4))])
shade_smooth(bm_all)
o_body = new_obj("Body", bm_all, root, (0, 0, 0))
for side in (1, -1):
    e = uv_sphere("BEye", 1.0, 10, 8, (0.022, 0.022, 0.026))
    shade_smooth(e)
    new_obj("Eye", e, o_body, (side * 0.085, -0.31, 0.16), M_EYE)
# wings: flat tapered shapes with pivot at shoulder, extending along +/-X
for side, nm in ((1, "WingL"), (-1, "WingR")):
    w = bpy.data.meshes.new(nm)
    bm = bmesh.new()
    prof = [(0.0, -0.12), (0.22, -0.13), (0.45, -0.06), (0.62, 0.06), (0.45, 0.10), (0.2, 0.14), (0.0, 0.14)]
    th = 0.025
    top = [bm.verts.new((side * p[0], p[1], th * (1 - p[0] / 0.7))) for p in prof]
    bot = [bm.verts.new((side * p[0], p[1], -th * (1 - p[0] / 0.7))) for p in prof]
    f1 = bm.faces.new(top if side > 0 else top[::-1])
    f2 = bm.faces.new(bot[::-1] if side > 0 else bot)
    n = len(prof)
    for i in range(n):
        j = (i + 1) % n
        if side > 0:
            bm.faces.new((top[j], top[i], bot[i], bot[j]))
        else:
            bm.faces.new((top[i], top[j], bot[j], bot[i]))
    bm.normal_update()
    bm.to_mesh(w)
    bm.free()

    def wing_mask(co, n):
        tip = smoothstep(0.42, 0.52, abs(co.x))
        return (1, tip, 0, 1)

    set_colors(w, wing_mask)
    w.materials.append(M_BIRD)
    new_obj(nm, w, o_body, (side * 0.12, -0.02, 0.07))
# feet
for side in (1, -1):
    f = cone("Foot", 0.02, 0.02, 0.1, 6)
    set_colors(f, lambda c, n: (1, 0, 0, 1))
    new_obj("Foot", f, o_body, (side * 0.06, 0.05, -0.17), M_BEAK)
export_glb(os.path.join(OUTDIR, "bird.glb"))
