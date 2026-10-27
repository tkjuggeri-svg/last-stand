class_name FrostTowerPainter
## Paints the vector Frost tower (M15): a stone obelisk on an octagonal plinth with glowing blue runes and a small warm
## lantern at its foot (the defenders' warmth against the cold), crowned by a large faceted ice crystal that floats and turns
## above it, with a ring of shards circling. Snow drifts on the plinth. Level 2 adds shards and a gold collar, level 3 a
## second crystal ring and a taller crystal. paint() is one sheet frame: idle (the crystal bobs, shards circle), fire (a
## flare of white-blue light and an expanding frost ring). Pose units: the slot at (0, 0), about 66 tall.

const STONE: Color = Color("8c97a6")
const STONE_DARK: Color = Color("4d5668")
const ICE: Color = Color("7fd8ff")
const ICE_LIGHT: Color = Color("d6f4ff")
const ICE_DARK: Color = Color("2f78b8")
const GOLD: Color = Color("e8b54e")
const SNOW: Color = Color("e8f2fa")
const TOP: Vector2 = Vector2(0, -48)


static func paint(ci: CanvasItem, level: int, t: float, fire: float) -> void:
	var firing: bool = fire >= 0.0
	var pulse: float = (smoothstep(0.0, 0.25, fire) * (1.0 - smoothstep(0.25, 0.8, fire))) if firing else 0.0
	VectorStyle.shadow(ci, Vector2(3, 5), 27, 10.5)
	ArcherPainter.plinth(ci, 0.95)
	_snow(ci)
	_obelisk(ci, level, pulse)
	_lantern(ci)
	var bob: float = sin(t * TAU) * 2.0
	var height: float = 17.0 + (level - 1) * 3.0
	var lift: Vector2 = TOP + Vector2(0, -12 + bob - pulse * 2.0)
	_shards(ci, lift, t, level, false)
	_crystal(ci, lift, height, pulse)
	_shards(ci, lift, t, level, true)
	if firing:
		_ring(ci, lift, fire)
	VectorStyle.draw_glow(ci, ICE, lift, 24.0 + pulse * 22.0, 0.35 + pulse * 0.5)
	VectorStyle.draw_glow(ci, ICE_LIGHT, lift, 9.0 + pulse * 10.0, 0.6 + pulse * 0.4)


static func _snow(ci: CanvasItem) -> void:
	for at: Vector2 in [Vector2(-15, -2), Vector2(-5, 3), Vector2(8, 4), Vector2(16, -1)]:
		VectorPaint.painted(ci, VectorStyle.ellipse(at, 5.0, 2.2, 12), SNOW, 1.2, 0.3, 0.6)


static func _obelisk(ci: CanvasItem, level: int, pulse: float) -> void:
	var body: PackedVector2Array = PackedVector2Array([Vector2(-11, -3), Vector2(11, -3), Vector2(7.5, -46), Vector2(-7.5, -46)])
	VectorPaint.painted(ci, body, STONE, 3.2, 0.7)
	for k: int in 5:
		var y: float = -8.0 - k * 8.0
		var half: float = lerpf(10.6, 7.8, (k + 1) / 6.0)
		VectorPaint.line(ci, Vector2(-half, y), Vector2(half, y), Color(VectorStyle.INK, 0.4), 0.9)
	VectorPaint.line(ci, Vector2(-7.5, -46), Vector2(-11, -3), Color(1, 1, 1, 0.25), 1.4)
	# Runes down the front, glowing.
	for k: int in 4:
		var c: Vector2 = Vector2(0, -12.0 - k * 8.5)
		var glow: float = 0.55 + pulse * 0.45
		ci.draw_arc(c, 2.4, 0.0, TAU, 10, Color(ICE, glow), 0.9, true)
		VectorPaint.line(ci, c + Vector2(-1.6, 1.6), c + Vector2(1.6, -1.6), Color(ICE_LIGHT, glow), 0.8)
		VectorStyle.draw_glow(ci, ICE, c, 5.0, 0.35 * glow)
	if level >= 2:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(-8.8, -40), Vector2(8.8, -40), Vector2(8.4, -37.4), Vector2(-8.4, -37.4)]), GOLD, 0.8, 0.0, 0.7)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-9.4, -47), Vector2(9.4, -47), Vector2(8.2, -43.6), Vector2(-8.2, -43.6)]), STONE_DARK, 1.4, 0.4)


