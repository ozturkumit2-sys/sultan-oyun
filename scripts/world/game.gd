extends Node3D
## Oyun sahnesi: sarayı kurar, hükümdarı ve saray halkını yerleştirir, arayüzü bağlar.

const BAKED := "res://data/palace_baked.scn"

var builder: PalaceBuilder
var player: PlayerController
var npcs: NPCManager
var hud: HUD
var day_night: DayNight
var _loading: CanvasLayer
var _load_bar: ProgressBar
var _load_text: Label
var _fade: ColorRect
var _ready_done := false
var _last_room := ""


func _ready() -> void:
	if not GameState.active:
		GameState.new_game("Kayhan", 1)
	_show_loading()
	await get_tree().process_frame
	day_night = DayNight.new()
	add_child(day_night)
	await _build_palace()
	_spawn_player()
	npcs = NPCManager.new()
	npcs.name = "NPCs"
	add_child(npcs)
	npcs.setup(builder, player)
	_set_load(0.95, "Saray halkı yerlerini alıyor")
	var map := builder.nav_region.get_navigation_map()
	var waited := 0
	while waited < 300 and (NavigationServer3D.map_get_iteration_id(map) == 0 or NavigationServer3D.map_get_closest_point(map, PalaceLayout.anchor("avlu")).y < 0.1):
		await get_tree().process_frame
		waited += 1
	npcs.refresh(true)
	_sound_points()
	hud = HUD.new()
	add_child(hud)
	hud.setup(self)
	Settings.apply_to(get_viewport(), day_night.sun, day_night.env)
	Settings.changed.connect(func(): Settings.apply_to(get_viewport(), day_night.sun, day_night.env))
	GameState.hour_changed.connect(_on_hour)
	GameState.relation_changed.connect(_on_rel_changed)
	GameState.month_changed.connect(_on_month)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var fl := CanvasLayer.new()
	fl.layer = 20
	add_child(fl)
	fl.add_child(_fade)
	AudioManager.play_music("theme")
	_update_ambient(player.current_room)
	_hide_loading()
	_ready_done = true
	if GameState.get_day() == 0 and GameState.total_minutes() < GameState.START_MINUTES + 30:
		hud.toast("Saltanatınız başladı. Valide Sultan ve Sadrazam sizinle görüşmek istiyor (Olaylar).", "bilgi")


# ------------------------------------------------------------ yükleme

func _show_loading() -> void:
	_loading = CanvasLayer.new()
	_loading.layer = 30
	add_child(_loading)
	var r := Control.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.theme = UI.theme()
	_loading.add_child(r)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/menu_bg.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.add_child(dim)
	var v := UI.vbox(12)
	v.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	v.offset_left = -360
	v.offset_right = 360
	v.offset_top = -170
	v.offset_bottom = -60
	r.add_child(v)
	_load_text = UI.label("Saray hazırlanıyor...", 24, UI.CREAM)
	_load_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_load_text)
	_load_bar = UI.bar(0.0, 1.0, UI.GOLD, 18)
	_load_bar.custom_minimum_size = Vector2(720, 18)
	v.add_child(_load_bar)


func _set_load(f: float, t: String) -> void:
	if _load_bar:
		_load_bar.value = f
	if _load_text:
		_load_text.text = t


func _hide_loading() -> void:
	if _loading == null:
		return
	var tw := create_tween()
	var r: Control = _loading.get_child(0)
	tw.tween_property(r, "modulate:a", 0.0, 0.6)
	tw.tween_callback(_loading.queue_free)


func _build_palace() -> void:
	if ResourceLoader.exists(BAKED):
		_set_load(0.3, "Saray yükleniyor...")
		await get_tree().process_frame
		var ps: PackedScene = load(BAKED)
		builder = ps.instantiate() as PalaceBuilder
		add_child(builder)
		builder.load_meta()
		_set_load(0.85, "Saray yüklendi")
	else:
		builder = PalaceBuilder.new()
		builder.name = "Palace"
		add_child(builder)
		builder.progress.connect(func(f, t): _set_load(f * 0.75, "İnşa ediliyor: " + t))
		await builder.build_async()
		_set_load(0.8, "Yollar hesaplanıyor...")
		builder.nav_region.bake_navigation_mesh(true)
		await builder.nav_region.bake_finished
		builder.free_nav_source()
	await get_tree().physics_frame


