class_name DialogUI
extends CanvasLayer
## Speech bubble pinned above the speaking character. Tap to advance.

signal finished(actions: Array)

var active := false

var _speaker: Node2D = null
var _speaker_rig: AvatarRig = null
var _lines := []
var _actions := []
var _line_idx := 0
var _chars := 0.0
var _panel: PanelContainer
var _label: Label
var _name_label: Label
var _hint: Label


func _ready() -> void:
	layer = 20
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", IconLib.panel_style(Color(1, 1, 1, 0.96), 14, Color("#2b3a4a")))
	_panel.visible = false
	add_child(_panel)

	var vb := VBoxContainer.new()
	_panel.add_child(vb)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_color_override("font_color", Color("#2e8bc0"))
	vb.add_child(_name_label)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 19)
	_label.add_theme_color_override("font_color", Color("#22292f"))
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(360, 0)
	vb.add_child(_label)

	_hint = Label.new()
	_hint.text = "tap to continue ▸"
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color("#8a9198"))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_hint)


func start(speaker: Node2D, speaker_name: String, lines: Array, actions: Array = []) -> void:
	_speaker = speaker
	_speaker_rig = null
	if speaker is NPC:
		_speaker_rig = speaker.rig
	elif speaker is Player:
		_speaker_rig = speaker.rig
	_lines = lines
	_actions = actions
	_line_idx = 0
	_chars = 0.0
	_name_label.text = speaker_name
	active = true
	_panel.visible = true
	if _speaker_rig:
		_speaker_rig.talking = true
	Game.sfx("talk")


func advance() -> void:
	if not active:
		return
	var full := str(_lines[_line_idx])
	if _chars < full.length():
		_chars = full.length()  # reveal all first
		return
	_line_idx += 1
	_chars = 0.0
	if _line_idx >= _lines.size():
		_close()
	else:
		Game.sfx("talk")


func _close() -> void:
	active = false
	_panel.visible = false
	if _speaker_rig:
		_speaker_rig.talking = false
	var acts := _actions
	_actions = []
	finished.emit(acts)


func _process(delta: float) -> void:
	if not active or _speaker == null or not is_instance_valid(_speaker):
		if active:
			_close()
		return
	var full := str(_lines[_line_idx])
	_chars = minf(_chars + delta * 55.0, full.length())
	_label.text = full.substr(0, int(_chars))
	_hint.visible = _chars >= full.length()

	# pin above speaker's head in screen coords
	var head_y := -150.0
	if _speaker is NPC:
		head_y = -130.0 * (_speaker as NPC).rig.scale.y - 30.0
	var screen_pos: Vector2 = _speaker.get_global_transform_with_canvas() * Vector2(0, head_y)
	var vp := _panel.get_viewport_rect().size
	_panel.reset_size()
	var sz := _panel.size
	var pos := screen_pos + Vector2(-sz.x / 2.0, -sz.y)
	pos.x = clampf(pos.x, 10, vp.x - sz.x - 10)
	pos.y = clampf(pos.y, 10, vp.y - sz.y - 10)
	_panel.position = pos
