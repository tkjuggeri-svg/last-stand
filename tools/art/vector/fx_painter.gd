class_name FxPainter
## The shared effects in vector (M15 P3, docs/M15_P3_HEROES.md): the explosions (two sizes), the frost nova and burst, the rising soul
## when something dies, burning ground (fire and soul fire), the status marks (frozen, shattered, beacon ember, silenced), the
## Huntress's snare, spiked patch and hawk (8 directions), and the ultimates' ring of light. frame(ci, anim, index, count) paints one
## sheet frame centred on the cell, as the old pixel sheets did, so every scene keeps its position. Warm for the defenders' side.

const FIRE: Array[Color] = [Color("c8341a"), Color("f07a24"), Color("ffc54a"), Color("fff3c0")]
const SOUL_FIRE: Array[Color] = [Color("2f8f86"), Color("56c9b9"), Color("8ff0dc"), Color("eafff8")]
const SMOKE: Color = Color("4a4048")
const ICE: Color = Color("7fd8ff")
const ICE_LIGHT: Color = Color("e4f8ff")
const ICE_DARK: Color = Color("3f86b8")
const GOLD: Color = Color("e8b54e")
const CREAM: Color = Color("fff0c8")
const IRON: Color = Color("55565f")
const IRON_LIGHT: Color = Color("9a9eab")
const FEATHER: Color = Color("8a6a48")
const FEATHER_LIGHT: Color = Color("e8dcc0")
const EXPLOSION_RADIUS: float = 40.0
const EXPLOSION_LARGE_RADIUS: float = 56.0
const NOVA_RADIUS: float = 40.0
## The ultimates' ring: its final radius (the base Last Stand circle, 160 px, and Wider Circle's 40% more).
const RING_RADIUS: float = 160.0
const RING_WIDE_RADIUS: float = 224.0


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var p: float = float(index + 1) / count
	var cycle: float = float(index) / count
	match anim:
		"explosion":
			_explosion(ci, p, EXPLOSION_RADIUS)
		"explosion_large":
			_explosion(ci, p, EXPLOSION_LARGE_RADIUS)
		"frost_nova":
			_nova(ci, p, NOVA_RADIUS)
		"frost_burst":
			_nova(ci, p, 16.0)
		"frost_aura":
			_aura(ci, cycle)
		"soul_burst":
			_soul_burst(ci, p)
		"burn":
			_flames(ci, cycle, FIRE)
		"soul_burn":
			_flames(ci, cycle, SOUL_FIRE)
		"frozen":
			_frozen(ci, cycle)
		"shattered":
			_shattered(ci, p)
		"beacon_ember":
			_ember(ci, cycle)
		"silenced":
			_bell(ci, cycle)
		"snare_armed":
			_snare(ci, 1.0 - float(index) * 0.06)
		"snare_sprung":
			_snare(ci, 1.0 - p)
			_dust_ring(ci, p)
		"patch":
			_patch(ci, cycle)
		"ring":
			_ring(ci, p, RING_RADIUS)
		"ring_wide":
			_ring(ci, p, RING_WIDE_RADIUS)
		_:
			if anim.begins_with("hawk_"):
				_hawk(ci, int(anim.get_slice("_", 1)) * PI / 4.0, cycle)


static func _ease(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)


