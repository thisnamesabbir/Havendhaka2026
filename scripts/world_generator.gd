extends Node2D

## Seeded, endless sandboarding terrain for HAVEN DHAKA 2026.
##
## The surface is a pure deterministic function of world X and the run seed, so
## collision, pickups and art can never disagree. Chunks are generated ahead of
## the rider and freed behind. Each chunk owns its silhouette art, collision,
## obstacles, coin trails, rare shards and small environmental props.

signal pickup_collected(kind: String, value: int, world_position: Vector2)
signal biome_changed(index: int)
signal chasm_approaching(distance: float)

const Pickup = preload("res://scripts/pickup.gd")
const SAND_TEXTURE := preload("res://assets/generated/sand_tile.png")
const GLOW_TEXTURE := preload("res://assets/generated/glow.png")
const DUST_TEXTURE := preload("res://assets/generated/dust.png")

const CHUNK_WIDTH := 1440.0
const SAMPLE_STEP := 16.0
const WORLD_AHEAD := 3900.0
const WORLD_BEHIND := 1900.0
const CHUNK_BOTTOM := 460.0
const CHASM_DEPTH := 700.0
const START_X := 0.0
const SAFE_ZONE := 760.0
const FEATURE_VERSION := 14

var player: Node2D
var run_seed := 20261114
var chunks_generated := 0
var pickups_spawned := 0
var obstacles_spawned := 0

var _chunks: Dictionary = {}
var _features: Dictionary = {}
var _current_biome := -1
var _last_chasm_signal := -10000.0
var _started := false


func _ready() -> void:
	z_index = 0
	add_to_group("world")
	set_process(true)
	_ensure_world()


func configure(seed_value: int, start_player: Node2D = null) -> void:
	run_seed = seed_value
	if start_player != null:
		player = start_player
	for chunk in _chunks.values():
		if is_instance_valid(chunk):
			chunk.queue_free()
	_chunks.clear()
	_features.clear()
	_current_biome = -1
	_last_chasm_signal = -10000.0
	chunks_generated = 0
	pickups_spawned = 0
	obstacles_spawned = 0
	_started = false
	_ensure_world()


func _ensure_world() -> void:
	if _started:
		return
	_started = true
	var focus := _focus_x()
	var first := int(floor((focus - WORLD_BEHIND) / CHUNK_WIDTH))
	var last := int(floor((focus + WORLD_AHEAD) / CHUNK_WIDTH))
	for index in range(first, last + 1):
		_generate_chunk(index)


func _process(_delta: float) -> void:
	if not _started:
		return
	var focus := _focus_x()
	var first := int(floor((focus - WORLD_BEHIND) / CHUNK_WIDTH))
	var last := int(floor((focus + WORLD_AHEAD) / CHUNK_WIDTH))
	for index in range(first, last + 1):
		if not _chunks.has(index):
			_generate_chunk(index)
	for index in _chunks.keys():
		if int(index) < first - 1:
			var chunk: Node2D = _chunks[int(index)]
			if is_instance_valid(chunk):
				chunk.queue_free()
			_chunks.erase(index)
	var biome := HavenWorldStyle.biome_index_at(focus)
	if biome != _current_biome:
		_current_biome = biome
		biome_changed.emit(biome)
	_watch_falls(focus)


func _focus_x() -> float:
	if is_instance_valid(player):
		return player.global_position.x
	return SAMPLE_STEP * 8.0


func _watch_falls(focus: float) -> void:
	if not is_instance_valid(player):
		return
	if not bool(player.get("alive")):
		return
	var surface := baseline_height_at(focus)
	if player.global_position.y > surface + 760.0 and not player.is_on_floor():
		if player.has_method("force_crash"):
			player.call("force_crash", "chasm")


# ---------------------------------------------------------------------------
# Height field
# ---------------------------------------------------------------------------

func baseline_height_at(world_x: float) -> float:
	var x := maxf(world_x, 0.0)
	var h := 548.0 - x * 0.012
	h += sin(x * 0.00112 + 0.55) * 68.0
	h += sin(x * 0.00265 + 2.15) * 34.0
	h += sin(x * 0.00590 + 1.10) * 13.0
	h += sin(x * 0.00039 + 4.30) * 52.0
	# A forgiving, near-level launch shelf at the beginning of every run.
	var intro := 1.0 - smoothstep(180.0, SAFE_ZONE, x)
	h = lerpf(h, 528.0 + sin(x * 0.0022) * 4.0, intro)
	return h


func ground_height_at(world_x: float) -> float:
	var chunk_index := int(floor(world_x / CHUNK_WIDTH))
	var feature: Dictionary = _chunk_features(chunk_index)
	if bool(feature.get("has_gap", false)):
		var g0: float = feature["gap_start_world"]
		var g1 := g0 + float(feature["gap_width"])
		if world_x > g0 and world_x < g1:
			return float(feature["gap_floor_y"])
	var h := baseline_height_at(world_x)
	if bool(feature.get("has_kicker", false)):
		var center: float = feature["kicker_center_world"]
		var half: float = float(feature["kicker_width"]) * 0.5
		var distance := absf(world_x - center)
		if distance < half:
			var t := distance / half
			h -= float(feature["kicker_height"]) * pow(cos(t * PI * 0.5), 2.0)
	return h


