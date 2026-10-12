class_name ProductCard
extends RefCounted
## Portfolio card: large bottle on a pastel backdrop tinted by the perfume's scent profile.

static func make(p: Dictionary, w := 196.0, h := 326.0, cb: Callable = Callable()) -> Control:
	var b := G.brand(p["brand"])
	var ev = MarketEngine.product_ev(p)
	var prof: PackedFloat32Array = ev.get("profile", PackedFloat32Array())
	var tint := UI.scent_tint(prof)
	var card := GradPanel.new().colors(tint[0], tint[1]).set_pad(12)
	card.border = Color(Color(tint[2]).darkened(0.3), 0.22)
	var pid: String = p["id"]
	card.tapped = cb if cb.is_valid() else func(): Router.go("product_detail", {"id": pid})
	card.custom_minimum_size = Vector2(w, h)
	var v := UI.vbox(4)
	card.add_child(v)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, h * 0.6)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(stage)
	var gl := Glow.new()
	gl.color = Color("#ffffff")
	gl.strength = 0.9
	gl.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(gl)
	var bv := BottleView.new().setup(p["bottle"], b.get("name", ""), p["name"], prof)
	bv.vivid = true
	bv.set_anchors_preset(Control.PRESET_FULL_RECT)
	bv.offset_left = 14
	bv.offset_right = -14
	bv.offset_top = 4
	stage.add_child(bv)
	var status := ""
	match p["status"]:
		"dev":
			status = "In development"
		"discontinued":
			status = "Discontinued"
		_:
			if int(p["inv"]) <= 0:
				status = "Out of stock"
	if status != "":
		var pill := UI.pill(status, UI.RED if status == "Out of stock" else UI.BLUE, 14)
		pill.position = Vector2(4, 0)
		stage.add_child(pill)
	var t := UI.lbl(p["name"], 21, UI.CREAM, "title")
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(t)
	var fmt_name: String = DB.formats[p["fmt"]]["name"]
	var sub := UI.lbl("%s · %dml" % [fmt_name, int(p["volume"])], 15, UI.MUTED, "medium")
	sub.clip_text = true
	v.add_child(sub)
	var row := UI.hbox(6)
	var wk: Array = p["wk"]
	var u := int(wk[wk.size() - 1][1]) if not wk.is_empty() else 0
	row.add_child(UI.lbl(G.group_int(u) + "/wk", 18, UI.BURGUNDY, "semi"))
	var sp := UI.spacer(0, 0)
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	var rt: Dictionary = p["rating"]
	if int(rt["n"]) > 0:
		row.add_child(UI.lbl("★ %.1f" % (float(rt["sum"]) / float(rt["n"])), 17, UI.GOLD, "semi"))
	v.add_child(row)
	return card
