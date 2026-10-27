class_name ArcherPainter
## Paints the vector Archer tower (M15, docs/M15_VECTOR.md), detailed. The body (baked once per level by
## VectorPoseCache): an octagonal plinth with dressed stones, a tapered tower built block by block with varied
## tones, moss and cracks, a lit arrow slit, iron torch sconces, a plank deck with merlons, a red banner with the gold
## keep and a fringe; level 2 adds a gold band, level 3 gold merlon caps. Live (paint_archer, paint_flame): a hooded
## archer drawing the bow toward the aim, and the torch flames. Pose units: the slot at (0, 0).

const STONE: Color = Color("a8998a")
const STONE_ALT: Color = Color("8f8273")
const PLINTH: Color = Color("80796f")
const WOOD: Color = Color("8b5a35")
const IRON: Color = Color("3e3c42")
const MOSS: Color = Color("4f6b3a")
const RED: Color = Color("ac2b2a")
const GOLD: Color = Color("e8b54e")
const CLOAK: Color = Color("6e3a26")
const TOP: Vector2 = Vector2(0, -54)
## Where the archer aims on the sheet (down and to the right, toward the road).
const AIM: float = 0.45
const TORCHES: Array[Vector2] = [Vector2(-14.5, -44), Vector2(14.5, -44)]
const BOX: Rect2 = Rect2(-34, -84, 68, 98)


static func paint_body(ci: CanvasItem, level: int) -> void:
	VectorStyle.shadow(ci, Vector2(3, 5), 28, 10.5)
	_plinth(ci)
	_tower(ci)
	if level >= 2:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(-13.2, -31), Vector2(13.2, -31), Vector2(13.0, -28.6), Vector2(-13.0, -28.6)]), GOLD, 0.8, 0.0, 0.6)
	for at: Vector2 in TORCHES:
		_sconce(ci, at)
	_deck(ci, level)
	_banner(ci)


static func plinth(ci: CanvasItem, scale_by: float = 1.0) -> void:
	_plinth(ci, scale_by)


