class_name InterventionMenu
extends Sheet
## The "meddling clipboard": what the invisible player can do to the tapped object.
## Workstations get tabs (Computer / Inbox / Phone / Desk); everything else a single
## list. Unavailable meddles stay visible, greyed, with the reason. Hidden
## combinations only show up (gold, with a key) once their ingredients are done.

signal meddled(action: Dictionary)

const TABS := ["pc", "mail", "phone", "papers"]
const TAB_ICON := {"pc": "monitor", "mail": "email", "phone": "phone", "papers": "papers"}
const COL_ROW := Color("fffdf5")
const COL_OFF := Color("ece8df")
const COL_SECRET := Color("ffe9a8")

var w: SimWorld
var spot := ""
var tab := "pc"
var _action: Dictionary = {}


func _init() -> void:
	super._init()
	setup_paper("clipboard", 0.6)


func open_for(world: SimWorld, hotspot: String) -> void:
	w = world
	spot = hotspot
	_action = {}
	if spot.begins_with("ws_"):
		tab = _best_tab()
	_build_actions()
	open()


## Opens the desk on the tab that has something special (a secret combo) or else
## the first tab with anything usable.
func _best_tab() -> String:
	var acts: Array = w.iv.actions_for(spot)
	for a in acts:
		if a.get("hidden", false) and a["enabled"]:
			return str(a.get("tab", "pc"))
	for t in TABS:
		for a in acts:
			if str(a.get("tab", "")) == t and a["enabled"]:
				return t
	return "pc"


func _owner() -> String:
	return spot.substr(3) if spot.begins_with("ws_") else ""


func _title() -> String:
	if spot.begins_with("ws_"):
		return Loc.t("spot.ws", {"name": w.npc(spot.substr(3)).name})
	if spot.begins_with("item_"):
		var it := spot.substr(5)
		return Loc.t("spot.item", {"owner": w.npc(w.office.items[it]["owner"]).name, "item": Loc.t("item." + it)})
	return Loc.t("spot." + spot)


func _state() -> String:
	var o := w.office.objects
	match spot:
		"coffee_machine":
			if o["coffee"]["broken"]:
				return Loc.t("state.broken")
			if o["coffee"].get("decaf", false) or o["coffee"].get("strong", false):
				return Loc.t("state.coffee_odd")
			return Loc.t("state.working")
		"printer":
			if o["printer"]["broken"]:
				return Loc.t("state.broken")
			return Loc.t("state.no_paper") if o["printer"].get("no_paper", false) else Loc.t("state.working")
		"meeting_board", "meeting_table":
			if w.meeting.get("ended", false) or w.meeting.get("started", false):
				return Loc.t("state.meeting_done")
			return Loc.t("state.meeting_at", {"time": C.fmt(float(o["board"]["time"]))})
		"ac":
			return Loc.t("state.temp", {"temp": "%d°C" % int(o["ac"]["temp"])})
		"lights":
			return Loc.t("state.lights_on") if o["lights"]["on"] else Loc.t("state.lights_off")
		"promo_file":
			return Loc.t("state.promo_altered") if o["promo"].get("altered", false) else Loc.t("state.promo")
		"water_cooler", "microwave":
			var key := "water" if spot == "water_cooler" else "microwave"
			return Loc.t("state.broken") if w.office.is_broken(key) else Loc.t("state.working")
		"wall_clock":
			return Loc.t("state.clock", {"time": C.fmt(w.minute + float(o.get("clock", {}).get("offset", 0)))})
		"alarm_panel":
			return Loc.t("state.alarm_on") if o.get("alarm", {}).get("on", false) else Loc.t("state.alarm_off")
		"speaker":
			var g := str(o.get("music", {}).get("genre", ""))
			return Loc.t("state.music_off") if g == "" else Loc.t("state.music", {"what": Loc.t("what.music_" + g)})
		"noticeboard":
			return Loc.t("state.pins", {"n": o.get("notice", {}).get("pins", []).size()})
	if spot.begins_with("ws_"):
		var n: NPC = w.npc(spot.substr(3))
		var doing: String = Loc.t("doing." + n.act) if n.present else Loc.t("ui.not_in_office")
		return Loc.t("state.desk", {"name": n.name, "doing": doing})
	if spot.begins_with("item_"):
		var it := spot.substr(5)
		return Loc.t("state.item_at", {"loc": Loc.t("loc." + w.office.items[it]["at"])})
	return ""


## "7 / 20 found here" — the player's collection for this object.
func _found_line() -> String:
	var fam := InterventionManager.obj_of(spot)
	var total := 0
	var found := 0
	var secret := 0
	for d in w.iv.by_obj.get(fam, []):
		var owners: Array = d.get("owners", [])
		if not owners.is_empty() and not (_owner() in owners):
			continue
		if d.get("hidden", false):
			secret += 1
		total += 1
		if w.discovery.ivs.has(d["id"]):
			found += 1
	var s := Loc.t("ui.found_here", {"n": found, "total": total})
	if secret > 0:
		s += "  ·  " + Loc.t("ui.secrets_here", {"n": secret})
	return s


func _header(back := false, sub := "") -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	if back:
		var b := NoteButton.make("", "back", "round", COL_ROW, Vector2(48, 48))
		b.pressed.connect(_build_actions)
		h.add_child(b)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(Sheet.label(_title(), 30, "marker"))
	v.add_child(Sheet.label(sub if sub != "" else _state(), 19, "type", Color(0.35, 0.3, 0.35)))
	h.add_child(v)
	body.add_child(h)


