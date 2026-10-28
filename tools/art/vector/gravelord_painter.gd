class_name GravelordPainter
## Paints the vector Gravelord (M15 P2, docs/M15_P2_BOSSES.md): a tall gaunt gravedigger-lord in a ragged cloak with a high
## collar, a bone-white skull under a rusted circlet with violet pits (the boss role's colour), a shovel-scythe and a hanging
## lantern with green fire (the one green on him). Pose units: feet at y 0, about 72 tall (SCALE makes the body ~94 world px; with the raised tool he reaches the old
## sprite's ~120). frame() paints one sheet frame (sheet_layouts.gd GRAVELORD): idle, a slow walk, a two-handed
## overhead shovel swing timed to the data's 0.6 s wind-up, the summoning cast (arms up, lantern flaring, the soil churning)
## and a collapse into the cloak with the skull rolling away.

const CLOAK: Color = Color("6e668c")
const CLOAK_DARK: Color = Color("3d3856")
const BONE: Color = Color("ebe5d0")
const BONE_DARK: Color = Color("918a72")
const IRON: Color = Color("aab0c4")
const IRON_DARK: Color = Color("5c6279")
const RUST: Color = Color("a8723c")
const WOOD: Color = Color("8f6038")
const LANTERN: Color = Color("8dffb0")
const BOSS_VIOLET: Color = Color("c27aff")
const SOIL: Color = Color("4c3a2a")
const SCALE: float = 1.3
## Where the swing shapes peak (shares of the attack): the wind-up ends, the blow lands.
const WINDUP_END: float = 0.58
const STRIKE_PEAK: float = 0.82
const PULL_BACK: float = -1.0


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var a: Dictionary = VectorFrames.parse(anim)
	var state: String = a.state
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	VectorStyle.shadow(ci, Vector2(0, 1), 21, 5.2)
	if state == "death":
		_death(ci, progress)
		return
	var pose: Dictionary = {"facing": a.facing, "phase": cycle, "walk": state == "walk", "swing": 0.0, "cast": 0.0, "glow": 0.0}
	if state == "attack":
		pose.swing = VectorFrames.attack_curve(progress, WINDUP_END, STRIKE_PEAK, PULL_BACK)
		pose.striking = true
	elif state == "cast":
		pose.cast = smoothstep(0.0, 0.4, progress)
		pose.glow = sin(progress * PI) * 0.6 + pose.cast * 0.4
		_churn(ci, progress)
	var bob: float = -absf(sin(cycle * TAU)) * 1.2 if state == "walk" else sin(cycle * TAU) * 0.6
	ci.draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	_figure(ci, pose)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Soil heaving up around the feet while he summons: dark clods that rise and fall, with green mist.
static func _churn(ci: CanvasItem, progress: float) -> void:
	for k: int in 7:
		var x: float = -22.0 + k * 7.4
		var h: float = absf(sin(progress * 9.0 + k * 1.7)) * 4.0
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(x, 1.5 - h * 0.4), 3.4, 1.6 + h * 0.6, 10), SOIL, 0.8, 0.2, 0.6)
	VectorStyle.draw_glow(ci, LANTERN, Vector2(0, -10), 17.0, 0.2 + progress * 0.16)


static func _figure(ci: CanvasItem, pose: Dictionary) -> void:
	var facing: String = pose.facing
	var back: bool = facing == "up"
	var side: bool = facing == "side"
	var hands: Dictionary = _hands(pose)
	# Facing away, the whole figure is mirrored so the tool stays in the hand the rest of the art expects.
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1) if back else Vector2.ONE)
	if back:
		_tool(ci, hands.right, float(hands.angle))
	var squeeze: float = 0.62 if side else 1.0
	_cloak(ci, pose, squeeze)
	if side:
		_head_side(ci)
	else:
		_collar(ci)
		_head_front(ci, back)
	_arms(ci, hands, side)
	if not back:
		_tool(ci, hands.right, float(hands.angle))
	_lantern(ci, hands.lantern, float(pose.glow))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Hand and tool targets for the pose: resting, mid-swing (both hands on the haft), or casting (arms raised).
