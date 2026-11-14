extends Control
class_name HavenSky

## Painterly, fully procedural parallax sky and horizon used by both the
## gameplay scene and the main menu. Everything is drawn at the target
## resolution, so the artwork stays crisp on desktop, mobile and Web.

@export var player_path: NodePath
@export var menu_mode := false
@export var forced_biome := -1
@export var menu_travel_speed := 22.0

var _player: Node2D
var _elapsed := 0.0
var _menu_travel := 0.0
var _sky_textures: Array[GradientTexture2D] = []
var _glow_texture: ImageTexture
var _cloud_texture: ImageTexture
var _cloud_texture_big: ImageTexture
var _haze_texture: GradientTexture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	if not player_path.is_empty():
		_player = get_node_or_null(player_path) as Node2D
	for index in range(HavenTheme.PALETTES.size()):
		_sky_textures.append(_make_sky_texture(HavenTheme.PALETTES[index]))
	_glow_texture = _make_glow_texture(220)
	_cloud_texture = _make_cloud_texture(256, 120, 11.0)
	_cloud_texture_big = _make_cloud_texture(384, 150, 23.0)
	_haze_texture = _make_haze_texture()
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	_menu_travel += delta * menu_travel_speed
	queue_redraw()

func set_forced_biome(index: int) -> void:
	forced_biome = index
	queue_redraw()

func _travel() -> float:
	if is_instance_valid(_player):
		return _player.global_position.x
	if menu_mode:
		return _menu_travel
	return _elapsed * 30.0

func _world_x() -> float:
	if forced_biome >= 0:
		return float(forced_biome) * HavenTheme.BIOME_LENGTH + HavenTheme.BIOME_LENGTH * 0.38
	return _travel()

func _draw() -> void:
	var size := get_viewport_rect().size
	if size.x < 2.0 or size.y < 2.0:
		return
	var travel := _travel()
	var world_x := _world_x()
	var info := HavenTheme.transition_info(world_x)
	var pal := HavenTheme.palette_at(world_x)
	var index := int(info.index)
	var next_index := int(info.next_index)
	var cross := float(info.transition)

	_draw_sky(size, index, next_index, cross)
	_draw_stars(size, pal, travel)
	_draw_celestial(size, pal, world_x, travel)
	_draw_clouds(size, pal, travel)
	_draw_air_life(size, pal, travel)
	_draw_far_mountains(size, pal, travel)
	_draw_horizon_haze(size, pal)
	_draw_landmarks(size, pal, travel, str(info.kind), str(info.next_kind), cross)
	_draw_mid_mountains(size, pal, travel)
	_draw_landmarks_close(size, pal, travel, str(info.kind), str(info.next_kind), cross)
	_draw_near_dunes(size, pal, travel)
	_draw_foreground_veil(size, pal)

# --------------------------------------------------------------------------
# Sky colour and atmosphere
# --------------------------------------------------------------------------

func _draw_sky(size: Vector2, index: int, next_index: int, cross: float) -> void:
	draw_texture_rect(_sky_textures[index], Rect2(Vector2.ZERO, size), false)
	if cross > 0.001:
		draw_texture_rect(
			_sky_textures[next_index],
			Rect2(Vector2.ZERO, size),
			false,
			Color(1.0, 1.0, 1.0, cross)
		)

func _draw_stars(size: Vector2, pal: Dictionary, travel: float) -> void:
	var amount := float(pal.star_amount)
	if amount <= 0.01:
		return
	var horizon := size.y * 0.58
	var count := 118
	for i in range(count):
		var seed := float(i) + 3.13
		var sx := fposmod(HavenTheme.hash01(seed) * size.x + travel * 0.0015 * (0.4 + HavenTheme.hash01(seed + 6.0)), size.x + 20.0) - 10.0
		var sy := HavenTheme.hash01(seed + 11.0) * horizon * 0.92 + 12.0
		var twinkle := 0.55 + 0.45 * sin(_elapsed * (1.4 + HavenTheme.hash01(seed + 2.0) * 2.0) + seed)
		var radius := 0.7 + HavenTheme.hash01(seed + 8.0) * 1.4
		var warm := HavenTheme.hash01(seed + 17.0)
		var color := Color(0.83, 0.90, 1.0).lerp(Color(1.0, 0.89, 0.72), warm * 0.35)
		draw_circle(Vector2(sx, sy), radius, Color(color.r, color.g, color.b, amount * twinkle * 0.9))
		# A handful of hero stars get a soft cross-flare.
		if i % 23 == 0:
			draw_line(Vector2(sx - 5.0, sy), Vector2(sx + 5.0, sy), Color(color.r, color.g, color.b, amount * 0.22), 1.0, true)
			draw_line(Vector2(sx, sy - 5.0), Vector2(sx, sy + 5.0), Color(color.r, color.g, color.b, amount * 0.22), 1.0, true)
	# A faint diagonal river of stars.
	for i in range(46):
		var t := float(i) / 45.0
		var sx := size.x * (0.05 + t * 0.88)
		var sy := size.y * (0.10 + t * 0.30) + sin(t * 9.0) * 14.0
		var a := float(pal.star_amount) * (0.10 + HavenTheme.hash01(float(i) + 21.0) * 0.12)
		draw_circle(Vector2(sx, sy), 0.8 + HavenTheme.hash01(float(i) + 4.0), Color(0.78, 0.86, 1.0, a))

