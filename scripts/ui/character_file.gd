class_name CharacterFile
extends Sheet
## Personnel file: who they are, mood, stress, relationships, memories, secrets.

signal locate(npc_id: String)

var w: SimWorld
var npc_id := ""
var _live: Dictionary = {}
var _tick := 0.0


func _init() -> void:
	super._init()
	setup_paper("manila", 0.8, "PERSONNEL FILE")


func open_for(world: SimWorld, id: String) -> void:
	w = world
	npc_id = id
	paper.tab_text = Loc.t("ui.personnel_file")
	_build()
	open()


static func opinion_key(a: float, rv: float) -> String:
	if rv > 55.0:
		return "rel.rival"
	if a > 55.0: return "rel.best"
	if a > 28.0: return "rel.friend"
	if a > 6.0: return "rel.ok"
	if a > -15.0: return "rel.neutral"
	if a > -40.0: return "rel.dislike"
	return "rel.enemy"


func _build() -> void:
	clear_body()
	var n: NPC = w.npc(npc_id)
	var sc := Sheet.scroll()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	body.add_child(sc)
	# --- header: polaroid + identity
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	var pol := Portrait.make(w, npc_id, Vector2(168, 196), true, 1.0)
	pol.pivot_offset = Vector2(84, 98)
	pol.rotation_degrees = -3.0
	head.add_child(pol)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(Sheet.label(n.name.to_upper(), 40, "marker", UiKit.NPC_COLOR.get(npc_id, UiKit.INK)))
	info.add_child(Sheet.label("%s · %s" % [n.role_title(), Loc.t("ui.age", {"age": int(n.def.get("age", 30))})], 20, "type"))
	var bio: Array = n.def.get("bio", [])
	info.add_child(Sheet.label(" · ".join(bio), 18, "hand", Color(0.3, 0.3, 0.36)))
	var goal_l := Sheet.label("%s: %s" % [Loc.t("ui.goal"), Loc.t("goal." + n.goal)], 20, "hand", UiKit.BLUE)
	info.add_child(goal_l)
	var doing := Sheet.label("", 20, "hand", Color(0.3, 0.3, 0.36))
	info.add_child(doing)
	_live["doing"] = doing
	head.add_child(info)
	v.add_child(head)
	# --- mood & stress
	var ms := Control.new()
	ms.custom_minimum_size = Vector2(0, 108)
	ms.draw.connect(func():
		var nn: NPC = w.npc(npc_id)
		Hud._mood_face(ms, Vector2(32, 36), 28, nn.mood)
		ms.draw_string(UiKit.font("hand"), Vector2(72, 26), Loc.t("ui.mood") + ":", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.3, 0.3, 0.35))
		ms.draw_string(UiKit.font("marker"), Vector2(140, 28), Loc.t(nn.mood_word()), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UiKit.INK)
		ms.draw_string(UiKit.font("hand"), Vector2(72, 62), Loc.t("ui.stress") + ":", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.3, 0.3, 0.35))
		UiKit.draw_scribble_bar(ms, Rect2(140, 48, ms.size.x - 160, 16), nn.stress / 100.0, UiKit.RED if nn.stress > 60 else Color("f4a261"))
		ms.draw_string(UiKit.font("hand"), Vector2(72, 96), Loc.t("ui.morale") + ":", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.3, 0.3, 0.35))
		UiKit.draw_scribble_bar(ms, Rect2(240, 82, ms.size.x - 260, 16), nn.morale / 100.0, Color("2a9d8f") if nn.morale > 40 else UiKit.RED))
	_live["ms"] = ms
	v.add_child(ms)
	# --- relationships
	v.add_child(_section(Loc.t("ui.relationships")))
	for other in w.order:
		if other == npc_id:
			continue
		v.add_child(_rel_row(n, other))
	# --- ties & plans (things that carry over from day to day)
	v.add_child(_section(Loc.t("ui.bonds")))
	var ties := _ties(n)
	if ties.is_empty():
		v.add_child(Sheet.label(Loc.t("ui.no_bonds"), 20, "type", Color(0.4, 0.4, 0.45)))
	for t in ties:
		v.add_child(Sheet.label("• " + t, 20, "hand", UiKit.INK))
	# --- what they have heard (and how sure they are)
	v.add_child(_section(Loc.t("ui.beliefs")))
	var heard := _heard(n)
	if heard.is_empty():
		v.add_child(Sheet.label(Loc.t("ui.no_beliefs"), 20, "type", Color(0.4, 0.4, 0.45)))
	for hb in heard:
		v.add_child(Sheet.label(hb, 19, "type", UiKit.INK))
	# --- memories
	v.add_child(_section(Loc.t("ui.memories")))
	var mems := n.recent_memories(6)
	if mems.is_empty():
		v.add_child(Sheet.label(Loc.t("ui.no_memories"), 20, "type", Color(0.4, 0.4, 0.45)))
	for m in mems:
		var txt := w.memory_text(m)
		if txt == "":
			continue
		var row := Sheet.label("“%s”  — %s" % [txt, Loc.t("ui.day", {"day": int(m["day"])}).capitalize()], 19, "type", UiKit.INK)
		v.add_child(row)
	# --- secrets
	v.add_child(_section(Loc.t("ui.secrets")))
	var any := false
	for fid in w.fact_defs:
		if w.fact_defs[fid].get("subject", "") != npc_id or not w.fact_exists(fid):
			continue
		any = true
		v.add_child(_secret_row(fid))
	if not any:
		v.add_child(Sheet.label(Loc.t("ui.no_secrets"), 20, "type", Color(0.4, 0.4, 0.45)))
	# --- locate
	var lb := NoteButton.make(Loc.t("ui.locate"), "locate", "sticky", UiKit.sticky("yellow"), Vector2(220, 70))
	lb.font_size = 22
	lb.tilt = -1.5
	lb.disabled = not n.present
	lb.pressed.connect(func():
		locate.emit(npc_id)
		close())
	var cbox := CenterContainer.new()
	cbox.add_child(lb)
	v.add_child(cbox)
	_refresh_live()


