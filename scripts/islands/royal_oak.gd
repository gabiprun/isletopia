class_name RoyalOakData
## Royal Oak — Mr. Kable's new-denture day. Daniel the denturist wants more
## money, the BMO machine says no, and the back lane says a lot more.
## Six rooms, a bakery job, three deliveries, a raccoon, and two endings.


static func data() -> Dictionary:
	return {
		"id": "royaloak",
		"name": "Royal Oak",
		"tagline": "New teeth, old debts.",
		"color": Color("#2b3f8a"),
		"start_room": "plaza",
		"hints": [
			{"if": {"flag": "royal_complete"}, "text": "Island complete! Take the blimp to your next adventure."},
			{"if": {"has_item": "denture"}, "text": "Take the denture to Mr. Kable — he's on the plaza bench."},
			{"if": {"has_item": "gold_tooth"}, "text": "Evidence in hand. Have a word with Daniel about his 'lab fees'."},
			{"if": {"flag": "saw_melting"}, "text": "Grab the gold tooth by the drainpipe — that's evidence, that is."},
			{"if": {"flag": "earned_pay"}, "text": "Head back to the clinic — the back lane's a shortcut. What's that glow?"},
			{"if": {"has_all": ["tip_earl", "tip_pia", "tip_daniel"]}, "text": "All three loaves paid for. Take the bread money back to Marge."},
			{"if": {"flag": "flour_delivered"}, "text": "Deliver the loaves: Earl at the mill, Pia in the park, Dr. Daniel at the clinic."},
			{"if": {"has_item": "flour_sack"}, "text": "Haul the flour back to Marge at Grainy's."},
			{"if": {"flag": "met_earl"}, "text": "The flour's up in the mill loft. Climb — mind the wobbly one."},
			{"if": {"flag": "met_marge"}, "text": "Marge needs flour from Earl's mill, up the lane past the bakery."},
			{"if": {"flag": "kable_working"}, "text": "Mr. Kable's at Grainy's Bakery. Talk to Marge."},
			{"if": {"flag": "price_hiked"}, "text": "Meet Mr. Kable at the BMO ATM, next door to the clinic."},
			{"if": {"flag": "met_kable"}, "text": "Follow Mr. Kable into the Royal Oak Denture Clinic."},
			{"text": "Talk to Mr. Kable outside the denture clinic."},
		],
		"rooms": {
			"plaza": _plaza(),
			"clinic": _clinic(),
			"bakery": _bakery(),
			"mill": _mill(),
			"park": _park(),
			"backlane": _backlane(),
		},
	}


static func _kable_look() -> Dictionary:
	## Old white man: pale skin, white hair, cardigan colors.
	return {"skin": Color("#f2d6b8"), "hair_style": 6, "hair_color": Color("#e8e6e0"),
		"shirt": Color("#7a5a44"), "pants": Color("#4a4f56")}


static func _daniel_look() -> Dictionary:
	## Young denturist, mid-20s: dark swoopy hair, crisp scrubs.
	return {"skin": Color("#f1c27d"), "hair_style": 3, "hair_color": Color("#2b1f16"),
		"shirt": Color("#e8f2f8"), "pants": Color("#1f2a66")}


static func _spare_denture_beat() -> Dictionary:
	## Side quest payoff — works at whichever Kable you bring the spare to.
	return {"if": {"has_item": "old_denture"}, "lines": [
		"My spare! The raccoon off the park took it right off my windowsill in June.",
		"...It's been *chewed*. Chewed by something with better teeth than me.",
		"Bin it, son. Bin it deep. And don't tell the raccoon where I live. Again.",
	], "actions": [{"take_item": "old_denture"}, {"set_flag": "found_spare"}]}


