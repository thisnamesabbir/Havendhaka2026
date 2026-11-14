extends Control

## Painted, procedural horizon for Haven Dhaka 2026.
## Every layer is drawn in-engine so the world can blend through eight authored
## time-of-day palettes without shipping dozens of megabyte-sized backdrops.

@export var player_path: NodePath
@export var world_path: NodePath
@export var preview_mode := false
@export var forced_travel := -1.0
@export var travel_speed := 72.0

const CLOUD_TEXTURE := preload("res://assets/generated/cloud_soft.png")
const GLOW_TEXTURE := preload("res://assets/generated/glow.png")
const HALO_TEXTURE := preload("res://assets/generated/halo.png")
const SPARKLE_TEXTURE := preload("res://assets/generated/sparkle.png")
const GRAIN_TEXTURE := preload("res://assets/generated/grain.png")

var _elapsed := 0.0
var _travel := 0.0
var _player: Node2D
var _world: Node
var _stars: Array[Vector3] = []
var _motes: Array[Vector3] = []
var _last_biome := -1
var _biome_flash := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not player_path.is_empty():
		_player = get_node_or_null(player_path) as Node2D
	if not world_path.is_empty():
		_world = get_node_or_null(world_path)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19072026
	for i in range(150):
		_stars.append(Vector3(rng.randf(), rng.randf_range(0.015, 0.62), rng.randf_range(0.5, 2.2)))
	for i in range(44):
		_motes.append(Vector3(rng.randf(), rng.randf_range(0.36, 0.86), rng.randf_range(0.25, 1.0)))

func _process(delta: float) -> void:
	_elapsed += delta
	if forced_travel >= 0.0:
		_travel = forced_travel + _elapsed * travel_speed
	elif is_instance_valid(_player):
		_travel = _player.global_position.x
	else:
		_travel = 200.0 + _elapsed * travel_speed
	var biome := HavenWorldStyle.biome_index_at(_travel)
	if biome != _last_biome:
		if _last_biome >= 0:
			_biome_flash = 1.0
		_last_biome = biome
	_biome_flash = maxf(0.0, _biome_flash - delta * 0.35)
	queue_redraw()

func set_echo_active(_active: bool) -> void:
	# Kept as a compatibility hook for older scenes; the new direction uses
	# light and momentum instead of a vision toggle.
	pass

func get_travel() -> float:
	return _travel

func _draw() -> void:
	var size := get_viewport_rect().size
	if size.x < 2.0 or size.y < 2.0:
		return
	var style := HavenWorldStyle.style_at(_travel)
	_draw_sky(size, style)
	_draw_celestial(size, style)
	_draw_stars(size, style)
	_draw_clouds(size, style)
	_draw_light_shafts(size, style)
	_draw_balloons(size, style)
	_draw_birds(size, style)
	_draw_mountain_layer(size, style, 0.045, 0.615, 0.155, 13.0, "far", style["far"])
	_draw_fog_band(size, style, 0.53, 0.16)
	_draw_mountain_layer(size, style, 0.105, 0.665, 0.105, 31.0, "mid", style["mid"])
	_draw_landmarks(size, style)
	_draw_mountain_layer(size, style, 0.205, 0.715, 0.060, 77.0, "near", style["near"])
	_draw_dunes_layer(size, style, 0.315, 0.765, 0.055, style["dune_far"], 0.95)
	_draw_palms_and_cacti(size, style)
	_draw_dunes_layer(size, style, 0.455, 0.825, 0.062, style["dune_near"], 1.0)
	_draw_fog_band(size, style, 0.70, 0.08)
	_draw_dust_motes(size, style)
	_draw_grain(size)
	if _biome_flash > 0.001:
		var entry: Color = style["accent"]
		entry.a = _biome_flash * 0.035
		draw_rect(Rect2(Vector2.ZERO, size), entry)

func _draw_sky(size: Vector2, style: Dictionary) -> void:
	var top: Color = style["sky_top"]
	var mid: Color = style["sky_mid"]
	var low: Color = style["sky_low"]
	var horizon: Color = style["horizon"]
	var band := 8.0
	var y := 0.0
	while y < size.y:
		var t := clampf(y / (size.y * 0.78), 0.0, 1.0)
		var color: Color
		if t < 0.34:
			color = top.lerp(mid, smoothstep(0.0, 0.34, t))
		elif t < 0.62:
			color = mid.lerp(low, smoothstep(0.34, 0.62, t))
		else:
			color = low.lerp(horizon, smoothstep(0.62, 0.92, t))
		draw_rect(Rect2(0.0, y, size.x, band + 1.0), color)
		y += band
	# Warm haze sitting on the horizon line.
	draw_rect(Rect2(0.0, size.y * 0.50, size.x, size.y * 0.15), _alpha(horizon, 0.10))

