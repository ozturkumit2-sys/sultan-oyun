class_name Mats
extends RefCounted
## Saray malzemeleri. Dokular assets/textures altındaki özgün PNG dosyalarıdır.

const TEX_DIR := "res://assets/textures/"

## tex: doku adı, tile: metre başına tekrar (0 = gerilmiş), color: çarpan renk (hex)
const DEFS := {
	# --- vertex rengiyle boyanan ortak taban malzemeler (draw call tasarrufu) ---
	"marble": {"tex": "marble", "tile": 2.0, "rough": 0.3, "vcol": true},
	"marble_warm": {"base": "marble", "color": "efe2cc", "tile": 2.0},
	"stone_red": {"base": "marble", "color": "a04c3c", "tile": 1.0},
	"stone_white": {"base": "marble", "color": "f4eee2", "tile": 1.0},
	"marble_floor": {"tex": "marble_tiles", "tile": 2.4, "rough": 0.3, "spec": 0.45, "vcol": true},
	"marble_dark_floor": {"base": "marble_floor", "color": "8d8a96", "tile": 2.4},
	"paving": {"tex": "stone_paving", "tile": 3.4, "rough": 0.85, "vcol": true},
	"paving_in": {"base": "paving", "color": "d6cbb8", "tile": 2.6},
	"path": {"base": "paving", "color": "e7dcc6", "tile": 2.0},
	"plaster": {"tex": "plaster", "tile": 3.0, "rough": 0.92, "vcol": true},
	"plaster_ext": {"base": "plaster", "color": "e9dcc3", "tile": 4.0},
	"wood": {"tex": "wood", "tile": 1.5, "rough": 0.55, "vcol": true},
	"wood_dark": {"base": "wood", "color": "7a5a48", "tile": 1.5},
	"brocade": {"tex": "brocade", "tile": 0.7, "rough": 0.8, "vcol": true},
	"brocade_red": {"base": "brocade", "color": "c23a3f", "tile": 0.7},
	"brocade_green": {"base": "brocade", "color": "2f8a5f", "tile": 0.7},
	"brocade_blue": {"base": "brocade", "color": "3b5fa8", "tile": 0.7},
	"brocade_gold": {"base": "brocade", "color": "d9b45a", "tile": 0.7},
	"brocade_purple": {"base": "brocade", "color": "7d3f86", "tile": 0.7},
	"solid": {"rough": 0.85, "vcol": true},
	"fabric_cream": {"base": "solid", "color": "efe5cf"},
	"curtain_red": {"base": "solid", "color": "8e2030"},
	"curtain_green": {"base": "solid", "color": "1f5e47"},
	"black": {"base": "solid", "color": "141416"},
	"parchment": {"base": "solid", "color": "e8d9b5"},
	"red_clay": {"base": "solid", "color": "a8553a"},
	"food": {"base": "solid", "color": "d2913f"},
	"foliage": {"tex": "foliage", "tile": 1.4, "rough": 0.9, "vcol": true},
	"foliage_dark": {"base": "foliage", "color": "8fa88a", "tile": 1.4},
	"foliage_light": {"base": "foliage", "color": "e0f0c8", "tile": 1.4},
	"leaf_dark": {"base": "solid", "color": "1b3a20"},
	"leaf": {"base": "solid", "color": "3a6a2a"},
	"leaf_light": {"base": "solid", "color": "5f8a35"},
	"bark": {"base": "solid", "color": "54402f"},
	"soil": {"base": "solid", "color": "5b4532"},
	"banner_red": {"base": "solid", "color": "a3202c"},
	"banner_blue": {"base": "solid", "color": "24467d"},
	"banner_green": {"base": "solid", "color": "1d6b45"},
	"banner_purple": {"base": "solid", "color": "5d2c73"},
	"metal": {"rough": 0.38, "metal": 0.8, "vcol": true},
	"gold_plain": {"base": "metal", "color": "c9a04a"},
	"brass": {"base": "metal", "color": "b08a3e"},
	"iron": {"base": "metal", "color": "2b2b30"},
	"steel": {"base": "metal", "color": "a8acb4"},
	"grass": {"tex": "grass", "tile": 3.0, "rough": 0.95, "vcol": true},
	"hedge": {"base": "grass", "color": "6f9a5c", "tile": 1.5},
	"ground_far": {"base": "grass", "color": "8a9a6a", "tile": 12.0},
	"lead": {"tex": "lead", "tile": 0.0, "rough": 0.55, "metal": 0.3, "vcol": true},
	"lead_roof": {"base": "lead", "color": "e8e8e8", "tile": 4.0},
	# --- kendine özgü dokular ---
	"wood_floor": {"tex": "wood_floor", "tile": 3.0, "rough": 0.55},
	"stone_ext": {"tex": "stone_block", "tile": 3.0, "rough": 0.9},
	"iznik": {"tex": "iznik", "tile": 1.0, "rough": 0.3},
	"iznik_blue": {"tex": "iznik_blue", "tile": 1.0, "rough": 0.3},
	"iznik_green": {"tex": "iznik_green", "tile": 1.0, "rough": 0.3},
	"ceiling": {"tex": "wood_ceiling", "tile": 3.0, "rough": 0.7},
	"carpet_red": {"tex": "carpet_red", "tile": 0.0, "rough": 0.95},
	"carpet_blue": {"tex": "carpet_blue", "tile": 0.0, "rough": 0.95},
	"carpet_green": {"tex": "carpet_green", "tile": 0.0, "rough": 0.95},
	"flowers": {"tex": "flowers", "tile": 1.6, "rough": 0.9},
	"gold": {"tex": "gold", "tile": 0.8, "rough": 0.32, "metal": 0.85},
	"dome_in": {"tex": "dome_paint", "tile": 0.0, "rough": 0.75},
	"books": {"tex": "books", "tile": 2.0, "rough": 0.8},
	"lamp": {"color": "ffe2a0", "emission": "ffb648", "emit": 3.0},
	"lamp_glass": {"color": "c8f0e0", "emission": "9ff0c8", "emit": 1.2},
	"fire": {"color": "ff8a2a", "emission": "ff6a10", "emit": 4.0},
	"window": {"tex": "stained_glass", "tile": 0.0, "emission_tex": true, "emit": 1.6},
	"lattice": {"tex": "lattice", "tile": 1.2, "color": "d9b45a", "scissor": true, "metal": 0.6, "rough": 0.35, "cull_off": true},
	"water": {"shader": "water"},
	"sea": {"shader": "sea"},
}

