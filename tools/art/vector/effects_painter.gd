class_name EffectsPainter
## The vector core effects (M15): the hero's sword swing (8 directions, scaled by the reach tier at runtime), the hit spark,
## the dust puff, and the towers' shots (arrows, cannonballs, the frost bolt, the fire glob, the hero's bolt and the evolution
## shots), each pre-drawn at its direction (no rotation of sprites in the game). Effects are warm for the defenders' side.
## frame(ci, anim, index, count) paints one sheet frame; the layouts are SWING, HIT_SPARK, DUST and PROJECTILES.

const GOLD: Color = Color("e8b54e")
const CREAM: Color = Color("fff0c8")
const AMBER: Color = Color("ffb050")
const WOOD: Color = Color("8a5a34")
const STEEL: Color = Color("dfe3e6")
const ICE: Color = Color("7fd8ff")
const ICE_LIGHT: Color = Color("e4f8ff")
const IRON: Color = Color("3d3f4a")
## The swing's base reach (world px) and the arc it sweeps (radians each side of the aim); the hitbox cone is about 68 px.
const SWING_RADIUS: float = 62.0
const SWING_HALF_ARC: float = 1.05
const SWING_CENTER: Vector2 = Vector2(0, -12)


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var progress: float = float(index + 1) / count
	if anim.begins_with("swing_"):
		_swing(ci, int(anim.get_slice("_", 1)), progress)
	elif anim == "spark":
		_spark(ci, progress)
	elif anim == "dust":
		_dust(ci, progress)
	else:
		_shot(ci, anim, index, count)


## ---- the sword swing ------------------------------------------------------------------------------------------

## A crescent sweeping from one side of the aim to the other: the head races ahead, the tail fades behind it.
static func _swing(ci: CanvasItem, direction: int, progress: float) -> void:
	var aim: float = direction * PI / 4.0
	var eased: float = 1.0 - pow(1.0 - progress, 2.2)
	var head: float = aim - SWING_HALF_ARC + 2.0 * SWING_HALF_ARC * eased
	var tail: float = maxf(aim - SWING_HALF_ARC, head - 1.9)
	var fade: float = 1.0 - pow(progress, 2.4) * 0.9
	if head - tail < 0.05:
		return
	var steps: int = 22
	for layer: Array in [[0.0, 1.0, Color(AMBER, 0.22 * fade)], [0.16, 0.74, Color(Color("ffd890"), 0.5 * fade)], [0.3, 0.5, Color(CREAM, 0.85 * fade)], [0.44, 0.3, Color(1, 1, 1, 0.95 * fade)]]:
		var outer: PackedVector2Array = PackedVector2Array()
		var inner: PackedVector2Array = PackedVector2Array()
		for i: int in steps + 1:
			var k: float = float(i) / steps
			var a: float = lerpf(tail, head, k)
			var thick: float = (0.12 + 0.88 * pow(k, 1.4)) * float(layer[1])
			var r_out: float = SWING_RADIUS + 5.0 * thick - float(layer[0]) * 6.0
			var r_in: float = SWING_RADIUS - 24.0 * thick + float(layer[0]) * 10.0
			outer.append(SWING_CENTER + Vector2.from_angle(a) * r_out)
			inner.append(SWING_CENTER + Vector2.from_angle(a) * minf(maxf(r_in, 4.0), r_out - 0.6))  # never crossing the outer edge
		inner.reverse()
		outer.append_array(inner)
		VectorPaint.fill(ci, outer, layer[2])
	var tip: Vector2 = SWING_CENTER + Vector2.from_angle(head) * (SWING_RADIUS - 4.0)
	VectorStyle.draw_glow(ci, GOLD, tip, 14.0, 0.85 * fade)
	VectorStyle.draw_glow(ci, CREAM, tip, 5.0, fade)
	for i: int in 5:
		var a: float = head - 0.1 - i * 0.16
		var out: Vector2 = SWING_CENTER + Vector2.from_angle(a) * (SWING_RADIUS + 6.0 + progress * 10.0 + i * 2.0)
		VectorStyle.draw_glow(ci, AMBER, out, 2.4, 0.8 * fade * (1.0 - i * 0.15))


