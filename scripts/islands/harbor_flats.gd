class_name HarborFlatsData
## Harbor Flats — Nathan lost his smokes. Six rooms, a job, a dive, a rooftop
## climb, and two ways to finish it.


static func data() -> Dictionary:
	return {
		"id": "harbor",
		"name": "Harbor Flats",
		"tagline": "Nathan lost his smokes...",
		"color": Color("#8a9198"),
		"start_room": "porch",
		"hints": [
			{"if": {"flag": "harbor_complete"}, "text": "Island complete! Take the blimp to your next adventure."},
			{"if": {"has_item": "smokes"}, "text": "Take the pack back to Nathan on his porch."},
			{"if": {"has_item": "gum"}, "text": "Take the gum back to Nathan on his porch."},
			{"if": {"has_item": "coins"}, "text": "You have pay! Rosie sells the pack — or ask Tam in the alley."},
			{"if": {"has_item": "wet_crate"}, "text": "Haul the crate back to Gus on the docks."},
			{"if": {"flag": "met_gus"}, "text": "Gus's crate went in the drink. Dive off the docks and fish it out."},
			{"if": {"flag": "met_rosie"}, "text": "Rosie needs paying and needs stock. Try the docks for work."},
			{"if": {"flag": "met_nathan"}, "text": "Head up the street to Rosie's corner store."},
			{"text": "Talk to Nathan on his porch."},
		],
		"rooms": {
			"porch": _porch(),
			"main": _main(),
			"docks": _docks(),
			"harbor": _harbor(),
			"alley": _alley(),
			"rooftops": _rooftops(),
		},
	}


static func _porch() -> Dictionary:
	return {
		"size": Vector2(2000, 720),
		"bg": "alley",
		"platforms": [
			{"rect": [0, 620, 2000, 100], "kind": "stone"},
		],
		"props": [
			{"type": "house", "pos": Vector2(760, 620), "w": 300.0, "h": 220.0,
				"body": Color("#b9a68c"), "roof": Color("#5f6a72")},
			{"type": "fence", "pos": Vector2(1180, 620), "w": 240.0},
			{"type": "sign", "pos": Vector2(320, 620), "text": "Harbor Flats"},
			{"type": "lamppost", "pos": Vector2(1500, 620)},
			{"type": "crate", "pos": Vector2(1320, 620), "s": 48.0},
		],
		"npcs": [
			{
				"id": "nathan", "name": "Nathan", "pos": Vector2(1000, 620),
				"look": {"skin": Color("#e0ac69"), "hair_style": 1, "hair_color": Color("#5a3825"),
					"shirt": Color("#444a54"), "pants": Color("#25537a")},
				"face_left": true,
				"dialog": [
					{"if": {"flag": "ending_gum"}, "lines": [
						"Day three, and I haven't caved. Chewed through half a pack of that gum though.",
						"You did me a favour, kid. Didn't feel like one at the time.",
					]},
					{"if": {"flag": "ending_smokes"}, "lines": [
						"You're a lifesaver. Genuinely.",
						"Don't tell Rosie I said that, she'll put it on a sign.",
					]},
					# --- endings ---
					{"if": {"has_item": "smokes"}, "lines": [
						"You found some! Ahh, you absolute legend.",
						"Right — that's me sorted. What do I owe you?",
						"Nothing? Get out of here. Take this instead, it's the least I can do.",
					], "actions": [
						{"take_item": "smokes"}, {"set_flag": "ending_smokes"},
						{"set_flag": "harbor_complete"}, {"medallion": "harbor"},
					]},
					{"if": {"has_item": "gum"}, "lines": [
						"...That's gum.",
						"That is definitely gum. I asked for one thing.",
						"*long pause* ...Tam's brother quit with this stuff, didn't he.",
						"Fine. FINE. Give it here. No promises. But — thanks. I think.",
					], "actions": [
						{"take_item": "gum"}, {"set_flag": "ending_gum"},
						{"set_flag": "harbor_complete"}, {"medallion": "harbor"},
					]},
					# --- side beat: the ruined pack ---
					{"if": {"has_item": "soggy_pack"}, "lines": [
						"That's my pack! Where was — oh. Oh no.",
						"It's soaked through. There's a feather in it. Is that a FEATHER?",
						"Bin it. Please. I don't want to know.",
					], "actions": [{"take_item": "soggy_pack"}, {"set_flag": "found_pack"}]},
					{"if": {"has_item": "lucky_ticket"}, "lines": [
						"My ticket! I thought that went in the harbour with everything else.",
						"Hang onto it for me, would you? I'm having a week.",
					]},
					{"if": {"not_flag": "met_nathan"}, "lines": [
						"Morning. Don't suppose you've seen a pack of smokes lying about?",
						"Had them on the wall right here, turned around, gone. Bird took them, I reckon.",
						"Any chance you'd run up to Rosie's corner store for me? Top of the street.",
						"I'd go myself but I've got the boat in bits and the tide waits for nobody.",
						"Ah — one snag. I'm skint until Friday. You'll have to sort the money out yourself.",
					], "actions": [{"set_flag": "met_nathan"}]},
					{"lines": [
						"Rosie's is up the street. Gus down on the docks always needs a hand if you're short.",
					]},
				],
			},
		],
		"items": [],
		"doors": [
			{"exit_island": true, "label": "Blimp", "pos": Vector2(110, 620), "dir": Vector2.UP},
			{"to": "main", "spawn": "from_porch", "label": "Main Street", "pos": Vector2(1930, 620), "dir": Vector2.RIGHT},
		],
		"spawns": {
			"default": Vector2(400, 620),
			"from_main": Vector2(1840, 620),
		},
	}


