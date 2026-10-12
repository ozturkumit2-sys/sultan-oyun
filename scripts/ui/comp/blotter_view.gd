class_name BlotterView
extends Control
## The try-out bench: an atomizer, a paper blotter on a stand, the scent rising from the strip
## (coloured by what you smell now) and the materials you notice floating around it.

var liquid := Color("#e9b949")
var strength := 0.0          # 0..1 perceived strength right now
var aura: Array = []         # [[Color, weight]...] top odour families at this moment
var notes: Array = []        # [[id, share 0..1]...] noticeable materials
var sprayed := false
var _bench: SceneView
var bottle: BottleView
var _t := 0.0
var _mist := 0.0             # spray animation 1 → 0
var _medals: Dictionary = {} # id -> TextureRect
var _fx: Control             # strip, scent ribbons and mist are drawn on this layer (above the art)


func _init() -> void:
	custom_minimum_size = Vector2(0, 470)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_bench = Art.banner("lab", 470, "", 26)
	_bench.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bench.focus = Vector2(0.45, 0.78)
	_bench.modulate = Color(1, 1, 1, 0.55)
	add_child(_bench)
	bottle = BottleView.new()
	bottle.vivid = true
	bottle.show_label = false
	bottle.position = Vector2(26, 250)
	bottle.size = Vector2(130, 200)
	add_child(bottle)
	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)
	_fx.draw.connect(_draw_fx)


func set_juice(design: Dictionary, col: Color) -> void:
	liquid = col
	bottle.design = design
	bottle.liquid = col
	bottle.queue_redraw()


func spray() -> void:
	_mist = 1.0
	sprayed = true
	Snd.play("page", -4.0)


func set_notes(n: Array) -> void:
	notes = n
	var keep := {}
	for x in n:
		keep[x[0]] = true
	for id in _medals.keys():
		if not keep.has(id):
			(_medals[id] as Control).queue_free()
			_medals.erase(id)
	for x in n:
		var id: String = x[0]
		if not _medals.has(id):
			var ic := Art.ing_icon(id, 84)
			ic.size = Vector2(84, 84)
			add_child(ic)
			_medals[id] = ic


func _strip_rect() -> Rect2:
	return Rect2(size.x * 0.56, 70, 54, 330)


func _process(delta: float) -> void:
	_t += delta
	_mist = maxf(0.0, _mist - delta * 1.4)
	# medallions orbit gently around the strip, fading with their share
	var sr := _strip_rect()
	var c := sr.get_center() + Vector2(0, -40)
	var i := 0
	for x in notes:
		var id: String = x[0]
		if not _medals.has(id):
			continue
		var n: Control = _medals[id]
		var share := float(x[1])
		var a := float(i) * 1.7 + _t * 0.25
		var rx := 200.0 if i % 2 == 0 else 150.0
		var pos := c + Vector2(cos(a) * rx * 0.55 + 70, sin(a) * 120.0 - 10)
		var sc := 0.65 + 0.6 * share
		n.scale = Vector2(sc, sc)
		n.pivot_offset = n.size * 0.5
		n.position = pos - n.size * 0.5
		n.modulate = Color(1, 1, 1, clampf(0.35 + share * 1.2, 0.0, 1.0) * (1.0 if sprayed else 0.0))
		i += 1
	if _fx != null:
		_fx.queue_redraw()


func _draw_fx() -> void:
	var fx := _fx
	var sr := _strip_rect()
	# soft light pool behind the strip
	for k in 10:
		fx.draw_circle(sr.get_center(), 190.0 - k * 16.0, Color(1, 1, 1, 0.05))
	# rising scent ribbons
	if sprayed and strength > 0.01:
		var top := sr.position + Vector2(sr.size.x * 0.5, 0)
		var n := aura.size()
		for k in n:
			var col: Color = aura[k][0]
			var w := float(aura[k][1])
			var pts := PackedVector2Array()
			var h := 60.0 + 220.0 * strength
			for j in 24:
				var f := float(j) / 23.0
				var x := top.x + sin(_t * 1.6 + f * 6.0 + float(k) * 2.1) * (10.0 + 40.0 * f) * (1.0 + 0.3 * float(k))
				pts.append(Vector2(x + (float(k) - float(n - 1) * 0.5) * 14.0, top.y + 30.0 - f * h))
			fx.draw_polyline(pts, Color(col, (0.25 + 0.5 * strength) * w), 4.0 + 10.0 * w * strength, true)
	# stand
	var base := Rect2(sr.position.x - 40, sr.end.y - 4, sr.size.x + 80, 26)
	fx.draw_rect(base, Color("#b9876a"), true)
	fx.draw_rect(Rect2(base.position, Vector2(base.size.x, 6)), Color("#d9a882"), true)
	fx.draw_rect(Rect2(sr.position.x - 6, sr.end.y - 70, sr.size.x + 12, 70), Color("#c99a78"), true)
	# paper strip with its pointed dipping end at the top (held upside down in the stand)
	var tip := 26.0
	var paper := PackedVector2Array([sr.position + Vector2(sr.size.x * 0.5, 0), sr.position + Vector2(sr.size.x, tip),
		sr.end - Vector2(0, 60), Vector2(sr.position.x, sr.end.y - 60), sr.position + Vector2(0, tip)])
	fx.draw_colored_polygon(paper, Color("#fffdf8"))
	if sprayed:
		var wet_h := sr.size.y * 0.42
		var wet := PackedVector2Array([sr.position + Vector2(sr.size.x * 0.5, 0), sr.position + Vector2(sr.size.x, tip),
			sr.position + Vector2(sr.size.x, wet_h), sr.position + Vector2(0, wet_h), sr.position + Vector2(0, tip)])
		fx.draw_colored_polygon(wet, Color(liquid, 0.12 + 0.55 * strength))
	var ol := paper.duplicate()
	ol.append(paper[0])
	fx.draw_polyline(ol, Color("#d8c8b8"), 2.0, true)
	# spray mist from the atomizer to the strip
	if _mist > 0.0:
		var from := bottle.position + Vector2(bottle.size.x * 0.62, bottle.size.y * 0.08)
		var to := sr.position + Vector2(sr.size.x * 0.5, 60)
		var r := RandomNumberGenerator.new()
		r.seed = 7
		for k in 60:
			var f := clampf((1.0 - _mist) * 1.6 - r.randf() * 0.6, 0.0, 1.0)
			var p := from.lerp(to, f) + Vector2(r.randf_range(-1, 1), r.randf_range(-1, 1)) * (8.0 + 46.0 * f)
			fx.draw_circle(p, 2.0 + 3.0 * r.randf(), Color(liquid.lightened(0.3), 0.6 * _mist))
