class_name CharacterView
extends Node2D
## Draws one office worker procedurally: 8 distinct looks, 5 facial expressions,
## walk / sit / type / phone / coffee / eat / read / fix / search / talk / react animations.

var npc: NPC
var w: SimWorld
var look: Dictionary = {}
var t := 0.0
var walk_phase := 0.0
var blink_t := 2.0
var blinking := 0.0
var react := 0.0          # >0: small jump
var react_kind := ""
var stain := 0.0
var selected := false
var _last_expr := "normal"
var _last_emote := ""
var dark := false
var portrait := false        # used inside UI cards: always faces the viewer, stands still

var skin: Color
var hair: Color
var hair2: Color
var top_c: Color
var shirt_c: Color
var accent: Color
var pants: Color
var shoes: Color
var build := 1.0


func setup(n: NPC, world: SimWorld) -> void:
	npc = n
	w = world
	look = n.def.get("look", {})
	skin = Color(look.get("skin", "#f1c7a3"))
	hair = Color(look.get("hair", "#3a2418"))
	hair2 = Color(look.get("hair2", look.get("hair", "#3a2418")))
	top_c = Color(look.get("top_color", "#79b8e8"))
	shirt_c = Color(look.get("shirt", "#ffffff"))
	accent = Color(look.get("accent", "#e63946"))
	pants = Color(look.get("pants", "#3b3340"))
	shoes = Color(look.get("shoes", "#2a2222"))
	build = float(look.get("build", 1.0))
	t = randf() * 10.0


func _process(delta: float) -> void:
	if npc == null:
		return
	if not portrait:
		visible = npc.present
		if not visible:
			return
		position = Iso.to_screen(npc.pos)
	t += delta
	if npc.pose == "walk":
		walk_phase += delta * 10.0 * maxf(1.0, Game.speed)
	blink_t -= delta
	if blink_t <= 0.0:
		blinking = 0.13
		blink_t = randf_range(2.0, 5.0)
	blinking = maxf(0.0, blinking - delta)
	if npc.expr != _last_expr:
		_last_expr = npc.expr
		if npc.expr in ["surprised", "angry"]:
			react = 0.35
			react_kind = npc.expr
	if npc.emote != _last_emote:
		_last_emote = npc.emote
		if npc.emote in ["exclaim", "anger", "love"]:
			react = maxf(react, 0.25)
	react = maxf(0.0, react - delta)
	stain = maxf(0.0, stain - delta)
	if not portrait:
		# skip re-recording draw commands for people outside the screen
		var sp := get_viewport().get_canvas_transform() * position
		if not get_viewport_rect().grow(140).has_point(sp):
			return
	queue_redraw()


func _expr() -> String:
	if npc.expr_timer > 0.0:
		return npc.expr
	return npc.base_expr()


func _draw() -> void:
	if npc == null or (not npc.present and not portrait):
		return
	var pose: String = npc.pose
	var sitting := pose in ["sit", "type", "eat", "read"] or (pose in ["phone", "coffee"] and _place_is_seat())
	var front := npc.face_front
	var sx := 1.0 if npc.face_right else -1.0
	if portrait:
		pose = "stand"
		sitting = false
		front = true
		sx = 1.0
	if pose == "search":
		sx = 1.0 if fmod(t, 2.4) < 1.2 else -1.0
	var ex := _expr()
	# shadow
	if not portrait:
		Iso.ellipse(self, Vector2(0, 0), 13.0 * build, 5.0, Color(0.15, 0.1, 0.2, 0.2), Color(0, 0, 0, 0))
	if selected:
		var pulse := 0.6 + 0.4 * sin(t * 6.0)
		draw_arc(Vector2.ZERO, 18, 0, TAU, 32, Color(1, 0.85, 0.2, 0.9 * pulse), 2.5, true)
	var lift := 0.0
	if react > 0.0:
		lift = sin(react / 0.35 * PI) * 7.0
	if pose == "walk":
		lift += absf(sin(walk_phase)) * 1.6
	if npc.emote == "cheer" and npc.emote_timer > 0.0 and not sitting:
		lift += absf(sin(t * 9.0)) * 7.0          # little jumps of joy
	var shake_x := 0.0
	if ex == "angry" and npc.expr_timer > 0.0:
		shake_x = sin(t * 40.0) * 1.2
	draw_set_transform(Vector2(shake_x, -lift), 0.0, Vector2(sx, 1.0))
	_draw_body(sitting, front, pose, ex)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not portrait:
		_draw_emote(sitting)


func _place_is_seat() -> bool:
	if npc.act_place == "" or npc.phase != "do":
		return false
	var p: Dictionary = w.office.places.get(npc.act_place, {})
	return p.get("pose", "") == "sit"


# ---------------------------------------------------------------- body

