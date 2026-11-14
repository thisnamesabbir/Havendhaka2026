class_name HavenWorld
extends Node2D

## The endless downhill desert. The terrain function is shared by everything
## that needs it, while chunks are streamed in ahead of the rider and removed
## behind them. Seed-stable geometry makes every run reproducible.

signal pickup_collected(kind: String, value: int, world_position: Vector2)
signal biome_changed(index: int, biome_name: String)

const TerrainChunk = preload("res://scripts/terrain_chunk.gd")
const TerrainDecor = preload("res://scripts/terrain_decor.gd")
const Obstacle = preload("res://scripts/obstacle.gd")
const Pickup = preload("res://scripts/collectible.gd")
const PickupBurst = preload("res://scripts/pickup_burst.gd")

const CHUNK_WIDTH := 1000.0
const SAMPLE_STEP := 20.0
const SEGMENT_LENGTH := 1600.0
const START_Y := 318.0
const BOTTOM_MARGIN := 1250.0
const WORLD_SEED := 20260214

var player: Node2D
var chunks: Array[Node2D] = []
var generated_to := 0.0
var world_seed := WORLD_SEED
var _rng := RandomNumberGenerator.new()
var _last_biome := -1

func _ready() -> void:
	z_index = 0
	if has_node("/root/SaveData"):
		var saved_seed := int(get_node("/root/SaveData").get("current_seed"))
		if saved_seed > 0:
			world_seed = saved_seed
	_rng.seed = world_seed
	_generate_chunk(-CHUNK_WIDTH)
	generated_to = 0.0
	while generated_to < 3600.0:
		_generate_chunk(generated_to)
		generated_to += CHUNK_WIDTH

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	while generated_to < player.global_position.x + 3000.0:
		_generate_chunk(generated_to)
		generated_to += CHUNK_WIDTH
	for chunk in chunks.duplicate():
		if chunk.position.x + CHUNK_WIDTH < player.global_position.x - 1500.0:
			chunks.erase(chunk)
			chunk.queue_free()
	var biome := HavenTheme.biome_index_at(player.global_position.x)
	if biome != _last_biome:
		_last_biome = biome
		biome_changed.emit(biome, HavenTheme.BIOME_NAMES[biome])

# --------------------------------------------------------------------------
# Public terrain queries
# --------------------------------------------------------------------------

func ground_height(world_x: float) -> float:
	var x := maxf(world_x, 0.0)
	var slope := 0.098 + clampf(x / 160000.0, 0.0, 1.0) * 0.042
	var y := START_Y + x * slope
	var rolling := sin(x * 0.00185 + 0.62) * 48.0
	rolling += sin(x * 0.0046 + 2.1) * 17.0
	rolling += sin(x * 0.0091 + 1.05) * 5.5
	var biome := HavenTheme.biome_index_at(x)
	match biome:
		1:
			rolling += sin(x * 0.0011 + 0.4) * 14.0
		2:
			rolling += sin(x * 0.00085 + 2.8) * 24.0
		3:
			rolling += sin(x * 0.0012 + 1.1) * 16.0
		4:
			rolling += sin(x * 0.0007 + 2.2) * 30.0
		5:
			rolling += sin(x * 0.00135 + 3.1) * 12.0
		6:
			rolling += sin(x * 0.0015 + 0.8) * 10.0
		7:
			rolling += sin(x * 0.0009 + 2.4) * 19.0
	return y + rolling + _bump_feature(x)

func slope_at(world_x: float) -> float:
	var epsilon := 8.0
	return atan2(ground_height(world_x + epsilon) - ground_height(world_x - epsilon), epsilon * 2.0)

func slope_tangent_at(world_x: float) -> Vector2:
	return Vector2(1.0, ground_height(world_x + 6.0) - ground_height(world_x - 6.0)).normalized()

func biome_name_at(world_x: float) -> String:
	return HavenTheme.biome_name_at(world_x)

func biome_index_at(world_x: float) -> int:
	return HavenTheme.biome_index_at(world_x)

func distance_at(world_x: float) -> int:
	return int(maxf(world_x, 0.0) / 10.0)

func kill_y_at(world_x: float) -> float:
	return ground_height(world_x) + 650.0

func is_gap_at(world_x: float) -> bool:
	var segment := floori(world_x / SEGMENT_LENGTH)
	var gap := _gap_for_segment(segment)
	if gap.x < 0.0:
		return false
	return world_x >= gap.x and world_x <= gap.x + gap.y

func is_over_gap(world_x: float) -> bool:
	return is_gap_at(world_x)

