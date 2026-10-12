class_name SceneView
extends Control
## Illustrated scene (SVG art) drawn cover-cropped inside a rounded rectangle, with an optional
## company-name overlay on the scene's sign plaque, a soft bottom fade and caption text.

var scene_name := "lab":
	set(v):
		scene_name = v
		queue_redraw()
var plaque_text := ""
var radius := 26.0
var focus := Vector2(0.5, 0.5)     # which part of the art stays visible when cropping
var fade := 0.0                    # 0..1 strength of the bottom fade for captions
var fade_color := Color("#2a1a24")
var caption := ""
var caption_sub := ""
var _mat: ShaderMaterial
static var _shader: Shader


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _shader == null:
		_shader = load("res://assets/shaders/rounded.gdshader")
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	material = _mat
	resized.connect(queue_redraw)


func _draw() -> void:
	var t := Art.scene(scene_name)
	if _mat != null:
		_mat.set_shader_parameter("rect_size", size)
		_mat.set_shader_parameter("radius", radius)
	if t == null:
		draw_rect(Rect2(Vector2.ZERO, size), UI.BG2)
		return
	var ts := t.get_size()
	var sc := maxf(size.x / ts.x, size.y / ts.y)
	var src_size := size / sc
	var src_pos := (ts - src_size) * focus
	src_pos = src_pos.clamp(Vector2.ZERO, ts - src_size)
	draw_texture_rect_region(t, Rect2(Vector2.ZERO, size), Rect2(src_pos, src_size))
	if plaque_text != "":
		var pr := Art.plaque(scene_name)
		if pr.size.x > 0.0:
			var r := Rect2((pr.position * ts - src_pos) * sc, pr.size * ts * sc)
			_plaque_text(r)
	if fade > 0.0:
		var top := Color(fade_color, 0.0)
		var bot := Color(fade_color, 0.86 * fade)
		var y0 := size.y * 0.42
		draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(size.x, y0), size, Vector2(0, size.y)]), PackedColorArray([top, top, bot, bot]))
	if caption != "":
		var f := UI.font("title")
		var fs := 40
		var cp := Vector2(26, size.y - (60 if caption_sub != "" else 28))
		draw_string(f, cp + Vector2(2, 2), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 52, fs, Color(0.16, 0.05, 0.1, 0.55))
		draw_string(f, cp, caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 52, fs, Color("#fffaf3"))
		if caption_sub != "":
			draw_string(UI.font("medium"), Vector2(29, size.y - 23), caption_sub, HORIZONTAL_ALIGNMENT_LEFT, size.x - 56, 20, Color(0.16, 0.05, 0.1, 0.5))
			draw_string(UI.font("medium"), Vector2(28, size.y - 24), caption_sub, HORIZONTAL_ALIGNMENT_LEFT, size.x - 56, 20, Color("#fbeee6"))


func _plaque_text(r: Rect2) -> void:
	var f := UI.font("title")
	var fs := int(r.size.y * 0.52)
	var w := f.get_string_size(plaque_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	while w > r.size.x * 0.86 and fs > 8:
		fs -= 1
		w = f.get_string_size(plaque_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var asc := f.get_ascent(fs)
	var desc := f.get_descent(fs)
	var pos := Vector2(r.get_center().x - w * 0.5, r.get_center().y + (asc - desc) * 0.5)
	draw_string(f, pos, plaque_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#f3dca0"))
