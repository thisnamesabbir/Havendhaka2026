class_name HavenPlayer
extends CharacterBody2D

## Momentum-driven sandboarding, air tricks, wingsuit flight and expressive
## procedural animation. The board's rotation is real: it decides whether a
## landing is perfect, rough, or a crash.

signal died(reason: String)
signal crashed(reason: String)
signal landed(rating: String, airtime: float, rotations: int, impact_speed: float, chasm_jump: bool)
signal trick_landed(trick_name: String, rotations: int, airtime: float, rating: String)
signal trick_failed(trick_name: String)
signal trick_started(trick_name: String)
signal wingsuit_changed(deployed: bool)
signal perfect_landing(world_position: Vector2)
signal rock_bounced

const GRAVITY := 1900.0
const BASE_RUN_SPEED := 330.0
const MIN_RUN_SPEED := 215.0
const MAX_RUN_SPEED := 710.0
const GROUND_PROPULSION := 70.0
const SLOPE_ACCELERATION := 0.62
const GROUND_FRICTION := 0.026
const SLIDE_FRICTION := 0.006
const JUMP_SPEED := 755.0
const JUMP_FORWARD_BOOST := 1.035
const JUMP_CUT := 0.54
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.14
const AIR_GRAVITY := 1850.0
const MAX_FALL_SPEED := 1280.0
const AIR_STEER := 330.0
const AIR_DRAG := 7.0
const FLIP_RATE := TAU * 1.58
const MAX_SPIN_TURNS := 6.0
const WINGSUIT_FORWARD_SPEED := 820.0
const WINGSUIT_ACCEL := 240.0
const WINGSUIT_LIFT_SPEED := -130.0
const WINGSUIT_GLIDE_SPEED := 45.0
const WINGSUIT_DIVE_SPEED := 420.0
const WINGSUIT_VERTICAL_ACCEL := 330.0
const WINGSUIT_MAX_RISE := -260.0
const WINGSUIT_MAX_FALL := 460.0
const WINGSUIT_STEER := 360.0
const HOLD_TO_FLIP_DELAY := 0.19
const CRASH_DURATION := 0.95

@onready var art: RiderArt = $Art
var world: Node2D
var alive := true
var run_speed := BASE_RUN_SPEED
var wingsuit_unlocked := false
var wingsuit_deployed := false
var _grounded := false
var _slide_held := false
var _sliding := false
var _space_held := false
var _up_held := false
var _down_held := false
var _air_steer := 0.0
var _jump_buffer := 0.0
var _coyote := 0.0
var _jump_hold_timer := 0.0
var _jump_cut_available := false
var _airborne_time := 0.0
var _ground_angle := 0.0
var _takeoff_rotation := 0.0
var _air_rotation := 0.0
var _wing_rotation := 0.0
var _spin_accumulated := 0.0
var _spin_direction := -1.0
var _spin_held := false
var _trick_active := false
var _trick_name := ""
var _trick_started_this_air := false
var _landing_timer := 0.0
var _landing_rating := ""
var _deploy_timer := 0.0
var _was_wingsuit_landing := false
var _chasm_jump := false
var _crash_timer := 0.0
var _crash_reason := ""
var _crash_tumble := 0.0
var _time := 0.0
var _dust_timer := 0.0
var _dust: Array[Dictionary] = []
var _impact_ring := 0.0
var _impact_color := Color(1.0, 0.82, 0.5)
var _landing_flash := 0.0
var _palette: Dictionary = {}

