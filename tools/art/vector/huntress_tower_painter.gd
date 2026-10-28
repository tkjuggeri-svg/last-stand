class_name HuntressTowerPainter
## Paints the Huntress's three towers in vector (M15 P3, docs/M15_P3_HEROES.md): the Trap Layer (a stone-and-timber trapper's hut
## with a rack of iron jaw traps; a trap is thrown on fire), the Hawk Perch (a tall timber perch with a hooded hawk that launches
## and returns) and the Watchtower (a stone-and-wood lookout with a lantern, a spyglass that flashes and a pennant). Warm lantern
## light and forest green, like the hero. Each paint_*() is one sheet frame: (ci, level 1-3, t the idle phase 0..1, fire -1 while idle
## or 0..1 through the shot). Pose units: the slot at (0, 0), about 58 tall.

const STONE: Color = Color("9a8d7e")
const TIMBER: Color = Color("94683c")
const TIMBER_DARK: Color = Color("4a2e1c")
const MOSS: Color = Color("5f8a55")
const MOSS_DARK: Color = Color("38573a")
const IRON: Color = Color("5c5e69")
const IRON_LIGHT: Color = Color("9a9eab")
const LANTERN: Color = Color("ffb84d")
const GOLD: Color = Color("e8b54e")
const FEATHER: Color = Color("8a6a48")
const FEATHER_LIGHT: Color = Color("e8dcc0")


static func paint_trap_layer(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	VectorStyle.shadow(ci, Vector2(3, 5), 27, 10.5)
	ArcherPainter.plinth(ci, 0.95)
	var firing: bool = fire >= 0.0
	# Stone ground floor with a door, a timber upper room and a mossy roof.
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-15, -3), Vector2(15, -3), Vector2(13, -22), Vector2(-13, -22)]), STONE, 3.0, 0.55)
	for row: int in 3:
		var y: float = -7.0 - row * 5.2
		VectorPaint.line(ci, Vector2(-14 + row, y), Vector2(14 - row, y), Color(VectorStyle.INK, 0.35), 0.9)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-4, -3), Vector2(4, -3), Vector2(4, -14), Vector2(0, -17), Vector2(-4, -14)]), TIMBER_DARK, 1.0, 0.2, 0.9)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(13, -37), Vector2(-13, -37)]), TIMBER, 3.0, 0.5)
	for x: float in [-7.0, 0.0, 7.0]:
		VectorPaint.line(ci, Vector2(x, -22), Vector2(x, -37), TIMBER_DARK, 1.4)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-4, -33), Vector2(4, -33), Vector2(4, -26), Vector2(-4, -26)]), Color("22301f") if not firing else Color(LANTERN, 0.9), 0.5, 0.0, 0.9)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-19, -36), Vector2(19, -36), Vector2(12, -47 - level * 1.5), Vector2(-12, -47 - level * 1.5)]), MOSS, 3.0, 0.55)
	for k: int in 4:
		VectorPaint.line(ci, Vector2(-16 + k * 10.0, -36), Vector2(-11 + k * 7.0, -46 - level * 1.5), Color(MOSS_DARK, 0.8), 0.9)
	_rack(ci, level)
	_banner(ci, Vector2(-17, -6), sin(t * TAU) * 2.0, level)
	if firing:
		_thrown_trap(ci, fire)


## The rack of iron jaw traps hanging on the right wall: one more per level.
static func _rack(ci: CanvasItem, level: int) -> void:
	VectorPaint.line(ci, Vector2(18, -28), Vector2(18, -4), TIMBER_DARK, 1.8)
	for k: int in level + 1:
		var at: Vector2 = Vector2(18, -9.0 - k * 7.0)
		_trap(ci, at, 0.0, 0.8)


static func _trap(ci: CanvasItem, at: Vector2, open: float, scale: float) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(at, 5.0 * scale, 2.2 * scale, 12), IRON, 0.8, 0.4, 0.9)
	for flip: float in [-1.0, 1.0]:
		var jaw: PackedVector2Array = PackedVector2Array([at + Vector2(flip * 4.6 * scale, 0), at + Vector2(flip * 2.0 * scale, -(2.0 + open * 4.0) * scale), at + Vector2(flip * 0.4 * scale, -(0.4 + open * 2.2) * scale)])
		VectorPaint.fill(ci, jaw, IRON_LIGHT)


