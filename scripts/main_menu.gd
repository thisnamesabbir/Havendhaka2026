extends Control

## Main title experience for HAVEN DHAKA 2026.
## A living panorama, one hand-drawn rider and a quiet five-note menu.

const SliderSkin = preload("res://scripts/slider_skin.gd")

const RIDER_TAGLINES := [
	"Ochre dust, an old promise, and the long way home.",
	"Sun on the shoulders, a bright line down the mountain.",
	"A cyan thread through the quietest night.",
]

var _background: HavenSky
var _rider: RiderArt
var _rider_shadow: Sprite2D
var _rider_glow: Sprite2D
var _rider_name: Label
var _rider_tag: Label
var _rider_anchor := Vector2(900.0, 548.0)
var _time := 0.0
var _modal: Control


func _ready() -> void:
	HavenUIKit.anchor_full(self)
	theme = HavenUIKit.make_theme()
	SaveData.refresh_unlocks()
	_create_background()
	_create_ambient_layers()
	_create_rider_stage()
	_create_title_and_nav()
	_create_corner_stats()
	AudioManager.start_music("dawn")
	AudioManager.set_ride_audio(0.0, false, false)


func _process(delta: float) -> void:
	_time += delta
	if is_instance_valid(_rider):
		_rider.position = _rider_anchor + Vector2(sin(_time * 0.58) * 2.4, sin(_time * 1.42) * 1.4)
		_rider.speed_ratio = 0.50 + sin(_time * 1.2) * 0.04
		_rider.set_animation_state("ride")
	if is_instance_valid(_rider_glow):
		_rider_glow.modulate.a = 0.18 + sin(_time * 0.7) * 0.03


func _create_background() -> void:
	_background = HavenSky.new()
	_background.name = "MenuSky"
	_background.menu_mode = true
	_background.menu_travel_speed = 330.0
	HavenUIKit.anchor_full(_background)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	move_child(_background, 0)


func _create_ambient_layers() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.016, 0.013, 0.024, 0.82))
	gradient.set_color(1, Color(0.016, 0.013, 0.024, 0.0))
	gradient.add_point(0.62, Color(0.016, 0.013, 0.024, 0.30))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 800
	texture.height = 8
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(1.0, 0.0)
	var left_shade := TextureRect.new()
	left_shade.texture = texture
	left_shade.stretch_mode = TextureRect.STRETCH_SCALE
	left_shade.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left_shade.offset_left = 0.0
	left_shade.offset_right = 840.0
	left_shade.offset_top = 0.0
	left_shade.offset_bottom = 720.0
	left_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left_shade)
	var bottom_gradient := Gradient.new()
	bottom_gradient.set_color(0, Color(0.012, 0.010, 0.018, 0.0))
	bottom_gradient.set_color(1, Color(0.012, 0.010, 0.018, 0.62))
	var bottom_texture := GradientTexture2D.new()
	bottom_texture.gradient = bottom_gradient
	bottom_texture.width = 8
	bottom_texture.height = 300
	bottom_texture.fill_from = Vector2(0.0, 0.0)
	bottom_texture.fill_to = Vector2(0.0, 1.0)
	var bottom_shade := TextureRect.new()
	bottom_shade.texture = bottom_texture
	bottom_shade.stretch_mode = TextureRect.STRETCH_SCALE
	bottom_shade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_shade.offset_top = -300.0
	bottom_shade.offset_bottom = 0.0
	bottom_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_shade)
	var grain := TextureRect.new()
	grain.texture = preload("res://assets/generated/grain.png")
	grain.stretch_mode = TextureRect.STRETCH_TILE
	grain.modulate = Color(1.0, 0.94, 0.84, 0.045)
	HavenUIKit.anchor_full(grain)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grain)


