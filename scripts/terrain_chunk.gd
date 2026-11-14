extends Node2D

## One streamed slice of the endless desert. It owns its visual layering and
## its collision so the visible ridge and the physical ridge never disagree.

const COLLISION_LAYER := 1

var strips: Array[PackedVector2Array] = []
var gap_ranges: Array[Vector2] = [] # local x, width
var palette: Dictionary
var bottom_y := 2200.0
var chunk_width := 1000.0
var art_seed := 0.0

func setup(
	surface_strips: Array[PackedVector2Array],
	local_gaps: Array[Vector2],
	bottom: float,
	chunk_palette: Dictionary,
	width: float,
	seed_value: float
) -> void:
	strips = surface_strips
	gap_ranges = local_gaps
	bottom_y = bottom
	palette = chunk_palette
	chunk_width = width
	art_seed = seed_value
	_build_collision()
	queue_redraw()

func _build_collision() -> void:
	if strips.is_empty():
		return
	var body := StaticBody2D.new()
	body.name = "TerrainBody"
	body.collision_layer = COLLISION_LAYER
	body.collision_mask = 0
	for surface in strips:
		if surface.size() < 2:
			continue
		var polygon := PackedVector2Array(surface)
		polygon.append(Vector2(surface[surface.size() - 1].x, bottom_y))
		polygon.append(Vector2(surface[0].x, bottom_y))
		var collision := CollisionPolygon2D.new()
		collision.polygon = polygon
		collision.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		body.add_child(collision)
	add_child(body)

func _draw() -> void:
	if strips.is_empty():
		return
	_draw_chasm_backs()
	for surface in strips:
		_draw_ground_strip(surface)
	_draw_chasm_rims()

func _draw_chasm_backs() -> void:
	for gap in gap_ranges:
		var start := gap.x
		var width := gap.y
		var left_surface := _surface_at(start)
		var right_surface := _surface_at(start + width)
		if left_surface == INF or right_surface == INF:
			continue
		var top := minf(left_surface, right_surface)
		var deep: Color = palette.sand_deep
		var shadow := Color(deep.r * 0.55, deep.g * 0.58, deep.b * 0.68, 0.96)
		var points := PackedVector2Array([
			Vector2(start, left_surface),
			Vector2(start + width, right_surface),
			Vector2(start + width, bottom_y),
			Vector2(start, bottom_y),
		])
		draw_colored_polygon(points, shadow)
		# A breath of depth in the chasm.
		var glow: Color = palette.accent
		for i in range(4):
			var y := top + 100.0 + float(i) * 76.0
			draw_rect(
				Rect2(start + 8.0, y, maxf(8.0, width - 16.0), 2.0),
				Color(glow.r, glow.g, glow.b, 0.050 - float(i) * 0.01)
			)

func _draw_chasm_rims() -> void:
	for gap in gap_ranges:
		var start := gap.x
		var width := gap.y
		var left_surface := _surface_at(start)
		var right_surface := _surface_at(start + width)
		if left_surface == INF or right_surface == INF:
			continue
		var rim: Color = palette.rim
		var sand: Color = palette.sand_low
		# The left lip glows towards the light; the right lip is in shadow.
		draw_line(Vector2(start, left_surface - 2.0), Vector2(start, left_surface + 64.0), Color(rim.r, rim.g, rim.b, 0.60), 2.0, true)
		draw_line(Vector2(start + width, right_surface - 2.0), Vector2(start + width, right_surface + 74.0), Color(sand.r, sand.g, sand.b, 0.72), 2.4, true)
		draw_circle(Vector2(start, left_surface), 3.0, Color(rim.r, rim.g, rim.b, 0.55))
		draw_circle(Vector2(start + width, right_surface), 2.2, Color(sand.r, sand.g, sand.b, 0.5))

func _surface_at(local_x: float) -> float:
	for surface in strips:
		if surface.is_empty():
			continue
		if local_x >= surface[0].x - 4.0 and local_x <= surface[surface.size() - 1].x + 4.0:
			for i in range(surface.size() - 1):
				var a := surface[i]
				var b := surface[i + 1]
				if local_x >= a.x and local_x <= b.x:
					var t := inverse_lerp(a.x, b.x, local_x)
					return lerpf(a.y, b.y, t)
	return INF

func _draw_ground_strip(surface: PackedVector2Array) -> void:
	if surface.size() < 2:
		return
	var first := surface[0].x
	var last := surface[surface.size() - 1].x
	var deep_fill: Color = palette["sand_deep"]
	var base_polygon := PackedVector2Array(surface)
	base_polygon.append(Vector2(last, bottom_y))
	base_polygon.append(Vector2(first, bottom_y))
	draw_colored_polygon(base_polygon, deep_fill)

	var bands := [
		{"depth": 22.0, "color": palette.sand_hi},
		{"depth": 70.0, "color": palette.sand},
		{"depth": 150.0, "color": palette.sand_mid},
		{"depth": 300.0, "color": palette.sand_low},
	]
	var previous_depth := 0.0
	for band in bands:
		var depth := float(band.depth)
		_draw_band(surface, previous_depth, depth, band.color, 0.0)
		previous_depth = depth
	_draw_band(surface, previous_depth, 640.0, palette.sand_low.lerp(palette.sand_deep, 0.45), 0.0)

	_draw_strata(surface)
	_draw_grains(surface)
	_draw_rim(surface)

