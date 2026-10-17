extends Node3D
class_name CatVisual
## Instantiates the cat model, applies toon materials for a coat preset and runs
## procedural animation (Astro-style rigid-part toy rig).

const CAT_SCENE := preload("res://assets/models/cat.glb")
const FUR_SHADER := preload("res://shaders/cat_fur.gdshader")
const SOLID_SHADER := preload("res://shaders/toon_solid.gdshader")

const COATS := {
	"tarcin": {"base": Color("e6762c"), "stripe": Color("b04716"), "white": Color("fff4e4")},
	"duman": {"base": Color("9aa3ad"), "stripe": Color("5d6570"), "white": Color("f4f4f2")},
	"pamuk": {"base": Color("fbf7f0"), "stripe": Color("e9dccb"), "white": Color("ffffff")},
	"komur": {"base": Color("34303a"), "stripe": Color("221f27"), "white": Color("f4f0ea")},
	"tekir": {"base": Color("a27a52"), "stripe": Color("4f3622"), "white": Color("f3e6d2")},
	"boncuk": {"base": Color("e9e1d6"), "stripe": Color("b9a48c"), "white": Color("ffffff")},
	"bal": {"base": Color("e8c27a"), "stripe": Color("c99a4c"), "white": Color("fff8ea")},
}

@export var coat := "tarcin"
@export var eye_color := Color("74c043")
@export var show_scarf := true

var model: Node3D
var parts := {}            # name -> Node3D
var rest := {}             # name -> Basis (rest rotation)
var rest_pos := {}         # name -> Vector3
var fur_materials: Array[ShaderMaterial] = []

# animation state (driven by the player / kitten script)
var speed_ratio := 0.0     # 0..1 run speed
var on_floor := true
var vel_y := 0.0
var wall_cling := false
var dash := false
var sitting := false
var excited := 0.0
var t := 0.0
var gait := 0.0
var blink_timer := 2.0
var blink := 0.0
var tail_phase := 0.0
var squash := 0.0          # >0 squash (landing), <0 stretch (jump)
var flip := 0.0            # double-jump flip angle progress 0..1
var ear_twitch := 0.0
var tail_vel := Vector3.ZERO
var tail_offset := Vector3.ZERO
var look_yaw := 0.0
var _flash := 0.0


func _ready() -> void:
	model = CAT_SCENE.instantiate()
	add_child(model)
	_collect(model)
	_apply_materials()
	set_coat(coat)
	for n in parts.keys():
		rest[n] = parts[n].transform.basis
		rest_pos[n] = parts[n].position
	if parts.has("Scarf"):
		parts["Scarf"].visible = show_scarf


func _collect(n: Node) -> void:
	if n is Node3D:
		parts[String(n.name)] = n
	for c in n.get_children():
		_collect(c)


func _mat_for(name: String) -> Material:
	match name:
		"Fur":
			var m := ShaderMaterial.new()
			m.shader = FUR_SHADER
			fur_materials.append(m)
			return m
		"Pink":
			return _solid(Color("f39aa6"))
		"Nose":
			return _solid(Color("e0607a"), 0.6)
		"Dark":
			return _solid(Color("3a2228"))
		"Whisker":
			return _solid(Color("fffaf2"), 0.0, 0.0, 0.25)
		"Eye":
			var e := _solid(Color(1, 1, 1), 0.0, 0.0, 0.22)
			e.set_shader_parameter("use_vertex", 1.0)
			return e
		"Highlight":
			var h := StandardMaterial3D.new()
			h.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			h.albedo_color = Color(1, 1, 1)
			return h
		"Scarf":
			return _solid(Color("d8262f"), 0.0, 0.35)
	return null


