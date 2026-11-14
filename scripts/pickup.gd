extends Area2D

signal collected(kind: String, value: int, world_position: Vector2)

const GLOW_TEXTURE := preload("res://assets/generated/glow.png")
const SPARKLE_TEXTURE := preload("res://assets/generated/sparkle.png")

@export var kind := "coin"
@export var value := 1
@export var accent := Color("ffcf86")

var _time := 0.0
var _base_position := Vector2.ZERO
var _collected := false
var _glow: Sprite2D
var _phase := 0.0

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 23.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_base_position = position
	_phase = fposmod(position.x * 0.013 + position.y * 0.007, TAU)
	_glow = Sprite2D.new()
	_glow.texture = GLOW_TEXTURE
	_glow.modulate = Color(accent, 0.32 if kind == "coin" else 0.5)
	_glow.scale = Vector2(0.16, 0.16) if kind == "coin" else Vector2(0.32, 0.32)
	_glow.z_index = -1
	add_child(_glow)
	z_index = 3

func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	var bob := sin(_time * 2.8 + _phase) * (3.2 if kind == "coin" else 5.0)
	position.y = _base_position.y + bob
	queue_redraw()

func _draw() -> void:
	if kind == "coin":
		var spin := 0.65 + 0.35 * absf(cos(_time * 1.9 + _phase))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(spin, 1.0))
		draw_circle(Vector2.ZERO, 16.5, Color(0.45, 0.26, 0.16, 0.30))
		draw_circle(Vector2(-0.8, -1.2), 15.2, Color(accent, 0.95))
		draw_circle(Vector2(-0.8, -1.2), 12.2, Color(1.0, 0.90, 0.58))
		draw_circle(Vector2(-1.4, -2.2), 9.6, Color(1.0, 0.97, 0.80))
		# A tiny sun/diamond mark stamped into the face.
		var mark := PackedVector2Array([
			Vector2(0.0, -7.0), Vector2(5.2, 0.0), Vector2(0.0, 7.0), Vector2(-5.2, 0.0)
		])
		draw_colored_polygon(mark, Color(0.72, 0.43, 0.19, 0.72))
		draw_polyline(PackedVector2Array([mark[0], mark[1], mark[2], mark[3], mark[0]]), Color(1.0, 0.96, 0.72, 0.65), 0.8, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var glint := 0.5 + 0.5 * sin(_time * 4.2 + _phase)
		var s := 6.0 + glint * 5.0
		draw_texture_rect(SPARKLE_TEXTURE, Rect2(Vector2(8.0 - s * 0.5, -15.0 - s * 0.5), Vector2(s, s)), false,
			Color(1.0, 0.98, 0.82, 0.30 + glint * 0.38))
	else:
		var pulse := 0.5 + 0.5 * sin(_time * 2.4 + _phase)
		draw_circle(Vector2.ZERO, 19.0 + pulse * 3.0, Color(accent, 0.08))
		var tip := Vector2(0.0, -24.0 - pulse * 2.0)
		var left := Vector2(-12.0, -3.0)
		var right := Vector2(12.0, -3.0)
		var low := Vector2(0.0, 20.0)
		draw_colored_polygon(PackedVector2Array([tip, right, low, left]), Color(accent, 0.90))
		draw_colored_polygon(PackedVector2Array([tip, Vector2(4.0, -2.0), Vector2(0.0, 19.0), left]), Color(accent.lightened(0.22), 0.9))
		draw_polyline(PackedVector2Array([tip, right, low, left, tip]), Color(1.0, 0.98, 0.86, 0.75), 1.1, true)
		draw_circle(Vector2(-2.0, -7.0), 2.4, Color(1.0, 1.0, 1.0, 0.55))
		draw_texture_rect(SPARKLE_TEXTURE, Rect2(Vector2(14.0, -24.0), Vector2(12.0, 12.0)), false,
			Color(0.9, 0.98, 1.0, 0.4 + pulse * 0.3))

func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	monitoring = false
	collected.emit(kind, value, global_position)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.7, 1.7), 0.22)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.tween_property(_glow, "modulate:a", 0.0, 0.22)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