static func _hands(pose: Dictionary) -> Dictionary:
	var sway: float = sin(float(pose.phase) * TAU) * (1.6 if pose.walk else 0.5)
	var right: Vector2 = Vector2(17, -32 + sway)
	var left: Vector2 = Vector2(-15, -30 - sway)
	var angle: float = -1.45 + sway * 0.02
	var lantern: Vector2 = left + Vector2(-1, 11)
	var cast: float = float(pose.cast)
	if cast > 0.0:
		right = right.lerp(Vector2(17, -36), cast)
		left = left.lerp(Vector2(-17, -58), cast)
		angle = lerpf(angle, -1.5708, cast)
		lantern = left + Vector2(0, -6.0 * cast + 11.0 * (1.0 - cast))
	var swing: float = float(pose.swing)
	if pose.has("striking"):
		angle = -1.45 + swing * 0.8 if swing < 0.0 else lerpf(-1.45, 0.65, swing)
		right = Vector2(13, -36).lerp(Vector2(17, -26), maxf(swing, 0.0))
		left = right + Vector2.from_angle(angle) * 13.0 * -1.0 + Vector2(-3, 2)
		lantern = Vector2(-13, -26 + sway)
	return {"right": right, "left": left, "angle": angle, "lantern": lantern}


## The ragged cloak: a tapering bell from the shoulders to a torn hem, with an inner opening, folds and a belt.
static func _cloak(ci: CanvasItem, pose: Dictionary, squeeze: float) -> void:
	var sway: float = sin(float(pose.phase) * TAU) * (2.6 if pose.walk else 0.9)
	var pts: PackedVector2Array = PackedVector2Array([Vector2(-10, -54), Vector2(10, -54), Vector2(14, -40), Vector2(17 + sway * 0.3, -20)])
	for i: int in 9:
		var x: float = lerpf(21.0, -21.0, i / 8.0) + sway * 0.5
		pts.append(Vector2(x, -3.0 + (2.6 if i % 2 == 0 else -1.2)))
	pts.append_array(PackedVector2Array([Vector2(-17 + sway * 0.3, -20), Vector2(-14, -40)]))
	pts = _squeezed(pts, squeeze)
	VectorPaint.painted(ci, pts, CLOAK, 4.0, 0.6, 1.4)
	if pose.facing == "down":
		var opening: PackedVector2Array = _squeezed(PackedVector2Array([Vector2(-3.4, -53), Vector2(3.4, -53), Vector2(8, -5), Vector2(-8, -5)]), squeeze)
		VectorPaint.fill(ci, opening, CLOAK_DARK)
		for k: int in 4:
			var y: float = -47.0 + k * 3.4
			VectorPaint.line(ci, Vector2(-2.4, y), Vector2(2.4, y), Color(BONE_DARK, 0.7), 0.9)
	for k: float in [-1.0, 1.0]:
		VectorPaint.strand(ci, Vector2(k * 7 * squeeze, -50), Vector2(k * 11 * squeeze, -28), Vector2(k * 15 * squeeze + sway * 0.4, -5), 3.0, Color(CLOAK_DARK, 0.8))
	VectorPaint.painted(ci, _squeezed(PackedVector2Array([Vector2(-12, -35), Vector2(12, -35), Vector2(12.4, -32), Vector2(-12.4, -32)]), squeeze), RUST, 0.6, 0.2, 0.8)
	if pose.facing != "up":
		ci.draw_circle(Vector2(0, -33.6) * Vector2(squeeze, 1.0), 1.7, BONE, true, -1.0, true)
	for k: float in [-0.7, 0.7]:
		VectorPaint.painted(ci, _squeezed(VectorStyle.ellipse(Vector2(k * 7.0, -1.4), 4.2, 2.0, 10), squeeze), IRON_DARK, 0.6, 0.2, 0.8)


static func _squeezed(points: PackedVector2Array, by: float) -> PackedVector2Array:
	if is_equal_approx(by, 1.0):
		return points
	var out: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in points:
		out.append(Vector2(p.x * by, p.y))
	return out


## The two pointed flares of the high collar, behind the skull.
static func _collar(ci: CanvasItem) -> void:
	for k: float in [-1.0, 1.0]:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(k * 3.0, -54), Vector2(k * 13.0, -74), Vector2(k * 10.0, -58), Vector2(k * 11.0, -52)]), CLOAK_DARK, 1.6, 0.5, 1.1)


