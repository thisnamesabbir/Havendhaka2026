class_name GameHUD
extends CanvasLayer

## Cinematic run interface: restrained top-corner telemetry, transient trick
## and biome cards, a full pause suite and touch controls for mobile Web.

signal pause_requested
signal restart_requested
signal menu_requested
signal quit_requested
signal tutorial_closed(from_pause: bool)
signal touch_jump(pressed: bool)
signal touch_slide(pressed: bool)
signal touch_steer(value: float)
signal touch_wingsuit

const SliderSkin = preload("res://scripts/slider_skin.gd")
const TOUCH_BUTTON := Color(0.028, 0.040, 0.066, 0.72)

var _root: Control
var _distance_value: Label
var _biome_name: Label
var _biome_tagline: Label
var _score_value: Label
var _best_value: Label
var _coin_value: Label
var _shard_value: Label
var _speed_value: Label
var _wing_value: Label
var _combo_box: PanelContainer
var _combo_label: Label
var _combo_bar: ProgressBar
var _trick_label: Label
var _hint_label: Label
var _toast_stack: VBoxContainer
var _biome_card: PanelContainer
var _biome_card_index: Label
var _biome_card_name: Label
var _biome_card_tagline: Label
var _biome_tween: Tween
var _pause_overlay: Control
var _pause_distance: Label
var _pause_score: Label
var _tutorial_overlay: Control
var _tutorial_from_pause := false
var _touch_controls: Control
var _touch_left := false
var _touch_right := false
var _hint_time := 11.0
var _combo_ratio := 0.0
var _combo_active := false
var _last_stats: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_root()


func _process(delta: float) -> void:
	if _combo_active:
		_combo_bar.value = lerpf(_combo_bar.value, _combo_ratio * 100.0, 1.0 - exp(-12.0 * delta))
	if _hint_time > 0.0:
		_hint_time -= delta
		if _hint_time <= 0.0:
			var tween := create_tween()
			tween.tween_property(_hint_label, "modulate:a", 0.0, 1.2)


# --------------------------------------------------------------------------
# Public interface
# --------------------------------------------------------------------------

func update_stats(
	distance: int,
	score: int,
	coins: int,
	shards: int,
	speed_kph: float,
	biome: String,
	tagline: String,
	combo: int,
	combo_ratio: float,
	wingsuit_unlocked: bool,
	wingsuit_deployed: bool,
	best_score: int
) -> void:
	_last_stats = {
		"distance": distance,
		"score": score,
		"combo": combo,
	}
	_distance_value.text = HavenUI.zero_pad(distance, 4)
	_score_value.text = HavenUI.number(score)
	_best_value.text = "BEST  %s" % HavenUI.number(best_score)
	_coin_value.text = "COINS  %s" % HavenUI.zero_pad(coins, 3)
	_shard_value.text = "SHARDS  %s" % HavenUI.zero_pad(shards, 2)
	_speed_value.text = "%d" % roundi(speed_kph)
	_biome_name.text = biome
	_biome_tagline.text = tagline
	if wingsuit_deployed:
		_wing_value.text = "WINGSUIT OPEN"
		_wing_value.add_theme_color_override("font_color", HavenUI.CYAN)
	elif wingsuit_unlocked:
		_wing_value.text = "WINGSUIT READY  ·  SHIFT"
		_wing_value.add_theme_color_override("font_color", HavenUI.GOLD)
	else:
		_wing_value.text = "WINGSUIT  ·  500 M OR 5 SHARDS"
		_wing_value.add_theme_color_override("font_color", Color(0.63, 0.64, 0.64))
	var hint_text := "SPACE LIFT  ·  DOWN DIVE  ·  SHIFT STOW" if wingsuit_deployed else "HOLD SPACE TO FLIP  ·  HOLD DOWN TO SLIDE  ·  LAND WITH THE SLOPE"
	if _hint_label.text != hint_text:
		_hint_label.text = hint_text
		_hint_label.modulate.a = 1.0
	_combo_ratio = combo_ratio
	_combo_active = combo >= 2
	if _combo_active:
		_combo_box.visible = true
		_combo_label.text = "COMBO  x%d" % combo
		var heat := clampf(float(combo) / 8.0, 0.0, 1.0)
		_combo_label.add_theme_color_override("font_color", HavenUI.GOLD.lerp(HavenUI.CORAL, heat))
	else:
		_combo_box.visible = false
	if is_instance_valid(_pause_distance):
		_pause_distance.text = "%s M" % HavenUI.number(distance)
		_pause_score.text = HavenUI.number(score)