func _spawn_player() -> void:
	player = PlayerController.new()
	player.name = "Player"
	add_child(player)
	player.setup(self)
	var pos := GameState.player_pos
	if PalaceLayout.room_at_v(pos) == "":
		pos = PalaceLayout.anchor("avlu")
	player.place(pos + Vector3(0, 0.1, 0), GameState.player_yaw)
	player.current_room = PalaceLayout.room_at_v(pos)
	GameState.player_room = player.current_room
	player.room_changed.connect(_on_room_changed)
	player.blocked.connect(func(): hud.toast("Yol tıkalı; biraz elle yürüyüp tekrar deneyin.", "uyari"))


func _sound_points() -> void:
	var holder := Node3D.new()
	holder.name = "Sounds"
	add_child(holder)
	for sp in builder.sound_points:
		match String(sp["type"]):
			"fountain":
				AudioManager.make_3d("fountain", sp["pos"], holder, 18.0, -4.0)
			"kitchen":
				AudioManager.make_3d("kitchen", sp["pos"], holder, 16.0, -6.0)
	for p in [Vector3(-20, 3, 62), Vector3(30, 3, 62), Vector3(45, 3, 30), Vector3(0, 4, -10)]:
		AudioManager.make_3d("birds", p, holder, 32.0, -8.0)


# ------------------------------------------------------------ dünya erişimi

func npc_nodes() -> Array:
	return npcs.all_nodes() if npcs else []


func interactables() -> Array:
	return builder.interactables if builder else []


func nearest_seat(pos: Vector3, r: float) -> Dictionary:
	var room := player.current_room
	var arr: Array = builder.spots.get(room, [])
	var best := {}
	var bd := r
	for i in range(arr.size()):
		var sp: Dictionary = arr[i]
		if not String(sp["type"]) in ["sit", "sit_low"]:
			continue
		if npcs._reserved.has("%s:%d" % [room, i]):
			continue
		var d := Vector2(sp["pos"].x - pos.x, sp["pos"].z - pos.z).length()
		if d < bd:
			bd = d
			best = sp
	return best


func _snap(p: Vector3) -> Vector3:
	var map := builder.nav_region.get_navigation_map()
	if map.is_valid() and NavigationServer3D.map_get_iteration_id(map) > 0:
		return NavigationServer3D.map_get_closest_point(map, p)
	return p


func walk_to_room(room: String) -> void:
	if player.walk_to(_snap(PalaceLayout.anchor(room))):
		hud.toast("%s gidiliyor..." % TR.dat(PalaceLayout.room_short(room)), "bilgi")
	else:
		hud.toast("Oraya yol bulunamadı.", "uyari")


func walk_to_char(id: String) -> void:
	var n: NPCNode = npcs.node_for(id)
	if n and n.visible:
		if Locomotion.flat(n.global_position, player.global_position) <= 1.8:
			return
		if player.walk_to(n.global_position, n, 1.6):
			hud.toast("%s yanına gidiliyor..." % TR.gen(GameState.short_name(id)), "bilgi")
		else:
			hud.toast("%s yanına yol bulunamadı." % TR.gen(GameState.short_name(id)), "uyari")
	else:
		var c: Dictionary = GameState.ch(id)
		if c.get("location", "") == "disari":
			hud.toast("%s şu an saray dışında." % GameState.short_name(id), "uyari")
		else:
			walk_to_room(String(c.get("location", "avlu")))


func summon(id: String) -> void:
	var c: Dictionary = GameState.ch(id)
	if c.is_empty() or c.get("location", "") == "disari":
		hud.toast("%s şu an saray dışında; çağrılamıyor." % GameState.short_name(id), "uyari")
		return
	if c.get("activity", "") == "uyku":
		hud.toast("%s uyuyor. Sabahı bekleyin." % GameState.short_name(id), "uyari")
		return
	GameState.set_override(id, player.current_room, "kabul", 120)
	hud.toast("%s huzurunuza çağrıldı." % GameState.short_name(id), "bilgi")


# ------------------------------------------------------------ etkileşim

