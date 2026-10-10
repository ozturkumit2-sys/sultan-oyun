extends Node
## Geliştirme aracı: /home/claude/tools/mh/out/*.json → res://assets/characters/*.res
## (dışa aktarılan oyuna dahil edilmez; çıktıları dahil edilir)

const SRC := "/home/claude/tools/mh/out/"
const DST := "res://assets/characters/"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var which: Array = args if args.size() > 0 else ["body"]
	for w in which:
		var path: String = SRC + String(w) + ".json"
		if not FileAccess.file_exists(path):
			print("yok: ", path)
			continue
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d.has("bones"):
			_save_rig(d)
		if d.has("meshes"):
			for mn in d["meshes"].keys():
				_save_mesh({"shapes": d["shapes"], "surfaces": d["meshes"][mn]}, String(mn))
		else:
			_save_mesh(d, String(w))
	get_tree().quit()


func _v3(a: Array, i: int) -> Vector3:
	return Vector3(a[i * 3], a[i * 3 + 1], a[i * 3 + 2])


func _save_rig(d: Dictionary) -> void:
	var rig := CharacterRig.new()
	var names: Array = []
	for b in d["bones"]:
		names.append(b["name"])
	for b in d["bones"]:
		rig.bone_names.append(b["name"])
		rig.bone_parents.append(names.find(b["parent"]) if b["parent"] != null else -1)
		var a: Array = b["basis"]
		var bs := Basis(Vector3(a[0], a[1], a[2]), Vector3(a[3], a[4], a[5]), Vector3(a[6], a[7], a[8]))
		var o: Array = b["origin"]
		rig.bone_rest.append(Transform3D(bs, Vector3(o[0], o[1], o[2])))
	for sn in d["shapes"]:
		rig.shape_names.append(sn)
		var arr := PackedVector3Array()
		for dd in d["bone_shape_deltas"][sn]:
			arr.append(Vector3(dd[0], dd[1], dd[2]))
		rig.shape_bone_deltas.append(arr)
		rig.shape_floor_deltas.append(float(d["floor_deltas"][sn]))
	var err := ResourceSaver.save(rig, DST + "rig.tres")
	_write_rig_script(rig)
	print("rig saved ", err, " bones=", rig.bone_names.size(), " shapes=", rig.shape_names.size())


func _save_mesh(d: Dictionary, name: String) -> void:
	# yalnız en az bir yüzeyde verisi olan şekil anahtarlarını taşı (boyut tasarrufu)
	var shape_names: Array = []
	for sn in d["shapes"]:
		for s0 in d["surfaces"]:
			if (s0["shapes"] as Dictionary).has(sn):
				shape_names.append(sn)
				break
	var im := ImporterMesh.new()
	im.set_blend_shape_mode(Mesh.BLEND_SHAPE_MODE_RELATIVE)
	for sn in shape_names:
		im.add_blend_shape(sn)
	var total := 0
	for s in d["surfaces"]:
		var pos: Array = s["positions"]
		var n := pos.size() / 3
		var verts := PackedVector3Array()
		verts.resize(n)
		for i in range(n):
			verts[i] = _v3(pos, i)
		var nor := PackedVector3Array()
		nor.resize(n)
		var na: Array = s["normals"]
		for i in range(n):
			nor[i] = _v3(na, i)
		var uvs := PackedVector2Array()
		if s.has("uvs"):
			uvs.resize(n)
			var ua: Array = s["uvs"]
			for i in range(n):
				uvs[i] = Vector2(ua[i * 2], ua[i * 2 + 1])
		var idx := PackedInt32Array()
		var ia: Array = s["indices"]
		idx.resize(ia.size())
		for i in range(0, ia.size(), 3):
			# MakeHuman saat yönü tersi → Godot saat yönü
			idx[i] = int(ia[i])
			idx[i + 1] = int(ia[i + 2])
			idx[i + 2] = int(ia[i + 1])
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = nor
		if not uvs.is_empty():
			arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = idx
		var has_tan: bool = s.has("tangents")
		var flags := 0
		for ci in [0, 1]:
			var key := "custom%d" % ci
			if s.has(key):
				var ca: Array = s[key]
				# yarım duyarlıklı (8 bayt/köşe): doku konumu için yeterli
				var cb := PackedByteArray()
				cb.resize(ca.size() * 2)
				for i in range(ca.size()):
					cb.encode_half(i * 2, float(ca[i]))
				arrays[Mesh.ARRAY_CUSTOM0 + ci] = cb
				flags |= Mesh.ARRAY_CUSTOM_RGBA_HALF << (Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT + ci * Mesh.ARRAY_FORMAT_CUSTOM_BITS)
		if has_tan:
			var ta: Array = s["tangents"]
			var tan := PackedFloat32Array()
			tan.resize(n * 4)
			for i in range(n * 4):
				tan[i] = float(ta[i])
			arrays[Mesh.ARRAY_TANGENT] = tan
		if s.has("bones"):
			var bo := PackedInt32Array()
			var ba: Array = s["bones"]
			bo.resize(ba.size())
			for i in range(ba.size()):
				bo[i] = int(ba[i])
			var we := PackedFloat32Array()
			var wa: Array = s["weights"]
			we.resize(wa.size())
			for i in range(wa.size()):
				we[i] = float(wa[i])
			arrays[Mesh.ARRAY_BONES] = bo
			arrays[Mesh.ARRAY_WEIGHTS] = we
		var blends := []
		var sh: Dictionary = s["shapes"]
		var shn: Dictionary = {} if OS.get_cmdline_user_args().has("nonorm") else s.get("shape_normals", {})
		# Godot 4 RELATIVE kipte şekil verisi taban üzerine EKLENİR: farkları (delta) veriyoruz
		var zero3 := PackedVector3Array()
		zero3.resize(n)
		for sn in shape_names:
			var bv := zero3.duplicate()
			var bn := zero3.duplicate()
			if sh.has(sn):
				var dv: Array = sh[sn]
				for i in range(n):
					bv[i] = _v3(dv, i)
				if shn.has(sn):
					var dn: Array = shn[sn]
					for i in range(n):
						bn[i] = _v3(dn, i)
			var ba2 := []
			ba2.resize(Mesh.ARRAY_MAX)
			ba2[Mesh.ARRAY_VERTEX] = bv
			ba2[Mesh.ARRAY_NORMAL] = bn
			if has_tan:
				var zt := PackedFloat32Array()
				zt.resize(n * 4)
				ba2[Mesh.ARRAY_TANGENT] = zt
			blends.append(ba2)
		var mat := StandardMaterial3D.new()
		mat.resource_name = s["name"]
		if OS.get_cmdline_user_args().has("compress"):
			flags |= Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, blends, {}, mat, s["name"], flags)
		total += idx.size() / 3
	im.generate_lods(25.0, 60.0, [])
	var mesh := im.get_mesh()
	var err := ResourceSaver.save(mesh, DST + name + ".res", ResourceSaver.FLAG_COMPRESS)
	var lods := []
	for si in range(mesh.get_surface_count()):
		lods.append(mesh.surface_get_name(si))
	print(name, " saved ", err, " surfaces=", mesh.get_surface_count(), " tris=", total, " blend=", mesh.get_blend_shape_count())


