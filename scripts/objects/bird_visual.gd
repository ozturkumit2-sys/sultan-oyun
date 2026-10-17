extends Node3D
class_name BirdVisual
## Seagull / pigeon visual baked from bird.glb into 3 meshes (body + 2 wings) with flapping.

const BIRD := preload("res://assets/models/bird.glb")
const SOLID := preload("res://shaders/toon_solid.gdshader")

static var _cache := {}

@export var kind := "gull"   # gull | pigeon
var model: Node3D
var wing_l: MeshInstance3D
var wing_r: MeshInstance3D
var rest_l: Basis
var rest_r: Basis
var flap_speed := 9.0
var flap_amp := 0.7
var gliding := false
var t := randf() * 10.0


static func _palette(k: String) -> Dictionary:
	if k == "gull":
		return {"base": Color("f7f4ee"), "tip": Color("4f5763"), "beak": Color("f5b731")}
	return {"base": Color("8e97a8"), "tip": Color("3d4352"), "beak": Color("c98b8b")}


static func _get_meshes(k: String) -> Dictionary:
	if _cache.has(k):
		return _cache[k]
	var pal := _palette(k)
	var cf := func(mname: String, m: Color) -> Color:
		match mname:
			"Beak":
				return pal["beak"].srgb_to_linear()
			"Dark":
				return Color(0.01, 0.01, 0.012)
		var c: Color = pal["base"].lerp(pal["tip"], smoothstep(0.3, 0.6, m.g))
		return c.srgb_to_linear()
	var mat := ShaderMaterial.new()
	mat.shader = SOLID
	mat.set_shader_parameter("use_vertex", 1.0)
	mat.set_shader_parameter("rim_strength", 0.4)
	mat.set_shader_parameter("gloss", 0.2)
	var body := ModelUtil.bake(BIRD, cf, [], ["WingL", "WingR"])
	var wl := ModelUtil.bake_node(BIRD, "WingL", cf)
	var wr := ModelUtil.bake_node(BIRD, "WingR", cf)
	for m in [body, wl, wr]:
		m.surface_set_material(0, mat)
	var d := {"body": body, "wl": wl, "wr": wr, "xl": ModelUtil.node_xform(BIRD, "WingL"), "xr": ModelUtil.node_xform(BIRD, "WingR")}
	_cache[k] = d
	return d


func _ready() -> void:
	var d := _get_meshes(kind)
	model = Node3D.new()
	add_child(model)
	var body := MeshInstance3D.new()
	body.mesh = d["body"]
	model.add_child(body)
	wing_l = MeshInstance3D.new()
	wing_l.mesh = d["wl"]
	wing_l.transform = d["xl"]
	model.add_child(wing_l)
	wing_r = MeshInstance3D.new()
	wing_r.mesh = d["wr"]
	wing_r.transform = d["xr"]
	model.add_child(wing_r)
	rest_l = wing_l.transform.basis
	rest_r = wing_r.transform.basis


func _process(delta: float) -> void:
	t += delta * flap_speed
	var a := sin(t) * flap_amp
	if gliding:
		a = 0.12 + sin(t * 0.25) * 0.05
	wing_l.transform.basis = rest_l * Basis(Vector3(0, 0, 1), a)
	wing_r.transform.basis = rest_r * Basis(Vector3(0, 0, 1), -a)