static func _plaza() -> Dictionary:
	return {
		"size": Vector2(2600, 720),
		"bg": "street",
		"platforms": [
			{"rect": [0, 620, 2600, 100], "kind": "stone"},
		],
		"props": [
			{"type": "house", "pos": Vector2(480, 620), "w": 280.0, "h": 200.0,
				"body": Color("#c9b08a"), "roof": Color("#5f6a72")},
			{"type": "sign", "pos": Vector2(300, 620), "text": "COLD BEER WINE"},
			{"type": "sign", "pos": Vector2(660, 620), "text": "NOTICE"},
			{"type": "house", "pos": Vector2(1500, 620), "w": 320.0, "h": 215.0,
				"body": Color("#4a5058"), "roof": Color("#1f2a66")},
			{"type": "awning", "pos": Vector2(1500, 434), "w": 300.0,
				"c1": Color("#1f2a66"), "c2": Color("#e8c930")},
			{"type": "sign", "pos": Vector2(1290, 620), "text": "ROYAL OAK DENTURE CLINIC"},
			{"type": "sign", "pos": Vector2(1700, 620), "text": "DENTURES"},
			{"type": "atm", "pos": Vector2(1920, 620)},
			{"type": "bench", "pos": Vector2(900, 620)},
			{"type": "lamppost", "pos": Vector2(1100, 620)},
			{"type": "tree", "pos": Vector2(2050, 620), "kind": "bare", "s": 1.1},
			{"type": "fence", "pos": Vector2(2250, 620), "w": 220.0},
			{"type": "crate", "pos": Vector2(2420, 620), "s": 48.0},
		],
		"npcs": [
			{
				"id": "kable_greet", "name": "Mr. Kable", "pos": Vector2(1650, 620),
				"look": _kable_look(), "face_left": true,
				"hidden_flag": "met_kable",
				"dialog": [
					{"lines": [
						"Morning! Big day. New denture day!",
						"Been eating soup since Easter. Soup, and things that surrender to soup.",
						"Daniel's had my new teeth ready a week — all paid up, just the fitting left.",
						"Young Danny. Took the clinic over from his dad last spring. Good lad. Probably.",
						"Come on in with me, would you?",
					], "actions": [{"set_flag": "met_kable"}]},
				],
			},
			{
				"id": "kable_atm", "name": "Mr. Kable", "pos": Vector2(1990, 620),
				"look": _kable_look(), "face_left": true,
				"visible_flag": "price_hiked", "hidden_flag": "kable_working",
				"dialog": [
					{"lines": [
						"Right. The BMO machine. Card in... PIN in... don't look.",
						"*beep* INSUFFICIENT FUNDS.",
						"Try it again— *beep* Same. The machine's made its point.",
						"Pension lands Friday. My gums cannot wait until Friday.",
						"...There's nothing for it. Marge always said the bakery door's open.",
						"Twenty years since I hung up that apron. Let's see if the arms remember.",
						"Meet me at Grainy's — past the plaza, follow your nose.",
					], "actions": [{"set_flag": "kable_working"}]},
				],
			},
			{
				"id": "kable_bench", "name": "Mr. Kable", "pos": Vector2(960, 620),
				"look": _kable_look(),
				"visible_flag": "resolved",
				"dialog": [
					{"if": {"has_item": "denture"}, "lines": [
						"That's the box! Give it here, give it here—",
						"*pop* ...Well then. Well THEN.",
						"*bites into an apple* CRUNCH. First crunch since Easter, son.",
						"You're a good egg. Best day this plaza's seen since the beer store got its NOTICE board.",
					], "actions": [
						{"take_item": "denture"}, {"set_flag": "royal_complete"},
						{"medallion": "royaloak"},
					]},
					{"if": {"flag": "ending_exposed"}, "lines": [
						"Free of charge, forever, he says. Amazing what a man remembers when you find his crucible.",
						"*bites apple* Hah! Hear that crunch? Music.",
					]},
					{"if": {"flag": "ending_paid"}, "lines": [
						"Worth every coin, and I earned every coin. Well. We earned it.",
						"*bites apple* Right in the crunch. Beautiful.",
					]},
					_spare_denture_beat(),
					{"lines": [
						"Go settle up with Daniel — I'll mind the bench. It's a good bench.",
					]},
				],
			},
			{
				"id": "milo", "name": "Milo", "pos": Vector2(2320, 620),
				"look": {"skin": Color("#f1c27d"), "hair_style": 3, "hair_color": Color("#3a2a1a"),
					"shirt": Color("#d9483b"), "pants": Color("#25537a"), "scale": 0.8},
				"scale": 0.8, "face_left": true,
				"dialog": [
					{"if": {"flag": "royal_complete"}, "lines": [
						"Mr. Kable bit an apple and everyone clapped. This plaza rules.",
					]},
					{"lines": [
						"That NOTICE has been up since before I was born. Nobody knows what it noticed.",
						"There's a raccoon in the park with something shiny. He showed me. He's so proud.",
					]},
				],
			},
		],
		"items": [],
		"doors": [
			{"exit_island": true, "label": "Blimp", "pos": Vector2(180, 620), "dir": Vector2.UP},
			{"to": "park", "spawn": "from_plaza", "label": "Oak Park", "pos": Vector2(80, 620), "dir": Vector2.LEFT},
			{"to": "clinic", "spawn": "default", "label": "Denture Clinic", "pos": Vector2(1500, 620), "dir": Vector2.UP},
			{"to": "backlane", "spawn": "default", "label": "Back Lane", "pos": Vector2(2140, 620), "dir": Vector2.DOWN},
			{"to": "bakery", "spawn": "from_plaza", "label": "Bakery Row", "pos": Vector2(2530, 620), "dir": Vector2.RIGHT},
		],
		"spawns": {
			"default": Vector2(340, 620),
			"from_park": Vector2(170, 620),
			"from_clinic": Vector2(1560, 620),
			"from_backlane": Vector2(2140, 620),
			"from_bakery": Vector2(2450, 620),
		},
	}