func _draw_body(sitting: bool, front: bool, pose: String, ex: String) -> void:
	var sh := 0.0 if not sitting else 6.0      # how much lower the upper body sits
	var slump := 2.0 if ex == "sad" else 0.0
	var top := -41.0 + sh + slump
	var hip := -18.0 + sh * 0.6
	var head_c := Vector2(0.5 if front else 0.0, -55.0 + sh + slump)
	var sw := 10.5 * build
	var hw := 9.5 * build
	# ---- legs
	if sitting:
		_legs_sitting(front, hip)
	else:
		_legs_standing(pose, hip)
	# ---- far arm (behind body)
	var arms := _arm_targets(pose, sitting, top, ex)
	var sh_l := Vector2(-sw + 1.5, top + 3)
	var sh_r := Vector2(sw - 1.5, top + 3)
	_arm(sh_l, arms[0], front, false)
	# ---- back hair layer (ponytail etc.)
	_hair_back(head_c, front)
	# ---- torso
	_torso(top, hip, sw, hw, front)
	# ---- head
	_head(head_c, front, ex, pose)
	# ---- near arm
	_arm(sh_r, arms[1], front, true)
	_held_item(pose, arms[1], arms[0])


func _legs_standing(pose: String, hip: float) -> void:
	var ph := walk_phase if pose == "walk" else 0.0
	var s := sin(ph)
	for k in [-1, 1]:
		var swing: float = s * 4.0 * k if pose == "walk" else 0.0
		var lift: float = maxf(0.0, -s * k) * 2.5 if pose == "walk" else 0.0
		var hp := Vector2(k * 4.2 * build, hip)
		var ft := Vector2(k * 4.2 * build + swing, -3.0 - lift)
		Iso.capsule(self, hp, ft, 3.6 * build, pants)
		Iso.ellipse(self, ft + Vector2(1.5, 1.5), 4.6, 2.6, shoes)


func _legs_sitting(front: bool, hip: float) -> void:
	var dirx := 1.0 if front else -1.0
	for k in [-1, 1]:
		var hp := Vector2(k * 3.2 - dirx * 1.0, hip + 1.0)
		var knee := Vector2(dirx * 11.0 + k * 2.5, hip + 4.0)
		var ft := Vector2(dirx * 12.5 + k * 2.5, -2.0)
		Iso.capsule(self, hp, knee, 3.8 * build, pants)
		Iso.capsule(self, knee, ft, 3.3 * build, Iso.shade(pants, 0.92))
		Iso.ellipse(self, ft + Vector2(dirx * 2.0, 1.0), 4.4, 2.4, shoes)


func _arm_targets(pose: String, sitting: bool, top: float, ex: String) -> Array:
	# returns [far_hand, near_hand] in canonical (facing right) space
	var down_l := Vector2(-12.0 * build, top + 19)
	var down_r := Vector2(12.0 * build, top + 19)
	match pose:
		"walk":
			var s := sin(walk_phase) * 4.0
			return [down_l + Vector2(-s, 0), down_r + Vector2(s, 0)]
		"type":
			var b := sin(t * 16.0) * 1.4
			return [Vector2(9, top + 15 + b), Vector2(15, top + 14 - b)]
		"phone":
			return [down_l, Vector2(8, top - 6)]
		"coffee":
			var sip := fmod(t, 4.5) < 0.9
			return [down_l, Vector2(7, top - 2) if sip else Vector2(10, top + 9)]
		"eat":
			var bite := fmod(t, 3.0) < 0.8
			return [Vector2(6, top + 12), Vector2(7, top - 2) if bite else Vector2(11, top + 8)]
		"read":
			return [Vector2(9, top + 10), Vector2(15, top + 9)]
		"fix":
			var f := sin(t * 10.0) * 2.0
			return [Vector2(12, top + 16 + f), Vector2(17, top + 12 - f)]
		"search":
			return [Vector2(-15, top + 12), Vector2(15, top + 12)]
	if npc.speaking > 0.0:
		var g := sin(t * 7.0) * 3.0
		return [down_l, Vector2(14, top + 7 + g)]
	if ex == "surprised" and npc.expr_timer > 0.0:
		return [Vector2(-13, top - 6), Vector2(13, top - 6)]
	if ex == "angry" and npc.expr_timer > 0.0:
		return [Vector2(-15, top + 11), Vector2(15, top + 11)]
	return [down_l, down_r]


func _sleeve_color(near: bool) -> Color:
	var st: String = look.get("top", "")
	if st in ["suit", "blazer", "suit_open", "cardigan", "hoodie", "sweater"]:
		return top_c
	return top_c


func _arm(shoulder: Vector2, hand: Vector2, front: bool, near: bool) -> void:
	var sleeve := _sleeve_color(near)
	var mid := shoulder.lerp(hand, 0.55)
	var st: String = look.get("top", "")
	if not near:
		sleeve = Iso.shade(sleeve, 0.9)
	if st == "shirt_rolled" or st == "blouse":
		Iso.capsule(self, shoulder, mid, 3.4 * build, sleeve)
		Iso.capsule(self, mid, hand, 2.9 * build, skin)
	else:
		Iso.capsule(self, shoulder, hand + (shoulder - hand).normalized() * 2.0, 3.4 * build, sleeve)
	if "watch" in look.get("extras", []) and near:
		Iso.capsule(self, hand + (shoulder - hand).normalized() * 3.0, hand + (shoulder - hand).normalized() * 4.5, 2.8, Color("c9c9d1"))
	Iso.ellipse(self, hand, 3.0, 3.0, skin)


