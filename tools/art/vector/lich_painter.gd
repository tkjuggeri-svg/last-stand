class_name LichPainter
## Paints the vector Lich Warden (M15 P2, docs/M15_P2_BOSSES.md): a thin robed sorcerer-king that hovers, layered
## purple-black robes with silver trim and a ragged hem that fades into wisps, shard pauldrons, a bone skull under violet
## flames with a floating crown of shards, and a crystal-topped staff (the boss role's violet). Pose units: feet (the
## shadow) at y 0, the figure floats about 5 above it, about 72 tall (SCALE ~94 world px, ~120 with the staff). frame()
## paints one sheet frame (sheet_layouts.gd LICH): a hovering idle, a gliding walk, a staff thrust, the ward cast (staff
## raised, the crystal pulsing, a ring of runes growing on the ground: the ward's reach) and a collapse that empties the robe.

const ROBE: Color = Color("7d5ca3")
const ROBE_DARK: Color = Color("3e2c5c")
const TRIM: Color = Color("d4d8ea")
const TRIM_DARK: Color = Color("8e93ad")
const BONE: Color = Color("efe9d6")
const BONE_DARK: Color = Color("958e78")
const VIOLET: Color = Color("c27aff")
const VIOLET_DEEP: Color = Color("7a3fc0")
const PIT: Color = Color("120d1a")
const WOOD: Color = Color("5a3f6e")
const SCALE: float = 1.3
const WINDUP_END: float = 0.58
const STRIKE_PEAK: float = 0.82
const PULL_BACK: float = -1.0
const HOVER: float = 6.0


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var a: Dictionary = VectorFrames.parse(anim)
	var state: String = a.state
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	var bob: float = sin(cycle * TAU) * 1.6
	# The shadow stays on the ground while the figure floats: it grows a little when the lich sinks.
	VectorStyle.shadow(ci, Vector2(0, 1), 18.0 - bob * 0.4, 4.6)
	if state == "death":
		_death(ci, progress)
		return
	var pose: Dictionary = {"facing": a.facing, "phase": cycle, "walk": state == "walk", "thrust": 0.0, "cast": 0.0, "pulse": 0.0, "striking": false}
	if state == "attack":
		pose.thrust = VectorFrames.attack_curve(progress, WINDUP_END, STRIKE_PEAK, PULL_BACK)
		pose.striking = true
	elif state == "cast":
		pose.cast = smoothstep(0.0, 0.4, progress)
		pose.pulse = 0.5 + 0.5 * sin(progress * TAU * 2.0)
		_rune_ring(ci, progress)
	var lift: float = HOVER + (bob if not pose.walk else bob * 0.6)
	ci.draw_set_transform(Vector2(0, -lift), 0.0, Vector2.ONE)
	_figure(ci, pose)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The ward's ring: violet runes circling on the ground, growing through the cast.
static func _rune_ring(ci: CanvasItem, progress: float) -> void:
	var radius: float = lerpf(10.0, 30.0, smoothstep(0.0, 0.8, progress))
	var alpha: float = 0.35 + 0.3 * sin(progress * PI)
	var ring: PackedVector2Array = VectorStyle.ellipse(Vector2(0, -1), radius, radius * 0.2, 40)
	ring.append(ring[0])
	ci.draw_polyline(ring, Color(VIOLET, alpha), 1.4, true)
	for k: int in 8:
		var ang: float = k * TAU / 8.0 + progress * 2.0
		var at: Vector2 = Vector2(cos(ang) * radius, -1.0 + sin(ang) * radius * 0.2)
		ci.draw_circle(at, 1.2, Color(VIOLET, alpha + 0.2), true, -1.0, true)