static func _banner(ci: CanvasItem, pole: Vector2, wave: float, level: int) -> void:
	VectorPaint.line(ci, pole, pole + Vector2(0, -32), TIMBER_DARK, 1.6)
	ci.draw_circle(pole + Vector2(0, -32.5), 1.1, GOLD, true, -1.0, true)
	var cloth: PackedVector2Array = PackedVector2Array([pole + Vector2(0, -31), pole + Vector2(-5, -30 + wave * 0.4), pole + Vector2(-9, -28 + wave), pole + Vector2(-5, -26 + wave * 0.6), pole + Vector2(-9, -23.5 + wave), pole + Vector2(-4, -24 + wave * 0.4), pole + Vector2(0, -24)])
	VectorPaint.painted(ci, cloth, Color("5f9a50") if level < 3 else Color("e8b54e"), 1.4, 0.3, 0.8)


## A trap lobbed out of the upper window: it arcs, spins and lands open on the road.
static func _thrown_trap(ci: CanvasItem, fire: float) -> void:
	var k: float = smoothstep(0.1, 0.9, fire)
	var p: Vector2 = Vector2(-2.0 + k * 30.0, -30.0 - sin(k * PI) * 18.0 + k * 22.0)
	ci.draw_set_transform(p, k * 7.0, Vector2.ONE)
	_trap(ci, Vector2.ZERO, k, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	VectorStyle.draw_glow(ci, LANTERN, Vector2(0, -30), 8.0, 0.5 * (1.0 - fire))


static func paint_hawk_perch(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	VectorStyle.shadow(ci, Vector2(3, 5), 25, 10.0)
	ArcherPainter.plinth(ci, 0.9)
	var firing: bool = fire >= 0.0
	var top: float = -42.0 - level * 3.0
	for flip: float in [-1.0, 1.0]:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(flip * 13 - 1.8, -3), Vector2(flip * 13 + 1.8, -3), Vector2(flip * 6 + 1.4, top), Vector2(flip * 6 - 1.4, top)]), TIMBER, 1.6, 0.5, 1.0)
	for k: int in 4:
		var y: float = -9.0 - k * (absf(top) - 8.0) / 4.0
		VectorPaint.line(ci, Vector2(-13.0 + k * 1.6, y), Vector2(13.0 - k * 1.6, y), TIMBER_DARK, 1.6)
	VectorPaint.line(ci, Vector2(-12, -9), Vector2(8, top + 6), Color(TIMBER_DARK, 0.9), 1.4)
	# The perch bar and the platform it stands on.
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-14, top), Vector2(14, top), Vector2(15, top + 3), Vector2(-15, top + 3)]), TIMBER, 1.2, 0.5, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-6, top - 1), Vector2(22, top - 4), Vector2(22, top - 2.4), Vector2(-6, top + 0.6)]), TIMBER_DARK, 0.6, 0.3, 0.9)
	_rope_ladder(ci, top)
	var away: float = smoothstep(0.0, 0.25, fire) * (1.0 - smoothstep(0.7, 1.0, fire)) if firing else 0.0
	if away < 0.95:
		_hawk(ci, Vector2(0, top - 1.0 - away * 8.0), level, t, away)
	if firing:
		_feathers(ci, Vector2(0, top - 4), fire)
	ci.draw_circle(Vector2(-9, top - 1.4), 1.4, LANTERN, true, -1.0, true)


static func _rope_ladder(ci: CanvasItem, top: float) -> void:
	for flip: float in [-1.0, 1.0]:
		VectorPaint.line(ci, Vector2(14 + flip * 1.6, top + 3), Vector2(16 + flip * 1.6, -4), Color("c9b48a"), 0.9)
	for k: int in 5:
		var y: float = top + 7.0 + k * (absf(top) - 12.0) / 5.0
		VectorPaint.line(ci, Vector2(12.6, y), Vector2(17.6, y), Color("c9b48a"), 0.9)


## The hooded hawk on its perch: folded wings, a hooked beak, the hood in the tower's level colour. `away` spreads its wings and lifts it off.
static func _hawk(ci: CanvasItem, at: Vector2, level: int, t: float, away: float) -> void:
	var flap: float = sin(t * TAU * 3.0 + away * 12.0) * 0.5 + 0.5
	if away > 0.05:
		for flip: float in [-1.0, 1.0]:
			VectorPaint.painted(ci, PackedVector2Array([at + Vector2(flip * 2, -5), at + Vector2(flip * (12 + flap * 3), -9 - flap * 5), at + Vector2(flip * 14, -4 - flap * 2), at + Vector2(flip * 3, -1)]), FEATHER, 1.0, 0.5, 1.0)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -6), 4.6, 6.0, 14), FEATHER, 1.6, 0.5, 1.0)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0.4, -3.6), 2.8, 3.4, 10), FEATHER_LIGHT, 0.6, 0.3, 0.8)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -13), 2.8, 2.9, 10), FEATHER, 0.8, 0.4, 0.9)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(1.6, -13.4), at + Vector2(4.6, -12.2), at + Vector2(1.6, -11.2)]), GOLD)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-2.8, -14.8), at + Vector2(2.8, -14.8), at + Vector2(2.4, -12.4), at + Vector2(-2.4, -12.4)]), Color("c0583e") if level < 3 else GOLD, 0.4, 0.3, 0.7)
	ci.draw_circle(at + Vector2(0.4, -13.6), 0.6, Color("fff2c8"), true, -1.0, true)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-2.4, -1), at + Vector2(2.4, -1), at + Vector2(0, 3)]), FEATHER)