## A fireball that blooms, a shock ring, sparks and smoke that lingers.
static func _explosion(ci: CanvasItem, p: float, radius: float) -> void:
	var grow: float = _ease(p)
	var fade: float = 1.0 - p * p
	VectorStyle.draw_glow(ci, Color("ff9a30"), Vector2.ZERO, radius * (0.9 + grow * 0.6), 0.6 * fade)
	for layer: int in 4:
		var r: float = radius * (0.3 + 0.7 * grow) * (1.0 - layer * 0.2)
		var lobes: int = 9
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in lobes * 2:
			var a: float = TAU * i / (lobes * 2.0) + layer * 0.35
			var wobble: float = 1.0 + (0.16 if i % 2 == 0 else -0.08) * (1.0 - p * 0.5)
			points.append(Vector2(cos(a), sin(a) * 0.9) * r * wobble)
		VectorPaint.fill(ci, points, Color(FIRE[layer], clampf(fade * (1.0 - layer * 0.08), 0.0, 1.0)))
	ci.draw_arc(Vector2.ZERO, radius * (0.5 + grow * 0.6), 0.0, TAU, 40, Color(CREAM, 0.7 * (1.0 - p)), 2.4, true)
	for i: int in 12:
		var a: float = TAU * i / 12.0 + 0.2
		var from: float = radius * (0.5 + grow * 0.5)
		ci.draw_line(Vector2.from_angle(a) * from, Vector2.from_angle(a) * (from + radius * 0.3 * (1.0 - p)), Color(FIRE[2], 0.9 * (1.0 - p)), 1.6, true)
	if p > 0.35:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 31
		for i: int in 7:
			var a: float = rng.randf() * TAU
			var d: float = radius * (0.35 + rng.randf() * 0.4) * (0.6 + p * 0.6)
			ci.draw_circle(Vector2.from_angle(a) * d + Vector2(0, -p * 6.0), radius * 0.16 * (0.6 + p), Color(SMOKE, 0.5 * (1.0 - p) * (p - 0.35) * 3.0), true, -1.0, true)


## An expanding ring of ice with crystal spikes, a cold glow inside.
static func _nova(ci: CanvasItem, p: float, radius: float) -> void:
	var grow: float = _ease(p)
	var fade: float = 1.0 - p * p
	var r: float = radius * (0.2 + 0.8 * grow)
	VectorStyle.draw_glow(ci, ICE, Vector2.ZERO, r * 1.2, 0.5 * fade)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, Color(ICE_LIGHT, 0.9 * fade), maxf(radius * 0.06, 1.6), true)
	ci.draw_arc(Vector2.ZERO, r * 0.8, 0.0, TAU, 36, Color(ICE, 0.5 * fade), maxf(radius * 0.04, 1.2), true)
	for i: int in 12:
		var a: float = TAU * i / 12.0
		var d: Vector2 = Vector2.from_angle(a)
		var s: Vector2 = d.orthogonal()
		var spike: float = radius * (0.18 + 0.16 * (i % 2)) * fade
		VectorPaint.fill(ci, PackedVector2Array([d * r + s * radius * 0.05, d * (r + spike), d * r - s * radius * 0.05]), Color(ICE_LIGHT, 0.95 * fade))


## A soul leaving a body: a pale-teal teardrop rising with a wavering tail and sparkles.
static func _soul_burst(ci: CanvasItem, p: float) -> void:
	var fade: float = 1.0 - smoothstep(0.7, 1.0, p)
	var teal: Color = Color("8ff0dc")
	ci.draw_arc(Vector2(0, 8), 8.0 + p * 24.0, 0.0, TAU, 28, Color(teal, 0.5 * (1.0 - p)), 1.6, true)
	var y: float = lerpf(4.0, -40.0, _ease(p))
	var head: Vector2 = Vector2(sin(p * 9.0) * 3.0, y)
	VectorStyle.draw_glow(ci, teal, head, 18.0, 0.5 * fade)
	for k: int in 3:
		VectorPaint.strand(ci, head + Vector2((k - 1) * 2.0, 2.0), head + Vector2(sin(p * 9.0 + k) * 5.0, 12.0 + k * 4.0), head + Vector2(sin(p * 9.0 + k * 2.0) * 7.0, 26.0 + k * 6.0), 5.0 - k, Color(teal, 0.7 * fade))
	VectorPaint.painted(ci, VectorStyle.ellipse(head, 5.0, 6.0, 14), Color("eafff8"), 1.2, 0.4, 0.6)
	for k: float in [-1.0, 1.0]:
		ci.draw_circle(head + Vector2(k * 1.9, -0.6), 0.9, Color("123a3a"), true, -1.0, true)
	for i: int in 5:
		var a: float = i * 1.3 + p * 4.0
		ci.draw_circle(head + Vector2(cos(a) * 12.0, sin(a) * 8.0), 1.2, Color(teal, 0.8 * fade), true, -1.0, true)


