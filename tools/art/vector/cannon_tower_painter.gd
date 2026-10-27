class_name CannonTowerPainter
## Paints the vector Cannon tower (M15): a squat round stone bastion with a parapet and merlons, a bronze cannon on a
## wooden carriage that points toward the road, powder kegs, a lit embrasure and a red banner. Level 2 adds iron bands and
## a second, smaller gun; level 3 gold trim and a bigger barrel. paint() is one sheet frame: idle (banner, a wisp of
## smoke), fire (recoil, a muzzle flash and a smoke ring). Pose units: the slot at (0, 0), about 52 tall.

const STONE: Color = Color("a39787")
const STONE_ALT: Color = Color("8a7e70")
const BRONZE: Color = Color("b8793a")
const BRONZE_LIGHT: Color = Color("e3a85a")
const IRON: Color = Color("4a4a54")
const WOOD: Color = Color("7d5230")
const RED: Color = Color("ac2b2a")
const GOLD: Color = Color("e8b54e")
const DECK: Vector2 = Vector2(0, -34)
const AIM: float = 0.45


static func paint(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	VectorStyle.shadow(ci, Vector2(3, 5), 30, 11)
	ArcherPainter.plinth(ci, 1.05)
	_drum(ci, level)
	_parapet(ci, level)
	_kegs(ci)
	_banner(ci, sin(t * TAU) * 2.0)
	var firing: bool = fire >= 0.0
	var recoil: float = 0.0
	if firing:
		recoil = (1.0 - smoothstep(0.0, 0.25, fire)) * 0.0 + (smoothstep(0.0, 0.12, fire) * (1.0 - smoothstep(0.12, 0.6, fire)))
	if level >= 2:
		_cannon(ci, DECK + Vector2(-10, 3), AIM + 0.15, 0.7, recoil * 0.5, false)
	_cannon(ci, DECK + Vector2(2, -3), AIM, 1.0 + (0.18 if level >= 3 else 0.0), recoil, level >= 3)
	VectorStyle.draw_glow(ci, VectorStyle.WARM_GLOW, Vector2(0, -20), 10.0, 0.5)
	VectorStyle.draw_glow(ci, VectorStyle.WARM_GLOW, DECK, 28.0, 0.12)
	if firing and fire < 0.7:
		_blast(ci, DECK + Vector2(2, -3), fire)
	elif not firing:
		_wisp(ci, DECK + Vector2(2, -3) + Vector2.from_angle(AIM) * 18.0, t)


static func _drum(ci: CanvasItem, level: int) -> void:
	var body: PackedVector2Array = PackedVector2Array([Vector2(-19, -3), Vector2(19, -3), Vector2(17.5, -31), Vector2(-17.5, -31)])
	VectorPaint.painted(ci, body, STONE, 4.0, 0.55)
	for row: int in 5:
		var y: float = -6.0 - row * 5.0
		VectorPaint.line(ci, Vector2(-18.4 + row * 0.3, y), Vector2(18.4 - row * 0.3, y), Color(VectorStyle.INK, 0.4), 0.9)
		var off: float = 5.0 if row % 2 == 0 else -2.0
		for x: float in [-12.0 + off, -2.0 + off, 8.0 + off]:
			VectorPaint.line(ci, Vector2(x, y), Vector2(x, y - 5.0), Color(VectorStyle.INK, 0.3), 0.8)
	for k: int in 4:
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(-14.0 + k * 9.0, -4.0 - (k % 2)), 3.0, 1.4, 10), Color("5a7a3f"), 0.6, 0.0, 0.0)
	VectorPaint.line(ci, Vector2(-17.5, -31), Vector2(-19, -3), Color(1, 0.95, 0.85, 0.22), 1.4)
	# The embrasure, lit from inside.
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-2.4, -22), Vector2(2.4, -22), Vector2(2.4, -13), Vector2(-2.4, -13)]), Color("ffb84d"), 0.6, 0.0, 0.9)
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-0.8, -21), Vector2(0.8, -21), Vector2(0.8, -14), Vector2(-0.8, -14)]), Color("fff0c8"))
	if level >= 2:
		for y: float in [-9.0, -24.0]:
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-19.0 + (y + 3.0) * -0.07, y), Vector2(19.0 - (y + 3.0) * -0.07, y), Vector2(19.0 - (y + 3.0) * -0.07, y - 2.4), Vector2(-19.0 + (y + 3.0) * -0.07, y - 2.4)]),
				GOLD if level >= 3 else IRON, 0.8, 0.0, 0.7)
			for x: float in [-14.0, 0.0, 14.0]:
				VectorPaint.rivet(ci, Vector2(x, y - 1.2), 0.8)


static func _parapet(ci: CanvasItem, level: int) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -32), 20, 8.5, 30), Color("6b6f78"), 2.6, 0.5)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -33), 16.5, 6.6, 28), WOOD, 2.0, 0.4)
	for k: int in 7:
		var a: float = PI + 0.12 + k * (PI - 0.24) / 6.0
		var at: Vector2 = Vector2(cos(a) * 19.0, -32.0 + sin(a) * 8.0)
		VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-2.7, 0), at + Vector2(2.7, 0), at + Vector2(2.7, -5.5), at + Vector2(-2.7, -5.5)]), STONE_ALT if k % 2 == 0 else STONE, 1.0, 0.4, 0.7)
		if level >= 3:
			VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-2.9, -5.5), at + Vector2(2.9, -5.5), at + Vector2(2.9, -6.8), at + Vector2(-2.9, -6.8)]), GOLD, 0.5, 0.0, 0.5)