static func _clinic() -> Dictionary:
	return {
		"size": Vector2(1800, 720),
		"bg": "alley",
		"platforms": [
			{"rect": [0, 620, 1800, 100], "kind": "stone"},
		],
		"props": [
			{"type": "stall", "pos": Vector2(480, 620), "c1": Color("#1f2a66"), "c2": Color("#e8f2f8")},
			{"type": "sign", "pos": Vector2(240, 620), "text": "Reception"},
			{"type": "banner", "pos": Vector2(900, 360), "w": 340.0},
			{"type": "sign", "pos": Vector2(1560, 620), "text": "LAB - STAFF ONLY"},
			{"type": "crate", "pos": Vector2(1340, 620), "s": 50.0},
			{"type": "crate", "pos": Vector2(1400, 620), "s": 44.0},
		],
		"npcs": [
			{
				"id": "carol", "name": "Carol", "pos": Vector2(620, 620),
				"look": {"skin": Color("#c68642"), "hair_style": 5, "hair_color": Color("#6b3a2a"),
					"shirt": Color("#68d0c8"), "pants": Color("#444a54")},
				"dialog": [
					{"if": {"flag": "royal_complete"}, "lines": [
						"He's alphabetising the molds and sweating. What did you DO?",
						"...No. Don't tell me. I love it.",
					]},
					{"if": {"flag": "saw_melting"}, "lines": [
						"You went down the LANE? At crucible o'clock?",
						"*whisper* Whatever you saw — I've seen the tray. Careful, love.",
					]},
					{"if": {"flag": "price_hiked"}, "lines": [
						"Third 'lab fee' hike this year. Lab hasn't bought so much as a kettle.",
						"Twenty-six years old, fresh out of denturist school, and somehow there's a boat payment.",
						"And patients keep leaving... lighter in the mouth, somehow.",
						"I never said anything. I wasn't even here. Who's Carol?",
					]},
					{"lines": [
						"Welcome to Royal Oak Denture Clinic. Take a seat — mind the springs.",
						"Doctor Daniel will see you shortly. He's young, but he's very... thorough.",
					]},
				],
			},
			{
				"id": "kable_waiting", "name": "Mr. Kable", "pos": Vector2(900, 620),
				"look": _kable_look(),
				"visible_flag": "met_kable", "hidden_flag": "price_hiked",
				"dialog": [
					{"lines": [
						"Look at this place. Smells like mint and money.",
						"Go on, tell Daniel we're here. I'll practice my chewing face.",
					]},
				],
			},
			{
				"id": "daniel", "name": "Dr. Daniel", "pos": Vector2(1150, 620),
				"look": _daniel_look(),
				"face_left": true,
				"dialog": [
					{"if": {"flag": "royal_complete"}, "lines": [
						"The Kable fitting went... smoothly. We don't discuss the invoicing.",
						"Floss.",
					]},
					{"if": {"flag": "ending_exposed"}, "lines": [
						"You saw nothing. There IS nothing. The lab is for LAB THINGS.",
						"Enjoy the complimentary care plan. Forever. Please leave.",
					]},
					{"if": {"flag": "ending_paid"}, "lines": [
						"A pleasure doing business. Tell your friends.",
						"The ones with teeth. Or without! Especially without.",
					]},
					{"if": {"has_item": "loaf_daniel"}, "lines": [
						"Ah! My sourdough. Extra crusty, as ordered.",
						"I have excellent teeth, you see. All mine. Well. *Mostly* mine.",
						"Here's the bread money — tell Marge her crust is a triumph of engineering.",
					], "actions": [{"take_item": "loaf_daniel"}, {"give_item": "tip_daniel"}]},
					{"if": {"has_item": "gold_tooth"}, "lines": [
						"Back again. Do we have the *adjusted* balance?",
					], "choices": [
						{"label": "Show him the gold tooth", "lines": [
							"Where did you— that could be ANYONE'S premolar!",
							"...You were in the lane. You saw the crucible.",
							"Listen. LISTEN. Lab fees are... flexible. Waived! All waived!",
							"The denture. Fitted, polished, free of charge, lifetime care plan.",
							"We never spoke. There is no crucible. Give my regards to nobody.",
						], "actions": [
							{"take_item": "gold_tooth"}, {"give_item": "denture"},
							{"set_flag": "ending_exposed"}, {"set_flag": "resolved"},
						]},
						{"label": "Just pay the man", "lines": [
							"Coins! Warm, honest, bakery-scented coins. Close enough.",
							"One denture, as ordered. A genuine pleasure.",
						], "actions": [
							{"take_item": "pay_coins"}, {"give_item": "denture"},
							{"set_flag": "ending_paid"}, {"set_flag": "resolved"},
						]},
					]},
					{"if": {"has_item": "pay_coins"}, "lines": [
						"The adjusted balance! In full. In coin. In... is that flour?",
						"No matter. One denture, fitted and polished. A pleasure.",
					], "actions": [
						{"take_item": "pay_coins"}, {"give_item": "denture"},
						{"set_flag": "ending_paid"}, {"set_flag": "resolved"},
					]},
					{"if": {"flag": "price_hiked"}, "lines": [
						"The balance stands. The ATM stands. Next door. I believe in you.",
					]},
					{"if": {"flag": "met_kable"}, "lines": [
						"Mr. Kable! And an assistant. Wonderful. The denture is ready — a beautiful piece.",
						"Premium acrylic. Hand-polished. You could crack walnuts. Please don't.",
						"Now — a small matter of the balance. Lab fees have gone up. Considerably.",
						"It's another forty. Cash. Before anything goes anywhere near a mouth.",
						"I know, I know — 'I've been coming here since you were in braces, Danny.' Times change. Prices too.",
						"Don't make that face, Mr. Kable, you haven't the teeth for it.",
						"There's a BMO ATM right next door. Go get more money.",
					], "actions": [{"set_flag": "price_hiked"}]},
					{"lines": [
						"Do you have an appointment? No?",
						"Then this is a waiting room, and you are excellent at it.",
					]},
				],
			},
		],
		"items": [],
		"doors": [
			{"to": "plaza", "spawn": "from_clinic", "label": "Plaza", "pos": Vector2(80, 620), "dir": Vector2.LEFT},
		],
		"spawns": {
			"default": Vector2(180, 620),
		},
	}


