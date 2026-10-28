class_name PropKit
## The building blocks the maps' props are drawn from (M15 P4): rocks, trees, stumps, posts, barrels, crystals, bones,
## banners, pillars and so on, each painted (shaded, outlined) and parameterised by colour, so a prop is a few calls. Props
## stand with their feet at (0, 0) in a 64x96 cell. Static; drawing only.

const INK: Color = Color("1a141f")
const WOOD: Color = Color("5a3d2a")
const WOOD_LIGHT: Color = Color("7d5638")
const IRON: Color = Color("2c2f38")
const IRON_LIGHT: Color = Color("5a5f6e")
const STONE: Color = Color("8a919c")
const STONE_WARM: Color = Color("918778")
const BONE: Color = Color("e8dcc0")
const SNOW: Color = Color("e6f0fa")
const MOSS: Color = Color("4f7040")
const EMBER: Color = Color("ff8a30")


static func shadow(ci: CanvasItem, rx: float = 18.0, ry: float = 6.0) -> void:
	VectorStyle.shadow(ci, Vector2(0, 1), rx, ry)


static func moss_tuft(ci: CanvasItem, at: Vector2, size: float = 1.0, color: Color = MOSS) -> void:
	for k: int in 3:
		VectorPaint.strand(ci, at + Vector2(k * 1.6 - 1.6, 0), at + Vector2(k * 2.0 - 2.0, -2.0 * size), at + Vector2(k * 2.6 - 2.6, -4.2 * size), 1.4, Color(color, 0.95))


## A faceted rock: a lumpy polygon around `at`, wider than tall, lit from the top-left.
static func rock(ci: CanvasItem, at: Vector2, r: float, color: Color, seed_value: int = 1, snow_cap: bool = false) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value * 7 + int(r)
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		var a: float = PI + i * PI * 1.0 / 8.0 if i < 9 else 0.0
		var lump: float = rng.randf_range(0.8, 1.1)
		pts.append(at + Vector2(cos(a) * r * lump, -absf(sin(a)) * r * 0.9 * lump))
	pts.append(at + Vector2(r * 0.95, 0))
	pts.append(at + Vector2(-r * 0.95, 0))
	VectorPaint.painted(ci, pts, color, r * 0.4, 0.5, 1.2)
	if snow_cap:
		VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-r * 0.7, -r * 0.6), at + Vector2(-r * 0.2, -r * 0.95), at + Vector2(r * 0.5, -r * 0.8), at + Vector2(r * 0.7, -r * 0.5), at + Vector2(0, -r * 0.45)]), SNOW, r * 0.15, 0.3, 0.0)


static func stump(ci: CanvasItem, at: Vector2, w: float, h: float, wood: Color = WOOD) -> void:
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-w, 0), at + Vector2(w, 0), at + Vector2(w * 0.85, -h), at + Vector2(-w * 0.85, -h)]), wood, 3.0, 0.4, 1.3)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -h), w * 0.88, w * 0.4, 18), wood.lightened(0.2), 1.6, 0.4, 1.2)
	for r: float in [0.65, 0.4]:
		ci.draw_arc(at + Vector2(0, -h), w * 0.85 * r, 0.0, TAU, 14, Color(wood, 0.9), 0.8, true)
	for root: float in [-1.0, 1.0]:
		VectorPaint.strand(ci, at + Vector2(root * w * 0.8, -2), at + Vector2(root * w * 1.2, 0), at + Vector2(root * w * 1.7, 2.5), 3.0, wood)


