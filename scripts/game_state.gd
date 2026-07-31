extends Node
## Autoload "Game" — global state, save/load, item registry, sfx, screen routing.

signal inventory_changed
signal flags_changed

const SAVE_PATH := "user://isletopia_save.json"

const ITEMS := {
	"lantern": {"name": "Lantern", "desc": "Keeper Finn's old lantern. Lights up dark places.", "icon": "lantern"},
	"starfish": {"name": "Starfish", "desc": "A bright orange starfish from under the dock.", "icon": "starfish"},
	"shard_cliff": {"name": "Lens Shard", "desc": "A piece of the lighthouse lens, found on the cliffs.", "icon": "shard"},
	"shard_cave": {"name": "Lens Shard", "desc": "A piece of the lighthouse lens, found deep in the cave.", "icon": "shard"},
	"shard_shop": {"name": "Lens Shard", "desc": "A piece of the lighthouse lens, traded at the shop.", "icon": "shard"},
	"yarn": {"name": "Ball of Yarn", "desc": "Soft mountain-goat yarn, snagged on a tree.", "icon": "yarn"},
	"warm_hat": {"name": "Warm Hat", "desc": "A hand-knitted hat. Extremely cozy.", "icon": "hat"},
	"festival_bell": {"name": "Festival Bell", "desc": "The great bell of the Frost Festival.", "icon": "bell"},
}

var main: Node = null

var player_name := "Traveler"
var avatar := default_avatar()
var flags := {}
var inventory := []
var medallions := []
var current_island := ""
var current_room := ""
var smoke_mode := false

var _sfx_cache := {}
var _sfx_players := []


func _ready() -> void:
	randomize()
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)


static func default_avatar() -> Dictionary:
	return {"skin": 1, "hair_style": 2, "hair_color": 2, "shirt": 4, "pants": 7}


func goto_screen(screen: String, args := {}) -> void:
	if main:
		main.switch_screen(screen, args)


# ---------- state ----------

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
	player_name = "Traveler"
	avatar = default_avatar()
	flags = {}
	inventory = []
	medallions = []
	current_island = ""
	current_room = ""


# ---------- save / load ----------

func save() -> void:
	var data := {
		"player_name": player_name,
		"avatar": avatar,
		"flags": flags,
		"inventory": inventory,
		"medallions": medallions,
		"current_island": current_island,
		"current_room": current_room,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_save() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	player_name = parsed.get("player_name", "Traveler")
	var av = parsed.get("avatar", default_avatar())
	avatar = default_avatar()
	for k in avatar.keys():
		avatar[k] = int(av.get(k, avatar[k]))
	flags = parsed.get("flags", {})
	inventory = parsed.get("inventory", [])
	medallions = parsed.get("medallions", [])
	current_island = parsed.get("current_island", "")
	current_room = parsed.get("current_room", "")
	return true


# ---------- sfx ----------

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
