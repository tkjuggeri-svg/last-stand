extends RefCounted
## Signature features for the recoloured enemy variants (dev-time art generator, M13 art pass). VariantArt
## recolours a base sheet; this draws what makes each variant itself (flames, straw, ice, a lantern, antlers,
## a halo) on top of every frame, with the same banded shading and 1 px outline as the base art
## (Canvas), anchored to the frame's own pixels (the head's top, the body's sides and hem) so the extras follow
## every pose and walk cycle. Three layers: `behind` (drawn under the body), `front` (over it) and `inlay`
## (only where the body is: cracks, frost, stitches). Soft parts (flames, mist, glows) get no outline.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const STRAW: Array[Color] = [Color("4a3814"), Color("7a5e22"), Color("a88a38"), Color("d4b65a"), Color("f0dc94")]
const CRYSTAL: Array[Color] = [Color("1d3d63"), Color("3f78aa"), Color("7fc0e8"), Color("c4ecff"), Color("ffffff")]
const FLAME: Array[Color] = [Color("8e2a14"), Color("d4551f"), Color("f29a35"), Color("ffd463"), Color("fff6d0")]
const SOIL: Array[Color] = [Color("231a14"), Color("3a2b1e"), Color("55402b"), Color("72573a"), Color("8f7048")]

## Variant id -> the method that draws it.
const DECOR: Dictionary = {
	"cinder_ghoul": "_cinder_ghoul",
	"scarecrow": "_scarecrow",
	"frost_wraith": "_frost_wraith",
	"rime_brute": "_rime_brute",
	"burrower": "_burrower",
	"lamp_wight": "_lamp_wight",
	"bone_hurler": "_bone_hurler",
	"rubble_brute": "_rubble_brute",
	"stalker": "_stalker",
	"hollow_treant": "_hollow_treant",
	"chorister": "_chorister",
	"inquisitor": "_inquisitor",
	"black_knight": "_black_knight",
	"siege_ram": "_siege_ram",
	"pyre_warden": "_pyre_warden",
	"winter_warden": "_winter_warden",
	"pale_bishop": "_pale_bishop",
	"deep_warden": "_deep_warden",
	"quarry_colossus": "_quarry_colossus",
	"hollow_stag": "_hollow_stag",
	"fallen_marshal": "_fallen_marshal",
}

## Art px of empty frame added on every side before the features are drawn (the signature may reach past the base's
## frame); sheet_layouts.gd gives these sheets the same extra size (4 x pad at the double resolution).
const PADS: Dictionary = {
	"cinder_ghoul": Vector2i(3, 3), "frost_wraith": Vector2i(3, 3), "rime_brute": Vector2i(4, 3), "lamp_wight": Vector2i(6, 3),
	"chorister": Vector2i(4, 8), "inquisitor": Vector2i(3, 6), "black_knight": Vector2i(4, 6), "siege_ram": Vector2i(6, 2),
	"hollow_treant": Vector2i(6, 6), "bone_hurler": Vector2i(3, 2), "stalker": Vector2i(4, 2),
	"pyre_warden": Vector2i(4, 7), "winter_warden": Vector2i(3, 6), "pale_bishop": Vector2i(6, 12), "deep_warden": Vector2i(3, 3),
	"quarry_colossus": Vector2i(4, 3), "hollow_stag": Vector2i(6, 12), "fallen_marshal": Vector2i(6, 6),
}

var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


func has(id: String) -> bool:
	return DECOR.has(id)


## `frame` with variant `id`'s features, for animation `anim` ("walk_side", ...) at frame `col` of `count`.
func decorate(id: String, source: Image, anim: String, col: int, count: int) -> Image:
	var pad: Vector2i = Vector2i(PADS.get(id, Vector2i.ZERO)) * detail
	var frame: Image = Image.create_empty(source.get_width() + 2 * pad.x, source.get_height() + 2 * pad.y, false, Image.FORMAT_RGBA8)
	frame.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), pad)
	var m: Dictionary = _measure(frame, anim, col, count)
	if m.is_empty():
		return frame
	var size: Vector2i = Vector2i(Vector2(frame.get_size()) / float(detail))
	var behind: Canvas = Canvas.new(size.x, size.y, detail)
	var front: Canvas = Canvas.new(size.x, size.y, detail)
	var inlay: Canvas = Canvas.new(size.x, size.y, detail)
	call(String(DECOR[id]), behind, front, inlay, m)
	var out: Image = behind.finish()
	out.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i.ZERO)
	var over: Image = front.finish()
	out.blend_rect(over, Rect2i(Vector2i.ZERO, over.get_size()), Vector2i.ZERO)
	var masked: Image = inlay.image
	for y: int in masked.get_height():
		for x: int in masked.get_width():
			if masked.get_pixel(x, y).a > 0.0 and frame.get_pixel(x, y).a > 0.8:
				out.set_pixel(x, y, masked.get_pixel(x, y))
	return out


