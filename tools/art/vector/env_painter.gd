class_name EnvPainter
## The graveyard's vector set pieces (M15): the twelve props (graveyard_props.png), the crypt, the build pad with its
## highlight frame and the rubble that blocks a slot. All static; each painter draws around its own origin (props: the
## feet at (0, 0); the crypt likewise; the pad and rubble around their centre). Cold stone and dead wood for the graveyard,
## with warm lantern light and the crypt's necrotic green door glow baked in as halos.

const GRAVE: Color = Color("8d98a8")
const GRAVE_DARK: Color = Color("4f5868")
const GRAVE_LIGHT: Color = Color("bcc6d3")
const MOSS: Color = Color("4f7040")
const WOOD: Color = Color("5a3d2a")
const WOOD_LIGHT: Color = Color("7d5638")
const IRON: Color = Color("2c2f38")
const BONE: Color = Color("e8dcc0")
const GREEN: Color = Color("7affa6")
## The props' order in graveyard_props.png (the same as the old props.png).
const PROPS: Array[String] = ["gravestone", "cross", "broken_stone", "tomb", "dead_tree", "stump", "bush", "mound", "lantern", "ruined_wall", "bones", "fence"]


static func prop_frame(ci: CanvasItem, index: int) -> void:
	VectorStyle.shadow(ci, Vector2(0, 1), 18.0, 6.0)
	match PROPS[index]:
		"gravestone":
			_gravestone(ci)
		"cross":
			_cross(ci)
		"broken_stone":
			_broken_stone(ci)
		"tomb":
			_tomb(ci)
		"dead_tree":
			_dead_tree(ci)
		"stump":
			_stump(ci)
		"bush":
			_bush(ci)
		"mound":
			_mound(ci)
		"lantern":
			_lantern(ci)
		"ruined_wall":
			_ruined_wall(ci)
		"bones":
			_bones(ci)
		"fence":
			_fence(ci)


static func _moss_tuft(ci: CanvasItem, at: Vector2, size: float = 1.0) -> void:
	for k: int in 3:
		VectorPaint.strand(ci, at + Vector2(k * 1.6 - 1.6, 0), at + Vector2(k * 2.0 - 2.0, -2.0 * size), at + Vector2(k * 2.6 - 2.6, -4.2 * size), 1.4, Color(MOSS, 0.95))


static func _gravestone(ci: CanvasItem) -> void:
	var stone: PackedVector2Array = PackedVector2Array([Vector2(-11, 0), Vector2(-11, -28)])
	for i: int in 9:
		var a: float = PI + i * PI / 8.0
		stone.append(Vector2(cos(a) * 11.0, -28.0 + sin(a) * 11.0))
	stone.append(Vector2(11, -28))
	stone.append(Vector2(11, 0))
	VectorPaint.painted(ci, stone, GRAVE, 4.0, 0.6, 1.4)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-13, 0), Vector2(13, 0), Vector2(12, 4), Vector2(-12, 4)]), GRAVE_DARK, 1.2, 0.3, 1.0)
	VectorPaint.line(ci, Vector2(0, -30), Vector2(0, -16), Color(VectorStyle.INK, 0.7), 2.4)
	VectorPaint.line(ci, Vector2(-5, -25), Vector2(5, -25), Color(VectorStyle.INK, 0.7), 2.4)
	VectorPaint.line(ci, Vector2(0.9, -30), Vector2(0.9, -16), Color(1, 1, 1, 0.3), 0.8)
	VectorPaint.line(ci, Vector2(-10, -4), Vector2(-10, -26), Color(1, 1, 1, 0.22), 1.6)
	_moss_tuft(ci, Vector2(-8, 1), 1.2)
	_moss_tuft(ci, Vector2(9, 1))


