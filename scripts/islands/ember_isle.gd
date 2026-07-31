class_name EmberIsleData
## Ember Isle — relight the lighthouse. 6 rooms, 3 lens shards, 1 medallion.


static func data() -> Dictionary:
	return {
		"id": "ember",
		"name": "Ember Isle",
		"tagline": "The lighthouse has gone dark...",
		"color": Color("#3f9b57"),
		"start_room": "dock",
		"hints": [
			{"if": {"flag": "ember_complete"}, "text": "Island complete! Take the blimp to your next adventure."},
			{"if": {"has_all": ["shard_cliff", "shard_cave", "shard_shop"]}, "text": "You have all 3 shards! Return to Keeper Finn."},
			{"if": {"flag": "met_finn"}, "text": "Find the 3 lens shards: the cliffs, the cave, and the market."},
			{"if": {"flag": "met_harbormaster"}, "text": "Visit Keeper Finn at the lighthouse, past Market Street."},
			{"text": "Talk to the harbormaster at the dock."},
		],
		"rooms": {
			"dock": _dock(),
			"under_dock": _under_dock(),
			"street": _street(),
			"cliffs": _cliffs(),
			"cave": _cave(),
			"lighthouse": _lighthouse(),
		},
	}


static func _dock() -> Dictionary:
	return {
		"size": Vector2(2400, 720),
		"bg": "coast",
		"platforms": [
			{"rect": [560, 620, 1840, 100], "kind": "sand"},
			{"rect": [140, 560, 560, 24], "kind": "wood"},
		],
		"props": [
			{"type": "boat", "pos": Vector2(160, 645), "z": -3},
			{"type": "sign", "pos": Vector2(950, 620), "text": "Ember Isle"},
			{"type": "tree", "kind": "palm", "pos": Vector2(1300, 620)},
			{"type": "tree", "kind": "palm", "pos": Vector2(1900, 620), "s": 0.8},
			{"type": "crate", "pos": Vector2(1080, 620)},
			{"type": "crate", "pos": Vector2(1135, 620), "s": 42.0},
		],
		"npcs": [
			{
				"id": "harbormaster", "name": "Harbormaster Bree", "pos": Vector2(640, 560),
				"look": {"skin": Color("#e0ac69"), "hair_style": 6, "hair_color": Color("#2b2b2b"), "shirt": Color("#25537a"), "pants": Color("#444a54")},
				"face_left": true,
				"dialog": [
					{"if": {"flag": "ember_complete"}, "lines": [
						"The light is back! Ships can find home again.",
						"You're a true islander now, friend.",
					]},
					{"if": {"not_flag": "met_harbormaster"}, "lines": [
						"Rough seas, traveler. Three ships nearly wrecked on the rocks this week.",
						"Our lighthouse has gone dark. Keeper Finn tends it, up past Market Street and the cliffs.",
						"Please — go see him. The whole island is counting on that light.",
					], "actions": [{"set_flag": "met_harbormaster"}]},
					{"lines": ["Finn's at the lighthouse — head right through Market Street, then over the cliffs."]},
				],
			},
		],
		"items": [],
		"doors": [
			{"exit_island": true, "label": "Blimp", "pos": Vector2(90, 560), "dir": Vector2.UP},
			{"to": "under_dock", "spawn": "default", "label": "Dive!", "pos": Vector2(340, 560), "dir": Vector2.DOWN},
			{"to": "street", "spawn": "from_dock", "label": "Market Street", "pos": Vector2(2330, 620), "dir": Vector2.RIGHT},
		],
		"spawns": {
			"default": Vector2(760, 620),
			"from_street": Vector2(2240, 620),
			"from_under": Vector2(450, 560),
		},
	}


static func _under_dock() -> Dictionary:
	return {
		"size": Vector2(1600, 900),
		"bg": "underwater",
		"swim": true,
		"platforms": [
			{"rect": [0, 820, 1600, 80], "kind": "rock"},
		],
		"props": [
			{"type": "seaweed", "pos": Vector2(300, 820), "s": 1.2},
			{"type": "seaweed", "pos": Vector2(700, 820)},
			{"type": "seaweed", "pos": Vector2(1250, 820), "s": 1.5},
			{"type": "rock", "pos": Vector2(500, 820), "s": 60.0, "color": Color("#4a6270")},
			{"type": "rock", "pos": Vector2(1450, 820), "s": 45.0, "color": Color("#4a6270")},
			{"type": "chest", "pos": Vector2(950, 820), "open_flag": "picked_starfish"},
		],
		"npcs": [],
		"items": [
			{"id": "starfish", "pos": Vector2(950, 750)},
		],
		"doors": [
			{"to": "dock", "spawn": "from_under", "label": "Surface", "pos": Vector2(300, 160), "dir": Vector2.UP},
		],
		"spawns": {"default": Vector2(300, 260)},
	}