func _draw_celestial(size: Vector2, pal: Dictionary, world_x: float, _travel: float) -> void:
	var sun_alpha := float(pal.sun_alpha)
	var moon_alpha := float(pal.moon_alpha)
	var phase := fposmod(world_x, HavenTheme.BIOME_LENGTH) / HavenTheme.BIOME_LENGTH
	var sun_pos := Vector2(size.x * (0.74 + phase * 0.035), size.y * (0.22 + phase * 0.10))
	var moon_pos := Vector2(size.x * 0.72, size.y * 0.19)
	var sun_color: Color = pal.sun
	var glow_color: Color = pal.sun_glow
	var moon_color: Color = pal.moon
	var moon_glow: Color = pal.moon_glow

	if sun_alpha > 0.01:
		var halo := 1.0 + sin(_elapsed * 0.35) * 0.015
		draw_texture_rect(
			_glow_texture,
			Rect2(sun_pos - Vector2(230.0, 230.0) * halo, Vector2(460.0, 460.0) * halo),
			false,
			Color(glow_color.r, glow_color.g, glow_color.b, 0.48 * sun_alpha)
		)
		draw_texture_rect(
			_glow_texture,
			Rect2(sun_pos - Vector2(105.0, 105.0), Vector2(210.0, 210.0)),
			false,
			Color(sun_color.r, sun_color.g, sun_color.b, 0.45 * sun_alpha)
		)
		draw_circle(sun_pos, 35.0, Color(sun_color.r, sun_color.g, sun_color.b, sun_alpha * 0.92))
		draw_circle(sun_pos, 27.0, Color(1.0, 0.98, 0.90, sun_alpha * 0.95))
		# Long, restrained light rays.
		var ray_alpha := 0.055 * sun_alpha
		for i in range(12):
			var angle := float(i) * TAU / 12.0 + _elapsed * 0.012
			var inner := 48.0
			var outer := 180.0 + sin(_elapsed * 0.4 + float(i)) * 35.0
			var width := 0.035
			var a := sun_pos + Vector2.from_angle(angle - width) * inner
			var b := sun_pos + Vector2.from_angle(angle + width) * inner
			var c := sun_pos + Vector2.from_angle(angle) * outer
			draw_colored_polygon(
				PackedVector2Array([a, b, c]),
				Color(1.0, 0.86, 0.62, ray_alpha)
			)

	if moon_alpha > 0.01:
		draw_texture_rect(
			_glow_texture,
			Rect2(moon_pos - Vector2(125.0, 125.0), Vector2(250.0, 250.0)),
			false,
			Color(moon_glow.r, moon_glow.g, moon_glow.b, 0.30 * moon_alpha)
		)
		draw_circle(moon_pos, 27.0, Color(moon_color.r, moon_color.g, moon_color.b, moon_alpha))
		draw_circle(moon_pos + Vector2(7.0, -4.0), 23.0, Color(moon_color.r, moon_color.g, moon_color.b, moon_alpha))
		draw_circle(moon_pos + Vector2(14.0, -7.0), 22.0, Color(0.06, 0.09, 0.18, 0.18 * moon_alpha))
		for i in range(3):
			draw_circle(
				moon_pos + Vector2(-8.0 + float(i) * 9.0, 8.0 + sin(float(i)) * 5.0),
				2.2,
				Color(0.66, 0.73, 0.84, 0.28 * moon_alpha)
			)

func _draw_clouds(size: Vector2, pal: Dictionary, travel: float) -> void:
	var amount := float(pal.cloud_amount)
	if amount <= 0.01:
		return
	var cloud: Color = pal.cloud
	for i in range(9):
		var depth := 0.025 + HavenTheme.hash01(float(i) + 9.0) * 0.06
		var span := size.x * 1.45
		var x := fposmod(HavenTheme.hash01(float(i) + 4.0) * span - travel * depth, span) - span * 0.20
		var y := size.y * (0.11 + HavenTheme.hash01(float(i) + 14.0) * 0.28)
		var scale := 0.65 + HavenTheme.hash01(float(i) + 18.0) * 1.0
		var drift := sin(_elapsed * 0.06 + float(i) * 2.1) * 9.0
		var alpha := cloud.a * amount * (0.55 + HavenTheme.hash01(float(i) + 2.0) * 0.45)
		var tex := _cloud_texture if i % 3 != 0 else _cloud_texture_big
		var rect := Rect2(
			Vector2(x + drift, y),
			Vector2(300.0, 94.0) * scale
		)
		draw_texture_rect(tex, rect, false, Color(cloud.r, cloud.g, cloud.b, alpha))