static func _main() -> Dictionary:
	return {
		"size": Vector2(2600, 720),
		"bg": "street",
		"platforms": [
			{"rect": [0, 620, 2600, 100], "kind": "stone"},
		],
		"props": [
			{"type": "house", "pos": Vector2(760, 620), "w": 300.0, "h": 215.0,
				"body": Color("#e2d3b4"), "roof": Color("#2f6b8a")},
			{"type": "awning", "pos": Vector2(760, 434), "w": 288.0},
			{"type": "sign", "pos": Vector2(1010, 620), "text": "ROSIE'S"},
			{"type": "house", "pos": Vector2(1700, 620), "w": 280.0, "h": 200.0,
				"body": Color("#cbb9a4"), "roof": Color("#8a4a44")},
			{"type": "lamppost", "pos": Vector2(1280, 620)},
			{"type": "banner", "pos": Vector2(1400, 330), "w": 360.0},
			{"type": "fence", "pos": Vector2(2150, 620), "w": 200.0},
			{"type": "crate", "pos": Vector2(2320, 620), "s": 52.0},
		],
		"npcs": [
			{
				"id": "rosie", "name": "Rosie", "pos": Vector2(600, 620),
				"look": {"skin": Color("#8d5524"), "hair_style": 6, "hair_color": Color("#e6e2d3"),
					"shirt": Color("#4ca64c"), "pants": Color("#444a54")},
				"dialog": [
					{"if": {"flag": "harbor_complete"}, "lines": [
						"Heard you sorted Nathan out. He's been in twice since, just to chat.",
						"Don't tell him I said this, but the street's nicer with him in it.",
					]},
					{"if": {"flag": "bought_smokes"}, "lines": [
						"Off you go then. And tell Nathan he still owes me for a paper from March.",
					]},
					# the actual sale
					{"if": {"has_item": "coins", "flag": "crate_delivered"}, "lines": [
						"Coins in hand and my shelves full — well, look at you.",
						"One pack. That's the lot of your pay, mind.",
						"*slides it across the counter* Tell Nathan I said he should pack it in.",
					], "actions": [
						{"take_item": "coins"}, {"give_item": "smokes"}, {"set_flag": "bought_smokes"},
					]},
					{"if": {"flag": "crate_delivered"}, "lines": [
						"Gus's crate came through — shelves are full again.",
						"Still going to cost you, though. Come back when you've got coin.",
					]},
					{"if": {"has_item": "coins"}, "lines": [
						"You've got the money, I'll give you that. What I haven't got is stock.",
						"My delivery's sat down on the docks. Gus dropped half of it in the water.",
					]},
					{"if": {"not_flag": "met_rosie"}, "lines": [
						"Morning. Let me guess — Nathan sent you.",
						"He's been sending someone up here twice a week since I opened.",
						"Two problems, love. One: that costs money, and you've none on you.",
						"Two: my delivery never turned up. Gus has it down on the docks.",
						"Sort both of those and we'll talk.",
					], "actions": [{"set_flag": "met_rosie"}]},
					{"lines": ["Money and stock. Neither of them are going to walk in here by themselves."]},
				],
			},
		],
		"items": [],
		"doors": [
			{"to": "porch", "spawn": "from_main", "label": "Nathan's", "pos": Vector2(80, 620), "dir": Vector2.LEFT},
			{"to": "docks", "spawn": "from_main", "label": "Docks", "pos": Vector2(2530, 620), "dir": Vector2.RIGHT},
			{"to": "alley", "spawn": "default", "label": "Back Alley", "pos": Vector2(1450, 620), "dir": Vector2.DOWN},
		],
		"spawns": {
			"default": Vector2(200, 620),
			"from_porch": Vector2(150, 620),
			"from_docks": Vector2(2450, 620),
			"from_alley": Vector2(1450, 620),
		},
	}


