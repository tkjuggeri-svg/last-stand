class_name VariantExtras
## The silhouettes of the enemy variants (variant_painter.gd): what each one wears over its recoloured base figure.
## paint() draws in the base's pose units (feet at y 0) already shifted by the base's bob; glows() draws the soft halos
## (normal alpha: additive blending doesn't survive a transparent bake) unshifted. `p` is the pose VariantPainter builds:
## id, base, facing, state, cycle, progress, lunge, bob, head (the base's head anchor at rest), walk.

const EMBER: Color = Color("ff8a2a")
const EMBER_HOT: Color = Color("ffd25a")
const EMBER_DARK: Color = Color("9a2e12")
const ICE: Color = Color("bfe6ff")
const ICE_DARK: Color = Color("5a8fc4")
const STONE: Color = Color("8a8478")
const STONE_DARK: Color = Color("4c483f")
const BARK: Color = Color("6a4a2a")
const BARK_DARK: Color = Color("3a2814")
const LEAF: Color = Color("5a8a3a")
const LEAF_DARK: Color = Color("2c4a22")
const STRAW: Color = Color("d8bc62")
const STRAW_DARK: Color = Color("8a6c2c")
const BONE: Color = Color("ece4cc")
const BONE_DARK: Color = Color("a89c7c")
const SLIME: Color = Color("9ab84a")
const SLIME_DARK: Color = Color("55702a")
const REED: Color = Color("8a7a3c")
const MOSS: Color = Color("4a7a3a")
const BRONZE: Color = Color("b8843a")
const BRONZE_DARK: Color = Color("6a4418")
const STEEL: Color = Color("b8c4d6")
const STEEL_DARK: Color = Color("56647c")
const MIST: Color = Color("cfe6ee")


static func paint(ci: CanvasItem, p: Dictionary) -> void:
	match String(p.id):
		"cinder_ghoul":
			_cinder_ghoul(ci, p)
		"scarecrow":
			_scarecrow(ci, p)
		"bone_hurler":
			_bone_hurler(ci, p)
		"rubble_brute":
			_rubble_brute(ci, p)
		"bloater":
			_bloater(ci, p)
		"bloatling":
			_bloatling(ci, p)
		"mire_priest":
			_mire_priest(ci, p)
		"shieldbearer":
			_shieldbearer(ci, p)
		"frost_wraith":
			_frost_wraith(ci, p)
		"rime_brute":
			_rime_brute(ci, p)
		"stalker":
			_stalker(ci, p)
		"hollow_treant":
			_hollow_treant(ci, p)
		"pyre_warden":
			_pyre_warden(ci, p)
		"winter_warden":
			_winter_warden(ci, p)
		"quarry_colossus":
			_quarry_colossus(ci, p)
		"hollow_stag":
			_hollow_stag(ci, p)
		"tollkeeper":
			_tollkeeper(ci, p)


## The soft light a variant throws around itself.
static func glows(ci: CanvasItem, p: Dictionary) -> void:
	var at: Vector2 = Vector2(p.head) + Vector2(0, float(p.bob))
	match String(p.id):
		"cinder_ghoul":
			VectorStyle.draw_glow(ci, EMBER, at + Vector2(0, -4), 22.0, 0.3)
		"pyre_warden":
			VectorStyle.draw_glow(ci, EMBER, at + Vector2(0, -6), 30.0, 0.35)
		"winter_warden", "frost_wraith":
			VectorStyle.draw_glow(ci, ICE, at + Vector2(0, 4), 26.0 if String(p.id) == "winter_warden" else 18.0, 0.22)
		"hollow_treant":
			VectorStyle.draw_glow(ci, EMBER, Vector2(0, -24 + float(p.bob)), 10.0, 0.35)
		"bloater", "bloatling":
			VectorStyle.draw_glow(ci, SLIME, Vector2(0, -22 + float(p.bob)), 22.0, 0.18)
		"mire_priest", "tollkeeper":
			VectorStyle.draw_glow(ci, Color("5affd0"), Vector2(0, -10 + float(p.bob)), 20.0, 0.16)