func _draw_air_life(size: Vector2, pal: Dictionary, travel: float) -> void:
	var sun_amount := float(pal.sun_alpha)
	var night := float(pal.star_amount)
	if sun_amount > 0.15:
		_draw_balloons(size, pal, travel)
		_draw_birds(size, pal, travel)
	if night > 0.85:
		_draw_meteor(size, pal)
		_draw_moon_birds(size, pal, travel)

func _draw_balloons(size: Vector2, pal: Dictionary, travel: float) -> void:
	var count := 2
	for i in range(count):
		var speed := 0.06 + float(i) * 0.025
		var x := fposmod(float(i) * 470.0 + 260.0 + travel * speed + _elapsed * 4.0, size.x + 320.0) - 160.0
		var y := size.y * (0.30 + float(i) * 0.08) + sin(_elapsed * 0.14 + float(i) * 2.0) * 9.0
		var scale := 0.75 + float(i) * 0.18
		_draw_balloon(Vector2(x, y), scale, pal, 0.48 - float(i) * 0.13)

func _draw_balloon(pos: Vector2, scale: float, pal: Dictionary, alpha: float) -> void:
	var body_color: Color = (pal.mid as Color).lerp(pal.accent as Color, 0.42)
	var stripe_color: Color = (pal.accent as Color).lerp(Color.WHITE, 0.15)
	var dark: Color = pal.mid
	var w := 25.0 * scale
	var h := 31.0 * scale
	draw_line(pos + Vector2(-w * 0.45, h), pos + Vector2(-w * 0.25, h + 18.0 * scale), Color(dark.r, dark.g, dark.b, alpha), 1.2, true)
	draw_line(pos + Vector2(w * 0.45, h), pos + Vector2(w * 0.25, h + 18.0 * scale), Color(dark.r, dark.g, dark.b, alpha), 1.2, true)
	draw_rect(Rect2(pos + Vector2(-w * 0.28, h + 15.0 * scale), Vector2(w * 0.56, 7.0 * scale)), Color(dark.r, dark.g, dark.b, alpha))
	var points := PackedVector2Array()
	for i in range(22):
		var t := float(i) / 21.0 * TAU
		var xx := cos(t) * w
		var yy := sin(t) * h - h * 1.1
		if yy > 0.0:
			yy *= 0.55
		points.append(pos + Vector2(xx, yy))
	draw_colored_polygon(points, Color(body_color.r, body_color.g, body_color.b, alpha))
	# Painted vertical seam.
	for i in range(-1, 2):
		var top := pos + Vector2(float(i) * w * 0.30, -h * 1.55)
		var bottom := pos + Vector2(float(i) * w * 0.42, -h * 0.45)
		draw_line(top, bottom, Color(stripe_color.r, stripe_color.g, stripe_color.b, alpha * 0.42), 1.4, true)
	draw_circle(pos + Vector2(-w * 0.36, -h * 1.25), w * 0.11, Color(1.0, 0.9, 0.7, alpha * 0.32))
	draw_circle(pos, w * 1.35, Color(1.0, 0.78, 0.46, 0.035 * alpha))

func _draw_birds(size: Vector2, pal: Dictionary, travel: float) -> void:
	var ink: Color = (pal.mid as Color).lerp(Color.BLACK, 0.15)
	for i in range(5):
		var x := fposmod(travel * (0.07 + float(i) * 0.011) + float(i) * 173.0, size.x + 100.0) - 50.0
		var y := size.y * (0.22 + HavenTheme.hash01(float(i) + 31.0) * 0.12)
		y += sin(_elapsed * 0.55 + float(i)) * 5.0
		var flap := sin(_elapsed * 3.2 + float(i) * 1.7) * 3.0
		var s := 4.0 + float(i % 3)
		draw_polyline(
			PackedVector2Array([
				Vector2(x - s * 1.8, y + flap),
				Vector2(x, y),
				Vector2(x + s * 1.8, y + flap),
			]),
			Color(ink.r, ink.g, ink.b, 0.55),
			1.2,
			true
		)

