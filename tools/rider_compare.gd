extends SceneTree

const RIDER_VISUAL := preload("res://scripts/rider_visual.gd")

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	call_deferred("_run")

func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.16, 0.22)
	bg.size = Vector2(1280, 720)
	stage.add_child(bg)
	var title_a := Label.new()
	title_a.text = "RiderArt"
	title_a.position = Vector2(170, 90)
	title_a.add_theme_font_size_override("font_size", 28)
	stage.add_child(title_a)
	var title_b := Label.new()
	title_b.text = "RiderVisual"
	title_b.position = Vector2(800, 90)
	title_b.add_theme_font_size_override("font_size", 28)
	stage.add_child(title_b)
	var art := RiderArt.new()
	art.position = Vector2(280, 460)
	art.scale = Vector2(2.2, 2.2)
	art.set_animation_state("ride")
	art.speed_ratio = 0.55
	stage.add_child(art)
	var vis := RIDER_VISUAL.new()
	vis.position = Vector2(900, 460)
	vis.scale = Vector2(2.2, 2.2)
	vis.call("set_rider", "wayfarer")
	vis.call("set_pose", "ride", 0.55, 0.2, 0.0, 0.0, 0.0)
	stage.add_child(vis)
	for i in range(60):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://screenshots/rider_compare.png")
	print("SAVED rider_compare ", image.get_size())
	quit(0)
