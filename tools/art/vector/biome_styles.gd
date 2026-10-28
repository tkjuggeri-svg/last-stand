class_name BiomeStyles
## The maps' palettes and kinds for the vector grounds and props (M15 P4, docs/M15_P4_MAPS.md). The palettes were copied from
## the pixel generator (tools/art/biome_art.gd STYLES, which can retire); the Drowned Marsh's come from the run map's ground
## look. Each style: "base" (the floor, dark to light), "alt" and "alt2" (patches of other soil), "path" (the roads), "tuft"
## (what grows or lies about), "speck" (the glints: embers, ice, ore, candle dust), "wall_tint" (the wall band), "stone" (cold
## or warm stone), "patch" (an optional extra ramp). KINDS says which details a ground gets.

const STYLES: Dictionary = {
	"ashen_keep": {
		"base": [Color("1d1a1c"), Color("26221f"), Color("302b28"), Color("3b3531"), Color("4a423c"), Color("5b5249")],
		"alt": [Color("231615"), Color("31201c"), Color("422b24"), Color("57382c")],
		"alt2": [Color("1a1a1e"), Color("26262c"), Color("33333b")],
		"path": [Color("120f10"), Color("231d1c"), Color("322a28"), Color("453b37"), Color("5a4d47"), Color("6f625a")],
		"tuft": [Color("3a342f"), Color("5e5148"), Color("7a6a5c")],
		"speck": [Color("8a3a22"), Color("c2652a"), Color("e8a24a")],
		"wall_tint": Color("2a1a14"),
		"stone": "STONE_WARM",
	},
	"ember_orchard": {
		"base": [Color("181c0f"), Color("212612"), Color("2a301b"), Color("353c22"), Color("424a29"), Color("525c31")],
		"alt": [Color("2a2a14"), Color("3a3a1c"), Color("4e4b24"), Color("665f2c")],
		"alt2": [Color("21200f"), Color("2d2b14"), Color("3a371b")],
		"path": [Color("1c140e"), Color("2c2016"), Color("3d2e20"), Color("523f2b"), Color("6b5238"), Color("84684a")],
		"tuft": [Color("3a4222"), Color("5e6a34"), Color("8a8c4a")],
		"speck": [Color("a8431c"), Color("e88a3a"), Color("f0c870")],
		"wall_tint": Color("2a2012"),
		"stone": "STONE_WARM",
		"patch": [Color("4a3f1c"), Color("63551f"), Color("7e6c2a"), Color("9b883a")],
	},
	"frostbound_pass": {
		"base": [Color("121a26"), Color("182330"), Color("202d40"), Color("293c54"), Color("334a68"), Color("3f5a7c")],
		"alt": [Color("1c2838"), Color("263648"), Color("32465e"), Color("405a78")],
		"alt2": [Color("141c2a"), Color("1c2838"), Color("263648")],
		"path": [Color("2a2420"), Color("3c342e"), Color("52483f"), Color("6c6054"), Color("887a6a"), Color("a4947f")],
		"tuft": [Color("586c82"), Color("8aa0b6"), Color("c4d6e6")],
		"speck": [Color("dff6ff"), Color("b6e4ff"), Color("8fd0f0")],
		"wall_tint": Color("1a2230"),
		"stone": "STONE",
	},
	"sunless_mines": {
		"base": [Color("17151c"), Color("201e27"), Color("2a2833"), Color("36333f"), Color("45414f"), Color("57535f")],
		"alt": [Color("1e1a1a"), Color("2b2423"), Color("3a302d"), Color("4c3e39")],
		"alt2": [Color("14161c"), Color("1e222a"), Color("2a2f3a")],
		"path": [Color("1a1820"), Color("2a2730"), Color("3e3a47"), Color("57525f"), Color("756f81"), Color("968fa3")],
		"tuft": [Color("2c2a34"), Color("46424f"), Color("625d6e")],
		"speck": [Color("57e0c8"), Color("b58cff"), Color("e8c060")],
		"wall_tint": Color("100e14"),
		"stone": "STONE",
	},
	"bone_quarry": {
		"base": [Color("1e1c1a"), Color("282522"), Color("33302b"), Color("403b35"), Color("524c43"), Color("675f53")],
		"alt": [Color("2a2420"), Color("3a322b"), Color("4c4137"), Color("62564a")],
		"alt2": [Color("1a1c20"), Color("24272d"), Color("303439")],
		"path": [Color("1c1814"), Color("2e2720"), Color("43392e"), Color("5c4f40"), Color("786a57"), Color("958471")],
		"tuft": [Color("3a362f"), Color("5e564a"), Color("8a8070")],
		"speck": [Color("c3b99c"), Color("ece4cb"), Color("8f8670")],
		"wall_tint": Color("221c16"),
		"stone": "STONE_WARM",
	},
	"gloam_wood": {
		"base": [Color("0e1612"), Color("141f19"), Color("1b2a22"), Color("233830"), Color("2c473b"), Color("385a4a")],
		"alt": [Color("16241a"), Color("1f3324"), Color("2a4631"), Color("375c40")],
		"alt2": [Color("0c1418"), Color("131f25"), Color("1b2b33")],
		"path": [Color("1a1410"), Color("2a2118"), Color("3c3022"), Color("52432f"), Color("6c5a40"), Color("88735a")],
		"tuft": [Color("1f3a28"), Color("2f5a3c"), Color("4a8a58")],
		"speck": [Color("a8f0c8"), Color("57b892"), Color("c8f57a")],
		"wall_tint": Color("0c1410"),
		"stone": "STONE",
	},
	"pale_cathedral": {
		"base": [Color("1b1b24"), Color("24242f"), Color("2f2f3c"), Color("3b3b4a"), Color("494959"), Color("5a5a6c")],
		"alt": [Color("2a2a38"), Color("383848"), Color("484860"), Color("5c5c78")],
		"alt2": [Color("17171f"), Color("20202a"), Color("2b2b38")],
		"path": [Color("221f26"), Color("322e38"), Color("46414f"), Color("5f5a69"), Color("7c7688"), Color("9a94a8")],
		"tuft": [Color("3a3a4a"), Color("5a5a72"), Color("84849e")],
		"speck": [Color("e4d4ff"), Color("b58cff"), Color("efd07a")],
		"wall_tint": Color("15131c"),
		"stone": "STONE",
		"path_shift": 1,  # the roads one step darker: characters must stay brighter than the floor (test_readability)
	},
}

