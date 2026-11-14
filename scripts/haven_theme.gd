class_name HavenTheme
extends RefCounted

## Shared art direction for HAVEN DHAKA 2026.
## Eight named environments cycle seamlessly through a cinematic day.

const BIOME_LENGTH := 7000.0
const TRANSITION_FRACTION := 0.14

const BIOME_NAMES := [
	"GOLDEN DESERT",
	"ANCIENT RUINS",
	"MOUNTAIN VALLEYS",
	"DESERT CITY",
	"SUNSET CANYON",
	"TWILIGHT DESERT",
	"MOONLIT DESERT",
	"STARRY NIGHT MOUNTAINS",
]

const BIOME_IDS := [
	"golden_desert",
	"ancient_ruins",
	"mountain_valleys",
	"desert_city",
	"sunset_canyon",
	"twilight_desert",
	"moonlit_desert",
	"star_night_mountains",
]

const BIOME_TAGLINES := [
	"THE FIRST LIGHT",
	"WHAT THE SAND REMEMBERS",
	"WHERE THE RIDGES SING",
	"LANTERNS OVER DHAKA",
	"CANYON OF THE LAST SUN",
	"THE VIOLET HOUR",
	"SILVER UNDER MOONLIGHT",
	"BEYOND THE STARS",
]

const LANDMARK_KINDS := [
	"palms",
	"ruins",
	"peaks",
	"city",
	"mesas",
	"deadwoods",
	"moon_ruins",
	"star_peaks",
]

const COLOR_KEYS := [
	"sky_top", "sky_upper", "sky_mid", "sky_low",
	"sun", "sun_glow", "moon", "moon_glow",
	"haze", "fog_color",
	"far", "far_light", "mid", "mid_light", "near", "near_light",
	"dune", "dune_shadow",
	"sand_hi", "sand", "sand_mid", "sand_low", "sand_deep",
	"rim", "accent", "cloud",
]

const NUMBER_KEYS := ["star_amount", "cloud_amount", "fog_amount", "sun_alpha", "moon_alpha"]