## A variant's collapse: only what stays on the ground, drawn small (the base's death plays under it).
static func death(ci: CanvasItem, p: Dictionary) -> void:
	var t: float = float(p.progress)
	match String(p.id):
		"cinder_ghoul", "pyre_warden":
			for k: int in 5:
				var x: float = -8.0 + k * 4.0
				_flame(ci, Vector2(x, 2.0), (6.0 + (k % 3) * 2.0) * (1.0 - t * 0.7), 2.4, sin(t * 9.0 + k), EMBER)
		"winter_warden", "rime_brute", "frost_wraith":
			for k: int in 4:
				_crystal(ci, Vector2(-9.0 + k * 6.0, 2.0), 7.0 * (0.4 + t * 0.6), 2.2, (k - 1.5) * 0.25, ICE)
		"hollow_treant", "hollow_stag":
			for k: int in 4:
				_leaf(ci, Vector2(-10.0 + k * 7.0, 2.0 - (k % 2) * 2.0), 3.0, k * 0.9)


# --- shapes -----------------------------------------------------------------------------------------------------------

## A tongue of flame standing at `at`: `h` tall, `w` wide at the root, swaying by `sway`; hot core inside.
static func _flame(ci: CanvasItem, at: Vector2, h: float, w: float, sway: float, color: Color) -> void:
	var tip: Vector2 = at + Vector2(sway * 1.6, -h)
	var outer: PackedVector2Array = PackedVector2Array([at + Vector2(-w, 0), at + Vector2(-w * 0.8, -h * 0.4), tip, at + Vector2(w * 0.8, -h * 0.4), at + Vector2(w, 0),
		at + Vector2(0, w * 0.6)])
	VectorPaint.fill(ci, outer, Color(color, 0.92))
	var inner: PackedVector2Array = PackedVector2Array([at + Vector2(-w * 0.5, 0), at + Vector2(sway * 0.8, -h * 0.65), at + Vector2(w * 0.5, 0)])
	VectorPaint.fill(ci, inner, EMBER_HOT)


## A faceted shard standing on `at`, `h` tall and `w` half-wide, leaning by `tilt` radians.
static func _crystal(ci: CanvasItem, at: Vector2, h: float, w: float, tilt: float, color: Color) -> void:
	var up: Vector2 = Vector2(0, -1).rotated(tilt)
	var side: Vector2 = up.orthogonal() * w
	var pts: PackedVector2Array = PackedVector2Array([at - side, at - side * 0.7 + up * h * 0.7, at + up * h, at + side * 0.7 + up * h * 0.7, at + side])
	VectorPaint.painted(ci, pts, color, 1.0, 0.5, 0.9)
	VectorPaint.fill(ci, PackedVector2Array([at - side * 0.1, at - side * 0.45 + up * h * 0.65, at + up * h * 0.92]), Color(1, 1, 1, 0.45))


## A lumpy boulder (a fixed irregular outline from `seed_`), shaded stone.
static func _rock(ci: CanvasItem, at: Vector2, r: float, seed_: int, color: Color = STONE) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in 8:
		var ang: float = k * TAU / 8.0
		var wob: float = 0.78 + 0.22 * absf(sin(float(seed_ * 3 + k * 5) * 1.7))
		pts.append(at + Vector2(cos(ang) * r * wob, sin(ang) * r * wob * 0.85))
	VectorPaint.painted(ci, pts, color, r * 0.35, 0.5, 1.0)
	VectorPaint.line(ci, at + Vector2(-r * 0.3, -r * 0.2), at + Vector2(r * 0.1, r * 0.3), Color(STONE_DARK, 0.8), 0.6)


## A branching twig: a stem of `length` from `a` at `angle` (radians, 0 = up), forking twice.
static func _twig(ci: CanvasItem, a: Vector2, angle: float, length: float, width: float, color: Color, depth: int) -> void:
	var dir: Vector2 = Vector2(0, -1).rotated(angle)
	var b: Vector2 = a + dir * length
	VectorPaint.strand(ci, a, a + dir * length * 0.5 + dir.orthogonal() * length * 0.06, b, width, color)
	if depth <= 0:
		return
	_twig(ci, a + dir * length * 0.45, angle - 0.7, length * 0.55, width * 0.75, color, depth - 1)
	_twig(ci, b, angle + 0.35, length * 0.6, width * 0.75, color, depth - 1)


static func _leaf(ci: CanvasItem, at: Vector2, r: float, angle: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in 6:
		var a: float = k * TAU / 6.0
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.5).rotated(angle) + at)
	VectorPaint.painted(ci, pts, LEAF, 0.6, 0.4, 0.7)


static func _sway(p: Dictionary, k: float = 0.0) -> float:
	return sin(float(p.cycle) * TAU + k)


# --- the small enemies --------------------------------------------------------------------------------------------------

