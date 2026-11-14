extends Node2D
class_name RiderArt

## Original vector-illustrated sandboarder. The rider is drawn in layers with
## articulated limbs, a wind-driven scarf, a painted board and an opening
## wingsuit membrane. Poses are smoothly blended, so every state reads as a
## continuous performance rather than a sprite flip.

const RIDER_IDS := ["wayfarer", "mirage", "ember"]

const RIDERS := [
	{
		"id": "wayfarer",
		"name": "THE WAYFARER",
		"tagline": "Ochre dust, an old promise, and the long way home.",
		"cloak": Color(0.086, 0.235, 0.247),
		"cloak_dark": Color(0.048, 0.140, 0.167),
		"cloak_light": Color(0.180, 0.392, 0.388),
		"pants": Color(0.070, 0.090, 0.129),
		"skin": Color(0.545, 0.341, 0.235),
		"skin_light": Color(0.741, 0.518, 0.359),
		"scarf": Color(0.937, 0.396, 0.286),
		"scarf_dark": Color(0.686, 0.224, 0.188),
		"boots": Color(0.229, 0.145, 0.121),
		"leather": Color(0.396, 0.239, 0.165),
		"gold": Color(0.961, 0.741, 0.392),
		"lens": Color(0.459, 0.792, 0.780),
		"board": Color(0.529, 0.278, 0.145),
		"board_top": Color(0.804, 0.475, 0.231),
		"board_trim": Color(0.965, 0.769, 0.428),
		"wing": Color(0.937, 0.533, 0.286),
		"wing_dark": Color(0.663, 0.271, 0.196),
	},
	{
		"id": "mirage",
		"name": "THE MIRAGE",
		"tagline": "Sun on the shoulders, a bright line down the mountain.",
		"cloak": Color(0.365, 0.176, 0.133),
		"cloak_dark": Color(0.235, 0.100, 0.086),
		"cloak_light": Color(0.565, 0.325, 0.220),
		"pants": Color(0.137, 0.105, 0.102),
		"skin": Color(0.663, 0.435, 0.298),
		"skin_light": Color(0.827, 0.596, 0.408),
		"scarf": Color(0.965, 0.847, 0.651),
		"scarf_dark": Color(0.741, 0.549, 0.380),
		"boots": Color(0.271, 0.161, 0.114),
		"leather": Color(0.514, 0.306, 0.184),
		"gold": Color(0.988, 0.828, 0.506),
		"lens": Color(0.965, 0.678, 0.341),
		"board": Color(0.259, 0.196, 0.161),
		"board_top": Color(0.561, 0.373, 0.224),
		"board_trim": Color(0.937, 0.694, 0.353),
		"wing": Color(0.949, 0.702, 0.392),
		"wing_dark": Color(0.690, 0.373, 0.220),
	},
	{
		"id": "ember",
		"name": "THE NIGHTBIRD",
		"tagline": "A cyan thread through the quietest night.",
		"cloak": Color(0.114, 0.133, 0.243),
		"cloak_dark": Color(0.053, 0.067, 0.145),
		"cloak_light": Color(0.231, 0.263, 0.435),
		"pants": Color(0.059, 0.067, 0.114),
		"skin": Color(0.435, 0.282, 0.208),
		"skin_light": Color(0.631, 0.443, 0.310),
		"scarf": Color(0.384, 0.855, 0.875),
		"scarf_dark": Color(0.180, 0.541, 0.663),
		"boots": Color(0.118, 0.098, 0.129),
		"leather": Color(0.239, 0.204, 0.290),
		"gold": Color(0.769, 0.890, 0.945),
		"lens": Color(0.459, 0.890, 0.929),
		"board": Color(0.153, 0.122, 0.224),
		"board_top": Color(0.310, 0.259, 0.420),
		"board_trim": Color(0.631, 0.812, 0.910),
		"wing": Color(0.553, 0.745, 0.867),
		"wing_dark": Color(0.259, 0.376, 0.557),
	},
]

