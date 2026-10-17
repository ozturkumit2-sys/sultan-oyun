class_name Accessories
extends RefCounted
## Hats, glasses and scarf colours for Tarçın. Meshes are built procedurally in the
## Head node's local space (+Y up, +Z forward, origin at the neck pivot).

const SOLID := preload("res://shaders/toon_solid.gdshader")

const ITEMS := {
	"fes": {"name": "Fes", "slot": "head", "price": 30},
	"kasket": {"name": "Kasket", "slot": "head", "price": 40},
	"cicek": {"name": "Sardunya", "slot": "head", "price": 25},
	"denizci": {"name": "Vapurcu Şapkası", "slot": "head", "price": 60},
	"tac": {"name": "Altın Taç", "slot": "head", "price": 150},
	"gozluk": {"name": "Güneş Gözlüğü", "slot": "eyes", "price": 50},
	"yuvarlak": {"name": "Yuvarlak Gözlük", "slot": "eyes", "price": 35},
	"kirmizi": {"name": "Kırmızı Atkı", "slot": "scarf", "price": 0, "color": "d8262f"},
	"lacivert": {"name": "Lacivert Atkı", "slot": "scarf", "price": 20, "color": "23408f"},
	"nazar": {"name": "Nazar Mavisi Atkı", "slot": "scarf", "price": 30, "color": "1e88e5"},
	"sari": {"name": "Sarı Atkı", "slot": "scarf", "price": 20, "color": "f2b33d"},
	"yesil": {"name": "Yeşil Atkı", "slot": "scarf", "price": 20, "color": "2e8b57"},
	"mor": {"name": "Mor Atkı", "slot": "scarf", "price": 25, "color": "7b3fa0"},
}
const ORDER := ["fes", "kasket", "cicek", "denizci", "tac", "gozluk", "yuvarlak", "kirmizi", "lacivert", "nazar", "sari", "yesil", "mor"]

static var _mesh_cache := {}


static func is_owned(id: String) -> bool:
	return id == "" or ITEMS.get(id, {}).get("price", 1) == 0 or id in GameState.owned


static func lin(hex: String) -> Color:
	return Color(hex).srgb_to_linear()


static func _mat(gloss := 0.3, rim := 0.35) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SOLID
	m.set_shader_parameter("use_vertex", 1.0)
	m.set_shader_parameter("gloss", gloss)
	m.set_shader_parameter("rim_strength", rim)
	return m


## Applies an equipment dictionary {head, eyes, scarf} to a cat.
static func apply(cat: CatVisual, eq: Dictionary) -> void:
	if not cat.parts.has("Head"):
		return
	var head: Node3D = cat.parts["Head"]
	for c in head.get_children():
		if String(c.name).begins_with("Acc_"):
			head.remove_child(c)
			c.queue_free()
	for slot in ["head", "eyes"]:
		var id: String = eq.get(slot, "")
		if id != "" and ITEMS.has(id):
			var node := build(id)
			if node:
				node.name = "Acc_" + slot
				head.add_child(node)
	var sc: String = eq.get("scarf", "kirmizi")
	var col: String = ITEMS.get(sc, ITEMS["kirmizi"]).get("color", "d8262f")
	cat.set_scarf_color(Color(col))