func _draw_celestial(size: Vector2, style: Dictionary) -> void:
	var night: float = style["night"]
	var sun_pos := Vector2(size.x * float(style["sun_x"]), size.y * float(style["sun_y"]))
	var sun_scale: float = float(style["sun_size"])
	var disc := Vector2(58.0 + sun_scale * 58.0, 58.0 + sun_scale * 58.0)
	var glow: Color = style["sun_glow"]
	var light: Color = style["sun"]
	var core: Color = style["sun_core"]
	# Broad atmospheric glow, then the tighter halo.
	var halo_size := Vector2(720.0, 720.0) * (0.7 + sun_scale * 0.6)
	draw_texture_rect(HALO_TEXTURE,
		Rect2(sun_pos - halo_size * 0.5, halo_size), false,
		_alpha(glow, 0.20 + (1.0 - night) * 0.16))
	var glow_size := Vector2(360.0, 360.0) * (0.7 + sun_scale * 0.5)
	draw_texture_rect(GLOW_TEXTURE,
		Rect2(sun_pos - glow_size * 0.5, glow_size), false,
		_alpha(glow, 0.30 + (1.0 - night) * 0.24))
	# Flattened lens haze across the disc.
	var streak := Rect2(sun_pos - Vector2(440.0, 26.0), Vector2(880.0, 52.0))
	draw_texture_rect(GLOW_TEXTURE, streak, false, _alpha(light, 0.10 + (1.0 - night) * 0.12))
	if night > 0.52:
		# Moon: a luminous pale disc with a few quiet craters.
		var moon_radius := 23.0 + 13.0 * night
		draw_circle(sun_pos, moon_radius * 1.9, _alpha(Color(0.82, 0.90, 1.0), 0.08))
		draw_circle(sun_pos, moon_radius, _alpha(Color(0.91, 0.96, 1.0), 0.94))
		draw_circle(sun_pos + Vector2(-moon_radius * 0.28, -moon_radius * 0.18), moon_radius * 0.22, Color(0.74, 0.80, 0.91, 0.40))
		draw_circle(sun_pos + Vector2(moon_radius * 0.24, moon_radius * 0.22), moon_radius * 0.15, Color(0.70, 0.77, 0.89, 0.35))
		draw_circle(sun_pos + Vector2(-moon_radius * 0.05, moon_radius * 0.38), moon_radius * 0.10, Color(0.70, 0.77, 0.89, 0.28))
	else:
		draw_circle(sun_pos, disc.x * 0.5, _alpha(light, 0.96))
		draw_circle(sun_pos, disc.x * 0.35, _alpha(core, 0.92))
		draw_circle(sun_pos, disc.x * 0.20, _alpha(Color.WHITE, 0.72))
	# A tiny second moon companion for the night sky's storybook quality.
	if night > 0.75:
		var companion := sun_pos + Vector2(size.x * 0.13, size.y * 0.09)
		draw_circle(companion, 7.0, _alpha(Color(0.81, 0.88, 1.0), 0.55))

func _draw_stars(size: Vector2, style: Dictionary) -> void:
	var night: float = style["night"]
	if night <= 0.02:
		return
	for i in range(_stars.size()):
		var star := _stars[i]
		var twinkle := 0.70 + 0.30 * sin(_elapsed * (0.7 + star.z * 0.7) + float(i) * 1.7)
		var alpha := night * twinkle * (0.30 + star.z * 0.22)
		var p := Vector2(star.x * size.x, star.y * size.y)
		if star.z > 1.65:
			var s := 4.0 + star.z * 1.8
			draw_texture_rect(SPARKLE_TEXTURE, Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), false,
				_alpha(Color(0.92, 0.96, 1.0), alpha))
		else:
			draw_circle(p, 0.55 + star.z * 0.42, _alpha(Color(0.89, 0.94, 1.0), alpha))
	# A soft river of galactic dust.
	var band_alpha := night * 0.035
	for i in range(54):
		var t := float(i) / 54.0
		var p := Vector2(t * size.x, size.y * (0.54 - t * 0.40) + sin(t * 9.0) * 18.0)
		draw_circle(p, 30.0, _alpha(Color(0.68, 0.78, 1.0), band_alpha * (0.4 + 0.6 * sin(t * 12.0 + 1.0))))
	# Rare shooting star.
	var cycle := fposmod(_elapsed, 13.0)
	if night > 0.5 and cycle < 0.55:
		var t := cycle / 0.55
		var start := Vector2(size.x * 0.72, size.y * 0.08)
		var p := start + Vector2(-240.0, 100.0) * t
		var tail := p + Vector2(60.0, -25.0)
		draw_line(p, tail, _alpha(Color(0.92, 0.96, 1.0), (1.0 - t) * 0.65), 1.6, true)
		draw_circle(p, 1.7, _alpha(Color.WHITE, (1.0 - t) * 0.85))