var animation_state := "idle"
var speed_ratio := 0.0
var boost := 0.0
var character_index := 0

var _palette: Dictionary = RIDERS[0]
var _time := 0.0
var _crouch := 0.12
var _tuck := 0.0
var _arm_spread := 0.3
var _lean := 0.1
var _flourish := 0.0
var _wing := 0.0
var _fall := 0.0
var _board_y := 44.0

func _ready() -> void:
	z_index = 1
	set_process(true)

static func rider_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in RIDERS:
		ids.append(String(entry["id"]))
	return ids

static func rider_index(rider_id: String) -> int:
	for index in range(RIDERS.size()):
		if String(RIDERS[index]["id"]) == rider_id:
			return index
	return 0

static func rider_details(rider_id: String) -> Dictionary:
	return RIDERS[rider_index(rider_id)]

func apply_character(index: int) -> void:
	character_index = clampi(index, 0, RIDERS.size() - 1)
	_palette = RIDERS[character_index]
	queue_redraw()

func set_rider(rider_id: String) -> void:
	apply_character(rider_index(rider_id))

func set_animation_state(state_name: String) -> void:
	animation_state = state_name

func _process(delta: float) -> void:
	_time += delta
	var targets := _targets_for_state()
	var ease := 1.0 - exp(-11.0 * delta)
	_crouch = lerpf(_crouch, float(targets.crouch), ease)
	_tuck = lerpf(_tuck, float(targets.tuck), ease)
	_arm_spread = lerpf(_arm_spread, float(targets.arms), ease)
	_lean = lerpf(_lean, float(targets.lean), ease)
	_flourish = lerpf(_flourish, float(targets.flourish), ease)
	_wing = lerpf(_wing, float(targets.wing), 1.0 - exp(-7.0 * delta))
	_fall = lerpf(_fall, float(targets.fall), ease)
	queue_redraw()

func _targets_for_state() -> Dictionary:
	var crouch := 0.12 + clampf(speed_ratio, 0.0, 1.0) * 0.20 + boost * 0.10
	var arms := 0.30
	var tuck := 0.0
	var lean := 0.10 + clampf(speed_ratio, 0.0, 1.0) * 0.07
	var flourish := 0.0
	var wing := 0.0
	var fall := 0.0
	match animation_state:
		"idle":
			crouch = 0.10
			arms = 0.22
			lean = 0.06
		"ride":
			pass
		"accelerate":
			crouch = 0.34
			arms = 0.14
			lean = 0.20
		"jump_prep":
			crouch = 0.60
			arms = 0.40
			lean = 0.22
		"jump":
			crouch = 0.20
			arms = 0.72
			lean = 0.04
			tuck = 0.16
		"flip":
			crouch = 0.30
			arms = 0.52
			lean = 0.30
			tuck = 0.82
		"fall":
			crouch = 0.14
			arms = 0.92
			lean = -0.05
			tuck = 0.12
			fall = 1.0
		"land":
			crouch = 0.62
			arms = 0.52
			lean = 0.22
			flourish = 0.0
		"perfect":
			crouch = 0.36
			arms = 0.34
			lean = 0.02
			flourish = 1.0
		"crash":
			crouch = 0.70
			arms = 0.95
			lean = 0.48
			fall = 0.6
		"wingsuit_deploy":
			crouch = 0.16
			arms = 1.0
			lean = -0.10
			wing = 1.0
		"wingsuit":
			crouch = 0.08
			arms = 1.0
			lean = -0.14
			wing = 1.0
		"wingsuit_land":
			crouch = 0.65
			arms = 0.4
			lean = 0.2
			wing = 0.25
		_:
			pass
	return {
		"crouch": crouch,
		"tuck": tuck,
		"arms": arms,
		"lean": lean,
		"flourish": flourish,
		"wing": wing,
		"fall": fall,
	}

