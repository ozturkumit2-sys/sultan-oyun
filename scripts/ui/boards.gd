class_name Boards
extends RefCounted
## Factory for the cork-board style sheets (staff wall & gossip board) and simple paper sheets.


## Staff wall: polaroids of everyone with their current status.
class StaffBoard extends Sheet:
	signal pick(npc_id: String)
	var w: SimWorld
	var cards: Array = []

	func _init() -> void:
		super._init()
		setup_paper("cork", 0.78, "STAFF")

	func open_for(world: SimWorld) -> void:
		w = world
		paper.tab_text = Loc.t("ui.staff").to_upper()
		clear_body()
		cards.clear()
		var sc := Sheet.scroll()
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 16)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(grid)
		body.add_child(sc)
		var i := 0
		for id in w.order:
			var card := _card(id, i)
			grid.add_child(card)
			i += 1
		open()

	func _card(id: String, i: int) -> Control:
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(320, 230)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		var tilt: float = [-2.5, 2.0, 1.5, -2.0, -1.0, 2.5, 2.0, -1.5][i % 8]
		var pol := Portrait.make(w, id, Vector2(150, 176), true, 1.0)
		pol.position = Vector2(10, 18)
		pol.pivot_offset = Vector2(75, 88)
		pol.rotation_degrees = tilt
		b.add_child(pol)
		var info := Control.new()
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.position = Vector2(166, 18)
		info.size = Vector2(150, 200)
		info.draw.connect(func():
			var n: NPC = w.npc(id)
			UiKit.draw_note(info, Rect2(0, 6, 148, 190), UiKit.sticky(["yellow", "pink", "blue", "green", "orange", "lilac", "yellow", "pink"][i % 8]), true, true)
			UiKit.draw_pin(info, Vector2(74, 10), UiKit.RED)
			info.draw_string(UiKit.font("marker"), Vector2(10, 46), n.name, HORIZONTAL_ALIGNMENT_LEFT, 130, 24, UiKit.NPC_COLOR.get(id, UiKit.INK))
			info.draw_multiline_string(UiKit.font("hand"), Vector2(10, 70), n.role_title(), HORIZONTAL_ALIGNMENT_LEFT, 130, 17, 2, Color(0.25, 0.25, 0.3))
			Hud._mood_face(info, Vector2(30, 122), 18, n.mood)
			info.draw_string(UiKit.font("hand"), Vector2(54, 128), Loc.t(n.mood_word()), HORIZONTAL_ALIGNMENT_LEFT, 90, 19, UiKit.INK)
			var d: String = Loc.t("doing." + n.act) if n.present else Loc.t("ui.not_in_office")
			info.draw_multiline_string(UiKit.font("hand"), Vector2(10, 160), d, HORIZONTAL_ALIGNMENT_LEFT, 132, 17, 2, Color(0.3, 0.3, 0.38)))
		b.add_child(info)
		cards.append(info)
		b.pressed.connect(func():
			Audio.play("click", -4.0)
			pick.emit(id))
		return b

	func _process(_d: float) -> void:
		if is_open:
			for c in cards:
				c.queue_redraw()


