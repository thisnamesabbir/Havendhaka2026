class_name HavenUI
extends RefCounted

## Shared interface language for HAVEN DHAKA 2026.
## Warm gold, bone-white serif display type and quiet, thin rules.

const GOLD := Color(0.956, 0.762, 0.455)
const GOLD_LIGHT := Color(1.0, 0.878, 0.647)
const CREAM := Color(0.976, 0.945, 0.878)
const MIST := Color(0.741, 0.788, 0.827)
const INK := Color(0.043, 0.055, 0.086)
const DEEP := Color(0.020, 0.028, 0.050)
const CYAN := Color(0.478, 0.902, 0.953)
const CORAL := Color(1.0, 0.478, 0.373)
const GREEN := Color(0.663, 0.898, 0.667)

const DISPLAY_FONT_PATH := "res://assets/fonts/CormorantSC-SemiBold.ttf"
const SERIF_FONT_PATH := "res://assets/fonts/CormorantGaramond.ttf"
const UI_FONT_PATH := "res://assets/fonts/InterTight.ttf"
const MONO_FONT_PATH := "res://assets/fonts/IBMPlexMono-Regular.ttf"

static var _display_font: Font
static var _serif_font: Font
static var _ui_font: Font
static var _mono_font: Font
static var _tracking_cache: Dictionary = {}

static func display_font() -> Font:
	if _display_font == null:
		_display_font = load(DISPLAY_FONT_PATH)
	return _display_font

static func serif_font() -> Font:
	if _serif_font == null:
		_serif_font = load(SERIF_FONT_PATH)
	return _serif_font

static func ui_font() -> Font:
	if _ui_font == null:
		_ui_font = load(UI_FONT_PATH)
	return _ui_font

static func mono_font() -> Font:
	if _mono_font == null:
		_mono_font = load(MONO_FONT_PATH)
	return _mono_font

static func tracked(base: Font, spacing: int) -> FontVariation:
	var key := "%s:%d" % [base.resource_path, spacing]
	if _tracking_cache.has(key):
		return _tracking_cache[key]
	var variation := FontVariation.new()
	variation.base_font = base
	variation.spacing_glyph = spacing
	_tracking_cache[key] = variation
	return variation

static func label(
	text: String,
	font_size: int,
	color: Color = CREAM,
	font_kind: String = "ui",
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER,
	tracking: int = 0,
	shadow: bool = true
) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = align
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	var base := ui_font()
	match font_kind:
		"display":
			base = display_font()
		"serif":
			base = serif_font()
		"mono":
			base = mono_font()
	if tracking != 0:
		result.add_theme_font_override("font", tracked(base, tracking))
	else:
		result.add_theme_font_override("font", base)
	if shadow:
		result.add_theme_color_override("font_shadow_color", Color(0.01, 0.02, 0.04, 0.62))
		result.add_theme_constant_override("shadow_offset_x", 0)
		result.add_theme_constant_override("shadow_offset_y", 2)
	return result

static func title(text: String, font_size: int, color: Color = CREAM, tracking: int = 4) -> Label:
	return label(text, font_size, color, "display", HORIZONTAL_ALIGNMENT_LEFT, tracking)

static func subhead(text: String, color: Color = GOLD, tracking: int = 3) -> Label:
	return label(text, 12, color, "ui", HORIZONTAL_ALIGNMENT_LEFT, tracking, false)