func set_trick(name: String, turns: int, active: bool) -> void:
	if not active:
		_trick_label.visible = false
		return
	_trick_label.visible = true
	_trick_label.text = "%s  ·  %d" % [name, turns] if turns > 0 else name


func show_toast(title: String, subtitle: String = "", color: Color = HavenUI.GOLD, hold: float = 1.7) -> void:
	var panel := HavenUI.panel_container(HavenUI.panel_style(Color(0.024, 0.034, 0.055, 0.80), Color(color.r, color.g, color.b, 0.30), 3, 1, 15.0))
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", -1)
	panel.add_child(column)
	var heading := HavenUI.label(title, 19, color, "display", HORIZONTAL_ALIGNMENT_CENTER, 2)
	column.add_child(heading)
	if not subtitle.is_empty():
		column.add_child(HavenUI.label(subtitle, 9, Color(0.77, 0.78, 0.78), "ui", HORIZONTAL_ALIGNMENT_CENTER, 1, false))
	_toast_stack.add_child(panel)
	panel.modulate.a = 0.0
	panel.position.y = 7.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.14)
	tween.tween_property(panel, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_interval(hold)
	tween.chain().tween_property(panel, "modulate:a", 0.0, 0.38)
	tween.chain().tween_callback(panel.queue_free)


func show_biome_card(index: int, biome: String, tagline: String) -> void:
	if _biome_tween != null and _biome_tween.is_valid():
		_biome_tween.kill()
	_biome_card_index.text = "WORLD  %02d  /  08" % (index + 1)
	_biome_card_name.text = biome
	_biome_card_tagline.text = tagline
	_biome_card.visible = true
	_biome_card.modulate.a = 0.0
	_biome_card.position.y = 12.0
	_biome_tween = create_tween().set_parallel(true)
	_biome_tween.tween_property(_biome_card, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	_biome_tween.tween_property(_biome_card, "position:y", 0.0, 0.70).set_trans(Tween.TRANS_SINE)
	_biome_tween.chain().tween_interval(2.3)
	_biome_tween.chain().tween_property(_biome_card, "modulate:a", 0.0, 0.85)
	_biome_tween.chain().tween_callback(func() -> void: _biome_card.visible = false)


func show_rating(rating: String, points: int) -> void:
	var color := HavenUI.CREAM
	var title := "CLEAN LANDING"
	match rating:
		"perfect":
			color = HavenUI.GOLD_LIGHT
			title = "PERFECT LANDING"
		"rough":
			color = HavenUI.CORAL
			title = "ROUGH LANDING"
	if points > 0:
		show_toast(title, "+%s POINTS" % HavenUI.number(points), color, 1.25)
	else:
		show_toast(title, "", color, 1.05)


func show_wingsuit_unlock() -> void:
	show_toast("WINGSUIT UNLOCKED", "PRESS SHIFT IN THE AIR TO TAKE FLIGHT", HavenUI.CYAN, 3.8)


func show_tutorial() -> void:
	_build_tutorial()
	_tutorial_from_pause = is_instance_valid(_pause_overlay) and _pause_overlay.visible
	if is_instance_valid(_pause_overlay):
		_pause_overlay.visible = false
	_tutorial_overlay.visible = true
	var button := _tutorial_overlay.find_child("TutorialStartButton", true, false) as Button
	if button != null:
		button.grab_focus()


func close_tutorial() -> void:
	if not is_instance_valid(_tutorial_overlay):
		return
	_tutorial_overlay.visible = false
	if _tutorial_from_pause:
		_pause_overlay.visible = true
		var resume := _pause_overlay.find_child("ResumeButton", true, false) as Button
		if resume != null:
			resume.grab_focus()
	var was_pause := _tutorial_from_pause
	_tutorial_from_pause = false
	tutorial_closed.emit(was_pause)


func set_paused(paused: bool) -> void:
	if not is_instance_valid(_pause_overlay):
		return
	_pause_overlay.visible = paused
	if paused:
		var resume := _pause_overlay.find_child("ResumeButton", true, false) as Button
		if resume != null:
			resume.grab_focus()


func is_pause_visible() -> bool:
	return is_instance_valid(_pause_overlay) and _pause_overlay.visible


func is_tutorial_visible() -> bool:
	return is_instance_valid(_tutorial_overlay) and _tutorial_overlay.visible


# --------------------------------------------------------------------------
# Construction
# --------------------------------------------------------------------------

func _build_root() -> void:
	_root = Control.new()
	_root.name = "HUDRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_root.add_child(_make_scrim(false))
	_root.add_child(_make_scrim(true))
	var grain := TextureRect.new()
	grain.texture = load("res://assets/generated/grain.png")
	grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grain.stretch_mode = TextureRect.STRETCH_TILE
	grain.modulate = Color(1.0, 0.94, 0.84, 0.025)
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(grain)
	var vignette := TextureRect.new()
	vignette.texture = _vignette_texture()
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(vignette)

	_build_distance_block()
	_build_score_block()
	_build_combo()
	_build_speed_block()
	_build_pause_button()
	_build_toasts()
	_build_biome_card()
	_build_trick_label()
	_build_hint()
	_build_touch_controls()
	_build_pause_overlay()


func _build_distance_block() -> void:
	var column := VBoxContainer.new()
	column.name = "DistanceBlock"
	column.set_anchor(SIDE_LEFT, 0.0)
	column.set_anchor(SIDE_TOP, 0.0)
	column.offset_left = 42.0
	column.offset_top = 24.0
	column.offset_right = 360.0
	column.offset_bottom = 136.0
	column.add_theme_constant_override("separation", -3)
	_root.add_child(column)
	column.add_child(HavenUI.label("DISTANCE", 8, HavenUI.GOLD, "ui", HORIZONTAL_ALIGNMENT_LEFT, 4, false))
	var number_row := HBoxContainer.new()
	number_row.add_theme_constant_override("separation", 5)
	column.add_child(number_row)
	_distance_value = HavenUI.label("0000", 42, HavenUI.CREAM, "display", HORIZONTAL_ALIGNMENT_LEFT, 2)
	_distance_value.name = "DistanceValue"
	number_row.add_child(_distance_value)
	var unit := HavenUI.label("M", 11, HavenUI.GOLD, "ui", HORIZONTAL_ALIGNMENT_LEFT, 2, false)
	unit.size_flags_vertical = Control.SIZE_SHRINK_END
	number_row.add_child(unit)
	_biome_name = HavenUI.label("GOLDEN DESERT", 10, HavenUI.CREAM, "ui", HORIZONTAL_ALIGNMENT_LEFT, 2, false)
	_biome_name.name = "BiomeName"
	column.add_child(_biome_name)
	_biome_tagline = HavenUI.label("THE FIRST LIGHT", 8, Color(0.70, 0.68, 0.62), "ui", HORIZONTAL_ALIGNMENT_LEFT, 1, false)
	column.add_child(_biome_tagline)


func _build_score_block() -> void:
	var column := VBoxContainer.new()
	column.name = "ScoreBlock"
	column.set_anchor(SIDE_LEFT, 1.0)
	column.set_anchor(SIDE_TOP, 0.0)
	column.set_anchor(SIDE_RIGHT, 1.0)
	column.offset_left = -356.0
	column.offset_top = 24.0
	column.offset_right = -80.0
	column.offset_bottom = 136.0
	column.add_theme_constant_override("separation", -3)
	_root.add_child(column)
	var score_caption := HavenUI.label("SCORE", 8, HavenUI.GOLD, "ui", HORIZONTAL_ALIGNMENT_RIGHT, 4, false)
	column.add_child(score_caption)
	_score_value = HavenUI.label("0", 34, HavenUI.CREAM, "display", HORIZONTAL_ALIGNMENT_RIGHT, 2)
	_score_value.name = "ScoreValue"
	column.add_child(_score_value)
	var counts := HBoxContainer.new()
	counts.alignment = BoxContainer.ALIGNMENT_END
	counts.add_theme_constant_override("separation", 14)
	column.add_child(counts)
	_coin_value = HavenUI.label("COINS  000", 9, HavenUI.GOLD, "mono", HORIZONTAL_ALIGNMENT_RIGHT, 1, false)
	_coin_value.name = "CoinValue"
	counts.add_child(_coin_value)
	_shard_value = HavenUI.label("SHARDS  00", 9, HavenUI.CYAN, "mono", HORIZONTAL_ALIGNMENT_RIGHT, 1, false)
	_shard_value.name = "ShardValue"
	counts.add_child(_shard_value)
	_best_value = HavenUI.label("BEST  0", 8, Color(0.61, 0.61, 0.59), "mono", HORIZONTAL_ALIGNMENT_RIGHT, 1, false)
	_best_value.name = "BestValue"
	column.add_child(_best_value)


func _build_combo() -> void:
	_combo_box = HavenUI.panel_container(HavenUI.panel_style(Color(0.028, 0.040, 0.062, 0.68), Color(0.956, 0.762, 0.455, 0.24), 3, 1, 13.0))
	_combo_box.name = "ComboBox"
	_combo_box.set_anchor(SIDE_LEFT, 0.5)
	_combo_box.set_anchor(SIDE_TOP, 0.0)
	_combo_box.set_anchor(SIDE_RIGHT, 0.5)
	_combo_box.offset_left = -86.0
	_combo_box.offset_top = 24.0
	_combo_box.offset_right = 86.0
	_combo_box.offset_bottom = 73.0
	_combo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_combo_box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	_combo_box.add_child(column)
	_combo_label = HavenUI.label("COMBO  x2", 12, HavenUI.GOLD, "ui", HORIZONTAL_ALIGNMENT_CENTER, 3, false)
	_combo_label.name = "ComboLabel"
	column.add_child(_combo_label)
	_combo_bar = ProgressBar.new()
	_combo_bar.name = "ComboBar"
	_combo_bar.show_percentage = false
	_combo_bar.custom_minimum_size = Vector2(132.0, 3.0)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(1.0, 1.0, 1.0, 0.10)
	background.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = HavenUI.GOLD
	fill.set_corner_radius_all(2)
	_combo_bar.add_theme_stylebox_override("background", background)
	_combo_bar.add_theme_stylebox_override("fill", fill)
	_combo_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_combo_bar)
	_combo_box.visible = false


func _build_speed_block() -> void:
	var row := HBoxContainer.new()
	row.name = "SpeedBlock"
	row.set_anchor(SIDE_LEFT, 0.0)
	row.set_anchor(SIDE_TOP, 1.0)
	row.set_anchor(SIDE_BOTTOM, 1.0)
	row.offset_left = 42.0
	row.offset_top = -59.0
	row.offset_right = 310.0
	row.offset_bottom = -24.0
	row.add_theme_constant_override("separation", 7)
	_root.add_child(row)
	_speed_value = HavenUI.label("0", 22, HavenUI.CREAM, "display", HORIZONTAL_ALIGNMENT_LEFT, 1)
	_speed_value.name = "SpeedValue"
	_speed_value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_speed_value)
	var unit := HavenUI.label("KM/H", 8, HavenUI.GOLD, "ui", HORIZONTAL_ALIGNMENT_LEFT, 2, false)
	unit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(unit)
	var divider := ColorRect.new()
	divider.color = Color(0.956, 0.762, 0.455, 0.26)
	divider.custom_minimum_size = Vector2(1.0, 16.0)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(divider)
	_wing_value = HavenUI.label("WINGSUIT  ·  500 M OR 5 SHARDS", 8, Color(0.63, 0.64, 0.64), "ui", HORIZONTAL_ALIGNMENT_LEFT, 1, false)
	_wing_value.name = "WingsuitLabel"
	_wing_value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_wing_value)