## Burning ground: a ring of tongues dancing across an oval patch.
static func _flames(ci: CanvasItem, cycle: float, colors: Array[Color]) -> void:
	VectorStyle.draw_glow(ci, colors[1], Vector2(0, 4), 40.0, 0.3)
	VectorPaint.fill(ci, VectorStyle.ellipse(Vector2(0, 8), 36.0, 12.0, 24), Color(colors[0], 0.45))
	for layer: int in 3:
		var s: float = 1.0 - layer * 0.28
		for i: int in 7:
			var phase: float = cycle * TAU + i * 1.9 + layer
			var x: float = (i - 3.0) * 9.0 * (0.75 + layer * 0.1)
			var h: float = (18.0 + sin(phase * 1.3) * 5.0) * s * (1.0 - absf(i - 3.0) * 0.12)
			var base: Vector2 = Vector2(x, 10.0 - absf(i - 3.0) * 1.5)
			var tip: Vector2 = base + Vector2(sin(phase) * 3.0, -h)
			VectorPaint.fill(ci, PackedVector2Array([base + Vector2(-5.0 * s, 0), base + Vector2(-3.0 * s + sin(phase) * 1.0, -h * 0.5), tip, base + Vector2(3.0 * s + sin(phase) * 1.0, -h * 0.5), base + Vector2(5.0 * s, 0)]), Color(colors[layer + 1], 0.95))


static func _frozen(ci: CanvasItem, cycle: float) -> void:
	var block: PackedVector2Array = PackedVector2Array([Vector2(-17, -26), Vector2(17, -26), Vector2(19, -22), Vector2(19, 20), Vector2(15, 24), Vector2(-15, 24), Vector2(-19, 20), Vector2(-19, -22)])
	VectorPaint.fill(ci, block, Color(ICE, 0.38))
	var closed: PackedVector2Array = block.duplicate()
	closed.append(block[0])
	ci.draw_polyline(closed, Color(ICE_LIGHT, 0.9), 2.0, true)
	var shine: float = sin(cycle * TAU) * 3.0
	ci.draw_line(Vector2(-12 + shine, -20), Vector2(-14 + shine, 10), Color(1, 1, 1, 0.7), 2.4, true)
	ci.draw_line(Vector2(-6 + shine, -16), Vector2(-7 + shine, -4), Color(1, 1, 1, 0.5), 1.6, true)
	VectorStyle.draw_glow(ci, ICE, Vector2(0, 0), 28.0, 0.25)


static func _shattered(ci: CanvasItem, p: float) -> void:
	var fade: float = 1.0 - p
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	for i: int in 10:
		var a: float = rng.randf() * TAU
		var d: float = (6.0 + rng.randf() * 14.0) * _ease(p)
		var at: Vector2 = Vector2(cos(a) * d, sin(a) * d * 0.9 - 4.0 + p * p * 14.0)
		var size: float = 3.0 + rng.randf() * 4.0
		var rot: float = rng.randf() * TAU + p * 3.0
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(0, -size).rotated(rot), at + Vector2(size * 0.7, size * 0.6).rotated(rot), at + Vector2(-size * 0.7, size * 0.6).rotated(rot)]), Color(ICE_LIGHT if i % 2 == 0 else ICE, 0.9 * fade))
	VectorStyle.draw_glow(ci, ICE, Vector2.ZERO, 22.0, 0.4 * fade)