static func _bakery() -> Dictionary:
	return {
		"size": Vector2(2200, 720),
		"bg": "street",
		"platforms": [
			{"rect": [0, 620, 2200, 100], "kind": "stone"},
		],
		"props": [
			{"type": "house", "pos": Vector2(700, 620), "w": 300.0, "h": 210.0,
				"body": Color("#e2c9a4"), "roof": Color("#8a4a44")},
			{"type": "awning", "pos": Vector2(700, 438), "w": 288.0,
				"c1": Color("#c0504a"), "c2": Color("#f4f1e8")},
			{"type": "sign", "pos": Vector2(940, 620), "text": "GRAINY'S BAKERY"},
			{"type": "stall", "pos": Vector2(1350, 620), "c1": Color("#c0504a"), "c2": Color("#f4e8b0")},
			{"type": "lamppost", "pos": Vector2(1050, 620)},
			{"type": "crate", "pos": Vector2(1600, 620), "s": 54.0},
			{"type": "crate", "pos": Vector2(1660, 620), "s": 44.0},
			{"type": "fence", "pos": Vector2(1900, 620), "w": 200.0},
		],
		"npcs": [
			{
				"id": "marge", "name": "Marge", "pos": Vector2(1200, 620),
				"look": {"skin": Color("#8d5524"), "hair_style": 6, "hair_color": Color("#3a2a1a"),
					"shirt": Color("#e88f2a"), "pants": Color("#5c3a1c")},
				"dialog": [
					{"if": {"flag": "royal_complete"}, "lines": [
						"Kable's taking Tuesdays now. Says retirement was making his hands soft.",
						"First batch he did solo sold out by nine. Don't tell him, he'll want Wednesdays.",
					]},
					{"if": {"flag": "earned_pay"}, "lines": [
						"Pay's paid. Go get those teeth sorted before Daniel invents another fee.",
					]},
					{"if": {"flag": "met_marge", "has_all": ["tip_earl", "tip_pia", "tip_daniel"]}, "lines": [
						"All three delivered and paid for? You'd make a decent baker's runner.",
						"Here — Kable's full day's pay. Plus a bit, because I remember what Daniel charges.",
						"Now walk him over there before he talks himself into night shifts.",
					], "actions": [
						{"take_item": "tip_earl"}, {"take_item": "tip_pia"}, {"take_item": "tip_daniel"},
						{"give_item": "pay_coins"}, {"set_flag": "earned_pay"},
					]},
					{"if": {"flag": "met_marge", "has_item": "flour_sack"}, "lines": [
						"That's the good flour! Ovens on. Kable, love — you're on buns.",
						"Right. Three special orders, boxed and warm:",
						"Earl at the mill. Pia at the park. And one for — *squints at the ticket* —",
						"'Dr. Daniel, Royal Oak Denture Clinic'. Sourdough. Extra crusty. Of course it is.",
						"Bread out, money back to me, then it's wages.",
					], "actions": [
						{"take_item": "flour_sack"}, {"give_item": "loaf_earl"},
						{"give_item": "loaf_pia"}, {"give_item": "loaf_daniel"},
						{"set_flag": "flour_delivered"},
					]},
					{"if": {"flag": "met_marge"}, "lines": [
						"No flour, no bread, no pay. That's not me being hard, that's just the order of operations.",
						"Earl's mill is up the lane. Loft's full, hoist is broke, Earl's knees are honest about it.",
					]},
					{"if": {"flag": "kable_working"}, "lines": [
						"Mr. Kable! Apron's where you left it. Twenty years and it still fits — don't check.",
						"You, small one. He's not lifting flour sacks with those wrists, so you're hired too.",
						"Two jobs, one day's pay: flour down from Earl's mill loft — hoist's broken, so someone climbs —",
						"— and my special orders delivered. Flour first. Can't box bread I haven't baked.",
					], "actions": [{"set_flag": "met_marge"}]},
					{"lines": [
						"Bakery's quiet. You buying or just sniffing?",
						"Sniffing's free. Loitering costs a smile.",
					]},
				],
			},
			{
				"id": "kable_baking", "name": "Mr. Kable", "pos": Vector2(1450, 620),
				"look": _kable_look(), "face_left": true,
				"visible_flag": "kable_working", "hidden_flag": "earned_pay",
				"dialog": [
					_spare_denture_beat(),
					{"lines": [
						"Flour in my ears already. Like riding a bike, if the bike were bread.",
						"Talk to Marge — she runs the day. I knead. That's the joke. I *need* to knead.",
					]},
				],
			},
		],
		"items": [],
		"doors": [
			{"to": "plaza", "spawn": "from_bakery", "label": "Plaza", "pos": Vector2(80, 620), "dir": Vector2.LEFT},
			{"to": "mill", "spawn": "from_bakery", "label": "Earl's Mill", "pos": Vector2(2130, 620), "dir": Vector2.RIGHT},
		],
		"spawns": {
			"default": Vector2(200, 620),
			"from_plaza": Vector2(160, 620),
			"from_mill": Vector2(2050, 620),
		},
	}


