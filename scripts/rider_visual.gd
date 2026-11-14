extends Node2D

## Hand-drawn skeletal rider. Every limb is an authored silhouette with
## shading, trim and outline passes; the rig animates continuously so the rider
## can crouch, tuck, land, flail and spread a wingsuit without sprite seams.

var style := HavenWorldStyle.rider_style("wayfarer")

var state := "ride"
var speed_ratio := 0.35
var crouch := 0.18
var tuck := 0.0
var wingsuit := 0.0
var crash := 0.0
var landing := 0.0
var time_scale := 1.0
var facing := 1.0

var _time := 0.0
var _crouch_cur := 0.18
var _tuck_cur := 0.0
var _wingsuit_cur := 0.0
var _crash_cur := 0.0
var _landing_cur := 0.0
var _speed_cur := 0.35
var _state_blend := 0.0

const OUTLINE := Color(0.075, 0.052, 0.075, 0.72)
const SCARF_SEGMENTS := 11
const ART_OFFSET := Vector2(0.0, 46.0)

func _ready() -> void:
	set_process(true)
	z_index = 4

func set_rider(rider_id: String) -> void:
	style = HavenWorldStyle.rider_style(rider_id)
	queue_redraw()

func set_pose(next_state: String, next_speed_ratio: float, next_crouch: float,
		next_tuck: float, next_wingsuit: float, next_crash: float) -> void:
	if next_state != state:
		state = next_state
		_state_blend = 0.0
	speed_ratio = clampf(next_speed_ratio, 0.0, 1.4)
	crouch = clampf(next_crouch, 0.0, 1.0)
	tuck = clampf(next_tuck, 0.0, 1.0)
	wingsuit = clampf(next_wingsuit, 0.0, 1.0)
	crash = clampf(next_crash, 0.0, 1.0)

func trigger_landing() -> void:
	landing = 1.0

func _process(delta: float) -> void:
	_time += delta * time_scale * (0.7 + _speed_cur * 0.7)
	_state_blend = minf(1.0, _state_blend + delta * 6.0)
	var smooth := 1.0 - exp(-11.0 * delta)
	_crouch_cur = lerpf(_crouch_cur, crouch, smooth)
	_tuck_cur = lerpf(_tuck_cur, tuck, smooth)
	_wingsuit_cur = lerpf(_wingsuit_cur, wingsuit, 1.0 - exp(-7.0 * delta))
	_crash_cur = lerpf(_crash_cur, crash, 1.0 - exp(-9.0 * delta))
	_landing_cur = maxf(0.0, _landing_cur - delta * 4.8)
	_speed_cur = lerpf(_speed_cur, speed_ratio, 1.0 - exp(-5.0 * delta))
	queue_redraw()