func _ready() -> void:
	add_to_group("player")
	z_index = 6
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_max_angle = deg_to_rad(68.0)
	floor_snap_length = 26.0
	floor_stop_on_slope = false
	floor_constant_speed = false
	safe_margin = 0.04
	collision_layer = 1
	collision_mask = 1
	world = get_node_or_null("../World") as Node2D
	if has_node("/root/SaveData"):
		var save := get_node("/root/SaveData")
		wingsuit_unlocked = bool(save.get("wingsuit_unlocked"))
		var index := int(save.call("get_selected_character"))
		art.apply_character(index)
	_palette = HavenTheme.palette_at(global_position.x)
	_grounded = is_on_floor()
	_ground_angle = 0.0
	_air_rotation = 0.0
	_takeoff_rotation = 0.0
	velocity = Vector2(run_speed, 0.0)
	art.set_animation_state("idle")
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not alive:
		return
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if key.echo:
		return
	match key.keycode:
		KEY_SPACE:
			_on_jump_input(key.pressed)
		KEY_UP, KEY_W:
			_on_up_input(key.pressed)
		KEY_DOWN, KEY_S:
			_on_down_input(key.pressed)
		KEY_SHIFT:
			if key.pressed:
				toggle_wingsuit()
		KEY_LEFT, KEY_A:
			_set_steer(-1.0 if key.pressed else (1.0 if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) else 0.0))
		KEY_RIGHT, KEY_D:
			_set_steer(1.0 if key.pressed else (-1.0 if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) else 0.0))

func _on_jump_input(pressed: bool) -> void:
	_space_held = pressed
	if pressed:
		if is_on_floor() or _coyote > 0.0:
			_jump_buffer = JUMP_BUFFER_TIME
			_jump_hold_timer = 0.0
		elif wingsuit_deployed:
			pass
		else:
			if not _trick_active:
				_start_trick(-1.0)
			_jump_cut_available = false
	elif not _space_held and not _up_held and not _down_held:
		_spin_held = false
	if not pressed:
		_cut_jump()

func _on_up_input(pressed: bool) -> void:
	_up_held = pressed
	if wingsuit_deployed:
		return
	if pressed and not is_on_floor():
		if not _trick_active:
			_start_trick(-1.0)
		_jump_cut_available = false
	if not _space_held and not _up_held and not _down_held:
		_spin_held = false

func _on_down_input(pressed: bool) -> void:
	_down_held = pressed
	if wingsuit_deployed:
		_slide_held = pressed
		return
	if pressed and not is_on_floor():
		if not _trick_active:
			_start_trick(1.0)
		_jump_cut_available = false
	else:
		_slide_held = pressed
	if not _space_held and not _up_held and not _down_held:
		_spin_held = false

func _set_steer(value: float) -> void:
	_air_steer = clampf(value, -1.0, 1.0)

func set_touch_jump(pressed: bool) -> void:
	_on_jump_input(pressed)

func set_touch_down(pressed: bool) -> void:
	_on_down_input(pressed)

func set_slide(pressed: bool) -> void:
	_on_down_input(pressed)

func set_touch_steer(value: float) -> void:
	_set_steer(value)

func set_wingsuit_unlocked(unlocked: bool) -> void:
	wingsuit_unlocked = unlocked
	if not unlocked and wingsuit_deployed:
		_set_wingsuit(false)

func get_animation_state() -> String:
	return art.animation_state if is_instance_valid(art) else ""

func is_tricking() -> bool:
	return _trick_active

func get_trick_rotation() -> float:
	return _spin_accumulated

func get_trick_turns() -> int:
	return int(floor(absf(_spin_accumulated) / TAU + 0.02))

func get_speed_kph() -> float:
	return run_speed * 0.11

func get_airtime() -> float:
	return _airborne_time

func is_wingsuit_deployed() -> bool:
	return wingsuit_deployed

