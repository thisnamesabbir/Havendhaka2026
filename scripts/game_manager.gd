extends Node2D

## Run director for HAVEN DHAKA 2026. It turns the raw simulation into a
## scored expedition: combos, landings, wingsuit unlocks, biome reveales,
## achievements, pause flow and the printed end-of-run record.

const GameOverScene = preload("res://scenes/game_over.tscn")
const COMBO_WINDOW := 5.2

@onready var world: HavenWorld = $World
@onready var player: HavenPlayer = $Player
@onready var camera: HavenCamera = $Camera2D
@onready var hud: GameHUD = $HUD

var score := 0
var distance := 0
var coins := 0
var shards := 0
var tricks := 0
var best_combo := 0
var perfects := 0
var flight_time := 0.0
var combo := 0
var combo_timer := 0.0
var run_active := true

var _initial_best_score := 0
var _initial_best_distance := 0
var _biome_index := 0
var _music_category := ""
var _ui_timer := 0.0
var _audio_timer := 0.0
var _unlock_timer := 0.0
var _trick_name := ""
var _trick_landed_this_frame := false
var _end_shown := false
var _tutorial_pause := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	world.player = player
	_initial_best_score = SaveData.best_score
	_initial_best_distance = SaveData.best_distance
	player.set_wingsuit_unlocked(SaveData.wingsuit_unlocked)
	_connect_signals()
	_biome_index = world.biome_index_at(player.global_position.x)
	_music_category = _music_for_biome(_biome_index)
	AudioManager.start_music(_music_category)
	camera.set_target(player)
	hud.update_stats(
		0, 0, 0, 0, player.get_speed_kph(),
		HavenTheme.BIOME_NAMES[_biome_index],
		HavenTheme.BIOME_TAGLINES[_biome_index],
		0, 0.0, SaveData.wingsuit_unlocked, false, SaveData.best_score
	)
	if not SaveData.tutorial_seen:
		_start_tutorial.call_deferred()


func _connect_signals() -> void:
	player.died.connect(_on_player_died)
	player.crashed.connect(_on_player_crashed)
	player.landed.connect(_on_player_landed)
	player.trick_landed.connect(_on_trick_landed)
	player.trick_failed.connect(_on_trick_failed)
	player.trick_started.connect(_on_trick_started)
	player.wingsuit_changed.connect(_on_wingsuit_changed)
	player.perfect_landing.connect(_on_perfect_landing)
	player.rock_bounced.connect(_on_rock_bounced)
	world.pickup_collected.connect(_on_pickup_collected)
	world.biome_changed.connect(_on_biome_changed)
	hud.pause_requested.connect(_toggle_pause)
	hud.restart_requested.connect(_restart_run)
	hud.menu_requested.connect(_return_to_menu)
	hud.quit_requested.connect(_quit_game)
	hud.tutorial_closed.connect(_on_tutorial_closed)
	hud.touch_jump.connect(func(pressed: bool) -> void: player.set_touch_jump(pressed))
	hud.touch_slide.connect(func(pressed: bool) -> void: player.set_touch_down(pressed))
	hud.touch_steer.connect(func(value: float) -> void: player.set_touch_steer(value))
	hud.touch_wingsuit.connect(func() -> void: player.toggle_wingsuit())


func _process(delta: float) -> void:
	if get_tree().paused or _end_shown:
		return
	if run_active:
		var new_distance := world.distance_at(player.global_position.x)
		if new_distance > distance:
			score += (new_distance - distance) * 10
			distance = new_distance
		if combo > 0.0:
			combo_timer = maxf(0.0, combo_timer - delta)
			if combo_timer <= 0.0:
				combo = 0
		if player.is_wingsuit_deployed():
			flight_time += delta
		_ui_timer += delta
		_audio_timer += delta
		_unlock_timer += delta
		if _ui_timer >= 0.07:
			_ui_timer = 0.0
			_refresh_hud()
		if _audio_timer >= 0.08:
			_audio_timer = 0.0
			AudioManager.set_ride_audio(player.speed_ratio(), player.is_on_floor(), player.is_wingsuit_deployed())
		if _unlock_timer >= 0.8:
			_unlock_timer = 0.0
			_check_progression()


func _refresh_hud() -> void:
	var ratio := combo_timer / COMBO_WINDOW if combo > 0 else 0.0
	hud.update_stats(
		distance,
		score,
		coins,
		shards,
		player.get_speed_kph(),
		HavenTheme.BIOME_NAMES[_biome_index],
		HavenTheme.BIOME_TAGLINES[_biome_index],
		combo,
		ratio,
		SaveData.wingsuit_unlocked,
		player.is_wingsuit_deployed(),
		SaveData.best_score
	)
	if player.is_tricking():
		hud.set_trick(_trick_name, player.get_trick_turns(), true)
	else:
		hud.set_trick("", 0, false)


