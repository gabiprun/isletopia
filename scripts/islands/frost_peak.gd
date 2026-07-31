class_name FrostPeakData
## Frost Peak — the yeti borrowed the Festival Bell. 3 rooms, icy platforming.


static func data() -> Dictionary:
	return {
		"id": "frost",
		"name": "Frost Peak",
		"tagline": "The Festival Bell is missing!",
		"color": Color("#7ab8d8"),
		"start_room": "village",
		"hints": [
			{"if": {"flag": "frost_complete"}, "text": "Island complete! Take the blimp to your next adventure."},
			{"if": {"has_item": "festival_bell"}, "text": "Return the Festival Bell to Elder Onna in the village."},
			{"if": {"has_item": "warm_hat"}, "text": "Bring the warm hat to the yeti at the summit."},
			{"if": {"has_item": "yarn"}, "text": "Bring the yarn to Pim the knitter in the village."},
			{"if": {"flag": "met_yeti"}, "text": "The yeti is cold. Find yarn on the slopes — Pim can knit a giant hat."},
			{"if": {"flag": "met_elder"}, "text": "Follow the giant footprints up the slopes to the summit."},
			{"text": "Talk to Elder Onna in the village."},
		],
		"rooms": {
			"village": _village(),
			"slopes": _slopes(),
			"summit": _summit(),
		},
	}


static func _village() -> Dictionary:
	return {
		"size": Vector2(2400, 720),
		"bg": "snow",
		"platforms": [
			{"rect": [0, 620, 2400, 100], "kind": "snow"},
		],
		"props": [
			{"type": "house", "pos": Vector2(450, 620), "w": 270.0, "h": 200.0, "body": Color("#8a6a4a"), "roof": Color("#eef4f8")},
			{"type": "house", "pos": Vector2(1050, 620), "w": 240.0, "h": 180.0, "body": Color("#6a7a8a"), "roof": Color("#eef4f8")},
			{"type": "banner", "pos": Vector2(750, 340), "w": 380.0},
			{"type": "bellstand", "pos": Vector2(1650, 620), "has_bell_flag": "frost_complete"},
			{"type": "snowman", "pos": Vector2(1950, 620)},
			{"type": "tree", "kind": "snowy", "pos": Vector2(2200, 620)},
			{"type": "sign", "pos": Vector2(180, 620), "text": "Frost Hollow"},
			{"type": "lamppost", "pos": Vector2(1350, 620)},
		],
		"npcs": [
			{
				"id": "elder", "name": "Elder Onna", "pos": Vector2(1550, 620),
				"look": {"skin": Color("#f1c27d"), "hair_style": 3, "hair_color": Color("#e6e2d3"), "shirt": Color("#8a4fb0"), "pants": Color("#444a54")},
				"dialog": [
					{"if": {"flag": "frost_complete"}, "lines": [
						"The bell sings again, and the festival is saved!",
						"You'll always have a warm hearth in Frost Hollow, friend.",
					]},
					{"if": {"has_item": "festival_bell"}, "lines": [
						"The bell! Oh, you wonderful explorer!",
						"Help me hang it back up... perfect. Let the Frost Festival begin!",
					], "actions": [
						{"take_item": "festival_bell"}, {"set_flag": "frost_complete"}, {"medallion": "frost"},
					]},
					{"if": {"not_flag": "met_elder"}, "lines": [
						"Disaster, traveler! The great Festival Bell vanished in the night.",
						"Without it there is no Frost Festival — and the festival keeps our spirits through the long dark.",
						"There were huge footprints in the snow... leading up the slopes.",
					], "actions": [{"set_flag": "met_elder"}]},
					{"lines": ["The footprints led up the slopes, toward the summit. Bundle up — the wind bites."]},
				],
			},
			{
				"id": "knitter", "name": "Pim", "pos": Vector2(850, 620),
				"look": {"skin": Color("#ffdbac"), "hair_style": 5, "hair_color": Color("#d8a12c"), "shirt": Color("#d9483b"), "pants": Color("#7a5230")},
				"face_left": true,
				"dialog": [
					{"if": {"flag": "hat_given"}, "lines": ["How's the big fellow liking his hat? I do my best work in giant sizes."]},
					{"if": {"has_item": "yarn"}, "lines": [
						"Ooh, perfect mountain-goat yarn! Give me a moment...",
						"Knit one, purl two, knit one, purl two...",
						"There! A hat big enough for a giant. Extra fluffy.",
					], "actions": [{"take_item": "yarn"}, {"give_item": "warm_hat"}, {"set_flag": "hat_made"}]},
					{"if": {"flag": "met_yeti"}, "lines": [
						"A freezing yeti? The poor dear! No wonder he wanted the bell — it reminds him of warm days.",
						"Bring me yarn and I'll knit the biggest, warmest hat this mountain has ever seen.",
						"I saw a ball of yarn snagged on a tree up the slopes, blown from my basket last storm.",
					]},
					{"lines": ["I knit the warmest hats on the mountain! If you ever need one, bring me good yarn."]},
				],
			},
		],
		"items": [],
		"doors": [
			{"exit_island": true, "label": "Blimp", "pos": Vector2(90, 620), "dir": Vector2.UP},
			{"to": "slopes", "spawn": "from_village", "label": "Slopes", "pos": Vector2(2330, 620), "dir": Vector2.RIGHT},
		],
		"spawns": {
			"default": Vector2(280, 620),
			"from_slopes": Vector2(2240, 620),
		},
	}


