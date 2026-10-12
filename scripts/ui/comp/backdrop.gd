class_name Backdrop
extends Control
## Section environment: soft vertical gradient, atmospheric glows and faint botanical line art.
## The palette eases between sections (Home, Lab, Products, Company, Finance, World).

var env_key := "home"
var _cols: Array = []
var _from: Array = []
var _to: Array = []
var _t := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cols = UI.env(env_key)
	set_process(false)


func set_env(k: String) -> void:
	if k == env_key and not _cols.is_empty():
		return
	env_key = k
	_from = _cols.duplicate() if not _cols.is_empty() else UI.env(k)
	_to = UI.env(k)
	_t = 0.0
	set_process(true)


func _process(delta: float) -> void:
	_t = minf(1.0, _t + delta * 3.0)
	_cols = []
	for i in _to.size():
		_cols.append((_from[i] as Color).lerp(_to[i], _t))
	queue_redraw()
	if _t >= 1.0:
		set_process(false)


func _draw() -> void:
	if _cols.is_empty():
		_cols = UI.env(env_key)
	var top: Color = _cols[0]
	var bot: Color = _cols[1]
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), PackedColorArray([top, top, bot, bot]))
	_glow(Vector2(size.x * 0.92, size.y * 0.12), size.x * 0.75, _cols[2], 0.05)
	_glow(Vector2(size.x * 0.02, size.y * 0.62), size.x * 0.7, _cols[3], 0.045)
	_glow(Vector2(size.x * 0.7, size.y * 1.02), size.x * 0.6, _cols[2], 0.035)
	# faint botanical sprigs in the corners
	var ink := Color(_cols[4], 0.07)
	_sprig(Vector2(size.x - 40, size.y * 0.32), -2.3, size.x * 0.32, ink)
	_sprig(Vector2(30, size.y * 0.86), -0.9, size.x * 0.28, ink)


func _glow(c: Vector2, r: float, col: Color, a: float) -> void:
	for i in 12:
		draw_circle(c, r * (1.0 - i * 0.075), Color(col, a))


func _sprig(base: Vector2, ang: float, length: float, col: Color) -> void:
	var dir := Vector2(cos(ang), sin(ang))
	var nrm := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array()
	for i in 21:
		var t := float(i) / 20.0
		pts.append(base + dir * length * t + nrm * sin(t * PI) * length * 0.08)
	draw_polyline(pts, col, 2.0, true)
	for k in 7:
		var t := 0.15 + k * 0.12
		var p := base + dir * length * t + nrm * sin(t * PI) * length * 0.08
		for sgn in [-1.0, 1.0]:
			var d: Vector2 = (dir * 0.6 + nrm * sgn).normalized()
			var leaf := PackedVector2Array()
			var L := length * (0.16 - k * 0.012)
			for j in 13:
				var u := float(j) / 12.0
				var w := sin(u * PI) * L * 0.28
				leaf.append(p + d * L * u + Vector2(-d.y, d.x) * w)
			for j in range(12, -1, -1):
				var u := float(j) / 12.0
				var w := sin(u * PI) * L * 0.28
				leaf.append(p + d * L * u - Vector2(-d.y, d.x) * w)
			draw_polyline(leaf, col, 1.6, true)