func _build_pause_button() -> void:
	var button := HavenUI.icon_button("II", 38.0)
	button.name = "PauseButton"
	button.set_anchor(SIDE_LEFT, 1.0)
	button.set_anchor(SIDE_TOP, 0.0)
	button.set_anchor(SIDE_RIGHT, 1.0)
	button.offset_left = -58.0
	button.offset_top = 22.0
	button.offset_right = -20.0
	button.offset_bottom = 60.0
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(func() -> void: pause_requested.emit())
	_root.add_child(button)


func _build_toasts() -> void:
	_toast_stack = VBoxContainer.new()
	_toast_stack.name = "ToastStack"
	_toast_stack.set_anchor(SIDE_LEFT, 0.5)
	_toast_stack.set_anchor(SIDE_RIGHT, 0.5)
	_toast_stack.set_anchor(SIDE_TOP, 0.0)
	_toast_stack.offset_left = -300.0
	_toast_stack.offset_top = 116.0
	_toast_stack.offset_right = 300.0
	_toast_stack.offset_bottom = 240.0
	_toast_stack.add_theme_constant_override("separation", 5)
	_toast_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toast_stack)


func _build_biome_card() -> void:
	var anchor := Control.new()
	anchor.name = "BiomeAnchor"
	anchor.set_anchor(SIDE_LEFT, 0.5)
	anchor.set_anchor(SIDE_RIGHT, 0.5)
	anchor.set_anchor(SIDE_TOP, 0.27)
	anchor.offset_left = -300.0
	anchor.offset_top = 0.0
	anchor.offset_right = 300.0
	anchor.offset_bottom = 150.0
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(anchor)
	_biome_card = HavenUI.panel_container(HavenUI.panel_style(Color(0.020, 0.030, 0.050, 0.60), Color(0.956, 0.762, 0.455, 0.24), 3, 1, 22.0))
	_biome_card.name = "BiomeCard"
	_biome_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_biome_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(_biome_card)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", -1)
	_biome_card.add_child(column)
	_biome_card_index = HavenUI.label("WORLD  01  /  08", 8, HavenUI.GOLD, "ui", HORIZONTAL_ALIGNMENT_CENTER, 4, false)
	column.add_child(_biome_card_index)
	_biome_card_name = HavenUI.label("GOLDEN DESERT", 34, HavenUI.CREAM, "display", HORIZONTAL_ALIGNMENT_CENTER, 4)
	_biome_card_name.name = "BiomeCardName"
	column.add_child(_biome_card_name)
	_biome_card_tagline = HavenUI.label("THE FIRST LIGHT", 9, Color(0.78, 0.76, 0.70), "ui", HORIZONTAL_ALIGNMENT_CENTER, 3, false)
	column.add_child(_biome_card_tagline)
	_biome_card.visible = false