# --------------------------------------------------------------------------
# Scoring and progression
# --------------------------------------------------------------------------

func _on_trick_landed(trick_name: String, rotations: int, airtime: float, _rating: String) -> void:
	if not run_active:
		return
	_trick_landed_this_frame = true
	tricks += 1
	combo = mini(combo + 1, 9)
	best_combo = maxi(best_combo, combo)
	combo_timer = COMBO_WINDOW
	var table := [0, 90, 250, 480, 780]
	var base: int = table[mini(rotations, table.size() - 1)] + int(airtime * 34.0)
	var multiplier := 1.0 + float(combo - 1) * 0.35
	var points := int(float(base) * multiplier)
	score += points
	var subtitle := "COMBO x%d  ·  %.1f S AIR" % [combo, airtime] if combo > 1 else "%.1f S AIR" % airtime
	hud.show_toast("%s  +%s" % [trick_name, HavenUI.number(points)], subtitle, HavenUI.GOLD_LIGHT, 1.6)
	if combo >= 3:
		AudioManager.play_sfx("combo", 1.0 + float(combo) * 0.03)
	_trick_name = ""


func _on_trick_failed(_trick_name_text: String) -> void:
	_trick_landed_this_frame = true
	combo = 0
	combo_timer = 0.0
	hud.show_toast("TRICK LOST", "THE SAND IS UNFORGIVING", HavenUI.CORAL, 1.0)


func _on_trick_started(trick_name: String) -> void:
	_trick_name = trick_name.capitalize()


func _on_player_landed(rating: String, airtime: float, rotations: int, impact_speed: float, chasm_jump: bool) -> void:
	if not run_active:
		return
	var had_trick := _trick_landed_this_frame
	_trick_landed_this_frame = false
	if rating == "perfect":
		perfects += 1
		score += 50
		camera.landing_pulse(1.15)
	elif rating == "rough":
		combo = 0
		combo_timer = 0.0
		camera.landing_pulse(0.8)
		if not had_trick:
			hud.show_rating(rating, 0)
	else:
		camera.landing_pulse(0.9)
		if not had_trick:
			hud.show_rating(rating, 0)
	if impact_speed > 620.0:
		camera.shake(clampf(impact_speed / 130.0, 2.0, 7.0), 0.22)
	if chasm_jump:
		score += 250
		hud.show_toast("CHASM CLEARED", "+250 POINTS  ·  %.1f S AIR" % airtime, HavenUI.CYAN, 1.5)
	_trick_name = ""


func _on_perfect_landing(_world_position: Vector2) -> void:
	camera.landing_pulse(1.25)


func _on_rock_bounced() -> void:
	combo = mini(combo + 1, 9)
	best_combo = maxi(best_combo, combo)
	combo_timer = COMBO_WINDOW
	score += 50
	camera.shake(3.2, 0.22)
	hud.show_toast("ROCK BOUNCE", "+50 POINTS", HavenUI.GOLD_LIGHT, 1.05)


func _on_pickup_collected(kind: String, value: int, _world_position: Vector2) -> void:
	if not run_active:
		return
	if kind == "coin":
		coins += 1
		score += 20 + maxi(0, value - 1) * 5
	else:
		shards += 1
		score += 125 * maxi(1, value)
		camera.shake(1.2, 0.15)
	_check_progression()


func _check_progression() -> void:
	if not SaveData.wingsuit_unlocked and (distance >= 500 or shards >= 5):
		SaveData.unlock_wingsuit()
		player.set_wingsuit_unlocked(true)
		hud.show_wingsuit_unlock()
		AudioManager.play_sfx("achievement")
	var unlocked := SaveData.refresh_unlocks()
	for rider_id in unlocked["riders"]:
		var index := SaveData.RIDER_ORDER.find(String(rider_id))
		if index >= 0:
			var rider_name := String(RiderArt.RIDERS[index]["name"])
			hud.show_toast("NEW RIDER UNLOCKED", rider_name, HavenUI.GOLD_LIGHT, 2.6)
			AudioManager.play_sfx("achievement")
			SaveData.save_data()


func _unlock_name(rider_id: String) -> String:
	var index := SaveData.RIDER_ORDER.find(rider_id)
	if index < 0:
		return rider_id.to_upper()
	return String(RiderArt.RIDERS[index]["name"])


# --------------------------------------------------------------------------
# World signals
# --------------------------------------------------------------------------

