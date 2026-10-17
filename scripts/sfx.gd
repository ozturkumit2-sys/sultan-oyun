extends Node
## Autoload "Sfx": pooled one-shot sounds + music with cross-fade.

const SOUNDS := [
	"jump", "jump2", "land", "step", "fish", "fish_gold", "kitten", "meow", "meow_kitten",
	"bounce", "stomp", "hurt", "gull", "gull_dive", "checkpoint", "dash", "wall", "respawn",
	"pigeons", "win", "click", "whoosh", "tram_bell", "ferry_horn",
]
var streams := {}
var pool: Array[AudioStreamPlayer] = []
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var ambience: AudioStreamPlayer
var _fish_chain := 0
var _fish_chain_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for s in SOUNDS:
		var p := "res://assets/audio/%s.ogg" % s
		if ResourceLoader.exists(p):
			streams[s] = load(p)
	for i in 14:
		var a := AudioStreamPlayer.new()
		a.bus = "SFX"
		add_child(a)
		pool.append(a)
	music_a = AudioStreamPlayer.new()
	music_a.bus = "Music"
	add_child(music_a)
	music_b = AudioStreamPlayer.new()
	music_b.bus = "Music"
	add_child(music_b)
	ambience = AudioStreamPlayer.new()
	ambience.bus = "SFX"
	ambience.volume_db = -10.0
	add_child(ambience)
	GameState.apply_audio()


func _ensure_bus(name: String) -> void:
	if AudioServer.get_bus_index(name) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, name)
		AudioServer.set_bus_send(i, "Master")


func _process(delta: float) -> void:
	_fish_chain_t -= delta
	if _fish_chain_t <= 0.0:
		_fish_chain = 0


func play(name: String, pitch := 1.0, vol_db := 0.0, pitch_rand := 0.0) -> void:
	if not streams.has(name):
		return
	for a in pool:
		if not a.playing:
			a.stream = streams[name]
			a.pitch_scale = pitch * (1.0 + randf_range(-pitch_rand, pitch_rand))
			a.volume_db = vol_db
			a.play()
			return
	# all busy: steal the first
	var b := pool[0]
	pool.push_back(pool.pop_front())
	b.stream = streams[name]
	b.pitch_scale = pitch
	b.volume_db = vol_db
	b.play()


func fish() -> void:
	# rising pitch while collecting in a chain (Astro coin feel)
	_fish_chain = min(_fish_chain + 1, 12)
	_fish_chain_t = 0.7
	play("fish", pow(2.0, (_fish_chain - 1) / 12.0 * 1.0), -4.0)


func play_music(path: String, vol_db := -6.0) -> void:
	if not ResourceLoader.exists(path):
		return
	var st: AudioStream = load(path)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	if music_a.stream == st and music_a.playing:
		return
	var old := music_a
	music_a = music_b
	music_b = old
	music_a.stream = st
	music_a.volume_db = -40.0
	music_a.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(music_a, "volume_db", vol_db, 1.2)
	if music_b.playing:
		tw.tween_property(music_b, "volume_db", -50.0, 1.2)
		tw.chain().tween_callback(music_b.stop)


func stop_music(fade := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(music_a, "volume_db", -50.0, fade)
	tw.tween_callback(music_a.stop)


func play_ambience(path: String) -> void:
	if ResourceLoader.exists(path):
		var st: AudioStream = load(path)
		if st is AudioStreamOggVorbis:
			(st as AudioStreamOggVorbis).loop = true
		ambience.stream = st
		ambience.play()


func stop_ambience() -> void:
	ambience.stop()