## Where the body is, in art px: its box, the middle of its top, which way it faces, and where in the cycle.
func _measure(frame: Image, anim: String, col: int, count: int) -> Dictionary:
	var first: int = 1 << 30
	var last: int = -1
	var left: int = 1 << 30
	var right: int = -1
	for y: int in frame.get_height():
		for x: int in frame.get_width():
			if frame.get_pixel(x, y).a > 0.8:
				first = mini(first, y)
				last = maxi(last, y)
				left = mini(left, x)
				right = maxi(right, x)
	if last < 0:
		return {}
	var sum: float = 0.0
	var n: int = 0
	for y: int in range(first, mini(first + 3 * detail, last + 1)):
		for x: int in range(left, right + 1):
			if frame.get_pixel(x, y).a > 0.8:
				sum += x
				n += 1
	var d: float = float(detail)
	var facing: String = "side" if anim.ends_with("_side") else ("up" if anim.ends_with("_up") else "down")
	return {"left": left / d, "right": (right + 1) / d, "top": first / d, "bottom": (last + 1) / d, "top_x": sum / maxf(n, 1.0) / d,
		"cx": (left + right + 1) / 2.0 / d, "width": (right + 1 - left) / d, "height": (last + 1 - first) / d, "facing": facing,
		"state": anim.get_slice("_", 0), "phase": float(col) / maxf(count, 1.0), "col": col, "seed": hash("%s%d" % [anim, col]), "frame": frame}


# ---------------------------------------------------------------- shared shapes

## A flame tongue rooted at `base`, `h` tall, swaying with the cycle (soft: no outline).
func _flame(c: Canvas, base: Vector2, h: float, w: float, phase: float) -> void:
	var sway: float = sin(phase * TAU + base.x * 0.7) * 1.1
	c.part(true)
	c.polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(w, 0), base + Vector2(sway * 0.6 + w * 0.3, -h * 0.6), base + Vector2(sway, -h)]), FLAME.slice(0, 3), Vector3(0, 0, 1))
	c.part(true)
	c.polygon(PackedVector2Array([base + Vector2(-w * 0.55, 0), base + Vector2(w * 0.55, 0), base + Vector2(sway * 0.7, -h * 0.72)]), FLAME.slice(2, 4), Vector3(0, 0, 1))
	c.part(true)
	c.polygon(PackedVector2Array([base + Vector2(-w * 0.25, 0), base + Vector2(w * 0.25, 0), base + Vector2(sway * 0.5, -h * 0.4)]), FLAME.slice(3, 5), Vector3(0, 0, 1))


## An ice crystal growing from `base` toward `direction` (a unit vector), two lit facets.
func _shard(c: Canvas, base: Vector2, direction: Vector2, length: float, width: float) -> void:
	var side: Vector2 = Vector2(-direction.y, direction.x)
	var tip: Vector2 = base + direction * length
	var waist: Vector2 = base + direction * length * 0.35
	c.part()
	c.polygon(PackedVector2Array([base, waist + side * width, tip]), CRYSTAL, Vector3(-0.7, -0.5, 0.6))
	c.part()
	c.polygon(PackedVector2Array([base, waist - side * width, tip]), CRYSTAL, Vector3(0.5, 0.4, 0.4))


## A tuft of straw: `count` strands fanning out from `from` around `direction`.
func _straw(c: Canvas, from: Vector2, direction: Vector2, length: float, count: int) -> void:
	for i: int in count:
		var spread: float = (i - (count - 1) / 2.0) * 0.38
		var strand: Vector2 = direction.rotated(spread) * (length * (0.8 + 0.2 * (i % 2)))
		c.part()
		c.capsule(from, from + strand, 0.55, STRAW, 0.05)


## A glow behind the figure: three stepped rings, brighter toward the middle (soft).
func _glow(c: Canvas, at: Vector2, radius: Vector2, color: Color) -> void:
	for i: int in 3:
		c.part(true)
		c.ellipse(at, radius * (1.0 - i * 0.3), [Color(color.r, color.g, color.b, color.a * (0.45 + 0.35 * i))], 0.0, 0.0)


## A rim of `color` on every upward-facing edge of the body (snow, frost): the body pixels whose neighbour
## above is empty, one art px thick, some of them left bare.
func _cap(inlay: Canvas, m: Dictionary, color: Color, chance: float, seed_value: int) -> void:
	var frame: Image = m["frame"]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var d: int = detail
	for y: int in range(d, frame.get_height()):
		for x: int in frame.get_width():
			if frame.get_pixel(x, y).a > 0.8 and frame.get_pixel(x, y - d).a < 0.5 and x % d == 0 and y % d == 0 and rng.randf() < chance:
				inlay.part(true)
				inlay.px(int(x / float(d)), int(y / float(d)), color)


# ---------------------------------------------------------------- the variants

## Cinder Ghoul: burning. Flames on its head and shoulders, glowing cracks in its skin, rising embers.
func _cinder_ghoul(behind: Canvas, front: Canvas, inlay: Canvas, m: Dictionary) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9
	var top: float = m["top"]
	var tx: float = m["top_x"]
	var phase: float = m["phase"]
	_glow(behind, Vector2(m["cx"], top + m["height"] * 0.5), Vector2(m["width"] * 0.62, m["height"] * 0.55), Color(1.0, 0.45, 0.1, 0.3))
	for k: int in 3:
		_flame(front, Vector2(tx + (k - 1) * 2.2, top + 2.5), 4.5 + 2.5 * (1.0 if k == 1 else 0.6) + sin(phase * TAU + k * 2.1) * 1.2, 1.5, phase + k * 0.3)
	if m["facing"] == "side":
		_flame(front, Vector2(m["left"] + 3.0, top + 7.0), 4.0, 1.4, phase + 0.5)
	else:
		_flame(front, Vector2(m["left"] + 3.0, top + 7.5), 3.6, 1.3, phase + 0.2)
		_flame(front, Vector2(m["right"] - 3.0, top + 7.5), 3.6, 1.3, phase + 0.7)
	for k: int in 4:
		var x: float = tx + rng.randf_range(-5.0, 5.0)
		var y: float = top + 6.0 + k * 3.2
		inlay.part(true)
		inlay.line(Vector2(x, y), Vector2(x + 1.5, y + 2.2), FLAME[3])
		inlay.line(Vector2(x + 1.5, y + 2.2), Vector2(x + 0.5, y + 4.0), FLAME[2])
	for k: int in 3:
		var rise: float = fmod(phase + k * 0.34, 1.0)
		front.part(true)
		front.px(roundi(tx + (k - 1) * 3.0 + sin(rise * TAU) * 1.5), roundi(top - 1.0 - rise * 7.0), FLAME[3 if rise < 0.5 else 2])