func _draw_clouds(size: Vector2, style: Dictionary) -> void:
	var cloud_color: Color = style["cloud"]
	var night: float = style["night"]
	for i in range(7):
		var width := 470.0 + float((i * 137) % 420)
		var height := width * 0.28
		var speed := 0.012 + float(i) * 0.0025
		var x := fposmod(_travel * speed + float(i) * 337.0 + _elapsed * (2.0 + i * 0.3), size.x + width + 400.0) - width - 200.0
		var y := size.y * (0.055 + float(i % 3) * 0.075) + sin(_elapsed * 0.07 + float(i)) * 7.0
		var alpha := (0.07 + float(i % 3) * 0.025) * (1.0 - night * 0.45)
		draw_texture_rect(CLOUD_TEXTURE, Rect2(Vector2(x, y), Vector2(width, height)), false,
			_alpha(cloud_color, alpha))

func _draw_light_shafts(size: Vector2, style: Dictionary) -> void:
	var night: float = style["night"]
	if night > 0.55:
		return
	var sun_pos := Vector2(size.x * float(style["sun_x"]), size.y * float(style["sun_y"]))
	var ray_color: Color = style["sun"]
	for i in range(4):
		var drift := sin(_elapsed * 0.035 + i) * 40.0
		var spread := 90.0 + i * 125.0
		var bottom_x := sun_pos.x + spread + drift
		var poly := PackedVector2Array([
			sun_pos + Vector2(-18.0, 0.0),
			sun_pos + Vector2(18.0, 0.0),
			Vector2(bottom_x + 180.0, size.y * 0.86),
			Vector2(bottom_x - 160.0, size.y * 0.86),
		])
		draw_colored_polygon(poly, _alpha(ray_color, 0.016 - i * 0.002))

func _draw_balloons(size: Vector2, style: Dictionary) -> void:
	var night: float = style["night"]
	if night > 0.72:
		return
	var accent: Color = style["accent"]
	var cloud: Color = style["cloud"]
	var spacing := 780.0
	var offset := fposmod(_travel * 0.032 + 280.0, spacing)
	for i in range(-1, 3):
		var x := float(i) * spacing - offset + 240.0
		var y := size.y * (0.18 + 0.10 * absf(sin(float(i) * 2.1))) + sin(_elapsed * 0.22 + i) * 14.0
		var scale := 0.72 + 0.20 * absf(sin(float(i) * 1.3))
		_draw_balloon(Vector2(x, y), scale, accent, cloud, 0.56)

func _draw_balloon(pos: Vector2, scale: float, accent: Color, pale: Color, alpha: float) -> void:
	var w := 56.0 * scale
	var h := 76.0 * scale
	var envelope := PackedVector2Array()
	for i in range(25):
		var a := TAU * float(i) / 24.0
		var rx := w * (0.52 + 0.10 * sin(a * 3.0))
		var ry := h * 0.5
		envelope.append(pos + Vector2(cos(a) * rx, sin(a) * ry - h * 0.15))
	draw_colored_polygon(envelope, _alpha(pale, alpha * 0.92))
	# Painted envelope stripes.
	for stripe in range(3):
		var sx := -w * 0.28 + stripe * w * 0.28
		var stripe_poly := PackedVector2Array([
			pos + Vector2(sx - w * 0.10, -h * 0.58),
			pos + Vector2(sx + w * 0.04, -h * 0.58),
			pos + Vector2(sx + w * 0.16, h * 0.17),
			pos + Vector2(sx - w * 0.03, h * 0.17),
		])
		draw_colored_polygon(stripe_poly, _alpha(accent, alpha * 0.55))
	# Basket and ropes.
	var basket := Rect2(pos + Vector2(-w * 0.12, h * 0.38), Vector2(w * 0.24, h * 0.16))
	draw_rect(basket, _alpha(Color(0.25, 0.16, 0.13), alpha))
	draw_line(pos + Vector2(-w * 0.34, h * 0.15), basket.position, _alpha(Color(0.24, 0.17, 0.16), alpha * 0.8), 1.0, true)
	draw_line(pos + Vector2(w * 0.34, h * 0.15), basket.position + Vector2(basket.size.x, 0.0), _alpha(Color(0.24, 0.17, 0.16), alpha * 0.8), 1.0, true)
	var flame := pos + Vector2(0.0, h * 0.25)
	draw_circle(flame, 8.0 * scale, _alpha(accent, alpha * 0.18))
	draw_circle(flame, 2.4 * scale, _alpha(Color(1.0, 0.88, 0.57), alpha * 0.8))