func _draw() -> void:
	var crouch := _crouch
	var tuck := _tuck
	var lean := _lean
	var hips := Vector2(0.0, 9.0 + crouch * 8.0 - tuck * 3.0)
	var shoulder := hips + Vector2(0.0, -37.0).rotated(lean * 0.65)
	var neck := hips + Vector2(0.0, -44.0).rotated(lean * 0.65)
	var head := neck + Vector2(1.6, -9.0)
	_board_y = 44.0 - tuck * 20.0 - crouch * 0.5
	var foot_y := _board_y - 5.0
	var back_foot := Vector2(-14.0, foot_y)
	var front_foot := Vector2(15.5, foot_y - 1.0)
	var back_knee := (hips + Vector2(-5.0, 0.0)).lerp(back_foot, 0.52) + Vector2(-8.0, -4.0 - tuck * 8.0)
	var front_knee := (hips + Vector2(5.0, 0.0)).lerp(front_foot, 0.52) + Vector2(9.0, -3.0 - tuck * 9.0)
	var back_shoulder := shoulder + Vector2(-7.5, -2.0).rotated(lean * 0.5)
	var front_shoulder := shoulder + Vector2(8.0, -2.0).rotated(lean * 0.5)
	var back_hand := _hand_target("back", hips, foot_y, shoulder)
	var front_hand := _hand_target("front", hips, foot_y, shoulder)
	var back_elbow := (back_shoulder + back_hand) * 0.5 + Vector2(-7.0, 5.0) * (1.0 - _wing * 0.7)
	var front_elbow := (front_shoulder + front_hand) * 0.5 + Vector2(8.0, 4.0) * (1.0 - _wing * 0.7)
	var wing_back := _wing > 0.015

	_draw_scarf(neck, head, lean)
	if wing_back:
		_draw_wingsuit_web(back_shoulder, back_hand, back_knee, back_foot, hips, true)
	_draw_board()
	# Back arm behind the body.
	_draw_arm(back_shoulder, back_elbow, back_hand, _palette.cloak_dark, _palette.leather)
	# Back leg.
	_draw_leg(hips + Vector2(-5.0, 0.0), back_knee, back_foot, true)
	_draw_cloak(hips, shoulder, neck, lean)
	# Front leg.
	_draw_leg(hips + Vector2(5.0, 0.0), front_knee, front_foot, false)
	_draw_torso(hips, shoulder, neck, lean)
	if wing_back:
		_draw_wingsuit_web(front_shoulder, front_hand, front_knee, front_foot, hips, false)
	_draw_arm(front_shoulder, front_elbow, front_hand, _palette.cloak, _palette.gold)
	_draw_head(head, lean)
	_draw_rim_light(hips, shoulder, neck, back_hand, front_hand, back_foot, front_foot)
	_draw_board_details()

func _hand_target(side: String, hips: Vector2, foot_y: float, shoulder: Vector2) -> Vector2:
	var spread := _arm_spread
	var flourish := _flourish
	if _wing > 0.2:
		var wing_spread := _wing
		if side == "back":
			return shoulder + Vector2(-34.0 - 8.0 * wing_spread, 11.0 + _fall * 2.0).rotated(0.0)
		return shoulder + Vector2(34.0 + 8.0 * wing_spread, 10.0).rotated(0.0)
	var ride_back := Vector2(-25.0, -9.0) - hips
	var ride_front := Vector2(23.0, -18.0) - hips
	var air_scale := clampf(_fall, 0.0, 1.0)
	var back_target := hips + ride_back.lerp(Vector2(-26.0, -28.0), air_scale) + Vector2(-7.0, -6.0) * spread
	var front_target := hips + ride_front.lerp(Vector2(27.0, -33.0), air_scale) + Vector2(7.0, -6.0) * spread
	if _tuck > 0.35:
		var tuck_hand := foot_y - 15.0
		back_target = back_target.lerp(Vector2(-14.0, tuck_hand), (_tuck - 0.35) / 0.65)
		front_target = front_target.lerp(Vector2(15.0, tuck_hand - 1.0), (_tuck - 0.35) / 0.65)
	if flourish > 0.01:
		front_target = front_target.lerp(shoulder + Vector2(24.0, -33.0), flourish)
		back_target = back_target.lerp(shoulder + Vector2(-22.0, 8.0), flourish * 0.5)
	if side == "back":
		back_target.y += sin(_time * 2.0) * 1.2 * (1.0 - _tuck)
		return back_target
	return front_target + Vector2(0.0, sin(_time * 2.3 + 1.4) * 1.2 * (1.0 - _tuck))