## The Beacon Flame's boost mark: a small ember flame over a tower.
static func _ember(ci: CanvasItem, cycle: float) -> void:
	var sway: float = sin(cycle * TAU) * 1.6
	VectorStyle.draw_glow(ci, Color("ff9a30"), Vector2(0, -2), 14.0, 0.55)
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-7, 6), Vector2(-5, -4), Vector2(sway * 0.5, -16), Vector2(5, -4), Vector2(7, 6), Vector2(0, 9)]), FIRE[1])
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-4, 6), Vector2(-2.5, -1), Vector2(sway * 0.3, -9), Vector2(2.5, -1), Vector2(4, 6)]), FIRE[2])
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-2, 6), Vector2(0, -2), Vector2(2, 6)]), FIRE[3])


## The silence mark: a cracked bell swinging.
static func _bell(ci: CanvasItem, cycle: float) -> void:
	var swing: float = sin(cycle * TAU) * 0.18
	ci.draw_set_transform(Vector2(0, -4), swing, Vector2.ONE)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-8, 8), Vector2(-6, -2), Vector2(-3, -9), Vector2(3, -9), Vector2(6, -2), Vector2(8, 8)]), Color("c9a565"), 2.0, 0.5, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-9.4, 8), Vector2(9.4, 8), Vector2(9.4, 10.4), Vector2(-9.4, 10.4)]), Color("8f7440"), 0.6, 0.3, 0.9)
	ci.draw_circle(Vector2(0, 13), 2.0, Color("8f7440"), true, -1.0, true)
	ci.draw_line(Vector2(-1, -8), Vector2(2, 0), Color(0.1, 0.08, 0.1, 0.95), 1.4, true)
	ci.draw_line(Vector2(2, 0), Vector2(-1, 6), Color(0.1, 0.08, 0.1, 0.95), 1.4, true)
	ci.draw_circle(Vector2(0, -11), 1.6, Color("c9a565"), true, -1.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A faint cold ring with sparkles around a slowed enemy.
static func _aura(ci: CanvasItem, cycle: float) -> void:
	ci.draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, Color(ICE, 0.35), 1.4, true)
	for i: int in 5:
		var a: float = TAU * i / 5.0 + cycle * TAU
		ci.draw_circle(Vector2.from_angle(a) * 14.0, 1.4, Color(ICE_LIGHT, 0.9), true, -1.0, true)


## The Huntress's snare: an iron jaw trap; `open` is 1 armed, 0 sprung.
static func _snare(ci: CanvasItem, open: float) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, 4), 16.0, 6.0, 18), IRON, 1.2, 0.4, 1.0)
	for flip: float in [-1.0, 1.0]:
		var jaw: PackedVector2Array = PackedVector2Array([Vector2(flip * 15.0, 4), Vector2(flip * 8.0, 4.0 - 14.0 * open), Vector2(flip * 2.0, 4.0 - 4.0 * open)])
		VectorPaint.painted(ci, jaw, IRON_LIGHT, 1.2, 0.5, 1.0)
		for k: int in 3:
			var x: float = flip * (4.0 + k * 3.4)
			VectorPaint.fill(ci, PackedVector2Array([Vector2(x - 1.2, 4.0 - (4.0 + k * 3.0) * open), Vector2(x + 1.2, 4.0 - (4.0 + k * 3.0) * open), Vector2(x, 2.0 - (6.0 + k * 3.0) * open)]), Color.WHITE)
	ci.draw_circle(Vector2(0, 4), 2.0, Color("5a3d24"), true, -1.0, true)


static func _dust_ring(ci: CanvasItem, p: float) -> void:
	for i: int in 8:
		var a: float = TAU * i / 8.0
		ci.draw_circle(Vector2(cos(a) * 16.0 * p, 4.0 + sin(a) * 6.0 * p), 2.0 + p * 3.0, Color(0.8, 0.74, 0.66, 0.5 * (1.0 - p)), true, -1.0, true)