func _draw() -> void:
	# The node origin is the rider's hip. All authored coordinates below are
	# relative to the board contact point, so shift the artwork down by 46 px.
	draw_set_transform(ART_OFFSET, 0.0, Vector2.ONE)
	var rider: Dictionary = style
	var coat: Color = rider["coat"]
	var coat_light: Color = rider["coat_light"]
	var coat_dark: Color = rider["coat_dark"]
	var pants: Color = rider["pants"]
	var pants_light: Color = rider["pants_light"]
	var scarf: Color = rider["scarf"]
	var scarf_shadow: Color = rider["scarf_shadow"]
	var skin: Color = rider["skin"]
	var skin_light: Color = rider["skin_light"]
	var hair: Color = rider["hair"]
	var board: Color = rider["board"]
	var board_dark: Color = rider["board_dark"]
	var trim: Color = rider["trim"]
	var goggles: Color = rider["goggles"]

	var speed := _speed_cur
	var crouch_v := _crouch_cur
	var tuck_v := _tuck_cur
	var wingsuit_v := _wingsuit_cur
	var crash_v := _crash_cur
	var landing_v := _landing_cur
	var airborne := state == "air" or state == "trick" or state == "wingsuit" or state == "crash"
	var ride_bob := sin(_time * (4.4 + speed * 3.2)) * (1.6 + speed * 1.6) * (1.0 if state == "ride" else 0.25)
	var hip := Vector2(0.0, -46.0 + crouch_v * 7.0 - tuck_v * 4.0 + ride_bob)
	var lean := 0.09 + speed * 0.15 + crouch_v * 0.08 + wingsuit_v * 0.23 - crash_v * 0.18
	var torso_len := 35.0 - crouch_v * 2.0
	var shoulder := hip + Vector2(0.0, -torso_len).rotated(lean)
	var neck := shoulder + Vector2(3.5, -5.0).rotated(lean * 0.75)
	var head_tilt := lean * 0.35 + sin(_time * 1.7) * 0.018 + landing_v * 0.06
	var head := neck + Vector2(1.5, -10.5).rotated(head_tilt)
	if state == "idle":
		lean = 0.05 + sin(_time * 1.2) * 0.015
		head_tilt = sin(_time * 1.2) * 0.035
		head.y += sin(_time * 1.9) * 0.5

	# Board and legs first: the board reads as the anchor of every pose.
	_draw_board(board, board_dark, trim, speed, airborne)
	var rear_ankle := Vector2(-18.0, -5.0)
	var front_ankle := Vector2(22.0, -5.5)
	if state == "idle":
		rear_ankle = Vector2(-16.0, -5.0)
		front_ankle = Vector2(20.0, -5.0)
	elif state == "crash":
		rear_ankle = Vector2(-25.0 + sin(_time * 12.0) * 5.0, -8.0)
		front_ankle = Vector2(28.0 + cos(_time * 10.0) * 5.0, -10.0)
	elif state == "trick" or tuck_v > 0.35:
		rear_ankle = Vector2(-9.0, -24.0) * 1.0
		front_ankle = Vector2(20.0, -25.0)
	elif state == "wingsuit":
		rear_ankle = Vector2(-20.0, -16.0)
		front_ankle = Vector2(23.0, -17.0)
	elif state == "air":
		rear_ankle = Vector2(-15.0, -8.0)
		front_ankle = Vector2(25.0, -9.0)
	elif landing_v > 0.1:
		rear_ankle = Vector2(-20.0, -4.0)
		front_ankle = Vector2(24.0, -5.0)
	# Airborne feet never sink through the deck during a tuck.
	var far_leg := _leg_points(hip + Vector2(-2.5, 0.0), rear_ankle + Vector2(-1.5, 0.5), 26.0, 25.0, false)
	var near_leg := _leg_points(hip + Vector2(1.5, 0.0), front_ankle, 26.0, 25.0, true)
	_draw_leg(far_leg, pants.darkened(0.18), pants_light.darkened(0.12), rider["trim"], true)
	_draw_leg(near_leg, pants, pants_light, rider["trim"], false)

	# Far arm behind the torso.
	var far_hand := _hand_target(false, hip, shoulder, speed, wingsuit_v, crash_v, landing_v)
	var far_arm := _arm_points(shoulder + Vector2(-3.0, 3.0), far_hand, 19.0, 18.0, false)
	_draw_arm(far_arm, coat_dark, coat_dark.lightened(0.06), rider["trim"], true)

	# Scarf tails are behind the coat and catch the wind.
	_draw_scarf(neck, speed, wingsuit_v, crash_v, scarf, scarf_shadow, trim)

	# Jacket silhouette.
	var hem_swing := sin(_time * (5.0 + speed * 3.0)) * (2.0 + speed * 3.0)
	var torso := PackedVector2Array([
		shoulder + Vector2(-6.0, 1.0),
		shoulder + Vector2(6.0, 2.0),
		hip + Vector2(8.0, 2.0),
		hip + Vector2(6.0, 11.0),
		hip + Vector2(-6.0, 12.0 + hem_swing * 0.3),
		hip + Vector2(-13.0 - speed * 5.0, 8.0 + hem_swing),
		hip + Vector2(-6.0, 0.0),
	])
	_draw_coat(torso, coat, coat_light, coat_dark, trim, speed, wingsuit_v)

	# Wingsuit membranes sit between torso and limbs.
	if wingsuit_v > 0.02:
		_draw_wingsuit(shoulder, hip, near_leg, far_hand, wingsuit_v, coat, coat_light, trim, scarf)

	# Near arm in front of the jacket.
	var near_hand := _hand_target(true, hip, shoulder, speed, wingsuit_v, crash_v, landing_v)
	var near_arm := _arm_points(shoulder + Vector2(4.0, 3.0), near_hand, 19.0, 18.0, true)
	_draw_arm(near_arm, coat, coat_light, trim, false)
	_draw_glove(near_hand, hair, trim)
	if wingsuit_v < 0.2:
		_draw_glove(far_hand, hair.darkened(0.12), trim.darkened(0.2))

	_draw_head(head, head_tilt, skin, skin_light, hair, scarf, scarf_shadow, goggles, trim, wingsuit_v)
	_draw_neck_scarf(neck, shoulder, scarf, scarf_shadow, trim, wingsuit_v)

	# A sparkle of trim at the chest.
	draw_line(shoulder + Vector2(1.0, 7.0), shoulder + Vector2(3.0, 15.0), trim, 1.3, true)
	draw_circle(shoulder + Vector2(2.6, 9.0), 1.6, trim)

	if crash_v > 0.3:
		_draw_crash_accents(crash_v)