func _draw_moon_birds(size: Vector2, pal: Dictionary, travel: float) -> void:
	var ink: Color = pal.accent
	for i in range(3):
		var x := fposmod(travel * 0.03 + float(i) * 260.0 + 140.0, size.x + 120.0) - 60.0
		var y := size.y * (0.28 + float(i) * 0.035)
		var s := 3.0 + float(i)
		draw_line(Vector2(x - s * 2.0, y), Vector2(x, y - s * 0.6), Color(ink.r, ink.g, ink.b, 0.18), 1.0, true)
		draw_line(Vector2(x, y - s * 0.6), Vector2(x + s * 2.0, y), Color(ink.r, ink.g, ink.b, 0.18), 1.0, true)

func _draw_meteor(size: Vector2, pal: Dictionary) -> void:
	var cycle := fposmod(_elapsed * 0.11, 1.0)
	if cycle > 0.035:
		return
	var t := cycle / 0.035
	var start := Vector2(size.x * 0.84, size.y * 0.10)
	var pos := start + Vector2(-170.0, 78.0) * t
	var tail := pos + Vector2(60.0, -27.0)
	var accent: Color = pal.accent
	draw_line(pos, tail, Color(accent.r, accent.g, accent.b, 0.55 * (1.0 - t)), 1.5, true)
	draw_circle(pos, 1.8, Color(1.0, 0.95, 0.82, 0.7 * (1.0 - t)))

# --------------------------------------------------------------------------
# Parallax silhouettes
# --------------------------------------------------------------------------

func _draw_far_mountains(size: Vector2, pal: Dictionary, travel: float) -> void:
	var scroll := travel * 0.028
	var base := size.y * 0.60
	var points := _mountain_line(size, scroll, base, size.y * 0.22, 1.7, true)
	_draw_ridge(points, size, pal.far, pal.far_light, 0.86)
	# Snow-flecked peaks on the coldest horizons.
	var amount := float(pal.star_amount)
	if amount > 0.72:
		_draw_snow_caps(size, points, pal, amount * 0.55, 0.62)

func _draw_mid_mountains(size: Vector2, pal: Dictionary, travel: float) -> void:
	var scroll := travel * 0.072
	var base := size.y * 0.665
	var points := _mountain_line(size, scroll, base, size.y * 0.155, 3.7, true)
	_draw_ridge(points, size, pal.mid, pal.mid_light, 0.94)
	# A subtle second ridge gives the horizon depth.
	var far_points := _mountain_line(size, scroll * 1.22 + 330.0, base + size.y * 0.025, size.y * 0.10, 5.3, true)
	_draw_ridge(far_points, size, pal.mid.darkened(0.08), pal.mid_light, 0.55)

func _draw_near_dunes(size: Vector2, pal: Dictionary, travel: float) -> void:
	var scroll := travel * 0.16
	var base := size.y * 0.745
	var points := _dune_line(size, scroll, base, size.y * 0.070, 2.2)
	_draw_ridge(points, size, pal.near, pal.near_light, 0.98)
	var second := _dune_line(size, scroll * 1.34 + 290.0, base + size.y * 0.05, size.y * 0.045, 3.2)
	_draw_ridge(second, size, pal.dune, pal.dune_shadow.lerp(pal.near_light, 0.4), 1.0)
	# Long wind-combed shadows on the dunes.
	for i in range(4):
		var y := base + size.y * (0.035 + float(i) * 0.017)
		var start := size.x * (0.05 + float(i) * 0.22)
		var end := start + size.x * 0.38
		draw_line(
			Vector2(start, y),
			Vector2(end, y + 3.0),
			Color(pal.dune_shadow.r, pal.dune_shadow.g, pal.dune_shadow.b, 0.12),
			2.0,
			true
		)

func _draw_foreground_veil(size: Vector2, pal: Dictionary) -> void:
	# The deepest band remains soft so procedural ground always sits naturally.
	var base := size.y * 0.86
	var points := _dune_line(size, _travel() * 0.28 + 1700.0, base, size.y * 0.062, 6.4)
	var deep: Color = pal.dune_shadow
	_draw_ridge(points, size, Color(deep.r, deep.g, deep.b, 0.92), Color(pal.rim.r, pal.rim.g, pal.rim.b, 0.13), 0.82)

