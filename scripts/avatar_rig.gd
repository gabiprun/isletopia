class_name AvatarRig
extends Node2D
## Code-drawn big-head character. Feet at local (0,0), head top ~ y=-114.
## Everything is drawn facing RIGHT; a mirror transform handles turning, so the
## whole body flips (cartoon-style pinch through zero) instead of just the face.

const SKIN_TONES := [
	Color("#ffdbac"), Color("#f1c27d"), Color("#e0ac69"),
	Color("#c68642"), Color("#8d5524"), Color("#5c3317"),
]
const HAIR_COLORS := [
	Color("#2b2b2b"), Color("#5a3825"), Color("#8a5a2b"), Color("#d8a12c"),
	Color("#c9483a"), Color("#e6e2d3"), Color("#3a6ea5"), Color("#8a4fb0"),
]
const CLOTH_COLORS := [
	Color("#d9483b"), Color("#e88f2a"), Color("#e8c930"), Color("#4ca64c"),
	Color("#2e8bc0"), Color("#25537a"), Color("#8a4fb0"), Color("#444a54"),
	Color("#e070a8"), Color("#68d0c8"), Color("#f4f1e8"), Color("#7a5230"),
]
const HAIR_STYLE_COUNT := 7  # 0 bald, 1 crop, 2 spiky, 3 bowl, 4 ponytail, 5 curly, 6 long

const FLIP_SPEED := 13.0

# Resolved look
var skin := SKIN_TONES[1]
var hair_color := HAIR_COLORS[2]
var shirt := CLOTH_COLORS[4]
var pants := CLOTH_COLORS[7]
var hair_style := 2
var shaggy := false  # yeti-style full fur

# Driven by the owner each frame
var facing := 1
var moving := false
var airborne := false
var swimming := false
var talking := false
var crouching := false
var vy := 0.0  # vertical velocity, so we can tell rising from falling

var _walk_phase := 0.0
var _blink := 0.0
var _blink_next := 2.0
var _talk_phase := 0.0
var _idle_phase := 0.0
var _face_v := 1.0     # animated mirror: lerps between -1 and 1
var _land_t := 0.0     # landing squash timer
var _launch_t := 0.0   # takeoff stretch timer
var _crouch_v := 0.0   # 0 = standing, 1 = fully crouched
var _prev_airborne := false


static func random_look() -> Dictionary:
	return {
		"skin": randi() % SKIN_TONES.size(),
		"hair_style": randi() % HAIR_STYLE_COUNT,
		"hair_color": randi() % HAIR_COLORS.size(),
		"shirt": randi() % CLOTH_COLORS.size(),
		"pants": randi() % CLOTH_COLORS.size(),
	}


func apply_config(cfg: Dictionary) -> void:
	## cfg uses palette indices (player save format)
	skin = SKIN_TONES[clampi(int(cfg.get("skin", 1)), 0, SKIN_TONES.size() - 1)]
	hair_style = clampi(int(cfg.get("hair_style", 2)), 0, HAIR_STYLE_COUNT - 1)
	hair_color = HAIR_COLORS[clampi(int(cfg.get("hair_color", 2)), 0, HAIR_COLORS.size() - 1)]
	shirt = CLOTH_COLORS[clampi(int(cfg.get("shirt", 4)), 0, CLOTH_COLORS.size() - 1)]
	pants = CLOTH_COLORS[clampi(int(cfg.get("pants", 7)), 0, CLOTH_COLORS.size() - 1)]
	queue_redraw()


func apply_colors(cfg: Dictionary) -> void:
	## cfg uses direct Colors (NPC format); keys optional
	skin = cfg.get("skin", skin)
	hair_color = cfg.get("hair_color", hair_color)
	shirt = cfg.get("shirt", shirt)
	pants = cfg.get("pants", pants)
	hair_style = cfg.get("hair_style", hair_style)
	shaggy = cfg.get("shaggy", false)
	queue_redraw()


