class_name World
extends Node2D
## Room engine: builds a room from island data, runs point-and-click input,
## item pickup, NPC dialog, door travel.

var screen_args := {}

var island := {}
var rooms := {}
var room := {}
var room_id := ""

var player: Player
var camera: Camera2D
var dialog: DialogUI
var hud: HUD

var _room_root: Node2D
var _npcs := []
var _items := []
var _doors := []
var _pending := {}  # {"kind": "npc"/"door", "node": Node}
var _edge_cooldown := 0.0


static func cond_ok(cond: Dictionary) -> bool:
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


func _ready() -> void:
	island = IslandRegistry.get_island(screen_args.get("island", "ember"))
	rooms = island.get("rooms", {})

	player = Player.new()
	add_child(player)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	player.add_child(camera)
	camera.position = Vector2(0, -60)
	camera.make_current()

	hud = HUD.new()
	add_child(hud)
	hud.set_island_name(island.get("name", ""))
	hud.request_map.connect(_go_map)

	dialog = DialogUI.new()
	add_child(dialog)
	dialog.finished.connect(_on_dialog_finished)

	player.arrived.connect(_on_player_arrived)
	Game.flags_changed.connect(_update_hint)
	Game.inventory_changed.connect(_update_hint)

	var start_room: String = screen_args.get("room", "")
	if start_room == "" or not rooms.has(start_room):
		start_room = island.get("start_room", rooms.keys()[0])
	build_room(start_room, screen_args.get("spawn", "default"))


# ---------- room building ----------

func build_room(id: String, spawn_key := "default", keep_pos := Vector2.INF) -> void:
	room_id = id
	room = rooms[id]
	Game.current_island = island.get("id", "")
	Game.current_room = id
	Game.save()

	if _room_root:
		_room_root.queue_free()
	_npcs = []
	_items = []
	_doors = []
	_pending = {}

	_room_root = Node2D.new()
	add_child(_room_root)

	var size: Vector2 = room.get("size", Vector2(2400, 720))

	# background
	var bg := BGDrawer.new()
	bg.theme_name = room.get("bg", "coast")
	bg.room_size = size
	bg.z_index = -20
	_room_root.add_child(bg)

	# platforms
	for pdef in room.get("platforms", []):
		_make_platform(pdef)

	# invisible walls + safety floor
	_make_wall(Rect2(-60, -800, 60, size.y + 1600))
	_make_wall(Rect2(size.x, -800, 60, size.y + 1600))
	_make_wall(Rect2(-100, size.y + 120, size.x + 200, 60))

	# props
	for pdef in room.get("props", []):
		if pdef.has("visible_flag") and not Game.flag(pdef["visible_flag"]):
			continue
		if pdef.has("hidden_flag") and Game.flag(pdef["hidden_flag"]):
			continue
		var resolved: Dictionary = pdef.duplicate()
		if pdef.has("lit_flag"):
			resolved["lit"] = Game.flag(pdef["lit_flag"])
		if pdef.has("has_bell_flag"):
			resolved["has_bell"] = Game.flag(pdef["has_bell_flag"])
		if pdef.has("open_flag"):
			resolved["open"] = Game.flag(pdef["open_flag"])
		var prop := Prop.new()
		prop.setup(resolved)
		_room_root.add_child(prop)

	# npcs
	for ndef in room.get("npcs", []):
		if ndef.has("visible_flag") and not Game.flag(ndef["visible_flag"]):
			continue
		if ndef.has("hidden_flag") and Game.flag(ndef["hidden_flag"]):
			continue
		var npc := NPC.new()
		npc.setup(ndef)
		_room_root.add_child(npc)
		_npcs.append(npc)

	# items
	for idef in room.get("items", []):
		var iid: String = idef.get("id", "")
		if Game.flag("picked_" + iid) or Game.has_item(iid):
			continue
		if idef.has("require_flag") and not Game.flag(idef["require_flag"]):
			continue
		var item := ItemNode.new()
		item.setup(idef)
		_room_root.add_child(item)
		_items.append(item)

	# doors
	for ddef in room.get("doors", []):
		if ddef.has("visible_flag") and not Game.flag(ddef["visible_flag"]):
			continue
		var door := Door.new()
		door.setup(ddef)
		_room_root.add_child(door)
		_doors.append(door)

	# player placement
	var spawns: Dictionary = room.get("spawns", {})
	var spawn_pos: Vector2 = spawns.get(spawn_key, spawns.get("default", Vector2(200, size.y - 100)))
	if keep_pos != Vector2.INF:
		spawn_pos = keep_pos
	player.global_position = spawn_pos
	player.velocity = Vector2.ZERO
	player.clear_target()
	_edge_cooldown = 0.5
	_pressing = false
	player.swim_mode = room.get("swim", false)
	camera.reset_smoothing()

	# camera limits
	camera.limit_left = 0
	camera.limit_top = -200
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)

	# darkness / lighting
	_setup_lighting()

	# ambient particles
	_setup_particles(size)

	_update_hint()


