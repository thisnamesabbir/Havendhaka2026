extends Node

## Original score and soundscape for HAVEN DHAKA 2026.
## Generated WAV stems are streamed with a two-deck music crossfade, a reactive
## sand/wind bed and a small round-robin SFX pool.

const AUDIO_DIR := "res://assets/audio/"
const MUSIC_FILES := {
	"dawn": "music_dawn.wav",
	"day": "music_dawn.wav",
	"dusk": "music_dusk.wav",
	"night": "music_night.wav",
	"flight": "music_flight.wav",
}
const SFX_FILES := {
	"ui": "sfx_ui.wav",
	"jump": "sfx_jump.wav",
	"land": "sfx_land.wav",
	"perfect": "sfx_perfect.wav",
	"coin": "sfx_coin.wav",
	"shard": "sfx_shard.wav",
	"flip": "sfx_flip.wav",
	"combo": "sfx_combo.wav",
	"crash": "sfx_crash.wav",
	"deploy": "sfx_deploy.wav",
	"biome": "sfx_biome.wav",
	"achievement": "sfx_achievement.wav",
}
const SFX_ALIASES := {
	"trick": "flip",
	"collision": "crash",
	"collect": "coin",
	"echo": "deploy",
	"land_perfect": "perfect",
	"trick_whoosh": "flip",
	"wingsuit_open": "deploy",
	"wingsuit_close": "deploy",
	"rock_bounce": "jump",
	"wind": "flip",
}
const SFX_VOICES := 10

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_current: AudioStreamPlayer
var _music_category := ""
var _music_tween: Tween
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}
var _next_voice := 0
var _sand_player: AudioStreamPlayer
var _wind_player: AudioStreamPlayer
var _wing_player: AudioStreamPlayer
var _ambience_tween: Tween


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_ensure_bus("Ambience")
	_music_a = _make_player("MusicA", "Music", -80.0)
	_music_b = _make_player("MusicB", "Music", -80.0)
	_music_current = _music_a
	for index in range(SFX_VOICES):
		_sfx_players.append(_make_player("SFXVoice%d" % index, "SFX", 0.0))
	for sfx_name in SFX_FILES:
		var stream := _load_stream(AUDIO_DIR + String(SFX_FILES[sfx_name]), false)
		if stream != null:
			_sfx_streams[sfx_name] = stream
	_sand_player = _make_player("SandBed", "Ambience", -80.0)
	_wind_player = _make_player("WindBed", "Ambience", -80.0)
	_wing_player = _make_player("WingBed", "Ambience", -80.0)
	_wind_player.stream = _load_stream(AUDIO_DIR + "loop_wind.wav", true)
	_sand_player.stream = _load_stream(AUDIO_DIR + "loop_sand.wav", true)
	_wing_player.stream = _load_stream(AUDIO_DIR + "loop_wing.wav", true)
	for player in [_wind_player, _sand_player, _wing_player]:
		if player.stream != null and not player.playing:
			player.play()
	apply_saved_volumes()


func _exit_tree() -> void:
	_music_a.stop()
	_music_b.stop()
	for player in _sfx_players:
		player.stop()
	_sand_player.stop()
	_wind_player.stop()
	_wing_player.stop()


func _make_player(player_name: String, bus_name: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	player.volume_db = volume
	add_child(player)
	return player


func _load_stream(path: String, loop: bool) -> AudioStream:
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("HAVEN audio missing: %s" % path)
		return null
	if loop and stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		var length := wav.get_length()
		if length > 0.0:
			wav.loop_end = int(length * float(wav.mix_rate))
	return stream


func start_music(category: String = "dawn") -> void:
	if _music_category.is_empty():
		set_music(category, true)
	elif category != _music_category:
		set_music(category, false)


func set_music(category: String, force: bool = false) -> void:
	if category == _music_category and not force:
		return
	if not MUSIC_FILES.has(category):
		category = "day"
	var stream := _load_stream(AUDIO_DIR + String(MUSIC_FILES[category]), true)
	if stream == null:
		return
	_music_category = category
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	var old := _music_current
	var next := _music_b if old == _music_a else _music_a
	next.stream = stream
	next.volume_db = -46.0
	next.play()
	_music_current = next
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(next, "volume_db", -8.5, 1.6).set_trans(Tween.TRANS_SINE)
	_music_tween.tween_property(old, "volume_db", -80.0, 2.2).set_trans(Tween.TRANS_SINE)
	_music_tween.chain().tween_callback(func(): old.stop())


func set_ride_audio(speed_ratio: float, grounded: bool, wingsuit: bool) -> void:
	var speed := clampf(speed_ratio, 0.0, 1.6)
	var sand_target := -5.5 + clampf(speed * 5.0, 0.0, 4.0) if grounded else -40.0
	var wind_target := -21.0 + speed * 10.5
	var wing_target := -8.0 if wingsuit else -55.0
	if wingsuit:
		wind_target = -13.0 + speed * 6.0
	_smooth_bed(_sand_player, sand_target)
	_smooth_bed(_wind_player, wind_target)
	_smooth_bed(_wing_player, wing_target)


func _smooth_bed(player: AudioStreamPlayer, target_db: float) -> void:
	if player == null:
		return
	player.volume_db = lerpf(player.volume_db, target_db, 0.08)


func play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	if _sfx_players.is_empty():
		return
	var key := String(SFX_ALIASES.get(sfx_name, sfx_name))
	if not _sfx_streams.has(key):
		push_warning("Unknown HAVEN sound effect: %s" % sfx_name)
		return
	var player := _sfx_players[_next_voice]
	_next_voice = (_next_voice + 1) % _sfx_players.size()
	player.stream = _sfx_streams[key]
	player.pitch_scale = pitch * randf_range(0.97, 1.035)
	player.volume_db = -2.0
	player.play()


func set_volume(bus_name: String, volume: float) -> void:
	if bus_name != "Master" and bus_name != "Music" and bus_name != "SFX":
		push_error("Unknown HAVEN audio bus: %s" % bus_name)
		return
	SaveData.set_setting("%s_volume" % bus_name.to_lower(), volume)
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_linear(bus_index, clampf(volume, 0.0, 1.0))


func apply_saved_volumes() -> void:
	for bus_name in ["Master", "Music", "SFX"]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index >= 0:
			AudioServer.set_bus_volume_linear(bus_index, SaveData.get_setting("%s_volume" % bus_name.to_lower()))
	var ambience_index := AudioServer.get_bus_index("Ambience")
	if ambience_index >= 0:
		AudioServer.set_bus_volume_linear(ambience_index, clampf(SaveData.get_setting("sfx_volume") * 0.65, 0.0, 1.0))


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	var bus_index := AudioServer.bus_count
	AudioServer.add_bus(bus_index)
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")