func open_dialogue(id: String) -> void:
	var n: NPCNode = npcs.node_for(id)
	if n:
		n.begin_talk(player.global_position)
		var d := n.global_position - player.global_position
		player.model.rotation.y = atan2(-d.x, -d.z)
	var p := DialoguePanel.new()
	hud.open_panel(p)
	p.open(id, self, n)
	if n and n.visible and Locomotion.flat(n.global_position, player.global_position) < 4.0:
		_dialogue_camera(n)
		p.closed.connect(_end_dialogue_camera)


# ------------------------------------------------------------ konuşma kamerası (omuz üstü yakın çekim)
var _dlg_cam: Camera3D
var _dlg_tw: Tween


func _dialogue_camera(n: NPCNode) -> void:
	if _dlg_cam:
		_dlg_cam.queue_free()
	await get_tree().process_frame
	if not is_instance_valid(n):
		return
	var face: Vector3 = n.model.face_position()
	var pp := player.global_position
	var to := face - pp
	to.y = 0.0
	if to.length() < 0.05:
		to = Vector3(0, 0, -1)
	to = to.normalized()
	var right := Vector3(-to.z, 0, to.x)
	var dist := Vector2(face.x - pp.x, face.z - pp.z).length()
	# karşıdan yakın çekim: kamera hükümdarın göz hizasına yakın, yüzü 1.3 m'den görür
	var cam_pos := face - to * 1.6 + right * 0.3
	cam_pos.y = face.y + 0.03
	player.hide_model = true
	# duvar varsa kamerayı yaklaştır
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(face, cam_pos, 1 | 8)
	q.exclude = [player.get_rid()]
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		cam_pos = face + (hit["position"] - face) * 0.85
	_dlg_cam = Camera3D.new()
	_dlg_cam.name = "DialogueCam"
	_dlg_cam.fov = player.camera.fov
	_dlg_cam.near = 0.05
	_dlg_cam.far = 3500.0
	add_child(_dlg_cam)
	_dlg_cam.global_transform = player.camera.global_transform
	_dlg_cam.current = true
	# yumuşak yüz ışığı (sinema ana ışığı gibi): yüz iç mekânda da okunur kalsın
	var key := OmniLight3D.new()
	key.name = "KeyLight"
	key.omni_range = 3.2
	key.omni_attenuation = 1.4
	key.light_energy = 0.9
	key.light_color = Color(1.0, 0.92, 0.82)
	key.light_specular = 0.25
	key.shadow_enabled = false
	add_child(key)
	key.global_position = face - to * 0.9 + right * 0.55 + Vector3(0, 0.45, 0)
	_dlg_cam.set_meta("key", key)
	var goal := Transform3D(Basis(), cam_pos).looking_at(face + Vector3(0, -0.02, 0), Vector3.UP)
	_dlg_tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_dlg_tw.tween_property(_dlg_cam, "global_transform", goal, 0.7)
	_dlg_tw.tween_property(_dlg_cam, "fov", 38.0, 0.7)
	_dlg_tw.tween_property(_dlg_cam, "v_offset", -0.3, 0.7)


func _end_dialogue_camera() -> void:
	if _dlg_cam == null or not is_instance_valid(_dlg_cam):
		return
	var cam := _dlg_cam
	_dlg_cam = null
	var key = cam.get_meta("key", null)
	if key and is_instance_valid(key):
		var kt := create_tween()
		kt.tween_property(key, "light_energy", 0.0, 0.4)
		kt.tween_callback(key.queue_free)
	if _dlg_tw:
		_dlg_tw.kill()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "global_transform", player.camera.global_transform, 0.45)
	tw.tween_property(cam, "fov", player.camera.fov, 0.45)
	tw.tween_property(cam, "v_offset", 0.0, 0.45)
	tw.chain().tween_callback(func():
		player.camera.current = true
		player.hide_model = false
		cam.queue_free())


func open_profile(id: String) -> void:
	var p := ProfilePanel.new()
	hud.open_panel(p)
	p.open(id, self)


func open_people() -> void:
	var p := PeoplePanel.new()
	hud.open_panel(p)
	p.open(self)


func open_map() -> void:
	var p := MapPanel.new()
	hud.open_panel(p)
	p.open(self)


