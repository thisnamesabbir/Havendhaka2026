extends Area2D
class_name DesertObstacle

## A readable, hand-shaped desert obstacle. Rocks are hazardous; wind stones
## bounce the rider into the air and are always worth steering toward.

var kind := "boulder"
var palette: Dictionary
var art_seed := 0.0
var size_scale := 1.0
var used := false
var _time := 0.0
var _collision: CollisionShape2D

func setup(
	kind_name: String,
	colors: Dictionary,
	scale_value: float = 1.0,
	seed_value: float = 0.0
) -> void:
	kind = kind_name
	palette = colors
	size_scale = scale_value
	art_seed = seed_value
	z_index = 4
	scale = Vector2.ONE * scale_value
	add_to_group("obstacles")

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = _collision_radius()
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	_collision.position = Vector2(0.0, _collision_offset_y())
	add_child(_collision)
	body_entered.connect(_on_body_entered)
	if kind == "bounce":
		set_process(true)
	else:
		set_process(false)
	queue_redraw()

func _collision_radius() -> float:
	match kind:
		"pillar":
			return 23.0
		"bounce":
			return 25.0
		_:
			return 25.0

func _collision_offset_y() -> float:
	match kind:
		"pillar":
			return -34.0
		_:
			return -20.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if used or not body.is_in_group("player"):
		return
	if kind == "bounce":
		if body.has_method("perform_rock_bounce"):
			used = true
			set_deferred("monitoring", false)
			body.call("perform_rock_bounce")
			AudioManager.play_sfx("rock_bounce")
			queue_redraw()
		return
	if body.has_method("crash"):
		body.call("crash", "rock")

func _draw() -> void:
	match kind:
		"pillar":
			_draw_pillar()
		"bounce":
			_draw_wind_stone()
		_:
			_draw_boulder()

func _shadow(width: float, height: float) -> void:
	var shadow_color: Color = palette.dune_shadow
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, height / maxf(width, 1.0)))
	draw_circle(Vector2.ZERO, width, Color(shadow_color.r, shadow_color.g, shadow_color.b, 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _rock_points(width: float, height: float, points_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(points_count):
		var angle := PI + float(i) / float(points_count - 1) * PI
		var wobble := 0.78 + HavenTheme.hash01(art_seed + float(i) * 2.17) * 0.30
		points.append(Vector2(cos(angle) * width * wobble, sin(angle) * height * wobble))
	points.append(Vector2(width * 0.82, 1.0))
	points.append(Vector2(-width * 0.82, 1.0))
	return points

func _draw_boulder() -> void:
	_shadow(27.0, 5.0)
	var dark: Color = palette.sand_low
	var body_color := Color(dark.r * 0.78, dark.g * 0.73, dark.b * 0.78, 0.98)
	var points := _rock_points(23.0, 23.0, 8)
	draw_colored_polygon(points, body_color)
	var highlight := PackedVector2Array([
		points[2], points[3], points[4], Vector2(points[4].x * 0.55, points[4].y * 0.62),
		Vector2(points[2].x * 0.45, points[2].y * 0.55),
	])
	draw_colored_polygon(highlight, Color(palette.rim.r, palette.rim.g, palette.rim.b, 0.18))
	draw_polyline(points, Color(palette.sand_deep.r, palette.sand_deep.g, palette.sand_deep.b, 0.55), 1.4, true)
	# Fracture lines and dust.
	draw_polyline(PackedVector2Array([
		Vector2(-10.0, -8.0), Vector2(-2.0, -14.0), Vector2(4.0, -9.0), Vector2(14.0, -12.0)
	]), Color(palette.sand_deep.r, palette.sand_deep.g, palette.sand_deep.b, 0.45), 1.0, true)
	for i in range(3):
		var x := -14.0 + float(i) * 10.0
		draw_circle(Vector2(x, -1.0 + sin(float(i)) * 1.5), 1.2, Color(dark.r, dark.g, dark.b, 0.5))

func _draw_pillar() -> void:
	_shadow(25.0, 5.0)
	var stone: Color = palette.sand_mid.lerp(palette.sand_low, 0.45)
	var rim: Color = palette.rim
	var ink := Color(stone.r * 0.70, stone.g * 0.67, stone.b * 0.72, 0.98)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20.0, 0.0), Vector2(-16.0, -8.0), Vector2(15.0, -8.0),
		Vector2(22.0, 0.0), Vector2(16.0, 5.0), Vector2(-15.0, 5.0),
	]), ink)
	draw_rect(Rect2(-10.0, -68.0, 20.0, 62.0), ink)
	draw_rect(Rect2(-14.0, -72.0, 28.0, 7.0), ink)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14.0, -72.0), Vector2(-8.0, -76.0), Vector2(3.0, -74.0),
		Vector2(10.0, -78.0), Vector2(14.0, -68.0), Vector2(-14.0, -68.0),
	]), ink)
	draw_line(Vector2(-9.0, -66.0), Vector2(-9.0, -10.0), Color(rim.r, rim.g, rim.b, 0.20), 1.2, true)
	draw_line(Vector2(8.0, -65.0), Vector2(8.0, -10.0), Color(0.0, 0.0, 0.0, 0.20), 1.2, true)
	for i in range(4):
		var y := -16.0 - float(i) * 12.0
		draw_line(Vector2(-8.0, y), Vector2(8.0, y - 1.0), Color(palette.sand_low.r, palette.sand_low.g, palette.sand_low.b, 0.25), 1.0, true)
	# A tiny desert bloom at the base.
	draw_line(Vector2(-18.0, 0.0), Vector2(-21.0, -12.0), Color(stone.r, stone.g, stone.b, 0.8), 1.0, true)
	draw_circle(Vector2(-21.0, -12.0), 2.4, Color(palette.accent.r, palette.accent.g, palette.accent.b, 0.55))

