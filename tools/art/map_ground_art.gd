extends RefCounted
## The run map's ground and node frames (dev-time art generator, M13 playtest: "the run map is super
## boring"). One seamless 128x128 art-pixel ground tile per biome (saved at 2x like the other UI art):
## wrapped value noise in the biome's colours, ordered-dither bands, then the biome's own litter (grass,
## bones, ice cracks, ripples, glints, ash). Plus the six node frames (idle, choice, done; normal and
## boss size): a stone disc with a 1 px dark outline, the choice ring gold, the done ring filled gold.
##   godot --headless --path . --script res://tools/art/generate_art.gd -- --only=map_ground,map_frames

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const BiomeArt: GDScript = preload("res://tools/art/biome_art.gd")

const TILE: int = 128
const LATTICE: int = 8
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

## Per chapter id: the ground ramp (dark to light), a darker/lighter patch ramp, the litter colours
## and what to scatter. The seven newer biomes borrow their ramps from BiomeArt.STYLES.
const OWN: Dictionary = {
	"crypt_road": {
		"base": [Color("141c12"), Color("1c2718"), Color("26331f"), Color("324128"), Color("3f5030")],
		"patch": [Color("2a2418"), Color("3a3220"), Color("4e432a")],
		"litter": [Color("5e6a3c"), Color("8a9a5a"), Color("c3b99c")],
		"kind": "bones",
	},
	"drowned_fields": {
		"base": [Color("0f1a1a"), Color("152524"), Color("1d3331"), Color("27433f"), Color("33564f")],
		"patch": [Color("1a2a1a"), Color("26391f"), Color("34492a")],
		"litter": [Color("57b892"), Color("8fd9b8"), Color("c8f57a")],
		"kind": "ripples",
	},
}
const KINDS: Dictionary = {
	"ashen_keep": "ash", "ember_orchard": "ash", "frostbound_pass": "cracks", "sunless_mines": "glints",
	"bone_quarry": "bones", "gloam_wood": "grass", "pale_cathedral": "glints",
}


func ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in OWN:
		out.append(id)
	for id: String in KINDS:
		out.append(id)
	return out


