class_name HavenCamera
extends Camera2D

## Cinematic side-scrolling camera. The horizon never rolls, framing opens up
## with speed and flight, and impacts feed a short, controlled shake.

@export var target_path: NodePath
@export var look_ahead_base := 118.0
@export var look_ahead_speed := 104.0
@export var vertical_offset := -178.0
@export var follow_x := 5.6
@export var follow_y := 3.4
@export var drift_strength := 5.0

var _target: Node2D
var _time := 0.0
var _shake := 0.0
var _shake_decay := 1.0
var _shake_phase := 0.0
var _landing_pulse := 0.0
var _zoom := 1.0
var _resume_position := Vector2.ZERO


func _ready() -> void:
	position_smoothing_enabled = false
	rotation = 0.0
	ignore_rotation = true
	make_current()
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node2D
	if is_instance_valid(_target):
		snap_to_target()


func snap_to_target() -> void:
	if not is_instance_valid(_target):
		return
	global_position = _target.global_position + Vector2(look_ahead_base, vertical_offset)
	_zoom = 1.0
	zoom = Vector2.ONE


func _process(delta: float) -> void:
	_time += delta
	_landing_pulse = maxf(0.0, _landing_pulse - delta * 3.2)
	_shake = maxf(0.0, _shake - delta * _shake_decay)
	if not is_instance_valid(_target):
		return
	var velocity: Vector2 = _target.get("velocity")
	var speed: float = float(_target.get("run_speed"))
	var ratio := clampf(speed / 860.0, 0.0, 1.25)
	var wingsuit := bool(_target.get("wingsuit_deployed"))
	var airborne: bool = not _target.is_on_floor()
	var ahead := look_ahead_base + look_ahead_speed * clampf(ratio, 0.0, 1.0)
	if wingsuit:
		ahead += 72.0
	var vertical := vertical_offset + clampf(velocity.y * 0.075, -34.0, 58.0)
	if wingsuit:
		vertical += 22.0
	if airborne:
		vertical -= 8.0
	var drift := Vector2(
		sin(_time * 0.62) * drift_strength,
		cos(_time * 0.91) * drift_strength * 0.55
	)
	var desired := _target.global_position + Vector2(ahead, vertical) + drift
	var smooth_x := 1.0 - exp(-follow_x * delta)
	var smooth_y := 1.0 - exp(-follow_y * delta)
	global_position.x = lerpf(global_position.x, desired.x, smooth_x)
	global_position.y = lerpf(global_position.y, desired.y, smooth_y)
	var desired_zoom := 1.0
	desired_zoom -= ratio * 0.075
	if wingsuit:
		desired_zoom -= 0.095
	if airborne and not wingsuit:
		desired_zoom += 0.018
	desired_zoom -= _landing_pulse * 0.045
	_zoom = lerpf(_zoom, desired_zoom, 1.0 - exp(-2.6 * delta))
	zoom = Vector2.ONE * _zoom
	# Stable horizon; positional shake only, no rotation.
	offset = Vector2(
		sin(_time * 56.0 + _shake_phase) * _shake * 1.1,
		cos(_time * 71.0 + _shake_phase * 1.7) * _shake * 0.72
	)
	if not airborne and _shake > 0.0:
		offset.y += sin(_time * 34.0) * _shake * 0.28


func shake(strength: float, duration: float) -> void:
	var scale := 1.0
	if is_instance_valid(SaveData):
		scale = clampf(SaveData.get_setting("screen_shake"), 0.0, 1.0)
	_shake = maxf(_shake, clampf(strength, 0.0, 22.0) * scale)
	_shake_decay = maxf(4.0, 18.0 / maxf(duration, 0.05))
	_shake_phase = randf_range(0.0, TAU)


func landing_pulse(strength: float = 1.0) -> void:
	_landing_pulse = clampf(strength, 0.0, 1.4)


func set_target(target: Node2D) -> void:
	_target = target
	snap_to_target()