static func _cross(ci: CanvasItem) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(7, 4), Vector2(-7, 4)]), GRAVE_DARK, 1.2, 0.3, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-3.4, 0), Vector2(3.4, 0), Vector2(3.0, -46), Vector2(-3.0, -46)]), GRAVE, 2.0, 0.6, 1.3)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-14, -33), Vector2(14, -33), Vector2(14, -27), Vector2(-14, -27)]), GRAVE, 2.0, 0.6, 1.3)
	VectorPaint.line(ci, Vector2(-2.4, -2), Vector2(-2.4, -44), Color(1, 1, 1, 0.3), 1.2)
	VectorPaint.line(ci, Vector2(-12, -31.8), Vector2(12, -31.8), Color(1, 1, 1, 0.25), 1.0)
	_moss_tuft(ci, Vector2(-5, 1))
	_moss_tuft(ci, Vector2(7, 1), 0.8)


static func _broken_stone(ci: CanvasItem) -> void:
	var slab: PackedVector2Array = PackedVector2Array([Vector2(-11, 0), Vector2(-12, -22), Vector2(-7, -38), Vector2(-1, -33), Vector2(4, -40), Vector2(9, -26), Vector2(11, 0)])
	VectorPaint.painted(ci, slab, GRAVE, 4.0, 0.6, 1.4)
	ci.draw_polyline(PackedVector2Array([Vector2(-1, -33), Vector2(0, -24), Vector2(-3, -17), Vector2(1, -10), Vector2(-1, -2)]), Color(VectorStyle.INK, 0.85), 1.6, true)
	VectorPaint.line(ci, Vector2(-10, -4), Vector2(-10, -24), Color(1, 1, 1, 0.22), 1.5)
	for k: int in 3:
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(10 + k * 3.0, -1 - k), 2.4, 1.6, 8), GRAVE_DARK, 0.6, 0.3, 0.6)
	_moss_tuft(ci, Vector2(-7, 1), 1.2)


static func _tomb(ci: CanvasItem) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-22, 0), Vector2(22, 0), Vector2(22, -14), Vector2(-22, -14)]), GRAVE, 4.0, 0.5, 1.4)
	for row: int in 2:
		VectorPaint.line(ci, Vector2(-21, -4.5 - row * 5.0), Vector2(21, -4.5 - row * 5.0), Color(VectorStyle.INK, 0.4), 0.9)
		for k: int in 4:
			VectorPaint.line(ci, Vector2(-13 + k * 9.0 + row * 4.0, -4.5 - row * 5.0), Vector2(-13 + k * 9.0 + row * 4.0, -9.5 - row * 5.0), Color(VectorStyle.INK, 0.3), 0.8)
	var lid: PackedVector2Array = PackedVector2Array([Vector2(-24, -14), Vector2(24, -14), Vector2(18, -22), Vector2(-14, -23)])
	VectorPaint.painted(ci, lid, GRAVE_LIGHT.lerp(GRAVE, 0.4), 3.0, 0.6, 1.4)
	ci.draw_polyline(PackedVector2Array([Vector2(8, -22), Vector2(10, -17), Vector2(7, -14)]), Color(VectorStyle.INK, 0.85), 1.4, true)
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-6, -22.6), Vector2(2, -22.8), Vector2(-1, -27), Vector2(-9, -25)]), GRAVE)
	_moss_tuft(ci, Vector2(-16, -22), 0.8)
	_moss_tuft(ci, Vector2(14, 1))