func terrain_slope_at(world_x: float) -> float:
	var e := 3.0
	return (ground_height_at(world_x + e) - ground_height_at(world_x - e)) / (2.0 * e)


func chunk_features_at(world_x: float) -> Dictionary:
	return _chunk_features(int(floor(world_x / CHUNK_WIDTH)))


func _chunk_features(index: int) -> Dictionary:
	if _features.has(index):
		return _features[index]
	var rng := RandomNumberGenerator.new()
	rng.seed = (run_seed * 7919 + index * 104729 + FEATURE_VERSION * 15485863) & 0x7fffffff
	var feature := {
		"has_gap": false,
		"gap_start_world": 0.0,
		"gap_width": 0.0,
		"gap_floor_y": 0.0,
		"has_kicker": false,
		"kicker_center_world": 0.0,
		"kicker_width": 0.0,
		"kicker_height": 0.0,
	}
	var chunk_origin := float(index) * CHUNK_WIDTH
	var kicker_center := 0.0
	var kicker_width := 0.0
	var kicker_height := 0.0
	if index >= 1:
		var difficulty := clampf(float(index) / 26.0, 0.0, 1.0)
		if rng.randf() < lerpf(0.46, 0.76, difficulty):
			kicker_width = rng.randf_range(150.0, 235.0)
			kicker_center = chunk_origin + rng.randf_range(kicker_width + 180.0, CHUNK_WIDTH - kicker_width - 180.0)
			kicker_height = rng.randf_range(42.0, 76.0 + difficulty * 48.0)
			feature["has_kicker"] = true
			feature["kicker_center_world"] = kicker_center
			feature["kicker_width"] = kicker_width
			feature["kicker_height"] = kicker_height
		var gap_roll := rng.randf()
		var gap_chance := lerpf(0.10, 0.34, difficulty)
		if index >= 4 and gap_roll < gap_chance:
			var gap_width := rng.randf_range(150.0, 230.0 + difficulty * 125.0)
			var gap_start := chunk_origin + rng.randf_range(260.0, CHUNK_WIDTH - gap_width - 260.0)
			if feature["has_kicker"] and absf((gap_start + gap_width * 0.5) - kicker_center) < (gap_width + kicker_width) * 0.5 + 110.0:
				feature["has_kicker"] = false
			feature["has_gap"] = true
			feature["gap_start_world"] = gap_start
			feature["gap_width"] = gap_width
			feature["gap_floor_y"] = baseline_height_at(gap_start + gap_width * 0.5) + CHASM_DEPTH
	_features[index] = feature
	return feature


# ---------------------------------------------------------------------------
# Chunk construction
# ---------------------------------------------------------------------------

func _generate_chunk(index: int) -> void:
	var chunk := Node2D.new()
	chunk.name = "Chunk_%d" % index
	chunk.position = Vector2(float(index) * CHUNK_WIDTH, 0.0)
	add_child(chunk)
	_chunks[index] = chunk
	chunks_generated += 1
	var feature := _chunk_features(index)
	var style := HavenWorldStyle.style_at(float(index) * CHUNK_WIDTH + CHUNK_WIDTH * 0.5)
	var segments := _surface_segments(index, feature)
	_build_collision(chunk, segments, feature)
	_build_ground_art(chunk, segments, feature, style)
	_build_decor(chunk, index, feature, style)
	_build_gap_art(chunk, feature, style)
	_populate(chunk, index, feature, style)


func _surface_segments(index: int, feature: Dictionary) -> Array:
	var origin := float(index) * CHUNK_WIDTH
	var result: Array = []
	var gap_start := -1.0
	var gap_end := -1.0
	if bool(feature.get("has_gap", false)):
		gap_start = float(feature["gap_start_world"]) - origin
		gap_end = gap_start + float(feature["gap_width"])
	if gap_start <= 1.0:
		result.append(_sample_interval(origin, 0.0, CHUNK_WIDTH))
		return result
	result.append(_sample_interval(origin, 0.0, gap_start))
	result.append(_sample_interval(origin, gap_end, CHUNK_WIDTH))
	return result


