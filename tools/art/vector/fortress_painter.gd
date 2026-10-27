class_name FortressPainter
## Paints the vector fortress (M15): a three-tower keep, drawn in node coordinates (the fortress scene's origin is the
## middle of its 96x96 collision box; the keep's front edge is at y +56 and the roof apex at about -100). Four looks, the
## sheet's four columns: 0 healthy (slate roofs, lit windows, a portcullis gate), 1 damaged (cracks, chipped battlements,
## scorch marks, a few fallen blocks), 2 badly damaged (a tower roof torn open, a hole in the keep roof, big cracks, dark
## windows, a litter of rubble), 3 destroyed (low jagged ruins, rubble, a broken beam, the gate arch dark with embers).
## The banners, braziers and fires are the animated decor (decor_frame): separate sprites the scene places.

const STONE: Color = Color("737b88")
const STONE_DARK: Color = Color("404756")
const STONE_LIGHT: Color = Color("a3abb8")
const SLATE: Color = Color("3a4357")
const SLATE_LIGHT: Color = Color("62708a")
const WOOD: Color = Color("86592f")
const WOOD_DARK: Color = Color("4a2e1c")
const IRON: Color = Color("2c2f38")
const AMBER: Color = Color("ffbe55")
const RED: Color = Color("b8302c")
const GOLD: Color = Color("e8b54e")
## The keep's ground line and the body's extent (node coordinates).
const FRONT: float = 50.0
const KEEP_HALF: float = 34.0
const KEEP_TOP: float = -66.0
const TOWER_X: float = 45.0
const TOWER_HALF: float = 17.0
const TOWER_TOP: float = -62.0


static func frame(ci: CanvasItem, look: int) -> void:
	VectorStyle.shadow(ci, Vector2(4, FRONT - 2), 78, 20)  # stays inside the 192 px cell (the shadow's outer ring is 15% wider)
	if look >= 3:
		_ruin(ci)
		return
	_towers(ci, look)
	_keep(ci, look)
	_gate(ci, look)
	_steps(ci)
	_roofs(ci, look)
	_damage(ci, look)
	_ground_light(ci)


static func _block_tone(row: int, col: int) -> Color:
	var h: int = (row * 53 + col * 97) % 7
	return STONE.lerp(STONE_DARK, h / 12.0).lerp(STONE_LIGHT, 0.12 if h == 2 else 0.0)


## A wall panel of dressed stone: courses of blocks in varied tones, with a lit left edge and a shaded right edge.
static func _wall(ci: CanvasItem, rect: Rect2, bond: int) -> void:
	VectorPaint.painted(ci, PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]), STONE, 4.0, 0.5, 1.4)
	var rows: int = int(rect.size.y / 9.0)
	var cols: int = maxi(int(rect.size.x / 12.0), 2)
	for row: int in rows:
		var y: float = rect.position.y + 2.0 + row * 9.0
		var shift: float = 6.0 if row % 2 == 0 else 0.0
		for col: int in cols + 1:
			var x: float = rect.position.x + col * 12.0 - shift
			var x0: float = maxf(x, rect.position.x + 0.8)
			var x1: float = minf(x + 11.2, rect.end.x - 0.8)
			if x1 - x0 < 2.0:
				continue
			var block: PackedVector2Array = PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1, y + 7.8), Vector2(x0, y + 7.8)])
			VectorPaint.painted(ci, block, _block_tone(row + bond, col), 1.2, 0.2, 0.7)
	VectorPaint.line(ci, rect.position + Vector2(1.5, 1), rect.position + Vector2(1.5, rect.size.y - 1), Color(1, 1, 1, 0.22), 1.6)