func _draw_board(board: Color, board_dark: Color, trim: Color, speed: float, airborne: bool) -> void:
	# Contact shadow / warm sand glow under the deck.
	draw_set_transform(ART_OFFSET + Vector2(0.0, 4.0), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 52.0, Color(0.10, 0.045, 0.05, 0.09 if airborne else 0.16))
	draw_set_transform(ART_OFFSET, 0.0, Vector2.ONE)
	var top := PackedVector2Array([
		Vector2(-57.0, -4.0), Vector2(-46.0, -1.8), Vector2(-25.0, -0.6),
		Vector2(2.0, 0.0), Vector2(34.0, -0.2), Vector2(51.0, -2.0),
		Vector2(60.0, -7.2), Vector2(66.0, -9.4), Vector2(64.0, -5.2),
		Vector2(55.0, 0.8), Vector2(32.0, 2.9), Vector2(4.0, 3.3),
		Vector2(-27.0, 3.0), Vector2(-49.0, 1.7), Vector2(-62.0, -1.0),
	])
	draw_colored_polygon(top, board)
	# Dark underside and a lit leading edge. Drawn as a stroked lip instead of
	# a sliver-thin polygon so the triangulator never sees a degenerate band.
	var edge := PackedVector2Array([
		Vector2(-62.0, -1.0), Vector2(-49.0, 1.7), Vector2(-27.0, 3.0),
		Vector2(4.0, 3.3), Vector2(32.0, 2.9), Vector2(55.0, 0.8),
		Vector2(64.0, -5.2), Vector2(66.0, -9.4), Vector2(-62.0, -1.0),
	])
	draw_polyline(edge, board_dark, 2.6, true)
	# Inlay stripe and two fine grain lines.
	draw_polyline(PackedVector2Array([
		Vector2(-48.0, 0.8), Vector2(-24.0, 1.6), Vector2(2.0, 1.9),
		Vector2(31.0, 1.5), Vector2(52.0, -0.1),
	]), Color(trim, 0.72), 1.6, true)
	draw_line(Vector2(-40.0, -1.0), Vector2(35.0, -0.4), Color(1.0, 0.94, 0.79, 0.18), 1.0, true)
	# Gold nose and tail protectors.
	draw_colored_polygon(PackedVector2Array([
		Vector2(51.0, -2.0), Vector2(60.0, -7.2), Vector2(66.0, -9.4), Vector2(64.0, -5.2), Vector2(55.0, 0.8), Vector2(50.5, 0.0)
	]), Color(trim, 0.9))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-57.0, -4.0), Vector2(-46.0, -1.8), Vector2(-53.0, 1.3), Vector2(-62.0, -1.0)
	]), Color(trim.darkened(0.12), 0.86))
	# Fins / board detail.
	draw_line(Vector2(-54.0, 2.0), Vector2(-58.0, 7.0), board_dark, 1.8, true)
	draw_line(Vector2(58.0, -2.0), Vector2(62.0, 2.0), board_dark, 1.6, true)
	# Foot bindings.
	draw_line(Vector2(-23.0, 3.0), Vector2(-13.0, 3.0), Color(0.16, 0.10, 0.11, 0.7), 2.0, true)
	draw_line(Vector2(18.0, 3.0), Vector2(29.0, 3.0), Color(0.16, 0.10, 0.11, 0.7), 2.0, true)

