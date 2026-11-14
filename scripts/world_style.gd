class_name HavenWorldStyle
extends RefCounted

## Shared palette and naming data for the eight Haven Dhaka environments.
## Palettes are deliberately authored rather than random so every biome keeps a
## clear cinematic identity while the atmosphere can blend continuously.

const BIOME_LENGTH := 5200.0
const COUNT := 8

const NAMES := [
	"GOLDEN DUNES",
	"SUN-BURIED RUINS",
	"MOUNTAIN VALLEYS",
	"DHAKA AT DUSK",
	"SUNSET CANYON",
	"TWILIGHT DESERT",
	"MOONLIT DUNES",
	"STARRY NIGHT MOUNTAINS",
]

const SUBTITLES := [
	"where the light begins",
	"stone remembers every traveller",
	"the long road between peaks",
	"lanterns above the old city",
	"the last fire of day",
	"a violet hush over the sand",
	"silver wind, silver dunes",
	"the road becomes the sky",
]

# Palettes: sky gradients, atmospheric layers, sand and accent colours.
const STYLES := [
	{
		"name": "GOLDEN DUNES", "subtitle": "where the light begins",
		"sky_top": Color("173d63"), "sky_mid": Color("4a7c96"),
		"sky_low": Color("f0b07e"), "horizon": Color("ffe0ae"),
		"sun": Color("ffe6b2"), "sun_core": Color("fff8df"), "sun_glow": Color("ffb46d"),
		"sun_x": 0.77, "sun_y": 0.235, "sun_size": 0.80,
		"cloud": Color("ffd8b2"), "fog": Color("ffd9b1"),
		"far": Color("7d5d70"), "mid": Color("a86e73"), "near": Color("c8886c"),
		"landmark": Color("694c59"), "landmark_hi": Color("c17f6d"),
		"dune_far": Color("dfa579"), "dune_near": Color("b9795d"),
		"terrain_hi": Color("eec188"), "terrain_mid": Color("c4855c"),
		"terrain_low": Color("74403f"), "rim": Color("ffe2ac"),
		"accent": Color("ffcf86"), "dust": Color("ffe0b5"),
		"night": 0.0, "landmark_kind": "palms", "mountain_kind": "dunes",
		"music": "day",
	},
	{
		"name": "SUN-BURIED RUINS", "subtitle": "stone remembers every traveller",
		"sky_top": Color("3a365f"), "sky_mid": Color("786184"),
		"sky_low": Color("d99178"), "horizon": Color("f4c493"),
		"sun": Color("ffe0ac"), "sun_core": Color("fff3d1"), "sun_glow": Color("e99a68"),
		"sun_x": 0.82, "sun_y": 0.31, "sun_size": 0.88,
		"cloud": Color("eac6b0"), "fog": Color("e5b698"),
		"far": Color("665369"), "mid": Color("846573"), "near": Color("a57974"),
		"landmark": Color("584553"), "landmark_hi": Color("c38b76"),
		"dune_far": Color("d0a17d"), "dune_near": Color("a97464"),
		"terrain_hi": Color("ddb07b"), "terrain_mid": Color("b07b5d"),
		"terrain_low": Color("5f3c3f"), "rim": Color("f1d0a3"),
		"accent": Color("f3c177"), "dust": Color("e8c59c"),
		"night": 0.0, "landmark_kind": "ruins", "mountain_kind": "ridges",
		"music": "day",
	},
	{
		"name": "MOUNTAIN VALLEYS", "subtitle": "the long road between peaks",
		"sky_top": Color("285073"), "sky_mid": Color("71909d"),
		"sky_low": Color("c4b69f"), "horizon": Color("efdcc2"),
		"sun": Color("fff0cb"), "sun_core": Color("fffbeb"), "sun_glow": Color("f3c785"),
		"sun_x": 0.70, "sun_y": 0.19, "sun_size": 0.58,
		"cloud": Color("e8e1d5"), "fog": Color("d6d5c8"),
		"far": Color("627383"), "mid": Color("78868d"), "near": Color("98958c"),
		"landmark": Color("59606a"), "landmark_hi": Color("a8aaa1"),
		"dune_far": Color("b6aa8f"), "dune_near": Color("968a79"),
		"terrain_hi": Color("d6c69a"), "terrain_mid": Color("a99778"),
		"terrain_low": Color("5d5450"), "rim": Color("f0e2bc"),
		"accent": Color("e6cf9a"), "dust": Color("e9ddc2"),
		"night": 0.0, "landmark_kind": "pines", "mountain_kind": "jagged",
		"music": "day",
	},
	{
		"name": "DHAKA AT DUSK", "subtitle": "lanterns above the old city",
		"sky_top": Color("251c48"), "sky_mid": Color("603b66"),
		"sky_low": Color("cf665d"), "horizon": Color("ffb56c"),
		"sun": Color("ffd49a"), "sun_core": Color("ffe9c8"), "sun_glow": Color("f27452"),
		"sun_x": 0.19, "sun_y": 0.36, "sun_size": 0.95,
		"cloud": Color("d99a8c"), "fog": Color("e08a70"),
		"far": Color("4f3e5d"), "mid": Color("68495c"), "near": Color("83545c"),
		"landmark": Color("3a2d46"), "landmark_hi": Color("bd6e5e"),
		"dune_far": Color("a97a72"), "dune_near": Color("825862"),
		"terrain_hi": Color("c48e65"), "terrain_mid": Color("945b54"),
		"terrain_low": Color("4f2d3b"), "rim": Color("e2a778"),
		"accent": Color("ffb45f"), "dust": Color("d79a83"),
		"night": 0.28, "landmark_kind": "city", "mountain_kind": "dunes",
		"music": "dusk",
	},
	{
		"name": "SUNSET CANYON", "subtitle": "the last fire of day",
		"sky_top": Color("2b1a3b"), "sky_mid": Color("813c4d"),
		"sky_low": Color("e2664c"), "horizon": Color("ffb063"),
		"sun": Color("ffce82"), "sun_core": Color("ffe6b2"), "sun_glow": Color("ff6b3d"),
		"sun_x": 0.72, "sun_y": 0.47, "sun_size": 1.16,
		"cloud": Color("d36d5b"), "fog": Color("dd7258"),
		"far": Color("572d42"), "mid": Color("78374a"), "near": Color("98434b"),
		"landmark": Color("452432"), "landmark_hi": Color("c75f51"),
		"dune_far": Color("b96852"), "dune_near": Color("8a4549"),
		"terrain_hi": Color("c67b55"), "terrain_mid": Color("8e4b43"),
		"terrain_low": Color("422333"), "rim": Color("eda06b"),
		"accent": Color("ffb05d"), "dust": Color("d67e63"),
		"night": 0.18, "landmark_kind": "mesas", "mountain_kind": "mesas",
		"music": "dusk",
	},
	{
		"name": "TWILIGHT DESERT", "subtitle": "a violet hush over the sand",
		"sky_top": Color("141532"), "sky_mid": Color("3a2a5b"),
		"sky_low": Color("7a4b6c"), "horizon": Color("da8b74"),
		"sun": Color("ffc7a0"), "sun_core": Color("ffe2c6"), "sun_glow": Color("b26778"),
		"sun_x": 0.16, "sun_y": 0.41, "sun_size": 0.86,
		"cloud": Color("9e708b"), "fog": Color("ad6f78"),
		"far": Color("342d51"), "mid": Color("4a3a5a"), "near": Color("67495e"),
		"landmark": Color("28223e"), "landmark_hi": Color("986478"),
		"dune_far": Color("705a6a"), "dune_near": Color("503f5b"),
		"terrain_hi": Color("80635f"), "terrain_mid": Color("5d4852"),
		"terrain_low": Color("2b233a"), "rim": Color("bd8178"),
		"accent": Color("e5a27b"), "dust": Color("a98186"),
		"night": 0.55, "landmark_kind": "monoliths", "mountain_kind": "ridges",
		"music": "dusk",
	},
	{
		"name": "MOONLIT DUNES", "subtitle": "silver wind, silver dunes",
		"sky_top": Color("040a1d"), "sky_mid": Color("0f2340"),
		"sky_low": Color("29435e"), "horizon": Color("597286"),
		"sun": Color("f0f6ff"), "sun_core": Color("ffffff"), "sun_glow": Color("8fb8d8"),
		"sun_x": 0.22, "sun_y": 0.19, "sun_size": 0.46,
		"cloud": Color("66809c"), "fog": Color("5f7d96"),
		"far": Color("16273f"), "mid": Color("20354c"), "near": Color("2e455b"),
		"landmark": Color("132135"), "landmark_hi": Color("4e6b86"),
		"dune_far": Color("324661"), "dune_near": Color("24354f"),
		"terrain_hi": Color("57667b"), "terrain_mid": Color("3d4e65"),
		"terrain_low": Color("172338"), "rim": Color("a9c1d1"),
		"accent": Color("d7e7ef"), "dust": Color("89a6bf"),
		"night": 0.92, "landmark_kind": "palms", "mountain_kind": "dunes",
		"music": "night",
	},
	{
		"name": "STARRY NIGHT MOUNTAINS", "subtitle": "the road becomes the sky",
		"sky_top": Color("01040f"), "sky_mid": Color("07152c"),
		"sky_low": Color("152b4b"), "horizon": Color("355272"),
		"sun": Color("eaf4ff"), "sun_core": Color("ffffff"), "sun_glow": Color("6d95c4"),
		"sun_x": 0.78, "sun_y": 0.17, "sun_size": 0.40,
		"cloud": Color("3f5c7b"), "fog": Color("43607d"),
		"far": Color("12233c"), "mid": Color("1b304a"), "near": Color("2b3e56"),
		"landmark": Color("0d1a2b"), "landmark_hi": Color("506884"),
		"dune_far": Color("263a54"), "dune_near": Color("172840"),
		"terrain_hi": Color("4c5b70"), "terrain_mid": Color("334357"),
		"terrain_low": Color("0e1626"), "rim": Color("a8bfd2"),
		"accent": Color("dfeaf4"), "dust": Color("7f9bb7"),
		"night": 1.0, "landmark_kind": "night_peaks", "mountain_kind": "jagged",
		"music": "night",
	},
]

