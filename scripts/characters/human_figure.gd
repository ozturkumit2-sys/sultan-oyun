class_name HumanFigure
extends Node3D
## Gerçekçi insan figürü: MakeHuman (CC0) tabanlı gövde + iskelet + şekil anahtarları.
## look sözlüğü: shapes (şekil -> ağırlık), skin (Color), eye (Color) ...

const RIG_PATH := "res://assets/characters/rig.tres"
const BODY_PATH := "res://assets/characters/body.res"

static var _rig: CharacterRig
static var _body: ArrayMesh
static var _meshes: Dictionary = {}
const CLOTH_SHADER := preload("res://assets/shaders/cloth.gdshader")
const HAIR_SHADER := preload("res://assets/shaders/hair.gdshader")

var pivot: Node3D
var skeleton: Skeleton3D
var anim_player: AnimationPlayer
var anim := "idle"
var speed := 0.0
var _blink_t := 3.0
var _blink_i := -1
var body_mi: MeshInstance3D
var skin_res: Skin
var parts: Array[MeshInstance3D] = []
var shape_w: Dictionary = {}
var rest_global: Array[Transform3D] = []


static var _blob: GradientTexture2D


static func _blob_tex() -> GradientTexture2D:
	if _blob == null:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0.75))
		g.set_color(1, Color(0, 0, 0, 0.0))
		g.add_point(0.45, Color(0, 0, 0, 0.45))
		_blob = GradientTexture2D.new()
		_blob.gradient = g
		_blob.fill = GradientTexture2D.FILL_RADIAL
		_blob.fill_from = Vector2(0.5, 0.5)
		_blob.fill_to = Vector2(1.0, 0.5)
		_blob.width = 64
		_blob.height = 64
	return _blob


static func rig() -> CharacterRig:
	if _rig == null:
		_rig = RigData.make()
	return _rig


## Oyun karakteri verisinden kur
func build_from_char(c: Dictionary, id: String) -> void:
	build(CharacterLooks.for_character(c, id))


## Uzaktaki karakterlerde animasyonu ve göz kırpmayı durdur
func set_lod_active(v: bool) -> void:
	set_process(v)
	if anim_player:
		anim_player.active = v


func build(look: Dictionary) -> void:
	if _body == null:
		_body = load(BODY_PATH)
	var r := rig()
	shape_w = look.get("shapes", {})
	pivot = Node3D.new()
	pivot.name = "Pivot"
	add_child(pivot)
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton"
	pivot.add_child(skeleton)
	rest_global = r.rest_for(shape_w)
	var n := r.bone_names.size()
	for i in range(n):
		skeleton.add_bone(r.bone_names[i])
	for i in range(n):
		skeleton.set_bone_parent(i, r.bone_parents[i])
	for i in range(n):
		var p := r.bone_parents[i]
		var local: Transform3D = rest_global[i] if p < 0 else rest_global[p].affine_inverse() * rest_global[i]
		skeleton.set_bone_rest(i, local)
	skeleton.reset_bone_poses()
	var hs := float(look.get("head_scale", 1.0))
	if hs != 1.0:
		skeleton.set_bone_pose_scale(r.bone_names.find("head"), Vector3.ONE * hs)
	skeleton.position.y = r.floor_offset(shape_w)
	var skin := Skin.new()
	for i in range(n):
		skin.add_named_bind(r.bone_names[i], rest_global[i].affine_inverse())
	body_mi = MeshInstance3D.new()
	body_mi.name = "Body"
	body_mi.mesh = _body
	skeleton.add_child(body_mi)
	body_mi.skin = skin
	body_mi.skeleton = NodePath("..")
	skin_res = skin
	parts.append(body_mi)
	_apply_shapes(body_mi)
	_apply_materials(look)
	for g in look.get("outfit", []):
		_add_garment(g)
	_blink_i = body_mi.find_blend_shape_by_name(&"blink")
	add_to_group("figures")
	set_shadows(Settings.quality >= 1)
	# karakter ağları görsel katman 2: yansıma sondalarına ve yer gölgesine girmesin
	for mi in parts:
		mi.layers = 2
		mi.visibility_range_end = 48.0
		mi.visibility_range_end_margin = 4.0
	# yumuşak yer gölgesi (iç mekânda ayaklar zemine bassın)
	var dc := Decal.new()
	dc.name = "BlobShadow"
	dc.size = Vector3(1.0, 0.8, 1.0)
	dc.position = Vector3(0, 0.3, 0)
	dc.texture_albedo = _blob_tex()
	dc.modulate = Color(0, 0, 0, 0.55)
	dc.albedo_mix = 1.0
	dc.cull_mask = 1
	dc.upper_fade = 0.3
	dc.lower_fade = 0.3
	add_child(dc)
	anim_player = AnimationPlayer.new()
	anim_player.name = "Anim"
	add_child(anim_player)
	anim_player.root_node = NodePath("..")
	anim_player.add_animation_library("", HumanAnims.library())
	anim_player.play("idle")
	anim_player.seek(randf() * 4.0, true)
	var sc := float(look.get("scale", 1.0))
	if sc != 1.0:
		scale = Vector3.ONE * sc