func _band_wobble(x: float, depth: float, wave: float) -> float:
	# Both edges of every band use this same depth-keyed ripple. Adjacent bands
	# therefore meet on exactly the same curve, with no hairline of the dark
	# base showing through between independently rasterised polygons.
	return sin(x * 0.017 + float(art_seed) + depth * 0.003) * (2.4 + depth * 0.013) + wave


func _draw_band(surface: PackedVector2Array, top_depth: float, bottom_depth: float, color: Color, wave: float) -> void:
	var points := PackedVector2Array()
	var seam_overlap := 1.2
	for p in surface:
		var wobble := _band_wobble(p.x, top_depth, wave)
		points.append(Vector2(p.x, p.y + top_depth - seam_overlap + wobble))
	for i in range(surface.size() - 1, -1, -1):
		var p := surface[i]
		var wobble := _band_wobble(p.x, bottom_depth, wave)
		points.append(Vector2(p.x, p.y + bottom_depth + wobble))
	draw_colored_polygon(points, color)

func _draw_strata(surface: PackedVector2Array) -> void:
	var colors := [palette.sand_low, palette.sand_deep, palette.sand_mid]
	for index in range(3):
		var depth := 115.0 + float(index) * 120.0
		var points := PackedVector2Array()
		var sample_index := 0
		for p in surface:
			if sample_index % 2 == 0:
				var wobble := sin(p.x * 0.021 + depth * 0.04 + float(art_seed)) * (3.0 + float(index) * 2.0)
				points.append(Vector2(p.x, p.y + depth + wobble))
			sample_index += 1
		if points.size() >= 2:
			var line_color: Color = colors[index]
			draw_polyline(points, Color(line_color.r, line_color.g, line_color.b, 0.20), 1.5, true)

func _draw_grains(surface: PackedVector2Array) -> void:
	if surface.size() < 3:
		return
	var span := surface[surface.size() - 1].x - surface[0].x
	var count := clampi(int(span / 10.0), 18, 120)
	var grain_dark: Color = palette.sand_low
	var grain_light: Color = palette.rim
	for i in range(count):
		var t := HavenTheme.hash01(float(i) * 2.73 + float(art_seed))
		var x := lerpf(surface[0].x, surface[surface.size() - 1].x, t)
		var idx := clampi(int(t * float(surface.size() - 1)), 0, surface.size() - 2)
		var a := surface[idx]
		var b := surface[idx + 1]
		var local_t := 0.0
		if b.x > a.x:
			local_t = clampf((x - a.x) / (b.x - a.x), 0.0, 1.0)
		var surface_y := lerpf(a.y, b.y, local_t)
		var depth := pow(HavenTheme.hash01(float(i) * 5.21 + float(art_seed) + 3.0), 1.8) * 170.0 + 3.0
		var radius := 0.7 + HavenTheme.hash01(float(i) * 9.17 + float(art_seed)) * 1.7
		var color := grain_dark if i % 4 != 0 else grain_light
		draw_circle(Vector2(x, surface_y + depth), radius, Color(color.r, color.g, color.b, 0.10))
		if i % 17 == 0:
			draw_line(
				Vector2(x - 8.0, surface_y + depth),
				Vector2(x + 12.0, surface_y + depth + 1.5),
				Color(grain_dark.r, grain_dark.g, grain_dark.b, 0.07),
				1.4,
				true
			)

func _draw_rim(surface: PackedVector2Array) -> void:
	var rim: Color = palette.rim
	var accent: Color = palette.accent
	draw_polyline(surface, Color(rim.r, rim.g, rim.b, 0.78), 2.6, true)
	var thinner := PackedVector2Array()
	for p in surface:
		thinner.append(Vector2(p.x, p.y - 1.7))
	draw_polyline(thinner, Color(accent.r, accent.g, accent.b, 0.30), 1.0, true)
	# Tiny ridge tufts break up a perfectly smooth edge.
	for i in range(1, surface.size() - 1, 7):
		var p := surface[i]
		var seed := float(i) + p.x * 0.013 + float(art_seed)
		if HavenTheme.hash01(seed) < 0.55:
			continue
		var h := 2.0 + HavenTheme.hash01(seed + 2.0) * 3.0
		draw_line(
			Vector2(p.x - 1.0, p.y - 0.5),
			Vector2(p.x + 1.2, p.y - h),
			Color(rim.r, rim.g, rim.b, 0.22),
			1.0,
			true
		)
