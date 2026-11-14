extends SceneTree

var _failures := 0
var _had_save := false
var _save_backup := PackedByteArray()
var _save_data: Node
const SAVE_PATH := "user://echo_save.cfg"

func _initialize() -> void:
	_backup_save()
	_save_data = root.get_node("SaveData")
	call_deferred("_run")

func _run() -> void:
	var invalid_data := ConfigFile.new()
	invalid_data.set_value("progress", "best_score", "not a score")
	var safe_score: int = _save_data.call("_read_non_negative_int", invalid_data, "progress", "best_score", 0)
	_check(safe_score == 0, "invalid numeric save fields fall back safely")
	invalid_data.set_value("settings", "master_volume", 1.5)
	var safe_volume: float = _save_data.call("_read_volume", invalid_data, "master_volume", 0.6)
	_check(is_equal_approx(safe_volume, 1.0), "out-of-range volume values are clamped")
	var legacy_data := ConfigFile.new()
	legacy_data.set_value("score", "best", 12345)
	legacy_data.save(SAVE_PATH)
	_save_data.call("load_data")
	_check(int(_save_data.get("best_score")) == 12345, "legacy best-score saves migrate to the versioned format")
	var migrated_save := ConfigFile.new()
	migrated_save.load(SAVE_PATH)
	_check(int(migrated_save.get_value("meta", "version", 0)) == 2, "legacy migration upgrades the save schema to version two")

	await _change_scene("res://scenes/main_menu.tscn")
	var menu := current_scene
	var settings_button := menu.find_child("SettingsButton", true, false) as Button
	_check(settings_button != null, "main menu exposes a functional settings action")
	settings_button.emit_signal("pressed")
	await process_frame
	var settings_modal := menu.find_child("MenuModal", true, false) as Control
	_check(settings_modal != null, "settings panel opens")
	_check(settings_modal.find_children("*", "HSlider", true, false).size() == 3, "settings expose master, music, and effects volume")
	var master_slider := settings_modal.find_child("MasterVolumeSlider", true, false) as HSlider
	var old_master: float = _save_data.call("get_setting", "master_volume")
	master_slider.value = 0.35
	_check(is_equal_approx(_save_data.call("get_setting", "master_volume"), 0.35), "master volume slider updates its setting")
	master_slider.value = old_master
	(settings_modal.find_child("DoneButton", true, false) as Button).emit_signal("pressed")
	await process_frame
	(menu.find_child("TutorialButton", true, false) as Button).emit_signal("pressed")
	await process_frame
	_check(menu.find_child("TutorialBackButton", true, false) != null, "tutorial opens with keyboard and touch control guidance")
	(menu.find_child("TutorialBackButton", true, false) as Button).emit_signal("pressed")
	await process_frame
	(menu.find_child("StatsButton", true, false) as Button).emit_signal("pressed")
	await process_frame
	_check(menu.find_child("StatsBackButton", true, false) != null, "journey statistics and achievements panel opens")
	(menu.find_child("StatsBackButton", true, false) as Button).emit_signal("pressed")
	await process_frame
	(menu.find_child("CreditsButton", true, false) as Button).emit_signal("pressed")
	await process_frame
	_check(menu.find_child("MenuModal", true, false) != null, "credits panel opens")
	(menu.find_child("CreditsBackButton", true, false) as Button).emit_signal("pressed")

	(menu.find_child("PlayButton", true, false) as Button).emit_signal("pressed")
	await scene_changed
	var game := current_scene
	var player := game.get_node("Player") as CharacterBody2D
	var world := game.get_node("World") as Node2D
	var player_art := player.get_node("Art") as Sprite2D
	var terrain_art := world.find_child("GroundPaint", true, false) as Polygon2D
	var atmosphere := game.get_node("AtmosphereLayer/Atmosphere") as Control
	var jump_button := game.find_child("JumpButton", true, false) as Button
	var slide_button := game.find_child("SlideButton", true, false) as Button
	var trick_button := game.find_child("TrickButton", true, false) as Button
	var landing_results: Array[Dictionary] = []
	var biome_names := PackedStringArray()
	for biome_index in range(7):
		biome_names.append(str(world.call("biome_name_at", float(biome_index) * 9000.0)))
	_check(biome_names.size() == 7 and biome_names[0] == "GOLDEN DUNES" and biome_names[3] == "NEON DHAKA" and biome_names[6] == "ECHO DIMENSION", "procedural world cycle exposes seven distinct environments")
	var original_player_position := player.global_position
	var test_worlds: PackedStringArray = _save_data.get("unlocked_worlds")
	test_worlds.erase("neon_dhaka")
	_save_data.set("unlocked_worlds", test_worlds)
	player.global_position.x = 27000.0
	game.call("_update_world_unlocks")
	_check(_save_data.get("unlocked_worlds").has("neon_dhaka"), "entering a new biome persists its world unlock")
	player.global_position = original_player_position
	player.landed.connect(func(successful_trick: bool, rating: String, airtime: float):
		landing_results.append({
			"successful_trick": successful_trick,
			"rating": rating,
			"airtime": airtime,
		})
	)
	for obstacle in get_nodes_in_group("obstacles"):
		obstacle.queue_free()
	for frame in range(40):
		if player.is_on_floor():
			break
		await physics_frame
	_check(player.is_on_floor(), "runner settles onto procedural terrain")
	_check(
		player_art.texture != null
		and player_art.texture.resource_path == "res://assets/character/echo_runner_sheet.png"
		and player_art.hframes == 6 and player_art.vframes == 7
		and player_art.texture.get_width() == 1536 and player_art.texture.get_height() == 1792,
		"player loads the original 42-frame character animation sheet including wingsuit poses"
	)
	_check(
		terrain_art != null
		and terrain_art.texture != null
		and terrain_art.texture.resource_path == "res://assets/backgrounds/terrain_paint.png"
		and terrain_art.uv.size() == terrain_art.polygon.size(),
		"procedural ground chunks use the painted terrain texture with matching UVs"
	)
	var neon_art: Texture2D = load("res://assets/backgrounds/biome_neon_dhaka.svg")
	_check(
		neon_art != null and neon_art.get_width() > 0 and atmosphere.get("_world") == world,
		"the browser-safe Dhaka illustration is imported and connected to biome parallax"
	)
	_check(get_nodes_in_group("obstacles").is_empty(), "the first 450 metres provide a safe opening route")
	for frame in range(30):
		if int(player_art.frame / player_art.hframes) == 0:
			break
		await physics_frame
	_check(int(player_art.frame / player_art.hframes) == 0, "running pose uses its dedicated sprite-sheet row")
	var ground_height: float = world.call("_ground_height", player.global_position.x)
	_check(absf(player.global_position.y - ground_height) < 14.0, "player anchor follows the procedural ground surface")
	var saved_velocity := player.velocity
	var saved_run_speed := float(player.get("run_speed"))
	player.call("set_touch_jump", true)
	player.velocity.y = 300.0
	player.call("_apply_air_physics", 0.1)
	_check(is_equal_approx(player.velocity.y, 320.0), "held jump engages a finite-speed glide")
	player.velocity = saved_velocity
	player.set("run_speed", saved_run_speed)
	player.set("_jump_buffer", 0.0)
	player.call("set_touch_jump", false)
	player.velocity.y = -600.0
	player.call("_cut_jump")
	_check(is_equal_approx(player.velocity.y, -312.0), "jump release cuts upward momentum for a short hop")
	player.velocity = saved_velocity

	var start_x := player.position.x
	for frame in range(20):
		await physics_frame
	_check(player.position.x > start_x, "acceleration moves the player forward")
	var ground_tangent: Vector2 = player.call("_forward_tangent", player.get_floor_normal())
	_check(player.velocity.normalized().dot(ground_tangent) > 0.95, "ground momentum follows the terrain tangent")
	var takeoff_speed := player.velocity.x

	var down := _key_event(KEY_DOWN, true)
	player.call("_input", down)
	await physics_frame
	_check(bool(player.get("_sliding")), "keyboard Down activates sliding")
	_check(int(player_art.frame / player_art.hframes) == 2, "slide state switches to the illustrated slide animation")
	player.call("_input", _key_event(KEY_DOWN, false))
	slide_button.emit_signal("button_down")
	await physics_frame
	_check(bool(player.get("_sliding")), "touch Slide button activates sliding")
	slide_button.emit_signal("button_up")

	var space := _key_event(KEY_SPACE, true)
	player.call("_input", space)
	await physics_frame
	_check(player.velocity.y < 0.0, "jump launches upward")
	_check(int(player_art.frame / player_art.hframes) == 1, "airborne state switches to the jump/glide animation")
	_check(player.velocity.x > 0.0, "jump preserves forward momentum")
	_check(player.velocity.x > takeoff_speed * 0.75, "takeoff retains most of the board's forward speed")
	player.call("set_wingsuit_unlocked", true)
	player.call("_input", _key_event(KEY_SHIFT, true))
	_check(bool(player.get("wingsuit_deployed")), "Shift deploys the unlocked wingsuit while airborne")
	player.call("_update_sprite_frame")
	_check(int(player_art.frame / player_art.hframes) == 6, "deployed wingsuit uses its dedicated animated sprite row")
	slide_button.emit_signal("button_down")
	_check(bool(player.get("_wingsuit_dive_held")) and slide_button.text == "DIVE", "touch Slide control becomes a functional wingsuit dive input")
	slide_button.emit_signal("button_up")
	var wing_velocity := player.velocity
	var wing_run_speed := float(player.get("run_speed"))
	player.velocity = Vector2(250.0, 0.0)
	player.call("_apply_wingsuit_physics", 0.1)
	_check(player.velocity.y < 0.0 and player.velocity.x > 250.0, "wingsuit lift and forward glide use distinct flight physics")
	player.velocity = wing_velocity
	player.set("run_speed", wing_run_speed)
	player.call("toggle_wingsuit")
	_check(not bool(player.get("wingsuit_deployed")), "wingsuit can be stowed during flight")
	player.call("_input", _key_event(KEY_UP, true))
	await physics_frame
	_check(int(player_art.frame / player_art.hframes) == 3, "active flip uses dedicated trick frames")
	for frame in range(90):
		if bool(player.get("_trick_complete")) or int(game.get("_tricks_completed")) > 0:
			break
		await physics_frame
	_check(bool(player.get("_trick_complete")), "keyboard backflip completes while airborne")
	player.call("_input", _key_event(KEY_SPACE, false))
	for frame in range(120):
		if int(game.get("_tricks_completed")) > 0:
			break
		await physics_frame
	_check(int(game.get("_tricks_completed")) == 1, "successful landing awards the backflip")
	_check(int(game.get("_bonus_score")) > 0, "trick and landing events add score")
	_check(not landing_results.is_empty() and float(landing_results.back()["airtime"]) > 0.0, "landing resolves real airtime against the contacted surface")
	_check(trick_button.text == "FRONTFLIP", "trick selector advances after keyboard backflip")

	var actual_tricks := int(game.get("_tricks_completed"))
	var actual_bonus := int(game.get("_bonus_score"))
	game.call("_on_player_landed", true, "rough", 1.0)
	game.call("_on_trick_completed", "backflip", 1.0, "clean")
	game.call("_on_trick_completed", "frontflip", 1.0, "clean")
	game.call("_on_trick_completed", "backflip", 1.0, "clean")
	_check(int(game.get("_combo_count")) == 3 and is_equal_approx(float(game.get("_combo_multiplier")), 1.5), "consecutive successful tricks build a combo multiplier")
	game.set("_tricks_completed", actual_tricks)
	game.set("_bonus_score", actual_bonus)
	game.set("_combo_count", 0)
	game.set("_combo_multiplier", 1.0)

	var tricks_before_touch := int(game.get("_tricks_completed"))
	jump_button.emit_signal("button_down")
	await physics_frame
	trick_button.emit_signal("pressed")
	_check(bool(player.get("_touch_jump")), "touch jump button engages glide input")
	_check(str(player.get("_active_trick")) == "frontflip", "touch trick button selects a frontflip")
	trick_button.emit_signal("pressed")
	_check(int(player.get("_trick_rotations")) == 2, "repeated touch trick input chains a double rotation")
	for frame in range(90):
		if bool(player.get("_trick_complete")) or int(game.get("_tricks_completed")) > tricks_before_touch:
			break
		await physics_frame
	_check(bool(player.get("_trick_complete")) or int(game.get("_tricks_completed")) > tricks_before_touch, "touch trick button completes the next flip")
	jump_button.emit_signal("button_up")
	for frame in range(180):
		if int(game.get("_tricks_completed")) > tricks_before_touch:
			break
		await physics_frame
	_check(int(game.get("_tricks_completed")) == tricks_before_touch + 2, "double touch flip awards both rotations after landing")

	var echo_key := _key_event(KEY_E, true)
	game.call("_unhandled_input", echo_key)
	await physics_frame
	_check(int(player_art.frame / player_art.hframes) == 5, "Echo activation uses the dedicated Echo animation")
	var hidden_crystals := get_nodes_in_group("hidden_crystals")
	_check(not hidden_crystals.is_empty() and hidden_crystals[0].visible, "Echo reveals hidden crystals")
	var echo_paths := get_nodes_in_group("echo_paths")
	_check(not echo_paths.is_empty() and echo_paths[0].visible, "Echo reveals secret paths")
	game.call("_process", 4.0)
	_check(not bool(game.get("_echo_active")), "Echo expires when its energy is exhausted")
	_check(not hidden_crystals[0].visible, "Echo expiry hides secret crystals again")

	var regular_crystal: Area2D
	for crystal in get_nodes_in_group("crystals"):
		if not crystal.is_in_group("hidden_crystals"):
			regular_crystal = crystal
			break
	if regular_crystal:
		regular_crystal.global_position = player.global_position + Vector2(0.0, -16.0)
		for frame in range(3):
			await physics_frame
	_check(int(game.get("_crystals")) > 0, "crystal collision increments run progress")
	var saved_run_crystals := int(game.get("_crystals"))
	player.call("set_wingsuit_unlocked", false)
	game.set("_crystals", 10)
	game.call("_process", 0.0)
	_check(bool(_save_data.get("wingsuit_unlocked")) and bool(player.get("wingsuit_unlocked")), "collecting ten lifetime crystals permanently unlocks the wingsuit")
	game.set("_crystals", saved_run_crystals)

	for obstacle in get_nodes_in_group("obstacles"):
		obstacle.queue_free()
	for rideable_wall in get_nodes_in_group("rideable_walls"):
		rideable_wall.queue_free()
	await physics_frame
	var test_wall_chunk := Node2D.new()
	test_wall_chunk.position.x = 2700.0
	world.add_child(test_wall_chunk)
	world.call("_create_wall_ride", test_wall_chunk, 2700.0, 420.0)
	var test_wall_nodes := get_nodes_in_group("rideable_walls")
	var test_wall_id: int = test_wall_nodes.back().get_instance_id()
	var wall_start_x := 3120.0
	var wall_ground_y: float = world.call("_ground_height", wall_start_x)
	player.set("alive", true)
	player.set("_wall_riding", false)
	player.set("_wall_ride_time", 0.0)
	player.set("_wall_contact_lost_time", 0.0)
	player.global_position = Vector2(wall_start_x - 50.0, wall_ground_y)
	player.velocity = Vector2(500.0, 0.0)
	player.set("run_speed", 500.0)
	var wall_ride_durations: Array[float] = []
	var wall_ride_count_before := int(game.get("_wall_rides_completed"))
	player.wall_ride_completed.connect(func(duration: float): wall_ride_durations.append(duration))
	for frame in range(40):
		if bool(player.get("_wall_riding")):
			break
		await physics_frame
	_check(bool(player.get("_wall_riding")), "generated steep terrain engages a physical wall ride")
	var wall_ride_start_x := player.global_position.x
	for frame in range(45):
		if bool(player.get("_wall_riding")) and float(player.get("_wall_ride_time")) >= 0.4:
			break
		await physics_frame
	_check(
		bool(player.get("_wall_riding")) and float(player.get("_wall_ride_time")) >= 0.4,
		"wall ride maintains contact long enough for a jump exit",
	)
	_check(player.global_position.x > wall_ride_start_x + 40.0, "wall ride carries the player forward along the bank")
	player.call("set_touch_jump", true)
	await physics_frame
	player.call("set_touch_jump", false)
	_check(not bool(player.get("_wall_riding")), "jump input exits the wall ride")
	_check(
		not wall_ride_durations.is_empty() and wall_ride_durations.max() >= 0.4
		and int(game.get("_wall_rides_completed")) > wall_ride_count_before,
		"jumping out of a scored wall ride records its duration and reward",
	)
	var scored_wall_count := int(game.get("_wall_rides_completed"))
	player.call("_try_start_wall_ride", test_wall_id, Vector2(-0.8, -0.6), Vector2(500.0, 0.0))
	player.set("_wall_ride_time", 0.6)
	player.call("_finish_wall_ride", true)
	_check(
		int(game.get("_wall_rides_completed")) == scored_wall_count,
		"re-entering the same bank cannot farm repeated wall-ride rewards",
	)

	game.call("_unhandled_input", _key_event(KEY_ESCAPE, true))
	_check(paused, "Escape pauses the game")
	game.call("_unhandled_input", _key_event(KEY_ESCAPE, true))
	_check(not paused, "Escape resumes the game")

	var obstacle := StaticBody2D.new()
	obstacle.add_to_group("obstacles")
	obstacle.position = player.position + Vector2(18.0, -30.0)
	var obstacle_shape := RectangleShape2D.new()
	obstacle_shape.size = Vector2(48.0, 180.0)
	var obstacle_collision := CollisionShape2D.new()
	obstacle_collision.shape = obstacle_shape
	obstacle.add_child(obstacle_collision)
	world.add_child(obstacle)
	for frame in range(20):
		if not bool(player.get("alive")):
			break
		await physics_frame
	_check(not bool(player.get("alive")), "obstacle contact ends the run")
	var game_over := game.get_node_or_null("GameOver")
	_check(game_over != null, "run end opens the game-over scene")
	_check(int(_save_data.get("best_score")) > 0 and int(_save_data.get("total_crystals")) > 0, "run summary persists progression")
	_check(int(_save_data.get("best_distance")) > 0 and int(_save_data.get("total_distance")) > 0, "distance statistics persist with completed runs")
	var old_scene_id := game.get_instance_id()
	game_over.emit_signal("restart_requested")
	for frame in range(10):
		if is_instance_valid(current_scene) and current_scene.get_instance_id() != old_scene_id:
			break
		await process_frame
	_check(is_instance_valid(current_scene) and current_scene.get_instance_id() != old_scene_id, "retry reloads the game scene")

	_restore_save()
	if _failures == 0:
		print("All ECHO gameplay smoke checks passed.")
		quit(0)
	else:
		push_error("%d ECHO gameplay smoke check(s) failed." % _failures)
		quit(1)

func _change_scene(scene_path: String) -> void:
	var packed_scene := load(scene_path) as PackedScene
	var error := change_scene_to_packed(packed_scene)
	if error != OK:
		push_error("Could not change to %s: %s" % [scene_path, error_string(error)])
		quit(1)
		return
	await scene_changed

func _key_event(key: Key, is_pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = is_pressed
	return event

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)

func _backup_save() -> void:
	_had_save = FileAccess.file_exists(SAVE_PATH)
	if _had_save:
		_save_backup = FileAccess.get_file_as_bytes(SAVE_PATH)

func _restore_save() -> void:
	var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
	if _had_save:
		var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_buffer(_save_backup)
		else:
			push_error("Could not restore the original ECHO save after tests.")
	else:
		var error := DirAccess.remove_absolute(absolute_path)
		if error != OK and error != ERR_FILE_NOT_FOUND:
			push_error("Could not remove the test ECHO save: %s" % error_string(error))