func _build_trick_label() -> void:
	_trick_label = HavenUI.label("BACKFLIP  ·  1", 16, HavenUI.CYAN, "display", HORIZONTAL_ALIGNMENT_CENTER, 3)
	_trick_label.name = "TrickStatus"
	_trick_label.set_anchor(SIDE_LEFT, 0.5)
	_trick_label.set_anchor(SIDE_RIGHT, 0.5)
	_trick_label.set_anchor(SIDE_TOP, 0.0)
	_trick_label.offset_left = -180.0
	_trick_label.offset_top = 84.0
	_trick_label.offset_right = 180.0
	_trick_label.offset_bottom = 112.0
	_trick_label.visible = false
	_root.add_child(_trick_label)


func _build_hint() -> void:
	_hint_label = HavenUI.label(
		"HOLD SPACE TO FLIP  ·  HOLD DOWN TO SLIDE  ·  LAND WITH THE SLOPE",
		9,
		Color(0.78, 0.76, 0.70),
		"ui",
		HORIZONTAL_ALIGNMENT_CENTER,
		2,
		false
	)
	_hint_label.name = "ControlHint"
	_hint_label.set_anchor(SIDE_LEFT, 0.5)
	_hint_label.set_anchor(SIDE_RIGHT, 0.5)
	_hint_label.set_anchor(SIDE_TOP, 1.0)
	_hint_label.set_anchor(SIDE_BOTTOM, 1.0)
	_hint_label.offset_left = -270.0
	_hint_label.offset_top = -95.0
	_hint_label.offset_right = 270.0
	_hint_label.offset_bottom = -72.0
	_root.add_child(_hint_label)


