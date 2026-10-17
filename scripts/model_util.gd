class_name ModelUtil
extends RefCounted
## Bakes glTF part-meshes into single ArrayMeshes with final vertex colours
## (so many copies can be drawn with MultiMesh in one draw call).


## color_fn(material_name: String, mask: Color) -> Color   (returns linear albedo)
## only: optional list of node names to include (empty = all)
static func bake(scene: PackedScene, color_fn: Callable, only: Array = [], exclude: Array = []) -> ArrayMesh:
	var root: Node3D = scene.instantiate()
	var mbld := MeshBuilder.new()
	_walk(root, Transform3D.IDENTITY, mbld, color_fn, only, exclude, root)
	root.free()
	return mbld.commit()


static func _walk(n: Node, parent_xf: Transform3D, mbld: MeshBuilder, color_fn: Callable, only: Array, exclude: Array, root: Node) -> void:
	var xf := parent_xf
	if n is Node3D and n != root:
		xf = parent_xf * (n as Node3D).transform
	if n is MeshInstance3D and (only.is_empty() or String(n.name) in only) and not (String(n.name) in exclude):
		var mesh: Mesh = (n as MeshInstance3D).mesh
		for si in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(si)
			var mat := mesh.surface_get_material(si)
			var mname := mat.resource_name if mat else ""
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var cs = arr[Mesh.ARRAY_COLOR]
			var idx = arr[Mesh.ARRAY_INDEX]
			var nb := xf.basis.inverse().transposed()
			var get_v := func(i: int) -> int:
				return idx[i] if idx != null and idx.size() > 0 else i
			var count: int = idx.size() if idx != null and idx.size() > 0 else vs.size()
			var i := 0
			while i + 2 < count:
				var ids := [get_v.call(i), get_v.call(i + 1), get_v.call(i + 2)]
				for k in 3:
					var vi: int = ids[k]
					var mask := Color(1, 0, 0, 1)
					if cs != null and cs.size() > vi:
						mask = cs[vi]
					mbld.verts.append(xf * vs[vi])
					mbld.normals.append((nb * ns[vi]).normalized())
					mbld.colors.append(color_fn.call(mname, mask))
					mbld.uvs.append(Vector2.ZERO)
				i += 3
	for c in n.get_children():
		_walk(c, xf, mbld, color_fn, only, exclude, root)


## Bakes one node (and its children) in the node's own local space.
static func bake_node(scene: PackedScene, node_name: String, color_fn: Callable) -> ArrayMesh:
	var root: Node3D = scene.instantiate()
	var n := find_node(root, node_name)
	var mbld := MeshBuilder.new()
	_walk(n, Transform3D.IDENTITY, mbld, color_fn, [], [], n)
	root.free()
	return mbld.commit()


## Global (model-space) transform of a node inside a scene.
static func node_xform(scene: PackedScene, node_name: String) -> Transform3D:
	var root: Node3D = scene.instantiate()
	var n: Node3D = find_node(root, node_name)
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != root and cur != null:
		xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	root.free()
	return xf


static func find_node(root: Node, name: String) -> Node:
	if String(root.name) == name:
		return root
	for c in root.get_children():
		var r := find_node(c, name)
		if r:
			return r
	return null
