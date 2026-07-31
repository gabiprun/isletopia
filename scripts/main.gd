extends Node
## Entry point: owns the current screen. Also hosts --smoke and --shot harnesses.

const SCREENS := {
	"title": preload("res://scripts/title_screen.gd"),
	"creator": preload("res://scripts/char_creator.gd"),
	"map": preload("res://scripts/map_screen.gd"),
	"world": preload("res://scripts/world.gd"),
}

var current_screen: Node = null


func _ready() -> void:
	Game.main = self
	var args := OS.get_cmdline_user_args()
	var smoke := "--smoke" in args
	var shot_dir := ""
	for a in args:
		if a.begins_with("--shot="):
			shot_dir = a.trim_prefix("--shot=")
	if smoke:
		Game.smoke_mode = true
		_run_smoke.call_deferred()
	elif shot_dir != "":
		_run_shots.call_deferred(shot_dir)
	else:
		switch_screen("title")


func switch_screen(name_: String, args := {}) -> void:
	if current_screen:
		current_screen.queue_free()
		current_screen = null
	var script: GDScript = SCREENS.get(name_)
	if script == null:
		push_error("Unknown screen: " + name_)
		return
	var node: Node = script.new()
	if "screen_args" in node:
		node.screen_args = args
	current_screen = node
	add_child(node)


# ---------------------------------------------------------------- smoke test

func _fail(msg: String) -> void:
	printerr("SMOKE FAIL: " + msg)
	get_tree().quit(1)


func _check(ok: bool, msg: String) -> bool:
	if not ok:
		_fail(msg)
	return ok


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _world() -> World:
	return current_screen as World


func _drain_dialog() -> void:
	var w := _world()
	var guard := 0
	while w.dialog.active and guard < 200:
		w.dialog.advance()
		await _frames(2)
		guard += 1


func _talk(npc_id: String) -> bool:
	var w := _world()
	if not w.smoke_talk(npc_id):
		_fail("npc not found: %s in %s" % [npc_id, w.room_id])
		return false
	await _frames(2)
	await _drain_dialog()
	await _frames(2)
	return true


func _travel(room: String) -> bool:
	var w := _world()
	if not w.smoke_travel(room):
		_fail("no door to %s from %s" % [room, w.room_id])
		return false
	await _frames(3)
	return true


func _grab(item_id: String) -> bool:
	var w := _world()
	if not w.smoke_grab(item_id):
		_fail("item not found: %s in %s" % [item_id, w.room_id])
		return false
	await _frames(2)
	return true


func _run_smoke() -> void:
	print("SMOKE: start")
	Game.reset_new_game()
	Game.avatar = AvatarRig.random_look()
	Game.player_name = "Test Pilot"

	# sanity: all screens instantiate
	for s in ["title", "creator", "map"]:
		switch_screen(s)
		await _frames(3)
	print("SMOKE: screens ok")

	# ---- Ember Isle ----
	switch_screen("world", {"island": "ember"})
	await _frames(5)
	if not _check(_world() != null and _world().room_id == "dock", "ember should start at dock"):
		return

	# hold-to-walk must never auto-jump, and must keep walking while held
	var w := _world()
	w.player.global_position = Vector2(1400, 620)  # open sand, room to walk
	await _frames(2)
	var start_x: float = w.player.global_position.x
	w.player.begin_hold(w.player.global_position + Vector2(-400, -300))  # held well ABOVE
	var jumped := false
	for i in range(30):
		await get_tree().physics_frame
		if w.player.velocity.y < -200.0:  # upward launch == a jump
			jumped = true
	w.player.end_hold()
	if not _check(not jumped, "hold above player must not jump"):
		return
	if not _check(w.player.global_position.x < start_x - 100.0, "hold should keep walking left"):
		return
	# a deliberate upward tap DOES jump
	w.player.global_position = Vector2(1400, 620)
	await _frames(4)
	w.player.request_jump()
	var launched := false
	for i in range(20):
		await get_tree().physics_frame
		if w.player.velocity.y < -200.0:
			launched = true
	if not _check(launched, "tap-jump should leave the ground"):
		return
	var guard2 := 0
	while not w.player.is_on_floor() and guard2 < 200:
		await get_tree().physics_frame
		guard2 += 1

	# walking into the right edge should auto-travel to the next room
	var dock_size: Vector2 = w.room.get("size", Vector2(2400, 720))
	w.player.global_position.x = dock_size.x - 260.0
	w.player.begin_hold(Vector2(dock_size.x + 600.0, w.player.global_position.y))
	for i in range(120):
		await get_tree().physics_frame
		if w.room_id != "dock":
			break
	w.player.end_hold()
	if not _check(w.room_id == "street", "edge-walk should travel to street, got " + w.room_id):
		return
	# E talks to the nearest NPC (no clicking)
	w.build_room("dock", "default")
	await _frames(3)
	w.player.global_position = Vector2(700, 560)
	await _frames(2)
	w._talk_nearest()
	await _frames(2)
	if not _check(w.dialog.active, "E should open dialog with the nearby NPC"):
		return
	await _drain_dialog()
	await _frames(2)
	await _talk("harbormaster")
	if not _check(Game.flag("met_harbormaster"), "met_harbormaster flag"):
		return

	await _travel("under_dock")
	# regression: swimming into the left wall must NOT trigger the Surface exit
	w.player.global_position = Vector2(220, 500)
	w.player.begin_hold(Vector2(-600, 500))
	for i in range(90):
		await get_tree().physics_frame
		if w.room_id != "under_dock":
			break
	w.player.end_hold()
	if not _check(w.room_id == "under_dock", "swimming left must not surface, got " + w.room_id):
		return
	await _grab("starfish")
	await _travel("dock")
	await _travel("street")
	await _talk("villager")
	await _travel("cliffs")
	await _grab("shard_cliff")
	await _travel("cave")
	if not _check(_world().room.get("dark", false), "cave should be dark"):
		return
	await _grab("shard_cave")
	await _travel("cliffs")
	await _travel("lighthouse")
	await _talk("finn")
	if not _check(Game.has_item("lantern"), "finn gives lantern"):
		return
	# shop trade
	await _travel("cliffs")
	await _travel("street")
	await _talk("shopkeeper")
	if not _check(Game.has_item("shard_shop"), "shop trade gives shard"):
		return
	if not _check(not Game.has_item("starfish"), "starfish consumed"):
		return
	# finish
	await _travel("cliffs")
	await _travel("lighthouse")
	await _talk("finn")
	if not _check(Game.flag("ember_complete"), "ember_complete flag"):
		return
	if not _check(Game.has_medallion("ember"), "ember medallion"):
		return
	print("SMOKE: ember complete")

	# ---- Frost Peak ----
	switch_screen("world", {"island": "frost"})
	await _frames(5)
	await _talk("elder")
	if not _check(Game.flag("met_elder"), "met_elder flag"):
		return
	await _travel("slopes")
	await _grab("yarn")
	await _travel("summit")
	await _talk("yeti")
	if not _check(Game.flag("met_yeti"), "met_yeti flag"):
		return
	await _travel("slopes")
	await _travel("village")
	await _talk("knitter")
	if not _check(Game.has_item("warm_hat"), "knitter makes hat"):
		return
	await _travel("slopes")
	await _travel("summit")
	await _talk("yeti")
	if not _check(Game.has_item("festival_bell"), "yeti gives bell"):
		return
	await _travel("slopes")
	await _travel("village")
	await _talk("elder")
	if not _check(Game.flag("frost_complete"), "frost_complete flag"):
		return
	if not _check(Game.has_medallion("frost"), "frost medallion"):
		return
	print("SMOKE: frost complete")

	# ---- save/load roundtrip ----
	Game.save()
	var flags_before := Game.flags.duplicate()
	var meds_before := Game.medallions.duplicate()
	Game.reset_new_game()
	if not _check(Game.load_save(), "save loads back"):
		return
	if not _check(Game.medallions == meds_before, "medallions roundtrip"):
		return
	for k in flags_before:
		if not _check(Game.flags.get(k) == flags_before[k], "flag roundtrip: " + str(k)):
			return
	print("SMOKE OK")
	get_tree().quit(0)