static func _window(ci: CanvasItem, at: Vector2, lit: bool) -> void:
	var frame_pts: PackedVector2Array = PackedVector2Array([at + Vector2(-4, -6), at + Vector2(4, -6), at + Vector2(4, 6), at + Vector2(-4, 6)])
	VectorPaint.painted(ci, frame_pts, STONE_DARK, 1.0, 0.0, 1.0)
	var glass: PackedVector2Array = PackedVector2Array([at + Vector2(-2.4, -4.4), at + Vector2(2.4, -4.4), at + Vector2(2.4, 4.4), at + Vector2(-2.4, 4.4)])
	VectorPaint.fill(ci, glass, AMBER if lit else Color("1a1820"))
	if lit:
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-2.7, -4.6), at + Vector2(0.4, -4.6), at + Vector2(0.4, 4.6), at + Vector2(-2.7, 4.6)]), Color("ffe3a0"))
		VectorStyle.draw_glow(ci, AMBER, at, 6.0, 0.35)
	VectorPaint.line(ci, at + Vector2(0, -4.6), at + Vector2(0, 4.6), Color(VectorStyle.INK, 0.8), 0.8)
	VectorPaint.line(ci, at + Vector2(-2.7, 0), at + Vector2(2.7, 0), Color(VectorStyle.INK, 0.8), 0.8)


static func _battlements(ci: CanvasItem, x0: float, x1: float, y: float, missing: Array) -> void:
	var count: int = int((x1 - x0) / 12.0)
	for i: int in count:
		if missing.has(i):
			continue
		var x: float = x0 + 1.0 + i * (x1 - x0) / count
		var w: float = (x1 - x0) / count - 2.4
		VectorPaint.painted(ci, PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y - 7), Vector2(x, y - 7)]), _block_tone(3, i), 1.2, 0.3, 0.8)


static func _towers(ci: CanvasItem, look: int) -> void:
	for side: float in [-1.0, 1.0]:
		var cx: float = side * TOWER_X
		var drum: PackedVector2Array = PackedVector2Array([Vector2(cx - TOWER_HALF, FRONT - 2), Vector2(cx + TOWER_HALF, FRONT - 2), Vector2(cx + TOWER_HALF - 1, TOWER_TOP + 14), Vector2(cx - TOWER_HALF + 1, TOWER_TOP + 14)])
		VectorPaint.painted(ci, drum, STONE, 5.0, 0.6, 1.4)
		for row: int in 11:
			var y: float = FRONT - 8.0 - row * 9.2
			VectorPaint.line(ci, Vector2(cx - TOWER_HALF + 1, y), Vector2(cx + TOWER_HALF - 1, y), Color(VectorStyle.INK, 0.42), 0.9)
			var shift: float = 5.0 if row % 2 == 0 else -1.0
			for k: int in 3:
				var x: float = cx - 12.0 + shift + k * 11.0
				if x > cx - TOWER_HALF + 2 and x < cx + TOWER_HALF - 2:
					VectorPaint.line(ci, Vector2(x, y), Vector2(x, y - 9.2), Color(VectorStyle.INK, 0.3), 0.8)
		VectorPaint.line(ci, Vector2(cx - TOWER_HALF + 1.5, FRONT - 4), Vector2(cx - TOWER_HALF + 2.5, TOWER_TOP + 18), Color(1, 1, 1, 0.22), 1.8)
		for y: float in [-14.0, 8.0, 30.0]:
			_window(ci, Vector2(cx - side * 2.0, y), look < 2 or (look == 2 and y > 0))


static func _keep(ci: CanvasItem, look: int) -> void:
	_wall(ci, Rect2(-KEEP_HALF, KEEP_TOP + 14, KEEP_HALF * 2, FRONT - KEEP_TOP - 16), 0)
	for row: int in 2:
		for col: int in 3:
			_window(ci, Vector2(-17.0 + col * 17.0, -42.0 + row * 19.0), look < 2 or (look == 2 and (row + col) % 2 == 0))
	_battlements(ci, -KEEP_HALF, KEEP_HALF, KEEP_TOP + 14, [] if look == 0 else [2])


