extends SceneTree

# Dev-only visual QA harness.
# Usage:
#   xvfb-run -a godot --path . --script res://tools/capture.gd -- <scene> <output> [frames] [distance] [mode]
#
# mode: "ride" (default) skips the first-run tutorial and drops the rider onto
# the terrain at [distance]. "raw" leaves the scene exactly as first loaded.
# Optional fifth argument "keep" prevents the run from being saved.

var _scene_path := "res://scenes/main_menu.tscn"
var _output_path := "res://screenshots/capture.png"
var _frames := 90
var _distance := -1.0
var _mode := "ride"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_scene_path = args[0]
	if args.size() > 1:
		_output_path = args[1]
	if args.size() > 2:
		_frames = int(args[2])
	if args.size() > 3:
		_distance = float(args[3])
	if args.size() > 4:
		_mode = args[4]
	DisplayServer.window_set_size(Vector2i(1280, 720))
	call_deferred("_run")


func _run() -> void:
	if _mode != "raw" and root.has_node("SaveData"):
		var save: Node = root.get_node("SaveData")
		save.call("mark_tutorial_seen")
	change_scene_to_file(_scene_path)
	await process_frame
	await process_frame
	var game := current_scene
	if _mode != "raw" and game != null:
		await _position_rider(game)
	for i in range(_frames):
		await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Capture failed: viewport image is empty")
		quit(2)
		return
	var error := image.save_png(_output_path)
	print("CAPTURE ", _output_path, " ", image.get_width(), "x", image.get_height(), " err=", error)
	quit(0)


func _position_rider(game: Node) -> void:
	var player := game.get_node_or_null("Player") as Node2D
	if player == null:
		return
	if _distance >= 0.0:
		player.global_position.x = _distance
	var world := game.get_node_or_null("World")
	if world != null:
		var surface := INF
		for method in ["ground_height", "ground_height_at", "baseline_height_at"]:
			if world.has_method(method):
				surface = float(world.call(method, player.global_position.x))
				break
		if surface != INF:
			player.global_position.y = surface - 76.0
	if player.has_method("set_velocity"):
		player.call("set_velocity", Vector2(380.0, 0.0))
	player.set("velocity", Vector2(380.0, 0.0))
	var camera := game.get_node_or_null("Camera2D")
	if camera != null and camera.has_method("snap_to_target"):
		camera.call("snap_to_target")
	var hud := game.get_node_or_null("HUD")
	if hud != null and hud.has_method("close_tutorial"):
		hud.call("close_tutorial")
	await process_frame