# --------------------------------------------------------------------------
# Generation
# --------------------------------------------------------------------------

func _generate_chunk(start_x: float) -> void:
	var chunk := TerrainChunk.new()
	chunk.name = "Chunk%d" % int(start_x)
	chunk.position.x = start_x
	add_child(chunk)
	chunks.append(chunk)
	var end_x := start_x + CHUNK_WIDTH
	var gaps := _gaps_in_range(start_x, end_x)
	var local_gaps: Array[Vector2] = []
	for gap in gaps:
		local_gaps.append(Vector2(gap.x - start_x, gap.y))
	var strips := _build_strips(start_x, end_x, gaps)
	var bottom := _chunk_bottom(strips)
	var palette := HavenTheme.palette_at(start_x + CHUNK_WIDTH * 0.5)
	chunk.setup(strips, local_gaps, bottom, palette, CHUNK_WIDTH, float(world_seed) + start_x * 0.013 + 451.0)
	var chunk_index := int(start_x / CHUNK_WIDTH)
	_place_obstacles(chunk, start_x, chunk_index, palette, gaps)
	_place_pickups(chunk, start_x, chunk_index, palette, gaps)
	_place_decor(chunk, start_x, chunk_index, palette, gaps)

func _build_strips(start_x: float, end_x: float, gaps: Array[Vector2]) -> Array[PackedVector2Array]:
	var intervals: Array[Vector2] = []
	var cursor := start_x
	for gap in gaps:
		var gap_start := maxf(gap.x, start_x)
		var gap_end := minf(gap.x + gap.y, end_x)
		if gap_start > cursor + 1.0:
			intervals.append(Vector2(cursor, gap_start))
		cursor = maxf(cursor, gap_end)
	if cursor < end_x - 1.0:
		intervals.append(Vector2(cursor, end_x))
	var strips: Array[PackedVector2Array] = []
	for interval in intervals:
		var points := PackedVector2Array()
		var x := interval.x
		while x < interval.y - 0.1:
			points.append(Vector2(x - start_x, ground_height(x)))
			x += SAMPLE_STEP
		points.append(Vector2(interval.y - start_x, ground_height(interval.y)))
		if points.size() >= 2:
			strips.append(points)
	return strips

func _chunk_bottom(strips: Array[PackedVector2Array]) -> float:
	var highest := 0.0
	for surface in strips:
		for point in surface:
			highest = maxf(highest, point.y)
	return highest + BOTTOM_MARGIN