static func _gate(ci: CanvasItem, look: int) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-31, 14), Vector2(31, 14), Vector2(31, FRONT - 2), Vector2(-31, FRONT - 2)]), STONE_DARK, 3.0, 0.4, 1.4)
	# A heavy lintel with a row of dressed stones over the arch.
	for k: int in 7:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(-31 + k * 8.9, 14), Vector2(-23 + k * 8.9, 14), Vector2(-23.6 + k * 8.9, 21), Vector2(-30.4 + k * 8.9, 21)]), _block_tone(5, k), 0.8, 0.3, 0.8)
	var arch: PackedVector2Array = PackedVector2Array([Vector2(-25, FRONT - 2), Vector2(-25, 28), Vector2(-20, 24), Vector2(0, 21), Vector2(20, 24), Vector2(25, 28), Vector2(25, FRONT - 2)])
	VectorPaint.fill(ci, arch, Color("120f16"))
	# The portcullis: vertical iron-shod timbers with cross bars.
	for k: int in 9:
		var x: float = -22.0 + k * 5.5
		VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 1.7, 25 - absf(x) * 0.12), Vector2(x + 1.7, 25 - absf(x) * 0.12), Vector2(x + 1.7, FRONT - 3), Vector2(x - 1.7, FRONT - 3)]), WOOD, 0.9, 0.4, 0.7)
	for y: float in [28.0, 38.0]:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(-24, y), Vector2(24, y), Vector2(24, y + 3), Vector2(-24, y + 3)]), IRON, 0.8, 0.3, 0.7)
		for x: float in [-18.0, -6.0, 6.0, 18.0]:
			VectorPaint.rivet(ci, Vector2(x, y + 1.5), 0.8)
	if look >= 2:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 24), Vector2(24, 28), Vector2(24, 42), Vector2(14, 36)]), Color(0.05, 0.04, 0.07, 0.9))


static func _steps(ci: CanvasItem) -> void:
	for k: int in 2:
		var w: float = 34.0 + k * 6.0
		VectorPaint.painted(ci, PackedVector2Array([Vector2(-w, FRONT - 2 + k * 3.4), Vector2(w, FRONT - 2 + k * 3.4), Vector2(w + 1, FRONT + 1.4 + k * 3.4), Vector2(-w - 1, FRONT + 1.4 + k * 3.4)]), STONE_DARK.lerp(STONE, 0.3 + k * 0.18), 1.0, 0.3, 0.8)


## The slate roofs: the keep's pyramid and the towers' cones, with shingle courses and a lit left face.
static func _roofs(ci: CanvasItem, look: int) -> void:
	_cone(ci, Vector2(-TOWER_X, TOWER_TOP + 14), 20.0, 44.0, look >= 2)
	_cone(ci, Vector2(TOWER_X, TOWER_TOP + 14), 20.0, 44.0, false)
	var keep: PackedVector2Array = PackedVector2Array([Vector2(-KEEP_HALF - 5, KEEP_TOP + 8), Vector2(KEEP_HALF + 5, KEEP_TOP + 8), Vector2(14, KEEP_TOP - 28), Vector2(-14, KEEP_TOP - 28)])
	VectorPaint.painted(ci, keep, SLATE, 5.0, 0.5, 1.4)
	for row: int in 5:
		var y: float = KEEP_TOP + 4.0 - row * 7.0
		var half: float = lerpf(KEEP_HALF + 3.0, 14.0, (row + 1) / 6.0)
		VectorPaint.line(ci, Vector2(-half, y), Vector2(half, y), Color(VectorStyle.INK, 0.5), 0.9)
		for k: int in int(half * 2.0 / 7.0):
			var x: float = -half + 3.0 + k * 7.0 + (3.5 if row % 2 == 0 else 0.0)
			VectorPaint.line(ci, Vector2(x, y), Vector2(x * 0.97, y - 7.0), Color(VectorStyle.INK, 0.3), 0.7)
	VectorPaint.line(ci, Vector2(-KEEP_HALF - 4, KEEP_TOP + 7), Vector2(-14, KEEP_TOP - 27), Color(SLATE_LIGHT, 0.7), 1.6)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-16, KEEP_TOP - 28), Vector2(16, KEEP_TOP - 28), Vector2(15, KEEP_TOP - 32), Vector2(-15, KEEP_TOP - 32)]), IRON, 1.0, 0.3, 0.8)
	if look >= 2:
		# A hole torn through the keep roof, timbers showing.
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-12, KEEP_TOP - 14), Vector2(6, KEEP_TOP - 20), Vector2(14, KEEP_TOP - 6), Vector2(2, KEEP_TOP - 2), Vector2(-10, KEEP_TOP - 6)]), Color(0.06, 0.05, 0.08, 0.95))
		ci.draw_line(Vector2(-12, KEEP_TOP - 4), Vector2(8, KEEP_TOP - 18), WOOD, 3.0, true)
		ci.draw_line(Vector2(-2, KEEP_TOP - 2), Vector2(12, KEEP_TOP - 10), WOOD_DARK, 2.4, true)


