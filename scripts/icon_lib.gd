class_name IconLib
## Shared code-drawn item icons. Draw centered at `pos`, roughly `s` px tall.


static func draw_icon(ci: CanvasItem, type: String, pos: Vector2, s: float = 32.0) -> void:
	var h := s / 2.0
	match type:
		"lantern":
			ci.draw_rect(Rect2(pos.x - h * 0.35, pos.y - h, h * 0.7, h * 0.2), Color("#6b6b6b"))
			ci.draw_arc(pos + Vector2(0, -h * 0.9), h * 0.35, PI, TAU, 10, Color("#6b6b6b"), 2.0)
			ci.draw_rect(Rect2(pos.x - h * 0.5, pos.y - h * 0.8, h, h * 1.5), Color("#8a5a2b"))
			ci.draw_rect(Rect2(pos.x - h * 0.35, pos.y - h * 0.65, h * 0.7, h * 1.2), Color("#ffe08a"))
			ci.draw_circle(pos + Vector2(0, -h * 0.05), h * 0.22, Color("#ffb347"))
		"starfish":
			var col := Color("#ff8c42")
			for i in range(5):
				var ang := -PI / 2 + i * TAU / 5.0
				var tip := pos + Vector2(cos(ang), sin(ang)) * h
				var l := pos + Vector2(cos(ang - 0.55), sin(ang - 0.55)) * h * 0.35
				var r := pos + Vector2(cos(ang + 0.55), sin(ang + 0.55)) * h * 0.35
				ci.draw_polygon(PackedVector2Array([l, tip, r]), PackedColorArray([col, col, col]))
			ci.draw_circle(pos, h * 0.32, Color("#ffb347"))
		"shard":
			var col := Color("#9ad8f0")
			var pts := PackedVector2Array([
				pos + Vector2(0, -h), pos + Vector2(h * 0.7, 0),
				pos + Vector2(0.2 * h, h), pos + Vector2(-h * 0.6, h * 0.2),
			])
			ci.draw_polygon(pts, PackedColorArray([col, col, col, col]))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#e8f8ff"), 2.0)
			ci.draw_line(pos + Vector2(0, -h * 0.7), pos + Vector2(0, h * 0.6), Color("#e8f8ff"), 1.5)
		"yarn":
			var col := Color("#c9483a")
			ci.draw_circle(pos, h * 0.8, col)
			for i in range(3):
				ci.draw_arc(pos, h * 0.8 - 2 - i * 4, 0.4 + i * 0.5, PI * 1.4 + i * 0.4, 12, col.darkened(0.3), 2.0)
			ci.draw_line(pos + Vector2(h * 0.5, h * 0.4), pos + Vector2(h * 1.1, h * 0.8), col.darkened(0.2), 2.0)
		"hat":
			var col := Color("#4ca64c")
			# dome
			var pts := PackedVector2Array()
			for i in range(13):
				var ang := PI + i * PI / 12.0
				pts.append(pos + Vector2(cos(ang), sin(ang)) * h * 0.85)
			var cols := PackedColorArray()
			for i in pts.size():
				cols.append(col)
			ci.draw_polygon(pts, cols)
			ci.draw_rect(Rect2(pos.x - h * 0.95, pos.y - h * 0.12, h * 1.9, h * 0.3), col.darkened(0.25))
			ci.draw_circle(pos + Vector2(0, -h * 0.85), h * 0.22, Color("#f4f1e8"))
		"bell":
			var col := Color("#d8a12c")
			var pts := PackedVector2Array()
			for i in range(13):
				var ang := PI + i * PI / 12.0
				pts.append(pos + Vector2(cos(ang) * h * 0.75, sin(ang) * h * 0.85))
			pts.append(pos + Vector2(h * 0.85, h * 0.35))
			pts.append(pos + Vector2(-h * 0.85, h * 0.35))
			var cols := PackedColorArray()
			for i in pts.size():
				cols.append(col)
			ci.draw_polygon(pts, cols)
			ci.draw_circle(pos + Vector2(0, h * 0.55), h * 0.18, col.darkened(0.35))
			ci.draw_rect(Rect2(pos.x - h * 0.12, pos.y - h * 1.05, h * 0.24, h * 0.25), col.darkened(0.3))
		"coins":
			for off in [Vector2(-h * 0.35, h * 0.25), Vector2(h * 0.35, h * 0.25), Vector2(0, -h * 0.1)]:
				ci.draw_circle(pos + off, h * 0.42, Color("#d8a12c"))
				ci.draw_circle(pos + off, h * 0.32, Color("#e8c930"))
				ci.draw_arc(pos + off, h * 0.42, 0, TAU, 16, Color("#b07d1e"), 1.5)
		"crate":
			ci.draw_rect(Rect2(pos.x - h * 0.8, pos.y - h * 0.7, h * 1.6, h * 1.5), Color("#a8743d"))
			ci.draw_rect(Rect2(pos.x - h * 0.8, pos.y - h * 0.7, h * 1.6, h * 1.5), Color("#6e4522"), false, 3.0)
			ci.draw_line(pos + Vector2(-h * 0.8, -h * 0.7), pos + Vector2(h * 0.8, h * 0.8), Color("#6e4522"), 3.0)
			ci.draw_line(pos + Vector2(h * 0.8, -h * 0.7), pos + Vector2(-h * 0.8, h * 0.8), Color("#6e4522"), 3.0)
		"pack":
			ci.draw_rect(Rect2(pos.x - h * 0.5, pos.y - h * 0.8, h, h * 1.6), Color("#e8e4da"))
			ci.draw_rect(Rect2(pos.x - h * 0.5, pos.y - h * 0.8, h, h * 1.6), Color("#8a9198"), false, 2.5)
			ci.draw_rect(Rect2(pos.x - h * 0.5, pos.y - h * 0.8, h, h * 0.45), Color("#c0504a"))
			ci.draw_line(pos + Vector2(-h * 0.3, h * 0.1), pos + Vector2(h * 0.3, h * 0.1), Color("#b8bcc2"), 2.0)
			ci.draw_line(pos + Vector2(-h * 0.3, h * 0.45), pos + Vector2(h * 0.3, h * 0.45), Color("#b8bcc2"), 2.0)
		"gum":
			ci.draw_rect(Rect2(pos.x - h * 0.42, pos.y - h * 0.8, h * 0.84, h * 1.6), Color("#68d0c8"))
			ci.draw_rect(Rect2(pos.x - h * 0.42, pos.y - h * 0.8, h * 0.84, h * 1.6), Color("#2e8b86"), false, 2.5)
			ci.draw_rect(Rect2(pos.x - h * 0.42, pos.y - h * 0.2, h * 0.84, h * 0.35), Color("#f4f1e8"))
			ci.draw_circle(pos + Vector2(0, -h * 0.45), h * 0.16, Color("#f4f1e8"))
		"ticket":
			ci.draw_rect(Rect2(pos.x - h * 0.9, pos.y - h * 0.55, h * 1.8, h * 1.1), Color("#f4e8b0"))
			ci.draw_rect(Rect2(pos.x - h * 0.9, pos.y - h * 0.55, h * 1.8, h * 1.1), Color("#c9a83a"), false, 2.5)
			for i in range(3):
				var yy := pos.y - h * 0.25 + i * h * 0.3
				ci.draw_line(Vector2(pos.x - h * 0.6, yy), Vector2(pos.x + h * 0.35, yy), Color("#8a7a3a"), 2.0)
			ci.draw_circle(pos + Vector2(h * 0.6, 0), h * 0.2, Color("#d9483b"))
		"medallion":
			ci.draw_circle(pos, h * 0.9, Color("#d8a12c"))
			ci.draw_circle(pos, h * 0.72, Color("#e8c930"))
			ci.draw_arc(pos, h * 0.8, 0, TAU, 24, Color("#b07d1e"), 2.0)
			var star := PackedVector2Array()
			for i in range(10):
				var ang := -PI / 2 + i * PI / 5.0
				var rr := h * 0.5 if i % 2 == 0 else h * 0.22
				star.append(pos + Vector2(cos(ang), sin(ang)) * rr)
			var cols := PackedColorArray()
			for i in star.size():
				cols.append(Color("#b07d1e"))
			ci.draw_polygon(star, cols)
		"map":
			ci.draw_rect(Rect2(pos.x - h, pos.y - h * 0.75, s, h * 1.5), Color("#e8d9b0"))
			ci.draw_line(pos + Vector2(-h * 0.33, -h * 0.75), pos + Vector2(-h * 0.33, h * 0.75), Color("#c9b98a"), 1.5)
			ci.draw_line(pos + Vector2(h * 0.33, -h * 0.75), pos + Vector2(h * 0.33, h * 0.75), Color("#c9b98a"), 1.5)
			ci.draw_circle(pos + Vector2(h * 0.1, -h * 0.1), h * 0.14, Color("#d9483b"))
			ci.draw_line(pos + Vector2(-h * 0.6, h * 0.4), pos + Vector2(h * 0.1, -h * 0.1), Color("#5a7ea5"), 2.0)
		"backpack":
			ci.draw_rect(Rect2(pos.x - h * 0.75, pos.y - h * 0.7, h * 1.5, h * 1.5), Color("#8a5a2b"))
			ci.draw_arc(pos + Vector2(0, -h * 0.7), h * 0.5, PI, TAU, 10, Color("#8a5a2b"), 5.0)
			ci.draw_rect(Rect2(pos.x - h * 0.45, pos.y - h * 0.05, h * 0.9, h * 0.75), Color("#a8743d"))
			ci.draw_rect(Rect2(pos.x - h * 0.2, pos.y - h * 0.05, h * 0.4, h * 0.22), Color("#d8a12c"))
		_:
			ci.draw_circle(pos, h * 0.6, Color("#cccccc"))


static func panel_style(bg: Color, radius := 12, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	if border.a > 0:
		sb.border_color = border
		sb.set_border_width_all(3)
	return sb


static func make_button(text: String, font_size := 24, bg := Color("#2e8bc0")) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("#dddddd"))
	b.add_theme_stylebox_override("normal", panel_style(bg))
	b.add_theme_stylebox_override("hover", panel_style(bg.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", panel_style(bg.darkened(0.15)))
	b.add_theme_stylebox_override("disabled", panel_style(Color("#9aa5ad")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b
