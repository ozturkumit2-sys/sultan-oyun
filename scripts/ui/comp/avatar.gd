class_name Avatar
extends Control
## Illustrated portrait (assets/art/people), chosen deterministically from the person's name.
## kind: "std" (office staff), "lab" (perfumers & chemists in lab coats), "glam" (influencers, celebrities).

const COUNTS := {"std": 18, "lab": 10, "glam": 10}

var seed_text := "x":
	set(v):
		seed_text = v
		queue_redraw()
var fem := false
var kind := "std"
var ring := Color(1, 1, 1, 0.95)
var _mat: ShaderMaterial
static var _shader: Shader


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if _shader == null:
		_shader = load("res://assets/shaders/rounded.gdshader")
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	material = _mat
	resized.connect(queue_redraw)


## Configure from an employee record (portrait set follows the role).
func for_employee(e: Dictionary) -> Avatar:
	seed_text = str(e.get("name", "x"))
	fem = e.get("fem", false)
	kind = kind_for_role(str(e.get("role", "")))
	return self


## Configure for an influencer or celebrity.
func for_media(m: Dictionary) -> Avatar:
	seed_text = str(m.get("name", "x"))
	fem = guess_fem(seed_text)
	kind = "glam"
	return self


static func kind_for_role(role: String) -> String:
	return "lab" if role in ["perfumer", "chemist", "research_manager"] else "std"


## First names come from per-country pools of feminine and masculine names.
static func guess_fem(full_name: String) -> bool:
	var first := full_name.split(" ")[0]
	for pool in DB.names.get("people", {}).values():
		if (pool as Dictionary).get("f", []).has(first):
			return true
		if (pool as Dictionary).get("m", []).has(first):
			return false
	return absi(hash(full_name)) % 2 == 0


static func path_for(nm: String, is_fem: bool, k: String) -> String:
	var n: int = COUNTS.get(k, 18)
	return "res://assets/art/people/%s_%s_%02d.svg" % [k, "f" if is_fem else "m", absi(hash(nm)) % n]


func _draw() -> void:
	var s := minf(size.x, size.y)
	if s <= 2.0:
		return
	var o := (size - Vector2(s, s)) * 0.5
	if _mat != null:
		_mat.set_shader_parameter("rect_size", Vector2(s, s))
		_mat.set_shader_parameter("rect_pos", o)
		_mat.set_shader_parameter("radius", s * 0.5)
	var t := Art.tex(path_for(seed_text, fem, kind))
	if t != null:
		draw_texture_rect(t, Rect2(o, Vector2(s, s)), false)
	else:
		draw_circle(o + Vector2(s, s) * 0.5, s * 0.5, UI.BLUSH)
	if ring.a > 0.0:
		draw_arc(o + Vector2(s, s) * 0.5, s * 0.5 - maxf(1.0, s * 0.02), 0, TAU, 48, ring, maxf(2.0, s * 0.04), true)
