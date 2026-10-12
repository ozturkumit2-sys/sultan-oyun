class_name Showcase
extends Control
## A perfume presented on the illustrated still-life pedestal (flowers, arch, soft light).
## The bottle stands exactly on the pedestal whatever the crop.

const PEDESTAL := Vector2(0.5, 0.7778)   # pedestal top centre in the still-life art (normalised)

var bottle: BottleView
var bottle_scale := 0.66                 # bottle height relative to the control height
var _scene: SceneView


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(design: Dictionary, brand := "", pname := "", profile := PackedFloat32Array()) -> Showcase:
	_scene = Art.banner("stilllife", 420, "", 26)
	_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scene.focus = Vector2(0.5, 0.75)
	add_child(_scene)
	var gl := Glow.new()
	gl.color = Color("#fffaf2")
	gl.strength = 1.4
	gl.name = "glow"
	add_child(gl)
	bottle = BottleView.new().setup(design, brand, pname, profile)
	bottle.vivid = true
	bottle.shadow = false
	add_child(bottle)
	resized.connect(_layout)
	return self


func _layout() -> void:
	if bottle == null:
		return
	var t := Art.scene("stilllife")
	var ped := Vector2(size.x * 0.5, size.y * 0.8)
	if t != null:
		var ts := t.get_size()
		var sc := maxf(size.x / ts.x, size.y / ts.y)
		var src_size := size / sc
		var src_pos := ((ts - src_size) * _scene.focus).clamp(Vector2.ZERO, ts - src_size)
		ped = (PEDESTAL * ts - src_pos) * sc
	var h := size.y * bottle_scale
	var w := h / 1.62
	# BottleView draws its glass base at ~1.56 of the unit height (out of 1.62)
	bottle.size = Vector2(w * 1.25, h)
	bottle.position = Vector2(ped.x - bottle.size.x * 0.5, ped.y - h * (1.56 / 1.62) + h * 0.01)
	var gl: Control = get_node("glow")
	gl.size = Vector2(h * 0.95, h * 0.95)
	gl.position = Vector2(ped.x - gl.size.x * 0.5, ped.y - h * 0.85)