func _draw_scarf(neck: Vector2, head: Vector2, _lean: float) -> void:
	var scarf: Color = _palette.scarf
	var dark: Color = _palette.scarf_dark
	var root := neck + Vector2(-3.0, 2.0).rotated(_lean * 0.4)
	var wing := _wing
	var gust := 1.0 + clampf(speed_ratio, 0.0, 1.0) * 0.9 + wing * 0.6
	for strand in range(2):
		var pts := PackedVector2Array()
		var count := 5
		for i in range(count + 1):
			var t := float(i) / float(count)
			var p: Vector2
			if wing > 0.2:
				var wing_base := Vector2(root.x - 2.0 + sin(_time * 5.5 + t * 4.0 + float(strand) * 1.3) * (3.0 + t * 6.0), root.y + t * (22.0 + float(strand) * 4.0) * (0.7 + wing * 0.6))
				var ground_p := root + Vector2(-t * (30.0 + float(strand) * 5.0) * gust, sin(_time * 6.5 + t * 4.2 + float(strand) * 1.1) * (1.5 + t * 4.0) + t * (6.0 + float(strand) * 2.0))
				p = ground_p.lerp(wing_base, wing)
			else:
				p = root + Vector2(
					-t * (30.0 + float(strand) * 5.0) * gust,
					sin(_time * 6.5 + t * 4.2 + float(strand) * 1.1) * (1.5 + t * 4.0) + t * (6.0 + float(strand) * 2.0)
				)
			pts.append(p)
		var back: Array[Vector2] = []
		for i in range(pts.size()):
			var width := lerpf(3.8, 0.7, float(i) / float(pts.size() - 1))
			if i < 2:
				width += 1.2
			back.append(pts[i] + Vector2(0.0, width))
		var forward := pts.duplicate()
		for i in range(back.size() - 1, -1, -1):
			forward.append(back[i])
		draw_colored_polygon(forward, Color(scarf.r, scarf.g, scarf.b, 0.92) if strand == 0 else Color(dark.r, dark.g, dark.b, 0.52))
		if strand == 0:
			var edge := PackedVector2Array()
			for i in range(pts.size()):
				edge.append(pts[i] + Vector2(0.0, -0.8))
			draw_polyline(edge, Color(1.0, 0.78, 0.57, 0.30), 0.8, true)

func _draw_wingsuit_web(
	shoulder: Vector2,
	hand: Vector2,
	_knee: Vector2,
	foot: Vector2,
	hips: Vector2,
	back: bool
) -> void:
	var wing_color: Color = _palette.wing_dark if back else _palette.wing
	var alpha := 0.64 if back else 0.78
	var anchor := hips + Vector2(0.0, -5.0)
	var points := PackedVector2Array([
		shoulder,
		hand,
		hand.lerp(foot, 0.56) + Vector2(0.0, 5.0),
		foot,
		anchor,
	])
	draw_colored_polygon(points, Color(wing_color.r, wing_color.g, wing_color.b, alpha * _wing))
	draw_polyline(points, Color(_palette.gold.r, _palette.gold.g, _palette.gold.b, 0.42 * _wing), 1.2, true)
	# Membrane ribs.
	for i in range(3):
		var t := 0.22 + float(i) * 0.22
		var a := shoulder.lerp(hand, t)
		var b := anchor.lerp(foot, t) + Vector2(0.0, -2.0)
		draw_line(a, b, Color(_palette.gold.r, _palette.gold.g, _palette.gold.b, 0.16 * _wing), 1.0, true)
	draw_circle(hand, 4.0, Color(wing_color.r, wing_color.g, wing_color.b, 0.55 * _wing))