## The tower as a sheet frame (TowerPainter): idle breathes (banner, flames, the archer's draw), fire looses an arrow
## toward the front-right and recoils. `t` is the idle cycle (0..1), `fire` the shot's progress (0..1, -1 when not firing).
static func paint(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	paint_body(ci, level)
	var firing: bool = fire >= 0.0
	var pull: float = 0.6 + sin(t * TAU) * 0.08
	if firing:
		pull = smoothstep(0.0, 0.3, fire) * (1.0 - smoothstep(0.3, 0.45, fire)) if fire < 0.45 else 0.0
	var wave: float = sin(t * TAU) * 2.0
	paint_pennant(ci, wave)
	paint_archer(ci, AIM, pull)
	for at: Vector2 in TORCHES:
		paint_flame(ci, at, t + at.x * 0.01)
	var flash: float = (1.0 - smoothstep(0.3, 0.7, fire)) if firing and fire > 0.3 else 0.0
	for at: Vector2 in TORCHES:
		VectorStyle.draw_glow(ci, VectorStyle.WARM_GLOW, at + Vector2(0, -6), 14.0, 0.5)
		VectorStyle.draw_glow(ci, VectorStyle.WARM_GLOW, at + Vector2(0, -5), 30.0, 0.14)
	VectorStyle.draw_glow(ci, VectorStyle.WARM_GLOW, Vector2(0, -26), 11.0, 0.5)
	if flash > 0.0:
		VectorStyle.draw_glow(ci, VectorStyle.GOLD, TOP + Vector2.from_angle(AIM) * 15.0, 9.0, flash)


static func paint_pennant(ci: CanvasItem, wave: float) -> void:
	var pole: Vector2 = Vector2(-12, -52)
	VectorPaint.line(ci, pole, pole + Vector2(0, -24), Color("4a2e1c"), 1.6)
	ci.draw_circle(pole + Vector2(0, -24.5), 1.1, GOLD, true, -1.0, true)
	var cloth: PackedVector2Array = PackedVector2Array([pole + Vector2(0, -23), pole + Vector2(7, -22 + wave * 0.5), pole + Vector2(14, -20 + wave), pole + Vector2(10, -18 + wave * 0.6),
		pole + Vector2(14, -15.5 + wave), pole + Vector2(6, -16 + wave * 0.4), pole + Vector2(0, -16)])
	VectorPaint.painted(ci, cloth, RED, 1.4, 0.3, 0.8)


static func _plinth(ci: CanvasItem, scale_by: float = 1.0) -> void:
	var top: PackedVector2Array = VectorStyle.regular(Vector2(0, -3), 8, 24 * scale_by, 11.5 * scale_by, PI / 8.0)
	var front: PackedVector2Array = PackedVector2Array()
	var lower: Array[Vector2] = []
	for p: Vector2 in top:
		if p.y >= -3.5:
			lower.append(p)
	lower.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	for p: Vector2 in lower:
		front.append(p)
	for i: int in range(lower.size() - 1, -1, -1):
		front.append(lower[i] + Vector2(0, 7))
	VectorPaint.painted(ci, front, PLINTH.darkened(0.25), 2.0, 0.5)
	for i: int in lower.size() - 1:
		var a: Vector2 = lower[i]
		var b: Vector2 = lower[i + 1]
		VectorPaint.line(ci, a, a + Vector2(0, 7), Color(VectorStyle.INK, 0.5), 0.8)
		VectorPaint.line(ci, a.lerp(b, 0.5) + Vector2(0, 3.5), a.lerp(b, 0.5) + Vector2(0, 7), Color(VectorStyle.INK, 0.35), 0.6)
		VectorPaint.line(ci, a + Vector2(0, 3.5), b + Vector2(0, 3.5), Color(VectorStyle.INK, 0.35), 0.6)
	VectorPaint.painted(ci, top, PLINTH, 3.0, 0.45)
	for k: int in 5:
		ci.draw_colored_polygon(VectorStyle.ellipse(Vector2(-18 + k * 8.5, 4 + (k % 2)), 2.2, 1.1, 10), Color(MOSS, 0.85))


## Deterministic tone per block, so the masonry reads as separate stones.
static func _tone(row: int, col: int) -> Color:
	var h: int = (row * 73 + col * 151) % 7
	return STONE.lerp(STONE_ALT, h / 6.0).lerp(Color("b4a48f"), 0.15 if h == 3 else 0.0)


static func _tower(ci: CanvasItem) -> void:
	var rows: int = 7
	var bottom: float = -4.0
	var top: float = -47.0
	for row: int in rows:
		var y0: float = lerpf(bottom, top, float(row) / rows)
		var y1: float = lerpf(bottom, top, float(row + 1) / rows)
		var h0: float = lerpf(14.5, 12.0, float(row) / rows)
		var h1: float = lerpf(14.5, 12.0, float(row + 1) / rows)
		var cuts: Array[float] = []
		cuts.assign([-1.0, -0.45, 0.1, 0.62, 1.0] if row % 2 == 0 else [-1.0, -0.72, -0.18, 0.36, 1.0])
		for col: int in cuts.size() - 1:
			var a: float = cuts[col]
			var b: float = cuts[col + 1]
			var block: PackedVector2Array = PackedVector2Array([Vector2(a * h0 + 0.3, y0 - 0.3), Vector2(b * h0 - 0.3, y0 - 0.3), Vector2(b * h1 - 0.3, y1 + 0.3),
				Vector2(a * h1 + 0.3, y1 + 0.3)])
			# The far right is in shade: blocks there are darker.
			var tone: Color = _tone(row, col).darkened(clampf((a + b) * 0.12, 0.0, 0.25))
			VectorPaint.painted(ci, block, tone, 1.0, 0.25, 0.6)
	VectorPaint.line(ci, Vector2(-12, top), Vector2(-14.5, bottom), Color(1, 0.95, 0.85, 0.25), 1.2)
	# Moss creeping up from the base, and a crack.
	for k: int in 6:
		var x: float = -12.0 + k * 4.6
		VectorPaint.strand(ci, Vector2(x, bottom), Vector2(x + 1.0, bottom - 3.0 - (k % 3)), Vector2(x - 0.5, bottom - 5.0 - (k % 3) * 2.0), 2.2, Color(MOSS, 0.85))
	ci.draw_polyline(PackedVector2Array([Vector2(6, -14), Vector2(7.5, -18), Vector2(6.5, -21), Vector2(8.5, -25)]), Color(VectorStyle.INK, 0.6), 0.7, true)
	# The arrow slit, lit from inside.
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-1.8, -31.5), Vector2(1.8, -31.5), Vector2(1.8, -20.5), Vector2(-1.8, -20.5)]), Color("ffb84d"), 0.8, 0.0, 0.9)
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-0.6, -30), Vector2(0.6, -30), Vector2(0.6, -22), Vector2(-0.6, -22)]), Color("fff0c8"))


static func _sconce(ci: CanvasItem, at: Vector2) -> void:
	var side: float = signf(at.x)
	VectorPaint.line(ci, at + Vector2(-side * 3.0, 4), at + Vector2(0, 1), IRON, 1.4)
	VectorPaint.line(ci, at + Vector2(0, 1), at + Vector2(0, -3), Color("5a3a22"), 1.8)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-1.8, -3), at + Vector2(1.8, -3), at + Vector2(1.2, -1.2), at + Vector2(-1.2, -1.2)]), IRON, 0.6, 0.2, 0.6)


static func _deck(ci: CanvasItem, level: int) -> void:
	var deck: PackedVector2Array = VectorStyle.ellipse(Vector2(0, -48), 18, 8, 32)
	VectorPaint.painted(ci, deck, WOOD, 2.0, 0.4)
	for k: int in 6:
		var x: float = -14.0 + k * 5.6
		VectorPaint.line(ci, Vector2(x, -54.5 + absf(x) * 0.12), Vector2(x, -41.5 - absf(x) * 0.12), Color(VectorStyle.INK, 0.35), 0.6)
	# Merlons on the far half of the rim (the near half would hide the archer).
	for k: int in 5:
		var a: float = PI + 0.25 + k * (PI - 0.5) / 4.0
		var at: Vector2 = Vector2(cos(a) * 16.5, -48 + sin(a) * 7.0)
		var merlon: PackedVector2Array = PackedVector2Array([at + Vector2(-2.6, 0), at + Vector2(2.6, 0), at + Vector2(2.6, -5), at + Vector2(-2.6, -5)])
		VectorPaint.painted(ci, merlon, _tone(k, 2), 1.0, 0.4, 0.7)
		if level >= 3:
			VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-2.8, -5), at + Vector2(2.8, -5), at + Vector2(2.8, -6.2), at + Vector2(-2.8, -6.2)]), GOLD, 0.5, 0.0, 0.5)


