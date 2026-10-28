class_name NecroTowerPainter
## Paints the Necromancer's three towers in vector (M15 P3, docs/M15_P3_HEROES.md): the Bone Pit (a ring of fused bone around a
## pit of teal fire, skeletal hands reaching up and clawing), the Soul Siphon (a crooked bone pylon holding a caged soul that
## fires a beam of soul light) and the Ossuary (a stacked-skull shrine whose crypt door opens on a skeleton). Pale teal like the
## hero's soul fire. Each paint_*() is one sheet frame: (ci, level 1-3, t the idle phase 0..1, fire -1 while idle or 0..1 through the
## shot). Pose units: the slot at (0, 0), about 58 tall.

const BONE: Color = Color("e2dcc2")
const BONE_DARK: Color = Color("9a9279")
const BONE_SHADE: Color = Color("5f5944")
const SOUL: Color = Color("8ff0dc")
const SOUL_DEEP: Color = Color("2f8f86")
const SOUL_LIGHT: Color = Color("eafff8")
const CRYPT: Color = Color("6f6a7a")
const CRYPT_DARK: Color = Color("3b3846")
const IRON: Color = Color("55565f")
const GOLD: Color = Color("e8b54e")


static func paint_bone_pit(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	VectorStyle.shadow(ci, Vector2(3, 5), 27, 10.5)
	ArcherPainter.plinth(ci, 1.0)
	var firing: bool = fire >= 0.0
	var surge: float = (smoothstep(0.0, 0.25, fire) * (1.0 - smoothstep(0.25, 0.8, fire))) if firing else 0.0
	# The back half of the ring, the pit, the hands, then the front half of the ring.
	_ring_half(ci, true, level)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -14), 15.0, 6.0, 24), Color("0f2224"), 1.0, 0.0, 1.0)
	VectorStyle.draw_glow(ci, SOUL, Vector2(0, -16), 22.0 + surge * 14.0, 0.45 + surge * 0.35)
	VectorStyle.draw_glow(ci, SOUL_LIGHT, Vector2(0, -15), 8.0, 0.5)
	for k: int in 2 + level:
		var x: float = lerpf(-9.0, 9.0, (k + 0.5) / (2 + level))
		var reach: float = 14.0 + sin(t * TAU + k * 1.7) * 2.0 + surge * 12.0
		_hand(ci, Vector2(x, -14), reach, (x / 9.0) * 0.35, surge)
	for i: int in 4:
		var k: float = fmod(t * 1.2 + i * 0.27, 1.0)
		VectorStyle.draw_glow(ci, SOUL, Vector2(sin(i * 2.1 + t * 5.0) * 7.0, -16.0 - k * 22.0), 2.0 + (1.0 - k), 0.8 * (1.0 - k))
	_ring_half(ci, false, level)
	if level >= 3:
		_skull(ci, Vector2(0, -33), 5.0)
	if firing:
		VectorStyle.draw_glow(ci, SOUL, Vector2(0, -20), 30.0 * surge + 6.0, 0.5 * surge)


## One half of the ring of fused bone: knuckled vertebrae in a curve around the pit.
static func _ring_half(ci: CanvasItem, back: bool, level: int) -> void:
	var count: int = 7 + level
	for i: int in count:
		var a: float = (PI if back else 0.0) + PI * (i + 0.5) / count
		var p: Vector2 = Vector2(cos(a) * 17.0, -10.0 + sin(a) * 6.5 - (0.0 if back else 0.0))
		var r: float = 3.4 + (0.6 if i % 2 == 0 else 0.0)
		VectorPaint.painted(ci, VectorStyle.ellipse(p, r, r * 0.9, 10), BONE if not back else BONE_DARK, 1.0, 0.5, 0.9)
		if not back and i % 2 == 1:
			VectorPaint.fill(ci, PackedVector2Array([p + Vector2(-1.2, -r), p + Vector2(1.2, -r), p + Vector2(0, -r - 3.2)]), BONE)