## Fills {owner}, {target}, {crush}... in a title/description with real names.
func _fmt(text: String, a: Dictionary, value = null) -> String:
	if text.find("{") < 0 or not a.has("def") or a["def"].is_empty():
		return text
	var ctx := w.iv.ctx_for(a["def"], str(a.get("owner", "")), value)
	return w.dialogue.format(text, ctx)


func _title_of(a: Dictionary) -> String:
	if a.has("legacy"):
		var la: Dictionary = a["legacy"]
		if la["id"] == "move_item":
			var it: String = la["item"]
			return Loc.t("act.move_item", {"owner": w.npc(w.office.items[it]["owner"]).name, "item": Loc.t("item." + it)})
		return Loc.t("act." + la["id"])
	return _fmt(Loc.t(str(a["def"]["name"])), a)


func _desc_of(a: Dictionary) -> String:
	if not a["enabled"]:
		return _fmt(Loc.t(str(a.get("reason", "why.not_now"))), a)
	if a.has("legacy"):
		return Loc.t("act." + a["legacy"]["id"] + ".d")
	return _fmt(Loc.t(str(a["def"]["name"]) + ".d"), a)


func _icon_of(a: Dictionary) -> String:
	if a.get("hidden", false):
		return "key"
	if a.has("legacy"):
		return Icons.for_action(a["legacy"]["id"])
	var ic := str(a["def"].get("icon", ""))
	return ic if ic != "" else "ghost"


func _build_actions() -> void:
	clear_body()
	_header()
	var acts: Array = w.iv.actions_for(spot)
	if spot.begins_with("ws_"):
		_tabs(acts)
	var fl := Sheet.label(_found_line(), 17, "hand", UiKit.INK_SOFT)
	body.add_child(fl)
	var sc := Sheet.scroll()
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 9)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	body.add_child(sc)
	var shown: Array = []
	for a in acts:
		if spot.begins_with("ws_") and str(a.get("tab", "pc")) != tab:
			continue
		shown.append(a)
	# secret combinations first, then what's usable, then the rest
	shown.sort_custom(func(x, y): return _rank(x) < _rank(y))
	for a in shown:
		list.add_child(_row(a))
	if shown.is_empty():
		list.add_child(Sheet.label(Loc.t("ui.nothing_here"), 20, "hand", UiKit.INK_SOFT))


func _rank(a: Dictionary) -> int:
	if a.get("hidden", false):
		return 0
	return 1 if a["enabled"] else 2


func _tabs(acts: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for t in TABS:
		var n_ok := 0
		var secret := false
		for a in acts:
			if str(a.get("tab", "")) == t:
				if a["enabled"]:
					n_ok += 1
				if a.get("hidden", false) and a["enabled"]:
					secret = true
		var b := NoteButton.make(Loc.t("tab." + t), TAB_ICON[t], "tab", (COL_SECRET if secret else Color("fff07a")) if t == tab else Color("e9e2d0"), Vector2(0, 66))
		b.font_size = 18
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.badge = n_ok if t != tab else 0
		var tt: String = t
		b.pressed.connect(func():
			tab = tt
			_build_actions())
		row.add_child(b)
	body.add_child(row)


func _row(a: Dictionary) -> NoteButton:
	var secret: bool = a.get("hidden", false)
	var colr := COL_SECRET if secret else (COL_ROW if a["enabled"] else COL_OFF)
	var row := NoteButton.make(_title_of(a), _icon_of(a), "row", colr, Vector2(0, 92))
	var desc := _desc_of(a)
	if secret:
		desc = Loc.t("ui.secret_combo") + " · " + desc
	row.sub = desc
	row.font_size = 22
	row.disabled = not a["enabled"]
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if a["enabled"] and not w.discovery.ivs.has(str(a.get("iv", ""))):
		row.tag = Loc.t("ui.new_tag")
	var act: Dictionary = a
	row.pressed.connect(func(): _choose(act))
	return row


func _choose(a: Dictionary) -> void:
	a["spot"] = spot
	if str(a.get("needs", "")) == "":
		_apply(a, null)
		return
	_action = a
	_options(a, w.iv.options_for(a), Loc.t("ui.choose"))


func _options(a: Dictionary, opts: Array, sub: String) -> void:
	clear_body()
	_header(true, sub)
	body.add_child(Sheet.label(_title_of(a), 22, "hand", UiKit.BLUE))
	var sc := Sheet.scroll()
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	body.add_child(sc)
	var needs := str(a.get("needs", ""))
	var two := not a.has("legacy") and InterventionManager.two_step(a.get("def", {}))
	for o in opts:
		var label := Loc.t(o["label"], o.get("args", {}))
		var row := NoteButton.make(label, "", "row", COL_ROW if o["enabled"] else COL_OFF, Vector2(0, 62))
		row.font_size = 23
		row.disabled = not o["enabled"]
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if typeof(o["value"]) == TYPE_ARRAY or needs in ["person", "credit"]:
			row.icon = "people" if typeof(o["value"]) != TYPE_ARRAY else "check"
		elif needs == "temp":
			row.icon = "thermo"
		elif needs == "time":
			row.icon = "board"
		elif needs == "notif":
			row.icon = "phone"
		elif needs == "dest":
			row.icon = "item"
		elif needs == "choice":
			row.icon = "check"
		var val = o["value"]
		if two and typeof(val) != TYPE_ARRAY:
			row.pressed.connect(func(): _options(a, w.iv.options_for(a, val), Loc.t("ui.picked", {"name": w.npc(str(val)).name})))
		else:
			row.pressed.connect(func(): _apply(a, val))
		list.add_child(row)


func _apply(a: Dictionary, value) -> void:
	a["spot"] = spot
	if w.iv.apply(a, value):
		meddled.emit(a)
	close()