## Flames on the head and shoulders, glowing cracks in the chest and sparks.
static func _cinder_ghoul(ci: CanvasItem, p: Dictionary) -> void:
	var head: Vector2 = p.head
	var lunge: float = maxf(float(p.lunge), 0.0)
	if p.facing == "side":
		head += Vector2(0, lunge)
	for k: int in 4:
		var x: float = (k - 1.5) * 2.8
		_flame(ci, head + Vector2(x - 1.0, -4.5), 8.0 - absf(k - 1.5) * 1.6, 2.0, _sway(p, k * 1.3), EMBER)
	for side: float in [-1.0, 1.0]:
		if p.facing != "side" or side > 0.0:
			_flame(ci, Vector2(side * 8.0 - (4.0 if p.facing == "side" else 0.0), -20.0), 6.0, 1.9, _sway(p, side * 2.0), EMBER_DARK)
	if p.facing != "up":
		for k: int in 3:
			VectorPaint.line(ci, Vector2(-3.0 + k * 3.0, -17.0 + k), Vector2(-2.0 + k * 3.0, -13.0 + k), Color(EMBER_HOT, 0.9), 0.8)
	for k: int in 3:
		var rise: float = fmod(float(p.cycle) + k * 0.33, 1.0)
		ci.draw_circle(head + Vector2((k - 1) * 5.0 + sin(rise * 6.0) * 2.0, -12.0 - rise * 12.0), 0.8 * (1.0 - rise), Color(EMBER_HOT, 1.0 - rise), true, -1.0, true)


## A pointed straw hat, a sacking face with stitched eyes, straw spilling from the cuffs, a stitched cross on the chest.
static func _scarecrow(ci: CanvasItem, p: Dictionary) -> void:
	var head: Vector2 = p.head
	var sack: PackedVector2Array = PackedVector2Array([head + Vector2(-6.4, -2), head + Vector2(-5.0, -8), head + Vector2(5.0, -8), head + Vector2(6.4, -2), head + Vector2(6.0, 5.4),
		head + Vector2(-6.0, 5.4)])
	if p.facing != "up":
		VectorPaint.painted(ci, sack, Color("b49a62"), 2.0, 0.5, 1.0)
		for x: float in [-2.8, 2.8] if p.facing == "down" else [3.0]:
			VectorPaint.line(ci, head + Vector2(x - 1.4, -1.8), head + Vector2(x + 1.4, 0.6), VectorStyle.INK, 0.9)
			VectorPaint.line(ci, head + Vector2(x + 1.4, -1.8), head + Vector2(x - 1.4, 0.6), VectorStyle.INK, 0.9)
		VectorPaint.line(ci, head + Vector2(-3.0, 3.4), head + Vector2(3.0, 3.4), VectorStyle.INK, 0.8)
		for k: int in 4:
			VectorPaint.line(ci, head + Vector2(-3.0 + k * 2.0, 3.0), head + Vector2(-3.0 + k * 2.0, 4.2), VectorStyle.INK, 0.6)
	VectorPaint.painted(ci, VectorStyle.ellipse(head + Vector2(0, -8.2), 11.0, 2.8, 20), STRAW_DARK, 1.0, 0.4, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([head + Vector2(-6.0, -8.6), head + Vector2(-1.5, -17.0), head + Vector2(1.5, -17.0), head + Vector2(6.0, -8.6)]), STRAW, 1.6, 0.5, 1.0)
	VectorPaint.line(ci, head + Vector2(-5.6, -10.6), head + Vector2(5.6, -10.6), Color(BARK_DARK, 0.8), 1.2)
	for side: float in [-1.0, 1.0]:
		for k: int in 4:
			var at: Vector2 = Vector2(side * 21.0, -18.0 + (k % 2) * 1.5) if p.facing != "side" else Vector2(side * 4.0 + 6.0, -18.0)
			VectorPaint.line(ci, at, at + Vector2(side * (3.0 + k), 2.0 + k * 1.2), STRAW, 1.0)
	if p.facing == "down":
		VectorPaint.line(ci, Vector2(-4, -31), Vector2(4, -25), Color(STRAW, 0.9), 0.9)
		VectorPaint.line(ci, Vector2(4, -31), Vector2(-4, -25), Color(STRAW, 0.9), 0.9)