func _gaps_in_range(start_x: float, end_x: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var first_segment := floori((start_x - SEGMENT_LENGTH) / SEGMENT_LENGTH)
	var last_segment := floori((end_x + SEGMENT_LENGTH) / SEGMENT_LENGTH)
	for segment in range(first_segment, last_segment + 1):
		var gap := _gap_for_segment(segment)
		if gap.x < 0.0:
			continue
		if gap.x < end_x and gap.x + gap.y > start_x:
			result.append(gap)
	return result

func _gap_for_segment(segment: int) -> Vector2:
	if segment < 3:
		return Vector2(-1.0, 0.0)
	var seed_offset := float(world_seed % 997) * 0.017
	var chance := HavenTheme.hash01(float(segment) * 8.31 + 2.7 + seed_offset)
	if chance > 0.40:
		return Vector2(-1.0, 0.0)
	var segment_start := float(segment) * SEGMENT_LENGTH
	var offset := 650.0 + HavenTheme.hash01(float(segment) * 3.77 + 5.1 + seed_offset) * 560.0
	var width := 150.0 + minf(float(segment), 18.0) * 6.0 + HavenTheme.hash01(float(segment) * 5.93 + 1.4 + seed_offset) * 80.0
	var gap_start := segment_start + offset
	# Keep the full chasm inside a single painted chunk so both cliff lips stay visible.
	var chunk_local := fposmod(gap_start, CHUNK_WIDTH)
	if chunk_local < 90.0:
		gap_start += 90.0 - chunk_local
	elif chunk_local + width > CHUNK_WIDTH - 90.0:
		gap_start -= (chunk_local + width) - (CHUNK_WIDTH - 90.0)
	return Vector2(gap_start, width)

func _bump_feature(world_x: float) -> float:
	var segment := floori(world_x / SEGMENT_LENGTH)
	var local := fposmod(world_x, SEGMENT_LENGTH)
	var roll := HavenTheme.hash01(float(segment) * 5.31 + 1.7)
	if roll < 0.20:
		return 0.0
	var start := 340.0 + HavenTheme.hash01(float(segment) * 7.7 + 3.3) * 360.0
	var width := 280.0 + HavenTheme.hash01(float(segment) * 9.1 + 1.3) * 140.0
	if local < start or local > start + width:
		return 0.0
	var t := (local - start) / width
	var height := 42.0 + HavenTheme.hash01(float(segment) * 2.9 + 9.0) * 46.0
	if t < 0.68:
		return -height * smoothstep(0.0, 0.68, t)
	return -height * (1.0 - smoothstep(0.68, 1.0, t))

# --------------------------------------------------------------------------
# World dressing
# --------------------------------------------------------------------------

func _place_obstacles(
	chunk: Node2D,
	start_x: float,
	chunk_index: int,
	palette: Dictionary,
	gaps: Array[Vector2]
) -> void:
	if start_x < 2500.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world_seed + chunk_index * 7919 + 17)
	var biome := HavenTheme.biome_index_at(start_x + 500.0)
	var difficulty := clampf(start_x / 65000.0, 0.0, 1.0)
	var count := 0
	if rng.randf() < 0.32 + difficulty * 0.30:
		count += 1
	if start_x > 14000.0 and rng.randf() < 0.16 + difficulty * 0.26:
		count += 1
	var used_x: Array[float] = []
	for i in range(count):
		var attempts := 0
		var local_x := 0.0
		while attempts < 6:
			local_x = rng.randf_range(170.0, CHUNK_WIDTH - 170.0)
			var world_x := start_x + local_x
			if _in_any_gap(world_x, 130.0, gaps, start_x):
				attempts += 1
				continue
			var too_close := false
			for other in used_x:
				if absf(other - local_x) < 230.0:
					too_close = true
					break
			if too_close:
				attempts += 1
				continue
			break
		if attempts >= 6:
			continue
		used_x.append(local_x)
		var world_x := start_x + local_x
		var kind := "boulder"
		var roll := rng.randf()
		if roll < 0.11 and start_x > 5000.0:
			kind = "bounce"
		elif biome == 1 and roll < 0.42:
			kind = "pillar"
		elif biome == 3 and roll < 0.34:
			kind = "pillar"
		var obstacle := Obstacle.new()
		chunk.add_child(obstacle)
		obstacle.position = Vector2(local_x, ground_height(world_x))
		obstacle.setup(kind, palette, rng.randf_range(0.86, 1.12), float(chunk_index * 13 + i * 7))
		_place_obstacle_coins(chunk, start_x, local_x, world_x, palette, kind)

func _in_any_gap(world_x: float, margin: float, gaps: Array[Vector2], _start_x: float) -> bool:
	if is_gap_at(world_x):
		return true
	for gap in gaps:
		if world_x + margin > gap.x and world_x - margin < gap.x + gap.y:
			return true
	return false

func _place_obstacle_coins(
	chunk: Node2D,
	start_x: float,
	local_x: float,
	world_x: float,
	palette: Dictionary,
	kind: String
) -> void:
	# A gentle arc of coins makes every obstacle readable before it arrives.
	for i in range(4):
		var offset := (float(i) - 1.5) * 34.0
		var coin_x := local_x + offset
		var wx := start_x + coin_x
		if coin_x < 16.0 or coin_x > CHUNK_WIDTH - 16.0 or is_gap_at(wx):
			continue
		var arc := 56.0 + sin((float(i) + 0.5) / 4.0 * PI) * 34.0
		if kind == "bounce":
			arc += 12.0
		_spawn_pickup(chunk, "coin", 1, coin_x, ground_height(wx) - arc, palette, float(i) * 0.8)