func _create_rider_stage() -> void:
	_rider_glow = Sprite2D.new()
	_rider_glow.texture = preload("res://assets/generated/glow.png")
	_rider_glow.position = _rider_anchor + Vector2(2.0, -48.0)
	_rider_glow.scale = Vector2(1.65, 1.35)
	_rider_glow.modulate = Color(1.0, 0.76, 0.45, 0.20)
	add_child(_rider_glow)
	_rider_shadow = Sprite2D.new()
	_rider_shadow.texture = preload("res://assets/generated/glow.png")
	_rider_shadow.position = _rider_anchor + Vector2(5.0, 104.0)
	_rider_shadow.scale = Vector2(0.52, 0.08)
	_rider_shadow.modulate = Color(0.02, 0.01, 0.03, 0.5)
	add_child(_rider_shadow)
	_rider = RiderArt.new()
	_rider.name = "MenuRider"
	_rider.position = _rider_anchor
	_rider.scale = Vector2(2.05, 2.05)
	_rider.z_index = 0
	add_child(_rider)
	_rider.apply_character(SaveData.get_selected_character())
	_rider.set_animation_state("ride")
	_rider.speed_ratio = 0.5
	var details := RiderArt.rider_details(SaveData.selected_character)
	_rider_name = HavenUIKit.display(String(details["name"]), 18, HavenUIKit.GOLD_PALE, HORIZONTAL_ALIGNMENT_RIGHT)
	_rider_name.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_rider_name.offset_left = -540.0
	_rider_name.offset_right = -44.0
	_rider_name.offset_top = 276.0
	_rider_name.offset_bottom = 304.0
	add_child(_rider_name)
	_rider_tag = HavenUIKit.label(String(details["tagline"]), 18, Color(HavenUIKit.SAND, 0.85), HavenUIKit.ACCENT_FONT, HORIZONTAL_ALIGNMENT_RIGHT)
	_rider_tag.autowrap_mode = TextServer.AUTOWRAP_OFF
	_rider_tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_rider_tag.offset_left = -680.0
	_rider_tag.offset_right = -44.0
	_rider_tag.offset_top = 307.0
	_rider_tag.offset_bottom = 338.0
	add_child(_rider_tag)


func _create_title_and_nav() -> void:
	var left := MarginContainer.new()
	left.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left.offset_right = 690.0
	left.add_theme_constant_override("margin_left", 72)
	left.add_theme_constant_override("margin_top", 54)
	left.add_theme_constant_override("margin_bottom", 40)
	add_child(left)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	left.add_child(column)
	var eyebrow_row := HBoxContainer.new()
	eyebrow_row.add_theme_constant_override("separation", 12)
	column.add_child(eyebrow_row)
	var haven := HavenUIKit.display("HAVEN", 24, HavenUIKit.GOLD_PALE)
	eyebrow_row.add_child(haven)
	var year := HavenUIKit.mono("2026", 12, Color(HavenUIKit.SAND, 0.8))
	year.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	eyebrow_row.add_child(year)
	var title := HavenUIKit.display("DHAKA", 104, HavenUIKit.CREAM)
	title.add_theme_constant_override("line_spacing", -12)
	column.add_child(title)
	var subtitle := HavenUIKit.label("an endless ride through light and sand", 26, HavenUIKit.GOLD_PALE, HavenUIKit.ACCENT_FONT)
	column.add_child(subtitle)
	column.add_child(HavenUIKit.spacer(5.0))
	var rule := ColorRect.new()
	rule.color = Color(HavenUIKit.GOLD, 0.55)
	rule.custom_minimum_size = Vector2(92.0, 1.0)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)
	column.add_child(HavenUIKit.spacer(32.0))
	var nav := VBoxContainer.new()
	nav.add_theme_constant_override("separation", 0)
	column.add_child(nav)
	_add_nav_row(nav, "01", "RIDE", "PlayButton", _start_game)
	_add_nav_row(nav, "02", "THE RIDER", "RidersButton", _open_riders)
	_add_nav_row(nav, "03", "JOURNEY", "StatsButton", _open_journey)
	_add_nav_row(nav, "04", "ACHIEVEMENTS", "AchievementsButton", _open_achievements)
	_add_nav_row(nav, "05", "SETTINGS", "SettingsButton", _open_settings)
	var flexible := Control.new()
	flexible.size_flags_vertical = Control.SIZE_EXPAND_FILL
	flexible.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(flexible)
	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 18)
	column.add_child(footer_row)
	var tutorial := HavenUIKit.small_button("HOW TO RIDE", Vector2(152.0, 34.0), HavenUIKit.SAND)
	tutorial.name = "TutorialButton"
	tutorial.pressed.connect(_open_tutorial)
	footer_row.add_child(tutorial)
	footer_row.add_child(HavenUIKit.mono("SPACE / TAP JUMP   ·   SHIFT WINGSUIT", 8, Color(HavenUIKit.MUTED, 0.8)))