static func _street() -> Dictionary:
	return {
		"size": Vector2(2600, 720),
		"bg": "street",
		"platforms": [
			{"rect": [0, 620, 2600, 100], "kind": "grass"},
		],
		"props": [
			{"type": "house", "pos": Vector2(420, 620), "w": 280.0, "h": 210.0, "body": Color("#e8d9b0"), "roof": Color("#c0504a")},
			{"type": "house", "pos": Vector2(950, 620), "w": 250.0, "h": 190.0, "body": Color("#cfe0d0"), "roof": Color("#25537a")},
			{"type": "house", "pos": Vector2(1550, 620), "w": 300.0, "h": 230.0, "body": Color("#e8cfc0"), "roof": Color("#7a5230")},
			{"type": "banner", "pos": Vector2(1250, 330), "w": 420.0},
			{"type": "lamppost", "pos": Vector2(700, 620)},
			{"type": "lamppost", "pos": Vector2(1800, 620)},
			{"type": "fence", "pos": Vector2(1200, 620), "w": 180.0},
			{"type": "sign", "pos": Vector2(180, 620), "text": "Market St."},
			{"type": "stall", "pos": Vector2(2100, 620)},
		],
		"npcs": [
			{
				"id": "shopkeeper", "name": "Sella", "pos": Vector2(2210, 620),
				"look": {"skin": Color("#c68642"), "hair_style": 4, "hair_color": Color("#c9483a"), "shirt": Color("#4ca64c"), "pants": Color("#7a5230")},
				"face_left": true,
				"dialog": [
					{"if": {"flag": "shop_traded"}, "lines": [
						"That starfish really ties the stall together. Good luck with the light!",
					]},
					{"if": {"has_item": "starfish"}, "lines": [
						"Oh my — a perfect starfish! They bring good luck, you know.",
						"Tell you what: trade you for this shiny glass shard I found on the beach after the storm.",
						"Deal? Deal!",
					], "actions": [{"take_item": "starfish"}, {"give_item": "shard_shop"}, {"set_flag": "shop_traded"}]},
					{"if": {"flag": "met_finn"}, "lines": [
						"A lens shard? Hmm... I did find a big piece of curved glass on the beach.",
						"I'll trade it for a starfish! There are some under the dock — just dive in.",
					]},
					{"lines": ["Welcome to my stall! Finest goods on Ember Isle. Well... only goods on Ember Isle."]},
				],
			},
			{
				"id": "villager", "name": "Maro", "pos": Vector2(1100, 620),
				"look": {"skin": Color("#8d5524"), "hair_style": 2, "hair_color": Color("#2b2b2b"), "shirt": Color("#e070a8"), "pants": Color("#444a54")},
				"dialog": [
					{"if": {"flag": "ember_complete"}, "lines": ["The beam swept past my window last night. Slept like a barnacle."]},
					{"if": {"flag": "met_finn"}, "lines": [
						"Shards, eh? I saw something sparkly up on the cliff ledges yesterday.",
						"And mind the cave — dark as squid ink in there. You'd want a lantern.",
					]},
					{"lines": ["Nice day! Shame about the lighthouse. Ships won't come near while it's dark."]},
				],
			},
		],
		"items": [],
		"doors": [
			{"to": "dock", "spawn": "from_street", "label": "Dock", "pos": Vector2(70, 620), "dir": Vector2.LEFT},
			{"to": "cliffs", "spawn": "from_street", "label": "Cliffs", "pos": Vector2(2530, 620), "dir": Vector2.RIGHT},
		],
		"spawns": {
			"default": Vector2(300, 620),
			"from_dock": Vector2(150, 620),
			"from_cliffs": Vector2(2450, 620),
		},
	}


static func _cliffs() -> Dictionary:
	return {
		"size": Vector2(2400, 900),
		"bg": "cliffs",
		"platforms": [
			{"rect": [0, 800, 2400, 100], "kind": "rock"},
			{"rect": [300, 700, 220, 26], "kind": "rock", "one_way": true},
			{"rect": [640, 590, 200, 26], "kind": "rock", "one_way": true},
			{"rect": [420, 470, 180, 26], "kind": "rock", "one_way": true},
			{"rect": [760, 360, 200, 26], "kind": "rock", "one_way": true},
			{"rect": [1080, 260, 240, 26], "kind": "rock", "one_way": true},
		],
		"props": [
			{"type": "rock", "pos": Vector2(1500, 800), "s": 60.0},
			{"type": "rock", "pos": Vector2(2000, 800), "s": 40.0},
			{"type": "tree", "kind": "bare", "pos": Vector2(1850, 800)},
			{"type": "sign", "pos": Vector2(200, 800), "text": "Windy Cliffs"},
		],
		"npcs": [],
		"items": [
			{"id": "shard_cliff", "pos": Vector2(1200, 200)},
		],
		"doors": [
			{"to": "street", "spawn": "from_cliffs", "label": "Market St.", "pos": Vector2(70, 800), "dir": Vector2.LEFT},
			{"to": "cave", "spawn": "default", "label": "Cave", "pos": Vector2(1600, 800), "dir": Vector2.DOWN},
			{"to": "lighthouse", "spawn": "default", "label": "Lighthouse", "pos": Vector2(2330, 800), "dir": Vector2.RIGHT},
		],
		"spawns": {
			"default": Vector2(150, 800),
			"from_street": Vector2(150, 800),
			"from_cave": Vector2(1680, 800),
			"from_lighthouse": Vector2(2250, 800),
		},
	}


