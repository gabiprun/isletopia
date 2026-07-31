class_name MapScreen
extends Node2D
## Blimp travel map: pick an island, blimp flies there, world loads.

var screen_args := {}
var _blimp: Node2D
var _travelling := false


func _ready() -> void:
	add_child(TitleScreen.SkyDrawer.new())

	var ui := CanvasLayer.new()
	add_child(ui)

	var title := Label.new()
	title.text = "Where to, %s?" % Game.player_name
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color("#25537a"))
	title.add_theme_constant_override("outline_size", 10)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position.y = 22
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ui.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	ui.add_child(row)

	for island_id in IslandRegistry.list_islands():
		var info := IslandRegistry.get_island(island_id)
		row.add_child(_island_card(island_id, info))
	row.add_child(_locked_card("Aurora Atoll"))


func _island_card(island_id: String, info: Dictionary) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 260)
	btn.add_theme_stylebox_override("normal", IconLib.panel_style(Color(0.08, 0.12, 0.18, 0.8), 18))
	btn.add_theme_stylebox_override("hover", IconLib.panel_style(Color(0.14, 0.2, 0.3, 0.9), 18, Color("#ffe08a")))
	btn.add_theme_stylebox_override("pressed", IconLib.panel_style(Color(0.05, 0.08, 0.12, 0.9), 18))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var art := IslandArt.new()
	art.tint = info.get("color", Color("#3f9b57"))
	art.custom_minimum_size = Vector2(0, 130)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(art)

	var nm := Label.new()
	nm.text = info.get("name", island_id)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 24)
	nm.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(nm)

	var status := HBoxContainer.new()
	status.alignment = BoxContainer.ALIGNMENT_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(status)
	if Game.has_medallion(island_id):
		var med := HUD.IconControl.new()
		med.icon = "medallion"
		med.custom_minimum_size = Vector2(34, 34)
		status.add_child(med)
		var done := Label.new()
		done.text = " Complete!"
		done.add_theme_font_size_override("font_size", 17)
		done.add_theme_color_override("font_color", Color("#ffe08a"))
		status.add_child(done)
	else:
		var tag := Label.new()
		tag.text = info.get("tagline", "")
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tag.custom_minimum_size = Vector2(210, 0)
		tag.add_theme_font_size_override("font_size", 15)
		tag.add_theme_color_override("font_color", Color("#aab4bd"))
		status.add_child(tag)

	btn.pressed.connect(func(): _fly_to(island_id))
	return btn


func _locked_card(name_text: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 260)
	panel.add_theme_stylebox_override("panel", IconLib.panel_style(Color(0.06, 0.08, 0.11, 0.6), 18))
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)
	var q := Label.new()
	q.text = "?"
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.add_theme_font_size_override("font_size", 80)
	q.add_theme_color_override("font_color", Color("#4a545e"))
	vb.add_child(q)
	var nm := Label.new()
	nm.text = "%s\nComing soon" % name_text
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 19)
	nm.add_theme_color_override("font_color", Color("#6a747e"))
	vb.add_child(nm)
	return panel


func _fly_to(island_id: String) -> void:
	if _travelling:
		return
	_travelling = true
	Game.sfx("door")
	Game.goto_screen("world", {"island": island_id})


class IslandArt:
	extends Control
	var tint := Color("#3f9b57")

	func _draw() -> void:
		var u := size.y / 130.0
		var c := Vector2(size.x / 2.0, size.y * 0.62)
		draw_circle(c + Vector2(0, 14 * u), 44 * u, Color("#2e86b8"))
		draw_circle(c + Vector2(0, 8 * u), 37 * u, Color("#e8d0a0"))
		draw_circle(c, 29 * u, tint)
		draw_polygon(
			PackedVector2Array([c + Vector2(-12 * u, -14 * u), c + Vector2(12 * u, -14 * u), c + Vector2(0, -46 * u)]),
			PackedColorArray([tint.darkened(0.2), tint.darkened(0.2), tint.darkened(0.2)])
		)