static func _banner(ci: CanvasItem) -> void:
	var cloth: PackedVector2Array = PackedVector2Array([Vector2(-5, -41), Vector2(5, -41), Vector2(5.5, -26), Vector2(3, -23.5), Vector2(0, -26), Vector2(-3, -23.5),
		Vector2(-5.5, -26)])
	VectorPaint.line(ci, Vector2(-6.5, -41), Vector2(6.5, -41), Color("5a3a22"), 1.6)
	VectorPaint.painted(ci, cloth, RED, 2.0, 0.35)
	VectorPaint.strand(ci, Vector2(-2, -40), Vector2(-2.5, -33), Vector2(-1.5, -26), 1.4, Color(VectorPaint.shadow_of(RED), 0.6))
	VectorPaint.strand(ci, Vector2(2.5, -40), Vector2(3, -33), Vector2(2, -26), 1.2, Color(VectorPaint.shadow_of(RED), 0.5))
	var trim: PackedVector2Array = cloth.duplicate()
	trim.append(cloth[0])
	ci.draw_polyline(trim, Color(GOLD, 0.85), 0.7, true)
	KnightPainter.keep_emblem(ci, Vector2(0, -34.5), 0.9)


## The hooded archer at the deck, turned toward `angle` (radians), drawing the bow by `pull` (0..1).
static func paint_archer(ci: CanvasItem, angle: float, pull: float) -> void:
	var dir: Vector2 = Vector2.from_angle(angle)
	var side: Vector2 = dir.orthogonal()
	var body: Vector2 = TOP + Vector2(0, 2)
	VectorPaint.painted(ci, VectorStyle.ellipse(body - dir * 1.5, 5.5, 4.2, 16), CLOAK, 1.6, 0.5)
	VectorPaint.painted(ci, VectorStyle.ellipse(body - dir * 2.0 - Vector2(0, 3.5), 3.6, 3.4, 14), CLOAK.darkened(0.15), 1.4, 0.6)
	ci.draw_colored_polygon(VectorStyle.ellipse(body - dir * 1.0 - Vector2(0, 3.2), 1.6, 1.3, 10), Color("1b1420"))
	# The bow: a recurve held out front, the string drawn back to the cheek.
	var grip: Vector2 = body + dir * 7.0 - Vector2(0, 2)
	var limb_a: Vector2 = grip + side * 7.5 - dir * 2.0
	var limb_b: Vector2 = grip - side * 7.5 - dir * 2.0
	for tip: Vector2 in [limb_a, limb_b]:
		VectorPaint.strand(ci, grip, grip.lerp(tip, 0.5) + dir * 1.8, tip, 2.2, Color("4a2e1c"))
		VectorPaint.strand(ci, grip, grip.lerp(tip, 0.5) + dir * 1.6, tip, 1.4, GOLD)
	var nock: Vector2 = grip - dir * (3.0 + pull * 5.0)
	ci.draw_polyline(PackedVector2Array([limb_a, nock, limb_b]), Color(1, 1, 1, 0.8), 0.6, true)
	VectorPaint.line(ci, body + side * 3.0, grip, CLOAK.lightened(0.1), 2.0)
	VectorPaint.line(ci, body - side * 3.0, nock, CLOAK.lightened(0.1), 2.0)
	if pull > 0.15:
		VectorPaint.line(ci, nock, grip + dir * 6.0, Color("ece4d4"), 1.0)
		VectorPaint.fill(ci, PackedVector2Array([grip + dir * 8.5, grip + dir * 5.5 + side * 1.6, grip + dir * 5.5 - side * 1.6]), Color("dfe3e6"))


## A flickering torch flame at `at` (the sconce), `t` the time.
static func paint_flame(ci: CanvasItem, at: Vector2, t: float) -> void:
	var base: Vector2 = at + Vector2(0, -3)
	var flick: float = sin(t * 13.0 + at.x) * 0.8 + sin(t * 7.0) * 0.5
	for layer: int in 3:
		var s: float = 1.0 - layer * 0.3
		var color: Color = [Color("e5541e"), Color("ffa63a"), Color("fff1b8")][layer]
		var tip: Vector2 = base + Vector2(flick * s, -8.0 * s - absf(flick))
		VectorPaint.fill(ci, PackedVector2Array([base + Vector2(-2.6 * s, 0), base + Vector2(-1.6 * s, -3.5 * s), tip, base + Vector2(1.6 * s, -3.5 * s),
			base + Vector2(2.6 * s, 0), base + Vector2(0, 1.2 * s)]), color)