## ---- the hit spark ----------------------------------------------------------------------------------------------

## A burst: a flash that flares and fades, jagged rays flying outward, a ring.
static func _spark(ci: CanvasItem, progress: float) -> void:
	var flare: float = sin(clampf(progress * 1.5, 0.0, 1.0) * PI * 0.65)
	var fade: float = 1.0 - progress * progress
	VectorStyle.draw_glow(ci, Color("ffd890"), Vector2.ZERO, 16.0 * (0.5 + progress), 0.85 * fade)
	VectorStyle.draw_glow(ci, Color.WHITE, Vector2.ZERO, 7.0 * flare, fade)
	for i: int in 8:
		var a: float = i * TAU / 8.0 + 0.2
		var long_ray: bool = i % 2 == 0
		var r0: float = 3.0 + progress * 6.0
		var r1: float = r0 + (7.0 if long_ray else 4.0) * (1.0 - progress * 0.4)
		var d: Vector2 = Vector2.from_angle(a)
		ci.draw_line(d * r0, d * r1, Color(CREAM if long_ray else GOLD, 0.95 * fade), 2.2 if long_ray else 1.5, true)
	ci.draw_arc(Vector2.ZERO, 4.0 + progress * 12.0, 0.0, TAU, 20, Color(GOLD, 0.7 * fade), 1.4, true)


## ---- the dust puff ------------------------------------------------------------------------------------------------

