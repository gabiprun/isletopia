extends Node
## Autoload "Game" — profiles, per-profile progress, item registry, sfx, routing.
##
## Accounts are device-local: every explorer on this device gets their own
## profile with isolated progress and an optional PIN. There is no server, so
## progress does not follow you to another device.

signal inventory_changed
signal flags_changed

const PROFILES_PATH := "user://isletopia_profiles.json"
const LEGACY_SAVE := "user://isletopia_save.json"
const MAX_PROFILES := 8

const ITEMS := {
	# Ember Isle
	"lantern": {"name": "Lantern", "desc": "Keeper Finn's old lantern. Lights up dark places.", "icon": "lantern"},
	"starfish": {"name": "Starfish", "desc": "A bright orange starfish from under the dock.", "icon": "starfish"},
	"shard_cliff": {"name": "Lens Shard", "desc": "A piece of the lighthouse lens, found on the cliffs.", "icon": "shard"},
	"shard_cave": {"name": "Lens Shard", "desc": "A piece of the lighthouse lens, found deep in the cave.", "icon": "shard"},
	"shard_shop": {"name": "Lens Shard", "desc": "A piece of the lighthouse lens, traded at the shop.", "icon": "shard"},
	# Frost Peak
	"yarn": {"name": "Ball of Yarn", "desc": "Soft mountain-goat yarn, snagged on a tree.", "icon": "yarn"},
	"warm_hat": {"name": "Warm Hat", "desc": "A hand-knitted hat. Extremely cozy.", "icon": "hat"},
	"festival_bell": {"name": "Festival Bell", "desc": "The great bell of the Frost Festival.", "icon": "bell"},
	# Harbor Flats
	"wet_crate": {"name": "Soggy Crate", "desc": "Fished out of the harbor. Smells like seaweed.", "icon": "crate"},
	"coins": {"name": "Handful of Coins", "desc": "Honest pay from Gus for honest diving.", "icon": "coins"},
	"soggy_pack": {"name": "Ruined Pack", "desc": "Nathan's lost pack. A seagull got to it first.", "icon": "pack"},
	"lucky_ticket": {"name": "Lottery Ticket", "desc": "Damp, but the numbers are still readable.", "icon": "ticket"},
	"smokes": {"name": "Pack of Smokes", "desc": "What Nathan asked for. Rosie carded you twice.", "icon": "pack"},
	"gum": {"name": "Pack of Gum", "desc": "Tam swears it worked for his brother.", "icon": "gum"},
}

var main: Node = null

# --- live state for the signed-in profile ---
var profile_id := ""
var player_name := "Traveler"
var avatar := default_avatar()
var flags := {}
var inventory := []
var medallions := []
var current_island := ""
var current_room := ""
var smoke_mode := false

var _profiles := {}  # id -> {name, avatar, pin, progress}
var _sfx_cache := {}
var _sfx_players := []


func _ready() -> void:
	randomize()
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)
	load_profiles()


static func default_avatar() -> Dictionary:
	return {"skin": 1, "hair_style": 2, "hair_color": 2, "shirt": 4, "pants": 7}


func goto_screen(screen: String, args := {}) -> void:
	if main:
		main.switch_screen(screen, args)


# ---------------- profiles ----------------