func refresh_room() -> void:
	build_room(room_id, "default", player.global_position)


func _make_platform(pdef: Dictionary) -> void:
	var r_arr: Array = pdef.get("rect", [0, 0, 100, 40])
	var rect := Rect2(r_arr[0], r_arr[1], r_arr[2], r_arr[3])
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2.0
	body.set_meta("kind", pdef.get("kind", "grass"))
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.one_way_collision = pdef.get("one_way", false)
	body.add_child(shape)
	_room_root.add_child(body)

	var vis := PlatDrawer.new()
	vis.rect = Rect2(-rect.size / 2.0, rect.size)
	vis.kind = pdef.get("kind", "grass")
	body.add_child(vis)


func _make_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2.0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	_room_root.add_child(body)


func _setup_lighting() -> void:
	if room.get("dark", false):
		var cm := CanvasModulate.new()
		cm.color = Color(0.13, 0.14, 0.2)
		_room_root.add_child(cm)
		var light := PointLight2D.new()
		var grad := Gradient.new()
		grad.set_color(0, Color.WHITE)
		grad.set_color(1, Color(1, 1, 1, 0))
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = 1024
		tex.height = 1024
		light.texture = tex
		light.position = Vector2(0, -50)
		if Game.has_item("lantern"):
			light.energy = 1.6
			light.texture_scale = 1.6
		else:
			light.energy = 0.9
			light.texture_scale = 0.45
		light.name = "PlayerLight"
		var old := player.get_node_or_null("PlayerLight")
		if old:
			old.queue_free()
		player.add_child(light)
	else:
		var old := player.get_node_or_null("PlayerLight")
		if old:
			old.queue_free()


func _setup_particles(size: Vector2) -> void:
	var theme: String = room.get("bg", "coast")
	if theme in ["snow", "summit"]:
		var parts := CPUParticles2D.new()
		parts.amount = 90
		parts.lifetime = 6.0
		parts.preprocess = 6.0
		parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		parts.emission_rect_extents = Vector2(size.x / 2.0 + 200, 10)
		parts.position = Vector2(size.x / 2.0, -150)
		parts.direction = Vector2(0.3, 1)
		parts.spread = 12.0
		parts.gravity = Vector2(0, 22)
		parts.initial_velocity_min = 50.0
		parts.initial_velocity_max = 110.0
		parts.scale_amount_min = 2.0
		parts.scale_amount_max = 4.0
		parts.color = Color(1, 1, 1, 0.85)
		_room_root.add_child(parts)
	elif theme == "underwater":
		var parts := CPUParticles2D.new()
		parts.amount = 50
		parts.lifetime = 5.0
		parts.preprocess = 5.0
		parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		parts.emission_rect_extents = Vector2(size.x / 2.0, 10)
		parts.position = Vector2(size.x / 2.0, size.y)
		parts.direction = Vector2(0, -1)
		parts.spread = 8.0
		parts.gravity = Vector2(0, -60)
		parts.initial_velocity_min = 30.0
		parts.initial_velocity_max = 80.0
		parts.scale_amount_min = 2.0
		parts.scale_amount_max = 5.0
		parts.color = Color(0.8, 0.95, 1.0, 0.5)
		_room_root.add_child(parts)