static func _kegs(ci: CanvasItem) -> void:
	for at: Vector2 in [Vector2(-13, -38), Vector2(-8, -35)]:
		VectorPaint.painted(ci, VectorStyle.ellipse(at, 3.4, 4.0, 14), WOOD, 1.6, 0.4)
		VectorPaint.line(ci, at + Vector2(-3.2, -1.2), at + Vector2(3.2, -1.2), IRON, 1.0)
		VectorPaint.line(ci, at + Vector2(-3.2, 1.4), at + Vector2(3.2, 1.4), IRON, 1.0)
	ci.draw_circle(Vector2(-10.5, -41), 1.3, Color("e5541e"), true, -1.0, true)


static func _banner(ci: CanvasItem, wave: float) -> void:
	var pole: Vector2 = Vector2(13, -35)
	VectorPaint.line(ci, pole, pole + Vector2(0, -22), Color("4a2e1c"), 1.6)
	ci.draw_circle(pole + Vector2(0, -22.5), 1.1, GOLD, true, -1.0, true)
	var cloth: PackedVector2Array = PackedVector2Array([pole + Vector2(0, -21), pole + Vector2(6, -20 + wave * 0.5), pole + Vector2(12, -18 + wave), pole + Vector2(8, -16 + wave * 0.6),
		pole + Vector2(12, -13.5 + wave), pole + Vector2(5, -14 + wave * 0.4), pole + Vector2(0, -14)])
	VectorPaint.painted(ci, cloth, RED, 1.4, 0.3, 0.8)


## The gun: a carriage with wheels, a bronze barrel with reinforcing rings, a muzzle flare and a touch hole.
static func _cannon(ci: CanvasItem, at: Vector2, angle: float, size: float, recoil: float, gold: bool) -> void:
	var dir: Vector2 = Vector2.from_angle(angle)
	var side: Vector2 = dir.orthogonal()
	var back: Vector2 = at - dir * recoil * 5.0 * size
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, 2), 9.5 * size, 4.4 * size, 16), WOOD, 1.8, 0.4)
	for s: float in [-1.0, 1.0]:
		var wheel: Vector2 = at + Vector2(s * 6.5 * size, 3)
		VectorPaint.painted(ci, VectorStyle.ellipse(wheel, 2.8 * size, 3.6 * size, 12), IRON, 1.0, 0.4, 0.9)
		ci.draw_circle(wheel, 0.9 * size, BRONZE_LIGHT, true, -1.0, true)
	var length: float = 19.0 * size
	var breech: float = 5.2 * size
	var muzzle: float = 6.4 * size
	var barrel: PackedVector2Array = PackedVector2Array([back - side * breech * 0.5 - dir * 3.0, back + side * breech * 0.5 - dir * 3.0, back + dir * length + side * muzzle * 0.5,
		back + dir * length - side * muzzle * 0.5])
	VectorPaint.painted(ci, barrel, BRONZE, 2.6, 0.55)
	for k: float in [0.25, 0.55, 0.85]:
		var c: Vector2 = back + dir * length * k
		var w: float = lerpf(breech, muzzle, k) * 0.5 + 0.8
		VectorPaint.line(ci, c - side * w, c + side * w, GOLD if gold else IRON, 1.8)
	ci.draw_circle(back - dir * 3.0, breech * 0.5, BRONZE_LIGHT, true, -1.0, true)
	ci.draw_colored_polygon(VectorStyle.ellipse(back + dir * length, 1.4 * size, muzzle * 0.45, 10), Color("1a1015"))
	VectorStyle.shine(ci, back + dir * length * 0.4 - side * breech * 0.2, 4.0 * size, 1.0, 0.4)


static func _blast(ci: CanvasItem, at: Vector2, fire: float) -> void:
	var muzzle: Vector2 = at + Vector2.from_angle(AIM) * 22.0
	var k: float = 1.0 - fire / 0.7
	VectorStyle.draw_glow(ci, Color("ffb050"), muzzle, 18.0 * (0.6 + k), 0.9 * k)
	VectorStyle.draw_glow(ci, Color("fff3c0"), muzzle, 8.0 * k, k)
	for i: int in 4:
		var puff: Vector2 = muzzle + Vector2.from_angle(AIM + (i - 1.5) * 0.35) * (4.0 + fire * 18.0) + Vector2(0, -fire * 6.0)
		ci.draw_circle(puff, 3.0 + fire * 6.0, Color(0.7, 0.68, 0.66, 0.35 * (1.0 - fire)), true, -1.0, true)


static func _wisp(ci: CanvasItem, at: Vector2, t: float) -> void:
	for i: int in 3:
		var k: float = fmod(t + i / 3.0, 1.0)
		ci.draw_circle(at + Vector2(sin(i * 2.0 + t * TAU) * 1.5, -k * 12.0), 1.6 + k * 2.4, Color(0.75, 0.73, 0.72, 0.3 * (1.0 - k)), true, -1.0, true)