## İskeleti düz GDScript koduna yazar (dışa aktarımda özel kaynak dönüşümüne güvenmemek için)
func _f(x: float) -> String:
	return "%.6f" % x


func _write_rig_script(rig: CharacterRig) -> void:
	var L := PackedStringArray()
	L.append("class_name RigData")
	L.append("extends RefCounted")
	L.append("## OTOMATİK ÜRETİLDİ (_dev/charbuild.gd). Elle düzenlemeyin.")
	L.append("")
	var names := []
	for n in rig.bone_names:
		names.append("\"%s\"" % n)
	L.append("const BONE_NAMES := [" + ", ".join(names) + "]")
	var par := []
	for v in rig.bone_parents:
		par.append(str(v))
	L.append("const BONE_PARENTS := [" + ", ".join(par) + "]")
	var rest := []
	for t in rig.bone_rest:
		var b: Basis = t.basis
		rest.append("[" + ", ".join([_f(b.x.x), _f(b.x.y), _f(b.x.z), _f(b.y.x), _f(b.y.y), _f(b.y.z), _f(b.z.x), _f(b.z.y), _f(b.z.z), _f(t.origin.x), _f(t.origin.y), _f(t.origin.z)]) + "]")
	L.append("const BONE_REST := [\n\t" + ",\n\t".join(rest) + "]")
	var sn := []
	for n in rig.shape_names:
		sn.append("\"%s\"" % n)
	L.append("const SHAPE_NAMES := [" + ", ".join(sn) + "]")
	var dl := []
	for d in rig.shape_bone_deltas:
		var vals := []
		for v in d:
			vals += [_f(v.x), _f(v.y), _f(v.z)]
		dl.append("[" + ", ".join(vals) + "]")
	L.append("const SHAPE_BONE_DELTAS := [\n\t" + ",\n\t".join(dl) + "]")
	var fl := []
	for v in rig.shape_floor_deltas:
		fl.append(_f(v))
	L.append("const SHAPE_FLOOR_DELTAS := [" + ", ".join(fl) + "]")
	L.append("")
	L.append("")
	L.append("static func make() -> CharacterRig:")
	L.append("\tvar r := CharacterRig.new()")
	L.append("\tr.bone_names = PackedStringArray(BONE_NAMES)")
	L.append("\tr.bone_parents = PackedInt32Array(BONE_PARENTS)")
	L.append("\tvar rests: Array[Transform3D] = []")
	L.append("\tfor a in BONE_REST:")
	L.append("\t\trests.append(Transform3D(Basis(Vector3(a[0], a[1], a[2]), Vector3(a[3], a[4], a[5]), Vector3(a[6], a[7], a[8])), Vector3(a[9], a[10], a[11])))")
	L.append("\tr.bone_rest = rests")
	L.append("\tr.shape_names = PackedStringArray(SHAPE_NAMES)")
	L.append("\tvar deltas: Array[PackedVector3Array] = []")
	L.append("\tfor a in SHAPE_BONE_DELTAS:")
	L.append("\t\tvar pv := PackedVector3Array()")
	L.append("\t\tfor i in range(0, a.size(), 3):")
	L.append("\t\t\tpv.append(Vector3(a[i], a[i + 1], a[i + 2]))")
	L.append("\t\tdeltas.append(pv)")
	L.append("\tr.shape_bone_deltas = deltas")
	L.append("\tr.shape_floor_deltas = PackedFloat32Array(SHAPE_FLOOR_DELTAS)")
	L.append("\treturn r")
	var f := FileAccess.open("res://scripts/characters/rig_data.gd", FileAccess.WRITE)
	f.store_string("\n".join(L) + "\n")
	f.close()
	print("rig_data.gd yazıldı")