func _build_touch_controls() -> void:
	_touch_controls = Control.new()
	_touch_controls.name = "TouchControls"
	_touch_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_touch_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_touch_controls)
	var visible_touch := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	_touch_controls.visible = visible_touch

	var left := _touch_button("<", Vector2(58.0, 58.0), "SteerLeftButton")
	left.set_anchor(SIDE_LEFT, 0.0)
	left.set_anchor(SIDE_TOP, 1.0)
	left.set_anchor(SIDE_BOTTOM, 1.0)
	left.offset_left = 24.0
	left.offset_top = -128.0
	left.offset_right = 82.0
	left.offset_bottom = -70.0
	left.button_down.connect(func() -> void:
		_touch_left = true
		touch_steer.emit(-1.0)
	)
	left.button_up.connect(func() -> void:
		_touch_left = false
		touch_steer.emit(1.0 if _touch_right else 0.0)
	)
	_touch_controls.add_child(left)
	var right := _touch_button(">", Vector2(58.0, 58.0), "SteerRightButton")
	right.set_anchor(SIDE_LEFT, 0.0)
	right.set_anchor(SIDE_TOP, 1.0)
	right.set_anchor(SIDE_BOTTOM, 1.0)
	right.offset_left = 90.0
	right.offset_top = -128.0
	right.offset_right = 148.0
	right.offset_bottom = -70.0
	right.button_down.connect(func() -> void:
		_touch_right = true
		touch_steer.emit(1.0)
	)
	right.button_up.connect(func() -> void:
		_touch_right = false
		touch_steer.emit(-1.0 if _touch_left else 0.0)
	)
	_touch_controls.add_child(right)

	var jump := _touch_button("JUMP", Vector2(86.0, 86.0), "JumpButton")
	jump.set_anchor(SIDE_LEFT, 1.0)
	jump.set_anchor(SIDE_TOP, 1.0)
	jump.offset_left = -104.0
	jump.offset_top = -136.0
	jump.offset_right = -18.0
	jump.offset_bottom = -50.0
	jump.button_down.connect(func() -> void: touch_jump.emit(true))
	jump.button_up.connect(func() -> void: touch_jump.emit(false))
	_touch_controls.add_child(jump)
	var slide := _touch_button("SLIDE", Vector2(82.0, 52.0), "SlideButton")
	slide.set_anchor(SIDE_LEFT, 1.0)
	slide.set_anchor(SIDE_TOP, 1.0)
	slide.offset_left = -198.0
	slide.offset_top = -150.0
	slide.offset_right = -116.0
	slide.offset_bottom = -98.0
	slide.button_down.connect(func() -> void: touch_slide.emit(true))
	slide.button_up.connect(func() -> void: touch_slide.emit(false))
	_touch_controls.add_child(slide)
	var wing := _touch_button("WING", Vector2(82.0, 44.0), "WingsuitButton")
	wing.set_anchor(SIDE_LEFT, 1.0)
	wing.set_anchor(SIDE_TOP, 1.0)
	wing.offset_left = -292.0
	wing.offset_top = -146.0
	wing.offset_right = -210.0
	wing.offset_bottom = -102.0
	wing.pressed.connect(func() -> void: touch_wingsuit.emit())
	_touch_controls.add_child(wing)