func _draw_birds(size: Vector2, style: Dictionary) -> void:
	var night: float = style["night"]
	if night > 0.65:
		return
	var base := Vector2(size.x * 0.23 - fposmod(_travel * 0.02, size.x * 0.6), size.y * 0.30)
	var ink: Color = style["landmark"]
	for i in range(5):
		var p := base + Vector2(float(i) * 32.0 + sin(_elapsed * 0.18 + i) * 7.0,
			absf(float(i) - 2.0) * 11.0 + sin(_elapsed * 0.4 + i) * 3.0)
		var flap := sin(_elapsed * 3.4 + i * 0.7) * 3.0
		draw_polyline(PackedVector2Array([
			p + Vector2(-8.0, 0.0), p + Vector2(0.0, -2.0 - flap), p + Vector2(8.0, 0.0)
		]), _alpha(ink, 0.38), 1.4, true)

func _draw_mountain_layer(size: Vector2, style: Dictionary, parallax: float, base_ratio: float,
		amplitude_ratio: float, seed_offset: float, layer: String, color: Color) -> void:
	var kind := String(style["mountain_kind"])
	var points := PackedVector2Array()
	points.append(Vector2(-100.0, size.y + 20.0))
	var x := -100.0
	var step := 18.0 if kind == "jagged" else 26.0
	while x <= size.x + 100.0:
		var world_x := x + _travel * parallax + seed_offset * 41.0
		var h := _ridge_profile(world_x, kind, layer)
		var y := size.y * base_ratio - h * size.y * amplitude_ratio
		points.append(Vector2(x, y))
		x += step
	points.append(Vector2(size.x + 100.0, size.y + 20.0))
	var fill := color
	var depth_fade := 0.86 if layer == "far" else (0.94 if layer == "mid" else 1.0)
	fill.a = depth_fade
	draw_colored_polygon(points, fill)
	# A quiet rim light makes the ridges feel painted instead of cut out.
	var rim_points := PackedVector2Array()
	for i in range(1, points.size() - 1):
		rim_points.append(points[i])
	var rim: Color = style["rim"]
	draw_polyline(rim_points, _alpha(rim, 0.16 if layer == "far" else 0.22), 1.2, true)
	# Snow / salt caps on high ridge peaks.
	if kind == "jagged":
		var cap: Color = style["rim"]
		for i in range(1, points.size() - 2):
			var p := points[i]
			var prev := points[i - 1]
			var nxt := points[i + 1]
			if p.y < size.y * base_ratio - size.y * amplitude_ratio * 0.62 and p.y < prev.y and p.y < nxt.y:
				var c := p + Vector2(0.0, 5.0)
				draw_colored_polygon(PackedVector2Array([p, c + Vector2(-8.0, 9.0), c + Vector2(8.0, 9.0)]), _alpha(cap, 0.22))

func _ridge_profile(world_x: float, kind: String, layer: String) -> float:
	var u := world_x * (0.00115 if layer != "near" else 0.00155)
	if kind == "jagged":
		var p1 := pow(clampf(0.5 + 0.5 * sin(u + 0.4), 0.0, 1.0), 2.2)
		var p2 := pow(clampf(0.5 + 0.5 * sin(u * 2.43 + 2.1), 0.0, 1.0), 3.2)
		var p3 := pow(clampf(0.5 + 0.5 * sin(u * 5.21 + 0.7), 0.0, 1.0), 4.0)
		return 0.20 + p1 * 0.56 + p2 * 0.28 + p3 * 0.10
	if kind == "mesas":
		var stair := clampf(sin(u * 0.70 + 0.6) * 1.8 + 0.5, 0.0, 1.0)
		var top := smoothstep(0.45, 0.62, stair)
		return 0.22 + top * 0.55 + sin(u * 2.8 + 1.2) * 0.015
	var h := 0.48 + 0.20 * sin(u * 1.1) + 0.12 * sin(u * 2.4 + 1.5) + 0.055 * sin(u * 5.3 + 0.4)
	return clampf(h, 0.10, 0.94)

func _draw_fog_band(size: Vector2, style: Dictionary, top_ratio: float, height_ratio: float) -> void:
	var fog: Color = style["fog"]
	var y0 := size.y * top_ratio
	var h := size.y * height_ratio
	var bands := 18
	for i in range(bands):
		var t := float(i) / float(bands)
		var a := sin(t * PI) * 0.10
		draw_rect(Rect2(0.0, y0 + t * h, size.x, h / float(bands) + 1.0), _alpha(fog, a))

