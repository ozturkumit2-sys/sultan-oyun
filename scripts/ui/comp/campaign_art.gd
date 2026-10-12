class_name CampaignArt
extends Control
## Campaign / retail-channel illustration with the actual product bottle placed in the artwork's
## lit hero slot (assets/art/campaigns/slots.json). art = campaign type id, or "ch/<name>" for channels.

var art := "social"
var design: Dictionary = {}
var brand_name := ""
var product_name := ""
var profile := PackedFloat32Array()
var radius := 18.0
var focus := Vector2(0.5, 0.5)
var _bv: BottleView
var _mat: ShaderMaterial
static var _shader: Shader
static var _slots := {}


func setup(kind: String, p: Dictionary = {}) -> CampaignArt:
	art = kind
	if not p.is_empty():
		design = p.get("bottle", {})
		brand_name = G.brand(p.get("brand", "")).get("name", "")
		product_name = p.get("name", "")
		profile = MarketEngine.product_ev(p).get("profile", PackedFloat32Array())
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _shader == null:
		_shader = load("res://assets/shaders/rounded.gdshader")
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	material = _mat
	if _slot_rect().size.x > 0.0:
		_bv = BottleView.new()
		var d := design
		if d.is_empty():
			var c := G.pc()
			d = {"shape": absi(hash(art)) % 10, "cap": absi(hash(art + "c")) % 8, "glass": 0, "label": 1, "accent": c.get("color", "#c9a55a"), "tint": "blush"}
			if brand_name == "":
				var bs := G.company_brands(G.pid()) if not c.is_empty() else []
				brand_name = str(bs[0]["name"]) if not bs.is_empty() else "Maison"
		_bv.setup(d, brand_name, product_name, profile)
		_bv.vivid = true
		add_child(_bv)
	resized.connect(_layout)
	_layout()


func _tex() -> Texture2D:
	if art.begins_with("ch/"):
		return Art.tex("res://assets/art/channels/%s.svg" % art.substr(3))
	return Art.tex("res://assets/art/campaigns/%s.svg" % art)


static func _slot_data() -> Dictionary:
	if _slots.is_empty():
		var f := FileAccess.open("res://assets/art/campaigns/slots.json", FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_slots = d
	return _slots


func _slot_rect() -> Rect2:
	var d := _slot_data()
	var s: Array = d.get("slots", {}).get(art, [])
	if s.size() < 4:
		return Rect2()
	var sz: Array = d.get("size", [800, 500])
	return Rect2(float(s[0]) / float(sz[0]), float(s[1]) / float(sz[1]), float(s[2]) / float(sz[0]), float(s[3]) / float(sz[1]))


func _crop() -> Array:
	var t := _tex()
	if t == null:
		return []
	var ts := t.get_size()
	var sc := maxf(size.x / ts.x, size.y / ts.y)
	var src_size := size / sc
	var src_pos := ((ts - src_size) * focus).clamp(Vector2.ZERO, ts - src_size)
	return [t, ts, sc, src_pos, src_size]


func _layout() -> void:
	queue_redraw()
	if _bv == null:
		return
	var cr := _crop()
	if cr.is_empty():
		return
	var sr := _slot_rect()
	var ts: Vector2 = cr[1]
	var sc: float = cr[2]
	var sp: Vector2 = cr[3]
	_bv.position = (sr.position * ts - sp) * sc
	_bv.size = sr.size * ts * sc


func _draw() -> void:
	if _mat != null:
		_mat.set_shader_parameter("rect_size", size)
		_mat.set_shader_parameter("rect_pos", Vector2.ZERO)
		_mat.set_shader_parameter("radius", radius)
	var cr := _crop()
	if cr.is_empty():
		draw_rect(Rect2(Vector2.ZERO, size), UI.BLUSH)
		return
	draw_texture_rect_region(cr[0], Rect2(Vector2.ZERO, size), Rect2(cr[3], cr[4]))
