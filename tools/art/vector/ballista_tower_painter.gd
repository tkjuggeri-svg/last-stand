class_name BallistaTowerPainter
## Paints the vector Bone Ballista tower (M15): a heavy wooden siege crossbow on a stone mount, its bow arms made of curved
## bone lashed with rope and sinew, twisted torsion skeins on iron hubs, a skull ornament, a long bone-tipped bolt on the
## rail and a red pennant. Level 2 adds a second bolt and iron fittings, level 3 gold fittings and a larger bow. paint() is one
## sheet frame: idle (a slow creak of the string), fire (the arms snap forward, the string flies slack, the bolt is gone and
## the mount recoils, then it is drawn back). Pose units: the slot at (0, 0), about 54 tall.

const STONE: Color = Color("918779")
const WOOD: Color = Color("86592f")
const WOOD_DARK: Color = Color("4a2e1c")
const BONE: Color = Color("e8dcc0")
const BONE_DARK: Color = Color("a99d82")
const IRON: Color = Color("474751")
const ROPE: Color = Color("c9a565")
const RED: Color = Color("ac2b2a")
const GOLD: Color = Color("e8b54e")
const MOUNT: Vector2 = Vector2(0, -26)
const AIM: float = 0.5


static func paint(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	var firing: bool = fire >= 0.0
	# `draw` is how far the string is drawn back: 1 at rest, 0 just after the shot, 1 again once reloaded.
	var draw: float = 1.0 - sin(t * TAU) * 0.04
	var shot: float = 0.0
	if firing:
		draw = smoothstep(0.35, 1.0, fire) if fire > 0.12 else 1.0 - fire / 0.12
		shot = (1.0 - smoothstep(0.0, 0.5, fire)) * smoothstep(0.0, 0.1, fire)
	VectorStyle.shadow(ci, Vector2(3, 5), 27, 10.5)
	ArcherPainter.plinth(ci, 0.95)
	_mount(ci, level)
	_pennant(ci, sin(t * TAU) * 2.0)
	_bow(ci, level, draw)
	if not firing or fire < 0.12:
		_bolt(ci, level, draw)
	if firing and fire >= 0.12 and fire < 0.6:
		_bolt_flight(ci, fire)
	VectorStyle.draw_glow(ci, VectorStyle.WARM_GLOW, Vector2(0, -16), 9.0, 0.4)
	if shot > 0.0:
		VectorStyle.draw_glow(ci, Color("fff1c8"), MOUNT + Vector2.from_angle(AIM) * 18.0, 12.0 * shot, shot)


static func _mount(ci: CanvasItem, level: int) -> void:
	var base: PackedVector2Array = PackedVector2Array([Vector2(-13, -3), Vector2(13, -3), Vector2(10, -19), Vector2(-10, -19)])
	VectorPaint.painted(ci, base, STONE, 3.0, 0.55)
	for row: int in 3:
		var y: float = -7.0 - row * 4.6
		VectorPaint.line(ci, Vector2(-12.4 + row, y), Vector2(12.4 - row, y), Color(VectorStyle.INK, 0.4), 0.9)
	VectorPaint.line(ci, Vector2(-10, -19), Vector2(-13, -3), Color(1, 1, 1, 0.2), 1.3)
	# The wooden turntable and the post.
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -20), 15, 5.6, 22), WOOD, 2.0, 0.45)
	for k: int in 6:
		VectorPaint.line(ci, Vector2(-13 + k * 5.2, -23.0 + absf(k - 2.5) * 0.4), Vector2(-13 + k * 5.2, -17.0 - absf(k - 2.5) * 0.4), Color(VectorStyle.INK, 0.35), 0.7)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-3.4, -20), Vector2(3.4, -20), Vector2(2.6, -29), Vector2(-2.6, -29)]), WOOD, 1.6, 0.4)
	VectorPaint.painted(ci, VectorStyle.ellipse(MOUNT + Vector2(0, -3), 5.0, 3.6, 12), GOLD if level >= 3 else IRON, 1.0, 0.4, 0.8)


