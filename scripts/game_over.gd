class_name HavenGameOver
extends CanvasLayer

## End-of-run card. The world keeps its colour behind a dark scrim while the
## rider's final numbers, medals and next invitation are laid out like a
## printed expedition record.

signal retry_requested
signal menu_requested

var _root: Control
var _panel: PanelContainer
var _content: VBoxContainer
var _retry: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20


func present(data: Dictionary) -> void:
	if is_instance_valid(_root):
		_root.queue_free()
	_root = Control.new()
	_root.name = "GameOverRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var scrim := ColorRect.new()
	scrim.color = Color(0.008, 0.012, 0.024, 0.86)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(scrim)
	var vignette := TextureRect.new()
	vignette.texture = _vignette()
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(vignette)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_panel = HavenUI.panel_container(HavenUI.panel_style(Color(0.023, 0.033, 0.053, 0.98), Color(0.956, 0.762, 0.455, 0.40), 4, 1, 32.0))
	_panel.name = "ResultsPanel"
	_panel.custom_minimum_size = Vector2(800.0, 552.0)
	center.add_child(_panel)
	_content = VBoxContainer.new()
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_theme_constant_override("separation", 7)
	_panel.add_child(_content)

	var new_best := bool(data.get("new_best_score", false))
	var eyebrow := "A NEW RECORD" if new_best else "THE DUNES REMEMBER"
	var eyebrow_label := HavenUI.label(eyebrow, 9, HavenUI.GOLD, "ui", HORIZONTAL_ALIGNMENT_LEFT, 5, false)
	_content.add_child(eyebrow_label)
	var title := HavenUI.label("RUN COMPLETE", 42, HavenUI.CREAM, "display", HORIZONTAL_ALIGNMENT_LEFT, 4)
	title.name = "ResultsTitle"
	_content.add_child(title)
	var reason := _reason_text(String(data.get("reason", "fall")))
	var reason_label := HavenUI.body(reason, 11, Color(0.72, 0.69, 0.64))
	_content.add_child(reason_label)
	_content.add_child(HavenUI.rule(736.0, Color(0.956, 0.762, 0.455, 0.22)))

	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 18)
	_content.add_child(score_row)
	var score_column := VBoxContainer.new()
	score_column.add_theme_constant_override("separation", -6)
	score_row.add_child(score_column)
	score_column.add_child(HavenUI.label("FINAL SCORE", 8, HavenUI.GOLD, "ui", HORIZONTAL_ALIGNMENT_LEFT, 4, false))
	var score_value := HavenUI.label(HavenUI.number(int(data.get("score", 0))), 58, HavenUI.CREAM, "display", HORIZONTAL_ALIGNMENT_LEFT, 3)
	score_value.name = "FinalScore"
	score_column.add_child(score_value)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_row.add_child(fill)
	var right_column := VBoxContainer.new()
	right_column.alignment = BoxContainer.ALIGNMENT_CENTER
	right_column.add_theme_constant_override("separation", 1)
	score_row.add_child(right_column)
	var record_text := "NEW BEST" if new_best else "PERSONAL BEST  %s" % HavenUI.number(int(data.get("best_score", 0)))
	right_column.add_child(HavenUI.label(record_text, 10, HavenUI.GOLD if new_best else Color(0.66, 0.66, 0.63), "ui", HORIZONTAL_ALIGNMENT_RIGHT, 3, false))
	var distance_best := "NEW DISTANCE RECORD" if bool(data.get("new_best_distance", false)) else "BEST DISTANCE  %s M" % HavenUI.number(int(data.get("best_distance", 0)))
	right_column.add_child(HavenUI.label(distance_best, 9, Color(0.64, 0.71, 0.73), "mono", HORIZONTAL_ALIGNMENT_RIGHT, 1, false))
	var seed_text := "SEED %s  ·  %s" % [
		HavenUI.zero_pad(int(data.get("seed", 0)) % 1000000, 6),
		String(data.get("biome", "GOLDEN DESERT")),
	]
	right_column.add_child(HavenUI.label(seed_text, 8, Color(0.50, 0.51, 0.51), "mono", HORIZONTAL_ALIGNMENT_RIGHT, 1, false))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	_stat(grid, "DISTANCE", "%s M" % HavenUI.number(int(data.get("distance", 0))))
	_stat(grid, "COINS", HavenUI.number(int(data.get("coins", 0))))
	_stat(grid, "SHARDS", HavenUI.number(int(data.get("shards", 0))))
	_stat(grid, "TRICKS", HavenUI.number(int(data.get("tricks", 0))))
	_stat(grid, "BEST COMBO", "x%d" % int(data.get("best_combo", 0)))
	_stat(grid, "AIR TIME", _format_time(float(data.get("flight_time", 0.0))))

	var medals := PackedStringArray()
	for medal in data.get("new_achievements", []):
		medals.append("✦  %s" % String(medal))
	var unlock_lines := PackedStringArray()
	if bool(data.get("wingsuit_just_unlocked", false)):
		unlock_lines.append("✦  WINGSUIT UNLOCKED")
	for rider in data.get("riders", []):
		unlock_lines.append("✦  NEW RIDER  ·  %s" % String(rider).to_upper())
	var all_news := PackedStringArray()
	all_news.append_array(unlock_lines)
	all_news.append_array(medals)
	_content.add_child(HavenUI.spacer(3))
	if all_news.is_empty():
		_content.add_child(HavenUI.label("THE ROAD CONTINUES", 9, Color(0.55, 0.56, 0.56), "ui", HORIZONTAL_ALIGNMENT_LEFT, 4, false))
	else:
		var joined := "     ".join(all_news.slice(0, mini(all_news.size(), 4)))
		_content.add_child(HavenUI.label(joined, 10, HavenUI.GOLD, "ui", HORIZONTAL_ALIGNMENT_LEFT, 2, false))
	_content.add_child(HavenUI.spacer(4))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	_content.add_child(actions)
	_retry = HavenUI.button("RIDE AGAIN", true, Vector2(354.0, 50.0), true, 3)
	_retry.name = "RetryButton"
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	actions.add_child(_retry)
	var menu := HavenUI.button("RETURN TO HAVEN", false, Vector2(354.0, 50.0), true, 3)
	menu.name = "MenuButton"
	menu.pressed.connect(func() -> void: menu_requested.emit())
	actions.add_child(menu)
	var hint := HavenUI.label("R  RIDE AGAIN      ESC  RETURN TO THE HAVEN", 8, Color(0.50, 0.51, 0.51), "ui", HORIZONTAL_ALIGNMENT_CENTER, 2, false)
	_content.add_child(hint)
	_content.add_child(HavenUI.spacer(5))
	_content.add_child(HavenUI.rule(736.0, Color(0.956, 0.762, 0.455, 0.13)))
	_content.add_child(HavenUI.label(
		"The dunes do not remember the fall. They remember the line.",
		16, Color(0.70, 0.62, 0.50), "serif", HORIZONTAL_ALIGNMENT_CENTER, 1, false
	))

	_root.modulate.a = 0.0
	_panel.position.y += 14.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_root, "modulate:a", 1.0, 0.40).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_panel, "position:y", _panel.position.y - 14.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_retry.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			if key.keycode == KEY_R:
				retry_requested.emit()
			elif key.keycode == KEY_ESCAPE:
				menu_requested.emit()