## A warm lantern at the obelisk's foot: the defenders' light in the cold.
static func _lantern(ci: CanvasItem) -> void:
	var at: Vector2 = Vector2(13, -7)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-2.6, -4), at + Vector2(2.6, -4), at + Vector2(2.2, 3), at + Vector2(-2.2, 3)]), Color("5a3a22"), 0.8, 0.2, 0.8)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-1.6, -3), at + Vector2(1.6, -3), at + Vector2(1.4, 2), at + Vector2(-1.4, 2)]), Color("ffd27a"))
	VectorStyle.draw_glow(ci, VectorStyle.WARM_GLOW, at, 14.0, 0.5)


static func _crystal(ci: CanvasItem, at: Vector2, height: float, pulse: float) -> void:
	var w: float = 9.0
	var top: Vector2 = at + Vector2(0, -height)
	var bottom: Vector2 = at + Vector2(0, height * 0.55)
	var left: Vector2 = at + Vector2(-w, -height * 0.18)
	var right: Vector2 = at + Vector2(w, -height * 0.18)
	var mid: Vector2 = at + Vector2(0, -height * 0.05)
	var lit: Color = ICE.lerp(ICE_LIGHT, pulse)
	VectorPaint.painted(ci, PackedVector2Array([top, left, mid]), lit.lightened(0.15), 2.0, 0.5, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([top, mid, right]), lit, 2.0, 0.5, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([left, bottom, mid]), ICE_DARK.lerp(ICE, 0.3 + pulse * 0.5), 2.0, 0.4, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([mid, bottom, right]), ICE_DARK.lerp(ICE, pulse * 0.5), 2.0, 0.4, 1.0)
	VectorPaint.line(ci, top + Vector2(-0.5, 2), mid + Vector2(-0.5, 0), Color(1, 1, 1, 0.7), 1.0)
	VectorPaint.line(ci, left + Vector2(2.4, 0.5), mid + Vector2(-0.5, 0.5), Color(1, 1, 1, 0.4), 0.7)
	VectorStyle.shine(ci, at + Vector2(-3.2, -height * 0.45), 1.6, 3.4, 0.55)


static func _shards(ci: CanvasItem, at: Vector2, t: float, level: int, front: bool) -> void:
	var count: int = 3 + level
	for i: int in count:
		var a: float = t * TAU + i * TAU / count
		var in_front: bool = sin(a) > 0.0
		if in_front != front:
			continue
		var p: Vector2 = at + Vector2(cos(a) * 18.0, sin(a) * 6.0 + 4.0)
		var s: float = 2.6 + (1.0 if in_front else 0.0)
		VectorPaint.painted(ci, PackedVector2Array([p + Vector2(0, -s * 1.5), p + Vector2(s, 0), p + Vector2(0, s * 1.5), p + Vector2(-s, 0)]), ICE_LIGHT if in_front else ICE, 0.8, 0.3, 0.7)


## The frost ring: expands from the crystal and fades.
static func _ring(ci: CanvasItem, at: Vector2, fire: float) -> void:
	var r: float = 8.0 + fire * 30.0
	var a: float = 1.0 - fire
	ci.draw_arc(at + Vector2(0, 20), r, 0.0, TAU, 40, Color(ICE, 0.5 * a), 5.0, true)
	ci.draw_arc(at + Vector2(0, 20), r, 0.0, TAU, 40, Color(ICE_LIGHT, 0.9 * a), 1.4, true)
