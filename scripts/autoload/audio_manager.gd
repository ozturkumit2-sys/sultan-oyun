extends Node
## AudioManager — müzik ve efektler ayrı otobüslerde, bağımsız ses kontrolüyle.
## Ses dosyası bulunamazsa kısa bir sentez bip sesi yer tutucu olarak çalınır.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL_SIZE := 12

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_current: AudioStreamPlayer
var _music_name := ""
var _pool: Array = []
var _pool_i := 0
var _loops: Dictionary = {}
var _cache: Dictionary = {}
var _fallback: AudioStreamWAV
var _last_play: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")
	_music_current = _music_a
	for i in POOL_SIZE:
		_pool.append(_make_player("SFX"))
	_fallback = _make_beep()
	apply_volumes()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _make_beep() -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * 0.08)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / sr
		var env := 1.0 - float(i) / n
		var v := int(sin(TAU * 880.0 * t) * env * 9000.0)
		bytes.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = sr
	w.data = bytes
	return w


func apply_volumes() -> void:
	var mv: float = float(SaveManager.setting("music", 0.7))
	var sv: float = float(SaveManager.setting("sfx", 0.9))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(mv, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), mv <= 0.001)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sv, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), sv <= 0.001)


func _stream(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_cache[path] = s
	return s


func sfx(sfx_name: String, pitch := 1.0, vol_db := 0.0) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(sfx_name, -1000)) < 35:
		return
	_last_play[sfx_name] = now
	var s := _stream(SFX_DIR + sfx_name + ".ogg")
	if s == null:
		s = _fallback
		vol_db -= 12.0
	var p: AudioStreamPlayer = _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()


func sfx_r(sfx_name: String, spread := 0.08, vol_db := 0.0) -> void:
	sfx(sfx_name, randf_range(1.0 - spread, 1.0 + spread), vol_db)


func loop_start(loop_name: String, vol_db := -4.0) -> void:
	if _loops.has(loop_name):
		return
	var s := _stream(SFX_DIR + loop_name + ".ogg")
	if s == null:
		return
	var p := _make_player("SFX")
	if s is AudioStreamOggVorbis:
		var oc: AudioStreamOggVorbis = s.duplicate()
		oc.loop = true
		p.stream = oc
	else:
		p.stream = s
	p.volume_db = vol_db
	p.play()
	_loops[loop_name] = p


func loop_stop(loop_name: String) -> void:
	if not _loops.has(loop_name):
		return
	var p: AudioStreamPlayer = _loops[loop_name]
	_loops.erase(loop_name)
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -40.0, 0.25)
	tw.tween_callback(p.queue_free)


func stop_all_loops() -> void:
	for k in _loops.keys():
		loop_stop(k)


func music(music_name: String, fade := 0.8) -> void:
	if music_name == _music_name:
		return
	_music_name = music_name
	var s := _stream(MUSIC_DIR + music_name + ".ogg")
	var old := _music_current
	var nxt := _music_b if _music_current == _music_a else _music_a
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -40.0, fade)
		tw.tween_callback(old.stop)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		var oc: AudioStreamOggVorbis = s.duplicate()
		oc.loop = true
		s = oc
	nxt.stream = s
	nxt.volume_db = -40.0
	nxt.play()
	var tw2 := create_tween()
	tw2.tween_property(nxt, "volume_db", -6.0, fade)
	_music_current = nxt


func stop_music(fade := 0.6) -> void:
	_music_name = ""
	var old := _music_current
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -40.0, fade)
		tw.tween_callback(old.stop)