static func _dead_tree(ci: CanvasItem) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(3, -34), Vector2(-3, -34)]), WOOD, 3.0, 0.4, 1.4)
	for root: float in [-1.0, 1.0]:
		VectorPaint.strand(ci, Vector2(root * 3, -3), Vector2(root * 9, 0), Vector2(root * 15, 3), 4.0, WOOD)
	var branches: Array = [
		[Vector2(-2, -30), Vector2(-14, -40), Vector2(-24, -66), 4.0],
		[Vector2(2, -33), Vector2(10, -48), Vector2(20, -74), 4.0],
		[Vector2(0, -40), Vector2(-2, -54), Vector2(-6, -82), 3.4],
		[Vector2(-10, -42), Vector2(-20, -50), Vector2(-26, -58), 2.4],
		[Vector2(8, -50), Vector2(18, -56), Vector2(24, -64), 2.2],
	]
	for b: Array in branches:
		VectorPaint.strand(ci, b[0], b[1], b[2], float(b[3]), WOOD)
		VectorPaint.strand(ci, b[0] + Vector2(-1, 0), b[1] + Vector2(-1, 0), b[2], float(b[3]) * 0.4, WOOD_LIGHT)
	VectorPaint.line(ci, Vector2(-4.4, -2), Vector2(-2.6, -32), Color(1, 1, 1, 0.12), 1.4)
	ci.draw_colored_polygon(VectorStyle.ellipse(Vector2(0, -22), 2.0, 3.4, 10), Color(0.04, 0.03, 0.05, 0.9))


static func _stump(ci: CanvasItem) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-14, 0), Vector2(14, 0), Vector2(12, -10), Vector2(-12, -10)]), WOOD, 3.0, 0.4, 1.4)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -10), 12.5, 5.6, 22), WOOD_LIGHT, 2.0, 0.4, 1.4)
	for r: float in [0.75, 0.5, 0.25]:
		ci.draw_arc(Vector2(0, -10), 12.0 * r, 0.0, TAU, 20, Color(WOOD, 0.9), 0.8, true)
	for root: float in [-1.0, 1.0]:
		VectorPaint.strand(ci, Vector2(root * 11, -3), Vector2(root * 16, 0), Vector2(root * 22, 3), 3.4, WOOD)
	_moss_tuft(ci, Vector2(-10, -9), 0.8)


static func _bush(ci: CanvasItem) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 14
	for i: int in 9:
		var at: Vector2 = Vector2(rng.randf_range(-14, 14), -9.0 - rng.randf_range(0, 14) + absf(rng.randf_range(-14, 14)) * 0.15)
		var r: float = rng.randf_range(6.5, 9.5)
		VectorPaint.painted(ci, VectorStyle.ellipse(at, r, r * 0.85, 14), Color("2f5a34").lerp(Color("4a7a3a"), rng.randf()), r * 0.4, 0.5, 1.0)
	for i: int in 8:
		var at: Vector2 = Vector2(rng.randf_range(-13, 13), -10.0 - rng.randf_range(0, 12))
		ci.draw_circle(at + Vector2(0.4, 0.5), 1.7, Color(VectorStyle.INK, 0.8), true, -1.0, true)
		ci.draw_circle(at, 1.5, Color("c9302f"), true, -1.0, true)
		ci.draw_circle(at + Vector2(-0.4, -0.4), 0.5, Color("ffb0a8"), true, -1.0, true)


static func _mound(ci: CanvasItem) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -2), 22.0, 6.0, 22), Color("3c3a30"), 2.0, 0.3, 1.0)
	for at: Vector2 in [Vector2(-12, -6), Vector2(0, -9), Vector2(12, -5)]:
		var stone: PackedVector2Array = PackedVector2Array([at + Vector2(-5.5, 6), at + Vector2(-5.5, -4)])
		for i: int in 6:
			var a: float = PI + i * PI / 5.0
			stone.append(at + Vector2(cos(a) * 5.5, -4.0 + sin(a) * 5.5))
		stone.append(at + Vector2(5.5, -4))
		stone.append(at + Vector2(5.5, 6))
		VectorPaint.painted(ci, stone, GRAVE, 2.2, 0.6, 1.2)
	_moss_tuft(ci, Vector2(-18, -1), 0.8)
	_moss_tuft(ci, Vector2(17, -1), 0.8)