func _draw_landmarks(size: Vector2, style: Dictionary) -> void:
	var kind := String(style["landmark_kind"])
	var alpha := 0.86
	match kind:
		"city":
			_draw_city_layer(size, style, 0.155, alpha)
		"ruins":
			_draw_ruins_layer(size, style, 0.175, alpha)
		"mesas":
			_draw_mesas_layer(size, style, 0.135, alpha)
		"monoliths":
			_draw_monolith_layer(size, style, 0.17, alpha)
		"pines":
			_draw_pine_layer(size, style, 0.18, alpha)
		"night_peaks":
			_draw_pine_layer(size, style, 0.18, alpha * 0.9)
			_draw_ruins_layer(size, style, 0.20, alpha * 0.35)
		_:
			_draw_far_palms(size, style, alpha * 0.7)

func _draw_city_layer(size: Vector2, style: Dictionary, parallax: float, alpha: float) -> void:
	var base_y := size.y * 0.668
	var ink: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var glow: Color = style["accent"]
	var spacing := 570.0
	var offset := fposmod(_travel * parallax + 180.0, spacing)
	for i in range(-1, 4):
		var x := float(i) * spacing - offset + 120.0
		var scale := 0.78 + 0.16 * absf(sin(float(i) * 2.7 + 0.4))
		# Ground block and layered old-city roofs.
		draw_rect(Rect2(x - 160.0 * scale, base_y - 34.0 * scale, 320.0 * scale, 40.0 * scale), _alpha(ink, alpha))
		for b in range(4):
			var bx := x - 146.0 * scale + b * 78.0 * scale
			var bh := (38.0 + 28.0 * absf(sin(float(b) * 1.9 + float(i)))) * scale
			var bw := 66.0 * scale
			draw_rect(Rect2(bx, base_y - 34.0 * scale - bh, bw, bh), _alpha(ink, alpha))
			# A tiny dome and finial.
			var dome_center := Vector2(bx + bw * 0.5, base_y - 34.0 * scale - bh)
			draw_circle(dome_center, bw * 0.32, _alpha(ink, alpha))
			draw_line(dome_center + Vector2(0.0, -bw * 0.32), dome_center + Vector2(0.0, -bw * 0.55), _alpha(ink, alpha), 2.0 * scale, true)
			# Lantern windows.
			for w in range(3):
				var wx := bx + bw * (0.25 + w * 0.25)
				draw_rect(Rect2(wx, base_y - 28.0 * scale - bh * 0.45, 2.0 * scale, 5.0 * scale), _alpha(glow, 0.80))
		# Minaret.
		var mx := x + 142.0 * scale
		var mh := (102.0 + 26.0 * absf(sin(float(i) * 1.2))) * scale
		draw_rect(Rect2(mx - 7.0 * scale, base_y - mh, 14.0 * scale, mh), _alpha(ink, alpha))
		draw_circle(Vector2(mx, base_y - mh - 6.0 * scale), 9.0 * scale, _alpha(ink, alpha))
		draw_line(Vector2(mx, base_y - mh - 15.0 * scale), Vector2(mx, base_y - mh - 28.0 * scale), _alpha(hi, alpha * 0.8), 1.5 * scale, true)
		for w in range(4):
			draw_rect(Rect2(mx - 3.0 * scale, base_y - mh + (12.0 + w * 17.0) * scale, 2.8 * scale, 4.0 * scale), _alpha(glow, 0.72))
		# Soft window glow pooling on the rooftops.
		draw_circle(Vector2(x, base_y - 22.0 * scale), 84.0 * scale, _alpha(glow, 0.032))