func _touch_button(text: String, minimum: Vector2, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", HavenUI.tracked(HavenUI.ui_font(), 2))
	button.add_theme_font_size_override("font_size", 10)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, HavenUI.CREAM)
	button.add_theme_stylebox_override("normal", HavenUI.panel_style(TOUCH_BUTTON, Color(0.956, 0.762, 0.455, 0.32), 30, 1, 6.0))
	button.add_theme_stylebox_override("hover", HavenUI.panel_style(Color(0.06, 0.075, 0.098, 0.82), HavenUI.GOLD, 30, 1, 6.0))
	button.add_theme_stylebox_override("pressed", HavenUI.panel_style(Color(0.94, 0.75, 0.45, 0.26), HavenUI.GOLD_LIGHT, 30, 1, 6.0))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


# --------------------------------------------------------------------------
# Pause
# --------------------------------------------------------------------------

func _build_pause_overlay() -> void:
	_pause_overlay = Control.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_pause_overlay)
	var scrim := ColorRect.new()
	scrim.color = Color(0.010, 0.015, 0.028, 0.84)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(center)
	var panel := HavenUI.panel_container(HavenUI.panel_style(Color(0.024, 0.034, 0.055, 0.98), Color(0.956, 0.762, 0.455, 0.38), 4, 1, 30.0))
	panel.custom_minimum_size = Vector2(750.0, 448.0)
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	var heading_row := HBoxContainer.new()
	outer.add_child(heading_row)
	var heading := HavenUI.label("PAUSED", 46, HavenUI.CREAM, "display", HORIZONTAL_ALIGNMENT_LEFT, 4)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	var sub := HavenUI.label("THE DUNES HOLD THEIR BREATH", 9, HavenUI.GOLD, "ui", HORIZONTAL_ALIGNMENT_RIGHT, 3, false)
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading_row.add_child(sub)
	outer.add_child(HavenUI.rule(686.0, Color(0.956, 0.762, 0.455, 0.20)))

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 26)
	outer.add_child(stats)
	_pause_distance = _pause_stat(stats, "DISTANCE", "0000 M")
	_pause_score = _pause_stat(stats, "SCORE", "0")
	var combo_stat := _pause_stat(stats, "BEST COMBO", "x0")
	combo_stat.name = "PauseComboValue"
	outer.add_child(HavenUI.spacer(2))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(columns)
	var actions := VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	columns.add_child(actions)
	var resume := HavenUI.button("RESUME THE RIDE", true, Vector2(342.0, 48.0), true, 2)
	resume.name = "ResumeButton"
	resume.pressed.connect(func() -> void:
		SaveData.save_data()
		pause_requested.emit()
	)
	actions.add_child(resume)
	var restart := HavenUI.button("RESTART RUN", false, Vector2(342.0, 44.0), true, 2)
	restart.name = "PauseRestartButton"
	restart.pressed.connect(func() -> void: restart_requested.emit())
	actions.add_child(restart)
	var guide := HavenUI.button("HOW TO RIDE", false, Vector2(342.0, 44.0), true, 2)
	guide.name = "PauseTutorialButton"
	guide.pressed.connect(func() -> void: show_tutorial())
	actions.add_child(guide)
	var menu := HavenUI.button("RETURN TO HAVEN", false, Vector2(342.0, 44.0), true, 2)
	menu.name = "PauseMenuButton"
	menu.pressed.connect(func() -> void: menu_requested.emit())
	actions.add_child(menu)
	var quit := HavenUI.button("EXIT TO DESKTOP", false, Vector2(342.0, 40.0), true, 2)
	quit.name = "PauseQuitButton"
	quit.pressed.connect(func() -> void: quit_requested.emit())
	if OS.has_feature("web"):
		quit.visible = false
	actions.add_child(quit)

	var settings := VBoxContainer.new()
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_theme_constant_override("separation", 6)
	columns.add_child(settings)
	settings.add_child(HavenUI.subhead("SOUND & CAMERA", HavenUI.GOLD, 3))
	_pause_slider(settings, "Master", "PauseMasterSlider", "Master", SaveData.get_setting("master_volume"))
	_pause_slider(settings, "Music", "PauseMusicSlider", "Music", SaveData.get_setting("music_volume"))
	_pause_slider(settings, "Effects", "PauseSfxSlider", "SFX", SaveData.get_setting("sfx_volume"))
	_pause_slider(settings, "Camera shake", "PauseShakeSlider", "ScreenShake", SaveData.get_setting("screen_shake"))
	settings.add_child(HavenUI.spacer(2))
	settings.add_child(HavenUI.body("ESC resumes. All settings save automatically.", 9, Color(0.55, 0.58, 0.60)))
	_pause_overlay.visible = false


