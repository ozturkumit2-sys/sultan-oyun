class_name DeskSurface
extends Node2D
## The "desk" the office diorama sits on: dotted journal paper + a soft shadow.

var tex: ImageTexture


func _ready() -> void:
	z_index = -40
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var img := Image.create(36, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color("efe3cb"))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if abs(dx) + abs(dy) <= 1:
				img.set_pixel(18 + dx, 18 + dy, Color("d9c7a3"))
	tex = ImageTexture.create_from_image(img)


func _draw() -> void:
	draw_texture_rect(tex, Rect2(-3000, -2200, 6000, 4800), true)
	# soft drop shadow under the floor slab
	var W := float(C.GRID_W)
	var H := float(C.GRID_H)
	for k in 4:
		var g := 10.0 + k * 9.0
		var pts := PackedVector2Array([Iso.P(0, 0) + Vector2(0, g), Iso.P(W, 0) + Vector2(g, g * 0.6), Iso.P(W, H) + Vector2(0, g + 18), Iso.P(0, H) + Vector2(-g, g * 0.6)])
		draw_colored_polygon(pts, Color(0.35, 0.25, 0.12, 0.05))
