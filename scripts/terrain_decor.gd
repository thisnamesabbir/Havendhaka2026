extends Node2D

## Non-colliding mid-ground scenery that sits behind the rider.

var kind := "palm"
var palette: Dictionary
var alpha := 0.8
var art_seed := 0.0

func setup(kind_name: String, colors: Dictionary, scale_value: float, alpha_value: float, seed_value: float) -> void:
	kind = kind_name
	palette = colors
	scale = Vector2(scale_value, scale_value)
	alpha = alpha_value
	art_seed = seed_value
	z_index = 1
	queue_redraw()

func _draw() -> void:
	if palette.is_empty():
		return
	match kind:
		"palm":
			_draw_palm()
		"cactus":
			_draw_cactus()
		"ruins":
			_draw_ruin()
		"tent":
			_draw_tent()
		"deadwood":
			_draw_deadwood()
		"pine":
			_draw_pine()
		"lantern":
			_draw_lantern()
		"reeds":
			_draw_reeds()
		_:
			_draw_rocks()

func _ink(darken_amount: float = 0.18) -> Color:
	var color: Color = (palette.sand_low as Color).darkened(darken_amount).lerp(palette.mid as Color, 0.18)
	return Color(color.r, color.g, color.b, alpha * 0.88)

func _rim() -> Color:
	var color: Color = palette.rim
	return Color(color.r, color.g, color.b, alpha * 0.38)