## A bare, twisted tree: a trunk with `branches` curving outward and a few twigs; `crown` adds leaf clumps.
static func dead_tree(ci: CanvasItem, height: float, wood: Color = WOOD, crown: Color = Color(0, 0, 0, 0), snowy: bool = false) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(3.4, -height * 0.45), Vector2(-3.4, -height * 0.45)]), wood, 3.0, 0.4, 1.4)
	for root: float in [-1.0, 1.0]:
		VectorPaint.strand(ci, Vector2(root * 3, -3), Vector2(root * 9, 0), Vector2(root * 15, 3), 4.0, wood)
	var branches: Array = [
		[Vector2(-2, -height * 0.4), Vector2(-14, -height * 0.5), Vector2(-24, -height * 0.78), 4.0],
		[Vector2(2, -height * 0.43), Vector2(10, -height * 0.6), Vector2(20, -height * 0.9), 4.0],
		[Vector2(0, -height * 0.5), Vector2(-2, -height * 0.66), Vector2(-6, -height), 3.4],
		[Vector2(-10, -height * 0.52), Vector2(-20, -height * 0.6), Vector2(-27, -height * 0.7), 2.4],
		[Vector2(8, -height * 0.62), Vector2(18, -height * 0.68), Vector2(25, -height * 0.78), 2.2],
	]
	for b: Array in branches:
		VectorPaint.strand(ci, b[0], b[1], b[2], float(b[3]), wood)
		VectorPaint.strand(ci, b[0] + Vector2(-1, 0), b[1] + Vector2(-1, 0), b[2], float(b[3]) * 0.4, wood.lightened(0.2))
		if crown.a > 0.0:
			VectorPaint.painted(ci, VectorStyle.ellipse(b[2], 7.0, 5.4, 12), crown, 2.0, 0.4, 1.0)
		if snowy:
			VectorPaint.strand(ci, b[0].lerp(b[2], 0.3) + Vector2(0, -2.2), b[1] + Vector2(0, -2.4), b[2] + Vector2(0, -1.6), 2.2, SNOW)
	ci.draw_colored_polygon(VectorStyle.ellipse(Vector2(0, -height * 0.3), 2.0, 3.4, 10), Color(0.04, 0.03, 0.05, 0.9))


## A pine: stacked tiers of boughs, optionally under snow.
static func pine(ci: CanvasItem, height: float, needles: Color, snowy: bool) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(2.4, -10), Vector2(-2.4, -10)]), WOOD, 1.6, 0.4, 1.2)
	var tiers: int = 5
	for i: int in tiers:
		var y: float = -6.0 - i * (height - 14.0) / tiers
		var w: float = lerpf(21.0, 6.0, float(i) / tiers)
		var tier: PackedVector2Array = PackedVector2Array([Vector2(-w, y), Vector2(w, y), Vector2(w * 0.55, y - 9.0), Vector2(0, y - 15.0), Vector2(-w * 0.55, y - 9.0)])
		VectorPaint.painted(ci, tier, needles.darkened(i * 0.04), 3.2, 0.5, 1.2)
		if snowy:
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-w * 0.8, y - 1.0), Vector2(0, y - 14.0), Vector2(w * 0.8, y - 1.0), Vector2(w * 0.3, y - 4.0), Vector2(-w * 0.2, y - 2.0)]), SNOW, 1.2, 0.3, 0.0)


static func post(ci: CanvasItem, x: float, height: float, w: float = 2.6, wood: Color = WOOD) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(x - w, 0), Vector2(x + w, 0), Vector2(x + w * 0.8, -height), Vector2(x - w * 0.8, -height)]), wood, 2.0, 0.4, 1.2)
	VectorPaint.line(ci, Vector2(x - w * 0.6, -2), Vector2(x - w * 0.5, -height + 2), Color(1, 1, 1, 0.14), 1.0)


static func beam(ci: CanvasItem, a: Vector2, b: Vector2, w: float = 3.0, wood: Color = WOOD) -> void:
	ci.draw_line(a, b, Color(INK, 0.9), w + 1.6, true)
	ci.draw_line(a, b, wood, w, true)
	ci.draw_line(a + Vector2(0, -w * 0.3), b + Vector2(0, -w * 0.3), Color(1, 1, 1, 0.16), 0.8, true)


static func barrel(ci: CanvasItem, at: Vector2, w: float = 7.0, h: float = 12.0, wood: Color = WOOD_LIGHT) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -h * 0.5), w, h * 0.5, 16), wood, 2.4, 0.45, 1.3)
	for y: float in [-h * 0.25, -h * 0.75]:
		VectorPaint.line(ci, at + Vector2(-w * 0.9, y), at + Vector2(w * 0.9, y), IRON, 1.4)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -h * 0.95), w * 0.8, w * 0.3, 14), wood.lightened(0.15), 1.0, 0.3, 0.9)


static func crate(ci: CanvasItem, at: Vector2, size: float, wood: Color = WOOD_LIGHT) -> void:
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-size, 0), at + Vector2(size, 0), at + Vector2(size, -size * 1.5), at + Vector2(-size, -size * 1.5)]), wood, 2.0, 0.4, 1.3)
	VectorPaint.line(ci, at + Vector2(-size, -size * 0.75), at + Vector2(size, -size * 0.75), Color(INK, 0.5), 1.0)
	VectorPaint.line(ci, at + Vector2(-size, 0), at + Vector2(size, -size * 1.5), Color(INK, 0.45), 1.0)