func _torso(top: float, hip: float, sw: float, hw: float, front: bool) -> void:
	var st: String = look.get("top", "")
	var pts := PackedVector2Array([
		Vector2(-sw, top + 4), Vector2(-sw + 3, top), Vector2(sw - 3, top), Vector2(sw, top + 4),
		Vector2(hw + 0.5, hip - 2), Vector2(hw - 1.5, hip + 1.5), Vector2(-hw + 1.5, hip + 1.5), Vector2(-hw - 0.5, hip - 2)])
	if not front:
		Iso.poly(self, pts, top_c)
		if st == "hoodie":
			Iso.ellipse(self, Vector2(0, top + 3), 7, 4.5, Iso.shade(top_c, 0.85))
		if st in ["suit", "suit_open", "blazer"]:
			Iso.line(self, Vector2(0, top + 6), Vector2(0, hip - 2), Iso.INK_SOFT)
		return
	match st:
		"suit", "suit_open", "blazer":
			Iso.poly(self, pts, top_c)
			var v := PackedVector2Array([Vector2(-4.5, top), Vector2(4.5, top), Vector2(1.2, top + 13), Vector2(-1.2, top + 13)])
			Iso.poly(self, v, shirt_c, Iso.INK_SOFT)
			if st == "suit":
				Iso.poly(self, PackedVector2Array([Vector2(-1.4, top + 1), Vector2(1.4, top + 1), Vector2(2.0, top + 11), Vector2(0, top + 14), Vector2(-2.0, top + 11)]), accent)
			# lapels
			Iso.line(self, Vector2(-4.5, top), Vector2(-1.2, top + 13), Iso.shade(top_c, 0.7), 1.4)
			Iso.line(self, Vector2(4.5, top), Vector2(1.2, top + 13), Iso.shade(top_c, 0.7), 1.4)
			draw_circle(Vector2(0.5, top + 16), 1.0, Iso.shade(top_c, 0.6))
			if st == "blazer":
				draw_circle(Vector2(-6, top + 8), 1.6, accent)
		"cardigan":
			Iso.poly(self, pts, shirt_c)
			var lpts := PackedVector2Array([Vector2(-sw, top + 4), Vector2(-sw + 3, top), Vector2(-3, top), Vector2(-2, hip + 1.5), Vector2(-hw + 1.5, hip + 1.5), Vector2(-hw - 0.5, hip - 2)])
			var rpts := PackedVector2Array([Vector2(3, top), Vector2(sw - 3, top), Vector2(sw, top + 4), Vector2(hw + 0.5, hip - 2), Vector2(hw - 1.5, hip + 1.5), Vector2(2, hip + 1.5)])
			Iso.poly(self, lpts, top_c)
			Iso.poly(self, rpts, top_c)
			for k in 3:
				draw_circle(Vector2(2.6, top + 5 + k * 5), 0.9, Iso.shade(top_c, 0.6))
		"hoodie":
			Iso.poly(self, pts, top_c)
			Iso.rrect(self, Rect2(Vector2(-6, hip - 9), Vector2(12, 6)), 2, Iso.shade(top_c, 0.88), Iso.INK_SOFT)
			Iso.line(self, Vector2(-2, top + 1), Vector2(-2.5, top + 9), Color("f2f2f2"), 1.2)
			Iso.line(self, Vector2(2, top + 1), Vector2(2.5, top + 9), Color("f2f2f2"), 1.2)
		"sweater":
			Iso.poly(self, pts, top_c)
			Iso.poly(self, PackedVector2Array([Vector2(-5, top - 0.5), Vector2(0, top + 4), Vector2(5, top - 0.5), Vector2(4, top + 2.5), Vector2(0, top + 5.5), Vector2(-4, top + 2.5)]), shirt_c, Iso.INK_SOFT)
			for k in 3:
				Iso.line(self, Vector2(-hw + 1, hip - 2 - k * 1.6), Vector2(hw - 1, hip - 2 - k * 1.6), Iso.shade(top_c, 0.85), 0.8)
		"shirt_rolled":
			Iso.poly(self, pts, top_c)
			Iso.poly(self, PackedVector2Array([Vector2(-5, top - 1), Vector2(0, top + 4), Vector2(-1, top + 6), Vector2(-6, top + 2)]), top_c.lightened(0.25))
			Iso.poly(self, PackedVector2Array([Vector2(5, top - 1), Vector2(0, top + 4), Vector2(1, top + 6), Vector2(6, top + 2)]), top_c.lightened(0.25))
			for k in 3:
				draw_circle(Vector2(0.4, top + 8 + k * 4), 0.8, Iso.shade(top_c, 0.6))
			Iso.rrect(self, Rect2(Vector2(-7, top + 5), Vector2(4.5, 4)), 1, Iso.shade(top_c, 0.9), Iso.INK_SOFT, 0.8)
		"blouse":
			Iso.poly(self, pts, top_c)
			Iso.poly(self, PackedVector2Array([Vector2(-4, top), Vector2(4, top), Vector2(0, top + 6)]), skin, Iso.INK_SOFT)
			Iso.line(self, Vector2(-hw + 0.5, hip - 4), Vector2(hw - 0.5, hip - 4), Iso.shade(top_c, 0.8), 1.2)
		_:
			Iso.poly(self, pts, top_c)
	# accessories on the chest
	var ext: Array = look.get("extras", [])
	if "lanyard" in ext:
		Iso.line(self, Vector2(-4, top), Vector2(-1, top + 13), Color("5b8def"), 1.4)
		Iso.line(self, Vector2(4, top), Vector2(1, top + 13), Color("5b8def"), 1.4)
		Iso.rrect(self, Rect2(Vector2(-3, top + 12), Vector2(6, 7.5)), 1, Color("ffffff"), Iso.INK_SOFT, 0.8)
		draw_rect(Rect2(Vector2(-2, top + 13.5), Vector2(4, 2)), Color("5b8def"))
	if "necklace" in ext:
		draw_arc(Vector2(0, top - 2), 5.5, 0.3, PI - 0.3, 10, Color("c0392b"), 1.4, true)
		for k in 5:
			var a := 0.4 + k * (PI - 0.8) / 4.0
			draw_circle(Vector2(0, top - 2) + Vector2(cos(a), sin(a)) * 5.5, 1.1, Color("e74c3c"))
	if stain > 0.0:
		Iso.ellipse(self, Vector2(2, top + 10), 4.5, 3.5, Color(0.45, 0.28, 0.15, 0.75 * minf(1.0, stain)), Color(0, 0, 0, 0))
		draw_circle(Vector2(-2, top + 14), 1.6, Color(0.45, 0.28, 0.15, 0.7 * minf(1.0, stain)))


