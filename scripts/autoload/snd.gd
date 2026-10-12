extends Node
## Lightweight UI sound effects and ambient music (synthesized original audio in assets/audio).

var _players: Array = []
var _streams := {}
var _music: AudioStreamPlayer


func _ready() -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	for n in ["click", "coin", "week", "success", "error", "page"]:
		var path := "res://assets/audio/%s.wav" % n
		if ResourceLoader.exists(path):
			_streams[n] = load(path)
	if ResourceLoader.exists("res://assets/audio/music.ogg"):
		_streams["music"] = load("res://assets/audio/music.ogg")
	if _streams.has("music") and _streams["music"] is AudioStreamOggVorbis:
		(_streams["music"] as AudioStreamOggVorbis).loop = true


func play(n: String, vol := 0.0) -> void:
	if not _streams.has(n):
		return
	var v := float(G.settings.get("sfx", 0.8))
	if v <= 0.01:
		return
	for p in _players:
		var ap := p as AudioStreamPlayer
		if not ap.playing:
			ap.stream = _streams[n]
			ap.volume_db = linear_to_db(v) + vol
			ap.play()
			return


func click() -> void:
	play("click", -6.0)


func music(on := true) -> void:
	if not _streams.has("music"):
		return
	var v := float(G.settings.get("music", 0.6))
	if not on or v <= 0.01:
		_music.stop()
		return
	_music.stream = _streams["music"]
	_music.volume_db = linear_to_db(v) - 12.0
	if not _music.playing:
		_music.play()
