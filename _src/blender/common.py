"""Shared helpers for building low-poly stylized assets with bpy (headless)."""
import bpy, bmesh, math
from mathutils import Vector, Matrix, Quaternion


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)


_uid = [0]


def _uname(base):
    _uid[0] += 1
    return "%s%dx" % (base, _uid[0])


def get_mat(name, color=(1, 1, 1, 1)):
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
        m.diffuse_color = color
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = color
            bsdf.inputs["Roughness"].default_value = 0.6
    return m


def metaball_mesh(name, elements, resolution=0.012, threshold=0.6):
    """elements: list of dicts: type, co, r, s, size(x,y,z), rot(quat), neg"""
    base = _uname("MB")
    mb = bpy.data.metaballs.new(base)
    mb.resolution = resolution
    mb.render_resolution = resolution
    mb.threshold = threshold
    obj = bpy.data.objects.new(base, mb)
    bpy.context.scene.collection.objects.link(obj)
    for e in elements:
        el = mb.elements.new(type=e.get("type", "BALL"))
        el.co = Vector(e["co"])
        el.radius = e["r"]
        el.stiffness = e.get("s", 2.0)
        if "size" in e:
            el.size_x, el.size_y, el.size_z = e["size"]
        if "rot" in e:
            el.rotation = e["rot"]
        if e.get("neg"):
            el.use_negative = True
    dg = bpy.context.evaluated_depsgraph_get()
    dg.update()
    ev = obj.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev)
    me.name = name
    bpy.data.objects.remove(obj)
    bpy.data.metaballs.remove(mb)
    return me


def decimate_mesh(me, target_faces):
    if len(me.polygons) <= target_faces:
        return me
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.to_mesh(me)
    bm.free()
    tmp = bpy.data.objects.new(_uname("dec"), me)
    bpy.context.scene.collection.objects.link(tmp)
    mod = tmp.modifiers.new("dec", "DECIMATE")
    mod.ratio = max(0.02, target_faces / float(len(me.polygons)))
    dg = bpy.context.evaluated_depsgraph_get()
    dg.update()
    new_me = bpy.data.meshes.new_from_object(tmp.evaluated_get(dg))
    new_me.name = me.name
    bpy.data.objects.remove(tmp)
    return new_me


def smooth_mesh(me, iterations=2, factor=0.5):
    bm = bmesh.new()
    bm.from_mesh(me)
    for _ in range(iterations):
        bmesh.ops.smooth_vert(bm, verts=bm.verts, factor=factor, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    bm.to_mesh(me)
    bm.free()


def shade_smooth(me, smooth=True):
    for p in me.polygons:
        p.use_smooth = smooth


def mesh_from_bmesh(name, build_fn):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    build_fn(bm)
    bm.to_mesh(me)
    bm.free()
    return me


def uv_sphere(name, radius=1.0, segs=24, rings=16, scale=(1, 1, 1)):
    def b(bm):
        bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=radius)
        bmesh.ops.scale(bm, vec=Vector(scale), verts=bm.verts)
    return mesh_from_bmesh(name, b)


def cone(name, r1, r2, depth, segs=16, cap=True):
    def b(bm):
        bmesh.ops.create_cone(bm, cap_ends=cap, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=depth)
    return mesh_from_bmesh(name, b)


def cylinder(name, r, depth, segs=16):
    return cone(name, r, r, depth, segs)


def box(name, size=(1, 1, 1)):
    def b(bm):
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    return mesh_from_bmesh(name, b)


def transform_mesh(me, mat):
    me.transform(mat)
    me.update()


def set_colors(me, fn, attr="Col"):
    """fn(co: Vector, normal: Vector) -> (r,g,b,a) ; stored per point, linear float."""
    if attr in me.color_attributes:
        me.color_attributes.remove(me.color_attributes[attr])
    ca = me.color_attributes.new(name=attr, type="FLOAT_COLOR", domain="POINT")
    for v in me.vertices:
        c = fn(v.co, v.normal)
        ca.data[v.index].color = c
    me.color_attributes.active_color = ca
    try:
        me.color_attributes.render_color_index = me.color_attributes.active_color_index
    except Exception:
        pass


def new_obj(name, me, parent=None, loc=(0, 0, 0), mat=None):
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    if mat is not None:
        if me is not None:
            me.materials.clear()
            me.materials.append(mat)
    if parent is not None:
        ob.parent = parent
        ob.matrix_parent_inverse = Matrix.Identity(4)
    ob.location = Vector(loc)
    return ob


def empty(name, parent=None, loc=(0, 0, 0)):
    ob = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(ob)
    if parent is not None:
        ob.parent = parent
        ob.matrix_parent_inverse = Matrix.Identity(4)
    ob.location = Vector(loc)
    return ob


def world_pos(ob):
    return ob.matrix_world.translation.copy()


def join_meshes(name, meshes_with_mats):
    """meshes_with_mats: list of (mesh, Matrix) -> one mesh keeping materials."""
    bm = bmesh.new()
    mats = []
    out = bpy.data.meshes.new(name)
    for me, mt in meshes_with_mats:
        tmp = me.copy()
        tmp.transform(mt)
        # remap material indices
        offs = []
        for m in tmp.materials:
            if m not in mats:
                mats.append(m)
            offs.append(mats.index(m))
        for p in tmp.polygons:
            if offs:
                p.material_index = offs[p.material_index]
        bm.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
    bm.to_mesh(out)
    bm.free()
    for m in mats:
        out.materials.append(m)
    if len(out.color_attributes) > 0:
        out.color_attributes.active_color = out.color_attributes[0]
        try:
            out.color_attributes.render_color_index = 0
        except Exception:
            pass
    return out


def export_glb(path, objects=None):
    bpy.context.view_layer.update()
    kwargs = dict(filepath=path, export_format="GLB", export_apply=True, export_yup=True,
                  export_animations=False, export_cameras=False, export_lights=False)
    try:
        bpy.ops.export_scene.gltf(export_vertex_color="ACTIVE", **kwargs)
    except TypeError:
        bpy.ops.export_scene.gltf(export_colors=True, **kwargs)
    print("EXPORTED", path)


def ray_surface(ob, origin, direction):
    """Raycast in world space against object ob. Returns (hit, loc, normal)."""
    mw = ob.matrix_world
    inv = mw.inverted()
    o = inv @ Vector(origin)
    d = (inv.to_3x3() @ Vector(direction)).normalized()
    ok, loc, nor, idx = ob.ray_cast(o, d)
    if not ok:
        return False, None, None
    return True, mw @ loc, (mw.to_3x3() @ nor).normalized()


def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)