## A thorny hood, a skull on the belt and a bone in the raised hand while it winds up.
static func _bone_hurler(ci: CanvasItem, p: Dictionary) -> void:
	var head: Vector2 = p.head
	for side: float in [-1.0, 1.0]:
		VectorPaint.strand(ci, head + Vector2(side * 3.0, -6.0), head + Vector2(side * 6.5, -10.0), head + Vector2(side * 5.0, -15.0), 1.7, BONE)
	VectorPaint.strand(ci, head + Vector2(0, -7.0), head + Vector2(0.6, -11.0), head + Vector2(0, -17.0), 1.9, BONE)
	if p.facing != "up":
		var belt: Vector2 = Vector2(-6.0 if p.facing == "down" else 2.0, -11.0)
		VectorPaint.painted(ci, VectorStyle.ellipse(belt, 2.8, 2.5, 10), BONE, 0.8, 0.4, 0.9)
		VectorPaint.fill(ci, PackedVector2Array([belt + Vector2(-1.4, 0.6), belt + Vector2(-0.4, 0.6), belt + Vector2(-0.4, 1.8), belt + Vector2(-1.4, 1.8)]), VectorStyle.INK)
		VectorPaint.fill(ci, PackedVector2Array([belt + Vector2(0.4, 0.6), belt + Vector2(1.4, 0.6), belt + Vector2(1.4, 1.8), belt + Vector2(0.4, 1.8)]), VectorStyle.INK)
	if String(p.state) == "attack":
		var up: float = clampf(float(p.progress) * 1.6, 0.0, 1.0) * (1.0 - smoothstep(0.78, 1.0, float(p.progress)))
		var hand: Vector2 = Vector2(9.0, -14.0 - up * 14.0) if p.facing != "side" else Vector2(8.0, -14.0 - up * 12.0)
		VectorPaint.strand(ci, hand + Vector2(-2.5, 2.5), hand, hand + Vector2(2.5, -2.5), 2.0, BONE)
		for end: Vector2 in [hand + Vector2(-3.0, 3.0), hand + Vector2(3.0, -3.0)]:
			ci.draw_circle(end, 1.7, BONE, true, -1.0, true)


## Boulders on the shoulders, amber cracks across the chest and dust at the feet.
static func _rubble_brute(ci: CanvasItem, p: Dictionary) -> void:
	var spots: Array = [Vector2(-16.0, -45.0), Vector2(16.0, -45.0)] if p.facing != "side" else [Vector2(-4.0, -46.0), Vector2(9.0, -44.0)]
	var seed_: int = 1
	for at: Vector2 in spots:
		_rock(ci, at, 7.0, seed_)
		seed_ += 2
	_rock(ci, Vector2(0, -56.0), 4.5, 7)
	if p.facing == "down":
		var crack: PackedVector2Array = PackedVector2Array([Vector2(-5, -38), Vector2(-2, -33), Vector2(-4, -28), Vector2(1, -22), Vector2(-1, -17)])
		ci.draw_polyline(crack, Color(EMBER, 0.95), 1.3, true)
		ci.draw_polyline(crack, Color(EMBER_HOT, 0.9), 0.5, true)
	for k: int in 4:
		var rise: float = fmod(float(p.cycle) * 0.5 + k * 0.25, 1.0)
		ci.draw_circle(Vector2(-14.0 + k * 9.0, -3.0 - rise * 4.0), 2.2 * (1.0 - rise), Color(STONE, 0.35 * (1.0 - rise)), true, -1.0, true)


## A great swollen belly of gas and pus slung in front, boils on it, and puffs rising off the body.
static func _bloater(ci: CanvasItem, p: Dictionary) -> void:
	var breathe: float = 1.0 + _sway(p) * 0.04
	var at: Vector2 = Vector2(0, -22.0) if p.facing != "side" else Vector2(4.0, -22.0)
	if p.facing == "up":
		VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, 0), 15.0 * breathe, 12.0 * breathe, 22), SLIME_DARK, 3.0, 0.5, 1.2)
		return
	VectorPaint.painted(ci, VectorStyle.ellipse(at, 15.5 * breathe, 12.5 * breathe, 24), SLIME, 4.0, 0.55, 1.3)
	for k: int in 5:
		var boil: Vector2 = at + Vector2(-8.0 + k * 4.2, -3.0 + ((k * 5) % 7) - 3.0)
		VectorPaint.painted(ci, VectorStyle.ellipse(boil, 2.2, 2.0, 8), Color("d6e07a"), 0.5, 0.4, 0.7)
	for k: int in 3:
		VectorPaint.strand(ci, at + Vector2(-9.0 + k * 9.0, -9.0), at + Vector2(-8.0 + k * 9.0, -2.0), at + Vector2(-10.0 + k * 9.0, 6.0), 0.8, Color(SLIME_DARK, 0.9))
	for k: int in 3:
		var rise: float = fmod(float(p.cycle) + k * 0.33, 1.0)
		ci.draw_circle(Vector2(-10.0 + k * 10.0 + sin(rise * 5.0) * 2.0, -38.0 - rise * 12.0), 2.0 + rise * 3.0, Color(SLIME, 0.45 * (1.0 - rise)), true, -1.0, true)