# --------------------------------------------------------------------------
# Main loop
# --------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_time += delta
	_update_dust(delta)
	_landing_timer = maxf(0.0, _landing_timer - delta)
	_deploy_timer = maxf(0.0, _deploy_timer - delta)
	_impact_ring = maxf(0.0, _impact_ring - delta)
	_landing_flash = maxf(0.0, _landing_flash - delta)
	if not alive:
		_update_crash(delta)
		queue_redraw()
		return

	_palette = HavenTheme.palette_at(global_position.x)
	var was_grounded := is_on_floor()
	_grounded = was_grounded
	if was_grounded and not wingsuit_deployed:
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(0.0, _coyote - delta)

	if was_grounded:
		_airborne_time = 0.0
	else:
		_airborne_time += delta
		_jump_hold_timer += delta

	var just_jumped := false
	if _jump_buffer > 0.0 and (was_grounded or _coyote > 0.0) and not wingsuit_deployed:
		_perform_jump()
		just_jumped = true
		_jump_buffer = 0.0
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)

	if not just_jumped and not was_grounded and _space_held and _jump_hold_timer > HOLD_TO_FLIP_DELAY and not _trick_active and not wingsuit_deployed:
		_start_trick(-1.0)

	if not was_grounded:
		_chasm_jump = _chasm_jump or _is_over_gap(global_position.x)

	_sliding = _slide_held and was_grounded and not wingsuit_deployed and not just_jumped
	if just_jumped:
		_air_physics(delta)
	elif was_grounded and not wingsuit_deployed:
		_ground_physics(delta)
	elif wingsuit_deployed:
		_wingsuit_physics(delta)
	else:
		_air_physics(delta)

	_update_trick(delta)
	_update_rotation(delta, was_grounded, just_jumped)
	var impact_velocity := velocity
	move_and_slide()

	if not was_grounded and not just_jumped and is_on_floor():
		_handle_landing(impact_velocity, get_floor_normal())
	elif was_grounded and not just_jumped and is_on_floor():
		var tangent := _forward_tangent(get_floor_normal())
		_ground_angle = lerp_angle(_ground_angle, tangent.angle(), 1.0 - exp(-16.0 * delta))

	if alive and _is_falling_out_of_world():
		crash("fall")
	_update_crash_timer_only(delta)
	_update_art(delta)
	queue_redraw()

func _perform_jump() -> void:
	var normal := get_floor_normal() if is_on_floor() else Vector2.UP
	var tangent := _forward_tangent(normal)
	if not is_on_floor() and is_instance_valid(world):
		tangent = world.call("slope_tangent_at", global_position.x)
		normal = Vector2(-tangent.y, tangent.x)
		if normal.y > 0.0:
			normal = -normal
	run_speed = maxf(run_speed, BASE_RUN_SPEED)
	velocity = tangent * run_speed * JUMP_FORWARD_BOOST + normal * JUMP_SPEED
	_takeoff_rotation = _ground_angle
	_air_rotation = _ground_angle
	_grounded = false
	_coyote = 0.0
	_jump_cut_available = true
	_jump_hold_timer = 0.0
	_spin_accumulated = 0.0
	_trick_active = false
	_trick_started_this_air = false
	_chasm_jump = _is_over_gap(global_position.x)
	_sliding = false
	AudioManager.play_sfx("jump")
	_spawn_dust(7, 0.72)
	_impact_ring = 0.20
	_impact_color = Color(0.96, 0.85, 0.65)

func _ground_physics(delta: float) -> void:
	var normal := get_floor_normal()
	var tangent := _forward_tangent(normal)
	var slope_accel := GRAVITY * SLOPE_ACCELERATION * maxf(tangent.y, -0.55)
	var friction := SLIDE_FRICTION if _sliding else GROUND_FRICTION
	run_speed += (slope_accel + GROUND_PROPULSION + (60.0 if _sliding else 0.0)) * delta
	run_speed *= exp(-friction * delta)
	run_speed = clampf(run_speed, MIN_RUN_SPEED, MAX_RUN_SPEED)
	velocity = tangent * run_speed + Vector2.DOWN * 70.0
	_ground_angle = lerp_angle(_ground_angle, tangent.angle(), 1.0 - exp(-18.0 * delta))
	_air_rotation = _ground_angle

func _air_physics(delta: float) -> void:
	var gravity := AIR_GRAVITY
	velocity.y = minf(velocity.y + gravity * delta, MAX_FALL_SPEED)
	velocity.x += _air_steer * AIR_STEER * delta
	var target_forward := maxf(BASE_RUN_SPEED, run_speed)
	velocity.x = move_toward(velocity.x, target_forward, AIR_DRAG * delta)
	velocity.x = clampf(velocity.x, 120.0, MAX_RUN_SPEED + 30.0)
	run_speed = velocity.x