static func _docks() -> Dictionary:
	return {
		"size": Vector2(2400, 720),
		"bg": "coast",
		"platforms": [
			{"rect": [0, 620, 1500, 100], "kind": "stone"},
			{"rect": [1500, 560, 900, 26], "kind": "wood"},
		],
		"props": [
			{"type": "boat", "pos": Vector2(2150, 585), "color": Color("#3f6b8a"), "z": -3},
			{"type": "crate", "pos": Vector2(1180, 620)},
			{"type": "crate", "pos": Vector2(1240, 620), "s": 44.0},
			{"type": "crate", "pos": Vector2(1205, 564), "s": 40.0},
			{"type": "sign", "pos": Vector2(300, 620), "text": "Harbour Docks"},
			{"type": "lamppost", "pos": Vector2(700, 620)},
		],
		"npcs": [
			{
				"id": "gus", "name": "Gus", "pos": Vector2(1600, 560),
				"look": {"skin": Color("#c68642"), "hair_style": 0, "hair_color": Color("#2b2b2b"),
					"shirt": Color("#e88f2a"), "pants": Color("#25537a")},
				"face_left": true,
				"dialog": [
					{"if": {"flag": "crate_delivered"}, "lines": [
						"Straight down and straight back up. You dive better than my whole crew.",
					]},
					{"if": {"has_item": "wet_crate"}, "lines": [
						"That's the one! Rosie's been on the phone about it since Tuesday.",
						"Here — a day's pay, and worth every coin.",
					], "actions": [
						{"take_item": "wet_crate"}, {"give_item": "coins"}, {"set_flag": "crate_delivered"},
					]},
					{"if": {"not_flag": "met_gus"}, "lines": [
						"Careful on those boards, they're slick.",
						"You looking for work? Because I'm looking for someone who can swim.",
						"Rosie's delivery went over the side this morning. One crate, straight down.",
						"Fish it out and there's honest pay in it. Just dive off the end there.",
					], "actions": [{"set_flag": "met_gus"}]},
					{"lines": ["Crate's still down there. Dive off the end of the dock — you'll see it."]},
				],
			},
		],
		"items": [],
		"doors": [
			{"to": "main", "spawn": "from_docks", "label": "Main Street", "pos": Vector2(80, 620), "dir": Vector2.LEFT},
			{"to": "harbor", "spawn": "default", "label": "Dive!", "pos": Vector2(2300, 560), "dir": Vector2.DOWN},
		],
		"spawns": {
			"default": Vector2(200, 620),
			"from_main": Vector2(160, 620),
			"from_harbor": Vector2(2220, 560),
		},
	}


static func _harbor() -> Dictionary:
	return {
		"size": Vector2(1700, 900),
		"bg": "underwater",
		"swim": true,
		"platforms": [
			{"rect": [0, 820, 1700, 80], "kind": "rock"},
		],
		"props": [
			{"type": "seaweed", "pos": Vector2(280, 820), "s": 1.3},
			{"type": "seaweed", "pos": Vector2(820, 820)},
			{"type": "seaweed", "pos": Vector2(1420, 820), "s": 1.5},
			{"type": "rock", "pos": Vector2(560, 820), "s": 62.0, "color": Color("#4a6270")},
			{"type": "rock", "pos": Vector2(1180, 820), "s": 44.0, "color": Color("#4a6270")},
			{"type": "boat", "pos": Vector2(1000, 820), "color": Color("#4a5a66"), "z": -2},
		],
		"npcs": [],
		"items": [
			{"id": "wet_crate", "pos": Vector2(1280, 740)},
		],
		"doors": [
			{"to": "docks", "spawn": "from_harbor", "label": "Surface", "pos": Vector2(250, 170), "dir": Vector2.UP},
		],
		"spawns": {"default": Vector2(260, 260)},
	}