func open_state(tab: String = "genel") -> void:
	var p := StatePanel.new()
	hud.open_panel(p)
	p.open(self, tab)


func open_events() -> void:
	var p := EventsPanel.new()
	hud.open_panel(p)
	p.open(self)


func open_log(summary_day: int = -1) -> void:
	var p := LogPanel.new()
	hud.open_panel(p)
	p.open(self, summary_day)


func open_pause() -> void:
	var p := PauseMenu.new()
	hud.open_panel(p)
	p.open(self)


func open_settings() -> void:
	var p := SettingsPanel.new()
	hud.open_panel(p)
	p.open()


func open_help() -> void:
	var p := PauseMenu.HelpPanel.new()
	hud.open_panel(p)
	p.open()


func open_save_load(saving: bool) -> void:
	var p := SaveLoadPanel.new()
	hud.open_panel(p)
	p.open(saving)
	p.loaded.connect(_load_slot)


func _load_slot(slot: String) -> void:
	if SaveSystem.load_game(slot):
		GameState.clear_pauses()
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		hud.toast("Kayıt okunamadı ya da bozuk.", "uyari")


func to_main_menu() -> void:
	GameState.active = false
	GameState.clear_pauses()
	AudioManager.set_ambient("")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func use_object(data: Dictionary) -> void:
	var action: String = data["action"]
	match action:
		"sit_throne":
			player.sit_at(data["seat"], float(data["yaw"]))
			hud.toast("Zehrâni tahtına oturdunuz.", "bilgi")
		"sit_here":
			player.sit_at(data["seat"], float(data["yaw"]))
		"divan":
			player.sit_at(data["seat"], float(data["yaw"]))
			var p := DivanPanel.new()
			hud.open_panel(p)
			p.open(self)
		"petitions":
			player.sit_at(data["seat"], float(data["yaw"]))
			var p2 := PetitionsPanel.new()
			hud.open_panel(p2)
			p2.open(self)
		"sleep":
			_sleep()
		"read":
			_time_skip(60, _after_read)
		"rest":
			var mins := int(data.get("minutes", 30))
			_time_skip(mins, func(): hud.toast("%d dakika dinlendiniz. Zihniniz berraklaştı." % mins, "bilgi"))
		"snack":
			_time_skip(int(data.get("minutes", 20)), _after_snack)
		"state_book":
			open_state("genel")
		"treasury":
			open_state("genel")
			if GameState.ch("kemal").get("location", "") == "hazine":
				hud.toast("Kemal Bey defterleri önünüze açtı.", "devlet")


func _after_read() -> void:
	var key := "okuma_%d" % GameState.get_day()
	if not GameState.flag(key):
		GameState.set_flag(key, true)
		GameState.player_skill_add("ilim", 1.0)
		GameState.player_skill_add("diplomasi", 0.4)
		hud.toast("Bir saat eski elçilik mektuplarını ve tarih kitaplarını okudunuz. (İlim +1)", "bilgi")
	else:
		hud.toast("Bir saat okudunuz; bugün zaten çok şey öğrendiniz.", "bilgi")


func _after_snack() -> void:
	if GameState.ch("bekir").get("location", "") == "mutfak":
		GameState.rel_add("bekir", GameState.PLAYER, {"sevgi": 1.5, "arkadaslik": 1.0})
		hud.toast("Bekir Usta sıcak bir börek ikram etti. Mutfakta hükümdarı görmek herkesi sevindirdi.", "bilgi")
	else:
		hud.toast("Mutfaktan bir dilim ekmek ve peynir aldınız.", "bilgi")


func _time_skip(mins: int, after: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.85, 0.35)
	tw.tween_callback(_do_skip.bind(mins, after))
	tw.tween_property(_fade, "color:a", 0.0, 0.45)


func _do_skip(mins: int, after: Callable) -> void:
	GameState.advance_minutes(mins, true)
	after.call()


func _sleep() -> void:
	var h := GameState.get_hour()
	if h >= 6 and h < 19:
		_time_skip(120, func(): hud.toast("İki saat kestirdiniz.", "bilgi"))
		return
	var prev_day := GameState.get_day() if h >= 19 else GameState.get_day() - 1
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.6)
	tw.tween_callback(_do_sleep.bind(prev_day))
	tw.tween_property(_fade, "color:a", 0.0, 0.8)


