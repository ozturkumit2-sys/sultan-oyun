extends Screen
## Scent bar: spray any perfume on a paper blotter and follow it hour by hour — which materials you
## notice, how strong it is, how its character shifts from the opening to the dry-down.
## Uses the same evaporation model as the formula engine (on paper, which holds scent longer than skin).

const T_MAX := 36.0
const NOTE_COL := {"top": "#e3a857", "heart": "#d97a96", "base": "#a67c52"}

var sel := {}
var mats: Array = []
var s := 0.0
var playing := false
var view: BlotterView
var tl: ScentTimeline
var time_lbl: Label
var phase_lbl: Label
var strength_lbl: Label
var desc_lbl: Label
var slider: HSlider
var radar: Radar
var _rows: Array = []        # reusable "what you smell" rows


func page_title() -> String:
	return "Scent bar"


func env() -> String:
	return "lab"


func setup(p: Dictionary) -> void:
	params = p
	_select_initial(p)
	_make()
	build()
	set_process(false)


# ---------------------------------------------------------------- choosing what to try
func _select_initial(p: Dictionary) -> void:
	if p.has("items") and not (p["items"] as Array).is_empty():
		var ev := FormulaEngine.evaluate(p["items"], p.get("fmt", "edp"), float(p.get("conc", 18.0)))
		var lk: Dictionary = p.get("look", {})
		sel = {"name": str(p.get("name", "Your draft")), "items": p["items"], "fmt": p.get("fmt", "edp"), "conc": float(p.get("conc", 18.0)),
			"design": _design(lk), "liquid": _liquid(lk, ev), "source": "Your draft"}
	elif p.has("product"):
		_sel_product(G.product(p["product"]))
	elif p.has("fid"):
		_sel_formula(G.formula(p["fid"]))
	else:
		var fs := _own_formulas()
		if not fs.is_empty():
			_sel_formula(fs[0])
		else:
			var mk := _market()
			if not mk.is_empty():
				_sel_product(mk[0])
	if not sel.is_empty():
		mats = FormulaEngine.blotter_mats(sel["items"], sel["fmt"], float(sel["conc"]))


func _design(lk: Dictionary) -> Dictionary:
	var d := {"shape": 6, "cap": 1, "glass": 0, "label": 0, "accent": "#c9a55a", "tint": "natural"}
	for k in lk:
		d[k] = lk[k]
	return d


func _liquid(lk: Dictionary, ev: Dictionary) -> Color:
	var nat := BottleView.liquid_color(ev.get("profile", PackedFloat32Array())) if (ev.get("profile", PackedFloat32Array()) as PackedFloat32Array).size() == DB.dims.size() else Color("#e9b949")
	return BottleView.tint_for(lk, nat)


func _sel_formula(f: Dictionary) -> void:
	if f.is_empty():
		return
	var fv: Dictionary = f["versions"][f["versions"].size() - 1]
	var ev := FormulaEngine.evaluate(fv["items"], f.get("fmt", "edp"), float(f.get("conc", 18.0)))
	var lk: Dictionary = f.get("look", {})
	sel = {"name": f["name"], "items": fv["items"], "fmt": f.get("fmt", "edp"), "conc": float(f.get("conc", 18.0)), "design": _design(lk),
		"liquid": _liquid(lk, ev), "source": "Your formula · v%d" % f["versions"].size()}


func _sel_product(p: Dictionary) -> void:
	if p.is_empty():
		return
	var fv := G.formula_version(p["formula"], int(p.get("fv", -1)))
	if fv.is_empty():
		return
	var ev := FormulaEngine.evaluate(fv["items"], p["fmt"], float(p["conc"]))
	var d: Dictionary = p["bottle"]
	sel = {"name": p["name"], "items": fv["items"], "fmt": p["fmt"], "conc": float(p["conc"]), "design": d,
		"liquid": _liquid(d, ev), "source": "%s · %s" % [G.brand(p["brand"]).get("name", ""), DB.formats[p["fmt"]]["name"]]}


func _own_formulas() -> Array:
	var fs: Array = G.s["formulas"].values().filter(func(f): return f["company"] == G.pid() and not f.get("accord", false) and not f.get("archived", false))
	fs.sort_custom(func(a, b): return int(a["versions"][a["versions"].size() - 1]["w"]) > int(b["versions"][b["versions"].size() - 1]["w"]))
	return fs