static func _figure(ci: CanvasItem, pose: Dictionary) -> void:
	var facing: String = pose.facing
	var back: bool = facing == "up"
	var side: bool = facing == "side"
	var hands: Dictionary = _hands(pose)
	_wisps(ci, pose)
	if back:
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
		_staff(ci, hands.right, float(hands.angle), float(pose.pulse), float(pose.cast))
	var squeeze: float = 0.64 if side else 1.0
	_robe(ci, pose, squeeze)
	_pauldrons(ci, squeeze, side)
	if side:
		_head_side(ci)
	else:
		_head_front(ci, back)
	_arms(ci, hands, side)
	if not back:
		_staff(ci, hands.right, float(hands.angle), float(pose.pulse), float(pose.cast))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _hands(pose: Dictionary) -> Dictionary:
	var sway: float = sin(float(pose.phase) * TAU) * 1.2
	var right: Vector2 = Vector2(18, -32 + sway)
	var left: Vector2 = Vector2(-14, -30 - sway)
	var angle: float = -1.5708
	var cast: float = float(pose.cast)
	if cast > 0.0:
		right = right.lerp(Vector2(17, -34), cast)
		left = left.lerp(Vector2(-18, -52), cast)
	if bool(pose.striking):
		var thrust: float = float(pose.thrust)
		angle = lerpf(-1.5708, -0.55, maxf(thrust, 0.0)) + (thrust * 0.5 if thrust < 0.0 else 0.0)
		right = Vector2(16, -34).lerp(Vector2(20, -30), maxf(thrust, 0.0))
		left = right + Vector2(-11, 3)
	return {"right": right, "left": left, "angle": angle}


## Pale wisps trailing under the hem: the lich has no feet.
static func _wisps(ci: CanvasItem, pose: Dictionary) -> void:
	var t: float = float(pose.phase) * TAU
	for k: int in 5:
		var x: float = -12.0 + k * 6.0
		var sway: float = sin(t + k * 1.3) * 2.0
		VectorPaint.strand(ci, Vector2(x, -12), Vector2(x + sway, -6), Vector2(x + sway * 1.5, 3.0), 5.0, Color(VIOLET_DEEP, 0.55))


static func _robe(ci: CanvasItem, pose: Dictionary, squeeze: float) -> void:
	var t: float = float(pose.phase) * TAU
	var sway: float = sin(t) * (2.4 if pose.walk else 1.0)
	var pts: PackedVector2Array = PackedVector2Array([Vector2(-9, -55), Vector2(9, -55), Vector2(13, -40), Vector2(15 + sway * 0.4, -24)])
	for i: int in 8:
		var x: float = lerpf(19.0, -19.0, i / 7.0) + sway * 0.6
		pts.append(Vector2(x, -10.0 + (3.0 if i % 2 == 0 else -1.0) + sin(t + i) * 1.0))
	pts.append_array(PackedVector2Array([Vector2(-15 + sway * 0.4, -24), Vector2(-13, -40)]))
	pts = _squeezed(pts, squeeze)
	VectorPaint.painted(ci, pts, ROBE, 4.0, 0.6, 1.4)
	if pose.facing == "down":
		VectorPaint.fill(ci, _squeezed(PackedVector2Array([Vector2(-3.4, -54), Vector2(3.4, -54), Vector2(8, -9), Vector2(-8, -9)]), squeeze), ROBE_DARK)
		VectorPaint.line(ci, Vector2(0, -52), Vector2(0, -10), Color(TRIM, 0.7), 1.1)
		for k: int in 5:
			var y: float = -48.0 + k * 7.0
			VectorPaint.line(ci, Vector2(-3.4, y), Vector2(3.4, y), Color(VIOLET, 0.6), 0.9)
	for k: float in [-1.0, 1.0]:
		VectorPaint.strand(ci, Vector2(k * 8 * squeeze, -51), Vector2(k * 12 * squeeze, -30), Vector2(k * 16 * squeeze + sway * 0.4, -11), 3.0, Color(ROBE_DARK, 0.8))
	VectorPaint.painted(ci, _squeezed(PackedVector2Array([Vector2(-14, -38), Vector2(14, -38), Vector2(14.4, -35.4), Vector2(-14.4, -35.4)]), squeeze), TRIM_DARK, 0.5, 0.3, 0.8)
	var hem: PackedVector2Array = PackedVector2Array()
	for i: int in 8:
		hem.append(Vector2(lerpf(19.0, -19.0, i / 7.0) + sway * 0.6, -10.0 + (3.0 if i % 2 == 0 else -1.0) + sin(t + i) * 1.0) * Vector2(squeeze, 1.0))
	ci.draw_polyline(hem, Color(TRIM, 0.85), 1.2, true)


static func _squeezed(points: PackedVector2Array, by: float) -> PackedVector2Array:
	if is_equal_approx(by, 1.0):
		return points
	var out: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in points:
		out.append(Vector2(p.x * by, p.y))
	return out