static func slab(ci: CanvasItem, at: Vector2, w: float, h: float, color: Color) -> void:
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-w, 0), at + Vector2(w, 0), at + Vector2(w * 0.9, -h), at + Vector2(-w * 0.9, -h)]), color, 3.0, 0.5, 1.4)
	for row: int in maxi(int(h / 7.0), 1):
		VectorPaint.line(ci, at + Vector2(-w, -5.0 - row * 7.0), at + Vector2(w, -5.0 - row * 7.0), Color(INK, 0.4), 0.9)


static func pillar(ci: CanvasItem, at: Vector2, w: float, h: float, color: Color, broken: bool = false) -> void:
	var top: PackedVector2Array = PackedVector2Array([at + Vector2(-w, 0), at + Vector2(w, 0), at + Vector2(w * 0.85, -h), at + Vector2(-w * 0.85, -h)])
	if broken:
		top = PackedVector2Array([at + Vector2(-w, 0), at + Vector2(w, 0), at + Vector2(w * 0.85, -h * 0.8), at + Vector2(w * 0.3, -h), at + Vector2(-w * 0.2, -h * 0.74), at + Vector2(-w * 0.85, -h * 0.92)])
	VectorPaint.painted(ci, top, color, w * 0.5, 0.5, 1.4)
	for k: int in 3:
		VectorPaint.line(ci, at + Vector2(-w * 0.45 + k * w * 0.45, -3), at + Vector2(-w * 0.4 + k * w * 0.4, -h * 0.8), Color(INK, 0.22), 0.8)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-w * 1.25, 0), at + Vector2(w * 1.25, 0), at + Vector2(w * 1.1, -4), at + Vector2(-w * 1.1, -4)]), color.darkened(0.1), 1.0, 0.3, 1.0)


static func crystal(ci: CanvasItem, at: Vector2, h: float, color: Color, glow: bool = true) -> void:
	var w: float = h * 0.28
	var top: Vector2 = at + Vector2(0, -h)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-w, 0), at + Vector2(-w * 0.9, -h * 0.65), top, at + Vector2(w * 0.1, -h * 0.5), at + Vector2(w * 0.1, 0)]), color.lightened(0.12), 1.8, 0.5, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(w * 0.1, 0), at + Vector2(w * 0.1, -h * 0.5), top, at + Vector2(w * 0.95, -h * 0.55), at + Vector2(w, 0)]), color.darkened(0.15), 1.8, 0.4, 1.0)
	VectorPaint.line(ci, at + Vector2(-w * 0.4, -h * 0.2), at + Vector2(-w * 0.3, -h * 0.7), Color(1, 1, 1, 0.55), 0.9)
	if glow:
		VectorStyle.draw_glow(ci, color, at + Vector2(0, -h * 0.5), h * 0.9, 0.4)


static func bones(ci: CanvasItem, at: Vector2, scale_by: float = 1.0) -> void:
	for b: Array in [[Vector2(-7, 1), Vector2(7, 2)], [Vector2(-4, -2), Vector2(9, -5)], [Vector2(-9, -4), Vector2(2, -1)]]:
		ci.draw_line(at + b[0] * scale_by, at + b[1] * scale_by, Color(INK, 0.8), 3.4 * scale_by, true)
		ci.draw_line(at + b[0] * scale_by, at + b[1] * scale_by, BONE, 2.2 * scale_by, true)
		for p: Vector2 in b:
			ci.draw_circle(at + p * scale_by, 1.7 * scale_by, BONE, true, -1.0, true)
	skull(ci, at + Vector2(-2, -6) * scale_by, 5.0 * scale_by)


static func skull(ci: CanvasItem, at: Vector2, r: float) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -r * 0.5), r, r * 0.95, 14), BONE, r * 0.4, 0.6, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-r * 0.55, 0), at + Vector2(r * 0.55, 0), at + Vector2(r * 0.4, r * 0.5), at + Vector2(-r * 0.4, r * 0.5)]), BONE.darkened(0.1), 0.6, 0.3, 0.8)
	for x: float in [-0.4, 0.4]:
		ci.draw_circle(at + Vector2(x * r, -r * 0.5), r * 0.25, Color("1a1015"), true, -1.0, true)