func _head(c: Vector2, front: bool, ex: String, pose: String) -> void:
	var r := 14.5
	# neck
	Iso.capsule(self, c + Vector2(0, 9), c + Vector2(0, 14), 3.4, Iso.shade(skin, 0.92))
	var ext: Array = look.get("extras", [])
	if "headphones" in ext:
		draw_arc(c + Vector2(0, 13), 8, 0.2, PI - 0.2, 12, Color("2b2d42"), 2.4, true)
		Iso.ellipse(self, c + Vector2(-7, 16), 3.2, 2.6, Color("f2c14e"))
		Iso.ellipse(self, c + Vector2(7, 16), 3.2, 2.6, Color("f2c14e"))
	if not front:
		Iso.ellipse(self, c, r, r, hair)
		draw_arc(c + Vector2(-2, -3), r - 4, PI * 1.1, PI * 1.55, 8, hair.lightened(0.28), 2.0, true)
		if look.get("hair_style", "") == "bob":
			Iso.rrect(self, Rect2(c + Vector2(-r - 1, -2), Vector2(2 * r + 2, 13)), 5, hair)
		_hair_front(c, false)
		if "headset" in ext:
			draw_arc(c, r + 0.5, PI * 1.05, PI * 1.95, 14, Color("2b2d42"), 2.0, true)
		return
	# ears & face
	Iso.ellipse(self, c + Vector2(-r + 1.0, 1.5), 3.2, 4.0, skin)
	Iso.ellipse(self, c, r, r, skin)
	# blush
	if ex == "happy" or npc.emote == "love":
		Iso.ellipse(self, c + Vector2(-5.5, 5), 3.2, 1.8, Color(1, 0.45, 0.5, 0.35), Color(0, 0, 0, 0))
		Iso.ellipse(self, c + Vector2(9.5, 5), 3.0, 1.7, Color(1, 0.45, 0.5, 0.35), Color(0, 0, 0, 0))
	if ex == "angry" and npc.expr_timer > 0.0:
		Iso.ellipse(self, c + Vector2(2, 2), r - 2, r - 3, Color(1, 0.2, 0.15, 0.12), Color(0, 0, 0, 0))
	_face(c, ex, pose)
	_hair_front(c, true)
	if "glasses" in ext:
		for k in [-1, 1]:
			var gc: Vector2 = c + Vector2(2.5 + k * 5.2, -1)
			var gp := PackedVector2Array([gc + Vector2(-4, -2.5), gc + Vector2(4, -3.5), gc + Vector2(3.5, 2.5), gc + Vector2(-3.5, 2.5)])
			var closed := gp.duplicate()
			closed.append(gp[0])
			draw_polyline(closed, Color("c0392b"), 1.5, true)
		draw_line(c + Vector2(1.2, -1.8), c + Vector2(3.8, -1.8), Color("c0392b"), 1.3)
	if "headset" in ext:
		draw_arc(c, r + 0.5, PI * 1.05, PI * 1.95, 14, Color("2b2d42"), 2.0, true)
		Iso.ellipse(self, c + Vector2(-r + 0.5, 1), 2.5, 3.5, Color("2b2d42"))
		draw_line(c + Vector2(-r + 1, 3), c + Vector2(-2, 9), Color("2b2d42"), 1.3, true)
		draw_circle(c + Vector2(-2, 9), 1.4, Color("2b2d42"))
	if "earrings" in ext:
		draw_circle(c + Vector2(-r + 1.5, 6.5), 1.5, accent)


