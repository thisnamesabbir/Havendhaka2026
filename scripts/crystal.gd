extends Area2D

signal collected(value: int)

var echo_hidden := false
var _time := 0.0

func _ready() -> void:
	add_to_group("crystals")
	if echo_hidden:
		add_to_group("hidden_crystals")
	visible = not echo_hidden
	monitoring = not echo_hidden
	monitorable = not echo_hidden
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func set_echo_active(active: bool) -> void:
	if not echo_hidden:
		return
	visible = active
	monitoring = active
	monitorable = active

func _draw() -> void:
	var bob := sin(_time * 3.2) * 5.0
	var glow := Color(0.35, 0.95, 1.0, 0.1 + (sin(_time * 4.0) + 1.0) * 0.07)
	draw_circle(Vector2(0.0, bob), 24.0, glow)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -16.0 + bob), Vector2(11.0, bob), Vector2(0.0, 16.0 + bob), Vector2(-11.0, bob)
	]), Color(0.38, 0.94, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -16.0 + bob), Vector2(0.0, 16.0 + bob), Vector2(-11.0, bob)
	]), Color(0.82, 1.0, 1.0, 0.85))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collected.emit(1)
		queue_free()
