class_name ProfileScreen
extends Node2D
## "Who's playing?" — pick, create, or delete a device-local explorer profile.

var screen_args := {}

var _pin_panel: Node = null
var _pending_id := ""


func _ready() -> void:
	add_child(TitleScreen.SkyDrawer.new())

	var ui := CanvasLayer.new()
	add_child(ui)

	var title := Label.new()
	title.text = "Who's Playing?"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color("#25537a"))
	title.add_theme_constant_override("outline_size", 12)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position.y = 22
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ui.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	ui.add_child(row)

	for p in Game.profile_list():
		row.add_child(_profile_card(p))
	if Game.can_add_profile():
		row.add_child(_new_card())

	var back := IconLib.make_button("Back", 20, Color("#5a6572"))
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.position = Vector2(24, -70)
	back.grow_vertical = Control.GROW_DIRECTION_BEGIN
	back.pressed.connect(func():
		Game.sfx("click")
		Game.goto_screen("title")
	)
	ui.add_child(back)


func _profile_card(p: Dictionary) -> Control:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 6)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(210, 250)
	btn.add_theme_stylebox_override("normal", IconLib.panel_style(Color(0.08, 0.12, 0.18, 0.8), 18))
	btn.add_theme_stylebox_override("hover", IconLib.panel_style(Color(0.14, 0.2, 0.3, 0.9), 18, Color("#ffe08a")))
	btn.add_theme_stylebox_override("pressed", IconLib.panel_style(Color(0.05, 0.08, 0.12, 0.9), 18))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	wrap.add_child(btn)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var face := AvatarPortrait.new()
	face.cfg = p["avatar"]
	face.custom_minimum_size = Vector2(0, 140)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(face)

	var nm := Label.new()
	nm.text = str(p["name"]) + (" 🔒" if p["has_pin"] else "")
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 21)
	nm.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(nm)

	var meds := Label.new()
	var n: int = p["medallions"]
	meds.text = "%d medallion%s" % [n, "" if n == 1 else "s"]
	meds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meds.add_theme_font_size_override("font_size", 15)
	meds.add_theme_color_override("font_color", Color("#ffe08a"))
	vb.add_child(meds)

	btn.pressed.connect(func(): _choose(p))

	var del := IconLib.make_button("Delete", 14, Color("#8a3b33"))
	del.pressed.connect(func(): _confirm_delete(p))
	wrap.add_child(del)
	return wrap


func _new_card() -> Control:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 6)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(210, 250)
	btn.add_theme_stylebox_override("normal", IconLib.panel_style(Color(0.10, 0.2, 0.14, 0.75), 18))
	btn.add_theme_stylebox_override("hover", IconLib.panel_style(Color(0.16, 0.3, 0.2, 0.9), 18, Color("#8fe08a")))
	btn.add_theme_stylebox_override("pressed", IconLib.panel_style(Color(0.06, 0.12, 0.09, 0.9), 18))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	wrap.add_child(btn)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var plus := Label.new()
	plus.text = "+"
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.add_theme_font_size_override("font_size", 76)
	plus.add_theme_color_override("font_color", Color("#8fe08a"))
	vb.add_child(plus)

	var nm := Label.new()
	nm.text = "New Explorer"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 20)
	nm.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(nm)

	btn.pressed.connect(func():
		Game.sfx("click")
		Game.goto_screen("creator")
	)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	wrap.add_child(spacer)
	return wrap


func _choose(p: Dictionary) -> void:
	Game.sfx("click")
	if p["has_pin"]:
		_ask_pin(p)
		return
	_enter(p["id"])


func _enter(id: String) -> void:
	if not Game.select_profile(id):
		return
	if Game.can_resume() and IslandRegistry.has_island(Game.current_island):
		Game.goto_screen("world", {"island": Game.current_island, "room": Game.current_room})
	else:
		Game.goto_screen("map")


func _ask_pin(p: Dictionary) -> void:
	_pending_id = p["id"]
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	layer.add_child(dim)
	_pin_panel = layer

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", IconLib.panel_style(Color(0.08, 0.12, 0.18, 0.96), 16, Color("#2e8bc0")))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	dim.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(340, 0)
	panel.add_child(vb)

	var lbl := Label.new()
	lbl.text = "PIN for %s" % p["name"]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(lbl)

	var entry := LineEdit.new()
	entry.secret = true
	entry.max_length = 4
	entry.alignment = HORIZONTAL_ALIGNMENT_CENTER
	entry.add_theme_font_size_override("font_size", 26)
	entry.custom_minimum_size = Vector2(0, 46)
	vb.add_child(entry)
	entry.grab_focus()

	var err := Label.new()
	err.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	err.add_theme_font_size_override("font_size", 15)
	err.add_theme_color_override("font_color", Color("#ff9a90"))
	vb.add_child(err)

	var try_pin := func():
		if Game.check_pin(_pending_id, entry.text):
			layer.queue_free()
			_pin_panel = null
			_enter(_pending_id)
		else:
			err.text = "Wrong PIN — try again"
			entry.text = ""
	entry.text_submitted.connect(func(_t): try_pin.call())

	var ok := IconLib.make_button("Enter", 20, Color("#4ca64c"))
	ok.pressed.connect(func(): Game.sfx("click"); try_pin.call())
	vb.add_child(ok)

	var cancel := IconLib.make_button("Cancel", 18, Color("#5a6572"))
	cancel.pressed.connect(func():
		Game.sfx("click")
		layer.queue_free()
		_pin_panel = null
	)
	vb.add_child(cancel)


func _confirm_delete(p: Dictionary) -> void:
	Game.sfx("click")
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", IconLib.panel_style(Color(0.16, 0.08, 0.08, 0.96), 16, Color("#d9483b")))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	dim.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(420, 0)
	panel.add_child(vb)

	var lbl := Label.new()
	lbl.text = "Delete %s?" % p["name"]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(lbl)

	var sub := Label.new()
	sub.text = "%d medallion(s) and all progress will be lost.\nThis cannot be undone." % p["medallions"]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color("#f0c0b8"))
	vb.add_child(sub)

	var yes := IconLib.make_button("Delete forever", 19, Color("#d9483b"))
	yes.pressed.connect(func():
		Game.sfx("click")
		Game.delete_profile(p["id"])
		Game.goto_screen("profiles")
	)
	vb.add_child(yes)

	var no := IconLib.make_button("Keep it", 19, Color("#4ca64c"))
	no.pressed.connect(func():
		Game.sfx("click")
		layer.queue_free()
	)
	vb.add_child(no)


class AvatarPortrait:
	extends Control
	var cfg := {}
	var _rig: AvatarRig

	func _ready() -> void:
		_rig = AvatarRig.new()
		_rig.apply_config(cfg)
		_rig.scale = Vector2.ONE * 0.92
		add_child(_rig)

	func _process(_d: float) -> void:
		if _rig:
			_rig.position = Vector2(size.x / 2.0, size.y - 4)