# ---------- input ----------

const TAP_TIME := 0.25   # press/release faster than this counts as a tap
const TAP_SLOP := 24.0   # ...and moved less than this many pixels

var _press_pos := Vector2.INF
var _press_time := 0.0
var _pressing := false


func _unhandled_input(event: InputEvent) -> void:
	# keyboard: E talks to the nearest NPC / advances dialog
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if dialog.active:
			dialog.advance()
		elif not hud.is_blocking():
			_talk_nearest()
		return
	# Enter acts like a click: advance dialog, else interact with what's nearest
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		if dialog.active:
			dialog.advance()
		elif not hud.is_blocking():
			_interact_nearest()
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_SPACE and dialog.active:
		dialog.advance()
		return

	# pointer: press / drag / release
	var pos := Vector2.INF
	var phase := ""
	if event is InputEventScreenTouch:
		pos = event.position
		phase = "down" if event.pressed else "up"
	elif event is InputEventScreenDrag:
		pos = event.position
		phase = "move"
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false):
		pos = event.position
		phase = "down" if event.pressed else "up"
	elif event is InputEventMouseMotion and _pressing \
			and not ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false):
		pos = event.position
		phase = "move"
	if phase == "":
		return

	if dialog.active:
		if phase == "down":
			dialog.advance()
		return
	if hud.is_blocking() or player.input_locked:
		return

	var wp: Vector2 = get_canvas_transform().affine_inverse() * pos

	match phase:
		"down":
			_pressing = true
			_press_pos = pos
			_press_time = float(Time.get_ticks_msec()) / 1000.0
			# doors and NPCs resolve immediately on press
			for door in _doors:
				if wp.distance_to(door.global_position + Vector2(0, -40)) < 60.0:
					_pressing = false
					_request_door(door)
					return
			for npc in _npcs:
				if _npc_rect(npc).has_point(wp):
					_pressing = false
					_request_npc(npc)
					return
			player.begin_hold(wp)
		"move":
			if _pressing:
				player.update_hold(wp)
		"up":
			if not _pressing:
				return
			_pressing = false
			player.end_hold()
			var held := float(Time.get_ticks_msec()) / 1000.0 - _press_time
			var moved := pos.distance_to(_press_pos)
			# a quick tap well above the player means "jump"
			if held < TAP_TIME and moved < TAP_SLOP:
				if wp.y < player.global_position.y - 90.0:
					player.request_jump()
					player.set_move_target(wp)
				else:
					player.set_move_target(wp)


func _npc_rect(npc: NPC) -> Rect2:
	var top: Vector2 = npc.head_pos()
	var half := 44.0 * npc.rig.scale.x
	return Rect2(top.x - half, top.y - 30.0, half * 2.0, npc.global_position.y - top.y + 40.0)


func _talk_nearest() -> void:
	var best: NPC = null
	var best_d := 190.0
	for npc in _npcs:
		var d: float = player.global_position.distance_to(npc.global_position)
		if d < best_d:
			best_d = d
			best = npc
	if best:
		_talk(best)


func _interact_nearest() -> void:
	## Enter/click-equivalent: prefer an NPC in range, else a door in range.
	var best_npc: NPC = null
	var best_d := 190.0
	for npc in _npcs:
		var d: float = player.global_position.distance_to(npc.global_position)
		if d < best_d:
			best_d = d
			best_npc = npc
	if best_npc:
		_talk(best_npc)
		return
	var best_door: Door = null
	var door_d := 150.0
	for door in _doors:
		var d: float = player.global_position.distance_to(door.global_position)
		if d < door_d:
			door_d = d
			best_door = door
	if best_door:
		_travel(best_door)


func _request_door(door: Door) -> void:
	if player.global_position.distance_to(door.global_position) < 140.0:
		_travel(door)
	else:
		_pending = {"kind": "door", "node": door}
		player.set_move_target(door.global_position)