## The seamless ground tile of chapter `id`, at 2x.
func ground(id: String) -> Image:
	var look: Dictionary = _look(id)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(id)
	var lattice: Array = _lattice(rng, LATTICE)
	var detail: Array = _lattice(rng, LATTICE * 3)
	var img: Image = Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	var base: Array = look["base"]
	var patch: Array = look["patch"]
	for y: int in TILE:
		for x: int in TILE:
			var n: float = 0.65 * _sample(lattice, LATTICE, x, y) + 0.35 * _sample(detail, LATTICE * 3, x, y)
			var threshold: float = (BAYER[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0
			var scaled: float = n * (base.size() - 1)
			var index: int = clampi(int(scaled + threshold - 0.5 + 0.5), 0, base.size() - 1)
			var color: Color = base[index]
			var p: float = _sample(lattice, LATTICE, x + 37, y + 61)
			if p > 0.68:  # worn patches: the road dust, the damp earth
				color = color.lerp(patch[clampi(int((p - 0.68) / 0.32 * patch.size()), 0, patch.size() - 1)], 0.4)
			img.set_pixel(x, y, color)
	_litter(img, look, str(look["kind"]), rng)
	return _x2(img)


## One node frame: state "idle" | "choice" | "done", boss or not.
func frame(state: String, boss: bool) -> Image:
	var size: int = 32 if boss else 22
	var c: Canvas = Canvas.new(size, size)
	var center: Vector2 = Vector2(size, size) * 0.5
	var radius: float = size * 0.5 - 1.5
	c.part()
	c.ellipse(center, Vector2(radius, radius), P.STONE, 0.0, -0.25)
	c.part()
	c.ellipse(center, Vector2(radius - 3.0, radius - 3.0), [P.STONE[0], P.STONE[1], P.STONE[1]], 0.0, 0.0)
	c.finish()
	var img: Image = c.image
	if state != "idle":
		_ring(img, radius - 0.5, P.GOLD if state == "choice" else P.GOLD)
	if state == "done":
		_disc(img, radius - 3.0, Color(P.GOLD[2], 0.32))
	return _x2(img)


func _look(id: String) -> Dictionary:
	if OWN.has(id):
		return OWN[id]
	var style: Dictionary = BiomeArt.STYLES[id]
	var base: Array = (style["base"] as Array).slice(0, 5)
	return {"base": base, "patch": (style["alt"] as Array).slice(0, 3), "litter": style["tuft"] as Array, "speck": style["speck"] as Array, "kind": KINDS[id]}


func _lattice(rng: RandomNumberGenerator, count: int) -> Array:
	var values: Array = []
	for _i: int in count * count:
		values.append(rng.randf())
	return values


## Wrapped, smoothly interpolated value noise: tiles without a seam.
func _sample(values: Array, count: int, x: int, y: int) -> float:
	var cell: float = float(TILE) / count
	var fx: float = fmod(float(x), TILE) / cell
	var fy: float = fmod(float(y), TILE) / cell
	var x0: int = int(fx) % count
	var y0: int = int(fy) % count
	var x1: int = (x0 + 1) % count
	var y1: int = (y0 + 1) % count
	var tx: float = smoothstep(0.0, 1.0, fx - floorf(fx))
	var ty: float = smoothstep(0.0, 1.0, fy - floorf(fy))
	var a: float = lerpf(values[y0 * count + x0], values[y0 * count + x1], tx)
	var b: float = lerpf(values[y1 * count + x0], values[y1 * count + x1], tx)
	return lerpf(a, b, ty)


func _put(img: Image, x: int, y: int, color: Color) -> void:
	img.set_pixel(posmod(x, TILE), posmod(y, TILE), color)


func _litter(img: Image, look: Dictionary, kind: String, rng: RandomNumberGenerator) -> void:
	var litter: Array = look["litter"]
	var speck: Array = look.get("speck", litter)
	for _i: int in 46:
		var x: int = rng.randi_range(0, TILE - 1)
		var y: int = rng.randi_range(0, TILE - 1)
		match kind:
			"grass":
				_put(img, x, y, litter[1])
				_put(img, x, y - 1, litter[2])
				_put(img, x + 1, y - 2, litter[1])
			"bones":
				_put(img, x, y, litter[2])
				_put(img, x + 1, y, litter[2])
				_put(img, x + 2, y + 1, litter[1])
				if _i % 3 == 0:
					_put(img, x, y + 1, litter[0])
			"ripples":
				for dx: int in 4:
					_put(img, x + dx, y, litter[0])
				_put(img, x + 1, y + 1, litter[1])
				_put(img, x + 2, y + 1, litter[1])
			"cracks":
				if _i % 3 != 0:
					continue
				var cx: int = x
				for step: int in 5:
					_put(img, cx, y + step, speck[2])
					cx += rng.randi_range(-1, 1)
			"glints":
				if _i % 2 == 0:
					_put(img, x, y, speck[0])
					_put(img, x + 1, y, speck[0])
					_put(img, x, y + 1, speck[0])
			"ash":
				_put(img, x, y, litter[1])
				_put(img, x + 1, y, litter[0])
				if _i % 5 == 0:
					_put(img, x, y, speck[1])
	# A few larger stones on every ground.
	for _i: int in 9:
		var sx: int = rng.randi_range(0, TILE - 1)
		var sy: int = rng.randi_range(0, TILE - 1)
		for dx: int in 3:
			_put(img, sx + dx, sy, P.STONE[3])
			_put(img, sx + dx, sy + 1, P.STONE[1])
		_put(img, sx, sy, P.STONE[4])


func _ring(img: Image, radius: float, ramp: Array) -> void:
	var center: Vector2 = Vector2(img.get_size()) * 0.5
	var scale: int = 1
	for y: int in img.get_height():
		for x: int in img.get_width():
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d <= radius and d > radius - 1.6 * scale and img.get_pixel(x, y).a > 0.0:
				img.set_pixel(x, y, ramp[3] if (x + y) % 5 else ramp[2])


func _disc(img: Image, radius: float, color: Color) -> void:
	var center: Vector2 = Vector2(img.get_size()) * 0.5
	for y: int in img.get_height():
		for x: int in img.get_width():
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius:
				var old: Color = img.get_pixel(x, y)
				img.set_pixel(x, y, old.lerp(Color(color, 1.0), color.a))


func _x2(img: Image) -> Image:
	var out: Image = img.duplicate() as Image
	out.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return out