func _mountain_line(size: Vector2, scroll: float, base: float, amplitude: float, seed: float, sharp: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(Vector2(-60.0, size.y + 20.0))
	var step := 14.0
	var x := -60.0
	while x <= size.x + 80.0:
		var n := (x + scroll) * 0.0031
		var a := absf(sin(n + seed))
		var b := absf(sin(n * 2.23 + seed * 1.7 + 0.9))
		var c := absf(sin(n * 4.47 + seed * 0.6 + 2.4))
		var shape := a * 0.58 + b * 0.29 + c * 0.13
		if sharp:
			shape = pow(shape, 1.35)
		var detail := sin((x + scroll) * 0.014 + seed * 2.0) * amplitude * 0.075
		points.append(Vector2(x, base - amplitude * shape + detail))
		x += step
	points.append(Vector2(size.x + 80.0, size.y + 20.0))
	return points

func _dune_line(size: Vector2, scroll: float, base: float, amplitude: float, seed: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(Vector2(-60.0, size.y + 25.0))
	var step := 18.0
	var x := -60.0
	while x <= size.x + 80.0:
		var n := (x + scroll) * 0.0023
		var y := base
		y -= (sin(n + seed) * 0.58 + sin(n * 2.4 + seed * 1.9) * 0.28 + sin(n * 5.1 + seed * 0.7) * 0.14) * amplitude
		y -= sin((x + scroll) * 0.009 + seed * 3.0) * amplitude * 0.06
		points.append(Vector2(x, y))
		x += step
	points.append(Vector2(size.x + 80.0, size.y + 25.0))
	return points

func _draw_ridge(points: PackedVector2Array, size: Vector2, fill: Color, rim: Color, alpha: float) -> void:
	var raised := PackedVector2Array()
	raised.resize(points.size())
	for i in range(points.size()):
		var p := points[i]
		raised[i] = Vector2(p.x, p.y - 2.2)
	draw_colored_polygon(raised, Color(rim.r, rim.g, rim.b, rim.a * alpha * 0.72))
	draw_colored_polygon(points, Color(fill.r, fill.g, fill.b, fill.a * alpha))

func _draw_snow_caps(size: Vector2, points: PackedVector2Array, pal: Dictionary, alpha: float, coverage: float) -> void:
	var snow: Color = (pal.far_light as Color).lerp(Color.WHITE, 0.28)
	for i in range(2, points.size() - 2, 3):
		var p := points[i]
		if p.y > size.y * 0.43:
			continue
		if HavenTheme.hash01(float(i) + points[i].x * 0.01) > coverage:
			continue
		var w := 11.0 + HavenTheme.hash01(float(i) + 12.0) * 16.0
		var h := 8.0 + HavenTheme.hash01(float(i) + 19.0) * 12.0
		var poly := PackedVector2Array([
			Vector2(p.x - w, p.y + 3.0),
			Vector2(p.x - w * 0.2, p.y + 0.5),
			Vector2(p.x, p.y - h * 0.2),
			Vector2(p.x + w * 0.2, p.y + 0.5),
			Vector2(p.x + w, p.y + 3.0),
			Vector2(p.x, p.y + 1.0),
		])
		draw_colored_polygon(poly, Color(snow.r, snow.g, snow.b, alpha * 0.45))

func _draw_horizon_haze(size: Vector2, pal: Dictionary) -> void:
	# One soft gradient instead of stacked strips: layered bands read as water
	# at the horizon, which is exactly the wrong cue for an endless desert.
	var haze: Color = pal.haze
	var fog: Color = pal.fog_color
	var tint := Color(
		lerpf(fog.r, haze.r, 0.58),
		lerpf(fog.g, haze.g, 0.58),
		lerpf(fog.b, haze.b, 0.58),
		clampf(haze.a * 0.95 + fog.a * 0.35, 0.0, 0.9)
	)
	draw_texture_rect(
		_haze_texture,
		Rect2(Vector2(0.0, size.y * 0.40), Vector2(size.x, size.y * 0.34)),
		false,
		tint
	)

# --------------------------------------------------------------------------
# Landmarks: Dhaka skyline, ruins, palms, mesas and bare trees
# --------------------------------------------------------------------------

func _draw_landmarks(
	size: Vector2,
	pal: Dictionary,
	travel: float,
	kind: String,
	next_kind: String,
	cross: float
) -> void:
	var current_alpha := (1.0 - cross) * 0.86
	var next_alpha := cross * 0.86
	_draw_landmark_set(size, pal, travel, kind, current_alpha)
	if cross > 0.01:
		_draw_landmark_set(size, pal, travel, next_kind, next_alpha)

func _draw_landmark_set(size: Vector2, pal: Dictionary, travel: float, kind: String, alpha: float) -> void:
	if alpha <= 0.01:
		return
	match kind:
		"city":
			_draw_city(size, pal, travel, alpha, 0.045)
		"ruins", "moon_ruins":
			_draw_ruins(size, pal, travel, alpha, 0.055)
		"mesas":
			_draw_mesas(size, pal, travel, alpha, 0.05)
		"palms":
			_draw_palms(size, pal, travel, alpha, 0.070)
		"deadwoods":
			_draw_deadwoods(size, pal, travel, alpha, 0.052)
		_:
			pass

func _draw_landmarks_close(
	size: Vector2,
	pal: Dictionary,
	travel: float,
	kind: String,
	next_kind: String,
	cross: float
) -> void:
	var current_alpha := (1.0 - cross) * 0.55
	var next_alpha := cross * 0.55
	if kind == "palms" or kind == "deadwoods":
		_draw_landmark_set(size, pal, travel + 420.0, kind, current_alpha * 0.55)
	if cross > 0.01 and (next_kind == "palms" or next_kind == "deadwoods"):
		_draw_landmark_set(size, pal, travel + 420.0, next_kind, next_alpha * 0.55)

func _landmark_ink(pal: Dictionary, amount: float = 0.24) -> Color:
	return (pal.mid as Color).darkened(amount).lerp(pal.near as Color, 0.12)

func _draw_city(size: Vector2, pal: Dictionary, travel: float, alpha: float, speed: float) -> void:
	var spacing := 156.0
	var scroll := travel * speed
	var offset := fposmod(scroll, spacing)
	var base_y := size.y * 0.625
	var ink := _landmark_ink(pal, 0.30)
	var rim: Color = pal.rim
	var start_k := floori(scroll / spacing) - 1
	for k in range(start_k, start_k + int(size.x / spacing) + 4):
		var x := float(k) * spacing - scroll - offset + offset
		var seed := float(k) + 3.7
		if x < -spacing or x > size.x + spacing:
			continue
		var scale := 0.68 + HavenTheme.hash01(seed) * 0.55
		var w := 28.0 + HavenTheme.hash01(seed + 1.0) * 38.0
		var h := 48.0 + HavenTheme.hash01(seed + 2.0) * 88.0
		base_y = size.y * 0.625
		# main block
		draw_rect(Rect2(x, base_y - h, w * scale, h), Color(ink.r, ink.g, ink.b, alpha))
		# roof / dome
		var style := int(HavenTheme.hash01(seed + 5.0) * 3.0)
		if style == 0:
			_draw_dome(Vector2(x + w * scale * 0.5, base_y - h), w * scale * 0.52, Color(ink.r, ink.g, ink.b, alpha))
		elif style == 1:
			draw_rect(Rect2(x + w * scale * 0.18, base_y - h - 12.0, w * scale * 0.64, 12.0), Color(ink.r, ink.g, ink.b, alpha))
			draw_line(
				Vector2(x + w * scale * 0.5, base_y - h - 12.0),
				Vector2(x + w * scale * 0.5, base_y - h - 35.0),
				Color(ink.r, ink.g, ink.b, alpha),
				1.5,
				true
			)
		# minaret
		if HavenTheme.hash01(seed + 7.0) > 0.52:
			var mx := x - 12.0 * scale
			draw_rect(Rect2(mx, base_y - h * 1.2, 7.0 * scale, h * 1.2), Color(ink.r, ink.g, ink.b, alpha))
			draw_circle(Vector2(mx + 3.5 * scale, base_y - h * 1.2), 5.0 * scale, Color(ink.r, ink.g, ink.b, alpha))
		# window lights
		var night := float(pal.star_amount)
		if night > 0.18:
			var glow: Color = pal.accent
			for wy in range(2):
				for wx in range(2):
					if HavenTheme.hash01(seed + wy * 5.0 + wx) > 0.45:
						var px := x + w * scale * (0.28 + float(wx) * 0.34)
						var py := base_y - h * (0.38 + float(wy) * 0.28)
						draw_rect(Rect2(px, py, 1.8, 2.6), Color(glow.r, glow.g, glow.b, alpha * night * 0.8))
		# rim light at the top and left
		draw_line(
			Vector2(x, base_y),
			Vector2(x, base_y - h),
			Color(rim.r, rim.g, rim.b, alpha * 0.18),
			1.0,
			true
		)

func _draw_dome(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	points.append(Vector2(center.x - radius, center.y))
	for i in range(13):
		var t := PI + float(i) / 12.0 * PI
		points.append(center + Vector2(cos(t) * radius, sin(t) * radius))
	points.append(Vector2(center.x + radius, center.y))
	draw_colored_polygon(points, color)
	draw_line(center + Vector2(0.0, -radius - 9.0), center + Vector2(0.0, -radius + 2.0), color, 1.2, true)

func _draw_ruins(size: Vector2, pal: Dictionary, travel: float, alpha: float, speed: float) -> void:
	var spacing := 224.0
	var scroll := travel * speed
	var base_y := size.y * 0.665
	var ink := _landmark_ink(pal, 0.22)
	var rim: Color = pal.rim
	var start_k := floori(scroll / spacing) - 1
	for k in range(start_k, start_k + int(size.x / spacing) + 4):
		var x := float(k) * spacing - scroll
		if x < -spacing or x > size.x + spacing:
			continue
		var seed := float(k) + 11.0
		if HavenTheme.hash01(seed) < 0.25:
			continue
		var scale := 0.75 + HavenTheme.hash01(seed + 4.0) * 0.65
		var count := 2 + int(HavenTheme.hash01(seed + 6.0) * 3.0)
		for i in range(count):
			var cx := x + float(i) * 30.0 * scale
			var height := (38.0 + HavenTheme.hash01(seed + float(i) * 2.1) * 60.0) * scale
			var width := 10.0 * scale
			var broken := HavenTheme.hash01(seed + float(i) * 3.3) > 0.35
			var top := base_y - height
			draw_rect(Rect2(cx, top, width, height), Color(ink.r, ink.g, ink.b, alpha))
			if broken:
				var jag := PackedVector2Array([
					Vector2(cx, top),
					Vector2(cx + width * 0.35, top + 7.0),
					Vector2(cx + width * 0.75, top + 2.0),
					Vector2(cx + width, top + 10.0),
					Vector2(cx + width, top + 14.0),
					Vector2(cx, top + 14.0),
				])
				draw_colored_polygon(jag, Color(ink.r, ink.g, ink.b, alpha))
			draw_line(Vector2(cx, top + 4.0), Vector2(cx, base_y), Color(rim.r, rim.g, rim.b, alpha * 0.12), 1.0, true)
			# lintel / arch ruins
			if i < count - 1 and HavenTheme.hash01(seed + float(i) * 6.7) > 0.55:
				var next_x := cx + 30.0 * scale
				var arch := PackedVector2Array()
				for a in range(9):
					var ang := PI + float(a) / 8.0 * PI
					arch.append(Vector2((cx + next_x) * 0.5 + cos(ang) * 18.0 * scale, top + 4.0 + sin(ang) * 14.0 * scale))
				draw_polyline(arch, Color(ink.r, ink.g, ink.b, alpha), 4.0 * scale, true)
		if HavenTheme.hash01(seed + 9.0) > 0.68:
			draw_rect(Rect2(x - 6.0, base_y - 7.0, 88.0 * scale, 5.0), Color(ink.r, ink.g, ink.b, alpha * 0.7))

func _draw_mesas(size: Vector2, pal: Dictionary, travel: float, alpha: float, speed: float) -> void:
	var spacing := 270.0
	var scroll := travel * speed
	var base_y := size.y * 0.64
	var ink := _landmark_ink(pal, 0.18)
	var rim: Color = pal.rim
	var start_k := floori(scroll / spacing) - 1
	for k in range(start_k, start_k + int(size.x / spacing) + 3):
		var x := float(k) * spacing - scroll
		if x < -spacing or x > size.x + spacing:
			continue
		var seed := float(k) + 7.1
		if HavenTheme.hash01(seed) < 0.22:
			continue
		var w := 120.0 + HavenTheme.hash01(seed + 3.0) * 130.0
		var h := 48.0 + HavenTheme.hash01(seed + 4.0) * 68.0
		var points := PackedVector2Array([
			Vector2(x, base_y),
			Vector2(x + w * 0.10, base_y - h * 0.55),
			Vector2(x + w * 0.20, base_y - h),
			Vector2(x + w * 0.72, base_y - h),
			Vector2(x + w * 0.82, base_y - h * 0.60),
			Vector2(x + w, base_y),
		])
		draw_colored_polygon(points, Color(ink.r, ink.g, ink.b, alpha))
		var cap := PackedVector2Array([
			Vector2(x + w * 0.20, base_y - h),
			Vector2(x + w * 0.72, base_y - h),
			Vector2(x + w * 0.78, base_y - h + 3.0),
			Vector2(x + w * 0.15, base_y - h + 3.0),
		])
		draw_colored_polygon(cap, Color(rim.r, rim.g, rim.b, alpha * 0.18))
		for band in range(3):
			var by := base_y - h * (0.18 + float(band) * 0.17)
			draw_line(
				Vector2(x + w * 0.14, by),
				Vector2(x + w * 0.86, by + 2.0),
				Color(rim.r, rim.g, rim.b, alpha * 0.07),
				2.0,
				true
			)

func _draw_palms(size: Vector2, pal: Dictionary, travel: float, alpha: float, speed: float) -> void:
	var spacing := 255.0
	var scroll := travel * speed
	var base_y := size.y * 0.69
	var ink := _landmark_ink(pal, 0.30)
	var start_k := floori(scroll / spacing) - 1
	for k in range(start_k, start_k + int(size.x / spacing) + 4):
		var x := float(k) * spacing - scroll
		if x < -spacing or x > size.x + spacing:
			continue
		var seed := float(k) + 4.4
		if HavenTheme.hash01(seed) < 0.35:
			continue
		var s := 0.55 + HavenTheme.hash01(seed + 1.0) * 0.65
		_draw_palm(Vector2(x, base_y + HavenTheme.hash01(seed + 2.0) * 8.0), s, Color(ink.r, ink.g, ink.b, alpha))

func _draw_palm(base: Vector2, s: float, color: Color) -> void:
	var top := base + Vector2(4.0 * s, -48.0 * s)
	var trunk := PackedVector2Array([
		base + Vector2(-2.0 * s, 0.0),
		base + Vector2(1.0 * s, -26.0 * s),
		top + Vector2(-1.0 * s, 0.0),
		top + Vector2(2.0 * s, 0.0),
	])
	draw_colored_polygon(trunk, color)
	for i in range(6):
		var angle := -PI * 0.86 + float(i) / 5.0 * PI * 0.72
		var end := top + Vector2(cos(angle) * 30.0 * s, sin(angle) * 20.0 * s - 3.0 * s)
		var mid := (top + end) * 0.5 + Vector2(0.0, -9.0 * s)
		var frond := PackedVector2Array([top, mid, end, mid + Vector2(0.0, 4.0 * s)])
		draw_colored_polygon(frond, color)
		draw_line(top, end, Color(color.r, color.g, color.b, color.a * 0.75), 2.0 * s, true)
	draw_circle(top, 2.2 * s, color)

func _draw_deadwoods(size: Vector2, pal: Dictionary, travel: float, alpha: float, speed: float) -> void:
	var spacing := 235.0
	var scroll := travel * speed
	var base_y := size.y * 0.69
	var ink := _landmark_ink(pal, 0.34)
	var start_k := floori(scroll / spacing) - 1
	for k in range(start_k, start_k + int(size.x / spacing) + 4):
		var x := float(k) * spacing - scroll
		if x < -spacing or x > size.x + spacing:
			continue
		var seed := float(k) + 6.6
		if HavenTheme.hash01(seed) < 0.3:
			continue
		var s := 0.7 + HavenTheme.hash01(seed + 1.0) * 0.55
		var color := Color(ink.r, ink.g, ink.b, alpha)
		var top := Vector2(x, base_y - 52.0 * s)
		draw_line(Vector2(x, base_y), top, color, 2.4 * s, true)
		for i in range(4):
			var y := base_y - (14.0 + float(i) * 11.0) * s
			var dir := -1.0 if i % 2 == 0 else 1.0
			draw_line(Vector2(x, y), Vector2(x + dir * 15.0 * s, y - 15.0 * s), color, 1.4 * s, true)
			draw_line(Vector2(x + dir * 8.0 * s, y - 8.0 * s), Vector2(x + dir * 17.0 * s, y - 9.0 * s), color, 1.0 * s, true)

# --------------------------------------------------------------------------
# Texture generation
# --------------------------------------------------------------------------

func _make_haze_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.34, 0.62, 0.84, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.30),
		Color(1.0, 1.0, 1.0, 0.52),
		Color(1.0, 1.0, 1.0, 0.20),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 8
	texture.height = 256
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


func _make_sky_texture(palette: Dictionary) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.34, 0.62, 0.82, 1.0])
	gradient.colors = PackedColorArray([
		palette.sky_top,
		palette.sky_upper,
		palette.sky_mid,
		palette.sky_low,
		palette.sky_low,
	])
	var texture := GradientTexture2D.new()
	texture.width = 8
	texture.height = 512
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.gradient = gradient
	return texture