static func build(id: String) -> Node3D:
	var root := Node3D.new()
	match id:
		"fes":
			var mb := MeshBuilder.new()
			mb.cylinder(Vector3(0, 0.0, 0), 0.14, 0.2, lin("b51f24"), 24, true, false, lin("9c171c"), 0.108)
			# tassel: cord over the top and a little black brush
			mb.box(Vector3(0.05, 0.202, 0.0), Vector3(0.1, 0.014, 0.014), lin("1b1416"))
			mb.cylinder(Vector3(0.108, 0.09, 0.0), 0.02, 0.11, lin("1b1416"), 8, true, true, Color(-1, 0, 0), 0.007)
			var mi := _mi(mb, _mat(0.0, 0.4))
			mi.position = Vector3(0, 0.405, 0.03)
			mi.rotation = Vector3(-0.14, 0, 0.1)
			root.add_child(mi)
		"kasket":
			var mb2 := MeshBuilder.new()
			mb2.dome(Vector3.ZERO, 0.255, lin("7a6650"), 20, 6, 0.42)
			mb2.cylinder(Vector3(0, -0.01, 0), 0.258, 0.03, lin("5b4b3b"), 20, false)
			mb2.sphere(Vector3(0, 0.0, 0.2), 0.17, lin("6b5846"), 14, 6, Vector3(0.95, 0.12, 0.6))
			mb2.sphere(Vector3(0, 0.105, 0.0), 0.022, lin("5b4b3b"), 8, 4)
			var mi2 := _mi(mb2, _mat(0.0, 0.3))
			mi2.position = Vector3(0, 0.39, 0.05)
			mi2.rotation = Vector3(0.12, 0, 0)
			root.add_child(mi2)
		"denizci":
			var mb3 := MeshBuilder.new()
			mb3.cylinder(Vector3.ZERO, 0.2, 0.12, lin("f6f4ef"), 22, true, false, lin("ffffff"), 0.21)
			mb3.cylinder(Vector3(0, 0.005, 0), 0.203, 0.04, lin("1d2d5c"), 22, false)
			mb3.sphere(Vector3(0, 0.0, 0.17), 0.12, lin("1a1a22"), 12, 6, Vector3(1.0, 0.12, 0.6))
			mb3.box(Vector3(0, 0.07, 0.205), Vector3(0.05, 0.05, 0.01), lin("e6b847"))
			var mi3 := _mi(mb3, _mat(0.4, 0.35))
			mi3.position = Vector3(0, 0.42, 0.04)
			mi3.rotation = Vector3(-0.08, 0, 0)
			root.add_child(mi3)
		"tac":
			var mb4 := MeshBuilder.new()
			var gold := lin("f2c23a")
			mb4.cylinder(Vector3.ZERO, 0.14, 0.075, gold, 20, false, false, Color(-1, 0, 0), 0.15)
			for k in 6:
				var a := TAU * k / 6.0
				mb4.cone(Vector3(cos(a) * 0.14, 0.07, sin(a) * 0.14), 0.04, 0.1, gold, 8)
				mb4.sphere(Vector3(cos(a) * 0.14, 0.18, sin(a) * 0.14), 0.018, lin("fff1a8"), 8, 4)
			mb4.sphere(Vector3(0, 0.04, 0.148), 0.026, lin("d6243b"), 10, 5, Vector3(1, 1, 0.6))
			mb4.sphere(Vector3(0.11, 0.04, 0.1), 0.02, lin("1e88e5"), 8, 4, Vector3(1, 1, 0.6))
			mb4.sphere(Vector3(-0.11, 0.04, 0.1), 0.02, lin("2e8b57"), 8, 4, Vector3(1, 1, 0.6))
			var mt := _mat(1.0, 0.6)
			mt.set_shader_parameter("emission_amount", 0.15)
			var mi4 := _mi(mb4, mt)
			mi4.position = Vector3(0, 0.44, 0.03)
			mi4.rotation = Vector3(-0.1, 0, 0.12)
			root.add_child(mi4)
		"cicek":
			var mb5 := MeshBuilder.new()
			for k in 6:
				var a := TAU * k / 6.0
				mb5.sphere(Vector3(cos(a) * 0.065, sin(a) * 0.065, 0), 0.05, lin("e8434f"), 10, 6, Vector3(1, 1, 0.35))
			mb5.sphere(Vector3(0, 0, 0.018), 0.032, lin("ffd23f"), 8, 5)
			for k in 2:
				mb5.sphere(Vector3(-0.09 + k * 0.05, -0.1, -0.012), 0.05, lin("3e8e41"), 8, 4, Vector3(0.5, 1.0, 0.25))
			var mi5 := _mi(mb5, _mat(0.0, 0.3))
			mi5.position = Vector3(0.2, 0.43, 0.12)
			mi5.rotation = Vector3(-0.35, 0.35, 0.2)
			root.add_child(mi5)
		"gozluk":
			var mb6 := MeshBuilder.new()
			for sx in [-1.0, 1.0]:
				mb6.sphere(Vector3(sx * 0.105, 0, 0), 1.0, lin("121216"), 16, 8, Vector3(0.085, 0.068, 0.014))
				mb6.box(Vector3(sx * 0.21, 0.01, -0.09), Vector3(0.012, 0.014, 0.18), lin("121216"))
			mb6.box(Vector3(0, 0.02, 0.0), Vector3(0.06, 0.014, 0.014), lin("121216"))
			var mi6 := _mi(mb6, _mat(1.4, 0.2))
			mi6.position = Vector3(0, 0.248, 0.345)
			root.add_child(mi6)
		"yuvarlak":
			var mb7 := MeshBuilder.new()
			for sx in [-1.0, 1.0]:
				mb7.torus(Vector3(sx * 0.105, 0, 0), 0.07, 0.009, lin("c9a227"), 22, 6)
				mb7.box(Vector3(sx * 0.18, 0.01, -0.09), Vector3(0.01, 0.01, 0.18), lin("c9a227"))
			mb7.box(Vector3(0, 0.015, 0.0), Vector3(0.07, 0.01, 0.01), lin("c9a227"))
			var mi7 := _mi(mb7, _mat(1.0, 0.3))
			mi7.position = Vector3(0, 0.248, 0.35)
			root.add_child(mi7)
			# faint lens glint (transparent)
			var lens := MeshBuilder.new()
			for sx in [-1.0, 1.0]:
				lens.sphere(Vector3(sx * 0.105, 0, 0), 1.0, Color(0.8, 0.95, 1.0), 14, 6, Vector3(0.066, 0.066, 0.004))
			var lm := StandardMaterial3D.new()
			lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			lm.albedo_color = Color(0.85, 0.95, 1.0, 0.18)
			lm.vertex_color_use_as_albedo = false
			lm.roughness = 0.1
			lm.metallic_specular = 1.0
			var li := _mi(lens, lm)
			li.position = Vector3(0, 0.248, 0.352)
			root.add_child(li)
		_:
			return null
	return root