func _place_pickups(
	chunk: Node2D,
	start_x: float,
	chunk_index: int,
	palette: Dictionary,
	gaps: Array[Vector2]
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world_seed + chunk_index * 3571 + 91)
	# Chasm arcs always point to a clean landing.
	for gap in gaps:
		var gap_start := gap.x
		var gap_end := gap.x + gap.y
		if gap_start < start_x or gap_start > start_x + CHUNK_WIDTH:
			continue
		var arc_span := gap.y + 100.0
		var arc_height := 74.0 + gap.y * 0.18
		var count := 8
		for i in range(count):
			var t := float(i) / float(count - 1)
			var wx := gap_start - 50.0 + t * arc_span
			if wx < start_x + 16.0 or wx > start_x + CHUNK_WIDTH - 16.0:
				continue
			var end_high := ground_height(gap_end + 60.0)
			var start_high := ground_height(gap_start - 60.0)
			var base_y := lerpf(start_high, end_high, t)
			var arc_y := base_y - sin(t * PI) * arc_height - 46.0
			_spawn_pickup(chunk, "coin", 1, wx - start_x, arc_y, palette, t * 2.0)
		_spawn_pickup(
			chunk,
			"shard",
			3,
			clampf(gap_start + gap.y * 0.5 - start_x, 30.0, CHUNK_WIDTH - 30.0),
			ground_height(gap_start + gap.y * 0.5) - (arc_height + 70.0),
			palette,
			1.0
		)
	# Sand trails: low, rhythmic coin lines following the terrain.
	var patterns := 2 if rng.randf() < 0.55 else 1
	for p in range(patterns):
		var attempts := 0
		var origin := 0.0
		while attempts < 8:
			origin = rng.randf_range(120.0, CHUNK_WIDTH - 320.0)
			var world_origin := start_x + origin
			if not _in_any_gap(world_origin, 90.0, gaps, start_x) and not is_gap_at(world_origin + 260.0):
				break
			attempts += 1
		if attempts >= 8:
			continue
		var count := 6
		for i in range(count):
			var local_x := origin + float(i) * 38.0
			var wx := start_x + local_x
			if local_x > CHUNK_WIDTH - 20.0 or is_gap_at(wx):
				continue
			var ground := ground_height(wx)
			var height := 62.0 + sin(float(i) * 0.62 + float(p)) * 14.0 + float(p) * 8.0
			_spawn_pickup(chunk, "coin", 1, local_x, ground - height, palette, float(i) * 0.55 + float(p))
	var shard_roll := rng.randf()
	if shard_roll < 0.34 or (chunk_index % 4 == 0):
		var local_x := rng.randf_range(180.0, CHUNK_WIDTH - 180.0)
		var wx := start_x + local_x
		if not is_gap_at(wx):
			_spawn_pickup(chunk, "shard", 3, local_x, ground_height(wx) - 158.0, palette, 0.3)

func _spawn_pickup(
	chunk: Node2D,
	kind: String,
	value: int,
	local_x: float,
	y: float,
	palette: Dictionary,
	phase: float
) -> void:
	var pickup := Pickup.new()
	chunk.add_child(pickup)
	pickup.position = Vector2(local_x, y)
	pickup.setup(kind, palette, value, phase)
	pickup.collected.connect(_on_pickup_collected)

func _place_decor(
	chunk: Node2D,
	start_x: float,
	chunk_index: int,
	palette: Dictionary,
	gaps: Array[Vector2]
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world_seed + chunk_index * 1811 + 53)
	var biome := HavenTheme.biome_index_at(start_x + 500.0)
	var kinds: Array[String] = []
	match biome:
		0:
			kinds = ["palm", "palm", "tent", "rocks", "reeds"]
		1:
			kinds = ["ruins", "ruins", "deadwood", "rocks"]
		2:
			kinds = ["pine", "pine", "pine", "rocks"]
		3:
			kinds = ["lantern", "palm", "ruins", "rocks"]
		4:
			kinds = ["rocks", "ruins", "deadwood", "reeds"]
		5:
			kinds = ["deadwood", "deadwood", "rocks", "reeds"]
		6:
			kinds = ["ruins", "palm", "lantern", "rocks"]
		7:
			kinds = ["pine", "deadwood", "rocks", "pine"]
	var count := 1 + (1 if rng.randf() < 0.55 else 0)
	for i in range(count):
		var local_x := rng.randf_range(80.0, CHUNK_WIDTH - 80.0)
		var wx := start_x + local_x
		if _in_any_gap(wx, 55.0, gaps, start_x):
			continue
		var decor := TerrainDecor.new()
		chunk.add_child(decor)
		decor.position = Vector2(local_x, ground_height(wx) + 1.0)
		var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		decor.setup(kind, palette, rng.randf_range(0.62, 0.98), rng.randf_range(0.68, 0.92), float(chunk_index) + float(i) * 3.7)

# --------------------------------------------------------------------------
# Pickup feedback
# --------------------------------------------------------------------------

func _on_pickup_collected(kind: String, value: int, world_position: Vector2) -> void:
	var burst := PickupBurst.new()
	add_child(burst)
	burst.position = to_local(world_position)
	burst.setup(Color(1.0, 0.82, 0.40) if kind == "coin" else Color(0.52, 0.96, 1.0), 9 if kind == "coin" else 13, 0.9 if kind == "coin" else 1.3)
	pickup_collected.emit(kind, value, world_position)