## A ring of overlapping puffs that grow, rise and fade, each with a lit top and a shaded underside.
static func _dust(ci: CanvasItem, progress: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 31
	for i: int in 9:
		var a: float = i * TAU / 9.0 + rng.randf() * 0.4
		var k: float = clampf(progress * 1.25 - rng.randf() * 0.2, 0.0, 1.0)
		var at: Vector2 = Vector2(cos(a) * 13.0 * k, sin(a) * 5.0 * k - k * 7.0 - 3.0)
		var r: float = (3.5 + rng.randf() * 3.0) * (0.6 + k * 1.2)
		var alpha: float = 0.5 * (1.0 - k)
		ci.draw_circle(at + Vector2(0.8, 1.0), r, Color(0.42, 0.37, 0.32, alpha), true, -1.0, true)
		ci.draw_circle(at, r, Color(0.8, 0.74, 0.66, alpha), true, -1.0, true)
		ci.draw_circle(at + Vector2(-r * 0.3, -r * 0.3), r * 0.5, Color(0.95, 0.9, 0.82, alpha * 0.8), true, -1.0, true)


## ---- shots ---------------------------------------------------------------------------------------------------------

static func _shot(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var tail: String = anim.get_slice("_", anim.get_slice_count("_") - 1)
	var direction: int = int(tail) if tail.is_valid_int() else 0
	var angle: float = direction * PI / 4.0
	var spin: float = float(index) / count
	if anim.begins_with("arrow_"):
		_arrow(ci, angle, 15.0, 1.6, GOLD)
	elif anim.begins_with("sniper_shot_"):
		_sniper(ci, angle)
	elif anim.begins_with("harpoon_"):
		_harpoon(ci, angle)
	elif anim.begins_with("bolt_"):
		_bolt(ci, angle)
	elif anim.begins_with("soul_bolt_"):
		_soul_bolt(ci, angle, spin)
	elif anim == "cannonball":
		_cannonball(ci, 6.0, spin)
	elif anim == "cannonball_heavy":
		_cannonball(ci, 8.2, spin)
	elif anim == "mortar_shell":
		_mortar(ci, spin)
	elif anim == "frost_bolt":
		_frost_bolt(ci, spin)
	elif anim == "fire_glob":
		_fire_glob(ci, spin)


static func _arrow(ci: CanvasItem, angle: float, length: float, width: float, glow: Color) -> void:
	var d: Vector2 = Vector2.from_angle(angle)
	var s: Vector2 = d.orthogonal()
	VectorStyle.draw_glow(ci, glow, d * 2.0, 9.0, 0.4)
	ci.draw_line(-d * length * 0.5, d * length * 0.35, Color(VectorStyle.INK, 0.9), width + 1.6, true)
	ci.draw_line(-d * length * 0.5, d * length * 0.35, WOOD.lightened(0.15), width, true)
	VectorPaint.fill(ci, PackedVector2Array([d * (length * 0.5 + 1.2), d * length * 0.28 + s * 2.4, d * length * 0.34, d * length * 0.28 - s * 2.4]), STEEL)
	for k: float in [-1.0, 1.0]:
		VectorPaint.fill(ci, PackedVector2Array([-d * length * 0.5, -d * length * 0.5 + d * 3.4 + s * k * 2.6, -d * length * 0.5 + d * 4.4]), Color("c9332f"))


static func _sniper(ci: CanvasItem, angle: float) -> void:
	var d: Vector2 = Vector2.from_angle(angle)
	var s: Vector2 = d.orthogonal()
	VectorStyle.draw_glow(ci, Color("ffd890"), Vector2.ZERO, 12.0, 0.7)
	for i: int in 4:
		VectorStyle.draw_glow(ci, GOLD, -d * (3.0 + i * 3.4), 4.5 - i, 0.5 - i * 0.1)
	VectorPaint.fill(ci, PackedVector2Array([d * 11.0, d * 3.0 + s * 1.8, -d * 8.0 + s * 0.6, -d * 8.0 - s * 0.6, d * 3.0 - s * 1.8]), CREAM)
	ci.draw_line(-d * 6.0, d * 9.0, Color.WHITE, 1.0, true)


static func _harpoon(ci: CanvasItem, angle: float) -> void:
	var d: Vector2 = Vector2.from_angle(angle)
	var s: Vector2 = d.orthogonal()
	ci.draw_line(-d * 11.0, d * 5.0, Color(VectorStyle.INK, 0.9), 3.4, true)
	ci.draw_line(-d * 11.0, d * 5.0, Color("e8dcc0"), 2.2, true)
	VectorPaint.fill(ci, PackedVector2Array([d * 12.0, d * 5.0 + s * 3.4, d * 7.0, d * 5.0 - s * 3.4]), STEEL)
	VectorPaint.fill(ci, PackedVector2Array([d * 8.0 + s * 3.2, d * 5.0 + s * 1.4, d * 5.0 + s * 3.8]), Color("aab3bb"))
	ci.draw_line(-d * 11.0, -d * 15.0 + s * 3.0, Color(0.85, 0.7, 0.4, 0.8), 1.0, true)


## The Huntress's crossbow bolt (M15 P3): a short dark shaft with an amber head, amber fletching and a thin amber streak.
static func _bolt(ci: CanvasItem, angle: float) -> void:
	var d: Vector2 = Vector2.from_angle(angle)
	var s: Vector2 = d.orthogonal()
	VectorStyle.draw_glow(ci, Color("ffb050"), d * 3.0, 9.0, 0.5)
	ci.draw_line(-d * 12.0, -d * 6.0, Color(AMBER, 0.5), 1.0, true)
	ci.draw_line(-d * 7.0, d * 6.0, Color(VectorStyle.INK, 0.9), 3.0, true)
	ci.draw_line(-d * 7.0, d * 6.0, Color("6a4a30"), 1.8, true)
	VectorPaint.fill(ci, PackedVector2Array([d * 11.0, d * 5.0 + s * 2.4, d * 4.0, d * 5.0 - s * 2.4]), Color("ffd890"))
	for k: float in [-1.0, 1.0]:
		VectorPaint.fill(ci, PackedVector2Array([-d * 7.0, -d * 7.0 + d * 3.4 + s * k * 2.6, -d * 7.0 + d * 4.4]), AMBER)
	ci.draw_line(-d * 3.0, d * 8.0, Color(1, 1, 1, 0.6), 0.8, true)


## The Necromancer's soul bolt: a pale-teal wisp with a small skull for a head and a wavering tail.
static func _soul_bolt(ci: CanvasItem, angle: float, spin: float) -> void:
	var d: Vector2 = Vector2.from_angle(angle)
	var s: Vector2 = d.orthogonal()
	var teal: Color = Color("8ff0dc")
	VectorStyle.draw_glow(ci, teal, d * 1.0, 11.0, 0.55)
	for k: int in 3:
		var wave: float = sin(spin * TAU + k * 1.6) * 2.4
		VectorPaint.strand(ci, -d * 3.0 + s * (k - 1) * 1.6, -d * (9.0 + k * 3.0) + s * wave, -d * (14.0 + k * 3.5) + s * wave * 1.5, 4.0 - k * 0.8, Color(teal, 0.8 - k * 0.15))
	VectorPaint.painted(ci, VectorStyle.ellipse(d * 2.0, 5.2, 4.6, 14), Color("e2fff6"), 1.4, 0.4, 1.0)
	for k: float in [-1.0, 1.0]:
		ci.draw_circle(d * 3.2 + s * k * 1.9, 1.1, Color("123a3a"), true, -1.0, true)
	ci.draw_circle(d * 0.0, 0.6, Color("123a3a"), true, -1.0, true)


static func _cannonball(ci: CanvasItem, radius: float, spin: float) -> void:
	VectorStyle.draw_glow(ci, Color("ff9a40"), Vector2.ZERO, radius * 2.0, 0.25)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2.ZERO, radius, radius, 20), IRON, radius * 0.5, 0.5, 1.2)
	var a: float = spin * TAU
	ci.draw_arc(Vector2.ZERO, radius * 0.62, a, a + 1.5, 8, Color(0.7, 0.72, 0.8, 0.6), 1.0, true)
	VectorStyle.shine(ci, Vector2(-radius * 0.35, -radius * 0.4), radius * 0.3, radius * 0.18, 0.55)