func _process(delta: float) -> void:
	_idle_phase += delta * 2.0
	if moving and not airborne and not crouching:
		_walk_phase += delta * 11.0
	else:
		_walk_phase = lerpf(_walk_phase, roundf(_walk_phase / PI) * PI, delta * 10.0)
	if swimming:
		_walk_phase += delta * 4.0

	# turn: animate the mirror so the body physically flips
	_face_v = move_toward(_face_v, float(facing), FLIP_SPEED * delta)

	# crouch blend
	_crouch_v = move_toward(_crouch_v, 1.0 if crouching else 0.0, delta * 9.0)

	# takeoff stretch / landing squash
	if airborne and not _prev_airborne:
		_launch_t = 0.18
	elif _prev_airborne and not airborne:
		_land_t = 0.22
	_prev_airborne = airborne
	_launch_t = maxf(_launch_t - delta, 0.0)
	_land_t = maxf(_land_t - delta, 0.0)

	_blink -= delta
	_blink_next -= delta
	if _blink_next <= 0.0:
		_blink = 0.12
		_blink_next = randf_range(1.8, 4.5)
	if talking:
		_talk_phase += delta * 14.0
	queue_redraw()


func _expression() -> String:
	if _land_t > 0.0:
		return "land"
	if airborne and not swimming:
		return "jump" if vy < -60.0 else "fall"
	if crouching:
		return "crouch"
	if swimming:
		return "swim"
	if talking:
		return "talk"
	return "idle"


