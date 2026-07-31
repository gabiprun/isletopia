class_name NPC
extends Node2D
## Standing character with a name and a data-driven dialog table.

var npc_id := ""
var npc_name := ""
var dialog := []  # array of {if?, lines:[], actions?:[]}
var rig: AvatarRig
var interact_radius := 110.0


func setup(def: Dictionary) -> void:
	npc_id = def.get("id", "npc")
	npc_name = def.get("name", "???")
	dialog = def.get("dialog", [])
	position = def.get("pos", Vector2.ZERO)

	rig = AvatarRig.new()
	rig.apply_colors(def.get("look", {}))
	rig.scale = Vector2.ONE * def.get("scale", 1.0)
	if def.get("face_left", false):
		rig.facing = -1
	add_child(rig)

	var label := Label.new()
	label.text = npc_name
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("#ffe08a"))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(240, 20)
	var s: float = def.get("scale", 1.0)
	label.position = Vector2(-120, -130 * s - 12)
	add_child(label)


func face_towards(x: float) -> void:
	rig.facing = 1 if x > global_position.x else -1


func head_pos() -> Vector2:
	return global_position + Vector2(0, -110.0 * rig.scale.y)


func pick_entry() -> Dictionary:
	for entry in dialog:
		if _cond_ok(entry.get("if", {})):
			return entry
	return {"lines": ["..."]}


func _cond_ok(cond: Dictionary) -> bool:
	for key in cond:
		var v = cond[key]
		match key:
			"flag":
				if not Game.flag(v):
					return false
			"not_flag":
				if Game.flag(v):
					return false
			"has_item":
				if not Game.has_item(v):
					return false
			"not_item":
				if Game.has_item(v):
					return false
			"has_all":
				for it in v:
					if not Game.has_item(it):
						return false
	return true