func _face(c: Vector2, ex: String, pose: String) -> void:
	var fx := 2.5   # 3/4 view: features shifted toward the facing side
	var le := c + Vector2(fx - 5.0, -1.0)
	var re := c + Vector2(fx + 5.0, -1.0)
	var eye := Color("2b2230")
	var closed := blinking > 0.0
	# brows
	var bl := le + Vector2(0, -5.5)
	var br := re + Vector2(0, -5.5)
	var brow_c := Iso.shade(hair, 0.8)
	match ex:
		"angry":
			draw_line(bl + Vector2(-3, -2), bl + Vector2(3, 1), brow_c, 1.8, true)
			draw_line(br + Vector2(-3, 1), br + Vector2(3, -2), brow_c, 1.8, true)
		"sad":
			draw_line(bl + Vector2(-3, 1), bl + Vector2(3, -1.5), brow_c, 1.6, true)
			draw_line(br + Vector2(-3, -1.5), br + Vector2(3, 1), brow_c, 1.6, true)
		"surprised":
			draw_arc(bl + Vector2(0, -1.5), 3.0, PI * 1.15, PI * 1.85, 6, brow_c, 1.5, true)
			draw_arc(br + Vector2(0, -1.5), 3.0, PI * 1.15, PI * 1.85, 6, brow_c, 1.5, true)
		_:
			draw_line(bl + Vector2(-2.5, 0), bl + Vector2(2.5, -0.5), brow_c, 1.4, true)
			draw_line(br + Vector2(-2.5, -0.5), br + Vector2(2.5, 0), brow_c, 1.4, true)
	# eyes
	if closed and ex != "surprised":
		draw_line(le + Vector2(-2, 0), le + Vector2(2, 0), eye, 1.4, true)
		draw_line(re + Vector2(-2, 0), re + Vector2(2, 0), eye, 1.4, true)
	else:
		match ex:
			"happy":
				draw_arc(le + Vector2(0, 1), 2.4, PI, TAU, 8, eye, 1.6, true)
				draw_arc(re + Vector2(0, 1), 2.4, PI, TAU, 8, eye, 1.6, true)
			"surprised":
				for e in [le, re]:
					Iso.ellipse(self, e, 3.2, 3.6, Color("ffffff"), eye, 1.0)
					draw_circle(e + Vector2(0.4, 0.3), 1.5, eye)
			"angry":
				for e in [le, re]:
					Iso.ellipse(self, e + Vector2(0, 0.5), 2.0, 1.6, eye, Color(0, 0, 0, 0))
			_:
				for e in [le, re]:
					Iso.ellipse(self, e, 1.8, 2.5, eye, Color(0, 0, 0, 0))
					draw_circle(e + Vector2(0.6, -0.8), 0.7, Color(1, 1, 1, 0.9))
	if ex == "sad" and npc.mood < -50.0:
		Iso.ellipse(self, le + Vector2(-0.5, 5), 1.2, 2.0, Color(0.5, 0.75, 1.0, 0.85), Color(0, 0, 0, 0))
	# nose
	draw_arc(c + Vector2(fx + 1.0, 3.0), 1.4, -0.3, PI * 0.6, 5, Iso.shade(skin, 0.7), 1.1, true)
	# mustache / stubble
	var ext: Array = look.get("extras", [])
	if "stubble" in ext:
		for k in 9:
			draw_circle(c + Vector2(fx - 5 + k * 1.3, 8.5 + (k % 2) * 1.2), 0.45, Iso.shade(hair, 0.9))
	# mouth
	var m := c + Vector2(fx, 7.8)
	var talking := npc.speaking > 0.0 and fmod(t, 0.24) < 0.13
	if pose == "eat" and fmod(t, 0.5) < 0.25:
		talking = true
	if talking:
		Iso.ellipse(self, m, 2.6, 2.2 if ex != "surprised" else 3.0, Color("7a2b35"), Iso.INK, 1.0)
	else:
		match ex:
			"happy":
				var pts := PackedVector2Array()
				for i in 9:
					var a := PI * float(i) / 8.0
					pts.append(m + Vector2(cos(a) * 4.2, sin(a) * 3.6 - 0.5))
				Iso.poly(self, pts, Color("7a2b35"), Iso.INK, 1.0)
				Iso.ellipse(self, m + Vector2(0, 1.8), 2.0, 1.0, Color("f08080"), Color(0, 0, 0, 0))
			"surprised":
				Iso.ellipse(self, m + Vector2(0, 0.5), 2.0, 2.6, Color("7a2b35"), Iso.INK, 1.0)
			"angry":
				Iso.rrect(self, Rect2(m + Vector2(-3.8, -1.2), Vector2(7.6, 3.0)), 1, Color("ffffff"), Iso.INK, 1.0)
				draw_line(m + Vector2(-3.5, 0.3), m + Vector2(3.5, 0.3), Iso.INK_SOFT, 0.8)
			"sad":
				draw_arc(m + Vector2(0, 2.8), 3.2, PI * 1.15, PI * 1.85, 8, Iso.INK, 1.4, true)
			_:
				draw_arc(m + Vector2(0, -1.5), 3.0, PI * 0.2, PI * 0.8, 8, Iso.INK, 1.4, true)
	if "mustache" in ext:
		var mc := c + Vector2(fx, 5.6)
		Iso.poly(self, PackedVector2Array([mc + Vector2(-5.5, 1.2), mc + Vector2(-2, -1.2), mc + Vector2(0, -0.4), mc + Vector2(2, -1.2), mc + Vector2(5.5, 1.2), mc + Vector2(2, 0.6), mc + Vector2(0, 1.2), mc + Vector2(-2, 0.6)]), Iso.shade(hair, 0.9), Iso.INK_SOFT, 0.8)


# ---------------------------------------------------------------- hair