func _draw_board() -> void:
	var y := _board_y
	var dark: Color = _palette.cloak_dark
	var wood: Color = _palette.board
	var top: Color = _palette.board_top
	var trim: Color = _palette.board_trim
	var under := PackedVector2Array([
		Vector2(-43.0, y + 2.0), Vector2(-36.0, y + 7.0), Vector2(31.0, y + 7.0),
		Vector2(45.0, y + 2.0), Vector2(38.0, y + 9.0), Vector2(-34.0, y + 9.0),
	])
	draw_colored_polygon(under, Color(dark.r, dark.g, dark.b, 0.95))
	var deck := PackedVector2Array([
		Vector2(-42.0, y + 1.0), Vector2(-35.0, y - 4.0), Vector2(-20.0, y - 5.5),
		Vector2(22.0, y - 5.0), Vector2(36.0, y - 2.0), Vector2(44.0, y + 2.5),
		Vector2(36.0, y + 5.0), Vector2(-34.0, y + 6.0),
	])
	draw_colored_polygon(deck, wood)
	var deck_top := PackedVector2Array([
		Vector2(-34.0, y - 1.5), Vector2(-22.0, y - 4.0), Vector2(24.0, y - 3.7),
		Vector2(34.0, y - 1.0), Vector2(37.0, y + 1.2), Vector2(-32.0, y + 2.0),
	])
	draw_colored_polygon(deck_top, top)
	draw_line(Vector2(-36.0, y + 1.0), Vector2(37.0, y + 1.0), Color(trim.r, trim.g, trim.b, 0.92), 1.3, true)
	draw_line(Vector2(-18.0, y + 4.2), Vector2(24.0, y + 4.0), Color(trim.r, trim.g, trim.b, 0.36), 1.0, true)
	# Nose and tail inlay.
	draw_colored_polygon(PackedVector2Array([
		Vector2(28.0, y - 3.0), Vector2(36.0, y - 1.0), Vector2(39.0, y + 2.0),
		Vector2(31.0, y + 3.0),
	]), Color(trim.r, trim.g, trim.b, 0.60))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-42.0, y + 1.0), Vector2(-34.0, y - 2.0), Vector2(-28.0, y + 2.0),
		Vector2(-36.0, y + 5.0),
	]), Color(trim.r, trim.g, trim.b, 0.36))
	# Nose lift highlight.
	draw_line(Vector2(30.0, y - 2.4), Vector2(43.0, y + 2.2), Color(1.0, 0.9, 0.68, 0.55), 1.2, true)

func _draw_board_details() -> void:
	var y := _board_y
	var grip: Color = _palette.cloak_dark
	draw_line(Vector2(-18.0, y - 4.7), Vector2(-8.0, y - 4.9), Color(grip.r, grip.g, grip.b, 0.8), 2.2, true)
	draw_line(Vector2(8.0, y - 4.5), Vector2(17.0, y - 4.4), Color(grip.r, grip.g, grip.b, 0.8), 2.2, true)
	draw_circle(Vector2(-36.0, y + 1.4), 1.5, Color(_palette.gold.r, _palette.gold.g, _palette.gold.b, 0.8))