func _leg_points(hip: Vector2, ankle: Vector2, upper: float, lower: float, near: bool) -> Dictionary:
	var knee := _solve_joint(hip, ankle, upper, lower, 1.0 if near else 0.86)
	return {"hip": hip, "knee": knee, "ankle": ankle}

func _arm_points(shoulder: Vector2, hand: Vector2, upper: float, lower: float, near: bool) -> Dictionary:
	var elbow := _solve_joint(shoulder, hand, upper, lower, -1.0 if near else -0.8)
	# Bending elbows downward and back reads naturally in a riding silhouette.
	if elbow.y < minf(shoulder.y, hand.y) + 2.0:
		elbow.y = minf(shoulder.y, hand.y) + 9.0
	return {"shoulder": shoulder, "elbow": elbow, "hand": hand}

func _solve_joint(a: Vector2, b: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var dir := b - a
	var d := clampf(dir.length(), absf(l1 - l2) + 0.01, l1 + l2 - 0.01)
	if d <= 0.001:
		return (a + b) * 0.5
	dir = dir.normalized()
	var cos_a := clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0)
	var along := l1 * cos_a
	var height := sqrt(maxf(0.0, l1 * l1 - along * along)) * bend
	var perp := Vector2(dir.y, -dir.x)
	return a + dir * along + perp * height

func _hand_target(near: bool, hip: Vector2, shoulder: Vector2, speed: float, wing: float,
		crash_v: float, landing_v: float) -> Vector2:
	var sway := sin(_time * (3.0 + speed * 3.0) + (1.4 if near else 0.0))
	var target: Vector2
	if state == "idle":
		target = Vector2(21.0, -57.0) if near else Vector2(10.0, -53.0)
	elif state == "trick" or _tuck_cur > 0.4:
		target = Vector2(22.0, -57.0) if near else Vector2(13.0, -59.0)
	elif state == "crash":
		target = Vector2(34.0 + sin(_time * 13.0) * 15.0, -58.0 + cos(_time * 11.0) * 18.0) if near else Vector2(-30.0 + cos(_time * 12.0) * 12.0, -54.0 + sin(_time * 9.0) * 17.0)
	elif wing > 0.08:
		target = Vector2(44.0 + sway * 2.0, -64.0 + sway * 2.0) if near else Vector2(-42.0 - sway * 2.0, -62.0 + sway * 2.0)
	elif landing_v > 0.15:
		target = Vector2(34.0, -63.0) if near else Vector2(-25.0, -58.0)
	elif state == "air":
		target = Vector2(32.0 + sway * 2.0, -68.0 + sway) if near else Vector2(-20.0 - sway * 2.0, -65.0 - sway)
	elif state == "landing":
		target = Vector2(29.0, -60.0) if near else Vector2(-19.0, -55.0)
	else:
		target = Vector2(25.0 + sway * 1.3, -55.0 + sway * 1.1) if near else Vector2(7.0 - sway * 1.5, -51.0 + sway)
	if _crouch_cur > 0.55 and state != "trick":
		target += Vector2(-4.0, 7.0)
	return target