## A small blob: a green sac across its back and a gas wisp.
static func _bloatling(ci: CanvasItem, p: Dictionary) -> void:
	var breathe: float = 1.0 + _sway(p) * 0.06
	var at: Vector2 = Vector2(-5.0, -17.0) if p.facing == "side" else Vector2(0, -14.0)
	VectorPaint.painted(ci, VectorStyle.ellipse(at, 11.0 * breathe, 9.0 * breathe, 18), SLIME, 3.0, 0.5, 1.1)
	for k: int in 3:
		VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(-5.0 + k * 5.0, -2.0 + (k % 2) * 3.0), 1.9, 1.7, 8), Color("d6e07a"), 0.4, 0.4, 0.6)
	var rise: float = fmod(float(p.cycle), 1.0)
	ci.draw_circle(at + Vector2(sin(rise * 6.0) * 3.0, -12.0 - rise * 8.0), 1.5 + rise * 2.0, Color(SLIME, 0.5 * (1.0 - rise)), true, -1.0, true)


## Reeds in the hood, a moss mantle, a drip of weed at the hem and a swamp light in the off hand.
static func _mire_priest(ci: CanvasItem, p: Dictionary) -> void:
	var head: Vector2 = p.head
	for k: int in 3:
		var lean: float = (k - 1) * 0.35 + _sway(p, k) * 0.05
		_twig(ci, head + Vector2((k - 1) * 3.0, -6.0), lean, 16.0 - k % 2 * 3.0, 1.1, REED, 0)
		VectorPaint.painted(ci, VectorStyle.ellipse(head + Vector2((k - 1) * 3.0 + lean * 14.0, -22.0 + k % 2 * 3.0), 1.4, 3.0, 8), BARK, 0.4, 0.3, 0.7)
	if p.facing != "side":
		for k: int in 6:
			var x: float = -9.0 + k * 3.6
			VectorPaint.strand(ci, Vector2(x, -3.0), Vector2(x + _sway(p, k) * 0.8, 1.0), Vector2(x + 0.5, 4.0 + (k % 3) * 1.4), 1.4, MOSS)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-10, -17), Vector2(-6, -20), Vector2(6, -20), Vector2(10, -17), Vector2(8, -13), Vector2(-8, -13)]), MOSS, 1.5, 0.4, 1.0)
	if String(p.state) == "heal":
		_heal_pulse(ci, p)


## The heal's telegraph and pulse: a green ring widening about the priest with motes rising from it.
static func _heal_pulse(ci: CanvasItem, p: Dictionary) -> void:
	var t: float = float(p.progress)
	var ring: PackedVector2Array = VectorStyle.ellipse(Vector2(0, -2.0), 8.0 + t * 17.0, (8.0 + t * 17.0) * 0.3, 32)
	ring.append(ring[0])
	ci.draw_polyline(ring, Color("7affc0", 0.7 * (1.0 - t * 0.6)), 1.4, true)
	for k: int in 6:
		var rise: float = fmod(t * 1.5 + k * 0.17, 1.0)
		ci.draw_circle(Vector2(-12.0 + k * 4.8, -4.0 - rise * 22.0), 1.2 * (1.0 - rise), Color("b8ffdc", 1.0 - rise), true, -1.0, true)


## A tall kite shield on the left arm that turns to the front: iron rim, boss and a cross.
static func _shieldbearer(ci: CanvasItem, p: Dictionary) -> void:
	var guard: float = 1.0 - clampf(maxf(float(p.lunge), 0.0), 0.0, 1.0) * 0.5
	var at: Vector2 = Vector2(-15.0, -27.0)
	if p.facing == "side":
		at = Vector2(10.0, -27.0)
	elif p.facing == "up":
		at = Vector2(0, -30.0)
	var body: PackedVector2Array = PackedVector2Array([at + Vector2(-8, -13), at + Vector2(8, -13), at + Vector2(9, 2), at + Vector2(0, 16), at + Vector2(-9, 2)])
	if p.facing == "side":
		body = PackedVector2Array([at + Vector2(-3, -13), at + Vector2(3, -13), at + Vector2(4, 2), at + Vector2(0, 15), at + Vector2(-4, 2)])
	VectorPaint.painted(ci, body, STEEL_DARK if p.facing == "up" else STEEL, 3.0, 0.55, 1.3)
	if p.facing != "side":
		VectorPaint.line(ci, at + Vector2(0, -12), at + Vector2(0, 14), Color(VectorStyle.INK, 0.6), 1.0)
		VectorPaint.line(ci, at + Vector2(-7, -3), at + Vector2(7, -3), Color(VectorStyle.INK, 0.6), 1.0)
		ci.draw_circle(at + Vector2(0, -3), 2.6 * guard, Color("d8b058"), true, -1.0, true)
	for k: int in 4:
		VectorPaint.rivet(ci, at + Vector2(-6.0 + k * 4.0, -11.0))