static func _head_front(ci: CanvasItem, back: bool) -> void:
	var at: Vector2 = Vector2(0, -63)
	VectorPaint.painted(ci, VectorStyle.ellipse(at, 6.4, 7.2, 22), BONE, 2.4, 0.6, 1.2)
	if not back:
		VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, 5.6), 4.2, 2.6, 14), BONE_DARK, 0.8, 0.1, 0.8)
		for x: float in [-2.8, 2.8]:
			VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(x, -0.4), 1.9, 2.3, 10), Color("100c18"), 0.4, 0.0, 0.0)
			VectorStyle.draw_glow(ci, BOSS_VIOLET, at + Vector2(x, -0.4), 2.8, 0.5)
			ci.draw_circle(at + Vector2(x, -0.4), 0.8, Color("f1d6ff"), true, -1.0, true)
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-0.7, 2.6), at + Vector2(0.7, 2.6), at + Vector2(0, 4.2)]), Color("100c18"))
		for k: int in 5:
			VectorPaint.line(ci, at + Vector2(-2.6 + k * 1.3, 5.0), at + Vector2(-2.6 + k * 1.3, 6.8), Color(VectorStyle.INK, 0.8), 0.6)
	else:
		VectorPaint.line(ci, at + Vector2(0, -6), at + Vector2(0, 5), Color(BONE_DARK, 0.8), 0.8)
	_circlet(ci, at, 6.9)


static func _head_side(ci: CanvasItem) -> void:
	var at: Vector2 = Vector2(3, -63)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-3, -54), Vector2(-9, -74), Vector2(-7, -58), Vector2(-4, -52)]), CLOAK_DARK, 1.6, 0.5, 1.1)
	VectorPaint.painted(ci, VectorStyle.ellipse(at, 6.0, 7.2, 22), BONE, 2.4, 0.6, 1.2)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(1, 3), at + Vector2(7.4, 4.4), at + Vector2(5.2, 8.6), at + Vector2(-1, 7.4)]), BONE_DARK, 0.8, 0.1, 0.8)
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(2.6, -0.6), 1.8, 2.2, 10), Color("100c18"), 0.4, 0.0, 0.0)
	VectorStyle.draw_glow(ci, BOSS_VIOLET, at + Vector2(2.6, -0.6), 2.8, 0.5)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(6.0, 1.2), at + Vector2(8.4, 3.4), at + Vector2(5.8, 3.6)]), Color("100c18"))
	_circlet(ci, at, 6.4)


static func _circlet(ci: CanvasItem, at: Vector2, half: float) -> void:
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-half, -4.6), at + Vector2(half, -4.6), at + Vector2(half, -2.6), at + Vector2(-half, -2.6)]), RUST, 0.6, 0.3, 0.8)
	for k: float in [-0.6, 0.0, 0.6]:
		var base: Vector2 = at + Vector2(k * half, -4.6)
		VectorPaint.painted(ci, PackedVector2Array([base + Vector2(-1.6, 0), base + Vector2(1.6, 0), base + Vector2(0, -4.6 - (1.0 - absf(k)) * 2.2)]), IRON, 0.5, 0.3, 0.7)


## Sleeves from the shoulders to bony hands: the right one holds the tool, the left holds it too mid-swing or the lantern.
static func _arms(ci: CanvasItem, hands: Dictionary, side: bool) -> void:
	var squeeze: float = 0.62 if side else 1.0
	for key: String in ["left", "right"]:
		var hand: Vector2 = hands[key]
		var flip: float = -1.0 if key == "left" else 1.0
		var shoulder: Vector2 = Vector2(flip * 10.0 * squeeze, -52)
		if side:
			shoulder = Vector2(2.0 + flip * 1.5, -52)
		var elbow: Vector2 = shoulder.lerp(hand, 0.5) + Vector2(flip * 3.0, 3.0)
		VectorPaint.limb(ci, shoulder, elbow, hand, 6.0, CLOAK)
		VectorPaint.painted(ci, VectorStyle.ellipse(hand, 2.4, 2.2, 10), BONE, 0.6, 0.3, 0.9)
	var pad: Vector2 = Vector2(0, -52)
	if not side:
		for k: float in [-1.0, 1.0]:
			VectorPaint.painted(ci, VectorStyle.ellipse(pad + Vector2(k * 10.0, 0), 4.6, 3.2, 12), IRON_DARK, 1.0, 0.4, 0.9)