func _draw_cloak(hips: Vector2, shoulder: Vector2, neck: Vector2, lean: float) -> void:
	var cloak: Color = _palette.cloak
	var dark: Color = _palette.cloak_dark
	var light: Color = _palette.cloak_light
	var sway := sin(_time * 4.2) * 1.8 + clampf(speed_ratio, 0.0, 1.0) * 3.0
	var hem := hips + Vector2(-8.0 - sway, 25.0)
	var tail := hips + Vector2(-27.0 - sway * 1.8, 19.0)
	var waist := hips + Vector2(-8.0, 0.0)
	var left_shoulder := shoulder + Vector2(-10.0, 3.0)
	var right_hip := hips + Vector2(9.0, 10.0)
	var points := PackedVector2Array([
		left_shoulder,
		shoulder + Vector2(-1.0, -5.0),
		shoulder + Vector2(8.0, 0.0),
		waist + Vector2(14.0, 2.0),
		right_hip,
		hips + Vector2(5.0, 18.0),
		hem,
		tail,
		hips + Vector2(-13.0, 3.0),
	])
	draw_colored_polygon(points, cloak)
	# Ragged hem.
	for i in range(3):
		var x := -24.0 + float(i) * 8.0 + sway
		draw_line(hips + Vector2(x, 19.0), hips + Vector2(x + 2.0, 25.0 + sin(_time * 3.0 + float(i)) * 2.0), Color(dark.r, dark.g, dark.b, 0.9), 2.0, true)
	# Wind-fold highlights.
	var fold := PackedVector2Array([
		left_shoulder + Vector2(1.0, 2.0),
		hips + Vector2(-15.0, 16.0),
		hips + Vector2(-10.0, 19.0),
		shoulder + Vector2(4.0, 1.0),
	])
	draw_colored_polygon(fold, Color(light.r, light.g, light.b, 0.38))
	draw_line(neck + Vector2(-7.0, 1.0), hips + Vector2(-16.0, 18.0), Color(light.r, light.g, light.b, 0.25), 1.2, true)

func _draw_torso(hips: Vector2, shoulder: Vector2, neck: Vector2, lean: float) -> void:
	var cloak: Color = _palette.cloak
	var light: Color = _palette.cloak_light
	var gold: Color = _palette.gold
	var torso := PackedVector2Array([
		shoulder + Vector2(-7.5, 1.0),
		shoulder + Vector2(0.0, -5.0),
		shoulder + Vector2(8.0, 0.0),
		hips + Vector2(10.0, -2.0),
		hips + Vector2(7.0, 9.0),
		hips + Vector2(-7.0, 9.0),
		hips + Vector2(-9.0, -2.0),
	])
	draw_colored_polygon(torso, cloak)
	var chest := PackedVector2Array([
		shoulder + Vector2(-3.0, 3.0),
		shoulder + Vector2(6.0, 1.0),
		hips + Vector2(6.5, -8.0),
		hips + Vector2(-2.0, -8.0),
	])
	draw_colored_polygon(chest, Color(light.r, light.g, light.b, 0.22))
	# Sash and knot.
	draw_polyline(PackedVector2Array([
		hips + Vector2(-8.0, -1.0),
		hips + Vector2(0.0, 2.0),
		hips + Vector2(8.5, -1.0),
	]), Color(gold.r, gold.g, gold.b, 0.8), 2.6, true)
	draw_circle(hips + Vector2(-1.0, 2.0), 2.0, Color(gold.r, gold.g, gold.b, 0.9))
	# Talisman at the belt.
	draw_line(hips + Vector2(6.0, 4.0), hips + Vector2(9.0, 13.0), Color(gold.r, gold.g, gold.b, 0.45), 1.0, true)
	draw_circle(hips + Vector2(9.0, 15.0), 2.1, Color(gold.r, gold.g, gold.b, 0.68))
	# Collar wrap.
	draw_arc(neck, 8.0, 0.2, PI * 0.95, 12, Color(cloak.r, cloak.g, cloak.b, 0.95), 2.4, true)
	# Shoulder seam.
	draw_line(shoulder + Vector2(-6.0, 3.0), shoulder + Vector2(7.0, 3.5), Color(0.0, 0.0, 0.0, 0.18), 1.0, true)

