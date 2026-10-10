class_name CharacterLooks
extends RefCounted
## Karakter verisinden (cinsiyet, yaş, rol, kıyafet renkleri, başlık, sakal) gerçekçi figür
## görünüşü üretir. Aynı karakter her zaman aynı yüzü/bedeni alır (kimliğe göre tohumlanır).

const SKIN := [Color(0.90, 0.74, 0.64), Color(0.80, 0.61, 0.49), Color(0.64, 0.46, 0.34)]
const WHITE_CLOTH := Color(0.95, 0.94, 0.90)
const GOLD := Color(0.86, 0.69, 0.32)

const FACE_KEYS := ["nose_wide", "nose_long", "nose_hump", "chin_prom", "chin_wide", "face_fat",
	"face_square", "mouth_wide", "eyes_big", "cheekbones"]

# role -> (kilo, kas, boy) eğilimleri
const ROLE_BODY := {
	"sultan": [0.0, 0.35, 0.25], "official": [0.35, 0.0, 0.0], "scribe": [-0.2, -0.2, 0.0], "clerk": [-0.1, -0.1, 0.0],
	"guard": [0.0, 0.8, 0.35], "physician": [-0.1, -0.1, 0.0], "servant": [0.2, 0.2, -0.1], "scholar": [-0.35, -0.3, -0.1],
	"envoy": [0.1, 0.0, 0.25], "artist": [-0.2, 0.0, 0.0], "valide": [0.15, 0.0, 0.0], "harem": [-0.1, 0.0, 0.0],
	"harem_staff": [0.0, 0.0, -0.1], "chamberlain": [0.1, 0.0, 0.0], "child": [-0.2, 0.0, 0.0],
}


static func _col(hex: String, fallback: Color) -> Color:
	if hex == "":
		return fallback
	return Color("#" + hex) if not hex.begins_with("#") else Color(hex)