func _market() -> Array:
	var ps: Array = G.s["products"].values().filter(func(p): return p["status"] == "active" and p["company"] != G.pid())
	ps.sort_custom(func(a, b): return _units(a) > _units(b))
	return ps.slice(0, 8)


func _units(p: Dictionary) -> float:
	var wk: Array = p["wk"]
	return float(wk[wk.size() - 1][1]) if not wk.is_empty() else float(p.get("st", {}).get("rev", 0.0)) * 0.0001


func _choose(kind: String, id: String) -> void:
	if kind == "f":
		_sel_formula(G.formula(id))
	else:
		_sel_product(G.product(id))
	mats = FormulaEngine.blotter_mats(sel["items"], sel["fmt"], float(sel["conc"]))
	s = 0.0
	playing = false
	rebuild()
	if scroll != null:
		scroll.scroll_vertical = 0
	_spray()


# ---------------------------------------------------------------- layout
func build() -> void:
	_rows.clear()
	if sel.is_empty():
		Art.hero(body, "lab", "Scent bar", "Compose a formula first — then try it here", 280, Vector2(0.45, 0.75))
		body.add_child(UI.btn("Compose a formula", func(): Router.go("formula_editor", {}), "primary", 22, 76))
		return
	var head := UI.hbox(10)
	var hv := UI.vbox(0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UI.lbl("NOW ON THE BLOTTER", 15, UI.PLUM, "semi"))
	var nm := UI.title(str(sel["name"]), 32, UI.CREAM)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hv.add_child(nm)
	hv.add_child(UI.lbl(str(sel["source"]), 16, UI.MUTED, "medium"))
	head.add_child(hv)
	body.add_child(head)
	view = BlotterView.new()
	body.add_child(view)
	view.set_juice(sel["design"], sel["liquid"])
	# time controls
	var tc := GradPanel.new().colors(Color("#fffdf9"), Color("#f4ecf6")).set_pad(16)
	body.add_child(tc)
	var tv := UI.vbox(10)
	tc.add_child(tv)
	var tr := UI.hbox(10)
	time_lbl = UI.title("", 28, UI.BURGUNDY)
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tr.add_child(time_lbl)
	phase_lbl = UI.lbl("", 17, UI.PLUM, "semi")
	tr.add_child(phase_lbl)
	tv.add_child(tr)
	strength_lbl = UI.lbl("", 18, UI.MUTED, "medium")
	tv.add_child(strength_lbl)
	slider = UI.slider(0.0, 1.0, 0.001, s, func(v):
		s = v
		playing = false
		_update_time())
	tv.add_child(slider)
	var br := UI.hbox(10)
	br.add_child(UI.btn("Spray & follow ▶", func(): _spray(), "primary", 21, 66))
	br.add_child(UI.btn("Pause", func(): playing = false, "secondary", 21, 66))
	tv.add_child(br)
	tl = ScentTimeline.new()
	tl.t_max = T_MAX
	tl.col = Color(sel["liquid"]).darkened(0.25)
	tv.add_child(tl)
	tl.set_mats(mats)
	# what you smell now
	UI.section(body, "What you smell now")
	var sc := GradPanel.new().colors(Color("#fffdf9"), Color("#f8efe6")).set_pad(14)
	body.add_child(sc)
	var sv := UI.vbox(8)
	sc.add_child(sv)
	desc_lbl = UI.lbl("", 20, UI.CREAM, "title", HORIZONTAL_ALIGNMENT_LEFT, true)
	sv.add_child(desc_lbl)
	for i in 5:
		var row := UI.hbox(10)
		var ic := TextureRect.new()
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(64, 64)
		row.add_child(ic)
		var cv := UI.vbox(2)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nl := UI.lbl("", 19, UI.CREAM, "semi")
		cv.add_child(nl)
		var bar := MeterBar.new()
		bar.custom_minimum_size = Vector2(40, 10)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.bg = Color(0.45, 0.28, 0.33, 0.1)
		cv.add_child(bar)
		row.add_child(cv)
		var pl := UI.lbl("", 15, UI.MUTED, "semi", HORIZONTAL_ALIGNMENT_RIGHT)
		pl.custom_minimum_size.x = 92
		row.add_child(pl)
		sv.add_child(row)
		_rows.append({"row": row, "icon": ic, "name": nl, "bar": bar, "tag": pl})
	UI.section(body, "Character right now")
	var rc := UI.card(body)
	radar = Radar.new()
	radar.custom_minimum_size = Vector2(0, 330)
	rc.add_child(radar)
	_try_others()
	body.add_child(UI.para("A paper blotter holds a scent longer than skin. Longevity and projection on skin are measured in Technical tests.", 16, UI.DIM))
	_update_time()