func _add_nav_row(parent: VBoxContainer, index: String, text: String, node_name: String, action: Callable) -> void:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(420.0, 46.0)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_stylebox_override("normal", _nav_style(Color(1, 1, 1, 0.0), Color(HavenUIKit.CREAM, 0.15)))
	button.add_theme_stylebox_override("hover", _nav_style(Color(HavenUIKit.GOLD, 0.08), Color(HavenUIKit.GOLD, 0.62)))
	button.add_theme_stylebox_override("pressed", _nav_style(Color(HavenUIKit.GOLD, 0.16), HavenUIKit.GOLD))
	button.add_theme_stylebox_override("focus", _nav_style(Color(HavenUIKit.GOLD, 0.05), Color(HavenUIKit.GOLD, 0.5)))
	button.pressed.connect(action)
	parent.add_child(button)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	row.offset_left = 12.0
	row.offset_right = -12.0
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var number := HavenUIKit.mono(index, 9, Color(HavenUIKit.GOLD, 0.7))
	number.custom_minimum_size = Vector2(26.0, 0.0)
	number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(number)
	var label := HavenUIKit.display(text, 21, HavenUIKit.CREAM)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	var filler := Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(filler)
	var arrow := HavenUIKit.mono("→", 14, Color(HavenUIKit.GOLD, 0.55))
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(arrow)
	button.mouse_entered.connect(func():
		label.add_theme_color_override("font_color", HavenUIKit.GOLD_PALE)
		arrow.add_theme_color_override("font_color", HavenUIKit.GOLD)
		AudioManager.play_sfx("ui", 1.08)
	)
	button.mouse_exited.connect(func():
		label.add_theme_color_override("font_color", HavenUIKit.CREAM)
		arrow.add_theme_color_override("font_color", Color(HavenUIKit.GOLD, 0.55))
	)
	if node_name == "PlayButton":
		button.custom_minimum_size.y = 56.0
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", HavenUIKit.GOLD_PALE)


func _nav_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_bottom = 1
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _create_corner_stats() -> void:
	var stats := PanelContainer.new()
	stats.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stats.offset_left = -382.0
	stats.offset_right = -38.0
	stats.offset_top = 30.0
	stats.offset_bottom = 92.0
	stats.add_theme_stylebox_override("panel", HavenUIKit.panel_style(
		Color(0.03, 0.026, 0.043, 0.46), Color(HavenUIKit.GOLD, 0.20), 12, 1, 14.0))
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	stats.add_child(row)
	_add_corner_stat(row, "BEST", HavenUI.number(SaveData.best_score))
	_add_corner_stat(row, "FARTHEST", "%s M" % HavenUI.number(SaveData.best_distance))
	_add_corner_stat(row, "GOLD", HavenUI.number(SaveData.total_coins))
	var version := HavenUIKit.mono("BUILD 2026.11  ·  SEEDED WORLD", 8, Color(HavenUIKit.MUTED, 0.7), HORIZONTAL_ALIGNMENT_RIGHT)
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -360.0
	version.offset_right = -38.0
	version.offset_top = -34.0
	version.offset_bottom = -18.0
	add_child(version)


func _add_corner_stat(row: HBoxContainer, title: String, value: String) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	row.add_child(box)
	box.add_child(HavenUIKit.mono(title, 7, HavenUIKit.MUTED))
	box.add_child(HavenUIKit.display(value, 16, HavenUIKit.CREAM))


# ---------------------------------------------------------------------------
# Modal shell
# ---------------------------------------------------------------------------

