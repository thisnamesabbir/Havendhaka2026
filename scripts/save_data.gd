extends Node

## Persistent profile for HAVEN DHAKA 2026.
## The schema is intentionally small, typed and defensive: a corrupt or older
## save falls back to safe defaults instead of breaking the title screen.

const SAVE_PATH := "user://haven_dhaka_2026.cfg"
const LEGACY_PATH := "user://echo_save.cfg"
const DATA_VERSION := 3
const DEFAULT_CHARACTER := "wayfarer"
const RIDER_ORDER := ["wayfarer", "mirage", "ember"]

const ACHIEVEMENTS := [
	{"id": "first_ride", "title": "FIRST TRACKS", "detail": "Complete your first run."},
	{"id": "coin_50", "title": "DUST & GOLD", "detail": "Collect 50 coins."},
	{"id": "coin_250", "title": "THE QUIET HOARD", "detail": "Collect 250 coins."},
	{"id": "shard_10", "title": "FIRST LIGHT", "detail": "Gather 10 energy shards."},
	{"id": "trick_10", "title": "SAND SPINNER", "detail": "Land 10 tricks."},
	{"id": "trick_50", "title": "SKY WEAVER", "detail": "Land 50 tricks."},
	{"id": "flawless", "title": "FLAWLESS", "detail": "Stick a perfect landing."},
	{"id": "combo_5", "title": "KITE STRING", "detail": "Reach a x5 combo."},
	{"id": "distance_500", "title": "OUT OF THE DUNES", "detail": "Ride 500 m in one run."},
	{"id": "distance_1500", "title": "HORIZON CHASER", "detail": "Ride 1,500 m in one run."},
	{"id": "distance_3000", "title": "WHERE THE ROAD ENDS", "detail": "Ride 3,000 m in one run."},
	{"id": "wing_10", "title": "WINGS OF THE DUNES", "detail": "Fly 10 seconds in one run."},
	{"id": "wingsuit", "title": "THE LONG WAY DOWN", "detail": "Unlock the wingsuit."},
	{"id": "riders_3", "title": "THE WHOLE CARAVAN", "detail": "Unlock all three riders."},
]

var best_score := 0
var best_distance := 0
var total_distance := 0
var total_runs := 0
var total_coins := 0
var total_shards := 0
var total_tricks := 0
var best_combo := 0
var perfect_landings := 0
var total_flight_time := 0.0
var longest_flight := 0.0
var wingsuit_unlocked := false
var achievements: PackedStringArray = PackedStringArray()
var unlocked_characters: PackedStringArray = PackedStringArray([DEFAULT_CHARACTER])
var selected_character := DEFAULT_CHARACTER
var current_seed := 0
var last_seed := 0
var tutorial_seen := false
var settings := {
	"master_volume": 0.92,
	"music_volume": 0.55,
	"sfx_volume": 0.82,
	"screen_shake": 1.0,
}


func _ready() -> void:
	load_data()
	if current_seed <= 0:
		current_seed = _make_seed()
	AudioManager.apply_saved_volumes()


func load_data() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		_load_legacy_or_defaults()
		save_data()
		return
	if error != OK:
		push_warning("HAVEN save could not be read; using defaults: %s" % error_string(error))
		_sanitize()
		return
	var version := int(config.get_value("meta", "version", 0))
	if version != DATA_VERSION:
		push_warning("HAVEN save version %s is unsupported; using defaults." % version)
		_load_legacy_or_defaults()
		save_data()
		return
	best_score = maxi(0, int(config.get_value("progress", "best_score", 0)))
	best_distance = maxi(0, int(config.get_value("progress", "best_distance", 0)))
	total_distance = maxi(0, int(config.get_value("progress", "total_distance", 0)))
	total_runs = maxi(0, int(config.get_value("progress", "total_runs", 0)))
	total_coins = maxi(0, int(config.get_value("progress", "total_coins", 0)))
	total_shards = maxi(0, int(config.get_value("progress", "total_shards", 0)))
	total_tricks = maxi(0, int(config.get_value("progress", "total_tricks", 0)))
	best_combo = maxi(0, int(config.get_value("progress", "best_combo", 0)))
	perfect_landings = maxi(0, int(config.get_value("progress", "perfect_landings", 0)))
	total_flight_time = maxf(0.0, float(config.get_value("progress", "total_flight_time", 0.0)))
	longest_flight = maxf(0.0, float(config.get_value("progress", "longest_flight", 0.0)))
	wingsuit_unlocked = bool(config.get_value("progress", "wingsuit_unlocked", false))
	achievements = PackedStringArray(config.get_value("progress", "achievements", PackedStringArray()))
	unlocked_characters = PackedStringArray(config.get_value("progress", "unlocked_characters", PackedStringArray([DEFAULT_CHARACTER])))
	selected_character = String(config.get_value("profile", "selected_character", DEFAULT_CHARACTER))
	current_seed = maxi(0, int(config.get_value("profile", "current_seed", 0)))
	last_seed = maxi(0, int(config.get_value("profile", "last_seed", 0)))
	tutorial_seen = bool(config.get_value("profile", "tutorial_seen", false))
	for setting_name in settings:
		var value: Variant = config.get_value("settings", setting_name, settings[setting_name])
		if (typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT) and is_finite(float(value)):
			settings[setting_name] = clampf(float(value), 0.0, 1.0)
	_sanitize()


