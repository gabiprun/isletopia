class_name IslandRegistry
## Static lookup of island definitions.

const EmberIsle = preload("res://scripts/islands/ember_isle.gd")
const FrostPeak = preload("res://scripts/islands/frost_peak.gd")

static var _cache := {}


static func list_islands() -> Array:
	return ["ember", "frost"]


static func has_island(id: String) -> bool:
	return id in list_islands()


static func get_island(id: String) -> Dictionary:
	if not _cache.has(id):
		match id:
			"ember":
				_cache[id] = EmberIsle.data()
			"frost":
				_cache[id] = FrostPeak.data()
			_:
				_cache[id] = EmberIsle.data()
	return _cache[id]