## Scarecrow: a straw hat, straw bursting from its sleeves and neck, stitched patches.
func _scarecrow(behind: Canvas, front: Canvas, inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var tx: float = m["top_x"]
	var cx: float = m["cx"]
	# Straw behind the shoulders and around the neck.
	if m["facing"] == "side":
		_straw(behind, Vector2(m["left"] + 5.0, top + 11.0), Vector2(-1.0, -0.3), 5.5, 4)
		_straw(behind, Vector2(m["left"] + 4.0, top + 22.0), Vector2(-0.5, 1.0), 4.5, 3)
	else:
		_straw(front, Vector2(m["left"] + 6.0, top + 13.0), Vector2(-1.0, -0.2), 6.0, 4)
		_straw(front, Vector2(m["right"] - 6.0, top + 13.0), Vector2(1.0, -0.2), 6.0, 4)
		_straw(front, Vector2(m["left"] + 4.0, top + 25.0), Vector2(-0.4, 1.0), 4.5, 3)
		_straw(front, Vector2(m["right"] - 4.0, top + 25.0), Vector2(0.4, 1.0), 4.5, 3)
	# The hat: a wide drooping brim, a rounded battered crown with a dark band and a ragged edge.
	front.part()
	front.ellipse(Vector2(tx, top + 3.4), Vector2(10.5, 3.0), STRAW, 0.25, -0.05)
	front.part()
	front.ellipse(Vector2(tx, top + 0.2), Vector2(5.6, 4.4), STRAW, 0.0, 0.05)
	front.part()
	front.rect(Rect2i(roundi(tx - 5.0), roundi(top + 1.5), 10, 1), P.LEATHER[2])
	front.rect(Rect2i(roundi(tx + 1.0), roundi(top - 3.5), 2, 2), STRAW[1])
	for k: int in 4:
		front.line(Vector2(tx - 10.0 + k * 1.1, top + 5.0), Vector2(tx - 11.5 + k * 1.1, top + 7.2), STRAW[3])
		front.line(Vector2(tx + 10.0 - k * 1.1, top + 5.0), Vector2(tx + 11.5 - k * 1.1, top + 7.2), STRAW[3])
	# Stitched patches on the torso.
	for patch: Vector2 in [Vector2(cx - 3.0, top + 16.0), Vector2(cx + 3.5, top + 21.0)]:
		inlay.part(true)
		inlay.rect(Rect2i(roundi(patch.x), roundi(patch.y), 3, 3), P.LEATHER[2])
		inlay.line(patch + Vector2(0, 0), patch + Vector2(3, 3), P.LEATHER[0], true)
		inlay.line(patch + Vector2(3, 0), patch + Vector2(0, 3), P.LEATHER[0], true)


## Frost Wraith: a crown of ice shards, shards on the shoulders, icicles along the hem, drifting mist.
func _frost_wraith(behind: Canvas, front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var tx: float = m["top_x"]
	var bottom: float = m["bottom"]
	_glow(behind, Vector2(m["cx"], top + m["height"] * 0.55), Vector2(m["width"] * 0.7, m["height"] * 0.58), Color(0.5, 0.8, 1.0, 0.26))
	_shard(front, Vector2(tx - 1.6, top + 3.0), Vector2(-0.45, -0.9).normalized(), 5.0, 1.2)
	_shard(front, Vector2(tx, top + 2.0), Vector2(0.0, -1.0), 7.0, 1.4)
	_shard(front, Vector2(tx + 1.6, top + 3.0), Vector2(0.45, -0.9).normalized(), 5.0, 1.2)
	if m["facing"] != "side":
		_shard(front, Vector2(m["left"] + 3.0, top + 11.0), Vector2(-0.6, -0.8).normalized(), 4.5, 1.1)
		_shard(front, Vector2(m["right"] - 3.0, top + 11.0), Vector2(0.6, -0.8).normalized(), 4.5, 1.1)
	else:
		_shard(front, Vector2(m["left"] + 4.0, top + 11.0), Vector2(-0.6, -0.8).normalized(), 4.5, 1.1)
	var x: float = m["left"] + 2.0
	var k: int = 0
	while x < m["right"] - 1.5:
		front.part()
		var hang: float = 2.0 + float((k * 7) % 3)
		front.polygon(PackedVector2Array([Vector2(x - 1.0, bottom - 2.0), Vector2(x + 1.0, bottom - 2.0), Vector2(x, bottom - 2.0 + hang)]), CRYSTAL, Vector3(-0.5, -0.4, 0.8))
		x += 3.2
		k += 1


## Rime Brute: great ice spikes through its back and shoulders, a cap of snow on every upper surface.
func _rime_brute(behind: Canvas, _front: Canvas, inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var cx: float = m["cx"]
	if m["facing"] == "side":
		_shard(behind, Vector2(m["left"] + 5.0, top + 14.0), Vector2(-0.75, -0.65).normalized(), 12.0, 2.3)
		_shard(behind, Vector2(m["left"] + 9.0, top + 10.0), Vector2(-0.35, -0.95).normalized(), 14.0, 2.5)
		_shard(behind, Vector2(m["left"] + 13.0, top + 8.0), Vector2(0.0, -1.0), 10.0, 2.0)
	else:
		_shard(behind, Vector2(m["left"] + 4.0, top + 15.0), Vector2(-0.7, -0.7).normalized(), 12.0, 2.4)
		_shard(behind, Vector2(m["right"] - 4.0, top + 15.0), Vector2(0.7, -0.7).normalized(), 12.0, 2.4)
		_shard(behind, Vector2(cx - 6.0, top + 9.0), Vector2(-0.35, -0.95).normalized(), 12.0, 2.2)
		_shard(behind, Vector2(cx + 6.0, top + 9.0), Vector2(0.35, -0.95).normalized(), 12.0, 2.2)
	_cap(inlay, m, CRYSTAL[4], 0.75, 4)
	_cap(inlay, m, CRYSTAL[3], 0.9, 5)


## Burrower: half out of the ground, in a low mound of loose soil, dirt flying off its back.
func _burrower(_behind: Canvas, front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var bottom: float = m["bottom"]
	var cx: float = m["cx"]
	var w: float = m["width"]
	var phase: float = m["phase"]
	front.part()
	front.ellipse(Vector2(cx, bottom - 1.8), Vector2(w * 0.36, 2.6), SOIL, 0.1, 0.05)
	for k: int in 4:
		var x: float = cx - w * 0.3 + k * (w * 0.6 / 3.0)
		front.part()
		front.ellipse(Vector2(x, bottom - 3.4 - float((k * 5) % 3) * 0.5), Vector2(1.6, 1.2), SOIL, 0.0, 0.1)
	for k: int in 3:
		var fall: float = fmod(phase + k * 0.33, 1.0)
		front.part(true)
		front.px(roundi(cx + (k - 1) * 4.0), roundi(bottom - 8.0 + fall * 6.0), SOIL[3])


## A bone: a shaft with a knob at each end.
func _bone(c: Canvas, from: Vector2, to: Vector2, thickness: float) -> void:
	var along: Vector2 = (to - from).normalized()
	var across: Vector2 = Vector2(-along.y, along.x)
	c.part()
	c.capsule(from, to, thickness, P.BONE, 0.1)
	for end: Vector2 in [from, to]:
		c.part()
		c.ellipse(end + across * thickness * 0.5, Vector2(thickness * 1.15, thickness * 1.15), P.BONE, 0.0, 0.1)
		c.ellipse(end - across * thickness * 0.5, Vector2(thickness * 1.15, thickness * 1.15), P.BONE, 0.0, 0.0)


## A leaf cluster: a few overlapping green lobes.
func _leaves(c: Canvas, at: Vector2, size: float) -> void:
	for k: int in 4:
		var lobe: Vector2 = at + Vector2(cos(k * 1.7) * size * 0.6, sin(k * 2.3) * size * 0.5)
		c.part()
		c.ellipse(lobe, Vector2(size * 0.7, size * 0.55), P.MOSS if k % 2 == 0 else P.HOOD, 0.0, 0.1 * k)


## Lamp Wight: its lantern burns bright (a wide warm glow), a second hangs at its belt, wisps of light hang about it.
func _lamp_wight(behind: Canvas, front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var h: float = m["height"]
	var lamp: Vector2 = Vector2(m["right"] - 1.5, top + h * 0.38)
	_glow(behind, lamp, Vector2(9.0, 9.0), Color(1.0, 0.78, 0.3, 0.3))
	front.part(true)
	front.ellipse(lamp, Vector2(1.8, 1.8), P.FIRE.slice(3, 6), 0.0, 0.2)
	var belt: Vector2 = Vector2(m["cx"] + (2.5 if m["facing"] == "side" else 0.0), top + h * 0.64)
	front.part()
	front.line(belt + Vector2(0, -3.0), belt, P.LEATHER[1])
	front.part()
	front.rect(Rect2i(roundi(belt.x - 1.5), roundi(belt.y), 3, 4), P.BRONZE[2])
	front.part(true)
	front.rect(Rect2i(roundi(belt.x - 0.5), roundi(belt.y + 1.0), 1, 2), P.FIRE[4])
	_glow(behind, belt + Vector2(0, 2.0), Vector2(4.5, 4.5), Color(1.0, 0.75, 0.3, 0.26))


## Bone Hurler: ribs on its chest, a skull at its belt, a long bone raised to throw.
func _bone_hurler(_behind: Canvas, front: Canvas, inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var cx: float = m["cx"]
	var h: float = m["height"]
	var swing: float = sin(m["phase"] * TAU) * 0.35
	var hand: Vector2 = Vector2(cx + (5.0 if m["facing"] != "side" else 6.5), top + h * 0.55)
	_bone(front, hand + Vector2(-1.0, 1.5), hand + Vector2(2.0, -6.0).rotated(swing), 0.85)
	for k: int in 3:
		inlay.part(true)
		inlay.line(Vector2(cx - 3.0, top + h * 0.40 + k * 2.0), Vector2(cx + 3.0, top + h * 0.40 + k * 2.0 + 0.6), P.BONE[3])
	front.part()
	front.ellipse(Vector2(cx - 4.0, top + h * 0.7), Vector2(1.9, 1.7), P.BONE, 0.0, 0.1)
	front.part()
	front.rect(Rect2i(roundi(cx - 5.0), roundi(top + h * 0.7), 1, 1), P.CULT_DARK[0])
	front.rect(Rect2i(roundi(cx - 3.0), roundi(top + h * 0.7), 1, 1), P.CULT_DARK[0])


## Rubble Brute: boulders of quarry stone on its shoulders and back, cracks through its skin, dust at its feet.
func _rubble_brute(behind: Canvas, front: Canvas, inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var cx: float = m["cx"]
	if m["facing"] == "side":
		behind.part()
		behind.ellipse(Vector2(m["left"] + 9.0, top + 6.0), Vector2(7.0, 5.5), P.STONE_WARM, 0.0, 0.05)
		front.part()
		front.ellipse(Vector2(m["left"] + 12.0, top + 7.5), Vector2(4.5, 3.6), P.STONE_WARM, 0.0, 0.1)
		front.part()
		front.ellipse(Vector2(m["left"] + 7.0, top + 10.0), Vector2(3.4, 3.0), P.STONE_WARM, 0.0, 0.0)
	else:
		for way: float in [-1.0, 1.0]:
			var shoulder: Vector2 = Vector2(cx + way * (m["width"] * 0.34), top + 9.0)
			front.part()
			front.ellipse(shoulder, Vector2(5.2, 4.2), P.STONE_WARM, 0.0, 0.05)
			front.part()
			front.ellipse(shoulder + Vector2(way * 1.8, -2.4), Vector2(3.0, 2.4), P.STONE_WARM, 0.0, 0.15)
			front.part()
			front.ellipse(shoulder + Vector2(-way * 2.4, 2.6), Vector2(2.2, 1.9), P.STONE_WARM, 0.0, -0.05)
	for k: int in 3:
		inlay.part(true)
		var x: float = cx - 4.0 + k * 4.0
		inlay.line(Vector2(x, top + 14.0 + k), Vector2(x + 1.5, top + 17.0 + k), P.STONE[0])
		inlay.line(Vector2(x + 1.5, top + 17.0 + k), Vector2(x - 0.5, top + 20.0 + k), P.STONE[1])
	for k: int in 3:
		var drift: float = fmod(m["phase"] + k * 0.33, 1.0)
		front.part(true)
		front.px(roundi(cx + (k - 1) * 6.0 + drift * 2.0), roundi(m["bottom"] - 2.0 - drift * 3.0), Color(0.75, 0.72, 0.65, 0.65))


## Stalker: moss on its back, shadow trailing behind it, a pair of extra glowing eyes in the dark of its head.
func _stalker(behind: Canvas, front: Canvas, inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var phase: float = m["phase"]
	var tail: float = m["left"] if m["facing"] == "side" else m["cx"]
	for k: int in 4:
		var drift: float = fmod(phase + k * 0.25, 1.0)
		behind.part(true)
		behind.ellipse(Vector2(tail - 1.0 - drift * 9.0, top + 9.0 + sin(k * 2.0 + phase * TAU) * 2.5), Vector2(3.4 - drift * 2.2, 2.2 - drift * 1.4), [Color(0.03, 0.08, 0.06, 0.5 * (1.0 - drift))], 0.0, 0.0)
	for k: int in 3:
		front.part()
		front.ellipse(Vector2(m["cx"] - 3.0 + k * 3.0, top + 2.5 + absf(k - 1.0) * 0.8), Vector2(1.9, 1.3), P.MOSS, 0.0, 0.1)
	for k: int in 4:
		inlay.part(true)
		inlay.px(roundi(m["cx"] - 5.0 + k * 3.0), roundi(top + 5.0 + (k % 2)), P.MOSS[2])


## Hollow Treant: branches in leaf from its shoulders and head, a glowing hollow in its trunk, roots at its feet.
func _hollow_treant(behind: Canvas, front: Canvas, inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var cx: float = m["cx"]
	var sway: float = sin(m["phase"] * TAU) * 0.8
	var tx: float = m["top_x"]
	var sides: Array[float] = [-1.0, 1.0]
	if m["facing"] == "side":
		sides = [-1.0]
	for way: float in sides:
		var root: Vector2 = Vector2(cx + way * (m["width"] * 0.34), top + 11.0)
		var tip: Vector2 = root + Vector2(way * 7.0 + sway, -9.0)
		behind.part()
		behind.capsule(root, tip, 1.5, P.WOOD, 0.05)
		behind.capsule(root + (tip - root) * 0.5, tip + Vector2(way * 3.0, -3.0), 0.9, P.WOOD, 0.05)
		_leaves(behind, tip + Vector2(way * 2.0, -1.5), 3.4)
	_leaves(front, Vector2(tx, top + 0.5), 4.4)
	_leaves(front, Vector2(tx - 3.5, top + 2.0), 3.0)
	_leaves(front, Vector2(tx + 3.5, top + 2.5), 3.0)
	inlay.part(true)
	inlay.ellipse(Vector2(cx, top + m["height"] * 0.52), Vector2(2.7, 3.5), [P.WOOD[0], Color("0a1608")], 0.0, 0.0)
	inlay.ellipse(Vector2(cx, top + m["height"] * 0.55), Vector2(1.0, 1.6), P.EYES_RANGED.slice(0, 3), 0.0, 0.1)
	for way: float in [-1.0, 1.0]:
		front.part()
		front.capsule(Vector2(cx + way * 4.0, m["bottom"] - 3.0), Vector2(cx + way * 11.0, m["bottom"] - 0.8), 1.1, P.WOOD, 0.0)


## Chorister: a halo over its head, gold trim at collar and hem, a candle-bright glow.
func _chorister(behind: Canvas, front: Canvas, inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var tx: float = m["top_x"]
	var bob: float = sin(m["phase"] * TAU) * 0.5
	front.part(true)
	for a: int in 24:
		var t: float = a * TAU / 24.0
		front.px(roundi(tx + cos(t) * 6.0), roundi(top - 4.2 + bob + sin(t) * 1.9), P.GOLD[4 if sin(t) < -0.3 else 3])
		front.px(roundi(tx + cos(t) * 6.0), roundi(top - 3.2 + bob + sin(t) * 1.9), P.GOLD[1])
	_glow(behind, Vector2(tx, top - 3.0 + bob), Vector2(9.0, 4.5), Color(1.0, 0.9, 0.5, 0.26))
	inlay.part(true)
	inlay.rect(Rect2i(roundi(m["left"]), roundi(m["bottom"] - 4.0), roundi(m["width"]), 1), P.GOLD[2])
	inlay.rect(Rect2i(roundi(m["cx"] - 2.0), roundi(top + m["height"] * 0.34), 4, 1), P.GOLD[3])
	inlay.line(Vector2(m["cx"], top + m["height"] * 0.38), Vector2(m["cx"], m["bottom"] - 5.0), P.GOLD[2])


## Inquisitor: a tall black judge's hat with a gold band, wax seals hanging from its belt.
func _inquisitor(_behind: Canvas, front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var tx: float = m["top_x"]
	front.part()
	front.polygon(PackedVector2Array([Vector2(tx - 4.2, top + 2.0), Vector2(tx + 4.2, top + 2.0), Vector2(tx + 1.0, top - 9.0), Vector2(tx - 1.0, top - 9.0)]), P.IRON_WORN, Vector3(-0.4, -0.5, 1.0))
	front.part()
	front.rect(Rect2i(roundi(tx - 5.0), roundi(top), 10, 2), P.GOLD[2])
	front.part()
	front.ellipse(Vector2(tx, top + 2.2), Vector2(7.0, 1.6), P.IRON_WORN, 0.2, 0.0)
	var belt: float = top + m["height"] * 0.72
	for k: int in 3:
		front.part()
		front.line(Vector2(m["cx"] - 5.0 + k * 3.0, belt - 2.0), Vector2(m["cx"] - 5.0 + k * 3.0, belt + 1.0), P.LEATHER[2])
		front.part()
		front.ellipse(Vector2(m["cx"] - 5.0 + k * 3.0, belt + 2.0), Vector2(1.1, 1.3), P.BANNER, 0.0, 0.1)


## Black Knight: a tall red crest on its helm, a dark cloak streaming behind it.
func _black_knight(behind: Canvas, front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var tx: float = m["top_x"]
	var sway: float = sin(m["phase"] * TAU) * 0.9
	if m["facing"] == "side":
		behind.part()
		behind.polygon(PackedVector2Array([Vector2(m["left"] + 5.0, top + 9.0), Vector2(m["cx"], top + 9.0), Vector2(m["cx"] + 2.0, m["bottom"] - 1.0), Vector2(m["left"] - 3.0 + sway, m["bottom"] - 2.0)]), P.BANNER, Vector3(-0.2, -0.3, 1.0))
	else:
		for way: float in [-1.0, 1.0]:
			var edge: float = m["cx"] + way * (m["width"] * 0.5)
			behind.part()
			behind.polygon(PackedVector2Array([Vector2(edge - way * 4.0, top + 9.0), Vector2(edge + way * 0.5, top + 9.0), Vector2(edge + way * (3.5 + sway * 0.4), m["bottom"] - 1.0), Vector2(edge - way * 3.0, m["bottom"] - 2.0)]), P.BANNER, Vector3(-0.2, -0.3, 1.0))
	front.part()
	front.polygon(PackedVector2Array([Vector2(tx - 2.2, top + 2.0), Vector2(tx + 2.2, top + 2.0), Vector2(tx + 2.0, top - 4.0), Vector2(tx - 0.5 - sway * 0.5, top - 8.0), Vector2(tx - 3.0 - sway, top - 6.0), Vector2(tx - 2.4, top - 1.0)]), P.BANNER, Vector3(-0.4, -0.5, 1.0))
	front.part()
	front.line(Vector2(tx - 0.5, top + 1.0), Vector2(tx - 1.5 - sway * 0.5, top - 5.5), P.BANNER[4])


## Siege Ram: it carries a battering ram, an iron-capped log across its arms.
func _siege_ram(_behind: Canvas, front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var h: float = m["height"]
	var y: float = top + h * 0.56
	var from: Vector2
	var to: Vector2
	if m["facing"] == "side":
		from = Vector2(m["left"] + 9.0, y + 2.0)
		to = Vector2(m["right"] + 7.0, y)
	else:
		from = Vector2(m["left"] - 4.0, y + 1.5)
		to = Vector2(m["right"] + 4.0, y - 1.0)
	front.part()
	front.capsule(from, to, 2.4, P.WOOD, 0.1)
	for t: float in [0.18, 0.5, 0.8]:
		var at: Vector2 = from.lerp(to, t)
		front.part()
		front.capsule(at + Vector2(0, -3.0), at + Vector2(0, 3.0), 0.9, P.IRON, 0.0)
	var head: Vector2 = to + (to - from).normalized() * 1.5
	front.part()
	front.ellipse(head, Vector2(3.4, 3.6), P.IRON_WORN, 0.0, 0.1)
	front.part()
	front.polygon(PackedVector2Array([head + Vector2(0, -3.0), head + Vector2(3.5, -6.0), head + Vector2(2.0, -1.0)]), P.IRON_WORN, Vector3(-0.3, -0.5, 1.0))
	front.polygon(PackedVector2Array([head + Vector2(0, 3.0), head + Vector2(3.5, 6.0), head + Vector2(2.0, 1.0)]), P.IRON_WORN, Vector3(-0.3, -0.5, 1.0))


## Where the staff's head is: the right edge, a little below the top (the Lich- and Gravelord-based bosses carry it right).
func _staff_head(m: Dictionary) -> Vector2:
	return Vector2(m["right"] - 1.5, m["top"] + 7.0)


## Pyre Warden: its crown is fire, its staff burns, embers rise off its hem.
func _pyre_warden(behind: Canvas, front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var tx: float = m["top_x"]
	var phase: float = m["phase"]
	_glow(behind, Vector2(tx, top + 6.0), Vector2(13.0, 12.0), Color(1.0, 0.5, 0.12, 0.28))
	for k: int in 5:
		var offset: float = (k - 2) * 2.3
		_flame(front, Vector2(tx + offset, top + 3.5), 7.0 + (3.0 if k % 2 == 0 else 0.0) - absf(k - 2.0) * 1.2 + sin(phase * TAU + k * 1.7) * 1.5, 1.7, phase + k * 0.2)
	var staff: Vector2 = _staff_head(m)
	_flame(front, staff + Vector2(0, 1.5), 7.0 + sin(phase * TAU) * 1.2, 2.0, phase + 0.4)
	for k: int in 5:
		var rise: float = fmod(phase + k * 0.21, 1.0)
		front.part(true)
		front.px(roundi(tx - 8.0 + k * 4.0 + sin(rise * TAU + k) * 1.5), roundi(top - 3.0 - rise * 10.0), FLAME[3 if rise < 0.5 else 2])


## Winter Warden: a crown of ice, a great crystal on its staff, mist about its hem.
func _winter_warden(behind: Canvas, front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var tx: float = m["top_x"]
	_glow(behind, Vector2(tx, top + 12.0), Vector2(15.0, 17.0), Color(0.5, 0.8, 1.0, 0.22))
	for k: int in 5:
		var offset: float = (k - 2) * 2.4
		_shard(front, Vector2(tx + offset, top + 3.5), Vector2(offset * 0.12, -1.0).normalized(), 8.0 - absf(k - 2.0) * 1.6, 1.5)
	var staff: Vector2 = _staff_head(m)
	_shard(front, staff + Vector2(0, 1.0), Vector2(0.3, -1.0).normalized(), 9.0, 2.0)
	_shard(front, staff + Vector2(0, 1.0), Vector2(-0.8, -0.6).normalized(), 6.0, 1.4)
	var bottom: float = m["bottom"]
	for k: int in 7:
		var drift: float = fmod(m["phase"] + k * 0.17, 1.0)
		front.part(true)
		front.px(roundi(m["left"] + 2.0 + k * (m["width"] - 4.0) / 6.0), roundi(bottom - 1.0 - drift * 4.0), Color(0.85, 0.96, 1.0, 0.8 * (1.0 - drift)))


## Pale Bishop: a tall mitre with a gold cross over its crown, a halo and rays of pale light.
func _pale_bishop(behind: Canvas, front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var tx: float = m["top_x"]
	var bob: float = sin(m["phase"] * TAU) * 0.4
	for k: int in 7:
		var angle: float = -PI / 2.0 + (k - 3) * 0.32
		behind.part(true)
		behind.line(Vector2(tx, top + 4.0) + Vector2.from_angle(angle) * 8.0, Vector2(tx, top + 4.0) + Vector2.from_angle(angle) * 17.0, Color(1.0, 0.95, 0.7, 0.35))
	_glow(behind, Vector2(tx, top + 2.0), Vector2(11.0, 9.0), Color(1.0, 0.95, 0.7, 0.24))
	front.part()
	front.polygon(PackedVector2Array([Vector2(tx - 5.5, top + 5.0), Vector2(tx + 5.5, top + 5.0), Vector2(tx + 3.0, top - 7.0 + bob), Vector2(tx, top - 9.0 + bob), Vector2(tx - 3.0, top - 7.0 + bob)]), P.LICH_ROBE.slice(3, 6), Vector3(-0.4, -0.5, 1.0))
	front.part()
	front.rect(Rect2i(roundi(tx - 5.5), roundi(top + 3.0), 11, 2), P.GOLD[3])
	front.part()
	front.rect(Rect2i(roundi(tx - 0.5), roundi(top - 6.0 + bob), 1, 6), P.GOLD[3])
	front.rect(Rect2i(roundi(tx - 2.5), roundi(top - 3.5 + bob), 5, 1), P.GOLD[3])
	front.part(true)
	for a: int in 90:
		var t: float = a * TAU / 90.0
		front.px(roundi(tx + cos(t) * 7.5), roundi(top - 11.5 + bob + sin(t) * 2.2), P.GOLD[4 if sin(t) < -0.3 else 3])


## Deep Warden: stalactites hang from its gallows, teal runes glow on its robe, its bell drips.
func _deep_warden(_behind: Canvas, front: Canvas, inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var cx: float = m["cx"]
	for k: int in 6:
		var x: float = m["left"] + 4.0 + k * (m["width"] - 8.0) / 5.0
		front.part()
		front.polygon(PackedVector2Array([Vector2(x - 1.4, top + 2.0), Vector2(x + 1.4, top + 2.0), Vector2(x, top + 2.0 + 3.5 + float((k * 5) % 3) * 1.5)]), P.STONE, Vector3(-0.5, -0.4, 0.8))
	for k: int in 4:
		inlay.part(true)
		var y: float = top + m["height"] * 0.55 + k * 3.0
		inlay.line(Vector2(cx - 3.0, y), Vector2(cx + 3.0, y), Color("57e0c8"))
		inlay.px(roundi(cx + (k - 1.5) * 2.0), roundi(y - 1.0), Color("b8fff0"))
	for k: int in 3:
		var fall: float = fmod(m["phase"] + k * 0.33, 1.0)
		front.part(true)
		front.px(roundi(cx + (k - 1) * 3.0), roundi(top + 12.0 + fall * 12.0), Color(0.5, 0.9, 0.85, 0.9 * (1.0 - fall)))


## Quarry Colossus: boulders on its shoulders and back, glowing amber cracks through its limbs.
func _quarry_colossus(behind: Canvas, front: Canvas, inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var cx: float = m["cx"]
	if m["facing"] == "side":
		behind.part()
		behind.ellipse(Vector2(m["left"] + 12.0, top + 10.0), Vector2(11.0, 8.0), P.STONE_WARM, 0.0, 0.0)
		front.part()
		front.ellipse(Vector2(m["left"] + 17.0, top + 12.0), Vector2(6.0, 5.0), P.STONE_WARM, 0.0, 0.1)
	else:
		for way: float in [-1.0, 1.0]:
			var shoulder: Vector2 = Vector2(cx + way * (m["width"] * 0.36), top + 12.0)
			front.part()
			front.ellipse(shoulder, Vector2(7.0, 5.5), P.STONE_WARM, 0.0, 0.05)
			front.part()
			front.ellipse(shoulder + Vector2(way * 2.5, -3.5), Vector2(4.0, 3.2), P.STONE_WARM, 0.0, 0.15)
	for k: int in 5:
		inlay.part(true)
		var x: float = cx - 9.0 + k * 4.5
		var y: float = top + 18.0 + float((k * 7) % 4) * 3.0
		inlay.line(Vector2(x, y), Vector2(x + 2.0, y + 3.0), FLAME[2])
		inlay.line(Vector2(x + 2.0, y + 3.0), Vector2(x + 0.5, y + 6.0), FLAME[3])


## Hollow Stag: great branching antlers of bone and wood grow from its skull, tipped with green fire; moss in its shroud.
func _hollow_stag(behind: Canvas, front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var tx: float = m["top_x"]
	var sway: float = sin(m["phase"] * TAU) * 0.5
	_glow(behind, Vector2(tx, top - 3.0), Vector2(17.0, 12.0), Color(0.45, 1.0, 0.5, 0.2))
	front.part()
	front.ellipse(Vector2(tx, top + 3.5), Vector2(6.0, 1.8), P.WOOD, 0.2, 0.05)  # a ring of wood over the old crown
	for k: int in 4:
		_leaves(front, Vector2(tx - 4.5 + k * 3.0, top + 3.0 + (k % 2)), 1.5)
	for way: float in [-1.0, 1.0]:
		var base: Vector2 = Vector2(tx + way * 3.5, top + 4.0)
		var beam: Vector2 = base + Vector2(way * 8.0, -11.0 + sway)
		behind.part()
		behind.capsule(base, beam, 1.9, P.WOOD, 0.1)
		behind.capsule(beam, beam + Vector2(way * 3.5, -5.0), 1.3, P.WOOD, 0.1)
		for tine: int in 3:
			var at: Vector2 = base.lerp(beam, 0.3 + tine * 0.27)
			var tip: Vector2 = at + Vector2(way * (3.0 + tine * 1.2), -7.5 + tine * 1.0)
			behind.part()
			behind.capsule(at, tip, 1.15 - tine * 0.15, P.BONE, 0.1)
			front.part(true)
			front.px(roundi(tip.x), roundi(tip.y - 0.5), P.EYES_RANGED[3])
			front.px(roundi(tip.x), roundi(tip.y - 1.5), P.EYES_RANGED[2])
	for k: int in 4:
		_leaves(front, Vector2(m["left"] + 5.0 + k * (m["width"] - 10.0) / 3.0, top + m["height"] * 0.42 + (k % 2) * 3.0), 2.2)


## Fallen Marshal: a broken crown, a tattered banner on its back, a streaming rag of red cloak.
func _fallen_marshal(behind: Canvas, _front: Canvas, _inlay: Canvas, m: Dictionary) -> void:
	var top: float = m["top"]
	var sway: float = sin(m["phase"] * TAU) * 1.4
	var pole_x: float = m["left"] + 6.0 if m["facing"] == "side" else m["right"] - 5.0
	behind.part()
	behind.capsule(Vector2(pole_x, top + 22.0), Vector2(pole_x, top - 8.0), 0.8, P.WOOD, 0.0)
	behind.part()
	behind.polygon(PackedVector2Array([Vector2(pole_x, top - 7.0), Vector2(pole_x - 11.0 + sway, top - 5.0), Vector2(pole_x - 8.0 + sway, top - 2.0), Vector2(pole_x - 12.0 + sway * 1.3, top + 1.5), Vector2(pole_x - 7.0 + sway, top + 4.0), Vector2(pole_x, top + 5.0)]), P.BANNER, Vector3(-0.4, -0.4, 1.0))
	var back_x: float = m["left"] + 2.0 if m["facing"] == "side" else m["cx"]
	var wide: float = m["width"] * (0.35 if m["facing"] == "side" else 0.45)
	behind.part()
	behind.polygon(PackedVector2Array([Vector2(back_x - wide, top + 12.0), Vector2(back_x + wide, top + 12.0), Vector2(back_x + wide + sway * 0.5, m["bottom"] - 8.0), Vector2(back_x + wide * 0.4, m["bottom"] - 3.0 + sway), Vector2(back_x, m["bottom"] - 8.0), Vector2(back_x - wide * 0.5, m["bottom"] - 2.0), Vector2(back_x - wide - sway * 0.5, m["bottom"] - 9.0)]), P.BANNER, Vector3(-0.2, -0.3, 1.0))
