extends SceneTree

# Dev-only gameplay QA harness.
# Usage:
#   xvfb-run -a godot --path . --script res://tools/capture_game.gd -- <output> [world_x] [frames] [mode]
#
# mode: ride | wingsuit | pause | tutorial
# The harness clears the immediate obstacles so the screenshot captures the
# intended composition rather than an unlucky rock.

var _world_x := 3000.0
var _output := "res://screenshots/game_qa.png"
var _frames := 40
var _mode := "ride"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_output = args[0]
	if args.size() > 1:
		_world_x = float(args[1])
	if args.size() > 2:
		_frames = int(args[2])
	if args.size() > 3:
		_mode = args[3]
	DisplayServer.window_set_size(Vector2i(1280, 720))
	call_deferred("_run")


func _run() -> void:
	if root.has_node("SaveData"):
		root.get_node("SaveData").call("mark_tutorial_seen")
	change_scene_to_file("res://scenes/game.tscn")
	await process_frame
	await process_frame
	var game := current_scene
	if game == null:
		push_error("Capture failed: game scene missing")
		quit(2)
		return
	if _mode == "sky":
		game.get_node("World").visible = false
		game.get_node("Player").visible = false
		game.get_node("HUD").visible = false
	elif _mode == "world":
		game.get_node("SkyLayer").visible = false
	for obstacle in get_nodes_in_group("obstacles"):
		obstacle.queue_free()
	var player := game.get_node("Player") as CharacterBody2D
	var world := game.get_node("World")
	var hud := game.get_node("HUD")
	# Keep the rider from clipping the QA camera into a rock while still
	# letting the streamed terrain collide normally.
	player.collision_layer = 0
	var safe_x := _world_x
	for step in range(0, 2600, 50):
		var candidate := _world_x + float(step)
		var clear := true
		for offset in range(-420, 1500, 60):
			if bool(world.call("is_gap_at", candidate + float(offset))):
				clear = false
				break
		if clear:
			safe_x = candidate
			break
	_world_x = safe_x
	player.global_position.x = _world_x
	var ground := float(world.call("ground_height", _world_x))
	player.global_position.y = ground - 8.0
	player.set("velocity", Vector2(470.0, 0.0))
	player.set("run_speed", 560.0)
	if _mode == "pause" or _mode == "tutorial":
		player.set("velocity", Vector2(420.0, 0.0))
	if _mode == "wingsuit":
		player.set("wingsuit_unlocked", true)
		player.global_position.y = ground - 330.0
		player.set("velocity", Vector2(700.0, 20.0))
		await physics_frame
		await physics_frame
		player.call("toggle_wingsuit")
		print("WINGSUIT_STATE floor=", player.call("is_on_floor"), " deployed=", player.call("is_wingsuit_deployed"), " alive=", player.get("alive"), " y=", player.global_position.y, " ground=", world.call("ground_height", player.global_position.x))
	await process_frame
	var camera := game.get_node("Camera2D")
	if camera != null and camera.has_method("snap_to_target"):
		camera.call("snap_to_target")
	await process_frame
	if hud != null:
		hud.call("close_tutorial")
		var biome_card = hud.get("_biome_card")
		if biome_card is CanvasItem:
			biome_card.visible = false
	if _mode == "ride" or _mode == "wingsuit":
		# Hold the framed moment. Letting the simulation keep running would
		# eventually find a chasm or a rock and replace the shot with the
		# game-over card.
		player.set_physics_process(false)
		var slope := float(world.call("slope_at", player.global_position.x))
		var art := player.get_node("Art") as Node2D
		if _mode == "wingsuit":
			art.rotation = 0.22
			art.set("speed_ratio", 0.9)
			art.call("set_animation_state", "wingsuit")
		else:
			art.rotation = slope
			art.set("speed_ratio", 0.72)
			art.call("set_animation_state", "accelerate")
			player.call("_spawn_dust", 8, 0.9)
		player.queue_redraw()
	if _mode == "pause" or _mode == "tutorial":
		var pause_button := hud.find_child("PauseButton", true, false) as Button
		if pause_button != null:
			pause_button.emit_signal("pressed")
		await process_frame
		if _mode == "tutorial":
			var guide := hud.find_child("PauseTutorialButton", true, false) as Button
			if guide != null:
				guide.emit_signal("pressed")
	for _i in range(_frames):
		await process_frame
	if hud != null:
		var toasts = hud.get("_toast_stack")
		if toasts is Node:
			for child in toasts.get_children():
				child.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Capture failed: viewport image is empty")
		quit(2)
		return
	var error := image.save_png(_output)
	print("CAPTURE ", _output, " ", image.get_width(), "x", image.get_height(), " err=", error)
	quit(0)