func _hair_back(c: Vector2, front: bool) -> void:
	var style: String = look.get("hair_style", "")
	match style:
		"ponytail":
			var base := c + Vector2(-11 if front else -4, -6)
			Iso.capsule(self, base, base + Vector2(-6, 14), 4.5, hair)
			Iso.capsule(self, base + Vector2(-6, 14), base + Vector2(-3, 22), 3.0, hair)
			draw_circle(base + Vector2(1, 0), 2.6, accent)
		"curly_bob":
			for p in [Vector2(-13, 4), Vector2(13, 4), Vector2(-11, 10), Vector2(11, 10), Vector2(0, 11)]:
				Iso.ellipse(self, c + p, 6, 6, hair)
		"bob":
			Iso.rrect(self, Rect2(c + Vector2(-16, -6), Vector2(32, 18)), 6, hair)
		"buns":
			pass


func _hair_front(c: Vector2, front: bool) -> void:
	var style: String = look.get("hair_style", "")
	var r := 14.5
	var hl := hair.lightened(0.18)
	if not front:
		match style:
			"buns":
				Iso.ellipse(self, c + Vector2(-8, -12), 5, 5, hair)
				Iso.ellipse(self, c + Vector2(8, -12), 5, 5, hair)
			"ponytail":
				Iso.capsule(self, c + Vector2(0, -4), c + Vector2(-2, 18), 4.5, hair)
			"curly_bob":
				for k in 6:
					var a := PI + k * PI / 5.0
					Iso.ellipse(self, c + Vector2(cos(a) * 12, sin(a) * 11), 5, 5, hair)
			"side_part":
				Iso.ellipse(self, c + Vector2(-9, 2), 4, 6, hair2, Color(0, 0, 0, 0))
				Iso.ellipse(self, c + Vector2(9, 2), 4, 6, hair2, Color(0, 0, 0, 0))
			"slick":
				draw_arc(c + Vector2(-3, -4), 8, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.35), 2.0, true)
		return
	match style:
		"side_part":
			var cap := Iso.ellipse_pts(c + Vector2(0, -2), r + 0.8, r - 1.0, 18, PI * 1.02, PI * 1.98)
			cap.append(c + Vector2(r - 1, -3))
			cap.append(c + Vector2(4, -7))
			cap.append(c + Vector2(-6, -6))
			cap.append(c + Vector2(-r + 0.5, 0))
			Iso.poly(self, cap, hair)
			Iso.ellipse(self, c + Vector2(-r + 2.5, -1), 2.8, 5, hair2, Iso.INK_SOFT)
			Iso.ellipse(self, c + Vector2(r - 2.5, -2), 2.4, 4, hair2, Iso.INK_SOFT)
			draw_line(c + Vector2(-2, -13), c + Vector2(-4, -7), Iso.shade(hair, 0.7), 1.2)
		"ponytail":
			var cap2 := Iso.ellipse_pts(c + Vector2(0, -1), r + 1.0, r, 18, PI * 1.0, PI * 2.0)
			cap2.append(c + Vector2(r, 2))
			cap2.append(c + Vector2(8, -6))
			cap2.append(c + Vector2(-2, -8))
			cap2.append(c + Vector2(-9, -4))
			cap2.append(c + Vector2(-r - 0.5, 3))
			Iso.poly(self, cap2, hair)
			draw_arc(c + Vector2(2, -8), 7, PI * 1.15, PI * 1.6, 6, hl, 1.6, true)
		"quiff":
			var cap3 := Iso.ellipse_pts(c + Vector2(0, -2), r + 0.5, r - 1.5, 18, PI * 1.0, PI * 2.0)
			cap3.append(c + Vector2(r - 1, -2))
			cap3.append(c + Vector2(-r + 1, -1))
			Iso.poly(self, cap3, hair)
			Iso.poly(self, PackedVector2Array([c + Vector2(-6, -13), c + Vector2(4, -22), c + Vector2(14, -17), c + Vector2(10, -11), c + Vector2(2, -12)]), hair)
			draw_arc(c + Vector2(6, -16), 5, PI * 1.1, PI * 1.7, 6, hl, 1.5, true)
		"curly_bob":
			for k in 7:
				var a := PI * 0.95 + k * PI * 1.1 / 6.0
				Iso.ellipse(self, c + Vector2(cos(a) * 12.5, sin(a) * 11.5 - 1), 5.5, 5.2, hair)
			Iso.ellipse(self, c + Vector2(4, -10), 7, 4.5, hair)
			for k in 4:
				draw_arc(c + Vector2(-9 + k * 6, -11 + (k % 2) * 2), 2.2, 0, PI * 1.5, 6, hl, 1.0, true)
		"messy":
			var cap4 := Iso.ellipse_pts(c + Vector2(0, -2), r + 0.6, r - 1.2, 18, PI * 1.0, PI * 2.0)
			cap4.append(c + Vector2(r - 1, -1))
			cap4.append(c + Vector2(-r + 1, 0))
			Iso.poly(self, cap4, hair)
			for k in 6:
				var bx := -12.0 + k * 5.0
				Iso.poly(self, PackedVector2Array([c + Vector2(bx, -11), c + Vector2(bx + 3, -19 - (k % 2) * 3), c + Vector2(bx + 6, -11)]), hair)
			Iso.poly(self, PackedVector2Array([c + Vector2(2, -9), c + Vector2(9, -2), c + Vector2(11, -9)]), hair)
		"buns":
			Iso.ellipse(self, c + Vector2(-9, -13), 5.5, 5.5, hair)
			Iso.ellipse(self, c + Vector2(9, -13), 5.5, 5.5, hair)
			var cap5 := Iso.ellipse_pts(c + Vector2(0, -2), r + 0.5, r - 1.0, 18, PI * 1.0, PI * 2.0)
			cap5.append(c + Vector2(r - 1, -1))
			cap5.append(c + Vector2(4, -6))
			cap5.append(c + Vector2(-5, -5))
			cap5.append(c + Vector2(-r + 1, 0))
			Iso.poly(self, cap5, hair)
			draw_circle(c + Vector2(10, -6), 2.3, Color("ff8fb1"))
		"slick":
			var cap6 := Iso.ellipse_pts(c + Vector2(0, -2.5), r + 0.4, r - 2.0, 18, PI * 1.0, PI * 2.0)
			cap6.append(c + Vector2(r - 1, -3))
			cap6.append(c + Vector2(-r + 1, -2))
			Iso.poly(self, cap6, hair)
			draw_arc(c + Vector2(-1, -6), 9, PI * 1.12, PI * 1.62, 8, Color(1, 1, 1, 0.45), 2.0, true)
			Iso.line(self, c + Vector2(-r + 2, -2), c + Vector2(-r + 2.5, 4), hair, 2.2)
		"bob":
			var cap7 := Iso.ellipse_pts(c + Vector2(0, -1), r + 1.5, r + 0.5, 18, PI * 1.0, PI * 2.0)
			cap7.append(c + Vector2(r + 1.5, 9))
			cap7.append(c + Vector2(r - 3, 9))
			cap7.append(c + Vector2(r - 3, -4))
			cap7.append(c + Vector2(-r + 3, -4))
			cap7.append(c + Vector2(-r + 3, 9))
			cap7.append(c + Vector2(-r - 1.5, 9))
			Iso.poly(self, cap7, hair)
			draw_arc(c + Vector2(-3, -7), 7, PI * 1.15, PI * 1.6, 6, Color(1, 1, 1, 0.25), 1.6, true)