func _solid(c: Color, gloss := 0.0, rim := 0.25, emis := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SOLID_SHADER
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("gloss", gloss)
	m.set_shader_parameter("rim_strength", rim)
	m.set_shader_parameter("emission_amount", emis)
	return m


func _apply_materials() -> void:
	for n in parts.values():
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			for i in mi.mesh.get_surface_count():
				var src := mi.mesh.surface_get_material(i)
				var nm := src.resource_name if src else "Fur"
				var m := _mat_for(nm)
				if m:
					mi.set_surface_override_material(i, m)


func set_coat(c: String) -> void:
	coat = c
	var d: Dictionary = COATS.get(c, COATS["tarcin"])
	for m in fur_materials:
		m.set_shader_parameter("base_color", d["base"])
		m.set_shader_parameter("stripe_color", d["stripe"])
		m.set_shader_parameter("white_color", d["white"])


func hit_flash() -> void:
	_flash = 1.0


func trigger_flip() -> void:
	flip = 0.001


func land(impact: float) -> void:
	squash = clamp(impact, 0.0, 1.0)


func jump_stretch() -> void:
	squash = -0.6


func _rot(name: String, euler: Vector3) -> void:
	if parts.has(name):
		parts[name].transform.basis = rest[name] * Basis.from_euler(euler)


func _process(delta: float) -> void:
	t += delta
	if _flash > 0.0:
		_flash = max(0.0, _flash - delta * 5.0)
		for m in fur_materials:
			m.set_shader_parameter("flash", _flash * 0.8)
	# --- blink
	blink_timer -= delta
	if blink_timer <= 0.0:
		blink = 1.0
		blink_timer = randf_range(1.8, 4.5)
	blink = max(0.0, blink - delta * 7.0)
	var eye_s := 1.0 - 0.9 * sin(blink * PI)
	for e in ["EyeL", "EyeR"]:
		if parts.has(e):
			parts[e].transform.basis = rest[e] * Basis.from_scale(Vector3(1.0, eye_s, 1.0))
	# --- gait
	var run := speed_ratio
	var freq: float = lerp(5.0, 13.0, run)
	if on_floor and run > 0.05:
		gait += delta * freq
	else:
		gait = lerp_angle(gait, 0.0, delta * 4.0) if not on_floor else gait
	var sw := sin(gait)
	var cw := cos(gait)
	var amp: float = clamp(run * 1.3, 0.0, 0.95)
	var body_pitch := 0.0
	var body_bob := 0.0
	var head_pitch := 0.0
	var leg_f := Vector2.ZERO   # front legs swing (L, R)
	var leg_b := Vector2.ZERO
	if on_floor:
		if run > 0.05:
			# gallop: front pair and back pair alternate, slight offset L/R
			leg_f = Vector2(sw, sin(gait + 0.5)) * amp
			leg_b = Vector2(-sw, -sin(gait + 0.5)) * amp
			body_pitch = cw * 0.10 * run
			body_bob = abs(sw) * 0.06 * run
			head_pitch = -cw * 0.08 * run
		elif sitting:
			leg_b = Vector2(-1.1, -1.1)
			body_pitch = -0.45
			head_pitch = 0.35
		else:
			body_bob = sin(t * 2.2) * 0.008
	else:
		# airborne pose: rising -> legs tucked forward/back, falling -> stretched down
		var rising: float = clamp(vel_y / 8.0, -1.0, 1.0)
		if wall_cling:
			leg_f = Vector2(-1.2, -1.2)
			leg_b = Vector2(0.6, 0.6)
			body_pitch = -0.9
			head_pitch = 0.5
		elif dash:
			leg_f = Vector2(-1.3, -1.3)
			leg_b = Vector2(1.2, 1.2)
			body_pitch = 0.05
		else:
			leg_f = Vector2(-0.7, -0.6) * max(rising, 0.2) + Vector2(0.3, 0.3) * max(-rising, 0.0)
			leg_b = Vector2(0.8, 0.7) * max(rising, 0.2) - Vector2(0.4, 0.4) * max(-rising, 0.0)
			body_pitch = -0.25 * rising
			head_pitch = 0.15 * rising
	_rot("LegFL", Vector3(leg_f.x, 0, 0))
	_rot("LegFR", Vector3(leg_f.y, 0, 0))
	_rot("LegBL", Vector3(leg_b.x, 0, 0))
	_rot("LegBR", Vector3(leg_b.y, 0, 0))
	# --- squash & stretch + flip on body
	squash = move_toward(squash, 0.0, delta * 3.5)
	var sq := squash
	var sy := 1.0 - 0.28 * sq if sq > 0.0 else 1.0 + 0.25 * -sq
	var sxz := 1.0 + 0.18 * sq if sq > 0.0 else 1.0 - 0.1 * -sq
	var flip_rot := 0.0
	if flip > 0.0:
		flip = min(1.0, flip + delta * 3.2)
		flip_rot = -TAU * ease(flip, -1.6)
		if flip >= 1.0:
			flip = 0.0
	if parts.has("Body"):
		var b: Node3D = parts["Body"]
		b.position = rest_pos["Body"] + Vector3(0, body_bob, 0)
		b.transform.basis = rest["Body"] * Basis.from_euler(Vector3(body_pitch + flip_rot, 0, 0))
	model.scale = Vector3(sxz, sy, sxz)
	# --- head
	var idle_look := sin(t * 0.7) * 0.25 if (on_floor and run < 0.05) else 0.0
	look_yaw = lerp(look_yaw, idle_look, delta * 2.0)
	var head_tilt := sin(t * 1.3) * 0.06 * (1.0 - run)
	_rot("Head", Vector3(head_pitch - body_pitch * 0.6, look_yaw, head_tilt))
	# --- ears (twitch occasionally, flatten when running fast)
	if randf() < delta * 0.4:
		ear_twitch = 1.0
	ear_twitch = max(0.0, ear_twitch - delta * 6.0)
	var ear_back := run * 0.35 + (0.4 if not on_floor and vel_y < -2.0 else 0.0)
	_rot("EarL", Vector3(-ear_back, 0, sin(ear_twitch * PI) * 0.35))
	_rot("EarR", Vector3(-ear_back, 0, 0))
	# --- tail: spring follow + idle sway
	tail_phase += delta * (2.0 + run * 4.0 + excited * 6.0)
	var target := Vector3(0.0, 0.0, 0.0)
	if on_floor:
		target.x = -run * 0.55 + (0.25 if sitting else 0.0)
		target.y = sin(tail_phase) * (0.35 - run * 0.2 + excited * 0.3)
	else:
		target.x = clamp(-vel_y * 0.06, -0.6, 0.5)
		target.y = sin(tail_phase * 2.0) * 0.15
	var force := (target - tail_offset) * 60.0 - tail_vel * 9.0
	tail_vel += force * delta
	tail_offset += tail_vel * delta
	for i in 4:
		var k := float(i + 1)
		var lag := sin(tail_phase - k * 0.7) * (0.35 - run * 0.2 + excited * 0.3) if on_floor else 0.0
		_rot("Tail%d" % (i + 1), Vector3(tail_offset.x * (0.6 if i == 0 else 0.35), (tail_offset.y + lag * 0.3) * 0.5, 0))
	# --- scarf tails flutter
	var fl := sin(t * (8.0 + run * 10.0)) * (0.15 + run * 0.35)
	_rot("ScarfTailL", Vector3(run * 0.9 + clamp(-vel_y * 0.05, -0.4, 0.6) + fl * 0.3, fl * 0.4, 0))
	_rot("ScarfTailR", Vector3(run * 0.9 + clamp(-vel_y * 0.05, -0.4, 0.6) - fl * 0.3, -fl * 0.4, 0))
