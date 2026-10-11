class_name DragScroll
extends ScrollContainer
## Parmakla sürükleyerek kaydırılan liste (dokunmatik ekranlar için).
## Godot'nun yerleşik sürükleme kaydırması, dokunuş bir düğme/kart/panel üzerinde başlayınca
## kaba ulaşmaz. Bu sınıf olayları GUI'den önce (_input) dinler:
## - parmak eşik kadar kaydırma yönünde hareket ederse kaydırmayı devralır,
## - basılı tutulan düğme/kartın tıklamasını iptal eder (dokunma sayılmaz),
## - bırakınca ataletle yavaşlayarak durur.
## Açık bir pencere (Modal) ya da tam ekran mini oyun varken, onun içinde değilse tepki vermez.

const THRESHOLD := 12.0
const FAR := Vector2(-50000, -50000)
const FRICTION := 4.0   # saniyede hız sönümü
const MAX_VEL := 3500.0

static var _owner: DragScroll = null   # aynı anda tek bir liste kaydırır

var horizontal := false
var _down := false
var _dragging := false
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _last_t := 0
var _vel := 0.0
var _pos := 0.0


func _init() -> void:
	# Yerleşik kaydırmayı kapat (çift kaydırmayı önler); fare tekerleği aşağıda ayrıca işlenir.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _ready() -> void:
	# Sağdan sola dillerde yatay liste sağdan başlar: ilk öğeler görünsün diye en sona kaydır.
	if horizontal and is_layout_rtl():
		for i in 2:
			await get_tree().process_frame
		if is_instance_valid(self) and not _dragging:
			_apply(_max_scroll())


func _exit_tree() -> void:
	if _owner == self:
		_owner = null


func _blocked() -> bool:
	for n in get_tree().get_nodes_in_group("ui_blocker"):
		var c := n as CanvasItem
		if c != null and c.is_visible_in_tree() and not c.is_ancestor_of(self):
			return true
	return false


func _axis(v: Vector2) -> float:
	return v.x if horizontal else v.y


func _max_scroll() -> float:
	var bar: ScrollBar = get_h_scroll_bar() if horizontal else get_v_scroll_bar()
	return maxf(0.0, bar.max_value - bar.page)


func _cur() -> float:
	return float(scroll_horizontal if horizontal else scroll_vertical)


func _apply(v: float) -> void:
	_pos = clampf(v, 0.0, _max_scroll())
	if horizontal:
		scroll_horizontal = int(roundf(_pos))
	else:
		scroll_vertical = int(roundf(_pos))


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.position == FAR:
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or \
				mb.button_index == MOUSE_BUTTON_WHEEL_LEFT or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			if mb.pressed and get_global_rect().has_point(mb.position) and not _blocked() and _max_scroll() > 0.0:
				var dir := -1.0 if (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_LEFT) else 1.0
				_vel = 0.0
				_apply(_cur() + dir * 80.0 * maxf(1.0, mb.factor))
				get_viewport().set_input_as_handled()
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if get_global_rect().has_point(mb.position) and not _blocked():
				_down = true
				_dragging = false
				_start = mb.position
				_last = mb.position
				_last_t = Time.get_ticks_msec()
				_vel = 0.0
				_pos = _cur()
				set_process(false)
		elif _down:
			_down = false
			if _dragging:
				_dragging = false
				if _owner == self:
					_owner = null
				get_viewport().set_input_as_handled()
				if absf(_vel) > 60.0:
					set_process(true)
	elif event is InputEventMouseMotion and _down:
		var mm := event as InputEventMouseMotion
		if mm.position == FAR:
			return
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_down = false
			return
		if not _dragging:
			var d := mm.position - _start
			var along := absf(_axis(d))
			var across := absf(d.y if horizontal else d.x)
			if along >= THRESHOLD and along > across and (_owner == null or _owner == self) and _max_scroll() > 0.0:
				_dragging = true
				_owner = self
				_last = mm.position
				_last_t = Time.get_ticks_msec()
				_cancel_press()
			elif across >= THRESHOLD * 1.5:
				_down = false   # diğer eksende hareket: bu liste karışmaz
				return
			else:
				return
		var step := _axis(mm.position - _last)
		var now := Time.get_ticks_msec()
		var dt := maxf(8.0, float(now - _last_t)) / 1000.0
		_vel = clampf(lerpf(_vel, -step / dt, 0.4), -MAX_VEL, MAX_VEL)
		_last = mm.position
		_last_t = now
		_apply(_pos - step)
		get_viewport().set_input_as_handled()


## Parmağın altında basılı kalan düğme ya da kartın tıklamasını iptal et: imleci uzağa taşıyıp
## orada bırakılmış gibi yap (düğme "içeride bırakıldı" saymaz, kart dokunmayı iptal eder).
func _cancel_press() -> void:
	var mv := InputEventMouseMotion.new()
	mv.position = FAR
	mv.global_position = FAR
	mv.button_mask = MOUSE_BUTTON_MASK_LEFT
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = FAR
	up.global_position = FAR
	var vp := get_viewport()
	vp.push_input.call_deferred(mv, true)
	vp.push_input.call_deferred(up, true)


func _process(delta: float) -> void:
	if _down or absf(_vel) < 20.0:
		_vel = 0.0
		set_process(false)
		return
	var before := _pos
	_apply(_pos + _vel * delta)
	_vel *= exp(-FRICTION * delta)
	if is_equal_approx(before, _pos):
		_vel = 0.0
		set_process(false)
