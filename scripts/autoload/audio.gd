extends Node
## AudioManager: original synthesized sound effects and background music.
## Sounds are pooled; each id maps to res://assets/audio/<id>.ogg

const SFX_IDS := ["click", "page", "meddle", "coffee", "printer", "printer_fail", "phone", "email", "gasp", "argue", "thump",
	"splash", "papers", "fixed", "lights_off", "lights_on", "crowd", "slam", "pop", "paper_day", "sparkle"]
const MIN_GAP := 0.08

var _streams := {}
var _players: Array = []
var _music: AudioStreamPlayer
var _last := {}


func _ready() -> void:
	for id in SFX_IDS:
		var p := "res://assets/audio/%s.ogg" % id
		if ResourceLoader.exists(p):
			_streams[id] = load(p)
	for i in 8:
		var pl := AudioStreamPlayer.new()
		pl.bus = "Master"
		add_child(pl)
		_players.append(pl)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	var mp := "res://assets/audio/music_office.ogg"
	if ResourceLoader.exists(mp):
		var st = load(mp)
		if st is AudioStreamOggVorbis:
			st.loop = true
		_music.stream = st
		_music.volume_db = -13.0
	Game.settings_changed.connect(_apply_settings)
	_apply_settings()


func _apply_settings() -> void:
	if _music.stream == null:
		return
	if Game.settings.get("music", true):
		if not _music.playing:
			_music.play()
	else:
		_music.stop()


func play(id: String, vol_db := 0.0, pitch := 1.0) -> void:
	if not Game.settings.get("sound", true) or not _streams.has(id):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(id, -10.0)) < MIN_GAP:
		return
	_last[id] = now
	for pl in _players:
		if not pl.playing:
			pl.stream = _streams[id]
			pl.volume_db = vol_db
			pl.pitch_scale = pitch
			pl.play()
			return
