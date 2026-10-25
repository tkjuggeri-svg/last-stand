extends RefCounted
## Enemy variants (dev-time art generator, M10): a new enemy that is an existing one in other colours. The
## base art is drawn as usual and every pixel taken from one of the base's ramps is replaced by the same
## step of the variant's ramp (outlines, shadows and untouched ramps stay), so the variant keeps the
## base's poses, silhouette and animation timings (its sheet layout is the base's: sheet_layouts.gd).
## What makes a variant different in play is its EnemyData and ability, not its sprite; a sprite of its
## own can replace the sheet later (M13's art pass).
##   godot --headless --path . --script res://tools/art/generate_art.gd -- --only=<variant id>

const P: GDScript = preload("res://tools/art/palette.gd")

## Variant id -> {art: the base art script, maps: [[from ramp, to ramp], ...]}.
const VARIANTS: Dictionary = {
	"siege_ram": {"art": "res://tools/art/brute_art.gd", "maps": [
		[[Color("2a2236"), Color("463a5a"), Color("66597f"), Color("8b7ca3"), Color("b0a2c4"), Color("dcd2ea")],
			[Color("2c2426"), Color("463a3c"), Color("665456"), Color("8a7573"), Color("b0a09a"), Color("d9ccc4")]],
		[[Color("10306e"), Color("1b5ac2"), Color("7fb4ff"), Color("d0e4ff")], [Color("6e2410"), Color("c2501b"), Color("ff8a3a"), Color("ffd0a0")]],
	]},
	"black_knight": {"art": "res://tools/art/shieldbearer_art.gd", "maps": [
		[[Color("2c2b37"), Color("484756"), Color("676778"), Color("8f909e"), Color("bcbec8")],
			[Color("33334a"), Color("4e4e70"), Color("72729a"), Color("a0a0c8"), Color("cdcdee")]],
		[[Color("24171a"), Color("432820"), Color("6a3c26"), Color("94582f"), Color("b97b45")],
			[Color("3a1219"), Color("6a1f2a"), Color("962d36"), Color("c04448"), Color("e06a60")]],
		[[Color("10306e"), Color("1b5ac2"), Color("7fb4ff"), Color("d0e4ff")], [Color("6e1410"), Color("c2261b"), Color("ff5a3a"), Color("ffc9a0")]],
	]},
	"fallen_marshal": {"art": "res://tools/art/colossus_art.gd", "maps": [
		[[Color("5b5446"), Color("8f8670"), Color("c3b99c"), Color("ece4cb")],
			[Color("2c2b3c"), Color("4a4962"), Color("6d6b8e"), Color("9a98bd")]],
		[[Color("26131a"), Color("45201f"), Color("6b3428"), Color("91503a"), Color("b47452"), Color("d39b72")],
			[Color("2c0d14"), Color("531721"), Color("7e232b"), Color("a83632"), Color("c95341"), Color("e07a5a")]],
	]},	"cinder_ghoul": {"art": "res://tools/art/ghoul_art.gd", "maps": [
		[P.GHOUL_SKIN, [Color("2a1a12"), Color("4a2c1c"), Color("7a4a28"), Color("b0692f"), Color("e08a3e"), Color("ffb860")]],
		[P.EYE_GLOW, [Color("6e3a10"), Color("c27a1b"), Color("ffb03a"), Color("fff0b0")]],
	]},	"scarecrow": {"art": "res://tools/art/brute_art.gd", "maps": [
		[P.BRUTE_SKIN, [Color("2c2410"), Color("4a3c1a"), Color("78622a"), Color("a88c3e"), Color("d4b65a"), Color("f0dc94")]],
		[P.EYES_TANK, [Color("6e2a10"), Color("c2501b"), Color("ff8a3a"), Color("ffd0a0")]],
	]},	"pyre_warden": {"art": "res://tools/art/lich_art.gd", "maps": [
		[P.LICH_ROBE, [Color("2a0e0a"), Color("4a1a10"), Color("7a2a14"), Color("a8431c"), Color("d06a2a"), Color("f0a050")]],
		[P.ARCANE_ICE, [Color("8e2a14"), Color("d4551f"), Color("f29a35"), Color("ffd463"), Color("fff6d0")]],
		[P.ICE, [Color("2a0e0a"), Color("4a1a10"), Color("7a2a14"), Color("a8431c"), Color("d06a2a"), Color("f0a050")]],
	]},	"frost_wraith": {"art": "res://tools/art/cultist_art.gd", "maps": [
		[P.CULT_ROBE, [Color("1a2a3a"), Color("2c4560"), Color("46688a"), Color("6f93b8"), Color("a0c4e0"), Color("d8eefc")]],
		[P.WITCHFIRE, [Color("1d3d63"), Color("2f6596"), Color("4f95c8"), Color("8fd0f0"), Color("dff6ff")]],
	]},	"rime_brute": {"art": "res://tools/art/brute_art.gd", "maps": [
		[P.BRUTE_SKIN, [Color("1f2f44"), Color("34506f"), Color("567a9e"), Color("86abcb"), Color("b6d4e8"), Color("e6f4fc")]],
		[P.EYES_TANK, [Color("104e6e"), Color("1b8ac2"), Color("57c8f0"), Color("d0f4ff")]],
	]},	"winter_warden": {"art": "res://tools/art/lich_art.gd", "maps": [
		[P.LICH_ROBE, [Color("14233a"), Color("26405e"), Color("3c648a"), Color("5f8fb8"), Color("92bde0"), Color("cfe8fa")]],
		[P.ARCANE_ICE, [Color("1d3d63"), Color("2f6596"), Color("4f95c8"), Color("8fd0f0"), Color("dff6ff")]],
		[P.GOLD, [Color("1d3d63"), Color("2f6596"), Color("4f95c8"), Color("8fd0f0"), Color("dff6ff")]],
	]},	"burrower": {"art": "res://tools/art/hound_art.gd", "maps": [
		[P.HOUND_HIDE, [Color("22180f"), Color("3a2a1a"), Color("58412a"), Color("7d5c3c"), Color("a38058"), Color("c8a67e")]],
	]},	"lamp_wight": {"art": "res://tools/art/mire_priest_art.gd", "maps": [
		[P.PRIEST_ROBE, [Color("2a2417"), Color("46391e"), Color("6c5a2c"), Color("948040"), Color("bfa85a"), Color("e6d28c")]],
		[P.SOUL, [Color("5a3a10"), Color("b87a1c"), Color("f0b040"), Color("ffe090"), Color("fff6d0")]],
	]},	"deep_warden": {"art": "res://tools/art/tollkeeper_art.gd", "maps": [
		[P.BRONZE, [Color("1c1c24"), Color("30303c"), Color("4a4a5a"), Color("6c6c80"), Color("9696aa"), Color("c4c4d6")]],
		[P.WOOD, [Color("14141a"), Color("24242c"), Color("383844"), Color("545468"), Color("74748c")]],
	]},	"bone_hurler": {"art": "res://tools/art/cultist_art.gd", "maps": [
		[P.CULT_ROBE, [Color("3a3426"), Color("5e5640"), Color("8a7e5c"), Color("b4a47c"), Color("d8cba0"), Color("f0e8c8")]],
		[P.WITCHFIRE, [Color("6e5a1c"), Color("c2a02c"), Color("f0d060"), Color("fff0a0"), Color("fffbe0")]],
	]},	"rubble_brute": {"art": "res://tools/art/brute_art.gd", "maps": [
		[P.BRUTE_SKIN, [Color("2a2824"), Color("443f38"), Color("615a4e"), Color("827a68"), Color("a89f88"), Color("cfc6ae")]],
	]},	"quarry_colossus": {"art": "res://tools/art/colossus_art.gd", "maps": [
		[P.BONE, [Color("2c2824"), Color("4a443c"), Color("6e665a"), Color("968c7c")]],
		[P.HOUND_HIDE, [Color("2a2622"), Color("463f38"), Color("655c50"), Color("867b6a"), Color("a99d86"), Color("cfc4aa")]],
	]},	"stalker": {"art": "res://tools/art/hound_art.gd", "maps": [
		[P.HOUND_HIDE, [Color("16241c"), Color("24402e"), Color("3a5e44"), Color("5a8864"), Color("86b488"), Color("b8dcb0")]],
	]},	"hollow_treant": {"art": "res://tools/art/brute_art.gd", "maps": [
		[P.BRUTE_SKIN, [Color("2c2218"), Color("4a3a26"), Color("6e5638"), Color("947850"), Color("b89c70"), Color("dcc496")]],
		[P.EYES_TANK, [Color("1f4a1c"), Color("3f8f2a"), Color("7fd13b"), Color("c8f57a")]],
	]},	"hollow_stag": {"art": "res://tools/art/gravelord_art.gd", "maps": [
		[P.GRAVE_SHROUD, [Color("1a2a1c"), Color("2e4a32"), Color("46704c"), Color("649a6a"), Color("88c490"), Color("b4e4b4")]],
	]},	"chorister": {"art": "res://tools/art/mire_priest_art.gd", "maps": [
		[P.PRIEST_ROBE, [Color("3a3248"), Color("5c4e70"), Color("8474a0"), Color("aa9ccc"), Color("d2c8ea"), Color("f0eaff")]],
		[P.SOUL, [Color("6a4a10"), Color("b8841c"), Color("f0c040"), Color("ffe890"), Color("fff8d0")]],
	]},	"inquisitor": {"art": "res://tools/art/shieldbearer_art.gd", "maps": [
		[P.IRON_WORN, [Color("34323e"), Color("52505e"), Color("76748a"), Color("a09eb6"), Color("cccae0")]],
		[P.RUST, [Color("3a1424"), Color("66243f"), Color("94385c"), Color("c05882"), Color("e888a8")]],
		[P.EYES_TANK, [Color("6e5410"), Color("c2a11b"), Color("ffe14a"), Color("fff6b0")]],
	]},	"pale_bishop": {"art": "res://tools/art/lich_art.gd", "maps": [
		[P.LICH_ROBE, [Color("3a3850"), Color("5a5878"), Color("827ea8"), Color("aaa6d0"), Color("d4d0f0"), Color("f4f2ff")]],
		[P.ARCANE_ICE, [Color("8a6a1c"), Color("c49a30"), Color("efd07a"), Color("fff1c0"), Color("ffffff")]],
	]},
}