## The Drowned Marsh (its own ground look, pools painted from the level's Water polygons).
const MARSH: Dictionary = {
	"base": [Color("0f1a1a"), Color("152524"), Color("1d3331"), Color("27433f"), Color("33564f"), Color("41695f")],
	"alt": [Color("1a2a1a"), Color("26391f"), Color("34492a"), Color("43592f")],
	"alt2": [Color("111d22"), Color("182a30"), Color("213a42")],
	"path": [Color("1a1612"), Color("2a221b"), Color("3b3025"), Color("4e4132"), Color("66553f"), Color("806c50")],
	"tuft": [Color("2a4a36"), Color("3f6b4a"), Color("6a9a5a")],
	"speck": [Color("57b892"), Color("8fd9b8"), Color("c8f57a")],
	"wall_tint": Color("0c1514"),
	"stone": "STONE",
}

## The details each ground gets: grass (blades and flowers), snow (frosted tufts, ice cracks, sparkles), ash (cinders and
## embers), stone (pebbles, gravel, bones), moss (ferns, moss, glowing mushrooms), tile (flagstones and cracks), marsh (reeds).
const KINDS: Dictionary = {
	"crypt_road": "grass", "ember_orchard": "ash_grass", "bone_quarry": "stone", "drowned_marsh": "marsh",
	"frostbound_pass": "snow", "gloam_wood": "moss", "ashen_keep": "ash", "sunless_mines": "stone", "pale_cathedral": "tile",
}


## The litter each ground scatters (embers, bone fragments, ice sparkles, ore glints, glowing mushrooms, candle dust, ripples).
const LITTER: Dictionary = {
	"crypt_road": "leaves", "ember_orchard": "embers", "bone_quarry": "bones", "drowned_marsh": "ripples",
	"frostbound_pass": "sparkles", "gloam_wood": "mushrooms", "ashen_keep": "embers", "sunless_mines": "glints", "pale_cathedral": "candle",
}


static func of(biome: String) -> Dictionary:
	if biome == "drowned_marsh":
		return MARSH
	return STYLES.get(biome, {})