static func _mill() -> Dictionary:
	return {
		"size": Vector2(2000, 900),
		"bg": "cliffs",
		"platforms": [
			{"rect": [0, 800, 2000, 100], "kind": "grass"},
			{"rect": [880, 690, 220, 24], "kind": "wood", "one_way": true},
			{"rect": [1220, 580, 220, 24], "kind": "wood", "one_way": true},
			{"rect": [940, 470, 200, 24], "kind": "wood", "one_way": true},
			{"rect": [1280, 370, 240, 24], "kind": "wood", "one_way": true},
			{"rect": [1580, 280, 340, 28], "kind": "wood"},
		],
		"props": [
			{"type": "house", "pos": Vector2(500, 800), "w": 300.0, "h": 215.0,
				"body": Color("#b9a68c"), "roof": Color("#5c3a1c")},
			{"type": "sign", "pos": Vector2(260, 800), "text": "EARL'S MILL"},
			{"type": "ladder", "pos": Vector2(820, 800), "h": 90.0, "z": -2},
			{"type": "crate", "pos": Vector2(1700, 280), "s": 50.0},
			{"type": "crate", "pos": Vector2(1760, 280), "s": 42.0},
			{"type": "sign", "pos": Vector2(1640, 280), "text": "LOFT"},
			{"type": "tree", "pos": Vector2(1200, 800), "kind": "pine", "s": 1.2},
			{"type": "rock", "pos": Vector2(1500, 800), "s": 46.0},
			{"type": "nest", "pos": Vector2(1880, 280)},
		],
		"npcs": [
			{
				"id": "earl", "name": "Earl", "pos": Vector2(700, 800),
				"look": {"skin": Color("#e0ac69"), "hair_style": 0, "hair_color": Color("#d8d4c8"),
					"shirt": Color("#4a6270"), "pants": Color("#5c3a1c")},
				"dialog": [
					{"if": {"has_item": "loaf_earl"}, "lines": [
						"That's my Friday loaf! Marge's crust could sharpen an axe.",
						"Here's the money for it. And tell her the hoist is still broke — before she asks.",
					], "actions": [{"take_item": "loaf_earl"}, {"give_item": "tip_earl"}]},
					{"if": {"flag": "met_earl"}, "lines": [
						"Flour's up top. Third platform wobbles. Well — they all wobble.",
						"Mind yourself. The pigeons won't catch you, they've made that clear.",
					]},
					{"lines": [
						"Hoist snapped Tuesday. Flour's stuck in the loft, and my knees retired before I did.",
						"You after Marge's sack? Climb up, mind the gaps, and it's yours to carry.",
					], "actions": [{"set_flag": "met_earl"}]},
				],
			},
		],
		"items": [
			{"id": "flour_sack", "pos": Vector2(1820, 220), "require_flag": "met_earl"},
		],
		"doors": [
			{"to": "bakery", "spawn": "from_mill", "label": "Bakery Row", "pos": Vector2(80, 800), "dir": Vector2.LEFT},
		],
		"spawns": {
			"default": Vector2(200, 800),
			"from_bakery": Vector2(160, 800),
		},
	}