func _wingsuit_physics(delta: float) -> void:
	var lift := _space_held or _up_held
	var dive := _down_held
	var target_vertical := WINGSUIT_GLIDE_SPEED
	if lift:
		target_vertical = WINGSUIT_LIFT_SPEED
	elif dive:
		target_vertical = WINGSUIT_DIVE_SPEED
	velocity.y = move_toward(
		velocity.y + GRAVITY * 0.08 * delta,
		target_vertical,
		WINGSUIT_VERTICAL_ACCEL * delta
	)
	velocity.y = clampf(velocity.y, WINGSUIT_MAX_RISE, WINGSUIT_MAX_FALL)
	velocity.x += _air_steer * WINGSUIT_STEER * delta
	velocity.x = move_toward(velocity.x, WINGSUIT_FORWARD_SPEED, WINGSUIT_ACCEL * delta)
	velocity.x = clampf(velocity.x, 280.0, WINGSUIT_FORWARD_SPEED + 80.0)
	run_speed = velocity.x
	if is_instance_valid(world):
		var ground: float = world.call("ground_height", global_position.x)
		if global_position.y > ground - 150.0:
			var closeness := clampf((global_position.y - (ground - 150.0)) / 150.0, 0.0, 1.0)
			velocity.x = lerpf(velocity.x, 520.0, closeness * 2.4 * delta)
			velocity.y = move_toward(velocity.y, 130.0, 170.0 * closeness * delta)
			if not _was_wingsuit_landing:
				_was_wingsuit_landing = true
				AudioManager.play_sfx("wind")

func _update_trick(delta: float) -> void:
	if _trick_active:
		_spin_held = (_space_held or _up_held or _down_held) and not wingsuit_deployed and not is_on_floor()
		if _spin_held:
			var speed_factor := clampf(run_speed / BASE_RUN_SPEED, 0.85, 1.3)
			var turn := FLIP_RATE * speed_factor * delta
			_spin_accumulated += turn
			if absf(_spin_accumulated) > TAU * MAX_SPIN_TURNS:
				_spin_accumulated = signf(_spin_accumulated) * TAU * MAX_SPIN_TURNS
	elif not is_on_floor():
		_spin_held = _space_held or _up_held or _down_held

func _update_rotation(delta: float, was_grounded: bool, just_jumped: bool) -> void:
	if wingsuit_deployed:
		var flight_angle := atan2(velocity.x, -velocity.y)
		_wing_rotation = lerp_angle(_wing_rotation, clampf(flight_angle, 0.55, 2.55), 1.0 - exp(-7.0 * delta))
		return
	if was_grounded and not just_jumped:
		_takeoff_rotation = _ground_angle
		_air_rotation = _ground_angle
		return
	if _trick_active:
		_air_rotation = _takeoff_rotation + _spin_direction * _spin_accumulated
	else:
		var target_angle := _takeoff_rotation
		if is_instance_valid(world):
			target_angle = float(world.call("slope_at", global_position.x))
		target_angle += clampf(velocity.y / 2600.0, -0.18, 0.42)
		_air_rotation = lerp_angle(_air_rotation, target_angle, 1.0 - exp(-2.8 * delta))