func _draw_ruins_layer(size: Vector2, style: Dictionary, parallax: float, alpha: float) -> void:
	var base_y := size.y * 0.688
	var ink: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var spacing := 690.0
	var offset := fposmod(_travel * parallax + 60.0, spacing)
	for i in range(-1, 4):
		var x := float(i) * spacing - offset + 190.0
		var scale := 0.78 + 0.2 * absf(sin(float(i) * 1.7))
		# Broken colonnade.
		for c in range(4):
			var cx := x + float(c) * 54.0 * scale - 70.0 * scale
			var ch := (94.0 + 26.0 * sin(float(c) * 2.1 + float(i))) * scale
			var cw := 18.0 * scale
			draw_rect(Rect2(cx, base_y - ch, cw, ch + 18.0), _alpha(ink, alpha))
			draw_rect(Rect2(cx - 5.0 * scale, base_y - ch, cw + 10.0 * scale, 5.0 * scale), _alpha(hi, alpha * 0.50))
			# Chipped blocks and fluting.
			for d in range(4):
				draw_line(Vector2(cx + 3.0 * scale, base_y - ch + (12.0 + d * 16.0) * scale),
					Vector2(cx + cw - 3.0 * scale, base_y - ch + (12.0 + d * 16.0) * scale),
					_alpha(hi, alpha * 0.12), 1.0, true)
		# A broken arch spanning the colonnade.
		draw_arc(Vector2(x + 8.0 * scale, base_y - 104.0 * scale), 92.0 * scale,
			PI, TAU * 0.94, 24, _alpha(ink, alpha), 16.0 * scale, true)
		draw_arc(Vector2(x + 8.0 * scale, base_y - 104.0 * scale), 92.0 * scale,
			PI, TAU * 0.94, 24, _alpha(hi, alpha * 0.20), 2.0, true)
		# A distant dome half-buried by the sand.
		draw_circle(Vector2(x + 155.0 * scale, base_y - 36.0 * scale), 56.0 * scale, _alpha(ink, alpha))
		draw_rect(Rect2(x + 99.0 * scale, base_y - 36.0 * scale, 112.0 * scale, 44.0 * scale), _alpha(ink, alpha))
		draw_line(Vector2(x + 155.0 * scale, base_y - 92.0 * scale), Vector2(x + 155.0 * scale, base_y - 112.0 * scale), _alpha(hi, alpha * 0.7), 2.0, true)

func _draw_mesas_layer(size: Vector2, style: Dictionary, parallax: float, alpha: float) -> void:
	var base_y := size.y * 0.69
	var ink: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var spacing := 860.0
	var offset := fposmod(_travel * parallax + 320.0, spacing)
	for i in range(-1, 3):
		var x := float(i) * spacing - offset + 260.0
		var scale := 0.85 + 0.25 * absf(sin(float(i) * 2.3))
		var w := 300.0 * scale
		var h := (100.0 + 44.0 * absf(sin(float(i) * 1.1))) * scale
		var points := PackedVector2Array([
			Vector2(x - w * 0.5, base_y),
			Vector2(x - w * 0.44, base_y - h * 0.70),
			Vector2(x - w * 0.32, base_y - h * 0.86),
			Vector2(x - w * 0.26, base_y - h),
			Vector2(x + w * 0.22, base_y - h),
			Vector2(x + w * 0.30, base_y - h * 0.84),
			Vector2(x + w * 0.43, base_y - h * 0.62),
			Vector2(x + w * 0.50, base_y),
		])
		draw_colored_polygon(points, _alpha(ink, alpha))
		draw_polyline(PackedVector2Array([points[1], points[2], points[3], points[4], points[5], points[6]]), _alpha(hi, alpha * 0.38), 2.0, true)
		for s in range(4):
			var sy := base_y - h * (0.16 + s * 0.16)
			var inset := w * (0.12 + s * 0.025)
			draw_line(Vector2(x - w * 0.5 + inset, sy), Vector2(x + w * 0.5 - inset, sy), _alpha(hi, alpha * 0.11), 1.3, true)

func _draw_monolith_layer(size: Vector2, style: Dictionary, parallax: float, alpha: float) -> void:
	var base_y := size.y * 0.70
	var ink: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var spacing := 640.0
	var offset := fposmod(_travel * parallax + 90.0, spacing)
	for i in range(-1, 4):
		var x := float(i) * spacing - offset + 230.0
		var scale := 0.8 + 0.2 * absf(sin(float(i) * 2.9))
		var w := 36.0 * scale
		var h := (150.0 + 32.0 * absf(sin(float(i) * 1.7))) * scale
		var stone := PackedVector2Array([
			Vector2(x - w * 0.5, base_y),
			Vector2(x - w * 0.42, base_y - h * 0.18),
			Vector2(x - w * 0.36, base_y - h * 0.82),
			Vector2(x - w * 0.14, base_y - h),
			Vector2(x + w * 0.32, base_y - h * 0.92),
			Vector2(x + w * 0.44, base_y - h * 0.22),
			Vector2(x + w * 0.5, base_y),
		])
		draw_colored_polygon(stone, _alpha(ink, alpha))
		draw_polyline(PackedVector2Array([stone[1], stone[2], stone[3], stone[4], stone[5]]), _alpha(hi, alpha * 0.3), 1.5, true)
		# A fallen neighbour.
		draw_colored_polygon(PackedVector2Array([
			Vector2(x + w * 0.8, base_y), Vector2(x + w * 0.9, base_y - 18.0 * scale),
			Vector2(x + w * 2.1, base_y - 16.0 * scale), Vector2(x + w * 2.0, base_y)
		]), _alpha(ink, alpha * 0.8))