static func _lantern(ci: CanvasItem) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-2.6, 0), Vector2(2.6, 0), Vector2(2.0, -50), Vector2(-2.0, -50)]), WOOD, 2.0, 0.4, 1.3)
	VectorPaint.line(ci, Vector2(-1.8, -2), Vector2(-1.4, -48), Color(1, 1, 1, 0.14), 1.0)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-8, -50), Vector2(8, -50), Vector2(8, -52), Vector2(-8, -52)]), IRON, 0.8, 0.3, 0.8)
	var lamp: PackedVector2Array = PackedVector2Array([Vector2(-6, -52), Vector2(6, -52), Vector2(5.4, -64), Vector2(-5.4, -64)])
	VectorPaint.painted(ci, lamp, IRON, 1.6, 0.3, 1.2)
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-4, -54), Vector2(4, -54), Vector2(3.6, -62), Vector2(-3.6, -62)]), Color("ffc96a"))
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-4, -54), Vector2(-0.6, -54), Vector2(-0.6, -62), Vector2(-3.6, -62)]), Color("fff0c0"))
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-7, -64), Vector2(7, -64), Vector2(0, -71)]), IRON)
	ci.draw_circle(Vector2(0, -72), 1.2, IRON, true, -1.0, true)
	VectorStyle.draw_glow(ci, VectorStyle.WARM_GLOW, Vector2(0, -58), 22.0, 0.45)
	VectorStyle.draw_glow(ci, Color("ffe6a0"), Vector2(0, -58), 7.0, 0.6)


static func _ruined_wall(ci: CanvasItem) -> void:
	var wall: PackedVector2Array = PackedVector2Array([Vector2(-26, 0), Vector2(-26, -28), Vector2(-20, -34), Vector2(-14, -29), Vector2(-9, -40), Vector2(-3, -30), Vector2(4, -33), Vector2(10, -25), Vector2(17, -31), Vector2(26, -22), Vector2(26, 0)])
	VectorPaint.painted(ci, wall, GRAVE, 4.0, 0.5, 1.4)
	for row: int in 4:
		var y: float = -4.0 - row * 7.0
		VectorPaint.line(ci, Vector2(-25, y), Vector2(25, y), Color(VectorStyle.INK, 0.4), 0.9)
		for k: int in 5:
			var x: float = -21.0 + k * 10.0 + (5.0 if row % 2 == 0 else 0.0)
			VectorPaint.line(ci, Vector2(x, y), Vector2(x, y - 7.0), Color(VectorStyle.INK, 0.3), 0.8)
	VectorPaint.line(ci, Vector2(-25, -3), Vector2(-25, -26), Color(1, 1, 1, 0.2), 1.6)
	_moss_tuft(ci, Vector2(-14, -29), 1.0)
	_moss_tuft(ci, Vector2(18, -29), 0.8)


static func _bones(ci: CanvasItem) -> void:
	for at: Vector2 in [Vector2(-12, -2), Vector2(2, -6), Vector2(15, -1)]:
		VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -3), 5.4, 5.0, 14), BONE, 2.0, 0.6, 1.2)
		VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-3, 0), at + Vector2(3, 0), at + Vector2(2, 3), at + Vector2(-2, 3)]), BONE.darkened(0.12), 0.8, 0.3, 0.9)
		for x: float in [-2.0, 2.0]:
			ci.draw_circle(at + Vector2(x, -3.4), 1.1, Color("1a1015"), true, -1.0, true)
		ci.draw_line(at + Vector2(0, 0.6), at + Vector2(0, 2.6), Color(VectorStyle.INK, 0.7), 0.7, true)
	for b: Array in [[Vector2(-6, 1), Vector2(6, 2)], [Vector2(8, -3), Vector2(20, 1)]]:
		ci.draw_line(b[0], b[1], Color(VectorStyle.INK, 0.8), 3.4, true)
		ci.draw_line(b[0], b[1], BONE, 2.2, true)
		for p: Vector2 in b:
			ci.draw_circle(p, 1.7, BONE, true, -1.0, true)