func _handle_landing(impact_velocity: Vector2, surface_normal: Vector2) -> void:
	var impact_speed := maxf(0.0, -impact_velocity.dot(surface_normal))
	var slope_angle := _forward_tangent(surface_normal).angle()
	var flight_rot := _air_rotation
	var had_wingsuit := wingsuit_deployed
	if had_wingsuit:
		_set_wingsuit(false)
		_was_wingsuit_landing = true
		flight_rot = lerp_angle(flight_rot, slope_angle, 0.86)
	var rotation_error := absf(wrapf(flight_rot - slope_angle, -PI, PI))
	var rotations := get_trick_turns()
	var trick_name := _trick_display_name(rotations)
	var rating := "clean"
	if rotation_error > 1.28 and impact_speed > 360.0 and not had_wingsuit:
		crash("landing")
		return
	if impact_speed > 1050.0:
		crash("landing")
		return
	if rotation_error > 0.62 or impact_speed > 760.0:
		rating = "rough"
	elif rotation_error < 0.16 and impact_speed < 430.0:
		rating = "perfect"
	elif rotation_error < 0.38 and impact_speed < 620.0:
		rating = "clean"
	else:
		rating = "rough" if rotation_error > 0.5 and impact_speed > 540.0 else "clean"
	if had_wingsuit and impact_speed < 520.0:
		rating = "perfect" if impact_speed < 300.0 else "clean"
		rotations = 0
		trick_name = ""
	var chasm := _chasm_jump
	var airtime := _airborne_time
	if rotations > 0 and rating != "rough":
		trick_landed.emit(trick_name, rotations, airtime, rating)
	elif rotations > 0:
		trick_failed.emit(trick_name)
	landed.emit(rating, airtime, rotations, impact_speed, chasm)
	if rating == "rough":
		run_speed = maxf(MIN_RUN_SPEED, run_speed * 0.62)
		velocity.x *= 0.78
		_landing_color(Color(0.95, 0.58, 0.43))
	else:
		run_speed = minf(MAX_RUN_SPEED, run_speed * (1.08 if rating == "perfect" else 1.03))
		velocity.x = maxf(velocity.x, run_speed)
		if rating == "perfect":
			perfect_landing.emit(global_position)
			_landing_color(Color(1.0, 0.88, 0.56))
			AudioManager.play_sfx("land_perfect")
		else:
			_landing_color(Color(1.0, 0.80, 0.52))
			AudioManager.play_sfx("land")
	_ground_angle = slope_angle
	_air_rotation = slope_angle
	_wing_rotation = slope_angle
	_spin_accumulated = 0.0
	_trick_active = false
	_trick_started_this_air = false
	_spin_held = false
	_chasm_jump = false
	_airborne_time = 0.0
	_landing_timer = 0.42
	_landing_rating = rating
	_impact_ring = 0.30
	_spawn_dust(12 if rating == "rough" else 8, 1.15)
	_landing_flash = 0.20
	if had_wingsuit:
		_landing_timer = 0.5
		_deploy_timer = 0.0

func _landing_color(color: Color) -> void:
	_impact_color = color
	_impact_ring = maxf(_impact_ring, 0.28)

func _start_trick(direction: float) -> void:
	if not alive or wingsuit_deployed or is_on_floor():
		return
	if _trick_active:
		if is_equal_approx(direction, _spin_direction):
			_spin_held = true
		return
	_trick_active = true
	_trick_started_this_air = true
	_spin_direction = -1.0 if direction < 0.0 else 1.0
	_spin_accumulated = 0.0
	_spin_held = true
	_takeoff_rotation = _air_rotation
	_jump_cut_available = false
	var kind := "backflip" if _spin_direction < 0.0 else "frontflip"
	trick_started.emit(kind)
	AudioManager.play_sfx("trick_whoosh")

func _trick_display_name(rotations: int) -> String:
	if rotations <= 0:
		return ""
	var direction := "BACKFLIP" if _spin_direction < 0.0 else "FRONTFLIP"
	match rotations:
		1:
			return direction
		2:
			return "DOUBLE " + direction
		3:
			return "TRIPLE " + direction
		4:
			return "QUAD " + direction
		_:
			return "ENDLESS " + direction

func _cut_jump() -> void:
	if _jump_cut_available and not _trick_active and not wingsuit_deployed and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
		_jump_cut_available = false

func toggle_wingsuit() -> void:
	if not alive or not wingsuit_unlocked or is_on_floor() or _trick_active:
		return
	_set_wingsuit(not wingsuit_deployed)

func _set_wingsuit(deployed: bool) -> void:
	if wingsuit_deployed == deployed:
		return
	wingsuit_deployed = deployed
	if deployed:
		_deploy_timer = 0.55
		_trick_active = false
		_spin_accumulated = 0.0
		_wing_rotation = _air_rotation
		AudioManager.play_sfx("wingsuit_open")
	else:
		_deploy_timer = 0.0
		AudioManager.play_sfx("wingsuit_close")
	wingsuit_changed.emit(deployed)