func _load_legacy_or_defaults() -> void:
	_sanitize()
	var config := ConfigFile.new()
	if config.load(LEGACY_PATH) != OK:
		return
	best_score = maxi(0, int(config.get_value("progress", "best_score", 0)))
	best_distance = maxi(0, int(config.get_value("progress", "best_distance", 0)))
	total_distance = maxi(0, int(config.get_value("progress", "total_distance", 0)))
	total_coins = maxi(0, int(config.get_value("progress", "total_crystals", 0)))
	tutorial_seen = best_score > 0


func _sanitize() -> void:
	best_score = maxi(0, best_score)
	best_distance = maxi(0, best_distance)
	total_distance = maxi(total_distance, best_distance)
	total_runs = maxi(0, total_runs)
	total_coins = maxi(0, total_coins)
	total_shards = maxi(0, total_shards)
	total_tricks = maxi(0, total_tricks)
	best_combo = maxi(best_combo, 0)
	perfect_landings = maxi(0, perfect_landings)
	total_flight_time = maxf(0.0, total_flight_time)
	longest_flight = maxf(longest_flight, 0.0)
	if not unlocked_characters.has(DEFAULT_CHARACTER):
		unlocked_characters.append(DEFAULT_CHARACTER)
	if not unlocked_characters.has(selected_character):
		selected_character = DEFAULT_CHARACTER
	if current_seed <= 0:
		current_seed = _make_seed()
	if last_seed <= 0:
		last_seed = current_seed


func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", DATA_VERSION)
	config.set_value("progress", "best_score", best_score)
	config.set_value("progress", "best_distance", best_distance)
	config.set_value("progress", "total_distance", total_distance)
	config.set_value("progress", "total_runs", total_runs)
	config.set_value("progress", "total_coins", total_coins)
	config.set_value("progress", "total_shards", total_shards)
	config.set_value("progress", "total_tricks", total_tricks)
	config.set_value("progress", "best_combo", best_combo)
	config.set_value("progress", "perfect_landings", perfect_landings)
	config.set_value("progress", "total_flight_time", total_flight_time)
	config.set_value("progress", "longest_flight", longest_flight)
	config.set_value("progress", "wingsuit_unlocked", wingsuit_unlocked)
	config.set_value("progress", "achievements", achievements)
	config.set_value("progress", "unlocked_characters", unlocked_characters)
	config.set_value("profile", "selected_character", selected_character)
	config.set_value("profile", "current_seed", current_seed)
	config.set_value("profile", "last_seed", last_seed)
	config.set_value("profile", "tutorial_seen", tutorial_seen)
	for setting_name in settings:
		config.set_value("settings", setting_name, settings[setting_name])
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_error("Could not save HAVEN data: %s" % error_string(error))


func begin_run() -> int:
	current_seed = _make_seed()
	last_seed = current_seed
	save_data()
	return current_seed