func _draw_pine_layer(size: Vector2, style: Dictionary, parallax: float, alpha: float) -> void:
	var base_y := size.y * 0.704
	var ink: Color = style["landmark"]
	var spacing := 220.0
	var offset := fposmod(_travel * parallax + 42.0, spacing)
	for i in range(-2, 8):
		var x := float(i) * spacing - offset
		var s := 0.65 + 0.3 * absf(sin(float(i) * 3.2))
		var h := 92.0 * s
		var w := 30.0 * s
		# Three stacked silhouettes per conifer, with trunks and snow shoulders.
		for layer in range(3):
			var ly := base_y - h * (0.25 + layer * 0.25)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, ly - h * 0.48),
				Vector2(x + w * (1.0 - layer * 0.16), ly),
				Vector2(x, ly + h * 0.12),
				Vector2(x - w * (1.0 - layer * 0.16), ly),
			]), _alpha(ink, alpha))
		draw_line(Vector2(x, base_y - 3.0), Vector2(x, base_y - h * 0.30), _alpha(ink, alpha), 3.0, true)
		draw_polyline(PackedVector2Array([
			Vector2(x - w * 0.5, base_y - h * 0.95),
			Vector2(x, base_y - h * 0.88),
			Vector2(x + w * 0.42, base_y - h * 0.94),
		]), _alpha(style["rim"], alpha * 0.18), 1.2, true)

func _draw_far_palms(size: Vector2, style: Dictionary, alpha: float) -> void:
	var base_y := size.y * 0.706
	var ink: Color = style["landmark"]
	var spacing := 330.0
	var offset := fposmod(_travel * 0.19 + 40.0, spacing)
	for i in range(-1, 6):
		var x := float(i) * spacing - offset + 110.0
		var s := 0.58 + 0.25 * absf(sin(float(i) * 1.8))
		_draw_palm(Vector2(x, base_y), s, _alpha(ink, alpha * 0.8))

func _draw_palms_and_cacti(size: Vector2, style: Dictionary) -> void:
	var base_y := size.y * 0.765
	var ink: Color = style["landmark"]
	var accent: Color = style["rim"]
	var spacing := 390.0
	var offset := fposmod(_travel * 0.33 + 90.0, spacing)
	var kind := String(style["landmark_kind"])
	for i in range(-1, 5):
		var x := float(i) * spacing - offset + 170.0
		var s := 0.70 + 0.18 * absf(sin(float(i) * 2.4))
		if kind == "pines" or kind == "night_peaks":
			continue
		if kind == "mesas":
			# A lone cactus on the canyon rim.
			_draw_cactus(Vector2(x, base_y), s * 0.72, _alpha(ink, 0.84))
		else:
			_draw_palm(Vector2(x, base_y), s, _alpha(ink, 0.84))
		if i % 2 == 0:
			var tuft_x := x + 84.0
			for b in range(5):
				var lean := (float(b) - 2.0) * 3.5
				draw_line(Vector2(tuft_x, base_y), Vector2(tuft_x + lean, base_y - (7.0 + absf(lean) * 0.9) * s),
					_alpha(accent, 0.16), 1.2, true)

func _draw_palm(pos: Vector2, scale: float, color: Color) -> void:
	var height := 112.0 * scale
	var trunk := PackedVector2Array()
	for i in range(9):
		var t := float(i) / 8.0
		var x := pos.x + sin(t * 2.2) * 13.0 * scale
		var y := pos.y - t * height
		var w := lerpf(5.0, 2.2, t) * scale
		trunk.append(Vector2(x - w, y))
	var right := PackedVector2Array()
	for i in range(8, -1, -1):
		var t := float(i) / 8.0
		var x := pos.x + sin(t * 2.2) * 13.0 * scale
		var y := pos.y - t * height
		var w := lerpf(5.0, 2.2, t) * scale
		right.append(Vector2(x + w, y))
	trunk.append_array(right)
	draw_colored_polygon(trunk, color)
	var crown := pos + Vector2(sin(2.2) * 13.0 * scale, -height)
	for f in range(7):
		var angle := -PI * 0.92 + float(f) * (PI * 0.95 / 6.0) + sin(float(f) * 1.8) * 0.10
		var points := PackedVector2Array()
		for seg in range(6):
			var t := float(seg) / 5.0
			var reach := (34.0 + 10.0 * sin(float(f) * 1.3)) * scale * t
			var droop := t * t * (22.0 + float(f) * 1.4) * scale
			points.append(crown + Vector2(cos(angle) * reach, sin(angle) * reach + droop))
		draw_polyline(points, color, (3.8 - float(f) * 0.18) * scale, true)
		for leaf in range(4):
			var lt := 0.32 + leaf * 0.16
			var p := points[mini(leaf + 1, points.size() - 1)].lerp(points[mini(leaf + 2, points.size() - 1)], 0.4)
			draw_line(p, p + Vector2(cos(angle + 0.55) * 9.0, sin(angle + 0.55) * 9.0 + 5.0) * scale,
				color, 1.2 * scale, true)