func perform_rock_bounce() -> void:
	if not alive:
		return
	velocity = Vector2(maxf(velocity.x, 340.0), -840.0)
	run_speed = velocity.x
	_takeoff_rotation = _air_rotation
	_air_rotation = _takeoff_rotation
	_jump_cut_available = false
	_jump_hold_timer = 0.0
	_spin_accumulated = 0.0
	_trick_active = false
	_airborne_time = 0.0
	_chasm_jump = false
	_spawn_dust(14, 1.4)
	_impact_ring = 0.34
	_impact_color = Color(1.0, 0.92, 0.64)
	rock_bounced.emit()

func crash(reason: String) -> void:
	if not alive:
		return
	alive = false
	_crash_reason = reason
	_crash_timer = CRASH_DURATION
	_crash_tumble = 0.0
	velocity = Vector2(-120.0, -380.0) if reason == "rock" else velocity * 0.5
	_spawn_dust(20, 1.8)
	AudioManager.play_sfx("crash")
	crashed.emit(reason)
	queue_redraw()

func _update_crash(delta: float) -> void:
	_crash_timer -= delta
	_crash_tumble += delta * 4.2
	velocity.y += AIR_GRAVITY * 0.55 * delta
	global_position += velocity * delta
	art.rotation = _crash_tumble
	art.animation_state = "crash"
	art.position = Vector2(0.0, -44.0)
	if _crash_timer <= 0.0:
		alive = false
		set_physics_process(false)
		died.emit(_crash_reason)

func _update_crash_timer_only(_delta: float) -> void:
	pass

func _update_art(delta: float) -> void:
	if not alive:
		return
	art.position = Vector2(0.0, -44.0)
	var state := "ride"
	if wingsuit_deployed:
		state = "wingsuit_deploy" if _deploy_timer > 0.25 else "wingsuit"
		art.rotation = lerp_angle(art.rotation, _wing_rotation, 1.0 - exp(-9.0 * delta))
	elif is_on_floor():
		if _was_wingsuit_landing and _landing_timer > 0.0:
			state = "wingsuit_land"
		elif _landing_timer > 0.0:
			state = "perfect" if _landing_rating == "perfect" and _landing_timer > 0.10 else "land"
		elif _sliding or speed_ratio() > 0.72:
			state = "accelerate"
		else:
			state = "ride"
		if _landing_timer <= 0.0:
			_was_wingsuit_landing = false
		art.rotation = lerp_angle(art.rotation, _ground_angle, 1.0 - exp(-16.0 * delta))
	else:
		if _trick_active:
			state = "flip"
		elif velocity.y > 380.0:
			state = "fall"
		else:
			state = "jump"
		art.rotation = lerp_angle(art.rotation, _air_rotation, 1.0 - exp(-22.0 * delta))
	art.speed_ratio = speed_ratio()
	art.boost = 1.0 if _landing_rating == "perfect" and _landing_timer > 0.1 else 0.0
	art.set_animation_state(state)

func speed_ratio() -> float:
	return clampf((run_speed - MIN_RUN_SPEED) / (MAX_RUN_SPEED - MIN_RUN_SPEED), 0.0, 1.0)

func _forward_tangent(normal: Vector2) -> Vector2:
	var tangent := Vector2(-normal.y, normal.x).normalized()
	if tangent.x < 0.0:
		tangent = -tangent
	return tangent

func _is_over_gap(x: float) -> bool:
	if is_instance_valid(world) and world.has_method("is_gap_at"):
		return bool(world.call("is_gap_at", x))
	return false

func _is_falling_out_of_world() -> bool:
	if global_position.y > 2400.0 and not is_instance_valid(world):
		return true
	if is_instance_valid(world) and world.has_method("kill_y_at"):
		return global_position.y > float(world.call("kill_y_at", global_position.x))
	return false

# --------------------------------------------------------------------------
# Dust, trail and impact feedback
# --------------------------------------------------------------------------

