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
	av.seed_text = m["name"]
	av.fem = hash(m["name"]) % 2 == 0
	av.custom_minimum_size = Vector2(60, 60)
	UI.row_card(parent, m["name"], sub, price if not busy else "Booked", cb if cb.is_valid() else (func(): Router.go("campaign_new", {"media": mid}) if not busy else Callable()), av, UI.GOLD2 if not busy else UI.DIM)
