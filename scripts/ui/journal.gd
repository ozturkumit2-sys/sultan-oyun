class_name DiscoveryJournal
extends Sheet
## The Discovery Journal: a leather field notebook of everything the player has
## found out about the office — which meddles they've discovered (and how many are
## still out there), special moments, finished stories and their alternative
## endings, and the biggest chain reaction so far. No tasks, just curiosity.

const PAGES := ["meddles", "stories", "moments", "records"]
const PAGE_ICON := {"meddles": "key", "stories": "book", "moments": "star", "records": "pin"}
const CAT_ORDER := "ABCDEFGHIJ"
const INK_GREEN := Color("2f4a3a")

var w: SimWorld
var page := "meddles"
var cat := ""            # category opened on the meddles page ("" = overview)


func _init() -> void:
	super._init()
	setup_paper("journal", 0.84)


func open_for(world: SimWorld) -> void:
	w = world
	cat = ""
	_build()
	open()


func _build() -> void:
	clear_body()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var tl := Sheet.label(Loc.t("ui.journal"), 32, "marker", INK_GREEN, false)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	body.add_child(head)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	for p in PAGES:
		var b := NoteButton.make(Loc.t("journal." + p), PAGE_ICON[p], "tab", Color("e9dcb4") if p == page else Color("d6ccb0"), Vector2(0, 64))
		b.font_size = 17
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text_col = INK_GREEN if p == page else UiKit.INK_SOFT
		var pp: String = p
		b.pressed.connect(func():
			page = pp
			cat = ""
			_build())
		tabs.add_child(b)
	body.add_child(tabs)
	var sc := Sheet.scroll()
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	body.add_child(sc)
	match page:
		"meddles":
			if cat == "":
				_meddles(list)
			else:
				_category(list, cat)
		"stories":
			_stories(list)
		"moments":
			_moments(list)
		"records":
			_records(list)


# ------------------------------------------------------------------ meddles

func _meddles(list: VBoxContainer) -> void:
	var total: int = w.iv.defs.size()
	var found := 0
	for d in w.iv.defs:
		if w.discovery.ivs.has(d["id"]):
			found += 1
	list.add_child(_big_number(found, total, Loc.t("journal.meddles_found"), Loc.t("journal.undiscovered", {"n": total - found})))
	for c in CAT_ORDER:
		var defs: Array = w.iv.defs.filter(func(d): return d["cat"] == c)
		if defs.is_empty():
			continue
		var f := 0
		for d in defs:
			if w.discovery.ivs.has(d["id"]):
				f += 1
		var row := _ledger_row(Loc.t("cat." + c), "%d / %d" % [f, defs.size()], float(f) / float(defs.size()), c == "J")
		var cc: String = c
		row.pressed.connect(func():
			cat = cc
			_build())
		list.add_child(row)


func _category(list: VBoxContainer, c: String) -> void:
	var back := NoteButton.make(Loc.t("journal.all_categories"), "back", "row", Color("efe5c8"), Vector2(0, 56))
	back.font_size = 20
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func():
		cat = ""
		_build())
	list.add_child(back)
	list.add_child(Sheet.label(Loc.t("cat." + c), 26, "marker", INK_GREEN))
	var hidden_left := 0
	var unknown := 0
	for d in w.iv.defs:
		if d["cat"] != c:
			continue
		var rec: Dictionary = w.discovery.ivs.get(d["id"], {})
		if rec.is_empty():
			if d.get("hidden", false):
				hidden_left += 1
			else:
				unknown += 1
			continue
		var n_out: int = rec.get("out", {}).size()
		var title := _plain(Loc.t(str(d.get("name", ""))))
		var sub := Loc.t("journal.used", {"n": int(rec.get("uses", 0)), "day": int(rec.get("day", 1))})
		if n_out > 0:
			sub += "  ·  " + Loc.t("journal.outcomes", {"n": n_out})
		var row := NoteButton.make(title, "key" if d.get("hidden", false) else str(d.get("icon", "ghost")), "row",
			Color("ffe9a8") if d.get("hidden", false) else Color("fbf6e6"), Vector2(0, 84))
		row.font_size = 21
		row.sub = sub
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(row)
	if unknown > 0:
		list.add_child(_mystery(Loc.t("journal.unknown_left", {"n": unknown})))
	if hidden_left > 0:
		list.add_child(_mystery(Loc.t("journal.secrets_left", {"n": hidden_left})))


## Titles may carry {placeholders} (names chosen at the time) — the journal shows a neutral form.
func _plain(t: String) -> String:
	var out := t
	var re := RegEx.new()
	re.compile("\\{[a-z_0-9]+\\}")
	out = re.sub(out, "…", true)
	return out


# ------------------------------------------------------------------ stories

func _stories(list: VBoxContainer) -> void:
	var ids: Array = w.director.arc_defs.keys()
	var done := 0
	for a in ids:
		if w.discovery.arcs.has(a):
			done += 1
	list.add_child(_big_number(done, ids.size(), Loc.t("journal.stories_done"), Loc.t("journal.endings", {"n": w.discovery.endings_seen()})))
	ids.sort_custom(func(x, y): return int(w.discovery.arcs.has(x)) > int(w.discovery.arcs.has(y)))
	var unknown := 0
	for a in ids:
		if not w.discovery.arcs.has(a):
			unknown += 1
			continue
		var rec: Dictionary = w.discovery.arcs[a]
		var ends: Array = rec.get("results", {}).keys()
		var ends_txt: Array = []
		for e in ends:
			ends_txt.append(Loc.t("ending." + str(e)) if Loc.has("ending." + str(e)) else str(e).replace("_", " "))
		var row := NoteButton.make(Loc.t("arc." + a), "book", "row", Color("fbf6e6"), Vector2(0, 88))
		row.font_size = 21
		row.sub = Loc.t("journal.story_line", {"n": int(rec.get("count", 0)), "ends": ", ".join(ends_txt)})
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(row)
	if unknown > 0:
		list.add_child(_mystery(Loc.t("journal.stories_left", {"n": unknown})))