static func _slopes() -> Dictionary:
	return {
		"size": Vector2(2600, 900),
		"bg": "snow",
		"platforms": [
			{"rect": [0, 800, 2600, 100], "kind": "snow"},
			{"rect": [400, 690, 240, 24], "kind": "ice", "one_way": true},
			{"rect": [750, 580, 220, 24], "kind": "ice", "one_way": true},
			{"rect": [1100, 470, 220, 24], "kind": "ice", "one_way": true},
			{"rect": [1480, 380, 260, 24], "kind": "ice", "one_way": true},
		],
		"props": [
			{"type": "tree", "kind": "snowy", "pos": Vector2(1600, 380), "s": 0.7},
			{"type": "tree", "kind": "snowy", "pos": Vector2(900, 800)},
			{"type": "tree", "kind": "snowy", "pos": Vector2(2100, 800), "s": 1.2},
			{"type": "rock", "pos": Vector2(1300, 800), "s": 50.0, "color": Color("#98aabb")},
			{"type": "sign", "pos": Vector2(200, 800), "text": "Slippery Slopes"},
			{"type": "snowman", "pos": Vector2(500, 800)},
		],
		"npcs": [],
		"items": [
			{"id": "yarn", "pos": Vector2(1620, 320)},
		],
		"doors": [
			{"to": "village", "spawn": "from_slopes", "label": "Village", "pos": Vector2(80, 800), "dir": Vector2.LEFT},
			{"to": "summit", "spawn": "default", "label": "Summit", "pos": Vector2(2520, 800), "dir": Vector2.RIGHT},
		],
		"spawns": {
			"default": Vector2(160, 800),
			"from_village": Vector2(160, 800),
			"from_summit": Vector2(2430, 800),
		},
	}


static func _summit() -> Dictionary:
	return {
		"size": Vector2(1800, 800),
		"bg": "summit",
		"platforms": [
			{"rect": [0, 700, 1800, 100], "kind": "snow"},
		],
		"props": [
			{"type": "rock", "pos": Vector2(1000, 700), "s": 70.0, "color": Color("#5a6a80")},
			{"type": "rock", "pos": Vector2(1600, 700), "s": 90.0, "color": Color("#485870")},
			{"type": "rock", "pos": Vector2(1700, 700), "s": 60.0, "color": Color("#5a6a80")},
			{"type": "crystal", "pos": Vector2(700, 700), "s": 44.0},
			{"type": "crystal", "pos": Vector2(1150, 700), "s": 30.0, "color": Color("#b8a0f0")},
			{"type": "sign", "pos": Vector2(250, 700), "text": "The Summit"},
		],
		"npcs": [
			{
				"id": "yeti", "name": "Grumble", "pos": Vector2(1350, 700), "scale": 1.9,
				"look": {"skin": Color("#dfe8f0"), "hair_style": 5, "hair_color": Color("#eef4f8"), "shirt": Color("#c8d4e0"), "pants": Color("#a8b8c8"), "shaggy": true},
				"face_left": true,
				"dialog": [
					{"if": {"flag": "frost_complete"}, "lines": [
						"Grumble warm. Grumble happy.",
						"Friend visit Grumble anytime. Bring cocoa.",
					]},
					{"if": {"has_item": "warm_hat"}, "lines": [
						"For... Grumble? *sniff* Nobody ever make Grumble a thing before.",
						"So WARM! Head was coldest part!",
						"Here — take shiny bell back to little village. Grumble only borrowed.",
						"Bell song is warm... but hat is warmer.",
					], "actions": [
						{"take_item": "warm_hat"}, {"give_item": "festival_bell"},
						{"set_flag": "hat_given"}, {"set_flag": "met_yeti"},
					]},
					{"if": {"not_flag": "met_yeti"}, "lines": [
						"GRRRAAAH! ...no, wait. Come back. Grumble not scary. Grumble COLD.",
						"Wind on summit bites through fur. Bell was singing in village — song felt warm.",
						"So Grumble borrowed bell. Bell stays until Grumble warm.",
					], "actions": [{"set_flag": "met_yeti"}]},
					{"lines": ["Grumble cold. Bell stays until Grumble warm. Brrr."]},
				],
			},
		],
		"items": [],
		"doors": [
			{"to": "slopes", "spawn": "from_summit", "label": "Slopes", "pos": Vector2(80, 700), "dir": Vector2.LEFT},
		],
		"spawns": {"default": Vector2(160, 700)},
	}