static func _park() -> Dictionary:
	return {
		"size": Vector2(2000, 760),
		"bg": "street",
		"platforms": [
			{"rect": [0, 660, 2000, 100], "kind": "grass"},
			{"rect": [1230, 550, 190, 22], "kind": "wood", "one_way": true},
			{"rect": [1470, 440, 180, 22], "kind": "wood", "one_way": true},
			{"rect": [1280, 340, 170, 22], "kind": "wood", "one_way": true},
			{"rect": [1520, 250, 200, 22], "kind": "wood", "one_way": true},
		],
		"props": [
			{"type": "sign", "pos": Vector2(200, 660), "text": "Garry Oak Park"},
			{"type": "tree", "pos": Vector2(700, 660), "kind": "pine", "s": 1.1},
			{"type": "tree", "pos": Vector2(1500, 660), "kind": "bare", "s": 2.2},
			{"type": "bench", "pos": Vector2(520, 660)},
			{"type": "crate", "pos": Vector2(430, 660), "s": 40.0},
			{"type": "fence", "pos": Vector2(1000, 660), "w": 220.0},
			{"type": "rock", "pos": Vector2(1150, 660), "s": 40.0},
			{"type": "nest", "pos": Vector2(1600, 250)},
		],
		"npcs": [
			{
				"id": "pia", "name": "Pia", "pos": Vector2(600, 660),
				"look": {"skin": Color("#f1c27d"), "hair_style": 4, "hair_color": Color("#2b2b2b"),
					"shirt": Color("#8a4fb0"), "pants": Color("#4ca64c")},
				"face_left": true,
				"dialog": [
					{"if": {"has_item": "loaf_pia"}, "lines": [
						"My picnic loaf! You star. Here's the bread money — count it, I mix up coins.",
						"Oh, and mind the raccoon. He's got something shiny up the big oak and he's VERY proud of it.",
						"Took my spoon in May. My good spoon.",
					], "actions": [{"take_item": "loaf_pia"}, {"give_item": "tip_pia"}]},
					{"if": {"flag": "found_spare"}, "lines": [
						"You took the shiny thing off the raccoon? He's been sulking on the fence all morning.",
						"He'll find something else. He always finds something else.",
					]},
					{"lines": [
						"Lovely day for a picnic. Would be lovelier with the bread I ordered from Grainy's.",
						"That raccoon's been up the big oak all week guarding something shiny. Grinning, sort of.",
					]},
				],
			},
		],
		"items": [
			{"id": "old_denture", "pos": Vector2(1680, 190)},
		],
		"doors": [
			{"to": "plaza", "spawn": "from_park", "label": "Plaza", "pos": Vector2(1930, 660), "dir": Vector2.RIGHT},
		],
		"spawns": {
			"default": Vector2(1800, 660),
			"from_plaza": Vector2(1840, 660),
		},
	}


