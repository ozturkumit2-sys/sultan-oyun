class_name InterventionMenu
extends Sheet
## The "meddling clipboard": lists what the invisible player can do to a tapped object.

signal meddled(action: Dictionary)

var w: SimWorld
var spot := ""
var _action: Dictionary = {}


func _init() -> void:
	super._init()
	setup_paper("clipboard", 0.56)


func open_for(world: SimWorld, hotspot: String) -> void:
	w = world
	spot = hotspot
	_action = {}
	_build_actions()
	open()


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
			return Loc.t("state.broken") if o["coffee"]["broken"] else Loc.t("state.working")
		"printer":
			return Loc.t("state.broken") if o["printer"]["broken"] else Loc.t("state.working")
		"meeting_board":
			if w.meeting.get("ended", false) or w.meeting.get("started", false):
				return Loc.t("state.meeting_done")
			return Loc.t("state.meeting_at", {"time": C.fmt(float(o["board"]["time"]))})
		"ac":
			return Loc.t("state.temp", {"temp": "%d°C" % int(o["ac"]["temp"])})
		"lights":
			return Loc.t("state.lights_on") if o["lights"]["on"] else Loc.t("state.lights_off")
		"promo_file":
			return Loc.t("state.promo_altered") if o["promo"].get("altered", false) else Loc.t("state.promo")
	if spot.begins_with("ws_"):
		var n: NPC = w.npc(spot.substr(3))
		var doing: String = Loc.t("doing." + n.act) if n.present else Loc.t("ui.not_in_office")
		return Loc.t("state.desk", {"name": n.name, "doing": doing})
	if spot.begins_with("item_"):
		var it := spot.substr(5)
		return Loc.t("state.item_at", {"loc": Loc.t("loc." + w.office.items[it]["at"])})
	return ""


func _header(back := false) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	if back:
		var b := NoteButton.make("", "back", "round", Color("fffdf5"), Vector2(48, 48))
		b.pressed.connect(_build_actions)
		h.add_child(b)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(Sheet.label(_title(), 30, "marker"))
	v.add_child(Sheet.label(_state(), 19, "type", Color(0.35, 0.3, 0.35)))
	h.add_child(v)
	body.add_child(h)


func _build_actions() -> void:
	clear_body()
	_header()
	var sc := Sheet.scroll()
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	body.add_child(sc)
	var acts := Interventions.actions_for(w, spot)
	for a in acts:
		var title := Loc.t("act." + a["id"])
		if a["id"] == "move_item":
			var it: String = a["item"]
			title = Loc.t("act.move_item", {"owner": w.npc(w.office.items[it]["owner"]).name, "item": Loc.t("item." + it)})
		var desc: String = Loc.t("act." + a["id"] + ".d") if a["enabled"] else Loc.t(a.get("reason", ""))
		var row := NoteButton.make(title, Icons.for_action(a["id"]), "row", Color("fffdf5") if a["enabled"] else Color("ece8df"), Vector2(0, 88))
		row.sub = desc
		row.font_size = 23
		row.disabled = not a["enabled"]
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var act: Dictionary = a
		row.pressed.connect(func(): _choose(act))
		list.add_child(row)


func _choose(a: Dictionary) -> void:
	if a["needs"] == "":
		_apply(a, null)
		return
	_action = a
	clear_body()
	_header(true)
	body.add_child(Sheet.label(Loc.t("act." + a["id"]) if a["id"] != "move_item" else Loc.t("ui.choose"), 22, "hand", UiKit.BLUE))
	var sc := Sheet.scroll()
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	body.add_child(sc)
	for o in Interventions.options_for(w, a):
		var row := NoteButton.make(Loc.t(o["label"], o.get("args", {})), "", "row", Color("fffdf5") if o["enabled"] else Color("ece8df"), Vector2(0, 62))
		row.font_size = 23
		row.disabled = not o["enabled"]
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if a["needs"] in ["person", "credit"]:
			row.icon = "people"
		elif a["needs"] == "temp":
			row.icon = "thermo"
		elif a["needs"] == "time":
			row.icon = "board"
		elif a["needs"] == "notif":
			row.icon = "phone"
		elif a["needs"] == "dest":
			row.icon = "item"
		var val = o["value"]
		row.pressed.connect(func(): _apply(a, val))
		list.add_child(row)


func _apply(a: Dictionary, value) -> void:
	if Interventions.apply(w, a, value):
		meddled.emit(a)
	close()
