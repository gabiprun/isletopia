extends Node
## Entry point: owns the current screen. Also hosts --smoke and --shot harnesses.

const SCREENS := {
	"title": preload("res://scripts/title_screen.gd"),
	"creator": preload("res://scripts/char_creator.gd"),
	"profiles": preload("res://scripts/profile_screen.gd"),
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


func _drain_dialog(choice := -1) -> void:
	## Advances to the end. If the entry offers choices, picks `choice`
	## (defaults to the last option, which is always the "decline" branch).
	var w := _world()
	var guard := 0
	while w.dialog.active and guard < 200:
		if w.dialog.has_choices():
			var pick := choice if choice >= 0 else w.dialog._choices.size() - 1
			w.dialog.choose(pick)
		else:
			w.dialog.advance()
		await _frames(2)
		guard += 1


func _talk(npc_id: String, choice := -1) -> bool:
	var w := _world()
	if not w.smoke_talk(npc_id):
		_fail("npc not found: %s in %s" % [npc_id, w.room_id])
		return false
	await _frames(2)
	await _drain_dialog(choice)
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


func _test_profiles() -> void:
	## Accounts must keep each explorer's progress fully separate.
	for p in Game.profile_list():
		Game.delete_profile(p["id"])
	if not _check(Game.profile_count() == 0, "profiles start empty"):
		return

	var a := Game.create_profile("Ada", AvatarRig.random_look(), "1234")
	if not _check(a != "" and Game.profile_id == a, "create profile A"):
		return
	Game.set_flag("test_a")
	Game.give_item("lantern")
	Game.award_medallion("ember")

	var b := Game.create_profile("Bo", AvatarRig.random_look(), "")
	if not _check(b != "" and b != a, "create profile B with a distinct id"):
		return
	if not _check(not Game.flag("test_a"), "B must not inherit A's flags"):
		return
	if not _check(not Game.has_item("lantern"), "B must not inherit A's items"):
		return
	if not _check(Game.medallions.is_empty(), "B must not inherit A's medallions"):
		return
	Game.set_flag("test_b")

	# switching back restores A exactly
	if not _check(Game.select_profile(a), "select A again"):
		return
	if not _check(Game.flag("test_a") and not Game.flag("test_b"), "A's flags survive a switch"):
		return
	if not _check(Game.has_item("lantern"), "A's items survive a switch"):
		return
	if not _check(Game.has_medallion("ember"), "A's medallion survives a switch"):
		return
	if not _check(Game.player_name == "Ada", "A's name survives a switch"):
		return

	# PINs
	if not _check(Game.check_pin(a, "1234"), "correct PIN opens A"):
		return
	if not _check(not Game.check_pin(a, "9999"), "wrong PIN is rejected"):
		return
	if not _check(Game.check_pin(b, "anything"), "a profile with no PIN always opens"):
		return

	# a PIN must not be recoverable from the saved file
	var pf := FileAccess.open(Game.PROFILES_PATH, FileAccess.READ)
	var raw := pf.get_as_text() if pf else ""
	if pf:
		pf.close()
	if not _check(not raw.contains("1234"), "PIN is not stored in the clear"):
		return

	# reload from disk: profiles must round-trip
	Game.load_profiles()
	if not _check(Game.profile_count() == 2, "both profiles reload from disk"):
		return
	if not _check(Game.select_profile(a) and Game.has_medallion("ember"), "progress reloads from disk"):
		return

	# delete only removes the one
	Game.delete_profile(b)
	if not _check(Game.profile_count() == 1, "delete removes exactly one profile"):
		return
	for p2 in Game.profile_list():
		Game.delete_profile(p2["id"])
	print("SMOKE: profiles ok")


func _run_smoke() -> void:
	print("SMOKE: start")
	Game.reset_new_game()
	Game.avatar = AvatarRig.random_look()
	Game.player_name = "Test Pilot"

	# ---- profiles / accounts ----
	await _test_profiles()

	# sanity: all screens instantiate
	for s in ["title", "creator", "map", "profiles"]:
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

	# ---- every rooftop must be climbable: ground -> ledge -> roof ----
	var max_jump: float = (Player.JUMP_VEL * Player.JUMP_VEL) / (2.0 * Player.GRAVITY)
	var reach := max_jump - 18.0  # leave room for the body/landing
	for island_id in IslandRegistry.list_islands():
		var isl := IslandRegistry.get_island(island_id)
		for rname in isl["rooms"]:
			for pdef in isl["rooms"][rname].get("props", []):
				if pdef.get("type", "") != "house":
					continue
				var pr := Prop.new()
				pr.setup(pdef)
				var ledge: float = absf(pr.ledge_y())
				var roof: float = absf(pr.roof_top_y())
				pr.free()
				if not _check(ledge <= reach,
						"%s/%s house ledge unreachable (%.0f > %.0f)" % [island_id, rname, ledge, reach]):
					return
				if not _check(roof - ledge <= reach,
						"%s/%s roof unreachable from ledge (%.0f > %.0f)" % [island_id, rname, roof - ledge, reach]):
					return
	print("SMOKE: rooftops reachable")

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

	var flags_snapshot := Game.flags.duplicate()
	var meds_snapshot := Game.medallions.duplicate()

	# ---- Harbor Flats (both endings) ----
	for ending in ["smokes", "gum"]:
		Game.reset_new_game()
		switch_screen("world", {"island": "harbor"})
		await _frames(5)
		var hw := _world()
		if not _check(hw.room_id == "porch", "harbor starts on the porch"):
			return
		await _talk("nathan")
		if not _check(Game.flag("met_nathan"), "met_nathan flag"):
			return
		await _travel("main")
		await _talk("rosie")
		if not _check(not Game.has_item("smokes"), "Rosie must not sell without money or stock"):
			return
		# earn the money: dive for Gus's crate
		await _travel("docks")
		await _talk("gus")
		await _travel("harbor")
		await _grab("wet_crate")
		await _travel("docks")
		await _talk("gus")
		if not _check(Game.has_item("coins"), "Gus pays for the crate"):
			return
		if not _check(Game.flag("crate_delivered"), "crate_delivered flag"):
			return
		# rooftop side-quest via the alley
		await _travel("main")
		await _travel("alley")
		await _talk("tam")
		await _travel("rooftops")
		await _grab("soggy_pack")
		await _grab("lucky_ticket")
		await _travel("alley")

		if ending == "smokes":
			await _travel("main")
			await _talk("rosie")
			if not _check(Game.has_item("smokes"), "Rosie sells once paid and restocked"):
				return
			if not _check(not Game.has_item("coins"), "coins are spent"):
				return
			await _travel("porch")
		else:
			await _talk("tam", 0)  # pick "Buy the gum"
			if not _check(Game.has_item("gum"), "Tam trades gum for the same coins"):
				return
			if not _check(not Game.has_item("coins"), "coins are spent on gum"):
				return
			await _travel("main")
			await _travel("porch")

		await _talk("nathan")
		if not _check(Game.flag("harbor_complete"), "harbor_complete via " + ending):
			return
		if not _check(Game.has_medallion("harbor"), "harbor medallion via " + ending):
			return
		var want: String = "ending_" + str(ending)
		if not _check(Game.flag(want), "correct ending flag: " + want):
			return
		print("SMOKE: harbor complete (%s ending)" % ending)

	# ---- save/resume roundtrip through a real profile ----
	var pid := Game.create_profile("Roundtrip", Game.default_avatar(), "")
	Game.flags = flags_snapshot.duplicate()
	Game.medallions = meds_snapshot.duplicate()
	Game.inventory = ["lantern"]
	Game.current_island = "harbor"
	Game.current_room = "main"
	Game.save()

	Game.load_profiles()  # forget everything in memory, reload from disk
	if not _check(Game.select_profile(pid), "profile reloads after save"):
		return
	if not _check(Game.medallions == meds_snapshot, "medallions roundtrip"):
		return
	if not _check(Game.has_item("lantern"), "inventory roundtrip"):
		return
	if not _check(Game.can_resume() and Game.current_room == "main", "resume point roundtrip"):
		return
	for k in flags_snapshot:
		if not _check(Game.flags.get(k) == flags_snapshot[k], "flag roundtrip: " + str(k)):
			return
	Game.delete_profile(pid)
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
		{"n": "roll", "s": {"rolling": true, "moving": true, "spin": 0.9}},
		{"n": "flip a", "s": {"airborne": true, "flipping": true, "vy": -400.0, "spin": 0.0}},
		{"n": "flip b", "s": {"airborne": true, "flipping": true, "vy": 100.0, "spin": PI * 0.6}},
		{"n": "flip c", "s": {"airborne": true, "flipping": true, "vy": 400.0, "spin": PI * 1.2}},
		{"n": "turned", "s": {"moving": true, "facing": -1}},
	]
	var i := 0
	for p in poses:
		var rig := AvatarRig.new()
		rig.apply_config({"skin": 1, "hair_style": 2, "hair_color": 3, "shirt": 4, "pants": 7})
		rig.position = Vector2(100 + (i % 6) * 208, 250 + int(i / 6) * 320)
		rig.scale = Vector2.ONE * 1.15
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
	# a couple of throwaway profiles so the account screen has cards to show
	var demo_ids := []
	if Game.profile_count() == 0:
		var d1 := Game.create_profile("Brave Falcon", {"skin": 1, "hair_style": 2, "hair_color": 3, "shirt": 4, "pants": 7}, "1234")
		Game.award_medallion("ember")
		Game.award_medallion("frost")
		var d2 := Game.create_profile("Sunny Otter", {"skin": 4, "hair_style": 5, "hair_color": 0, "shirt": 8, "pants": 5}, "")
		Game.award_medallion("harbor")
		demo_ids = [d1, d2]

	var targets := [
		["title", {}],
		["profiles", {}],
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
		["world_harbor_porch", {"island": "harbor", "room": "porch"}],
		["world_harbor_main", {"island": "harbor", "room": "main"}],
		["world_harbor_docks", {"island": "harbor", "room": "docks"}],
		["world_harbor_alley", {"island": "harbor", "room": "alley"}],
		["world_harbor_rooftops", {"island": "harbor", "room": "rooftops"}],
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
	for did in demo_ids:
		Game.delete_profile(did)
	get_tree().quit(0)