## Ice on the hood, an icicle fringe at the hem, a mist at the feet.
static func _frost_wraith(ci: CanvasItem, p: Dictionary) -> void:
	var head: Vector2 = p.head
	for k: int in 5:
		var tilt: float = (k - 2) * 0.28
		_crystal(ci, head + Vector2((k - 2) * 2.6, -5.5 + absf(k - 2) * 0.8), 9.0 - absf(k - 2) * 1.8, 1.7, tilt, ICE)
	if p.facing != "side":
		for k: int in 7:
			_crystal(ci, Vector2(-10.5 + k * 3.5, 1.5), 4.0 + (k % 3) * 1.6, 1.3, 0.0, Color(ICE, 0.9))
	for k: int in 4:
		var drift: float = fmod(float(p.cycle) + k * 0.25, 1.0)
		VectorPaint.fill(ci, VectorStyle.ellipse(Vector2(-12.0 + k * 8.0 + drift * 4.0, 2.0 - drift * 2.0), 6.0, 2.2, 12), Color(MIST, 0.28 * (1.0 - drift)))


## Frost on the pauldrons: crystal clusters, an icicle beard under the helm, breath misting.
static func _rime_brute(ci: CanvasItem, p: Dictionary) -> void:
	var spots: Array = [Vector2(-16.0, -42.0), Vector2(16.0, -42.0)] if p.facing != "side" else [Vector2(-4.0, -43.0), Vector2(9.0, -41.0)]
	for at: Vector2 in spots:
		for k: int in 3:
			_crystal(ci, at + Vector2((k - 1) * 3.0, -1.0 + absf(k - 1)), 11.0 - absf(k - 1) * 3.0, 2.4, (k - 1) * 0.4, ICE)
	if p.facing == "down":
		for k: int in 5:
			_icicle(ci, Vector2(-4.0 + k * 2.0, -43.0), 4.0 + (k % 2) * 3.0)
	for k: int in 3:
		var drift: float = fmod(float(p.cycle) + k * 0.33, 1.0)
		VectorPaint.fill(ci, VectorStyle.ellipse(Vector2(-6.0 + k * 6.0, -3.0 - drift * 3.0), 5.0, 1.8, 10), Color(MIST, 0.3 * (1.0 - drift)))


static func _icicle(ci: CanvasItem, at: Vector2, length: float) -> void:
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-1.0, 0), at + Vector2(1.0, 0), at + Vector2(0, length)]), Color(ICE, 0.95))


## A hunched stalker: twig spines along the back, moss patches and pale thorn tufts.
static func _stalker(ci: CanvasItem, p: Dictionary) -> void:
	if p.facing == "side":
		for k: int in 5:
			var x: float = -9.0 + k * 4.4
			_twig(ci, Vector2(x, -17.0 - (2.0 - absf(k - 2)) * 0.8), -0.15 - k * 0.04, 7.0 + (k % 2) * 3.0, 1.0, BARK, 1)
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(-2.0, -15.5), 6.0, 2.6, 12), MOSS, 0.8, 0.4, 0.8)
	else:
		for k: int in 5:
			_twig(ci, Vector2(-6.0 + k * 3.0, -13.0 - (2.0 - absf(k - 2)) * 0.6), (k - 2) * 0.3, 6.0 + (k % 2) * 3.0, 1.0, BARK, 1)
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -11.0), 6.0, 2.4, 12), MOSS, 0.8, 0.4, 0.8)
	for side: float in [-1.0, 1.0]:
		var head: Vector2 = p.head
		if p.facing != "side" or side > 0.0:
			_twig(ci, head + Vector2(side * 2.5, -4.0), side * 0.5, 7.0, 0.9, BARK_DARK, 1)