func _pause_stat(parent: HBoxContainer, heading: String, value: String) -> Label:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -4)
	parent.add_child(column)
	column.add_child(HavenUI.label(heading, 8, Color(0.58, 0.62, 0.64), "ui", HORIZONTAL_ALIGNMENT_LEFT, 3, false))
	var label := HavenUI.label(value, 22, HavenUI.CREAM, "display", HORIZONTAL_ALIGNMENT_LEFT, 1)
	column.add_child(label)
	return label


func _pause_slider(parent: VBoxContainer, title_text: String, node_name: String, bus_name: String, value: float) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	parent.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	var heading := HavenUI.body(title_text, 10, Color(0.72, 0.73, 0.72))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	var percentage := HavenUI.label("%d%%" % roundi(value * 100.0), 9, HavenUI.GOLD, "mono", HORIZONTAL_ALIGNMENT_RIGHT, 0, false)
	percentage.custom_minimum_size.x = 42.0
	row.add_child(percentage)
	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size = Vector2(296.0, 17.0)
	SliderSkin.apply(slider)
	slider.value_changed.connect(func(new_value: float) -> void:
		percentage.text = "%d%%" % roundi(new_value * 100.0)
		if bus_name == "ScreenShake":
			SaveData.set_setting("screen_shake", new_value)
		else:
			AudioManager.set_volume(bus_name, new_value)
	)
	column.add_child(slider)