func _sample_interval(origin: float, from_local: float, to_local: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if to_local <= from_local:
		return points
	var x := from_local
	while x < to_local:
		points.append(Vector2(x, ground_height_at(origin + x)))
		x += SAMPLE_STEP
	points.append(Vector2(to_local, ground_height_at(origin + to_local)))
	return points


func _build_collision(chunk: Node2D, segments: Array, _feature: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.name = "Terrain"
	body.collision_layer = 1
	body.collision_mask = 0
	body.z_index = 1
	chunk.add_child(body)
	for points in segments:
		if points.size() < 2:
			continue
		var deepest := 0.0
		for point in points:
			deepest = maxf(deepest, point.y)
		var bottom := deepest + CHUNK_BOTTOM
		var collision_polygon := PackedVector2Array(points)
		collision_polygon.append(Vector2(points[points.size() - 1].x, bottom))
		collision_polygon.append(Vector2(points[0].x, bottom))
		var collider := CollisionPolygon2D.new()
		collider.polygon = collision_polygon
		body.add_child(collider)


func _band_polygon(points: PackedVector2Array, top_offset: float, bottom: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(Vector2(point.x, point.y + top_offset))
	polygon.append(Vector2(points[points.size() - 1].x, bottom))
	polygon.append(Vector2(points[0].x, bottom))
	return polygon


func _shape_band(points: PackedVector2Array, top_offset: float, thickness: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(Vector2(point.x, point.y + top_offset))
	for i in range(points.size() - 1, -1, -1):
		polygon.append(Vector2(points[i].x, points[i].y + top_offset + thickness))
	return polygon


func _build_ground_art(chunk: Node2D, segments: Array, _feature: Dictionary, style: Dictionary) -> void:
	var low: Color = style["terrain_low"]
	var mid: Color = style["terrain_mid"]
	var hi: Color = style["terrain_hi"]
	var rim: Color = style["rim"]
	var dust: Color = style["dust"]
	for points in segments:
		if points.size() < 2:
			continue
		var deepest := 0.0
		for point in points:
			deepest = maxf(deepest, point.y)
		var bottom := deepest + CHUNK_BOTTOM + 120.0
		# Broad, quiet base masses barely darker than the mid tone.
		_add_polygon(chunk, _band_polygon(points, 0.0, bottom), low.darkened(0.14), 1)
		_add_polygon(chunk, _band_polygon(points, 96.0, bottom), mid.darkened(0.13), 1)
		_add_polygon(chunk, _shape_band(points, 0.0, 20.0), hi.lightened(0.16), 1)
		_add_polygon(chunk, _shape_band(points, 20.0, 86.0), hi, 1)
		_add_polygon(chunk, _shape_band(points, 106.0, 190.0), mid, 1)
		# Fine strata and wind-cut lines.
		for depth in [154.0, 236.0, 330.0]:
			var strata := PackedVector2Array()
			for point in points:
				strata.append(Vector2(point.x, point.y + depth))
			_add_polyline(chunk, strata, 1.4, low.lightened(0.12) if depth < 300 else low.darkened(0.2), 1)
		# Sparse wind ripples following the surface.
		for i in range(2, points.size() - 2, 4):
			var a := points[i]
			var b := points[i + 2]
			var slope := (b - a).normalized()
			var normal := Vector2(-slope.y, slope.x)
			if normal.y > 0.0:
				normal = -normal
			var ripple := PackedVector2Array([
				a + normal * 15.0 - slope * 12.0,
				a + normal * 20.0,
				a + normal * 15.0 + slope * 20.0,
			])
			_add_polyline(chunk, ripple, 1.3, dust.lightened(0.18), 1)
		# Sand texture breathes just enough grain into the painted bands.
		var overlay := Polygon2D.new()
		overlay.name = "SandGrain"
		overlay.texture = SAND_TEXTURE
		overlay.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		overlay.polygon = _shape_band(points, 0.0, 430.0)
		var uvs := PackedVector2Array()
		for point in overlay.polygon:
			uvs.append(Vector2(point.x / 260.0, point.y / 260.0))
		overlay.uv = uvs
		overlay.color = Color(1.0, 1.0, 1.0, 0.16)
		overlay.z_index = 1
		chunk.add_child(overlay)
		# Bright crest line anchors the rideable edge.
		_add_polyline(chunk, points, 4.6, Color(rim, 0.92), 2)
		_add_polyline(chunk, points, 1.2, Color(1.0, 1.0, 1.0, 0.32), 2)


func _build_gap_art(chunk: Node2D, feature: Dictionary, style: Dictionary) -> void:
	if not bool(feature.get("has_gap", false)):
		return
	var origin := chunk.position.x
	var g0 := float(feature["gap_start_world"]) - origin
	var g1 := g0 + float(feature["gap_width"])
	var h0 := baseline_height_at(origin + g0)
	var h1 := baseline_height_at(origin + g1)
	var low: Color = style["terrain_low"]
	var mid: Color = style["terrain_mid"]
	var accent: Color = style["accent"]
	var floor_y := maxf(h0, h1) + CHASM_DEPTH
	# The shadowed ravine behind the shoulders.
	_add_polygon(chunk, PackedVector2Array([
		Vector2(g0 - 34.0, h0),
		Vector2(g1 + 34.0, h1),
		Vector2(g1 + 60.0, floor_y + 100.0),
		Vector2(g0 - 60.0, floor_y + 100.0),
	]), low.darkened(0.56), 2)
	_add_polygon(chunk, PackedVector2Array([
		Vector2(g0, h0),
		Vector2(g0 + 30.0, h0 + 52.0),
		Vector2(g0 + 22.0, floor_y),
		Vector2(g0, floor_y),
	]), mid.darkened(0.32), 2)
	_add_polygon(chunk, PackedVector2Array([
		Vector2(g1, h1),
		Vector2(g1 - 30.0, h1 + 52.0),
		Vector2(g1 - 22.0, floor_y),
		Vector2(g1, floor_y),
	]), mid.darkened(0.42), 2)
	_add_polyline(chunk, PackedVector2Array([
		Vector2(g0, h0 + 2.0), Vector2(g0 + 5.0, h0 + 38.0), Vector2(g0 + 4.0, h0 + 92.0)
	]), 2.0, Color(accent, 0.42), 3)
	_add_polyline(chunk, PackedVector2Array([
		Vector2(g1, h1 + 2.0), Vector2(g1 - 5.0, h1 + 38.0), Vector2(g1 - 4.0, h1 + 92.0)
	]), 2.0, Color(accent, 0.35), 3)
	# Low mist in the abyss.
	var mist := Sprite2D.new()
	mist.texture = DUST_TEXTURE
	mist.position = Vector2((g0 + g1) * 0.5, maxf(h0, h1) + 510.0)
	mist.modulate = Color(style["fog"], 0.17)
	mist.scale = Vector2(float(feature["gap_width"]) / 90.0, 3.4)
	mist.z_index = 2
	chunk.add_child(mist)
	# Marker flags give the rider a readable warning before the lip.
	for i in range(2):
		var flag_x := g0 - 118.0 + float(i) * 58.0
		var flag_ground := baseline_height_at(origin + flag_x)
		var pole_top := flag_ground - 92.0
		_add_polyline(chunk, PackedVector2Array([
			Vector2(flag_x, flag_ground), Vector2(flag_x, pole_top)
		]), 2.4, low.lightened(0.2), 2)
		_add_polygon(chunk, PackedVector2Array([
			Vector2(flag_x, pole_top + 2.0),
			Vector2(flag_x + 34.0, pole_top + 12.0),
			Vector2(flag_x, pole_top + 27.0),
		]), Color(accent, 0.94), 2)


func _populate(chunk: Node2D, index: int, feature: Dictionary, style: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = (run_seed * 3571 + index * 6151 + 9091) & 0x7fffffff
	var origin := float(index) * CHUNK_WIDTH
	var gap_start := float(feature["gap_start_world"]) - origin
	var gap_width := float(feature["gap_width"])
	var has_gap := bool(feature.get("has_gap", false))
	var safe := origin + CHUNK_WIDTH < SAFE_ZONE
	# A first-run present: one readable coin arc over the starter kicker.
	if index == 1 and bool(feature.get("has_kicker", false)):
		var center: float = float(feature["kicker_center_world"]) - origin
		_spawn_coin_arc(chunk, center - 110.0, center + 190.0, 7, style, 86.0)
		_spawn_shard(chunk, center + 30.0, baseline_height_at(origin + center) - 175.0, style)
	if has_gap:
		_spawn_coin_arc(chunk, gap_start - 78.0, gap_start + gap_width + 78.0, 8, style, 94.0 + gap_width * 0.28)
		if rng.randf() < 0.65:
			var center_x := gap_start + gap_width * 0.5
			var center_y := minf(baseline_height_at(origin + gap_start), baseline_height_at(origin + gap_start + gap_width)) - 168.0
			_spawn_shard(chunk, center_x, center_y, style)
	# Scenic coin trail where there is room and no immediate hazard.
	if not safe and index > 0 and not has_gap and rng.randf() < 0.68:
		var start := rng.randf_range(220.0, CHUNK_WIDTH - 520.0)
		var count := rng.randi_range(4, 7)
		var spacing := rng.randf_range(44.0, 58.0)
		var wobble := rng.randf_range(0.0, 2.0)
		for i in range(count):
			var lx := start + float(i) * spacing
			var ly := baseline_height_at(origin + lx) - 54.0 - sin(float(i) * 0.7 + wobble) * 12.0
			if absf(lx - gap_start) < gap_width * 0.5:
				continue
			_spawn_pickup(chunk, lx, ly, "coin", 1, style["accent"])
	# Rare floating energy shard.
	if not safe and index > 1 and rng.randf() < 0.46 and not has_gap:
		var sx := rng.randf_range(300.0, CHUNK_WIDTH - 300.0)
		var sy := baseline_height_at(origin + sx) - rng.randf_range(120.0, 230.0)
		_spawn_shard(chunk, sx, sy, style)
	# Obstacles become denser with distance but always leave a readable line.
	if not safe and index >= 2:
		var count := 1 if index < 7 else (2 if index < 17 else 3)
		for obstacle_index in range(count):
			var ox := 220.0 + (float(obstacle_index) + 0.5) * (CHUNK_WIDTH - 440.0) / float(count)
			ox += rng.randf_range(-92.0, 92.0)
			if has_gap and absf(ox - (gap_start + gap_width * 0.5)) < gap_width * 0.5 + 140.0:
				continue
			var surface := baseline_height_at(origin + ox)
			if rng.randf() < 0.24:
				_spawn_bounce_rock(chunk, ox, surface, style)
			else:
				_spawn_hazard(chunk, ox, surface, style, rng)


func _build_decor(chunk: Node2D, index: int, feature: Dictionary, style: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = (run_seed * 5087 + index * 2377 + 4243) & 0x7fffffff
	var origin := float(index) * CHUNK_WIDTH
	var gap_start := float(feature["gap_start_world"]) - origin
	var gap_end := gap_start + float(feature["gap_width"])
	var count := 2 + rng.randi_range(0, 2)
	for i in range(count):
		var lx := rng.randf_range(110.0, CHUNK_WIDTH - 110.0)
		if bool(feature.get("has_gap", false)) and lx > gap_start - 80.0 and lx < gap_end + 80.0:
			continue
		var surface := baseline_height_at(origin + lx)
		var kind := String(style["landmark_kind"])
		var scale_value := rng.randf_range(0.7, 1.25)
		match kind:
			"palms":
				if rng.randf() < 0.62:
					_add_palm(chunk, Vector2(lx, surface), style, scale_value, rng)
				else:
					_add_shrub(chunk, Vector2(lx, surface), style, scale_value)
			"ruins":
				if rng.randf() < 0.58:
					_add_ruin(chunk, Vector2(lx, surface), style, scale_value, rng)
				else:
					_add_rock_silhouette(chunk, Vector2(lx, surface), style, scale_value, rng)
			"pines":
				_add_pine(chunk, Vector2(lx, surface), style, scale_value, rng)
			"city":
				if rng.randf() < 0.55:
					_add_tower(chunk, Vector2(lx, surface), style, scale_value, rng)
				else:
					_add_shrub(chunk, Vector2(lx, surface), style, scale_value)
			"mesas":
				_add_mesa(chunk, Vector2(lx, surface), style, scale_value, rng)
			"monoliths":
				_add_monolith(chunk, Vector2(lx, surface), style, scale_value, rng)
			"night_peaks":
				_add_pine(chunk, Vector2(lx, surface), style, scale_value * 1.2, rng)
			_:
				_add_shrub(chunk, Vector2(lx, surface), style, scale_value)
	# Occasional bold foreground silhouette; no collision, just depth.
	if index >= 2 and rng.randf() < 0.34:
		var fx := rng.randf_range(180.0, CHUNK_WIDTH - 180.0)
		if not (bool(feature.get("has_gap", false)) and fx > gap_start - 60.0 and fx < gap_end + 60.0):
			_add_foreground_silhouette(chunk, Vector2(fx, baseline_height_at(origin + fx) + 10.0), style, rng)


# ---------------------------------------------------------------------------
# Props & silhouettes
# ---------------------------------------------------------------------------

func _add_palm(chunk: Node2D, base: Vector2, style: Dictionary, scale_value: float, rng: RandomNumberGenerator) -> void:
	var landmark: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var height := 148.0 * scale_value
	var bend := rng.randf_range(-18.0, 22.0)
	var trunk := PackedVector2Array()
	for i in range(7):
		var t := float(i) / 6.0
		trunk.append(base + Vector2(bend * t * t, -height * t))
	_add_polyline(chunk, trunk, 7.0 * scale_value, landmark.lightened(0.06), 0)
	_add_polyline(chunk, trunk, 2.0 * scale_value, hi.darkened(0.24), 0)
	var crown := trunk[trunk.size() - 1]
	for i in range(6):
		var angle := -PI * 0.92 + float(i) * (PI * 0.84 / 5.0) + rng.randf_range(-0.12, 0.12)
		var length := rng.randf_range(38.0, 66.0) * scale_value
		var tip := crown + Vector2(cos(angle), sin(angle)) * length
		tip.y += 20.0 * scale_value
		var mid := crown.lerp(tip, 0.5) + Vector2(0.0, -10.0 * scale_value)
		_add_polyline(chunk, PackedVector2Array([crown, mid, tip]), 4.4 * scale_value, landmark, 0)
		_add_polyline(chunk, PackedVector2Array([crown, mid, tip]), 1.0 * scale_value, hi.darkened(0.2), 0)


func _add_shrub(chunk: Node2D, base: Vector2, style: Dictionary, scale_value: float) -> void:
	var landmark: Color = style["landmark"]
	var points := PackedVector2Array()
	for i in range(9):
		var angle := PI + float(i) * PI / 8.0
		var radius := (16.0 + (i % 3) * 7.0) * scale_value
		points.append(base + Vector2(cos(angle) * radius, sin(angle) * radius * 0.66))
	points.append(base)
	_add_polygon(chunk, points, landmark.darkened(0.06), 0)
	_add_polyline(chunk, points, 1.0, style["landmark_hi"].darkened(0.2), 0)


func _add_ruin(chunk: Node2D, base: Vector2, style: Dictionary, scale_value: float, rng: RandomNumberGenerator) -> void:
	var stone: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var width := 52.0 * scale_value
	var height := rng.randf_range(70.0, 135.0) * scale_value
	_add_polygon(chunk, PackedVector2Array([
		base + Vector2(-width * 0.5, 0.0),
		base + Vector2(-width * 0.42, -height),
		base + Vector2(width * 0.36, -height * 0.93),
		base + Vector2(width * 0.5, 0.0),
	]), stone, 0)
	_add_polyline(chunk, PackedVector2Array([
		base + Vector2(-width * 0.42, -height),
		base + Vector2(width * 0.36, -height * 0.93),
	]), 3.0, hi.darkened(0.16), 0)
	for i in range(3):
		var y := base.y - height * (0.28 + i * 0.21)
		_add_polyline(chunk, PackedVector2Array([
			Vector2(base.x - width * 0.4, y), Vector2(base.x + width * 0.34, y - 3.0)
		]), 1.3, hi.darkened(0.32), 0)
	if rng.randf() < 0.4:
		var other := base + Vector2(width * 1.6, 0.0)
		_add_polygon(chunk, PackedVector2Array([
			other + Vector2(-width * 0.32, 0.0), other + Vector2(-width * 0.28, -height * 0.48),
			other + Vector2(width * 0.4, -height * 0.42), other + Vector2(width * 0.44, 0.0),
		]), stone.darkened(0.1), 0)


func _add_pine(chunk: Node2D, base: Vector2, style: Dictionary, scale_value: float, rng: RandomNumberGenerator) -> void:
	var dark: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var height := rng.randf_range(90.0, 190.0) * scale_value
	_add_polyline(chunk, PackedVector2Array([base, base + Vector2(0.0, -height * 0.34)]), 4.0 * scale_value, dark.darkened(0.2), 0)
	for i in range(3):
		var t := 0.34 + float(i) * 0.18
		var half := (33.0 - float(i) * 6.0) * scale_value
		var y := base.y - height * t
		_add_polygon(chunk, PackedVector2Array([
			Vector2(base.x, y - height * 0.3),
			Vector2(base.x + half, y),
			Vector2(base.x - half, y),
		]), dark.lightened(float(i) * 0.025), 0)
		_add_polyline(chunk, PackedVector2Array([
			Vector2(base.x, y - height * 0.3), Vector2(base.x + half, y)
		]), 1.0, hi.darkened(0.3), 0)


func _add_tower(chunk: Node2D, base: Vector2, style: Dictionary, scale_value: float, rng: RandomNumberGenerator) -> void:
	var dark: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var height := rng.randf_range(120.0, 220.0) * scale_value
	var half := rng.randf_range(18.0, 32.0) * scale_value
	_add_polygon(chunk, PackedVector2Array([
		base + Vector2(-half, 0.0), base + Vector2(-half * 0.58, -height),
		base + Vector2(half * 0.58, -height), base + Vector2(half, 0.0),
	]), dark, 0)
	for i in range(4):
		var t := float(i + 1) / 5.0
		var y := base.y - height * t
		_add_polyline(chunk, PackedVector2Array([
			Vector2(base.x - half * lerpf(1.0, 0.58, t), y),
			Vector2(base.x + half * lerpf(1.0, 0.58, t), y),
		]), 1.0, hi.darkened(0.38), 0)
	_add_polyline(chunk, PackedVector2Array([
		Vector2(base.x, base.y), Vector2(base.x, base.y - height)
	]), 1.1, hi.darkened(0.3), 0)
	var lantern := Polygon2D.new()
	lantern.polygon = PackedVector2Array([
		Vector2(-3.0, -4.0), Vector2(3.0, -4.0), Vector2(2.0, 3.0), Vector2(-2.0, 3.0)
	])
	lantern.color = Color(style["accent"], 0.78)
	lantern.position = base + Vector2(0.0, -height * 0.86)
	lantern.z_index = 0
	chunk.add_child(lantern)


func _add_mesa(chunk: Node2D, base: Vector2, style: Dictionary, scale_value: float, rng: RandomNumberGenerator) -> void:
	var dark: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var width := rng.randf_range(80.0, 150.0) * scale_value
	var height := rng.randf_range(90.0, 160.0) * scale_value
	_add_polygon(chunk, PackedVector2Array([
		base + Vector2(-width * 0.55, 0.0),
		base + Vector2(-width * 0.4, -height * 0.74),
		base + Vector2(-width * 0.23, -height),
		base + Vector2(width * 0.18, -height * 0.96),
		base + Vector2(width * 0.32, -height * 0.58),
		base + Vector2(width * 0.5, 0.0),
	]), dark, 0)
	_add_polyline(chunk, PackedVector2Array([
		base + Vector2(-width * 0.23, -height),
		base + Vector2(width * 0.18, -height * 0.96),
	]), 2.4, hi.darkened(0.2), 0)
	_add_polyline(chunk, PackedVector2Array([
		base + Vector2(-width * 0.4, -height * 0.74), base + Vector2(width * 0.26, -height * 0.7)
	]), 1.2, hi.darkened(0.38), 0)


func _add_monolith(chunk: Node2D, base: Vector2, style: Dictionary, scale_value: float, rng: RandomNumberGenerator) -> void:
	var dark: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var height := rng.randf_range(130.0, 250.0) * scale_value
	var width := rng.randf_range(24.0, 48.0) * scale_value
	_add_polygon(chunk, PackedVector2Array([
		base + Vector2(-width * 0.5, 0.0),
		base + Vector2(-width * 0.42, -height * 0.92),
		base + Vector2(0.0, -height),
		base + Vector2(width * 0.4, -height * 0.88),
		base + Vector2(width * 0.5, 0.0),
	]), dark, 0)
	_add_polyline(chunk, PackedVector2Array([
		base + Vector2(-width * 0.12, -height), base + Vector2(-width * 0.2, 0.0)
	]), 1.4, hi.darkened(0.32), 0)


func _add_rock_silhouette(chunk: Node2D, base: Vector2, style: Dictionary, scale_value: float, rng: RandomNumberGenerator) -> void:
	var dark: Color = style["landmark"]
	var hi: Color = style["landmark_hi"]
	var width := rng.randf_range(38.0, 78.0) * scale_value
	var height := rng.randf_range(22.0, 52.0) * scale_value
	_add_polygon(chunk, PackedVector2Array([
		base + Vector2(-width * 0.5, 0.0),
		base + Vector2(-width * 0.42, -height * 0.7),
		base + Vector2(-width * 0.1, -height),
		base + Vector2(width * 0.36, -height * 0.62),
		base + Vector2(width * 0.5, 0.0),
	]), dark.darkened(0.06), 0)
	_add_polyline(chunk, PackedVector2Array([
		base + Vector2(-width * 0.1, -height), base + Vector2(width * 0.36, -height * 0.62)
	]), 1.6, hi.darkened(0.32), 0)


func _add_foreground_silhouette(chunk: Node2D, base: Vector2, style: Dictionary, rng: RandomNumberGenerator) -> void:
	var color: Color = style["terrain_low"].darkened(0.58)
	var width := rng.randf_range(46.0, 110.0)
	var height := rng.randf_range(18.0, 46.0)
	_add_polygon(chunk, PackedVector2Array([
		base + Vector2(-width * 0.5, 0.0),
		base + Vector2(-width * 0.34, -height),
		base + Vector2(width * 0.28, -height * 0.82),
		base + Vector2(width * 0.5, 0.0),
	]), Color(color, 0.52), 6)


# ---------------------------------------------------------------------------
# Gameplay objects
# ---------------------------------------------------------------------------

func _spawn_hazard(chunk: Node2D, local_x: float, surface_y: float, style: Dictionary, rng: RandomNumberGenerator) -> void:
	var radius := rng.randf_range(17.0, 28.0)
	var height := radius * rng.randf_range(1.35, 2.1)
	var body := StaticBody2D.new()
	body.name = "SandstoneHazard"
	body.add_to_group("obstacles")
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(local_x, surface_y - height * 0.5 + 2.0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(radius * 1.65, height)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	var art := Polygon2D.new()
	art.polygon = PackedVector2Array([
		Vector2(-radius * 0.86, height * 0.5),
		Vector2(-radius * 0.74, -height * 0.16),
		Vector2(-radius * 0.22, -height * 0.5),
		Vector2(radius * 0.48, -height * 0.42),
		Vector2(radius * 0.82, height * 0.5),
	])
	art.color = style["terrain_low"].darkened(0.08)
	art.z_index = 2
	body.add_child(art)
	var cap := Polygon2D.new()
	cap.polygon = PackedVector2Array([
		Vector2(-radius * 0.22, -height * 0.5),
		Vector2(radius * 0.48, -height * 0.42),
		Vector2(radius * 0.2, -height * 0.24),
		Vector2(-radius * 0.3, -height * 0.3),
	])
	cap.color = Color(style["rim"], 0.4)
	cap.z_index = 2
	body.add_child(cap)
	var warning := Polygon2D.new()
	warning.polygon = PackedVector2Array([
		Vector2(-3.0, -height * 0.55), Vector2(3.0, -height * 0.55),
		Vector2(1.4, -height * 0.42), Vector2(-1.4, -height * 0.42),
	])
	warning.color = Color(style["accent"], 0.55)
	warning.z_index = 2
	body.add_child(warning)
	chunk.add_child(body)
	obstacles_spawned += 1


func _spawn_bounce_rock(chunk: Node2D, local_x: float, surface_y: float, style: Dictionary) -> void:
	var radius := 30.0
	var body := StaticBody2D.new()
	body.name = "BounceRock"
	body.add_to_group("bounce_rocks")
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(local_x, surface_y - radius + 3.0)
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	var art := Polygon2D.new()
	art.polygon = PackedVector2Array([
		Vector2(-radius * 1.02, radius * 0.34), Vector2(-radius * 0.76, -radius * 0.44),
		Vector2(-radius * 0.14, -radius * 0.9), Vector2(radius * 0.56, -radius * 0.62),
		Vector2(radius * 0.98, radius * 0.12), Vector2(radius * 0.62, radius * 0.72),
		Vector2(-radius * 0.38, radius * 0.82),
	])
	art.color = style["terrain_low"].darkened(0.18)
	art.z_index = 2
	body.add_child(art)
	var cap := Polygon2D.new()
	cap.polygon = PackedVector2Array([
		Vector2(-radius * 0.14, -radius * 0.9), Vector2(radius * 0.56, -radius * 0.62),
		Vector2(radius * 0.26, -radius * 0.38), Vector2(-radius * 0.26, -radius * 0.56),
	])
	cap.color = Color(style["rim"], 0.52)
	cap.z_index = 2
	body.add_child(cap)
	var rune := Polygon2D.new()
	rune.polygon = PackedVector2Array([
		Vector2(0.0, -radius * 0.24), Vector2(radius * 0.18, -radius * 0.02),
		Vector2(0.0, radius * 0.24), Vector2(-radius * 0.18, -radius * 0.02),
	])
	rune.color = Color(style["accent"], 0.68)
	rune.z_index = 2
	body.add_child(rune)
	chunk.add_child(body)
	obstacles_spawned += 1


func _spawn_coin_arc(chunk: Node2D, from_x: float, to_x: float, count: int, style: Dictionary, peak: float) -> void:
	if to_x <= from_x:
		return
	var origin := chunk.position.x
	var y0 := baseline_height_at(origin + from_x) - 54.0
	var y1 := baseline_height_at(origin + to_x) - 54.0
	for i in range(count):
		var t := float(i) / float(maxi(1, count - 1))
		var lx := lerpf(from_x, to_x, t)
		var ly := lerpf(y0, y1, t) - sin(t * PI) * peak
		_spawn_pickup(chunk, lx, ly, "coin", 1, style["accent"])


func _spawn_shard(chunk: Node2D, local_x: float, local_y: float, style: Dictionary) -> void:
	_spawn_pickup(chunk, local_x, local_y, "shard", 25, style["accent"])


func _spawn_pickup(chunk: Node2D, local_x: float, local_y: float, kind: String, value: int, accent: Color) -> void:
	var pickup: Area2D = Pickup.new()
	pickup.set("kind", kind)
	pickup.set("value", value)
	pickup.set("accent", accent)
	pickup.position = Vector2(local_x, local_y)
	pickup.connect("collected", _on_pickup_collected)
	chunk.add_child(pickup)
	pickups_spawned += 1


func _on_pickup_collected(kind: String, value: int, world_position: Vector2) -> void:
	pickup_collected.emit(kind, value, world_position)


# ---------------------------------------------------------------------------
# Drawing helpers
# ---------------------------------------------------------------------------

func _add_polygon(parent: Node2D, points: PackedVector2Array, color: Color, z: int) -> Polygon2D:
	if points.size() < 3:
		return
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = z
	parent.add_child(polygon)


func _add_polyline(parent: Node2D, points: PackedVector2Array, width: float, color: Color, z: int) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.z_index = z
	line.antialiased = true
	parent.add_child(line)
	return line


# ---------------------------------------------------------------------------
# Public info
# ---------------------------------------------------------------------------

func biome_index_at(world_x: float) -> int:
	return HavenWorldStyle.biome_index_at(world_x)


func biome_name_at(world_x: float) -> String:
	return HavenWorldStyle.name_at(world_x)


func biome_style_at(world_x: float) -> Dictionary:
	return HavenWorldStyle.style_at(world_x)


func distance_at(world_x: float) -> int:
	return maxi(0, int((world_x - 80.0) / 10.0))


func next_gap_distance(world_x: float) -> float:
	for offset in range(0, 12):
		var index := int(floor(world_x / CHUNK_WIDTH)) + offset
		var feature := _chunk_features(index)
		if bool(feature.get("has_gap", false)):
			var g0: float = feature["gap_start_world"]
			if g0 > world_x:
				return g0 - world_x
	return 99999.0


func get_generated_chunk_count() -> int:
	return _chunks.size()


func get_feature_signature() -> String:
	return "seed=%d v=%d" % [run_seed, FEATURE_VERSION]