# ---------------------------------------------------------------- props & emotes

func _held_item(pose: String, near_hand: Vector2, far_hand: Vector2) -> void:
	match pose:
		"phone":
			Iso.rrect(self, Rect2(near_hand + Vector2(-2.5, -6), Vector2(5, 9)), 1.5, Color("2b2d42"), Iso.INK, 1.0)
		"coffee":
			Iso.rrect(self, Rect2(near_hand + Vector2(-1, -6), Vector2(6, 7)), 1.5, Color("ffffff"), Iso.INK, 1.0)
			draw_arc(near_hand + Vector2(5.5, -2.5), 2, -PI * 0.5, PI * 0.5, 5, Iso.INK, 1.0)
			if fmod(t, 2.0) < 1.0:
				draw_line(near_hand + Vector2(1, -8), near_hand + Vector2(2, -13), Color(1, 1, 1, 0.7), 1.2, true)
		"eat":
			Iso.rrect(self, Rect2(near_hand + Vector2(-1, -5), Vector2(8, 5)), 2, Color("f4c27a"), Iso.INK, 1.0)
			draw_line(near_hand + Vector2(0, -3), near_hand + Vector2(6, -3), Color("6fb06a"), 1.4)
		"read":
			Iso.poly(self, PackedVector2Array([far_hand + Vector2(-2, -8), near_hand + Vector2(3, -9), near_hand + Vector2(3, 3), far_hand + Vector2(-2, 3)]), Color("fffdf7"), Iso.INK, 1.0)
			for k in 3:
				draw_line(far_hand + Vector2(0, -5 + k * 3), near_hand + Vector2(0, -6 + k * 3), Color(0.4, 0.4, 0.5, 0.5), 0.8)
		"fix":
			Iso.capsule(self, near_hand, near_hand + Vector2(8, -6), 1.4, Color("9aa5b1"))
			draw_circle(near_hand + Vector2(9, -7), 2.4, Color("9aa5b1"))