static func _mortar(ci: CanvasItem, spin: float) -> void:
	VectorStyle.draw_glow(ci, Color("ff8a30"), Vector2(0, -9), 7.0, 0.7)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2.ZERO, 8.6, 8.6, 20), Color("30323c"), 4.0, 0.5, 1.3)
	ci.draw_line(Vector2(0, -8), Vector2(sin(spin * TAU) * 2.0, -12), Color("c9a565"), 1.4, true)
	VectorStyle.draw_glow(ci, Color("ffd070"), Vector2(sin(spin * TAU) * 2.0, -12.5), 3.0, 1.0)
	ci.draw_arc(Vector2.ZERO, 5.4, spin * TAU, spin * TAU + 1.6, 8, Color(0.7, 0.72, 0.8, 0.6), 1.0, true)


static func _frost_bolt(ci: CanvasItem, spin: float) -> void:
	var a: float = spin * TAU * 0.5
	VectorStyle.draw_glow(ci, ICE, Vector2.ZERO, 13.0, 0.7)
	var diamond: PackedVector2Array = PackedVector2Array([Vector2(0, -8), Vector2(5, 0), Vector2(0, 8), Vector2(-5, 0)])
	var turned: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in diamond:
		turned.append(p.rotated(a))
	VectorPaint.painted(ci, turned, ICE_LIGHT, 2.0, 0.5, 1.0)
	VectorStyle.draw_glow(ci, Color.WHITE, Vector2.ZERO, 3.4, 0.9)


static func _fire_glob(ci: CanvasItem, spin: float) -> void:
	VectorStyle.draw_glow(ci, Color("ff8a30"), Vector2.ZERO, 14.0, 0.6)
	for layer: int in 3:
		var color: Color = [Color("e5541e"), Color("ffa63a"), Color("fff1b8")][layer]
		var s: float = 1.0 - layer * 0.28
		var wob: float = sin(spin * TAU + layer) * 1.2
		VectorPaint.fill(ci, PackedVector2Array([Vector2(-5 * s, 3 * s), Vector2(-4 * s, -3 * s), Vector2(wob, -10 * s), Vector2(4 * s, -3 * s), Vector2(5 * s, 3 * s), Vector2(0, 6 * s)]), color)