# --------------------------------------------------------------------------
# Tutorial
# --------------------------------------------------------------------------

func _build_tutorial() -> void:
	if is_instance_valid(_tutorial_overlay):
		return
	_tutorial_overlay = Control.new()
	_tutorial_overlay.name = "TutorialOverlay"
	_tutorial_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_tutorial_overlay)
	var scrim := ColorRect.new()
	scrim.color = Color(0.010, 0.015, 0.028, 0.88)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_overlay.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_overlay.add_child(center)
	var panel := HavenUI.panel_container(HavenUI.panel_style(Color(0.024, 0.034, 0.055, 0.98), Color(0.956, 0.762, 0.455, 0.38), 4, 1, 30.0))
	panel.custom_minimum_size = Vector2(760.0, 492.0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	panel.add_child(column)
	column.add_child(HavenUI.label("THE FIRST DESCENT", 40, HavenUI.CREAM, "display", HORIZONTAL_ALIGNMENT_LEFT, 4))
	column.add_child(HavenUI.body("A short guide to the quiet art of going downhill.", 12, Color(0.82, 0.76, 0.67)))
	column.add_child(HavenUI.rule(696.0, Color(0.956, 0.762, 0.455, 0.22)))
	_tutorial_line(column, "SPACE", "Jump. Hold in the air to commit to a backflip. Release early to shorten the hop.")
	_tutorial_line(column, "DOWN", "Slide low for speed. In the air it begins a frontflip.")
	_tutorial_line(column, "LEFT / RIGHT", "Steer in flight and line the board up with the landing slope.")
	_tutorial_line(column, "SHIFT", "Open the wingsuit once unlocked. Space lifts, Down dives, Shift stows.")
	_tutorial_line(column, "ESC", "Pause, adjust sound and camera, or return here from the pause menu.")
	column.add_child(HavenUI.spacer(3))
	column.add_child(HavenUI.body("TOUCH  ·  Steer left and right, hold JUMP to flip, tap WING to fly. Every control is on screen.", 10, Color(0.57, 0.77, 0.84)))
	column.add_child(HavenUI.spacer(3))
	var button := HavenUI.button("TAKE THE FIRST STEP", true, Vector2(300.0, 50.0), true, 3)
	button.name = "TutorialStartButton"
	button.pressed.connect(func() -> void: close_tutorial())
	column.add_child(button)
	_tutorial_overlay.visible = false


func _tutorial_line(parent: VBoxContainer, key_text: String, detail: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var keycap := PanelContainer.new()
	keycap.custom_minimum_size = Vector2(124.0, 32.0)
	keycap.add_theme_stylebox_override("panel", HavenUI.panel_style(Color(0.072, 0.082, 0.105, 0.90), Color(0.956, 0.762, 0.455, 0.30), 3, 1, 8.0))
	row.add_child(keycap)
	keycap.add_child(HavenUI.label(key_text, 9, HavenUI.GOLD, "mono", HORIZONTAL_ALIGNMENT_CENTER, 1, false))
	var copy := HavenUI.body(detail, 11, Color(0.78, 0.79, 0.77))
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)


# --------------------------------------------------------------------------
# Decorative textures
# --------------------------------------------------------------------------

func _make_scrim(top: bool) -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.008, 0.012, 0.024, 0.74 if top else 0.0))
	gradient.set_color(1, Color(0.008, 0.012, 0.024, 0.0 if top else 0.72))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 4
	texture.height = 256
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	var rect := TextureRect.new()
	rect.name = "TopScrim" if top else "BottomScrim"
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep the scrim local to the HUD bands. A full-rect gradient would stack
	# two half-opaque veils over the rider and drain the desert of colour.
	if top:
		rect.anchor_right = 1.0
		rect.anchor_bottom = 0.30
	else:
		rect.anchor_top = 0.70
		rect.anchor_right = 1.0
		rect.anchor_bottom = 1.0
	return rect


func _vignette_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.50))
	gradient.add_point(0.62, Color(0.0, 0.0, 0.0, 0.0))
	gradient.add_point(0.88, Color(0.0, 0.0, 0.0, 0.18))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 512
	texture.height = 512
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.52, 0.48)
	texture.fill_to = Vector2(1.04, 1.02)
	return texture