func _stat(grid: GridContainer, heading: String, value: String) -> void:
	var panel := HavenUI.panel_container(HavenUI.panel_style(Color(0.043, 0.053, 0.078, 0.76), Color(0.956, 0.762, 0.455, 0.14), 3, 1, 12.0))
	panel.custom_minimum_size = Vector2(238.0, 54.0)
	grid.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -3)
	panel.add_child(column)
	column.add_child(HavenUI.label(heading, 8, Color(0.58, 0.61, 0.63), "ui", HORIZONTAL_ALIGNMENT_LEFT, 2, false))
	column.add_child(HavenUI.label(value, 20, HavenUI.CREAM, "display", HORIZONTAL_ALIGNMENT_LEFT, 1))


func _reason_text(reason: String) -> String:
	match reason:
		"landing":
			return "The board came down out of alignment. The desert is patient; try the line again."
		"rock":
			return "A stone in the path. Read the dunes earlier and carry your speed around it."
		"fall":
			return "The chasm kept what it was owed. Jump earlier and trust the far lip."
		_:
			return "Every ending is a new line down the mountain."


func _format_time(seconds: float) -> String:
	var total := maxf(0.0, seconds)
	var minutes := int(total / 60.0)
	var remainder := total - float(minutes) * 60.0
	return "%02d:%04.1f" % [minutes, remainder]


func _vignette() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.58))
	gradient.add_point(0.55, Color(0.0, 0.0, 0.0, 0.0))
	gradient.add_point(0.85, Color(0.0, 0.0, 0.0, 0.22))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 512
	texture.height = 512
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.05, 1.05)
	return texture
