class_name FamilyTree
extends Control
## Hanedan aile ağacı: ebeveynler, hükümdar, eşleri / çocuk annesi hanımlar ve çocukları.

const ROW_P := 50.0
const ROW_S := 160.0
const ROW_M := 290.0
const ROW_C := 400.0
const CHILD_STEP := 78.0

var _mothers: Array = []
var _kids: Dictionary = {}


func _ready() -> void:
	resized.connect(queue_redraw)
	_collect()


func _collect() -> void:
	_mothers = []
	_kids = {}
	if not GameState.active:
		return
	var wives: Array = GameState.player().get("married_to", [])
	for wid in wives:
		if not GameState.ch(wid).is_empty():
			_mothers.append(wid)
	for cid in HaremEngine.data(GameState)["children"]:
		var c: Dictionary = GameState.ch(cid)
		if c.is_empty():
			continue
		var m: String = c.get("mother", "")
		if not m in _mothers:
			_mothers.append(m)
		if not _kids.has(m):
			_kids[m] = []
		_kids[m].append(cid)
	var most := 0
	for m2 in _kids.keys():
		most = maxi(most, _kids[m2].size())
	custom_minimum_size.y = (ROW_C + most * CHILD_STEP + 10.0) if most > 0 else ROW_M + 70.0


func _box(center: Vector2, title: String, sub: String, col: Color, w: float = 230.0, h: float = 68.0) -> Rect2:
	var r := Rect2(center - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
	draw_style_box(UI.sb(Color(UI.NAVY3, 0.95), col, 2, 10, 6), r)
	var fs := 19 if w >= 200 else 16
	draw_string(UI.font_semi, r.position + Vector2(8, h * 0.42), title, HORIZONTAL_ALIGNMENT_CENTER, w - 16, fs, UI.GOLD2)
	draw_string(UI.font_body, r.position + Vector2(8, h * 0.78), sub, HORIZONTAL_ALIGNMENT_CENTER, w - 16, 14, UI.MUTED)
	return r


func _draw() -> void:
	UI.fonts()
	if not GameState.active:
		return
	var w := size.x
	var cx := w * 0.5
	var f := _box(Vector2(cx - 140, ROW_P), "Sultan Cem", "merhum hükümdar", Color(0.5, 0.5, 0.55))
	var m := _box(Vector2(cx + 140, ROW_P), "Mahinur", "Valide Sultan", UI.GOLD)
	draw_line(Vector2(f.end.x, ROW_P), Vector2(m.position.x, ROW_P), UI.GOLD, 2.0)
	draw_line(Vector2(cx, ROW_P), Vector2(cx, ROW_S - 34), UI.GOLD, 2.0)
	var pl: Dictionary = GameState.player()
	var heir := HaremEngine.heir(GameState)
	_box(Vector2(cx, ROW_S), GameState.full_name(GameState.PLAYER), "%d yaşında • hükümdar" % int(pl["age"]), UI.GOLD2, 260)
	if _mothers.is_empty():
		draw_string(UI.font_body, Vector2(cx - 200, ROW_M), "Henüz eş ya da çocuk yok", HORIZONTAL_ALIGNMENT_CENTER, 400, 16, UI.MUTED)
		return
	var n := _mothers.size()
	var slot := minf(250.0, (w - 20.0) / n)
	var bw := slot - 16.0
	var x0 := cx - slot * (n - 1) * 0.5
	var bus_y := ROW_M - 60.0
	draw_line(Vector2(cx, ROW_S + 34), Vector2(cx, bus_y), Color("d76b8a"), 2.0)
	draw_line(Vector2(x0, bus_y), Vector2(x0 + slot * (n - 1), bus_y), Color("d76b8a"), 2.0)
	for i in range(n):
		var mid: String = _mothers[i]
		var x := x0 + slot * i
		draw_line(Vector2(x, bus_y), Vector2(x, ROW_M - 34), Color("d76b8a"), 2.0)
		var mc: Dictionary = GameState.ch(mid)
		var sub := HaremEngine.rank_name(GameState, mid)
		if not mc.get("alive", true):
			sub = "merhum"
		elif mc.get("gone", false):
			sub = "saraydan ayrıldı"
		elif HaremEngine.pregnancy_known(GameState, mid):
			sub += " • hamile"
		_box(Vector2(x, ROW_M), GameState.short_name(mid), sub if sub != "" else "eşi", Color("d76b8a"), bw)
		var kids: Array = _kids.get(mid, [])
		if kids.is_empty():
			continue
		draw_line(Vector2(x, ROW_M + 34), Vector2(x, ROW_C - 30), Color(UI.GOLD, 0.6), 2.0)
		for k in range(kids.size()):
			var cid: String = kids[k]
			var c: Dictionary = GameState.ch(cid)
			var y := ROW_C + k * CHILD_STEP
			var t := "%d yaşında" % int(c.get("age", 0))
			if not c.get("alive", true):
				t = "merhum"
			elif cid == heir:
				t += " • veliaht"
			var col := UI.GOLD2 if cid == heir else (UI.BLUE if String(c.get("gender", "")) == "m" else Color("c88aa8"))
			if k > 0:
				draw_line(Vector2(x, y - CHILD_STEP + 30), Vector2(x, y - 30), Color(UI.GOLD, 0.4), 2.0)
			_box(Vector2(x, y), String(c.get("full", c.get("name", "?"))), t, col, bw * 0.95, 60.0)
