class_name TitleScreen
extends Node2D
## Title: drifting clouds, bobbing blimp, New Adventure / Continue.

var screen_args := {}
var _t := 0.0
var _sky: Node2D


func _ready() -> void:
	_sky = SkyDrawer.new()
	add_child(_sky)

	var ui := CanvasLayer.new()
	add_child(ui)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 18)
	ui.add_child(center)

	var title := Label.new()
	title.text = "ISLETOPIA"
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color("#25537a"))
	title.add_theme_constant_override("outline_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)

	var sub := Label.new()
	sub.text = "Every island holds a story."
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color("#f4f1e8"))
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	sub.add_theme_constant_override("outline_size", 6)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	center.add_child(gap)

	var has_profiles := Game.profile_count() > 0

	var play_btn := IconLib.make_button("Choose Explorer" if has_profiles else "New Adventure", 26, Color("#4ca64c"))
	play_btn.custom_minimum_size = Vector2(320, 0)
	play_btn.pressed.connect(_on_play)
	center.add_child(play_btn)

	if has_profiles:
		var new_btn := IconLib.make_button("New Explorer", 22, Color("#2e8bc0"))
		new_btn.custom_minimum_size = Vector2(320, 0)
		new_btn.disabled = not Game.can_add_profile()
		new_btn.pressed.connect(func():
			Game.sfx("click")
			Game.reset_new_game()
			Game.goto_screen("creator")
		)
		center.add_child(new_btn)

	var note := Label.new()
	note.text = "Everyone on this device gets their own saved progress."
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color("#eaf4fb"))
	note.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	note.add_theme_constant_override("outline_size", 5)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(note)


func _on_play() -> void:
	Game.sfx("click")
	if Game.profile_count() > 0:
		Game.goto_screen("profiles")
	else:
		Game.reset_new_game()
		Game.goto_screen("creator")


class SkyDrawer:
	extends Node2D
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var vp := get_viewport_rect().size
		var top := Color("#5aa8dc")
		var bottom := Color("#c8e8f8")
		draw_polygon(
			PackedVector2Array([Vector2.ZERO, Vector2(vp.x, 0), vp, Vector2(0, vp.y)]),
			PackedColorArray([top, top, bottom, bottom])
		)
		draw_circle(Vector2(vp.x * 0.82, vp.y * 0.18), 60, Color("#ffe08a"))
		# sea + islands silhouette
		draw_rect(Rect2(0, vp.y * 0.82, vp.x, vp.y * 0.2), Color("#2e86b8"))
		for i in range(3):
			var cx := vp.x * (0.2 + i * 0.3)
			draw_circle(Vector2(cx, vp.y * 0.84), 60 + i * 14, Color("#3f9b57"))
		# drifting clouds
		for i in range(5):
			var speed := 12.0 + i * 5.0
			var cx := fmod(t * speed + i * 300.0, vp.x + 240.0) - 120.0
			var cy := vp.y * (0.12 + 0.09 * i)
			var col := Color(1, 1, 1, 0.9)
			draw_circle(Vector2(cx, cy), 30, col)
			draw_circle(Vector2(cx + 26, cy + 8), 22, col)
			draw_circle(Vector2(cx - 27, cy + 9), 20, col)
		# blimp
		var bx := vp.x * 0.5 + sin(t * 0.6) * 30.0
		var by := vp.y * 0.32 + sin(t * 1.1) * 10.0
		_blimp(Vector2(bx, by))

	func _blimp(c: Vector2) -> void:
		var body := Color("#e8c930")
		var pts := PackedVector2Array()
		for i in range(25):
			var ang := i * TAU / 24.0
			pts.append(c + Vector2(cos(ang) * 90.0, sin(ang) * 34.0))
		var cols := PackedColorArray()
		for i in pts.size():
			cols.append(body)
		draw_polygon(pts, cols)
		draw_arc(c, 1.0, 0, 0.1, 2, body, 1.0)
		# stripes
		draw_line(c + Vector2(-88, 0), c + Vector2(88, 0), Color("#d9483b"), 10.0)
		# fin
		draw_polygon(
			PackedVector2Array([c + Vector2(-88, -6), c + Vector2(-116, -26), c + Vector2(-84, 8)]),
			PackedColorArray([Color("#d9483b"), Color("#d9483b"), Color("#d9483b")])
		)
		# gondola
		draw_rect(Rect2(c.x - 22, c.y + 36, 44, 20), Color("#8a5a2b"))
		draw_line(c + Vector2(-16, 30), c + Vector2(-16, 40), Color("#5c3a1c"), 3.0)
		draw_line(c + Vector2(16, 30), c + Vector2(16, 40), Color("#5c3a1c"), 3.0)
