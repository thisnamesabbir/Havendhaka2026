extends SceneTree

# Dev-only menu/modal QA harness.
# Usage:
#   xvfb-run -a godot --path . --script res://tools/capture_ui.gd -- <output> [button_name] [frames] [nested_button]
#
# Opens the main menu, optionally presses a named button (for example
# RidersButton), waits, and writes a 1280x720 PNG. A nested button can be
# pressed after the first modal has settled, which is useful for opening
# achievements from the journey panel.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var output := "res://screenshots/menu_ui.png"
	var button_name := ""
	var frames := 30
	var nested := ""
	if args.size() > 0:
		output = args[0]
	if args.size() > 1:
		button_name = args[1]
	if args.size() > 2:
		frames = int(args[2])
	if args.size() > 3:
		nested = args[3]
	DisplayServer.window_set_size(Vector2i(1280, 720))
	call_deferred("_run", output, button_name, frames, nested)


func _run(output: String, button_name: String, frames: int, nested: String) -> void:
	if root.has_node("SaveData"):
		root.get_node("SaveData").call("mark_tutorial_seen")
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	if not button_name.is_empty():
		var button := current_scene.find_child(button_name, true, false) as Button
		if button == null:
			push_error("Capture failed: button not found: %s" % button_name)
			quit(2)
			return
		button.emit_signal("pressed")
		await process_frame
		if not nested.is_empty():
			for _i in range(8):
				await process_frame
			var nested_button := current_scene.find_child(nested, true, false) as Button
			if nested_button == null:
				push_error("Capture failed: nested button not found: %s" % nested)
				quit(2)
				return
			nested_button.emit_signal("pressed")
	for _i in range(frames):
		await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Capture failed: viewport image is empty")
		quit(2)
		return
	var error := image.save_png(output)
	print("CAPTURE ", output, " ", image.get_width(), "x", image.get_height(), " err=", error)
	quit(0)
