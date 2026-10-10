class_name Locomotion
extends RefCounted
## Navigasyon yolu izleyici + küçük basamak çıkma yardımcısı (oyuncu ve NPC'ler ortak kullanır).
## NavigationAgent3D yerine kullanılır: ara noktalara varış YATAY mesafeyle ölçülür, böylece
## yol köşelerinin yüksekliği farklı olsa bile karakter bir noktada dönüp durmaz.

var path := PackedVector3Array()
var idx := 0
var target := Vector3.ZERO
var active := false
var reach := 0.3          # ara noktaya varış yarıçapı (köşe kesmeyi sınırlar)
var final_reach := 0.35   # son noktaya varış yarıçapı


## Yol hesaplar. Başarısızsa false döner (harita hazır değil / yol yok).
func compute(map: RID, from: Vector3, to: Vector3, end_reach: float = 0.35) -> bool:
	active = false
	idx = 0
	target = to
	final_reach = end_reach
	path = PackedVector3Array()
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return false
	var a := NavigationServer3D.map_get_closest_point(map, from)
	var b := NavigationServer3D.map_get_closest_point(map, to)
	var raw := NavigationServer3D.map_get_path(map, a, b, true)
	if raw.is_empty():
		return false
	for q in raw:
		if path.is_empty() or flat(path[path.size() - 1], q) > 0.12:
			path.append(q)
	active = true
	return true


## Bir sonraki ara noktaya yatay birim yön. Yol bittiğinde active=false olur ve ZERO döner.
func next_dir(pos: Vector3) -> Vector3:
	if not active:
		return Vector3.ZERO
	while idx < path.size():
		var wp := path[idx]
		var last := idx == path.size() - 1
		var d := flat(pos, wp)
		if d < (final_reach if last else reach):
			idx += 1
			continue
		# ara noktayı (yan kayarak) geçtiysek bir sonrakine geç
		if not last and idx > 0 and d < 1.2:
			var prev := path[idx - 1]
			var seg := Vector2(wp.x - prev.x, wp.z - prev.z)
			var rel := Vector2(wp.x - pos.x, wp.z - pos.z)
			if seg.dot(rel) < 0.0:
				idx += 1
				continue
		break
	if idx >= path.size():
		active = false
		return Vector3.ZERO
	var w := path[idx]
	var v := Vector3(w.x - pos.x, 0.0, w.z - pos.z)
	return v.normalized() if v.length() > 0.001 else Vector3.ZERO


## Yolun kalan yatay uzunluğu
func remaining(pos: Vector3) -> float:
	if not active or idx >= path.size():
		return 0.0
	var s := flat(pos, path[idx])
	for i in range(idx, path.size() - 1):
		s += flat(path[i], path[i + 1])
	return s


func stop() -> void:
	active = false


static func flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Önündeki alçak bir basamağa (eşik, kürsü, köşk zemini) çıkmayı dener; çıkılan yüksekliği döndürür (0 = çıkamadı).
## CharacterBody3D kendiliğinden basamak çıkamaz; bu yüzden hareket bir duvara takıldığında çağrılır.
static func try_step_up(body: CharacterBody3D, dir: Vector3, max_h: float = 0.47) -> float:
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return 0.0
	dir = dir.normalized()
	var xf := body.global_transform
	var up := Vector3(0.0, max_h, 0.0)
	if body.test_move(xf, up):
		return 0.0
	var xf_up := xf.translated(up)
	var fwd := dir * 0.28
	if body.test_move(xf_up, fwd):
		return 0.0
	var xf_f := xf_up.translated(fwd)
	var col := KinematicCollision3D.new()
	if not body.test_move(xf_f, -up - Vector3(0.0, 0.05, 0.0), col):
		return 0.0
	if col.get_normal().y < 0.7:
		return 0.0
	var land_y := xf_f.origin.y + col.get_travel().y
	var rise := land_y - xf.origin.y
	if rise < 0.03 or rise > max_h:
		return 0.0
	body.global_position = xf.origin + Vector3(0.0, rise + 0.02, 0.0) + dir * 0.06
	return rise + 0.02