func _update_dust(delta: float) -> void:
	_dust_timer -= delta
	if is_on_floor() and alive and not wingsuit_deployed and run_speed > 260.0 and _dust_timer <= 0.0:
		_dust_timer = 0.045 if _sliding or run_speed > 520.0 else 0.075
		_spawn_dust(1 if run_speed < 460.0 else 2, 0.55 + speed_ratio() * 0.55)
	for particle in _dust:
		particle.position += particle.velocity * delta
		particle.velocity.y += 80.0 * delta
		particle.velocity.x *= 1.0 - 1.4 * delta
		particle.life -= delta
	for i in range(_dust.size() - 1, -1, -1):
		if _dust[i].life <= 0.0:
			_dust.remove_at(i)

func _spawn_dust(count: int, strength: float) -> void:
	if _palette.is_empty():
		_palette = HavenTheme.palette_at(global_position.x)
	for i in range(count):
		var seed := float(_dust.size() + i) * 2.17 + _time * 7.0
		var offset := Vector2(-18.0 - HavenTheme.hash01(seed) * 24.0, -4.0 + HavenTheme.hash01(seed + 2.0) * 4.0)
		var color: Color = _palette.sand_hi if i % 2 == 0 else _palette.rim
		_dust.append({
			"position": global_position + offset,
			"velocity": Vector2(
				-run_speed * (0.10 + HavenTheme.hash01(seed + 4.0) * 0.18),
				-24.0 - HavenTheme.hash01(seed + 7.0) * 50.0 * strength
			),
			"life": 0.35 + HavenTheme.hash01(seed + 9.0) * 0.55,
			"max_life": 0.35 + HavenTheme.hash01(seed + 9.0) * 0.55,
			"size": 2.0 + HavenTheme.hash01(seed + 11.0) * 5.0 * strength,
			"color": color,
		})

func _draw() -> void:
	# Contact shadow projects onto the sand and softens with altitude.
	var shadow_y := 2.0
	var shadow_radius := 31.0
	var shadow_alpha := 0.20
	if not is_on_floor() and is_instance_valid(world):
		var height: float = maxf(0.0, float(world.call("ground_height", global_position.x)) - global_position.y)
		shadow_y = clampf(height + 2.0, 2.0, 520.0)
		var fade := clampf(1.0 - height / 420.0, 0.18, 1.0)
		shadow_radius *= lerpf(0.55, 1.0, fade)
		shadow_alpha *= fade
	draw_set_transform(Vector2(0.0, shadow_y), 0.0, Vector2(1.0, 0.24))
	draw_circle(Vector2.ZERO, shadow_radius, Color(0.04, 0.04, 0.06, shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for particle in _dust:
		var local: Vector2 = particle.position - global_position
		var alpha := clampf(particle.life / particle.max_life, 0.0, 1.0)
		var color: Color = particle.color
		draw_circle(local, particle.size * (1.2 - alpha * 0.35), Color(color.r, color.g, color.b, alpha * 0.24))
	if _impact_ring > 0.0:
		var total := 0.30
		var t := 1.0 - clampf(_impact_ring / total, 0.0, 1.0)
		draw_arc(Vector2(0.0, 0.0), 18.0 + t * 42.0, PI * 1.05, PI * 1.95, 22, Color(_impact_color.r, _impact_color.g, _impact_color.b, (1.0 - t) * 0.55), 2.0, true)
	if _landing_flash > 0.0:
		var alpha := _landing_flash / 0.20
		draw_arc(Vector2(0.0, 0.0), 22.0 + (1.0 - alpha) * 40.0, PI * 1.08, PI * 1.92, 20, Color(1.0, 0.88, 0.62, alpha * 0.4), 1.5, true)
	if alive and not is_on_floor() and run_speed > 520.0 and not wingsuit_deployed:
		for i in range(2):
			var y := -22.0 + float(i) * 18.0
			draw_line(Vector2(-54.0 - float(i) * 8.0, y), Vector2(-24.0, y + 1.0), Color(1.0, 0.9, 0.7, 0.10), 1.0, true)