static func _cave() -> Dictionary:
	return {
		"size": Vector2(2200, 900),
		"bg": "cave",
		"dark": true,
		"platforms": [
			{"rect": [0, 820, 2200, 80], "kind": "cavern"},
			{"rect": [500, 700, 240, 26], "kind": "cavern", "one_way": true},
			{"rect": [900, 600, 220, 26], "kind": "cavern", "one_way": true},
			{"rect": [1300, 500, 220, 26], "kind": "cavern", "one_way": true},
			{"rect": [1750, 660, 300, 30], "kind": "stone"},
		],
		"props": [
			{"type": "stalactite", "pos": Vector2(400, -60), "s": 120.0},
			{"type": "stalactite", "pos": Vector2(800, -60), "s": 90.0},
			{"type": "stalactite", "pos": Vector2(1400, -60), "s": 140.0},
			{"type": "crystal", "pos": Vector2(700, 820), "s": 50.0},
			{"type": "crystal", "pos": Vector2(1500, 820), "s": 36.0, "color": Color("#b8a0f0")},
			{"type": "crystal", "pos": Vector2(1980, 660), "s": 30.0},
			{"type": "rock", "pos": Vector2(1150, 820), "s": 55.0, "color": Color("#4a5258")},
		],
		"npcs": [],
		"items": [
			{"id": "shard_cave", "pos": Vector2(1900, 600)},
		],
		"doors": [
			{"to": "cliffs", "spawn": "from_cave", "label": "Cliffs", "pos": Vector2(80, 820), "dir": Vector2.UP},
		],
		"spawns": {"default": Vector2(160, 820)},
	}


static func _lighthouse() -> Dictionary:
	return {
		"size": Vector2(1800, 800),
		"bg": "cliffs",
		"platforms": [
			{"rect": [0, 700, 1800, 100], "kind": "grass"},
		],
		"props": [
			{"type": "lighthouse", "pos": Vector2(1250, 700), "h": 480.0, "lit_flag": "ember_complete"},
			{"type": "beam", "pos": Vector2(1250, 185), "visible_flag": "ember_complete", "z": 2},
			{"type": "fence", "pos": Vector2(600, 700), "w": 260.0},
			{"type": "sign", "pos": Vector2(300, 700), "text": "Old Point Light"},
			{"type": "rock", "pos": Vector2(1650, 700), "s": 45.0},
		],
		"npcs": [
			{
				"id": "finn", "name": "Keeper Finn", "pos": Vector2(1000, 700),
				"look": {"skin": Color("#ffdbac"), "hair_style": 1, "hair_color": Color("#e6e2d3"), "shirt": Color("#e8c930"), "pants": Color("#25537a")},
				"face_left": true,
				"dialog": [
					{"if": {"flag": "ember_complete"}, "lines": [
						"Listen to her hum! Prettiest sound on the island.",
						"Thank you, friend. Ember Isle won't forget you.",
					]},
					{"if": {"has_all": ["shard_cliff", "shard_cave", "shard_shop"]}, "lines": [
						"You found them! All three shards!",
						"Let me fit them back into the lens... a little to the left... there!",
						"Stand back, friend — LET THERE BE LIGHT!",
					], "actions": [
						{"take_item": "shard_cliff"}, {"take_item": "shard_cave"}, {"take_item": "shard_shop"},
						{"set_flag": "ember_complete"}, {"medallion": "ember"},
					]},
					{"if": {"flag": "met_finn"}, "lines": [
						"Any luck? Three shards: one up on the cliff ledges, one deep in the cave,",
						"and Sella at the market found one on the beach. My lantern will help in the dark.",
					]},
					{"lines": [
						"Ah, a visitor! Bree sent you? Good, good.",
						"The great storm shattered my lens — three shards scattered across the island.",
						"One glinted up on the cliffs. One fell into the cave — pitch dark, take my lantern.",
						"And I hear Sella at the market found a piece on the beach. Bring me all three!",
					], "actions": [{"set_flag": "met_finn"}, {"give_item": "lantern"}]},
				],
			},
		],
		"items": [],
		"doors": [
			{"to": "cliffs", "spawn": "from_lighthouse", "label": "Cliffs", "pos": Vector2(70, 700), "dir": Vector2.LEFT},
		],
		"spawns": {"default": Vector2(150, 700)},
	}