func load_profiles() -> void:
	_profiles = {}
	if FileAccess.file_exists(PROFILES_PATH):
		var f := FileAccess.open(PROFILES_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				var raw = parsed.get("profiles", {})
				if typeof(raw) == TYPE_DICTIONARY:
					_profiles = raw
	if _profiles.is_empty():
		_import_legacy_save()


func _import_legacy_save() -> void:
	## Carry a pre-accounts save into a first profile so nobody loses progress.
	if not FileAccess.file_exists(LEGACY_SAVE):
		return
	var f := FileAccess.open(LEGACY_SAVE, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var id := _new_id()
	_profiles[id] = {
		"name": parsed.get("player_name", "Explorer"),
		"avatar": parsed.get("avatar", default_avatar()),
		"pin": "",
		"progress": {
			"flags": parsed.get("flags", {}),
			"inventory": parsed.get("inventory", []),
			"medallions": parsed.get("medallions", []),
			"current_island": parsed.get("current_island", ""),
			"current_room": parsed.get("current_room", ""),
		},
	}
	_save_profiles_file()


func _new_id() -> String:
	var n := 1
	while _profiles.has("p%d" % n):
		n += 1
	return "p%d" % n


func profile_list() -> Array:
	## [{id, name, avatar, has_pin, medallions, island}] sorted by id
	var out := []
	var ids := _profiles.keys()
	ids.sort()
	for id in ids:
		var p: Dictionary = _profiles[id]
		var prog: Dictionary = p.get("progress", {})
		out.append({
			"id": id,
			"name": p.get("name", "Explorer"),
			"avatar": p.get("avatar", default_avatar()),
			"has_pin": str(p.get("pin", "")) != "",
			"medallions": (prog.get("medallions", []) as Array).size(),
			"island": prog.get("current_island", ""),
		})
	return out


func profile_count() -> int:
	return _profiles.size()


func can_add_profile() -> bool:
	return _profiles.size() < MAX_PROFILES


static func hash_pin(pin: String) -> String:
	if pin.strip_edges() == "":
		return ""
	return ("isletopia:" + pin.strip_edges()).sha256_text()


func check_pin(id: String, pin: String) -> bool:
	if not _profiles.has(id):
		return false
	var stored := str(_profiles[id].get("pin", ""))
	if stored == "":
		return true
	return stored == hash_pin(pin)


func create_profile(name_: String, avatar_cfg: Dictionary, pin := "") -> String:
	if not can_add_profile():
		return ""
	var id := _new_id()
	_profiles[id] = {
		"name": name_,
		"avatar": avatar_cfg.duplicate(),
		"pin": hash_pin(pin),
		"progress": {
			"flags": {}, "inventory": [], "medallions": [],
			"current_island": "", "current_room": "",
		},
	}
	_save_profiles_file()
	select_profile(id)
	return id


func delete_profile(id: String) -> void:
	if not _profiles.has(id):
		return
	_profiles.erase(id)
	if profile_id == id:
		profile_id = ""
		_reset_live_state()
	_save_profiles_file()


func select_profile(id: String) -> bool:
	if not _profiles.has(id):
		return false
	profile_id = id
	var p: Dictionary = _profiles[id]
	player_name = p.get("name", "Explorer")
	avatar = default_avatar()
	var av = p.get("avatar", {})
	for k in avatar.keys():
		avatar[k] = int(av.get(k, avatar[k]))
	var prog: Dictionary = p.get("progress", {})
	flags = (prog.get("flags", {}) as Dictionary).duplicate()
	inventory = (prog.get("inventory", []) as Array).duplicate()
	medallions = (prog.get("medallions", []) as Array).duplicate()
	current_island = prog.get("current_island", "")
	current_room = prog.get("current_room", "")
	return true


func _reset_live_state() -> void:
	player_name = "Traveler"
	avatar = default_avatar()
	flags = {}
	inventory = []
	medallions = []
	current_island = ""
	current_room = ""


func has_profile() -> bool:
	return profile_id != "" and _profiles.has(profile_id)


func can_resume() -> bool:
	return has_profile() and current_island != ""


# ---------------- state ----------------

func flag(id: String) -> bool:
	return flags.get(id, false)


func set_flag(id: String, value := true) -> void:
	flags[id] = value
	flags_changed.emit()
	save()


func has_item(id: String) -> bool:
	return id in inventory


func give_item(id: String) -> void:
	if not has_item(id):
		inventory.append(id)
		inventory_changed.emit()
	save()


func take_item(id: String) -> void:
	inventory.erase(id)
	inventory_changed.emit()
	save()


func has_medallion(island_id: String) -> bool:
	return island_id in medallions


func award_medallion(island_id: String) -> void:
	if not has_medallion(island_id):
		medallions.append(island_id)
	save()


func reset_new_game() -> void:
	## Used by the smoke harness and by starting a fresh profile in memory.
	_reset_live_state()


# ---------------- save ----------------

func save() -> void:
	if not has_profile():
		return
	_profiles[profile_id]["name"] = player_name
	_profiles[profile_id]["avatar"] = avatar.duplicate()
	_profiles[profile_id]["progress"] = {
		"flags": flags,
		"inventory": inventory,
		"medallions": medallions,
		"current_island": current_island,
		"current_room": current_room,
	}
	_save_profiles_file()


func _save_profiles_file() -> void:
	var f := FileAccess.open(PROFILES_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version": 2, "profiles": _profiles}))
		f.close()


# ---------------- sfx ----------------

func sfx(name: String) -> void:
	if smoke_mode:
		return
	var stream = _sfx_cache.get(name)
	if stream == null:
		var path := "res://assets/sfx/%s.wav" % name
		if ResourceLoader.exists(path):
			stream = load(path)
		_sfx_cache[name] = stream if stream else false
	if not stream:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