static func _backlane() -> Dictionary:
	return {
		"size": Vector2(1600, 720),
		"bg": "alley",
		"platforms": [
			{"rect": [0, 620, 1600, 100], "kind": "stone"},
		],
		"props": [
			{"type": "sign", "pos": Vector2(280, 620), "text": "Deliveries Only"},
			{"type": "dumpster", "pos": Vector2(520, 620)},
			{"type": "crate", "pos": Vector2(680, 620), "s": 50.0},
			{"type": "crate", "pos": Vector2(735, 620), "s": 40.0},
			{"type": "sign", "pos": Vector2(1120, 620), "text": "LAB"},
			{"type": "crucible", "pos": Vector2(1270, 620),
				"visible_flag": "earned_pay", "hidden_flag": "resolved"},
			{"type": "chest", "pos": Vector2(1380, 620), "open": true,
				"visible_flag": "earned_pay", "hidden_flag": "resolved", "solid": false},
			{"type": "ladder", "pos": Vector2(1480, 620), "h": 320.0, "z": -2},
		],
		"npcs": [
			{
				"id": "kable_lane", "name": "Mr. Kable", "pos": Vector2(980, 620),
				"look": _kable_look(),
				"visible_flag": "earned_pay", "hidden_flag": "resolved",
				"dialog": [
					_spare_denture_beat(),
					{"if": {"flag": "saw_melting"}, "lines": [
						"I'll wait here. If I go in there I'll say something I regret.",
						"Or bite him. With what, I don't know.",
					]},
					{"lines": [
						"Shortcut past the bins, then it's teeth o'clo— wait. Wait wait wait.",
						"The lab window. Is that Daniel? What's he got the burner going for at this hour?",
						"Those are TEETH. Gold ones. A whole tray of them, marked PATIENTS.",
						"That's Mrs. Fontaine's bridgework — I'd know it anywhere, she waves a lot.",
						"He's been pulling gold teeth out of his patients and MELTING them down.",
						"The 'lab fees' are a shakedown! The lab IS the fee!",
						"There — by the drainpipe. One rolled out with the recycling. Grab it.",
						"That's evidence, that is.",
					], "actions": [{"set_flag": "saw_melting"}]},
				],
			},
			{
				"id": "daniel_melting", "name": "Dr. Daniel", "pos": Vector2(1290, 620),
				"look": _daniel_look(),
				"visible_flag": "earned_pay", "hidden_flag": "resolved",
				"dialog": [
					{"lines": [
						"*through the glass, muttering* ...gently... six hundred degrees... gently...",
						"*He hasn't seen you. He drops another gold tooth into the little crucible.*",
						"*mutter* ...Mrs. Fontaine's bridge... lovely lustre... 'lab fees'... heh...",
					]},
				],
			},
		],
		"items": [
			{"id": "gold_tooth", "pos": Vector2(1450, 560), "require_flag": "saw_melting"},
		],
		"doors": [
			{"to": "plaza", "spawn": "from_backlane", "label": "Plaza", "pos": Vector2(120, 620), "dir": Vector2.UP},
		],
		"spawns": {
			"default": Vector2(200, 620),
		},
	}
