class_name HavenUIKit
extends RefCounted

## Shared typography and quiet, tactile UI styling for HAVEN DHAKA 2026.

const DISPLAY_FONT = preload("res://assets/fonts/Marcellus-Regular.ttf")
const BODY_FONT = preload("res://assets/fonts/InterTight.ttf")
const ACCENT_FONT = preload("res://assets/fonts/CormorantGaramond.ttf")
const MONO_FONT = preload("res://assets/fonts/IBMPlexMono-Regular.ttf")
const BENGALI_FONT = preload("res://assets/fonts/NotoSansBengali-Regular.ttf")

const CREAM := Color("f8eeda")
const GOLD := Color("f0c37a")
const GOLD_PALE := Color("ffe6b4")
const SAND := Color("cdb79f")
const MUTED := Color("9d8e87")
const INK := Color("100c16")
const CYAN := Color("a9e3e6")
const ROSE := Color("f0a08d")
const DEEP := Color("171223")


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = BODY_FONT
	theme.default_font_size = 15
	return theme


static func label(text: String, font_size: int, color: Color = CREAM,
		font: Font = BODY_FONT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = align
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0.03, 0.02, 0.05, 0.55))
	node.add_theme_constant_override("shadow_offset_x", 0)
	node.add_theme_constant_override("shadow_offset_y", 1)
	node.add_theme_constant_override("outline_size", 0)
	return node


static func display(text: String, font_size: int, color: Color = CREAM,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return label(text, font_size, color, DISPLAY_FONT, align)


static func mono(text: String, font_size: int, color: Color = SAND,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return label(text, font_size, color, MONO_FONT, align)


static func button(text: String, minimum := Vector2(240.0, 50.0), accent: Color = GOLD) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.add_theme_font_override("font", BODY_FONT)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", GOLD_PALE)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.96, 0.88))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.45, 0.43, 0.7))
	button.add_theme_stylebox_override("normal", panel_style(Color(0.06, 0.05, 0.09, 0.42), Color(accent, 0.40), 9, 1))
	button.add_theme_stylebox_override("hover", panel_style(Color(accent, 0.15), Color(accent, 0.8), 9, 1))
	button.add_theme_stylebox_override("pressed", panel_style(Color(accent, 0.28), Color(accent, 1.0), 9, 1))
	button.add_theme_stylebox_override("disabled", panel_style(Color(0.06, 0.05, 0.09, 0.22), Color(0.5, 0.45, 0.42, 0.18), 9, 1))
	var focus := panel_style(Color(accent, 0.08), Color(accent, 0.9), 9, 2)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_constant_override("outline_size", 0)
	return button


static func small_button(text: String, minimum := Vector2(180.0, 42.0), accent: Color = GOLD) -> Button:
	var node := button(text, minimum, accent)
	node.add_theme_font_size_override("font_size", 13)
	return node


static func panel_style(background: Color, border: Color, radius := 14,
		border_width := 1, margin := 18.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin * 0.6
	style.content_margin_bottom = margin * 0.6
	style.anti_aliasing = true
	return style


static func panel(background: Color = Color(0.055, 0.045, 0.075, 0.80),
		border: Color = Color(GOLD, 0.28), radius := 16, border_width := 1) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", panel_style(background, border, radius, border_width, 22.0))
	return node


static func separator(color: Color = Color(GOLD, 0.22), height := 1.0) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = Vector2(0.0, height)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func spacer(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0.0, height)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func add_modal_scrim(parent: Control, alpha := 0.64) -> ColorRect:
	var scrim := ColorRect.new()
	scrim.color = Color(0.018, 0.016, 0.028, alpha)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(scrim)
	return scrim


static func anchor_full(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.grow_horizontal = Control.GROW_DIRECTION_BOTH
	node.grow_vertical = Control.GROW_DIRECTION_BOTH