static func _cone(ci: CanvasItem, base: Vector2, half: float, height: float, torn: bool) -> void:
	var tip: Vector2 = base + Vector2(0, -height)
	var pts: PackedVector2Array = PackedVector2Array([base + Vector2(-half, 0), base + Vector2(half, 0), tip + Vector2(3, 0), tip + Vector2(-3, 0)])
	if torn:
		pts = PackedVector2Array([base + Vector2(-half, 0), base + Vector2(half, 0), base + Vector2(half * 0.5, -height * 0.5), base + Vector2(half * 0.2, -height * 0.4), tip + Vector2(8, 10), tip + Vector2(-2, 4), tip + Vector2(-8, 14)])
	VectorPaint.painted(ci, pts, SLATE, 5.0, 0.55, 1.4)
	for row: int in 5:
		var y: float = base.y - row * (height / 5.5)
		var k: float = 1.0 - float(row) / 5.5
		VectorPaint.line(ci, Vector2(base.x - half * k, y), Vector2(base.x + half * k, y), Color(VectorStyle.INK, 0.5), 0.9)
	VectorPaint.line(ci, base + Vector2(-half + 1.5, -1), tip + Vector2(-2.5, 2), Color(SLATE_LIGHT, 0.75), 1.6)
	VectorPaint.painted(ci, PackedVector2Array([base + Vector2(-half - 2, 0), base + Vector2(half + 2, 0), base + Vector2(half + 1.6, 3.4), base + Vector2(-half - 1.6, 3.4)]), IRON, 1.0, 0.3, 0.8)


## Cracks, scorch marks, chipped battlements and fallen blocks, by look.
static func _damage(ci: CanvasItem, look: int) -> void:
	if look == 0:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 91 + look
	var cracks: Array = [[Vector2(-50, 20), Vector2(-46, 10), Vector2(-49, 2), Vector2(-44, -8), Vector2(-47, -20)], [Vector2(58, 34), Vector2(54, 24), Vector2(58, 14), Vector2(53, 4)]]
	if look >= 2:
		cracks.append([Vector2(-10, -30), Vector2(-6, -20), Vector2(-9, -12), Vector2(-4, -2)])
		cracks.append([Vector2(26, -44), Vector2(22, -34), Vector2(27, -24)])
	for c: Array in cracks:
		var pts: PackedVector2Array = PackedVector2Array(c)
		ci.draw_polyline(pts, Color(VectorStyle.INK, 0.9), 1.8, true)
		ci.draw_polyline(VectorPaint.moved(pts, Vector2(0.8, 0)), Color(1, 1, 1, 0.2), 0.7, true)
	var scorches: int = 2 if look == 1 else 5
	for i: int in scorches:
		var at: Vector2 = Vector2(rng.randf_range(-60, 60), rng.randf_range(-50, 30))
		VectorStyle.draw_glow(ci, Color(0.02, 0.02, 0.03), at, rng.randf_range(10.0, 16.0), 0.5)
	for i: int in (4 if look == 1 else 9):
		var at: Vector2 = Vector2(rng.randf_range(-78, 78), FRONT + rng.randf_range(-2.0, 8.0))
		var s: float = rng.randf_range(2.4, 5.0)
		var a: float = rng.randf() * TAU
		VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-s, -s * 0.6).rotated(a), at + Vector2(s, -s * 0.7).rotated(a), at + Vector2(s * 0.8, s * 0.6).rotated(a), at + Vector2(-s * 0.9, s * 0.7).rotated(a)]), STONE.lerp(STONE_DARK, rng.randf() * 0.6), s * 0.4, 0.4, 0.8)