func _do_sleep(prev_day: int) -> void:
	player.stand_up()
	var night := {}
	if HaremEngine.night_ready(GameState):
		night = HaremEngine.do_night(GameState)
	GameState.sleep_until_morning()
	if Settings.autosave:
		SaveSystem.save_game("oto")
	if night.is_empty():
		open_log(prev_day)
		return
	var who: String = night["who"]
	var txt := "[i]%s[/i]" % String(night["text"])
	match String(night.get("promo", "")):
		"gozde":
			txt += "\n\nSabah haremde herkes konuşuyordu: %s artık hükümdarın [b]gözdesi[/b]." % GameState.short_name(who)
		"ikbal":
			txt += "\n\n%s artık haremde [b]ikbal[/b]; kendine ait bir oda ve hizmetkâr verildi." % GameState.short_name(who)
	txt += "\n\nSabah ezanıyla uyandığınızda %s çoktan dairesine dönmüştü." % GameState.short_name(who)
	var sp := StoryPanel.new()
	hud.open_panel(sp)
	sp.open("Gece", txt, open_log.bind(prev_day), 0.62, 0.62)


# ------------------------------------------------------------ zaman atlama
var skipping := false


func open_time_skip() -> void:
	var p := TimeSkipPanel.new()
	hud.open_panel(p)
	p.open(self)


func begin_skip() -> void:
	skipping = true
	player.stand_up()
	npcs.suspended = true
	hud.mute_toasts = true


func end_skip() -> void:
	skipping = false
	npcs.suspended = false
	hud.mute_toasts = false
	npcs.refresh(true)
	if Settings.autosave:
		SaveSystem.save_game("oto")


# ------------------------------------------------------------ olaylar

func _on_room_changed(r: String) -> void:
	_update_ambient(r)
	EventEngine.check_randevu(GameState)
	if r == "divan" and GameState.is_divan_day() and GameState.get_hour() >= 8 and GameState.get_hour() < 12 and _last_room != "divan":
		hud.toast("Divan toplantı hâlinde. Başköşeye oturup 'Divanı Topla' diyebilirsiniz.", "devlet")
	elif r == "halk" and _last_room != "halk" and not PetitionEngine.list(GameState).is_empty():
		hud.toast("Arz kürsüsünde %d dilekçe sahibi sizi bekliyor." % PetitionEngine.list(GameState).size(), "devlet")
	_last_room = r


func _update_ambient(r: String) -> void:
	if r == "":
		return
	if PalaceLayout.is_outdoor(r):
		AudioManager.set_ambient("outdoor_amb")
	else:
		AudioManager.set_ambient("palace_amb")


func _on_hour(h: int) -> void:
	if h == 6 and Settings.autosave and _ready_done and not skipping:
		if SaveSystem.save_game("oto"):
			hud.toast("Oyun otomatik kaydedildi.", "bilgi")


func _on_month(_rep: Dictionary) -> void:
	if hud:
		hud.toast("Ay sonu hesabı kapandı. Ayrıntılar Devlet Defteri'nde.", "devlet")


func _on_rel_changed(a: String, b: String, applied: Dictionary) -> void:
	pass


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if _ready_done and Settings.autosave and GameState.active and OS.has_feature("mobile"):
				SaveSystem.save_game("oto")
			if what == NOTIFICATION_WM_CLOSE_REQUEST and _ready_done and Settings.autosave and GameState.active:
				SaveSystem.save_game("oto")
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if not _ready_done:
				return
			var top := hud.top_panel()
			if top and top.has_method("close_panel"):
				top.close_panel()
			else:
				open_pause()


func _unhandled_input(event: InputEvent) -> void:
	if not _ready_done:
		return
	if event.is_action_pressed("menu"):
		var top := hud.top_panel()
		if top and top.has_method("close_panel"):
			top.close_panel()
		else:
			open_pause()
	elif event.is_action_pressed("map") and hud.top_panel() == null:
		open_map()
	elif event.is_action_pressed("people") and hud.top_panel() == null:
		open_people()
	elif event.is_action_pressed("time_pause") and hud.top_panel() == null:
		GameState.set_speed(0 if GameState.speed_idx != 0 else 1)