static func _pauldrons(ci: CanvasItem, squeeze: float, side: bool) -> void:
	var xs: PackedFloat32Array = PackedFloat32Array([-1.0, 1.0]) if not side else PackedFloat32Array([1.0])
	for k: float in xs:
		var at: Vector2 = Vector2(k * 11.0 * squeeze, -53)
		VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-4.0 * k, 0), at + Vector2(k * 8.0, -2.0), at + Vector2(k * 13.0, -11.0), at + Vector2(k * 6.0, 4.0)]), TRIM_DARK, 1.4, 0.5, 1.0)
		VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-3.0 * k, -1.0), at + Vector2(k * 6.0, -3.0), at + Vector2(k * 9.0, -16.0), at + Vector2(k * 3.0, -3.0)]), TRIM, 1.0, 0.5, 0.9)


static func _head_front(ci: CanvasItem, back: bool) -> void:
	var at: Vector2 = Vector2(0, -63)
	_flames(ci, at)
	_crown(ci, at)
	VectorPaint.painted(ci, VectorStyle.ellipse(at, 6.2, 7.0, 22), BONE, 2.4, 0.6, 1.2)
	if back:
		VectorPaint.line(ci, at + Vector2(0, -6), at + Vector2(0, 5), Color(BONE_DARK, 0.8), 0.8)
		return
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, 5.2), 4.0, 2.4, 14), BONE_DARK, 0.8, 0.1, 0.8)
	for x: float in [-2.7, 2.7]:
		VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(x, -0.4), 1.9, 2.4, 10), PIT, 0.4, 0.0, 0.0)
		VectorStyle.draw_glow(ci, VIOLET, at + Vector2(x, -0.4), 3.0, 0.65)
		ci.draw_circle(at + Vector2(x, -0.4), 0.8, Color("f1d6ff"), true, -1.0, true)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-0.7, 2.4), at + Vector2(0.7, 2.4), at + Vector2(0, 4.0)]), PIT)
	for k: int in 5:
		VectorPaint.line(ci, at + Vector2(-2.6 + k * 1.3, 4.6), at + Vector2(-2.6 + k * 1.3, 6.4), Color(VectorStyle.INK, 0.8), 0.6)


static func _head_side(ci: CanvasItem) -> void:
	var at: Vector2 = Vector2(2, -63)
	_flames(ci, at)
	_crown(ci, at)
	VectorPaint.painted(ci, VectorStyle.ellipse(at, 5.8, 7.0, 22), BONE, 2.4, 0.6, 1.2)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(1, 3), at + Vector2(7.0, 4.4), at + Vector2(5.0, 8.4), at + Vector2(-1, 7.2)]), BONE_DARK, 0.8, 0.1, 0.8)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(2.4, -0.6), 1.8, 2.3, 10), PIT, 0.4, 0.0, 0.0)
	VectorStyle.draw_glow(ci, VIOLET, at + Vector2(2.4, -0.6), 3.0, 0.65)
	ci.draw_circle(at + Vector2(2.4, -0.6), 0.8, Color("f1d6ff"), true, -1.0, true)


## Violet flames licking up from the skull.
static func _flames(ci: CanvasItem, at: Vector2) -> void:
	VectorStyle.draw_glow(ci, VIOLET, at + Vector2(0, -6), 13.0, 0.4)
	for k: int in 5:
		var x: float = (k - 2) * 3.2
		var h: float = 9.0 - absf(k - 2) * 2.2
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(x - 2.2, -4.4), at + Vector2(x + 2.2, -4.4), at + Vector2(x + x * 0.12, -4.4 - h)]), Color(VIOLET, 0.9))
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(x - 1.0, -4.4), at + Vector2(x + 1.0, -4.4), at + Vector2(x, -4.4 - h * 0.55)]), Color("f1d6ff"))


## Five shards of the crown floating in an arc above the flames.
static func _crown(ci: CanvasItem, at: Vector2) -> void:
	for k: int in 5:
		var ang: float = -PI + (k + 0.5) * PI / 5.0
		var p: Vector2 = at + Vector2(cos(ang) * 10.0, -14.0 + sin(ang) * 3.5)
		VectorPaint.painted(ci, VectorStyle.regular(p, 4, 1.5, 3.4, 0.0), TRIM, 0.4, 0.4, 0.7)