func _draw_leg(hip: Vector2, knee: Vector2, foot: Vector2, back: bool) -> void:
	var pants: Color = _palette.pants
	var boots: Color = _palette.boots
	var leather: Color = _palette.leather
	_draw_limb(hip, knee, 7.2 if not back else 6.4, pants.darkened(0.10 if not back else 0.22))
	_draw_limb(knee, foot + Vector2(0.0, -3.0), 5.8 if not back else 5.2, pants.darkened(0.03 if not back else 0.16))
	# Boot with an angular toe.
	var direction := 1.0 if foot.x > hip.x else -1.0
	var boot := PackedVector2Array([
		foot + Vector2(-5.0, -7.0),
		foot + Vector2(5.0, -7.0),
		foot + Vector2(6.0, 0.0),
		foot + Vector2(11.0, 1.5),
		foot + Vector2(5.0, 4.0),
		foot + Vector2(-5.0, 4.0),
	])
	draw_colored_polygon(boot, boots)
	draw_line(foot + Vector2(-4.0, -5.0), foot + Vector2(5.0, -4.0), Color(leather.r, leather.g, leather.b, 0.5), 1.0, true)
	draw_line(foot + Vector2(-4.0, 3.2), foot + Vector2(6.0, 3.2), Color(0.0, 0.0, 0.0, 0.35), 1.2, true)
	# A small cuff of cloth over the boot.
	var cuff := foot.lerp(knee, 0.15)
	draw_line(cuff + Vector2(-4.0, 0.0), cuff + Vector2(4.0, 0.0), Color(_palette.cloak_light.r, _palette.cloak_light.g, _palette.cloak_light.b, 0.38), 2.0, true)
	if direction < 0.0:
		pass

func _draw_arm(shoulder: Vector2, elbow: Vector2, hand: Vector2, sleeve: Color, glove: Color) -> void:
	_draw_limb(shoulder, elbow, 5.8, sleeve)
	_draw_limb(elbow, hand, 4.5, sleeve.darkened(0.06))
	var direction := (hand - elbow).normalized()
	var normal := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([
		hand + normal * 2.3 + direction * 1.0,
		hand - normal * 2.3 + direction * 1.0,
		hand - normal * 1.6 - direction * 2.2,
		hand + normal * 1.6 - direction * 2.2,
	]), glove)
	draw_circle(hand, 2.4, glove)
	# Wrist cuff.
	draw_line(hand - direction * 4.0 + normal * 2.5, hand - direction * 4.0 - normal * 2.5, Color(_palette.gold.r, _palette.gold.g, _palette.gold.b, 0.35), 1.0, true)

