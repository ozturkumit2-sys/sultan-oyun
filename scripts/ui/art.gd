class_name Art
extends RefCounted
## Access to the game's original illustrations (assets/art): ingredient art, scenes and plaques.

static var _cache := {}
static var _plaques := {}


static func tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = t
	return t


static func ing(id: String) -> Texture2D:
	return tex("res://assets/art/ing/%s.svg" % id)


static func scene(name: String) -> Texture2D:
	return tex("res://assets/art/scenes/%s.svg" % name)


static func hq_scene(tier: int) -> String:
	return "hq%d" % clampi(tier, 1, 4)


## Plaque rectangle in normalized scene coordinates (0..1), or an empty Rect2.
static func plaque(name: String) -> Rect2:
	if _plaques.is_empty():
		var f := FileAccess.open("res://assets/art/scenes/plaques.json", FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_plaques = d
	var p: Array = _plaques.get("plaques", {}).get(name, [])
	if p.size() < 4:
		return Rect2()
	var sz: Array = _plaques.get("size", [1200, 700])
	return Rect2(float(p[0]) / float(sz[0]), float(p[1]) / float(sz[1]), float(p[2]) / float(sz[0]), float(p[3]) / float(sz[1]))


## An illustrated banner: cover-cropped, rounded, optional plaque text and bottom caption.
static func banner(name: String, height := 300.0, plaque_text := "", radius := 26.0) -> SceneView:
	var v := SceneView.new()
	v.scene_name = name
	v.plaque_text = plaque_text
	v.radius = radius
	v.custom_minimum_size = Vector2(0, height)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return v


## Ingredient illustration as a square control.
static func ing_icon(id: String, size := 72.0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = ing(id)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Section hero: a large illustrated banner with a soft fade and a title/subtitle written on the art.
static func hero(parent: Control, scene_name: String, title: String, sub := "", height := 300.0, focus := Vector2(0.5, 0.5), plaque_text := "") -> SceneView:
	var v := banner(scene_name, height, plaque_text, 26.0)
	v.focus = focus
	v.fade = 0.9 if title != "" else 0.0
	v.caption = title
	v.caption_sub = sub
	if parent != null:
		parent.add_child(v)
	return v


## Illustrated activity card: scene thumbnail, title, subtitle and optional red badge.
static func card(scene_name: String, title: String, sub: String, cb: Callable, badge := 0, focus := Vector2(0.5, 0.55), thumb_h := 150.0) -> GradPanel:
	var p := GradPanel.new().colors(Color("#fffdf9"), Color("#f8eee6")).set_pad(10)
	p.tapped = cb
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	p.add_child(v)
	var th := banner(scene_name, thumb_h, "", 16)
	th.focus = focus
	v.add_child(th)
	var tr := UI.hbox(6)
	var t := UI.lbl(title, 22, UI.CREAM, "semi")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tr.add_child(t)
	if badge > 0:
		tr.add_child(UI.pill(str(badge), UI.RED, 15))
	v.add_child(tr)
	if sub != "":
		var s := UI.lbl(sub, 16, UI.MUTED, "medium")
		s.clip_text = true
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(s)
	return p


## Same card, but the thumbnail is an ingredient illustration strip (several materials side by side).
static func ing_card(ids: Array, title: String, sub: String, cb: Callable, tint := Color("#eef3e6")) -> GradPanel:
	var p := GradPanel.new().colors(tint.lerp(Color("#fffdf9"), 0.4), tint).set_pad(10)
	p.tapped = cb
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	p.add_child(v)
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", -18)
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.custom_minimum_size = Vector2(0, 150)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in ids.slice(0, 3):
		strip.add_child(ing_icon(str(id), 96))
	v.add_child(strip)
	var t := UI.lbl(title, 22, UI.CREAM, "semi")
	t.clip_text = true
	v.add_child(t)
	if sub != "":
		var s := UI.lbl(sub, 16, UI.MUTED, "medium")
		s.clip_text = true
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(s)
	return p


## Two-column grid helper for illustrated cards.
static func grid2(parent: Control, cards: Array) -> GridContainer:
	var g := UI.grid(2, 12)
	for c in cards:
		g.add_child(c)
	if parent != null:
		parent.add_child(g)
	return g


## Card with a single illustration (texture path) on a tinted background.
static func tex_card(path: String, title: String, sub: String, cb: Callable, tint := Color("#fbf1e4"), art_h := 150.0, badge := 0) -> GradPanel:
	var p := GradPanel.new().colors(tint.lerp(Color("#fffdf9"), 0.45), tint).set_pad(10)
	p.tapped = cb
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	p.add_child(v)
	var t := TextureRect.new()
	t.texture = tex(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(0, art_h)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	var tr := UI.hbox(6)
	var tl := UI.lbl(title, 22, UI.CREAM, "semi")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.clip_text = true
	tr.add_child(tl)
	if badge > 0:
		tr.add_child(UI.pill(str(badge), UI.RED, 15))
	v.add_child(tr)
	if sub != "":
		var s := UI.lbl(sub, 16, UI.MUTED, "medium")
		s.clip_text = true
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(s)
	return p


## Card showing a few overlapping portraits (team, candidates, rivals' perfumers).
static func people_card(people: Array, title: String, sub: String, cb: Callable, tint := Color("#f6e2e6"), badge := 0, fallback_scene := "office") -> GradPanel:
	var p := GradPanel.new().colors(tint.lerp(Color("#fffdf9"), 0.5), tint).set_pad(10)
	p.tapped = cb
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	p.add_child(v)
	if people.is_empty():
		var th := banner(fallback_scene, 150, "", 16)
		v.add_child(th)
	else:
		var strip := HBoxContainer.new()
		strip.add_theme_constant_override("separation", -26)
		strip.alignment = BoxContainer.ALIGNMENT_CENTER
		strip.custom_minimum_size = Vector2(0, 150)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for e in people.slice(0, 3):
			var av := Avatar.new()
			if e.has("followers"):
				av.for_media(e)
			else:
				av.for_employee(e)
			av.custom_minimum_size = Vector2(98, 98)
			strip.add_child(av)
		v.add_child(strip)
	var tr := UI.hbox(6)
	var t := UI.lbl(title, 22, UI.CREAM, "semi")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tr.add_child(t)
	if badge > 0:
		tr.add_child(UI.pill(str(badge), UI.RED, 15))
	v.add_child(tr)
	if sub != "":
		var s := UI.lbl(sub, 16, UI.MUTED, "medium")
		s.clip_text = true
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(s)
	return p
