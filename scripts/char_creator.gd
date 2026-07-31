class_name CharCreator
extends Node2D
## Avatar customization + generated explorer name.

const ADJECTIVES := ["Brave", "Shiny", "Sneaky", "Mighty", "Zippy", "Clever", "Lucky", "Wild", "Quiet", "Golden", "Fuzzy", "Swift", "Merry", "Bold", "Sunny"]
const NOUNS := ["Falcon", "Otter", "Comet", "Tiger", "Pebble", "Sailor", "Wolf", "Sparrow", "Maple", "Rocket", "Badger", "Coral", "Drifter", "Lantern", "Breeze"]

var screen_args := {}
var _cfg := {}
var _rig: AvatarRig
var _name_label: Label
var _player_name := ""


func _ready() -> void:
	_cfg = Game.avatar.duplicate()
	_player_name = Game.player_name if Game.player_name != "Traveler" else _random_name()

	add_child(TitleScreen.SkyDrawer.new())

	_rig = AvatarRig.new()
	_rig.scale = Vector2.ONE * 2.4
	add_child(_rig)
	_apply()

	var ui := CanvasLayer.new()
	add_child(ui)

	var title := Label.new()
	title.text = "Create Your Explorer"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color("#25537a"))
	title.add_theme_constant_override("outline_size", 12)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position.y = 24
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ui.add_child(title)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 26)
	_name_label.add_theme_color_override("font_color", Color("#ffe08a"))
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	_name_label.add_theme_constant_override("outline_size", 8)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(_name_label)

	# right-side option rows
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", IconLib.panel_style(Color(0.08, 0.12, 0.18, 0.85), 16))
	ui.add_child(panel)
	_panel_ref = panel

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	vb.add_child(_option_row("Skin", "skin", AvatarRig.SKIN_TONES.size()))
	vb.add_child(_option_row("Hair Style", "hair_style", AvatarRig.HAIR_STYLE_COUNT))
	vb.add_child(_option_row("Hair Color", "hair_color", AvatarRig.HAIR_COLORS.size()))
	vb.add_child(_option_row("Shirt", "shirt", AvatarRig.CLOTH_COLORS.size()))
	vb.add_child(_option_row("Pants", "pants", AvatarRig.CLOTH_COLORS.size()))

	var rand_btn := IconLib.make_button("🎲 Randomize", 20, Color("#8a4fb0"))
	rand_btn.pressed.connect(func():
		Game.sfx("click")
		_cfg = AvatarRig.random_look()
		_apply()
	)
	vb.add_child(rand_btn)

	var name_btn := IconLib.make_button("New Name", 20, Color("#e88f2a"))
	name_btn.pressed.connect(func():
		Game.sfx("click")
		_player_name = _random_name()
		_layout()
	)
	vb.add_child(name_btn)

	var go := IconLib.make_button("Set Sail!", 24, Color("#4ca64c"))
	go.pressed.connect(_on_start)
	vb.add_child(go)

	get_viewport().size_changed.connect(_layout)
	_layout()


var _panel_ref: PanelContainer


func _layout() -> void:
	var vp := get_viewport_rect().size
	_rig.position = Vector2(vp.x * 0.3, vp.y * 0.62)
	_name_label.size = Vector2(400, 30)
	_name_label.position = Vector2(vp.x * 0.3 - 200, vp.y * 0.68)
	_name_label.text = _player_name
	if _panel_ref:
		var psize := _panel_ref.get_combined_minimum_size()
		_panel_ref.position = Vector2(vp.x - psize.x - 36.0, (vp.y - psize.y) / 2.0)


func _option_row(label_text: String, key: String, count: int) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)

	var prev := IconLib.make_button("◀", 18, Color("#2e8bc0"))
	prev.pressed.connect(func(): _cycle(key, -1, count))
	hb.add_child(prev)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(150, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	hb.add_child(lbl)

	var next := IconLib.make_button("▶", 18, Color("#2e8bc0"))
	next.pressed.connect(func(): _cycle(key, 1, count))
	hb.add_child(next)
	return hb


func _cycle(key: String, dir: int, count: int) -> void:
	Game.sfx("click")
	_cfg[key] = wrapi(int(_cfg[key]) + dir, 0, count)
	_apply()


func _apply() -> void:
	_rig.apply_config(_cfg)


func _random_name() -> String:
	return "%s %s" % [ADJECTIVES[randi() % ADJECTIVES.size()], NOUNS[randi() % NOUNS.size()]]


func _on_start() -> void:
	Game.sfx("click")
	Game.avatar = _cfg.duplicate()
	Game.player_name = _player_name
	Game.save()
	Game.goto_screen("map")