## The bow: a stock along the aim, two bone arms swept forward, rope and sinew skeins at the hubs, the string to the nock.
static func _bow(ci: CanvasItem, level: int, draw: float) -> void:
	var dir: Vector2 = Vector2.from_angle(AIM)
	var side: Vector2 = dir.orthogonal()
	var size: float = 1.0 + (0.14 if level >= 3 else 0.0)
	var hub: Vector2 = MOUNT + dir * 6.0 * size - Vector2(0, 3)
	var span: float = 15.0 * size
	var sweep: float = (1.0 - draw) * 5.0 + 3.0
	# The stock (the rail the bolt rides).
	var stock: PackedVector2Array = PackedVector2Array([MOUNT - dir * 9.0 - side * 1.7 - Vector2(0, 3), MOUNT + dir * 17.0 * size - side * 1.2 - Vector2(0, 3),
		MOUNT + dir * 17.0 * size + side * 1.2 - Vector2(0, 3), MOUNT - dir * 9.0 + side * 1.7 - Vector2(0, 3)])
	VectorPaint.painted(ci, stock, WOOD, 1.6, 0.5)
	VectorPaint.line(ci, MOUNT - dir * 8.0 - Vector2(0, 4.4), MOUNT + dir * 16.0 * size - Vector2(0, 4.4), Color(1, 1, 1, 0.25), 0.7)
	for s: float in [-1.0, 1.0]:
		var tip: Vector2 = hub + side * s * span + dir * sweep
		var mid: Vector2 = hub + side * s * span * 0.55 + dir * (sweep * 0.25 - 1.5)
		VectorPaint.strand(ci, hub, mid, tip, 4.8, BONE_DARK)
		VectorPaint.strand(ci, hub, hub.lerp(mid, 0.5) + dir * 0.4, tip, 3.4, BONE)
		for k: int in 4:
			var q: Vector2 = hub.lerp(tip, 0.18 + k * 0.2)
			VectorPaint.line(ci, q - dir * 1.8, q + dir * 1.8, ROPE, 1.1)
		VectorPaint.painted(ci, VectorStyle.ellipse(hub + side * s * 4.0, 3.4, 3.0, 12), GOLD if level >= 3 else IRON, 1.0, 0.4, 0.8)
		for k: int in 3:
			var a: float = -0.6 + k * 0.6
			VectorPaint.line(ci, hub + side * s * 4.0 + Vector2(-2.4, a * 2.4), hub + side * s * 4.0 + Vector2(2.4, a * 2.4), ROPE, 0.9)
	var nock: Vector2 = MOUNT - dir * (1.0 + draw * 4.0) - Vector2(0, 3)
	var tip_a: Vector2 = hub + side * span + dir * sweep
	var tip_b: Vector2 = hub - side * span + dir * sweep
	ci.draw_polyline(PackedVector2Array([tip_a, nock, tip_b]), Color(0.95, 0.9, 0.8, 0.9), 0.9, true)
	# A skull ornament on the stock's front, and a pennant's pole socket.
	VectorPaint.painted(ci, VectorStyle.ellipse(MOUNT + dir * 14.0 * size - Vector2(0, 7), 3.2, 3.0, 12), BONE, 1.0, 0.6, 0.8)
	ci.draw_circle(MOUNT + dir * 14.0 * size - Vector2(1.0, 7.4), 0.7, Color("1a1015"), true, -1.0, true)
	ci.draw_circle(MOUNT + dir * 14.0 * size - Vector2(-1.0, 7.4), 0.7, Color("1a1015"), true, -1.0, true)


static func _bolt(ci: CanvasItem, level: int, draw: float) -> void:
	var dir: Vector2 = Vector2.from_angle(AIM)
	var side: Vector2 = dir.orthogonal()
	var at: Vector2 = MOUNT - dir * (1.0 + draw * 4.0) - Vector2(0, 5.4)
	for i: int in (2 if level >= 2 else 1):
		var origin: Vector2 = at + Vector2(0, -i * 2.2)
		VectorPaint.line(ci, origin, origin + dir * 26.0, BONE, 1.8)
		VectorPaint.fill(ci, PackedVector2Array([origin + dir * 28.5, origin + dir * 24.5 + side * 1.9, origin + dir * 24.5 - side * 1.9]), Color("d9dee6"))
		VectorPaint.fill(ci, PackedVector2Array([origin, origin + dir * 3.0 + side * 1.6, origin + dir * 3.0 - side * 1.6]), RED)
		VectorPaint.line(ci, origin + dir * 1.0, origin + dir * 24.0, Color(1, 1, 1, 0.4), 0.6)


## The bolt in flight just after the shot: it speeds along the aim, out of the sheet's frame soon after.
static func _bolt_flight(ci: CanvasItem, fire: float) -> void:
	var dir: Vector2 = Vector2.from_angle(AIM)
	var k: float = (fire - 0.12) / 0.48
	var start: Vector2 = MOUNT + dir * 16.0 - Vector2(0, 5.4)
	var at: Vector2 = start + dir * (4.0 + k * 40.0)
	VectorStyle.draw_glow(ci, Color("fff1c8"), at, 6.0, 0.6 * (1.0 - k))
	VectorPaint.line(ci, at - dir * 14.0, at, BONE, 1.6)
	VectorPaint.fill(ci, PackedVector2Array([at + dir * 3.0, at - dir * 1.0 + dir.orthogonal() * 1.8, at - dir * 1.0 - dir.orthogonal() * 1.8]), Color("d9dee6"))


static func _pennant(ci: CanvasItem, wave: float) -> void:
	var pole: Vector2 = Vector2(-14, -8)
	VectorPaint.line(ci, pole, pole + Vector2(0, -36), WOOD_DARK, 1.6)
	ci.draw_circle(pole + Vector2(0, -36.5), 1.1, GOLD, true, -1.0, true)
	var cloth: PackedVector2Array = PackedVector2Array([pole + Vector2(0, -35), pole + Vector2(6, -34 + wave * 0.4), pole + Vector2(12, -32 + wave), pole + Vector2(8, -30 + wave * 0.6),
		pole + Vector2(12, -27.5 + wave), pole + Vector2(5, -28 + wave * 0.4), pole + Vector2(0, -28)])
	VectorPaint.painted(ci, cloth, RED, 1.4, 0.3, 0.8)