const RIDERS := {
	"wayfarer": {
		"name": "THE WAYFARER",
		"tagline": "Ochre dust, an old promise, and the long way home.",
		"coat": Color("c76846"), "coat_light": Color("e08a5d"), "coat_dark": Color("7c3c39"),
		"pants": Color("3a3946"), "pants_light": Color("56536a"),
		"scarf": Color("e9d6b0"), "scarf_shadow": Color("b99a7c"),
		"skin": Color("a86648"), "skin_light": Color("c9845e"),
		"hair": Color("241b24"), "board": Color("d68a51"), "board_dark": Color("764038"),
		"trim": Color("f2c77f"), "goggles": Color("77c8c1"),
		"unlock": "default",
	},
	"mirage": {
		"name": "THE MIRAGE",
		"tagline": "Indigo silk, silver laughter, footprints in two worlds.",
		"coat": Color("4d5e96"), "coat_light": Color("7587bf"), "coat_dark": Color("2f365c"),
		"pants": Color("2c3242"), "pants_light": Color("414b62"),
		"scarf": Color("f0e6d0"), "scarf_shadow": Color("c2b39b"),
		"skin": Color("744834"), "skin_light": Color("986249"),
		"hair": Color("17141e"), "board": Color("3f7e8c"), "board_dark": Color("244450"),
		"trim": Color("d9c28b"), "goggles": Color("f0c271"),
		"unlock": "distance",
	},
	"ember": {
		"name": "THE EMBER",
		"tagline": "A crimson thread through the quietest night.",
		"coat": Color("e5d3b1"), "coat_light": Color("f5e7cc"), "coat_dark": Color("9f8667"),
		"pants": Color("4f4a3c"), "pants_light": Color("6e6854"),
		"scarf": Color("bd4350"), "scarf_shadow": Color("812f3d"),
		"skin": Color("c68b66"), "skin_light": Color("e2aa7e"),
		"hair": Color("302126"), "board": Color("3e3337"), "board_dark": Color("211b1f"),
		"trim": Color("d9b472"), "goggles": Color("8ec6de"),
		"unlock": "tricks",
	},
}