func _make_glow_texture(size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := float(size) * 0.5
	for y in range(size):
		for x in range(size):
			var distance := center.distance_to(Vector2(x, y)) / radius
			var alpha := pow(clampf(1.0 - distance, 0.0, 1.0), 2.35)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)

func _make_cloud_texture(width: int, height: int, seed: float) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var blobs := [
		Vector3(0.18, 0.63, 0.19),
		Vector3(0.36, 0.46, 0.25),
		Vector3(0.55, 0.38, 0.23),
		Vector3(0.72, 0.52, 0.20),
		Vector3(0.87, 0.64, 0.13),
	]
	for y in range(height):
		for x in range(width):
			var nx := float(x) / float(width)
			var ny := float(y) / float(height)
			var alpha := 0.0
			for i in range(blobs.size()):
				var blob: Vector3 = blobs[i]
				var dx := (nx - blob.x) / blob.z
				var dy := (ny - blob.y) / (blob.z * 0.46)
				var d := sqrt(dx * dx + dy * dy)
				var puff := pow(clampf(1.0 - d, 0.0, 1.0), 1.8)
				puff *= 0.78 + 0.22 * sin(nx * 21.0 + ny * 17.0 + seed + float(i) * 4.0)
				alpha = maxf(alpha, puff)
			alpha *= smoothstep(0.0, 0.13, nx) * smoothstep(1.0, 0.88, nx)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)