## A skeletal hand rising from the pit: a forearm of bone and a clawed hand that curls as it strikes.
static func _hand(ci: CanvasItem, base: Vector2, reach: float, lean: float, claw: float) -> void:
	var tip: Vector2 = base + Vector2(lean * reach, -reach)
	VectorPaint.limb(ci, base, base.lerp(tip, 0.55) + Vector2(lean * 2.0, 0), tip, 3.4, BONE_DARK)
	for k: int in 3:
		var a: float = -PI * 0.5 + (k - 1) * (0.5 + claw * 0.4) + lean
		VectorPaint.line(ci, tip, tip + Vector2.from_angle(a) * (4.0 + claw * 2.0), BONE, 1.3)
	VectorPaint.painted(ci, VectorStyle.ellipse(tip, 2.2, 2.0, 8), BONE, 0.5, 0.3, 0.8)


static func _skull(ci: CanvasItem, at: Vector2, r: float) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(at, r, r * 0.95, 14), BONE, 1.2, 0.5, 1.0)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, r * 0.7), r * 0.6, r * 0.4, 10), BONE_DARK, 0.4, 0.2, 0.7)
	for x: float in [-1.0, 1.0]:
		VectorPaint.fill(ci, VectorStyle.ellipse(at + Vector2(x * r * 0.4, -r * 0.1), r * 0.26, r * 0.3, 8), Color("123a3a"))
		VectorStyle.draw_glow(ci, SOUL, at + Vector2(x * r * 0.4, -r * 0.1), r * 0.7, 0.7)


static func paint_soul_siphon(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	VectorStyle.shadow(ci, Vector2(3, 5), 25, 10.0)
	ArcherPainter.plinth(ci, 0.9)
	var firing: bool = fire >= 0.0
	var pulse: float = 0.5 + 0.5 * sin(t * TAU)
	var surge: float = (smoothstep(0.0, 0.2, fire) * (1.0 - smoothstep(0.2, 0.7, fire))) if firing else 0.0
	var top: float = -40.0 - level * 3.0
	# The crooked pylon: a spine of vertebrae leaning and bending up to the cage.
	for i: int in 9:
		var k: float = i / 8.0
		var p: Vector2 = Vector2(sin(k * 3.0) * 4.0 - k * 2.0, lerpf(-4.0, top, k))
		var r: float = lerpf(5.4, 3.0, k)
		VectorPaint.painted(ci, VectorStyle.ellipse(p, r, r * 0.8, 10), BONE if i % 2 == 0 else BONE_DARK, 1.0, 0.5, 0.9)
	for flip: float in [-1.0, 1.0]:
		VectorPaint.limb(ci, Vector2(flip * 2.0, -8), Vector2(flip * 10.0, -16), Vector2(flip * 15.0, -5), 2.8, BONE_DARK)
		_node(ci, Vector2(flip * 17.0, -4.0), pulse)
	# The cage of rib bones holding the soul.
	var cage: Vector2 = Vector2(sin(3.0) * 4.0 - 2.0, top - 6.0)
	VectorStyle.draw_glow(ci, SOUL, cage, 18.0 + surge * 12.0 + pulse * 3.0, 0.5 + surge * 0.4)
	VectorPaint.painted(ci, VectorStyle.ellipse(cage, 6.0, 6.4, 16), Color("0f2224"), 0.6, 0.0, 0.8)
	VectorPaint.painted(ci, VectorStyle.ellipse(cage, 3.4 + pulse * 0.6, 3.6 + pulse * 0.6, 12), SOUL, 0.8, 0.5, 0.0)
	ci.draw_circle(cage + Vector2(-0.8, -1.0), 1.4, SOUL_LIGHT, true, -1.0, true)
	for k: float in [-1.0, -0.4, 0.4, 1.0]:
		VectorPaint.strand(ci, cage + Vector2(k * 5.6, 5.6), cage + Vector2(k * 7.6, 0), cage + Vector2(k * 4.0, -6.0), 2.2, BONE)
	if level >= 3:
		_skull(ci, cage + Vector2(0, -10), 3.4)
	if firing:
		_beam(ci, cage, fire)


static func _node(ci: CanvasItem, at: Vector2, pulse: float) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(at, 3.0, 2.0, 10), CRYPT_DARK, 0.6, 0.3, 0.9)
	VectorStyle.draw_glow(ci, SOUL, at + Vector2(0, -2), 5.0, 0.4 + pulse * 0.3)