func _try_others() -> void:
	UI.section(body, "Try something else")
	var sc := DragScroll.new()
	sc.horizontal = true
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc.custom_minimum_size = Vector2(0, 250)
	var row := UI.hbox(12)
	sc.add_child(row)
	for f in _own_formulas().slice(0, 10):
		var fv: Dictionary = f["versions"][f["versions"].size() - 1]
		var ev := FormulaEngine.evaluate(fv["items"], f.get("fmt", "edp"), float(f.get("conc", 18.0)))
		var lk: Dictionary = f.get("look", {})
		var fid: String = f["id"]
		row.add_child(_pick_card(f["name"], "Yours", _design(lk), _liquid(lk, ev), func(): _choose("f", fid)))
	for p in _market():
		var fv2 := G.formula_version(p["formula"], int(p.get("fv", -1)))
		if fv2.is_empty():
			continue
		var ev2 := FormulaEngine.evaluate(fv2["items"], p["fmt"], float(p["conc"]))
		var pid: String = p["id"]
		row.add_child(_pick_card(p["name"], G.company(p["company"]).get("name", ""), p["bottle"], _liquid(p["bottle"], ev2), func(): _choose("p", pid)))
	body.add_child(sc)


func _pick_card(title: String, sub: String, design: Dictionary, col: Color, cb: Callable) -> Control:
	var p := GradPanel.new().colors(col.lerp(Color("#fffdf9"), 0.8), col.lerp(Color("#f6ece4"), 0.6)).set_pad(10)
	p.custom_minimum_size = Vector2(160, 236)
	p.tapped = cb
	var v := UI.vbox(4)
	p.add_child(v)
	var bv := BottleView.new().setup(design, "", "")
	bv.liquid = col
	bv.show_label = false
	bv.vivid = true
	bv.custom_minimum_size = Vector2(0, 150)
	v.add_child(bv)
	var t := UI.lbl(title, 18, UI.CREAM, "title")
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(t)
	var sl := UI.lbl(sub, 14, UI.MUTED, "medium")
	sl.clip_text = true
	sl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(sl)
	return p


# ---------------------------------------------------------------- time
func _spray() -> void:
	if view == null:
		return
	s = 0.0
	view.spray()
	playing = true
	set_process(true)
	_update_time()


func _process(delta: float) -> void:
	if not playing:
		set_process(false)
		return
	s = minf(1.0, s + delta / 16.0)
	if s >= 1.0:
		playing = false
	if slider != null:
		slider.set_value_no_signal(s)
	_update_time()


func _t() -> float:
	return T_MAX * pow(s, 2.2)