static func body(text: String, font_size: int = 15, color: Color = MIST, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result := label(text, font_size, color, "ui", align, 0, false)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result

static func button(
	text: String,
	primary: bool = false,
	button_size: Vector2 = Vector2(330.0, 52.0),
	focusable: bool = true,
	tracking: int = 2
) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = button_size
	result.alignment = HORIZONTAL_ALIGNMENT_LEFT
	result.focus_mode = Control.FOCUS_ALL if focusable else Control.FOCUS_NONE
	result.add_theme_font_override("font", tracked(ui_font(), tracking))
	result.add_theme_font_size_override("font_size", 12 if primary else 11)
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	var focus: StyleBoxFlat
	if primary:
		normal = _box(Color(0.941, 0.752, 0.447), Color(1.0, 0.89, 0.66), 1, 1, 3, 22.0)
		hover = _box(Color(1.0, 0.84, 0.55), Color(1.0, 0.95, 0.78), 1, 1, 3, 22.0)
		pressed = _box(Color(0.80, 0.61, 0.32), Color(0.95, 0.79, 0.49), 1, 1, 3, 22.0)
		focus = _box(Color(1.0, 0.84, 0.55), CREAM, 1, 2, 3, 22.0)
		result.add_theme_color_override("font_color", INK)
		result.add_theme_color_override("font_hover_color", INK)
		result.add_theme_color_override("font_pressed_color", INK)
		result.add_theme_color_override("font_focus_color", INK)
	else:
		normal = _box(Color(0.028, 0.040, 0.066, 0.64), Color(0.956, 0.762, 0.455, 0.28), 1, 1, 3, 22.0)
		hover = _box(Color(0.072, 0.078, 0.104, 0.86), Color(0.956, 0.762, 0.455, 0.85), 1, 1, 3, 22.0)
		pressed = _box(Color(0.941, 0.752, 0.447, 0.22), GOLD, 1, 1, 3, 22.0)
		focus = _box(Color(0.072, 0.078, 0.104, 0.86), GOLD_LIGHT, 1, 2, 3, 22.0)
		result.add_theme_color_override("font_color", CREAM)
		result.add_theme_color_override("font_hover_color", CREAM)
		result.add_theme_color_override("font_pressed_color", CREAM)
		result.add_theme_color_override("font_focus_color", CREAM)
	result.add_theme_stylebox_override("normal", normal)
	result.add_theme_stylebox_override("hover", hover)
	result.add_theme_stylebox_override("pressed", pressed)
	result.add_theme_stylebox_override("focus", focus)
	result.add_theme_stylebox_override("disabled", _box(Color(0.04, 0.05, 0.08, 0.42), Color(0.5, 0.5, 0.5, 0.14), 1, 1, 3, 22.0))
	result.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7, 0.36))
	var arrow := label("→", 17, INK if primary else GOLD, "ui", HORIZONTAL_ALIGNMENT_RIGHT, 0, false)
	arrow.name = "Arrow"
	arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	arrow.position = Vector2(-32.0, -13.0)
	arrow.size = Vector2(20.0, 26.0)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(arrow)
	result.pressed.connect(func() -> void:
		if is_instance_valid(AudioManager):
			AudioManager.play_sfx("ui")
	)
	return result

static func icon_button(glyph: String, size: float = 44.0) -> Button:
	var result := Button.new()
	result.text = glyph
	result.custom_minimum_size = Vector2(size, size)
	result.focus_mode = Control.FOCUS_NONE
	result.add_theme_font_size_override("font_size", 16)
	result.add_theme_color_override("font_color", CREAM)
	result.add_theme_color_override("font_hover_color", INK)
	result.add_theme_color_override("font_pressed_color", INK)
	result.add_theme_stylebox_override("normal", _box(Color(0.028, 0.040, 0.066, 0.62), Color(0.956, 0.762, 0.455, 0.34), 1, 1, 22, 6.0))
	result.add_theme_stylebox_override("hover", _box(GOLD, GOLD_LIGHT, 1, 1, 22, 6.0))
	result.add_theme_stylebox_override("pressed", _box(Color(0.80, 0.61, 0.32), GOLD, 1, 1, 22, 6.0))
	result.add_theme_stylebox_override("focus", _box(Color(0.028, 0.040, 0.066, 0.62), GOLD_LIGHT, 1, 2, 22, 6.0))
	result.pressed.connect(func() -> void:
		if is_instance_valid(AudioManager):
			AudioManager.play_sfx("ui")
	)
	return result

static func panel_style(
	fill: Color = Color(0.026, 0.036, 0.060, 0.92),
	border: Color = Color(0.956, 0.762, 0.455, 0.34),
	radius: int = 4,
	border_width: int = 1,
	margin: float = 28.0
) -> StyleBoxFlat:
	return _box(fill, border, border_width, border_width, radius, margin)

static func _box(
	fill: Color,
	border: Color,
	border_width: int,
	_border_bottom: int,
	radius: int,
	margin: float
) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin
	box.content_margin_right = margin
	box.content_margin_top = margin * 0.62
	box.content_margin_bottom = margin * 0.62
	return box

static func rule(width: float, color: Color = Color(0.956, 0.762, 0.455, 0.32), height: float = 1.0) -> ColorRect:
	var line := ColorRect.new()
	line.color = color
	line.custom_minimum_size = Vector2(width, height)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

static func spacer(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap

static func panel_container(style: StyleBoxFlat) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	return panel

static func number(value: int) -> String:
	var text := str(absi(value))
	var grouped := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		grouped = text[i] + grouped
		count += 1
		if count % 3 == 0 and i > 0:
			grouped = "," + grouped
	return ("-" if value < 0 else "") + grouped

static func zero_pad(value: int, digits: int) -> String:
	return str(maxi(0, value)).pad_zeros(digits)

static func distance_text(metres: int) -> String:
	return zero_pad(metres, 4)

static func rarity_color(ratio: float) -> Color:
	return MIST.lerp(GOLD, clampf(ratio, 0.0, 1.0))