static func _ground_light(ci: CanvasItem) -> void:
	VectorStyle.draw_glow(ci, VectorStyle.WARM_GLOW, Vector2(0, FRONT - 14), 70.0, 0.1)


## The ruin: low broken walls, a collapsed roof beam, a dark arch with embers, scattered stone.
static func _ruin(ci: CanvasItem) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	var left: PackedVector2Array = PackedVector2Array([Vector2(-78, FRONT - 2), Vector2(-78, -12), Vector2(-72, -26), Vector2(-66, -14), Vector2(-60, -34), Vector2(-52, -18), Vector2(-46, -22), Vector2(-40, FRONT - 2)])
	VectorPaint.painted(ci, left, STONE, 4.0, 0.5, 1.4)
	var right: PackedVector2Array = PackedVector2Array([Vector2(40, FRONT - 2), Vector2(44, -6), Vector2(54, -2), Vector2(60, -30), Vector2(68, -16), Vector2(78, -28), Vector2(80, FRONT - 2)])
	VectorPaint.painted(ci, right, STONE, 4.0, 0.5, 1.4)
	var back: PackedVector2Array = PackedVector2Array([Vector2(-44, FRONT - 2), Vector2(-44, 8), Vector2(-34, -4), Vector2(-20, 14), Vector2(0, -10), Vector2(22, 8), Vector2(34, -2), Vector2(44, 10), Vector2(44, FRONT - 2)])
	VectorPaint.painted(ci, back, STONE_DARK.lerp(STONE, 0.4), 4.0, 0.4, 1.4)
	for row: int in 6:
		for k: int in 8:
			VectorPaint.line(ci, Vector2(-76 + k * 18.0, 40 - row * 8.0), Vector2(-68 + k * 18.0, 40 - row * 8.0), Color(VectorStyle.INK, 0.3), 0.8)
	var arch: PackedVector2Array = PackedVector2Array([Vector2(-26, FRONT - 2), Vector2(-26, 30), Vector2(-18, 20), Vector2(0, 16), Vector2(18, 20), Vector2(26, 30), Vector2(26, FRONT - 2)])
	VectorPaint.fill(ci, arch, Color("120f16"))
	VectorStyle.draw_glow(ci, Color("ff7a30"), Vector2(4, 44), 24.0, 0.7)
	VectorStyle.draw_glow(ci, Color("ffc060"), Vector2(4, 46), 9.0, 0.8)
	ci.draw_line(Vector2(-62, 30), Vector2(30, 58), WOOD, 4.0, true)
	ci.draw_line(Vector2(-58, 28), Vector2(34, 56), Color(WOOD_DARK, 0.9), 1.6, true)
	ci.draw_line(Vector2(20, 22), Vector2(70, 50), WOOD_DARK, 3.4, true)
	for i: int in 26:
		var at: Vector2 = Vector2(rng.randf_range(-92, 92), FRONT - 4.0 + rng.randf_range(-6.0, 12.0))
		var s: float = rng.randf_range(2.4, 6.4)
		var a: float = rng.randf() * TAU
		VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-s, -s * 0.6).rotated(a), at + Vector2(s, -s * 0.7).rotated(a), at + Vector2(s * 0.8, s * 0.6).rotated(a), at + Vector2(-s * 0.9, s * 0.7).rotated(a)]), STONE.lerp(STONE_DARK, rng.randf() * 0.6), s * 0.4, 0.4, 0.8)