## Branches sprouting from the shoulders and the crown, leaves, a glowing knot-hole in the chest and roots at the feet.
static func _hollow_treant(ci: CanvasItem, p: Dictionary) -> void:
	var shoulders: Array = [Vector2(-15.0, -43.0), Vector2(15.0, -43.0)] if p.facing != "side" else [Vector2(-3.0, -44.0), Vector2(9.0, -42.0)]
	var sign_: float = -1.0
	for at: Vector2 in shoulders:
		_twig(ci, at, sign_ * 0.7 + _sway(p, sign_) * 0.04, 16.0, 2.6, BARK, 2)
		_leaf(ci, at + Vector2(sign_ * 9.0, -13.0), 3.4, sign_)
		_leaf(ci, at + Vector2(sign_ * 3.0, -17.0), 3.0, -sign_)
		sign_ = 1.0
	_twig(ci, Vector2(float(p.head.x), -53.0), -0.2, 11.0, 2.2, BARK, 1)
	_twig(ci, Vector2(float(p.head.x) + 2.0, -53.0), 0.4, 10.0, 2.2, BARK, 1)
	if p.facing == "down":
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -30.0), 3.8, 5.4, 12), Color("2a1a0c"), 0.6, 0.0, 1.0)
		ci.draw_circle(Vector2(0, -29.0), 2.0, Color(EMBER, 0.9), true, -1.0, true)
	for k: int in 5:
		VectorPaint.strand(ci, Vector2(-10.0 + k * 5.0, -1.0), Vector2(-11.0 + k * 5.5, 2.0), Vector2(-12.0 + k * 6.0, 3.0 + k % 2), 1.6, BARK_DARK)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(-13.0, -40.0), 4.0, 2.0, 10), MOSS, 0.8, 0.4, 0.8)


# --- the bosses ---------------------------------------------------------------------------------------------------------