static var _cache := {}
static var _resolve_cache := {}


## Malzeme anahtarını [taban anahtar, köşe rengi] olarak çözer
static func resolve(mat: String) -> Array:
	if _resolve_cache.has(mat):
		return _resolve_cache[mat]
	var def: Dictionary = DEFS.get(mat, {})
	var r: Array
	if def.has("base"):
		r = [String(def["base"]), Color(String(def.get("color", "ffffff")))]
	else:
		r = [mat, Color.WHITE]
	_resolve_cache[mat] = r
	return r


static func tile(mat: String) -> float:
	if DEFS.has(mat):
		return float(DEFS[mat].get("tile", 2.0))
	return 2.0


## Bu malzemenin normal haritası var mı (ağda teğet üretmek gerekir)
static func has_normal(mat: String) -> bool:
	var def: Dictionary = DEFS.get(mat, {})
	if not def.has("tex"):
		return false
	return ResourceLoader.exists(TEX_DIR + String(def["tex"]) + "_n.png")


static func get_mat(mat: String) -> Material:
	if _cache.has(mat):
		return _cache[mat]
	var m: Material = _make(mat)
	_cache[mat] = m
	return m


static func all_for(keys: Array) -> Dictionary:
	var d := {}
	for k in keys:
		d[k] = get_mat(k)
	return d


static func _load_tex(name: String) -> Texture2D:
	var p := TEX_DIR + name + ".png"
	if ResourceLoader.exists(p):
		return load(p) as Texture2D
	return null


static func _make(mat: String) -> Material:
	var def: Dictionary = DEFS.get(mat, {"color": "ff00ff"})
	if def.has("shader"):
		return _make_shader(String(def["shader"]))
	var m := StandardMaterial3D.new()
	m.resource_name = mat
	if def.has("color"):
		m.albedo_color = Color(String(def["color"]))
	if def.has("tex"):
		var t := _load_tex(String(def["tex"]))
		if t:
			m.albedo_texture = t
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		var nt := _load_tex(String(def["tex"]) + "_n")
		if nt:
			m.normal_enabled = true
			m.normal_texture = nt
			m.normal_scale = float(def.get("nscale", 1.0))
	m.roughness = float(def.get("rough", 0.8))
	m.metallic = float(def.get("metal", 0.0))
	m.metallic_specular = float(def.get("spec", 0.5))
	if def.has("emission"):
		m.emission_enabled = true
		m.emission = Color(String(def["emission"]))
		m.emission_energy_multiplier = float(def.get("emit", 1.0))
	if def.get("emission_tex", false):
		m.emission_enabled = true
		m.emission_texture = m.albedo_texture
		m.emission = Color(1, 1, 1)
		m.emission_energy_multiplier = float(def.get("emit", 1.0))
	if def.get("scissor", false):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
	if def.get("cull_off", false):
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if def.get("vcol", false):
		m.vertex_color_use_as_albedo = true
	return m


static func _make_shader(kind: String) -> Material:
	var sh := Shader.new()
	if kind == "water":
		sh.code = """
shader_type spatial;
render_mode blend_mix, cull_back, specular_schlick_ggx;
uniform vec4 shallow : source_color = vec4(0.32, 0.62, 0.66, 1.0);
uniform vec4 deep : source_color = vec4(0.06, 0.27, 0.36, 1.0);
void fragment() {
	vec2 p = UV * 7.0;
	float t = TIME * 0.7;
	float w1 = sin(p.x * 2.3 + t) + sin(p.y * 3.1 - t * 1.2);
	float w2 = sin((p.x + p.y) * 4.7 + t * 0.8) * 0.5;
	vec3 wn = normalize(vec3(cos(p.x * 2.3 + t) * 0.18 + cos((p.x + p.y) * 4.7 + t * 0.8) * 0.08, 1.0,
		cos(p.y * 3.1 - t * 1.2) * 0.18 + cos((p.x + p.y) * 4.7 + t * 0.8) * 0.08));
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	ALBEDO = mix(deep.rgb, shallow.rgb, 0.5 + 0.18 * (w1 + w2));
	ROUGHNESS = 0.06;
	SPECULAR = 0.8;
	ALPHA = 0.88;
}
"""
	else:
		sh.code = """
shader_type spatial;
render_mode blend_mix, cull_back, specular_schlick_ggx;
void fragment() {
	vec2 p = UV * 120.0;
	float t = TIME * 0.35;
	vec3 wn = normalize(vec3(sin(p.x * 0.9 + t) * 0.08, 1.0, cos(p.y * 1.1 - t) * 0.08));
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	ALBEDO = vec3(0.08, 0.26, 0.38);
	ROUGHNESS = 0.12;
	SPECULAR = 0.7;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.resource_name = kind
	return m