func _request_npc(npc: NPC) -> void:
	if player.global_position.distance_to(npc.global_position) < npc.interact_radius:
		_talk(npc)
	else:
		_pending = {"kind": "npc", "node": npc}
		var side := 1.0 if player.global_position.x < npc.global_position.x else -1.0
		player.set_move_target(npc.global_position + Vector2(-side * 70.0, 0))


func _on_player_arrived() -> void:
	_check_pending(true)


func _physics_process(delta: float) -> void:
	_edge_cooldown = maxf(_edge_cooldown - delta, 0.0)
	_check_edge_travel()
	_check_pending(false)
	# item pickup by proximity
	for item in _items.duplicate():
		if not is_instance_valid(item):
			continue
		if player.global_position.distance_to(item.global_position + Vector2(0, 40)) < 62.0 \
				or player.global_position.distance_to(item.global_position) < 62.0:
			_pick_item(item)


func _check_edge_travel() -> void:
	## Walking into the left/right boundary carries you to the adjoining room.
	if _edge_cooldown > 0.0 or dialog.active or player.input_locked or hud.is_blocking():
		return
	var size: Vector2 = room.get("size", Vector2(2400, 720))
	var margin := 44.0
	var at_left := player.global_position.x <= margin
	var at_right := player.global_position.x >= size.x - margin
	if not at_left and not at_right:
		return
	# only when actually pushing that way (not just standing at the wall)
	if at_left and player.velocity.x > -20.0:
		return
	if at_right and player.velocity.x < 20.0:
		return
	var best: Door = null
	for door in _doors:
		if door.is_exit_island:
			continue  # leaving the island stays a deliberate tap on the blimp
		# only doors that actually lead sideways — a "Surface"/"Dive" exit that
		# happens to sit near the edge must not trigger from walking into it
		if absf(door.arrow_dir.x) < 0.5:
			continue
		if at_left and door.arrow_dir.x < 0 and door.position.x < size.x * 0.25:
			if best == null or door.position.x < best.position.x:
				best = door
		elif at_right and door.arrow_dir.x > 0 and door.position.x > size.x * 0.75:
			if best == null or door.position.x > best.position.x:
				best = door
	if best:
		_travel(best)


func _check_pending(arrived: bool) -> void:
	if _pending.is_empty():
		return
	var node = _pending.get("node")
	if node == null or not is_instance_valid(node):
		_pending = {}
		return
	var dist: float = player.global_position.distance_to(node.global_position)
	match _pending.get("kind"):
		"door":
			if dist < 140.0:
				_pending = {}
				_travel(node)
			elif arrived:
				_pending = {}
		"npc":
			if dist < (node as NPC).interact_radius:
				_pending = {}
				_talk(node)
			elif arrived:
				_pending = {}


func _pick_item(item: ItemNode) -> void:
	_items.erase(item)
	var iid := item.item_id
	item.queue_free()
	Game.set_flag("picked_" + iid)
	Game.give_item(iid)
	Game.sfx("pickup")
	if not Game.smoke_mode:
		hud.show_item_popup(iid)


# ---------- dialog / actions ----------

func _talk(npc: NPC) -> void:
	npc.face_towards(player.global_position.x)
	player.rig.facing = 1 if npc.global_position.x > player.global_position.x else -1
	player.clear_target()
	player.input_locked = true
	var entry := npc.pick_entry()
	dialog.start(npc, npc.npc_name, entry.get("lines", ["..."]), entry.get("actions", []))


func _on_dialog_finished(actions: Array) -> void:
	player.input_locked = false
	var need_refresh := false
	for act in actions:
		for key in act:
			var v = act[key]
			match key:
				"set_flag":
					Game.set_flag(v)
					need_refresh = true
				"give_item":
					Game.give_item(v)
					Game.sfx("pickup")
					if not Game.smoke_mode:
						hud.show_item_popup(v)
				"take_item":
					Game.take_item(v)
				"medallion":
					Game.award_medallion(island.get("id", ""))
					need_refresh = true
					if not Game.smoke_mode:
						hud.show_medallion(island.get("name", ""))
	if need_refresh:
		refresh_room()
	_update_hint()


# ---------- travel ----------

func _travel(door: Door) -> void:
	Game.sfx("door")
	if door.is_exit_island:
		_go_map()
		return
	build_room(door.to_room, door.spawn)