# ---------------------------------------------------------------- screenshots

func _pose_sheet(dir: String) -> void:
	## Renders the rig in every animation state so the faces can be eyeballed.
	var root := Node2D.new()
	var bg := ColorRect.new()
	bg.color = Color("#cdeaf8")
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	current_screen = root
	add_child(root)
	var poses := [
		{"n": "idle", "s": {}},
		{"n": "walk", "s": {"moving": true}},
		{"n": "jump", "s": {"airborne": true, "vy": -600.0}},
		{"n": "fall", "s": {"airborne": true, "vy": 500.0}},
		{"n": "crouch", "s": {"crouching": true}},
		{"n": "swim", "s": {"swimming": true, "moving": true}},
		{"n": "talk", "s": {"talking": true}},
		{"n": "flip", "s": {"moving": true, "facing": -1}},
	]
	var i := 0
	for p in poses:
		var rig := AvatarRig.new()
		rig.apply_config({"skin": 1, "hair_style": 2, "hair_color": 3, "shirt": 4, "pants": 7})
		rig.position = Vector2(110 + (i % 4) * 300, 260 + int(i / 4) * 330)
		rig.scale = Vector2.ONE * 1.5
		for k in p["s"]:
			rig.set(k, p["s"][k])
		root.add_child(rig)
		var lbl := Label.new()
		lbl.text = str(p["n"])
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color("#22292f"))
		lbl.position = rig.position + Vector2(-40, 20)
		root.add_child(lbl)
		i += 1
	for f in range(30):
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join("poses.png"))
	print("shot: poses")


func _run_shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await _pose_sheet(dir)
	Game.reset_new_game()
	Game.player_name = "Brave Falcon"
	var targets := [
		["title", {}],
		["creator", {}],
		["map", {}],
		["world_ember_dock", {"island": "ember", "room": "dock"}],
		["world_ember_street", {"island": "ember", "room": "street"}],
		["world_ember_under", {"island": "ember", "room": "under_dock"}],
		["world_ember_cave", {"island": "ember", "room": "cave"}],
		["world_ember_lighthouse", {"island": "ember", "room": "lighthouse"}],
		["world_frost_village", {"island": "frost", "room": "village"}],
		["world_frost_slopes", {"island": "frost", "room": "slopes"}],
		["world_frost_summit", {"island": "frost", "room": "summit"}],
	]
	for t in targets:
		var tag: String = t[0]
		var targs: Dictionary = t[1]
		if tag.begins_with("world"):
			switch_screen("world", targs)
		else:
			switch_screen(tag)
		for i in range(40):
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png(dir.path_join(tag + ".png"))
		print("shot: " + tag)
	get_tree().quit(0)
