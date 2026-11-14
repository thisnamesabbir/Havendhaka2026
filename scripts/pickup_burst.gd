extends Node2D

## Short-lived sparkle burst for pickups and landings.

var color := Color(1.0, 0.86, 0.5)
var _life := 0.0
var _max_life := 0.45
var _particles: Array[Dictionary] = []

func setup(burst_color: Color, count: int = 8, strength: float = 1.0) -> void:
	color = burst_color
	for i in range(count):
		var angle := TAU * float(i) / float(count) + HavenTheme.hash01(float(i) + 2.0) * 0.8
		var speed := (45.0 + HavenTheme.hash01(float(i) + 7.0) * 70.0) * strength
		_particles.append({
			"position": Vector2.ZERO,
			"velocity": Vector2.from_angle(angle) * speed + Vector2(0.0, -28.0),
			"size": 1.4 + HavenTheme.hash01(float(i) + 3.0) * 2.4,
			"spin": HavenTheme.hash01(float(i) + 9.0) * TAU,
		})
	z_index = 8

func _process(delta: float) -> void:
	_life += delta
	if _life >= _max_life:
		queue_free()
		return
	for particle in _particles:
		particle.position += particle.velocity * delta
		particle.velocity.y += 260.0 * delta
		particle.velocity *= 1.0 - 1.8 * delta
	queue_redraw()

func _draw() -> void:
	var t := clampf(_life / _max_life, 0.0, 1.0)
	var alpha := 1.0 - t
	for particle in _particles:
		var p: Vector2 = particle.position
		var size: float = particle.size * (1.0 - t * 0.7)
		var spin: float = particle.spin + t * 4.0
		var direction := Vector2.from_angle(spin)
		var normal := Vector2(-direction.y, direction.x)
		draw_colored_polygon(PackedVector2Array([
			p + direction * size * 1.8,
			p + normal * size * 0.5,
			p - direction * size * 0.8,
			p - normal * size * 0.5,
		]), Color(color.r, color.g, color.b, alpha * 0.8))