func _draw_leg(leg: Dictionary, pants: Color, pants_light: Color, trim: Color, far: bool) -> void:
	var hip: Vector2 = leg["hip"]
	var knee: Vector2 = leg["knee"]
	var ankle: Vector2 = leg["ankle"]
	var thigh := _limb_polygon(hip, knee, 8.5, 6.4, false)
	var shin := _limb_polygon(knee, ankle, 6.1, 4.5, false)
	draw_colored_polygon(thigh, pants)
	draw_colored_polygon(shin, pants)
	# Lit edge on the top/right of the leg.
	draw_polyline(PackedVector2Array([
		hip + Vector2(2.6, 1.0), knee + Vector2(2.0, -1.4), ankle + Vector2(1.2, -0.4)
	]), Color(pants_light, 0.42 if not far else 0.22), 1.7, true)
	var boot := PackedVector2Array([
		ankle + Vector2(-7.5, -2.0),
		ankle + Vector2(5.8, -2.6),
		ankle + Vector2(11.2, 0.0),
		ankle + Vector2(10.0, 4.6),
		ankle + Vector2(-7.2, 4.1),
		ankle + Vector2(-9.5, 1.2),
	])
	draw_colored_polygon(boot, Color(0.16, 0.12, 0.14, 1.0) if not far else Color(0.11, 0.09, 0.12, 1.0))
	draw_polyline(PackedVector2Array([boot[0], boot[1], boot[2], boot[3]]), Color(trim, 0.35), 1.0, true)
	draw_line(ankle + Vector2(-6.0, -0.4), ankle + Vector2(8.0, -0.7), Color(trim, 0.5), 1.2, true)

func _draw_arm(arm: Dictionary, sleeve: Color, highlight: Color, trim: Color, far: bool) -> void:
	var shoulder: Vector2 = arm["shoulder"]
	var elbow: Vector2 = arm["elbow"]
	var hand: Vector2 = arm["hand"]
	var upper := _limb_polygon(shoulder, elbow, 6.8, 5.1, false)
	var fore := _limb_polygon(elbow, hand, 4.9, 3.2, false)
	draw_colored_polygon(upper, sleeve)
	draw_colored_polygon(fore, sleeve)
	draw_polyline(PackedVector2Array([
		shoulder + Vector2(1.0, -1.0), elbow + Vector2(1.0, -1.0), hand + Vector2(0.4, -0.8)
	]), Color(highlight, 0.45 if not far else 0.22), 1.2, true)
	# Cuff.
	var dir := (hand - elbow).normalized()
	var cuff := PackedVector2Array()
	var perp := Vector2(-dir.y, dir.x)
	cuff.append(hand - dir * 4.0 + perp * 4.1)
	cuff.append(hand - dir * 4.0 - perp * 4.1)
	cuff.append(hand - dir * 0.5 - perp * 3.1)
	cuff.append(hand - dir * 0.5 + perp * 3.1)
	draw_colored_polygon(cuff, Color(trim, 0.76))
	# Shoulder seam.
	draw_circle(shoulder, 6.2, sleeve)
	draw_line(shoulder + Vector2(-3.0, 2.0), shoulder + Vector2(3.0, 4.0), Color(highlight, 0.36), 1.0, true)

func _draw_glove(hand: Vector2, color: Color, trim: Color) -> void:
	draw_circle(hand + Vector2(0.5, 0.5), 3.9, color)
	draw_circle(hand + Vector2(-1.2, -0.8), 2.0, color.lightened(0.08))
	draw_circle(hand + Vector2(2.2, -1.0), 1.7, color.lightened(0.08))
	draw_arc(hand, 3.9, -PI * 0.7, PI * 0.75, 12, Color(trim, 0.35), 0.8, true)