## Gossip board: every logged event as a pinned sticky note, newest first.
class GossipBoard extends Sheet:
	signal focus_event(entry: Dictionary)
	var w: SimWorld

	func _init() -> void:
		super._init()
		setup_paper("cork", 0.8, "GOSSIP BOARD")

	func open_for(world: SimWorld) -> void:
		w = world
		paper.tab_text = Loc.t("ui.log").to_upper()
		clear_body()
		var sc := Sheet.scroll()
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(v)
		body.add_child(sc)
		var entries: Array = w.log_entries.duplicate()
		entries.reverse()
		var last_day := -1
		var shown := 0
		for e in entries:
			if shown >= 120:
				break
			if int(e["day"]) != last_day:
				last_day = int(e["day"])
				var hl := Sheet.label("— " + Loc.t("ui.day", {"day": last_day}) + " —", 24, "marker", Color("fffdf5"))
				hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				v.add_child(hl)
			v.add_child(_note(e, shown))
			shown += 1
		if shown == 0:
			v.add_child(Sheet.label(Loc.t("ui.no_events"), 22, "hand", Color("fffdf5")))
		open()

	func _note(e: Dictionary, i: int) -> Control:
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var text: String = e["text"]
		var lines := 1 + int(UiKit.font("hand").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x / 560.0)
		b.custom_minimum_size = Vector2(0, 46 + lines * 25)
		var cat: String = e.get("cat", "misc")
		var col := UiKit.sticky(UiKit.CAT_COLOR.get(cat, "yellow"))
		var tilt: float = [-0.8, 0.6, -0.4, 0.9, -0.6][i % 5]
		var imp := int(e.get("imp", 1))
		var player: bool = cat == "player"
		var n := Control.new()
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		n.set_anchors_preset(Control.PRESET_FULL_RECT)
		n.draw.connect(func():
			var r := Rect2(Vector2(6, 4), n.size - Vector2(12, 8))
			n.draw_set_transform(r.get_center(), deg_to_rad(tilt), Vector2.ONE)
			var rr := Rect2(-r.size * 0.5, r.size)
			UiKit.draw_note(n, rr, col if not player else Color("eceae4"), true, imp >= 3)
			UiKit.draw_pin(n, rr.position + Vector2(20, 12), [UiKit.RED, UiKit.BLUE, UiKit.GREEN][i % 3])
			n.draw_string(UiKit.font("type"), rr.position + Vector2(36, 20), C.fmt(e["minute"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.35, 0.33, 0.35))
			if imp >= 4:
				Icons.draw(n, "star", Vector2(rr.end.x - 22, rr.position.y + 16), 22, UiKit.RED)
			if player:
				Icons.draw(n, "ghost", Vector2(rr.end.x - 22, rr.position.y + 18), 26)
			n.draw_multiline_string(UiKit.font("hand"), rr.position + Vector2(14, 44), text, HORIZONTAL_ALIGNMENT_LEFT, rr.size.x - 28, 21, -1, UiKit.INK)
			n.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE))
		b.add_child(n)
		b.pressed.connect(func():
			Audio.play("click", -4.0)
			focus_event.emit(e)
			close())
		return b


## Today's numbers so far.
class TodayCard extends Sheet:
	var w: SimWorld

	func _init() -> void:
		super._init()
		setup_paper("card", 0.6)

	func open_for(world: SimWorld) -> void:
		w = world
		clear_body()
		body.add_child(Sheet.label(Loc.t("ui.day", {"day": w.day}) + " · " + Loc.t("ui.today_so_far"), 30, "marker"))
		body.add_child(Sheet.label(Loc.t(w.stats.headline_key()), 26, "slab", UiKit.RED))
		var sc := Sheet.scroll()
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(v)
		body.add_child(sc)
		var any := false
		for k in DayStats.ORDER:
			var c := w.stats.get_count(k)
			if c <= 0 or k == "interventions":
				continue
			any = true
			v.add_child(_row(Loc.t("stat." + k), c))
		v.add_child(_row(Loc.t("stat.interventions"), w.stats.get_count("interventions")))
		if not any:
			v.add_child(Sheet.label(Loc.t("paper.no_stories"), 20, "type", Color(0.4, 0.4, 0.45)))
		v.add_child(Sheet.label(Loc.t("ui.interventions_total", {"n": w.total_interventions}), 20, "type", Color(0.35, 0.35, 0.4)))
		open()

	func _row(t: String, n: int) -> Control:
		var c := Control.new()
		c.custom_minimum_size = Vector2(0, 34)
		c.draw.connect(func():
			c.draw_string(UiKit.font("hand"), Vector2(8, 25), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, UiKit.INK)
			c.draw_string(UiKit.font("marker"), Vector2(c.size.x - 90, 26), str(n), HORIZONTAL_ALIGNMENT_RIGHT, 80, 25, UiKit.BLUE)
			var tally := mini(n, 10)
			for k in tally:
				var x := c.size.x - 200.0 + k * 9.0
				if k % 5 == 4:
					c.draw_line(Vector2(x - 38, 22), Vector2(x + 2, 8), UiKit.INK, 1.6, true)
				else:
					c.draw_line(Vector2(x, 24), Vector2(x, 8), UiKit.INK, 1.6, true))
		return c