func _draw_wind_stone() -> void:
	_shadow(29.0, 6.0)
	var glow: Color = palette.accent
	var pulse := 0.5 + 0.5 * sin(_time * 2.6 + art_seed)
	var points := _rock_points(25.0, 21.0, 9)
	var stone := Color(palette.sand_low.r * 0.72, palette.sand_low.g * 0.68, palette.sand_low.b * 0.75, 0.98)
	draw_circle(Vector2(0.0, -16.0), 36.0 + pulse * 6.0, Color(glow.r, glow.g, glow.b, 0.055 + pulse * 0.03))
	draw_colored_polygon(points, stone)
	draw_polyline(points, Color(glow.r, glow.g, glow.b, 0.30 + pulse * 0.18), 1.6, true)
	var sigil := PackedVector2Array([
		Vector2(0.0, -30.0), Vector2(7.0, -19.0), Vector2(0.0, -8.0), Vector2(-7.0, -19.0)
	])
	draw_colored_polygon(sigil, Color(glow.r, glow.g, glow.b, 0.28 + pulse * 0.18))
	draw_polyline(PackedVector2Array([sigil[0], sigil[1], sigil[2], sigil[3], sigil[0]]), Color(glow.r, glow.g, glow.b, 0.68), 1.5, true)
	draw_circle(Vector2(0.0, -19.0), 2.0, Color(1.0, 0.95, 0.82, 0.8))
	# Upward motes.
	for i in range(4):
		var phase := fposmod(_time * 0.5 + float(i) * 0.25, 1.0)
		var p := Vector2(sin(float(i) * 4.0 + _time) * 17.0, -30.0 - phase * 34.0)
		draw_circle(p, 1.2, Color(glow.r, glow.g, glow.b, (1.0 - phase) * 0.42))
	# Used stones lose their spark.
	if used:
		draw_line(Vector2(-12.0, -28.0), Vector2(12.0, -10.0), Color(0.05, 0.05, 0.08, 0.32), 2.0, true)