func _shadow(width: float, height: float = 6.0) -> void:
	var color: Color = palette.dune_shadow
	draw_set_transform(Vector2(0.0, 0.0), 0.0, Vector2(1.0, height / maxf(width, 1.0)))
	draw_circle(Vector2.ZERO, width, Color(color.r, color.g, color.b, alpha * 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_palm() -> void:
	_shadow(25.0, 5.0)
	var ink := _ink(0.25)
	var top := Vector2(3.0 + sin(art_seed) * 3.0, -62.0)
	var trunk := PackedVector2Array([
		Vector2(-2.4, 0.0), Vector2(-1.2, -20.0), Vector2(0.3, -42.0),
		top + Vector2(-1.2, 1.0), top + Vector2(1.4, 0.0), Vector2(1.6, -38.0),
		Vector2(1.4, -16.0), Vector2(2.4, 0.0),
	])
	draw_colored_polygon(trunk, ink)
	for i in range(7):
		var angle := -PI * 0.92 + float(i) / 6.0 * PI * 0.84
		var length := 28.0 + HavenTheme.hash01(art_seed + float(i) * 1.7) * 15.0
		var end := top + Vector2(cos(angle) * length, sin(angle) * length * 0.70 - 7.0)
		var mid := (top + end) * 0.5 + Vector2(0.0, -8.0)
		var control := top.lerp(end, 0.5)
		var frond := PackedVector2Array([top, control + Vector2(0.0, -8.0), end, control + Vector2(0.0, 1.5)])
		draw_colored_polygon(frond, Color(ink.r, ink.g, ink.b, alpha * 0.92))
		draw_line(top, end, Color(ink.r, ink.g, ink.b, alpha * 0.7), 1.4, true)
	draw_circle(top, 2.6, ink)
	draw_circle(top - Vector2(1.0, 1.0), 1.0, _rim())

func _draw_cactus() -> void:
	_shadow(15.0, 4.0)
	var ink := _ink(0.12)
	var body := PackedVector2Array([
		Vector2(-8.0, 0.0), Vector2(-8.0, -42.0), Vector2(-3.0, -50.0),
		Vector2(3.0, -50.0), Vector2(8.0, -42.0), Vector2(8.0, 0.0),
	])
	draw_colored_polygon(body, ink)
	var arm_l := PackedVector2Array([
		Vector2(-8.0, -22.0), Vector2(-20.0, -22.0), Vector2(-23.0, -27.0),
		Vector2(-20.0, -38.0), Vector2(-14.0, -38.0), Vector2(-12.0, -32.0),
		Vector2(-14.0, -28.0), Vector2(-8.0, -28.0),
	])
	var arm_r := PackedVector2Array([
		Vector2(8.0, -30.0), Vector2(18.0, -30.0), Vector2(21.0, -35.0),
		Vector2(18.0, -46.0), Vector2(12.0, -46.0), Vector2(10.0, -40.0),
		Vector2(12.0, -36.0), Vector2(8.0, -36.0),
	])
	draw_colored_polygon(arm_l, ink)
	draw_colored_polygon(arm_r, ink)
	for i in range(7):
		var x := -6.0 + float(i) * 2.0
		draw_line(Vector2(x, -10.0 - float(i % 3) * 11.0), Vector2(x + 2.0, -13.0 - float(i % 3) * 11.0), _rim(), 0.8, true)
	draw_line(Vector2(-7.0, -3.0), Vector2(-7.0, -46.0), _rim(), 1.2, true)

func _draw_ruin() -> void:
	_shadow(30.0, 5.0)
	var ink := _ink(0.10)
	var stone: Color = palette.sand_mid.lerp(palette.mid, 0.35)
	stone.a = alpha * 0.90
	var base := PackedVector2Array([
		Vector2(-24.0, 0.0), Vector2(-20.0, -7.0), Vector2(-13.0, -9.0),
		Vector2(15.0, -8.0), Vector2(24.0, 0.0),
	])
	draw_colored_polygon(base, stone)
	draw_rect(Rect2(-8.0, -54.0, 16.0, 47.0), ink)
	draw_rect(Rect2(-12.0, -59.0, 24.0, 6.0), ink)
	draw_line(Vector2(-22.0, -8.0), Vector2(-16.0, -42.0), Color(ink.r, ink.g, ink.b, alpha * 0.65), 8.0, true)
	var broken := PackedVector2Array([
		Vector2(-8.0, -54.0), Vector2(-4.0, -50.0), Vector2(4.0, -53.0),
		Vector2(8.0, -47.0), Vector2(8.0, -42.0), Vector2(-8.0, -42.0),
	])
	draw_colored_polygon(broken, ink)
	draw_line(Vector2(-7.0, -52.0), Vector2(-7.0, -12.0), _rim(), 1.0, true)
	draw_line(Vector2(-18.0, -9.0), Vector2(-14.0, -42.0), _rim(), 0.8, true)
	for i in range(3):
		var y := -16.0 - float(i) * 9.0
		draw_line(Vector2(-5.0, y), Vector2(5.0, y + 1.0), Color(ink.r, ink.g, ink.b, alpha * 0.35), 1.0, true)

func _draw_tent() -> void:
	_shadow(30.0, 5.0)
	var ink := _ink(0.16)
	var shape := PackedVector2Array([
		Vector2(-32.0, 0.0), Vector2(0.0, -37.0), Vector2(35.0, 0.0),
		Vector2(19.0, 0.0), Vector2(0.0, -13.0), Vector2(-17.0, 0.0),
	])
	draw_colored_polygon(shape, ink)
	draw_line(Vector2(-34.0, 0.0), Vector2(0.0, -38.0), _rim(), 1.0, true)
	draw_line(Vector2(0.0, -38.0), Vector2(36.0, 0.0), _rim(), 0.8, true)
	var flag_color: Color = palette.accent
	draw_line(Vector2(0.0, -38.0), Vector2(0.0, -52.0), Color(ink.r, ink.g, ink.b, alpha), 1.2, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -52.0), Vector2(12.0, -47.0), Vector2(0.0, -43.0)
	]), Color(flag_color.r, flag_color.g, flag_color.b, alpha * 0.72))
	draw_line(Vector2(-20.0, 0.0), Vector2(-6.0, -14.0), Color(ink.r, ink.g, ink.b, alpha * 0.55), 1.0, true)