func record_run(score: int, coins: int, shards: int, tricks: int, distance: int,
		run_best_combo: int, perfects: int, flight_time: float) -> Dictionary:
	var winged_before := wingsuit_unlocked
	var riders_before := PackedStringArray(unlocked_characters)
	best_score = maxi(best_score, maxi(0, score))
	best_distance = maxi(best_distance, maxi(0, distance))
	total_distance += maxi(0, distance)
	total_runs += 1
	total_coins += maxi(0, coins)
	total_shards += maxi(0, shards)
	total_tricks += maxi(0, tricks)
	best_combo = maxi(best_combo, maxi(0, run_best_combo))
	perfect_landings += maxi(0, perfects)
	total_flight_time += maxf(0.0, flight_time)
	longest_flight = maxf(longest_flight, flight_time)
	var unlocked_now := refresh_unlocks()
	var new_achievements := check_achievements()
	last_seed = current_seed
	save_data()
	return {
		"new_achievements": new_achievements,
		"riders": unlocked_now["riders"],
		"wingsuit_just_unlocked": wingsuit_unlocked and not winged_before,
		"riders_before": riders_before,
	}


func refresh_unlocks() -> Dictionary:
	var newly_unlocked: Array = []
	if not wingsuit_unlocked and (best_distance >= 500 or total_shards >= 5):
		wingsuit_unlocked = true
	if best_distance >= 800 and not unlocked_characters.has("mirage"):
		unlocked_characters.append("mirage")
		newly_unlocked.append("mirage")
	if total_tricks >= 10 and not unlocked_characters.has("ember"):
		unlocked_characters.append("ember")
		newly_unlocked.append("ember")
	return {"riders": newly_unlocked, "wingsuit": wingsuit_unlocked}


func check_achievements() -> Array:
	var earned: Array = []
	_add_achievement("first_ride", total_runs >= 1, earned)
	_add_achievement("coin_50", total_coins >= 50, earned)
	_add_achievement("coin_250", total_coins >= 250, earned)
	_add_achievement("shard_10", total_shards >= 10, earned)
	_add_achievement("trick_10", total_tricks >= 10, earned)
	_add_achievement("trick_50", total_tricks >= 50, earned)
	_add_achievement("flawless", perfect_landings >= 1, earned)
	_add_achievement("combo_5", best_combo >= 5, earned)
	_add_achievement("distance_500", best_distance >= 500, earned)
	_add_achievement("distance_1500", best_distance >= 1500, earned)
	_add_achievement("distance_3000", best_distance >= 3000, earned)
	_add_achievement("wing_10", longest_flight >= 10.0, earned)
	_add_achievement("wingsuit", wingsuit_unlocked, earned)
	_add_achievement("riders_3", unlocked_characters.size() >= 3, earned)
	return earned


func _add_achievement(id: String, condition: bool, earned: Array) -> void:
	if condition and not achievements.has(id):
		achievements.append(id)
		earned.append(id)


func get_achievement_title(id: String) -> String:
	for entry in ACHIEVEMENTS:
		if String(entry["id"]) == id:
			return String(entry["title"])
	return id.to_upper()


func get_achievement_defs() -> Array:
	var result: Array = []
	for entry in ACHIEVEMENTS:
		var copy: Dictionary = entry.duplicate()
		copy["earned"] = achievements.has(String(entry["id"]))
		result.append(copy)
	return result


func get_achievement_progress() -> Vector2i:
	return Vector2i(achievements.size(), ACHIEVEMENTS.size())


func set_character(rider_id: String) -> bool:
	if not unlocked_characters.has(rider_id):
		return false
	selected_character = rider_id
	save_data()
	return true


func unlock_wingsuit() -> bool:
	if wingsuit_unlocked:
		return false
	wingsuit_unlocked = true
	check_achievements()
	save_data()
	return true


func mark_tutorial_seen() -> void:
	tutorial_seen = true
	save_data()


func set_setting(setting_name: String, value: float) -> void:
	if not settings.has(setting_name):
		push_error("Unknown HAVEN setting: %s" % setting_name)
		return
	if not is_finite(value):
		push_error("HAVEN setting must be finite: %s" % setting_name)
		return
	settings[setting_name] = clampf(value, 0.0, 1.0)


func get_setting(setting_name: String) -> float:
	return float(settings.get(setting_name, 1.0))


func get_unlocked_character_count() -> int:
	var count := 0
	for rider_id in RIDER_ORDER:
		if unlocked_characters.has(rider_id):
			count += 1
	return count


func get_selected_character() -> int:
	var index := RIDER_ORDER.find(selected_character)
	return maxi(0, index)


func _make_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(100000, 999999999)