var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


## The base's sheet rows with the variant's colours.
func sheet_rows(id: String) -> Array[Array]:
	var entry: Dictionary = VARIANTS[id]
	var base: RefCounted = (load(String(entry["art"])) as GDScript).new(detail)
	var mapping: Dictionary = _mapping(entry["maps"])
	var rows: Array[Array] = []
	for row: Array in base.sheet_rows():
		var out: Array[Image] = []
		for frame: Image in row:
			out.append(_remap(frame, mapping))
		rows.append(out)
	return _decorated(id, rows)


## The rows with the variant's own features drawn on (variant_decor.gd), if it has any: each frame knows
## its animation (from the sheet's layout) and its place in the cycle.
func _decorated(id: String, rows: Array[Array]) -> Array[Array]:
	var decor: RefCounted = (load("res://tools/art/variant_decor.gd") as GDScript).new(detail)
	if not decor.call("has", id):
		return rows
	var layout: Dictionary = (load("res://tools/art/sheet_layouts.gd") as GDScript).get_script_constant_map()[id.to_upper()]
	var names: Dictionary = {}
	for anim: Array in layout["anims"]:
		names[int(anim[1])] = String(anim[0])
	var out: Array[Array] = []
	for r: int in rows.size():
		var row: Array[Image] = []
		for c: int in rows[r].size():
			row.append(decor.call("decorate", id, rows[r][c], names.get(r, "idle_down"), c, rows[r].size()))
		out.append(row)
	return out


## Colour (as an html string) -> colour, from each pair of ramps (step by step, scaled if the sizes differ).
func _mapping(maps: Array) -> Dictionary:
	var mapping: Dictionary = {}
	for pair: Array in maps:
		var from: Array = pair[0]
		var to: Array = pair[1]
		for i: int in from.size():
			mapping[(from[i] as Color).to_html(false)] = to[roundi(i * (to.size() - 1.0) / maxf(from.size() - 1.0, 1.0))]
	return mapping


func _remap(frame: Image, mapping: Dictionary) -> Image:
	var out: Image = frame.duplicate() as Image
	for y: int in out.get_height():
		for x: int in out.get_width():
			var color: Color = out.get_pixel(x, y)
			if color.a > 0.0:
				var key: String = color.to_html(false)
				if mapping.has(key):
					var to: Color = mapping[key]
					out.set_pixel(x, y, Color(to.r, to.g, to.b, color.a))
	return out