## The shovel-scythe: a long haft with a spade blade and a curved scythe edge at its head, `hand` on the haft.
static func _tool(ci: CanvasItem, hand: Vector2, angle: float) -> void:
	# Swung level, the long tool would leave the cell: it is foreshortened as it lies across the view (at 15 fps nobody sees it).
	var reach: float = lerpf(1.0, 0.4, absf(cos(angle)))
	var dir: Vector2 = Vector2.from_angle(angle)
	var across: Vector2 = dir.orthogonal()
	var butt: Vector2 = hand - dir * 20.0 * reach
	var neck: Vector2 = hand + dir * 38.0 * reach
	VectorPaint.painted(ci, PackedVector2Array([butt + across * 1.2, neck + across * 1.2, neck - across * 1.2, butt - across * 1.2]), WOOD, 0.6, 0.3, 1.0)
	var spade: PackedVector2Array = PackedVector2Array([neck + across * 6.0, neck + dir * 12.0 + across * 5.2, neck + dir * 18.0, neck + dir * 12.0 - across * 5.2, neck - across * 6.0])
	VectorPaint.painted(ci, spade, IRON, 1.8, 0.6, 1.1)
	VectorPaint.line(ci, neck + dir * 2.0, neck + dir * 15.0, Color(1, 1, 1, 0.4), 0.7)
	var outer: PackedVector2Array = VectorPaint.curve(neck + across * 5.0 + dir * 3.0, neck + across * 17.0 + dir * 10.0, neck + across * 17.0 - dir * 6.0, 8)
	var inner: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in outer:
		inner.append(p - dir * 3.4 - across * 1.2)
	inner.reverse()
	outer.append_array(inner)
	VectorPaint.painted(ci, outer, IRON_DARK, 0.8, 0.5, 1.0)
	VectorPaint.rivet(ci, neck + dir * 2.0, 0.8)


static func _lantern(ci: CanvasItem, at: Vector2, glow: float) -> void:
	VectorPaint.line(ci, at + Vector2(0, -5.5), at + Vector2(0, -2), IRON_DARK, 0.9)
	VectorStyle.draw_glow(ci, LANTERN, at, 15.0 + glow * 13.0, 0.5 + glow * 0.45)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-2.6, -2), at + Vector2(2.6, -2), at + Vector2(3.2, 4), at + Vector2(-3.2, 4)]), IRON_DARK, 0.6, 0.3, 0.9)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-1.7, -1), at + Vector2(1.7, -1), at + Vector2(2.1, 3), at + Vector2(-2.1, 3)]), LANTERN)
	ci.draw_circle(at + Vector2(0, 1), 1.0, Color("f0fff4"), true, -1.0, true)


## He sinks, the cloak slumps into a pile, the skull rolls off and the shovel falls; the lantern's fire dies.
static func _death(ci: CanvasItem, progress: float) -> void:
	var slump: float = smoothstep(0.1, 0.85, progress)
	var pose: Dictionary = {"facing": "down", "phase": 0.0, "walk": false, "swing": 0.0, "cast": 0.0, "glow": 0.0}
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + slump * 0.55, 1.0 - slump * 0.86))
	_cloak(ci, pose, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if slump < 0.45:
		_collar(ci)
		_head_front(ci, false)
		var hands: Dictionary = _hands(pose)
		_arms(ci, hands, false)
		var drop: float = slump / 0.45
		_tool(ci, Vector2(17, -32).lerp(Vector2(-26, -3), drop), lerpf(-1.45, -0.5, drop))
	else:
		var roll: float = smoothstep(0.4, 0.95, progress)
		var skull: Vector2 = Vector2(0, -63).lerp(Vector2(24, -6), roll)
		# _head_front paints around (0, -63): move that point onto `skull` while the head turns about itself.
		ci.draw_set_transform(skull + Vector2(0, 63).rotated(roll * 5.0), roll * 5.0, Vector2.ONE)
		_head_front(ci, false)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_tool(ci, Vector2(-26, -3.0), lerpf(-0.5, 0.06, roll))
	VectorStyle.draw_glow(ci, LANTERN, Vector2(-14, -12), 12.0, 0.5 * (1.0 - slump))