static func banner_pole(ci: CanvasItem, height: float, cloth: Color, torn: bool, frozen: bool = false) -> void:
	post(ci, 0.0, height, 1.8)
	ci.draw_circle(Vector2(0, -height - 1), 1.6, VectorStyle.GOLD, true, -1.0, true)
	var top: float = -height + 4.0
	var cloth_pts: PackedVector2Array = PackedVector2Array([Vector2(1.8, top), Vector2(16, top + 1.0), Vector2(15, top + 14), Vector2(8, top + 18), Vector2(2, top + 15)])
	if torn:
		cloth_pts = PackedVector2Array([Vector2(1.8, top), Vector2(16, top + 1.0), Vector2(12, top + 7), Vector2(15, top + 12), Vector2(8, top + 11), Vector2(6, top + 19), Vector2(2, top + 14)])
	VectorPaint.painted(ci, cloth_pts, cloth, 2.0, 0.35, 1.0)
	if frozen:
		for k: int in 4:
			VectorPaint.fill(ci, PackedVector2Array([Vector2(3 + k * 3.4, top + 15), Vector2(5 + k * 3.4, top + 15), Vector2(4 + k * 3.4, top + 22 - k)]), Color("cfeeff"))


static func glow_mushroom(ci: CanvasItem, at: Vector2, h: float, cap: Color) -> void:
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-1.6, 0), at + Vector2(1.6, 0), at + Vector2(1.2, -h), at + Vector2(-1.2, -h)]), Color("d8e4d0"), 0.8, 0.3, 0.8)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-h * 0.5, -h), at + Vector2(-h * 0.35, -h - h * 0.5), at + Vector2(h * 0.35, -h - h * 0.5), at + Vector2(h * 0.5, -h)]), cap, h * 0.2, 0.5, 1.0)
	VectorStyle.draw_glow(ci, cap, at + Vector2(0, -h), h * 1.6, 0.45)


static func lamp_post(ci: CanvasItem, height: float, flame: Color) -> void:
	post(ci, 0.0, height, 2.2, IRON)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-5, -height), Vector2(5, -height), Vector2(4.4, -height - 11), Vector2(-4.4, -height - 11)]), IRON, 1.4, 0.3, 1.1)
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-3, -height - 1.5), Vector2(3, -height - 1.5), Vector2(2.6, -height - 9.5), Vector2(-2.6, -height - 9.5)]), flame)
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-6, -height - 11), Vector2(6, -height - 11), Vector2(0, -height - 17)]), IRON)
	VectorStyle.draw_glow(ci, flame, Vector2(0, -height - 6), 20.0, 0.45)


static func fire_pit(ci: CanvasItem, at: Vector2, size: float = 1.0) -> void:
	for k: int in 6:
		var a: float = k * TAU / 6.0
		rock(ci, at + Vector2(cos(a) * 9.0, sin(a) * 3.4) * size, 3.0 * size, Color("4a4650"), k + 3)
	var colors: Array[Color] = [Color("c8341a"), Color("f07a24"), Color("ffc54a")]
	for layer: int in 3:
		var s: float = (1.0 - layer * 0.28) * size
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-5 * s, 0), at + Vector2(-3 * s, -6 * s), at + Vector2(0, -13 * s), at + Vector2(3 * s, -6 * s), at + Vector2(5 * s, 0)]), colors[layer])
	VectorStyle.draw_glow(ci, EMBER, at + Vector2(0, -5), 20.0 * size, 0.5)


static func fence(ci: CanvasItem, from_x: float, to_x: float, height: float = 20.0, broken: bool = false, wood: Color = WOOD) -> void:
	var count: int = int((to_x - from_x) / 10.0) + 1
	for i: int in count:
		if broken and i == 2:
			post(ci, from_x + i * 10.0, height * 0.45, 2.0, wood)
			continue
		post(ci, from_x + i * 10.0, height + (i % 2) * 2.0, 2.0, wood)
	for y: float in [-height * 0.35, -height * 0.7]:
		beam(ci, Vector2(from_x, y), Vector2(to_x, y + (4.0 if broken else 0.0)), 2.4, wood)


static func pile(ci: CanvasItem, at: Vector2, w: float, h: float, color: Color, seed_value: int = 2) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for i: int in 9:
		var p: Vector2 = at + Vector2(rng.randf_range(-w, w), -rng.randf_range(0.0, h) * (1.0 - absf(rng.randf_range(-w, w)) / (w * 1.6)))
		rock(ci, p, rng.randf_range(3.0, 6.0), color.darkened(rng.randf_range(0.0, 0.35)), i + seed_value)