## ---- the animated decor (FORTRESS_FX): banners, a torn banner, a torch flame, a fire ---------------------------

static func decor_frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var t: float = float(index) / count
	match anim:
		"banner":
			_banner(ci, t, false)
		"banner_torn":
			_banner(ci, t, true)
		"brazier":
			_torch(ci, t)
		"fire":
			_fire(ci, t)


## A hanging banner: a gold crossbar, red cloth with a swallowtail hem and the keep's emblem, swaying a little.
static func _banner(ci: CanvasItem, t: float, torn: bool) -> void:
	var sway: float = sin(t * TAU) * 2.4
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-9, -26), Vector2(9, -26), Vector2(9, -24), Vector2(-9, -24)]), GOLD, 0.6, 0.0, 0.8)
	ci.draw_circle(Vector2(-9.5, -25), 1.3, GOLD, true, -1.0, true)
	ci.draw_circle(Vector2(9.5, -25), 1.3, GOLD, true, -1.0, true)
	var cloth: PackedVector2Array = PackedVector2Array([Vector2(-7.5, -24), Vector2(7.5, -24), Vector2(7.5 + sway * 0.4, -2), Vector2(2.5 + sway * 0.8, 3), Vector2(sway, -4), Vector2(-2.5 + sway * 0.8, 3), Vector2(-7.5 + sway * 0.4, -2)])
	if torn:
		cloth = PackedVector2Array([Vector2(-7.5, -24), Vector2(7.5, -24), Vector2(6.5 + sway * 0.4, -10), Vector2(3 + sway, -6), Vector2(4.5 + sway, 2), Vector2(0, -3), Vector2(-3 + sway * 0.8, 4), Vector2(-6 + sway * 0.4, -8)])
	VectorPaint.painted(ci, cloth, RED, 1.8, 0.35, 1.0)
	VectorPaint.strand(ci, Vector2(-3, -22), Vector2(-3.5 + sway * 0.3, -12), Vector2(-3 + sway * 0.5, -3), 1.6, Color(VectorPaint.shadow_of(RED), 0.7))
	KnightPainter.keep_emblem(ci, Vector2(sway * 0.2, -14), 1.0)


static func _torch(ci: CanvasItem, t: float) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-1.8, 20), Vector2(1.8, 20), Vector2(1.4, -2), Vector2(-1.4, -2)]), WOOD, 0.8, 0.4, 0.8)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-3.4, -2), Vector2(3.4, -2), Vector2(2.4, -6), Vector2(-2.4, -6)]), IRON, 0.8, 0.3, 0.8)
	_flame(ci, Vector2(0, -5), t, 1.0)
	VectorStyle.draw_glow(ci, Color("ff9a30"), Vector2(0, -9), 14.0, 0.45)


static func _fire(ci: CanvasItem, t: float) -> void:
	_flame(ci, Vector2(0, 10), t, 1.7)
	VectorStyle.draw_glow(ci, Color("ff8a30"), Vector2(0, 0), 20.0, 0.5)


static func _flame(ci: CanvasItem, base: Vector2, t: float, size: float) -> void:
	var colors: Array[Color] = [Color("c8341a"), Color("f07a24"), Color("ffc54a"), Color("fff3c0")]
	for layer: int in 4:
		var s: float = (1.0 - layer * 0.24) * size
		var phase: float = t * TAU + layer * 1.3
		var sway: float = sin(phase) * 1.6 * s
		var h: float = (11.0 + sin(phase * 1.7) * 2.0) * s
		VectorPaint.fill(ci, PackedVector2Array([base + Vector2(-3.4 * s, 0), base + Vector2(-2.4 * s, -h * 0.5), base + Vector2(sway, -h), base + Vector2(2.4 * s, -h * 0.5), base + Vector2(3.4 * s, 0), base + Vector2(0, 1.2 * s)]), colors[layer])