## A crown of fire over the skull, flaming hands' light and embers rising.
static func _pyre_warden(ci: CanvasItem, p: Dictionary) -> void:
	var head: Vector2 = Vector2(p.head) + Vector2(0, -6)
	for k: int in 7:
		var x: float = (k - 3) * 3.2
		var h: float = 16.0 - absf(k - 3) * 2.8
		_flame(ci, head + Vector2(x, -4.0), h, 2.6, _sway(p, k * 0.8) * (1.0 + absf(k - 3) * 0.2), EMBER if k % 2 == 0 else EMBER_DARK)
	for k: int in 6:
		var rise: float = fmod(float(p.cycle) * 0.7 + k * 0.17, 1.0)
		var ang: float = k * 1.1
		ci.draw_circle(head + Vector2(cos(ang) * (8.0 + rise * 6.0), -10.0 - rise * 26.0), 1.1 * (1.0 - rise), Color(EMBER_HOT, 1.0 - rise), true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		if p.facing != "side" or side > 0.0:
			_flame(ci, Vector2(side * 17.0, -36.0), 11.0, 3.2, _sway(p, side), EMBER_DARK)


## A crown of long icicles, frost shards drifting around the figure.
static func _winter_warden(ci: CanvasItem, p: Dictionary) -> void:
	var head: Vector2 = Vector2(p.head) + Vector2(0, -6)
	for k: int in 7:
		var x: float = (k - 3) * 3.4
		_crystal(ci, head + Vector2(x, -3.0 + absf(k - 3) * 1.2), 17.0 - absf(k - 3) * 2.6, 2.2, (k - 3) * 0.2, ICE)
	for k: int in 6:
		var ang: float = float(p.cycle) * TAU * 0.5 + k * TAU / 6.0
		var at: Vector2 = Vector2(cos(ang) * 24.0, -34.0 + sin(ang) * 8.0)
		_crystal(ci, at, 6.0, 1.6, ang, Color(ICE, 0.9))
	for k: int in 8:
		var fall: float = fmod(float(p.cycle) + k * 0.125, 1.0)
		ci.draw_circle(Vector2(-22.0 + k * 6.0, -60.0 + fall * 58.0), 0.9, Color(1, 1, 1, 0.7 * (1.0 - fall * 0.5)), true, -1.0, true)


## Quarry stone: heavy slabs on the shoulders, amber-lit cracks and rubble about the feet.
static func _quarry_colossus(ci: CanvasItem, p: Dictionary) -> void:
	var spots: Array = [Vector2(-25.0, -50.0), Vector2(25.0, -50.0)] if p.facing != "side" else [Vector2(-6.0, -51.0), Vector2(10.0, -49.0)]
	var seed_: int = 2
	for at: Vector2 in spots:
		_rock(ci, at, 10.0, seed_)
		_rock(ci, at + Vector2(0, -8.0), 6.0, seed_ + 3)
		seed_ += 3
	if p.facing == "down":
		var crack: PackedVector2Array = PackedVector2Array([Vector2(-8, -48), Vector2(-3, -40), Vector2(-7, -32), Vector2(0, -24), Vector2(-3, -14)])
		ci.draw_polyline(crack, Color(EMBER, 0.95), 1.8, true)
		ci.draw_polyline(crack, Color(EMBER_HOT, 0.9), 0.7, true)
	for k: int in 5:
		_rock(ci, Vector2(-22.0 + k * 11.0, 1.0 + (k % 2)), 3.0 + (k % 3), k + 11, STONE_DARK)


## Great branching antlers, ferns on the shoulders and a green wisp-light between the tines.
static func _hollow_stag(ci: CanvasItem, p: Dictionary) -> void:
	var head: Vector2 = p.head
	var spread: float = 0.5
	for side: float in [-1.0, 1.0]:
		if p.facing == "side" and side < 0.0:
			continue
		var root: Vector2 = head + Vector2(side * 4.0, -5.0)
		_twig(ci, root, side * spread, 26.0, 3.0, Color("d8caa0"), 2)
		_twig(ci, root + Vector2(side * 2.0, -9.0), side * (spread + 0.7), 14.0, 2.2, Color("d8caa0"), 1)
	for side: float in [-1.0, 1.0]:
		var at: Vector2 = Vector2(side * 24.0, -46.0) if p.facing != "side" else Vector2(side * 6.0 + 4.0, -47.0)
		for k: int in 4:
			_leaf(ci, at + Vector2(side * k * 3.0, -k * 1.6), 5.0, side * (0.5 + k * 0.4))
	for k: int in 3:
		var rise: float = fmod(float(p.cycle) * 0.6 + k * 0.33, 1.0)
		ci.draw_circle(head + Vector2((k - 1) * 12.0, -20.0 - rise * 14.0), 1.5 * (1.0 - rise), Color("d8ff70", 1.0 - rise), true, -1.0, true)


## A bronze bell hung at the hip on a chain (it swings and rings on the toll), drowned weed on the shoulders, a ferryman's hat.
static func _tollkeeper(ci: CanvasItem, p: Dictionary) -> void:
	var head: Vector2 = p.head
	var cast: float = 1.0 if String(p.state) == "cast" else 0.0
	var swing: float = _sway(p) * (0.35 if cast > 0.0 else 0.08)
	var hang: Vector2 = Vector2(-22.0 if p.facing != "side" else -2.0, -36.0)
	VectorPaint.strand(ci, hang, hang + Vector2(0, 4.0), hang + Vector2(sin(swing) * 4.0, 10.0), 1.4, BRONZE_DARK)
	var bell: Vector2 = hang + Vector2(sin(swing) * 6.0, 16.0)
	var shell: PackedVector2Array = PackedVector2Array([bell + Vector2(-3, -7), bell + Vector2(3, -7), bell + Vector2(7, 5), bell + Vector2(-7, 5)])
	VectorPaint.painted(ci, shell, BRONZE, 2.0, 0.55, 1.2)
	VectorPaint.painted(ci, VectorStyle.ellipse(bell + Vector2(0, 5.0), 7.0, 1.8, 14), BRONZE_DARK, 0.6, 0.2, 0.9)
	ci.draw_circle(bell + Vector2(0, 7.6), 1.6, BRONZE_DARK, true, -1.0, true)
	if cast > 0.0:
		for k: int in 2:
			ci.draw_arc(bell, 12.0 + k * 5.0, -2.4, -0.7, 8, Color("9cf4e0", 0.5 - k * 0.2), 1.2, true)
	VectorPaint.painted(ci, VectorStyle.ellipse(head + Vector2(0, -6.5), 13.0, 3.4, 20), BARK_DARK, 1.0, 0.3, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([head + Vector2(-7, -7), head + Vector2(-5, -14), head + Vector2(5, -14), head + Vector2(7, -7)]), BARK, 1.2, 0.4, 1.0)
	for side: float in [-1.0, 1.0]:
		var at: Vector2 = Vector2(side * 20.0, -46.0) if p.facing != "side" else Vector2(side * 5.0 + 2.0, -47.0)
		for k: int in 4:
			VectorPaint.strand(ci, at + Vector2(side * k * 1.6, 0), at + Vector2(side * (k * 2.0 + 1.0), 6.0), at + Vector2(side * (k * 2.4 + 2.0), 13.0 + k * 1.5 + _sway(p, k)), 1.6, MOSS)