static func _mi(mb: MeshBuilder, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(null, m)
	return mi


# ------------------------------------------------------------- 2D icons for the shop
static func draw_icon(ci: CanvasItem, id: String, c: Vector2, s: float) -> void:
	var item: Dictionary = ITEMS.get(id, {})
	match id:
		"fes":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.32, s * 0.3), c + Vector2(s * 0.32, s * 0.3), c + Vector2(s * 0.24, -s * 0.28), c + Vector2(-s * 0.24, -s * 0.28)]), Color("b51f24"))
			ci.draw_line(c + Vector2(0, -s * 0.28), c + Vector2(s * 0.3, -s * 0.2), Color("1b1416"), 3.0)
			ci.draw_line(c + Vector2(s * 0.3, -s * 0.2), c + Vector2(s * 0.32, s * 0.12), Color("1b1416"), 5.0)
		"kasket":
			ci.draw_circle(c + Vector2(0, s * 0.1), s * 0.36, Color("7a6650"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.45, s * 0.1), Vector2(s * 0.9, s * 0.3)), Color(0, 0, 0, 0))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, s * 0.12), c + Vector2(s * 0.5, s * 0.12), c + Vector2(s * 0.42, s * 0.26), c + Vector2(-s * 0.1, s * 0.26)]), Color("5b4b3b"))
		"denizci":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.2), Vector2(s * 0.72, s * 0.3)), Color("f6f4ef"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, s * 0.04), Vector2(s * 0.72, s * 0.1)), Color("1d2d5c"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.3, s * 0.14), c + Vector2(s * 0.3, s * 0.14), c + Vector2(s * 0.22, s * 0.3), c + Vector2(-s * 0.22, s * 0.3)]), Color("1a1a22"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.05, -s * 0.12), Vector2(s * 0.1, s * 0.1)), Color("e6b847"))
		"tac":
			var pts := PackedVector2Array([c + Vector2(-s * 0.38, s * 0.25), c + Vector2(-s * 0.38, -s * 0.2), c + Vector2(-s * 0.2, s * 0.0), c + Vector2(0, -s * 0.32),
				c + Vector2(s * 0.2, s * 0.0), c + Vector2(s * 0.38, -s * 0.2), c + Vector2(s * 0.38, s * 0.25)])
			ci.draw_colored_polygon(pts, Color("f2c23a"))
			ci.draw_circle(c + Vector2(0, s * 0.1), s * 0.06, Color("d6243b"))
		"cicek":
			for k in 5:
				var a := TAU * k / 5.0 - PI * 0.5
				ci.draw_circle(c + Vector2(cos(a), sin(a)) * s * 0.18, s * 0.15, Color("e8434f"))
			ci.draw_circle(c, s * 0.1, Color("ffd23f"))
		"gozluk":
			for sx in [-1.0, 1.0]:
				ci.draw_circle(c + Vector2(sx * s * 0.2, 0), s * 0.17, Color("121216"))
			ci.draw_line(c + Vector2(-s * 0.05, -s * 0.04), c + Vector2(s * 0.05, -s * 0.04), Color("121216"), 4.0)
		"yuvarlak":
			for sx in [-1.0, 1.0]:
				ci.draw_arc(c + Vector2(sx * s * 0.2, 0), s * 0.16, 0, TAU, 24, Color("c9a227"), 4.0, true)
			ci.draw_line(c + Vector2(-s * 0.05, -s * 0.03), c + Vector2(s * 0.05, -s * 0.03), Color("c9a227"), 3.0)
		_:
			if item.has("color"):
				var col := Color(item["color"])
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.38, -s * 0.12), c + Vector2(s * 0.38, -s * 0.12), c + Vector2(s * 0.38, s * 0.06), c + Vector2(-s * 0.38, s * 0.06)]), col)
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.1, s * 0.0), c + Vector2(s * 0.24, s * 0.0), c + Vector2(s * 0.3, s * 0.38), c + Vector2(s * 0.12, s * 0.34)]), col.darkened(0.15))
