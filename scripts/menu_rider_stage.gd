class_name MenuRiderStage
extends Control

## Presentation stage for the rider on the title screen. A painted halo,
## concentric sand rings and drifting motes frame the articulated character.

var rider: RiderArt
var _time := 0.0
var _palette: Dictionary = {}
var _target_scale := 2.2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_palette = HavenTheme.palette(0)
	rider = RiderArt.new()
	rider.name = "RiderArt"
	rider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rider)
	rider.apply_character(0)
	rider.set_animation_state("ride")
	rider.speed_ratio = 0.42
	resized.connect(_layout_rider)
	_layout_rider()

func set_character(index: int) -> void:
	if is_instance_valid(rider):
		rider.apply_character(index)
		rider.set_animation_state("ride")
		rider.speed_ratio = 0.45

func _layout_rider() -> void:
	if not is_instance_valid(rider):
		return
	var stage_size := size
	if stage_size.x < 10.0 or stage_size.y < 10.0:
		return
	_target_scale = clampf(minf(stage_size.x / 205.0, stage_size.y / 215.0), 1.55, 2.85)
	rider.scale = Vector2.ONE * _target_scale
	rider.position = Vector2(
		stage_size.x * 0.51,
		stage_size.y * 0.82 - 44.0 * _target_scale
	)

func _process(delta: float) -> void:
	_time += delta
	if is_instance_valid(rider):
		rider.position.x = size.x * 0.51 + sin(_time * 0.72) * 2.1
		rider.rotation = sin(_time * 0.54) * 0.012
		rider.speed_ratio = 0.42 + sin(_time * 0.63) * 0.08
	queue_redraw()

func _draw() -> void:
	if _palette.is_empty():
		return
	var stage := size
	if stage.x < 10.0 or stage.y < 10.0:
		return
	var center := Vector2(stage.x * 0.51, stage.y * 0.45)
	var base := Vector2(stage.x * 0.51, stage.y * 0.82)
	var accent: Color = _palette.accent
	var rim: Color = _palette.rim
	var deep: Color = _palette.sand_deep

	# Luminous halo.
	for i in range(11, 0, -1):
		var t := float(i) / 11.0
		var radius := stage.x * (0.13 + t * 0.30)
		var alpha := (1.0 - t) * 0.035 + 0.006
		draw_circle(center, radius, Color(accent.r, accent.g, accent.b, alpha))
	draw_circle(center, stage.x * 0.105, Color(accent.r, accent.g, accent.b, 0.10))
	draw_circle(center, stage.x * 0.075, Color(rim.r, rim.g, rim.b, 0.09))

	# Crown ring and fine orbital arcs.
	var ring_radius := stage.x * 0.31
	draw_arc(center, ring_radius, PI * 1.06, PI * 1.94, 72, Color(rim.r, rim.g, rim.b, 0.34), 1.1, true)
	draw_arc(center, ring_radius * 0.84, PI * 1.12, PI * 1.88, 64, Color(rim.r, rim.g, rim.b, 0.14), 1.0, true)
	draw_arc(center, ring_radius * 1.08, -0.55 + sin(_time * 0.2) * 0.08, 0.55 + sin(_time * 0.2) * 0.08, 48, Color(accent.r, accent.g, accent.b, 0.34), 1.4, true)

	# Vertical light shaft.
	for i in range(5):
		var width := 2.0 + float(i) * 4.0
		draw_rect(
			Rect2(Vector2(center.x - width * 0.5, stage.y * 0.04), Vector2(width, base.y - stage.y * 0.08)),
			Color(rim.r, rim.g, rim.b, 0.010 - float(i) * 0.0016)
		)

	# Sand disc and its rings.
	draw_set_transform(base, 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, stage.x * 0.30, Color(deep.r, deep.g, deep.b, 0.52))
	draw_circle(Vector2.ZERO, stage.x * 0.26, Color(accent.r * 0.45, accent.g * 0.38, accent.b * 0.34, 0.42))
	for i in range(4):
		var t := 0.30 + float(i) * 0.055
		draw_arc(Vector2.ZERO, stage.x * t, 0.0, TAU, 96, Color(rim.r, rim.g, rim.b, 0.18 - float(i) * 0.03), 1.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# A faint dune ridge behind the platform.
	var ridge := PackedVector2Array()
	var ridge_points := 26
	for i in range(ridge_points):
		var t := float(i) / float(ridge_points - 1)
		var x := stage.x * (0.08 + t * 0.84)
		var y := base.y - 8.0 + sin(t * 7.0 + _time * 0.15) * 7.0 + sin(t * 17.0 + 1.7) * 3.0
		ridge.append(Vector2(x, y))
	draw_polyline(ridge, Color(accent.r, accent.g, accent.b, 0.14), 1.2, true)

	# Wind motes.
	for i in range(26):
		var seed := float(i) * 6.71 + 2.3
		var speed := 0.08 + HavenTheme.hash01(seed + 3.0) * 0.11
		var px := fposmod(HavenTheme.hash01(seed) * stage.x + _time * stage.x * speed, stage.x)
		var py := stage.y * (0.18 + HavenTheme.hash01(seed + 4.0) * 0.58)
		var drift := sin(_time * (0.5 + HavenTheme.hash01(seed + 8.0)) + seed) * 10.0
		var alpha := 0.10 + HavenTheme.hash01(seed + 11.0) * 0.20
		var radius := 0.8 + HavenTheme.hash01(seed + 13.0) * 1.8
		draw_circle(Vector2(px + drift, py), radius, Color(rim.r, rim.g, rim.b, alpha))
