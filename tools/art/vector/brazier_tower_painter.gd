class_name BrazierTowerPainter
## Paints the vector Brazier tower (M15): a squat stone pedestal under a wide iron bowl heaped with burning pitch and logs,
## a roaring layered flame, drifting embers, a pitch pot beside it and a red banner. Level 2 adds a taller flame and iron
## legs, level 3 a gold rim and a second flame crown. paint() is one sheet frame: idle (the flames dance), fire (a surge
## of flame and a fireball lobbed up and out). Pose units: the slot at (0, 0), about 58 tall.

const STONE: Color = Color("9a8d7e")
const IRON: Color = Color("464650")
const IRON_LIGHT: Color = Color("7a7a88")
const PITCH: Color = Color("1c1216")
const RED: Color = Color("ac2b2a")
const GOLD: Color = Color("e8b54e")
const BOWL: Vector2 = Vector2(0, -30)
const FLAME_COLORS: Array[Color] = [Color("c8341a"), Color("f07a24"), Color("ffc54a"), Color("fff3c0")]


static func paint(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	var firing: bool = fire >= 0.0
	var surge: float = (smoothstep(0.0, 0.2, fire) * (1.0 - smoothstep(0.2, 0.75, fire))) if firing else 0.0
	VectorStyle.shadow(ci, Vector2(3, 5), 27, 10.5)
	ArcherPainter.plinth(ci, 0.95)
	_pedestal(ci, level)
	_pot(ci)
	_banner(ci, sin(t * TAU) * 2.0)
	_bowl(ci, level)
	var heat: float = 1.0 + (level - 1) * 0.22 + surge * 0.7
	_flames(ci, t, heat, level)
	VectorStyle.draw_glow(ci, Color("ff9a30"), BOWL + Vector2(0, -10), 30.0 * heat, 0.4 + surge * 0.3)
	VectorStyle.draw_glow(ci, Color("ffe08a"), BOWL + Vector2(0, -8), 10.0 * heat, 0.55)
	for i: int in 5:
		var k: float = fmod(t * 1.3 + i * 0.21, 1.0)
		var p: Vector2 = BOWL + Vector2(sin(i * 2.4 + t * 6.0) * 6.0, -8.0 - k * 26.0 * heat)
		VectorStyle.draw_glow(ci, Color("ffb050"), p, 2.0 + (1.0 - k) * 1.2, 0.9 * (1.0 - k))
	if firing:
		_fireball(ci, fire)


static func _pedestal(ci: CanvasItem, level: int) -> void:
	var body: PackedVector2Array = PackedVector2Array([Vector2(-14, -3), Vector2(14, -3), Vector2(11, -22), Vector2(-11, -22)])
	VectorPaint.painted(ci, body, STONE, 3.2, 0.55)
	for row: int in 3:
		var y: float = -7.0 - row * 5.5
		VectorPaint.line(ci, Vector2(-13.4 + row, y), Vector2(13.4 - row, y), Color(VectorStyle.INK, 0.4), 0.9)
		var off: float = 4.0 if row % 2 == 0 else -2.0
		VectorPaint.line(ci, Vector2(off - 5.0, y), Vector2(off - 5.0, y - 5.5), Color(VectorStyle.INK, 0.3), 0.8)
		VectorPaint.line(ci, Vector2(off + 5.0, y), Vector2(off + 5.0, y - 5.5), Color(VectorStyle.INK, 0.3), 0.8)
	VectorPaint.line(ci, Vector2(-11, -22), Vector2(-14, -3), Color(1, 1, 1, 0.22), 1.3)
	if level >= 2:
		for x: float in [-9.0, 9.0]:
			VectorPaint.limb(ci, Vector2(x, -22), Vector2(x * 1.3, -12), Vector2(x * 1.15, -2), 2.4, IRON)


static func _bowl(ci: CanvasItem, level: int) -> void:
	var bowl: PackedVector2Array = PackedVector2Array([Vector2(-16, -29), Vector2(16, -29), Vector2(11, -20), Vector2(-11, -20)])
	VectorPaint.painted(ci, bowl, IRON, 3.0, 0.6)
	VectorPaint.painted(ci, VectorStyle.ellipse(BOWL + Vector2(0, -1), 16.5, 5.0, 24), GOLD if level >= 3 else IRON_LIGHT, 1.4, 0.4)
	VectorPaint.painted(ci, VectorStyle.ellipse(BOWL + Vector2(0, -1.4), 13.5, 3.8, 22), PITCH, 1.0, 0.0, 0.0)
	for x: float in [-9.0, -3.0, 4.0, 10.0]:
		VectorPaint.rivet(ci, Vector2(x, -24.5), 0.8)
	# Logs heaped in the bowl, glowing at their cut ends.
	for k: int in 3:
		var a: float = -0.5 + k * 0.5
		var c: Vector2 = BOWL + Vector2(k * 5.0 - 5.0, -2.0)
		VectorPaint.painted(ci, PackedVector2Array([c + Vector2(-5, -1) .rotated(a), c + Vector2(5, -1).rotated(a), c + Vector2(5, 1.4).rotated(a), c + Vector2(-5, 1.4).rotated(a)]), Color("5a3a22"), 0.8, 0.3, 0.7)
		ci.draw_circle(c + Vector2(5, 0).rotated(a), 1.3, Color("ff9a30"), true, -1.0, true)


static func _flames(ci: CanvasItem, t: float, heat: float, level: int) -> void:
	var crowns: int = 2 if level >= 3 else 1
	for crown: int in crowns:
		var base: Vector2 = BOWL + Vector2((crown - (crowns - 1) * 0.5) * 7.0, -4.0)
		for layer: int in 4:
			var s: float = (1.0 - layer * 0.22) * heat
			var tongues: int = 4 - int(layer * 0.5)
			for i: int in tongues:
				var phase: float = t * TAU * (1.0 + i * 0.25) + i * 1.7 + layer + crown * 2.0
				var sway: float = sin(phase) * 2.6 * s
				var h: float = (16.0 + sin(phase * 1.7) * 3.0) * s * (1.0 - absf(i - (tongues - 1) * 0.5) * 0.22)
				var x: float = (i - (tongues - 1) * 0.5) * 5.4 * s
				var tip: Vector2 = base + Vector2(x * 0.6 + sway, -h)
				var left: Vector2 = base + Vector2(x - 4.4 * s, 0)
				var right: Vector2 = base + Vector2(x + 4.4 * s, 0)
				VectorPaint.fill(ci, PackedVector2Array([left, base + Vector2(x - 3.0 * s + sway * 0.3, -h * 0.5), tip, base + Vector2(x + 3.0 * s + sway * 0.3, -h * 0.5), right, base + Vector2(x, 1.5)]), FLAME_COLORS[layer])


static func _pot(ci: CanvasItem) -> void:
	var at: Vector2 = Vector2(-18, -4)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -3), 4.6, 5.0, 14), IRON, 1.6, 0.5)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -7), 4.0, 1.5, 12), PITCH, 0.6, 0.0, 0.0)
	ci.draw_circle(at + Vector2(1.2, -7.4), 0.8, Color("ff9a30"), true, -1.0, true)


