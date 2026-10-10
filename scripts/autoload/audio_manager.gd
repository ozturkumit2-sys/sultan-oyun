extends Node
## Modüler ses sistemi. Sesler assets/audio altındaki özgün (sentezlenmiş) dosyalardır.
## Bir dosya yoksa ses sessizce atlanır; var olmayan sesler var gibi gösterilmez.

const DIR := "res://assets/audio/"

var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _ui: Array = []
var _ui_idx := 0
var _cache := {}
var _current_music := ""
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	add_child(_music)
	_ambient = AudioStreamPlayer.new()
	_ambient.name = "Ambient"
	add_child(_ambient)
	for i in range(4):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_ui.append(p)
	Settings.changed.connect(_apply_volumes)
	_apply_volumes()


func stream(name: String, loop: bool = false) -> AudioStream:
	var key := name + (":L" if loop else "")
	if _cache.has(key):
		return _cache[key]
	var s: AudioStream = null
	for ext in [".ogg", ".wav"]:
		var p: String = DIR + name + String(ext)
		if ResourceLoader.exists(p):
			s = load(p)
			break
	if s != null and loop:
		s = s.duplicate()
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		elif s is AudioStreamWAV:
			var wv := s as AudioStreamWAV
			wv.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wv.loop_begin = 0
			wv.loop_end = int(wv.get_length() * wv.mix_rate)
	_cache[key] = s
	return s


func _lin(v: float) -> float:
	return linear_to_db(maxf(v, 0.0001))


func _apply_volumes() -> void:
	_music.volume_db = _lin(Settings.music_vol * 0.8)
	_ambient.volume_db = _lin(Settings.sfx_vol * 0.22)
	for p in _ui:
		p.volume_db = _lin(Settings.sfx_vol * 0.7)


func play_ui(name: String, pitch: float = 1.0) -> void:
	var s := stream(name)
	if s == null:
		return
	var p: AudioStreamPlayer = _ui[_ui_idx]
	_ui_idx = (_ui_idx + 1) % _ui.size()
	p.stream = s
	p.pitch_scale = pitch
	p.play()


func play_music(name: String, fade: float = 1.5) -> void:
	if name == _current_music and _music.playing:
		return
	_current_music = name
	var s := stream(name, true)
	if s == null:
		return
	if _music_tween:
		_music_tween.kill()
	_music.stream = s
	_music.volume_db = -40.0
	_music.play()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", _lin(Settings.music_vol * 0.8), fade)


func stop_music(fade: float = 1.0) -> void:
	_current_music = ""
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", -40.0, fade)
	_music_tween.tween_callback(_music.stop)


func set_ambient(name: String) -> void:
	var s := stream(name, true)
	if s == null:
		_ambient.stop()
		return
	if _ambient.stream == s and _ambient.playing:
		return
	_ambient.stream = s
	_ambient.play()


## Dünyada sabit bir ses kaynağı (çeşme, kuşlar, mutfak)
func make_3d(name: String, pos: Vector3, parent: Node, max_dist: float = 22.0, vol: float = 0.0) -> AudioStreamPlayer3D:
	var s := stream(name, true)
	if s == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.position = pos
	p.max_distance = max_dist
	p.unit_size = 6.0
	p.volume_db = vol + _lin(Settings.sfx_vol)
	p.autoplay = true
	parent.add_child(p)
	return p