const PALETTES := [
	{
		"sky_top": Color(0.33, 0.56, 0.73),
		"sky_upper": Color(0.55, 0.72, 0.80),
		"sky_mid": Color(0.92, 0.82, 0.66),
		"sky_low": Color(1.00, 0.88, 0.67),
		"sun": Color(1.00, 0.95, 0.79),
		"sun_glow": Color(1.00, 0.72, 0.37),
		"moon": Color(0.85, 0.91, 1.00),
		"moon_glow": Color(0.49, 0.66, 0.88),
		"haze": Color(0.99, 0.85, 0.65, 0.52),
		"fog_color": Color(0.96, 0.82, 0.65, 0.20),
		"far": Color(0.49, 0.59, 0.63),
		"far_light": Color(0.68, 0.76, 0.73),
		"mid": Color(0.59, 0.52, 0.50),
		"mid_light": Color(0.77, 0.64, 0.54),
		"near": Color(0.70, 0.53, 0.39),
		"near_light": Color(0.90, 0.69, 0.45),
		"dune": Color(0.84, 0.63, 0.40),
		"dune_shadow": Color(0.56, 0.39, 0.30),
		"sand_hi": Color(0.97, 0.79, 0.49),
		"sand": Color(0.86, 0.63, 0.36),
		"sand_mid": Color(0.66, 0.44, 0.28),
		"sand_low": Color(0.39, 0.27, 0.24),
		"sand_deep": Color(0.18, 0.14, 0.18),
		"rim": Color(1.00, 0.86, 0.58),
		"accent": Color(1.00, 0.80, 0.43),
		"cloud": Color(1.00, 0.91, 0.79, 0.30),
		"star_amount": 0.0,
		"cloud_amount": 0.9,
		"fog_amount": 0.42,
		"sun_alpha": 1.0,
		"moon_alpha": 0.0,
	},
	{
		"sky_top": Color(0.28, 0.49, 0.65),
		"sky_upper": Color(0.51, 0.67, 0.72),
		"sky_mid": Color(0.86, 0.77, 0.63),
		"sky_low": Color(0.99, 0.83, 0.63),
		"sun": Color(1.00, 0.93, 0.75),
		"sun_glow": Color(1.00, 0.70, 0.36),
		"moon": Color(0.86, 0.92, 1.00),
		"moon_glow": Color(0.53, 0.67, 0.87),
		"haze": Color(0.98, 0.83, 0.62, 0.55),
		"fog_color": Color(0.94, 0.78, 0.60, 0.22),
		"far": Color(0.47, 0.47, 0.49),
		"far_light": Color(0.64, 0.63, 0.59),
		"mid": Color(0.58, 0.48, 0.43),
		"mid_light": Color(0.76, 0.62, 0.50),
		"near": Color(0.69, 0.52, 0.37),
		"near_light": Color(0.88, 0.67, 0.44),
		"dune": Color(0.82, 0.61, 0.39),
		"dune_shadow": Color(0.53, 0.38, 0.29),
		"sand_hi": Color(0.96, 0.78, 0.49),
		"sand": Color(0.85, 0.63, 0.38),
		"sand_mid": Color(0.65, 0.44, 0.30),
		"sand_low": Color(0.38, 0.27, 0.24),
		"sand_deep": Color(0.17, 0.14, 0.17),
		"rim": Color(1.00, 0.85, 0.56),
		"accent": Color(0.98, 0.77, 0.42),
		"cloud": Color(0.99, 0.90, 0.78, 0.22),
		"star_amount": 0.02,
		"cloud_amount": 0.68,
		"fog_amount": 0.38,
		"sun_alpha": 1.0,
		"moon_alpha": 0.0,
	},
	{
		"sky_top": Color(0.20, 0.35, 0.56),
		"sky_upper": Color(0.38, 0.55, 0.67),
		"sky_mid": Color(0.78, 0.62, 0.55),
		"sky_low": Color(0.98, 0.73, 0.48),
		"sun": Color(1.00, 0.88, 0.64),
		"sun_glow": Color(1.00, 0.60, 0.32),
		"moon": Color(0.88, 0.92, 1.00),
		"moon_glow": Color(0.55, 0.66, 0.87),
		"haze": Color(0.98, 0.77, 0.57, 0.52),
		"fog_color": Color(0.76, 0.61, 0.59, 0.24),
		"far": Color(0.35, 0.42, 0.51),
		"far_light": Color(0.54, 0.59, 0.65),
		"mid": Color(0.47, 0.39, 0.44),
		"mid_light": Color(0.68, 0.51, 0.48),
		"near": Color(0.58, 0.42, 0.36),
		"near_light": Color(0.81, 0.58, 0.41),
		"dune": Color(0.76, 0.55, 0.35),
		"dune_shadow": Color(0.45, 0.33, 0.28),
		"sand_hi": Color(0.93, 0.74, 0.47),
		"sand": Color(0.79, 0.57, 0.34),
		"sand_mid": Color(0.57, 0.39, 0.28),
		"sand_low": Color(0.29, 0.24, 0.25),
		"sand_deep": Color(0.12, 0.12, 0.18),
		"rim": Color(1.00, 0.79, 0.52),
		"accent": Color(0.97, 0.67, 0.38),
		"cloud": Color(0.94, 0.82, 0.76, 0.25),
		"star_amount": 0.08,
		"cloud_amount": 0.55,
		"fog_amount": 0.34,
		"sun_alpha": 0.94,
		"moon_alpha": 0.05,
	},
	{
		"sky_top": Color(0.13, 0.20, 0.36),
		"sky_upper": Color(0.32, 0.31, 0.42),
		"sky_mid": Color(0.67, 0.40, 0.40),
		"sky_low": Color(0.96, 0.59, 0.37),
		"sun": Color(1.00, 0.72, 0.44),
		"sun_glow": Color(1.00, 0.49, 0.22),
		"moon": Color(0.85, 0.90, 1.00),
		"moon_glow": Color(0.49, 0.62, 0.85),
		"haze": Color(0.97, 0.63, 0.42, 0.48),
		"fog_color": Color(0.64, 0.45, 0.46, 0.22),
		"far": Color(0.20, 0.19, 0.26),
		"far_light": Color(0.35, 0.30, 0.35),
		"mid": Color(0.28, 0.23, 0.28),
		"mid_light": Color(0.46, 0.33, 0.33),
		"near": Color(0.36, 0.26, 0.26),
		"near_light": Color(0.57, 0.38, 0.30),
		"dune": Color(0.60, 0.41, 0.30),
		"dune_shadow": Color(0.34, 0.25, 0.25),
		"sand_hi": Color(0.83, 0.60, 0.38),
		"sand": Color(0.66, 0.45, 0.30),
		"sand_mid": Color(0.45, 0.32, 0.26),
		"sand_low": Color(0.23, 0.20, 0.23),
		"sand_deep": Color(0.09, 0.10, 0.16),
		"rim": Color(1.00, 0.66, 0.40),
		"accent": Color(1.00, 0.65, 0.34),
		"cloud": Color(0.85, 0.66, 0.64, 0.26),
		"star_amount": 0.25,
		"cloud_amount": 0.40,
		"fog_amount": 0.30,
		"sun_alpha": 0.82,
		"moon_alpha": 0.12,
	},
	{
		"sky_top": Color(0.10, 0.13, 0.28),
		"sky_upper": Color(0.30, 0.22, 0.38),
		"sky_mid": Color(0.63, 0.32, 0.40),
		"sky_low": Color(0.93, 0.48, 0.33),
		"sun": Color(1.00, 0.63, 0.40),
		"sun_glow": Color(1.00, 0.39, 0.17),
		"moon": Color(0.88, 0.92, 1.00),
		"moon_glow": Color(0.50, 0.60, 0.83),
		"haze": Color(0.95, 0.53, 0.35, 0.42),
		"fog_color": Color(0.54, 0.34, 0.38, 0.22),
		"far": Color(0.21, 0.16, 0.24),
		"far_light": Color(0.36, 0.26, 0.31),
		"mid": Color(0.32, 0.21, 0.25),
		"mid_light": Color(0.48, 0.30, 0.30),
		"near": Color(0.41, 0.26, 0.25),
		"near_light": Color(0.59, 0.37, 0.29),
		"dune": Color(0.55, 0.36, 0.29),
		"dune_shadow": Color(0.30, 0.22, 0.24),
		"sand_hi": Color(0.77, 0.52, 0.34),
		"sand": Color(0.58, 0.38, 0.28),
		"sand_mid": Color(0.39, 0.28, 0.25),
		"sand_low": Color(0.20, 0.18, 0.22),
		"sand_deep": Color(0.08, 0.09, 0.15),
		"rim": Color(1.00, 0.59, 0.34),
		"accent": Color(1.00, 0.58, 0.30),
		"cloud": Color(0.75, 0.55, 0.60, 0.25),
		"star_amount": 0.42,
		"cloud_amount": 0.30,
		"fog_amount": 0.27,
		"sun_alpha": 0.68,
		"moon_alpha": 0.22,
	},
	{
		"sky_top": Color(0.045, 0.065, 0.16),
		"sky_upper": Color(0.12, 0.14, 0.29),
		"sky_mid": Color(0.35, 0.24, 0.38),
		"sky_low": Color(0.70, 0.40, 0.39),
		"sun": Color(0.94, 0.49, 0.33),
		"sun_glow": Color(0.85, 0.34, 0.26),
		"moon": Color(0.87, 0.92, 1.00),
		"moon_glow": Color(0.51, 0.63, 0.86),
		"haze": Color(0.72, 0.44, 0.45, 0.34),
		"fog_color": Color(0.38, 0.27, 0.37, 0.22),
		"far": Color(0.15, 0.14, 0.24),
		"far_light": Color(0.28, 0.24, 0.34),
		"mid": Color(0.23, 0.18, 0.28),
		"mid_light": Color(0.38, 0.28, 0.35),
		"near": Color(0.30, 0.23, 0.31),
		"near_light": Color(0.48, 0.34, 0.37),
		"dune": Color(0.45, 0.33, 0.38),
		"dune_shadow": Color(0.25, 0.20, 0.27),
		"sand_hi": Color(0.66, 0.48, 0.46),
		"sand": Color(0.47, 0.35, 0.38),
		"sand_mid": Color(0.31, 0.25, 0.31),
		"sand_low": Color(0.16, 0.16, 0.22),
		"sand_deep": Color(0.06, 0.07, 0.13),
		"rim": Color(0.95, 0.63, 0.50),
		"accent": Color(0.95, 0.66, 0.52),
		"cloud": Color(0.55, 0.45, 0.58, 0.22),
		"star_amount": 0.72,
		"cloud_amount": 0.22,
		"fog_amount": 0.23,
		"sun_alpha": 0.28,
		"moon_alpha": 0.38,
	},
	{
		"sky_top": Color(0.010, 0.025, 0.070),
		"sky_upper": Color(0.030, 0.070, 0.155),
		"sky_mid": Color(0.085, 0.150, 0.265),
		"sky_low": Color(0.225, 0.320, 0.440),
		"sun": Color(0.85, 0.91, 1.00),
		"sun_glow": Color(0.40, 0.59, 0.80),
		"moon": Color(0.93, 0.96, 1.00),
		"moon_glow": Color(0.51, 0.68, 0.88),
		"haze": Color(0.46, 0.61, 0.76, 0.24),
		"fog_color": Color(0.20, 0.31, 0.44, 0.20),
		"far": Color(0.09, 0.15, 0.24),
		"far_light": Color(0.18, 0.26, 0.36),
		"mid": Color(0.13, 0.20, 0.30),
		"mid_light": Color(0.23, 0.31, 0.41),
		"near": Color(0.18, 0.26, 0.35),
		"near_light": Color(0.30, 0.38, 0.46),
		"dune": Color(0.24, 0.31, 0.40),
		"dune_shadow": Color(0.13, 0.19, 0.28),
		"sand_hi": Color(0.41, 0.49, 0.56),
		"sand": Color(0.27, 0.34, 0.43),
		"sand_mid": Color(0.17, 0.23, 0.32),
		"sand_low": Color(0.09, 0.13, 0.21),
		"sand_deep": Color(0.035, 0.055, 0.10),
		"rim": Color(0.64, 0.82, 0.96),
		"accent": Color(0.62, 0.83, 0.98),
		"cloud": Color(0.42, 0.55, 0.71, 0.16),
		"star_amount": 1.0,
		"cloud_amount": 0.15,
		"fog_amount": 0.20,
		"sun_alpha": 0.0,
		"moon_alpha": 1.0,
	},
	{
		"sky_top": Color(0.003, 0.008, 0.024),
		"sky_upper": Color(0.010, 0.024, 0.066),
		"sky_mid": Color(0.030, 0.060, 0.125),
		"sky_low": Color(0.080, 0.135, 0.220),
		"sun": Color(0.88, 0.93, 1.00),
		"sun_glow": Color(0.35, 0.48, 0.69),
		"moon": Color(0.87, 0.92, 1.00),
		"moon_glow": Color(0.43, 0.57, 0.78),
		"haze": Color(0.22, 0.37, 0.52, 0.18),
		"fog_color": Color(0.09, 0.17, 0.27, 0.17),
		"far": Color(0.065, 0.115, 0.18),
		"far_light": Color(0.15, 0.23, 0.31),
		"mid": Color(0.10, 0.17, 0.24),
		"mid_light": Color(0.19, 0.28, 0.36),
		"near": Color(0.15, 0.23, 0.30),
		"near_light": Color(0.26, 0.35, 0.43),
		"dune": Color(0.19, 0.26, 0.34),
		"dune_shadow": Color(0.10, 0.16, 0.23),
		"sand_hi": Color(0.35, 0.44, 0.51),
		"sand": Color(0.22, 0.29, 0.37),
		"sand_mid": Color(0.13, 0.19, 0.27),
		"sand_low": Color(0.065, 0.10, 0.16),
		"sand_deep": Color(0.020, 0.033, 0.065),
		"rim": Color(0.66, 0.82, 0.98),
		"accent": Color(0.70, 0.86, 1.00),
		"cloud": Color(0.33, 0.45, 0.61, 0.12),
		"star_amount": 1.0,
		"cloud_amount": 0.08,
		"fog_amount": 0.17,
		"sun_alpha": 0.0,
		"moon_alpha": 0.85,
	},
]