## A beam of soul light from the cage toward the road, bending a little, fading as it goes.
static func _beam(ci: CanvasItem, from: Vector2, fire: float) -> void:
	var reach: float = smoothstep(0.0, 0.35, fire) * (1.0 - smoothstep(0.6, 1.0, fire) * 0.8)
	var end: Vector2 = from + Vector2(26.0, 8.0) * reach
	var mid: Vector2 = from.lerp(end, 0.5) + Vector2(0, -6.0)
	var points: PackedVector2Array = VectorPaint.curve(from, mid, end, 12)
	ci.draw_polyline(points, Color(SOUL, 0.4 * (1.0 - fire * 0.5)), 5.0, true)
	ci.draw_polyline(points, Color(SOUL_LIGHT, 0.95 * (1.0 - fire * 0.6)), 1.8, true)
	VectorStyle.draw_glow(ci, SOUL, end, 8.0, 0.7 * (1.0 - fire))


static func paint_ossuary(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	VectorStyle.shadow(ci, Vector2(3, 5), 27, 10.5)
	ArcherPainter.plinth(ci, 1.0)
	var firing: bool = fire >= 0.0
	var open: float = (smoothstep(0.0, 0.25, fire) * (1.0 - smoothstep(0.6, 0.95, fire))) if firing else 0.0
	var top: float = -34.0 - level * 3.0
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-17, -3), Vector2(17, -3), Vector2(15, top), Vector2(-15, top)]), CRYPT, 3.2, 0.55)
	for row: int in 4:
		var y: float = -8.0 - row * (absf(top) - 6.0) / 4.0
		VectorPaint.line(ci, Vector2(-16 + row * 0.6, y), Vector2(16 - row * 0.6, y), Color(VectorStyle.INK, 0.35), 0.9)
	# The crypt door: an arch that glows teal and opens on a skeleton.
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-6, -3), Vector2(6, -3), Vector2(6, -16), Vector2(3.6, -21), Vector2(-3.6, -21), Vector2(-6, -16)]), CRYPT_DARK, 1.0, 0.2, 1.0)
	VectorStyle.draw_glow(ci, SOUL, Vector2(0, -12), 12.0 + open * 14.0, 0.35 + open * 0.5)
	if open > 0.05:
		var width: float = 5.0 * open
		VectorPaint.fill(ci, PackedVector2Array([Vector2(-width, -3), Vector2(width, -3), Vector2(width, -17), Vector2(0, -20.4), Vector2(-width, -17)]), Color(SOUL, 0.85))
		_marcher(ci, fire)
	# Skulls stacked on both sides and along the cornice; more with each level.
	var rows: int = 2 + level
	for flip: float in [-1.0, 1.0]:
		for k: int in rows:
			_skull(ci, Vector2(flip * (11.0 + (k % 2) * 1.6), -8.0 - k * 6.4), 2.8)
	for k: int in 5:
		_skull(ci, Vector2(-12.0 + k * 6.0, top - 2.0), 2.8)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-18, top), Vector2(18, top), Vector2(14, top - 6), Vector2(-14, top - 6)]), CRYPT_DARK, 1.6, 0.5, 1.1)
	for flip: float in [-1.0, 1.0]:
		VectorPaint.line(ci, Vector2(flip * 14, top - 5), Vector2(flip * 15, -12), Color(IRON, 0.9), 1.0)
	if level >= 3:
		VectorStyle.draw_glow(ci, GOLD, Vector2(0, top - 7), 6.0, 0.4)
		_skull(ci, Vector2(0, top - 9), 3.6)
	VectorStyle.draw_glow(ci, SOUL, Vector2(0, -22), 5.0 + sin(t * TAU) * 1.0, 0.4)


## A little skeleton stepping out of the door during the shot.
static func _marcher(ci: CanvasItem, fire: float) -> void:
	var x: float = lerpf(0.0, 12.0, smoothstep(0.2, 0.9, fire))
	var at: Vector2 = Vector2(x, -4.0)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -9), 2.8, 4.0, 10), BONE, 0.6, 0.4, 0.8)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0.4, -15), 2.4, 2.4, 10), BONE, 0.6, 0.4, 0.8)
	VectorPaint.line(ci, at + Vector2(0, -5), at + Vector2(-1.2 + sin(fire * 18.0), 0), BONE, 1.2)
	VectorPaint.line(ci, at + Vector2(0, -5), at + Vector2(1.2 - sin(fire * 18.0), 0), BONE, 1.2)
	ci.draw_circle(at + Vector2(1.2, -15.4), 0.7, SOUL_LIGHT, true, -1.0, true)