func _go_map() -> void:
	Game.goto_screen("map")


# ---------- hints ----------

func _update_hint() -> void:
	if not hud:
		return
	for h in island.get("hints", []):
		if cond_ok(h.get("if", {})):
			hud.set_hint(str(h.get("text", "")))
			return
	hud.set_hint("")


# ---------- helpers for smoke test ----------

func smoke_talk(npc_id: String) -> bool:
	for npc in _npcs:
		if npc.npc_id == npc_id:
			player.global_position = npc.global_position + Vector2(-60, 0)
			_talk(npc)
			return true
	return false


func smoke_travel(to_room: String) -> bool:
	for door in _doors:
		if door.to_room == to_room and not door.is_exit_island:
			build_room(door.to_room, door.spawn)
			return true
	return false


func smoke_grab(item_id: String) -> bool:
	for item in _items.duplicate():
		if item.item_id == item_id:
			_pick_item(item)
			return true
	return false


# ---------- inner drawers ----------

class BGDrawer:
	extends Node2D
	var theme_name := "coast"
	var room_size := Vector2(2400, 720)

	const THEMES := {
		"coast": {"top": Color("#7ec8f0"), "bottom": Color("#cdeaf8")},
		"street": {"top": Color("#8ecfeb"), "bottom": Color("#e8e0c8")},
		"cliffs": {"top": Color("#6fb8e8"), "bottom": Color("#bcdff2")},
		"cave": {"top": Color("#23282e"), "bottom": Color("#3a4048")},
		"underwater": {"top": Color("#1f6f9f"), "bottom": Color("#0c3a58")},
		"snow": {"top": Color("#a8cfe8"), "bottom": Color("#e8f2f8")},
		"summit": {"top": Color("#6888b8"), "bottom": Color("#c8d8ea")},
	}

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		var t: Dictionary = THEMES.get(theme_name, THEMES["coast"])
		var w := room_size.x
		var h := room_size.y
		var top: Color = t["top"]
		var bottom: Color = t["bottom"]
		draw_polygon(
			PackedVector2Array([Vector2(-400, -400), Vector2(w + 400, -400), Vector2(w + 400, h + 200), Vector2(-400, h + 200)]),
			PackedColorArray([top, top, bottom, bottom])
		)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(theme_name) + int(w)
		match theme_name:
			"coast":
				draw_circle(Vector2(w - 260, 130), 55, Color("#ffe08a"))
				draw_circle(Vector2(w - 260, 130), 70, Color(1, 0.9, 0.55, 0.25))
				_clouds(rng, w, 5)
				# sea along the bottom horizon
				draw_rect(Rect2(-400, h - 190, w + 800, 220), Color("#2e86b8"))
				for i in range(8):
					var x := rng.randf_range(0, w)
					draw_arc(Vector2(x, h - 185 + rng.randf_range(0, 30)), 18, PI, TAU, 10, Color(1, 1, 1, 0.35), 2.5)
			"street":
				_clouds(rng, w, 4)
				_hills(w, h, Color("#a8c8a0"))
			"cliffs":
				_clouds(rng, w, 6)
				draw_rect(Rect2(-400, h - 130, w + 800, 200), Color("#2e86b8"))
			"cave":
				for i in range(int(w / 140.0)):
					var x := i * 140.0 + rng.randf_range(-30, 30)
					var s := rng.randf_range(30, 90)
					var col := Color("#2c3238")
					draw_polygon(
						PackedVector2Array([Vector2(x - s * 0.35, -200), Vector2(x + s * 0.35, -200), Vector2(x, -200 + s + 260)]),
						PackedColorArray([col, col, col])
					)
			"underwater":
				for i in range(6):
					var x := rng.randf_range(0, w)
					var beam_w := rng.randf_range(60, 140)
					draw_polygon(
						PackedVector2Array([
							Vector2(x, -300), Vector2(x + beam_w, -300),
							Vector2(x + beam_w + 200, h), Vector2(x + 200, h),
						]),
						PackedColorArray([
							Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.10),
							Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0),
						])
					)
			"snow":
				_mountains(w, h, Color("#c8d8e8"), Color("#eef4f8"))
				_clouds(rng, w, 3)
			"summit":
				_mountains(w, h, Color("#48608a"), Color("#dce8f2"))
				# aurora
				for i in range(3):
					var y := 60.0 + i * 46.0
					var col: Color = [Color("#68d0c8"), Color("#8a4fb0"), Color("#4ca64c")][i]
					var pts := PackedVector2Array()
					for k in range(24):
						var x := -400 + (w + 800) * k / 23.0
						pts.append(Vector2(x, y + sin(k * 0.7 + i * 2.0) * 26.0))
					draw_polyline(pts, Color(col, 0.28), 26.0)

	func _clouds(rng: RandomNumberGenerator, w: float, n: int) -> void:
		for i in range(n):
			var c := Vector2(rng.randf_range(0, w), rng.randf_range(50, 240))
			var col := Color(1, 1, 1, 0.85)
			draw_circle(c, 32, col)
			draw_circle(c + Vector2(28, 8), 24, col)
			draw_circle(c + Vector2(-30, 10), 22, col)
			draw_circle(c + Vector2(0, 14), 26, col)

	func _hills(w: float, h: float, col: Color) -> void:
		for i in range(int(w / 400.0) + 2):
			var cx := i * 400.0 - 100.0
			draw_circle(Vector2(cx, h - 60), 220, col)

	func _mountains(w: float, h: float, rock: Color, snow: Color) -> void:
		var n := int(w / 500.0) + 2
		for i in range(n):
			var cx := i * 500.0 - 150.0
			var peak := Vector2(cx, h - 520)
			draw_polygon(
				PackedVector2Array([Vector2(cx - 340, h - 60), peak, Vector2(cx + 340, h - 60)]),
				PackedColorArray([rock, rock, rock])
			)
			draw_polygon(
				PackedVector2Array([peak + Vector2(-70, 110), peak, peak + Vector2(70, 110), peak + Vector2(30, 130), peak + Vector2(-25, 125)]),
				PackedColorArray([snow, snow, snow, snow, snow])
			)