func _draw_cactus(pos: Vector2, scale: float, color: Color) -> void:
	var h := 54.0 * scale
	var pts := PackedVector2Array([
		pos + Vector2(-7.0, 0.0) * scale,
		pos + Vector2(-6.0, -h * 0.5) * scale,
		pos + Vector2(-4.0, -h) * scale,
		pos + Vector2(4.0, -h) * scale,
		pos + Vector2(6.0, -h * 0.5) * scale,
		pos + Vector2(7.0, 0.0) * scale,
	])
	draw_colored_polygon(pts, color)
	# Arms.
	draw_rect(Rect2(pos + Vector2(-18.0, -h * 0.52) * scale, Vector2(12.0, 6.0) * scale), color)
	draw_rect(Rect2(pos + Vector2(-18.0, -h * 0.52) * scale, Vector2(6.0, 18.0) * scale), color)
	draw_rect(Rect2(pos + Vector2(7.0, -h * 0.66) * scale, Vector2(12.0, 5.0) * scale), color)
	draw_rect(Rect2(pos + Vector2(14.0, -h * 0.66) * scale, Vector2(5.0, 23.0) * scale), color)

func _draw_dunes_layer(size: Vector2, style: Dictionary, parallax: float, base_ratio: float,
		amplitude_ratio: float, color: Color, alpha: float) -> void:
	var points := PackedVector2Array()
	points.append(Vector2(-100.0, size.y + 40.0))
	var x := -100.0
	while x <= size.x + 100.0:
		var world_x := x + _travel * parallax
		var h := 0.55 + 0.21 * sin(world_x * 0.00135 + 0.3) + 0.12 * sin(world_x * 0.0031 + 1.8) + 0.04 * sin(world_x * 0.0067 + 0.7)
		points.append(Vector2(x, size.y * base_ratio - h * size.y * amplitude_ratio))
		x += 24.0
	points.append(Vector2(size.x + 100.0, size.y + 40.0))
	draw_colored_polygon(points, _alpha(color, alpha))
	var rim := PackedVector2Array()
	for i in range(1, points.size() - 1):
		rim.append(points[i])
	draw_polyline(rim, _alpha(style["rim"], 0.13), 1.1, true)
	# Soft secondary dune shadow, giving the ridge volume.
	var shadow := PackedVector2Array()
	for i in range(1, points.size() - 1):
		shadow.append(points[i] + Vector2(3.0, 9.0))
	for i in range(shadow.size() - 1, -1, -1):
		shadow[i].y += 15.0
	draw_polyline(shadow, _alpha(style["terrain_low"], 0.055), 6.0, true)

func _draw_dust_motes(size: Vector2, style: Dictionary) -> void:
	var dust: Color = style["dust"]
	for i in range(_motes.size()):
		var mote := _motes[i]
		var phase := _elapsed * (0.22 + mote.z * 0.30) + float(i) * 1.9
		var x := fposmod(_travel * 0.28 + mote.x * size.x + sin(phase * 0.7) * 22.0, size.x + 80.0) - 40.0
		var y := mote.y * size.y + sin(phase) * 15.0
		var a := 0.06 + 0.07 * (0.5 + 0.5 * sin(phase * 1.7))
		draw_circle(Vector2(x, y), 0.9 + mote.z * 1.1, _alpha(dust, a))
	# A few longer wind-blown grains.
	for i in range(14):
		var phase := _elapsed * (0.8 + float(i) * 0.12) + float(i) * 7.3
		var x := fposmod(_travel * 0.42 + float(i) * 173.0, size.x + 300.0) - 150.0
		var y := size.y * (0.42 + float(i % 7) * 0.065) + sin(phase) * 12.0
		var length := 14.0 + float(i % 4) * 8.0
		draw_line(Vector2(x, y), Vector2(x + length, y + 2.0), _alpha(dust, 0.07), 1.0, true)

func _draw_grain(size: Vector2) -> void:
	draw_texture_rect(GRAIN_TEXTURE, Rect2(Vector2.ZERO, size), true, Color(1.0, 0.96, 0.90, 0.018))

func _alpha(color: Color, alpha: float) -> Color:
	var c := color
	c.a = clampf(alpha, 0.0, 1.0)
	return c