static func biome_index_at(world_x: float) -> int:
	var x := maxf(world_x, 0.0)
	return posmod(floori(x / BIOME_LENGTH), BIOME_NAMES.size())

static func biome_name_at(world_x: float) -> String:
	return BIOME_NAMES[biome_index_at(world_x)]

static func biome_id_at(world_x: float) -> String:
	return BIOME_IDS[biome_index_at(world_x)]

static func tagline_at(world_x: float) -> String:
	return BIOME_TAGLINES[biome_index_at(world_x)]

static func transition_info(world_x: float) -> Dictionary:
	var x := maxf(world_x, 0.0)
	var index := biome_index_at(x)
	var phase := fposmod(x, BIOME_LENGTH) / BIOME_LENGTH
	var start := 1.0 - TRANSITION_FRACTION
	var t := clampf((phase - start) / TRANSITION_FRACTION, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	return {
		"index": index,
		"next_index": posmod(index + 1, BIOME_NAMES.size()),
		"transition": t,
		"kind": LANDMARK_KINDS[index],
		"next_kind": LANDMARK_KINDS[posmod(index + 1, LANDMARK_KINDS.size())],
	}

static func palette_at(world_x: float) -> Dictionary:
	var info := transition_info(world_x)
	var a: Dictionary = PALETTES[int(info.index)]
	var b: Dictionary = PALETTES[int(info.next_index)]
	var t: float = float(info.transition)
	var result := {}
	for key in COLOR_KEYS:
		result[key] = (a[key] as Color).lerp(b[key] as Color, t)
	for key in NUMBER_KEYS:
		result[key] = lerpf(float(a[key]), float(b[key]), t)
	result["biome_index"] = int(info.index)
	result["next_biome_index"] = int(info.next_index)
	result["transition"] = t
	result["kind"] = str(info.kind)
	result["next_kind"] = str(info.next_kind)
	return result

static func palette(index: int) -> Dictionary:
	return PALETTES[posmod(index, PALETTES.size())].duplicate()

static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha)

static func ui_gold() -> Color:
	return Color(0.96, 0.78, 0.48)

static func ui_cream() -> Color:
	return Color(0.97, 0.93, 0.84)

static func ui_ink() -> Color:
	return Color(0.055, 0.060, 0.095)

static func ui_mist() -> Color:
	return Color(0.80, 0.84, 0.87)

static func ridgeline(seed_value: float, x: float, frequency: float, amplitude: float) -> float:
	var n := x * frequency
	return sin(n + seed_value) * amplitude \
		+ sin(n * 2.13 + seed_value * 1.7) * amplitude * 0.34 \
		+ sin(n * 4.71 + seed_value * 2.3) * amplitude * 0.12

static func hash01(value: float) -> float:
	return fposmod(sin(value * 127.1 + 311.7) * 43758.5453123, 1.0)
