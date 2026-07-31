class_name Door
extends Node2D
## Room link marker: bouncing arrow + label. Tap to travel (world handles it).

var to_room := ""
var spawn := "default"
var label_text := ""
var arrow_dir := Vector2.RIGHT  # visual hint direction
var is_exit_island := false     # returns to map
var _t := 0.0


func setup(def: Dictionary) -> void:
	to_room = def.get("to", "")
	spawn = def.get("spawn", "default")
	label_text = def.get("label", "")
	position = def.get("pos", Vector2.ZERO)
	is_exit_island = def.get("exit_island", false)
	arrow_dir = def.get("dir", Vector2.RIGHT)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("outline_size", 7)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(240, 22)
	label.position = Vector2(-120, -74)
	add_child(label)


func _process(delta: float) -> void:
	_t += delta * 3.0
	queue_redraw()


func _draw() -> void:
	var bounce := sin(_t) * 5.0
	var c := Vector2(0, -40 + bounce)
	var col := Color("#ffe08a")
	var outline := Color("#b07d1e")
	# circle badge
	draw_circle(c, 20.0, Color(0.1, 0.15, 0.25, 0.55))
	draw_arc(c, 20.0, 0, TAU, 24, col, 2.5)
	# arrow
	var d := arrow_dir.normalized()
	var perp := Vector2(-d.y, d.x)
	var tip := c + d * 11.0
	var back := c - d * 8.0
	draw_line(back, tip, col, 4.0)
	draw_polygon(
		PackedVector2Array([tip + d * 7.0, tip + perp * 6.0, tip - perp * 6.0]),
		PackedColorArray([col, col, col])
	)
	if outline.a > 0:
		pass