func _draw() -> void:
	var expr := _expression()

	# --- squash & stretch (pivots at the feet) ---
	var sy := 1.0
	if _launch_t > 0.0:
		sy += 0.16 * (_launch_t / 0.18)
	if _land_t > 0.0:
		sy -= 0.22 * (_land_t / 0.22)
	if expr == "fall":
		sy += 0.06
	sy -= 0.30 * _crouch_v
	var sx := 1.0 / sy  # keep the silhouette's volume roughly constant

	# mirrored turn: pinch through zero as they spin around
	var mirror := _face_v
	if absf(mirror) < 0.08:
		mirror = 0.08 * (1.0 if mirror >= 0.0 else -1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(mirror * sx, sy))

	var bob := sin(_idle_phase) * 1.2 if (not moving and expr == "idle") else 0.0
	var swing := sin(_walk_phase) * 0.7 if (moving and not airborne and not crouching) else 0.0
	if swimming:
		swing = sin(_walk_phase) * 0.4

	var hip := Vector2(0, -34 + bob)
	var leg_len := 34.0

	# --- legs ---
	if crouching and not airborne and not swimming:
		# folded underneath
		_capsule(hip + Vector2(-7, 2), hip + Vector2(-15, 26), 9, pants)
		_capsule(hip + Vector2(7, 2), hip + Vector2(15, 26), 9, pants)
		draw_circle(hip + Vector2(-15, 26), 6.5, Color("#3a3a3a"))
		draw_circle(hip + Vector2(15, 26), 6.5, Color("#3a3a3a"))
	elif airborne and not swimming:
		if expr == "jump":
			# tucked up on the way up
			_capsule(hip + Vector2(-6, 0), hip + Vector2(-11, 17), 9, pants)
			_capsule(hip + Vector2(6, 0), hip + Vector2(12, 19), 9, pants)
		else:
			# reaching for the ground on the way down
			_capsule(hip + Vector2(-6, 0), hip + Vector2(-12, 32), 9, pants)
			_capsule(hip + Vector2(6, 0), hip + Vector2(9, 34), 9, pants)
			draw_circle(hip + Vector2(-12, 32), 6.5, Color("#3a3a3a"))
			draw_circle(hip + Vector2(9, 34), 6.5, Color("#3a3a3a"))
	else:
		var a1 := swing
		var a2 := -swing
		if swimming:
			a1 = 0.5 + swing
			a2 = 0.5 - swing
		var foot1 := hip + Vector2(-6, 0) + Vector2(sin(a1), cos(a1)) * leg_len
		var foot2 := hip + Vector2(6, 0) + Vector2(sin(a2), cos(a2)) * leg_len
		_capsule(hip + Vector2(-6, 0), foot1, 9, pants)
		_capsule(hip + Vector2(6, 0), foot2, 9, pants)
		draw_circle(foot1, 6.5, Color("#3a3a3a"))
		draw_circle(foot2, 6.5, Color("#3a3a3a"))

	# --- body ---
	var body_top := Vector2(0, -66 + bob)
	_capsule(body_top, hip, 15, shirt)

	# --- arms ---
	var sh_l := Vector2(-13, -58 + bob)
	var sh_r := Vector2(13, -58 + bob)
	var arm_len := 26.0
	if crouching and not airborne and not swimming:
		_capsule(sh_l, sh_l + Vector2(-9, 20), 6, skin)
		_capsule(sh_r, sh_r + Vector2(9, 20), 6, skin)
	elif airborne and not swimming:
		if expr == "jump":
			# both arms punched up and out, clear of the head
			_capsule(sh_l, sh_l + Vector2(-22, -26), 6, skin)
			_capsule(sh_r, sh_r + Vector2(23, -28), 6, skin)
		else:
			# flailing on the way down
			var flail := sin(_idle_phase * 9.0) * 6.0
			_capsule(sh_l, sh_l + Vector2(-20, -14 + flail), 6, skin)
			_capsule(sh_r, sh_r + Vector2(21, -16 - flail), 6, skin)
	elif swimming:
		var wave := sin(_walk_phase * 2.0) * 8.0
		_capsule(sh_l, sh_l + Vector2(-18, -6 + wave), 6, skin)
		_capsule(sh_r, sh_r + Vector2(18, -6 - wave), 6, skin)
	else:
		var asw := sin(_walk_phase + PI) * 0.6 if moving else 0.0
		_capsule(sh_l, sh_l + Vector2(sin(asw) * arm_len - 3, cos(asw) * arm_len))
		_capsule(sh_r, sh_r + Vector2(sin(-asw) * arm_len + 3, cos(-asw) * arm_len))

	# --- head ---
	var head_c := Vector2(0, -88 + bob)
	if expr == "fall":
		head_c.y += 2  # scrunched into the shoulders
	draw_circle(head_c, 24, skin)
	if shaggy:
		_draw_shaggy(head_c)
	_draw_hair(head_c, expr)
	_draw_face(head_c, expr)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_face(c: Vector2, expr: String) -> void:
	var eye_y := c.y - 3
	var ex := 6.0  # always drawn facing right; the mirror handles the rest
	var brow := Color(0, 0, 0, 0.75)

	match expr:
		"jump":
			# wide eyes, small open mouth, brows raised — "whee!"
			draw_circle(Vector2(ex - 6, eye_y), 4.0, Color.BLACK)
			draw_circle(Vector2(ex + 6, eye_y), 4.0, Color.BLACK)
			draw_circle(Vector2(ex - 5, eye_y - 1.5), 1.4, Color.WHITE)
			draw_circle(Vector2(ex + 7, eye_y - 1.5), 1.4, Color.WHITE)
			draw_line(Vector2(ex - 11, eye_y - 10), Vector2(ex - 2, eye_y - 12), brow, 2.0)
			draw_line(Vector2(ex + 2, eye_y - 12), Vector2(ex + 11, eye_y - 10), brow, 2.0)
			draw_circle(Vector2(ex + 1, c.y + 11), 4.5, Color("#7a3b2e"))
		"fall":
			# big yell, eyes squeezed wide, brows angled in
			draw_circle(Vector2(ex - 6, eye_y), 4.5, Color.BLACK)
			draw_circle(Vector2(ex + 6, eye_y), 4.5, Color.BLACK)
			draw_line(Vector2(ex - 11, eye_y - 11), Vector2(ex - 2, eye_y - 8), brow, 2.2)
			draw_line(Vector2(ex + 2, eye_y - 8), Vector2(ex + 11, eye_y - 11), brow, 2.2)
			_oval(Vector2(ex + 1, c.y + 12), 5.0, 7.0, Color("#7a3b2e"))
		"land":
			# eyes shut, mouth a flat line — the "oof"
			draw_arc(Vector2(ex - 6, eye_y + 1), 4.0, PI, TAU, 8, Color.BLACK, 2.2)
			draw_arc(Vector2(ex + 6, eye_y + 1), 4.0, PI, TAU, 8, Color.BLACK, 2.2)
			draw_line(Vector2(ex - 4, c.y + 12), Vector2(ex + 6, c.y + 12), Color("#7a3b2e"), 2.2)
		"crouch":
			# looking down, small mouth
			draw_circle(Vector2(ex - 6, eye_y + 2), 3.0, Color.BLACK)
			draw_circle(Vector2(ex + 6, eye_y + 2), 3.0, Color.BLACK)
			draw_line(Vector2(ex - 11, eye_y - 7), Vector2(ex - 2, eye_y - 8), brow, 2.0)
			draw_line(Vector2(ex + 2, eye_y - 8), Vector2(ex + 11, eye_y - 7), brow, 2.0)
			draw_line(Vector2(ex - 3, c.y + 11), Vector2(ex + 5, c.y + 11), Color("#7a3b2e"), 2.0)
		"swim":
			# puffed cheeks, holding breath
			draw_circle(Vector2(ex - 12, c.y + 6), 6.0, Color(skin.darkened(0.06)))
			draw_circle(Vector2(ex + 13, c.y + 6), 6.0, Color(skin.darkened(0.06)))
			draw_circle(Vector2(ex - 6, eye_y), 3.0, Color.BLACK)
			draw_circle(Vector2(ex + 6, eye_y), 3.0, Color.BLACK)
			draw_circle(Vector2(ex + 1, c.y + 11), 3.0, Color("#7a3b2e"))
		_:
			# idle / talking
			if _blink > 0.0:
				draw_line(Vector2(ex - 9, eye_y), Vector2(ex - 3, eye_y), Color.BLACK, 2.0)
				draw_line(Vector2(ex + 3, eye_y), Vector2(ex + 9, eye_y), Color.BLACK, 2.0)
			else:
				draw_circle(Vector2(ex - 6, eye_y), 3.0, Color.BLACK)
				draw_circle(Vector2(ex + 6, eye_y), 3.0, Color.BLACK)
				draw_circle(Vector2(ex - 5, eye_y - 1), 1.0, Color.WHITE)
				draw_circle(Vector2(ex + 7, eye_y - 1), 1.0, Color.WHITE)
			if talking:
				var open := absf(sin(_talk_phase)) * 4.0 + 1.5
				draw_circle(Vector2(ex + 1, c.y + 11), open, Color("#7a3b2e"))
			else:
				draw_arc(Vector2(ex + 1, c.y + 9), 5.0, 0.3, PI - 0.3, 8, Color("#7a3b2e"), 2.0)