## Feathers falling from the perch after the hawk goes.
static func _feathers(ci: CanvasItem, at: Vector2, fire: float) -> void:
	for k: int in 3:
		var p: Vector2 = at + Vector2((k - 1) * 6.0 + sin(fire * 9.0 + k) * 2.0, fire * 14.0 + k * 3.0)
		ci.draw_circle(p, 1.2, Color(FEATHER_LIGHT, 0.8 * (1.0 - fire)), true, -1.0, true)


static func paint_watchtower(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	VectorStyle.shadow(ci, Vector2(3, 5), 25, 10.0)
	ArcherPainter.plinth(ci, 0.9)
	var firing: bool = fire >= 0.0
	var rise: float = level * 3.0
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-12, -3), Vector2(12, -3), Vector2(9, -30 - rise), Vector2(-9, -30 - rise)]), STONE, 3.0, 0.55)
	for row: int in 5:
		var y: float = -7.0 - row * (23.0 + rise) / 5.0
		VectorPaint.line(ci, Vector2(-11.4 + row * 0.6, y), Vector2(11.4 - row * 0.6, y), Color(VectorStyle.INK, 0.35), 0.9)
	VectorPaint.line(ci, Vector2(-9, -30 - rise), Vector2(-12, -3), Color(1, 1, 1, 0.22), 1.2)
	var deck: float = -30.0 - rise
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-15, deck), Vector2(15, deck), Vector2(15, deck - 3), Vector2(-15, deck - 3)]), TIMBER, 1.2, 0.5, 1.0)
	for x: float in [-13.0, -4.0, 4.0, 13.0]:
		VectorPaint.line(ci, Vector2(x, deck - 3), Vector2(x, deck - 11), TIMBER_DARK, 1.4)
	VectorPaint.line(ci, Vector2(-13, deck - 9), Vector2(13, deck - 9), TIMBER_DARK, 1.2)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-17, deck - 11), Vector2(17, deck - 11), Vector2(0, deck - 24)]), MOSS, 3.0, 0.55)
	var glow: float = 0.5 + 0.1 * sin(t * TAU)
	VectorStyle.draw_glow(ci, LANTERN, Vector2(-9, deck - 6), 12.0, glow)
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-10.4, deck - 8), Vector2(-7.6, deck - 8), Vector2(-7.6, deck - 4), Vector2(-10.4, deck - 4)]), LANTERN)
	if level >= 3:
		VectorStyle.draw_glow(ci, LANTERN, Vector2(9, deck - 6), 10.0, glow)
		VectorPaint.fill(ci, PackedVector2Array([Vector2(7.6, deck - 8), Vector2(10.4, deck - 8), Vector2(10.4, deck - 4), Vector2(7.6, deck - 4)]), LANTERN)
	# The spyglass on the rail, pointing out toward the road.
	VectorPaint.painted(ci, PackedVector2Array([Vector2(1, deck - 7), Vector2(11, deck - 10), Vector2(11, deck - 7.6), Vector2(1, deck - 5.2)]), Color("b0793a"), 0.6, 0.4, 0.9)
	_pennant(ci, Vector2(0, deck - 24), sin(t * TAU) * 1.6)
	if firing:
		_flash(ci, Vector2(12, deck - 9), fire)


static func _pennant(ci: CanvasItem, pole: Vector2, wave: float) -> void:
	VectorPaint.line(ci, pole, pole + Vector2(0, -10), TIMBER_DARK, 1.2)
	VectorPaint.painted(ci, PackedVector2Array([pole + Vector2(0, -10), pole + Vector2(9, -8.5 + wave * 0.6), pole + Vector2(0, -6)]), Color("5f9a50"), 0.8, 0.3, 0.7)


## The spyglass flashes and a crosshair of light marks the target above the tower.
static func _flash(ci: CanvasItem, at: Vector2, fire: float) -> void:
	var k: float = 1.0 - fire
	VectorStyle.draw_glow(ci, Color("fff2c8"), at, 6.0 + k * 10.0, 0.9 * k)
	for a: float in [0.0, PI * 0.5]:
		var d: Vector2 = Vector2.from_angle(a + fire * 0.8)
		ci.draw_line(at - d * (4.0 + k * 8.0), at + d * (4.0 + k * 8.0), Color(1, 0.95, 0.75, k), 1.2, true)
