class_name HUD
extends CanvasLayer
## In-world overlay: island name, quest hint, backpack + map buttons,
## inventory panel, item-get popup, medallion ceremony.

signal request_map

var world: Node = null  # set by world.gd

var _inv_panel: Control
var _popup_layer: Control
var _hint_label: Label
var _island_label: Label


func _ready() -> void:
	layer = 15

	var top := MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.add_theme_constant_override("margin_left", 14)
	top.add_theme_constant_override("margin_right", 14)
	top.add_theme_constant_override("margin_top", 10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(row)

	var left_col := VBoxContainer.new()
	left_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left_col)

	_island_label = Label.new()
	_island_label.add_theme_font_size_override("font_size", 22)
	_island_label.add_theme_color_override("font_color", Color.WHITE)
	_island_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	_island_label.add_theme_constant_override("outline_size", 8)
	left_col.add_child(_island_label)

	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 16)
	_hint_label.add_theme_color_override("font_color", Color("#ffe08a"))
	_hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	_hint_label.add_theme_constant_override("outline_size", 7)
	left_col.add_child(_hint_label)

	var map_btn := _icon_button("map")
	map_btn.pressed.connect(func(): Game.sfx("click"); request_map.emit())
	row.add_child(map_btn)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(10, 0)
	row.add_child(spacer)

	var inv_btn := _icon_button("backpack")
	inv_btn.pressed.connect(_toggle_inventory)
	row.add_child(inv_btn)

	_popup_layer = Control.new()
	_popup_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_popup_layer)


func _icon_button(icon: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(58, 58)
	b.add_theme_stylebox_override("normal", IconLib.panel_style(Color(0.1, 0.16, 0.24, 0.75), 14))
	b.add_theme_stylebox_override("hover", IconLib.panel_style(Color(0.16, 0.24, 0.34, 0.85), 14))
	b.add_theme_stylebox_override("pressed", IconLib.panel_style(Color(0.07, 0.1, 0.16, 0.9), 14))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ic := IconControl.new()
	ic.icon = icon
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)
	return b


func set_island_name(text: String) -> void:
	_island_label.text = text


func set_hint(text: String) -> void:
	_hint_label.text = text


func is_blocking() -> bool:
	return _inv_panel != null or _popup_layer.get_child_count() > 0


# ---------- inventory ----------

func _toggle_inventory() -> void:
	Game.sfx("click")
	if _inv_panel:
		_inv_panel.queue_free()
		_inv_panel = null
		return
	_inv_panel = PanelContainer.new()
	_inv_panel.add_theme_stylebox_override("panel", IconLib.panel_style(Color(0.08, 0.12, 0.18, 0.94), 16, Color("#2e8bc0")))
	_inv_panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(_inv_panel)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(520, 0)
	_inv_panel.add_child(vb)

	var title := Label.new()
	title.text = "Backpack — %s" % Game.player_name
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(title)

	if Game.inventory.is_empty():
		var empty := Label.new()
		empty.text = "Nothing here yet. Explore the island!"
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color("#aab4bd"))
		vb.add_child(empty)

	for id in Game.inventory:
		var info: Dictionary = Game.ITEMS.get(id, {"name": id, "desc": "", "icon": "shard"})
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		vb.add_child(hb)
		var ic := IconControl.new()
		ic.icon = info.get("icon", "shard")
		ic.custom_minimum_size = Vector2(52, 52)
		hb.add_child(ic)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(col)
		var nm := Label.new()
		nm.text = info.get("name", id)
		nm.add_theme_font_size_override("font_size", 19)
		nm.add_theme_color_override("font_color", Color("#ffe08a"))
		col.add_child(nm)
		var ds := Label.new()
		ds.text = info.get("desc", "")
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.add_theme_font_size_override("font_size", 15)
		ds.add_theme_color_override("font_color", Color("#c8d0d8"))
		col.add_child(ds)

	if not Game.medallions.is_empty():
		var mrow := HBoxContainer.new()
		mrow.add_theme_constant_override("separation", 10)
		vb.add_child(mrow)
		var ml := Label.new()
		ml.text = "Medallions:"
		ml.add_theme_font_size_override("font_size", 18)
		ml.add_theme_color_override("font_color", Color.WHITE)
		mrow.add_child(ml)
		for m in Game.medallions:
			var ic2 := IconControl.new()
			ic2.icon = "medallion"
			ic2.custom_minimum_size = Vector2(40, 40)
			mrow.add_child(ic2)

	var close := IconLib.make_button("Close", 20, Color("#d9483b"))
	close.pressed.connect(_toggle_inventory)
	vb.add_child(close)


# ---------- popups ----------

func show_item_popup(item_id: String) -> void:
	var info: Dictionary = Game.ITEMS.get(item_id, {"name": item_id, "desc": "", "icon": "shard"})
	_show_popup("You got: %s!" % info.get("name", item_id), str(info.get("desc", "")), info.get("icon", "shard"), false)


func show_medallion(island_name: String) -> void:
	_show_popup("Island Complete!", "You earned the %s Medallion!" % island_name, "medallion", true)
	Game.sfx("medallion")


func _show_popup(title_text: String, body_text: String, icon: String, celebrate: bool) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup_layer.add_child(dim)

	if celebrate:
		var parts := CPUParticles2D.new()
		parts.amount = 120
		parts.lifetime = 2.5
		parts.one_shot = false
		parts.speed_scale = 1.0
		parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		parts.emission_rect_extents = Vector2(640, 10)
		parts.direction = Vector2(0, 1)
		parts.spread = 25.0
		parts.gravity = Vector2(0, 220)
		parts.initial_velocity_min = 60.0
		parts.initial_velocity_max = 160.0
		parts.scale_amount_min = 3.0
		parts.scale_amount_max = 6.0
		parts.color_ramp = _confetti_gradient()
		parts.position = Vector2(dim.get_viewport_rect().size.x / 2.0, -20)
		dim.add_child(parts)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", IconLib.panel_style(Color(0.98, 0.96, 0.9, 0.98), 18, Color("#d8a12c")))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	dim.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.custom_minimum_size = Vector2(420, 0)
	panel.add_child(vb)

	var ic := IconControl.new()
	ic.icon = icon
	ic.custom_minimum_size = Vector2(90, 90)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(ic)

	var t := Label.new()
	t.text = title_text
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 26)
	t.add_theme_color_override("font_color", Color("#22292f"))
	vb.add_child(t)

	var b := Label.new()
	b.text = body_text
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color("#4a545e"))
	vb.add_child(b)

	var ok := IconLib.make_button("Nice!", 22, Color("#4ca64c"))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func():
		Game.sfx("click")
		dim.queue_free()
	)
	vb.add_child(ok)


func _confetti_gradient() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color("#e8c930"))
	g.set_color(1, Color("#d9483b"))
	g.add_point(0.33, Color("#4ca64c"))
	g.add_point(0.66, Color("#2e8bc0"))
	return g


class IconControl:
	extends Control
	var icon := "shard"

	func _draw() -> void:
		IconLib.draw_icon(self, icon, size / 2.0, minf(size.x, size.y) * 0.62)