static func _banner(ci: CanvasItem, wave: float) -> void:
	var pole: Vector2 = Vector2(17, -6)
	VectorPaint.line(ci, pole, pole + Vector2(0, -34), Color("4a2e1c"), 1.6)
	ci.draw_circle(pole + Vector2(0, -34.5), 1.1, GOLD, true, -1.0, true)
	var cloth: PackedVector2Array = PackedVector2Array([pole + Vector2(0, -33), pole + Vector2(5, -32 + wave * 0.4), pole + Vector2(10, -30 + wave), pole + Vector2(6, -28 + wave * 0.6),
		pole + Vector2(10, -25.5 + wave), pole + Vector2(4, -26 + wave * 0.4), pole + Vector2(0, -26)])
	VectorPaint.painted(ci, cloth, RED, 1.4, 0.3, 0.8)


## A burning ball thrown up and out toward the road.
static func _fireball(ci: CanvasItem, fire: float) -> void:
	var k: float = smoothstep(0.15, 0.85, fire)
	var p: Vector2 = BOWL + Vector2(k * 26.0, -10.0 - sin(k * PI) * 22.0 + k * 10.0)
	for i: int in 4:
		var back: Vector2 = p - Vector2(8.0 * i * 0.5, -4.0 * i * 0.4 + 0.0)
		VectorStyle.draw_glow(ci, Color("ff8a30"), back, 5.0 - i, 0.5 - i * 0.1)
	VectorPaint.painted(ci, VectorStyle.ellipse(p, 3.6, 3.6, 12), Color("ff9a30"), 1.2, 0.0, 0.7)
	ci.draw_circle(p + Vector2(-0.6, -0.6), 1.6, Color("fff3c0"), true, -1.0, true)
	VectorStyle.draw_glow(ci, Color("ffb050"), p, 12.0, 0.8 * (1.0 - fire * 0.5))