## Caltrops scattered over a patch of ground (the Caltrop Field's spiked patch).
static func _patch(ci: CanvasItem, cycle: float) -> void:
	VectorPaint.fill(ci, VectorStyle.ellipse(Vector2(0, 4), 28.0, 11.0, 20), Color(0.18, 0.14, 0.12, 0.4))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	for i: int in 12:
		var at: Vector2 = Vector2((rng.randf() - 0.5) * 48.0, 4.0 + (rng.randf() - 0.5) * 16.0)
		var a: float = rng.randf() * TAU
		for k: int in 4:
			var d: Vector2 = Vector2.from_angle(a + k * TAU / 4.0 + cycle * 0.0)
			ci.draw_line(at, at + d * 3.6 + Vector2(0, -1.4), Color(0.1, 0.08, 0.1, 0.95), 2.2, true)
			ci.draw_line(at, at + d * 3.6 + Vector2(0, -1.4), IRON_LIGHT, 1.2, true)
	var glint: float = fmod(cycle * 3.0, 1.0)
	ci.draw_circle(Vector2(lerpf(-14.0, 14.0, glint), 3.0), 1.4, Color(1, 1, 1, 0.8 * (1.0 - glint)), true, -1.0, true)


## The hawk in flight, seen from above and ahead, flapping; `angle` is its heading (hawk_0 flies right, then every 45 degrees clockwise).
static func _hawk(ci: CanvasItem, angle: float, cycle: float) -> void:
	var d: Vector2 = Vector2.from_angle(angle)
	var s: Vector2 = d.orthogonal()
	var flap: float = 0.5 + 0.5 * sin(cycle * TAU * 2.0)
	VectorStyle.shadow(ci, Vector2(0, 14), 8, 3)
	for flip: float in [-1.0, 1.0]:
		VectorPaint.painted(ci, PackedVector2Array([s * flip * 2.0 - d * 2.0, s * flip * (12.0 + flap * 4.0) - d * (4.0 + flap * 6.0), s * flip * (13.0 + flap * 3.0) - d * (8.0 + flap * 6.0), s * flip * 3.0 - d * 8.0]), FEATHER, 1.0, 0.5, 1.0)
	VectorPaint.painted(ci, VectorStyle.ellipse(-d * 2.0, 5.0, 3.4, 12), FEATHER, 1.2, 0.5, 1.0)
	VectorPaint.painted(ci, VectorStyle.ellipse(d * 4.0, 2.8, 2.8, 10), FEATHER_LIGHT, 0.6, 0.4, 0.9)
	VectorPaint.fill(ci, PackedVector2Array([d * 6.0 + s * 1.2, d * 9.6, d * 6.0 - s * 1.2]), GOLD)
	for k: float in [-1.0, 1.0]:
		ci.draw_line(-d * 8.0 + s * k * 1.0, -d * 12.0 + s * k * 2.0, FEATHER_LIGHT, 1.2, true)


## The ultimates' ring of light: a golden shockwave racing out to `radius`, bright at its edge, with a warm disc inside and rays.
static func _ring(ci: CanvasItem, p: float, radius: float) -> void:
	var grow: float = _ease(p)
	var fade: float = 1.0 - smoothstep(0.55, 1.0, p)
	var r: float = radius * (0.15 + 0.85 * grow)
	VectorPaint.fill(ci, VectorStyle.ellipse(Vector2.ZERO, r, r, 48), Color(GOLD, 0.16 * fade))
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 72, Color(GOLD, 0.35 * fade), 14.0, true)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 72, Color(CREAM, 0.95 * fade), 3.6, true)
	ci.draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 72, Color(GOLD, 0.4 * fade), 2.0, true)
	for i: int in 24:
		var a: float = TAU * i / 24.0
		var from: Vector2 = Vector2.from_angle(a) * r * 0.9
		ci.draw_line(from, Vector2.from_angle(a) * (r + 10.0), Color(CREAM, 0.7 * fade), 2.0, true)