static func biome_index_at(travel_x: float) -> int:
	return posmod(floori(maxf(travel_x, 0.0) / BIOME_LENGTH), COUNT)


static func next_biome_index_at(travel_x: float) -> int:
	return posmod(biome_index_at(travel_x) + 1, COUNT)


static func transition_at(travel_x: float) -> float:
	var phase := fposmod(maxf(travel_x, 0.0), BIOME_LENGTH) / BIOME_LENGTH
	return smoothstep(0.80, 0.985, phase)


static func name_at(travel_x: float) -> String:
	return NAMES[biome_index_at(travel_x)]


static func subtitle_at(travel_x: float) -> String:
	return SUBTITLES[biome_index_at(travel_x)]


static func style_at(travel_x: float) -> Dictionary:
	var current: Dictionary = STYLES[biome_index_at(travel_x)]
	var next: Dictionary = STYLES[next_biome_index_at(travel_x)]
	var t := transition_at(travel_x)
	if t <= 0.001:
		return current.duplicate()
	var result := current.duplicate()
	for key in current:
		if current[key] is Color:
			result[key] = (current[key] as Color).lerp(next[key], t)
		elif current[key] is float:
			result[key] = lerpf(current[key], next[key], t)
	# The near landmark swaps in the final sliver so two architectural styles do
	# not overlap awkwardly. Colours still blend across the whole transition.
	if t > 0.55:
		result["landmark_kind"] = next["landmark_kind"]
		result["mountain_kind"] = next["mountain_kind"]
		result["name"] = next["name"]
		result["subtitle"] = next["subtitle"]
	return result


static func style_for_index(index: int) -> Dictionary:
	return STYLES[posmod(index, COUNT)]


static func rider_ids() -> Array:
	return RIDERS.keys()


static func rider_style(id: String) -> Dictionary:
	return RIDERS.get(id, RIDERS["wayfarer"])


static func music_for(travel_x: float) -> String:
	return String(STYLES[biome_index_at(travel_x)]["music"])