static func for_character(c: Dictionary, id: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id + "_yuz")
	var look: Dictionary = c.get("look", {})
	var female: bool = String(c.get("gender", "m")) == "f"
	var age := float(c.get("age", 30))
	var role := String(c.get("role", "servant"))
	var shapes := {}
	var child := role == "child" and age < 16.0
	if female and not child:
		shapes["female"] = 1.0
	var old := clampf((age - 32.0) / 38.0, 0.0, 1.0)
	if old > 0.0:
		shapes["old"] = old * 0.95
		if female:
			shapes["female_old"] = old * 0.95
	var rb: Array = ROLE_BODY.get(role, [0.0, 0.0, 0.0])
	var weight := clampf(float(rb[0]) + rng.randf_range(-0.3, 0.35) + old * 0.2, -0.7, 0.9)
	if weight > 0.0:
		shapes["heavy"] = weight
		if female:
			shapes["female_heavy"] = weight
	elif weight < 0.0:
		shapes["thin"] = -weight
	var mus := clampf(float(rb[1]) + rng.randf_range(-0.2, 0.2), 0.0, 1.0)
	if mus > 0.05 and not female and not child:
		shapes["muscle"] = mus
	if child:
		for k0 in ["heavy", "female_heavy", "tall", "short"]:
			shapes.erase(k0)
		shapes["thin"] = 0.85
	var h := clampf(float(rb[2]) + rng.randf_range(-0.45, 0.45), -0.8, 0.8)
	if h > 0.0:
		shapes["tall"] = h * 0.8
	else:
		shapes["short"] = -h * 0.8
	for k in FACE_KEYS:
		var amp := 0.7 if not child else 0.3
		if k == "nose_hump" and not female and not child:
			shapes[k] = rng.randf_range(-0.2, 1.0)
			continue
		shapes[k] = rng.randf_range(-amp, amp)
	if child:
		# yuvarlak yüz, büyük gözler, küçük burun
		shapes["eyes_big"] = 0.8
		shapes["face_fat"] = 0.5
		shapes["nose_long"] = -0.6
		shapes["nose_wide"] = -0.3
		shapes["chin_prom"] = -0.5
		shapes["cheekbones"] = -0.4
	if id == "edric":
		shapes["nose_long"] = 0.6
		shapes["face_fat"] = -0.4
	var skin_i := clampi(int(look.get("skin", 1)), 0, 2)
	var skin: Color = SKIN[skin_i]
	skin = skin.lerp(Color(skin.r * 1.03, skin.g * 0.98, skin.b * 0.96), rng.randf())
	if skin_i == 2:
		shapes["african"] = rng.randf_range(0.0, 0.25)
	if rng.randf() < 0.25:
		shapes["asian"] = rng.randf_range(0.0, 0.25)

	# saç / sakal rengi
	var beard := String(look.get("beard", ""))
	var hair := Color(0.07, 0.05, 0.035)
	if rng.randf() < 0.3:
		hair = Color(0.16, 0.10, 0.06)
	if female and rng.randf() < 0.25:
		hair = Color(0.28, 0.13, 0.07)
	if beard == "grey" or (old > 0.6 and beard != "white"):
		hair = Color(0.5, 0.48, 0.45)
	if beard == "white":
		hair = Color(0.86, 0.85, 0.82)
	var eyes := ["darkbrown", "brown", "brown", "darkbrown", "hazel"]
	if skin_i == 0:
		eyes += ["green", "grey", "hazel", "blue"]
	var eye: String = eyes[rng.randi() % eyes.size()]

	var robe := _col(String(look.get("robe", "")), Color(0.8, 0.75, 0.65))
	var outer := _col(String(look.get("outer", "")), robe.darkened(0.3))
	var accent := _col(String(look.get("accent", "")), GOLD)
	var head := String(look.get("head", ""))
	var outfit := []
	var rich := role in ["sultan", "valide", "official", "harem", "envoy"]
	var pats := [Vector4(1, 0, 0, 0), Vector4(0, 1, 0, 0), Vector4(0, 0, 0, 1)]
	var outer_pat: Vector4 = pats[rng.randi() % pats.size()] if rich else Vector4.ZERO
	var robe_pat := Vector4(0, 0, 1, 0) if rng.randf() < 0.5 else Vector4(0, 0, 0, 1)
	var staff := head.begins_with("scarf") or head == "cook"
	var has_kaftan := not staff
	outfit.append({"mesh": "entari_in", "color": robe, "pattern": robe_pat if rich or rng.randf() < 0.5 else Vector4.ZERO,
		"pattern_color": robe.lerp(accent, 0.45), "scale": 3.5, "trim": accent.darkened(0.2)})
	if has_kaftan:
		outfit.append({"mesh": "kaftan", "color": outer, "pattern": outer_pat, "pattern_color": accent, "metal": 0.55 if rich else 0.0,
			"scale": 2.2, "trim": accent, "sheen": 0.35 if rich else 0.15, "rough": 0.62 if rich else 0.82})
	else:
		# hizmetliler: entariyle aynı renkte sade, desensiz üst giysi
		outfit.append({"mesh": "kaftan", "color": robe.darkened(0.08), "trim": robe.darkened(0.25), "trim_pattern": Vector4.ZERO,
			"sheen": 0.1, "rough": 0.88})
	outfit.append({"mesh": "sash", "color": accent, "pattern": Vector4(0, 0, 1, 0), "pattern_color": accent.darkened(0.35), "scale": 6.0})
	var shoe_col := Color(0.78, 0.6, 0.18)   # sarı çedik
	if role == "sultan":
		shoe_col = Color(0.55, 0.1, 0.1)
	elif role in ["servant", "guard", "harem_staff"]:
		shoe_col = Color(0.25, 0.16, 0.1)
	outfit.append({"mesh": "shoes", "color": shoe_col, "rough": 0.45, "sheen": 0.1})
	# başlık
	match head:
		"sultan":
			outfit.append({"mesh": "hw_sultan", "color": WHITE_CLOTH, "cap_color": Color(0.62, 0.08, 0.1)})
		"vezir":
			outfit.append({"mesh": "hw_vezir", "color": WHITE_CLOTH, "trim": GOLD})
		"sarik":
			outfit.append({"mesh": "hw_sarik", "color": WHITE_CLOTH, "cap_color": outer})
		"sarik_small":
			outfit.append({"mesh": "hw_sarik_small", "color": WHITE_CLOTH.darkened(0.04), "cap_color": outer})
		"kadi":
			outfit.append({"mesh": "hw_kadi", "color": WHITE_CLOTH, "cap_color": WHITE_CLOTH})
		"bork":
			outfit.append({"mesh": "hw_bork", "color": Color(0.9, 0.88, 0.82), "trim": GOLD})
		"takke":
			outfit.append({"mesh": "hw_takke", "color": outer.darkened(0.1)})
		"cook":
			outfit.append({"mesh": "hw_cook", "color": WHITE_CLOTH})
		"foreign_hat":
			outfit.append({"mesh": "hw_foreign_hat", "color": Color(0.1, 0.1, 0.12), "trim": Color(0.12, 0.12, 0.14)})
		"valide":
			outfit.append({"mesh": "hw_valide", "color": outer, "trim": GOLD, "trim_pattern": Vector4(0, 0, 0, 1)})
			outfit.append({"mesh": "hair_f", "color": hair})
		"hotoz_blue", "hotoz_red", "hotoz":
			var hc := Color(0.16, 0.26, 0.52) if head == "hotoz_blue" else Color(0.55, 0.08, 0.1)
			if head == "hotoz":
				hc = _col(String(look.get("hotoz_color", "")), hc)
			outfit.append({"mesh": "hw_hotoz", "color": hc, "trim": GOLD, "trim_pattern": Vector4(0, 0, 0, 1)})
			outfit.append({"mesh": "hair_f", "color": hair})
		"scarf_dark":
			outfit.append({"mesh": "hw_scarf", "color": Color(0.24, 0.21, 0.27)})
		"scarf_light":
			outfit.append({"mesh": "hw_scarf", "color": Color(0.86, 0.82, 0.74), "pattern": Vector4(0, 0, 0, 1), "pattern_color": Color(0.7, 0.6, 0.45)})
		_:
			if female:
				outfit.append({"mesh": "hair_f", "color": hair})
	# sakal
	match beard:
		"short":
			outfit.append({"mesh": "beard_short", "color": hair})
		"long":
			outfit.append({"mesh": "beard_long", "color": hair})
		"grey":
			outfit.append({"mesh": "beard_long", "color": hair})
		"white":
			outfit.append({"mesh": "beard_full", "color": hair})
	var stubble := 0.0
	if not female and not child:
		stubble = 0.35 if beard == "" else 0.55
	var res := {"shapes": shapes, "skin": skin, "hair": hair, "eye": eye, "stubble": stubble, "scalp": 0.0 if female else 0.25,
		"outfit": outfit, "lip": Color(0.6, 0.3, 0.3) if female else Color(0.55, 0.33, 0.3)}
	if child:
		# boy: 5 yaşında ~%55, 15 yaşında ~%92; baş gövdeye göre daha iri
		res["scale"] = clampf(0.4 + age * 0.035, 0.45, 0.95)
		res["head_scale"] = 1.0 + 0.42 * clampf(1.0 - age / 16.0, 0.0, 1.0)
		res["scalp"] = 0.0 if female else 0.15
	return res
