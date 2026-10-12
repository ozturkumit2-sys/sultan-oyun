class_name FurnitureView
extends Node2D
## One y-sorted piece of furniture (or the front part of a chair).

var def: Dictionary
var w: SimWorld
var part := ""


func setup(d: Dictionary, world: SimWorld, p := "") -> void:
	def = d
	w = world
	part = p
	var cells: Array = d["cells"]
	var mnx := 999.0
	var mny := 999.0
	var mxx := -999.0
	var mxy := -999.0
	for c in cells:
		mnx = minf(mnx, c[0])
		mny = minf(mny, c[1])
		mxx = maxf(mxx, c[0])
		mxy = maxf(mxy, c[1])
	var sp := Vector2((mnx + mxx + 1.0) * 0.5, (mny + mxy + 1.0) * 0.5)
	var bias := 0.0
	match d["type"]:
		"chair", "office_chair", "stool", "armchair":
			bias = 3.0 if part == "back" else -3.0
		"boss_chair":
			sp = Vector2(d["seat"][0], d["seat"][1])
			bias = -3.0
		"sofa":
			sp = Vector2(mnx + 0.5, mny + 0.5)
			bias = -6.0
	position = Iso.to_screen(sp) + Vector2(0, bias)


func _draw() -> void:
	FurnitureArt.draw(self, def, -position, w, part)
