class_name ProductRow
extends RefCounted
## Reusable product list row with bottle thumbnail.

static func add(parent: Control, p: Dictionary, cb: Callable = Callable()) -> PanelContainer:
	var b := G.brand(p["brand"])
	var ev = MarketEngine.product_ev(p)
	var tp := TapPanel.new()
	tp.add_theme_stylebox_override("panel", UI.sb(UI.PANEL, 16, UI.LINE, 1, 12))
	var pid: String = p["id"]
	tp.tapped = cb if cb.is_valid() else func(): Router.go("product_detail", {"id": pid})
	var h := UI.hbox(12)
	tp.add_child(h)
	var bv := BottleView.new().setup(p["bottle"], b.get("name", ""), "", ev.get("profile", PackedFloat32Array()))
	bv.show_label = false
	bv.shadow = false
	bv.custom_minimum_size = Vector2(64, 96)
	h.add_child(bv)
	var v := UI.vbox(3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := UI.lbl(p["name"], 24, UI.CREAM, "semi")
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(t)
	var fmt_name: String = DB.formats[p["fmt"]]["name"]
	v.add_child(UI.lbl("%s · %s · %dml" % [b.get("name", ""), fmt_name, int(p["volume"])], 18, UI.MUTED))
	var tags := UI.hbox(6)
	match p["status"]:
		"dev":
			tags.add_child(UI.pill("In development" if not _ordered(p) else "Production", UI.BLUE))
		"discontinued":
			tags.add_child(UI.pill("Discontinued", UI.DIM))
		_:
			if int(p["inv"]) <= 0:
				tags.add_child(UI.pill("Out of stock", UI.RED))
	for tg in p.get("tags", []).slice(0, 2):
		tags.add_child(UI.pill(str(tg), UI.GOLD))
	if p.get("edition", {}).get("type", "regular") != "regular":
		tags.add_child(UI.pill(str(p["edition"]["type"]).capitalize(), UI.ROSE))
	if p.get("kind", "full") != "full":
		tags.add_child(UI.pill(str(p["kind"]).capitalize(), UI.BLUE))
	v.add_child(tags)
	h.add_child(v)
	var rv := UI.vbox(2)
	var wk: Array = p["wk"]
	var u := int(wk[wk.size() - 1][1]) if not wk.is_empty() else 0
	rv.add_child(UI.lbl(G.group_int(u), 26, UI.GOLD2, "title", HORIZONTAL_ALIGNMENT_RIGHT))
	rv.add_child(UI.lbl("units/wk", 16, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_RIGHT))
	var rt: Dictionary = p["rating"]
	if int(rt["n"]) > 0:
		rv.add_child(UI.lbl("★ %.1f" % (float(rt["sum"]) / float(rt["n"])), 18, UI.GOLD, "semi", HORIZONTAL_ALIGNMENT_RIGHT))
	h.add_child(rv)
	parent.add_child(tp)
	return tp


static func _ordered(p: Dictionary) -> bool:
	for o in G.s["orders"]:
		if o["product"] == p["id"]:
			return true
	return false