# ------------------------------------------------------------------ moments

func _moments(list: VBoxContainer) -> void:
	var seen: Array = w.discovery.specials.keys()
	var total: int = w.discovery.special_ids.size()
	list.add_child(_big_number(seen.size(), total, Loc.t("journal.moments_seen"), Loc.t("journal.moments_hint")))
	seen.sort_custom(func(x, y): return int(w.discovery.specials[x]) > int(w.discovery.specials[y]))
	for eid in seen.slice(0, 60):
		var txt: String = str(w.discovery.special_text.get(eid, ""))
		if txt == "":
			txt = Loc.t("journal.moment_unrecorded")
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("fffaf0")
		sb.border_color = Color(0.3, 0.25, 0.2, 0.25)
		sb.set_border_width_all(1)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", sb)
		var v := VBoxContainer.new()
		v.add_child(Sheet.label(Loc.t("ui.day") + " " + str(int(w.discovery.specials[eid])), 16, "type", Color("b23a48")))
		v.add_child(Sheet.label(txt, 20, "hand"))
		card.add_child(v)
		list.add_child(card)


# ------------------------------------------------------------------ records

func _records(list: VBoxContainer) -> void:
	var b: Dictionary = w.discovery.biggest
	list.add_child(Sheet.label(Loc.t("journal.biggest"), 24, "marker", INK_GREEN))
	if b.is_empty():
		list.add_child(Sheet.label(Loc.t("journal.no_biggest"), 20, "hand", UiKit.INK_SOFT))
	else:
		var d: Dictionary = w.iv.by_id.get(str(b.get("iv", "")), {})
		var name := _plain(Loc.t(str(d.get("name", "")))) if not d.is_empty() else "?"
		list.add_child(Sheet.label(Loc.t("journal.biggest_line", {"what": name, "n": int(b.get("count", 0)), "day": int(b.get("day", 1))}), 21, "hand"))
		var arcs: Array = b.get("arcs", [])
		if not arcs.is_empty():
			var names: Array = []
			for a in arcs:
				names.append(Loc.t("arc." + str(a)))
			list.add_child(Sheet.label(Loc.t("journal.biggest_arcs", {"arcs": ", ".join(names)}), 19, "hand", Color("b23a48")))
		if str(b.get("text", "")) != "":
			list.add_child(Sheet.label(Loc.t("ui.quote", {"text": str(b["text"])}), 19, "type", UiKit.INK_SOFT))
	list.add_child(HSeparator.new())
	var rows := [
		[Loc.t("journal.r_meddles"), w.discovery.ivs.size()],
		[Loc.t("journal.r_outcomes"), w.discovery.outcomes_seen()],
		[Loc.t("journal.r_secrets"), w.iv.defs.filter(func(x): return x.get("hidden", false) and w.discovery.ivs.has(x["id"])).size()],
		[Loc.t("journal.r_stories"), w.discovery.arcs.size()],
		[Loc.t("journal.r_endings"), w.discovery.endings_seen()],
		[Loc.t("journal.r_moments"), w.discovery.specials.size()],
	]
	for r in rows:
		var h := HBoxContainer.new()
		var l := Sheet.label(str(r[0]), 21, "hand")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(Sheet.label(str(r[1]), 24, "slab", INK_GREEN, false))
		list.add_child(h)


# ------------------------------------------------------------------ bits

func _big_number(n: int, total: int, label: String, sub: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(Sheet.label(str(n), 54, "slab", INK_GREEN, false))
	var vv := VBoxContainer.new()
	vv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vv.add_child(Sheet.label("/ %d" % total, 22, "type", UiKit.INK_SOFT, false))
	vv.add_child(Sheet.label(label, 20, "hand"))
	h.add_child(vv)
	v.add_child(h)
	var bar := ProgressBarDrawn.new()
	bar.frac = float(n) / maxf(1.0, float(total))
	bar.custom_minimum_size = Vector2(0, 14)
	v.add_child(bar)
	v.add_child(Sheet.label(sub, 18, "hand", UiKit.INK_SOFT))
	return v


func _ledger_row(title: String, count: String, frac: float, secret: bool) -> NoteButton:
	var row := NoteButton.make(title, "key" if secret else "", "row", Color("ffe9a8") if secret else Color("fbf6e6"), Vector2(0, 74))
	row.font_size = 22
	row.sub = Loc.t("journal.found_pct", {"n": count, "pct": int(round(frac * 100.0))})
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return row


func _mystery(text: String) -> Control:
	var l := Sheet.label("? ? ?   " + text, 20, "type", UiKit.INK_SOFT)
	return l


## A thin hand-drawn progress bar.
class ProgressBarDrawn:
	extends Control
	var frac := 0.0

	func _draw() -> void:
		var r := Rect2(Vector2(0, 2), Vector2(size.x, size.y - 4))
		draw_rect(r, Color(0.3, 0.25, 0.2, 0.12))
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), Color("4f7a5f"))
		draw_rect(r, Color(0.2, 0.3, 0.25, 0.6), false, 1.2)