func _draw_coat(torso: PackedVector2Array, coat: Color, light: Color, dark: Color, trim: Color, speed: float, wing: float) -> void:
	draw_colored_polygon(torso, coat)
	# Shadow panel on the back of the coat.
	var shadow_poly := PackedVector2Array([
		torso[0], torso[1] + Vector2(-1.0, 4.0), torso[2] + Vector2(-2.0, 4.0),
		torso[3] + Vector2(-4.0, 1.0), torso[4] + Vector2(-2.0, 1.0),
		torso[5] + Vector2(0.0, -2.0), torso[6] + Vector2(0.0, -1.0),
	])
	draw_colored_polygon(shadow_poly, Color(dark, 0.35))
	# Chest light and a sweeping gold hem.
	draw_polyline(PackedVector2Array([
		torso[1] + Vector2(-1.0, 6.0), torso[2] + Vector2(-1.0, 8.0),
		torso[3] + Vector2(-1.0, 4.0)
	]), Color(light, 0.52), 2.0, true)
	draw_polyline(PackedVector2Array([
		torso[4], torso[5], torso[6],
	]), Color(trim, 0.66), 1.4, true)
	# Belt, clasp and paired buttons.
	var belt_a := torso[2] + Vector2(-7.0, -1.0)
	var belt_b := torso[3] + Vector2(1.0, -2.0)
	draw_line(belt_a, belt_b, Color(dark, 0.9), 3.4, true)
	draw_line(belt_a + Vector2(0.0, -2.0), belt_b + Vector2(0.0, -2.0), Color(trim, 0.62), 0.9, true)
	draw_circle(belt_a.lerp(belt_b, 0.52), 2.2, Color(trim, 0.9))
	draw_circle(torso[1] + Vector2(1.0, 13.0), 1.2, Color(trim, 0.72))
	draw_circle(torso[1] + Vector2(0.4, 20.0), 1.1, Color(trim, 0.55))
	# Collar.
	draw_polyline(PackedVector2Array([
		torso[0] + Vector2(3.0, 2.0), torso[1] + Vector2(-1.0, 2.0),
		torso[1] + Vector2(-4.0, 8.0),
	]), Color(dark, 0.8), 3.0, true)
	# Wind flutter on the hem.
	if speed > 0.15:
		var flutter := sin(_time * (6.0 + speed * 4.0)) * (2.0 + speed * 2.0)
		draw_line(torso[5] + Vector2(-1.0, 1.0), torso[5] + Vector2(-8.0 - speed * 4.0, 4.0 + flutter), Color(dark, 0.5), 2.0, true)

func _draw_scarf(neck: Vector2, speed: float, wing: float, crash_v: float, scarf: Color, shadow: Color, trim: Color) -> void:
	var wind := 0.45 + speed * 1.2 + wing * 0.8
	var anchor := neck + Vector2(-2.0, 1.0)
	var length := 46.0 + speed * 32.0 + wing * 28.0 + crash_v * 10.0
	_ribbon(anchor, length, 5.4, scarf, shadow, wind, 0.0, trim)
	_ribbon(anchor + Vector2(-1.0, 3.0), length * 0.76, 3.4, shadow, scarf, wind * 1.23, 1.7, trim)

func _ribbon(anchor: Vector2, length: float, width: float, color: Color, underside: Color,
		speed: float, phase: float, trim: Color) -> void:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var steps := SCARF_SEGMENTS
	for i in range(steps):
		var t := float(i) / float(steps - 1)
		var wobble := 3.2 + t * 11.0 + speed * 4.0
		var wave := sin(t * (3.2 + speed * 3.3) + _time * (5.2 + speed * 3.6) + phase) * wobble
		var sag := t * t * (5.0 - speed * 4.0) + sin(t * 2.5 + phase) * 2.0
		var p := anchor + Vector2(-t * length, wave * 0.36 + sag)
		var w := width * (1.0 - t * 0.78)
		top.append(p + Vector2(0.0, -w * 0.5))
		bottom.append(p + Vector2(0.0, w * 0.5))
	var poly := PackedVector2Array()
	poly.append_array(top)
	for i in range(bottom.size() - 1, -1, -1):
		poly.append(bottom[i])
	draw_colored_polygon(poly, color)
	var shade := PackedVector2Array()
	for i in range(bottom.size()):
		shade.append(bottom[i])
	for i in range(bottom.size() - 1, -1, -1):
		var p := bottom[i]
		shade.append(p + Vector2(0.0, -width * 0.24 * (1.0 - float(i) / float(bottom.size()))))
	draw_colored_polygon(shade, Color(underside, 0.65))
	# A thread of gold catches the sun at the tip.
	draw_line(bottom[bottom.size() - 1], top[top.size() - 1], Color(trim, 0.28), 0.9, true)