class PlatDrawer:
	extends Node2D
	var rect := Rect2()
	var kind := "grass"

	const THEMES := {
		"grass": {"base": Color("#8a6b48"), "top": Color("#4ca64c")},
		"sand": {"base": Color("#d8bc86"), "top": Color("#e8d0a0")},
		"rock": {"base": Color("#6b7278"), "top": Color("#848c92")},
		"wood": {"base": Color("#8a5a2b"), "top": Color("#a8743d")},
		"snow": {"base": Color("#98aabb"), "top": Color("#eef4f8")},
		"ice": {"base": Color("#7ab8d8"), "top": Color("#b8e0f0")},
		"stone": {"base": Color("#5a6068"), "top": Color("#787f88")},
		"cavern": {"base": Color("#3a4046"), "top": Color("#4d555c")},
	}

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		var t: Dictionary = THEMES.get(kind, THEMES["grass"])
		draw_rect(rect, t["base"])
		var lip := minf(12.0, rect.size.y)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, lip)), t["top"])
		if kind == "wood":
			var n := int(rect.size.x / 42.0)
			for i in range(n):
				var x := rect.position.x + (i + 1) * rect.size.x / (n + 1)
				draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), t["base"].darkened(0.25), 2.0)
		elif kind == "ice":
			draw_line(rect.position + Vector2(8, 4), rect.position + Vector2(rect.size.x * 0.4, 4), Color(1, 1, 1, 0.7), 3.0)
		elif kind in ["rock", "stone", "cavern"]:
			var rng := RandomNumberGenerator.new()
			rng.seed = int(rect.size.x) * 31 + int(rect.size.y)
			for i in range(int(rect.size.x * rect.size.y / 4200.0)):
				var pp := rect.position + Vector2(rng.randf() * rect.size.x, lip + rng.randf() * maxf(rect.size.y - lip, 1.0))
				draw_circle(pp, rng.randf_range(2, 5), t["base"].darkened(0.18))