## Plain text sheet (how to play, credits).
class InfoSheet extends Sheet:
	func _init() -> void:
		super._init()
		setup_paper("lined", 0.74)

	func open_text(title: String, text: String) -> void:
		clear_body()
		body.add_child(Sheet.label(title, 32, "marker"))
		var sc := Sheet.scroll()
		var l := Sheet.label(text, 23, "hand")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(l)
		body.add_child(sc)
		open()


## Settings: sound, music, auto day, how to play, main menu.
class SettingsSheet extends Sheet:
	signal to_menu
	signal how_to
	signal credits
	var rows := {}

	func _init() -> void:
		super._init()
		setup_paper("lined", 0.62)

	func open_settings(in_game: bool) -> void:
		clear_body()
		body.add_child(Sheet.label(Loc.t("ui.settings"), 34, "marker"))
		for k in ["sound", "music", "auto_next"]:
			var key: String = k
			var row := NoteButton.make("", "", "row", Color("fffdf5"), Vector2(0, 62))
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.icon = {"sound": "sound", "music": "music", "auto_next": "calendar"}[k]
			row.font_size = 23
			rows[k] = row
			row.pressed.connect(func():
				Game.set_setting(key, not Game.settings.get(key, true))
				_refresh())
			body.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var b1 := NoteButton.make(Loc.t("ui.how_to"), "help", "sticky", UiKit.sticky("blue"), Vector2(200, 92))
		b1.tilt = -2
		b1.pressed.connect(func(): how_to.emit())
		var b2 := NoteButton.make(Loc.t("ui.credits"), "star", "sticky", UiKit.sticky("lilac"), Vector2(200, 92))
		b2.tilt = 1.5
		b2.pressed.connect(func(): credits.emit())
		h.add_child(b1)
		h.add_child(b2)
		if in_game:
			var b3 := NoteButton.make(Loc.t("ui.main_menu"), "home", "sticky", UiKit.sticky("pink"), Vector2(220, 92))
			b3.tilt = -1
			b3.font_size = 20
			b3.pressed.connect(func():
				close()
				to_menu.emit())
			h.add_child(b3)
		body.add_child(h)
		_refresh()
		open()

	func _refresh() -> void:
		var names := {"sound": "ui.sound", "music": "ui.music", "auto_next": "ui.auto_next"}
		for k in rows:
			var on: bool = Game.settings.get(k, true)
			rows[k].text = "%s:  %s" % [Loc.t(names[k]), Loc.t("ui.on") if on else Loc.t("ui.off")]
			rows[k].col = Color("e9f7e4") if on else Color("f6e3e3")
			rows[k].queue_redraw()


## Yes / No sticky note.
class ConfirmSheet extends Sheet:
	signal answered(yes: bool)

	func _init() -> void:
		super._init()
		setup_paper("sticky", 0.3)
		paper.col = UiKit.sticky("yellow")
		add_to_group("ui_blocker")

	func ask(text: String) -> void:
		clear_body()
		close_btn.visible = false
		var l := Sheet.label(text, 26, "hand")
		body.add_child(l)
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 30)
		var y := NoteButton.make(Loc.t("ui.yes"), "check", "card", Color("fffdf5"), Vector2(170, 76))
		var n := NoteButton.make(Loc.t("ui.no"), "close", "card", Color("fffdf5"), Vector2(170, 76))
		y.pressed.connect(func():
			answered.emit(true)
			close())
		n.pressed.connect(func():
			answered.emit(false)
			close())
		h.add_child(y)
		h.add_child(n)
		body.add_child(h)
		open()
