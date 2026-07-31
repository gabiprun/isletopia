class_name ItemNode
extends Node2D
## A floating collectible. Picked-up state is tracked via flag "picked_<id>".

var item_id := ""
var icon := "shard"
var _t := 0.0
var _base_y := 0.0


func setup(def: Dictionary) -> void:
	item_id = def.get("id", "")
	icon = def.get("icon", Game.ITEMS.get(item_id, {}).get("icon", "shard"))
	position = def.get("pos", Vector2.ZERO)
	_base_y = position.y
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta * 2.4
	position.y = _base_y + sin(_t) * 6.0
	queue_redraw()


func _draw() -> void:
	# glow
	var pulse := 0.5 + 0.25 * sin(_t * 1.7)
	draw_circle(Vector2.ZERO, 30.0, Color(1.0, 1.0, 0.7, 0.10 + 0.08 * pulse))
	draw_circle(Vector2.ZERO, 22.0, Color(1.0, 1.0, 0.7, 0.12 + 0.08 * pulse))
	IconLib.draw_icon(self, icon, Vector2.ZERO, 36.0)
