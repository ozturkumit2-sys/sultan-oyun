class_name Icons
extends RefCounted
## Hand-drawn-style vector icons for the stationery UI.

const INK := Color("2b2d42")


static func draw(ci: CanvasItem, name: String, c: Vector2, s: float, col := INK) -> void:
	var w := maxf(1.6, s * 0.09)
	match name:
		"pause":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, -s * 0.35), Vector2(s * 0.2, s * 0.7)), col)
			ci.draw_rect(Rect2(c + Vector2(s * 0.1, -s * 0.35), Vector2(s * 0.2, s * 0.7)), col)
		"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.25, -s * 0.38), c + Vector2(s * 0.38, 0), c + Vector2(-s * 0.25, s * 0.38)]), col)
		"fast":
			for k in [-1, 1]:
				var o: Vector2 = c + Vector2(k * s * 0.2 - s * 0.05, 0)
				ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-s * 0.2, -s * 0.32), o + Vector2(s * 0.22, 0), o + Vector2(-s * 0.2, s * 0.32)]), col)
		"gear":
			var r := s * 0.32
			var pts := PackedVector2Array()
			for i in 32:
				var a := TAU * i / 32.0
				var rr := r * (1.25 if (i / 2) % 2 == 0 else 1.0)
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			ci.draw_colored_polygon(pts, col)
			ci.draw_circle(c, r * 0.45, Color("fffdf5"))
		"pin":
			ci.draw_circle(c + Vector2(0, -s * 0.12), s * 0.26, col)
			ci.draw_line(c + Vector2(0, s * 0.1), c + Vector2(0, s * 0.42), col, w, true)
		"folder":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.42, -s * 0.28), c + Vector2(-s * 0.1, -s * 0.28), c + Vector2(0, -s * 0.18), c + Vector2(s * 0.42, -s * 0.18), c + Vector2(s * 0.42, s * 0.3), c + Vector2(-s * 0.42, s * 0.3)]), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.08), Vector2(s * 0.72, s * 0.32)), Color(1, 1, 1, 0.35))
		"paper":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.42), Vector2(s * 0.72, s * 0.84)), Color("fffdf5"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.42), Vector2(s * 0.72, s * 0.84)), col, false, w)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.32), Vector2(s * 0.52, s * 0.14)), col)
			for k in 3:
				ci.draw_line(c + Vector2(-s * 0.26, -s * 0.06 + k * s * 0.14), c + Vector2(s * 0.26, -s * 0.06 + k * s * 0.14), col, w * 0.7)
		"people":
			for k in [-1, 1]:
				var o2: Vector2 = c + Vector2(k * s * 0.2, 0)
				ci.draw_circle(o2 + Vector2(0, -s * 0.18), s * 0.14, col)
				ci.draw_colored_polygon(Iso.ellipse_pts(o2 + Vector2(0, s * 0.22), s * 0.22, s * 0.2, 12, PI, TAU), col)
		"close":
			ci.draw_line(c + Vector2(-s * 0.3, -s * 0.3), c + Vector2(s * 0.3, s * 0.3), col, w * 1.4, true)
			ci.draw_line(c + Vector2(s * 0.3, -s * 0.3), c + Vector2(-s * 0.3, s * 0.3), col, w * 1.4, true)
		"back":
			ci.draw_polyline(PackedVector2Array([c + Vector2(s * 0.15, -s * 0.3), c + Vector2(-s * 0.15, 0), c + Vector2(s * 0.15, s * 0.3)]), col, w * 1.4, true)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.3, 0), c + Vector2(-s * 0.08, s * 0.25), c + Vector2(s * 0.32, -s * 0.28)]), col, w * 1.5, true)
		"locate":
			ci.draw_arc(c, s * 0.28, 0, TAU, 20, col, w, true)
			ci.draw_circle(c, s * 0.08, col)
			for d in [Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0)]:
				ci.draw_line(c + d * s * 0.28, c + d * s * 0.42, col, w, true)
		"zoom":
			ci.draw_arc(c + Vector2(-s * 0.06, -s * 0.06), s * 0.24, 0, TAU, 20, col, w, true)
			ci.draw_line(c + Vector2(s * 0.12, s * 0.12), c + Vector2(s * 0.36, s * 0.36), col, w * 1.6, true)
		"coffee":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.18), Vector2(s * 0.4, s * 0.42)), col)
			ci.draw_arc(c + Vector2(s * 0.16, 0.02 * s), s * 0.12, -PI * 0.5, PI * 0.5, 8, col, w, true)
			for k in 2:
				ci.draw_line(c + Vector2(-s * 0.14 + k * s * 0.16, -s * 0.26), c + Vector2(-s * 0.1 + k * s * 0.16, -s * 0.42), col, w * 0.8, true)
		"printer":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.38, -s * 0.12), Vector2(s * 0.76, s * 0.34)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.24, -s * 0.36), Vector2(s * 0.48, s * 0.22)), Color("fffdf5"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.24, -s * 0.36), Vector2(s * 0.48, s * 0.22)), col, false, w * 0.8)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.24, s * 0.16), Vector2(s * 0.48, s * 0.2)), Color("fffdf5"))
		"board":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.3), Vector2(s * 0.8, s * 0.5)), Color("fffdf5"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.3), Vector2(s * 0.8, s * 0.5)), col, false, w)
			ci.draw_arc(c + Vector2(0, -s * 0.05), s * 0.14, 0, TAU, 12, col, w * 0.8, true)
			ci.draw_line(c + Vector2(-s * 0.15, s * 0.2), c + Vector2(-s * 0.28, s * 0.42), col, w, true)
			ci.draw_line(c + Vector2(s * 0.15, s * 0.2), c + Vector2(s * 0.28, s * 0.42), col, w, true)
		"thermo":
			ci.draw_arc(c + Vector2(0, s * 0.22), s * 0.15, 0, TAU, 12, col, w, true)
			ci.draw_circle(c + Vector2(0, s * 0.22), s * 0.09, Color("e63946"))
			ci.draw_line(c + Vector2(0, -s * 0.38), c + Vector2(0, s * 0.1), col, w * 2.2, true)
			ci.draw_line(c + Vector2(0, -s * 0.05), c + Vector2(0, s * 0.12), Color("e63946"), w * 1.2, true)
		"bulb":
			ci.draw_circle(c + Vector2(0, -s * 0.08), s * 0.26, col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.12, s * 0.16), Vector2(s * 0.24, s * 0.18)), col)
		"file":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.32, -s * 0.4), c + Vector2(s * 0.14, -s * 0.4), c + Vector2(s * 0.32, -s * 0.22), c + Vector2(s * 0.32, s * 0.4), c + Vector2(-s * 0.32, s * 0.4)]), Color("e63946"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, -s * 0.15), Vector2(s * 0.4, s * 0.06)), Color("fffdf5"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, 0.02 * s), Vector2(s * 0.3, s * 0.06)), Color("fffdf5"))
		"email":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.38, -s * 0.26), Vector2(s * 0.76, s * 0.52)), Color("fffdf5"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.38, -s * 0.26), Vector2(s * 0.76, s * 0.52)), col, false, w)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.38, -s * 0.26), c + Vector2(0, s * 0.04), c + Vector2(s * 0.38, -s * 0.26)]), col, w, true)
		"redirect":
			draw(ci, "email", c + Vector2(-s * 0.06, s * 0.05), s * 0.8, col)
			ci.draw_polyline(PackedVector2Array([c + Vector2(s * 0.1, -s * 0.4), c + Vector2(s * 0.4, -s * 0.4), c + Vector2(s * 0.4, -s * 0.12)]), Color("e63946"), w * 1.2, true)
			ci.draw_line(c + Vector2(s * 0.4, -s * 0.4), c + Vector2(s * 0.12, -s * 0.12), Color("e63946"), w * 1.2, true)
		"papers":
			for k in 3:
				var o3 := c + Vector2(-s * 0.1 + k * s * 0.1, -s * 0.06 + k * s * 0.05)
				var ang := -0.4 + k * 0.4
				var q := PackedVector2Array()
				for v in [Vector2(-0.24, -0.3), Vector2(0.24, -0.3), Vector2(0.24, 0.3), Vector2(-0.24, 0.3)]:
					q.append(o3 + (v * s).rotated(ang))
				ci.draw_colored_polygon(q, Color("fffdf5"))
				ci.draw_polyline(q + PackedVector2Array([q[0]]), col, w * 0.8, true)
		"phone":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, -s * 0.38), Vector2(s * 0.4, s * 0.76)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.14, -s * 0.28), Vector2(s * 0.28, s * 0.5)), Color("a8d8ff"))
			for k in [-1, 1]:
				ci.draw_arc(c, s * 0.42, -0.5 if k > 0 else PI - 0.5, 0.5 if k > 0 else PI + 0.5, 6, Color("e63946"), w, true)
		"item":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, -s * 0.2), Vector2(s * 0.6, s * 0.4)), col)
			ci.draw_line(c + Vector2(-s * 0.1, -s * 0.36), c + Vector2(s * 0.3, s * 0.36), Color("e63946"), w, true)
		"ghost":
			var gp := PackedVector2Array()
			for i in 13:
				var a2 := PI + PI * i / 12.0
				gp.append(c + Vector2(cos(a2) * s * 0.32, -s * 0.05 + sin(a2) * s * 0.34))
			for k in 4:
				gp.append(c + Vector2(s * 0.32 - k * s * 0.16 - s * 0.08, s * 0.32 + (k % 2) * s * 0.08))
			gp.append(c + Vector2(-s * 0.32, s * 0.32))
			ci.draw_colored_polygon(gp, Color("fffdf5"))
			ci.draw_polyline(gp + PackedVector2Array([gp[0]]), col, w, true)
			ci.draw_circle(c + Vector2(-s * 0.11, -s * 0.08), s * 0.05, col)
			ci.draw_circle(c + Vector2(s * 0.11, -s * 0.08), s * 0.05, col)
		"newspaper":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.42, -s * 0.32), Vector2(s * 0.84, s * 0.64)), Color("fffdf5"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.42, -s * 0.32), Vector2(s * 0.84, s * 0.64)), col, false, w)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.34, -s * 0.24), Vector2(s * 0.68, s * 0.12)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.34, -s * 0.04), Vector2(s * 0.28, s * 0.26)), Color("8d99ae"))
			for k in 3:
				ci.draw_line(c + Vector2(s * 0.0, -s * 0.02 + k * s * 0.1), c + Vector2(s * 0.34, -s * 0.02 + k * s * 0.1), col, w * 0.7)
		"star":
			var sp := PackedVector2Array()
			for i in 10:
				var r := s * (0.42 if i % 2 == 0 else 0.18)
				var a3 := -PI * 0.5 + PI * i / 5.0
				sp.append(c + Vector2(cos(a3), sin(a3)) * r)
			ci.draw_colored_polygon(sp, col)
		"sound":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.36, -s * 0.12), c + Vector2(-s * 0.18, -s * 0.12), c + Vector2(0, -s * 0.3), c + Vector2(0, s * 0.3), c + Vector2(-s * 0.18, s * 0.12), c + Vector2(-s * 0.36, s * 0.12)]), col)
			ci.draw_arc(c + Vector2(s * 0.04, 0), s * 0.16, -0.8, 0.8, 8, col, w, true)
			ci.draw_arc(c + Vector2(s * 0.04, 0), s * 0.3, -0.8, 0.8, 8, col, w, true)
		"music":
			ci.draw_circle(c + Vector2(-s * 0.16, s * 0.24), s * 0.12, col)
			ci.draw_circle(c + Vector2(s * 0.2, s * 0.16), s * 0.12, col)
			ci.draw_line(c + Vector2(-s * 0.06, s * 0.24), c + Vector2(-s * 0.06, -s * 0.32), col, w, true)
			ci.draw_line(c + Vector2(s * 0.3, s * 0.16), c + Vector2(s * 0.3, -s * 0.4), col, w, true)
			ci.draw_line(c + Vector2(-s * 0.06, -s * 0.32), c + Vector2(s * 0.3, -s * 0.4), col, w * 1.8, true)
		"calendar":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.3), Vector2(s * 0.72, s * 0.66)), Color("fffdf5"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.3), Vector2(s * 0.72, s * 0.18)), Color("e63946"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.3), Vector2(s * 0.72, s * 0.66)), col, false, w)
		"home":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, 0), c + Vector2(0, -s * 0.38), c + Vector2(s * 0.4, 0)]), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.28, 0), Vector2(s * 0.56, s * 0.36)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.08, s * 0.12), Vector2(s * 0.16, s * 0.24)), Color("fffdf5"))
		"help":
			ci.draw_arc(c, s * 0.36, 0, TAU, 24, col, w, true)
			ci.draw_string(UiKit.font("marker"), c + Vector2(-s * 0.13, s * 0.17), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s * 0.5), col)


static func for_action(id: String) -> String:
	match id:
		"break_coffee", "fix_coffee": return "coffee"
		"break_printer": return "printer"
		"move_meeting": return "board"
		"set_temp": return "thermo"
		"lights_off", "lights_on": return "bulb"
		"edit_promo": return "file"
		"email_all": return "email"
		"email_redirect": return "redirect"
		"shuffle_files": return "papers"
		"fake_notif": return "phone"
		"move_item": return "item"
	return "ghost"