func _draw_limb(a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var direction := (b - a).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var half := width * 0.5
	var points := PackedVector2Array([
		a + normal * half,
		b + normal * half * 0.76,
		b - normal * half * 0.76,
		a - normal * half,
	])
	draw_colored_polygon(points, color)
	draw_circle(a, half, color)
	draw_circle(b, half * 0.78, color)
	# A quiet rim on the lit side.
	draw_line(a + normal * half * 0.82, b + normal * half * 0.60, Color(_palette.cloak_light.r, _palette.cloak_light.g, _palette.cloak_light.b, 0.22), 1.0, true)

func _draw_head(head: Vector2, lean: float) -> void:
	var hood: Color = _palette.cloak
	var hood_dark: Color = _palette.cloak_dark
	var skin: Color = _palette.skin
	var skin_light: Color = _palette.skin_light
	var gold: Color = _palette.gold
	var lens: Color = _palette.lens
	# Hood silhouette.
	_ellipse(head + Vector2(-1.0, 0.5), 12.0, hood, Vector2(1.02, 1.12))
	_ellipse(head + Vector2(-6.5, 1.0), 8.5, hood_dark, Vector2(0.80, 1.0))
	# Face, turned slightly towards the horizon.
	_ellipse(head + Vector2(2.4, 1.6), 7.0, skin, Vector2(0.78, 1.0))
	_ellipse(head + Vector2(1.0, 0.6), 5.6, skin_light, Vector2(0.38, 0.65))
	# Profile nose.
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(8.6, 0.5),
		head + Vector2(11.7, 3.4),
		head + Vector2(8.2, 3.6),
	]), skin)
	# Wind scarf over the mouth.
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-3.0, 4.0),
		head + Vector2(8.0, 3.6),
		head + Vector2(8.8, 7.0),
		head + Vector2(-1.0, 8.2),
	]), _palette.scarf_dark)
	# Goggle strap and lens.
	draw_line(head + Vector2(-8.0, -2.8), head + Vector2(7.0, -3.2), Color(hood_dark.r, hood_dark.g, hood_dark.b, 0.9), 2.0, true)
	_ellipse(head + Vector2(3.6, -1.2), 5.1, gold, Vector2(1.0, 0.74))
	_ellipse(head + Vector2(3.9, -1.2), 4.1, lens, Vector2(1.0, 0.68))
	draw_line(head + Vector2(1.0, -3.0), head + Vector2(4.0, -3.5), Color(1.0, 1.0, 0.95, 0.62), 1.1, true)
	draw_circle(head + Vector2(6.5, -1.0), 1.0, Color(0.05, 0.10, 0.12, 0.6))
	# Hair tuft escaping the hood.
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-8.0, -5.0),
		head + Vector2(-1.0, -10.5),
		head + Vector2(5.0, -9.0),
		head + Vector2(2.0, -6.0),
		head + Vector2(-3.0, -7.2),
	]), Color(0.105, 0.075, 0.071, 0.94))
	# Hood rim light.
	draw_arc(head + Vector2(-1.0, 0.5), 12.4, PI * 1.03, PI * 1.78, 18, Color(gold.r, gold.g, gold.b, 0.32), 1.6, true)
	draw_arc(head + Vector2(-1.0, 0.5), 10.4, PI * 1.34, PI * 1.68, 12, Color(1.0, 0.88, 0.64, 0.25), 1.1, true)
	# Earring catches the last light.
	draw_circle(head + Vector2(-4.0, 7.3), 1.1, Color(gold.r, gold.g, gold.b, 0.8))

func _ellipse(center: Vector2, radius: float, color: Color, scale_value: Vector2) -> void:
	draw_set_transform(center, 0.0, scale_value)
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_rim_light(
	hips: Vector2,
	shoulder: Vector2,
	neck: Vector2,
	back_hand: Vector2,
	front_hand: Vector2,
	back_foot: Vector2,
	front_foot: Vector2
) -> void:
	var rim: Color = _palette.gold
	var light := Color(1.0, 0.90, 0.70, 0.36)
	var spine := PackedVector2Array([
		hips + Vector2(-8.0, 18.0),
		hips + Vector2(-10.0, 3.0),
		shoulder + Vector2(-8.0, 1.0),
		neck + Vector2(-8.0, -1.0),
	])
	draw_polyline(spine, Color(rim.r, rim.g, rim.b, 0.24), 1.4, true)
	# Warm edge along the hood and shoulder.
	draw_arc(neck + Vector2(1.0, -8.0), 12.5, PI * 1.05, PI * 1.62, 16, Color(light.r, light.g, light.b, 0.34), 1.1, true)
	draw_line(shoulder + Vector2(-8.0, 1.0), shoulder + Vector2(-7.0, 5.0), Color(rim.r, rim.g, rim.b, 0.22), 1.0, true)
	# Board trailing wind sparkle.
	if _board_y < 42.5:
		draw_circle(Vector2(38.0, _board_y - 1.0), 1.2, Color(1.0, 0.9, 0.68, 0.5))
	# Gloves.
	for hand in [back_hand, front_hand, back_foot, front_foot]:
		pass