func _ties(n: NPC) -> Array:
	var r: Array = []
	for kind in ["romance", "alliance", "feud", "mentor"]:
		for other in w.bonds_of(n.id, kind):
			r.append(Loc.t("bond." + kind, {"name": w.npc(other).name}))
	for p in n.plans:
		var tgt: String = p.get("target", "")
		var nm: String = w.npc(tgt).name if w.npc(tgt) != null else ""
		var key := "plan." + str(p["kind"])
		if Loc.has(key):
			r.append(Loc.t(key, {"name": nm}))
	return r


## Rumours and (already leaked) secrets this person carries around.
func _heard(n: NPC) -> Array:
	var items: Array = []
	for f in n.known:
		var is_rumor: bool = w.dyn_facts.has(f)
		if not is_rumor and not w.discovered.has(f):
			continue   # secrets the player hasn't uncovered stay hidden here too
		if is_rumor and w.fact_subject(f) == n.id:
			continue
		var c := n.certainty(f)
		var tag := Loc.t("ui.sure") if c >= 0.8 else (Loc.t("ui.heard") if c >= 0.5 else Loc.t("ui.not_sure"))
		items.append([float(n.known[f]) + c * 0.1, "“%s” (%s)" % [w.fact_text(f), tag]])
	items.sort_custom(func(a, b): return a[0] > b[0])
	var out: Array = []
	for i in mini(5, items.size()):
		out.append(items[i][1])
	return out


func _section(t: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 40)
	c.draw.connect(func():
		c.draw_string(UiKit.font("marker"), Vector2(4, 30), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UiKit.INK)
		c.draw_line(Vector2(4, 36), Vector2(c.size.x - 4, 36), Color(0.2, 0.2, 0.3, 0.35), 1.5))
	return c


func _rel_row(n: NPC, other: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var p := Portrait.make(w, other, Vector2(52, 52), false, 1.15)
	h.add_child(p)
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 56)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.draw.connect(func():
		var nn: NPC = w.npc(npc_id)
		var on: NPC = w.npc(other)
		var tr := nn.get_rel(other, "trust")
		var fr := nn.get_rel(other, "friendship")
		var rv := nn.get_rel(other, "rivalry")
		c.draw_string(UiKit.font("hand"), Vector2(0, 22), on.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UiKit.INK)
		var op := Loc.t(opinion_key(nn.affinity(other), rv))
		c.draw_string(UiKit.font("hand"), Vector2(0, 46), op, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.35, 0.35, 0.4))
		var bx := 128.0
		var bw := (c.size.x - bx - 6) / 3.0 - 8
		var labels := [Loc.t("ui.friendship"), Loc.t("ui.trust"), Loc.t("ui.rivalry")]
		var vals := [(fr + 100) / 200.0, (tr + 100) / 200.0, rv / 100.0]
		var cols := [Color("e0608a"), Color("2b6cb0"), Color("e76f51")]
		for i in 3:
			var x: float = bx + i * (bw + 8)
			c.draw_string(UiKit.font("hand"), Vector2(x, 20), labels[i], HORIZONTAL_ALIGNMENT_LEFT, bw, 15, Color(0.35, 0.35, 0.4))
			UiKit.draw_scribble_bar(c, Rect2(x, 28, bw, 12), vals[i], cols[i]))
	h.add_child(c)
	return h


func _secret_row(fid: String) -> Control:
	var known: bool = w.discovered.has(fid)
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 54)
	c.draw.connect(func():
		if known:
			c.draw_multiline_string(UiKit.font("type"), Vector2(6, 22), w.fact_text(fid), HORIZONTAL_ALIGNMENT_LEFT, c.size.x - 140, 18, 2, UiKit.INK)
			# rubber stamp
			c.draw_set_transform(Vector2(c.size.x - 70, 26), -0.2, Vector2.ONE)
			c.draw_rect(Rect2(-58, -16, 116, 32), UiKit.RED, false, 3.0)
			c.draw_string(UiKit.font("slab"), Vector2(-58, 8), "LEAKED", HORIZONTAL_ALIGNMENT_CENTER, 116, 20, UiKit.RED)
			c.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		else:
			c.draw_rect(Rect2(6, 10, c.size.x * 0.62, 14), Color("1d1d22"))
			c.draw_rect(Rect2(6, 30, c.size.x * 0.4, 14), Color("1d1d22"))
			c.draw_set_transform(Vector2(c.size.x - 90, 26), 0.12, Vector2.ONE)
			c.draw_rect(Rect2(-80, -16, 160, 32), UiKit.RED, false, 3.0)
			c.draw_string(UiKit.font("slab"), Vector2(-80, 8), Loc.t("ui.classified"), HORIZONTAL_ALIGNMENT_CENTER, 160, 20, UiKit.RED)
			c.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE))
	return c


func _refresh_live() -> void:
	if w == null or not _live.has("doing"):
		return
	var n: NPC = w.npc(npc_id)
	var doing: Label = _live["doing"]
	var d: String = Loc.t("doing." + n.act) if n.present else Loc.t("ui.not_in_office")
	doing.text = "%s: %s" % [Loc.t("ui.doing"), d]
	(_live["ms"] as Control).queue_redraw()


func _process(delta: float) -> void:
	if not is_open:
		return
	_tick += delta
	if _tick > 0.5:
		_tick = 0.0
		_refresh_live()