func _make_modal(title_text: String, eyebrow_text: String, width: float, height: float) -> Dictionary:
	if is_instance_valid(_modal):
		_modal.queue_free()
	var scrim := ColorRect.new()
	scrim.name = "MenuModal"
	scrim.color = Color(0.012, 0.010, 0.018, 0.82)
	HavenUIKit.anchor_full(scrim)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.z_index = 50
	add_child(scrim)
	_modal = scrim
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -width * 0.5
	panel.offset_right = width * 0.5
	panel.offset_top = -height * 0.5
	panel.offset_bottom = height * 0.5
	panel.add_theme_stylebox_override("panel", HavenUIKit.panel_style(
		Color(0.040, 0.034, 0.052, 0.97), Color(HavenUIKit.GOLD, 0.32), 18, 1, 30.0))
	scrim.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 9)
	panel.add_child(body)
	body.add_child(HavenUIKit.mono(eyebrow_text, 9, HavenUIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(HavenUIKit.display(title_text, 31, HavenUIKit.CREAM, HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(HavenUIKit.separator(Color(HavenUIKit.GOLD, 0.20)))
	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_END
	body.add_child(close_row)
	var close := HavenUIKit.small_button("CLOSE", Vector2(96.0, 32.0), HavenUIKit.SAND)
	close.name = "%sBackButton" % title_text.capitalize().replace(" ", "")
	close.pressed.connect(_close_modal)
	close_row.add_child(close)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.24)
	return {"scrim": scrim, "panel": panel, "body": body}


func _close_modal() -> void:
	AudioManager.play_sfx("ui")
	if is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_instance_valid(_modal):
			_close_modal()
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Rider selection
# ---------------------------------------------------------------------------

func _open_riders() -> void:
	AudioManager.play_sfx("ui")
	var modal := _make_modal("THE RIDER", "CHOOSE YOUR SILHOUETTE", 940.0, 566.0)
	var body: VBoxContainer = modal["body"]
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cards)
	for rider_id in RiderArt.rider_ids():
		cards.add_child(_rider_card(String(rider_id)))


func _rider_card(rider_id: String) -> Control:
	var details := RiderArt.rider_details(rider_id)
	var unlocked := SaveData.unlocked_characters.has(rider_id)
	var selected := SaveData.selected_character == rider_id
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(286.0, 352.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border := HavenUIKit.GOLD if selected else Color(HavenUIKit.CREAM, 0.14)
	var background := Color(HavenUIKit.GOLD, 0.055) if selected else Color(0.96, 0.9, 0.8, 0.025)
	card.add_theme_stylebox_override("panel", HavenUIKit.panel_style(background, border, 12, 1, 16.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	var swatch := Control.new()
	swatch.custom_minimum_size = Vector2(0.0, 112.0)
	swatch.clip_contents = true
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(swatch)
	var cloak := Color(details["cloak"])
	var glow := TextureRect.new()
	glow.texture = preload("res://assets/generated/glow.png")
	HavenUIKit.anchor_full(glow)
	glow.offset_left = 18.0
	glow.offset_right = -18.0
	glow.offset_top = 10.0
	glow.offset_bottom = -12.0
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.modulate = Color(cloak.lightened(0.34), 0.42 if unlocked else 0.16)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.add_child(glow)
	var board_line := ColorRect.new()
	board_line.color = Color(Color(details["board_trim"]), 0.42 if unlocked else 0.12)
	board_line.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	board_line.offset_top = -15.0
	board_line.offset_bottom = -14.0
	board_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.add_child(board_line)
	var preview_shadow := Sprite2D.new()
	preview_shadow.texture = preload("res://assets/generated/glow.png")
	preview_shadow.scale = Vector2(0.46, 0.045)
	preview_shadow.modulate = Color(0.01, 0.01, 0.02, 0.48)
	swatch.add_child(preview_shadow)
	var preview := RiderArt.new()
	preview.name = "%sPreview" % rider_id.capitalize()
	preview.set_rider(rider_id)
	preview.scale = Vector2(0.84, 0.84)
	preview.set_animation_state("ride")
	preview.speed_ratio = 0.44
	if not unlocked:
		preview.modulate = Color(0.52, 0.49, 0.55, 0.7)
	swatch.add_child(preview)
	var place_preview := func() -> void:
		var center := Vector2(swatch.size.x * 0.5, swatch.size.y - 46.0)
		preview.position = center
		preview_shadow.position = center + Vector2(0.0, 37.0)
	swatch.resized.connect(place_preview)
	place_preview.call()
	var status := "SELECTED" if selected else ("AVAILABLE" if unlocked else "LOCKED")
	box.add_child(HavenUIKit.mono(status, 8, HavenUIKit.GOLD if selected else HavenUIKit.MUTED))
	box.add_child(HavenUIKit.display(String(details["name"]), 22, HavenUIKit.CREAM))
	var tag := HavenUIKit.label(String(details["tagline"]), 17, HavenUIKit.SAND, HavenUIKit.ACCENT_FONT)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size.y = 52.0
	box.add_child(tag)
	var requirement := "YOURS FROM THE FIRST DUNE"
	if rider_id == "mirage":
		requirement = "REACH 800 M IN ONE RIDE"
	elif rider_id == "ember":
		requirement = "LAND 10 TRICKS ACROSS YOUR JOURNEY"
	if not unlocked:
		box.add_child(HavenUIKit.mono(requirement, 8, Color(HavenUIKit.ROSE, 0.85)))
	else:
		box.add_child(HavenUIKit.mono("AVAILABLE", 8, Color(HavenUIKit.GOLD, 0.55)))
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(filler)
	var select := HavenUIKit.small_button("RIDE AS " + String(details["name"]).replace("THE ", ""), Vector2(0.0, 38.0), HavenUIKit.GOLD)
	select.disabled = not unlocked or selected
	if not unlocked:
		select.text = "LOCKED"
	elif selected:
		select.text = "CURRENT RIDER"
	select.pressed.connect(func():
		if SaveData.set_character(rider_id):
			AudioManager.play_sfx("ui")
			_rider.call("set_rider", rider_id)
			_update_rider_caption(details)
			_close_modal()
	)
	box.add_child(select)
	return card


func _update_rider_caption(details: Dictionary) -> void:
	_rider_name.text = String(details["name"])
	_rider_tag.text = String(details["tagline"])


# ---------------------------------------------------------------------------
# Journey, achievements and settings
# ---------------------------------------------------------------------------

func _open_journey() -> void:
	AudioManager.play_sfx("ui")
	var modal := _make_modal("YOUR JOURNEY", "THE ROAD BEHIND YOU", 780.0, 500.0)
	var body: VBoxContainer = modal["body"]
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	_add_journey_stat(grid, "BEST SCORE", HavenUI.number(SaveData.best_score), HavenUIKit.GOLD_PALE)
	_add_journey_stat(grid, "BEST DISTANCE", "%s M" % HavenUI.number(SaveData.best_distance), HavenUIKit.CREAM)
	_add_journey_stat(grid, "RUNS", HavenUI.number(SaveData.total_runs), HavenUIKit.CREAM)
	_add_journey_stat(grid, "TOTAL DISTANCE", "%s M" % HavenUI.number(SaveData.total_distance), HavenUIKit.CREAM)
	_add_journey_stat(grid, "GOLD", HavenUI.number(SaveData.total_coins), HavenUIKit.GOLD)
	_add_journey_stat(grid, "SHARDS", HavenUI.number(SaveData.total_shards), HavenUIKit.CYAN)
	_add_journey_stat(grid, "TRICKS LANDED", HavenUI.number(SaveData.total_tricks), HavenUIKit.CREAM)
	_add_journey_stat(grid, "BEST COMBO", "x%d" % SaveData.best_combo, HavenUIKit.GOLD_PALE)
	_add_journey_stat(grid, "PERFECT LANDINGS", HavenUI.number(SaveData.perfect_landings), HavenUIKit.CREAM)
	_add_journey_stat(grid, "TIME IN FLIGHT", "%.1f S" % SaveData.total_flight_time, HavenUIKit.CYAN)
	_add_journey_stat(grid, "LONGEST FLIGHT", "%.1f S" % SaveData.longest_flight, HavenUIKit.CYAN)
	_add_journey_stat(grid, "RIDERS", "%d / 3" % SaveData.get_unlocked_character_count(), HavenUIKit.GOLD)
	body.add_child(HavenUIKit.spacer(6.0))
	var progress := HavenUIKit.mono(_progress_line(), 9, HavenUIKit.SAND, HORIZONTAL_ALIGNMENT_CENTER)
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(progress)
	body.add_child(HavenUIKit.spacer(4.0))
	var achievements := HavenUIKit.small_button("VIEW ACHIEVEMENTS", Vector2(250.0, 38.0), HavenUIKit.GOLD)
	achievements.pressed.connect(func():
		_close_modal()
		_open_achievements()
	)
	body.add_child(achievements)


func _progress_line() -> String:
	if not SaveData.wingsuit_unlocked:
		return "THE WINGSUIT OPENS AT 500 M IN ONE RIDE OR FIVE SHARDS IN ONE DESCENT."
	if not SaveData.unlocked_characters.has("mirage"):
		return "THE MIRAGE WAITS AT 800 M IN A SINGLE RIDE."
	if not SaveData.unlocked_characters.has("ember"):
		return "THE NIGHTBIRD WAITS FOR TEN LANDED TRICKS ACROSS YOUR JOURNEY."
	return "ALL RIDERS WALK THE SAME DUNES. THE HORIZON IS YOURS."


func _add_journey_stat(grid: GridContainer, title: String, value: String, color: Color) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", HavenUIKit.panel_style(Color(0.95, 0.88, 0.78, 0.03), Color(HavenUIKit.CREAM, 0.08), 9, 1, 10.0))
	panel.custom_minimum_size = Vector2(226.0, 56.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -4)
	panel.add_child(box)
	box.add_child(HavenUIKit.mono(title, 7, HavenUIKit.MUTED))
	box.add_child(HavenUIKit.display(value, 18, color))


func _open_achievements() -> void:
	AudioManager.play_sfx("ui")
	var modal := _make_modal("ACHIEVEMENTS", "MARKS LEFT IN THE SAND", 740.0, 522.0)
	var body: VBoxContainer = modal["body"]
	var progress := SaveData.get_achievement_progress()
	body.add_child(HavenUIKit.mono("%d OF %d EARNED" % [progress.x, progress.y], 9, HavenUIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_style_scrollbar(scroll.get_v_scroll_bar())
	body.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	for entry in SaveData.get_achievement_defs():
		var earned := bool(entry["earned"])
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", HavenUIKit.panel_style(
			Color(HavenUIKit.GOLD, 0.045) if earned else Color(0.95, 0.88, 0.78, 0.02),
			Color(HavenUIKit.GOLD, 0.28) if earned else Color(HavenUIKit.CREAM, 0.06), 8, 1, 10.0))
		list.add_child(row)
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 12)
		row.add_child(row_box)
		row_box.add_child(HavenUIKit.mono("✦" if earned else "·", 12, HavenUIKit.GOLD if earned else HavenUIKit.MUTED))
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", -4)
		row_box.add_child(text)
		text.add_child(HavenUIKit.display(String(entry["title"]), 14, HavenUIKit.CREAM if earned else Color(HavenUIKit.SAND, 0.7)))
		text.add_child(HavenUIKit.label(String(entry["detail"]), 12, HavenUIKit.MUTED))
		row_box.add_child(HavenUIKit.mono("EARNED" if earned else "", 7, HavenUIKit.GOLD))


func _style_scrollbar(bar: VScrollBar) -> void:
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(0.95, 0.88, 0.78, 0.035)
	groove.set_corner_radius_all(4)
	groove.content_margin_left = 3.0
	groove.content_margin_right = 3.0
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(HavenUIKit.GOLD, 0.32)
	grabber.set_corner_radius_all(4)
	grabber.content_margin_left = 3.0
	grabber.content_margin_right = 3.0
	var grabber_hot := StyleBoxFlat.new()
	grabber_hot.bg_color = Color(HavenUIKit.GOLD, 0.62)
	grabber_hot.set_corner_radius_all(4)
	grabber_hot.content_margin_left = 3.0
	grabber_hot.content_margin_right = 3.0
	bar.add_theme_stylebox_override("scroll", groove)
	bar.add_theme_stylebox_override("grabber", grabber)
	bar.add_theme_stylebox_override("grabber_highlight", grabber_hot)
	bar.add_theme_stylebox_override("grabber_pressed", grabber_hot)


func _open_settings() -> void:
	AudioManager.play_sfx("ui")
	var modal := _make_modal("SETTINGS", "SOUND, LIGHT AND MOTION", 560.0, 508.0)
	var body: VBoxContainer = modal["body"]
	_add_volume_row(body, "MASTER VOLUME", "Master")
	_add_volume_row(body, "MUSIC", "Music")
	_add_volume_row(body, "SOUND EFFECTS", "SFX")
	_add_setting_slider(body, "CAMERA SHAKE", "ScreenShakeSlider", SaveData.get_setting("screen_shake"),
		func(value: float) -> void: SaveData.set_setting("screen_shake", value))
	body.add_child(HavenUIKit.spacer(4.0))
	var fullscreen := HavenUIKit.small_button("TOGGLE FULLSCREEN", Vector2(280.0, 36.0), HavenUIKit.SAND)
	fullscreen.name = "FullscreenButton"
	fullscreen.pressed.connect(_toggle_fullscreen)
	body.add_child(fullscreen)
	var tutorial := HavenUIKit.small_button("SHOW THE RIDING LESSON NEXT RUN", Vector2(320.0, 36.0), HavenUIKit.SAND)
	tutorial.pressed.connect(func():
		SaveData.tutorial_seen = false
		SaveData.save_data()
		AudioManager.play_sfx("ui")
		tutorial.text = "LESSON ENABLED"
		tutorial.disabled = true
	)
	body.add_child(tutorial)
	var done := HavenUIKit.button("DONE", Vector2(220.0, 42.0))
	done.name = "SettingsDoneButton"
	done.pressed.connect(_close_modal)
	body.add_child(done)


func _add_volume_row(parent: VBoxContainer, title: String, bus_name: String) -> void:
	_add_setting_slider(parent, title, "%sVolumeSlider" % bus_name,
		SaveData.get_setting("%s_volume" % bus_name.to_lower()),
		func(value: float) -> void: AudioManager.set_volume(bus_name, value))


func _add_setting_slider(parent: VBoxContainer, title: String, node_name: String, value: float,
		on_change: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	parent.add_child(row)
	row.add_child(HavenUIKit.mono(title, 8, HavenUIKit.SAND, HORIZONTAL_ALIGNMENT_CENTER))
	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size = Vector2(360.0, 18.0)
	SliderSkin.apply(slider)
	slider.value_changed.connect(on_change)
	row.add_child(slider)


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	AudioManager.play_sfx("ui")


func _open_tutorial() -> void:
	AudioManager.play_sfx("ui")
	var modal := _make_modal("HOW TO RIDE", "FOUR QUIET LESSONS", 650.0, 458.0)
	var body: VBoxContainer = modal["body"]
	_add_lesson(body, "SPACE / TAP", "Jump with the slope. Release early for a short hop, hold for height.")
	_add_lesson(body, "HOLD IN AIR", "Tuck into a backflip. Tap again to add rotations. Straighten before landing.")
	_add_lesson(body, "SHIFT / WING", "Open the wingsuit after take-off. Hold Jump to lift, Down to dive, Up to climb.")
	_add_lesson(body, "CHAIN", "Land cleanly to keep the combo alive. Rocks, wall rides and skims all feed it.")
	body.add_child(HavenUIKit.spacer(4.0))
	var quote := HavenUIKit.label("The dunes do not rush. Neither should you.", 19, HavenUIKit.GOLD_PALE, HavenUIKit.ACCENT_FONT, HORIZONTAL_ALIGNMENT_CENTER)
	body.add_child(quote)
	var got_it := HavenUIKit.button("I KNOW THE DUNES", Vector2(260.0, 44.0))
	got_it.name = "TutorialBackButton"
	got_it.pressed.connect(_close_modal)
	body.add_child(got_it)


func _add_lesson(parent: VBoxContainer, key_text: String, detail: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var key := HavenUIKit.mono(key_text, 9, HavenUIKit.GOLD)
	key.custom_minimum_size = Vector2(126.0, 0.0)
	key.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(key)
	var text := HavenUIKit.label(detail, 14, HavenUIKit.CREAM)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)


func _start_game() -> void:
	AudioManager.play_sfx("ui")
	SaveData.begin_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
