extends AnimatableBody3D
class_name Tram
## The red nostalgic tram (İstiklal style). A moving platform: ride on its roof.

var a := Vector3.ZERO
var b := Vector3.ZERO
var speed := 3.6
var wait := 1.6
var t := 0.0
var dir := 1
var pause := 0.0
var length := 7.0
var bell_cd := 0.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	var L := length
	var W := 2.3
	var H := 2.6
	var mb := MeshBuilder.new()
	var red := City.lin("c8302b")
	var cream := City.lin("f6ead2")
	var dark := City.lin("2b2a33")
	mb.box(Vector3(0, 0.75, 0), Vector3(L, 1.1, W), red, 0.0, true)
	mb.box(Vector3(0, 1.8, 0), Vector3(L, 1.0, W), cream)
	mb.box(Vector3(0, 2.38, 0), Vector3(L + 0.1, 0.18, W + 0.1), red)
	mb.box(Vector3(0, 2.52, 0), Vector3(L - 0.6, 0.12, W - 0.4), City.lin("8d8f96"))
	mb.box(Vector3(0, 0.15, 0), Vector3(L - 1.0, 0.3, W - 0.3), dark, 0.0, true)
	# windows
	var n := 6
	for i in n:
		var x := -L * 0.5 + L * (i + 0.5) / n
		for side in [-1.0, 1.0]:
			var z: float = side * (W * 0.5 + 0.01)
			var c := Vector3(x, 1.85, z)
			var u := Vector3(1, 0, 0) * (1.0 if side > 0 else -1.0)
			var nn := Vector3(0, 0, side)
			var ww := 0.42
			var hh := 0.32
			mb.quad(c - u * ww - Vector3(0, hh, 0), c + u * ww - Vector3(0, hh, 0), c + u * ww + Vector3(0, hh, 0), c - u * ww + Vector3(0, hh, 0), City.lin("ffd98a") if randf() < 0.5 else City.lin("3a4a63"))
	# front/back lamps
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * (L * 0.5 + 0.02), 1.0, 0), Vector3(0.05, 0.25, 0.25), City.lin("fff3b0"))
	# pantograph
	mb.box(Vector3(0, 3.0, 0), Vector3(0.08, 0.9, 0.08), dark)
	mb.box(Vector3(0, 3.45, 0), Vector3(1.2, 0.06, 0.06), dark)
	var mi := MeshInstance3D.new()
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/toon_solid.gdshader")
	m.set_shader_parameter("use_vertex", 1.0)
	m.set_shader_parameter("gloss", 0.5)
	m.set_shader_parameter("rim_strength", 0.3)
	mi.mesh = mb.commit(null, m)
	add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(L, 2.6, W)
	cs.shape = bs
	cs.position = Vector3(0, 1.3, 0)
	add_child(cs)
	global_position = a
	# number plate
	var lbl := Label3D.new()
	lbl.text = "TAKSİM - TÜNEL"
	lbl.font = UIKit.font(800)
	lbl.font_size = 40
	lbl.modulate = Color("fff0c8")
	lbl.outline_size = 0
	lbl.pixel_size = 0.006
	lbl.position = Vector3(L * 0.5 + 0.06, 2.1, 0)
	lbl.rotation.y = PI * 0.5
	add_child(lbl)


func _physics_process(delta: float) -> void:
	bell_cd -= delta
	if pause > 0.0:
		pause -= delta
		if pause <= 0.0 and bell_cd <= 0.0:
			var p := get_tree().get_first_node_in_group("player") as Node3D
			if p and p.global_position.distance_to(global_position) < 25.0:
				Sfx.play("tram_bell", 1.0, -6.0)
			bell_cd = 3.0
		return
	var L := a.distance_to(b)
	t += dir * speed * delta / max(L, 0.01)
	if t >= 1.0:
		t = 1.0
		dir = -1
		pause = wait
	elif t <= 0.0:
		t = 0.0
		dir = 1
		pause = wait
	var e := t * t * (3.0 - 2.0 * t) * 0.35 + t * 0.65
	global_position = a.lerp(b, e)