func set_anim(a: String) -> void:
	if a == anim or anim_player == null:
		return
	anim = a
	if anim_player.has_animation(a):
		anim_player.play(a, 0.35)


func _process(delta: float) -> void:
	if anim_player == null:
		return
	if anim == "walk":
		anim_player.speed_scale = clampf(speed / 1.55, 0.7, 2.6)
	else:
		anim_player.speed_scale = 1.0
	# göz kırpma
	_blink_t -= delta
	if _blink_i >= 0:
		if _blink_t < 0.0:
			var k := clampf(1.0 - absf(_blink_t + 0.07) / 0.07, 0.0, 1.0)
			body_mi.set_blend_shape_value(_blink_i, k)
			if _blink_t < -0.14:
				body_mi.set_blend_shape_value(_blink_i, 0.0)
				_blink_t = randf_range(2.0, 5.5)


static func mesh_res(n: String) -> ArrayMesh:
	if not _meshes.has(n):
		_meshes[n] = load("res://assets/characters/%s.res" % n)
	return _meshes[n]


func _apply_shapes(mi: MeshInstance3D) -> void:
	var m: ArrayMesh = mi.mesh
	var have := {}
	for i in range(m.get_blend_shape_count()):
		have[String(m.get_blend_shape_name(i))] = i
	for k in have.keys():
		var v := float(shape_w.get(k, 0.0))
		# giysilerde ayrı "zayıf/kısa" şekli yok: ters yönlü kilo/boy olarak uygula
		if k == "heavy" and not have.has("thin"):
			v -= float(shape_w.get("thin", 0.0))
		if k == "tall" and not have.has("short"):
			v -= float(shape_w.get("short", 0.0))
		if v != 0.0:
			mi.set_blend_shape_value(have[k], v)