func _oval(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(17):
		var a := i * TAU / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	var cols := PackedColorArray()
	for i in pts.size():
		cols.append(col)
	draw_polygon(pts, cols)


func _capsule(a: Vector2, b: Vector2, r: float = 6.0, col: Color = Color.WHITE) -> void:
	if col == Color.WHITE:
		col = skin
	draw_line(a, b, col, r * 2.0)
	draw_circle(a, r, col)
	draw_circle(b, r, col)


func _draw_shaggy(c: Vector2) -> void:
	for i in range(10):
		var ang := -PI + i * (PI / 9.0)
		var p := c + Vector2(cos(ang), sin(ang)) * 24.0
		draw_circle(p, 7.0, hair_color)


func _draw_hair(c: Vector2, expr: String) -> void:
	var hc := hair_color
	# hair lags behind the body: lifts when rising, flattens when falling
	var lift := 0.0
	if expr == "jump":
		lift = 4.0
	elif expr == "fall":
		lift = -3.0
	match hair_style:
		0:
			pass  # bald
		1:  # crop
			draw_circle_arc_cap(c + Vector2(0, -lift * 0.3), 24.5, hc, -PI, 0.0)
		2:  # spiky
			draw_circle_arc_cap(c, 24.5, hc, -PI, 0.0)
			for i in range(5):
				var ang := -PI + (i + 0.5) * (PI / 5.0)
				var base := c + Vector2(cos(ang), sin(ang)) * 22.0
				var tip := c + Vector2(cos(ang), sin(ang)) * (36.0 + lift)
				draw_polygon(
					PackedVector2Array([base + Vector2(-5, 0), base + Vector2(5, 0), tip]),
					PackedColorArray([hc, hc, hc])
				)
		3:  # bowl
			draw_circle_arc_cap(c, 25.0, hc, -PI - 0.5, 0.5)
		4:  # ponytail
			draw_circle_arc_cap(c, 24.5, hc, -PI, 0.0)
			draw_circle(c + Vector2(-22, -6 - lift), 8.0, hc)
			draw_circle(c + Vector2(-26, 6 - lift * 0.5), 6.0, hc)
		5:  # curly
			for i in range(6):
				var ang := -PI + (i + 0.5) * (PI / 6.0)
				draw_circle(c + Vector2(cos(ang), sin(ang)) * (22.0 + lift * 0.5), 9.0, hc)
		6:  # long
			draw_circle_arc_cap(c, 25.0, hc, -PI - 0.4, 0.4)
			draw_rect(Rect2(c.x - 26, c.y - 4, 9, 30 - lift), hc)
			draw_rect(Rect2(c.x + 17, c.y - 4, 9, 30 - lift), hc)


func draw_circle_arc_cap(c: Vector2, r: float, col: Color, from: float, to: float) -> void:
	var pts := PackedVector2Array()
	var n := 18
	for i in range(n + 1):
		var ang := from + (to - from) * i / n
		pts.append(c + Vector2(cos(ang), sin(ang)) * r)
	var cols := PackedColorArray()
	for i in pts.size():
		cols.append(col)
	draw_polygon(pts, cols)