static func _arms(ci: CanvasItem, hands: Dictionary, side: bool) -> void:
	for key: String in ["left", "right"]:
		var hand: Vector2 = hands[key]
		var flip: float = -1.0 if key == "left" else 1.0
		var shoulder: Vector2 = Vector2(flip * 10.0 * (0.64 if side else 1.0), -50)
		if side:
			shoulder = Vector2(2.0 + flip, -50)
		var elbow: Vector2 = shoulder.lerp(hand, 0.5) + Vector2(flip * 3.0, 3.0)
		VectorPaint.limb(ci, shoulder, elbow, hand, 5.0, ROBE)
		VectorPaint.painted(ci, VectorStyle.ellipse(hand, 2.2, 2.0, 10), BONE, 0.6, 0.3, 0.9)


## The staff: a long dark haft, silver rings and a violet crystal that glows (flaring through the cast and the thrust).
static func _staff(ci: CanvasItem, hand: Vector2, angle: float, pulse: float, cast: float) -> void:
	var reach: float = lerpf(1.0, 0.45, absf(cos(angle)))
	var dir: Vector2 = Vector2.from_angle(angle)
	var across: Vector2 = dir.orthogonal()
	var butt: Vector2 = hand - dir * 22.0 * reach
	var top: Vector2 = hand + dir * 34.0 * reach
	VectorPaint.painted(ci, PackedVector2Array([butt + across * 1.1, top + across * 1.1, top - across * 1.1, butt - across * 1.1]), WOOD, 0.6, 0.3, 1.0)
	for k: float in [0.2, 0.5, 0.8]:
		var at: Vector2 = butt.lerp(top, k)
		VectorPaint.line(ci, at + across * 1.7, at - across * 1.7, TRIM, 1.0)
	var glow: float = 0.5 + pulse * 0.5 + cast * 0.3
	var gem: Vector2 = top + dir * 6.0
	VectorStyle.draw_glow(ci, VIOLET, gem, 9.0 + glow * 6.0, 0.5 + glow * 0.4)
	VectorPaint.painted(ci, PackedVector2Array([gem + dir * 6.0, gem + across * 3.6, gem - dir * 5.0, gem - across * 3.6]), VIOLET, 1.0, 0.6, 1.0)
	VectorPaint.line(ci, gem - dir * 3.0, gem + dir * 3.0, Color(1, 1, 1, 0.55), 0.7)
	for k: float in [-1.0, 1.0]:
		VectorPaint.painted(ci, PackedVector2Array([top + across * k * 1.0, top + dir * 5.0 + across * k * 5.0, top + dir * 3.0 + across * k * 1.0]), TRIM, 0.4, 0.3, 0.7)


## The robe empties: the crystal cracks, the lich sinks and the robe slumps into a pile, the skull settles on it, the flames die.
static func _death(ci: CanvasItem, progress: float) -> void:
	var slump: float = smoothstep(0.15, 0.9, progress)
	var pose: Dictionary = {"facing": "down", "phase": 0.0, "walk": false, "thrust": 0.0, "cast": 0.0, "pulse": 0.0, "striking": false}
	ci.draw_set_transform(Vector2(0, -HOVER * (1.0 - slump)), 0.0, Vector2(1.0 + slump * 0.45, 1.0 - slump * 0.88))
	_robe(ci, pose, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var hands: Dictionary = _hands(pose)
	if slump < 0.5:
		var down: float = slump / 0.5
		ci.draw_set_transform(Vector2(0, -HOVER + down * 22.0), 0.0, Vector2(1.0, 1.0 - down * 0.2))
		_pauldrons(ci, 1.0, false)
		_head_front(ci, false)
		_arms(ci, hands, false)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var settle: float = smoothstep(0.45, 0.95, progress)
		var skull: Vector2 = Vector2(0, -63 + 22.0 - HOVER).lerp(Vector2(5, -5), settle)
		# _head_front paints around (0, -63): move that point onto `skull`.
		ci.draw_set_transform(skull + Vector2(0, 63), 0.0, Vector2.ONE)
		_head_front(ci, false)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var drop: float = smoothstep(0.1, 0.9, progress)
	_staff(ci, Vector2(18, -32).lerp(Vector2(-24, -4.0), drop), lerpf(-1.5708, 0.03, drop), 1.0 - drop, 0.0)
	VectorStyle.draw_glow(ci, VIOLET, Vector2(0, -16), 14.0 * (1.0 - drop), 0.9 * (1.0 - drop))
