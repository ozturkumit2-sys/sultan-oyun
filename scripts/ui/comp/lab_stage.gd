class_name LabStage
extends Control
## The laboratory bench: illustrated lab, a large bottle whose juice takes the colour of the live
## formula, and floating ingredient medallions (sized by their share). New materials are "poured"
## into the bottle and the juice is stirred.

var look: Dictionary = {"shape": 0, "cap": 1, "glass": 0, "label": 0, "accent": "#c9a55a", "tint": "natural"}
var brand_name := ""
var product_name := ""
var bottle: BottleView
var family_lbl: Label
var info_lbl: Label
var _bench: SceneView
var _medals: Array = []      # [{id, node, base: Vector2, phase}]
var _t := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(0, 520)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	_bench = Art.banner("lab", 520, "", 28)
	_bench.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bench.focus = Vector2(0.62, 0.7)
	_bench.fade = 0.35
	_bench.fade_color = Color("#3a2433")
	add_child(_bench)
	var gl := Glow.new()
	gl.color = Color("#fffaf0")
	gl.strength = 1.8
	gl.anchor_left = 1.0
	gl.anchor_right = 1.0
	gl.offset_left = -330
	gl.offset_right = 10
	gl.offset_top = 40
	gl.offset_bottom = 440
	add_child(gl)
	bottle = BottleView.new()
	bottle.vivid = true
	bottle.idle_bubbles = true
	bottle.anchor_left = 1.0
	bottle.anchor_right = 1.0
	bottle.offset_left = -270
	bottle.offset_right = -40
	bottle.offset_top = 70
	bottle.offset_bottom = 470
	bottle.setup(look, brand_name, product_name)
	add_child(bottle)
	# caption panel
	var cap := PanelContainer.new()
	cap.add_theme_stylebox_override("panel", UI.shadowed(UI.sb(Color(1, 0.99, 0.97, 0.9), 18, Color(1, 1, 1, 0.9), 1, 12), 8))
	cap.position = Vector2(16, 16)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cv := UI.vbox(0)
	cap.add_child(cv)
	cv.add_child(UI.lbl("ON THE BENCH", 14, UI.PLUM, "semi"))
	family_lbl = UI.title("Empty flask", 26, UI.CREAM)
	cv.add_child(family_lbl)
	info_lbl = UI.lbl("Add materials to begin", 16, UI.MUTED, "medium")
	cv.add_child(info_lbl)
	add_child(cap)
	tap_bottle()


## Tapping the bottle swirls the juice.
func tap_bottle() -> void:
	var tp := TapPanel.new()
	tp.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	tp.anchor_left = 1.0
	tp.anchor_right = 1.0
	tp.offset_left = -270
	tp.offset_right = -40
	tp.offset_top = 70
	tp.offset_bottom = 470
	tp.tapped = func(): bottle.stir(0.8)
	add_child(tp)


func set_look(lk: Dictionary) -> void:
	for k in lk:
		look[k] = lk[k]
	if bottle != null:
		bottle.design = look
		bottle.queue_redraw()


## Refresh from the editor: items [[id, pct]...], evaluation (may be empty), previously shown ids.
func update_formula(items: Array, ev: Dictionary, prev_ids: Array) -> void:
	if bottle == null:
		return
	var prof: PackedFloat32Array = ev.get("profile", PackedFloat32Array())
	if prof.size() == DB.dims.size():
		bottle.liquid = BottleView.liquid_color(prof)
	bottle.design = look
	bottle.product_name = product_name
	bottle.brand_name = brand_name
	bottle.queue_redraw()
	family_lbl.text = str(ev.get("family", "Empty flask")) if not items.is_empty() else "Empty flask"
	var aromatic := 0
	for it in items:
		if DB.ing(it[0]).get("role", "") == "aromatic":
			aromatic += 1
	info_lbl.text = ("%d materials · %d aromatic" % [items.size(), aromatic]) if not items.is_empty() else "Add materials to begin"
	_rebuild_medals(items, prev_ids)


func _rebuild_medals(items: Array, prev_ids: Array) -> void:
	for m in _medals:
		if is_instance_valid(m["node"]):
			m["node"].queue_free()
	_medals.clear()
	var sorted := items.duplicate()
	sorted.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	var shown := sorted.slice(0, 6)
	var slots := [Vector2(40, 150), Vector2(170, 200), Vector2(46, 290), Vector2(178, 330), Vector2(64, 410), Vector2(196, 444)]
	var poured := 0
	for i in shown.size():
		var id: String = shown[i][0]
		var share := clampf(float(shown[i][1]) / 40.0, 0.0, 1.0)
		var d := 86.0 + 44.0 * share
		var node := _medal(id, d)
		var base: Vector2 = slots[i] - Vector2(d, d) * 0.5 + Vector2(40, 0)
		node.position = base
		add_child(node)
		_medals.append({"id": id, "node": node, "base": base, "phase": float(i) * 1.3})
		if not prev_ids.is_empty() and not prev_ids.has(id):
			_pour(id, base + Vector2(d, d) * 0.5, poured * 0.25)
			poured += 1
	if poured > 0:
		get_tree().create_timer(0.75).timeout.connect(func():
			if is_instance_valid(bottle):
				bottle.stir(1.0))


func _medal(id: String, d: float) -> Control:
	var p := Control.new()
	p.size = Vector2(d, d)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var disc := Panel.new()
	disc.add_theme_stylebox_override("panel", UI.shadowed(UI.sb(Color(1, 0.995, 0.985, 0.9), 999, Color(1, 1, 1, 1), 3, 0), 8, 1.4))
	disc.size = Vector2(d, d) * 0.86
	disc.position = Vector2(d, d) * 0.07
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(disc)
	var ic := Art.ing_icon(id, d)
	ic.size = Vector2(d, d)
	p.add_child(ic)
	return p


## A drop of the new material flies from its medallion into the neck of the bottle.
func _pour(id: String, from: Vector2, delay: float) -> void:
	var drop := Art.ing_icon(id, 64)
	drop.size = Vector2(64, 64)
	drop.position = from - Vector2(32, 32)
	add_child(drop)
	var target := bottle.position + Vector2(bottle.size.x * 0.5 - 32, bottle.size.y * 0.12)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(drop, "position", target, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(drop, "scale", Vector2(0.35, 0.35), 0.6)
	tw.tween_property(drop, "modulate:a", 0.0, 0.15)
	tw.tween_callback(drop.queue_free)


func _process(delta: float) -> void:
	_t += delta
	for m in _medals:
		var n: Control = m["node"]
		if is_instance_valid(n):
			n.position = m["base"] + Vector2(0, sin(_t * 1.4 + float(m["phase"])) * 6.0)