func _on_biome_changed(index: int, biome_name: String) -> void:
	_biome_index = index
	hud.show_biome_card(index, biome_name, HavenTheme.BIOME_TAGLINES[index])
	AudioManager.play_sfx("biome", 0.95)
	if not player.is_wingsuit_deployed():
		_music_category = _music_for_biome(index)
		AudioManager.set_music(_music_category)


func _music_for_biome(index: int) -> String:
	if index <= 1:
		return "dawn"
	if index <= 3:
		return "day"
	if index <= 5:
		return "dusk"
	return "night"


func _on_wingsuit_changed(deployed: bool) -> void:
	if deployed:
		AudioManager.set_music("flight")
		hud.show_toast("WINGSUIT OPEN", "SPACE LIFT  ·  DOWN DIVE  ·  SHIFT STOW", HavenUI.CYAN, 1.5)
	else:
		AudioManager.set_music(_music_category)


func _on_player_crashed(reason: String) -> void:
	run_active = false
	combo = 0
	combo_timer = 0.0
	camera.shake(13.0, 0.55)
	var copy := "WIPEOUT"
	if reason == "rock":
		copy = "THE STONE HELD ITS GROUND"
	elif reason == "fall":
		copy = "THE CHASM KEPT ITS SECRET"
	elif reason == "landing":
		copy = "THE BOARD CAME DOWN SIDEWAYS"
	hud.show_toast(copy, "", HavenUI.CORAL, 1.2)
	hud.set_trick("", 0, false)


func _on_player_died(reason: String) -> void:
	if _end_shown:
		return
	_finish_run(reason)


func _finish_run(reason: String) -> void:
	_end_shown = true
	run_active = false
	hud.set_trick("", 0, false)
	var old_best_score := _initial_best_score
	var old_best_distance := _initial_best_distance
	var result := SaveData.record_run(
		score,
		coins,
		shards,
		tricks,
		distance,
		best_combo,
		perfects,
		flight_time
	)
	var achievement_titles: Array[String] = []
	for achievement_id in result["new_achievements"]:
		achievement_titles.append(SaveData.get_achievement_title(String(achievement_id)))
	var rider_names: Array[String] = []
	for rider_id in result["riders"]:
		rider_names.append(_unlock_name(String(rider_id)))
	var data := {
		"score": score,
		"distance": distance,
		"coins": coins,
		"shards": shards,
		"tricks": tricks,
		"best_combo": best_combo,
		"perfects": perfects,
		"flight_time": flight_time,
		"reason": reason,
		"new_best_score": score > old_best_score,
		"new_best_distance": distance > old_best_distance,
		"best_score": SaveData.best_score,
		"best_distance": SaveData.best_distance,
		"new_achievements": achievement_titles,
		"riders": rider_names,
		"wingsuit_just_unlocked": bool(result["wingsuit_just_unlocked"]),
		"seed": SaveData.current_seed,
		"biome": HavenTheme.BIOME_NAMES[_biome_index],
	}
	AudioManager.set_ride_audio(0.0, false, false)
	get_tree().paused = true
	var overlay: HavenGameOver = GameOverScene.instantiate()
	add_child(overlay)
	overlay.present(data)
	overlay.retry_requested.connect(_restart_run)
	overlay.menu_requested.connect(_return_to_menu)


# --------------------------------------------------------------------------
# Flow
# --------------------------------------------------------------------------

func _start_tutorial() -> void:
	_tutorial_pause = true
	get_tree().paused = true
	hud.show_tutorial()


func _on_tutorial_closed(from_pause: bool) -> void:
	if from_pause:
		return
	if _tutorial_pause:
		_tutorial_pause = false
		SaveData.mark_tutorial_seen()
		get_tree().paused = false


func _toggle_pause() -> void:
	if _end_shown or hud.is_tutorial_visible():
		return
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	hud.set_paused(should_pause)
	AudioManager.play_sfx("ui")
	if not should_pause:
		SaveData.save_data()


func _unhandled_input(event: InputEvent) -> void:
	if _end_shown:
		return
	var pressed := false
	if event.is_action_pressed("ui_cancel"):
		pressed = true
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_P:
			pressed = true
	if not pressed:
		return
	if hud.is_tutorial_visible():
		hud.close_tutorial()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused or hud.is_pause_visible():
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _restart_run() -> void:
	get_tree().paused = false
	SaveData.current_seed = SaveData.begin_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _return_to_menu() -> void:
	get_tree().paused = false
	SaveData.save_data()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _quit_game() -> void:
	SaveData.save_data()
	get_tree().quit()
