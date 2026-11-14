extends RefCounted

## Shared gold slider skin for the menu and the pause suite. Kept in a
## preloaded helper so both screens use the same quiet, tactile control.

const HavenUI = preload("res://scripts/haven_ui.gd")


static func apply(slider: HSlider, accent: Color = HavenUI.GOLD) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.95, 0.90, 0.82, 0.16)
	track.set_corner_radius_all(3)
	track.content_margin_top = 2.0
	track.content_margin_bottom = 2.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(accent, 0.82)
	fill.set_corner_radius_all(3)
	fill.content_margin_top = 2.0
	fill.content_margin_bottom = 2.0
	var fill_hover := StyleBoxFlat.new()
	fill_hover.bg_color = accent
	fill_hover.set_corner_radius_all(3)
	fill_hover.content_margin_top = 2.0
	fill_hover.content_margin_bottom = 2.0
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_hover)
	slider.add_theme_icon_override("grabber", _disc(7, accent))
	slider.add_theme_icon_override("grabber_highlight", _disc(7, HavenUI.GOLD_LIGHT))
	slider.add_theme_icon_override("grabber_disabled", _disc(7, Color(0.55, 0.50, 0.48)))
	slider.add_theme_constant_override("grabber_offset", 0)


static func _disc(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2 + 3
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size - 1, size - 1) * 0.5
	var outer := float(radius) + 1.4
	for y in range(size):
		for x in range(size):
			var distance := Vector2(float(x), float(y)).distance_to(center)
			var coverage := clampf(outer - distance, 0.0, 1.0)
			var edge := clampf(float(radius) - distance + 0.7, 0.0, 1.0)
			var tone := color.lerp(Color(0.10, 0.08, 0.12), (1.0 - edge) * 0.26)
			tone.a = coverage
			image.set_pixel(x, y, tone)
	return ImageTexture.create_from_image(image)