static func _fence(ci: CanvasItem) -> void:
	for rail: float in [-12.0, -26.0]:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(-28, rail), Vector2(28, rail), Vector2(28, rail + 2.4), Vector2(-28, rail + 2.4)]), IRON, 0.8, 0.4, 0.9)
	for k: int in 5:
		var x: float = -24.0 + k * 12.0
		VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 1.6, 0), Vector2(x + 1.6, 0), Vector2(x + 1.4, -42), Vector2(x - 1.4, -42)]), IRON, 0.8, 0.5, 0.9)
		VectorPaint.fill(ci, PackedVector2Array([Vector2(x - 2.8, -41), Vector2(x + 2.8, -41), Vector2(x, -50)]), Color("3d4150"))
		VectorPaint.line(ci, Vector2(x - 0.8, -2), Vector2(x - 0.8, -40), Color(1, 1, 1, 0.22), 0.8)


## ---- the crypt ----------------------------------------------------------------------------------------------------

## A stone mausoleum: stepped base, two columns, a carved pediment with a skull, a slate roof, an arched iron-barred door
## with a necrotic green glow, moss and cracks. Cell 128x128, the feet at its bottom front.
static func crypt_frame(ci: CanvasItem, _index: int) -> void:
	VectorStyle.shadow(ci, Vector2(0, 2), 52.0, 11.0)
	for k: int in 3:
		var w: float = 50.0 - k * 3.0
		VectorPaint.painted(ci, PackedVector2Array([Vector2(-w, -k * 4.0), Vector2(w, -k * 4.0), Vector2(w - 1, -k * 4.0 - 5.0), Vector2(-w + 1, -k * 4.0 - 5.0)]), GRAVE_DARK.lerp(GRAVE, k * 0.3), 1.2, 0.3, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-42, -12), Vector2(42, -12), Vector2(42, -58), Vector2(-42, -58)]), GRAVE, 5.0, 0.5, 1.5)
	for row: int in 6:
		var y: float = -17.0 - row * 7.0
		VectorPaint.line(ci, Vector2(-41, y), Vector2(41, y), Color(VectorStyle.INK, 0.4), 0.9)
		for k: int in 7:
			var x: float = -36.0 + k * 12.0 + (6.0 if row % 2 == 0 else 0.0)
			VectorPaint.line(ci, Vector2(x, y), Vector2(x, y - 7.0), Color(VectorStyle.INK, 0.3), 0.8)
	var door: PackedVector2Array = PackedVector2Array([Vector2(-14, -12), Vector2(-14, -34)])
	for i: int in 9:
		var a: float = PI + i * PI / 8.0
		door.append(Vector2(cos(a) * 14.0, -34.0 + sin(a) * 14.0))
	door.append(Vector2(14, -34))
	door.append(Vector2(14, -12))
	VectorPaint.fill(ci, door, Color("0b1410"))
	VectorStyle.draw_glow(ci, GREEN, Vector2(0, -28), 22.0, 0.55)
	VectorStyle.draw_glow(ci, Color("c8ffd8"), Vector2(0, -26), 7.0, 0.55)
	for k: int in 5:
		var x: float = -10.0 + k * 5.0
		VectorPaint.line(ci, Vector2(x, -12), Vector2(x, -42.0 + absf(x) * 0.5), Color(IRON, 0.95), 1.6)
	for x: float in [-30.0, 30.0]:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 4.4, -12), Vector2(x + 4.4, -12), Vector2(x + 3.8, -58), Vector2(x - 3.8, -58)]), GRAVE_LIGHT.lerp(GRAVE, 0.5), 2.4, 0.6, 1.2)
		VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 6, -58), Vector2(x + 6, -58), Vector2(x + 6, -62), Vector2(x - 6, -62)]), GRAVE, 1.0, 0.4, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-48, -62), Vector2(48, -62), Vector2(48, -68), Vector2(-48, -68)]), GRAVE, 2.0, 0.5, 1.3)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-44, -68), Vector2(44, -68), Vector2(0, -98)]), GRAVE, 4.0, 0.5, 1.5)
	for row: int in 4:
		var y: float = -70.0 - row * 6.0
		var half: float = lerpf(40.0, 12.0, row / 4.0)
		VectorPaint.line(ci, Vector2(-half, y), Vector2(half, y), Color(VectorStyle.INK, 0.45), 0.9)
	VectorPaint.line(ci, Vector2(-43, -68), Vector2(-1, -97), Color(1, 1, 1, 0.25), 1.6)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -77), 5.0, 5.4, 14), BONE, 1.6, 0.5, 1.0)
	for x: float in [-1.8, 1.8]:
		ci.draw_circle(Vector2(x, -77.6), 1.1, Color("1a1015"), true, -1.0, true)
	ci.draw_polyline(PackedVector2Array([Vector2(26, -56), Vector2(24, -46), Vector2(28, -38), Vector2(25, -28)]), Color(VectorStyle.INK, 0.85), 1.6, true)
	_moss_tuft(ci, Vector2(-38, -12), 1.5)
	_moss_tuft(ci, Vector2(36, -12), 1.2)
	_moss_tuft(ci, Vector2(-18, -62), 1.2)
	VectorStyle.draw_glow(ci, GREEN, Vector2(0, -8), 36.0, 0.18)