static func _alley() -> Dictionary:
	return {
		"size": Vector2(1700, 780),
		"bg": "alley",
		"platforms": [
			{"rect": [0, 680, 1700, 100], "kind": "stone"},
		],
		"props": [
			{"type": "dumpster", "pos": Vector2(1080, 680)},
			{"type": "crate", "pos": Vector2(900, 680), "s": 54.0},
			{"type": "ladder", "pos": Vector2(1400, 680), "h": 300.0, "z": -2},
			{"type": "crate", "pos": Vector2(1320, 680), "s": 46.0},
		],
		"npcs": [
			{
				"id": "tam", "name": "Tam", "pos": Vector2(640, 680),
				"look": {"skin": Color("#f1c27d"), "hair_style": 2, "hair_color": Color("#c9483a"),
					"shirt": Color("#8a4fb0"), "pants": Color("#444a54"), "scale": 0.86},
				"scale": 0.86,
				"dialog": [
					{"if": {"flag": "bought_gum"}, "lines": [
						"Tell him it gets easier around day four. That's what my brother says anyway.",
					]},
					{"if": {"has_item": "coins"}, "lines": [
						"You're the one running errands for Nathan, yeah? Everyone knows.",
						"Here's a thought. My brother packed it in last spring — chewed this stuff instead.",
						"Same money Rosie charges. Your call, and I'm not going to be weird about it.",
					], "choices": [
						{"label": "Buy the gum", "lines": [
							"Nice one. Tell him day four's the worst of it.",
						], "actions": [
							{"take_item": "coins"}, {"give_item": "gum"}, {"set_flag": "bought_gum"},
						]},
						{"label": "No thanks — he asked for smokes", "lines": [
							"Fair enough. Rosie's got them. No hard feelings.",
						]},
					]},
					{"if": {"flag": "met_tam"}, "lines": [
						"The gull's nest is up top. Big scruffy thing, you can't miss it.",
						"Mind the ladder, third rung's gone.",
					]},
					{"lines": [
						"You want the roof. That's where everything on this street ends up.",
						"There's a gull nests up there — proper menace, takes anything shiny or crinkly.",
						"Took my hat in June. Took a whole sandwich off Gus.",
						"Ladder's at the end. Careful, third rung's gone.",
					], "actions": [{"set_flag": "met_tam"}]},
				],
			},
		],
		"items": [],
		"doors": [
			{"to": "main", "spawn": "from_alley", "label": "Main Street", "pos": Vector2(120, 680), "dir": Vector2.UP},
			{"to": "rooftops", "spawn": "default", "label": "Up the ladder", "pos": Vector2(1480, 680), "dir": Vector2.UP},
		],
		"spawns": {
			"default": Vector2(240, 680),
			"from_roof": Vector2(1400, 680),
		},
	}


static func _rooftops() -> Dictionary:
	return {
		"size": Vector2(2200, 820),
		"bg": "dusk",
		"platforms": [
			{"rect": [0, 720, 2200, 100], "kind": "stone"},
			{"rect": [260, 600, 300, 26], "kind": "stone", "one_way": true},
			{"rect": [700, 480, 280, 26], "kind": "stone", "one_way": true},
			{"rect": [1120, 380, 260, 26], "kind": "stone", "one_way": true},
			{"rect": [1560, 300, 320, 30], "kind": "stone"},
		],
		"props": [
			{"type": "nest", "pos": Vector2(1720, 300)},
			{"type": "crate", "pos": Vector2(420, 600), "s": 44.0},
			{"type": "lamppost", "pos": Vector2(180, 720)},
			{"type": "sign", "pos": Vector2(900, 480), "text": "Mind the gap"},
		],
		"npcs": [],
		"items": [
			{"id": "soggy_pack", "pos": Vector2(1680, 240)},
			{"id": "lucky_ticket", "pos": Vector2(1790, 240)},
		],
		"doors": [
			{"to": "alley", "spawn": "from_roof", "label": "Back down", "pos": Vector2(90, 720), "dir": Vector2.DOWN},
		],
		"spawns": {"default": Vector2(180, 720)},
	}