func _draw_neck_scarf(neck: Vector2, shoulder: Vector2, scarf: Color, shadow: Color, trim: Color, wing: float) -> void:
	var knot := neck + Vector2(1.0, 3.0)
	draw_circle(knot, 7.2, scarf)
	draw_circle(knot + Vector2(-1.2, 1.2), 5.6, Color(shadow, 0.55))
	draw_arc(knot, 6.4, -PI * 0.6, PI * 0.75, 14, Color(trim, 0.4), 1.0, true)
	# Cowl folding behind the neck.
	draw_polyline(PackedVector2Array([
		knot + Vector2(-5.0, 1.0), knot + Vector2(-10.0, 6.0 + sin(_time * 4.0) * 1.5),
		knot + Vector2(-7.0, 12.0),
	]), Color(shadow, 0.8), 3.7, true)
	if wing > 0.2:
		draw_line(knot + Vector2(-4.0, 4.0), knot + Vector2(4.0, 10.0), Color(trim, 0.6), 1.4, true)

func _draw_head(head: Vector2, tilt: float, skin: Color, skin_light: Color, hair: Color,
		scarf: Color, scarf_shadow: Color, goggles: Color, trim: Color, wing: float) -> void:
	var t := head
	# Face profile, facing right.
	var face := PackedVector2Array([
		t + Vector2(-8.0, -6.0),
		t + Vector2(-2.0, -10.0),
		t + Vector2(6.0, -9.5),
		t + Vector2(9.0, -6.0),
		t + Vector2(8.8, -2.4),
		t + Vector2(11.2, 0.0),
		t + Vector2(8.6, 2.2),
		t + Vector2(8.2, 5.4),
		t + Vector2(5.8, 8.4),
		t + Vector2(1.0, 9.0),
		t + Vector2(-5.3, 6.2),
		t + Vector2(-8.0, 1.5),
	])
	draw_colored_polygon(face, skin)
	# Cheek light.
	draw_polyline(PackedVector2Array([
		t + Vector2(1.0, -5.2), t + Vector2(7.0, -4.0), t + Vector2(5.5, 4.5), t + Vector2(1.0, 6.4)
	]), Color(skin_light, 0.42), 2.2, true)
	# Hair / short hood shape.
	var hair_poly := PackedVector2Array([
		t + Vector2(-9.0, -4.0),
		t + Vector2(-7.0, -10.0),
		t + Vector2(0.0, -13.4),
		t + Vector2(7.0, -11.0),
		t + Vector2(8.6, -7.5),
		t + Vector2(3.0, -8.0),
		t + Vector2(-3.0, -5.6),
		t + Vector2(-7.8, 0.0),
	])
	draw_colored_polygon(hair_poly, hair)
	draw_polyline(PackedVector2Array([
		t + Vector2(-8.0, -2.0), t + Vector2(-7.4, -8.0), t + Vector2(0.0, -12.0),
		t + Vector2(6.0, -10.0)
	]), Color(trim, 0.18), 1.0, true)
	# Cowl scarf framing the lower face.
	var cowl := PackedVector2Array([
		t + Vector2(-8.0, 2.0),
		t + Vector2(-6.0, 8.0),
		t + Vector2(0.0, 11.0),
		t + Vector2(6.0, 8.0),
		t + Vector2(8.2, 4.0),
		t + Vector2(3.0, 7.0),
		t + Vector2(-2.0, 5.5),
	])
	draw_colored_polygon(cowl, Color(scarf, 0.92))
	draw_polyline(PackedVector2Array([
		t + Vector2(-5.0, 8.0), t + Vector2(0.0, 9.6), t + Vector2(5.0, 7.6)
	]), Color(scarf_shadow, 0.7), 1.4, true)
	# Ear.
	draw_circle(t + Vector2(-6.2, 1.0), 2.4, skin_light.darkened(0.08))
	draw_arc(t + Vector2(-6.2, 1.0), 2.0, -1.0, 2.0, 7, Color(hair, 0.6), 0.8, true)
	# Goggle strap and lens.
	draw_line(t + Vector2(-7.8, -3.4), t + Vector2(3.4, -4.0), Color(hair.darkened(0.2), 0.92), 3.7, true)
	draw_line(t + Vector2(-7.8, -3.4), t + Vector2(3.4, -4.0), Color(trim, 0.45), 0.8, true)
	draw_circle(t + Vector2(4.8, -2.2), 5.1, Color(trim, 0.85))
	draw_circle(t + Vector2(4.8, -2.2), 4.2, goggles)
	draw_circle(t + Vector2(4.8, -2.2), 2.8, Color(0.83, 0.97, 1.0, 0.86))
	draw_line(t + Vector2(2.8, -4.0), t + Vector2(5.8, -0.8), Color.WHITE, 1.0, true)
	# A small gold earring.
	draw_arc(t + Vector2(-7.2, 4.2), 2.1, 0.2, PI * 1.4, 8, Color(trim, 0.9), 1.0, true)
	# Chin shade.
	draw_polyline(PackedVector2Array([
		t + Vector2(1.0, 8.0), t + Vector2(5.8, 6.4)
	]), Color(hair, 0.22), 1.2, true)
	if wing > 0.25:
		draw_line(t + Vector2(4.0, -6.0), t + Vector2(8.0, -5.0), Color(trim, 0.6), 1.1, true)