func _update_time() -> void:
	if view == null or time_lbl == null:
		return
	var t := _t()
	if slider != null:
		slider.set_value_no_signal(s)
	var b := FormulaEngine.blotter_at(mats, t)
	var tot := float(b["total"])
	var thr := float(b["detect"])
	var strength := clampf(log(tot / thr) / log(40.0), 0.0, 1.0) if tot > thr else 0.0
	view.strength = strength if view.sprayed else 0.0
	var prof: PackedFloat32Array = b["profile"]
	var idx: Array = []
	for i in prof.size():
		idx.append(i)
	idx.sort_custom(func(a, c): return prof[a] > prof[c])
	var aura: Array = []
	var top_w := maxf(0.001, prof[idx[0]]) if not idx.is_empty() else 1.0
	for k in mini(3, idx.size()):
		if prof[idx[k]] > 0.05:
			aura.append([UI.dim_color(DB.dims[idx[k]]), prof[idx[k]] / top_w])
	view.aura = aura
	# noticeable materials
	var per: Array = b["per"]
	var notes: Array = []
	for x in per:
		var ou := float(x[1])
		var share := ou / maxf(0.0001, tot)
		if ou >= thr * 0.3 and share >= 0.05 and tot > thr:
			notes.append([x[0], share, ou])
	view.set_notes(notes.slice(0, 4) if view.sprayed else [])
	# labels
	time_lbl.text = _time_text(t)
	phase_lbl.text = _phase(per, tot, thr, t)
	strength_lbl.text = _strength_text(tot, thr) if view.sprayed else "Spray the blotter to begin"
	desc_lbl.text = _describe(prof, idx, tot, thr) if view.sprayed else "Spray to smell it."
	for i in _rows.size():
		var r: Dictionary = _rows[i]
		var on: bool = view.sprayed and i < notes.size()
		(r["row"] as Control).visible = on
		if not on:
			continue
		var id: String = notes[i][0]
		var rec := DB.ing(id)
		(r["icon"] as TextureRect).texture = Art.ing(id)
		(r["name"] as Label).text = FormulaEngine.short_name(rec)
		var bar: MeterBar = r["bar"]
		bar.value = clampf(float(notes[i][1]) * 1.6, 0.05, 1.0)
		var note: String = rec.get("note", "base")
		bar.color = Color(NOTE_COL.get(note, "#a67c52"))
		bar.queue_redraw()
		(r["tag"] as Label).text = "%s · %d%%" % [note.capitalize(), int(round(float(notes[i][1]) * 100.0))]
	if radar != null:
		radar.set_profiles([[prof, Color(sel["liquid"]).darkened(0.2)]] if view.sprayed and tot > thr else [])
	if tl != null:
		tl.t_now = t
		tl.queue_redraw()


func _time_text(t: float) -> String:
	if t < 1.0 / 60.0:
		return "Just sprayed"
	if t < 1.0:
		return "%d min after spraying" % int(round(t * 60.0))
	if t < 6.0:
		return "%dh %02d min" % [int(t), int(round((t - floorf(t)) * 60.0)) % 60]
	return "%d hours later" % int(round(t))


func _phase(per: Array, tot: float, thr: float, t: float) -> String:
	if tot < thr:
		return "Gone"
	if tot < thr * 3.0:
		return "Fading"
	var w := {"top": 0.0, "heart": 0.0, "base": 0.0}
	for x in per:
		var note: String = DB.ing(x[0]).get("note", "base")
		if w.has(note):
			w[note] = float(w[note]) + float(x[1])
	if t < 0.5 or (float(w["top"]) >= float(w["heart"]) and float(w["top"]) >= float(w["base"]) and t < 2.0):
		return "Opening · top notes"
	if float(w["heart"]) >= float(w["base"]):
		return "Heart"
	return "Dry-down · base notes"


func _strength_text(tot: float, thr: float) -> String:
	var r := tot / thr
	if r >= 40.0:
		return "Very strong — fills the room"
	if r >= 12.0:
		return "Strong and clear"
	if r >= 4.0:
		return "Moderate, close to the strip"
	if r >= 1.0:
		return "Soft — you have to bring it to your nose"
	return "Nothing left on the strip"


const DESCR := {"citrus": "sparkling citrus", "aromatic": "herbal freshness", "green": "green leaves", "aquatic": "a watery freshness",
	"floral": "flowers", "fruity": "juicy fruit", "gourmand": "sweet gourmand notes", "spicy": "spice", "woody": "woods",
	"amber": "warm amber", "musk": "soft musk", "powdery": "powder", "animalic": "a sensual animalic edge"}


func _describe(prof: PackedFloat32Array, idx: Array, tot: float, thr: float) -> String:
	if tot < thr or idx.is_empty():
		return "The strip is almost odourless now."
	var a := str(DESCR.get(DB.dims[idx[0]], DB.dims[idx[0]]))
	var txt := a.substr(0, 1).to_upper() + a.substr(1)
	if idx.size() > 1 and prof[idx[1]] > prof[idx[0]] * 0.45:
		txt += " with " + str(DESCR.get(DB.dims[idx[1]], DB.dims[idx[1]]))
	if idx.size() > 2 and prof[idx[2]] > prof[idx[0]] * 0.3:
		txt += " and a touch of " + str(DESCR.get(DB.dims[idx[2]], DB.dims[idx[2]]))
	return txt + "."
