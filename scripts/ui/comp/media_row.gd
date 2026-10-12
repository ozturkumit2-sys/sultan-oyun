class_name MediaRow
extends RefCounted

static func add(parent: Control, m: Dictionary, cb: Callable = Callable()) -> void:
	var ct: Dictionary = m.get("contract", {})
	var busy: bool = not ct.is_empty() and int(ct.get("until", 0)) > G.week()
	var who := ""
	if busy:
		who = "with " + G.company(ct["company"]).get("name", "?")
	var foci: Array = []
	var aud: Dictionary = m["aud"]
	var ks: Array = aud.keys()
	ks.sort_custom(func(a, b): return float(aud[a]) > float(aud[b]))
	for k in ks.slice(0, 2):
		foci.append(DB.segments[DB.seg_index[k]]["name"])
	var fol := float(m["followers"])
	var fs := ("%.1fM" % (fol / 1e6)) if fol >= 1e6 else ("%dK" % int(fol / 1e3))
	var sub := "%s %s · %s followers · %s · rep %d · audience: %s" % [m["tier"], ("· " + str(m["handle"])) if m["kind"] == "influencer" else ("· " + str(m["handle"])), fs, ", ".join(m["markets"]), int(float(m["reputation"]) * 100), ", ".join(foci)]
	if busy:
		sub += " · " + who
	var mid: String = m["id"]
	var price := G.money(float(m["fee"])) + ("/4 wks" if m["kind"] == "influencer" else "/wk")
	var av = Avatar.new()
	av.for_media(m)
	av.custom_minimum_size = Vector2(60, 60)
	UI.row_card(parent, m["name"], sub, price if not busy else "Booked", cb if cb.is_valid() else (func(): Router.go("campaign_new", {"media": mid}) if not busy else Callable()), av, UI.GOLD2 if not busy else UI.DIM)


## Portrait card for the 2-column personality gallery.
static func card(m: Dictionary, cb: Callable = Callable()) -> Control:
	var ct: Dictionary = m.get("contract", {})
	var busy: bool = not ct.is_empty() and int(ct.get("until", 0)) > G.week()
	var celeb: bool = m["kind"] == "celebrity"
	var tint := Color("#f6e0ec") if not celeb else Color("#f3e6cc")
	var p := GradPanel.new().colors(tint.lerp(Color("#fffdf9"), 0.5), tint).set_pad(12)
	p.border = Color(UI.GOLD if celeb else UI.ROSE, 0.35)
	var mid: String = m["id"]
	p.tapped = cb if cb.is_valid() else (func(): Router.go("campaign_new", {"media": mid}) if not busy else Callable())
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(4)
	p.add_child(v)
	var av := Avatar.new().for_media(m)
	av.custom_minimum_size = Vector2(150, 150)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av.ring = UI.GOLD if celeb else Color(1, 1, 1, 0.95)
	v.add_child(av)
	var n := UI.lbl(m["name"], 20, UI.CREAM, "semi", HORIZONTAL_ALIGNMENT_CENTER)
	n.clip_text = true
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(n)
	var h := UI.lbl(str(m["handle"]), 15, UI.PLUM if not celeb else UI.GOLD, "medium", HORIZONTAL_ALIGNMENT_CENTER)
	h.clip_text = true
	h.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(h)
	var fol := float(m["followers"])
	var fs := ("%.1fM" % (fol / 1e6)) if fol >= 1e6 else ("%dK" % int(fol / 1e3))
	v.add_child(UI.lbl("%s followers · rep %d" % [fs, int(float(m["reputation"]) * 100)], 15, UI.MUTED, "medium", HORIZONTAL_ALIGNMENT_CENTER))
	var row := UI.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if busy:
		row.add_child(UI.pill("Booked · " + G.company(ct["company"]).get("name", "?"), UI.DIM, 13))
	else:
		row.add_child(UI.pill(G.money(float(m["fee"])) + ("/4 wks" if not celeb else "/wk"), UI.BURGUNDY, 15))
	v.add_child(row)
	return p