## ---- the build pad and the rubble -----------------------------------------------------------------------------------

## A stone pad: a flat octagonal plate with a worn X inlay; frame 1 is the highlighted pad (a gold rim and glow).
static func pad_frame(ci: CanvasItem, index: int) -> void:
	var plate: PackedVector2Array = VectorStyle.regular(Vector2.ZERO, 8, 24.0, 11.0, PI / 8.0)
	var base: PackedVector2Array = VectorPaint.moved(plate, Vector2(0, 4.0))
	VectorPaint.painted(ci, base, GRAVE_DARK, 1.6, 0.3, 1.2)
	VectorPaint.painted(ci, plate, GRAVE.lerp(GRAVE_DARK, 0.25), 3.4, 0.5, 1.4)
	var inner: PackedVector2Array = VectorStyle.regular(Vector2.ZERO, 8, 17.0, 7.6, PI / 8.0)
	VectorPaint.painted(ci, inner, GRAVE_DARK.lerp(GRAVE, 0.3), 2.0, 0.4, 1.0)
	ci.draw_line(Vector2(-6, -3), Vector2(6, 3), Color(VectorStyle.INK, 0.8), 2.4, true)
	ci.draw_line(Vector2(6, -3), Vector2(-6, 3), Color(VectorStyle.INK, 0.8), 2.4, true)
	ci.draw_line(Vector2(-6, -3.6), Vector2(6, 2.4), Color(1, 1, 1, 0.25), 0.8, true)
	if index == 1:
		var rim: PackedVector2Array = VectorStyle.regular(Vector2.ZERO, 8, 24.0, 11.0, PI / 8.0)
		rim.append(rim[0])
		ci.draw_polyline(rim, Color(VectorStyle.GOLD, 0.95), 2.4, true)
		VectorStyle.draw_glow(ci, VectorStyle.GOLD, Vector2.ZERO, 30.0, 0.5)


static func rubble_frame(ci: CanvasItem, _index: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 23
	VectorStyle.shadow(ci, Vector2(0, 3), 20.0, 7.0)
	for i: int in 14:
		var at: Vector2 = Vector2(rng.randf_range(-19, 19), rng.randf_range(-6, 6))
		var s: float = rng.randf_range(2.4, 6.0)
		var a: float = rng.randf() * TAU
		VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-s, -s * 0.6).rotated(a), at + Vector2(s, -s * 0.7).rotated(a), at + Vector2(s * 0.8, s * 0.6).rotated(a), at + Vector2(-s * 0.9, s * 0.7).rotated(a)]), GRAVE.lerp(GRAVE_DARK, rng.randf() * 0.7), s * 0.4, 0.4, 0.9)
	ci.draw_line(Vector2(-14, 2), Vector2(10, -6), Color(VectorStyle.INK, 0.9), 3.4, true)
	ci.draw_line(Vector2(-14, 2), Vector2(10, -6), WOOD, 2.2, true)
