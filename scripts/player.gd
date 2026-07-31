class_name Player
extends CharacterBody2D
## Poptropica-feel movement: floaty high jumps, tap-to-move, swim mode.

signal arrived  # reached tap target / pending action range

const SPEED := 330.0
const ACCEL := 2400.0
const DECEL := 2600.0
const JUMP_VEL := -760.0
const GRAVITY := 1500.0
const FALL_GRAVITY := 1900.0
const SWIM_GRAVITY := 60.0
const SWIM_SPEED := 240.0

var rig: AvatarRig
var name_label: Label
var swim_mode := false
var input_locked := false
var crouching := false
var rolling := false

const ROLL_SPEED := 430.0
const ROLL_DECEL := 260.0

var _roll_dir := 1.0

var _target_x := NAN
var _jump_queued := false
var _swim_target := Vector2.INF
var _was_on_floor := true
var _hold_active := false
var _hold_x := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 15.0
	cap.height = 66.0
	shape.shape = cap
	shape.position = Vector2(0, -46)
	add_child(shape)

	rig = AvatarRig.new()
	rig.apply_config(Game.avatar)
	add_child(rig)

	name_label = Label.new()
	name_label.text = Game.player_name
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	name_label.add_theme_constant_override("outline_size", 6)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size = Vector2(200, 20)
	name_label.position = Vector2(-100, -140)
	add_child(name_label)


func set_move_target(p: Vector2) -> void:
	## Walk to a point (used for tap-to-move and auto-approach). Never jumps.
	if input_locked:
		return
	_target_x = p.x
	if swim_mode:
		_swim_target = p


func begin_hold(p: Vector2) -> void:
	## Pointer pressed: start walking toward it and keep walking while held.
	if input_locked:
		return
	_hold_active = true
	_hold_x = p.x
	_target_x = NAN
	if swim_mode:
		_swim_target = p


func update_hold(p: Vector2) -> void:
	if _hold_active and not input_locked:
		_hold_x = p.x
		if swim_mode:
			_swim_target = p


func end_hold() -> void:
	_hold_active = false


func request_jump() -> void:
	if not input_locked:
		_jump_queued = true
		_jump_buffer = 0.15


func clear_target() -> void:
	_target_x = NAN
	_swim_target = Vector2.INF
	_jump_queued = false
	_hold_active = false


func _physics_process(delta: float) -> void:
	if swim_mode:
		_swim(delta)
	else:
		_walk(delta)
	_update_rig()


func _walk(delta: float) -> void:
	var on_floor := is_on_floor()
	var on_ice := false
	if on_floor:
		for i in get_slide_collision_count():
			var col := get_slide_collision(i)
			var node := col.get_collider()
			if node is Node and node.get_meta("kind", "") == "ice":
				on_ice = true

	# gravity
	if not on_floor:
		velocity.y += (GRAVITY if velocity.y < 0 else FALL_GRAVITY) * delta
		velocity.y = minf(velocity.y, 1300.0)

	# Down/S: roll if already moving, otherwise crouch
	var down_held := not input_locked and on_floor \
		and (Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S))
	if rolling:
		# stay rolling until you slow down or let go
		rolling = down_held and absf(velocity.x) > 90.0
	elif down_held and absf(velocity.x) > 120.0:
		rolling = true
		_roll_dir = signf(velocity.x)
		Game.sfx("jump")
	crouching = down_held and not rolling

	if rolling:
		velocity.x = move_toward(velocity.x, _roll_dir * ROLL_SPEED, ROLL_DECEL * delta)
		move_and_slide()
		_coyote = 0.12
		_was_on_floor = true
		return

	if crouching:
		_target_x = NAN
		_hold_active = false

	# horizontal intent: keyboard > held pointer > tap target
	var dir := 0.0
	if crouching:
		velocity.x = move_toward(velocity.x, 0.0, DECEL * 2.0 * delta)
		move_and_slide()
		_coyote = 0.12
		_was_on_floor = true
		return
	if not input_locked:
		if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
			dir = -1.0
			_target_x = NAN
			_hold_active = false
		elif Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
			dir = 1.0
			_target_x = NAN
			_hold_active = false
		elif _hold_active:
			var hdx := _hold_x - global_position.x
			if absf(hdx) > 6.0:
				dir = signf(hdx)
		elif not is_nan(_target_x):
			var dx := _target_x - global_position.x
			if absf(dx) > 8.0:
				dir = signf(dx)
			else:
				_target_x = NAN
				arrived.emit()

	var accel := ACCEL if not on_ice else ACCEL * 0.18
	var decel := DECEL if not on_ice else DECEL * 0.06
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	# coyote time: brief grace after walking off a ledge
	if on_floor:
		_coyote = 0.12
	else:
		_coyote = maxf(_coyote - delta, 0.0)

	# jump (keyboard held, or a queued tap-jump buffered until landing)
	var want_jump := false
	if not input_locked:
		want_jump = Input.is_physical_key_pressed(KEY_SPACE) \
			or Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W)
	if _jump_queued:
		if _coyote > 0.0:
			want_jump = true
			_jump_queued = false
		else:
			_jump_buffer = maxf(_jump_buffer - delta, 0.0)
			if _jump_buffer <= 0.0:
				_jump_queued = false
	if want_jump and _coyote > 0.0:
		velocity.y = JUMP_VEL
		_coyote = 0.0
		rig.flipping = true  # somersault through the air
		Game.sfx("jump")

	move_and_slide()
	_was_on_floor = is_on_floor()


func _swim(delta: float) -> void:
	velocity.y += SWIM_GRAVITY * delta
	var dir := Vector2.ZERO
	if not input_locked:
		if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
			dir.x -= 1
		if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
			dir.x += 1
		if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
			dir.y -= 1
		if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
			dir.y += 1
		if dir != Vector2.ZERO:
			_swim_target = Vector2.INF
		elif _swim_target != Vector2.INF:
			var d := _swim_target - global_position + Vector2(0, -40)
			if d.length() > 20.0:
				dir = d.normalized()
			else:
				_swim_target = Vector2.INF
				arrived.emit()
	if dir != Vector2.ZERO:
		velocity = velocity.move_toward(dir.normalized() * SWIM_SPEED, 900.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2(0, velocity.y * 0.4), 500.0 * delta)
	move_and_slide()


func _update_rig() -> void:
	rig.swimming = swim_mode
	rig.airborne = not is_on_floor() and not swim_mode
	rig.crouching = crouching
	rig.rolling = rolling
	rig.vy = velocity.y
	rig.moving = absf(velocity.x) > 15.0 or (swim_mode and velocity.length() > 20.0)
	if absf(velocity.x) > 10.0:
		rig.facing = 1 if velocity.x > 0 else -1