func _draw_emote(sitting: bool) -> void:
	var e: String = npc.emote
	if e == "" or npc.emote_timer <= 0.0:
		return
	var y := -90.0 + (6.0 if sitting else 0.0)
	var bounce := sin(t * 8.0) * 2.0
	var p := Vector2(16, y + bounce)
	var a := minf(1.0, npc.emote_timer * 2.0)
	match e:
		"exclaim":
			_bubble_icon(p, Color(1, 1, 1, a))
			Iso.rrect(self, Rect2(p + Vector2(-2, -9), Vector2(4.2, 10)), 1.5, Color(0.9, 0.2, 0.25, a), Color(0, 0, 0, 0))
			draw_circle(p + Vector2(0.1, 5), 2.2, Color(0.9, 0.2, 0.25, a))
		"question":
			_bubble_icon(p, Color(1, 1, 1, a))
			draw_string(UiKit.font("marker"), p + Vector2(-5, 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.17, 0.42, 0.69, a))
		"anger":
			for k in 4:
				var ang := k * PI * 0.5 + PI * 0.25
				var q := p + Vector2(cos(ang), sin(ang)) * 5.5
				draw_arc(q, 4.0, ang + PI * 0.6, ang + PI * 1.4, 6, Color(0.9, 0.15, 0.2, a), 2.2, true)
		"love":
			_heart(p, 7.0, Color(1.0, 0.36, 0.5, a))
			_heart(p + Vector2(10, -8), 4.0, Color(1.0, 0.5, 0.62, a * 0.8))
		"sweat":
			var sp := Vector2(-14, y + 22)
			Iso.poly(self, PackedVector2Array([sp + Vector2(0, -6), sp + Vector2(3.5, 1), sp + Vector2(0, 4), sp + Vector2(-3.5, 1)]), Color(0.55, 0.8, 1.0, a), Color(0.2, 0.4, 0.7, a * 0.8), 1.0)
		"cloud":
			for q in [Vector2(-6, 0), Vector2(0, -4), Vector2(6, 0)]:
				Iso.ellipse(self, p + q, 6, 5, Color(0.6, 0.62, 0.7, a), Color(0, 0, 0, 0))
			for k in 3:
				draw_line(p + Vector2(-5 + k * 5, 6), p + Vector2(-6 + k * 5, 11), Color(0.4, 0.6, 0.95, a), 1.4)
		"idea":
			Iso.ellipse(self, p, 5.5, 6.5, Color(1.0, 0.92, 0.35, a))
			draw_rect(Rect2(p + Vector2(-2.5, 6), Vector2(5, 3)), Color(0.6, 0.6, 0.65, a))
			for k in 5:
				var ang2 := PI + k * PI / 4.0
				draw_line(p + Vector2(cos(ang2), sin(ang2)) * 9, p + Vector2(cos(ang2), sin(ang2)) * 12, Color(1.0, 0.85, 0.2, a), 1.4)
		"ok":
			_bubble_icon(p, Color(1, 1, 1, a))
			draw_polyline(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(-1, 3.5), p + Vector2(5, -4)]), Color(0.16, 0.62, 0.4, a), 2.4, true)
		"wave":
			for k in 2:
				var sp2 := p + Vector2(-4 + k * 9, -2 - k * 4)
				_sparkle(sp2, 4.5 - k, Color(1.0, 0.8, 0.25, a))
		"shiver":
			for s in [-1, 1]:
				var bx: float = s * 16.0
				draw_polyline(PackedVector2Array([Vector2(bx, y + 30), Vector2(bx + 2 * s, y + 34), Vector2(bx, y + 38), Vector2(bx + 2 * s, y + 42)]), Color(0.45, 0.7, 1.0, a), 1.4, true)
		"cheer":
			# confetti burst around the head
			var cols := [Color(1.0, 0.82, 0.25, a), Color(0.95, 0.4, 0.55, a), Color(0.35, 0.75, 0.95, a), Color(0.45, 0.85, 0.5, a)]
			for k in 6:
				var ang3 := t * 2.2 + k * TAU / 6.0
				var rr := 13.0 + sin(t * 5.0 + k) * 3.0
				var cp := p + Vector2(-16, 6) + Vector2(cos(ang3) * rr, sin(ang3) * rr * 0.6)
				draw_rect(Rect2(cp - Vector2(1.6, 1.6), Vector2(3.2, 3.2)), cols[k % 4])
			_sparkle(p + Vector2(2, -2), 5.5, Color(1.0, 0.85, 0.2, a))
		"whisper":
			# a hushed little bubble: "psst..."
			Iso.ellipse(self, p + Vector2(2, 0), 11.0, 7.5, Color(0.96, 0.95, 0.99, a * 0.95), Color(Iso.INK.r, Iso.INK.g, Iso.INK.b, a * 0.6), 1.0)
			for k in 3:
				draw_circle(p + Vector2(-4 + k * 5, 0.5), 1.4, Color(0.35, 0.3, 0.5, a))
			draw_line(p + Vector2(-6, 6), p + Vector2(-11, 11), Color(Iso.INK.r, Iso.INK.g, Iso.INK.b, a * 0.6), 1.2, true)
		"phone":
			Iso.rrect(self, Rect2(p + Vector2(-4, -7), Vector2(8, 13)), 2, Color(0.17, 0.18, 0.26, a), Color(0, 0, 0, 0))
			draw_rect(Rect2(p + Vector2(-2.6, -5), Vector2(5.2, 8)), Color(0.66, 0.85, 1.0, a))
			for s2 in [-1, 1]:
				draw_arc(p, 9, -0.6 if s2 > 0 else PI - 0.6, 0.6 if s2 > 0 else PI + 0.6, 6, Color(0.9, 0.2, 0.25, a), 1.4, true)


func _bubble_icon(p: Vector2, col: Color) -> void:
	Iso.ellipse(self, p, 8.5, 9.5, col, Color(Iso.INK.r, Iso.INK.g, Iso.INK.b, col.a * 0.8), 1.2)


func _heart(p: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var tt := TAU * i / 24.0
		var hx := 16.0 * pow(sin(tt), 3)
		var hy := -(13.0 * cos(tt) - 5.0 * cos(2 * tt) - 2.0 * cos(3 * tt) - cos(4 * tt))
		pts.append(p + Vector2(hx, hy) * (s / 16.0))
	Iso.poly(self, pts, col, Color(0.5, 0.1, 0.2, col.a * 0.6), 1.0)


func _sparkle(p: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var r := s if i % 2 == 0 else s * 0.35
		var a := PI * 0.25 * i
		pts.append(p + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col)
