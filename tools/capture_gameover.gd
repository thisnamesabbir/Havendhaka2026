extends SceneTree

# Dev-only results-card QA harness. Poses the rider in the moonlit desert and
# presents a representative completed run without writing a save file.

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	call_deferred("_run")


func _run() -> void:
	if root.has_node("SaveData"):
		root.get_node("SaveData").call("mark_tutorial_seen")
	change_scene_to_file("res://scenes/game.tscn")
	await process_frame
	await process_frame
	var game := current_scene
	for obstacle in get_nodes_in_group("obstacles"):
		obstacle.queue_free()
	var player := game.get_node("Player") as Node2D
	var world := game.get_node("World")
	var hud := game.get_node("HUD")
	player.global_position = Vector2(43800.0, float(world.call("ground_height", 43800.0)) - 74.0)
	player.set("velocity", Vector2(520.0, 0.0))
	player.set("run_speed", 620.0)
	await process_frame
	var camera := game.get_node("Camera2D")
	if camera != null and camera.has_method("snap_to_target"):
		camera.call("snap_to_target")
	hud.call("close_tutorial")
	var biome_card = hud.get("_biome_card")
	if biome_card is CanvasItem:
		biome_card.visible = false
	for _i in range(20):
		await process_frame
	paused = true
	var overlay = load("res://scenes/game_over.tscn").instantiate()
	game.add_child(overlay)
	overlay.present({
		"score": 28540,
		"distance": 2140,
		"coins": 96,
		"shards": 8,
		"tricks": 16,
		"best_combo": 7,
		"perfects": 5,
		"flight_time": 78.4,
		"reason": "rock",
		"new_best_score": true,
		"new_best_distance": true,
		"best_score": 28540,
		"best_distance": 2140,
		"new_achievements": ["SKY WEAVER", "FLAWLESS", "THE LONG WAY DOWN"],
		"riders": ["THE MIRAGE"],
		"wingsuit_just_unlocked": false,
		"seed": 260214,
		"biome": "MOONLIT DESERT",
	})
	for _i in range(36):
		await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Capture failed: viewport image is empty")
		quit(2)
		return
	var error := image.save_png("res://screenshots/game_over.png")
	print("CAPTURE res://screenshots/game_over.png ", image.get_width(), "x", image.get_height(), " err=", error)
	quit(0)
