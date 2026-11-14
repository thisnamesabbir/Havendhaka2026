extends Area2D
class_name DesertPickup

signal collected(kind: String, value: int, world_position: Vector2)

var kind := "coin"
var value := 1
var palette: Dictionary
var phase := 0.0
var _time := 0.0
var _taken := false
var _collect_time := 0.0
var _base_position := Vector2.ZERO

func setup(pickup_kind: String, colors: Dictionary, pickup_value: int, phase_value: float = 0.0) -> void:
	kind = pickup_kind
	value = pickup_value
	palette = colors
	phase = phase_value
	z_index = 5
	add_to_group("collectibles")

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = 17.0 if kind == "coin" else 20.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	_base_position = position
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	if _taken:
		_collect_time += delta
		var t := clampf(_collect_time / 0.24, 0.0, 1.0)
		scale = Vector2.ONE * (1.0 + t * 0.55)
		modulate = Color(1.0, 1.0, 1.0, 1.0 - t)
		if t >= 1.0:
			queue_free()
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	collected.emit(kind, value, global_position)
	AudioManager.play_sfx("coin" if kind == "coin" else "shard")

func _draw() -> void:
	if _taken:
		_draw_collect_ring()
		return
	var bob := sin(_time * 2.6 + phase) * 5.0
	match kind:
		"shard":
			_draw_shard(Vector2(0.0, bob))
		_:
			_draw_coin(Vector2(0.0, bob))

func _draw_coin(offset: Vector2) -> void:
	var gold: Color = Color(1.0, 0.80, 0.37) if palette.is_empty() else palette.accent.lerp(Color(1.0, 0.84, 0.45), 0.55)
	var hot: Color = Color(1.0, 0.95, 0.78)
	var deep: Color = Color(0.69, 0.41, 0.14)
	var squash := 0.30 + 0.70 * absf(cos(_time * 2.1 + phase))
	draw_circle(offset, 21.0, Color(gold.r, gold.g, gold.b, 0.055))
	draw_set_transform(offset, sin(_time * 1.3 + phase) * 0.05, Vector2(squash, 1.0))
	draw_circle(Vector2.ZERO, 10.5, Color(deep.r, deep.g, deep.b, 0.95))
	draw_circle(Vector2.ZERO, 8.8, gold)
	draw_circle(Vector2(-1.5, -1.8), 6.8, Color(hot.r, hot.g, hot.b, 0.44))
	draw_arc(Vector2.ZERO, 8.2, 0.0, TAU, 24, Color(deep.r, deep.g, deep.b, 0.65), 1.0, true)
	# A tiny four-point sun embossed in the centre.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -5.2), Vector2(1.4, -1.4), Vector2(5.2, 0.0), Vector2(1.4, 1.4),
		Vector2(0.0, 5.2), Vector2(-1.4, 1.4), Vector2(-5.2, 0.0), Vector2(-1.4, -1.4),
	]), Color(deep.r, deep.g, deep.b, 0.85))
	draw_circle(Vector2.ZERO, 1.5, Color(1.0, 0.98, 0.88, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_line(offset + Vector2(-17.0, 15.0), offset + Vector2(-8.0, 18.0), Color(1.0, 0.83, 0.48, 0.18), 1.2, true)

func _draw_shard(offset: Vector2) -> void:
	var cyan: Color = Color(0.47, 0.94, 0.98)
	var pale: Color = Color(0.83, 1.0, 1.0)
	var deep: Color = Color(0.18, 0.51, 0.66)
	var pulse := 0.5 + 0.5 * sin(_time * 2.2 + phase)
	draw_circle(offset, 32.0 + pulse * 5.0, Color(cyan.r, cyan.g, cyan.b, 0.045 + pulse * 0.028))
	draw_circle(offset, 16.0, Color(cyan.r, cyan.g, cyan.b, 0.09))
	var points := PackedVector2Array([
		offset + Vector2(0.0, -19.0), offset + Vector2(11.0, -2.0),
		offset + Vector2(0.0, 19.0), offset + Vector2(-11.0, -2.0),
	])
	draw_colored_polygon(points, Color(deep.r, deep.g, deep.b, 0.92))
	draw_colored_polygon(PackedVector2Array([
		offset + Vector2(0.0, -17.0), offset + Vector2(8.5, -2.0),
		offset + Vector2(0.0, 14.0), offset + Vector2(-8.5, -2.0),
	]), cyan)
	draw_colored_polygon(PackedVector2Array([
		offset + Vector2(0.0, -17.0), offset + Vector2(8.5, -2.0),
		offset + Vector2(0.0, -1.0), offset + Vector2(-8.5, -2.0),
	]), Color(pale.r, pale.g, pale.b, 0.58))
	draw_line(offset + Vector2(0.0, -13.0), offset + Vector2(0.0, 12.0), Color(pale.r, pale.g, pale.b, 0.38), 1.0, true)
	for i in range(4):
		var angle := float(i) * PI * 0.5 + _time * 0.45
		var p := offset + Vector2.from_angle(angle) * (23.0 + pulse * 4.0)
		draw_circle(p, 1.3, Color(pale.r, pale.g, pale.b, 0.45 + pulse * 0.2))

func _draw_collect_ring() -> void:
	var t := clampf(_collect_time / 0.24, 0.0, 1.0)
	var color: Color = Color(1.0, 0.83, 0.45) if kind == "coin" else Color(0.52, 0.96, 1.0)
	draw_arc(Vector2.ZERO, 12.0 + t * 26.0, 0.0, TAU, 24, Color(color.r, color.g, color.b, (1.0 - t) * 0.55), 2.0, true)