func _cloth_mat(col: Color, pat_col: Color, sel: Vector4, scale: float, rough: float, sheen: float, metal: float, lining: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CLOTH_SHADER
	m.set_shader_parameter("patterns", preload("res://assets/characters/fabric_patterns.png"))
	m.set_shader_parameter("weave", preload("res://assets/characters/fabric_weave.png"))
	m.set_shader_parameter("base_color", col)
	m.set_shader_parameter("pattern_color", pat_col)
	m.set_shader_parameter("pattern_sel", sel)
	m.set_shader_parameter("pattern_scale", scale)
	m.set_shader_parameter("roughness", rough)
	m.set_shader_parameter("sheen", sheen)
	m.set_shader_parameter("metallic_pattern", metal)
	m.set_shader_parameter("lining_color", lining)
	return m


## g: {mesh, color, pattern_color, pattern (Vector4), scale, trim, trim_pattern, rough, sheen, metal, lining}
func _add_garment(g: Dictionary) -> void:
	var mesh := mesh_res(String(g["mesh"]))
	if mesh == null:
		return
	var mi := MeshInstance3D.new()
	mi.name = String(g["mesh"])
	mi.mesh = mesh
	skeleton.add_child(mi)
	mi.skin = skin_res
	mi.skeleton = NodePath("..")
	parts.append(mi)
	_apply_shapes(mi)
	var col: Color = g.get("color", Color(0.5, 0.1, 0.1))
	var lining: Color = g.get("lining", col.darkened(0.2))
	var main := _cloth_mat(col, g.get("pattern_color", col.lightened(0.3)), g.get("pattern", Vector4.ZERO),
			float(g.get("scale", 3.0)), float(g.get("rough", 0.72)), float(g.get("sheen", 0.25)), float(g.get("metal", 0.0)), lining)
	var trim_col: Color = g.get("trim", col.darkened(0.3))
	var trim := _cloth_mat(trim_col, g.get("trim_pattern_color", Color(0.85, 0.68, 0.3)), g.get("trim_pattern", Vector4(0, 0, 0, 1)),
			7.0, 0.55, 0.35, 0.8, lining)
	for si in range(mesh.get_surface_count()):
		var sn := mesh.surface_get_name(si)
		if sn.begins_with("trim"):
			mi.set_surface_override_material(si, trim)
		elif sn == "hair" or sn == "beard":
			var hm := ShaderMaterial.new()
			hm.shader = HAIR_SHADER
			hm.set_shader_parameter("hair_color", col)
			hm.set_shader_parameter("strands", preload("res://assets/characters/hair_strands.png"))
			mi.set_surface_override_material(si, hm)
		elif sn == "cap":
			var cc: Color = g.get("cap_color", Color(0.6, 0.1, 0.1))
			mi.set_surface_override_material(si, _cloth_mat(cc, cc.lightened(0.2), Vector4.ZERO, 3.0, 0.8, 0.2, 0.0, cc.darkened(0.4)))
		else:
			mi.set_surface_override_material(si, main)


func _apply_materials(look: Dictionary) -> void:
	for si in range(_body.get_surface_count()):
		var nm := _body.surface_get_name(si)
		var m := StandardMaterial3D.new()
		match nm:
			"skin":
				var sm := ShaderMaterial.new()
				sm.shader = preload("res://assets/shaders/skin.gdshader")
				sm.set_shader_parameter("detail", preload("res://assets/characters/skin_detail.png"))
				sm.set_shader_parameter("masks", preload("res://assets/characters/skin_masks.png"))
				sm.set_shader_parameter("skin_color", look.get("skin", Color(0.82, 0.64, 0.52)))
				sm.set_shader_parameter("hair_color", look.get("hair", Color(0.1, 0.07, 0.05)))
				sm.set_shader_parameter("stubble", float(look.get("stubble", 0.0)))
				sm.set_shader_parameter("scalp_shadow", float(look.get("scalp", 0.0)))
				sm.set_shader_parameter("lip_color", look.get("lip", Color(0.6, 0.32, 0.3)))
				sm.set_shader_parameter("age", float(shape_w.get("old", 0.0)))
				body_mi.set_surface_override_material(si, sm)
				continue
			"shoe":
				m.albedo_color = look.get("shoe", Color(0.55, 0.12, 0.1))
				m.roughness = 0.45
			"eyes":
				m.albedo_texture = load("res://assets/characters/eye_%s.png" % String(look.get("eye", "brown")))
				m.roughness = 0.15
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		body_mi.set_surface_override_material(si, m)


func set_shadows(on: bool) -> void:
	for mi in parts:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Yüzün (gözlerin hemen altı) dünya konumu
func face_position() -> Vector3:
	if skeleton == null:
		return global_position + Vector3(0, 1.6, 0)
	var hi := skeleton.find_bone("head")
	var t := skeleton.global_transform * skeleton.get_bone_global_pose(hi)
	return t.origin + t.basis.y.normalized() * 0.09 * scale.x


func set_shape(name: String, w: float) -> void:
	var bi: int = body_mi.find_blend_shape_by_name(StringName(name))
	if bi >= 0:
		body_mi.set_blend_shape_value(bi, w)