func _draw_deadwood() -> void:
	_shadow(16.0, 3.0)
	var ink := _ink(0.22)
	draw_line(Vector2(0.0, 0.0), Vector2(-1.0, -55.0), ink, 3.0, true)
	for i in range(5):
		var y := -14.0 - float(i) * 9.0
		var direction := -1.0 if i % 2 == 0 else 1.0
		var length := 16.0 + float(i % 3) * 6.0
		draw_line(Vector2(-1.0, y), Vector2(-1.0 + direction * length, y - 14.0), ink, 2.0, true)
		draw_line(
			Vector2(-1.0 + direction * length * 0.55, y - 7.0),
			Vector2(-1.0 + direction * length * 0.9, y - 16.0),
			ink,
			1.2,
			true
		)
	draw_line(Vector2(-2.0, -20.0), Vector2(-1.0, -52.0), _rim(), 0.8, true)

func _draw_pine() -> void:
	_shadow(17.0, 3.0)
	var ink := _ink(0.24)
	draw_rect(Rect2(-1.5, -18.0, 3.0, 18.0), ink)
	for i in range(4):
		var width := 22.0 - float(i) * 4.0
		var y := -15.0 - float(i) * 14.0
		var points := PackedVector2Array([
			Vector2(-width, y), Vector2(0.0, y - 27.0), Vector2(width, y),
			Vector2(0.0, y - 7.0),
		])
		draw_colored_polygon(points, ink)
		draw_line(Vector2(0.0, y - 27.0), Vector2(0.0, y), Color(ink.r, ink.g, ink.b, alpha * 0.4), 0.8, true)

func _draw_lantern() -> void:
	_shadow(7.0, 3.0)
	var ink := _ink(0.28)
	draw_line(Vector2(0.0, 0.0), Vector2(0.0, -52.0), ink, 2.0, true)
	var glow: Color = palette.accent
	draw_circle(Vector2(0.0, -55.0), 13.0, Color(glow.r, glow.g, glow.b, alpha * 0.10))
	draw_circle(Vector2(0.0, -55.0), 5.5, Color(glow.r, glow.g, glow.b, alpha * 0.55))
	draw_circle(Vector2(0.0, -55.0), 2.4, Color(1.0, 0.94, 0.75, alpha * 0.9))
	draw_line(Vector2(-8.0, -61.0), Vector2(8.0, -61.0), Color(ink.r, ink.g, ink.b, alpha * 0.8), 1.4, true)

func _draw_reeds() -> void:
	_shadow(12.0, 3.0)
	var ink := _ink(0.15)
	for i in range(7):
		var x := -10.0 + float(i) * 3.3
		var height := 35.0 + HavenTheme.hash01(art_seed + float(i)) * 24.0
		var bend := sin(art_seed + float(i) * 1.4) * 5.0
		draw_line(Vector2(x, 0.0), Vector2(x + bend, -height), Color(ink.r, ink.g, ink.b, alpha * 0.75), 1.2, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x + bend, -height),
			Vector2(x + bend - 2.3, -height + 8.0),
			Vector2(x + bend + 1.0, -height + 5.0),
		]), Color(ink.r, ink.g, ink.b, alpha * 0.8))

func _draw_rocks() -> void:
	_shadow(20.0, 4.0)
	var ink := _ink(0.28)
	for i in range(3):
		var offset := Vector2(-13.0 + float(i) * 12.0, 0.0)
		var w := 8.0 + HavenTheme.hash01(art_seed + float(i) * 2.3) * 7.0
		var h := 6.0 + HavenTheme.hash01(art_seed + float(i) * 4.1) * 9.0
		draw_colored_polygon(PackedVector2Array([
			offset + Vector2(-w, 0.0),
			offset + Vector2(-w * 0.55, -h),
			offset + Vector2(w * 0.45, -h * 0.8),
			offset + Vector2(w, 0.0),
		]), ink)
		draw_line(offset + Vector2(-w * 0.4, -h * 0.7), offset + Vector2(w * 0.1, -h * 0.85), _rim(), 0.8, true)