func _draw_wingsuit(shoulder: Vector2, hip: Vector2, near_leg: Dictionary, far_hand: Vector2,
		amount: float, coat: Color, light: Color, trim: Color, scarf: Color) -> void:
	var far_shoulder := shoulder + Vector2(-5.0, 2.0)
	var near_shoulder := shoulder + Vector2(5.0, 2.0)
	var far_ankle: Vector2 = near_leg["hip"] + Vector2(-15.0, 17.0)
	var near_ankle: Vector2 = near_leg["ankle"]
	var spread := amount
	# Far membrane.
	var far_poly := PackedVector2Array([
		far_shoulder + Vector2(0.0, 2.0), far_hand + Vector2(0.0, 1.0),
		hip + Vector2(-16.0, 18.0), hip + Vector2(-2.0, 4.0),
	])
	draw_colored_polygon(far_poly, Color(coat.darkened(0.14), 0.55 * spread))
	draw_polyline(PackedVector2Array([far_shoulder, far_hand, hip + Vector2(-16.0, 18.0)]),
		Color(trim, 0.36 * spread), 1.2, true)
	# Near membrane sweeping from the wrist to the knee.
	var hand := near_shoulder + Vector2(39.0, -60.0)
	var near_poly := PackedVector2Array([
		near_shoulder + Vector2(0.0, 2.0), hand,
		hip + Vector2(17.0, 16.0), hip + Vector2(2.0, 4.0),
	])
	draw_colored_polygon(near_poly, Color(coat, 0.45 * spread))
	draw_colored_polygon(PackedVector2Array([
		near_shoulder + Vector2(3.0, 5.0), hand + Vector2(-2.0, -2.0),
		hip + Vector2(12.0, 12.0), hip + Vector2(5.0, 6.0),
	]), Color(light, 0.24 * spread))
	draw_polyline(PackedVector2Array([near_shoulder, hand, hip + Vector2(17.0, 16.0)]),
		Color(trim, 0.45 * spread), 1.3, true)
	# Scarf ribbon flutters along the near membrane.
	draw_line(near_shoulder + Vector2(2.0, 4.0), hip + Vector2(13.0, 12.0), Color(scarf, 0.25 * spread), 2.0, true)

func _draw_crash_accents(crash_v: float) -> void:
	var alpha := crash_v * 0.5
	for i in range(3):
		var a := _time * (4.0 + i) + float(i) * 2.1
		var p := Vector2(cos(a) * (22.0 + i * 7.0), -46.0 + sin(a * 1.4) * (20.0 + i * 5.0))
		draw_circle(p, 1.2, Color(1.0, 0.84, 0.55, alpha))

func _limb_polygon(a: Vector2, b: Vector2, wa: float, wb: float, _rounded: bool) -> PackedVector2Array:
	var dir := (b - a)
	if dir.length() < 0.001:
		dir = Vector2.DOWN
	dir = dir.normalized()
	var perp := Vector2(-dir.y, dir.x)
	return PackedVector2Array([
		a + perp * wa * 0.5,
		a - perp * wa * 0.5,
		b - perp * wb * 0.5,
		b + perp * wb * 0.5,
	])
