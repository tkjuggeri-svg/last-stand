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
	return rows


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
